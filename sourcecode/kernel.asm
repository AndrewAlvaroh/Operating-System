
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 20 da 10 80       	mov    $0x8010da20,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 52 2b 10 80       	mov    $0x80102b52,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 20 da 10 80       	push   $0x8010da20
80100046:	e8 3f 3f 00 00       	call   80103f8a <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 70 21 11 80    	mov    0x80112170,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb 1c 21 11 80    	cmp    $0x8011211c,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 20 da 10 80       	push   $0x8010da20
8010007c:	e8 72 3f 00 00       	call   80103ff3 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 f1 3c 00 00       	call   80103d7d <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 6c 21 11 80    	mov    0x8011216c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb 1c 21 11 80    	cmp    $0x8011211c,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 20 da 10 80       	push   $0x8010da20
801000ca:	e8 24 3f 00 00       	call   80103ff3 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 a3 3c 00 00       	call   80103d7d <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 e0 69 10 80       	push   $0x801069e0
801000ef:	e8 68 02 00 00       	call   8010035c <panic>

801000f4 <binit>:
{
801000f4:	f3 0f 1e fb          	endbr32 
801000f8:	55                   	push   %ebp
801000f9:	89 e5                	mov    %esp,%ebp
801000fb:	53                   	push   %ebx
801000fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000ff:	68 f1 69 10 80       	push   $0x801069f1
80100104:	68 20 da 10 80       	push   $0x8010da20
80100109:	e8 2c 3d 00 00       	call   80103e3a <initlock>
  bcache.head.prev = &bcache.head;
8010010e:	c7 05 6c 21 11 80 1c 	movl   $0x8011211c,0x8011216c
80100115:	21 11 80 
  bcache.head.next = &bcache.head;
80100118:	c7 05 70 21 11 80 1c 	movl   $0x8011211c,0x80112170
8010011f:	21 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100122:	83 c4 10             	add    $0x10,%esp
80100125:	bb 54 da 10 80       	mov    $0x8010da54,%ebx
8010012a:	eb 37                	jmp    80100163 <binit+0x6f>
    b->next = bcache.head.next;
8010012c:	a1 70 21 11 80       	mov    0x80112170,%eax
80100131:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100134:	c7 43 50 1c 21 11 80 	movl   $0x8011211c,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
8010013b:	83 ec 08             	sub    $0x8,%esp
8010013e:	68 f8 69 10 80       	push   $0x801069f8
80100143:	8d 43 0c             	lea    0xc(%ebx),%eax
80100146:	50                   	push   %eax
80100147:	e8 fa 3b 00 00       	call   80103d46 <initsleeplock>
    bcache.head.next->prev = b;
8010014c:	a1 70 21 11 80       	mov    0x80112170,%eax
80100151:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100154:	89 1d 70 21 11 80    	mov    %ebx,0x80112170
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010015a:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
80100160:	83 c4 10             	add    $0x10,%esp
80100163:	81 fb 1c 21 11 80    	cmp    $0x8011211c,%ebx
80100169:	72 c1                	jb     8010012c <binit+0x38>
}
8010016b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016e:	c9                   	leave  
8010016f:	c3                   	ret    

80100170 <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
80100170:	f3 0f 1e fb          	endbr32 
80100174:	55                   	push   %ebp
80100175:	89 e5                	mov    %esp,%ebp
80100177:	53                   	push   %ebx
80100178:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
8010017b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010017e:	8b 45 08             	mov    0x8(%ebp),%eax
80100181:	e8 ae fe ff ff       	call   80100034 <bget>
80100186:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100188:	f6 00 02             	testb  $0x2,(%eax)
8010018b:	74 07                	je     80100194 <bread+0x24>
    iderw(b);
  }
  return b;
}
8010018d:	89 d8                	mov    %ebx,%eax
8010018f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100192:	c9                   	leave  
80100193:	c3                   	ret    
    iderw(b);
80100194:	83 ec 0c             	sub    $0xc,%esp
80100197:	50                   	push   %eax
80100198:	e8 29 1d 00 00       	call   80101ec6 <iderw>
8010019d:	83 c4 10             	add    $0x10,%esp
  return b;
801001a0:	eb eb                	jmp    8010018d <bread+0x1d>

801001a2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
801001a2:	f3 0f 1e fb          	endbr32 
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	53                   	push   %ebx
801001aa:	83 ec 10             	sub    $0x10,%esp
801001ad:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001b0:	8d 43 0c             	lea    0xc(%ebx),%eax
801001b3:	50                   	push   %eax
801001b4:	e8 56 3c 00 00       	call   80103e0f <holdingsleep>
801001b9:	83 c4 10             	add    $0x10,%esp
801001bc:	85 c0                	test   %eax,%eax
801001be:	74 14                	je     801001d4 <bwrite+0x32>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001c0:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001c3:	83 ec 0c             	sub    $0xc,%esp
801001c6:	53                   	push   %ebx
801001c7:	e8 fa 1c 00 00       	call   80101ec6 <iderw>
}
801001cc:	83 c4 10             	add    $0x10,%esp
801001cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001d2:	c9                   	leave  
801001d3:	c3                   	ret    
    panic("bwrite");
801001d4:	83 ec 0c             	sub    $0xc,%esp
801001d7:	68 ff 69 10 80       	push   $0x801069ff
801001dc:	e8 7b 01 00 00       	call   8010035c <panic>

801001e1 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001e1:	f3 0f 1e fb          	endbr32 
801001e5:	55                   	push   %ebp
801001e6:	89 e5                	mov    %esp,%ebp
801001e8:	56                   	push   %esi
801001e9:	53                   	push   %ebx
801001ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001ed:	8d 73 0c             	lea    0xc(%ebx),%esi
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 16 3c 00 00       	call   80103e0f <holdingsleep>
801001f9:	83 c4 10             	add    $0x10,%esp
801001fc:	85 c0                	test   %eax,%eax
801001fe:	74 6b                	je     8010026b <brelse+0x8a>
    panic("brelse");

  releasesleep(&b->lock);
80100200:	83 ec 0c             	sub    $0xc,%esp
80100203:	56                   	push   %esi
80100204:	e8 c7 3b 00 00       	call   80103dd0 <releasesleep>

  acquire(&bcache.lock);
80100209:	c7 04 24 20 da 10 80 	movl   $0x8010da20,(%esp)
80100210:	e8 75 3d 00 00       	call   80103f8a <acquire>
  b->refcnt--;
80100215:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100218:	83 e8 01             	sub    $0x1,%eax
8010021b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010021e:	83 c4 10             	add    $0x10,%esp
80100221:	85 c0                	test   %eax,%eax
80100223:	75 2f                	jne    80100254 <brelse+0x73>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100225:	8b 43 54             	mov    0x54(%ebx),%eax
80100228:	8b 53 50             	mov    0x50(%ebx),%edx
8010022b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010022e:	8b 43 50             	mov    0x50(%ebx),%eax
80100231:	8b 53 54             	mov    0x54(%ebx),%edx
80100234:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100237:	a1 70 21 11 80       	mov    0x80112170,%eax
8010023c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010023f:	c7 43 50 1c 21 11 80 	movl   $0x8011211c,0x50(%ebx)
    bcache.head.next->prev = b;
80100246:	a1 70 21 11 80       	mov    0x80112170,%eax
8010024b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010024e:	89 1d 70 21 11 80    	mov    %ebx,0x80112170
  }
  
  release(&bcache.lock);
80100254:	83 ec 0c             	sub    $0xc,%esp
80100257:	68 20 da 10 80       	push   $0x8010da20
8010025c:	e8 92 3d 00 00       	call   80103ff3 <release>
}
80100261:	83 c4 10             	add    $0x10,%esp
80100264:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100267:	5b                   	pop    %ebx
80100268:	5e                   	pop    %esi
80100269:	5d                   	pop    %ebp
8010026a:	c3                   	ret    
    panic("brelse");
8010026b:	83 ec 0c             	sub    $0xc,%esp
8010026e:	68 06 6a 10 80       	push   $0x80106a06
80100273:	e8 e4 00 00 00       	call   8010035c <panic>

80100278 <consoleread>:
#endif
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100278:	f3 0f 1e fb          	endbr32 
8010027c:	55                   	push   %ebp
8010027d:	89 e5                	mov    %esp,%ebp
8010027f:	57                   	push   %edi
80100280:	56                   	push   %esi
80100281:	53                   	push   %ebx
80100282:	83 ec 28             	sub    $0x28,%esp
80100285:	8b 7d 08             	mov    0x8(%ebp),%edi
80100288:	8b 75 0c             	mov    0xc(%ebp),%esi
8010028b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010028e:	57                   	push   %edi
8010028f:	e8 39 14 00 00       	call   801016cd <iunlock>
  target = n;
80100294:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100297:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010029e:	e8 e7 3c 00 00       	call   80103f8a <acquire>
  while(n > 0){
801002a3:	83 c4 10             	add    $0x10,%esp
801002a6:	85 db                	test   %ebx,%ebx
801002a8:	0f 8e 8f 00 00 00    	jle    8010033d <consoleread+0xc5>
    while(input.r == input.w){
801002ae:	a1 00 24 11 80       	mov    0x80112400,%eax
801002b3:	3b 05 04 24 11 80    	cmp    0x80112404,%eax
801002b9:	75 47                	jne    80100302 <consoleread+0x8a>
      if(myproc()->killed){
801002bb:	e8 78 30 00 00       	call   80103338 <myproc>
801002c0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002c4:	75 17                	jne    801002dd <consoleread+0x65>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002c6:	83 ec 08             	sub    $0x8,%esp
801002c9:	68 20 a5 10 80       	push   $0x8010a520
801002ce:	68 00 24 11 80       	push   $0x80112400
801002d3:	e8 95 35 00 00       	call   8010386d <sleep>
801002d8:	83 c4 10             	add    $0x10,%esp
801002db:	eb d1                	jmp    801002ae <consoleread+0x36>
        release(&cons.lock);
801002dd:	83 ec 0c             	sub    $0xc,%esp
801002e0:	68 20 a5 10 80       	push   $0x8010a520
801002e5:	e8 09 3d 00 00       	call   80103ff3 <release>
        ilock(ip);
801002ea:	89 3c 24             	mov    %edi,(%esp)
801002ed:	e8 15 13 00 00       	call   80101607 <ilock>
        return -1;
801002f2:	83 c4 10             	add    $0x10,%esp
801002f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002fd:	5b                   	pop    %ebx
801002fe:	5e                   	pop    %esi
801002ff:	5f                   	pop    %edi
80100300:	5d                   	pop    %ebp
80100301:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
80100302:	8d 50 01             	lea    0x1(%eax),%edx
80100305:	89 15 00 24 11 80    	mov    %edx,0x80112400
8010030b:	89 c2                	mov    %eax,%edx
8010030d:	83 e2 7f             	and    $0x7f,%edx
80100310:	0f b6 92 80 23 11 80 	movzbl -0x7feedc80(%edx),%edx
80100317:	0f be ca             	movsbl %dl,%ecx
    if(c == C('D')){  // EOF
8010031a:	80 fa 04             	cmp    $0x4,%dl
8010031d:	74 14                	je     80100333 <consoleread+0xbb>
    *dst++ = c;
8010031f:	8d 46 01             	lea    0x1(%esi),%eax
80100322:	88 16                	mov    %dl,(%esi)
    --n;
80100324:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100327:	83 f9 0a             	cmp    $0xa,%ecx
8010032a:	74 11                	je     8010033d <consoleread+0xc5>
    *dst++ = c;
8010032c:	89 c6                	mov    %eax,%esi
8010032e:	e9 73 ff ff ff       	jmp    801002a6 <consoleread+0x2e>
      if(n < target){
80100333:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100336:	73 05                	jae    8010033d <consoleread+0xc5>
        input.r--;
80100338:	a3 00 24 11 80       	mov    %eax,0x80112400
  release(&cons.lock);
8010033d:	83 ec 0c             	sub    $0xc,%esp
80100340:	68 20 a5 10 80       	push   $0x8010a520
80100345:	e8 a9 3c 00 00       	call   80103ff3 <release>
  ilock(ip);
8010034a:	89 3c 24             	mov    %edi,(%esp)
8010034d:	e8 b5 12 00 00       	call   80101607 <ilock>
  return target - n;
80100352:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100355:	29 d8                	sub    %ebx,%eax
80100357:	83 c4 10             	add    $0x10,%esp
8010035a:	eb 9e                	jmp    801002fa <consoleread+0x82>

8010035c <panic>:
{
8010035c:	f3 0f 1e fb          	endbr32 
80100360:	55                   	push   %ebp
80100361:	89 e5                	mov    %esp,%ebp
80100363:	53                   	push   %ebx
80100364:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
80100367:	fa                   	cli    
  cons.locking = 0;
80100368:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
8010036f:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
80100372:	e8 df 20 00 00       	call   80102456 <lapicid>
80100377:	83 ec 08             	sub    $0x8,%esp
8010037a:	50                   	push   %eax
8010037b:	68 0d 6a 10 80       	push   $0x80106a0d
80100380:	e8 a4 02 00 00       	call   80100629 <cprintf>
  cprintf(s);
80100385:	83 c4 04             	add    $0x4,%esp
80100388:	ff 75 08             	pushl  0x8(%ebp)
8010038b:	e8 99 02 00 00       	call   80100629 <cprintf>
  cprintf("\n");
80100390:	c7 04 24 b3 73 10 80 	movl   $0x801073b3,(%esp)
80100397:	e8 8d 02 00 00       	call   80100629 <cprintf>
  getcallerpcs(&s, pcs);
8010039c:	83 c4 08             	add    $0x8,%esp
8010039f:	8d 45 d0             	lea    -0x30(%ebp),%eax
801003a2:	50                   	push   %eax
801003a3:	8d 45 08             	lea    0x8(%ebp),%eax
801003a6:	50                   	push   %eax
801003a7:	e8 ad 3a 00 00       	call   80103e59 <getcallerpcs>
  for(i=0; i<10; i++)
801003ac:	83 c4 10             	add    $0x10,%esp
801003af:	bb 00 00 00 00       	mov    $0x0,%ebx
801003b4:	eb 17                	jmp    801003cd <panic+0x71>
    cprintf(" %p", pcs[i]);
801003b6:	83 ec 08             	sub    $0x8,%esp
801003b9:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003bd:	68 21 6a 10 80       	push   $0x80106a21
801003c2:	e8 62 02 00 00       	call   80100629 <cprintf>
  for(i=0; i<10; i++)
801003c7:	83 c3 01             	add    $0x1,%ebx
801003ca:	83 c4 10             	add    $0x10,%esp
801003cd:	83 fb 09             	cmp    $0x9,%ebx
801003d0:	7e e4                	jle    801003b6 <panic+0x5a>
  panicked = 1; // freeze other CPU
801003d2:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
801003d9:	00 00 00 
  for(;;)
801003dc:	eb fe                	jmp    801003dc <panic+0x80>

801003de <cgaputc>:
{
801003de:	55                   	push   %ebp
801003df:	89 e5                	mov    %esp,%ebp
801003e1:	57                   	push   %edi
801003e2:	56                   	push   %esi
801003e3:	53                   	push   %ebx
801003e4:	83 ec 0c             	sub    $0xc,%esp
801003e7:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003e9:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
801003f3:	89 ca                	mov    %ecx,%edx
801003f5:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f6:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003fb:	89 da                	mov    %ebx,%edx
801003fd:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003fe:	0f b6 f8             	movzbl %al,%edi
80100401:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100404:	b8 0f 00 00 00       	mov    $0xf,%eax
80100409:	89 ca                	mov    %ecx,%edx
8010040b:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010040c:	89 da                	mov    %ebx,%edx
8010040e:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
8010040f:	0f b6 c8             	movzbl %al,%ecx
80100412:	09 f9                	or     %edi,%ecx
  if(c == '\n')
80100414:	83 fe 0a             	cmp    $0xa,%esi
80100417:	74 66                	je     8010047f <cgaputc+0xa1>
  else if(c == BACKSPACE){
80100419:	81 fe 00 01 00 00    	cmp    $0x100,%esi
8010041f:	74 7f                	je     801004a0 <cgaputc+0xc2>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
80100421:	89 f0                	mov    %esi,%eax
80100423:	0f b6 f0             	movzbl %al,%esi
80100426:	8d 59 01             	lea    0x1(%ecx),%ebx
80100429:	66 81 ce 00 07       	or     $0x700,%si
8010042e:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100435:	80 
  if(pos < 0 || pos > 25*80)
80100436:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
8010043c:	77 6f                	ja     801004ad <cgaputc+0xcf>
  if((pos/80) >= 24){  // Scroll up.
8010043e:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100444:	7f 74                	jg     801004ba <cgaputc+0xdc>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100446:	be d4 03 00 00       	mov    $0x3d4,%esi
8010044b:	b8 0e 00 00 00       	mov    $0xe,%eax
80100450:	89 f2                	mov    %esi,%edx
80100452:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
80100453:	89 d8                	mov    %ebx,%eax
80100455:	c1 f8 08             	sar    $0x8,%eax
80100458:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
8010045d:	89 ca                	mov    %ecx,%edx
8010045f:	ee                   	out    %al,(%dx)
80100460:	b8 0f 00 00 00       	mov    $0xf,%eax
80100465:	89 f2                	mov    %esi,%edx
80100467:	ee                   	out    %al,(%dx)
80100468:	89 d8                	mov    %ebx,%eax
8010046a:	89 ca                	mov    %ecx,%edx
8010046c:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
8010046d:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100474:	80 20 07 
}
80100477:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010047a:	5b                   	pop    %ebx
8010047b:	5e                   	pop    %esi
8010047c:	5f                   	pop    %edi
8010047d:	5d                   	pop    %ebp
8010047e:	c3                   	ret    
    pos += 80 - pos%80;
8010047f:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100484:	89 c8                	mov    %ecx,%eax
80100486:	f7 ea                	imul   %edx
80100488:	c1 fa 05             	sar    $0x5,%edx
8010048b:	8d 04 92             	lea    (%edx,%edx,4),%eax
8010048e:	c1 e0 04             	shl    $0x4,%eax
80100491:	89 ca                	mov    %ecx,%edx
80100493:	29 c2                	sub    %eax,%edx
80100495:	bb 50 00 00 00       	mov    $0x50,%ebx
8010049a:	29 d3                	sub    %edx,%ebx
8010049c:	01 cb                	add    %ecx,%ebx
8010049e:	eb 96                	jmp    80100436 <cgaputc+0x58>
    if(pos > 0) --pos;
801004a0:	85 c9                	test   %ecx,%ecx
801004a2:	7e 05                	jle    801004a9 <cgaputc+0xcb>
801004a4:	8d 59 ff             	lea    -0x1(%ecx),%ebx
801004a7:	eb 8d                	jmp    80100436 <cgaputc+0x58>
  pos |= inb(CRTPORT+1);
801004a9:	89 cb                	mov    %ecx,%ebx
801004ab:	eb 89                	jmp    80100436 <cgaputc+0x58>
    panic("pos under/overflow");
801004ad:	83 ec 0c             	sub    $0xc,%esp
801004b0:	68 25 6a 10 80       	push   $0x80106a25
801004b5:	e8 a2 fe ff ff       	call   8010035c <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004ba:	83 ec 04             	sub    $0x4,%esp
801004bd:	68 60 0e 00 00       	push   $0xe60
801004c2:	68 a0 80 0b 80       	push   $0x800b80a0
801004c7:	68 00 80 0b 80       	push   $0x800b8000
801004cc:	e8 ed 3b 00 00       	call   801040be <memmove>
    pos -= 80;
801004d1:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004d4:	b8 80 07 00 00       	mov    $0x780,%eax
801004d9:	29 d8                	sub    %ebx,%eax
801004db:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004e2:	83 c4 0c             	add    $0xc,%esp
801004e5:	01 c0                	add    %eax,%eax
801004e7:	50                   	push   %eax
801004e8:	6a 00                	push   $0x0
801004ea:	52                   	push   %edx
801004eb:	e8 4e 3b 00 00       	call   8010403e <memset>
801004f0:	83 c4 10             	add    $0x10,%esp
801004f3:	e9 4e ff ff ff       	jmp    80100446 <cgaputc+0x68>

801004f8 <consputc>:
  if(panicked){
801004f8:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
801004ff:	74 03                	je     80100504 <consputc+0xc>
  asm volatile("cli");
80100501:	fa                   	cli    
    for(;;)
80100502:	eb fe                	jmp    80100502 <consputc+0xa>
{
80100504:	55                   	push   %ebp
80100505:	89 e5                	mov    %esp,%ebp
80100507:	53                   	push   %ebx
80100508:	83 ec 04             	sub    $0x4,%esp
8010050b:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
8010050d:	3d 00 01 00 00       	cmp    $0x100,%eax
80100512:	74 18                	je     8010052c <consputc+0x34>
    uartputc(c);
80100514:	83 ec 0c             	sub    $0xc,%esp
80100517:	50                   	push   %eax
80100518:	e8 84 50 00 00       	call   801055a1 <uartputc>
8010051d:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
80100520:	89 d8                	mov    %ebx,%eax
80100522:	e8 b7 fe ff ff       	call   801003de <cgaputc>
}
80100527:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010052a:	c9                   	leave  
8010052b:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010052c:	83 ec 0c             	sub    $0xc,%esp
8010052f:	6a 08                	push   $0x8
80100531:	e8 6b 50 00 00       	call   801055a1 <uartputc>
80100536:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010053d:	e8 5f 50 00 00       	call   801055a1 <uartputc>
80100542:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100549:	e8 53 50 00 00       	call   801055a1 <uartputc>
8010054e:	83 c4 10             	add    $0x10,%esp
80100551:	eb cd                	jmp    80100520 <consputc+0x28>

80100553 <printint>:
{
80100553:	55                   	push   %ebp
80100554:	89 e5                	mov    %esp,%ebp
80100556:	57                   	push   %edi
80100557:	56                   	push   %esi
80100558:	53                   	push   %ebx
80100559:	83 ec 2c             	sub    $0x2c,%esp
8010055c:	89 d6                	mov    %edx,%esi
8010055e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  if(sign && (sign = xx < 0))
80100561:	85 c9                	test   %ecx,%ecx
80100563:	74 0c                	je     80100571 <printint+0x1e>
80100565:	89 c7                	mov    %eax,%edi
80100567:	c1 ef 1f             	shr    $0x1f,%edi
8010056a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
8010056d:	85 c0                	test   %eax,%eax
8010056f:	78 38                	js     801005a9 <printint+0x56>
    x = xx;
80100571:	89 c1                	mov    %eax,%ecx
  i = 0;
80100573:	bb 00 00 00 00       	mov    $0x0,%ebx
    buf[i++] = digits[x % base];
80100578:	89 c8                	mov    %ecx,%eax
8010057a:	ba 00 00 00 00       	mov    $0x0,%edx
8010057f:	f7 f6                	div    %esi
80100581:	89 df                	mov    %ebx,%edi
80100583:	83 c3 01             	add    $0x1,%ebx
80100586:	0f b6 92 64 6a 10 80 	movzbl -0x7fef959c(%edx),%edx
8010058d:	88 54 3d d8          	mov    %dl,-0x28(%ebp,%edi,1)
  }while((x /= base) != 0);
80100591:	89 ca                	mov    %ecx,%edx
80100593:	89 c1                	mov    %eax,%ecx
80100595:	39 d6                	cmp    %edx,%esi
80100597:	76 df                	jbe    80100578 <printint+0x25>
  if(sign)
80100599:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
8010059d:	74 1a                	je     801005b9 <printint+0x66>
    buf[i++] = '-';
8010059f:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
801005a4:	8d 5f 02             	lea    0x2(%edi),%ebx
801005a7:	eb 10                	jmp    801005b9 <printint+0x66>
    x = -xx;
801005a9:	f7 d8                	neg    %eax
801005ab:	89 c1                	mov    %eax,%ecx
801005ad:	eb c4                	jmp    80100573 <printint+0x20>
    consputc(buf[i]);
801005af:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
801005b4:	e8 3f ff ff ff       	call   801004f8 <consputc>
  while(--i >= 0)
801005b9:	83 eb 01             	sub    $0x1,%ebx
801005bc:	79 f1                	jns    801005af <printint+0x5c>
}
801005be:	83 c4 2c             	add    $0x2c,%esp
801005c1:	5b                   	pop    %ebx
801005c2:	5e                   	pop    %esi
801005c3:	5f                   	pop    %edi
801005c4:	5d                   	pop    %ebp
801005c5:	c3                   	ret    

801005c6 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005c6:	f3 0f 1e fb          	endbr32 
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	57                   	push   %edi
801005ce:	56                   	push   %esi
801005cf:	53                   	push   %ebx
801005d0:	83 ec 18             	sub    $0x18,%esp
801005d3:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005d6:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005d9:	ff 75 08             	pushl  0x8(%ebp)
801005dc:	e8 ec 10 00 00       	call   801016cd <iunlock>
  acquire(&cons.lock);
801005e1:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005e8:	e8 9d 39 00 00       	call   80103f8a <acquire>
  for(i = 0; i < n; i++)
801005ed:	83 c4 10             	add    $0x10,%esp
801005f0:	bb 00 00 00 00       	mov    $0x0,%ebx
801005f5:	39 f3                	cmp    %esi,%ebx
801005f7:	7d 0e                	jge    80100607 <consolewrite+0x41>
    consputc(buf[i] & 0xff);
801005f9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005fd:	e8 f6 fe ff ff       	call   801004f8 <consputc>
  for(i = 0; i < n; i++)
80100602:	83 c3 01             	add    $0x1,%ebx
80100605:	eb ee                	jmp    801005f5 <consolewrite+0x2f>
  release(&cons.lock);
80100607:	83 ec 0c             	sub    $0xc,%esp
8010060a:	68 20 a5 10 80       	push   $0x8010a520
8010060f:	e8 df 39 00 00       	call   80103ff3 <release>
  ilock(ip);
80100614:	83 c4 04             	add    $0x4,%esp
80100617:	ff 75 08             	pushl  0x8(%ebp)
8010061a:	e8 e8 0f 00 00       	call   80101607 <ilock>

  return n;
}
8010061f:	89 f0                	mov    %esi,%eax
80100621:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100624:	5b                   	pop    %ebx
80100625:	5e                   	pop    %esi
80100626:	5f                   	pop    %edi
80100627:	5d                   	pop    %ebp
80100628:	c3                   	ret    

80100629 <cprintf>:
{
80100629:	f3 0f 1e fb          	endbr32 
8010062d:	55                   	push   %ebp
8010062e:	89 e5                	mov    %esp,%ebp
80100630:	57                   	push   %edi
80100631:	56                   	push   %esi
80100632:	53                   	push   %ebx
80100633:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100636:	a1 54 a5 10 80       	mov    0x8010a554,%eax
8010063b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(locking)
8010063e:	85 c0                	test   %eax,%eax
80100640:	75 10                	jne    80100652 <cprintf+0x29>
  if (fmt == 0)
80100642:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100646:	74 1c                	je     80100664 <cprintf+0x3b>
  argp = (uint*)(void*)(&fmt + 1);
80100648:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010064b:	be 00 00 00 00       	mov    $0x0,%esi
80100650:	eb 27                	jmp    80100679 <cprintf+0x50>
    acquire(&cons.lock);
80100652:	83 ec 0c             	sub    $0xc,%esp
80100655:	68 20 a5 10 80       	push   $0x8010a520
8010065a:	e8 2b 39 00 00       	call   80103f8a <acquire>
8010065f:	83 c4 10             	add    $0x10,%esp
80100662:	eb de                	jmp    80100642 <cprintf+0x19>
    panic("null fmt");
80100664:	83 ec 0c             	sub    $0xc,%esp
80100667:	68 3f 6a 10 80       	push   $0x80106a3f
8010066c:	e8 eb fc ff ff       	call   8010035c <panic>
      consputc(c);
80100671:	e8 82 fe ff ff       	call   801004f8 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100676:	83 c6 01             	add    $0x1,%esi
80100679:	8b 55 08             	mov    0x8(%ebp),%edx
8010067c:	0f b6 04 32          	movzbl (%edx,%esi,1),%eax
80100680:	85 c0                	test   %eax,%eax
80100682:	0f 84 b1 00 00 00    	je     80100739 <cprintf+0x110>
    if(c != '%'){
80100688:	83 f8 25             	cmp    $0x25,%eax
8010068b:	75 e4                	jne    80100671 <cprintf+0x48>
    c = fmt[++i] & 0xff;
8010068d:	83 c6 01             	add    $0x1,%esi
80100690:	0f b6 1c 32          	movzbl (%edx,%esi,1),%ebx
    if(c == 0)
80100694:	85 db                	test   %ebx,%ebx
80100696:	0f 84 9d 00 00 00    	je     80100739 <cprintf+0x110>
    switch(c){
8010069c:	83 fb 70             	cmp    $0x70,%ebx
8010069f:	74 2e                	je     801006cf <cprintf+0xa6>
801006a1:	7f 22                	jg     801006c5 <cprintf+0x9c>
801006a3:	83 fb 25             	cmp    $0x25,%ebx
801006a6:	74 6c                	je     80100714 <cprintf+0xeb>
801006a8:	83 fb 64             	cmp    $0x64,%ebx
801006ab:	75 76                	jne    80100723 <cprintf+0xfa>
      printint(*argp++, 10, 1);
801006ad:	8d 5f 04             	lea    0x4(%edi),%ebx
801006b0:	8b 07                	mov    (%edi),%eax
801006b2:	b9 01 00 00 00       	mov    $0x1,%ecx
801006b7:	ba 0a 00 00 00       	mov    $0xa,%edx
801006bc:	e8 92 fe ff ff       	call   80100553 <printint>
801006c1:	89 df                	mov    %ebx,%edi
      break;
801006c3:	eb b1                	jmp    80100676 <cprintf+0x4d>
    switch(c){
801006c5:	83 fb 73             	cmp    $0x73,%ebx
801006c8:	74 1d                	je     801006e7 <cprintf+0xbe>
801006ca:	83 fb 78             	cmp    $0x78,%ebx
801006cd:	75 54                	jne    80100723 <cprintf+0xfa>
      printint(*argp++, 16, 0);
801006cf:	8d 5f 04             	lea    0x4(%edi),%ebx
801006d2:	8b 07                	mov    (%edi),%eax
801006d4:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d9:	ba 10 00 00 00       	mov    $0x10,%edx
801006de:	e8 70 fe ff ff       	call   80100553 <printint>
801006e3:	89 df                	mov    %ebx,%edi
      break;
801006e5:	eb 8f                	jmp    80100676 <cprintf+0x4d>
      if((s = (char*)*argp++) == 0)
801006e7:	8d 47 04             	lea    0x4(%edi),%eax
801006ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801006ed:	8b 1f                	mov    (%edi),%ebx
801006ef:	85 db                	test   %ebx,%ebx
801006f1:	75 05                	jne    801006f8 <cprintf+0xcf>
        s = "(null)";
801006f3:	bb 38 6a 10 80       	mov    $0x80106a38,%ebx
      for(; *s; s++)
801006f8:	0f b6 03             	movzbl (%ebx),%eax
801006fb:	84 c0                	test   %al,%al
801006fd:	74 0d                	je     8010070c <cprintf+0xe3>
        consputc(*s);
801006ff:	0f be c0             	movsbl %al,%eax
80100702:	e8 f1 fd ff ff       	call   801004f8 <consputc>
      for(; *s; s++)
80100707:	83 c3 01             	add    $0x1,%ebx
8010070a:	eb ec                	jmp    801006f8 <cprintf+0xcf>
      if((s = (char*)*argp++) == 0)
8010070c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010070f:	e9 62 ff ff ff       	jmp    80100676 <cprintf+0x4d>
      consputc('%');
80100714:	b8 25 00 00 00       	mov    $0x25,%eax
80100719:	e8 da fd ff ff       	call   801004f8 <consputc>
      break;
8010071e:	e9 53 ff ff ff       	jmp    80100676 <cprintf+0x4d>
      consputc('%');
80100723:	b8 25 00 00 00       	mov    $0x25,%eax
80100728:	e8 cb fd ff ff       	call   801004f8 <consputc>
      consputc(c);
8010072d:	89 d8                	mov    %ebx,%eax
8010072f:	e8 c4 fd ff ff       	call   801004f8 <consputc>
      break;
80100734:	e9 3d ff ff ff       	jmp    80100676 <cprintf+0x4d>
  if(locking)
80100739:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010073d:	75 08                	jne    80100747 <cprintf+0x11e>
}
8010073f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100742:	5b                   	pop    %ebx
80100743:	5e                   	pop    %esi
80100744:	5f                   	pop    %edi
80100745:	5d                   	pop    %ebp
80100746:	c3                   	ret    
    release(&cons.lock);
80100747:	83 ec 0c             	sub    $0xc,%esp
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 9f 38 00 00       	call   80103ff3 <release>
80100754:	83 c4 10             	add    $0x10,%esp
}
80100757:	eb e6                	jmp    8010073f <cprintf+0x116>

80100759 <do_shutdown>:
{
80100759:	f3 0f 1e fb          	endbr32 
8010075d:	55                   	push   %ebp
8010075e:	89 e5                	mov    %esp,%ebp
80100760:	83 ec 14             	sub    $0x14,%esp
  cprintf("\nShutting down ...\n");
80100763:	68 48 6a 10 80       	push   $0x80106a48
80100768:	e8 bc fe ff ff       	call   80100629 <cprintf>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010076d:	b8 00 20 00 00       	mov    $0x2000,%eax
80100772:	ba 04 06 00 00       	mov    $0x604,%edx
80100777:	66 ef                	out    %ax,(%dx)
  return;  // not reached
80100779:	83 c4 10             	add    $0x10,%esp
}
8010077c:	c9                   	leave  
8010077d:	c3                   	ret    

8010077e <consoleintr>:
{
8010077e:	f3 0f 1e fb          	endbr32 
80100782:	55                   	push   %ebp
80100783:	89 e5                	mov    %esp,%ebp
80100785:	57                   	push   %edi
80100786:	56                   	push   %esi
80100787:	53                   	push   %ebx
80100788:	83 ec 28             	sub    $0x28,%esp
8010078b:	8b 75 08             	mov    0x8(%ebp),%esi
  acquire(&cons.lock);
8010078e:	68 20 a5 10 80       	push   $0x8010a520
80100793:	e8 f2 37 00 00       	call   80103f8a <acquire>
  while((c = getc()) >= 0){
80100798:	83 c4 10             	add    $0x10,%esp
  int shutdown = FALSE;
8010079b:	bf 00 00 00 00       	mov    $0x0,%edi
  int c, doprocdump = 0;
801007a0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  while((c = getc()) >= 0){
801007a7:	e9 d5 00 00 00       	jmp    80100881 <consoleintr+0x103>
    switch(c){
801007ac:	83 fb 15             	cmp    $0x15,%ebx
801007af:	0f 84 94 00 00 00    	je     80100849 <consoleintr+0xcb>
801007b5:	83 fb 7f             	cmp    $0x7f,%ebx
801007b8:	0f 84 e4 00 00 00    	je     801008a2 <consoleintr+0x124>
      if(c != 0 && input.e-input.r < INPUT_BUF){
801007be:	85 db                	test   %ebx,%ebx
801007c0:	0f 84 bb 00 00 00    	je     80100881 <consoleintr+0x103>
801007c6:	a1 08 24 11 80       	mov    0x80112408,%eax
801007cb:	89 c2                	mov    %eax,%edx
801007cd:	2b 15 00 24 11 80    	sub    0x80112400,%edx
801007d3:	83 fa 7f             	cmp    $0x7f,%edx
801007d6:	0f 87 a5 00 00 00    	ja     80100881 <consoleintr+0x103>
        c = (c == '\r') ? '\n' : c;
801007dc:	83 fb 0d             	cmp    $0xd,%ebx
801007df:	0f 84 84 00 00 00    	je     80100869 <consoleintr+0xeb>
        input.buf[input.e++ % INPUT_BUF] = c;
801007e5:	8d 50 01             	lea    0x1(%eax),%edx
801007e8:	89 15 08 24 11 80    	mov    %edx,0x80112408
801007ee:	83 e0 7f             	and    $0x7f,%eax
801007f1:	88 98 80 23 11 80    	mov    %bl,-0x7feedc80(%eax)
        consputc(c);
801007f7:	89 d8                	mov    %ebx,%eax
801007f9:	e8 fa fc ff ff       	call   801004f8 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007fe:	83 fb 0a             	cmp    $0xa,%ebx
80100801:	0f 94 c2             	sete   %dl
80100804:	83 fb 04             	cmp    $0x4,%ebx
80100807:	0f 94 c0             	sete   %al
8010080a:	08 c2                	or     %al,%dl
8010080c:	75 10                	jne    8010081e <consoleintr+0xa0>
8010080e:	a1 00 24 11 80       	mov    0x80112400,%eax
80100813:	83 e8 80             	sub    $0xffffff80,%eax
80100816:	39 05 08 24 11 80    	cmp    %eax,0x80112408
8010081c:	75 63                	jne    80100881 <consoleintr+0x103>
          input.w = input.e;
8010081e:	a1 08 24 11 80       	mov    0x80112408,%eax
80100823:	a3 04 24 11 80       	mov    %eax,0x80112404
          wakeup(&input.r);
80100828:	83 ec 0c             	sub    $0xc,%esp
8010082b:	68 00 24 11 80       	push   $0x80112400
80100830:	e8 a7 31 00 00       	call   801039dc <wakeup>
80100835:	83 c4 10             	add    $0x10,%esp
80100838:	eb 47                	jmp    80100881 <consoleintr+0x103>
        input.e--;
8010083a:	a3 08 24 11 80       	mov    %eax,0x80112408
        consputc(BACKSPACE);
8010083f:	b8 00 01 00 00       	mov    $0x100,%eax
80100844:	e8 af fc ff ff       	call   801004f8 <consputc>
      while(input.e != input.w &&
80100849:	a1 08 24 11 80       	mov    0x80112408,%eax
8010084e:	3b 05 04 24 11 80    	cmp    0x80112404,%eax
80100854:	74 2b                	je     80100881 <consoleintr+0x103>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	89 c2                	mov    %eax,%edx
8010085b:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010085e:	80 ba 80 23 11 80 0a 	cmpb   $0xa,-0x7feedc80(%edx)
80100865:	75 d3                	jne    8010083a <consoleintr+0xbc>
80100867:	eb 18                	jmp    80100881 <consoleintr+0x103>
        c = (c == '\r') ? '\n' : c;
80100869:	bb 0a 00 00 00       	mov    $0xa,%ebx
8010086e:	e9 72 ff ff ff       	jmp    801007e5 <consoleintr+0x67>
    switch(c){
80100873:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
8010087a:	eb 05                	jmp    80100881 <consoleintr+0x103>
      shutdown = TRUE;
8010087c:	bf 01 00 00 00       	mov    $0x1,%edi
  while((c = getc()) >= 0){
80100881:	ff d6                	call   *%esi
80100883:	89 c3                	mov    %eax,%ebx
80100885:	85 c0                	test   %eax,%eax
80100887:	78 3a                	js     801008c3 <consoleintr+0x145>
    switch(c){
80100889:	83 fb 10             	cmp    $0x10,%ebx
8010088c:	74 e5                	je     80100873 <consoleintr+0xf5>
8010088e:	0f 8f 18 ff ff ff    	jg     801007ac <consoleintr+0x2e>
80100894:	83 fb 04             	cmp    $0x4,%ebx
80100897:	74 e3                	je     8010087c <consoleintr+0xfe>
80100899:	83 fb 08             	cmp    $0x8,%ebx
8010089c:	0f 85 1c ff ff ff    	jne    801007be <consoleintr+0x40>
      if(input.e != input.w){
801008a2:	a1 08 24 11 80       	mov    0x80112408,%eax
801008a7:	3b 05 04 24 11 80    	cmp    0x80112404,%eax
801008ad:	74 d2                	je     80100881 <consoleintr+0x103>
        input.e--;
801008af:	83 e8 01             	sub    $0x1,%eax
801008b2:	a3 08 24 11 80       	mov    %eax,0x80112408
        consputc(BACKSPACE);
801008b7:	b8 00 01 00 00       	mov    $0x100,%eax
801008bc:	e8 37 fc ff ff       	call   801004f8 <consputc>
801008c1:	eb be                	jmp    80100881 <consoleintr+0x103>
  release(&cons.lock);
801008c3:	83 ec 0c             	sub    $0xc,%esp
801008c6:	68 20 a5 10 80       	push   $0x8010a520
801008cb:	e8 23 37 00 00       	call   80103ff3 <release>
  if (shutdown)
801008d0:	83 c4 10             	add    $0x10,%esp
801008d3:	85 ff                	test   %edi,%edi
801008d5:	75 0e                	jne    801008e5 <consoleintr+0x167>
  if(doprocdump) {
801008d7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801008db:	75 0f                	jne    801008ec <consoleintr+0x16e>
}
801008dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801008e0:	5b                   	pop    %ebx
801008e1:	5e                   	pop    %esi
801008e2:	5f                   	pop    %edi
801008e3:	5d                   	pop    %ebp
801008e4:	c3                   	ret    
    do_shutdown();
801008e5:	e8 6f fe ff ff       	call   80100759 <do_shutdown>
801008ea:	eb eb                	jmp    801008d7 <consoleintr+0x159>
    procdump();  // now call procdump() wo. cons.lock held
801008ec:	e8 70 32 00 00       	call   80103b61 <procdump>
}
801008f1:	eb ea                	jmp    801008dd <consoleintr+0x15f>

801008f3 <consoleinit>:

void
consoleinit(void)
{
801008f3:	f3 0f 1e fb          	endbr32 
801008f7:	55                   	push   %ebp
801008f8:	89 e5                	mov    %esp,%ebp
801008fa:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
801008fd:	68 5c 6a 10 80       	push   $0x80106a5c
80100902:	68 20 a5 10 80       	push   $0x8010a520
80100907:	e8 2e 35 00 00       	call   80103e3a <initlock>

  devsw[CONSOLE].write = consolewrite;
8010090c:	c7 05 cc 2d 11 80 c6 	movl   $0x801005c6,0x80112dcc
80100913:	05 10 80 
  devsw[CONSOLE].read = consoleread;
80100916:	c7 05 c8 2d 11 80 78 	movl   $0x80100278,0x80112dc8
8010091d:	02 10 80 
  cons.locking = 1;
80100920:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
80100927:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
8010092a:	83 c4 08             	add    $0x8,%esp
8010092d:	6a 00                	push   $0x0
8010092f:	6a 01                	push   $0x1
80100931:	e8 02 17 00 00       	call   80102038 <ioapicenable>
}
80100936:	83 c4 10             	add    $0x10,%esp
80100939:	c9                   	leave  
8010093a:	c3                   	ret    

8010093b <exec>:
#include "elf.h"


int
exec(char *path, char **argv)
{
8010093b:	f3 0f 1e fb          	endbr32 
8010093f:	55                   	push   %ebp
80100940:	89 e5                	mov    %esp,%ebp
80100942:	57                   	push   %edi
80100943:	56                   	push   %esi
80100944:	53                   	push   %ebx
80100945:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
8010094b:	e8 e8 29 00 00       	call   80103338 <myproc>
80100950:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)

  begin_op();
80100956:	e8 31 1f 00 00       	call   8010288c <begin_op>

  if((ip = namei(path)) == 0){
8010095b:	83 ec 0c             	sub    $0xc,%esp
8010095e:	ff 75 08             	pushl  0x8(%ebp)
80100961:	e8 26 13 00 00       	call   80101c8c <namei>
80100966:	83 c4 10             	add    $0x10,%esp
80100969:	85 c0                	test   %eax,%eax
8010096b:	74 56                	je     801009c3 <exec+0x88>
8010096d:	89 c3                	mov    %eax,%ebx
#ifndef PDX_XV6
    cprintf("exec: fail\n");
#endif
    return -1;
  }
  ilock(ip);
8010096f:	83 ec 0c             	sub    $0xc,%esp
80100972:	50                   	push   %eax
80100973:	e8 8f 0c 00 00       	call   80101607 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100978:	6a 34                	push   $0x34
8010097a:	6a 00                	push   $0x0
8010097c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100982:	50                   	push   %eax
80100983:	53                   	push   %ebx
80100984:	e8 84 0e 00 00       	call   8010180d <readi>
80100989:	83 c4 20             	add    $0x20,%esp
8010098c:	83 f8 34             	cmp    $0x34,%eax
8010098f:	75 0c                	jne    8010099d <exec+0x62>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100991:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
80100998:	45 4c 46 
8010099b:	74 32                	je     801009cf <exec+0x94>
  return 0;

bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
8010099d:	85 db                	test   %ebx,%ebx
8010099f:	0f 84 b9 02 00 00    	je     80100c5e <exec+0x323>
    iunlockput(ip);
801009a5:	83 ec 0c             	sub    $0xc,%esp
801009a8:	53                   	push   %ebx
801009a9:	e8 0c 0e 00 00       	call   801017ba <iunlockput>
    end_op();
801009ae:	e8 57 1f 00 00       	call   8010290a <end_op>
801009b3:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
801009b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801009bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801009be:	5b                   	pop    %ebx
801009bf:	5e                   	pop    %esi
801009c0:	5f                   	pop    %edi
801009c1:	5d                   	pop    %ebp
801009c2:	c3                   	ret    
    end_op();
801009c3:	e8 42 1f 00 00       	call   8010290a <end_op>
    return -1;
801009c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801009cd:	eb ec                	jmp    801009bb <exec+0x80>
  if((pgdir = setupkvm()) == 0)
801009cf:	e8 af 5d 00 00       	call   80106783 <setupkvm>
801009d4:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009da:	85 c0                	test   %eax,%eax
801009dc:	0f 84 09 01 00 00    	je     80100aeb <exec+0x1b0>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
801009e2:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
801009e8:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
801009ed:	be 00 00 00 00       	mov    $0x0,%esi
801009f2:	eb 0c                	jmp    80100a00 <exec+0xc5>
801009f4:	83 c6 01             	add    $0x1,%esi
801009f7:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
801009fd:	83 c0 20             	add    $0x20,%eax
80100a00:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
80100a07:	39 f2                	cmp    %esi,%edx
80100a09:	0f 8e 98 00 00 00    	jle    80100aa7 <exec+0x16c>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100a0f:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
80100a15:	6a 20                	push   $0x20
80100a17:	50                   	push   %eax
80100a18:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
80100a1e:	50                   	push   %eax
80100a1f:	53                   	push   %ebx
80100a20:	e8 e8 0d 00 00       	call   8010180d <readi>
80100a25:	83 c4 10             	add    $0x10,%esp
80100a28:	83 f8 20             	cmp    $0x20,%eax
80100a2b:	0f 85 ba 00 00 00    	jne    80100aeb <exec+0x1b0>
    if(ph.type != ELF_PROG_LOAD)
80100a31:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
80100a38:	75 ba                	jne    801009f4 <exec+0xb9>
    if(ph.memsz < ph.filesz)
80100a3a:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
80100a40:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
80100a46:	0f 82 9f 00 00 00    	jb     80100aeb <exec+0x1b0>
    if(ph.vaddr + ph.memsz < ph.vaddr)
80100a4c:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
80100a52:	0f 82 93 00 00 00    	jb     80100aeb <exec+0x1b0>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100a58:	83 ec 04             	sub    $0x4,%esp
80100a5b:	50                   	push   %eax
80100a5c:	57                   	push   %edi
80100a5d:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100a63:	e8 ba 5b 00 00       	call   80106622 <allocuvm>
80100a68:	89 c7                	mov    %eax,%edi
80100a6a:	83 c4 10             	add    $0x10,%esp
80100a6d:	85 c0                	test   %eax,%eax
80100a6f:	74 7a                	je     80100aeb <exec+0x1b0>
    if(ph.vaddr % PGSIZE != 0)
80100a71:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a77:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a7c:	75 6d                	jne    80100aeb <exec+0x1b0>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a7e:	83 ec 0c             	sub    $0xc,%esp
80100a81:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a87:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a8d:	53                   	push   %ebx
80100a8e:	50                   	push   %eax
80100a8f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100a95:	e8 53 5a 00 00       	call   801064ed <loaduvm>
80100a9a:	83 c4 20             	add    $0x20,%esp
80100a9d:	85 c0                	test   %eax,%eax
80100a9f:	0f 89 4f ff ff ff    	jns    801009f4 <exec+0xb9>
80100aa5:	eb 44                	jmp    80100aeb <exec+0x1b0>
  iunlockput(ip);
80100aa7:	83 ec 0c             	sub    $0xc,%esp
80100aaa:	53                   	push   %ebx
80100aab:	e8 0a 0d 00 00       	call   801017ba <iunlockput>
  end_op();
80100ab0:	e8 55 1e 00 00       	call   8010290a <end_op>
  sz = PGROUNDUP(sz);
80100ab5:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100abb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ac0:	83 c4 0c             	add    $0xc,%esp
80100ac3:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100ac9:	52                   	push   %edx
80100aca:	50                   	push   %eax
80100acb:	8b bd f0 fe ff ff    	mov    -0x110(%ebp),%edi
80100ad1:	57                   	push   %edi
80100ad2:	e8 4b 5b 00 00       	call   80106622 <allocuvm>
80100ad7:	89 c6                	mov    %eax,%esi
80100ad9:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
80100adf:	83 c4 10             	add    $0x10,%esp
80100ae2:	85 c0                	test   %eax,%eax
80100ae4:	75 24                	jne    80100b0a <exec+0x1cf>
  ip = 0;
80100ae6:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100aeb:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100af1:	85 c0                	test   %eax,%eax
80100af3:	0f 84 a4 fe ff ff    	je     8010099d <exec+0x62>
    freevm(pgdir);
80100af9:	83 ec 0c             	sub    $0xc,%esp
80100afc:	50                   	push   %eax
80100afd:	e8 0d 5c 00 00       	call   8010670f <freevm>
80100b02:	83 c4 10             	add    $0x10,%esp
80100b05:	e9 93 fe ff ff       	jmp    8010099d <exec+0x62>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100b0a:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100b10:	83 ec 08             	sub    $0x8,%esp
80100b13:	50                   	push   %eax
80100b14:	57                   	push   %edi
80100b15:	e8 f6 5c 00 00       	call   80106810 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100b1a:	83 c4 10             	add    $0x10,%esp
80100b1d:	bf 00 00 00 00       	mov    $0x0,%edi
80100b22:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b25:	8d 1c b8             	lea    (%eax,%edi,4),%ebx
80100b28:	8b 03                	mov    (%ebx),%eax
80100b2a:	85 c0                	test   %eax,%eax
80100b2c:	74 4d                	je     80100b7b <exec+0x240>
    if(argc >= MAXARG)
80100b2e:	83 ff 1f             	cmp    $0x1f,%edi
80100b31:	0f 87 13 01 00 00    	ja     80100c4a <exec+0x30f>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100b37:	83 ec 0c             	sub    $0xc,%esp
80100b3a:	50                   	push   %eax
80100b3b:	e8 bf 36 00 00       	call   801041ff <strlen>
80100b40:	29 c6                	sub    %eax,%esi
80100b42:	83 ee 01             	sub    $0x1,%esi
80100b45:	83 e6 fc             	and    $0xfffffffc,%esi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100b48:	83 c4 04             	add    $0x4,%esp
80100b4b:	ff 33                	pushl  (%ebx)
80100b4d:	e8 ad 36 00 00       	call   801041ff <strlen>
80100b52:	83 c0 01             	add    $0x1,%eax
80100b55:	50                   	push   %eax
80100b56:	ff 33                	pushl  (%ebx)
80100b58:	56                   	push   %esi
80100b59:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100b5f:	e8 fa 5d 00 00       	call   8010695e <copyout>
80100b64:	83 c4 20             	add    $0x20,%esp
80100b67:	85 c0                	test   %eax,%eax
80100b69:	0f 88 e5 00 00 00    	js     80100c54 <exec+0x319>
    ustack[3+argc] = sp;
80100b6f:	89 b4 bd 64 ff ff ff 	mov    %esi,-0x9c(%ebp,%edi,4)
  for(argc = 0; argv[argc]; argc++) {
80100b76:	83 c7 01             	add    $0x1,%edi
80100b79:	eb a7                	jmp    80100b22 <exec+0x1e7>
80100b7b:	89 f1                	mov    %esi,%ecx
80100b7d:	89 c3                	mov    %eax,%ebx
  ustack[3+argc] = 0;
80100b7f:	c7 84 bd 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%edi,4)
80100b86:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b8a:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b91:	ff ff ff 
  ustack[1] = argc;
80100b94:	89 bd 5c ff ff ff    	mov    %edi,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b9a:	8d 04 bd 04 00 00 00 	lea    0x4(,%edi,4),%eax
80100ba1:	89 f2                	mov    %esi,%edx
80100ba3:	29 c2                	sub    %eax,%edx
80100ba5:	89 95 60 ff ff ff    	mov    %edx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100bab:	8d 04 bd 10 00 00 00 	lea    0x10(,%edi,4),%eax
80100bb2:	29 c1                	sub    %eax,%ecx
80100bb4:	89 ce                	mov    %ecx,%esi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100bb6:	50                   	push   %eax
80100bb7:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100bbd:	50                   	push   %eax
80100bbe:	51                   	push   %ecx
80100bbf:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100bc5:	e8 94 5d 00 00       	call   8010695e <copyout>
80100bca:	83 c4 10             	add    $0x10,%esp
80100bcd:	85 c0                	test   %eax,%eax
80100bcf:	0f 88 16 ff ff ff    	js     80100aeb <exec+0x1b0>
  for(last=s=path; *s; s++)
80100bd5:	8b 55 08             	mov    0x8(%ebp),%edx
80100bd8:	89 d0                	mov    %edx,%eax
80100bda:	eb 03                	jmp    80100bdf <exec+0x2a4>
80100bdc:	83 c0 01             	add    $0x1,%eax
80100bdf:	0f b6 08             	movzbl (%eax),%ecx
80100be2:	84 c9                	test   %cl,%cl
80100be4:	74 0a                	je     80100bf0 <exec+0x2b5>
    if(*s == '/')
80100be6:	80 f9 2f             	cmp    $0x2f,%cl
80100be9:	75 f1                	jne    80100bdc <exec+0x2a1>
      last = s+1;
80100beb:	8d 50 01             	lea    0x1(%eax),%edx
80100bee:	eb ec                	jmp    80100bdc <exec+0x2a1>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100bf0:	8b bd ec fe ff ff    	mov    -0x114(%ebp),%edi
80100bf6:	89 f8                	mov    %edi,%eax
80100bf8:	83 c0 6c             	add    $0x6c,%eax
80100bfb:	83 ec 04             	sub    $0x4,%esp
80100bfe:	6a 10                	push   $0x10
80100c00:	52                   	push   %edx
80100c01:	50                   	push   %eax
80100c02:	e8 b7 35 00 00       	call   801041be <safestrcpy>
  oldpgdir = curproc->pgdir;
80100c07:	8b 5f 04             	mov    0x4(%edi),%ebx
  curproc->pgdir = pgdir;
80100c0a:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100c10:	89 4f 04             	mov    %ecx,0x4(%edi)
  curproc->sz = sz;
80100c13:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100c19:	89 0f                	mov    %ecx,(%edi)
  curproc->tf->eip = elf.entry;  // main
80100c1b:	8b 47 18             	mov    0x18(%edi),%eax
80100c1e:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100c24:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100c27:	8b 47 18             	mov    0x18(%edi),%eax
80100c2a:	89 70 44             	mov    %esi,0x44(%eax)
  switchuvm(curproc);
80100c2d:	89 3c 24             	mov    %edi,(%esp)
80100c30:	e8 2f 57 00 00       	call   80106364 <switchuvm>
  freevm(oldpgdir);
80100c35:	89 1c 24             	mov    %ebx,(%esp)
80100c38:	e8 d2 5a 00 00       	call   8010670f <freevm>
  return 0;
80100c3d:	83 c4 10             	add    $0x10,%esp
80100c40:	b8 00 00 00 00       	mov    $0x0,%eax
80100c45:	e9 71 fd ff ff       	jmp    801009bb <exec+0x80>
  ip = 0;
80100c4a:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c4f:	e9 97 fe ff ff       	jmp    80100aeb <exec+0x1b0>
80100c54:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c59:	e9 8d fe ff ff       	jmp    80100aeb <exec+0x1b0>
  return -1;
80100c5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c63:	e9 53 fd ff ff       	jmp    801009bb <exec+0x80>

80100c68 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c68:	f3 0f 1e fb          	endbr32 
80100c6c:	55                   	push   %ebp
80100c6d:	89 e5                	mov    %esp,%ebp
80100c6f:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c72:	68 75 6a 10 80       	push   $0x80106a75
80100c77:	68 20 24 11 80       	push   $0x80112420
80100c7c:	e8 b9 31 00 00       	call   80103e3a <initlock>
}
80100c81:	83 c4 10             	add    $0x10,%esp
80100c84:	c9                   	leave  
80100c85:	c3                   	ret    

80100c86 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c86:	f3 0f 1e fb          	endbr32 
80100c8a:	55                   	push   %ebp
80100c8b:	89 e5                	mov    %esp,%ebp
80100c8d:	53                   	push   %ebx
80100c8e:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c91:	68 20 24 11 80       	push   $0x80112420
80100c96:	e8 ef 32 00 00       	call   80103f8a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c9b:	83 c4 10             	add    $0x10,%esp
80100c9e:	bb 54 24 11 80       	mov    $0x80112454,%ebx
80100ca3:	eb 03                	jmp    80100ca8 <filealloc+0x22>
80100ca5:	83 c3 18             	add    $0x18,%ebx
80100ca8:	81 fb b4 2d 11 80    	cmp    $0x80112db4,%ebx
80100cae:	73 24                	jae    80100cd4 <filealloc+0x4e>
    if(f->ref == 0){
80100cb0:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100cb4:	75 ef                	jne    80100ca5 <filealloc+0x1f>
      f->ref = 1;
80100cb6:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100cbd:	83 ec 0c             	sub    $0xc,%esp
80100cc0:	68 20 24 11 80       	push   $0x80112420
80100cc5:	e8 29 33 00 00       	call   80103ff3 <release>
      return f;
80100cca:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100ccd:	89 d8                	mov    %ebx,%eax
80100ccf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd2:	c9                   	leave  
80100cd3:	c3                   	ret    
  release(&ftable.lock);
80100cd4:	83 ec 0c             	sub    $0xc,%esp
80100cd7:	68 20 24 11 80       	push   $0x80112420
80100cdc:	e8 12 33 00 00       	call   80103ff3 <release>
  return 0;
80100ce1:	83 c4 10             	add    $0x10,%esp
80100ce4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ce9:	eb e2                	jmp    80100ccd <filealloc+0x47>

80100ceb <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100ceb:	f3 0f 1e fb          	endbr32 
80100cef:	55                   	push   %ebp
80100cf0:	89 e5                	mov    %esp,%ebp
80100cf2:	53                   	push   %ebx
80100cf3:	83 ec 10             	sub    $0x10,%esp
80100cf6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100cf9:	68 20 24 11 80       	push   $0x80112420
80100cfe:	e8 87 32 00 00       	call   80103f8a <acquire>
  if(f->ref < 1)
80100d03:	8b 43 04             	mov    0x4(%ebx),%eax
80100d06:	83 c4 10             	add    $0x10,%esp
80100d09:	85 c0                	test   %eax,%eax
80100d0b:	7e 1a                	jle    80100d27 <filedup+0x3c>
    panic("filedup");
  f->ref++;
80100d0d:	83 c0 01             	add    $0x1,%eax
80100d10:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100d13:	83 ec 0c             	sub    $0xc,%esp
80100d16:	68 20 24 11 80       	push   $0x80112420
80100d1b:	e8 d3 32 00 00       	call   80103ff3 <release>
  return f;
}
80100d20:	89 d8                	mov    %ebx,%eax
80100d22:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d25:	c9                   	leave  
80100d26:	c3                   	ret    
    panic("filedup");
80100d27:	83 ec 0c             	sub    $0xc,%esp
80100d2a:	68 7c 6a 10 80       	push   $0x80106a7c
80100d2f:	e8 28 f6 ff ff       	call   8010035c <panic>

80100d34 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100d34:	f3 0f 1e fb          	endbr32 
80100d38:	55                   	push   %ebp
80100d39:	89 e5                	mov    %esp,%ebp
80100d3b:	53                   	push   %ebx
80100d3c:	83 ec 30             	sub    $0x30,%esp
80100d3f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100d42:	68 20 24 11 80       	push   $0x80112420
80100d47:	e8 3e 32 00 00       	call   80103f8a <acquire>
  if(f->ref < 1)
80100d4c:	8b 43 04             	mov    0x4(%ebx),%eax
80100d4f:	83 c4 10             	add    $0x10,%esp
80100d52:	85 c0                	test   %eax,%eax
80100d54:	7e 65                	jle    80100dbb <fileclose+0x87>
    panic("fileclose");
  if(--f->ref > 0){
80100d56:	83 e8 01             	sub    $0x1,%eax
80100d59:	89 43 04             	mov    %eax,0x4(%ebx)
80100d5c:	85 c0                	test   %eax,%eax
80100d5e:	7f 68                	jg     80100dc8 <fileclose+0x94>
    release(&ftable.lock);
    return;
  }
  ff = *f;
80100d60:	8b 03                	mov    (%ebx),%eax
80100d62:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d65:	8b 43 08             	mov    0x8(%ebx),%eax
80100d68:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d6b:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d6e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d71:	8b 43 10             	mov    0x10(%ebx),%eax
80100d74:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d77:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d7e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d84:	83 ec 0c             	sub    $0xc,%esp
80100d87:	68 20 24 11 80       	push   $0x80112420
80100d8c:	e8 62 32 00 00       	call   80103ff3 <release>

  if(ff.type == FD_PIPE)
80100d91:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d94:	83 c4 10             	add    $0x10,%esp
80100d97:	83 f8 01             	cmp    $0x1,%eax
80100d9a:	74 41                	je     80100ddd <fileclose+0xa9>
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE){
80100d9c:	83 f8 02             	cmp    $0x2,%eax
80100d9f:	75 37                	jne    80100dd8 <fileclose+0xa4>
    begin_op();
80100da1:	e8 e6 1a 00 00       	call   8010288c <begin_op>
    iput(ff.ip);
80100da6:	83 ec 0c             	sub    $0xc,%esp
80100da9:	ff 75 f0             	pushl  -0x10(%ebp)
80100dac:	e8 65 09 00 00       	call   80101716 <iput>
    end_op();
80100db1:	e8 54 1b 00 00       	call   8010290a <end_op>
80100db6:	83 c4 10             	add    $0x10,%esp
80100db9:	eb 1d                	jmp    80100dd8 <fileclose+0xa4>
    panic("fileclose");
80100dbb:	83 ec 0c             	sub    $0xc,%esp
80100dbe:	68 84 6a 10 80       	push   $0x80106a84
80100dc3:	e8 94 f5 ff ff       	call   8010035c <panic>
    release(&ftable.lock);
80100dc8:	83 ec 0c             	sub    $0xc,%esp
80100dcb:	68 20 24 11 80       	push   $0x80112420
80100dd0:	e8 1e 32 00 00       	call   80103ff3 <release>
    return;
80100dd5:	83 c4 10             	add    $0x10,%esp
  }
}
80100dd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ddb:	c9                   	leave  
80100ddc:	c3                   	ret    
    pipeclose(ff.pipe, ff.writable);
80100ddd:	83 ec 08             	sub    $0x8,%esp
80100de0:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100de4:	50                   	push   %eax
80100de5:	ff 75 ec             	pushl  -0x14(%ebp)
80100de8:	e8 32 21 00 00       	call   80102f1f <pipeclose>
80100ded:	83 c4 10             	add    $0x10,%esp
80100df0:	eb e6                	jmp    80100dd8 <fileclose+0xa4>

80100df2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100df2:	f3 0f 1e fb          	endbr32 
80100df6:	55                   	push   %ebp
80100df7:	89 e5                	mov    %esp,%ebp
80100df9:	53                   	push   %ebx
80100dfa:	83 ec 04             	sub    $0x4,%esp
80100dfd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100e00:	83 3b 02             	cmpl   $0x2,(%ebx)
80100e03:	75 31                	jne    80100e36 <filestat+0x44>
    ilock(f->ip);
80100e05:	83 ec 0c             	sub    $0xc,%esp
80100e08:	ff 73 10             	pushl  0x10(%ebx)
80100e0b:	e8 f7 07 00 00       	call   80101607 <ilock>
    stati(f->ip, st);
80100e10:	83 c4 08             	add    $0x8,%esp
80100e13:	ff 75 0c             	pushl  0xc(%ebp)
80100e16:	ff 73 10             	pushl  0x10(%ebx)
80100e19:	e8 c0 09 00 00       	call   801017de <stati>
    iunlock(f->ip);
80100e1e:	83 c4 04             	add    $0x4,%esp
80100e21:	ff 73 10             	pushl  0x10(%ebx)
80100e24:	e8 a4 08 00 00       	call   801016cd <iunlock>
    return 0;
80100e29:	83 c4 10             	add    $0x10,%esp
80100e2c:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100e31:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100e34:	c9                   	leave  
80100e35:	c3                   	ret    
  return -1;
80100e36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100e3b:	eb f4                	jmp    80100e31 <filestat+0x3f>

80100e3d <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100e3d:	f3 0f 1e fb          	endbr32 
80100e41:	55                   	push   %ebp
80100e42:	89 e5                	mov    %esp,%ebp
80100e44:	56                   	push   %esi
80100e45:	53                   	push   %ebx
80100e46:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100e49:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100e4d:	74 70                	je     80100ebf <fileread+0x82>
    return -1;
  if(f->type == FD_PIPE)
80100e4f:	8b 03                	mov    (%ebx),%eax
80100e51:	83 f8 01             	cmp    $0x1,%eax
80100e54:	74 44                	je     80100e9a <fileread+0x5d>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e56:	83 f8 02             	cmp    $0x2,%eax
80100e59:	75 57                	jne    80100eb2 <fileread+0x75>
    ilock(f->ip);
80100e5b:	83 ec 0c             	sub    $0xc,%esp
80100e5e:	ff 73 10             	pushl  0x10(%ebx)
80100e61:	e8 a1 07 00 00       	call   80101607 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100e66:	ff 75 10             	pushl  0x10(%ebp)
80100e69:	ff 73 14             	pushl  0x14(%ebx)
80100e6c:	ff 75 0c             	pushl  0xc(%ebp)
80100e6f:	ff 73 10             	pushl  0x10(%ebx)
80100e72:	e8 96 09 00 00       	call   8010180d <readi>
80100e77:	89 c6                	mov    %eax,%esi
80100e79:	83 c4 20             	add    $0x20,%esp
80100e7c:	85 c0                	test   %eax,%eax
80100e7e:	7e 03                	jle    80100e83 <fileread+0x46>
      f->off += r;
80100e80:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e83:	83 ec 0c             	sub    $0xc,%esp
80100e86:	ff 73 10             	pushl  0x10(%ebx)
80100e89:	e8 3f 08 00 00       	call   801016cd <iunlock>
    return r;
80100e8e:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e91:	89 f0                	mov    %esi,%eax
80100e93:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e96:	5b                   	pop    %ebx
80100e97:	5e                   	pop    %esi
80100e98:	5d                   	pop    %ebp
80100e99:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e9a:	83 ec 04             	sub    $0x4,%esp
80100e9d:	ff 75 10             	pushl  0x10(%ebp)
80100ea0:	ff 75 0c             	pushl  0xc(%ebp)
80100ea3:	ff 73 0c             	pushl  0xc(%ebx)
80100ea6:	e8 ce 21 00 00       	call   80103079 <piperead>
80100eab:	89 c6                	mov    %eax,%esi
80100ead:	83 c4 10             	add    $0x10,%esp
80100eb0:	eb df                	jmp    80100e91 <fileread+0x54>
  panic("fileread");
80100eb2:	83 ec 0c             	sub    $0xc,%esp
80100eb5:	68 8e 6a 10 80       	push   $0x80106a8e
80100eba:	e8 9d f4 ff ff       	call   8010035c <panic>
    return -1;
80100ebf:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100ec4:	eb cb                	jmp    80100e91 <fileread+0x54>

80100ec6 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100ec6:	f3 0f 1e fb          	endbr32 
80100eca:	55                   	push   %ebp
80100ecb:	89 e5                	mov    %esp,%ebp
80100ecd:	57                   	push   %edi
80100ece:	56                   	push   %esi
80100ecf:	53                   	push   %ebx
80100ed0:	83 ec 1c             	sub    $0x1c,%esp
80100ed3:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;

  if(f->writable == 0)
80100ed6:	80 7e 09 00          	cmpb   $0x0,0x9(%esi)
80100eda:	0f 84 cc 00 00 00    	je     80100fac <filewrite+0xe6>
    return -1;
  if(f->type == FD_PIPE)
80100ee0:	8b 06                	mov    (%esi),%eax
80100ee2:	83 f8 01             	cmp    $0x1,%eax
80100ee5:	74 10                	je     80100ef7 <filewrite+0x31>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100ee7:	83 f8 02             	cmp    $0x2,%eax
80100eea:	0f 85 af 00 00 00    	jne    80100f9f <filewrite+0xd9>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100ef0:	bf 00 00 00 00       	mov    $0x0,%edi
80100ef5:	eb 67                	jmp    80100f5e <filewrite+0x98>
    return pipewrite(f->pipe, addr, n);
80100ef7:	83 ec 04             	sub    $0x4,%esp
80100efa:	ff 75 10             	pushl  0x10(%ebp)
80100efd:	ff 75 0c             	pushl  0xc(%ebp)
80100f00:	ff 76 0c             	pushl  0xc(%esi)
80100f03:	e8 a7 20 00 00       	call   80102faf <pipewrite>
80100f08:	83 c4 10             	add    $0x10,%esp
80100f0b:	e9 82 00 00 00       	jmp    80100f92 <filewrite+0xcc>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100f10:	e8 77 19 00 00       	call   8010288c <begin_op>
      ilock(f->ip);
80100f15:	83 ec 0c             	sub    $0xc,%esp
80100f18:	ff 76 10             	pushl  0x10(%esi)
80100f1b:	e8 e7 06 00 00       	call   80101607 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100f20:	ff 75 e4             	pushl  -0x1c(%ebp)
80100f23:	ff 76 14             	pushl  0x14(%esi)
80100f26:	89 f8                	mov    %edi,%eax
80100f28:	03 45 0c             	add    0xc(%ebp),%eax
80100f2b:	50                   	push   %eax
80100f2c:	ff 76 10             	pushl  0x10(%esi)
80100f2f:	e8 da 09 00 00       	call   8010190e <writei>
80100f34:	89 c3                	mov    %eax,%ebx
80100f36:	83 c4 20             	add    $0x20,%esp
80100f39:	85 c0                	test   %eax,%eax
80100f3b:	7e 03                	jle    80100f40 <filewrite+0x7a>
        f->off += r;
80100f3d:	01 46 14             	add    %eax,0x14(%esi)
      iunlock(f->ip);
80100f40:	83 ec 0c             	sub    $0xc,%esp
80100f43:	ff 76 10             	pushl  0x10(%esi)
80100f46:	e8 82 07 00 00       	call   801016cd <iunlock>
      end_op();
80100f4b:	e8 ba 19 00 00       	call   8010290a <end_op>

      if(r < 0)
80100f50:	83 c4 10             	add    $0x10,%esp
80100f53:	85 db                	test   %ebx,%ebx
80100f55:	78 31                	js     80100f88 <filewrite+0xc2>
        break;
      if(r != n1)
80100f57:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
80100f5a:	75 1f                	jne    80100f7b <filewrite+0xb5>
        panic("short filewrite");
      i += r;
80100f5c:	01 df                	add    %ebx,%edi
    while(i < n){
80100f5e:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f61:	7d 25                	jge    80100f88 <filewrite+0xc2>
      int n1 = n - i;
80100f63:	8b 45 10             	mov    0x10(%ebp),%eax
80100f66:	29 f8                	sub    %edi,%eax
80100f68:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100f6b:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f70:	7e 9e                	jle    80100f10 <filewrite+0x4a>
        n1 = max;
80100f72:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f79:	eb 95                	jmp    80100f10 <filewrite+0x4a>
        panic("short filewrite");
80100f7b:	83 ec 0c             	sub    $0xc,%esp
80100f7e:	68 97 6a 10 80       	push   $0x80106a97
80100f83:	e8 d4 f3 ff ff       	call   8010035c <panic>
    }
    return i == n ? n : -1;
80100f88:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f8b:	74 0d                	je     80100f9a <filewrite+0xd4>
80100f8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  panic("filewrite");
}
80100f92:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f95:	5b                   	pop    %ebx
80100f96:	5e                   	pop    %esi
80100f97:	5f                   	pop    %edi
80100f98:	5d                   	pop    %ebp
80100f99:	c3                   	ret    
    return i == n ? n : -1;
80100f9a:	8b 45 10             	mov    0x10(%ebp),%eax
80100f9d:	eb f3                	jmp    80100f92 <filewrite+0xcc>
  panic("filewrite");
80100f9f:	83 ec 0c             	sub    $0xc,%esp
80100fa2:	68 9d 6a 10 80       	push   $0x80106a9d
80100fa7:	e8 b0 f3 ff ff       	call   8010035c <panic>
    return -1;
80100fac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100fb1:	eb df                	jmp    80100f92 <filewrite+0xcc>

80100fb3 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100fb3:	55                   	push   %ebp
80100fb4:	89 e5                	mov    %esp,%ebp
80100fb6:	57                   	push   %edi
80100fb7:	56                   	push   %esi
80100fb8:	53                   	push   %ebx
80100fb9:	83 ec 0c             	sub    $0xc,%esp
80100fbc:	89 d6                	mov    %edx,%esi
  char *s;
  int len;

  while(*path == '/')
80100fbe:	0f b6 10             	movzbl (%eax),%edx
80100fc1:	80 fa 2f             	cmp    $0x2f,%dl
80100fc4:	75 05                	jne    80100fcb <skipelem+0x18>
    path++;
80100fc6:	83 c0 01             	add    $0x1,%eax
80100fc9:	eb f3                	jmp    80100fbe <skipelem+0xb>
  if(*path == 0)
80100fcb:	84 d2                	test   %dl,%dl
80100fcd:	74 59                	je     80101028 <skipelem+0x75>
80100fcf:	89 c3                	mov    %eax,%ebx
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80100fd1:	0f b6 13             	movzbl (%ebx),%edx
80100fd4:	80 fa 2f             	cmp    $0x2f,%dl
80100fd7:	0f 95 c1             	setne  %cl
80100fda:	84 d2                	test   %dl,%dl
80100fdc:	0f 95 c2             	setne  %dl
80100fdf:	84 d1                	test   %dl,%cl
80100fe1:	74 05                	je     80100fe8 <skipelem+0x35>
    path++;
80100fe3:	83 c3 01             	add    $0x1,%ebx
80100fe6:	eb e9                	jmp    80100fd1 <skipelem+0x1e>
  len = path - s;
80100fe8:	89 df                	mov    %ebx,%edi
80100fea:	29 c7                	sub    %eax,%edi
  if(len >= DIRSIZ)
80100fec:	83 ff 0d             	cmp    $0xd,%edi
80100fef:	7e 11                	jle    80101002 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100ff1:	83 ec 04             	sub    $0x4,%esp
80100ff4:	6a 0e                	push   $0xe
80100ff6:	50                   	push   %eax
80100ff7:	56                   	push   %esi
80100ff8:	e8 c1 30 00 00       	call   801040be <memmove>
80100ffd:	83 c4 10             	add    $0x10,%esp
80101000:	eb 17                	jmp    80101019 <skipelem+0x66>
  else {
    memmove(name, s, len);
80101002:	83 ec 04             	sub    $0x4,%esp
80101005:	57                   	push   %edi
80101006:	50                   	push   %eax
80101007:	56                   	push   %esi
80101008:	e8 b1 30 00 00       	call   801040be <memmove>
    name[len] = 0;
8010100d:	c6 04 3e 00          	movb   $0x0,(%esi,%edi,1)
80101011:	83 c4 10             	add    $0x10,%esp
80101014:	eb 03                	jmp    80101019 <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80101016:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80101019:	80 3b 2f             	cmpb   $0x2f,(%ebx)
8010101c:	74 f8                	je     80101016 <skipelem+0x63>
  return path;
}
8010101e:	89 d8                	mov    %ebx,%eax
80101020:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101023:	5b                   	pop    %ebx
80101024:	5e                   	pop    %esi
80101025:	5f                   	pop    %edi
80101026:	5d                   	pop    %ebp
80101027:	c3                   	ret    
    return 0;
80101028:	bb 00 00 00 00       	mov    $0x0,%ebx
8010102d:	eb ef                	jmp    8010101e <skipelem+0x6b>

8010102f <bzero>:
{
8010102f:	55                   	push   %ebp
80101030:	89 e5                	mov    %esp,%ebp
80101032:	53                   	push   %ebx
80101033:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80101036:	52                   	push   %edx
80101037:	50                   	push   %eax
80101038:	e8 33 f1 ff ff       	call   80100170 <bread>
8010103d:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
8010103f:	8d 40 5c             	lea    0x5c(%eax),%eax
80101042:	83 c4 0c             	add    $0xc,%esp
80101045:	68 00 02 00 00       	push   $0x200
8010104a:	6a 00                	push   $0x0
8010104c:	50                   	push   %eax
8010104d:	e8 ec 2f 00 00       	call   8010403e <memset>
  log_write(bp);
80101052:	89 1c 24             	mov    %ebx,(%esp)
80101055:	e8 63 19 00 00       	call   801029bd <log_write>
  brelse(bp);
8010105a:	89 1c 24             	mov    %ebx,(%esp)
8010105d:	e8 7f f1 ff ff       	call   801001e1 <brelse>
}
80101062:	83 c4 10             	add    $0x10,%esp
80101065:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101068:	c9                   	leave  
80101069:	c3                   	ret    

8010106a <balloc>:
{
8010106a:	55                   	push   %ebp
8010106b:	89 e5                	mov    %esp,%ebp
8010106d:	57                   	push   %edi
8010106e:	56                   	push   %esi
8010106f:	53                   	push   %ebx
80101070:	83 ec 1c             	sub    $0x1c,%esp
80101073:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101076:	be 00 00 00 00       	mov    $0x0,%esi
8010107b:	eb 14                	jmp    80101091 <balloc+0x27>
    brelse(bp);
8010107d:	83 ec 0c             	sub    $0xc,%esp
80101080:	ff 75 e4             	pushl  -0x1c(%ebp)
80101083:	e8 59 f1 ff ff       	call   801001e1 <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101088:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010108e:	83 c4 10             	add    $0x10,%esp
80101091:	39 35 20 2e 11 80    	cmp    %esi,0x80112e20
80101097:	76 75                	jbe    8010110e <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
80101099:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
8010109f:	85 f6                	test   %esi,%esi
801010a1:	0f 49 c6             	cmovns %esi,%eax
801010a4:	c1 f8 0c             	sar    $0xc,%eax
801010a7:	83 ec 08             	sub    $0x8,%esp
801010aa:	03 05 38 2e 11 80    	add    0x80112e38,%eax
801010b0:	50                   	push   %eax
801010b1:	ff 75 d8             	pushl  -0x28(%ebp)
801010b4:	e8 b7 f0 ff ff       	call   80100170 <bread>
801010b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801010bc:	83 c4 10             	add    $0x10,%esp
801010bf:	b8 00 00 00 00       	mov    $0x0,%eax
801010c4:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801010c9:	7f b2                	jg     8010107d <balloc+0x13>
801010cb:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
801010ce:	89 5d e0             	mov    %ebx,-0x20(%ebp)
801010d1:	3b 1d 20 2e 11 80    	cmp    0x80112e20,%ebx
801010d7:	73 a4                	jae    8010107d <balloc+0x13>
      m = 1 << (bi % 8);
801010d9:	99                   	cltd   
801010da:	c1 ea 1d             	shr    $0x1d,%edx
801010dd:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801010e0:	83 e1 07             	and    $0x7,%ecx
801010e3:	29 d1                	sub    %edx,%ecx
801010e5:	ba 01 00 00 00       	mov    $0x1,%edx
801010ea:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801010ec:	8d 48 07             	lea    0x7(%eax),%ecx
801010ef:	85 c0                	test   %eax,%eax
801010f1:	0f 49 c8             	cmovns %eax,%ecx
801010f4:	c1 f9 03             	sar    $0x3,%ecx
801010f7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
801010fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801010fd:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101102:	0f b6 f9             	movzbl %cl,%edi
80101105:	85 d7                	test   %edx,%edi
80101107:	74 12                	je     8010111b <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101109:	83 c0 01             	add    $0x1,%eax
8010110c:	eb b6                	jmp    801010c4 <balloc+0x5a>
  panic("balloc: out of blocks");
8010110e:	83 ec 0c             	sub    $0xc,%esp
80101111:	68 a7 6a 10 80       	push   $0x80106aa7
80101116:	e8 41 f2 ff ff       	call   8010035c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
8010111b:	09 ca                	or     %ecx,%edx
8010111d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101120:	8b 75 dc             	mov    -0x24(%ebp),%esi
80101123:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
80101127:	83 ec 0c             	sub    $0xc,%esp
8010112a:	89 c6                	mov    %eax,%esi
8010112c:	50                   	push   %eax
8010112d:	e8 8b 18 00 00       	call   801029bd <log_write>
        brelse(bp);
80101132:	89 34 24             	mov    %esi,(%esp)
80101135:	e8 a7 f0 ff ff       	call   801001e1 <brelse>
        bzero(dev, b + bi);
8010113a:	89 da                	mov    %ebx,%edx
8010113c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010113f:	e8 eb fe ff ff       	call   8010102f <bzero>
}
80101144:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    

8010114f <bmap>:
{
8010114f:	55                   	push   %ebp
80101150:	89 e5                	mov    %esp,%ebp
80101152:	57                   	push   %edi
80101153:	56                   	push   %esi
80101154:	53                   	push   %ebx
80101155:	83 ec 1c             	sub    $0x1c,%esp
80101158:	89 c3                	mov    %eax,%ebx
8010115a:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
8010115c:	83 fa 0b             	cmp    $0xb,%edx
8010115f:	76 45                	jbe    801011a6 <bmap+0x57>
  bn -= NDIRECT;
80101161:	8d 72 f4             	lea    -0xc(%edx),%esi
  if(bn < NINDIRECT){
80101164:	83 fe 7f             	cmp    $0x7f,%esi
80101167:	77 7f                	ja     801011e8 <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101169:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
8010116f:	85 c0                	test   %eax,%eax
80101171:	74 4a                	je     801011bd <bmap+0x6e>
    bp = bread(ip->dev, addr);
80101173:	83 ec 08             	sub    $0x8,%esp
80101176:	50                   	push   %eax
80101177:	ff 33                	pushl  (%ebx)
80101179:	e8 f2 ef ff ff       	call   80100170 <bread>
8010117e:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101180:	8d 44 b0 5c          	lea    0x5c(%eax,%esi,4),%eax
80101184:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101187:	8b 30                	mov    (%eax),%esi
80101189:	83 c4 10             	add    $0x10,%esp
8010118c:	85 f6                	test   %esi,%esi
8010118e:	74 3c                	je     801011cc <bmap+0x7d>
    brelse(bp);
80101190:	83 ec 0c             	sub    $0xc,%esp
80101193:	57                   	push   %edi
80101194:	e8 48 f0 ff ff       	call   801001e1 <brelse>
    return addr;
80101199:	83 c4 10             	add    $0x10,%esp
}
8010119c:	89 f0                	mov    %esi,%eax
8010119e:	8d 65 f4             	lea    -0xc(%ebp),%esp
801011a1:	5b                   	pop    %ebx
801011a2:	5e                   	pop    %esi
801011a3:	5f                   	pop    %edi
801011a4:	5d                   	pop    %ebp
801011a5:	c3                   	ret    
    if((addr = ip->addrs[bn]) == 0)
801011a6:	8b 74 90 5c          	mov    0x5c(%eax,%edx,4),%esi
801011aa:	85 f6                	test   %esi,%esi
801011ac:	75 ee                	jne    8010119c <bmap+0x4d>
      ip->addrs[bn] = addr = balloc(ip->dev);
801011ae:	8b 00                	mov    (%eax),%eax
801011b0:	e8 b5 fe ff ff       	call   8010106a <balloc>
801011b5:	89 c6                	mov    %eax,%esi
801011b7:	89 44 bb 5c          	mov    %eax,0x5c(%ebx,%edi,4)
    return addr;
801011bb:	eb df                	jmp    8010119c <bmap+0x4d>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801011bd:	8b 03                	mov    (%ebx),%eax
801011bf:	e8 a6 fe ff ff       	call   8010106a <balloc>
801011c4:	89 83 8c 00 00 00    	mov    %eax,0x8c(%ebx)
801011ca:	eb a7                	jmp    80101173 <bmap+0x24>
      a[bn] = addr = balloc(ip->dev);
801011cc:	8b 03                	mov    (%ebx),%eax
801011ce:	e8 97 fe ff ff       	call   8010106a <balloc>
801011d3:	89 c6                	mov    %eax,%esi
801011d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011d8:	89 30                	mov    %esi,(%eax)
      log_write(bp);
801011da:	83 ec 0c             	sub    $0xc,%esp
801011dd:	57                   	push   %edi
801011de:	e8 da 17 00 00       	call   801029bd <log_write>
801011e3:	83 c4 10             	add    $0x10,%esp
801011e6:	eb a8                	jmp    80101190 <bmap+0x41>
  panic("bmap: out of range");
801011e8:	83 ec 0c             	sub    $0xc,%esp
801011eb:	68 bd 6a 10 80       	push   $0x80106abd
801011f0:	e8 67 f1 ff ff       	call   8010035c <panic>

801011f5 <iget>:
{
801011f5:	55                   	push   %ebp
801011f6:	89 e5                	mov    %esp,%ebp
801011f8:	57                   	push   %edi
801011f9:	56                   	push   %esi
801011fa:	53                   	push   %ebx
801011fb:	83 ec 28             	sub    $0x28,%esp
801011fe:	89 c7                	mov    %eax,%edi
80101200:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101203:	68 40 2e 11 80       	push   $0x80112e40
80101208:	e8 7d 2d 00 00       	call   80103f8a <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010120d:	83 c4 10             	add    $0x10,%esp
  empty = 0;
80101210:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101215:	bb 74 2e 11 80       	mov    $0x80112e74,%ebx
8010121a:	eb 0a                	jmp    80101226 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010121c:	85 f6                	test   %esi,%esi
8010121e:	74 3b                	je     8010125b <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101220:	81 c3 90 00 00 00    	add    $0x90,%ebx
80101226:	81 fb 94 4a 11 80    	cmp    $0x80114a94,%ebx
8010122c:	73 35                	jae    80101263 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010122e:	8b 43 08             	mov    0x8(%ebx),%eax
80101231:	85 c0                	test   %eax,%eax
80101233:	7e e7                	jle    8010121c <iget+0x27>
80101235:	39 3b                	cmp    %edi,(%ebx)
80101237:	75 e3                	jne    8010121c <iget+0x27>
80101239:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010123c:	39 4b 04             	cmp    %ecx,0x4(%ebx)
8010123f:	75 db                	jne    8010121c <iget+0x27>
      ip->ref++;
80101241:	83 c0 01             	add    $0x1,%eax
80101244:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
80101247:	83 ec 0c             	sub    $0xc,%esp
8010124a:	68 40 2e 11 80       	push   $0x80112e40
8010124f:	e8 9f 2d 00 00       	call   80103ff3 <release>
      return ip;
80101254:	83 c4 10             	add    $0x10,%esp
80101257:	89 de                	mov    %ebx,%esi
80101259:	eb 32                	jmp    8010128d <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010125b:	85 c0                	test   %eax,%eax
8010125d:	75 c1                	jne    80101220 <iget+0x2b>
      empty = ip;
8010125f:	89 de                	mov    %ebx,%esi
80101261:	eb bd                	jmp    80101220 <iget+0x2b>
  if(empty == 0)
80101263:	85 f6                	test   %esi,%esi
80101265:	74 30                	je     80101297 <iget+0xa2>
  ip->dev = dev;
80101267:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
80101269:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010126c:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
8010126f:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101276:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010127d:	83 ec 0c             	sub    $0xc,%esp
80101280:	68 40 2e 11 80       	push   $0x80112e40
80101285:	e8 69 2d 00 00       	call   80103ff3 <release>
  return ip;
8010128a:	83 c4 10             	add    $0x10,%esp
}
8010128d:	89 f0                	mov    %esi,%eax
8010128f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101292:	5b                   	pop    %ebx
80101293:	5e                   	pop    %esi
80101294:	5f                   	pop    %edi
80101295:	5d                   	pop    %ebp
80101296:	c3                   	ret    
    panic("iget: no inodes");
80101297:	83 ec 0c             	sub    $0xc,%esp
8010129a:	68 d0 6a 10 80       	push   $0x80106ad0
8010129f:	e8 b8 f0 ff ff       	call   8010035c <panic>

801012a4 <readsb>:
{
801012a4:	f3 0f 1e fb          	endbr32 
801012a8:	55                   	push   %ebp
801012a9:	89 e5                	mov    %esp,%ebp
801012ab:	53                   	push   %ebx
801012ac:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
801012af:	6a 01                	push   $0x1
801012b1:	ff 75 08             	pushl  0x8(%ebp)
801012b4:	e8 b7 ee ff ff       	call   80100170 <bread>
801012b9:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
801012bb:	8d 40 5c             	lea    0x5c(%eax),%eax
801012be:	83 c4 0c             	add    $0xc,%esp
801012c1:	6a 1c                	push   $0x1c
801012c3:	50                   	push   %eax
801012c4:	ff 75 0c             	pushl  0xc(%ebp)
801012c7:	e8 f2 2d 00 00       	call   801040be <memmove>
  brelse(bp);
801012cc:	89 1c 24             	mov    %ebx,(%esp)
801012cf:	e8 0d ef ff ff       	call   801001e1 <brelse>
}
801012d4:	83 c4 10             	add    $0x10,%esp
801012d7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801012da:	c9                   	leave  
801012db:	c3                   	ret    

801012dc <bfree>:
{
801012dc:	55                   	push   %ebp
801012dd:	89 e5                	mov    %esp,%ebp
801012df:	57                   	push   %edi
801012e0:	56                   	push   %esi
801012e1:	53                   	push   %ebx
801012e2:	83 ec 14             	sub    $0x14,%esp
801012e5:	89 c3                	mov    %eax,%ebx
801012e7:	89 d6                	mov    %edx,%esi
  readsb(dev, &sb);
801012e9:	68 20 2e 11 80       	push   $0x80112e20
801012ee:	50                   	push   %eax
801012ef:	e8 b0 ff ff ff       	call   801012a4 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
801012f4:	89 f0                	mov    %esi,%eax
801012f6:	c1 e8 0c             	shr    $0xc,%eax
801012f9:	83 c4 08             	add    $0x8,%esp
801012fc:	03 05 38 2e 11 80    	add    0x80112e38,%eax
80101302:	50                   	push   %eax
80101303:	53                   	push   %ebx
80101304:	e8 67 ee ff ff       	call   80100170 <bread>
80101309:	89 c3                	mov    %eax,%ebx
  bi = b % BPB;
8010130b:	89 f7                	mov    %esi,%edi
8010130d:	81 e7 ff 0f 00 00    	and    $0xfff,%edi
  m = 1 << (bi % 8);
80101313:	89 f1                	mov    %esi,%ecx
80101315:	83 e1 07             	and    $0x7,%ecx
80101318:	b8 01 00 00 00       	mov    $0x1,%eax
8010131d:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
8010131f:	83 c4 10             	add    $0x10,%esp
80101322:	c1 ff 03             	sar    $0x3,%edi
80101325:	0f b6 54 3b 5c       	movzbl 0x5c(%ebx,%edi,1),%edx
8010132a:	0f b6 ca             	movzbl %dl,%ecx
8010132d:	85 c1                	test   %eax,%ecx
8010132f:	74 24                	je     80101355 <bfree+0x79>
  bp->data[bi/8] &= ~m;
80101331:	f7 d0                	not    %eax
80101333:	21 d0                	and    %edx,%eax
80101335:	88 44 3b 5c          	mov    %al,0x5c(%ebx,%edi,1)
  log_write(bp);
80101339:	83 ec 0c             	sub    $0xc,%esp
8010133c:	53                   	push   %ebx
8010133d:	e8 7b 16 00 00       	call   801029bd <log_write>
  brelse(bp);
80101342:	89 1c 24             	mov    %ebx,(%esp)
80101345:	e8 97 ee ff ff       	call   801001e1 <brelse>
}
8010134a:	83 c4 10             	add    $0x10,%esp
8010134d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101350:	5b                   	pop    %ebx
80101351:	5e                   	pop    %esi
80101352:	5f                   	pop    %edi
80101353:	5d                   	pop    %ebp
80101354:	c3                   	ret    
    panic("freeing free block");
80101355:	83 ec 0c             	sub    $0xc,%esp
80101358:	68 e0 6a 10 80       	push   $0x80106ae0
8010135d:	e8 fa ef ff ff       	call   8010035c <panic>

80101362 <iinit>:
{
80101362:	f3 0f 1e fb          	endbr32 
80101366:	55                   	push   %ebp
80101367:	89 e5                	mov    %esp,%ebp
80101369:	53                   	push   %ebx
8010136a:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
8010136d:	68 f3 6a 10 80       	push   $0x80106af3
80101372:	68 40 2e 11 80       	push   $0x80112e40
80101377:	e8 be 2a 00 00       	call   80103e3a <initlock>
  for(i = 0; i < NINODE; i++) {
8010137c:	83 c4 10             	add    $0x10,%esp
8010137f:	bb 00 00 00 00       	mov    $0x0,%ebx
80101384:	83 fb 31             	cmp    $0x31,%ebx
80101387:	7f 23                	jg     801013ac <iinit+0x4a>
    initsleeplock(&icache.inode[i].lock, "inode");
80101389:	83 ec 08             	sub    $0x8,%esp
8010138c:	68 fa 6a 10 80       	push   $0x80106afa
80101391:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101394:	89 d0                	mov    %edx,%eax
80101396:	c1 e0 04             	shl    $0x4,%eax
80101399:	05 80 2e 11 80       	add    $0x80112e80,%eax
8010139e:	50                   	push   %eax
8010139f:	e8 a2 29 00 00       	call   80103d46 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
801013a4:	83 c3 01             	add    $0x1,%ebx
801013a7:	83 c4 10             	add    $0x10,%esp
801013aa:	eb d8                	jmp    80101384 <iinit+0x22>
  readsb(dev, &sb);
801013ac:	83 ec 08             	sub    $0x8,%esp
801013af:	68 20 2e 11 80       	push   $0x80112e20
801013b4:	ff 75 08             	pushl  0x8(%ebp)
801013b7:	e8 e8 fe ff ff       	call   801012a4 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
801013bc:	ff 35 38 2e 11 80    	pushl  0x80112e38
801013c2:	ff 35 34 2e 11 80    	pushl  0x80112e34
801013c8:	ff 35 30 2e 11 80    	pushl  0x80112e30
801013ce:	ff 35 2c 2e 11 80    	pushl  0x80112e2c
801013d4:	ff 35 28 2e 11 80    	pushl  0x80112e28
801013da:	ff 35 24 2e 11 80    	pushl  0x80112e24
801013e0:	ff 35 20 2e 11 80    	pushl  0x80112e20
801013e6:	68 60 6b 10 80       	push   $0x80106b60
801013eb:	e8 39 f2 ff ff       	call   80100629 <cprintf>
}
801013f0:	83 c4 30             	add    $0x30,%esp
801013f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801013f6:	c9                   	leave  
801013f7:	c3                   	ret    

801013f8 <ialloc>:
{
801013f8:	f3 0f 1e fb          	endbr32 
801013fc:	55                   	push   %ebp
801013fd:	89 e5                	mov    %esp,%ebp
801013ff:	57                   	push   %edi
80101400:	56                   	push   %esi
80101401:	53                   	push   %ebx
80101402:	83 ec 1c             	sub    $0x1c,%esp
80101405:	8b 45 0c             	mov    0xc(%ebp),%eax
80101408:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010140b:	bb 01 00 00 00       	mov    $0x1,%ebx
80101410:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101413:	39 1d 28 2e 11 80    	cmp    %ebx,0x80112e28
80101419:	76 76                	jbe    80101491 <ialloc+0x99>
    bp = bread(dev, IBLOCK(inum, sb));
8010141b:	89 d8                	mov    %ebx,%eax
8010141d:	c1 e8 03             	shr    $0x3,%eax
80101420:	83 ec 08             	sub    $0x8,%esp
80101423:	03 05 34 2e 11 80    	add    0x80112e34,%eax
80101429:	50                   	push   %eax
8010142a:	ff 75 08             	pushl  0x8(%ebp)
8010142d:	e8 3e ed ff ff       	call   80100170 <bread>
80101432:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
80101434:	89 d8                	mov    %ebx,%eax
80101436:	83 e0 07             	and    $0x7,%eax
80101439:	c1 e0 06             	shl    $0x6,%eax
8010143c:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
80101440:	83 c4 10             	add    $0x10,%esp
80101443:	66 83 3f 00          	cmpw   $0x0,(%edi)
80101447:	74 11                	je     8010145a <ialloc+0x62>
    brelse(bp);
80101449:	83 ec 0c             	sub    $0xc,%esp
8010144c:	56                   	push   %esi
8010144d:	e8 8f ed ff ff       	call   801001e1 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
80101452:	83 c3 01             	add    $0x1,%ebx
80101455:	83 c4 10             	add    $0x10,%esp
80101458:	eb b6                	jmp    80101410 <ialloc+0x18>
      memset(dip, 0, sizeof(*dip));
8010145a:	83 ec 04             	sub    $0x4,%esp
8010145d:	6a 40                	push   $0x40
8010145f:	6a 00                	push   $0x0
80101461:	57                   	push   %edi
80101462:	e8 d7 2b 00 00       	call   8010403e <memset>
      dip->type = type;
80101467:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010146b:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
8010146e:	89 34 24             	mov    %esi,(%esp)
80101471:	e8 47 15 00 00       	call   801029bd <log_write>
      brelse(bp);
80101476:	89 34 24             	mov    %esi,(%esp)
80101479:	e8 63 ed ff ff       	call   801001e1 <brelse>
      return iget(dev, inum);
8010147e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101481:	8b 45 08             	mov    0x8(%ebp),%eax
80101484:	e8 6c fd ff ff       	call   801011f5 <iget>
}
80101489:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010148c:	5b                   	pop    %ebx
8010148d:	5e                   	pop    %esi
8010148e:	5f                   	pop    %edi
8010148f:	5d                   	pop    %ebp
80101490:	c3                   	ret    
  panic("ialloc: no inodes");
80101491:	83 ec 0c             	sub    $0xc,%esp
80101494:	68 00 6b 10 80       	push   $0x80106b00
80101499:	e8 be ee ff ff       	call   8010035c <panic>

8010149e <iupdate>:
{
8010149e:	f3 0f 1e fb          	endbr32 
801014a2:	55                   	push   %ebp
801014a3:	89 e5                	mov    %esp,%ebp
801014a5:	56                   	push   %esi
801014a6:	53                   	push   %ebx
801014a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801014aa:	8b 43 04             	mov    0x4(%ebx),%eax
801014ad:	c1 e8 03             	shr    $0x3,%eax
801014b0:	83 ec 08             	sub    $0x8,%esp
801014b3:	03 05 34 2e 11 80    	add    0x80112e34,%eax
801014b9:	50                   	push   %eax
801014ba:	ff 33                	pushl  (%ebx)
801014bc:	e8 af ec ff ff       	call   80100170 <bread>
801014c1:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801014c3:	8b 43 04             	mov    0x4(%ebx),%eax
801014c6:	83 e0 07             	and    $0x7,%eax
801014c9:	c1 e0 06             	shl    $0x6,%eax
801014cc:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
801014d0:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
801014d4:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801014d7:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
801014db:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801014df:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
801014e3:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801014e7:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
801014eb:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801014ef:	8b 53 58             	mov    0x58(%ebx),%edx
801014f2:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801014f5:	83 c3 5c             	add    $0x5c,%ebx
801014f8:	83 c0 0c             	add    $0xc,%eax
801014fb:	83 c4 0c             	add    $0xc,%esp
801014fe:	6a 34                	push   $0x34
80101500:	53                   	push   %ebx
80101501:	50                   	push   %eax
80101502:	e8 b7 2b 00 00       	call   801040be <memmove>
  log_write(bp);
80101507:	89 34 24             	mov    %esi,(%esp)
8010150a:	e8 ae 14 00 00       	call   801029bd <log_write>
  brelse(bp);
8010150f:	89 34 24             	mov    %esi,(%esp)
80101512:	e8 ca ec ff ff       	call   801001e1 <brelse>
}
80101517:	83 c4 10             	add    $0x10,%esp
8010151a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010151d:	5b                   	pop    %ebx
8010151e:	5e                   	pop    %esi
8010151f:	5d                   	pop    %ebp
80101520:	c3                   	ret    

80101521 <itrunc>:
{
80101521:	55                   	push   %ebp
80101522:	89 e5                	mov    %esp,%ebp
80101524:	57                   	push   %edi
80101525:	56                   	push   %esi
80101526:	53                   	push   %ebx
80101527:	83 ec 1c             	sub    $0x1c,%esp
8010152a:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
8010152c:	bb 00 00 00 00       	mov    $0x0,%ebx
80101531:	eb 03                	jmp    80101536 <itrunc+0x15>
80101533:	83 c3 01             	add    $0x1,%ebx
80101536:	83 fb 0b             	cmp    $0xb,%ebx
80101539:	7f 19                	jg     80101554 <itrunc+0x33>
    if(ip->addrs[i]){
8010153b:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
8010153f:	85 d2                	test   %edx,%edx
80101541:	74 f0                	je     80101533 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
80101543:	8b 06                	mov    (%esi),%eax
80101545:	e8 92 fd ff ff       	call   801012dc <bfree>
      ip->addrs[i] = 0;
8010154a:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
80101551:	00 
80101552:	eb df                	jmp    80101533 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
80101554:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
8010155a:	85 c0                	test   %eax,%eax
8010155c:	75 1b                	jne    80101579 <itrunc+0x58>
  ip->size = 0;
8010155e:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
80101565:	83 ec 0c             	sub    $0xc,%esp
80101568:	56                   	push   %esi
80101569:	e8 30 ff ff ff       	call   8010149e <iupdate>
}
8010156e:	83 c4 10             	add    $0x10,%esp
80101571:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101574:	5b                   	pop    %ebx
80101575:	5e                   	pop    %esi
80101576:	5f                   	pop    %edi
80101577:	5d                   	pop    %ebp
80101578:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101579:	83 ec 08             	sub    $0x8,%esp
8010157c:	50                   	push   %eax
8010157d:	ff 36                	pushl  (%esi)
8010157f:	e8 ec eb ff ff       	call   80100170 <bread>
80101584:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101587:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
8010158a:	83 c4 10             	add    $0x10,%esp
8010158d:	bb 00 00 00 00       	mov    $0x0,%ebx
80101592:	eb 0a                	jmp    8010159e <itrunc+0x7d>
        bfree(ip->dev, a[j]);
80101594:	8b 06                	mov    (%esi),%eax
80101596:	e8 41 fd ff ff       	call   801012dc <bfree>
    for(j = 0; j < NINDIRECT; j++){
8010159b:	83 c3 01             	add    $0x1,%ebx
8010159e:	83 fb 7f             	cmp    $0x7f,%ebx
801015a1:	77 09                	ja     801015ac <itrunc+0x8b>
      if(a[j])
801015a3:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
801015a6:	85 d2                	test   %edx,%edx
801015a8:	74 f1                	je     8010159b <itrunc+0x7a>
801015aa:	eb e8                	jmp    80101594 <itrunc+0x73>
    brelse(bp);
801015ac:	83 ec 0c             	sub    $0xc,%esp
801015af:	ff 75 e4             	pushl  -0x1c(%ebp)
801015b2:	e8 2a ec ff ff       	call   801001e1 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
801015b7:	8b 06                	mov    (%esi),%eax
801015b9:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
801015bf:	e8 18 fd ff ff       	call   801012dc <bfree>
    ip->addrs[NDIRECT] = 0;
801015c4:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
801015cb:	00 00 00 
801015ce:	83 c4 10             	add    $0x10,%esp
801015d1:	eb 8b                	jmp    8010155e <itrunc+0x3d>

801015d3 <idup>:
{
801015d3:	f3 0f 1e fb          	endbr32 
801015d7:	55                   	push   %ebp
801015d8:	89 e5                	mov    %esp,%ebp
801015da:	53                   	push   %ebx
801015db:	83 ec 10             	sub    $0x10,%esp
801015de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
801015e1:	68 40 2e 11 80       	push   $0x80112e40
801015e6:	e8 9f 29 00 00       	call   80103f8a <acquire>
  ip->ref++;
801015eb:	8b 43 08             	mov    0x8(%ebx),%eax
801015ee:	83 c0 01             	add    $0x1,%eax
801015f1:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801015f4:	c7 04 24 40 2e 11 80 	movl   $0x80112e40,(%esp)
801015fb:	e8 f3 29 00 00       	call   80103ff3 <release>
}
80101600:	89 d8                	mov    %ebx,%eax
80101602:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101605:	c9                   	leave  
80101606:	c3                   	ret    

80101607 <ilock>:
{
80101607:	f3 0f 1e fb          	endbr32 
8010160b:	55                   	push   %ebp
8010160c:	89 e5                	mov    %esp,%ebp
8010160e:	56                   	push   %esi
8010160f:	53                   	push   %ebx
80101610:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101613:	85 db                	test   %ebx,%ebx
80101615:	74 22                	je     80101639 <ilock+0x32>
80101617:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
8010161b:	7e 1c                	jle    80101639 <ilock+0x32>
  acquiresleep(&ip->lock);
8010161d:	83 ec 0c             	sub    $0xc,%esp
80101620:	8d 43 0c             	lea    0xc(%ebx),%eax
80101623:	50                   	push   %eax
80101624:	e8 54 27 00 00       	call   80103d7d <acquiresleep>
  if(ip->valid == 0){
80101629:	83 c4 10             	add    $0x10,%esp
8010162c:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101630:	74 14                	je     80101646 <ilock+0x3f>
}
80101632:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101635:	5b                   	pop    %ebx
80101636:	5e                   	pop    %esi
80101637:	5d                   	pop    %ebp
80101638:	c3                   	ret    
    panic("ilock");
80101639:	83 ec 0c             	sub    $0xc,%esp
8010163c:	68 12 6b 10 80       	push   $0x80106b12
80101641:	e8 16 ed ff ff       	call   8010035c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101646:	8b 43 04             	mov    0x4(%ebx),%eax
80101649:	c1 e8 03             	shr    $0x3,%eax
8010164c:	83 ec 08             	sub    $0x8,%esp
8010164f:	03 05 34 2e 11 80    	add    0x80112e34,%eax
80101655:	50                   	push   %eax
80101656:	ff 33                	pushl  (%ebx)
80101658:	e8 13 eb ff ff       	call   80100170 <bread>
8010165d:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010165f:	8b 43 04             	mov    0x4(%ebx),%eax
80101662:	83 e0 07             	and    $0x7,%eax
80101665:	c1 e0 06             	shl    $0x6,%eax
80101668:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
8010166c:	0f b7 10             	movzwl (%eax),%edx
8010166f:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
80101673:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101677:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
8010167b:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010167f:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
80101683:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101687:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
8010168b:	8b 50 08             	mov    0x8(%eax),%edx
8010168e:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101691:	83 c0 0c             	add    $0xc,%eax
80101694:	8d 53 5c             	lea    0x5c(%ebx),%edx
80101697:	83 c4 0c             	add    $0xc,%esp
8010169a:	6a 34                	push   $0x34
8010169c:	50                   	push   %eax
8010169d:	52                   	push   %edx
8010169e:	e8 1b 2a 00 00       	call   801040be <memmove>
    brelse(bp);
801016a3:	89 34 24             	mov    %esi,(%esp)
801016a6:	e8 36 eb ff ff       	call   801001e1 <brelse>
    ip->valid = 1;
801016ab:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
801016b2:	83 c4 10             	add    $0x10,%esp
801016b5:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
801016ba:	0f 85 72 ff ff ff    	jne    80101632 <ilock+0x2b>
      panic("ilock: no type");
801016c0:	83 ec 0c             	sub    $0xc,%esp
801016c3:	68 18 6b 10 80       	push   $0x80106b18
801016c8:	e8 8f ec ff ff       	call   8010035c <panic>

801016cd <iunlock>:
{
801016cd:	f3 0f 1e fb          	endbr32 
801016d1:	55                   	push   %ebp
801016d2:	89 e5                	mov    %esp,%ebp
801016d4:	56                   	push   %esi
801016d5:	53                   	push   %ebx
801016d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
801016d9:	85 db                	test   %ebx,%ebx
801016db:	74 2c                	je     80101709 <iunlock+0x3c>
801016dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801016e0:	83 ec 0c             	sub    $0xc,%esp
801016e3:	56                   	push   %esi
801016e4:	e8 26 27 00 00       	call   80103e0f <holdingsleep>
801016e9:	83 c4 10             	add    $0x10,%esp
801016ec:	85 c0                	test   %eax,%eax
801016ee:	74 19                	je     80101709 <iunlock+0x3c>
801016f0:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
801016f4:	7e 13                	jle    80101709 <iunlock+0x3c>
  releasesleep(&ip->lock);
801016f6:	83 ec 0c             	sub    $0xc,%esp
801016f9:	56                   	push   %esi
801016fa:	e8 d1 26 00 00       	call   80103dd0 <releasesleep>
}
801016ff:	83 c4 10             	add    $0x10,%esp
80101702:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101705:	5b                   	pop    %ebx
80101706:	5e                   	pop    %esi
80101707:	5d                   	pop    %ebp
80101708:	c3                   	ret    
    panic("iunlock");
80101709:	83 ec 0c             	sub    $0xc,%esp
8010170c:	68 27 6b 10 80       	push   $0x80106b27
80101711:	e8 46 ec ff ff       	call   8010035c <panic>

80101716 <iput>:
{
80101716:	f3 0f 1e fb          	endbr32 
8010171a:	55                   	push   %ebp
8010171b:	89 e5                	mov    %esp,%ebp
8010171d:	57                   	push   %edi
8010171e:	56                   	push   %esi
8010171f:	53                   	push   %ebx
80101720:	83 ec 18             	sub    $0x18,%esp
80101723:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101726:	8d 73 0c             	lea    0xc(%ebx),%esi
80101729:	56                   	push   %esi
8010172a:	e8 4e 26 00 00       	call   80103d7d <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010172f:	83 c4 10             	add    $0x10,%esp
80101732:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101736:	74 07                	je     8010173f <iput+0x29>
80101738:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010173d:	74 35                	je     80101774 <iput+0x5e>
  releasesleep(&ip->lock);
8010173f:	83 ec 0c             	sub    $0xc,%esp
80101742:	56                   	push   %esi
80101743:	e8 88 26 00 00       	call   80103dd0 <releasesleep>
  acquire(&icache.lock);
80101748:	c7 04 24 40 2e 11 80 	movl   $0x80112e40,(%esp)
8010174f:	e8 36 28 00 00       	call   80103f8a <acquire>
  ip->ref--;
80101754:	8b 43 08             	mov    0x8(%ebx),%eax
80101757:	83 e8 01             	sub    $0x1,%eax
8010175a:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010175d:	c7 04 24 40 2e 11 80 	movl   $0x80112e40,(%esp)
80101764:	e8 8a 28 00 00       	call   80103ff3 <release>
}
80101769:	83 c4 10             	add    $0x10,%esp
8010176c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010176f:	5b                   	pop    %ebx
80101770:	5e                   	pop    %esi
80101771:	5f                   	pop    %edi
80101772:	5d                   	pop    %ebp
80101773:	c3                   	ret    
    acquire(&icache.lock);
80101774:	83 ec 0c             	sub    $0xc,%esp
80101777:	68 40 2e 11 80       	push   $0x80112e40
8010177c:	e8 09 28 00 00       	call   80103f8a <acquire>
    int r = ip->ref;
80101781:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
80101784:	c7 04 24 40 2e 11 80 	movl   $0x80112e40,(%esp)
8010178b:	e8 63 28 00 00       	call   80103ff3 <release>
    if(r == 1){
80101790:	83 c4 10             	add    $0x10,%esp
80101793:	83 ff 01             	cmp    $0x1,%edi
80101796:	75 a7                	jne    8010173f <iput+0x29>
      itrunc(ip);
80101798:	89 d8                	mov    %ebx,%eax
8010179a:	e8 82 fd ff ff       	call   80101521 <itrunc>
      ip->type = 0;
8010179f:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
801017a5:	83 ec 0c             	sub    $0xc,%esp
801017a8:	53                   	push   %ebx
801017a9:	e8 f0 fc ff ff       	call   8010149e <iupdate>
      ip->valid = 0;
801017ae:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
801017b5:	83 c4 10             	add    $0x10,%esp
801017b8:	eb 85                	jmp    8010173f <iput+0x29>

801017ba <iunlockput>:
{
801017ba:	f3 0f 1e fb          	endbr32 
801017be:	55                   	push   %ebp
801017bf:	89 e5                	mov    %esp,%ebp
801017c1:	53                   	push   %ebx
801017c2:	83 ec 10             	sub    $0x10,%esp
801017c5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
801017c8:	53                   	push   %ebx
801017c9:	e8 ff fe ff ff       	call   801016cd <iunlock>
  iput(ip);
801017ce:	89 1c 24             	mov    %ebx,(%esp)
801017d1:	e8 40 ff ff ff       	call   80101716 <iput>
}
801017d6:	83 c4 10             	add    $0x10,%esp
801017d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801017dc:	c9                   	leave  
801017dd:	c3                   	ret    

801017de <stati>:
{
801017de:	f3 0f 1e fb          	endbr32 
801017e2:	55                   	push   %ebp
801017e3:	89 e5                	mov    %esp,%ebp
801017e5:	8b 55 08             	mov    0x8(%ebp),%edx
801017e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
801017eb:	8b 0a                	mov    (%edx),%ecx
801017ed:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
801017f0:	8b 4a 04             	mov    0x4(%edx),%ecx
801017f3:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
801017f6:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
801017fa:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
801017fd:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101801:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
80101805:	8b 52 58             	mov    0x58(%edx),%edx
80101808:	89 50 10             	mov    %edx,0x10(%eax)
}
8010180b:	5d                   	pop    %ebp
8010180c:	c3                   	ret    

8010180d <readi>:
{
8010180d:	f3 0f 1e fb          	endbr32 
80101811:	55                   	push   %ebp
80101812:	89 e5                	mov    %esp,%ebp
80101814:	57                   	push   %edi
80101815:	56                   	push   %esi
80101816:	53                   	push   %ebx
80101817:	83 ec 1c             	sub    $0x1c,%esp
8010181a:	8b 75 10             	mov    0x10(%ebp),%esi
  if(ip->type == T_DEV){
8010181d:	8b 45 08             	mov    0x8(%ebp),%eax
80101820:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101825:	74 2c                	je     80101853 <readi+0x46>
  if(off > ip->size || off + n < off)
80101827:	8b 45 08             	mov    0x8(%ebp),%eax
8010182a:	8b 40 58             	mov    0x58(%eax),%eax
8010182d:	39 f0                	cmp    %esi,%eax
8010182f:	0f 82 cb 00 00 00    	jb     80101900 <readi+0xf3>
80101835:	89 f2                	mov    %esi,%edx
80101837:	03 55 14             	add    0x14(%ebp),%edx
8010183a:	0f 82 c7 00 00 00    	jb     80101907 <readi+0xfa>
  if(off + n > ip->size)
80101840:	39 d0                	cmp    %edx,%eax
80101842:	73 05                	jae    80101849 <readi+0x3c>
    n = ip->size - off;
80101844:	29 f0                	sub    %esi,%eax
80101846:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101849:	bf 00 00 00 00       	mov    $0x0,%edi
8010184e:	e9 8f 00 00 00       	jmp    801018e2 <readi+0xd5>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101853:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101857:	66 83 f8 09          	cmp    $0x9,%ax
8010185b:	0f 87 91 00 00 00    	ja     801018f2 <readi+0xe5>
80101861:	98                   	cwtl   
80101862:	8b 04 c5 c0 2d 11 80 	mov    -0x7feed240(,%eax,8),%eax
80101869:	85 c0                	test   %eax,%eax
8010186b:	0f 84 88 00 00 00    	je     801018f9 <readi+0xec>
    return devsw[ip->major].read(ip, dst, n);
80101871:	83 ec 04             	sub    $0x4,%esp
80101874:	ff 75 14             	pushl  0x14(%ebp)
80101877:	ff 75 0c             	pushl  0xc(%ebp)
8010187a:	ff 75 08             	pushl  0x8(%ebp)
8010187d:	ff d0                	call   *%eax
8010187f:	83 c4 10             	add    $0x10,%esp
80101882:	eb 66                	jmp    801018ea <readi+0xdd>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101884:	89 f2                	mov    %esi,%edx
80101886:	c1 ea 09             	shr    $0x9,%edx
80101889:	8b 45 08             	mov    0x8(%ebp),%eax
8010188c:	e8 be f8 ff ff       	call   8010114f <bmap>
80101891:	83 ec 08             	sub    $0x8,%esp
80101894:	50                   	push   %eax
80101895:	8b 45 08             	mov    0x8(%ebp),%eax
80101898:	ff 30                	pushl  (%eax)
8010189a:	e8 d1 e8 ff ff       	call   80100170 <bread>
8010189f:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
801018a1:	89 f0                	mov    %esi,%eax
801018a3:	25 ff 01 00 00       	and    $0x1ff,%eax
801018a8:	bb 00 02 00 00       	mov    $0x200,%ebx
801018ad:	29 c3                	sub    %eax,%ebx
801018af:	8b 55 14             	mov    0x14(%ebp),%edx
801018b2:	29 fa                	sub    %edi,%edx
801018b4:	83 c4 0c             	add    $0xc,%esp
801018b7:	39 d3                	cmp    %edx,%ebx
801018b9:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
801018bc:	53                   	push   %ebx
801018bd:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
801018c0:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
801018c4:	50                   	push   %eax
801018c5:	ff 75 0c             	pushl  0xc(%ebp)
801018c8:	e8 f1 27 00 00       	call   801040be <memmove>
    brelse(bp);
801018cd:	83 c4 04             	add    $0x4,%esp
801018d0:	ff 75 e4             	pushl  -0x1c(%ebp)
801018d3:	e8 09 e9 ff ff       	call   801001e1 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801018d8:	01 df                	add    %ebx,%edi
801018da:	01 de                	add    %ebx,%esi
801018dc:	01 5d 0c             	add    %ebx,0xc(%ebp)
801018df:	83 c4 10             	add    $0x10,%esp
801018e2:	39 7d 14             	cmp    %edi,0x14(%ebp)
801018e5:	77 9d                	ja     80101884 <readi+0x77>
  return n;
801018e7:	8b 45 14             	mov    0x14(%ebp),%eax
}
801018ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
801018ed:	5b                   	pop    %ebx
801018ee:	5e                   	pop    %esi
801018ef:	5f                   	pop    %edi
801018f0:	5d                   	pop    %ebp
801018f1:	c3                   	ret    
      return -1;
801018f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018f7:	eb f1                	jmp    801018ea <readi+0xdd>
801018f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018fe:	eb ea                	jmp    801018ea <readi+0xdd>
    return -1;
80101900:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101905:	eb e3                	jmp    801018ea <readi+0xdd>
80101907:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010190c:	eb dc                	jmp    801018ea <readi+0xdd>

8010190e <writei>:
{
8010190e:	f3 0f 1e fb          	endbr32 
80101912:	55                   	push   %ebp
80101913:	89 e5                	mov    %esp,%ebp
80101915:	57                   	push   %edi
80101916:	56                   	push   %esi
80101917:	53                   	push   %ebx
80101918:	83 ec 1c             	sub    $0x1c,%esp
8010191b:	8b 75 10             	mov    0x10(%ebp),%esi
  if(ip->type == T_DEV){
8010191e:	8b 45 08             	mov    0x8(%ebp),%eax
80101921:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101926:	0f 84 9b 00 00 00    	je     801019c7 <writei+0xb9>
  if(off > ip->size || off + n < off)
8010192c:	8b 45 08             	mov    0x8(%ebp),%eax
8010192f:	39 70 58             	cmp    %esi,0x58(%eax)
80101932:	0f 82 f0 00 00 00    	jb     80101a28 <writei+0x11a>
80101938:	89 f0                	mov    %esi,%eax
8010193a:	03 45 14             	add    0x14(%ebp),%eax
8010193d:	0f 82 ec 00 00 00    	jb     80101a2f <writei+0x121>
  if(off + n > MAXFILE*BSIZE)
80101943:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101948:	0f 87 e8 00 00 00    	ja     80101a36 <writei+0x128>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010194e:	bf 00 00 00 00       	mov    $0x0,%edi
80101953:	3b 7d 14             	cmp    0x14(%ebp),%edi
80101956:	0f 83 94 00 00 00    	jae    801019f0 <writei+0xe2>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010195c:	89 f2                	mov    %esi,%edx
8010195e:	c1 ea 09             	shr    $0x9,%edx
80101961:	8b 45 08             	mov    0x8(%ebp),%eax
80101964:	e8 e6 f7 ff ff       	call   8010114f <bmap>
80101969:	83 ec 08             	sub    $0x8,%esp
8010196c:	50                   	push   %eax
8010196d:	8b 45 08             	mov    0x8(%ebp),%eax
80101970:	ff 30                	pushl  (%eax)
80101972:	e8 f9 e7 ff ff       	call   80100170 <bread>
80101977:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101979:	89 f0                	mov    %esi,%eax
8010197b:	25 ff 01 00 00       	and    $0x1ff,%eax
80101980:	bb 00 02 00 00       	mov    $0x200,%ebx
80101985:	29 c3                	sub    %eax,%ebx
80101987:	8b 55 14             	mov    0x14(%ebp),%edx
8010198a:	29 fa                	sub    %edi,%edx
8010198c:	83 c4 0c             	add    $0xc,%esp
8010198f:	39 d3                	cmp    %edx,%ebx
80101991:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
80101994:	53                   	push   %ebx
80101995:	ff 75 0c             	pushl  0xc(%ebp)
80101998:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
8010199b:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
8010199f:	50                   	push   %eax
801019a0:	e8 19 27 00 00       	call   801040be <memmove>
    log_write(bp);
801019a5:	83 c4 04             	add    $0x4,%esp
801019a8:	ff 75 e4             	pushl  -0x1c(%ebp)
801019ab:	e8 0d 10 00 00       	call   801029bd <log_write>
    brelse(bp);
801019b0:	83 c4 04             	add    $0x4,%esp
801019b3:	ff 75 e4             	pushl  -0x1c(%ebp)
801019b6:	e8 26 e8 ff ff       	call   801001e1 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801019bb:	01 df                	add    %ebx,%edi
801019bd:	01 de                	add    %ebx,%esi
801019bf:	01 5d 0c             	add    %ebx,0xc(%ebp)
801019c2:	83 c4 10             	add    $0x10,%esp
801019c5:	eb 8c                	jmp    80101953 <writei+0x45>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801019c7:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801019cb:	66 83 f8 09          	cmp    $0x9,%ax
801019cf:	77 49                	ja     80101a1a <writei+0x10c>
801019d1:	98                   	cwtl   
801019d2:	8b 04 c5 c4 2d 11 80 	mov    -0x7feed23c(,%eax,8),%eax
801019d9:	85 c0                	test   %eax,%eax
801019db:	74 44                	je     80101a21 <writei+0x113>
    return devsw[ip->major].write(ip, src, n);
801019dd:	83 ec 04             	sub    $0x4,%esp
801019e0:	ff 75 14             	pushl  0x14(%ebp)
801019e3:	ff 75 0c             	pushl  0xc(%ebp)
801019e6:	ff 75 08             	pushl  0x8(%ebp)
801019e9:	ff d0                	call   *%eax
801019eb:	83 c4 10             	add    $0x10,%esp
801019ee:	eb 11                	jmp    80101a01 <writei+0xf3>
  if(n > 0 && off > ip->size){
801019f0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801019f4:	74 08                	je     801019fe <writei+0xf0>
801019f6:	8b 45 08             	mov    0x8(%ebp),%eax
801019f9:	39 70 58             	cmp    %esi,0x58(%eax)
801019fc:	72 0b                	jb     80101a09 <writei+0xfb>
  return n;
801019fe:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101a01:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a04:	5b                   	pop    %ebx
80101a05:	5e                   	pop    %esi
80101a06:	5f                   	pop    %edi
80101a07:	5d                   	pop    %ebp
80101a08:	c3                   	ret    
    ip->size = off;
80101a09:	89 70 58             	mov    %esi,0x58(%eax)
    iupdate(ip);
80101a0c:	83 ec 0c             	sub    $0xc,%esp
80101a0f:	50                   	push   %eax
80101a10:	e8 89 fa ff ff       	call   8010149e <iupdate>
80101a15:	83 c4 10             	add    $0x10,%esp
80101a18:	eb e4                	jmp    801019fe <writei+0xf0>
      return -1;
80101a1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a1f:	eb e0                	jmp    80101a01 <writei+0xf3>
80101a21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a26:	eb d9                	jmp    80101a01 <writei+0xf3>
    return -1;
80101a28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a2d:	eb d2                	jmp    80101a01 <writei+0xf3>
80101a2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a34:	eb cb                	jmp    80101a01 <writei+0xf3>
    return -1;
80101a36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a3b:	eb c4                	jmp    80101a01 <writei+0xf3>

80101a3d <namecmp>:
{
80101a3d:	f3 0f 1e fb          	endbr32 
80101a41:	55                   	push   %ebp
80101a42:	89 e5                	mov    %esp,%ebp
80101a44:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
80101a47:	6a 0e                	push   $0xe
80101a49:	ff 75 0c             	pushl  0xc(%ebp)
80101a4c:	ff 75 08             	pushl  0x8(%ebp)
80101a4f:	e8 dc 26 00 00       	call   80104130 <strncmp>
}
80101a54:	c9                   	leave  
80101a55:	c3                   	ret    

80101a56 <dirlookup>:
{
80101a56:	f3 0f 1e fb          	endbr32 
80101a5a:	55                   	push   %ebp
80101a5b:	89 e5                	mov    %esp,%ebp
80101a5d:	57                   	push   %edi
80101a5e:	56                   	push   %esi
80101a5f:	53                   	push   %ebx
80101a60:	83 ec 1c             	sub    $0x1c,%esp
80101a63:	8b 75 08             	mov    0x8(%ebp),%esi
80101a66:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
80101a69:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101a6e:	75 07                	jne    80101a77 <dirlookup+0x21>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101a70:	bb 00 00 00 00       	mov    $0x0,%ebx
80101a75:	eb 1d                	jmp    80101a94 <dirlookup+0x3e>
    panic("dirlookup not DIR");
80101a77:	83 ec 0c             	sub    $0xc,%esp
80101a7a:	68 2f 6b 10 80       	push   $0x80106b2f
80101a7f:	e8 d8 e8 ff ff       	call   8010035c <panic>
      panic("dirlookup read");
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	68 41 6b 10 80       	push   $0x80106b41
80101a8c:	e8 cb e8 ff ff       	call   8010035c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101a91:	83 c3 10             	add    $0x10,%ebx
80101a94:	39 5e 58             	cmp    %ebx,0x58(%esi)
80101a97:	76 48                	jbe    80101ae1 <dirlookup+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101a99:	6a 10                	push   $0x10
80101a9b:	53                   	push   %ebx
80101a9c:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101a9f:	50                   	push   %eax
80101aa0:	56                   	push   %esi
80101aa1:	e8 67 fd ff ff       	call   8010180d <readi>
80101aa6:	83 c4 10             	add    $0x10,%esp
80101aa9:	83 f8 10             	cmp    $0x10,%eax
80101aac:	75 d6                	jne    80101a84 <dirlookup+0x2e>
    if(de.inum == 0)
80101aae:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101ab3:	74 dc                	je     80101a91 <dirlookup+0x3b>
    if(namecmp(name, de.name) == 0){
80101ab5:	83 ec 08             	sub    $0x8,%esp
80101ab8:	8d 45 da             	lea    -0x26(%ebp),%eax
80101abb:	50                   	push   %eax
80101abc:	57                   	push   %edi
80101abd:	e8 7b ff ff ff       	call   80101a3d <namecmp>
80101ac2:	83 c4 10             	add    $0x10,%esp
80101ac5:	85 c0                	test   %eax,%eax
80101ac7:	75 c8                	jne    80101a91 <dirlookup+0x3b>
      if(poff)
80101ac9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101acd:	74 05                	je     80101ad4 <dirlookup+0x7e>
        *poff = off;
80101acf:	8b 45 10             	mov    0x10(%ebp),%eax
80101ad2:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101ad4:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101ad8:	8b 06                	mov    (%esi),%eax
80101ada:	e8 16 f7 ff ff       	call   801011f5 <iget>
80101adf:	eb 05                	jmp    80101ae6 <dirlookup+0x90>
  return 0;
80101ae1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101ae6:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101ae9:	5b                   	pop    %ebx
80101aea:	5e                   	pop    %esi
80101aeb:	5f                   	pop    %edi
80101aec:	5d                   	pop    %ebp
80101aed:	c3                   	ret    

80101aee <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101aee:	55                   	push   %ebp
80101aef:	89 e5                	mov    %esp,%ebp
80101af1:	57                   	push   %edi
80101af2:	56                   	push   %esi
80101af3:	53                   	push   %ebx
80101af4:	83 ec 1c             	sub    $0x1c,%esp
80101af7:	89 c3                	mov    %eax,%ebx
80101af9:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101afc:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101aff:	80 38 2f             	cmpb   $0x2f,(%eax)
80101b02:	74 17                	je     80101b1b <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101b04:	e8 2f 18 00 00       	call   80103338 <myproc>
80101b09:	83 ec 0c             	sub    $0xc,%esp
80101b0c:	ff 70 68             	pushl  0x68(%eax)
80101b0f:	e8 bf fa ff ff       	call   801015d3 <idup>
80101b14:	89 c6                	mov    %eax,%esi
80101b16:	83 c4 10             	add    $0x10,%esp
80101b19:	eb 53                	jmp    80101b6e <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101b1b:	ba 01 00 00 00       	mov    $0x1,%edx
80101b20:	b8 01 00 00 00       	mov    $0x1,%eax
80101b25:	e8 cb f6 ff ff       	call   801011f5 <iget>
80101b2a:	89 c6                	mov    %eax,%esi
80101b2c:	eb 40                	jmp    80101b6e <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101b2e:	83 ec 0c             	sub    $0xc,%esp
80101b31:	56                   	push   %esi
80101b32:	e8 83 fc ff ff       	call   801017ba <iunlockput>
      return 0;
80101b37:	83 c4 10             	add    $0x10,%esp
80101b3a:	be 00 00 00 00       	mov    $0x0,%esi
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101b3f:	89 f0                	mov    %esi,%eax
80101b41:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101b44:	5b                   	pop    %ebx
80101b45:	5e                   	pop    %esi
80101b46:	5f                   	pop    %edi
80101b47:	5d                   	pop    %ebp
80101b48:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101b49:	83 ec 04             	sub    $0x4,%esp
80101b4c:	6a 00                	push   $0x0
80101b4e:	ff 75 e4             	pushl  -0x1c(%ebp)
80101b51:	56                   	push   %esi
80101b52:	e8 ff fe ff ff       	call   80101a56 <dirlookup>
80101b57:	89 c7                	mov    %eax,%edi
80101b59:	83 c4 10             	add    $0x10,%esp
80101b5c:	85 c0                	test   %eax,%eax
80101b5e:	74 4a                	je     80101baa <namex+0xbc>
    iunlockput(ip);
80101b60:	83 ec 0c             	sub    $0xc,%esp
80101b63:	56                   	push   %esi
80101b64:	e8 51 fc ff ff       	call   801017ba <iunlockput>
80101b69:	83 c4 10             	add    $0x10,%esp
    ip = next;
80101b6c:	89 fe                	mov    %edi,%esi
  while((path = skipelem(path, name)) != 0){
80101b6e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101b71:	89 d8                	mov    %ebx,%eax
80101b73:	e8 3b f4 ff ff       	call   80100fb3 <skipelem>
80101b78:	89 c3                	mov    %eax,%ebx
80101b7a:	85 c0                	test   %eax,%eax
80101b7c:	74 3c                	je     80101bba <namex+0xcc>
    ilock(ip);
80101b7e:	83 ec 0c             	sub    $0xc,%esp
80101b81:	56                   	push   %esi
80101b82:	e8 80 fa ff ff       	call   80101607 <ilock>
    if(ip->type != T_DIR){
80101b87:	83 c4 10             	add    $0x10,%esp
80101b8a:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101b8f:	75 9d                	jne    80101b2e <namex+0x40>
    if(nameiparent && *path == '\0'){
80101b91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b95:	74 b2                	je     80101b49 <namex+0x5b>
80101b97:	80 3b 00             	cmpb   $0x0,(%ebx)
80101b9a:	75 ad                	jne    80101b49 <namex+0x5b>
      iunlock(ip);
80101b9c:	83 ec 0c             	sub    $0xc,%esp
80101b9f:	56                   	push   %esi
80101ba0:	e8 28 fb ff ff       	call   801016cd <iunlock>
      return ip;
80101ba5:	83 c4 10             	add    $0x10,%esp
80101ba8:	eb 95                	jmp    80101b3f <namex+0x51>
      iunlockput(ip);
80101baa:	83 ec 0c             	sub    $0xc,%esp
80101bad:	56                   	push   %esi
80101bae:	e8 07 fc ff ff       	call   801017ba <iunlockput>
      return 0;
80101bb3:	83 c4 10             	add    $0x10,%esp
80101bb6:	89 fe                	mov    %edi,%esi
80101bb8:	eb 85                	jmp    80101b3f <namex+0x51>
  if(nameiparent){
80101bba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101bbe:	0f 84 7b ff ff ff    	je     80101b3f <namex+0x51>
    iput(ip);
80101bc4:	83 ec 0c             	sub    $0xc,%esp
80101bc7:	56                   	push   %esi
80101bc8:	e8 49 fb ff ff       	call   80101716 <iput>
    return 0;
80101bcd:	83 c4 10             	add    $0x10,%esp
80101bd0:	89 de                	mov    %ebx,%esi
80101bd2:	e9 68 ff ff ff       	jmp    80101b3f <namex+0x51>

80101bd7 <dirlink>:
{
80101bd7:	f3 0f 1e fb          	endbr32 
80101bdb:	55                   	push   %ebp
80101bdc:	89 e5                	mov    %esp,%ebp
80101bde:	57                   	push   %edi
80101bdf:	56                   	push   %esi
80101be0:	53                   	push   %ebx
80101be1:	83 ec 20             	sub    $0x20,%esp
80101be4:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101be7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101bea:	6a 00                	push   $0x0
80101bec:	57                   	push   %edi
80101bed:	53                   	push   %ebx
80101bee:	e8 63 fe ff ff       	call   80101a56 <dirlookup>
80101bf3:	83 c4 10             	add    $0x10,%esp
80101bf6:	85 c0                	test   %eax,%eax
80101bf8:	75 07                	jne    80101c01 <dirlink+0x2a>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101bfa:	b8 00 00 00 00       	mov    $0x0,%eax
80101bff:	eb 23                	jmp    80101c24 <dirlink+0x4d>
    iput(ip);
80101c01:	83 ec 0c             	sub    $0xc,%esp
80101c04:	50                   	push   %eax
80101c05:	e8 0c fb ff ff       	call   80101716 <iput>
    return -1;
80101c0a:	83 c4 10             	add    $0x10,%esp
80101c0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c12:	eb 63                	jmp    80101c77 <dirlink+0xa0>
      panic("dirlink read");
80101c14:	83 ec 0c             	sub    $0xc,%esp
80101c17:	68 50 6b 10 80       	push   $0x80106b50
80101c1c:	e8 3b e7 ff ff       	call   8010035c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101c21:	8d 46 10             	lea    0x10(%esi),%eax
80101c24:	89 c6                	mov    %eax,%esi
80101c26:	39 43 58             	cmp    %eax,0x58(%ebx)
80101c29:	76 1c                	jbe    80101c47 <dirlink+0x70>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101c2b:	6a 10                	push   $0x10
80101c2d:	50                   	push   %eax
80101c2e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101c31:	50                   	push   %eax
80101c32:	53                   	push   %ebx
80101c33:	e8 d5 fb ff ff       	call   8010180d <readi>
80101c38:	83 c4 10             	add    $0x10,%esp
80101c3b:	83 f8 10             	cmp    $0x10,%eax
80101c3e:	75 d4                	jne    80101c14 <dirlink+0x3d>
    if(de.inum == 0)
80101c40:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101c45:	75 da                	jne    80101c21 <dirlink+0x4a>
  strncpy(de.name, name, DIRSIZ);
80101c47:	83 ec 04             	sub    $0x4,%esp
80101c4a:	6a 0e                	push   $0xe
80101c4c:	57                   	push   %edi
80101c4d:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101c50:	8d 45 da             	lea    -0x26(%ebp),%eax
80101c53:	50                   	push   %eax
80101c54:	e8 18 25 00 00       	call   80104171 <strncpy>
  de.inum = inum;
80101c59:	8b 45 10             	mov    0x10(%ebp),%eax
80101c5c:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101c60:	6a 10                	push   $0x10
80101c62:	56                   	push   %esi
80101c63:	57                   	push   %edi
80101c64:	53                   	push   %ebx
80101c65:	e8 a4 fc ff ff       	call   8010190e <writei>
80101c6a:	83 c4 20             	add    $0x20,%esp
80101c6d:	83 f8 10             	cmp    $0x10,%eax
80101c70:	75 0d                	jne    80101c7f <dirlink+0xa8>
  return 0;
80101c72:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c77:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101c7a:	5b                   	pop    %ebx
80101c7b:	5e                   	pop    %esi
80101c7c:	5f                   	pop    %edi
80101c7d:	5d                   	pop    %ebp
80101c7e:	c3                   	ret    
    panic("dirlink");
80101c7f:	83 ec 0c             	sub    $0xc,%esp
80101c82:	68 b0 71 10 80       	push   $0x801071b0
80101c87:	e8 d0 e6 ff ff       	call   8010035c <panic>

80101c8c <namei>:

struct inode*
namei(char *path)
{
80101c8c:	f3 0f 1e fb          	endbr32 
80101c90:	55                   	push   %ebp
80101c91:	89 e5                	mov    %esp,%ebp
80101c93:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101c96:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101c99:	ba 00 00 00 00       	mov    $0x0,%edx
80101c9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca1:	e8 48 fe ff ff       	call   80101aee <namex>
}
80101ca6:	c9                   	leave  
80101ca7:	c3                   	ret    

80101ca8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101ca8:	f3 0f 1e fb          	endbr32 
80101cac:	55                   	push   %ebp
80101cad:	89 e5                	mov    %esp,%ebp
80101caf:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101cb2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101cb5:	ba 01 00 00 00       	mov    $0x1,%edx
80101cba:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbd:	e8 2c fe ff ff       	call   80101aee <namex>
}
80101cc2:	c9                   	leave  
80101cc3:	c3                   	ret    

80101cc4 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101cc4:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101cc6:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ccb:	ec                   	in     (%dx),%al
80101ccc:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101cce:	83 e0 c0             	and    $0xffffffc0,%eax
80101cd1:	3c 40                	cmp    $0x40,%al
80101cd3:	75 f1                	jne    80101cc6 <idewait+0x2>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101cd5:	85 c9                	test   %ecx,%ecx
80101cd7:	74 0a                	je     80101ce3 <idewait+0x1f>
80101cd9:	f6 c2 21             	test   $0x21,%dl
80101cdc:	75 08                	jne    80101ce6 <idewait+0x22>
    return -1;
  return 0;
80101cde:	b9 00 00 00 00       	mov    $0x0,%ecx
}
80101ce3:	89 c8                	mov    %ecx,%eax
80101ce5:	c3                   	ret    
    return -1;
80101ce6:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
80101ceb:	eb f6                	jmp    80101ce3 <idewait+0x1f>

80101ced <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101ced:	55                   	push   %ebp
80101cee:	89 e5                	mov    %esp,%ebp
80101cf0:	56                   	push   %esi
80101cf1:	53                   	push   %ebx
  if(b == 0)
80101cf2:	85 c0                	test   %eax,%eax
80101cf4:	0f 84 91 00 00 00    	je     80101d8b <idestart+0x9e>
80101cfa:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101cfc:	8b 58 08             	mov    0x8(%eax),%ebx
80101cff:	81 fb cf 07 00 00    	cmp    $0x7cf,%ebx
80101d05:	0f 87 8d 00 00 00    	ja     80101d98 <idestart+0xab>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101d0b:	b8 00 00 00 00       	mov    $0x0,%eax
80101d10:	e8 af ff ff ff       	call   80101cc4 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d15:	b8 00 00 00 00       	mov    $0x0,%eax
80101d1a:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101d1f:	ee                   	out    %al,(%dx)
80101d20:	b8 01 00 00 00       	mov    $0x1,%eax
80101d25:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101d2a:	ee                   	out    %al,(%dx)
80101d2b:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101d30:	89 d8                	mov    %ebx,%eax
80101d32:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101d33:	89 d8                	mov    %ebx,%eax
80101d35:	c1 f8 08             	sar    $0x8,%eax
80101d38:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101d3d:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101d3e:	89 d8                	mov    %ebx,%eax
80101d40:	c1 f8 10             	sar    $0x10,%eax
80101d43:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101d48:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101d49:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101d4d:	c1 e0 04             	shl    $0x4,%eax
80101d50:	83 e0 10             	and    $0x10,%eax
80101d53:	c1 fb 18             	sar    $0x18,%ebx
80101d56:	83 e3 0f             	and    $0xf,%ebx
80101d59:	09 d8                	or     %ebx,%eax
80101d5b:	83 c8 e0             	or     $0xffffffe0,%eax
80101d5e:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d63:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101d64:	f6 06 04             	testb  $0x4,(%esi)
80101d67:	74 3c                	je     80101da5 <idestart+0xb8>
80101d69:	b8 30 00 00 00       	mov    $0x30,%eax
80101d6e:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d73:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
80101d74:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101d77:	b9 80 00 00 00       	mov    $0x80,%ecx
80101d7c:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101d81:	fc                   	cld    
80101d82:	f3 6f                	rep outsl %ds:(%esi),(%dx)
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101d84:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101d87:	5b                   	pop    %ebx
80101d88:	5e                   	pop    %esi
80101d89:	5d                   	pop    %ebp
80101d8a:	c3                   	ret    
    panic("idestart");
80101d8b:	83 ec 0c             	sub    $0xc,%esp
80101d8e:	68 b3 6b 10 80       	push   $0x80106bb3
80101d93:	e8 c4 e5 ff ff       	call   8010035c <panic>
    panic("incorrect blockno");
80101d98:	83 ec 0c             	sub    $0xc,%esp
80101d9b:	68 bc 6b 10 80       	push   $0x80106bbc
80101da0:	e8 b7 e5 ff ff       	call   8010035c <panic>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101da5:	b8 20 00 00 00       	mov    $0x20,%eax
80101daa:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101daf:	ee                   	out    %al,(%dx)
}
80101db0:	eb d2                	jmp    80101d84 <idestart+0x97>

80101db2 <ideinit>:
{
80101db2:	f3 0f 1e fb          	endbr32 
80101db6:	55                   	push   %ebp
80101db7:	89 e5                	mov    %esp,%ebp
80101db9:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101dbc:	68 ce 6b 10 80       	push   $0x80106bce
80101dc1:	68 80 a5 10 80       	push   $0x8010a580
80101dc6:	e8 6f 20 00 00       	call   80103e3a <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101dcb:	83 c4 08             	add    $0x8,%esp
80101dce:	a1 60 51 11 80       	mov    0x80115160,%eax
80101dd3:	83 e8 01             	sub    $0x1,%eax
80101dd6:	50                   	push   %eax
80101dd7:	6a 0e                	push   $0xe
80101dd9:	e8 5a 02 00 00       	call   80102038 <ioapicenable>
  idewait(0);
80101dde:	b8 00 00 00 00       	mov    $0x0,%eax
80101de3:	e8 dc fe ff ff       	call   80101cc4 <idewait>
80101de8:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101ded:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101df2:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101df3:	83 c4 10             	add    $0x10,%esp
80101df6:	b9 00 00 00 00       	mov    $0x0,%ecx
80101dfb:	eb 03                	jmp    80101e00 <ideinit+0x4e>
80101dfd:	83 c1 01             	add    $0x1,%ecx
80101e00:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101e06:	7f 14                	jg     80101e1c <ideinit+0x6a>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101e08:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101e0d:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101e0e:	84 c0                	test   %al,%al
80101e10:	74 eb                	je     80101dfd <ideinit+0x4b>
      havedisk1 = 1;
80101e12:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
80101e19:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101e1c:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101e21:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101e26:	ee                   	out    %al,(%dx)
}
80101e27:	c9                   	leave  
80101e28:	c3                   	ret    

80101e29 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101e29:	f3 0f 1e fb          	endbr32 
80101e2d:	55                   	push   %ebp
80101e2e:	89 e5                	mov    %esp,%ebp
80101e30:	57                   	push   %edi
80101e31:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101e32:	83 ec 0c             	sub    $0xc,%esp
80101e35:	68 80 a5 10 80       	push   $0x8010a580
80101e3a:	e8 4b 21 00 00       	call   80103f8a <acquire>

  if((b = idequeue) == 0){
80101e3f:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101e45:	83 c4 10             	add    $0x10,%esp
80101e48:	85 db                	test   %ebx,%ebx
80101e4a:	74 48                	je     80101e94 <ideintr+0x6b>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101e4c:	8b 43 58             	mov    0x58(%ebx),%eax
80101e4f:	a3 64 a5 10 80       	mov    %eax,0x8010a564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101e54:	f6 03 04             	testb  $0x4,(%ebx)
80101e57:	74 4d                	je     80101ea6 <ideintr+0x7d>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101e59:	8b 03                	mov    (%ebx),%eax
80101e5b:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101e5e:	83 e0 fb             	and    $0xfffffffb,%eax
80101e61:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101e63:	83 ec 0c             	sub    $0xc,%esp
80101e66:	53                   	push   %ebx
80101e67:	e8 70 1b 00 00       	call   801039dc <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101e6c:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101e71:	83 c4 10             	add    $0x10,%esp
80101e74:	85 c0                	test   %eax,%eax
80101e76:	74 05                	je     80101e7d <ideintr+0x54>
    idestart(idequeue);
80101e78:	e8 70 fe ff ff       	call   80101ced <idestart>

  release(&idelock);
80101e7d:	83 ec 0c             	sub    $0xc,%esp
80101e80:	68 80 a5 10 80       	push   $0x8010a580
80101e85:	e8 69 21 00 00       	call   80103ff3 <release>
80101e8a:	83 c4 10             	add    $0x10,%esp
}
80101e8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101e90:	5b                   	pop    %ebx
80101e91:	5f                   	pop    %edi
80101e92:	5d                   	pop    %ebp
80101e93:	c3                   	ret    
    release(&idelock);
80101e94:	83 ec 0c             	sub    $0xc,%esp
80101e97:	68 80 a5 10 80       	push   $0x8010a580
80101e9c:	e8 52 21 00 00       	call   80103ff3 <release>
    return;
80101ea1:	83 c4 10             	add    $0x10,%esp
80101ea4:	eb e7                	jmp    80101e8d <ideintr+0x64>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101ea6:	b8 01 00 00 00       	mov    $0x1,%eax
80101eab:	e8 14 fe ff ff       	call   80101cc4 <idewait>
80101eb0:	85 c0                	test   %eax,%eax
80101eb2:	78 a5                	js     80101e59 <ideintr+0x30>
    insl(0x1f0, b->data, BSIZE/4);
80101eb4:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101eb7:	b9 80 00 00 00       	mov    $0x80,%ecx
80101ebc:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101ec1:	fc                   	cld    
80101ec2:	f3 6d                	rep insl (%dx),%es:(%edi)
}
80101ec4:	eb 93                	jmp    80101e59 <ideintr+0x30>

80101ec6 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101ec6:	f3 0f 1e fb          	endbr32 
80101eca:	55                   	push   %ebp
80101ecb:	89 e5                	mov    %esp,%ebp
80101ecd:	53                   	push   %ebx
80101ece:	83 ec 10             	sub    $0x10,%esp
80101ed1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101ed4:	8d 43 0c             	lea    0xc(%ebx),%eax
80101ed7:	50                   	push   %eax
80101ed8:	e8 32 1f 00 00       	call   80103e0f <holdingsleep>
80101edd:	83 c4 10             	add    $0x10,%esp
80101ee0:	85 c0                	test   %eax,%eax
80101ee2:	74 37                	je     80101f1b <iderw+0x55>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101ee4:	8b 03                	mov    (%ebx),%eax
80101ee6:	83 e0 06             	and    $0x6,%eax
80101ee9:	83 f8 02             	cmp    $0x2,%eax
80101eec:	74 3a                	je     80101f28 <iderw+0x62>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101eee:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101ef2:	74 09                	je     80101efd <iderw+0x37>
80101ef4:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101efb:	74 38                	je     80101f35 <iderw+0x6f>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101efd:	83 ec 0c             	sub    $0xc,%esp
80101f00:	68 80 a5 10 80       	push   $0x8010a580
80101f05:	e8 80 20 00 00       	call   80103f8a <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101f0a:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101f11:	83 c4 10             	add    $0x10,%esp
80101f14:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101f19:	eb 2a                	jmp    80101f45 <iderw+0x7f>
    panic("iderw: buf not locked");
80101f1b:	83 ec 0c             	sub    $0xc,%esp
80101f1e:	68 d2 6b 10 80       	push   $0x80106bd2
80101f23:	e8 34 e4 ff ff       	call   8010035c <panic>
    panic("iderw: nothing to do");
80101f28:	83 ec 0c             	sub    $0xc,%esp
80101f2b:	68 e8 6b 10 80       	push   $0x80106be8
80101f30:	e8 27 e4 ff ff       	call   8010035c <panic>
    panic("iderw: ide disk 1 not present");
80101f35:	83 ec 0c             	sub    $0xc,%esp
80101f38:	68 fd 6b 10 80       	push   $0x80106bfd
80101f3d:	e8 1a e4 ff ff       	call   8010035c <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101f42:	8d 50 58             	lea    0x58(%eax),%edx
80101f45:	8b 02                	mov    (%edx),%eax
80101f47:	85 c0                	test   %eax,%eax
80101f49:	75 f7                	jne    80101f42 <iderw+0x7c>
    ;
  *pp = b;
80101f4b:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101f4d:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101f53:	75 1a                	jne    80101f6f <iderw+0xa9>
    idestart(b);
80101f55:	89 d8                	mov    %ebx,%eax
80101f57:	e8 91 fd ff ff       	call   80101ced <idestart>
80101f5c:	eb 11                	jmp    80101f6f <iderw+0xa9>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101f5e:	83 ec 08             	sub    $0x8,%esp
80101f61:	68 80 a5 10 80       	push   $0x8010a580
80101f66:	53                   	push   %ebx
80101f67:	e8 01 19 00 00       	call   8010386d <sleep>
80101f6c:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101f6f:	8b 03                	mov    (%ebx),%eax
80101f71:	83 e0 06             	and    $0x6,%eax
80101f74:	83 f8 02             	cmp    $0x2,%eax
80101f77:	75 e5                	jne    80101f5e <iderw+0x98>
  }


  release(&idelock);
80101f79:	83 ec 0c             	sub    $0xc,%esp
80101f7c:	68 80 a5 10 80       	push   $0x8010a580
80101f81:	e8 6d 20 00 00       	call   80103ff3 <release>
}
80101f86:	83 c4 10             	add    $0x10,%esp
80101f89:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101f8c:	c9                   	leave  
80101f8d:	c3                   	ret    

80101f8e <ioapicread>:
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
80101f8e:	8b 15 94 4a 11 80    	mov    0x80114a94,%edx
80101f94:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101f96:	a1 94 4a 11 80       	mov    0x80114a94,%eax
80101f9b:	8b 40 10             	mov    0x10(%eax),%eax
}
80101f9e:	c3                   	ret    

80101f9f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
80101f9f:	8b 0d 94 4a 11 80    	mov    0x80114a94,%ecx
80101fa5:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101fa7:	a1 94 4a 11 80       	mov    0x80114a94,%eax
80101fac:	89 50 10             	mov    %edx,0x10(%eax)
}
80101faf:	c3                   	ret    

80101fb0 <ioapicinit>:

void
ioapicinit(void)
{
80101fb0:	f3 0f 1e fb          	endbr32 
80101fb4:	55                   	push   %ebp
80101fb5:	89 e5                	mov    %esp,%ebp
80101fb7:	57                   	push   %edi
80101fb8:	56                   	push   %esi
80101fb9:	53                   	push   %ebx
80101fba:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101fbd:	c7 05 94 4a 11 80 00 	movl   $0xfec00000,0x80114a94
80101fc4:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101fc7:	b8 01 00 00 00       	mov    $0x1,%eax
80101fcc:	e8 bd ff ff ff       	call   80101f8e <ioapicread>
80101fd1:	c1 e8 10             	shr    $0x10,%eax
80101fd4:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101fd7:	b8 00 00 00 00       	mov    $0x0,%eax
80101fdc:	e8 ad ff ff ff       	call   80101f8e <ioapicread>
80101fe1:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101fe4:	0f b6 15 c0 4b 11 80 	movzbl 0x80114bc0,%edx
80101feb:	39 c2                	cmp    %eax,%edx
80101fed:	75 2f                	jne    8010201e <ioapicinit+0x6e>
{
80101fef:	bb 00 00 00 00       	mov    $0x0,%ebx
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80101ff4:	39 fb                	cmp    %edi,%ebx
80101ff6:	7f 38                	jg     80102030 <ioapicinit+0x80>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101ff8:	8d 53 20             	lea    0x20(%ebx),%edx
80101ffb:	81 ca 00 00 01 00    	or     $0x10000,%edx
80102001:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80102005:	89 f0                	mov    %esi,%eax
80102007:	e8 93 ff ff ff       	call   80101f9f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010200c:	8d 46 01             	lea    0x1(%esi),%eax
8010200f:	ba 00 00 00 00       	mov    $0x0,%edx
80102014:	e8 86 ff ff ff       	call   80101f9f <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80102019:	83 c3 01             	add    $0x1,%ebx
8010201c:	eb d6                	jmp    80101ff4 <ioapicinit+0x44>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010201e:	83 ec 0c             	sub    $0xc,%esp
80102021:	68 1c 6c 10 80       	push   $0x80106c1c
80102026:	e8 fe e5 ff ff       	call   80100629 <cprintf>
8010202b:	83 c4 10             	add    $0x10,%esp
8010202e:	eb bf                	jmp    80101fef <ioapicinit+0x3f>
  }
}
80102030:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102033:	5b                   	pop    %ebx
80102034:	5e                   	pop    %esi
80102035:	5f                   	pop    %edi
80102036:	5d                   	pop    %ebp
80102037:	c3                   	ret    

80102038 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102038:	f3 0f 1e fb          	endbr32 
8010203c:	55                   	push   %ebp
8010203d:	89 e5                	mov    %esp,%ebp
8010203f:	53                   	push   %ebx
80102040:	83 ec 04             	sub    $0x4,%esp
80102043:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102046:	8d 50 20             	lea    0x20(%eax),%edx
80102049:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
8010204d:	89 d8                	mov    %ebx,%eax
8010204f:	e8 4b ff ff ff       	call   80101f9f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102054:	8b 55 0c             	mov    0xc(%ebp),%edx
80102057:	c1 e2 18             	shl    $0x18,%edx
8010205a:	8d 43 01             	lea    0x1(%ebx),%eax
8010205d:	e8 3d ff ff ff       	call   80101f9f <ioapicwrite>
}
80102062:	83 c4 04             	add    $0x4,%esp
80102065:	5b                   	pop    %ebx
80102066:	5d                   	pop    %ebp
80102067:	c3                   	ret    

80102068 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102068:	f3 0f 1e fb          	endbr32 
8010206c:	55                   	push   %ebp
8010206d:	89 e5                	mov    %esp,%ebp
8010206f:	53                   	push   %ebx
80102070:	83 ec 04             	sub    $0x4,%esp
80102073:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102076:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
8010207c:	75 4c                	jne    801020ca <kfree+0x62>
8010207e:	81 fb 88 59 11 80    	cmp    $0x80115988,%ebx
80102084:	72 44                	jb     801020ca <kfree+0x62>
80102086:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010208c:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102091:	77 37                	ja     801020ca <kfree+0x62>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102093:	83 ec 04             	sub    $0x4,%esp
80102096:	68 00 10 00 00       	push   $0x1000
8010209b:	6a 01                	push   $0x1
8010209d:	53                   	push   %ebx
8010209e:	e8 9b 1f 00 00       	call   8010403e <memset>

  if(kmem.use_lock)
801020a3:	83 c4 10             	add    $0x10,%esp
801020a6:	83 3d d4 4a 11 80 00 	cmpl   $0x0,0x80114ad4
801020ad:	75 28                	jne    801020d7 <kfree+0x6f>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
801020af:	a1 d8 4a 11 80       	mov    0x80114ad8,%eax
801020b4:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
801020b6:	89 1d d8 4a 11 80    	mov    %ebx,0x80114ad8
  if(kmem.use_lock)
801020bc:	83 3d d4 4a 11 80 00 	cmpl   $0x0,0x80114ad4
801020c3:	75 24                	jne    801020e9 <kfree+0x81>
    release(&kmem.lock);
}
801020c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020c8:	c9                   	leave  
801020c9:	c3                   	ret    
    panic("kfree");
801020ca:	83 ec 0c             	sub    $0xc,%esp
801020cd:	68 4e 6c 10 80       	push   $0x80106c4e
801020d2:	e8 85 e2 ff ff       	call   8010035c <panic>
    acquire(&kmem.lock);
801020d7:	83 ec 0c             	sub    $0xc,%esp
801020da:	68 a0 4a 11 80       	push   $0x80114aa0
801020df:	e8 a6 1e 00 00       	call   80103f8a <acquire>
801020e4:	83 c4 10             	add    $0x10,%esp
801020e7:	eb c6                	jmp    801020af <kfree+0x47>
    release(&kmem.lock);
801020e9:	83 ec 0c             	sub    $0xc,%esp
801020ec:	68 a0 4a 11 80       	push   $0x80114aa0
801020f1:	e8 fd 1e 00 00       	call   80103ff3 <release>
801020f6:	83 c4 10             	add    $0x10,%esp
}
801020f9:	eb ca                	jmp    801020c5 <kfree+0x5d>

801020fb <freerange>:
{
801020fb:	f3 0f 1e fb          	endbr32 
801020ff:	55                   	push   %ebp
80102100:	89 e5                	mov    %esp,%ebp
80102102:	56                   	push   %esi
80102103:	53                   	push   %ebx
80102104:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
80102107:	8b 45 08             	mov    0x8(%ebp),%eax
8010210a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010210f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102114:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010211a:	39 de                	cmp    %ebx,%esi
8010211c:	77 10                	ja     8010212e <freerange+0x33>
    kfree(p);
8010211e:	83 ec 0c             	sub    $0xc,%esp
80102121:	50                   	push   %eax
80102122:	e8 41 ff ff ff       	call   80102068 <kfree>
80102127:	83 c4 10             	add    $0x10,%esp
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010212a:	89 f0                	mov    %esi,%eax
8010212c:	eb e6                	jmp    80102114 <freerange+0x19>
}
8010212e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102131:	5b                   	pop    %ebx
80102132:	5e                   	pop    %esi
80102133:	5d                   	pop    %ebp
80102134:	c3                   	ret    

80102135 <kinit1>:
{
80102135:	f3 0f 1e fb          	endbr32 
80102139:	55                   	push   %ebp
8010213a:	89 e5                	mov    %esp,%ebp
8010213c:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010213f:	68 54 6c 10 80       	push   $0x80106c54
80102144:	68 a0 4a 11 80       	push   $0x80114aa0
80102149:	e8 ec 1c 00 00       	call   80103e3a <initlock>
  kmem.use_lock = 0;
8010214e:	c7 05 d4 4a 11 80 00 	movl   $0x0,0x80114ad4
80102155:	00 00 00 
  freerange(vstart, vend);
80102158:	83 c4 08             	add    $0x8,%esp
8010215b:	ff 75 0c             	pushl  0xc(%ebp)
8010215e:	ff 75 08             	pushl  0x8(%ebp)
80102161:	e8 95 ff ff ff       	call   801020fb <freerange>
}
80102166:	83 c4 10             	add    $0x10,%esp
80102169:	c9                   	leave  
8010216a:	c3                   	ret    

8010216b <kinit2>:
{
8010216b:	f3 0f 1e fb          	endbr32 
8010216f:	55                   	push   %ebp
80102170:	89 e5                	mov    %esp,%ebp
80102172:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
80102175:	ff 75 0c             	pushl  0xc(%ebp)
80102178:	ff 75 08             	pushl  0x8(%ebp)
8010217b:	e8 7b ff ff ff       	call   801020fb <freerange>
  kmem.use_lock = 1;
80102180:	c7 05 d4 4a 11 80 01 	movl   $0x1,0x80114ad4
80102187:	00 00 00 
}
8010218a:	83 c4 10             	add    $0x10,%esp
8010218d:	c9                   	leave  
8010218e:	c3                   	ret    

8010218f <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
8010218f:	f3 0f 1e fb          	endbr32 
80102193:	55                   	push   %ebp
80102194:	89 e5                	mov    %esp,%ebp
80102196:	53                   	push   %ebx
80102197:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
8010219a:	83 3d d4 4a 11 80 00 	cmpl   $0x0,0x80114ad4
801021a1:	75 21                	jne    801021c4 <kalloc+0x35>
    acquire(&kmem.lock);
  r = kmem.freelist;
801021a3:	8b 1d d8 4a 11 80    	mov    0x80114ad8,%ebx
  if(r)
801021a9:	85 db                	test   %ebx,%ebx
801021ab:	74 07                	je     801021b4 <kalloc+0x25>
    kmem.freelist = r->next;
801021ad:	8b 03                	mov    (%ebx),%eax
801021af:	a3 d8 4a 11 80       	mov    %eax,0x80114ad8
  if(kmem.use_lock)
801021b4:	83 3d d4 4a 11 80 00 	cmpl   $0x0,0x80114ad4
801021bb:	75 19                	jne    801021d6 <kalloc+0x47>
    release(&kmem.lock);
  return (char*)r;
}
801021bd:	89 d8                	mov    %ebx,%eax
801021bf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801021c2:	c9                   	leave  
801021c3:	c3                   	ret    
    acquire(&kmem.lock);
801021c4:	83 ec 0c             	sub    $0xc,%esp
801021c7:	68 a0 4a 11 80       	push   $0x80114aa0
801021cc:	e8 b9 1d 00 00       	call   80103f8a <acquire>
801021d1:	83 c4 10             	add    $0x10,%esp
801021d4:	eb cd                	jmp    801021a3 <kalloc+0x14>
    release(&kmem.lock);
801021d6:	83 ec 0c             	sub    $0xc,%esp
801021d9:	68 a0 4a 11 80       	push   $0x80114aa0
801021de:	e8 10 1e 00 00       	call   80103ff3 <release>
801021e3:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801021e6:	eb d5                	jmp    801021bd <kalloc+0x2e>

801021e8 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021e8:	f3 0f 1e fb          	endbr32 
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021ec:	ba 64 00 00 00       	mov    $0x64,%edx
801021f1:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021f2:	a8 01                	test   $0x1,%al
801021f4:	0f 84 ad 00 00 00    	je     801022a7 <kbdgetc+0xbf>
801021fa:	ba 60 00 00 00       	mov    $0x60,%edx
801021ff:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102200:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102203:	3c e0                	cmp    $0xe0,%al
80102205:	74 5b                	je     80102262 <kbdgetc+0x7a>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102207:	84 c0                	test   %al,%al
80102209:	78 64                	js     8010226f <kbdgetc+0x87>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010220b:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102211:	f6 c1 40             	test   $0x40,%cl
80102214:	74 0f                	je     80102225 <kbdgetc+0x3d>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102216:	83 c8 80             	or     $0xffffff80,%eax
80102219:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010221c:	83 e1 bf             	and    $0xffffffbf,%ecx
8010221f:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
80102225:	0f b6 8a 80 6d 10 80 	movzbl -0x7fef9280(%edx),%ecx
8010222c:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
80102232:	0f b6 82 80 6c 10 80 	movzbl -0x7fef9380(%edx),%eax
80102239:	31 c1                	xor    %eax,%ecx
8010223b:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102241:	89 c8                	mov    %ecx,%eax
80102243:	83 e0 03             	and    $0x3,%eax
80102246:	8b 04 85 60 6c 10 80 	mov    -0x7fef93a0(,%eax,4),%eax
8010224d:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102251:	f6 c1 08             	test   $0x8,%cl
80102254:	74 56                	je     801022ac <kbdgetc+0xc4>
    if('a' <= c && c <= 'z')
80102256:	8d 50 9f             	lea    -0x61(%eax),%edx
80102259:	83 fa 19             	cmp    $0x19,%edx
8010225c:	77 3d                	ja     8010229b <kbdgetc+0xb3>
      c += 'A' - 'a';
8010225e:	83 e8 20             	sub    $0x20,%eax
80102261:	c3                   	ret    
    shift |= E0ESC;
80102262:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102269:	b8 00 00 00 00       	mov    $0x0,%eax
8010226e:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
8010226f:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102275:	f6 c1 40             	test   $0x40,%cl
80102278:	75 05                	jne    8010227f <kbdgetc+0x97>
8010227a:	89 c2                	mov    %eax,%edx
8010227c:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010227f:	0f b6 82 80 6d 10 80 	movzbl -0x7fef9280(%edx),%eax
80102286:	83 c8 40             	or     $0x40,%eax
80102289:	0f b6 c0             	movzbl %al,%eax
8010228c:	f7 d0                	not    %eax
8010228e:	21 c8                	and    %ecx,%eax
80102290:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
80102295:	b8 00 00 00 00       	mov    $0x0,%eax
8010229a:	c3                   	ret    
    else if('A' <= c && c <= 'Z')
8010229b:	8d 50 bf             	lea    -0x41(%eax),%edx
8010229e:	83 fa 19             	cmp    $0x19,%edx
801022a1:	77 09                	ja     801022ac <kbdgetc+0xc4>
      c += 'a' - 'A';
801022a3:	83 c0 20             	add    $0x20,%eax
  }
  return c;
801022a6:	c3                   	ret    
    return -1;
801022a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801022ac:	c3                   	ret    

801022ad <kbdintr>:

void
kbdintr(void)
{
801022ad:	f3 0f 1e fb          	endbr32 
801022b1:	55                   	push   %ebp
801022b2:	89 e5                	mov    %esp,%ebp
801022b4:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801022b7:	68 e8 21 10 80       	push   $0x801021e8
801022bc:	e8 bd e4 ff ff       	call   8010077e <consoleintr>
}
801022c1:	83 c4 10             	add    $0x10,%esp
801022c4:	c9                   	leave  
801022c5:	c3                   	ret    

801022c6 <lapicw>:

//PAGEBREAK!
static void
lapicw(int index, int value)
{
  lapic[index] = value;
801022c6:	8b 0d dc 4a 11 80    	mov    0x80114adc,%ecx
801022cc:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801022cf:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801022d1:	a1 dc 4a 11 80       	mov    0x80114adc,%eax
801022d6:	8b 40 20             	mov    0x20(%eax),%eax
}
801022d9:	c3                   	ret    

801022da <cmos_read>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022da:	ba 70 00 00 00       	mov    $0x70,%edx
801022df:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022e0:	ba 71 00 00 00       	mov    $0x71,%edx
801022e5:	ec                   	in     (%dx),%al
static uint cmos_read(uint reg)
{
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022e6:	0f b6 c0             	movzbl %al,%eax
}
801022e9:	c3                   	ret    

801022ea <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801022ea:	55                   	push   %ebp
801022eb:	89 e5                	mov    %esp,%ebp
801022ed:	53                   	push   %ebx
801022ee:	83 ec 04             	sub    $0x4,%esp
801022f1:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022f3:	b8 00 00 00 00       	mov    $0x0,%eax
801022f8:	e8 dd ff ff ff       	call   801022da <cmos_read>
801022fd:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801022ff:	b8 02 00 00 00       	mov    $0x2,%eax
80102304:	e8 d1 ff ff ff       	call   801022da <cmos_read>
80102309:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010230c:	b8 04 00 00 00       	mov    $0x4,%eax
80102311:	e8 c4 ff ff ff       	call   801022da <cmos_read>
80102316:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102319:	b8 07 00 00 00       	mov    $0x7,%eax
8010231e:	e8 b7 ff ff ff       	call   801022da <cmos_read>
80102323:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102326:	b8 08 00 00 00       	mov    $0x8,%eax
8010232b:	e8 aa ff ff ff       	call   801022da <cmos_read>
80102330:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102333:	b8 09 00 00 00       	mov    $0x9,%eax
80102338:	e8 9d ff ff ff       	call   801022da <cmos_read>
8010233d:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102340:	83 c4 04             	add    $0x4,%esp
80102343:	5b                   	pop    %ebx
80102344:	5d                   	pop    %ebp
80102345:	c3                   	ret    

80102346 <lapicinit>:
{
80102346:	f3 0f 1e fb          	endbr32 
  if(!lapic)
8010234a:	83 3d dc 4a 11 80 00 	cmpl   $0x0,0x80114adc
80102351:	0f 84 fe 00 00 00    	je     80102455 <lapicinit+0x10f>
{
80102357:	55                   	push   %ebp
80102358:	89 e5                	mov    %esp,%ebp
8010235a:	83 ec 08             	sub    $0x8,%esp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010235d:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102362:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102367:	e8 5a ff ff ff       	call   801022c6 <lapicw>
  lapicw(TDCR, X1);
8010236c:	ba 0b 00 00 00       	mov    $0xb,%edx
80102371:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102376:	e8 4b ff ff ff       	call   801022c6 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010237b:	ba 20 00 02 00       	mov    $0x20020,%edx
80102380:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102385:	e8 3c ff ff ff       	call   801022c6 <lapicw>
  lapicw(TICR, 1000000);
8010238a:	ba 40 42 0f 00       	mov    $0xf4240,%edx
8010238f:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102394:	e8 2d ff ff ff       	call   801022c6 <lapicw>
  lapicw(LINT0, MASKED);
80102399:	ba 00 00 01 00       	mov    $0x10000,%edx
8010239e:	b8 d4 00 00 00       	mov    $0xd4,%eax
801023a3:	e8 1e ff ff ff       	call   801022c6 <lapicw>
  lapicw(LINT1, MASKED);
801023a8:	ba 00 00 01 00       	mov    $0x10000,%edx
801023ad:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023b2:	e8 0f ff ff ff       	call   801022c6 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801023b7:	a1 dc 4a 11 80       	mov    0x80114adc,%eax
801023bc:	8b 40 30             	mov    0x30(%eax),%eax
801023bf:	c1 e8 10             	shr    $0x10,%eax
801023c2:	a8 fc                	test   $0xfc,%al
801023c4:	75 7b                	jne    80102441 <lapicinit+0xfb>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801023c6:	ba 33 00 00 00       	mov    $0x33,%edx
801023cb:	b8 dc 00 00 00       	mov    $0xdc,%eax
801023d0:	e8 f1 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ESR, 0);
801023d5:	ba 00 00 00 00       	mov    $0x0,%edx
801023da:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023df:	e8 e2 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ESR, 0);
801023e4:	ba 00 00 00 00       	mov    $0x0,%edx
801023e9:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023ee:	e8 d3 fe ff ff       	call   801022c6 <lapicw>
  lapicw(EOI, 0);
801023f3:	ba 00 00 00 00       	mov    $0x0,%edx
801023f8:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023fd:	e8 c4 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ICRHI, 0);
80102402:	ba 00 00 00 00       	mov    $0x0,%edx
80102407:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010240c:	e8 b5 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102411:	ba 00 85 08 00       	mov    $0x88500,%edx
80102416:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010241b:	e8 a6 fe ff ff       	call   801022c6 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102420:	a1 dc 4a 11 80       	mov    0x80114adc,%eax
80102425:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010242b:	f6 c4 10             	test   $0x10,%ah
8010242e:	75 f0                	jne    80102420 <lapicinit+0xda>
  lapicw(TPR, 0);
80102430:	ba 00 00 00 00       	mov    $0x0,%edx
80102435:	b8 20 00 00 00       	mov    $0x20,%eax
8010243a:	e8 87 fe ff ff       	call   801022c6 <lapicw>
}
8010243f:	c9                   	leave  
80102440:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102441:	ba 00 00 01 00       	mov    $0x10000,%edx
80102446:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010244b:	e8 76 fe ff ff       	call   801022c6 <lapicw>
80102450:	e9 71 ff ff ff       	jmp    801023c6 <lapicinit+0x80>
80102455:	c3                   	ret    

80102456 <lapicid>:
{
80102456:	f3 0f 1e fb          	endbr32 
  if (!lapic)
8010245a:	a1 dc 4a 11 80       	mov    0x80114adc,%eax
8010245f:	85 c0                	test   %eax,%eax
80102461:	74 07                	je     8010246a <lapicid+0x14>
  return lapic[ID] >> 24;
80102463:	8b 40 20             	mov    0x20(%eax),%eax
80102466:	c1 e8 18             	shr    $0x18,%eax
80102469:	c3                   	ret    
    return 0;
8010246a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010246f:	c3                   	ret    

80102470 <lapiceoi>:
{
80102470:	f3 0f 1e fb          	endbr32 
  if(lapic)
80102474:	83 3d dc 4a 11 80 00 	cmpl   $0x0,0x80114adc
8010247b:	74 17                	je     80102494 <lapiceoi+0x24>
{
8010247d:	55                   	push   %ebp
8010247e:	89 e5                	mov    %esp,%ebp
80102480:	83 ec 08             	sub    $0x8,%esp
    lapicw(EOI, 0);
80102483:	ba 00 00 00 00       	mov    $0x0,%edx
80102488:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010248d:	e8 34 fe ff ff       	call   801022c6 <lapicw>
}
80102492:	c9                   	leave  
80102493:	c3                   	ret    
80102494:	c3                   	ret    

80102495 <microdelay>:
{
80102495:	f3 0f 1e fb          	endbr32 
}
80102499:	c3                   	ret    

8010249a <lapicstartap>:
{
8010249a:	f3 0f 1e fb          	endbr32 
8010249e:	55                   	push   %ebp
8010249f:	89 e5                	mov    %esp,%ebp
801024a1:	57                   	push   %edi
801024a2:	56                   	push   %esi
801024a3:	53                   	push   %ebx
801024a4:	83 ec 0c             	sub    $0xc,%esp
801024a7:	8b 75 08             	mov    0x8(%ebp),%esi
801024aa:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024ad:	b8 0f 00 00 00       	mov    $0xf,%eax
801024b2:	ba 70 00 00 00       	mov    $0x70,%edx
801024b7:	ee                   	out    %al,(%dx)
801024b8:	b8 0a 00 00 00       	mov    $0xa,%eax
801024bd:	ba 71 00 00 00       	mov    $0x71,%edx
801024c2:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801024c3:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801024ca:	00 00 
  wrv[1] = addr >> 4;
801024cc:	89 f8                	mov    %edi,%eax
801024ce:	c1 e8 04             	shr    $0x4,%eax
801024d1:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801024d7:	c1 e6 18             	shl    $0x18,%esi
801024da:	89 f2                	mov    %esi,%edx
801024dc:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024e1:	e8 e0 fd ff ff       	call   801022c6 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801024e6:	ba 00 c5 00 00       	mov    $0xc500,%edx
801024eb:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024f0:	e8 d1 fd ff ff       	call   801022c6 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024f5:	ba 00 85 00 00       	mov    $0x8500,%edx
801024fa:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024ff:	e8 c2 fd ff ff       	call   801022c6 <lapicw>
  for(i = 0; i < 2; i++){
80102504:	bb 00 00 00 00       	mov    $0x0,%ebx
80102509:	eb 21                	jmp    8010252c <lapicstartap+0x92>
    lapicw(ICRHI, apicid<<24);
8010250b:	89 f2                	mov    %esi,%edx
8010250d:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102512:	e8 af fd ff ff       	call   801022c6 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102517:	89 fa                	mov    %edi,%edx
80102519:	c1 ea 0c             	shr    $0xc,%edx
8010251c:	80 ce 06             	or     $0x6,%dh
8010251f:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102524:	e8 9d fd ff ff       	call   801022c6 <lapicw>
  for(i = 0; i < 2; i++){
80102529:	83 c3 01             	add    $0x1,%ebx
8010252c:	83 fb 01             	cmp    $0x1,%ebx
8010252f:	7e da                	jle    8010250b <lapicstartap+0x71>
}
80102531:	83 c4 0c             	add    $0xc,%esp
80102534:	5b                   	pop    %ebx
80102535:	5e                   	pop    %esi
80102536:	5f                   	pop    %edi
80102537:	5d                   	pop    %ebp
80102538:	c3                   	ret    

80102539 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80102539:	f3 0f 1e fb          	endbr32 
8010253d:	55                   	push   %ebp
8010253e:	89 e5                	mov    %esp,%ebp
80102540:	57                   	push   %edi
80102541:	56                   	push   %esi
80102542:	53                   	push   %ebx
80102543:	83 ec 3c             	sub    $0x3c,%esp
80102546:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102549:	b8 0b 00 00 00       	mov    $0xb,%eax
8010254e:	e8 87 fd ff ff       	call   801022da <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102553:	83 e0 04             	and    $0x4,%eax
80102556:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102558:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010255b:	e8 8a fd ff ff       	call   801022ea <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102560:	b8 0a 00 00 00       	mov    $0xa,%eax
80102565:	e8 70 fd ff ff       	call   801022da <cmos_read>
8010256a:	a8 80                	test   $0x80,%al
8010256c:	75 ea                	jne    80102558 <cmostime+0x1f>
        continue;
    fill_rtcdate(&t2);
8010256e:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102571:	89 d8                	mov    %ebx,%eax
80102573:	e8 72 fd ff ff       	call   801022ea <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102578:	83 ec 04             	sub    $0x4,%esp
8010257b:	6a 18                	push   $0x18
8010257d:	53                   	push   %ebx
8010257e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102581:	50                   	push   %eax
80102582:	e8 fe 1a 00 00       	call   80104085 <memcmp>
80102587:	83 c4 10             	add    $0x10,%esp
8010258a:	85 c0                	test   %eax,%eax
8010258c:	75 ca                	jne    80102558 <cmostime+0x1f>
      break;
  }

  // convert
  if(bcd) {
8010258e:	85 ff                	test   %edi,%edi
80102590:	75 78                	jne    8010260a <cmostime+0xd1>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102592:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102595:	89 c2                	mov    %eax,%edx
80102597:	c1 ea 04             	shr    $0x4,%edx
8010259a:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010259d:	83 e0 0f             	and    $0xf,%eax
801025a0:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025a3:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801025a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025a9:	89 c2                	mov    %eax,%edx
801025ab:	c1 ea 04             	shr    $0x4,%edx
801025ae:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025b1:	83 e0 0f             	and    $0xf,%eax
801025b4:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801025ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
801025bd:	89 c2                	mov    %eax,%edx
801025bf:	c1 ea 04             	shr    $0x4,%edx
801025c2:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025c5:	83 e0 0f             	and    $0xf,%eax
801025c8:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801025ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
801025d1:	89 c2                	mov    %eax,%edx
801025d3:	c1 ea 04             	shr    $0x4,%edx
801025d6:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025d9:	83 e0 0f             	and    $0xf,%eax
801025dc:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025df:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801025e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801025e5:	89 c2                	mov    %eax,%edx
801025e7:	c1 ea 04             	shr    $0x4,%edx
801025ea:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025ed:	83 e0 0f             	and    $0xf,%eax
801025f0:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801025f9:	89 c2                	mov    %eax,%edx
801025fb:	c1 ea 04             	shr    $0x4,%edx
801025fe:	8d 14 92             	lea    (%edx,%edx,4),%edx
80102601:	83 e0 0f             	and    $0xf,%eax
80102604:	8d 04 50             	lea    (%eax,%edx,2),%eax
80102607:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010260a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010260d:	89 06                	mov    %eax,(%esi)
8010260f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102612:	89 46 04             	mov    %eax,0x4(%esi)
80102615:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102618:	89 46 08             	mov    %eax,0x8(%esi)
8010261b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010261e:	89 46 0c             	mov    %eax,0xc(%esi)
80102621:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102624:	89 46 10             	mov    %eax,0x10(%esi)
80102627:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010262a:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010262d:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102634:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102637:	5b                   	pop    %ebx
80102638:	5e                   	pop    %esi
80102639:	5f                   	pop    %edi
8010263a:	5d                   	pop    %ebp
8010263b:	c3                   	ret    

8010263c <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010263c:	55                   	push   %ebp
8010263d:	89 e5                	mov    %esp,%ebp
8010263f:	53                   	push   %ebx
80102640:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102643:	ff 35 14 4b 11 80    	pushl  0x80114b14
80102649:	ff 35 24 4b 11 80    	pushl  0x80114b24
8010264f:	e8 1c db ff ff       	call   80100170 <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102654:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102657:	89 1d 28 4b 11 80    	mov    %ebx,0x80114b28
  for (i = 0; i < log.lh.n; i++) {
8010265d:	83 c4 10             	add    $0x10,%esp
80102660:	ba 00 00 00 00       	mov    $0x0,%edx
80102665:	39 d3                	cmp    %edx,%ebx
80102667:	7e 10                	jle    80102679 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
80102669:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010266d:	89 0c 95 2c 4b 11 80 	mov    %ecx,-0x7feeb4d4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102674:	83 c2 01             	add    $0x1,%edx
80102677:	eb ec                	jmp    80102665 <read_head+0x29>
  }
  brelse(buf);
80102679:	83 ec 0c             	sub    $0xc,%esp
8010267c:	50                   	push   %eax
8010267d:	e8 5f db ff ff       	call   801001e1 <brelse>
}
80102682:	83 c4 10             	add    $0x10,%esp
80102685:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102688:	c9                   	leave  
80102689:	c3                   	ret    

8010268a <install_trans>:
{
8010268a:	55                   	push   %ebp
8010268b:	89 e5                	mov    %esp,%ebp
8010268d:	57                   	push   %edi
8010268e:	56                   	push   %esi
8010268f:	53                   	push   %ebx
80102690:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102693:	be 00 00 00 00       	mov    $0x0,%esi
80102698:	39 35 28 4b 11 80    	cmp    %esi,0x80114b28
8010269e:	7e 68                	jle    80102708 <install_trans+0x7e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801026a0:	89 f0                	mov    %esi,%eax
801026a2:	03 05 14 4b 11 80    	add    0x80114b14,%eax
801026a8:	83 c0 01             	add    $0x1,%eax
801026ab:	83 ec 08             	sub    $0x8,%esp
801026ae:	50                   	push   %eax
801026af:	ff 35 24 4b 11 80    	pushl  0x80114b24
801026b5:	e8 b6 da ff ff       	call   80100170 <bread>
801026ba:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026bc:	83 c4 08             	add    $0x8,%esp
801026bf:	ff 34 b5 2c 4b 11 80 	pushl  -0x7feeb4d4(,%esi,4)
801026c6:	ff 35 24 4b 11 80    	pushl  0x80114b24
801026cc:	e8 9f da ff ff       	call   80100170 <bread>
801026d1:	89 c3                	mov    %eax,%ebx
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801026d3:	8d 57 5c             	lea    0x5c(%edi),%edx
801026d6:	8d 40 5c             	lea    0x5c(%eax),%eax
801026d9:	83 c4 0c             	add    $0xc,%esp
801026dc:	68 00 02 00 00       	push   $0x200
801026e1:	52                   	push   %edx
801026e2:	50                   	push   %eax
801026e3:	e8 d6 19 00 00       	call   801040be <memmove>
    bwrite(dbuf);  // write dst to disk
801026e8:	89 1c 24             	mov    %ebx,(%esp)
801026eb:	e8 b2 da ff ff       	call   801001a2 <bwrite>
    brelse(lbuf);
801026f0:	89 3c 24             	mov    %edi,(%esp)
801026f3:	e8 e9 da ff ff       	call   801001e1 <brelse>
    brelse(dbuf);
801026f8:	89 1c 24             	mov    %ebx,(%esp)
801026fb:	e8 e1 da ff ff       	call   801001e1 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102700:	83 c6 01             	add    $0x1,%esi
80102703:	83 c4 10             	add    $0x10,%esp
80102706:	eb 90                	jmp    80102698 <install_trans+0xe>
}
80102708:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010270b:	5b                   	pop    %ebx
8010270c:	5e                   	pop    %esi
8010270d:	5f                   	pop    %edi
8010270e:	5d                   	pop    %ebp
8010270f:	c3                   	ret    

80102710 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102710:	55                   	push   %ebp
80102711:	89 e5                	mov    %esp,%ebp
80102713:	53                   	push   %ebx
80102714:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102717:	ff 35 14 4b 11 80    	pushl  0x80114b14
8010271d:	ff 35 24 4b 11 80    	pushl  0x80114b24
80102723:	e8 48 da ff ff       	call   80100170 <bread>
80102728:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010272a:	8b 0d 28 4b 11 80    	mov    0x80114b28,%ecx
80102730:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102733:	83 c4 10             	add    $0x10,%esp
80102736:	b8 00 00 00 00       	mov    $0x0,%eax
8010273b:	39 c1                	cmp    %eax,%ecx
8010273d:	7e 10                	jle    8010274f <write_head+0x3f>
    hb->block[i] = log.lh.block[i];
8010273f:	8b 14 85 2c 4b 11 80 	mov    -0x7feeb4d4(,%eax,4),%edx
80102746:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010274a:	83 c0 01             	add    $0x1,%eax
8010274d:	eb ec                	jmp    8010273b <write_head+0x2b>
  }
  bwrite(buf);
8010274f:	83 ec 0c             	sub    $0xc,%esp
80102752:	53                   	push   %ebx
80102753:	e8 4a da ff ff       	call   801001a2 <bwrite>
  brelse(buf);
80102758:	89 1c 24             	mov    %ebx,(%esp)
8010275b:	e8 81 da ff ff       	call   801001e1 <brelse>
}
80102760:	83 c4 10             	add    $0x10,%esp
80102763:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102766:	c9                   	leave  
80102767:	c3                   	ret    

80102768 <recover_from_log>:

static void
recover_from_log(void)
{
80102768:	55                   	push   %ebp
80102769:	89 e5                	mov    %esp,%ebp
8010276b:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010276e:	e8 c9 fe ff ff       	call   8010263c <read_head>
  install_trans(); // if committed, copy from log to disk
80102773:	e8 12 ff ff ff       	call   8010268a <install_trans>
  log.lh.n = 0;
80102778:	c7 05 28 4b 11 80 00 	movl   $0x0,0x80114b28
8010277f:	00 00 00 
  write_head(); // clear the log
80102782:	e8 89 ff ff ff       	call   80102710 <write_head>
}
80102787:	c9                   	leave  
80102788:	c3                   	ret    

80102789 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102789:	55                   	push   %ebp
8010278a:	89 e5                	mov    %esp,%ebp
8010278c:	57                   	push   %edi
8010278d:	56                   	push   %esi
8010278e:	53                   	push   %ebx
8010278f:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102792:	be 00 00 00 00       	mov    $0x0,%esi
80102797:	39 35 28 4b 11 80    	cmp    %esi,0x80114b28
8010279d:	7e 68                	jle    80102807 <write_log+0x7e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010279f:	89 f0                	mov    %esi,%eax
801027a1:	03 05 14 4b 11 80    	add    0x80114b14,%eax
801027a7:	83 c0 01             	add    $0x1,%eax
801027aa:	83 ec 08             	sub    $0x8,%esp
801027ad:	50                   	push   %eax
801027ae:	ff 35 24 4b 11 80    	pushl  0x80114b24
801027b4:	e8 b7 d9 ff ff       	call   80100170 <bread>
801027b9:	89 c3                	mov    %eax,%ebx
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027bb:	83 c4 08             	add    $0x8,%esp
801027be:	ff 34 b5 2c 4b 11 80 	pushl  -0x7feeb4d4(,%esi,4)
801027c5:	ff 35 24 4b 11 80    	pushl  0x80114b24
801027cb:	e8 a0 d9 ff ff       	call   80100170 <bread>
801027d0:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801027d2:	8d 50 5c             	lea    0x5c(%eax),%edx
801027d5:	8d 43 5c             	lea    0x5c(%ebx),%eax
801027d8:	83 c4 0c             	add    $0xc,%esp
801027db:	68 00 02 00 00       	push   $0x200
801027e0:	52                   	push   %edx
801027e1:	50                   	push   %eax
801027e2:	e8 d7 18 00 00       	call   801040be <memmove>
    bwrite(to);  // write the log
801027e7:	89 1c 24             	mov    %ebx,(%esp)
801027ea:	e8 b3 d9 ff ff       	call   801001a2 <bwrite>
    brelse(from);
801027ef:	89 3c 24             	mov    %edi,(%esp)
801027f2:	e8 ea d9 ff ff       	call   801001e1 <brelse>
    brelse(to);
801027f7:	89 1c 24             	mov    %ebx,(%esp)
801027fa:	e8 e2 d9 ff ff       	call   801001e1 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027ff:	83 c6 01             	add    $0x1,%esi
80102802:	83 c4 10             	add    $0x10,%esp
80102805:	eb 90                	jmp    80102797 <write_log+0xe>
  }
}
80102807:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010280a:	5b                   	pop    %ebx
8010280b:	5e                   	pop    %esi
8010280c:	5f                   	pop    %edi
8010280d:	5d                   	pop    %ebp
8010280e:	c3                   	ret    

8010280f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010280f:	83 3d 28 4b 11 80 00 	cmpl   $0x0,0x80114b28
80102816:	7f 01                	jg     80102819 <commit+0xa>
80102818:	c3                   	ret    
{
80102819:	55                   	push   %ebp
8010281a:	89 e5                	mov    %esp,%ebp
8010281c:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010281f:	e8 65 ff ff ff       	call   80102789 <write_log>
    write_head();    // Write header to disk -- the real commit
80102824:	e8 e7 fe ff ff       	call   80102710 <write_head>
    install_trans(); // Now install writes to home locations
80102829:	e8 5c fe ff ff       	call   8010268a <install_trans>
    log.lh.n = 0;
8010282e:	c7 05 28 4b 11 80 00 	movl   $0x0,0x80114b28
80102835:	00 00 00 
    write_head();    // Erase the transaction from the log
80102838:	e8 d3 fe ff ff       	call   80102710 <write_head>
  }
}
8010283d:	c9                   	leave  
8010283e:	c3                   	ret    

8010283f <initlog>:
{
8010283f:	f3 0f 1e fb          	endbr32 
80102843:	55                   	push   %ebp
80102844:	89 e5                	mov    %esp,%ebp
80102846:	53                   	push   %ebx
80102847:	83 ec 2c             	sub    $0x2c,%esp
8010284a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010284d:	68 80 6e 10 80       	push   $0x80106e80
80102852:	68 e0 4a 11 80       	push   $0x80114ae0
80102857:	e8 de 15 00 00       	call   80103e3a <initlock>
  readsb(dev, &sb);
8010285c:	83 c4 08             	add    $0x8,%esp
8010285f:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102862:	50                   	push   %eax
80102863:	53                   	push   %ebx
80102864:	e8 3b ea ff ff       	call   801012a4 <readsb>
  log.start = sb.logstart;
80102869:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010286c:	a3 14 4b 11 80       	mov    %eax,0x80114b14
  log.size = sb.nlog;
80102871:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102874:	a3 18 4b 11 80       	mov    %eax,0x80114b18
  log.dev = dev;
80102879:	89 1d 24 4b 11 80    	mov    %ebx,0x80114b24
  recover_from_log();
8010287f:	e8 e4 fe ff ff       	call   80102768 <recover_from_log>
}
80102884:	83 c4 10             	add    $0x10,%esp
80102887:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010288a:	c9                   	leave  
8010288b:	c3                   	ret    

8010288c <begin_op>:
{
8010288c:	f3 0f 1e fb          	endbr32 
80102890:	55                   	push   %ebp
80102891:	89 e5                	mov    %esp,%ebp
80102893:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102896:	68 e0 4a 11 80       	push   $0x80114ae0
8010289b:	e8 ea 16 00 00       	call   80103f8a <acquire>
801028a0:	83 c4 10             	add    $0x10,%esp
801028a3:	eb 15                	jmp    801028ba <begin_op+0x2e>
      sleep(&log, &log.lock);
801028a5:	83 ec 08             	sub    $0x8,%esp
801028a8:	68 e0 4a 11 80       	push   $0x80114ae0
801028ad:	68 e0 4a 11 80       	push   $0x80114ae0
801028b2:	e8 b6 0f 00 00       	call   8010386d <sleep>
801028b7:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028ba:	83 3d 20 4b 11 80 00 	cmpl   $0x0,0x80114b20
801028c1:	75 e2                	jne    801028a5 <begin_op+0x19>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801028c3:	a1 1c 4b 11 80       	mov    0x80114b1c,%eax
801028c8:	83 c0 01             	add    $0x1,%eax
801028cb:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028ce:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801028d1:	03 15 28 4b 11 80    	add    0x80114b28,%edx
801028d7:	83 fa 1e             	cmp    $0x1e,%edx
801028da:	7e 17                	jle    801028f3 <begin_op+0x67>
      sleep(&log, &log.lock);
801028dc:	83 ec 08             	sub    $0x8,%esp
801028df:	68 e0 4a 11 80       	push   $0x80114ae0
801028e4:	68 e0 4a 11 80       	push   $0x80114ae0
801028e9:	e8 7f 0f 00 00       	call   8010386d <sleep>
801028ee:	83 c4 10             	add    $0x10,%esp
801028f1:	eb c7                	jmp    801028ba <begin_op+0x2e>
      log.outstanding += 1;
801028f3:	a3 1c 4b 11 80       	mov    %eax,0x80114b1c
      release(&log.lock);
801028f8:	83 ec 0c             	sub    $0xc,%esp
801028fb:	68 e0 4a 11 80       	push   $0x80114ae0
80102900:	e8 ee 16 00 00       	call   80103ff3 <release>
}
80102905:	83 c4 10             	add    $0x10,%esp
80102908:	c9                   	leave  
80102909:	c3                   	ret    

8010290a <end_op>:
{
8010290a:	f3 0f 1e fb          	endbr32 
8010290e:	55                   	push   %ebp
8010290f:	89 e5                	mov    %esp,%ebp
80102911:	53                   	push   %ebx
80102912:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102915:	68 e0 4a 11 80       	push   $0x80114ae0
8010291a:	e8 6b 16 00 00       	call   80103f8a <acquire>
  log.outstanding -= 1;
8010291f:	a1 1c 4b 11 80       	mov    0x80114b1c,%eax
80102924:	83 e8 01             	sub    $0x1,%eax
80102927:	a3 1c 4b 11 80       	mov    %eax,0x80114b1c
  if(log.committing)
8010292c:	8b 1d 20 4b 11 80    	mov    0x80114b20,%ebx
80102932:	83 c4 10             	add    $0x10,%esp
80102935:	85 db                	test   %ebx,%ebx
80102937:	75 2c                	jne    80102965 <end_op+0x5b>
  if(log.outstanding == 0){
80102939:	85 c0                	test   %eax,%eax
8010293b:	75 35                	jne    80102972 <end_op+0x68>
    log.committing = 1;
8010293d:	c7 05 20 4b 11 80 01 	movl   $0x1,0x80114b20
80102944:	00 00 00 
    do_commit = 1;
80102947:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
8010294c:	83 ec 0c             	sub    $0xc,%esp
8010294f:	68 e0 4a 11 80       	push   $0x80114ae0
80102954:	e8 9a 16 00 00       	call   80103ff3 <release>
  if(do_commit){
80102959:	83 c4 10             	add    $0x10,%esp
8010295c:	85 db                	test   %ebx,%ebx
8010295e:	75 24                	jne    80102984 <end_op+0x7a>
}
80102960:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102963:	c9                   	leave  
80102964:	c3                   	ret    
    panic("log.committing");
80102965:	83 ec 0c             	sub    $0xc,%esp
80102968:	68 84 6e 10 80       	push   $0x80106e84
8010296d:	e8 ea d9 ff ff       	call   8010035c <panic>
    wakeup(&log);
80102972:	83 ec 0c             	sub    $0xc,%esp
80102975:	68 e0 4a 11 80       	push   $0x80114ae0
8010297a:	e8 5d 10 00 00       	call   801039dc <wakeup>
8010297f:	83 c4 10             	add    $0x10,%esp
80102982:	eb c8                	jmp    8010294c <end_op+0x42>
    commit();
80102984:	e8 86 fe ff ff       	call   8010280f <commit>
    acquire(&log.lock);
80102989:	83 ec 0c             	sub    $0xc,%esp
8010298c:	68 e0 4a 11 80       	push   $0x80114ae0
80102991:	e8 f4 15 00 00       	call   80103f8a <acquire>
    log.committing = 0;
80102996:	c7 05 20 4b 11 80 00 	movl   $0x0,0x80114b20
8010299d:	00 00 00 
    wakeup(&log);
801029a0:	c7 04 24 e0 4a 11 80 	movl   $0x80114ae0,(%esp)
801029a7:	e8 30 10 00 00       	call   801039dc <wakeup>
    release(&log.lock);
801029ac:	c7 04 24 e0 4a 11 80 	movl   $0x80114ae0,(%esp)
801029b3:	e8 3b 16 00 00       	call   80103ff3 <release>
801029b8:	83 c4 10             	add    $0x10,%esp
}
801029bb:	eb a3                	jmp    80102960 <end_op+0x56>

801029bd <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801029bd:	f3 0f 1e fb          	endbr32 
801029c1:	55                   	push   %ebp
801029c2:	89 e5                	mov    %esp,%ebp
801029c4:	53                   	push   %ebx
801029c5:	83 ec 04             	sub    $0x4,%esp
801029c8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801029cb:	8b 15 28 4b 11 80    	mov    0x80114b28,%edx
801029d1:	83 fa 1d             	cmp    $0x1d,%edx
801029d4:	7f 45                	jg     80102a1b <log_write+0x5e>
801029d6:	a1 18 4b 11 80       	mov    0x80114b18,%eax
801029db:	83 e8 01             	sub    $0x1,%eax
801029de:	39 c2                	cmp    %eax,%edx
801029e0:	7d 39                	jge    80102a1b <log_write+0x5e>
    panic("too big a transaction");
  if (log.outstanding < 1)
801029e2:	83 3d 1c 4b 11 80 00 	cmpl   $0x0,0x80114b1c
801029e9:	7e 3d                	jle    80102a28 <log_write+0x6b>
    panic("log_write outside of trans");

  acquire(&log.lock);
801029eb:	83 ec 0c             	sub    $0xc,%esp
801029ee:	68 e0 4a 11 80       	push   $0x80114ae0
801029f3:	e8 92 15 00 00       	call   80103f8a <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029f8:	83 c4 10             	add    $0x10,%esp
801029fb:	b8 00 00 00 00       	mov    $0x0,%eax
80102a00:	8b 15 28 4b 11 80    	mov    0x80114b28,%edx
80102a06:	39 c2                	cmp    %eax,%edx
80102a08:	7e 2b                	jle    80102a35 <log_write+0x78>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a0a:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a0d:	39 0c 85 2c 4b 11 80 	cmp    %ecx,-0x7feeb4d4(,%eax,4)
80102a14:	74 1f                	je     80102a35 <log_write+0x78>
  for (i = 0; i < log.lh.n; i++) {
80102a16:	83 c0 01             	add    $0x1,%eax
80102a19:	eb e5                	jmp    80102a00 <log_write+0x43>
    panic("too big a transaction");
80102a1b:	83 ec 0c             	sub    $0xc,%esp
80102a1e:	68 93 6e 10 80       	push   $0x80106e93
80102a23:	e8 34 d9 ff ff       	call   8010035c <panic>
    panic("log_write outside of trans");
80102a28:	83 ec 0c             	sub    $0xc,%esp
80102a2b:	68 a9 6e 10 80       	push   $0x80106ea9
80102a30:	e8 27 d9 ff ff       	call   8010035c <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a35:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a38:	89 0c 85 2c 4b 11 80 	mov    %ecx,-0x7feeb4d4(,%eax,4)
  if (i == log.lh.n)
80102a3f:	39 c2                	cmp    %eax,%edx
80102a41:	74 18                	je     80102a5b <log_write+0x9e>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a43:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a46:	83 ec 0c             	sub    $0xc,%esp
80102a49:	68 e0 4a 11 80       	push   $0x80114ae0
80102a4e:	e8 a0 15 00 00       	call   80103ff3 <release>
}
80102a53:	83 c4 10             	add    $0x10,%esp
80102a56:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a59:	c9                   	leave  
80102a5a:	c3                   	ret    
    log.lh.n++;
80102a5b:	83 c2 01             	add    $0x1,%edx
80102a5e:	89 15 28 4b 11 80    	mov    %edx,0x80114b28
80102a64:	eb dd                	jmp    80102a43 <log_write+0x86>

80102a66 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a66:	55                   	push   %ebp
80102a67:	89 e5                	mov    %esp,%ebp
80102a69:	53                   	push   %ebx
80102a6a:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a6d:	68 8a 00 00 00       	push   $0x8a
80102a72:	68 8c a4 10 80       	push   $0x8010a48c
80102a77:	68 00 70 00 80       	push   $0x80007000
80102a7c:	e8 3d 16 00 00       	call   801040be <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a81:	83 c4 10             	add    $0x10,%esp
80102a84:	bb e0 4b 11 80       	mov    $0x80114be0,%ebx
80102a89:	eb 47                	jmp    80102ad2 <startothers+0x6c>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a8b:	e8 ff f6 ff ff       	call   8010218f <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a90:	05 00 10 00 00       	add    $0x1000,%eax
80102a95:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void**)(code-8) = mpenter;
80102a9a:	c7 05 f8 6f 00 80 34 	movl   $0x80102b34,0x80006ff8
80102aa1:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102aa4:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102aab:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102aae:	83 ec 08             	sub    $0x8,%esp
80102ab1:	68 00 70 00 00       	push   $0x7000
80102ab6:	0f b6 03             	movzbl (%ebx),%eax
80102ab9:	50                   	push   %eax
80102aba:	e8 db f9 ff ff       	call   8010249a <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102abf:	83 c4 10             	add    $0x10,%esp
80102ac2:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ac8:	85 c0                	test   %eax,%eax
80102aca:	74 f6                	je     80102ac2 <startothers+0x5c>
  for(c = cpus; c < cpus+ncpu; c++){
80102acc:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ad2:	69 05 60 51 11 80 b0 	imul   $0xb0,0x80115160,%eax
80102ad9:	00 00 00 
80102adc:	05 e0 4b 11 80       	add    $0x80114be0,%eax
80102ae1:	39 d8                	cmp    %ebx,%eax
80102ae3:	76 0b                	jbe    80102af0 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102ae5:	e8 cf 07 00 00       	call   801032b9 <mycpu>
80102aea:	39 c3                	cmp    %eax,%ebx
80102aec:	74 de                	je     80102acc <startothers+0x66>
80102aee:	eb 9b                	jmp    80102a8b <startothers+0x25>
      ;
  }
}
80102af0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102af3:	c9                   	leave  
80102af4:	c3                   	ret    

80102af5 <mpmain>:
{
80102af5:	55                   	push   %ebp
80102af6:	89 e5                	mov    %esp,%ebp
80102af8:	53                   	push   %ebx
80102af9:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102afc:	e8 18 08 00 00       	call   80103319 <cpuid>
80102b01:	89 c3                	mov    %eax,%ebx
80102b03:	e8 11 08 00 00       	call   80103319 <cpuid>
80102b08:	83 ec 04             	sub    $0x4,%esp
80102b0b:	53                   	push   %ebx
80102b0c:	50                   	push   %eax
80102b0d:	68 c4 6e 10 80       	push   $0x80106ec4
80102b12:	e8 12 db ff ff       	call   80100629 <cprintf>
  idtinit();       // load idt register
80102b17:	e8 0f 28 00 00       	call   8010532b <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b1c:	e8 98 07 00 00       	call   801032b9 <mycpu>
80102b21:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b23:	b8 01 00 00 00       	mov    $0x1,%eax
80102b28:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b2f:	e8 bc 0a 00 00       	call   801035f0 <scheduler>

80102b34 <mpenter>:
{
80102b34:	f3 0f 1e fb          	endbr32 
80102b38:	55                   	push   %ebp
80102b39:	89 e5                	mov    %esp,%ebp
80102b3b:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b3e:	e8 0f 38 00 00       	call   80106352 <switchkvm>
  seginit();
80102b43:	e8 ba 36 00 00       	call   80106202 <seginit>
  lapicinit();
80102b48:	e8 f9 f7 ff ff       	call   80102346 <lapicinit>
  mpmain();
80102b4d:	e8 a3 ff ff ff       	call   80102af5 <mpmain>

80102b52 <main>:
{
80102b52:	f3 0f 1e fb          	endbr32 
80102b56:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b5a:	83 e4 f0             	and    $0xfffffff0,%esp
80102b5d:	ff 71 fc             	pushl  -0x4(%ecx)
80102b60:	55                   	push   %ebp
80102b61:	89 e5                	mov    %esp,%ebp
80102b63:	51                   	push   %ecx
80102b64:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b67:	68 00 00 40 80       	push   $0x80400000
80102b6c:	68 88 59 11 80       	push   $0x80115988
80102b71:	e8 bf f5 ff ff       	call   80102135 <kinit1>
  kvmalloc();      // kernel page table
80102b76:	e8 7a 3c 00 00       	call   801067f5 <kvmalloc>
  mpinit();        // detect other processors
80102b7b:	e8 c1 01 00 00       	call   80102d41 <mpinit>
  lapicinit();     // interrupt controller
80102b80:	e8 c1 f7 ff ff       	call   80102346 <lapicinit>
  seginit();       // segment descriptors
80102b85:	e8 78 36 00 00       	call   80106202 <seginit>
  picinit();       // disable pic
80102b8a:	e8 8c 02 00 00       	call   80102e1b <picinit>
  ioapicinit();    // another interrupt controller
80102b8f:	e8 1c f4 ff ff       	call   80101fb0 <ioapicinit>
  consoleinit();   // console hardware
80102b94:	e8 5a dd ff ff       	call   801008f3 <consoleinit>
  uartinit();      // serial port
80102b99:	e8 4c 2a 00 00       	call   801055ea <uartinit>
  pinit();         // process table
80102b9e:	e8 f8 06 00 00       	call   8010329b <pinit>
  tvinit();        // trap vectors
80102ba3:	e8 ea 26 00 00       	call   80105292 <tvinit>
  binit();         // buffer cache
80102ba8:	e8 47 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102bad:	e8 b6 e0 ff ff       	call   80100c68 <fileinit>
  ideinit();       // disk 
80102bb2:	e8 fb f1 ff ff       	call   80101db2 <ideinit>
  startothers();   // start other processors
80102bb7:	e8 aa fe ff ff       	call   80102a66 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102bbc:	83 c4 08             	add    $0x8,%esp
80102bbf:	68 00 00 00 8e       	push   $0x8e000000
80102bc4:	68 00 00 40 80       	push   $0x80400000
80102bc9:	e8 9d f5 ff ff       	call   8010216b <kinit2>
  userinit();      // first user process
80102bce:	e8 8d 07 00 00       	call   80103360 <userinit>
  mpmain();        // finish this processor's setup
80102bd3:	e8 1d ff ff ff       	call   80102af5 <mpmain>

80102bd8 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102bd8:	55                   	push   %ebp
80102bd9:	89 e5                	mov    %esp,%ebp
80102bdb:	56                   	push   %esi
80102bdc:	53                   	push   %ebx
80102bdd:	89 c6                	mov    %eax,%esi
  int i, sum;

  sum = 0;
80102bdf:	b8 00 00 00 00       	mov    $0x0,%eax
  for(i=0; i<len; i++)
80102be4:	b9 00 00 00 00       	mov    $0x0,%ecx
80102be9:	39 d1                	cmp    %edx,%ecx
80102beb:	7d 0b                	jge    80102bf8 <sum+0x20>
    sum += addr[i];
80102bed:	0f b6 1c 0e          	movzbl (%esi,%ecx,1),%ebx
80102bf1:	01 d8                	add    %ebx,%eax
  for(i=0; i<len; i++)
80102bf3:	83 c1 01             	add    $0x1,%ecx
80102bf6:	eb f1                	jmp    80102be9 <sum+0x11>
  return sum;
}
80102bf8:	5b                   	pop    %ebx
80102bf9:	5e                   	pop    %esi
80102bfa:	5d                   	pop    %ebp
80102bfb:	c3                   	ret    

80102bfc <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102bfc:	55                   	push   %ebp
80102bfd:	89 e5                	mov    %esp,%ebp
80102bff:	56                   	push   %esi
80102c00:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c01:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c07:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c09:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c0b:	eb 03                	jmp    80102c10 <mpsearch1+0x14>
80102c0d:	83 c3 10             	add    $0x10,%ebx
80102c10:	39 f3                	cmp    %esi,%ebx
80102c12:	73 29                	jae    80102c3d <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c14:	83 ec 04             	sub    $0x4,%esp
80102c17:	6a 04                	push   $0x4
80102c19:	68 d8 6e 10 80       	push   $0x80106ed8
80102c1e:	53                   	push   %ebx
80102c1f:	e8 61 14 00 00       	call   80104085 <memcmp>
80102c24:	83 c4 10             	add    $0x10,%esp
80102c27:	85 c0                	test   %eax,%eax
80102c29:	75 e2                	jne    80102c0d <mpsearch1+0x11>
80102c2b:	ba 10 00 00 00       	mov    $0x10,%edx
80102c30:	89 d8                	mov    %ebx,%eax
80102c32:	e8 a1 ff ff ff       	call   80102bd8 <sum>
80102c37:	84 c0                	test   %al,%al
80102c39:	75 d2                	jne    80102c0d <mpsearch1+0x11>
80102c3b:	eb 05                	jmp    80102c42 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c3d:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c42:	89 d8                	mov    %ebx,%eax
80102c44:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c47:	5b                   	pop    %ebx
80102c48:	5e                   	pop    %esi
80102c49:	5d                   	pop    %ebp
80102c4a:	c3                   	ret    

80102c4b <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c4b:	55                   	push   %ebp
80102c4c:	89 e5                	mov    %esp,%ebp
80102c4e:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c51:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c58:	c1 e0 08             	shl    $0x8,%eax
80102c5b:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c62:	09 d0                	or     %edx,%eax
80102c64:	c1 e0 04             	shl    $0x4,%eax
80102c67:	74 1f                	je     80102c88 <mpsearch+0x3d>
    if((mp = mpsearch1(p, 1024)))
80102c69:	ba 00 04 00 00       	mov    $0x400,%edx
80102c6e:	e8 89 ff ff ff       	call   80102bfc <mpsearch1>
80102c73:	85 c0                	test   %eax,%eax
80102c75:	75 0f                	jne    80102c86 <mpsearch+0x3b>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c77:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c7c:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c81:	e8 76 ff ff ff       	call   80102bfc <mpsearch1>
}
80102c86:	c9                   	leave  
80102c87:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c88:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c8f:	c1 e0 08             	shl    $0x8,%eax
80102c92:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c99:	09 d0                	or     %edx,%eax
80102c9b:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c9e:	2d 00 04 00 00       	sub    $0x400,%eax
80102ca3:	ba 00 04 00 00       	mov    $0x400,%edx
80102ca8:	e8 4f ff ff ff       	call   80102bfc <mpsearch1>
80102cad:	85 c0                	test   %eax,%eax
80102caf:	75 d5                	jne    80102c86 <mpsearch+0x3b>
80102cb1:	eb c4                	jmp    80102c77 <mpsearch+0x2c>

80102cb3 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102cb3:	55                   	push   %ebp
80102cb4:	89 e5                	mov    %esp,%ebp
80102cb6:	57                   	push   %edi
80102cb7:	56                   	push   %esi
80102cb8:	53                   	push   %ebx
80102cb9:	83 ec 1c             	sub    $0x1c,%esp
80102cbc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102cbf:	e8 87 ff ff ff       	call   80102c4b <mpsearch>
80102cc4:	89 c3                	mov    %eax,%ebx
80102cc6:	85 c0                	test   %eax,%eax
80102cc8:	74 5a                	je     80102d24 <mpconfig+0x71>
80102cca:	8b 70 04             	mov    0x4(%eax),%esi
80102ccd:	85 f6                	test   %esi,%esi
80102ccf:	74 57                	je     80102d28 <mpconfig+0x75>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102cd1:	8d be 00 00 00 80    	lea    -0x80000000(%esi),%edi
  if(memcmp(conf, "PCMP", 4) != 0)
80102cd7:	83 ec 04             	sub    $0x4,%esp
80102cda:	6a 04                	push   $0x4
80102cdc:	68 dd 6e 10 80       	push   $0x80106edd
80102ce1:	57                   	push   %edi
80102ce2:	e8 9e 13 00 00       	call   80104085 <memcmp>
80102ce7:	83 c4 10             	add    $0x10,%esp
80102cea:	85 c0                	test   %eax,%eax
80102cec:	75 3e                	jne    80102d2c <mpconfig+0x79>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102cee:	0f b6 86 06 00 00 80 	movzbl -0x7ffffffa(%esi),%eax
80102cf5:	3c 01                	cmp    $0x1,%al
80102cf7:	0f 95 c2             	setne  %dl
80102cfa:	3c 04                	cmp    $0x4,%al
80102cfc:	0f 95 c0             	setne  %al
80102cff:	84 c2                	test   %al,%dl
80102d01:	75 30                	jne    80102d33 <mpconfig+0x80>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d03:	0f b7 96 04 00 00 80 	movzwl -0x7ffffffc(%esi),%edx
80102d0a:	89 f8                	mov    %edi,%eax
80102d0c:	e8 c7 fe ff ff       	call   80102bd8 <sum>
80102d11:	84 c0                	test   %al,%al
80102d13:	75 25                	jne    80102d3a <mpconfig+0x87>
    return 0;
  *pmp = mp;
80102d15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d18:	89 18                	mov    %ebx,(%eax)
  return conf;
}
80102d1a:	89 f8                	mov    %edi,%eax
80102d1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d1f:	5b                   	pop    %ebx
80102d20:	5e                   	pop    %esi
80102d21:	5f                   	pop    %edi
80102d22:	5d                   	pop    %ebp
80102d23:	c3                   	ret    
    return 0;
80102d24:	89 c7                	mov    %eax,%edi
80102d26:	eb f2                	jmp    80102d1a <mpconfig+0x67>
80102d28:	89 f7                	mov    %esi,%edi
80102d2a:	eb ee                	jmp    80102d1a <mpconfig+0x67>
    return 0;
80102d2c:	bf 00 00 00 00       	mov    $0x0,%edi
80102d31:	eb e7                	jmp    80102d1a <mpconfig+0x67>
    return 0;
80102d33:	bf 00 00 00 00       	mov    $0x0,%edi
80102d38:	eb e0                	jmp    80102d1a <mpconfig+0x67>
    return 0;
80102d3a:	bf 00 00 00 00       	mov    $0x0,%edi
80102d3f:	eb d9                	jmp    80102d1a <mpconfig+0x67>

80102d41 <mpinit>:

void
mpinit(void)
{
80102d41:	f3 0f 1e fb          	endbr32 
80102d45:	55                   	push   %ebp
80102d46:	89 e5                	mov    %esp,%ebp
80102d48:	57                   	push   %edi
80102d49:	56                   	push   %esi
80102d4a:	53                   	push   %ebx
80102d4b:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d4e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d51:	e8 5d ff ff ff       	call   80102cb3 <mpconfig>
80102d56:	85 c0                	test   %eax,%eax
80102d58:	74 19                	je     80102d73 <mpinit+0x32>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d5a:	8b 50 24             	mov    0x24(%eax),%edx
80102d5d:	89 15 dc 4a 11 80    	mov    %edx,0x80114adc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d63:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d66:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d6a:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d6c:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d71:	eb 20                	jmp    80102d93 <mpinit+0x52>
    panic("Expect to run on an SMP");
80102d73:	83 ec 0c             	sub    $0xc,%esp
80102d76:	68 e2 6e 10 80       	push   $0x80106ee2
80102d7b:	e8 dc d5 ff ff       	call   8010035c <panic>
    switch(*p){
80102d80:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d85:	eb 0c                	jmp    80102d93 <mpinit+0x52>
80102d87:	83 e8 03             	sub    $0x3,%eax
80102d8a:	3c 01                	cmp    $0x1,%al
80102d8c:	76 1a                	jbe    80102da8 <mpinit+0x67>
80102d8e:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d93:	39 ca                	cmp    %ecx,%edx
80102d95:	73 4d                	jae    80102de4 <mpinit+0xa3>
    switch(*p){
80102d97:	0f b6 02             	movzbl (%edx),%eax
80102d9a:	3c 02                	cmp    $0x2,%al
80102d9c:	74 38                	je     80102dd6 <mpinit+0x95>
80102d9e:	77 e7                	ja     80102d87 <mpinit+0x46>
80102da0:	84 c0                	test   %al,%al
80102da2:	74 09                	je     80102dad <mpinit+0x6c>
80102da4:	3c 01                	cmp    $0x1,%al
80102da6:	75 d8                	jne    80102d80 <mpinit+0x3f>
      p += sizeof(struct mpioapic);
      continue;
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102da8:	83 c2 08             	add    $0x8,%edx
      continue;
80102dab:	eb e6                	jmp    80102d93 <mpinit+0x52>
      if(ncpu < NCPU) {
80102dad:	8b 35 60 51 11 80    	mov    0x80115160,%esi
80102db3:	83 fe 07             	cmp    $0x7,%esi
80102db6:	7f 19                	jg     80102dd1 <mpinit+0x90>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102db8:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dbc:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102dc2:	88 87 e0 4b 11 80    	mov    %al,-0x7feeb420(%edi)
        ncpu++;
80102dc8:	83 c6 01             	add    $0x1,%esi
80102dcb:	89 35 60 51 11 80    	mov    %esi,0x80115160
      p += sizeof(struct mpproc);
80102dd1:	83 c2 14             	add    $0x14,%edx
      continue;
80102dd4:	eb bd                	jmp    80102d93 <mpinit+0x52>
      ioapicid = ioapic->apicno;
80102dd6:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dda:	a2 c0 4b 11 80       	mov    %al,0x80114bc0
      p += sizeof(struct mpioapic);
80102ddf:	83 c2 08             	add    $0x8,%edx
      continue;
80102de2:	eb af                	jmp    80102d93 <mpinit+0x52>
    default:
      ismp = 0;
      break;
    }
  }
  if(!ismp)
80102de4:	85 db                	test   %ebx,%ebx
80102de6:	74 26                	je     80102e0e <mpinit+0xcd>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102de8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102deb:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102def:	74 15                	je     80102e06 <mpinit+0xc5>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102df1:	b8 70 00 00 00       	mov    $0x70,%eax
80102df6:	ba 22 00 00 00       	mov    $0x22,%edx
80102dfb:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dfc:	ba 23 00 00 00       	mov    $0x23,%edx
80102e01:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e02:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e05:	ee                   	out    %al,(%dx)
  }
}
80102e06:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e09:	5b                   	pop    %ebx
80102e0a:	5e                   	pop    %esi
80102e0b:	5f                   	pop    %edi
80102e0c:	5d                   	pop    %ebp
80102e0d:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e0e:	83 ec 0c             	sub    $0xc,%esp
80102e11:	68 fc 6e 10 80       	push   $0x80106efc
80102e16:	e8 41 d5 ff ff       	call   8010035c <panic>

80102e1b <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e1b:	f3 0f 1e fb          	endbr32 
80102e1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e24:	ba 21 00 00 00       	mov    $0x21,%edx
80102e29:	ee                   	out    %al,(%dx)
80102e2a:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e2f:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e30:	c3                   	ret    

80102e31 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e31:	f3 0f 1e fb          	endbr32 
80102e35:	55                   	push   %ebp
80102e36:	89 e5                	mov    %esp,%ebp
80102e38:	57                   	push   %edi
80102e39:	56                   	push   %esi
80102e3a:	53                   	push   %ebx
80102e3b:	83 ec 0c             	sub    $0xc,%esp
80102e3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e41:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e44:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e4a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e50:	e8 31 de ff ff       	call   80100c86 <filealloc>
80102e55:	89 03                	mov    %eax,(%ebx)
80102e57:	85 c0                	test   %eax,%eax
80102e59:	0f 84 88 00 00 00    	je     80102ee7 <pipealloc+0xb6>
80102e5f:	e8 22 de ff ff       	call   80100c86 <filealloc>
80102e64:	89 06                	mov    %eax,(%esi)
80102e66:	85 c0                	test   %eax,%eax
80102e68:	74 7d                	je     80102ee7 <pipealloc+0xb6>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e6a:	e8 20 f3 ff ff       	call   8010218f <kalloc>
80102e6f:	89 c7                	mov    %eax,%edi
80102e71:	85 c0                	test   %eax,%eax
80102e73:	74 72                	je     80102ee7 <pipealloc+0xb6>
    goto bad;
  p->readopen = 1;
80102e75:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e7c:	00 00 00 
  p->writeopen = 1;
80102e7f:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e86:	00 00 00 
  p->nwrite = 0;
80102e89:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e90:	00 00 00 
  p->nread = 0;
80102e93:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e9a:	00 00 00 
  initlock(&p->lock, "pipe");
80102e9d:	83 ec 08             	sub    $0x8,%esp
80102ea0:	68 1b 6f 10 80       	push   $0x80106f1b
80102ea5:	50                   	push   %eax
80102ea6:	e8 8f 0f 00 00       	call   80103e3a <initlock>
  (*f0)->type = FD_PIPE;
80102eab:	8b 03                	mov    (%ebx),%eax
80102ead:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102eb3:	8b 03                	mov    (%ebx),%eax
80102eb5:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102eb9:	8b 03                	mov    (%ebx),%eax
80102ebb:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102ebf:	8b 03                	mov    (%ebx),%eax
80102ec1:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102ec4:	8b 06                	mov    (%esi),%eax
80102ec6:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102ecc:	8b 06                	mov    (%esi),%eax
80102ece:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102ed2:	8b 06                	mov    (%esi),%eax
80102ed4:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102ed8:	8b 06                	mov    (%esi),%eax
80102eda:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102edd:	83 c4 10             	add    $0x10,%esp
80102ee0:	b8 00 00 00 00       	mov    $0x0,%eax
80102ee5:	eb 29                	jmp    80102f10 <pipealloc+0xdf>

//PAGEBREAK: 20
 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102ee7:	8b 03                	mov    (%ebx),%eax
80102ee9:	85 c0                	test   %eax,%eax
80102eeb:	74 0c                	je     80102ef9 <pipealloc+0xc8>
    fileclose(*f0);
80102eed:	83 ec 0c             	sub    $0xc,%esp
80102ef0:	50                   	push   %eax
80102ef1:	e8 3e de ff ff       	call   80100d34 <fileclose>
80102ef6:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102ef9:	8b 06                	mov    (%esi),%eax
80102efb:	85 c0                	test   %eax,%eax
80102efd:	74 19                	je     80102f18 <pipealloc+0xe7>
    fileclose(*f1);
80102eff:	83 ec 0c             	sub    $0xc,%esp
80102f02:	50                   	push   %eax
80102f03:	e8 2c de ff ff       	call   80100d34 <fileclose>
80102f08:	83 c4 10             	add    $0x10,%esp
  return -1;
80102f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f13:	5b                   	pop    %ebx
80102f14:	5e                   	pop    %esi
80102f15:	5f                   	pop    %edi
80102f16:	5d                   	pop    %ebp
80102f17:	c3                   	ret    
  return -1;
80102f18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f1d:	eb f1                	jmp    80102f10 <pipealloc+0xdf>

80102f1f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f1f:	f3 0f 1e fb          	endbr32 
80102f23:	55                   	push   %ebp
80102f24:	89 e5                	mov    %esp,%ebp
80102f26:	53                   	push   %ebx
80102f27:	83 ec 10             	sub    $0x10,%esp
80102f2a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f2d:	53                   	push   %ebx
80102f2e:	e8 57 10 00 00       	call   80103f8a <acquire>
  if(writable){
80102f33:	83 c4 10             	add    $0x10,%esp
80102f36:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f3a:	74 3f                	je     80102f7b <pipeclose+0x5c>
    p->writeopen = 0;
80102f3c:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f43:	00 00 00 
    wakeup(&p->nread);
80102f46:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f4c:	83 ec 0c             	sub    $0xc,%esp
80102f4f:	50                   	push   %eax
80102f50:	e8 87 0a 00 00       	call   801039dc <wakeup>
80102f55:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f58:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f5f:	75 09                	jne    80102f6a <pipeclose+0x4b>
80102f61:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f68:	74 2f                	je     80102f99 <pipeclose+0x7a>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f6a:	83 ec 0c             	sub    $0xc,%esp
80102f6d:	53                   	push   %ebx
80102f6e:	e8 80 10 00 00       	call   80103ff3 <release>
80102f73:	83 c4 10             	add    $0x10,%esp
}
80102f76:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f79:	c9                   	leave  
80102f7a:	c3                   	ret    
    p->readopen = 0;
80102f7b:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f82:	00 00 00 
    wakeup(&p->nwrite);
80102f85:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f8b:	83 ec 0c             	sub    $0xc,%esp
80102f8e:	50                   	push   %eax
80102f8f:	e8 48 0a 00 00       	call   801039dc <wakeup>
80102f94:	83 c4 10             	add    $0x10,%esp
80102f97:	eb bf                	jmp    80102f58 <pipeclose+0x39>
    release(&p->lock);
80102f99:	83 ec 0c             	sub    $0xc,%esp
80102f9c:	53                   	push   %ebx
80102f9d:	e8 51 10 00 00       	call   80103ff3 <release>
    kfree((char*)p);
80102fa2:	89 1c 24             	mov    %ebx,(%esp)
80102fa5:	e8 be f0 ff ff       	call   80102068 <kfree>
80102faa:	83 c4 10             	add    $0x10,%esp
80102fad:	eb c7                	jmp    80102f76 <pipeclose+0x57>

80102faf <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80102faf:	f3 0f 1e fb          	endbr32 
80102fb3:	55                   	push   %ebp
80102fb4:	89 e5                	mov    %esp,%ebp
80102fb6:	57                   	push   %edi
80102fb7:	56                   	push   %esi
80102fb8:	53                   	push   %ebx
80102fb9:	83 ec 18             	sub    $0x18,%esp
80102fbc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fbf:	89 de                	mov    %ebx,%esi
80102fc1:	53                   	push   %ebx
80102fc2:	e8 c3 0f 00 00       	call   80103f8a <acquire>
  for(i = 0; i < n; i++){
80102fc7:	83 c4 10             	add    $0x10,%esp
80102fca:	bf 00 00 00 00       	mov    $0x0,%edi
80102fcf:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102fd2:	7c 41                	jl     80103015 <pipewrite+0x66>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102fd4:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fda:	83 ec 0c             	sub    $0xc,%esp
80102fdd:	50                   	push   %eax
80102fde:	e8 f9 09 00 00       	call   801039dc <wakeup>
  release(&p->lock);
80102fe3:	89 1c 24             	mov    %ebx,(%esp)
80102fe6:	e8 08 10 00 00       	call   80103ff3 <release>
  return n;
80102feb:	83 c4 10             	add    $0x10,%esp
80102fee:	8b 45 10             	mov    0x10(%ebp),%eax
80102ff1:	eb 5c                	jmp    8010304f <pipewrite+0xa0>
      wakeup(&p->nread);
80102ff3:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ff9:	83 ec 0c             	sub    $0xc,%esp
80102ffc:	50                   	push   %eax
80102ffd:	e8 da 09 00 00       	call   801039dc <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103002:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103008:	83 c4 08             	add    $0x8,%esp
8010300b:	56                   	push   %esi
8010300c:	50                   	push   %eax
8010300d:	e8 5b 08 00 00       	call   8010386d <sleep>
80103012:	83 c4 10             	add    $0x10,%esp
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103015:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
8010301b:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103021:	05 00 02 00 00       	add    $0x200,%eax
80103026:	39 c2                	cmp    %eax,%edx
80103028:	75 2d                	jne    80103057 <pipewrite+0xa8>
      if(p->readopen == 0 || myproc()->killed){
8010302a:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103031:	74 0b                	je     8010303e <pipewrite+0x8f>
80103033:	e8 00 03 00 00       	call   80103338 <myproc>
80103038:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010303c:	74 b5                	je     80102ff3 <pipewrite+0x44>
        release(&p->lock);
8010303e:	83 ec 0c             	sub    $0xc,%esp
80103041:	53                   	push   %ebx
80103042:	e8 ac 0f 00 00       	call   80103ff3 <release>
        return -1;
80103047:	83 c4 10             	add    $0x10,%esp
8010304a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010304f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103052:	5b                   	pop    %ebx
80103053:	5e                   	pop    %esi
80103054:	5f                   	pop    %edi
80103055:	5d                   	pop    %ebp
80103056:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103057:	8d 42 01             	lea    0x1(%edx),%eax
8010305a:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103060:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103066:	8b 45 0c             	mov    0xc(%ebp),%eax
80103069:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010306d:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103071:	83 c7 01             	add    $0x1,%edi
80103074:	e9 56 ff ff ff       	jmp    80102fcf <pipewrite+0x20>

80103079 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103079:	f3 0f 1e fb          	endbr32 
8010307d:	55                   	push   %ebp
8010307e:	89 e5                	mov    %esp,%ebp
80103080:	57                   	push   %edi
80103081:	56                   	push   %esi
80103082:	53                   	push   %ebx
80103083:	83 ec 18             	sub    $0x18,%esp
80103086:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103089:	89 df                	mov    %ebx,%edi
8010308b:	53                   	push   %ebx
8010308c:	e8 f9 0e 00 00       	call   80103f8a <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103091:	83 c4 10             	add    $0x10,%esp
80103094:	eb 13                	jmp    801030a9 <piperead+0x30>
    if(myproc()->killed){
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103096:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010309c:	83 ec 08             	sub    $0x8,%esp
8010309f:	57                   	push   %edi
801030a0:	50                   	push   %eax
801030a1:	e8 c7 07 00 00       	call   8010386d <sleep>
801030a6:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030a9:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030af:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030b5:	75 28                	jne    801030df <piperead+0x66>
801030b7:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030bd:	85 f6                	test   %esi,%esi
801030bf:	74 23                	je     801030e4 <piperead+0x6b>
    if(myproc()->killed){
801030c1:	e8 72 02 00 00       	call   80103338 <myproc>
801030c6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801030ca:	74 ca                	je     80103096 <piperead+0x1d>
      release(&p->lock);
801030cc:	83 ec 0c             	sub    $0xc,%esp
801030cf:	53                   	push   %ebx
801030d0:	e8 1e 0f 00 00       	call   80103ff3 <release>
      return -1;
801030d5:	83 c4 10             	add    $0x10,%esp
801030d8:	be ff ff ff ff       	mov    $0xffffffff,%esi
801030dd:	eb 50                	jmp    8010312f <piperead+0xb6>
801030df:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030e4:	3b 75 10             	cmp    0x10(%ebp),%esi
801030e7:	7d 2c                	jge    80103115 <piperead+0x9c>
    if(p->nread == p->nwrite)
801030e9:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801030ef:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801030f5:	74 1e                	je     80103115 <piperead+0x9c>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801030f7:	8d 50 01             	lea    0x1(%eax),%edx
801030fa:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103100:	25 ff 01 00 00       	and    $0x1ff,%eax
80103105:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010310a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010310d:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103110:	83 c6 01             	add    $0x1,%esi
80103113:	eb cf                	jmp    801030e4 <piperead+0x6b>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103115:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010311b:	83 ec 0c             	sub    $0xc,%esp
8010311e:	50                   	push   %eax
8010311f:	e8 b8 08 00 00       	call   801039dc <wakeup>
  release(&p->lock);
80103124:	89 1c 24             	mov    %ebx,(%esp)
80103127:	e8 c7 0e 00 00       	call   80103ff3 <release>
  return i;
8010312c:	83 c4 10             	add    $0x10,%esp
}
8010312f:	89 f0                	mov    %esi,%eax
80103131:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103134:	5b                   	pop    %ebx
80103135:	5e                   	pop    %esi
80103136:	5f                   	pop    %edi
80103137:	5d                   	pop    %ebp
80103138:	c3                   	ret    

80103139 <wakeup1>:
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103139:	ba 14 a6 10 80       	mov    $0x8010a614,%edx
8010313e:	eb 0d                	jmp    8010314d <wakeup1+0x14>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
80103140:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103147:	81 c2 90 00 00 00    	add    $0x90,%edx
8010314d:	81 fa 14 ca 10 80    	cmp    $0x8010ca14,%edx
80103153:	73 0d                	jae    80103162 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103155:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103159:	75 ec                	jne    80103147 <wakeup1+0xe>
8010315b:	39 42 20             	cmp    %eax,0x20(%edx)
8010315e:	75 e7                	jne    80103147 <wakeup1+0xe>
80103160:	eb de                	jmp    80103140 <wakeup1+0x7>
}
80103162:	c3                   	ret    

80103163 <allocproc>:
{
80103163:	55                   	push   %ebp
80103164:	89 e5                	mov    %esp,%ebp
80103166:	53                   	push   %ebx
80103167:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
8010316a:	68 e0 a5 10 80       	push   $0x8010a5e0
8010316f:	e8 16 0e 00 00       	call   80103f8a <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103174:	83 c4 10             	add    $0x10,%esp
80103177:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
8010317c:	81 fb 14 ca 10 80    	cmp    $0x8010ca14,%ebx
80103182:	73 0e                	jae    80103192 <allocproc+0x2f>
    if(p->state == UNUSED) {
80103184:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103188:	74 0f                	je     80103199 <allocproc+0x36>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010318a:	81 c3 90 00 00 00    	add    $0x90,%ebx
80103190:	eb ea                	jmp    8010317c <allocproc+0x19>
  int found = 0;
80103192:	b8 00 00 00 00       	mov    $0x0,%eax
80103197:	eb 05                	jmp    8010319e <allocproc+0x3b>
      found = 1;
80103199:	b8 01 00 00 00       	mov    $0x1,%eax
  if (!found) {
8010319e:	85 c0                	test   %eax,%eax
801031a0:	0f 84 8c 00 00 00    	je     80103232 <allocproc+0xcf>
  p->state = EMBRYO;
801031a6:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801031ad:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801031b2:	8d 50 01             	lea    0x1(%eax),%edx
801031b5:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801031bb:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801031be:	83 ec 0c             	sub    $0xc,%esp
801031c1:	68 e0 a5 10 80       	push   $0x8010a5e0
801031c6:	e8 28 0e 00 00       	call   80103ff3 <release>
  if((p->kstack = kalloc()) == 0){
801031cb:	e8 bf ef ff ff       	call   8010218f <kalloc>
801031d0:	89 43 08             	mov    %eax,0x8(%ebx)
801031d3:	83 c4 10             	add    $0x10,%esp
801031d6:	85 c0                	test   %eax,%eax
801031d8:	74 6f                	je     80103249 <allocproc+0xe6>
  sp -= sizeof *p->tf;
801031da:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031e0:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801031e3:	c7 80 b0 0f 00 00 87 	movl   $0x80105287,0xfb0(%eax)
801031ea:	52 10 80 
  sp -= sizeof *p->context;
801031ed:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801031f2:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801031f5:	83 ec 04             	sub    $0x4,%esp
801031f8:	6a 14                	push   $0x14
801031fa:	6a 00                	push   $0x0
801031fc:	50                   	push   %eax
801031fd:	e8 3c 0e 00 00       	call   8010403e <memset>
  p->context->eip = (uint)forkret;
80103202:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103205:	c7 40 10 54 32 10 80 	movl   $0x80103254,0x10(%eax)
    p->start_ticks = ticks;
8010320c:	a1 80 59 11 80       	mov    0x80115980,%eax
80103211:	89 43 7c             	mov    %eax,0x7c(%ebx)
    p->cpu_ticks_total = 0;
80103214:	c7 83 88 00 00 00 00 	movl   $0x0,0x88(%ebx)
8010321b:	00 00 00 
    p->cpu_ticks_in = 0;
8010321e:	c7 83 8c 00 00 00 00 	movl   $0x0,0x8c(%ebx)
80103225:	00 00 00 
  return p;
80103228:	83 c4 10             	add    $0x10,%esp
}
8010322b:	89 d8                	mov    %ebx,%eax
8010322d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103230:	c9                   	leave  
80103231:	c3                   	ret    
    release(&ptable.lock);
80103232:	83 ec 0c             	sub    $0xc,%esp
80103235:	68 e0 a5 10 80       	push   $0x8010a5e0
8010323a:	e8 b4 0d 00 00       	call   80103ff3 <release>
    return 0;
8010323f:	83 c4 10             	add    $0x10,%esp
80103242:	bb 00 00 00 00       	mov    $0x0,%ebx
80103247:	eb e2                	jmp    8010322b <allocproc+0xc8>
    p->state = UNUSED;
80103249:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103250:	89 c3                	mov    %eax,%ebx
80103252:	eb d7                	jmp    8010322b <allocproc+0xc8>

80103254 <forkret>:
{
80103254:	f3 0f 1e fb          	endbr32 
80103258:	55                   	push   %ebp
80103259:	89 e5                	mov    %esp,%ebp
8010325b:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010325e:	68 e0 a5 10 80       	push   $0x8010a5e0
80103263:	e8 8b 0d 00 00       	call   80103ff3 <release>
  if (first) {
80103268:	83 c4 10             	add    $0x10,%esp
8010326b:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103272:	75 02                	jne    80103276 <forkret+0x22>
}
80103274:	c9                   	leave  
80103275:	c3                   	ret    
    first = 0;
80103276:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010327d:	00 00 00 
    iinit(ROOTDEV);
80103280:	83 ec 0c             	sub    $0xc,%esp
80103283:	6a 01                	push   $0x1
80103285:	e8 d8 e0 ff ff       	call   80101362 <iinit>
    initlog(ROOTDEV);
8010328a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103291:	e8 a9 f5 ff ff       	call   8010283f <initlog>
80103296:	83 c4 10             	add    $0x10,%esp
}
80103299:	eb d9                	jmp    80103274 <forkret+0x20>

8010329b <pinit>:
{
8010329b:	f3 0f 1e fb          	endbr32 
8010329f:	55                   	push   %ebp
801032a0:	89 e5                	mov    %esp,%ebp
801032a2:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801032a5:	68 20 6f 10 80       	push   $0x80106f20
801032aa:	68 e0 a5 10 80       	push   $0x8010a5e0
801032af:	e8 86 0b 00 00       	call   80103e3a <initlock>
}
801032b4:	83 c4 10             	add    $0x10,%esp
801032b7:	c9                   	leave  
801032b8:	c3                   	ret    

801032b9 <mycpu>:
{
801032b9:	f3 0f 1e fb          	endbr32 
801032bd:	55                   	push   %ebp
801032be:	89 e5                	mov    %esp,%ebp
801032c0:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032c3:	9c                   	pushf  
801032c4:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032c5:	f6 c4 02             	test   $0x2,%ah
801032c8:	75 28                	jne    801032f2 <mycpu+0x39>
  apicid = lapicid();
801032ca:	e8 87 f1 ff ff       	call   80102456 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032cf:	ba 00 00 00 00       	mov    $0x0,%edx
801032d4:	39 15 60 51 11 80    	cmp    %edx,0x80115160
801032da:	7e 30                	jle    8010330c <mycpu+0x53>
    if (cpus[i].apicid == apicid) {
801032dc:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032e2:	0f b6 89 e0 4b 11 80 	movzbl -0x7feeb420(%ecx),%ecx
801032e9:	39 c1                	cmp    %eax,%ecx
801032eb:	74 12                	je     801032ff <mycpu+0x46>
  for (i = 0; i < ncpu; ++i) {
801032ed:	83 c2 01             	add    $0x1,%edx
801032f0:	eb e2                	jmp    801032d4 <mycpu+0x1b>
    panic("mycpu called with interrupts enabled\n");
801032f2:	83 ec 0c             	sub    $0xc,%esp
801032f5:	68 f0 6f 10 80       	push   $0x80106ff0
801032fa:	e8 5d d0 ff ff       	call   8010035c <panic>
      return &cpus[i];
801032ff:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103305:	05 e0 4b 11 80       	add    $0x80114be0,%eax
}
8010330a:	c9                   	leave  
8010330b:	c3                   	ret    
  panic("unknown apicid\n");
8010330c:	83 ec 0c             	sub    $0xc,%esp
8010330f:	68 27 6f 10 80       	push   $0x80106f27
80103314:	e8 43 d0 ff ff       	call   8010035c <panic>

80103319 <cpuid>:
cpuid() {
80103319:	f3 0f 1e fb          	endbr32 
8010331d:	55                   	push   %ebp
8010331e:	89 e5                	mov    %esp,%ebp
80103320:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103323:	e8 91 ff ff ff       	call   801032b9 <mycpu>
80103328:	2d e0 4b 11 80       	sub    $0x80114be0,%eax
8010332d:	c1 f8 04             	sar    $0x4,%eax
80103330:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103336:	c9                   	leave  
80103337:	c3                   	ret    

80103338 <myproc>:
myproc(void) {
80103338:	f3 0f 1e fb          	endbr32 
8010333c:	55                   	push   %ebp
8010333d:	89 e5                	mov    %esp,%ebp
8010333f:	53                   	push   %ebx
80103340:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103343:	e8 59 0b 00 00       	call   80103ea1 <pushcli>
  c = mycpu();
80103348:	e8 6c ff ff ff       	call   801032b9 <mycpu>
  p = c->proc;
8010334d:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103353:	e8 8a 0b 00 00       	call   80103ee2 <popcli>
}
80103358:	89 d8                	mov    %ebx,%eax
8010335a:	83 c4 04             	add    $0x4,%esp
8010335d:	5b                   	pop    %ebx
8010335e:	5d                   	pop    %ebp
8010335f:	c3                   	ret    

80103360 <userinit>:
{
80103360:	f3 0f 1e fb          	endbr32 
80103364:	55                   	push   %ebp
80103365:	89 e5                	mov    %esp,%ebp
80103367:	53                   	push   %ebx
80103368:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010336b:	e8 f3 fd ff ff       	call   80103163 <allocproc>
80103370:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103372:	a3 c0 a5 10 80       	mov    %eax,0x8010a5c0
  if((p->pgdir = setupkvm()) == 0)
80103377:	e8 07 34 00 00       	call   80106783 <setupkvm>
8010337c:	89 43 04             	mov    %eax,0x4(%ebx)
8010337f:	85 c0                	test   %eax,%eax
80103381:	0f 84 cc 00 00 00    	je     80103453 <userinit+0xf3>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103387:	83 ec 04             	sub    $0x4,%esp
8010338a:	68 2c 00 00 00       	push   $0x2c
8010338f:	68 60 a4 10 80       	push   $0x8010a460
80103394:	50                   	push   %eax
80103395:	e8 e6 30 00 00       	call   80106480 <inituvm>
  p->sz = PGSIZE;
8010339a:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801033a0:	8b 43 18             	mov    0x18(%ebx),%eax
801033a3:	83 c4 0c             	add    $0xc,%esp
801033a6:	6a 4c                	push   $0x4c
801033a8:	6a 00                	push   $0x0
801033aa:	50                   	push   %eax
801033ab:	e8 8e 0c 00 00       	call   8010403e <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801033b0:	8b 43 18             	mov    0x18(%ebx),%eax
801033b3:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801033b9:	8b 43 18             	mov    0x18(%ebx),%eax
801033bc:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033c2:	8b 43 18             	mov    0x18(%ebx),%eax
801033c5:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033c9:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033cd:	8b 43 18             	mov    0x18(%ebx),%eax
801033d0:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033d4:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033d8:	8b 43 18             	mov    0x18(%ebx),%eax
801033db:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033e2:	8b 43 18             	mov    0x18(%ebx),%eax
801033e5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033ec:	8b 43 18             	mov    0x18(%ebx),%eax
801033ef:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033f6:	8d 43 6c             	lea    0x6c(%ebx),%eax
801033f9:	83 c4 0c             	add    $0xc,%esp
801033fc:	6a 10                	push   $0x10
801033fe:	68 50 6f 10 80       	push   $0x80106f50
80103403:	50                   	push   %eax
80103404:	e8 b5 0d 00 00       	call   801041be <safestrcpy>
  p->cwd = namei("/");
80103409:	c7 04 24 59 6f 10 80 	movl   $0x80106f59,(%esp)
80103410:	e8 77 e8 ff ff       	call   80101c8c <namei>
80103415:	89 43 68             	mov    %eax,0x68(%ebx)
    p->uid = DEFAULT_UID;
80103418:	c7 83 80 00 00 00 00 	movl   $0x0,0x80(%ebx)
8010341f:	00 00 00 
    p->gid = DEFAULT_GID;
80103422:	c7 83 84 00 00 00 00 	movl   $0x0,0x84(%ebx)
80103429:	00 00 00 
  acquire(&ptable.lock);
8010342c:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103433:	e8 52 0b 00 00       	call   80103f8a <acquire>
  p->state = RUNNABLE;
80103438:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010343f:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103446:	e8 a8 0b 00 00       	call   80103ff3 <release>
}
8010344b:	83 c4 10             	add    $0x10,%esp
8010344e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103451:	c9                   	leave  
80103452:	c3                   	ret    
    panic("userinit: out of memory?");
80103453:	83 ec 0c             	sub    $0xc,%esp
80103456:	68 37 6f 10 80       	push   $0x80106f37
8010345b:	e8 fc ce ff ff       	call   8010035c <panic>

80103460 <growproc>:
{
80103460:	f3 0f 1e fb          	endbr32 
80103464:	55                   	push   %ebp
80103465:	89 e5                	mov    %esp,%ebp
80103467:	56                   	push   %esi
80103468:	53                   	push   %ebx
80103469:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010346c:	e8 c7 fe ff ff       	call   80103338 <myproc>
80103471:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103473:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103475:	85 f6                	test   %esi,%esi
80103477:	7f 1c                	jg     80103495 <growproc+0x35>
  } else if(n < 0){
80103479:	78 37                	js     801034b2 <growproc+0x52>
  curproc->sz = sz;
8010347b:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010347d:	83 ec 0c             	sub    $0xc,%esp
80103480:	53                   	push   %ebx
80103481:	e8 de 2e 00 00       	call   80106364 <switchuvm>
  return 0;
80103486:	83 c4 10             	add    $0x10,%esp
80103489:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010348e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103491:	5b                   	pop    %ebx
80103492:	5e                   	pop    %esi
80103493:	5d                   	pop    %ebp
80103494:	c3                   	ret    
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103495:	83 ec 04             	sub    $0x4,%esp
80103498:	01 c6                	add    %eax,%esi
8010349a:	56                   	push   %esi
8010349b:	50                   	push   %eax
8010349c:	ff 73 04             	pushl  0x4(%ebx)
8010349f:	e8 7e 31 00 00       	call   80106622 <allocuvm>
801034a4:	83 c4 10             	add    $0x10,%esp
801034a7:	85 c0                	test   %eax,%eax
801034a9:	75 d0                	jne    8010347b <growproc+0x1b>
      return -1;
801034ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034b0:	eb dc                	jmp    8010348e <growproc+0x2e>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801034b2:	83 ec 04             	sub    $0x4,%esp
801034b5:	01 c6                	add    %eax,%esi
801034b7:	56                   	push   %esi
801034b8:	50                   	push   %eax
801034b9:	ff 73 04             	pushl  0x4(%ebx)
801034bc:	e8 cb 30 00 00       	call   8010658c <deallocuvm>
801034c1:	83 c4 10             	add    $0x10,%esp
801034c4:	85 c0                	test   %eax,%eax
801034c6:	75 b3                	jne    8010347b <growproc+0x1b>
      return -1;
801034c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034cd:	eb bf                	jmp    8010348e <growproc+0x2e>

801034cf <fork>:
{
801034cf:	f3 0f 1e fb          	endbr32 
801034d3:	55                   	push   %ebp
801034d4:	89 e5                	mov    %esp,%ebp
801034d6:	57                   	push   %edi
801034d7:	56                   	push   %esi
801034d8:	53                   	push   %ebx
801034d9:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034dc:	e8 57 fe ff ff       	call   80103338 <myproc>
801034e1:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034e3:	e8 7b fc ff ff       	call   80103163 <allocproc>
801034e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034eb:	85 c0                	test   %eax,%eax
801034ed:	0f 84 f6 00 00 00    	je     801035e9 <fork+0x11a>
801034f3:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801034f5:	83 ec 08             	sub    $0x8,%esp
801034f8:	ff 33                	pushl  (%ebx)
801034fa:	ff 73 04             	pushl  0x4(%ebx)
801034fd:	e8 3e 33 00 00       	call   80106840 <copyuvm>
80103502:	89 47 04             	mov    %eax,0x4(%edi)
80103505:	83 c4 10             	add    $0x10,%esp
80103508:	85 c0                	test   %eax,%eax
8010350a:	74 40                	je     8010354c <fork+0x7d>
  np->sz = curproc->sz;
8010350c:	8b 03                	mov    (%ebx),%eax
8010350e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103511:	89 02                	mov    %eax,(%edx)
  np->parent = curproc;
80103513:	89 5a 14             	mov    %ebx,0x14(%edx)
  *np->tf = *curproc->tf;
80103516:	8b 73 18             	mov    0x18(%ebx),%esi
80103519:	8b 7a 18             	mov    0x18(%edx),%edi
8010351c:	b9 13 00 00 00       	mov    $0x13,%ecx
80103521:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    np->uid = curproc->uid;
80103523:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
80103529:	89 82 80 00 00 00    	mov    %eax,0x80(%edx)
    np->gid = curproc->gid;
8010352f:	8b 83 84 00 00 00    	mov    0x84(%ebx),%eax
80103535:	89 82 84 00 00 00    	mov    %eax,0x84(%edx)
  np->tf->eax = 0;
8010353b:	8b 42 18             	mov    0x18(%edx),%eax
8010353e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103545:	be 00 00 00 00       	mov    $0x0,%esi
8010354a:	eb 3c                	jmp    80103588 <fork+0xb9>
    kfree(np->kstack);
8010354c:	83 ec 0c             	sub    $0xc,%esp
8010354f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103552:	ff 77 08             	pushl  0x8(%edi)
80103555:	e8 0e eb ff ff       	call   80102068 <kfree>
    np->kstack = 0;
8010355a:	c7 47 08 00 00 00 00 	movl   $0x0,0x8(%edi)
    np->state = UNUSED;
80103561:	c7 47 0c 00 00 00 00 	movl   $0x0,0xc(%edi)
    return -1;
80103568:	83 c4 10             	add    $0x10,%esp
8010356b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103570:	eb 6f                	jmp    801035e1 <fork+0x112>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103572:	83 ec 0c             	sub    $0xc,%esp
80103575:	50                   	push   %eax
80103576:	e8 70 d7 ff ff       	call   80100ceb <filedup>
8010357b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010357e:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103582:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NOFILE; i++)
80103585:	83 c6 01             	add    $0x1,%esi
80103588:	83 fe 0f             	cmp    $0xf,%esi
8010358b:	7f 0a                	jg     80103597 <fork+0xc8>
    if(curproc->ofile[i])
8010358d:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103591:	85 c0                	test   %eax,%eax
80103593:	75 dd                	jne    80103572 <fork+0xa3>
80103595:	eb ee                	jmp    80103585 <fork+0xb6>
  np->cwd = idup(curproc->cwd);
80103597:	83 ec 0c             	sub    $0xc,%esp
8010359a:	ff 73 68             	pushl  0x68(%ebx)
8010359d:	e8 31 e0 ff ff       	call   801015d3 <idup>
801035a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801035a5:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801035a8:	83 c3 6c             	add    $0x6c,%ebx
801035ab:	8d 47 6c             	lea    0x6c(%edi),%eax
801035ae:	83 c4 0c             	add    $0xc,%esp
801035b1:	6a 10                	push   $0x10
801035b3:	53                   	push   %ebx
801035b4:	50                   	push   %eax
801035b5:	e8 04 0c 00 00       	call   801041be <safestrcpy>
  pid = np->pid;
801035ba:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801035bd:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
801035c4:	e8 c1 09 00 00       	call   80103f8a <acquire>
  np->state = RUNNABLE;
801035c9:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801035d0:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
801035d7:	e8 17 0a 00 00       	call   80103ff3 <release>
  return pid;
801035dc:	89 d8                	mov    %ebx,%eax
801035de:	83 c4 10             	add    $0x10,%esp
}
801035e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035e4:	5b                   	pop    %ebx
801035e5:	5e                   	pop    %esi
801035e6:	5f                   	pop    %edi
801035e7:	5d                   	pop    %ebp
801035e8:	c3                   	ret    
    return -1;
801035e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035ee:	eb f1                	jmp    801035e1 <fork+0x112>

801035f0 <scheduler>:
{
801035f0:	f3 0f 1e fb          	endbr32 
801035f4:	55                   	push   %ebp
801035f5:	89 e5                	mov    %esp,%ebp
801035f7:	57                   	push   %edi
801035f8:	56                   	push   %esi
801035f9:	53                   	push   %ebx
801035fa:	83 ec 0c             	sub    $0xc,%esp
  struct cpu *c = mycpu();
801035fd:	e8 b7 fc ff ff       	call   801032b9 <mycpu>
80103602:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103604:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010360b:	00 00 00 
8010360e:	eb 73                	jmp    80103683 <scheduler+0x93>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103610:	81 c3 90 00 00 00    	add    $0x90,%ebx
80103616:	81 fb 14 ca 10 80    	cmp    $0x8010ca14,%ebx
8010361c:	73 4f                	jae    8010366d <scheduler+0x7d>
      if(p->state != RUNNABLE)
8010361e:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103622:	75 ec                	jne    80103610 <scheduler+0x20>
      c->proc = p;
80103624:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
8010362a:	83 ec 0c             	sub    $0xc,%esp
8010362d:	53                   	push   %ebx
8010362e:	e8 31 2d 00 00       	call   80106364 <switchuvm>
      p->state = RUNNING;
80103633:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
        p->cpu_ticks_in = ticks;
8010363a:	a1 80 59 11 80       	mov    0x80115980,%eax
8010363f:	89 83 8c 00 00 00    	mov    %eax,0x8c(%ebx)
      swtch(&(c->scheduler), p->context);
80103645:	83 c4 08             	add    $0x8,%esp
80103648:	ff 73 1c             	pushl  0x1c(%ebx)
8010364b:	8d 46 04             	lea    0x4(%esi),%eax
8010364e:	50                   	push   %eax
8010364f:	e8 c7 0b 00 00       	call   8010421b <swtch>
      switchkvm();
80103654:	e8 f9 2c 00 00       	call   80106352 <switchkvm>
      c->proc = 0;
80103659:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103660:	00 00 00 
80103663:	83 c4 10             	add    $0x10,%esp
      idle = 0;  // not idle this timeslice
80103666:	bf 00 00 00 00       	mov    $0x0,%edi
8010366b:	eb a3                	jmp    80103610 <scheduler+0x20>
    release(&ptable.lock);
8010366d:	83 ec 0c             	sub    $0xc,%esp
80103670:	68 e0 a5 10 80       	push   $0x8010a5e0
80103675:	e8 79 09 00 00       	call   80103ff3 <release>
    if (idle) {
8010367a:	83 c4 10             	add    $0x10,%esp
8010367d:	85 ff                	test   %edi,%edi
8010367f:	74 02                	je     80103683 <scheduler+0x93>
  asm volatile("sti");
80103681:	fb                   	sti    

// hlt() added by Noah Zentzis, Fall 2016.
static inline void
hlt()
{
  asm volatile("hlt");
80103682:	f4                   	hlt    
80103683:	fb                   	sti    
    acquire(&ptable.lock);
80103684:	83 ec 0c             	sub    $0xc,%esp
80103687:	68 e0 a5 10 80       	push   $0x8010a5e0
8010368c:	e8 f9 08 00 00       	call   80103f8a <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103691:	83 c4 10             	add    $0x10,%esp
    idle = 1;  // assume idle unless we schedule a process
80103694:	bf 01 00 00 00       	mov    $0x1,%edi
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103699:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
8010369e:	e9 73 ff ff ff       	jmp    80103616 <scheduler+0x26>

801036a3 <sched>:
{
801036a3:	f3 0f 1e fb          	endbr32 
801036a7:	55                   	push   %ebp
801036a8:	89 e5                	mov    %esp,%ebp
801036aa:	56                   	push   %esi
801036ab:	53                   	push   %ebx
  struct proc *p = myproc();
801036ac:	e8 87 fc ff ff       	call   80103338 <myproc>
801036b1:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801036b3:	83 ec 0c             	sub    $0xc,%esp
801036b6:	68 e0 a5 10 80       	push   $0x8010a5e0
801036bb:	e8 86 08 00 00       	call   80103f46 <holding>
801036c0:	83 c4 10             	add    $0x10,%esp
801036c3:	85 c0                	test   %eax,%eax
801036c5:	74 60                	je     80103727 <sched+0x84>
  if(mycpu()->ncli != 1)
801036c7:	e8 ed fb ff ff       	call   801032b9 <mycpu>
801036cc:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
801036d3:	75 5f                	jne    80103734 <sched+0x91>
  if(p->state == RUNNING)
801036d5:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
801036d9:	74 66                	je     80103741 <sched+0x9e>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801036db:	9c                   	pushf  
801036dc:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801036dd:	f6 c4 02             	test   $0x2,%ah
801036e0:	75 6c                	jne    8010374e <sched+0xab>
  intena = mycpu()->intena;
801036e2:	e8 d2 fb ff ff       	call   801032b9 <mycpu>
801036e7:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
    p->cpu_ticks_total += (ticks - p->cpu_ticks_in);
801036ed:	a1 80 59 11 80       	mov    0x80115980,%eax
801036f2:	2b 83 8c 00 00 00    	sub    0x8c(%ebx),%eax
801036f8:	01 83 88 00 00 00    	add    %eax,0x88(%ebx)
  swtch(&p->context, mycpu()->scheduler);
801036fe:	e8 b6 fb ff ff       	call   801032b9 <mycpu>
80103703:	83 ec 08             	sub    $0x8,%esp
80103706:	ff 70 04             	pushl  0x4(%eax)
80103709:	83 c3 1c             	add    $0x1c,%ebx
8010370c:	53                   	push   %ebx
8010370d:	e8 09 0b 00 00       	call   8010421b <swtch>
  mycpu()->intena = intena;
80103712:	e8 a2 fb ff ff       	call   801032b9 <mycpu>
80103717:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010371d:	83 c4 10             	add    $0x10,%esp
80103720:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103723:	5b                   	pop    %ebx
80103724:	5e                   	pop    %esi
80103725:	5d                   	pop    %ebp
80103726:	c3                   	ret    
    panic("sched ptable.lock");
80103727:	83 ec 0c             	sub    $0xc,%esp
8010372a:	68 5b 6f 10 80       	push   $0x80106f5b
8010372f:	e8 28 cc ff ff       	call   8010035c <panic>
    panic("sched locks");
80103734:	83 ec 0c             	sub    $0xc,%esp
80103737:	68 6d 6f 10 80       	push   $0x80106f6d
8010373c:	e8 1b cc ff ff       	call   8010035c <panic>
    panic("sched running");
80103741:	83 ec 0c             	sub    $0xc,%esp
80103744:	68 79 6f 10 80       	push   $0x80106f79
80103749:	e8 0e cc ff ff       	call   8010035c <panic>
    panic("sched interruptible");
8010374e:	83 ec 0c             	sub    $0xc,%esp
80103751:	68 87 6f 10 80       	push   $0x80106f87
80103756:	e8 01 cc ff ff       	call   8010035c <panic>

8010375b <exit>:
{
8010375b:	f3 0f 1e fb          	endbr32 
8010375f:	55                   	push   %ebp
80103760:	89 e5                	mov    %esp,%ebp
80103762:	56                   	push   %esi
80103763:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103764:	e8 cf fb ff ff       	call   80103338 <myproc>
  if(curproc == initproc)
80103769:	39 05 c0 a5 10 80    	cmp    %eax,0x8010a5c0
8010376f:	74 09                	je     8010377a <exit+0x1f>
80103771:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103773:	bb 00 00 00 00       	mov    $0x0,%ebx
80103778:	eb 24                	jmp    8010379e <exit+0x43>
    panic("init exiting");
8010377a:	83 ec 0c             	sub    $0xc,%esp
8010377d:	68 9b 6f 10 80       	push   $0x80106f9b
80103782:	e8 d5 cb ff ff       	call   8010035c <panic>
      fileclose(curproc->ofile[fd]);
80103787:	83 ec 0c             	sub    $0xc,%esp
8010378a:	50                   	push   %eax
8010378b:	e8 a4 d5 ff ff       	call   80100d34 <fileclose>
      curproc->ofile[fd] = 0;
80103790:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103797:	00 
80103798:	83 c4 10             	add    $0x10,%esp
  for(fd = 0; fd < NOFILE; fd++){
8010379b:	83 c3 01             	add    $0x1,%ebx
8010379e:	83 fb 0f             	cmp    $0xf,%ebx
801037a1:	7f 0a                	jg     801037ad <exit+0x52>
    if(curproc->ofile[fd]){
801037a3:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801037a7:	85 c0                	test   %eax,%eax
801037a9:	75 dc                	jne    80103787 <exit+0x2c>
801037ab:	eb ee                	jmp    8010379b <exit+0x40>
  begin_op();
801037ad:	e8 da f0 ff ff       	call   8010288c <begin_op>
  iput(curproc->cwd);
801037b2:	83 ec 0c             	sub    $0xc,%esp
801037b5:	ff 76 68             	pushl  0x68(%esi)
801037b8:	e8 59 df ff ff       	call   80101716 <iput>
  end_op();
801037bd:	e8 48 f1 ff ff       	call   8010290a <end_op>
  curproc->cwd = 0;
801037c2:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801037c9:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
801037d0:	e8 b5 07 00 00       	call   80103f8a <acquire>
  wakeup1(curproc->parent);
801037d5:	8b 46 14             	mov    0x14(%esi),%eax
801037d8:	e8 5c f9 ff ff       	call   80103139 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037dd:	83 c4 10             	add    $0x10,%esp
801037e0:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
801037e5:	eb 06                	jmp    801037ed <exit+0x92>
801037e7:	81 c3 90 00 00 00    	add    $0x90,%ebx
801037ed:	81 fb 14 ca 10 80    	cmp    $0x8010ca14,%ebx
801037f3:	73 1a                	jae    8010380f <exit+0xb4>
    if(p->parent == curproc){
801037f5:	39 73 14             	cmp    %esi,0x14(%ebx)
801037f8:	75 ed                	jne    801037e7 <exit+0x8c>
      p->parent = initproc;
801037fa:	a1 c0 a5 10 80       	mov    0x8010a5c0,%eax
801037ff:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103802:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103806:	75 df                	jne    801037e7 <exit+0x8c>
        wakeup1(initproc);
80103808:	e8 2c f9 ff ff       	call   80103139 <wakeup1>
8010380d:	eb d8                	jmp    801037e7 <exit+0x8c>
  curproc->state = ZOMBIE;
8010380f:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  curproc->sz = 0;
80103816:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
  sched();
8010381c:	e8 82 fe ff ff       	call   801036a3 <sched>
  panic("zombie exit");
80103821:	83 ec 0c             	sub    $0xc,%esp
80103824:	68 a8 6f 10 80       	push   $0x80106fa8
80103829:	e8 2e cb ff ff       	call   8010035c <panic>

8010382e <yield>:
{
8010382e:	f3 0f 1e fb          	endbr32 
80103832:	55                   	push   %ebp
80103833:	89 e5                	mov    %esp,%ebp
80103835:	53                   	push   %ebx
80103836:	83 ec 04             	sub    $0x4,%esp
  struct proc *curproc = myproc();
80103839:	e8 fa fa ff ff       	call   80103338 <myproc>
8010383e:	89 c3                	mov    %eax,%ebx
  acquire(&ptable.lock);  //DOC: yieldlock
80103840:	83 ec 0c             	sub    $0xc,%esp
80103843:	68 e0 a5 10 80       	push   $0x8010a5e0
80103848:	e8 3d 07 00 00       	call   80103f8a <acquire>
  curproc->state = RUNNABLE;
8010384d:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  sched();
80103854:	e8 4a fe ff ff       	call   801036a3 <sched>
  release(&ptable.lock);
80103859:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103860:	e8 8e 07 00 00       	call   80103ff3 <release>
}
80103865:	83 c4 10             	add    $0x10,%esp
80103868:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010386b:	c9                   	leave  
8010386c:	c3                   	ret    

8010386d <sleep>:
{
8010386d:	f3 0f 1e fb          	endbr32 
80103871:	55                   	push   %ebp
80103872:	89 e5                	mov    %esp,%ebp
80103874:	56                   	push   %esi
80103875:	53                   	push   %ebx
80103876:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct proc *p = myproc();
80103879:	e8 ba fa ff ff       	call   80103338 <myproc>
  if(p == 0)
8010387e:	85 c0                	test   %eax,%eax
80103880:	74 72                	je     801038f4 <sleep+0x87>
80103882:	89 c3                	mov    %eax,%ebx
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103884:	81 fe e0 a5 10 80    	cmp    $0x8010a5e0,%esi
8010388a:	74 20                	je     801038ac <sleep+0x3f>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010388c:	83 ec 0c             	sub    $0xc,%esp
8010388f:	68 e0 a5 10 80       	push   $0x8010a5e0
80103894:	e8 f1 06 00 00       	call   80103f8a <acquire>
    if (lk) release(lk);
80103899:	83 c4 10             	add    $0x10,%esp
8010389c:	85 f6                	test   %esi,%esi
8010389e:	74 0c                	je     801038ac <sleep+0x3f>
801038a0:	83 ec 0c             	sub    $0xc,%esp
801038a3:	56                   	push   %esi
801038a4:	e8 4a 07 00 00       	call   80103ff3 <release>
801038a9:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801038ac:	8b 45 08             	mov    0x8(%ebp),%eax
801038af:	89 43 20             	mov    %eax,0x20(%ebx)
  p->state = SLEEPING;
801038b2:	c7 43 0c 02 00 00 00 	movl   $0x2,0xc(%ebx)
  sched();
801038b9:	e8 e5 fd ff ff       	call   801036a3 <sched>
  p->chan = 0;
801038be:	c7 43 20 00 00 00 00 	movl   $0x0,0x20(%ebx)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801038c5:	81 fe e0 a5 10 80    	cmp    $0x8010a5e0,%esi
801038cb:	74 20                	je     801038ed <sleep+0x80>
    release(&ptable.lock);
801038cd:	83 ec 0c             	sub    $0xc,%esp
801038d0:	68 e0 a5 10 80       	push   $0x8010a5e0
801038d5:	e8 19 07 00 00       	call   80103ff3 <release>
    if (lk) acquire(lk);
801038da:	83 c4 10             	add    $0x10,%esp
801038dd:	85 f6                	test   %esi,%esi
801038df:	74 0c                	je     801038ed <sleep+0x80>
801038e1:	83 ec 0c             	sub    $0xc,%esp
801038e4:	56                   	push   %esi
801038e5:	e8 a0 06 00 00       	call   80103f8a <acquire>
801038ea:	83 c4 10             	add    $0x10,%esp
}
801038ed:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038f0:	5b                   	pop    %ebx
801038f1:	5e                   	pop    %esi
801038f2:	5d                   	pop    %ebp
801038f3:	c3                   	ret    
    panic("sleep");
801038f4:	83 ec 0c             	sub    $0xc,%esp
801038f7:	68 b4 6f 10 80       	push   $0x80106fb4
801038fc:	e8 5b ca ff ff       	call   8010035c <panic>

80103901 <wait>:
{
80103901:	f3 0f 1e fb          	endbr32 
80103905:	55                   	push   %ebp
80103906:	89 e5                	mov    %esp,%ebp
80103908:	56                   	push   %esi
80103909:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010390a:	e8 29 fa ff ff       	call   80103338 <myproc>
8010390f:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103911:	83 ec 0c             	sub    $0xc,%esp
80103914:	68 e0 a5 10 80       	push   $0x8010a5e0
80103919:	e8 6c 06 00 00       	call   80103f8a <acquire>
8010391e:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103921:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103926:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
8010392b:	eb 5e                	jmp    8010398b <wait+0x8a>
        pid = p->pid;
8010392d:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103930:	83 ec 0c             	sub    $0xc,%esp
80103933:	ff 73 08             	pushl  0x8(%ebx)
80103936:	e8 2d e7 ff ff       	call   80102068 <kfree>
        p->kstack = 0;
8010393b:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103942:	83 c4 04             	add    $0x4,%esp
80103945:	ff 73 04             	pushl  0x4(%ebx)
80103948:	e8 c2 2d 00 00       	call   8010670f <freevm>
        p->pid = 0;
8010394d:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103954:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
8010395b:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
8010395f:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103966:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
8010396d:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103974:	e8 7a 06 00 00       	call   80103ff3 <release>
        return pid;
80103979:	89 f0                	mov    %esi,%eax
8010397b:	83 c4 10             	add    $0x10,%esp
}
8010397e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103981:	5b                   	pop    %ebx
80103982:	5e                   	pop    %esi
80103983:	5d                   	pop    %ebp
80103984:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103985:	81 c3 90 00 00 00    	add    $0x90,%ebx
8010398b:	81 fb 14 ca 10 80    	cmp    $0x8010ca14,%ebx
80103991:	73 12                	jae    801039a5 <wait+0xa4>
      if(p->parent != curproc)
80103993:	39 73 14             	cmp    %esi,0x14(%ebx)
80103996:	75 ed                	jne    80103985 <wait+0x84>
      if(p->state == ZOMBIE){
80103998:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010399c:	74 8f                	je     8010392d <wait+0x2c>
      havekids = 1;
8010399e:	b8 01 00 00 00       	mov    $0x1,%eax
801039a3:	eb e0                	jmp    80103985 <wait+0x84>
    if(!havekids || curproc->killed){
801039a5:	85 c0                	test   %eax,%eax
801039a7:	74 06                	je     801039af <wait+0xae>
801039a9:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801039ad:	74 17                	je     801039c6 <wait+0xc5>
      release(&ptable.lock);
801039af:	83 ec 0c             	sub    $0xc,%esp
801039b2:	68 e0 a5 10 80       	push   $0x8010a5e0
801039b7:	e8 37 06 00 00       	call   80103ff3 <release>
      return -1;
801039bc:	83 c4 10             	add    $0x10,%esp
801039bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039c4:	eb b8                	jmp    8010397e <wait+0x7d>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
801039c6:	83 ec 08             	sub    $0x8,%esp
801039c9:	68 e0 a5 10 80       	push   $0x8010a5e0
801039ce:	56                   	push   %esi
801039cf:	e8 99 fe ff ff       	call   8010386d <sleep>
    havekids = 0;
801039d4:	83 c4 10             	add    $0x10,%esp
801039d7:	e9 45 ff ff ff       	jmp    80103921 <wait+0x20>

801039dc <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801039dc:	f3 0f 1e fb          	endbr32 
801039e0:	55                   	push   %ebp
801039e1:	89 e5                	mov    %esp,%ebp
801039e3:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
801039e6:	68 e0 a5 10 80       	push   $0x8010a5e0
801039eb:	e8 9a 05 00 00       	call   80103f8a <acquire>
  wakeup1(chan);
801039f0:	8b 45 08             	mov    0x8(%ebp),%eax
801039f3:	e8 41 f7 ff ff       	call   80103139 <wakeup1>
  release(&ptable.lock);
801039f8:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
801039ff:	e8 ef 05 00 00       	call   80103ff3 <release>
}
80103a04:	83 c4 10             	add    $0x10,%esp
80103a07:	c9                   	leave  
80103a08:	c3                   	ret    

80103a09 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103a09:	f3 0f 1e fb          	endbr32 
80103a0d:	55                   	push   %ebp
80103a0e:	89 e5                	mov    %esp,%ebp
80103a10:	53                   	push   %ebx
80103a11:	83 ec 10             	sub    $0x10,%esp
80103a14:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103a17:	68 e0 a5 10 80       	push   $0x8010a5e0
80103a1c:	e8 69 05 00 00       	call   80103f8a <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a21:	83 c4 10             	add    $0x10,%esp
80103a24:	b8 14 a6 10 80       	mov    $0x8010a614,%eax
80103a29:	3d 14 ca 10 80       	cmp    $0x8010ca14,%eax
80103a2e:	73 3c                	jae    80103a6c <kill+0x63>
    if(p->pid == pid){
80103a30:	39 58 10             	cmp    %ebx,0x10(%eax)
80103a33:	74 07                	je     80103a3c <kill+0x33>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a35:	05 90 00 00 00       	add    $0x90,%eax
80103a3a:	eb ed                	jmp    80103a29 <kill+0x20>
      p->killed = 1;
80103a3c:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103a43:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103a47:	74 1a                	je     80103a63 <kill+0x5a>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103a49:	83 ec 0c             	sub    $0xc,%esp
80103a4c:	68 e0 a5 10 80       	push   $0x8010a5e0
80103a51:	e8 9d 05 00 00       	call   80103ff3 <release>
      return 0;
80103a56:	83 c4 10             	add    $0x10,%esp
80103a59:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103a5e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a61:	c9                   	leave  
80103a62:	c3                   	ret    
        p->state = RUNNABLE;
80103a63:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103a6a:	eb dd                	jmp    80103a49 <kill+0x40>
  release(&ptable.lock);
80103a6c:	83 ec 0c             	sub    $0xc,%esp
80103a6f:	68 e0 a5 10 80       	push   $0x8010a5e0
80103a74:	e8 7a 05 00 00       	call   80103ff3 <release>
  return -1;
80103a79:	83 c4 10             	add    $0x10,%esp
80103a7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a81:	eb db                	jmp    80103a5e <kill+0x55>

80103a83 <procdumpP2P3P4>:
// No lock to avoid wedging a stuck machine further.

#if defined(CS333_P2)
void
procdumpP2P3P4(struct proc *p, char *state_string)
{
80103a83:	f3 0f 1e fb          	endbr32 
80103a87:	55                   	push   %ebp
80103a88:	89 e5                	mov    %esp,%ebp
80103a8a:	57                   	push   %edi
80103a8b:	56                   	push   %esi
80103a8c:	53                   	push   %ebx
80103a8d:	83 ec 1c             	sub    $0x1c,%esp
80103a90:	8b 4d 08             	mov    0x8(%ebp),%ecx
  uint elapsed = ticks-p->start_ticks;
80103a93:	8b 3d 80 59 11 80    	mov    0x80115980,%edi
80103a99:	2b 79 7c             	sub    0x7c(%ecx),%edi
  uint elapsedLeft = (elapsed) / 1000;
80103a9c:	bb d3 4d 62 10       	mov    $0x10624dd3,%ebx
80103aa1:	89 f8                	mov    %edi,%eax
80103aa3:	f7 e3                	mul    %ebx
80103aa5:	89 d6                	mov    %edx,%esi
80103aa7:	c1 ee 06             	shr    $0x6,%esi
  uint elapsedRight = elapsed % 1000;
80103aaa:	69 c6 e8 03 00 00    	imul   $0x3e8,%esi,%eax
80103ab0:	29 c7                	sub    %eax,%edi
80103ab2:	89 7d e4             	mov    %edi,-0x1c(%ebp)
  char *zeros = "";
  char *cpuZeros = "";
  uint cpuTicksTotal = p->cpu_ticks_total;
80103ab5:	8b b9 88 00 00 00    	mov    0x88(%ecx),%edi
  uint cpuSecond = cpuTicksTotal / 1000;
80103abb:	89 f8                	mov    %edi,%eax
80103abd:	f7 e3                	mul    %ebx
80103abf:	c1 ea 06             	shr    $0x6,%edx
  uint cpuMs = cpuTicksTotal % 1000;
80103ac2:	69 c2 e8 03 00 00    	imul   $0x3e8,%edx,%eax
80103ac8:	29 c7                	sub    %eax,%edi
80103aca:	89 f8                	mov    %edi,%eax
  uint ppid = p->parent ? p->parent->pid : p->pid;
80103acc:	8b 59 14             	mov    0x14(%ecx),%ebx
80103acf:	85 db                	test   %ebx,%ebx
80103ad1:	74 19                	je     80103aec <procdumpP2P3P4+0x69>
80103ad3:	8b 7b 10             	mov    0x10(%ebx),%edi

  if (elapsedRight < 10) {
80103ad6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103ad9:	83 fb 09             	cmp    $0x9,%ebx
80103adc:	76 13                	jbe    80103af1 <procdumpP2P3P4+0x6e>
    zeros = "00";
  } else if (elapsedRight < 100) {
80103ade:	83 fb 63             	cmp    $0x63,%ebx
80103ae1:	76 28                	jbe    80103b0b <procdumpP2P3P4+0x88>
  char *zeros = "";
80103ae3:	c7 45 e0 b4 73 10 80 	movl   $0x801073b4,-0x20(%ebp)
80103aea:	eb 0c                	jmp    80103af8 <procdumpP2P3P4+0x75>
  uint ppid = p->parent ? p->parent->pid : p->pid;
80103aec:	8b 79 10             	mov    0x10(%ecx),%edi
80103aef:	eb e5                	jmp    80103ad6 <procdumpP2P3P4+0x53>
    zeros = "00";
80103af1:	c7 45 e0 ba 6f 10 80 	movl   $0x80106fba,-0x20(%ebp)
    zeros = "0";
  }

  if (cpuMs < 10) {
80103af8:	83 f8 09             	cmp    $0x9,%eax
80103afb:	76 17                	jbe    80103b14 <procdumpP2P3P4+0x91>
    cpuZeros = "00";
  } else if (cpuMs < 100) {
80103afd:	83 f8 63             	cmp    $0x63,%eax
80103b00:	76 56                	jbe    80103b58 <procdumpP2P3P4+0xd5>
  char *cpuZeros = "";
80103b02:	c7 45 dc b4 73 10 80 	movl   $0x801073b4,-0x24(%ebp)
80103b09:	eb 10                	jmp    80103b1b <procdumpP2P3P4+0x98>
    zeros = "0";
80103b0b:	c7 45 e0 bb 6f 10 80 	movl   $0x80106fbb,-0x20(%ebp)
80103b12:	eb e4                	jmp    80103af8 <procdumpP2P3P4+0x75>
    cpuZeros = "00";
80103b14:	c7 45 dc ba 6f 10 80 	movl   $0x80106fba,-0x24(%ebp)
  }

  cprintf(
    "\n%d\t%s\t%d\t%d\t%d\t%d.%s%d\t%d.%s%d\t%s\t%d\t", 
    p->pid, 
    p->name, 
80103b1b:	8d 59 6c             	lea    0x6c(%ecx),%ebx
  cprintf(
80103b1e:	83 ec 08             	sub    $0x8,%esp
80103b21:	ff 31                	pushl  (%ecx)
80103b23:	ff 75 0c             	pushl  0xc(%ebp)
80103b26:	50                   	push   %eax
80103b27:	ff 75 dc             	pushl  -0x24(%ebp)
80103b2a:	52                   	push   %edx
80103b2b:	ff 75 e4             	pushl  -0x1c(%ebp)
80103b2e:	ff 75 e0             	pushl  -0x20(%ebp)
80103b31:	56                   	push   %esi
80103b32:	57                   	push   %edi
80103b33:	ff b1 84 00 00 00    	pushl  0x84(%ecx)
80103b39:	ff b1 80 00 00 00    	pushl  0x80(%ecx)
80103b3f:	53                   	push   %ebx
80103b40:	ff 71 10             	pushl  0x10(%ecx)
80103b43:	68 18 70 10 80       	push   $0x80107018
80103b48:	e8 dc ca ff ff       	call   80100629 <cprintf>
    cpuZeros,
    cpuMs,
    state_string, 
    p->sz
  );
}
80103b4d:	83 c4 40             	add    $0x40,%esp
80103b50:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103b53:	5b                   	pop    %ebx
80103b54:	5e                   	pop    %esi
80103b55:	5f                   	pop    %edi
80103b56:	5d                   	pop    %ebp
80103b57:	c3                   	ret    
    cpuZeros = "0";
80103b58:	c7 45 dc bb 6f 10 80 	movl   $0x80106fbb,-0x24(%ebp)
80103b5f:	eb ba                	jmp    80103b1b <procdumpP2P3P4+0x98>

80103b61 <procdump>:
}
#endif

void
procdump(void)
{
80103b61:	f3 0f 1e fb          	endbr32 
80103b65:	55                   	push   %ebp
80103b66:	89 e5                	mov    %esp,%ebp
80103b68:	56                   	push   %esi
80103b69:	53                   	push   %ebx
80103b6a:	83 ec 3c             	sub    $0x3c,%esp
#define HEADER "\nPID\tName\tElapsed\tState\tSize\t PCs\n"
#else
#define HEADER "\n"
#endif

  cprintf(HEADER);  // not conditionally compiled as must work in all project states
80103b6d:	68 40 70 10 80       	push   $0x80107040
80103b72:	e8 b2 ca ff ff       	call   80100629 <cprintf>

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b77:	83 c4 10             	add    $0x10,%esp
80103b7a:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80103b7f:	eb 2e                	jmp    80103baf <procdump+0x4e>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103b81:	b8 bd 6f 10 80       	mov    $0x80106fbd,%eax

    // see TODOs above this function
    // P2 and P3 are identical and the P4 change is minor
#if defined(CS333_P2)
    procdumpP2P3P4(p, state);
80103b86:	83 ec 08             	sub    $0x8,%esp
80103b89:	50                   	push   %eax
80103b8a:	53                   	push   %ebx
80103b8b:	e8 f3 fe ff ff       	call   80103a83 <procdumpP2P3P4>
    procdumpP1(p, state);
#else
    cprintf("%d\t%s\t%s\t", p->pid, p->name, state);
#endif

    if(p->state == SLEEPING){
80103b90:	83 c4 10             	add    $0x10,%esp
80103b93:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103b97:	74 3c                	je     80103bd5 <procdump+0x74>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103b99:	83 ec 0c             	sub    $0xc,%esp
80103b9c:	68 b3 73 10 80       	push   $0x801073b3
80103ba1:	e8 83 ca ff ff       	call   80100629 <cprintf>
80103ba6:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ba9:	81 c3 90 00 00 00    	add    $0x90,%ebx
80103baf:	81 fb 14 ca 10 80    	cmp    $0x8010ca14,%ebx
80103bb5:	73 61                	jae    80103c18 <procdump+0xb7>
    if(p->state == UNUSED)
80103bb7:	8b 43 0c             	mov    0xc(%ebx),%eax
80103bba:	85 c0                	test   %eax,%eax
80103bbc:	74 eb                	je     80103ba9 <procdump+0x48>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103bbe:	83 f8 05             	cmp    $0x5,%eax
80103bc1:	77 be                	ja     80103b81 <procdump+0x20>
80103bc3:	8b 04 85 74 70 10 80 	mov    -0x7fef8f8c(,%eax,4),%eax
80103bca:	85 c0                	test   %eax,%eax
80103bcc:	75 b8                	jne    80103b86 <procdump+0x25>
      state = "???";
80103bce:	b8 bd 6f 10 80       	mov    $0x80106fbd,%eax
80103bd3:	eb b1                	jmp    80103b86 <procdump+0x25>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103bd5:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103bd8:	8b 40 0c             	mov    0xc(%eax),%eax
80103bdb:	83 c0 08             	add    $0x8,%eax
80103bde:	83 ec 08             	sub    $0x8,%esp
80103be1:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103be4:	52                   	push   %edx
80103be5:	50                   	push   %eax
80103be6:	e8 6e 02 00 00       	call   80103e59 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103beb:	83 c4 10             	add    $0x10,%esp
80103bee:	be 00 00 00 00       	mov    $0x0,%esi
80103bf3:	eb 14                	jmp    80103c09 <procdump+0xa8>
        cprintf(" %p", pc[i]);
80103bf5:	83 ec 08             	sub    $0x8,%esp
80103bf8:	50                   	push   %eax
80103bf9:	68 21 6a 10 80       	push   $0x80106a21
80103bfe:	e8 26 ca ff ff       	call   80100629 <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c03:	83 c6 01             	add    $0x1,%esi
80103c06:	83 c4 10             	add    $0x10,%esp
80103c09:	83 fe 09             	cmp    $0x9,%esi
80103c0c:	7f 8b                	jg     80103b99 <procdump+0x38>
80103c0e:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103c12:	85 c0                	test   %eax,%eax
80103c14:	75 df                	jne    80103bf5 <procdump+0x94>
80103c16:	eb 81                	jmp    80103b99 <procdump+0x38>
  }
#ifdef CS333_P1
  cprintf("$ ");  // simulate shell prompt
80103c18:	83 ec 0c             	sub    $0xc,%esp
80103c1b:	68 c1 6f 10 80       	push   $0x80106fc1
80103c20:	e8 04 ca ff ff       	call   80100629 <cprintf>
#endif // CS333_P1
}
80103c25:	83 c4 10             	add    $0x10,%esp
80103c28:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c2b:	5b                   	pop    %ebx
80103c2c:	5e                   	pop    %esi
80103c2d:	5d                   	pop    %ebp
80103c2e:	c3                   	ret    

80103c2f <getprocs>:
}
#endif // DEBUG

#ifdef CS333_P2
int
getprocs(uint max, struct uproc* upTable){
80103c2f:	f3 0f 1e fb          	endbr32 
80103c33:	55                   	push   %ebp
80103c34:	89 e5                	mov    %esp,%ebp
80103c36:	57                   	push   %edi
80103c37:	56                   	push   %esi
80103c38:	53                   	push   %ebx
80103c39:	83 ec 18             	sub    $0x18,%esp
  struct proc* p;
  int procsNumber = 0;
  acquire(&ptable.lock);
80103c3c:	68 e0 a5 10 80       	push   $0x8010a5e0
80103c41:	e8 44 03 00 00       	call   80103f8a <acquire>

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103c46:	83 c4 10             	add    $0x10,%esp
  int procsNumber = 0;
80103c49:	bf 00 00 00 00       	mov    $0x0,%edi
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103c4e:	be 14 a6 10 80       	mov    $0x8010a614,%esi
80103c53:	e9 82 00 00 00       	jmp    80103cda <getprocs+0xab>
    if (procsNumber < max) {
      if(p->state != UNUSED && p->state != EMBRYO) {
        if(p->state >= 0 && p->state < NELEM(states) && states[p->state]){
          safestrcpy(upTable[procsNumber].state, states[p->state],STRMAX);
        } else {
          safestrcpy(upTable[procsNumber].state,"???",STRMAX);
80103c58:	6b c3 5c             	imul   $0x5c,%ebx,%eax
80103c5b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103c5e:	8d 44 01 18          	lea    0x18(%ecx,%eax,1),%eax
80103c62:	83 ec 04             	sub    $0x4,%esp
80103c65:	6a 20                	push   $0x20
80103c67:	68 bd 6f 10 80       	push   $0x80106fbd
80103c6c:	50                   	push   %eax
80103c6d:	e8 4c 05 00 00       	call   801041be <safestrcpy>
80103c72:	83 c4 10             	add    $0x10,%esp
        }

        upTable[procsNumber].pid = p->pid;
80103c75:	6b db 5c             	imul   $0x5c,%ebx,%ebx
80103c78:	03 5d 0c             	add    0xc(%ebp),%ebx
80103c7b:	8b 46 10             	mov    0x10(%esi),%eax
80103c7e:	89 03                	mov    %eax,(%ebx)
        upTable[procsNumber].uid = p->uid;
80103c80:	8b 86 80 00 00 00    	mov    0x80(%esi),%eax
80103c86:	89 43 04             	mov    %eax,0x4(%ebx)
        upTable[procsNumber].gid = p->gid;
80103c89:	8b 86 84 00 00 00    	mov    0x84(%esi),%eax
80103c8f:	89 43 08             	mov    %eax,0x8(%ebx)
        upTable[procsNumber].ppid = p->parent ? p->parent->pid : p->pid;
80103c92:	8b 46 14             	mov    0x14(%esi),%eax
80103c95:	85 c0                	test   %eax,%eax
80103c97:	0f 84 8a 00 00 00    	je     80103d27 <getprocs+0xf8>
80103c9d:	8b 40 10             	mov    0x10(%eax),%eax
80103ca0:	89 43 0c             	mov    %eax,0xc(%ebx)
        upTable[procsNumber].elapsed_ticks = ticks - p->start_ticks;
80103ca3:	a1 80 59 11 80       	mov    0x80115980,%eax
80103ca8:	2b 46 7c             	sub    0x7c(%esi),%eax
80103cab:	89 43 10             	mov    %eax,0x10(%ebx)
        upTable[procsNumber].CPU_total_ticks = p->cpu_ticks_total;
80103cae:	8b 86 88 00 00 00    	mov    0x88(%esi),%eax
80103cb4:	89 43 14             	mov    %eax,0x14(%ebx)
        upTable[procsNumber].size = p->sz;
80103cb7:	8b 06                	mov    (%esi),%eax
80103cb9:	89 43 38             	mov    %eax,0x38(%ebx)
        safestrcpy(upTable[procsNumber].name, p->name, STRMAX);
80103cbc:	8d 46 6c             	lea    0x6c(%esi),%eax
80103cbf:	83 c3 3c             	add    $0x3c,%ebx
80103cc2:	83 ec 04             	sub    $0x4,%esp
80103cc5:	6a 20                	push   $0x20
80103cc7:	50                   	push   %eax
80103cc8:	53                   	push   %ebx
80103cc9:	e8 f0 04 00 00       	call   801041be <safestrcpy>
        procsNumber++;
80103cce:	83 c7 01             	add    $0x1,%edi
80103cd1:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103cd4:	81 c6 90 00 00 00    	add    $0x90,%esi
80103cda:	81 fe 14 ca 10 80    	cmp    $0x8010ca14,%esi
80103ce0:	73 4d                	jae    80103d2f <getprocs+0x100>
    if (procsNumber < max) {
80103ce2:	89 fb                	mov    %edi,%ebx
80103ce4:	3b 7d 08             	cmp    0x8(%ebp),%edi
80103ce7:	73 46                	jae    80103d2f <getprocs+0x100>
      if(p->state != UNUSED && p->state != EMBRYO) {
80103ce9:	8b 46 0c             	mov    0xc(%esi),%eax
80103cec:	83 f8 01             	cmp    $0x1,%eax
80103cef:	76 e3                	jbe    80103cd4 <getprocs+0xa5>
        if(p->state >= 0 && p->state < NELEM(states) && states[p->state]){
80103cf1:	83 f8 05             	cmp    $0x5,%eax
80103cf4:	0f 87 5e ff ff ff    	ja     80103c58 <getprocs+0x29>
80103cfa:	8b 04 85 74 70 10 80 	mov    -0x7fef8f8c(,%eax,4),%eax
80103d01:	85 c0                	test   %eax,%eax
80103d03:	0f 84 4f ff ff ff    	je     80103c58 <getprocs+0x29>
          safestrcpy(upTable[procsNumber].state, states[p->state],STRMAX);
80103d09:	6b d7 5c             	imul   $0x5c,%edi,%edx
80103d0c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103d0f:	8d 54 11 18          	lea    0x18(%ecx,%edx,1),%edx
80103d13:	83 ec 04             	sub    $0x4,%esp
80103d16:	6a 20                	push   $0x20
80103d18:	50                   	push   %eax
80103d19:	52                   	push   %edx
80103d1a:	e8 9f 04 00 00       	call   801041be <safestrcpy>
80103d1f:	83 c4 10             	add    $0x10,%esp
80103d22:	e9 4e ff ff ff       	jmp    80103c75 <getprocs+0x46>
        upTable[procsNumber].ppid = p->parent ? p->parent->pid : p->pid;
80103d27:	8b 46 10             	mov    0x10(%esi),%eax
80103d2a:	e9 71 ff ff ff       	jmp    80103ca0 <getprocs+0x71>
      }
    } else {
      break;
    }
  }
  release(&ptable.lock);
80103d2f:	83 ec 0c             	sub    $0xc,%esp
80103d32:	68 e0 a5 10 80       	push   $0x8010a5e0
80103d37:	e8 b7 02 00 00       	call   80103ff3 <release>
  return procsNumber;
}
80103d3c:	89 f8                	mov    %edi,%eax
80103d3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103d41:	5b                   	pop    %ebx
80103d42:	5e                   	pop    %esi
80103d43:	5f                   	pop    %edi
80103d44:	5d                   	pop    %ebp
80103d45:	c3                   	ret    

80103d46 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103d46:	f3 0f 1e fb          	endbr32 
80103d4a:	55                   	push   %ebp
80103d4b:	89 e5                	mov    %esp,%ebp
80103d4d:	53                   	push   %ebx
80103d4e:	83 ec 0c             	sub    $0xc,%esp
80103d51:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103d54:	68 8c 70 10 80       	push   $0x8010708c
80103d59:	8d 43 04             	lea    0x4(%ebx),%eax
80103d5c:	50                   	push   %eax
80103d5d:	e8 d8 00 00 00       	call   80103e3a <initlock>
  lk->name = name;
80103d62:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d65:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103d68:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103d6e:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103d75:	83 c4 10             	add    $0x10,%esp
80103d78:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d7b:	c9                   	leave  
80103d7c:	c3                   	ret    

80103d7d <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103d7d:	f3 0f 1e fb          	endbr32 
80103d81:	55                   	push   %ebp
80103d82:	89 e5                	mov    %esp,%ebp
80103d84:	56                   	push   %esi
80103d85:	53                   	push   %ebx
80103d86:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103d89:	8d 73 04             	lea    0x4(%ebx),%esi
80103d8c:	83 ec 0c             	sub    $0xc,%esp
80103d8f:	56                   	push   %esi
80103d90:	e8 f5 01 00 00       	call   80103f8a <acquire>
  while (lk->locked) {
80103d95:	83 c4 10             	add    $0x10,%esp
80103d98:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d9b:	74 0f                	je     80103dac <acquiresleep+0x2f>
    sleep(lk, &lk->lk);
80103d9d:	83 ec 08             	sub    $0x8,%esp
80103da0:	56                   	push   %esi
80103da1:	53                   	push   %ebx
80103da2:	e8 c6 fa ff ff       	call   8010386d <sleep>
80103da7:	83 c4 10             	add    $0x10,%esp
80103daa:	eb ec                	jmp    80103d98 <acquiresleep+0x1b>
  }
  lk->locked = 1;
80103dac:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103db2:	e8 81 f5 ff ff       	call   80103338 <myproc>
80103db7:	8b 40 10             	mov    0x10(%eax),%eax
80103dba:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103dbd:	83 ec 0c             	sub    $0xc,%esp
80103dc0:	56                   	push   %esi
80103dc1:	e8 2d 02 00 00       	call   80103ff3 <release>
}
80103dc6:	83 c4 10             	add    $0x10,%esp
80103dc9:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103dcc:	5b                   	pop    %ebx
80103dcd:	5e                   	pop    %esi
80103dce:	5d                   	pop    %ebp
80103dcf:	c3                   	ret    

80103dd0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103dd0:	f3 0f 1e fb          	endbr32 
80103dd4:	55                   	push   %ebp
80103dd5:	89 e5                	mov    %esp,%ebp
80103dd7:	56                   	push   %esi
80103dd8:	53                   	push   %ebx
80103dd9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ddc:	8d 73 04             	lea    0x4(%ebx),%esi
80103ddf:	83 ec 0c             	sub    $0xc,%esp
80103de2:	56                   	push   %esi
80103de3:	e8 a2 01 00 00       	call   80103f8a <acquire>
  lk->locked = 0;
80103de8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103dee:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103df5:	89 1c 24             	mov    %ebx,(%esp)
80103df8:	e8 df fb ff ff       	call   801039dc <wakeup>
  release(&lk->lk);
80103dfd:	89 34 24             	mov    %esi,(%esp)
80103e00:	e8 ee 01 00 00       	call   80103ff3 <release>
}
80103e05:	83 c4 10             	add    $0x10,%esp
80103e08:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103e0b:	5b                   	pop    %ebx
80103e0c:	5e                   	pop    %esi
80103e0d:	5d                   	pop    %ebp
80103e0e:	c3                   	ret    

80103e0f <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103e0f:	f3 0f 1e fb          	endbr32 
80103e13:	55                   	push   %ebp
80103e14:	89 e5                	mov    %esp,%ebp
80103e16:	56                   	push   %esi
80103e17:	53                   	push   %ebx
80103e18:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;
  
  acquire(&lk->lk);
80103e1b:	8d 5e 04             	lea    0x4(%esi),%ebx
80103e1e:	83 ec 0c             	sub    $0xc,%esp
80103e21:	53                   	push   %ebx
80103e22:	e8 63 01 00 00       	call   80103f8a <acquire>
  r = lk->locked;
80103e27:	8b 36                	mov    (%esi),%esi
  release(&lk->lk);
80103e29:	89 1c 24             	mov    %ebx,(%esp)
80103e2c:	e8 c2 01 00 00       	call   80103ff3 <release>
  return r;
}
80103e31:	89 f0                	mov    %esi,%eax
80103e33:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103e36:	5b                   	pop    %ebx
80103e37:	5e                   	pop    %esi
80103e38:	5d                   	pop    %ebp
80103e39:	c3                   	ret    

80103e3a <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103e3a:	f3 0f 1e fb          	endbr32 
80103e3e:	55                   	push   %ebp
80103e3f:	89 e5                	mov    %esp,%ebp
80103e41:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103e44:	8b 55 0c             	mov    0xc(%ebp),%edx
80103e47:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103e4a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103e50:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103e57:	5d                   	pop    %ebp
80103e58:	c3                   	ret    

80103e59 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103e59:	f3 0f 1e fb          	endbr32 
80103e5d:	55                   	push   %ebp
80103e5e:	89 e5                	mov    %esp,%ebp
80103e60:	53                   	push   %ebx
80103e61:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103e64:	8b 45 08             	mov    0x8(%ebp),%eax
80103e67:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103e6a:	b8 00 00 00 00       	mov    $0x0,%eax
80103e6f:	83 f8 09             	cmp    $0x9,%eax
80103e72:	7f 25                	jg     80103e99 <getcallerpcs+0x40>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103e74:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103e7a:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103e80:	77 17                	ja     80103e99 <getcallerpcs+0x40>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103e82:	8b 5a 04             	mov    0x4(%edx),%ebx
80103e85:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103e88:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103e8a:	83 c0 01             	add    $0x1,%eax
80103e8d:	eb e0                	jmp    80103e6f <getcallerpcs+0x16>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103e8f:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103e96:	83 c0 01             	add    $0x1,%eax
80103e99:	83 f8 09             	cmp    $0x9,%eax
80103e9c:	7e f1                	jle    80103e8f <getcallerpcs+0x36>
}
80103e9e:	5b                   	pop    %ebx
80103e9f:	5d                   	pop    %ebp
80103ea0:	c3                   	ret    

80103ea1 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103ea1:	f3 0f 1e fb          	endbr32 
80103ea5:	55                   	push   %ebp
80103ea6:	89 e5                	mov    %esp,%ebp
80103ea8:	53                   	push   %ebx
80103ea9:	83 ec 04             	sub    $0x4,%esp
80103eac:	9c                   	pushf  
80103ead:	5b                   	pop    %ebx
  asm volatile("cli");
80103eae:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103eaf:	e8 05 f4 ff ff       	call   801032b9 <mycpu>
80103eb4:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103ebb:	74 12                	je     80103ecf <pushcli+0x2e>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103ebd:	e8 f7 f3 ff ff       	call   801032b9 <mycpu>
80103ec2:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103ec9:	83 c4 04             	add    $0x4,%esp
80103ecc:	5b                   	pop    %ebx
80103ecd:	5d                   	pop    %ebp
80103ece:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103ecf:	e8 e5 f3 ff ff       	call   801032b9 <mycpu>
80103ed4:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103eda:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103ee0:	eb db                	jmp    80103ebd <pushcli+0x1c>

80103ee2 <popcli>:

void
popcli(void)
{
80103ee2:	f3 0f 1e fb          	endbr32 
80103ee6:	55                   	push   %ebp
80103ee7:	89 e5                	mov    %esp,%ebp
80103ee9:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103eec:	9c                   	pushf  
80103eed:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103eee:	f6 c4 02             	test   $0x2,%ah
80103ef1:	75 28                	jne    80103f1b <popcli+0x39>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103ef3:	e8 c1 f3 ff ff       	call   801032b9 <mycpu>
80103ef8:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103efe:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103f01:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103f07:	85 d2                	test   %edx,%edx
80103f09:	78 1d                	js     80103f28 <popcli+0x46>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103f0b:	e8 a9 f3 ff ff       	call   801032b9 <mycpu>
80103f10:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103f17:	74 1c                	je     80103f35 <popcli+0x53>
    sti();
}
80103f19:	c9                   	leave  
80103f1a:	c3                   	ret    
    panic("popcli - interruptible");
80103f1b:	83 ec 0c             	sub    $0xc,%esp
80103f1e:	68 97 70 10 80       	push   $0x80107097
80103f23:	e8 34 c4 ff ff       	call   8010035c <panic>
    panic("popcli");
80103f28:	83 ec 0c             	sub    $0xc,%esp
80103f2b:	68 ae 70 10 80       	push   $0x801070ae
80103f30:	e8 27 c4 ff ff       	call   8010035c <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103f35:	e8 7f f3 ff ff       	call   801032b9 <mycpu>
80103f3a:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103f41:	74 d6                	je     80103f19 <popcli+0x37>
  asm volatile("sti");
80103f43:	fb                   	sti    
}
80103f44:	eb d3                	jmp    80103f19 <popcli+0x37>

80103f46 <holding>:
{
80103f46:	f3 0f 1e fb          	endbr32 
80103f4a:	55                   	push   %ebp
80103f4b:	89 e5                	mov    %esp,%ebp
80103f4d:	53                   	push   %ebx
80103f4e:	83 ec 04             	sub    $0x4,%esp
80103f51:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103f54:	e8 48 ff ff ff       	call   80103ea1 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103f59:	83 3b 00             	cmpl   $0x0,(%ebx)
80103f5c:	75 12                	jne    80103f70 <holding+0x2a>
80103f5e:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103f63:	e8 7a ff ff ff       	call   80103ee2 <popcli>
}
80103f68:	89 d8                	mov    %ebx,%eax
80103f6a:	83 c4 04             	add    $0x4,%esp
80103f6d:	5b                   	pop    %ebx
80103f6e:	5d                   	pop    %ebp
80103f6f:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103f70:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103f73:	e8 41 f3 ff ff       	call   801032b9 <mycpu>
80103f78:	39 c3                	cmp    %eax,%ebx
80103f7a:	74 07                	je     80103f83 <holding+0x3d>
80103f7c:	bb 00 00 00 00       	mov    $0x0,%ebx
80103f81:	eb e0                	jmp    80103f63 <holding+0x1d>
80103f83:	bb 01 00 00 00       	mov    $0x1,%ebx
80103f88:	eb d9                	jmp    80103f63 <holding+0x1d>

80103f8a <acquire>:
{
80103f8a:	f3 0f 1e fb          	endbr32 
80103f8e:	55                   	push   %ebp
80103f8f:	89 e5                	mov    %esp,%ebp
80103f91:	53                   	push   %ebx
80103f92:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103f95:	e8 07 ff ff ff       	call   80103ea1 <pushcli>
  if(holding(lk))
80103f9a:	83 ec 0c             	sub    $0xc,%esp
80103f9d:	ff 75 08             	pushl  0x8(%ebp)
80103fa0:	e8 a1 ff ff ff       	call   80103f46 <holding>
80103fa5:	83 c4 10             	add    $0x10,%esp
80103fa8:	85 c0                	test   %eax,%eax
80103faa:	75 3a                	jne    80103fe6 <acquire+0x5c>
  while(xchg(&lk->locked, 1) != 0)
80103fac:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103faf:	b8 01 00 00 00       	mov    $0x1,%eax
80103fb4:	f0 87 02             	lock xchg %eax,(%edx)
80103fb7:	85 c0                	test   %eax,%eax
80103fb9:	75 f1                	jne    80103fac <acquire+0x22>
  __sync_synchronize();
80103fbb:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103fc0:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103fc3:	e8 f1 f2 ff ff       	call   801032b9 <mycpu>
80103fc8:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103fcb:	8b 45 08             	mov    0x8(%ebp),%eax
80103fce:	83 c0 0c             	add    $0xc,%eax
80103fd1:	83 ec 08             	sub    $0x8,%esp
80103fd4:	50                   	push   %eax
80103fd5:	8d 45 08             	lea    0x8(%ebp),%eax
80103fd8:	50                   	push   %eax
80103fd9:	e8 7b fe ff ff       	call   80103e59 <getcallerpcs>
}
80103fde:	83 c4 10             	add    $0x10,%esp
80103fe1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103fe4:	c9                   	leave  
80103fe5:	c3                   	ret    
    panic("acquire");
80103fe6:	83 ec 0c             	sub    $0xc,%esp
80103fe9:	68 b5 70 10 80       	push   $0x801070b5
80103fee:	e8 69 c3 ff ff       	call   8010035c <panic>

80103ff3 <release>:
{
80103ff3:	f3 0f 1e fb          	endbr32 
80103ff7:	55                   	push   %ebp
80103ff8:	89 e5                	mov    %esp,%ebp
80103ffa:	53                   	push   %ebx
80103ffb:	83 ec 10             	sub    $0x10,%esp
80103ffe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80104001:	53                   	push   %ebx
80104002:	e8 3f ff ff ff       	call   80103f46 <holding>
80104007:	83 c4 10             	add    $0x10,%esp
8010400a:	85 c0                	test   %eax,%eax
8010400c:	74 23                	je     80104031 <release+0x3e>
  lk->pcs[0] = 0;
8010400e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80104015:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
8010401c:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80104021:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80104027:	e8 b6 fe ff ff       	call   80103ee2 <popcli>
}
8010402c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010402f:	c9                   	leave  
80104030:	c3                   	ret    
    panic("release");
80104031:	83 ec 0c             	sub    $0xc,%esp
80104034:	68 bd 70 10 80       	push   $0x801070bd
80104039:	e8 1e c3 ff ff       	call   8010035c <panic>

8010403e <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010403e:	f3 0f 1e fb          	endbr32 
80104042:	55                   	push   %ebp
80104043:	89 e5                	mov    %esp,%ebp
80104045:	57                   	push   %edi
80104046:	53                   	push   %ebx
80104047:	8b 55 08             	mov    0x8(%ebp),%edx
8010404a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010404d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80104050:	f6 c2 03             	test   $0x3,%dl
80104053:	75 25                	jne    8010407a <memset+0x3c>
80104055:	f6 c1 03             	test   $0x3,%cl
80104058:	75 20                	jne    8010407a <memset+0x3c>
    c &= 0xFF;
8010405a:	0f b6 f8             	movzbl %al,%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010405d:	c1 e9 02             	shr    $0x2,%ecx
80104060:	c1 e0 18             	shl    $0x18,%eax
80104063:	89 fb                	mov    %edi,%ebx
80104065:	c1 e3 10             	shl    $0x10,%ebx
80104068:	09 d8                	or     %ebx,%eax
8010406a:	89 fb                	mov    %edi,%ebx
8010406c:	c1 e3 08             	shl    $0x8,%ebx
8010406f:	09 d8                	or     %ebx,%eax
80104071:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80104073:	89 d7                	mov    %edx,%edi
80104075:	fc                   	cld    
80104076:	f3 ab                	rep stos %eax,%es:(%edi)
}
80104078:	eb 05                	jmp    8010407f <memset+0x41>
  asm volatile("cld; rep stosb" :
8010407a:	89 d7                	mov    %edx,%edi
8010407c:	fc                   	cld    
8010407d:	f3 aa                	rep stos %al,%es:(%edi)
  } else
    stosb(dst, c, n);
  return dst;
}
8010407f:	89 d0                	mov    %edx,%eax
80104081:	5b                   	pop    %ebx
80104082:	5f                   	pop    %edi
80104083:	5d                   	pop    %ebp
80104084:	c3                   	ret    

80104085 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104085:	f3 0f 1e fb          	endbr32 
80104089:	55                   	push   %ebp
8010408a:	89 e5                	mov    %esp,%ebp
8010408c:	56                   	push   %esi
8010408d:	53                   	push   %ebx
8010408e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104091:	8b 55 0c             	mov    0xc(%ebp),%edx
80104094:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104097:	8d 70 ff             	lea    -0x1(%eax),%esi
8010409a:	85 c0                	test   %eax,%eax
8010409c:	74 1c                	je     801040ba <memcmp+0x35>
    if(*s1 != *s2)
8010409e:	0f b6 01             	movzbl (%ecx),%eax
801040a1:	0f b6 1a             	movzbl (%edx),%ebx
801040a4:	38 d8                	cmp    %bl,%al
801040a6:	75 0a                	jne    801040b2 <memcmp+0x2d>
      return *s1 - *s2;
    s1++, s2++;
801040a8:	83 c1 01             	add    $0x1,%ecx
801040ab:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
801040ae:	89 f0                	mov    %esi,%eax
801040b0:	eb e5                	jmp    80104097 <memcmp+0x12>
      return *s1 - *s2;
801040b2:	0f b6 c0             	movzbl %al,%eax
801040b5:	0f b6 db             	movzbl %bl,%ebx
801040b8:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
801040ba:	5b                   	pop    %ebx
801040bb:	5e                   	pop    %esi
801040bc:	5d                   	pop    %ebp
801040bd:	c3                   	ret    

801040be <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
801040be:	f3 0f 1e fb          	endbr32 
801040c2:	55                   	push   %ebp
801040c3:	89 e5                	mov    %esp,%ebp
801040c5:	56                   	push   %esi
801040c6:	53                   	push   %ebx
801040c7:	8b 75 08             	mov    0x8(%ebp),%esi
801040ca:	8b 55 0c             	mov    0xc(%ebp),%edx
801040cd:	8b 45 10             	mov    0x10(%ebp),%eax
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801040d0:	39 f2                	cmp    %esi,%edx
801040d2:	73 3a                	jae    8010410e <memmove+0x50>
801040d4:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
801040d7:	39 f1                	cmp    %esi,%ecx
801040d9:	76 37                	jbe    80104112 <memmove+0x54>
    s += n;
    d += n;
801040db:	8d 14 06             	lea    (%esi,%eax,1),%edx
    while(n-- > 0)
801040de:	8d 58 ff             	lea    -0x1(%eax),%ebx
801040e1:	85 c0                	test   %eax,%eax
801040e3:	74 23                	je     80104108 <memmove+0x4a>
      *--d = *--s;
801040e5:	83 e9 01             	sub    $0x1,%ecx
801040e8:	83 ea 01             	sub    $0x1,%edx
801040eb:	0f b6 01             	movzbl (%ecx),%eax
801040ee:	88 02                	mov    %al,(%edx)
    while(n-- > 0)
801040f0:	89 d8                	mov    %ebx,%eax
801040f2:	eb ea                	jmp    801040de <memmove+0x20>
  } else
    while(n-- > 0)
      *d++ = *s++;
801040f4:	0f b6 02             	movzbl (%edx),%eax
801040f7:	88 01                	mov    %al,(%ecx)
801040f9:	8d 49 01             	lea    0x1(%ecx),%ecx
801040fc:	8d 52 01             	lea    0x1(%edx),%edx
    while(n-- > 0)
801040ff:	89 d8                	mov    %ebx,%eax
80104101:	8d 58 ff             	lea    -0x1(%eax),%ebx
80104104:	85 c0                	test   %eax,%eax
80104106:	75 ec                	jne    801040f4 <memmove+0x36>

  return dst;
}
80104108:	89 f0                	mov    %esi,%eax
8010410a:	5b                   	pop    %ebx
8010410b:	5e                   	pop    %esi
8010410c:	5d                   	pop    %ebp
8010410d:	c3                   	ret    
8010410e:	89 f1                	mov    %esi,%ecx
80104110:	eb ef                	jmp    80104101 <memmove+0x43>
80104112:	89 f1                	mov    %esi,%ecx
80104114:	eb eb                	jmp    80104101 <memmove+0x43>

80104116 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104116:	f3 0f 1e fb          	endbr32 
8010411a:	55                   	push   %ebp
8010411b:	89 e5                	mov    %esp,%ebp
8010411d:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80104120:	ff 75 10             	pushl  0x10(%ebp)
80104123:	ff 75 0c             	pushl  0xc(%ebp)
80104126:	ff 75 08             	pushl  0x8(%ebp)
80104129:	e8 90 ff ff ff       	call   801040be <memmove>
}
8010412e:	c9                   	leave  
8010412f:	c3                   	ret    

80104130 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104130:	f3 0f 1e fb          	endbr32 
80104134:	55                   	push   %ebp
80104135:	89 e5                	mov    %esp,%ebp
80104137:	53                   	push   %ebx
80104138:	8b 55 08             	mov    0x8(%ebp),%edx
8010413b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010413e:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80104141:	eb 09                	jmp    8010414c <strncmp+0x1c>
    n--, p++, q++;
80104143:	83 e8 01             	sub    $0x1,%eax
80104146:	83 c2 01             	add    $0x1,%edx
80104149:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
8010414c:	85 c0                	test   %eax,%eax
8010414e:	74 0b                	je     8010415b <strncmp+0x2b>
80104150:	0f b6 1a             	movzbl (%edx),%ebx
80104153:	84 db                	test   %bl,%bl
80104155:	74 04                	je     8010415b <strncmp+0x2b>
80104157:	3a 19                	cmp    (%ecx),%bl
80104159:	74 e8                	je     80104143 <strncmp+0x13>
  if(n == 0)
8010415b:	85 c0                	test   %eax,%eax
8010415d:	74 0b                	je     8010416a <strncmp+0x3a>
    return 0;
  return (uchar)*p - (uchar)*q;
8010415f:	0f b6 02             	movzbl (%edx),%eax
80104162:	0f b6 11             	movzbl (%ecx),%edx
80104165:	29 d0                	sub    %edx,%eax
}
80104167:	5b                   	pop    %ebx
80104168:	5d                   	pop    %ebp
80104169:	c3                   	ret    
    return 0;
8010416a:	b8 00 00 00 00       	mov    $0x0,%eax
8010416f:	eb f6                	jmp    80104167 <strncmp+0x37>

80104171 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104171:	f3 0f 1e fb          	endbr32 
80104175:	55                   	push   %ebp
80104176:	89 e5                	mov    %esp,%ebp
80104178:	57                   	push   %edi
80104179:	56                   	push   %esi
8010417a:	53                   	push   %ebx
8010417b:	8b 7d 08             	mov    0x8(%ebp),%edi
8010417e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104181:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80104184:	89 fa                	mov    %edi,%edx
80104186:	eb 04                	jmp    8010418c <strncpy+0x1b>
80104188:	89 f1                	mov    %esi,%ecx
8010418a:	89 da                	mov    %ebx,%edx
8010418c:	89 c3                	mov    %eax,%ebx
8010418e:	83 e8 01             	sub    $0x1,%eax
80104191:	85 db                	test   %ebx,%ebx
80104193:	7e 1b                	jle    801041b0 <strncpy+0x3f>
80104195:	8d 71 01             	lea    0x1(%ecx),%esi
80104198:	8d 5a 01             	lea    0x1(%edx),%ebx
8010419b:	0f b6 09             	movzbl (%ecx),%ecx
8010419e:	88 0a                	mov    %cl,(%edx)
801041a0:	84 c9                	test   %cl,%cl
801041a2:	75 e4                	jne    80104188 <strncpy+0x17>
801041a4:	89 da                	mov    %ebx,%edx
801041a6:	eb 08                	jmp    801041b0 <strncpy+0x3f>
    ;
  while(n-- > 0)
    *s++ = 0;
801041a8:	c6 02 00             	movb   $0x0,(%edx)
  while(n-- > 0)
801041ab:	89 c8                	mov    %ecx,%eax
    *s++ = 0;
801041ad:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
801041b0:	8d 48 ff             	lea    -0x1(%eax),%ecx
801041b3:	85 c0                	test   %eax,%eax
801041b5:	7f f1                	jg     801041a8 <strncpy+0x37>
  return os;
}
801041b7:	89 f8                	mov    %edi,%eax
801041b9:	5b                   	pop    %ebx
801041ba:	5e                   	pop    %esi
801041bb:	5f                   	pop    %edi
801041bc:	5d                   	pop    %ebp
801041bd:	c3                   	ret    

801041be <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801041be:	f3 0f 1e fb          	endbr32 
801041c2:	55                   	push   %ebp
801041c3:	89 e5                	mov    %esp,%ebp
801041c5:	57                   	push   %edi
801041c6:	56                   	push   %esi
801041c7:	53                   	push   %ebx
801041c8:	8b 7d 08             	mov    0x8(%ebp),%edi
801041cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801041ce:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  if(n <= 0)
801041d1:	85 c0                	test   %eax,%eax
801041d3:	7e 23                	jle    801041f8 <safestrcpy+0x3a>
801041d5:	89 fa                	mov    %edi,%edx
801041d7:	eb 04                	jmp    801041dd <safestrcpy+0x1f>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
801041d9:	89 f1                	mov    %esi,%ecx
801041db:	89 da                	mov    %ebx,%edx
801041dd:	83 e8 01             	sub    $0x1,%eax
801041e0:	85 c0                	test   %eax,%eax
801041e2:	7e 11                	jle    801041f5 <safestrcpy+0x37>
801041e4:	8d 71 01             	lea    0x1(%ecx),%esi
801041e7:	8d 5a 01             	lea    0x1(%edx),%ebx
801041ea:	0f b6 09             	movzbl (%ecx),%ecx
801041ed:	88 0a                	mov    %cl,(%edx)
801041ef:	84 c9                	test   %cl,%cl
801041f1:	75 e6                	jne    801041d9 <safestrcpy+0x1b>
801041f3:	89 da                	mov    %ebx,%edx
    ;
  *s = 0;
801041f5:	c6 02 00             	movb   $0x0,(%edx)
  return os;
}
801041f8:	89 f8                	mov    %edi,%eax
801041fa:	5b                   	pop    %ebx
801041fb:	5e                   	pop    %esi
801041fc:	5f                   	pop    %edi
801041fd:	5d                   	pop    %ebp
801041fe:	c3                   	ret    

801041ff <strlen>:

int
strlen(const char *s)
{
801041ff:	f3 0f 1e fb          	endbr32 
80104203:	55                   	push   %ebp
80104204:	89 e5                	mov    %esp,%ebp
80104206:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104209:	b8 00 00 00 00       	mov    $0x0,%eax
8010420e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80104212:	74 05                	je     80104219 <strlen+0x1a>
80104214:	83 c0 01             	add    $0x1,%eax
80104217:	eb f5                	jmp    8010420e <strlen+0xf>
    ;
  return n;
}
80104219:	5d                   	pop    %ebp
8010421a:	c3                   	ret    

8010421b <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010421b:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010421f:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80104223:	55                   	push   %ebp
  pushl %ebx
80104224:	53                   	push   %ebx
  pushl %esi
80104225:	56                   	push   %esi
  pushl %edi
80104226:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104227:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104229:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010422b:	5f                   	pop    %edi
  popl %esi
8010422c:	5e                   	pop    %esi
  popl %ebx
8010422d:	5b                   	pop    %ebx
  popl %ebp
8010422e:	5d                   	pop    %ebp
  ret
8010422f:	c3                   	ret    

80104230 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104230:	f3 0f 1e fb          	endbr32 
80104234:	55                   	push   %ebp
80104235:	89 e5                	mov    %esp,%ebp
80104237:	53                   	push   %ebx
80104238:	83 ec 04             	sub    $0x4,%esp
8010423b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
8010423e:	e8 f5 f0 ff ff       	call   80103338 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104243:	8b 00                	mov    (%eax),%eax
80104245:	39 d8                	cmp    %ebx,%eax
80104247:	76 19                	jbe    80104262 <fetchint+0x32>
80104249:	8d 53 04             	lea    0x4(%ebx),%edx
8010424c:	39 d0                	cmp    %edx,%eax
8010424e:	72 19                	jb     80104269 <fetchint+0x39>
    return -1;
  *ip = *(int*)(addr);
80104250:	8b 13                	mov    (%ebx),%edx
80104252:	8b 45 0c             	mov    0xc(%ebp),%eax
80104255:	89 10                	mov    %edx,(%eax)
  return 0;
80104257:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010425c:	83 c4 04             	add    $0x4,%esp
8010425f:	5b                   	pop    %ebx
80104260:	5d                   	pop    %ebp
80104261:	c3                   	ret    
    return -1;
80104262:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104267:	eb f3                	jmp    8010425c <fetchint+0x2c>
80104269:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010426e:	eb ec                	jmp    8010425c <fetchint+0x2c>

80104270 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104270:	f3 0f 1e fb          	endbr32 
80104274:	55                   	push   %ebp
80104275:	89 e5                	mov    %esp,%ebp
80104277:	53                   	push   %ebx
80104278:	83 ec 04             	sub    $0x4,%esp
8010427b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
8010427e:	e8 b5 f0 ff ff       	call   80103338 <myproc>

  if(addr >= curproc->sz)
80104283:	39 18                	cmp    %ebx,(%eax)
80104285:	76 26                	jbe    801042ad <fetchstr+0x3d>
    return -1;
  *pp = (char*)addr;
80104287:	8b 55 0c             	mov    0xc(%ebp),%edx
8010428a:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
8010428c:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
8010428e:	89 d8                	mov    %ebx,%eax
80104290:	39 d0                	cmp    %edx,%eax
80104292:	73 0e                	jae    801042a2 <fetchstr+0x32>
    if(*s == 0)
80104294:	80 38 00             	cmpb   $0x0,(%eax)
80104297:	74 05                	je     8010429e <fetchstr+0x2e>
  for(s = *pp; s < ep; s++){
80104299:	83 c0 01             	add    $0x1,%eax
8010429c:	eb f2                	jmp    80104290 <fetchstr+0x20>
      return s - *pp;
8010429e:	29 d8                	sub    %ebx,%eax
801042a0:	eb 05                	jmp    801042a7 <fetchstr+0x37>
  }
  return -1;
801042a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801042a7:	83 c4 04             	add    $0x4,%esp
801042aa:	5b                   	pop    %ebx
801042ab:	5d                   	pop    %ebp
801042ac:	c3                   	ret    
    return -1;
801042ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042b2:	eb f3                	jmp    801042a7 <fetchstr+0x37>

801042b4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801042b4:	f3 0f 1e fb          	endbr32 
801042b8:	55                   	push   %ebp
801042b9:	89 e5                	mov    %esp,%ebp
801042bb:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801042be:	e8 75 f0 ff ff       	call   80103338 <myproc>
801042c3:	8b 50 18             	mov    0x18(%eax),%edx
801042c6:	8b 45 08             	mov    0x8(%ebp),%eax
801042c9:	c1 e0 02             	shl    $0x2,%eax
801042cc:	03 42 44             	add    0x44(%edx),%eax
801042cf:	83 ec 08             	sub    $0x8,%esp
801042d2:	ff 75 0c             	pushl  0xc(%ebp)
801042d5:	83 c0 04             	add    $0x4,%eax
801042d8:	50                   	push   %eax
801042d9:	e8 52 ff ff ff       	call   80104230 <fetchint>
}
801042de:	c9                   	leave  
801042df:	c3                   	ret    

801042e0 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801042e0:	f3 0f 1e fb          	endbr32 
801042e4:	55                   	push   %ebp
801042e5:	89 e5                	mov    %esp,%ebp
801042e7:	56                   	push   %esi
801042e8:	53                   	push   %ebx
801042e9:	83 ec 10             	sub    $0x10,%esp
801042ec:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801042ef:	e8 44 f0 ff ff       	call   80103338 <myproc>
801042f4:	89 c6                	mov    %eax,%esi

  if(argint(n, &i) < 0)
801042f6:	83 ec 08             	sub    $0x8,%esp
801042f9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801042fc:	50                   	push   %eax
801042fd:	ff 75 08             	pushl  0x8(%ebp)
80104300:	e8 af ff ff ff       	call   801042b4 <argint>
80104305:	83 c4 10             	add    $0x10,%esp
80104308:	85 c0                	test   %eax,%eax
8010430a:	78 24                	js     80104330 <argptr+0x50>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010430c:	85 db                	test   %ebx,%ebx
8010430e:	78 27                	js     80104337 <argptr+0x57>
80104310:	8b 16                	mov    (%esi),%edx
80104312:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104315:	39 c2                	cmp    %eax,%edx
80104317:	76 25                	jbe    8010433e <argptr+0x5e>
80104319:	01 c3                	add    %eax,%ebx
8010431b:	39 da                	cmp    %ebx,%edx
8010431d:	72 26                	jb     80104345 <argptr+0x65>
    return -1;
  *pp = (char*)i;
8010431f:	8b 55 0c             	mov    0xc(%ebp),%edx
80104322:	89 02                	mov    %eax,(%edx)
  return 0;
80104324:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104329:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010432c:	5b                   	pop    %ebx
8010432d:	5e                   	pop    %esi
8010432e:	5d                   	pop    %ebp
8010432f:	c3                   	ret    
    return -1;
80104330:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104335:	eb f2                	jmp    80104329 <argptr+0x49>
    return -1;
80104337:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010433c:	eb eb                	jmp    80104329 <argptr+0x49>
8010433e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104343:	eb e4                	jmp    80104329 <argptr+0x49>
80104345:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010434a:	eb dd                	jmp    80104329 <argptr+0x49>

8010434c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010434c:	f3 0f 1e fb          	endbr32 
80104350:	55                   	push   %ebp
80104351:	89 e5                	mov    %esp,%ebp
80104353:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104356:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104359:	50                   	push   %eax
8010435a:	ff 75 08             	pushl  0x8(%ebp)
8010435d:	e8 52 ff ff ff       	call   801042b4 <argint>
80104362:	83 c4 10             	add    $0x10,%esp
80104365:	85 c0                	test   %eax,%eax
80104367:	78 13                	js     8010437c <argstr+0x30>
    return -1;
  return fetchstr(addr, pp);
80104369:	83 ec 08             	sub    $0x8,%esp
8010436c:	ff 75 0c             	pushl  0xc(%ebp)
8010436f:	ff 75 f4             	pushl  -0xc(%ebp)
80104372:	e8 f9 fe ff ff       	call   80104270 <fetchstr>
80104377:	83 c4 10             	add    $0x10,%esp
}
8010437a:	c9                   	leave  
8010437b:	c3                   	ret    
    return -1;
8010437c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104381:	eb f7                	jmp    8010437a <argstr+0x2e>

80104383 <syscall>:
};
#endif // PRINT_SYSCALLS

void
syscall(void)
{
80104383:	f3 0f 1e fb          	endbr32 
80104387:	55                   	push   %ebp
80104388:	89 e5                	mov    %esp,%ebp
8010438a:	53                   	push   %ebx
8010438b:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010438e:	e8 a5 ef ff ff       	call   80103338 <myproc>
80104393:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104395:	8b 40 18             	mov    0x18(%eax),%eax
80104398:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010439b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010439e:	83 fa 1c             	cmp    $0x1c,%edx
801043a1:	77 17                	ja     801043ba <syscall+0x37>
801043a3:	8b 14 85 00 71 10 80 	mov    -0x7fef8f00(,%eax,4),%edx
801043aa:	85 d2                	test   %edx,%edx
801043ac:	74 0c                	je     801043ba <syscall+0x37>
    curproc->tf->eax = syscalls[num]();
801043ae:	ff d2                	call   *%edx
801043b0:	89 c2                	mov    %eax,%edx
801043b2:	8b 43 18             	mov    0x18(%ebx),%eax
801043b5:	89 50 1c             	mov    %edx,0x1c(%eax)
801043b8:	eb 1f                	jmp    801043d9 <syscall+0x56>
    #ifdef PRINT_SYSCALLS
      cprintf("%s -> %d \n", syscallnames[num], curproc->tf->eax);
    #endif
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
801043ba:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801043bd:	50                   	push   %eax
801043be:	52                   	push   %edx
801043bf:	ff 73 10             	pushl  0x10(%ebx)
801043c2:	68 c5 70 10 80       	push   $0x801070c5
801043c7:	e8 5d c2 ff ff       	call   80100629 <cprintf>
    curproc->tf->eax = -1;
801043cc:	8b 43 18             	mov    0x18(%ebx),%eax
801043cf:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801043d6:	83 c4 10             	add    $0x10,%esp
  }
}
801043d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801043dc:	c9                   	leave  
801043dd:	c3                   	ret    

801043de <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801043de:	55                   	push   %ebp
801043df:	89 e5                	mov    %esp,%ebp
801043e1:	56                   	push   %esi
801043e2:	53                   	push   %ebx
801043e3:	83 ec 18             	sub    $0x18,%esp
801043e6:	89 d6                	mov    %edx,%esi
801043e8:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801043ea:	8d 55 f4             	lea    -0xc(%ebp),%edx
801043ed:	52                   	push   %edx
801043ee:	50                   	push   %eax
801043ef:	e8 c0 fe ff ff       	call   801042b4 <argint>
801043f4:	83 c4 10             	add    $0x10,%esp
801043f7:	85 c0                	test   %eax,%eax
801043f9:	78 35                	js     80104430 <argfd+0x52>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801043fb:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801043ff:	77 28                	ja     80104429 <argfd+0x4b>
80104401:	e8 32 ef ff ff       	call   80103338 <myproc>
80104406:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104409:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010440d:	85 c0                	test   %eax,%eax
8010440f:	74 18                	je     80104429 <argfd+0x4b>
    return -1;
  if(pfd)
80104411:	85 f6                	test   %esi,%esi
80104413:	74 02                	je     80104417 <argfd+0x39>
    *pfd = fd;
80104415:	89 16                	mov    %edx,(%esi)
  if(pf)
80104417:	85 db                	test   %ebx,%ebx
80104419:	74 1c                	je     80104437 <argfd+0x59>
    *pf = f;
8010441b:	89 03                	mov    %eax,(%ebx)
  return 0;
8010441d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104422:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104425:	5b                   	pop    %ebx
80104426:	5e                   	pop    %esi
80104427:	5d                   	pop    %ebp
80104428:	c3                   	ret    
    return -1;
80104429:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010442e:	eb f2                	jmp    80104422 <argfd+0x44>
    return -1;
80104430:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104435:	eb eb                	jmp    80104422 <argfd+0x44>
  return 0;
80104437:	b8 00 00 00 00       	mov    $0x0,%eax
8010443c:	eb e4                	jmp    80104422 <argfd+0x44>

8010443e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010443e:	55                   	push   %ebp
8010443f:	89 e5                	mov    %esp,%ebp
80104441:	53                   	push   %ebx
80104442:	83 ec 04             	sub    $0x4,%esp
80104445:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104447:	e8 ec ee ff ff       	call   80103338 <myproc>
8010444c:	89 c2                	mov    %eax,%edx

  for(fd = 0; fd < NOFILE; fd++){
8010444e:	b8 00 00 00 00       	mov    $0x0,%eax
80104453:	83 f8 0f             	cmp    $0xf,%eax
80104456:	7f 12                	jg     8010446a <fdalloc+0x2c>
    if(curproc->ofile[fd] == 0){
80104458:	83 7c 82 28 00       	cmpl   $0x0,0x28(%edx,%eax,4)
8010445d:	74 05                	je     80104464 <fdalloc+0x26>
  for(fd = 0; fd < NOFILE; fd++){
8010445f:	83 c0 01             	add    $0x1,%eax
80104462:	eb ef                	jmp    80104453 <fdalloc+0x15>
      curproc->ofile[fd] = f;
80104464:	89 5c 82 28          	mov    %ebx,0x28(%edx,%eax,4)
      return fd;
80104468:	eb 05                	jmp    8010446f <fdalloc+0x31>
    }
  }
  return -1;
8010446a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010446f:	83 c4 04             	add    $0x4,%esp
80104472:	5b                   	pop    %ebx
80104473:	5d                   	pop    %ebp
80104474:	c3                   	ret    

80104475 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104475:	55                   	push   %ebp
80104476:	89 e5                	mov    %esp,%ebp
80104478:	56                   	push   %esi
80104479:	53                   	push   %ebx
8010447a:	83 ec 10             	sub    $0x10,%esp
8010447d:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010447f:	b8 20 00 00 00       	mov    $0x20,%eax
80104484:	89 c6                	mov    %eax,%esi
80104486:	39 43 58             	cmp    %eax,0x58(%ebx)
80104489:	76 2e                	jbe    801044b9 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010448b:	6a 10                	push   $0x10
8010448d:	50                   	push   %eax
8010448e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104491:	50                   	push   %eax
80104492:	53                   	push   %ebx
80104493:	e8 75 d3 ff ff       	call   8010180d <readi>
80104498:	83 c4 10             	add    $0x10,%esp
8010449b:	83 f8 10             	cmp    $0x10,%eax
8010449e:	75 0c                	jne    801044ac <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801044a0:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801044a5:	75 1e                	jne    801044c5 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801044a7:	8d 46 10             	lea    0x10(%esi),%eax
801044aa:	eb d8                	jmp    80104484 <isdirempty+0xf>
      panic("isdirempty: readi");
801044ac:	83 ec 0c             	sub    $0xc,%esp
801044af:	68 78 71 10 80       	push   $0x80107178
801044b4:	e8 a3 be ff ff       	call   8010035c <panic>
      return 0;
  }
  return 1;
801044b9:	b8 01 00 00 00       	mov    $0x1,%eax
}
801044be:	8d 65 f8             	lea    -0x8(%ebp),%esp
801044c1:	5b                   	pop    %ebx
801044c2:	5e                   	pop    %esi
801044c3:	5d                   	pop    %ebp
801044c4:	c3                   	ret    
      return 0;
801044c5:	b8 00 00 00 00       	mov    $0x0,%eax
801044ca:	eb f2                	jmp    801044be <isdirempty+0x49>

801044cc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801044cc:	55                   	push   %ebp
801044cd:	89 e5                	mov    %esp,%ebp
801044cf:	57                   	push   %edi
801044d0:	56                   	push   %esi
801044d1:	53                   	push   %ebx
801044d2:	83 ec 44             	sub    $0x44,%esp
801044d5:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801044d8:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801044db:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801044de:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801044e1:	52                   	push   %edx
801044e2:	50                   	push   %eax
801044e3:	e8 c0 d7 ff ff       	call   80101ca8 <nameiparent>
801044e8:	89 c6                	mov    %eax,%esi
801044ea:	83 c4 10             	add    $0x10,%esp
801044ed:	85 c0                	test   %eax,%eax
801044ef:	0f 84 35 01 00 00    	je     8010462a <create+0x15e>
    return 0;
  ilock(dp);
801044f5:	83 ec 0c             	sub    $0xc,%esp
801044f8:	50                   	push   %eax
801044f9:	e8 09 d1 ff ff       	call   80101607 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801044fe:	83 c4 0c             	add    $0xc,%esp
80104501:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104504:	50                   	push   %eax
80104505:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104508:	50                   	push   %eax
80104509:	56                   	push   %esi
8010450a:	e8 47 d5 ff ff       	call   80101a56 <dirlookup>
8010450f:	89 c3                	mov    %eax,%ebx
80104511:	83 c4 10             	add    $0x10,%esp
80104514:	85 c0                	test   %eax,%eax
80104516:	74 3d                	je     80104555 <create+0x89>
    iunlockput(dp);
80104518:	83 ec 0c             	sub    $0xc,%esp
8010451b:	56                   	push   %esi
8010451c:	e8 99 d2 ff ff       	call   801017ba <iunlockput>
    ilock(ip);
80104521:	89 1c 24             	mov    %ebx,(%esp)
80104524:	e8 de d0 ff ff       	call   80101607 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104529:	83 c4 10             	add    $0x10,%esp
8010452c:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104531:	75 07                	jne    8010453a <create+0x6e>
80104533:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104538:	74 11                	je     8010454b <create+0x7f>
      return ip;
    iunlockput(ip);
8010453a:	83 ec 0c             	sub    $0xc,%esp
8010453d:	53                   	push   %ebx
8010453e:	e8 77 d2 ff ff       	call   801017ba <iunlockput>
    return 0;
80104543:	83 c4 10             	add    $0x10,%esp
80104546:	bb 00 00 00 00       	mov    $0x0,%ebx
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010454b:	89 d8                	mov    %ebx,%eax
8010454d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104550:	5b                   	pop    %ebx
80104551:	5e                   	pop    %esi
80104552:	5f                   	pop    %edi
80104553:	5d                   	pop    %ebp
80104554:	c3                   	ret    
  if((ip = ialloc(dp->dev, type)) == 0)
80104555:	83 ec 08             	sub    $0x8,%esp
80104558:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010455c:	50                   	push   %eax
8010455d:	ff 36                	pushl  (%esi)
8010455f:	e8 94 ce ff ff       	call   801013f8 <ialloc>
80104564:	89 c3                	mov    %eax,%ebx
80104566:	83 c4 10             	add    $0x10,%esp
80104569:	85 c0                	test   %eax,%eax
8010456b:	74 52                	je     801045bf <create+0xf3>
  ilock(ip);
8010456d:	83 ec 0c             	sub    $0xc,%esp
80104570:	50                   	push   %eax
80104571:	e8 91 d0 ff ff       	call   80101607 <ilock>
  ip->major = major;
80104576:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
8010457a:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010457e:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104582:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104588:	89 1c 24             	mov    %ebx,(%esp)
8010458b:	e8 0e cf ff ff       	call   8010149e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104590:	83 c4 10             	add    $0x10,%esp
80104593:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104598:	74 32                	je     801045cc <create+0x100>
  if(dirlink(dp, name, ip->inum) < 0)
8010459a:	83 ec 04             	sub    $0x4,%esp
8010459d:	ff 73 04             	pushl  0x4(%ebx)
801045a0:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801045a3:	50                   	push   %eax
801045a4:	56                   	push   %esi
801045a5:	e8 2d d6 ff ff       	call   80101bd7 <dirlink>
801045aa:	83 c4 10             	add    $0x10,%esp
801045ad:	85 c0                	test   %eax,%eax
801045af:	78 6c                	js     8010461d <create+0x151>
  iunlockput(dp);
801045b1:	83 ec 0c             	sub    $0xc,%esp
801045b4:	56                   	push   %esi
801045b5:	e8 00 d2 ff ff       	call   801017ba <iunlockput>
  return ip;
801045ba:	83 c4 10             	add    $0x10,%esp
801045bd:	eb 8c                	jmp    8010454b <create+0x7f>
    panic("create: ialloc");
801045bf:	83 ec 0c             	sub    $0xc,%esp
801045c2:	68 8a 71 10 80       	push   $0x8010718a
801045c7:	e8 90 bd ff ff       	call   8010035c <panic>
    dp->nlink++;  // for ".."
801045cc:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801045d0:	83 c0 01             	add    $0x1,%eax
801045d3:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801045d7:	83 ec 0c             	sub    $0xc,%esp
801045da:	56                   	push   %esi
801045db:	e8 be ce ff ff       	call   8010149e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801045e0:	83 c4 0c             	add    $0xc,%esp
801045e3:	ff 73 04             	pushl  0x4(%ebx)
801045e6:	68 9a 71 10 80       	push   $0x8010719a
801045eb:	53                   	push   %ebx
801045ec:	e8 e6 d5 ff ff       	call   80101bd7 <dirlink>
801045f1:	83 c4 10             	add    $0x10,%esp
801045f4:	85 c0                	test   %eax,%eax
801045f6:	78 18                	js     80104610 <create+0x144>
801045f8:	83 ec 04             	sub    $0x4,%esp
801045fb:	ff 76 04             	pushl  0x4(%esi)
801045fe:	68 99 71 10 80       	push   $0x80107199
80104603:	53                   	push   %ebx
80104604:	e8 ce d5 ff ff       	call   80101bd7 <dirlink>
80104609:	83 c4 10             	add    $0x10,%esp
8010460c:	85 c0                	test   %eax,%eax
8010460e:	79 8a                	jns    8010459a <create+0xce>
      panic("create dots");
80104610:	83 ec 0c             	sub    $0xc,%esp
80104613:	68 9c 71 10 80       	push   $0x8010719c
80104618:	e8 3f bd ff ff       	call   8010035c <panic>
    panic("create: dirlink");
8010461d:	83 ec 0c             	sub    $0xc,%esp
80104620:	68 a8 71 10 80       	push   $0x801071a8
80104625:	e8 32 bd ff ff       	call   8010035c <panic>
    return 0;
8010462a:	89 c3                	mov    %eax,%ebx
8010462c:	e9 1a ff ff ff       	jmp    8010454b <create+0x7f>

80104631 <sys_dup>:
{
80104631:	f3 0f 1e fb          	endbr32 
80104635:	55                   	push   %ebp
80104636:	89 e5                	mov    %esp,%ebp
80104638:	53                   	push   %ebx
80104639:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010463c:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010463f:	ba 00 00 00 00       	mov    $0x0,%edx
80104644:	b8 00 00 00 00       	mov    $0x0,%eax
80104649:	e8 90 fd ff ff       	call   801043de <argfd>
8010464e:	85 c0                	test   %eax,%eax
80104650:	78 23                	js     80104675 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
80104652:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104655:	e8 e4 fd ff ff       	call   8010443e <fdalloc>
8010465a:	89 c3                	mov    %eax,%ebx
8010465c:	85 c0                	test   %eax,%eax
8010465e:	78 1c                	js     8010467c <sys_dup+0x4b>
  filedup(f);
80104660:	83 ec 0c             	sub    $0xc,%esp
80104663:	ff 75 f4             	pushl  -0xc(%ebp)
80104666:	e8 80 c6 ff ff       	call   80100ceb <filedup>
  return fd;
8010466b:	83 c4 10             	add    $0x10,%esp
}
8010466e:	89 d8                	mov    %ebx,%eax
80104670:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104673:	c9                   	leave  
80104674:	c3                   	ret    
    return -1;
80104675:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010467a:	eb f2                	jmp    8010466e <sys_dup+0x3d>
    return -1;
8010467c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104681:	eb eb                	jmp    8010466e <sys_dup+0x3d>

80104683 <sys_read>:
{
80104683:	f3 0f 1e fb          	endbr32 
80104687:	55                   	push   %ebp
80104688:	89 e5                	mov    %esp,%ebp
8010468a:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010468d:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104690:	ba 00 00 00 00       	mov    $0x0,%edx
80104695:	b8 00 00 00 00       	mov    $0x0,%eax
8010469a:	e8 3f fd ff ff       	call   801043de <argfd>
8010469f:	85 c0                	test   %eax,%eax
801046a1:	78 43                	js     801046e6 <sys_read+0x63>
801046a3:	83 ec 08             	sub    $0x8,%esp
801046a6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801046a9:	50                   	push   %eax
801046aa:	6a 02                	push   $0x2
801046ac:	e8 03 fc ff ff       	call   801042b4 <argint>
801046b1:	83 c4 10             	add    $0x10,%esp
801046b4:	85 c0                	test   %eax,%eax
801046b6:	78 2e                	js     801046e6 <sys_read+0x63>
801046b8:	83 ec 04             	sub    $0x4,%esp
801046bb:	ff 75 f0             	pushl  -0x10(%ebp)
801046be:	8d 45 ec             	lea    -0x14(%ebp),%eax
801046c1:	50                   	push   %eax
801046c2:	6a 01                	push   $0x1
801046c4:	e8 17 fc ff ff       	call   801042e0 <argptr>
801046c9:	83 c4 10             	add    $0x10,%esp
801046cc:	85 c0                	test   %eax,%eax
801046ce:	78 16                	js     801046e6 <sys_read+0x63>
  return fileread(f, p, n);
801046d0:	83 ec 04             	sub    $0x4,%esp
801046d3:	ff 75 f0             	pushl  -0x10(%ebp)
801046d6:	ff 75 ec             	pushl  -0x14(%ebp)
801046d9:	ff 75 f4             	pushl  -0xc(%ebp)
801046dc:	e8 5c c7 ff ff       	call   80100e3d <fileread>
801046e1:	83 c4 10             	add    $0x10,%esp
}
801046e4:	c9                   	leave  
801046e5:	c3                   	ret    
    return -1;
801046e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046eb:	eb f7                	jmp    801046e4 <sys_read+0x61>

801046ed <sys_write>:
{
801046ed:	f3 0f 1e fb          	endbr32 
801046f1:	55                   	push   %ebp
801046f2:	89 e5                	mov    %esp,%ebp
801046f4:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801046f7:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801046fa:	ba 00 00 00 00       	mov    $0x0,%edx
801046ff:	b8 00 00 00 00       	mov    $0x0,%eax
80104704:	e8 d5 fc ff ff       	call   801043de <argfd>
80104709:	85 c0                	test   %eax,%eax
8010470b:	78 43                	js     80104750 <sys_write+0x63>
8010470d:	83 ec 08             	sub    $0x8,%esp
80104710:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104713:	50                   	push   %eax
80104714:	6a 02                	push   $0x2
80104716:	e8 99 fb ff ff       	call   801042b4 <argint>
8010471b:	83 c4 10             	add    $0x10,%esp
8010471e:	85 c0                	test   %eax,%eax
80104720:	78 2e                	js     80104750 <sys_write+0x63>
80104722:	83 ec 04             	sub    $0x4,%esp
80104725:	ff 75 f0             	pushl  -0x10(%ebp)
80104728:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010472b:	50                   	push   %eax
8010472c:	6a 01                	push   $0x1
8010472e:	e8 ad fb ff ff       	call   801042e0 <argptr>
80104733:	83 c4 10             	add    $0x10,%esp
80104736:	85 c0                	test   %eax,%eax
80104738:	78 16                	js     80104750 <sys_write+0x63>
  return filewrite(f, p, n);
8010473a:	83 ec 04             	sub    $0x4,%esp
8010473d:	ff 75 f0             	pushl  -0x10(%ebp)
80104740:	ff 75 ec             	pushl  -0x14(%ebp)
80104743:	ff 75 f4             	pushl  -0xc(%ebp)
80104746:	e8 7b c7 ff ff       	call   80100ec6 <filewrite>
8010474b:	83 c4 10             	add    $0x10,%esp
}
8010474e:	c9                   	leave  
8010474f:	c3                   	ret    
    return -1;
80104750:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104755:	eb f7                	jmp    8010474e <sys_write+0x61>

80104757 <sys_close>:
{
80104757:	f3 0f 1e fb          	endbr32 
8010475b:	55                   	push   %ebp
8010475c:	89 e5                	mov    %esp,%ebp
8010475e:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104761:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104764:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104767:	b8 00 00 00 00       	mov    $0x0,%eax
8010476c:	e8 6d fc ff ff       	call   801043de <argfd>
80104771:	85 c0                	test   %eax,%eax
80104773:	78 25                	js     8010479a <sys_close+0x43>
  myproc()->ofile[fd] = 0;
80104775:	e8 be eb ff ff       	call   80103338 <myproc>
8010477a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010477d:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104784:	00 
  fileclose(f);
80104785:	83 ec 0c             	sub    $0xc,%esp
80104788:	ff 75 f0             	pushl  -0x10(%ebp)
8010478b:	e8 a4 c5 ff ff       	call   80100d34 <fileclose>
  return 0;
80104790:	83 c4 10             	add    $0x10,%esp
80104793:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104798:	c9                   	leave  
80104799:	c3                   	ret    
    return -1;
8010479a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010479f:	eb f7                	jmp    80104798 <sys_close+0x41>

801047a1 <sys_fstat>:
{
801047a1:	f3 0f 1e fb          	endbr32 
801047a5:	55                   	push   %ebp
801047a6:	89 e5                	mov    %esp,%ebp
801047a8:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801047ab:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801047ae:	ba 00 00 00 00       	mov    $0x0,%edx
801047b3:	b8 00 00 00 00       	mov    $0x0,%eax
801047b8:	e8 21 fc ff ff       	call   801043de <argfd>
801047bd:	85 c0                	test   %eax,%eax
801047bf:	78 2a                	js     801047eb <sys_fstat+0x4a>
801047c1:	83 ec 04             	sub    $0x4,%esp
801047c4:	6a 14                	push   $0x14
801047c6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801047c9:	50                   	push   %eax
801047ca:	6a 01                	push   $0x1
801047cc:	e8 0f fb ff ff       	call   801042e0 <argptr>
801047d1:	83 c4 10             	add    $0x10,%esp
801047d4:	85 c0                	test   %eax,%eax
801047d6:	78 13                	js     801047eb <sys_fstat+0x4a>
  return filestat(f, st);
801047d8:	83 ec 08             	sub    $0x8,%esp
801047db:	ff 75 f0             	pushl  -0x10(%ebp)
801047de:	ff 75 f4             	pushl  -0xc(%ebp)
801047e1:	e8 0c c6 ff ff       	call   80100df2 <filestat>
801047e6:	83 c4 10             	add    $0x10,%esp
}
801047e9:	c9                   	leave  
801047ea:	c3                   	ret    
    return -1;
801047eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047f0:	eb f7                	jmp    801047e9 <sys_fstat+0x48>

801047f2 <sys_link>:
{
801047f2:	f3 0f 1e fb          	endbr32 
801047f6:	55                   	push   %ebp
801047f7:	89 e5                	mov    %esp,%ebp
801047f9:	56                   	push   %esi
801047fa:	53                   	push   %ebx
801047fb:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801047fe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104801:	50                   	push   %eax
80104802:	6a 00                	push   $0x0
80104804:	e8 43 fb ff ff       	call   8010434c <argstr>
80104809:	83 c4 10             	add    $0x10,%esp
8010480c:	85 c0                	test   %eax,%eax
8010480e:	0f 88 d3 00 00 00    	js     801048e7 <sys_link+0xf5>
80104814:	83 ec 08             	sub    $0x8,%esp
80104817:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010481a:	50                   	push   %eax
8010481b:	6a 01                	push   $0x1
8010481d:	e8 2a fb ff ff       	call   8010434c <argstr>
80104822:	83 c4 10             	add    $0x10,%esp
80104825:	85 c0                	test   %eax,%eax
80104827:	0f 88 ba 00 00 00    	js     801048e7 <sys_link+0xf5>
  begin_op();
8010482d:	e8 5a e0 ff ff       	call   8010288c <begin_op>
  if((ip = namei(old)) == 0){
80104832:	83 ec 0c             	sub    $0xc,%esp
80104835:	ff 75 e0             	pushl  -0x20(%ebp)
80104838:	e8 4f d4 ff ff       	call   80101c8c <namei>
8010483d:	89 c3                	mov    %eax,%ebx
8010483f:	83 c4 10             	add    $0x10,%esp
80104842:	85 c0                	test   %eax,%eax
80104844:	0f 84 a4 00 00 00    	je     801048ee <sys_link+0xfc>
  ilock(ip);
8010484a:	83 ec 0c             	sub    $0xc,%esp
8010484d:	50                   	push   %eax
8010484e:	e8 b4 cd ff ff       	call   80101607 <ilock>
  if(ip->type == T_DIR){
80104853:	83 c4 10             	add    $0x10,%esp
80104856:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010485b:	0f 84 99 00 00 00    	je     801048fa <sys_link+0x108>
  ip->nlink++;
80104861:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104865:	83 c0 01             	add    $0x1,%eax
80104868:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010486c:	83 ec 0c             	sub    $0xc,%esp
8010486f:	53                   	push   %ebx
80104870:	e8 29 cc ff ff       	call   8010149e <iupdate>
  iunlock(ip);
80104875:	89 1c 24             	mov    %ebx,(%esp)
80104878:	e8 50 ce ff ff       	call   801016cd <iunlock>
  if((dp = nameiparent(new, name)) == 0)
8010487d:	83 c4 08             	add    $0x8,%esp
80104880:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104883:	50                   	push   %eax
80104884:	ff 75 e4             	pushl  -0x1c(%ebp)
80104887:	e8 1c d4 ff ff       	call   80101ca8 <nameiparent>
8010488c:	89 c6                	mov    %eax,%esi
8010488e:	83 c4 10             	add    $0x10,%esp
80104891:	85 c0                	test   %eax,%eax
80104893:	0f 84 85 00 00 00    	je     8010491e <sys_link+0x12c>
  ilock(dp);
80104899:	83 ec 0c             	sub    $0xc,%esp
8010489c:	50                   	push   %eax
8010489d:	e8 65 cd ff ff       	call   80101607 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801048a2:	83 c4 10             	add    $0x10,%esp
801048a5:	8b 03                	mov    (%ebx),%eax
801048a7:	39 06                	cmp    %eax,(%esi)
801048a9:	75 67                	jne    80104912 <sys_link+0x120>
801048ab:	83 ec 04             	sub    $0x4,%esp
801048ae:	ff 73 04             	pushl  0x4(%ebx)
801048b1:	8d 45 ea             	lea    -0x16(%ebp),%eax
801048b4:	50                   	push   %eax
801048b5:	56                   	push   %esi
801048b6:	e8 1c d3 ff ff       	call   80101bd7 <dirlink>
801048bb:	83 c4 10             	add    $0x10,%esp
801048be:	85 c0                	test   %eax,%eax
801048c0:	78 50                	js     80104912 <sys_link+0x120>
  iunlockput(dp);
801048c2:	83 ec 0c             	sub    $0xc,%esp
801048c5:	56                   	push   %esi
801048c6:	e8 ef ce ff ff       	call   801017ba <iunlockput>
  iput(ip);
801048cb:	89 1c 24             	mov    %ebx,(%esp)
801048ce:	e8 43 ce ff ff       	call   80101716 <iput>
  end_op();
801048d3:	e8 32 e0 ff ff       	call   8010290a <end_op>
  return 0;
801048d8:	83 c4 10             	add    $0x10,%esp
801048db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048e0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801048e3:	5b                   	pop    %ebx
801048e4:	5e                   	pop    %esi
801048e5:	5d                   	pop    %ebp
801048e6:	c3                   	ret    
    return -1;
801048e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048ec:	eb f2                	jmp    801048e0 <sys_link+0xee>
    end_op();
801048ee:	e8 17 e0 ff ff       	call   8010290a <end_op>
    return -1;
801048f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048f8:	eb e6                	jmp    801048e0 <sys_link+0xee>
    iunlockput(ip);
801048fa:	83 ec 0c             	sub    $0xc,%esp
801048fd:	53                   	push   %ebx
801048fe:	e8 b7 ce ff ff       	call   801017ba <iunlockput>
    end_op();
80104903:	e8 02 e0 ff ff       	call   8010290a <end_op>
    return -1;
80104908:	83 c4 10             	add    $0x10,%esp
8010490b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104910:	eb ce                	jmp    801048e0 <sys_link+0xee>
    iunlockput(dp);
80104912:	83 ec 0c             	sub    $0xc,%esp
80104915:	56                   	push   %esi
80104916:	e8 9f ce ff ff       	call   801017ba <iunlockput>
    goto bad;
8010491b:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010491e:	83 ec 0c             	sub    $0xc,%esp
80104921:	53                   	push   %ebx
80104922:	e8 e0 cc ff ff       	call   80101607 <ilock>
  ip->nlink--;
80104927:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010492b:	83 e8 01             	sub    $0x1,%eax
8010492e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104932:	89 1c 24             	mov    %ebx,(%esp)
80104935:	e8 64 cb ff ff       	call   8010149e <iupdate>
  iunlockput(ip);
8010493a:	89 1c 24             	mov    %ebx,(%esp)
8010493d:	e8 78 ce ff ff       	call   801017ba <iunlockput>
  end_op();
80104942:	e8 c3 df ff ff       	call   8010290a <end_op>
  return -1;
80104947:	83 c4 10             	add    $0x10,%esp
8010494a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010494f:	eb 8f                	jmp    801048e0 <sys_link+0xee>

80104951 <sys_unlink>:
{
80104951:	f3 0f 1e fb          	endbr32 
80104955:	55                   	push   %ebp
80104956:	89 e5                	mov    %esp,%ebp
80104958:	57                   	push   %edi
80104959:	56                   	push   %esi
8010495a:	53                   	push   %ebx
8010495b:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
8010495e:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104961:	50                   	push   %eax
80104962:	6a 00                	push   $0x0
80104964:	e8 e3 f9 ff ff       	call   8010434c <argstr>
80104969:	83 c4 10             	add    $0x10,%esp
8010496c:	85 c0                	test   %eax,%eax
8010496e:	0f 88 83 01 00 00    	js     80104af7 <sys_unlink+0x1a6>
  begin_op();
80104974:	e8 13 df ff ff       	call   8010288c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104979:	83 ec 08             	sub    $0x8,%esp
8010497c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010497f:	50                   	push   %eax
80104980:	ff 75 c4             	pushl  -0x3c(%ebp)
80104983:	e8 20 d3 ff ff       	call   80101ca8 <nameiparent>
80104988:	89 c6                	mov    %eax,%esi
8010498a:	83 c4 10             	add    $0x10,%esp
8010498d:	85 c0                	test   %eax,%eax
8010498f:	0f 84 ed 00 00 00    	je     80104a82 <sys_unlink+0x131>
  ilock(dp);
80104995:	83 ec 0c             	sub    $0xc,%esp
80104998:	50                   	push   %eax
80104999:	e8 69 cc ff ff       	call   80101607 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010499e:	83 c4 08             	add    $0x8,%esp
801049a1:	68 9a 71 10 80       	push   $0x8010719a
801049a6:	8d 45 ca             	lea    -0x36(%ebp),%eax
801049a9:	50                   	push   %eax
801049aa:	e8 8e d0 ff ff       	call   80101a3d <namecmp>
801049af:	83 c4 10             	add    $0x10,%esp
801049b2:	85 c0                	test   %eax,%eax
801049b4:	0f 84 fc 00 00 00    	je     80104ab6 <sys_unlink+0x165>
801049ba:	83 ec 08             	sub    $0x8,%esp
801049bd:	68 99 71 10 80       	push   $0x80107199
801049c2:	8d 45 ca             	lea    -0x36(%ebp),%eax
801049c5:	50                   	push   %eax
801049c6:	e8 72 d0 ff ff       	call   80101a3d <namecmp>
801049cb:	83 c4 10             	add    $0x10,%esp
801049ce:	85 c0                	test   %eax,%eax
801049d0:	0f 84 e0 00 00 00    	je     80104ab6 <sys_unlink+0x165>
  if((ip = dirlookup(dp, name, &off)) == 0)
801049d6:	83 ec 04             	sub    $0x4,%esp
801049d9:	8d 45 c0             	lea    -0x40(%ebp),%eax
801049dc:	50                   	push   %eax
801049dd:	8d 45 ca             	lea    -0x36(%ebp),%eax
801049e0:	50                   	push   %eax
801049e1:	56                   	push   %esi
801049e2:	e8 6f d0 ff ff       	call   80101a56 <dirlookup>
801049e7:	89 c3                	mov    %eax,%ebx
801049e9:	83 c4 10             	add    $0x10,%esp
801049ec:	85 c0                	test   %eax,%eax
801049ee:	0f 84 c2 00 00 00    	je     80104ab6 <sys_unlink+0x165>
  ilock(ip);
801049f4:	83 ec 0c             	sub    $0xc,%esp
801049f7:	50                   	push   %eax
801049f8:	e8 0a cc ff ff       	call   80101607 <ilock>
  if(ip->nlink < 1)
801049fd:	83 c4 10             	add    $0x10,%esp
80104a00:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104a05:	0f 8e 83 00 00 00    	jle    80104a8e <sys_unlink+0x13d>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104a0b:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a10:	0f 84 85 00 00 00    	je     80104a9b <sys_unlink+0x14a>
  memset(&de, 0, sizeof(de));
80104a16:	83 ec 04             	sub    $0x4,%esp
80104a19:	6a 10                	push   $0x10
80104a1b:	6a 00                	push   $0x0
80104a1d:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104a20:	57                   	push   %edi
80104a21:	e8 18 f6 ff ff       	call   8010403e <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104a26:	6a 10                	push   $0x10
80104a28:	ff 75 c0             	pushl  -0x40(%ebp)
80104a2b:	57                   	push   %edi
80104a2c:	56                   	push   %esi
80104a2d:	e8 dc ce ff ff       	call   8010190e <writei>
80104a32:	83 c4 20             	add    $0x20,%esp
80104a35:	83 f8 10             	cmp    $0x10,%eax
80104a38:	0f 85 90 00 00 00    	jne    80104ace <sys_unlink+0x17d>
  if(ip->type == T_DIR){
80104a3e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a43:	0f 84 92 00 00 00    	je     80104adb <sys_unlink+0x18a>
  iunlockput(dp);
80104a49:	83 ec 0c             	sub    $0xc,%esp
80104a4c:	56                   	push   %esi
80104a4d:	e8 68 cd ff ff       	call   801017ba <iunlockput>
  ip->nlink--;
80104a52:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104a56:	83 e8 01             	sub    $0x1,%eax
80104a59:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104a5d:	89 1c 24             	mov    %ebx,(%esp)
80104a60:	e8 39 ca ff ff       	call   8010149e <iupdate>
  iunlockput(ip);
80104a65:	89 1c 24             	mov    %ebx,(%esp)
80104a68:	e8 4d cd ff ff       	call   801017ba <iunlockput>
  end_op();
80104a6d:	e8 98 de ff ff       	call   8010290a <end_op>
  return 0;
80104a72:	83 c4 10             	add    $0x10,%esp
80104a75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a7d:	5b                   	pop    %ebx
80104a7e:	5e                   	pop    %esi
80104a7f:	5f                   	pop    %edi
80104a80:	5d                   	pop    %ebp
80104a81:	c3                   	ret    
    end_op();
80104a82:	e8 83 de ff ff       	call   8010290a <end_op>
    return -1;
80104a87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a8c:	eb ec                	jmp    80104a7a <sys_unlink+0x129>
    panic("unlink: nlink < 1");
80104a8e:	83 ec 0c             	sub    $0xc,%esp
80104a91:	68 b8 71 10 80       	push   $0x801071b8
80104a96:	e8 c1 b8 ff ff       	call   8010035c <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104a9b:	89 d8                	mov    %ebx,%eax
80104a9d:	e8 d3 f9 ff ff       	call   80104475 <isdirempty>
80104aa2:	85 c0                	test   %eax,%eax
80104aa4:	0f 85 6c ff ff ff    	jne    80104a16 <sys_unlink+0xc5>
    iunlockput(ip);
80104aaa:	83 ec 0c             	sub    $0xc,%esp
80104aad:	53                   	push   %ebx
80104aae:	e8 07 cd ff ff       	call   801017ba <iunlockput>
    goto bad;
80104ab3:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104ab6:	83 ec 0c             	sub    $0xc,%esp
80104ab9:	56                   	push   %esi
80104aba:	e8 fb cc ff ff       	call   801017ba <iunlockput>
  end_op();
80104abf:	e8 46 de ff ff       	call   8010290a <end_op>
  return -1;
80104ac4:	83 c4 10             	add    $0x10,%esp
80104ac7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104acc:	eb ac                	jmp    80104a7a <sys_unlink+0x129>
    panic("unlink: writei");
80104ace:	83 ec 0c             	sub    $0xc,%esp
80104ad1:	68 ca 71 10 80       	push   $0x801071ca
80104ad6:	e8 81 b8 ff ff       	call   8010035c <panic>
    dp->nlink--;
80104adb:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104adf:	83 e8 01             	sub    $0x1,%eax
80104ae2:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104ae6:	83 ec 0c             	sub    $0xc,%esp
80104ae9:	56                   	push   %esi
80104aea:	e8 af c9 ff ff       	call   8010149e <iupdate>
80104aef:	83 c4 10             	add    $0x10,%esp
80104af2:	e9 52 ff ff ff       	jmp    80104a49 <sys_unlink+0xf8>
    return -1;
80104af7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104afc:	e9 79 ff ff ff       	jmp    80104a7a <sys_unlink+0x129>

80104b01 <sys_open>:

int
sys_open(void)
{
80104b01:	f3 0f 1e fb          	endbr32 
80104b05:	55                   	push   %ebp
80104b06:	89 e5                	mov    %esp,%ebp
80104b08:	57                   	push   %edi
80104b09:	56                   	push   %esi
80104b0a:	53                   	push   %ebx
80104b0b:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104b0e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104b11:	50                   	push   %eax
80104b12:	6a 00                	push   $0x0
80104b14:	e8 33 f8 ff ff       	call   8010434c <argstr>
80104b19:	83 c4 10             	add    $0x10,%esp
80104b1c:	85 c0                	test   %eax,%eax
80104b1e:	0f 88 a0 00 00 00    	js     80104bc4 <sys_open+0xc3>
80104b24:	83 ec 08             	sub    $0x8,%esp
80104b27:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104b2a:	50                   	push   %eax
80104b2b:	6a 01                	push   $0x1
80104b2d:	e8 82 f7 ff ff       	call   801042b4 <argint>
80104b32:	83 c4 10             	add    $0x10,%esp
80104b35:	85 c0                	test   %eax,%eax
80104b37:	0f 88 87 00 00 00    	js     80104bc4 <sys_open+0xc3>
    return -1;

  begin_op();
80104b3d:	e8 4a dd ff ff       	call   8010288c <begin_op>

  if(omode & O_CREATE){
80104b42:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104b46:	0f 84 8b 00 00 00    	je     80104bd7 <sys_open+0xd6>
    ip = create(path, T_FILE, 0, 0);
80104b4c:	83 ec 0c             	sub    $0xc,%esp
80104b4f:	6a 00                	push   $0x0
80104b51:	b9 00 00 00 00       	mov    $0x0,%ecx
80104b56:	ba 02 00 00 00       	mov    $0x2,%edx
80104b5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104b5e:	e8 69 f9 ff ff       	call   801044cc <create>
80104b63:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104b65:	83 c4 10             	add    $0x10,%esp
80104b68:	85 c0                	test   %eax,%eax
80104b6a:	74 5f                	je     80104bcb <sys_open+0xca>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104b6c:	e8 15 c1 ff ff       	call   80100c86 <filealloc>
80104b71:	89 c3                	mov    %eax,%ebx
80104b73:	85 c0                	test   %eax,%eax
80104b75:	0f 84 b5 00 00 00    	je     80104c30 <sys_open+0x12f>
80104b7b:	e8 be f8 ff ff       	call   8010443e <fdalloc>
80104b80:	89 c7                	mov    %eax,%edi
80104b82:	85 c0                	test   %eax,%eax
80104b84:	0f 88 a6 00 00 00    	js     80104c30 <sys_open+0x12f>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104b8a:	83 ec 0c             	sub    $0xc,%esp
80104b8d:	56                   	push   %esi
80104b8e:	e8 3a cb ff ff       	call   801016cd <iunlock>
  end_op();
80104b93:	e8 72 dd ff ff       	call   8010290a <end_op>

  f->type = FD_INODE;
80104b98:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104b9e:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104ba1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104ba8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104bab:	83 c4 10             	add    $0x10,%esp
80104bae:	a8 01                	test   $0x1,%al
80104bb0:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104bb4:	a8 03                	test   $0x3,%al
80104bb6:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104bba:	89 f8                	mov    %edi,%eax
80104bbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104bbf:	5b                   	pop    %ebx
80104bc0:	5e                   	pop    %esi
80104bc1:	5f                   	pop    %edi
80104bc2:	5d                   	pop    %ebp
80104bc3:	c3                   	ret    
    return -1;
80104bc4:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104bc9:	eb ef                	jmp    80104bba <sys_open+0xb9>
      end_op();
80104bcb:	e8 3a dd ff ff       	call   8010290a <end_op>
      return -1;
80104bd0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104bd5:	eb e3                	jmp    80104bba <sys_open+0xb9>
    if((ip = namei(path)) == 0){
80104bd7:	83 ec 0c             	sub    $0xc,%esp
80104bda:	ff 75 e4             	pushl  -0x1c(%ebp)
80104bdd:	e8 aa d0 ff ff       	call   80101c8c <namei>
80104be2:	89 c6                	mov    %eax,%esi
80104be4:	83 c4 10             	add    $0x10,%esp
80104be7:	85 c0                	test   %eax,%eax
80104be9:	74 39                	je     80104c24 <sys_open+0x123>
    ilock(ip);
80104beb:	83 ec 0c             	sub    $0xc,%esp
80104bee:	50                   	push   %eax
80104bef:	e8 13 ca ff ff       	call   80101607 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104bf4:	83 c4 10             	add    $0x10,%esp
80104bf7:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104bfc:	0f 85 6a ff ff ff    	jne    80104b6c <sys_open+0x6b>
80104c02:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104c06:	0f 84 60 ff ff ff    	je     80104b6c <sys_open+0x6b>
      iunlockput(ip);
80104c0c:	83 ec 0c             	sub    $0xc,%esp
80104c0f:	56                   	push   %esi
80104c10:	e8 a5 cb ff ff       	call   801017ba <iunlockput>
      end_op();
80104c15:	e8 f0 dc ff ff       	call   8010290a <end_op>
      return -1;
80104c1a:	83 c4 10             	add    $0x10,%esp
80104c1d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c22:	eb 96                	jmp    80104bba <sys_open+0xb9>
      end_op();
80104c24:	e8 e1 dc ff ff       	call   8010290a <end_op>
      return -1;
80104c29:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c2e:	eb 8a                	jmp    80104bba <sys_open+0xb9>
    if(f)
80104c30:	85 db                	test   %ebx,%ebx
80104c32:	74 0c                	je     80104c40 <sys_open+0x13f>
      fileclose(f);
80104c34:	83 ec 0c             	sub    $0xc,%esp
80104c37:	53                   	push   %ebx
80104c38:	e8 f7 c0 ff ff       	call   80100d34 <fileclose>
80104c3d:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104c40:	83 ec 0c             	sub    $0xc,%esp
80104c43:	56                   	push   %esi
80104c44:	e8 71 cb ff ff       	call   801017ba <iunlockput>
    end_op();
80104c49:	e8 bc dc ff ff       	call   8010290a <end_op>
    return -1;
80104c4e:	83 c4 10             	add    $0x10,%esp
80104c51:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104c56:	e9 5f ff ff ff       	jmp    80104bba <sys_open+0xb9>

80104c5b <sys_mkdir>:

int
sys_mkdir(void)
{
80104c5b:	f3 0f 1e fb          	endbr32 
80104c5f:	55                   	push   %ebp
80104c60:	89 e5                	mov    %esp,%ebp
80104c62:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104c65:	e8 22 dc ff ff       	call   8010288c <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104c6a:	83 ec 08             	sub    $0x8,%esp
80104c6d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c70:	50                   	push   %eax
80104c71:	6a 00                	push   $0x0
80104c73:	e8 d4 f6 ff ff       	call   8010434c <argstr>
80104c78:	83 c4 10             	add    $0x10,%esp
80104c7b:	85 c0                	test   %eax,%eax
80104c7d:	78 36                	js     80104cb5 <sys_mkdir+0x5a>
80104c7f:	83 ec 0c             	sub    $0xc,%esp
80104c82:	6a 00                	push   $0x0
80104c84:	b9 00 00 00 00       	mov    $0x0,%ecx
80104c89:	ba 01 00 00 00       	mov    $0x1,%edx
80104c8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c91:	e8 36 f8 ff ff       	call   801044cc <create>
80104c96:	83 c4 10             	add    $0x10,%esp
80104c99:	85 c0                	test   %eax,%eax
80104c9b:	74 18                	je     80104cb5 <sys_mkdir+0x5a>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104c9d:	83 ec 0c             	sub    $0xc,%esp
80104ca0:	50                   	push   %eax
80104ca1:	e8 14 cb ff ff       	call   801017ba <iunlockput>
  end_op();
80104ca6:	e8 5f dc ff ff       	call   8010290a <end_op>
  return 0;
80104cab:	83 c4 10             	add    $0x10,%esp
80104cae:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104cb3:	c9                   	leave  
80104cb4:	c3                   	ret    
    end_op();
80104cb5:	e8 50 dc ff ff       	call   8010290a <end_op>
    return -1;
80104cba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cbf:	eb f2                	jmp    80104cb3 <sys_mkdir+0x58>

80104cc1 <sys_mknod>:

int
sys_mknod(void)
{
80104cc1:	f3 0f 1e fb          	endbr32 
80104cc5:	55                   	push   %ebp
80104cc6:	89 e5                	mov    %esp,%ebp
80104cc8:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104ccb:	e8 bc db ff ff       	call   8010288c <begin_op>
  if((argstr(0, &path)) < 0 ||
80104cd0:	83 ec 08             	sub    $0x8,%esp
80104cd3:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cd6:	50                   	push   %eax
80104cd7:	6a 00                	push   $0x0
80104cd9:	e8 6e f6 ff ff       	call   8010434c <argstr>
80104cde:	83 c4 10             	add    $0x10,%esp
80104ce1:	85 c0                	test   %eax,%eax
80104ce3:	78 62                	js     80104d47 <sys_mknod+0x86>
     argint(1, &major) < 0 ||
80104ce5:	83 ec 08             	sub    $0x8,%esp
80104ce8:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ceb:	50                   	push   %eax
80104cec:	6a 01                	push   $0x1
80104cee:	e8 c1 f5 ff ff       	call   801042b4 <argint>
  if((argstr(0, &path)) < 0 ||
80104cf3:	83 c4 10             	add    $0x10,%esp
80104cf6:	85 c0                	test   %eax,%eax
80104cf8:	78 4d                	js     80104d47 <sys_mknod+0x86>
     argint(2, &minor) < 0 ||
80104cfa:	83 ec 08             	sub    $0x8,%esp
80104cfd:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d00:	50                   	push   %eax
80104d01:	6a 02                	push   $0x2
80104d03:	e8 ac f5 ff ff       	call   801042b4 <argint>
     argint(1, &major) < 0 ||
80104d08:	83 c4 10             	add    $0x10,%esp
80104d0b:	85 c0                	test   %eax,%eax
80104d0d:	78 38                	js     80104d47 <sys_mknod+0x86>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104d0f:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
80104d13:	83 ec 0c             	sub    $0xc,%esp
80104d16:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104d1a:	50                   	push   %eax
80104d1b:	ba 03 00 00 00       	mov    $0x3,%edx
80104d20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d23:	e8 a4 f7 ff ff       	call   801044cc <create>
     argint(2, &minor) < 0 ||
80104d28:	83 c4 10             	add    $0x10,%esp
80104d2b:	85 c0                	test   %eax,%eax
80104d2d:	74 18                	je     80104d47 <sys_mknod+0x86>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104d2f:	83 ec 0c             	sub    $0xc,%esp
80104d32:	50                   	push   %eax
80104d33:	e8 82 ca ff ff       	call   801017ba <iunlockput>
  end_op();
80104d38:	e8 cd db ff ff       	call   8010290a <end_op>
  return 0;
80104d3d:	83 c4 10             	add    $0x10,%esp
80104d40:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d45:	c9                   	leave  
80104d46:	c3                   	ret    
    end_op();
80104d47:	e8 be db ff ff       	call   8010290a <end_op>
    return -1;
80104d4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d51:	eb f2                	jmp    80104d45 <sys_mknod+0x84>

80104d53 <sys_chdir>:

int
sys_chdir(void)
{
80104d53:	f3 0f 1e fb          	endbr32 
80104d57:	55                   	push   %ebp
80104d58:	89 e5                	mov    %esp,%ebp
80104d5a:	56                   	push   %esi
80104d5b:	53                   	push   %ebx
80104d5c:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104d5f:	e8 d4 e5 ff ff       	call   80103338 <myproc>
80104d64:	89 c6                	mov    %eax,%esi

  begin_op();
80104d66:	e8 21 db ff ff       	call   8010288c <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104d6b:	83 ec 08             	sub    $0x8,%esp
80104d6e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d71:	50                   	push   %eax
80104d72:	6a 00                	push   $0x0
80104d74:	e8 d3 f5 ff ff       	call   8010434c <argstr>
80104d79:	83 c4 10             	add    $0x10,%esp
80104d7c:	85 c0                	test   %eax,%eax
80104d7e:	78 52                	js     80104dd2 <sys_chdir+0x7f>
80104d80:	83 ec 0c             	sub    $0xc,%esp
80104d83:	ff 75 f4             	pushl  -0xc(%ebp)
80104d86:	e8 01 cf ff ff       	call   80101c8c <namei>
80104d8b:	89 c3                	mov    %eax,%ebx
80104d8d:	83 c4 10             	add    $0x10,%esp
80104d90:	85 c0                	test   %eax,%eax
80104d92:	74 3e                	je     80104dd2 <sys_chdir+0x7f>
    end_op();
    return -1;
  }
  ilock(ip);
80104d94:	83 ec 0c             	sub    $0xc,%esp
80104d97:	50                   	push   %eax
80104d98:	e8 6a c8 ff ff       	call   80101607 <ilock>
  if(ip->type != T_DIR){
80104d9d:	83 c4 10             	add    $0x10,%esp
80104da0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104da5:	75 37                	jne    80104dde <sys_chdir+0x8b>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104da7:	83 ec 0c             	sub    $0xc,%esp
80104daa:	53                   	push   %ebx
80104dab:	e8 1d c9 ff ff       	call   801016cd <iunlock>
  iput(curproc->cwd);
80104db0:	83 c4 04             	add    $0x4,%esp
80104db3:	ff 76 68             	pushl  0x68(%esi)
80104db6:	e8 5b c9 ff ff       	call   80101716 <iput>
  end_op();
80104dbb:	e8 4a db ff ff       	call   8010290a <end_op>
  curproc->cwd = ip;
80104dc0:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104dc3:	83 c4 10             	add    $0x10,%esp
80104dc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104dcb:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104dce:	5b                   	pop    %ebx
80104dcf:	5e                   	pop    %esi
80104dd0:	5d                   	pop    %ebp
80104dd1:	c3                   	ret    
    end_op();
80104dd2:	e8 33 db ff ff       	call   8010290a <end_op>
    return -1;
80104dd7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ddc:	eb ed                	jmp    80104dcb <sys_chdir+0x78>
    iunlockput(ip);
80104dde:	83 ec 0c             	sub    $0xc,%esp
80104de1:	53                   	push   %ebx
80104de2:	e8 d3 c9 ff ff       	call   801017ba <iunlockput>
    end_op();
80104de7:	e8 1e db ff ff       	call   8010290a <end_op>
    return -1;
80104dec:	83 c4 10             	add    $0x10,%esp
80104def:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104df4:	eb d5                	jmp    80104dcb <sys_chdir+0x78>

80104df6 <sys_exec>:

int
sys_exec(void)
{
80104df6:	f3 0f 1e fb          	endbr32 
80104dfa:	55                   	push   %ebp
80104dfb:	89 e5                	mov    %esp,%ebp
80104dfd:	53                   	push   %ebx
80104dfe:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104e04:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e07:	50                   	push   %eax
80104e08:	6a 00                	push   $0x0
80104e0a:	e8 3d f5 ff ff       	call   8010434c <argstr>
80104e0f:	83 c4 10             	add    $0x10,%esp
80104e12:	85 c0                	test   %eax,%eax
80104e14:	78 38                	js     80104e4e <sys_exec+0x58>
80104e16:	83 ec 08             	sub    $0x8,%esp
80104e19:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104e1f:	50                   	push   %eax
80104e20:	6a 01                	push   $0x1
80104e22:	e8 8d f4 ff ff       	call   801042b4 <argint>
80104e27:	83 c4 10             	add    $0x10,%esp
80104e2a:	85 c0                	test   %eax,%eax
80104e2c:	78 20                	js     80104e4e <sys_exec+0x58>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104e2e:	83 ec 04             	sub    $0x4,%esp
80104e31:	68 80 00 00 00       	push   $0x80
80104e36:	6a 00                	push   $0x0
80104e38:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104e3e:	50                   	push   %eax
80104e3f:	e8 fa f1 ff ff       	call   8010403e <memset>
80104e44:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104e47:	bb 00 00 00 00       	mov    $0x0,%ebx
80104e4c:	eb 2c                	jmp    80104e7a <sys_exec+0x84>
    return -1;
80104e4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e53:	eb 78                	jmp    80104ecd <sys_exec+0xd7>
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
80104e55:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104e5c:	00 00 00 00 
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80104e60:	83 ec 08             	sub    $0x8,%esp
80104e63:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104e69:	50                   	push   %eax
80104e6a:	ff 75 f4             	pushl  -0xc(%ebp)
80104e6d:	e8 c9 ba ff ff       	call   8010093b <exec>
80104e72:	83 c4 10             	add    $0x10,%esp
80104e75:	eb 56                	jmp    80104ecd <sys_exec+0xd7>
  for(i=0;; i++){
80104e77:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104e7a:	83 fb 1f             	cmp    $0x1f,%ebx
80104e7d:	77 49                	ja     80104ec8 <sys_exec+0xd2>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104e7f:	83 ec 08             	sub    $0x8,%esp
80104e82:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104e88:	50                   	push   %eax
80104e89:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104e8f:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104e92:	50                   	push   %eax
80104e93:	e8 98 f3 ff ff       	call   80104230 <fetchint>
80104e98:	83 c4 10             	add    $0x10,%esp
80104e9b:	85 c0                	test   %eax,%eax
80104e9d:	78 33                	js     80104ed2 <sys_exec+0xdc>
    if(uarg == 0){
80104e9f:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104ea5:	85 c0                	test   %eax,%eax
80104ea7:	74 ac                	je     80104e55 <sys_exec+0x5f>
    if(fetchstr(uarg, &argv[i]) < 0)
80104ea9:	83 ec 08             	sub    $0x8,%esp
80104eac:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104eb3:	52                   	push   %edx
80104eb4:	50                   	push   %eax
80104eb5:	e8 b6 f3 ff ff       	call   80104270 <fetchstr>
80104eba:	83 c4 10             	add    $0x10,%esp
80104ebd:	85 c0                	test   %eax,%eax
80104ebf:	79 b6                	jns    80104e77 <sys_exec+0x81>
      return -1;
80104ec1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ec6:	eb 05                	jmp    80104ecd <sys_exec+0xd7>
      return -1;
80104ec8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104ecd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ed0:	c9                   	leave  
80104ed1:	c3                   	ret    
      return -1;
80104ed2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ed7:	eb f4                	jmp    80104ecd <sys_exec+0xd7>

80104ed9 <sys_pipe>:

int
sys_pipe(void)
{
80104ed9:	f3 0f 1e fb          	endbr32 
80104edd:	55                   	push   %ebp
80104ede:	89 e5                	mov    %esp,%ebp
80104ee0:	53                   	push   %ebx
80104ee1:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104ee4:	6a 08                	push   $0x8
80104ee6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ee9:	50                   	push   %eax
80104eea:	6a 00                	push   $0x0
80104eec:	e8 ef f3 ff ff       	call   801042e0 <argptr>
80104ef1:	83 c4 10             	add    $0x10,%esp
80104ef4:	85 c0                	test   %eax,%eax
80104ef6:	78 79                	js     80104f71 <sys_pipe+0x98>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104ef8:	83 ec 08             	sub    $0x8,%esp
80104efb:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104efe:	50                   	push   %eax
80104eff:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f02:	50                   	push   %eax
80104f03:	e8 29 df ff ff       	call   80102e31 <pipealloc>
80104f08:	83 c4 10             	add    $0x10,%esp
80104f0b:	85 c0                	test   %eax,%eax
80104f0d:	78 69                	js     80104f78 <sys_pipe+0x9f>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104f0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f12:	e8 27 f5 ff ff       	call   8010443e <fdalloc>
80104f17:	89 c3                	mov    %eax,%ebx
80104f19:	85 c0                	test   %eax,%eax
80104f1b:	78 21                	js     80104f3e <sys_pipe+0x65>
80104f1d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104f20:	e8 19 f5 ff ff       	call   8010443e <fdalloc>
80104f25:	85 c0                	test   %eax,%eax
80104f27:	78 15                	js     80104f3e <sys_pipe+0x65>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104f29:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f2c:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104f2e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104f31:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104f34:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f39:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f3c:	c9                   	leave  
80104f3d:	c3                   	ret    
    if(fd0 >= 0)
80104f3e:	85 db                	test   %ebx,%ebx
80104f40:	79 20                	jns    80104f62 <sys_pipe+0x89>
    fileclose(rf);
80104f42:	83 ec 0c             	sub    $0xc,%esp
80104f45:	ff 75 f0             	pushl  -0x10(%ebp)
80104f48:	e8 e7 bd ff ff       	call   80100d34 <fileclose>
    fileclose(wf);
80104f4d:	83 c4 04             	add    $0x4,%esp
80104f50:	ff 75 ec             	pushl  -0x14(%ebp)
80104f53:	e8 dc bd ff ff       	call   80100d34 <fileclose>
    return -1;
80104f58:	83 c4 10             	add    $0x10,%esp
80104f5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f60:	eb d7                	jmp    80104f39 <sys_pipe+0x60>
      myproc()->ofile[fd0] = 0;
80104f62:	e8 d1 e3 ff ff       	call   80103338 <myproc>
80104f67:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104f6e:	00 
80104f6f:	eb d1                	jmp    80104f42 <sys_pipe+0x69>
    return -1;
80104f71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f76:	eb c1                	jmp    80104f39 <sys_pipe+0x60>
    return -1;
80104f78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f7d:	eb ba                	jmp    80104f39 <sys_pipe+0x60>

80104f7f <sys_fork>:
  #include "uproc.h"
#endif  // CS333_P2

int
sys_fork(void)
{
80104f7f:	f3 0f 1e fb          	endbr32 
80104f83:	55                   	push   %ebp
80104f84:	89 e5                	mov    %esp,%ebp
80104f86:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104f89:	e8 41 e5 ff ff       	call   801034cf <fork>
}
80104f8e:	c9                   	leave  
80104f8f:	c3                   	ret    

80104f90 <sys_exit>:

int
sys_exit(void)
{
80104f90:	f3 0f 1e fb          	endbr32 
80104f94:	55                   	push   %ebp
80104f95:	89 e5                	mov    %esp,%ebp
80104f97:	83 ec 08             	sub    $0x8,%esp
  exit();
80104f9a:	e8 bc e7 ff ff       	call   8010375b <exit>
  return 0;  // not reached
}
80104f9f:	b8 00 00 00 00       	mov    $0x0,%eax
80104fa4:	c9                   	leave  
80104fa5:	c3                   	ret    

80104fa6 <sys_wait>:

int
sys_wait(void)
{
80104fa6:	f3 0f 1e fb          	endbr32 
80104faa:	55                   	push   %ebp
80104fab:	89 e5                	mov    %esp,%ebp
80104fad:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104fb0:	e8 4c e9 ff ff       	call   80103901 <wait>
}
80104fb5:	c9                   	leave  
80104fb6:	c3                   	ret    

80104fb7 <sys_kill>:

int
sys_kill(void)
{
80104fb7:	f3 0f 1e fb          	endbr32 
80104fbb:	55                   	push   %ebp
80104fbc:	89 e5                	mov    %esp,%ebp
80104fbe:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104fc1:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fc4:	50                   	push   %eax
80104fc5:	6a 00                	push   $0x0
80104fc7:	e8 e8 f2 ff ff       	call   801042b4 <argint>
80104fcc:	83 c4 10             	add    $0x10,%esp
80104fcf:	85 c0                	test   %eax,%eax
80104fd1:	78 10                	js     80104fe3 <sys_kill+0x2c>
    return -1;
  return kill(pid);
80104fd3:	83 ec 0c             	sub    $0xc,%esp
80104fd6:	ff 75 f4             	pushl  -0xc(%ebp)
80104fd9:	e8 2b ea ff ff       	call   80103a09 <kill>
80104fde:	83 c4 10             	add    $0x10,%esp
}
80104fe1:	c9                   	leave  
80104fe2:	c3                   	ret    
    return -1;
80104fe3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fe8:	eb f7                	jmp    80104fe1 <sys_kill+0x2a>

80104fea <sys_getpid>:

int
sys_getpid(void)
{
80104fea:	f3 0f 1e fb          	endbr32 
80104fee:	55                   	push   %ebp
80104fef:	89 e5                	mov    %esp,%ebp
80104ff1:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104ff4:	e8 3f e3 ff ff       	call   80103338 <myproc>
80104ff9:	8b 40 10             	mov    0x10(%eax),%eax
}
80104ffc:	c9                   	leave  
80104ffd:	c3                   	ret    

80104ffe <sys_sbrk>:

int
sys_sbrk(void)
{
80104ffe:	f3 0f 1e fb          	endbr32 
80105002:	55                   	push   %ebp
80105003:	89 e5                	mov    %esp,%ebp
80105005:	53                   	push   %ebx
80105006:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80105009:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010500c:	50                   	push   %eax
8010500d:	6a 00                	push   $0x0
8010500f:	e8 a0 f2 ff ff       	call   801042b4 <argint>
80105014:	83 c4 10             	add    $0x10,%esp
80105017:	85 c0                	test   %eax,%eax
80105019:	78 20                	js     8010503b <sys_sbrk+0x3d>
    return -1;
  addr = myproc()->sz;
8010501b:	e8 18 e3 ff ff       	call   80103338 <myproc>
80105020:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80105022:	83 ec 0c             	sub    $0xc,%esp
80105025:	ff 75 f4             	pushl  -0xc(%ebp)
80105028:	e8 33 e4 ff ff       	call   80103460 <growproc>
8010502d:	83 c4 10             	add    $0x10,%esp
80105030:	85 c0                	test   %eax,%eax
80105032:	78 0e                	js     80105042 <sys_sbrk+0x44>
    return -1;
  return addr;
}
80105034:	89 d8                	mov    %ebx,%eax
80105036:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105039:	c9                   	leave  
8010503a:	c3                   	ret    
    return -1;
8010503b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80105040:	eb f2                	jmp    80105034 <sys_sbrk+0x36>
    return -1;
80105042:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80105047:	eb eb                	jmp    80105034 <sys_sbrk+0x36>

80105049 <sys_sleep>:

int
sys_sleep(void)
{
80105049:	f3 0f 1e fb          	endbr32 
8010504d:	55                   	push   %ebp
8010504e:	89 e5                	mov    %esp,%ebp
80105050:	53                   	push   %ebx
80105051:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80105054:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105057:	50                   	push   %eax
80105058:	6a 00                	push   $0x0
8010505a:	e8 55 f2 ff ff       	call   801042b4 <argint>
8010505f:	83 c4 10             	add    $0x10,%esp
80105062:	85 c0                	test   %eax,%eax
80105064:	78 3b                	js     801050a1 <sys_sleep+0x58>
    return -1;
  ticks0 = ticks;
80105066:	8b 1d 80 59 11 80    	mov    0x80115980,%ebx
  while(ticks - ticks0 < n){
8010506c:	a1 80 59 11 80       	mov    0x80115980,%eax
80105071:	29 d8                	sub    %ebx,%eax
80105073:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105076:	73 1f                	jae    80105097 <sys_sleep+0x4e>
    if(myproc()->killed){
80105078:	e8 bb e2 ff ff       	call   80103338 <myproc>
8010507d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105081:	75 25                	jne    801050a8 <sys_sleep+0x5f>
      return -1;
    }
    sleep(&ticks, (struct spinlock *)0);
80105083:	83 ec 08             	sub    $0x8,%esp
80105086:	6a 00                	push   $0x0
80105088:	68 80 59 11 80       	push   $0x80115980
8010508d:	e8 db e7 ff ff       	call   8010386d <sleep>
80105092:	83 c4 10             	add    $0x10,%esp
80105095:	eb d5                	jmp    8010506c <sys_sleep+0x23>
  }
  return 0;
80105097:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010509c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010509f:	c9                   	leave  
801050a0:	c3                   	ret    
    return -1;
801050a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050a6:	eb f4                	jmp    8010509c <sys_sleep+0x53>
      return -1;
801050a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801050ad:	eb ed                	jmp    8010509c <sys_sleep+0x53>

801050af <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801050af:	f3 0f 1e fb          	endbr32 
  uint xticks;

  xticks = ticks;
  return xticks;
}
801050b3:	a1 80 59 11 80       	mov    0x80115980,%eax
801050b8:	c3                   	ret    

801050b9 <sys_halt>:

#ifdef PDX_XV6
// shutdown QEMU
int
sys_halt(void)
{
801050b9:	f3 0f 1e fb          	endbr32 
801050bd:	55                   	push   %ebp
801050be:	89 e5                	mov    %esp,%ebp
801050c0:	83 ec 08             	sub    $0x8,%esp
  do_shutdown();  // never returns
801050c3:	e8 91 b6 ff ff       	call   80100759 <do_shutdown>
  return 0;
}
801050c8:	b8 00 00 00 00       	mov    $0x0,%eax
801050cd:	c9                   	leave  
801050ce:	c3                   	ret    

801050cf <sys_date>:
#endif // PDX_XV6

int
sys_date(void)
{
801050cf:	f3 0f 1e fb          	endbr32 
801050d3:	55                   	push   %ebp
801050d4:	89 e5                	mov    %esp,%ebp
801050d6:	83 ec 1c             	sub    $0x1c,%esp
  struct rtcdate *d;
  if(argptr(0, (void*)&d, sizeof(struct rtcdate)) <0)
801050d9:	6a 18                	push   $0x18
801050db:	8d 45 f4             	lea    -0xc(%ebp),%eax
801050de:	50                   	push   %eax
801050df:	6a 00                	push   $0x0
801050e1:	e8 fa f1 ff ff       	call   801042e0 <argptr>
801050e6:	83 c4 10             	add    $0x10,%esp
801050e9:	85 c0                	test   %eax,%eax
801050eb:	78 15                	js     80105102 <sys_date+0x33>
    return -1;
  else{
    cmostime(d);
801050ed:	83 ec 0c             	sub    $0xc,%esp
801050f0:	ff 75 f4             	pushl  -0xc(%ebp)
801050f3:	e8 41 d4 ff ff       	call   80102539 <cmostime>
    return 0;
801050f8:	83 c4 10             	add    $0x10,%esp
801050fb:	b8 00 00 00 00       	mov    $0x0,%eax
  }
}
80105100:	c9                   	leave  
80105101:	c3                   	ret    
    return -1;
80105102:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105107:	eb f7                	jmp    80105100 <sys_date+0x31>

80105109 <sys_getuid>:

#ifdef CS333_P2
int
sys_getuid(void)
{
80105109:	f3 0f 1e fb          	endbr32 
8010510d:	55                   	push   %ebp
8010510e:	89 e5                	mov    %esp,%ebp
80105110:	83 ec 08             	sub    $0x8,%esp
  struct proc *curproc = myproc();
80105113:	e8 20 e2 ff ff       	call   80103338 <myproc>
  return curproc->uid;
80105118:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
}
8010511e:	c9                   	leave  
8010511f:	c3                   	ret    

80105120 <sys_getgid>:

int
sys_getgid(void)
{
80105120:	f3 0f 1e fb          	endbr32 
80105124:	55                   	push   %ebp
80105125:	89 e5                	mov    %esp,%ebp
80105127:	83 ec 08             	sub    $0x8,%esp
  struct proc *curproc = myproc();
8010512a:	e8 09 e2 ff ff       	call   80103338 <myproc>
  return curproc->gid;
8010512f:	8b 80 84 00 00 00    	mov    0x84(%eax),%eax
}
80105135:	c9                   	leave  
80105136:	c3                   	ret    

80105137 <sys_getppid>:

int
sys_getppid(void)
{
80105137:	f3 0f 1e fb          	endbr32 
8010513b:	55                   	push   %ebp
8010513c:	89 e5                	mov    %esp,%ebp
8010513e:	83 ec 08             	sub    $0x8,%esp
  struct proc *curproc = myproc();
80105141:	e8 f2 e1 ff ff       	call   80103338 <myproc>
  struct proc *parent = curproc->parent;
80105146:	8b 40 14             	mov    0x14(%eax),%eax
  return parent != NULL ? parent->pid : 0;
80105149:	85 c0                	test   %eax,%eax
8010514b:	74 05                	je     80105152 <sys_getppid+0x1b>
8010514d:	8b 40 10             	mov    0x10(%eax),%eax
}
80105150:	c9                   	leave  
80105151:	c3                   	ret    
  return parent != NULL ? parent->pid : 0;
80105152:	b8 00 00 00 00       	mov    $0x0,%eax
80105157:	eb f7                	jmp    80105150 <sys_getppid+0x19>

80105159 <sys_setuid>:

int sys_setuid(void)
{
80105159:	f3 0f 1e fb          	endbr32 
8010515d:	55                   	push   %ebp
8010515e:	89 e5                	mov    %esp,%ebp
80105160:	53                   	push   %ebx
80105161:	83 ec 14             	sub    $0x14,%esp
  uint uid;
  struct proc *curproc = myproc();
80105164:	e8 cf e1 ff ff       	call   80103338 <myproc>
80105169:	89 c3                	mov    %eax,%ebx

  if(argint(0, (int*)&uid) >= 0) {
8010516b:	83 ec 08             	sub    $0x8,%esp
8010516e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105171:	50                   	push   %eax
80105172:	6a 00                	push   $0x0
80105174:	e8 3b f1 ff ff       	call   801042b4 <argint>
80105179:	83 c4 10             	add    $0x10,%esp
8010517c:	85 c0                	test   %eax,%eax
8010517e:	78 1a                	js     8010519a <sys_setuid+0x41>
    if(uid >= 0 && uid <= 32767) {
80105180:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105183:	3d ff 7f 00 00       	cmp    $0x7fff,%eax
80105188:	77 17                	ja     801051a1 <sys_setuid+0x48>
      curproc->uid = uid;
8010518a:	89 83 80 00 00 00    	mov    %eax,0x80(%ebx)
      return 0;
80105190:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }

  return -1;
}
80105195:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105198:	c9                   	leave  
80105199:	c3                   	ret    
  return -1;
8010519a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010519f:	eb f4                	jmp    80105195 <sys_setuid+0x3c>
801051a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051a6:	eb ed                	jmp    80105195 <sys_setuid+0x3c>

801051a8 <sys_setgid>:

int sys_setgid(void)
{
801051a8:	f3 0f 1e fb          	endbr32 
801051ac:	55                   	push   %ebp
801051ad:	89 e5                	mov    %esp,%ebp
801051af:	53                   	push   %ebx
801051b0:	83 ec 14             	sub    $0x14,%esp
  uint gid;
  struct proc *curproc = myproc();
801051b3:	e8 80 e1 ff ff       	call   80103338 <myproc>
801051b8:	89 c3                	mov    %eax,%ebx

  if(argint(0, (int*)&gid) >= 0) {
801051ba:	83 ec 08             	sub    $0x8,%esp
801051bd:	8d 45 f4             	lea    -0xc(%ebp),%eax
801051c0:	50                   	push   %eax
801051c1:	6a 00                	push   $0x0
801051c3:	e8 ec f0 ff ff       	call   801042b4 <argint>
801051c8:	83 c4 10             	add    $0x10,%esp
801051cb:	85 c0                	test   %eax,%eax
801051cd:	78 1a                	js     801051e9 <sys_setgid+0x41>
    if(gid >= 0 && gid <= 32767) {
801051cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801051d2:	3d ff 7f 00 00       	cmp    $0x7fff,%eax
801051d7:	77 17                	ja     801051f0 <sys_setgid+0x48>
      curproc->gid = gid;
801051d9:	89 83 84 00 00 00    	mov    %eax,0x84(%ebx)
      return 0;
801051df:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }

  return -1;
}
801051e4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051e7:	c9                   	leave  
801051e8:	c3                   	ret    
  return -1;
801051e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051ee:	eb f4                	jmp    801051e4 <sys_setgid+0x3c>
801051f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051f5:	eb ed                	jmp    801051e4 <sys_setgid+0x3c>

801051f7 <sys_getprocs>:

int sys_getprocs(void)
{
801051f7:	f3 0f 1e fb          	endbr32 
801051fb:	55                   	push   %ebp
801051fc:	89 e5                	mov    %esp,%ebp
801051fe:	83 ec 20             	sub    $0x20,%esp
  uint max;
  struct uproc* proc;

  if (argint(0,(int*)&max) >= 0) {
80105201:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105204:	50                   	push   %eax
80105205:	6a 00                	push   $0x0
80105207:	e8 a8 f0 ff ff       	call   801042b4 <argint>
8010520c:	83 c4 10             	add    $0x10,%esp
8010520f:	85 c0                	test   %eax,%eax
80105211:	78 47                	js     8010525a <sys_getprocs+0x63>
    if (max == 1 || max == 16 || max == 64 || max == 72) {
80105213:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105216:	83 f8 01             	cmp    $0x1,%eax
80105219:	0f 94 c1             	sete   %cl
8010521c:	83 f8 10             	cmp    $0x10,%eax
8010521f:	0f 94 c2             	sete   %dl
80105222:	08 d1                	or     %dl,%cl
80105224:	75 0a                	jne    80105230 <sys_getprocs+0x39>
80105226:	83 f8 40             	cmp    $0x40,%eax
80105229:	74 05                	je     80105230 <sys_getprocs+0x39>
8010522b:	83 f8 48             	cmp    $0x48,%eax
8010522e:	75 31                	jne    80105261 <sys_getprocs+0x6a>
      if (argptr(1, (void*)&proc, sizeof(struct uproc)) >= 0) {
80105230:	83 ec 04             	sub    $0x4,%esp
80105233:	6a 5c                	push   $0x5c
80105235:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105238:	50                   	push   %eax
80105239:	6a 01                	push   $0x1
8010523b:	e8 a0 f0 ff ff       	call   801042e0 <argptr>
80105240:	83 c4 10             	add    $0x10,%esp
80105243:	85 c0                	test   %eax,%eax
80105245:	78 21                	js     80105268 <sys_getprocs+0x71>
        return getprocs(max, proc);
80105247:	83 ec 08             	sub    $0x8,%esp
8010524a:	ff 75 f0             	pushl  -0x10(%ebp)
8010524d:	ff 75 f4             	pushl  -0xc(%ebp)
80105250:	e8 da e9 ff ff       	call   80103c2f <getprocs>
80105255:	83 c4 10             	add    $0x10,%esp
      }
    }
  }

  return -1;
}
80105258:	c9                   	leave  
80105259:	c3                   	ret    
  return -1;
8010525a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010525f:	eb f7                	jmp    80105258 <sys_getprocs+0x61>
80105261:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105266:	eb f0                	jmp    80105258 <sys_getprocs+0x61>
80105268:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010526d:	eb e9                	jmp    80105258 <sys_getprocs+0x61>

8010526f <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010526f:	1e                   	push   %ds
  pushl %es
80105270:	06                   	push   %es
  pushl %fs
80105271:	0f a0                	push   %fs
  pushl %gs
80105273:	0f a8                	push   %gs
  pushal
80105275:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80105276:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010527a:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010527c:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
8010527e:	54                   	push   %esp
  call trap
8010527f:	e8 cf 00 00 00       	call   80105353 <trap>
  addl $4, %esp
80105284:	83 c4 04             	add    $0x4,%esp

80105287 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80105287:	61                   	popa   
  popl %gs
80105288:	0f a9                	pop    %gs
  popl %fs
8010528a:	0f a1                	pop    %fs
  popl %es
8010528c:	07                   	pop    %es
  popl %ds
8010528d:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010528e:	83 c4 08             	add    $0x8,%esp
  iret
80105291:	cf                   	iret   

80105292 <tvinit>:
uint ticks;
#endif // PDX_XV6

void
tvinit(void)
{
80105292:	f3 0f 1e fb          	endbr32 
  int i;

  for(i = 0; i < 256; i++)
80105296:	b8 00 00 00 00       	mov    $0x0,%eax
8010529b:	3d ff 00 00 00       	cmp    $0xff,%eax
801052a0:	7f 4c                	jg     801052ee <tvinit+0x5c>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801052a2:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
801052a9:	66 89 0c c5 80 51 11 	mov    %cx,-0x7feeae80(,%eax,8)
801052b0:	80 
801052b1:	66 c7 04 c5 82 51 11 	movw   $0x8,-0x7feeae7e(,%eax,8)
801052b8:	80 08 00 
801052bb:	c6 04 c5 84 51 11 80 	movb   $0x0,-0x7feeae7c(,%eax,8)
801052c2:	00 
801052c3:	0f b6 14 c5 85 51 11 	movzbl -0x7feeae7b(,%eax,8),%edx
801052ca:	80 
801052cb:	83 e2 f0             	and    $0xfffffff0,%edx
801052ce:	83 ca 0e             	or     $0xe,%edx
801052d1:	83 e2 8f             	and    $0xffffff8f,%edx
801052d4:	83 ca 80             	or     $0xffffff80,%edx
801052d7:	88 14 c5 85 51 11 80 	mov    %dl,-0x7feeae7b(,%eax,8)
801052de:	c1 e9 10             	shr    $0x10,%ecx
801052e1:	66 89 0c c5 86 51 11 	mov    %cx,-0x7feeae7a(,%eax,8)
801052e8:	80 
  for(i = 0; i < 256; i++)
801052e9:	83 c0 01             	add    $0x1,%eax
801052ec:	eb ad                	jmp    8010529b <tvinit+0x9>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801052ee:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
801052f4:	66 89 15 80 53 11 80 	mov    %dx,0x80115380
801052fb:	66 c7 05 82 53 11 80 	movw   $0x8,0x80115382
80105302:	08 00 
80105304:	c6 05 84 53 11 80 00 	movb   $0x0,0x80115384
8010530b:	0f b6 05 85 53 11 80 	movzbl 0x80115385,%eax
80105312:	83 c8 0f             	or     $0xf,%eax
80105315:	83 e0 ef             	and    $0xffffffef,%eax
80105318:	83 c8 e0             	or     $0xffffffe0,%eax
8010531b:	a2 85 53 11 80       	mov    %al,0x80115385
80105320:	c1 ea 10             	shr    $0x10,%edx
80105323:	66 89 15 86 53 11 80 	mov    %dx,0x80115386

#ifndef PDX_XV6
  initlock(&tickslock, "time");
#endif // PDX_XV6
}
8010532a:	c3                   	ret    

8010532b <idtinit>:

void
idtinit(void)
{
8010532b:	f3 0f 1e fb          	endbr32 
8010532f:	55                   	push   %ebp
80105330:	89 e5                	mov    %esp,%ebp
80105332:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80105335:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
8010533b:	b8 80 51 11 80       	mov    $0x80115180,%eax
80105340:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80105344:	c1 e8 10             	shr    $0x10,%eax
80105347:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010534b:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010534e:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80105351:	c9                   	leave  
80105352:	c3                   	ret    

80105353 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80105353:	f3 0f 1e fb          	endbr32 
80105357:	55                   	push   %ebp
80105358:	89 e5                	mov    %esp,%ebp
8010535a:	57                   	push   %edi
8010535b:	56                   	push   %esi
8010535c:	53                   	push   %ebx
8010535d:	83 ec 1c             	sub    $0x1c,%esp
80105360:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105363:	8b 43 30             	mov    0x30(%ebx),%eax
80105366:	83 f8 40             	cmp    $0x40,%eax
80105369:	74 14                	je     8010537f <trap+0x2c>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
8010536b:	83 e8 20             	sub    $0x20,%eax
8010536e:	83 f8 1f             	cmp    $0x1f,%eax
80105371:	0f 87 23 01 00 00    	ja     8010549a <trap+0x147>
80105377:	3e ff 24 85 7c 72 10 	notrack jmp *-0x7fef8d84(,%eax,4)
8010537e:	80 
    if(myproc()->killed)
8010537f:	e8 b4 df ff ff       	call   80103338 <myproc>
80105384:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105388:	75 1f                	jne    801053a9 <trap+0x56>
    myproc()->tf = tf;
8010538a:	e8 a9 df ff ff       	call   80103338 <myproc>
8010538f:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105392:	e8 ec ef ff ff       	call   80104383 <syscall>
    if(myproc()->killed)
80105397:	e8 9c df ff ff       	call   80103338 <myproc>
8010539c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801053a0:	74 7e                	je     80105420 <trap+0xcd>
      exit();
801053a2:	e8 b4 e3 ff ff       	call   8010375b <exit>
    return;
801053a7:	eb 77                	jmp    80105420 <trap+0xcd>
      exit();
801053a9:	e8 ad e3 ff ff       	call   8010375b <exit>
801053ae:	eb da                	jmp    8010538a <trap+0x37>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801053b0:	e8 64 df ff ff       	call   80103319 <cpuid>
801053b5:	85 c0                	test   %eax,%eax
801053b7:	74 6f                	je     80105428 <trap+0xd5>
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
#endif // PDX_XV6
    }
    lapiceoi();
801053b9:	e8 b2 d0 ff ff       	call   80102470 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801053be:	e8 75 df ff ff       	call   80103338 <myproc>
801053c3:	85 c0                	test   %eax,%eax
801053c5:	74 1c                	je     801053e3 <trap+0x90>
801053c7:	e8 6c df ff ff       	call   80103338 <myproc>
801053cc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801053d0:	74 11                	je     801053e3 <trap+0x90>
801053d2:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801053d6:	83 e0 03             	and    $0x3,%eax
801053d9:	66 83 f8 03          	cmp    $0x3,%ax
801053dd:	0f 84 4a 01 00 00    	je     8010552d <trap+0x1da>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
801053e3:	e8 50 df ff ff       	call   80103338 <myproc>
801053e8:	85 c0                	test   %eax,%eax
801053ea:	74 0f                	je     801053fb <trap+0xa8>
801053ec:	e8 47 df ff ff       	call   80103338 <myproc>
801053f1:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
801053f5:	0f 84 3c 01 00 00    	je     80105537 <trap+0x1e4>
    tf->trapno == T_IRQ0+IRQ_TIMER)
#endif // PDX_XV6
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801053fb:	e8 38 df ff ff       	call   80103338 <myproc>
80105400:	85 c0                	test   %eax,%eax
80105402:	74 1c                	je     80105420 <trap+0xcd>
80105404:	e8 2f df ff ff       	call   80103338 <myproc>
80105409:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010540d:	74 11                	je     80105420 <trap+0xcd>
8010540f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105413:	83 e0 03             	and    $0x3,%eax
80105416:	66 83 f8 03          	cmp    $0x3,%ax
8010541a:	0f 84 4a 01 00 00    	je     8010556a <trap+0x217>
    exit();
}
80105420:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105423:	5b                   	pop    %ebx
80105424:	5e                   	pop    %esi
80105425:	5f                   	pop    %edi
80105426:	5d                   	pop    %ebp
80105427:	c3                   	ret    
// atom_inc() necessary for removal of tickslock
// other atomic ops added for completeness
static inline void
atom_inc(volatile int *num)
{
  asm volatile ( "lock incl %0" : "=m" (*num));
80105428:	f0 ff 05 80 59 11 80 	lock incl 0x80115980
      wakeup(&ticks);
8010542f:	83 ec 0c             	sub    $0xc,%esp
80105432:	68 80 59 11 80       	push   $0x80115980
80105437:	e8 a0 e5 ff ff       	call   801039dc <wakeup>
8010543c:	83 c4 10             	add    $0x10,%esp
8010543f:	e9 75 ff ff ff       	jmp    801053b9 <trap+0x66>
    ideintr();
80105444:	e8 e0 c9 ff ff       	call   80101e29 <ideintr>
    lapiceoi();
80105449:	e8 22 d0 ff ff       	call   80102470 <lapiceoi>
    break;
8010544e:	e9 6b ff ff ff       	jmp    801053be <trap+0x6b>
    kbdintr();
80105453:	e8 55 ce ff ff       	call   801022ad <kbdintr>
    lapiceoi();
80105458:	e8 13 d0 ff ff       	call   80102470 <lapiceoi>
    break;
8010545d:	e9 5c ff ff ff       	jmp    801053be <trap+0x6b>
    uartintr();
80105462:	e8 29 02 00 00       	call   80105690 <uartintr>
    lapiceoi();
80105467:	e8 04 d0 ff ff       	call   80102470 <lapiceoi>
    break;
8010546c:	e9 4d ff ff ff       	jmp    801053be <trap+0x6b>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105471:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105474:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105478:	e8 9c de ff ff       	call   80103319 <cpuid>
8010547d:	57                   	push   %edi
8010547e:	0f b7 f6             	movzwl %si,%esi
80105481:	56                   	push   %esi
80105482:	50                   	push   %eax
80105483:	68 dc 71 10 80       	push   $0x801071dc
80105488:	e8 9c b1 ff ff       	call   80100629 <cprintf>
    lapiceoi();
8010548d:	e8 de cf ff ff       	call   80102470 <lapiceoi>
    break;
80105492:	83 c4 10             	add    $0x10,%esp
80105495:	e9 24 ff ff ff       	jmp    801053be <trap+0x6b>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010549a:	e8 99 de ff ff       	call   80103338 <myproc>
8010549f:	85 c0                	test   %eax,%eax
801054a1:	74 5f                	je     80105502 <trap+0x1af>
801054a3:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801054a7:	74 59                	je     80105502 <trap+0x1af>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801054a9:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801054ac:	8b 43 38             	mov    0x38(%ebx),%eax
801054af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801054b2:	e8 62 de ff ff       	call   80103319 <cpuid>
801054b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
801054ba:	8b 4b 34             	mov    0x34(%ebx),%ecx
801054bd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
801054c0:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801054c3:	e8 70 de ff ff       	call   80103338 <myproc>
801054c8:	8d 50 6c             	lea    0x6c(%eax),%edx
801054cb:	89 55 d8             	mov    %edx,-0x28(%ebp)
801054ce:	e8 65 de ff ff       	call   80103338 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801054d3:	57                   	push   %edi
801054d4:	ff 75 e4             	pushl  -0x1c(%ebp)
801054d7:	ff 75 e0             	pushl  -0x20(%ebp)
801054da:	ff 75 dc             	pushl  -0x24(%ebp)
801054dd:	56                   	push   %esi
801054de:	ff 75 d8             	pushl  -0x28(%ebp)
801054e1:	ff 70 10             	pushl  0x10(%eax)
801054e4:	68 34 72 10 80       	push   $0x80107234
801054e9:	e8 3b b1 ff ff       	call   80100629 <cprintf>
    myproc()->killed = 1;
801054ee:	83 c4 20             	add    $0x20,%esp
801054f1:	e8 42 de ff ff       	call   80103338 <myproc>
801054f6:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801054fd:	e9 bc fe ff ff       	jmp    801053be <trap+0x6b>
80105502:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105505:	8b 73 38             	mov    0x38(%ebx),%esi
80105508:	e8 0c de ff ff       	call   80103319 <cpuid>
8010550d:	83 ec 0c             	sub    $0xc,%esp
80105510:	57                   	push   %edi
80105511:	56                   	push   %esi
80105512:	50                   	push   %eax
80105513:	ff 73 30             	pushl  0x30(%ebx)
80105516:	68 00 72 10 80       	push   $0x80107200
8010551b:	e8 09 b1 ff ff       	call   80100629 <cprintf>
      panic("trap");
80105520:	83 c4 14             	add    $0x14,%esp
80105523:	68 77 72 10 80       	push   $0x80107277
80105528:	e8 2f ae ff ff       	call   8010035c <panic>
    exit();
8010552d:	e8 29 e2 ff ff       	call   8010375b <exit>
80105532:	e9 ac fe ff ff       	jmp    801053e3 <trap+0x90>
  if(myproc() && myproc()->state == RUNNING &&
80105537:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
8010553b:	0f 85 ba fe ff ff    	jne    801053fb <trap+0xa8>
    tf->trapno == T_IRQ0+IRQ_TIMER && ticks%SCHED_INTERVAL==0)
80105541:	8b 0d 80 59 11 80    	mov    0x80115980,%ecx
80105547:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
8010554c:	89 c8                	mov    %ecx,%eax
8010554e:	f7 e2                	mul    %edx
80105550:	c1 ea 03             	shr    $0x3,%edx
80105553:	8d 04 92             	lea    (%edx,%edx,4),%eax
80105556:	01 c0                	add    %eax,%eax
80105558:	39 c1                	cmp    %eax,%ecx
8010555a:	0f 85 9b fe ff ff    	jne    801053fb <trap+0xa8>
    yield();
80105560:	e8 c9 e2 ff ff       	call   8010382e <yield>
80105565:	e9 91 fe ff ff       	jmp    801053fb <trap+0xa8>
    exit();
8010556a:	e8 ec e1 ff ff       	call   8010375b <exit>
8010556f:	e9 ac fe ff ff       	jmp    80105420 <trap+0xcd>

80105574 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105574:	f3 0f 1e fb          	endbr32 
  if(!uart)
80105578:	83 3d 14 ca 10 80 00 	cmpl   $0x0,0x8010ca14
8010557f:	74 14                	je     80105595 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105581:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105586:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105587:	a8 01                	test   $0x1,%al
80105589:	74 10                	je     8010559b <uartgetc+0x27>
8010558b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105590:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105591:	0f b6 c0             	movzbl %al,%eax
80105594:	c3                   	ret    
    return -1;
80105595:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010559a:	c3                   	ret    
    return -1;
8010559b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801055a0:	c3                   	ret    

801055a1 <uartputc>:
{
801055a1:	f3 0f 1e fb          	endbr32 
  if(!uart)
801055a5:	83 3d 14 ca 10 80 00 	cmpl   $0x0,0x8010ca14
801055ac:	74 3b                	je     801055e9 <uartputc+0x48>
{
801055ae:	55                   	push   %ebp
801055af:	89 e5                	mov    %esp,%ebp
801055b1:	53                   	push   %ebx
801055b2:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801055b5:	bb 00 00 00 00       	mov    $0x0,%ebx
801055ba:	83 fb 7f             	cmp    $0x7f,%ebx
801055bd:	7f 1c                	jg     801055db <uartputc+0x3a>
801055bf:	ba fd 03 00 00       	mov    $0x3fd,%edx
801055c4:	ec                   	in     (%dx),%al
801055c5:	a8 20                	test   $0x20,%al
801055c7:	75 12                	jne    801055db <uartputc+0x3a>
    microdelay(10);
801055c9:	83 ec 0c             	sub    $0xc,%esp
801055cc:	6a 0a                	push   $0xa
801055ce:	e8 c2 ce ff ff       	call   80102495 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801055d3:	83 c3 01             	add    $0x1,%ebx
801055d6:	83 c4 10             	add    $0x10,%esp
801055d9:	eb df                	jmp    801055ba <uartputc+0x19>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801055db:	8b 45 08             	mov    0x8(%ebp),%eax
801055de:	ba f8 03 00 00       	mov    $0x3f8,%edx
801055e3:	ee                   	out    %al,(%dx)
}
801055e4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801055e7:	c9                   	leave  
801055e8:	c3                   	ret    
801055e9:	c3                   	ret    

801055ea <uartinit>:
{
801055ea:	f3 0f 1e fb          	endbr32 
801055ee:	55                   	push   %ebp
801055ef:	89 e5                	mov    %esp,%ebp
801055f1:	56                   	push   %esi
801055f2:	53                   	push   %ebx
801055f3:	b9 00 00 00 00       	mov    $0x0,%ecx
801055f8:	ba fa 03 00 00       	mov    $0x3fa,%edx
801055fd:	89 c8                	mov    %ecx,%eax
801055ff:	ee                   	out    %al,(%dx)
80105600:	be fb 03 00 00       	mov    $0x3fb,%esi
80105605:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010560a:	89 f2                	mov    %esi,%edx
8010560c:	ee                   	out    %al,(%dx)
8010560d:	b8 0c 00 00 00       	mov    $0xc,%eax
80105612:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105617:	ee                   	out    %al,(%dx)
80105618:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010561d:	89 c8                	mov    %ecx,%eax
8010561f:	89 da                	mov    %ebx,%edx
80105621:	ee                   	out    %al,(%dx)
80105622:	b8 03 00 00 00       	mov    $0x3,%eax
80105627:	89 f2                	mov    %esi,%edx
80105629:	ee                   	out    %al,(%dx)
8010562a:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010562f:	89 c8                	mov    %ecx,%eax
80105631:	ee                   	out    %al,(%dx)
80105632:	b8 01 00 00 00       	mov    $0x1,%eax
80105637:	89 da                	mov    %ebx,%edx
80105639:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010563a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010563f:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105640:	3c ff                	cmp    $0xff,%al
80105642:	74 45                	je     80105689 <uartinit+0x9f>
  uart = 1;
80105644:	c7 05 14 ca 10 80 01 	movl   $0x1,0x8010ca14
8010564b:	00 00 00 
8010564e:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105653:	ec                   	in     (%dx),%al
80105654:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105659:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010565a:	83 ec 08             	sub    $0x8,%esp
8010565d:	6a 00                	push   $0x0
8010565f:	6a 04                	push   $0x4
80105661:	e8 d2 c9 ff ff       	call   80102038 <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105666:	83 c4 10             	add    $0x10,%esp
80105669:	bb fc 72 10 80       	mov    $0x801072fc,%ebx
8010566e:	eb 12                	jmp    80105682 <uartinit+0x98>
    uartputc(*p);
80105670:	83 ec 0c             	sub    $0xc,%esp
80105673:	0f be c0             	movsbl %al,%eax
80105676:	50                   	push   %eax
80105677:	e8 25 ff ff ff       	call   801055a1 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010567c:	83 c3 01             	add    $0x1,%ebx
8010567f:	83 c4 10             	add    $0x10,%esp
80105682:	0f b6 03             	movzbl (%ebx),%eax
80105685:	84 c0                	test   %al,%al
80105687:	75 e7                	jne    80105670 <uartinit+0x86>
}
80105689:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010568c:	5b                   	pop    %ebx
8010568d:	5e                   	pop    %esi
8010568e:	5d                   	pop    %ebp
8010568f:	c3                   	ret    

80105690 <uartintr>:

void
uartintr(void)
{
80105690:	f3 0f 1e fb          	endbr32 
80105694:	55                   	push   %ebp
80105695:	89 e5                	mov    %esp,%ebp
80105697:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
8010569a:	68 74 55 10 80       	push   $0x80105574
8010569f:	e8 da b0 ff ff       	call   8010077e <consoleintr>
}
801056a4:	83 c4 10             	add    $0x10,%esp
801056a7:	c9                   	leave  
801056a8:	c3                   	ret    

801056a9 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801056a9:	6a 00                	push   $0x0
  pushl $0
801056ab:	6a 00                	push   $0x0
  jmp alltraps
801056ad:	e9 bd fb ff ff       	jmp    8010526f <alltraps>

801056b2 <vector1>:
.globl vector1
vector1:
  pushl $0
801056b2:	6a 00                	push   $0x0
  pushl $1
801056b4:	6a 01                	push   $0x1
  jmp alltraps
801056b6:	e9 b4 fb ff ff       	jmp    8010526f <alltraps>

801056bb <vector2>:
.globl vector2
vector2:
  pushl $0
801056bb:	6a 00                	push   $0x0
  pushl $2
801056bd:	6a 02                	push   $0x2
  jmp alltraps
801056bf:	e9 ab fb ff ff       	jmp    8010526f <alltraps>

801056c4 <vector3>:
.globl vector3
vector3:
  pushl $0
801056c4:	6a 00                	push   $0x0
  pushl $3
801056c6:	6a 03                	push   $0x3
  jmp alltraps
801056c8:	e9 a2 fb ff ff       	jmp    8010526f <alltraps>

801056cd <vector4>:
.globl vector4
vector4:
  pushl $0
801056cd:	6a 00                	push   $0x0
  pushl $4
801056cf:	6a 04                	push   $0x4
  jmp alltraps
801056d1:	e9 99 fb ff ff       	jmp    8010526f <alltraps>

801056d6 <vector5>:
.globl vector5
vector5:
  pushl $0
801056d6:	6a 00                	push   $0x0
  pushl $5
801056d8:	6a 05                	push   $0x5
  jmp alltraps
801056da:	e9 90 fb ff ff       	jmp    8010526f <alltraps>

801056df <vector6>:
.globl vector6
vector6:
  pushl $0
801056df:	6a 00                	push   $0x0
  pushl $6
801056e1:	6a 06                	push   $0x6
  jmp alltraps
801056e3:	e9 87 fb ff ff       	jmp    8010526f <alltraps>

801056e8 <vector7>:
.globl vector7
vector7:
  pushl $0
801056e8:	6a 00                	push   $0x0
  pushl $7
801056ea:	6a 07                	push   $0x7
  jmp alltraps
801056ec:	e9 7e fb ff ff       	jmp    8010526f <alltraps>

801056f1 <vector8>:
.globl vector8
vector8:
  pushl $8
801056f1:	6a 08                	push   $0x8
  jmp alltraps
801056f3:	e9 77 fb ff ff       	jmp    8010526f <alltraps>

801056f8 <vector9>:
.globl vector9
vector9:
  pushl $0
801056f8:	6a 00                	push   $0x0
  pushl $9
801056fa:	6a 09                	push   $0x9
  jmp alltraps
801056fc:	e9 6e fb ff ff       	jmp    8010526f <alltraps>

80105701 <vector10>:
.globl vector10
vector10:
  pushl $10
80105701:	6a 0a                	push   $0xa
  jmp alltraps
80105703:	e9 67 fb ff ff       	jmp    8010526f <alltraps>

80105708 <vector11>:
.globl vector11
vector11:
  pushl $11
80105708:	6a 0b                	push   $0xb
  jmp alltraps
8010570a:	e9 60 fb ff ff       	jmp    8010526f <alltraps>

8010570f <vector12>:
.globl vector12
vector12:
  pushl $12
8010570f:	6a 0c                	push   $0xc
  jmp alltraps
80105711:	e9 59 fb ff ff       	jmp    8010526f <alltraps>

80105716 <vector13>:
.globl vector13
vector13:
  pushl $13
80105716:	6a 0d                	push   $0xd
  jmp alltraps
80105718:	e9 52 fb ff ff       	jmp    8010526f <alltraps>

8010571d <vector14>:
.globl vector14
vector14:
  pushl $14
8010571d:	6a 0e                	push   $0xe
  jmp alltraps
8010571f:	e9 4b fb ff ff       	jmp    8010526f <alltraps>

80105724 <vector15>:
.globl vector15
vector15:
  pushl $0
80105724:	6a 00                	push   $0x0
  pushl $15
80105726:	6a 0f                	push   $0xf
  jmp alltraps
80105728:	e9 42 fb ff ff       	jmp    8010526f <alltraps>

8010572d <vector16>:
.globl vector16
vector16:
  pushl $0
8010572d:	6a 00                	push   $0x0
  pushl $16
8010572f:	6a 10                	push   $0x10
  jmp alltraps
80105731:	e9 39 fb ff ff       	jmp    8010526f <alltraps>

80105736 <vector17>:
.globl vector17
vector17:
  pushl $17
80105736:	6a 11                	push   $0x11
  jmp alltraps
80105738:	e9 32 fb ff ff       	jmp    8010526f <alltraps>

8010573d <vector18>:
.globl vector18
vector18:
  pushl $0
8010573d:	6a 00                	push   $0x0
  pushl $18
8010573f:	6a 12                	push   $0x12
  jmp alltraps
80105741:	e9 29 fb ff ff       	jmp    8010526f <alltraps>

80105746 <vector19>:
.globl vector19
vector19:
  pushl $0
80105746:	6a 00                	push   $0x0
  pushl $19
80105748:	6a 13                	push   $0x13
  jmp alltraps
8010574a:	e9 20 fb ff ff       	jmp    8010526f <alltraps>

8010574f <vector20>:
.globl vector20
vector20:
  pushl $0
8010574f:	6a 00                	push   $0x0
  pushl $20
80105751:	6a 14                	push   $0x14
  jmp alltraps
80105753:	e9 17 fb ff ff       	jmp    8010526f <alltraps>

80105758 <vector21>:
.globl vector21
vector21:
  pushl $0
80105758:	6a 00                	push   $0x0
  pushl $21
8010575a:	6a 15                	push   $0x15
  jmp alltraps
8010575c:	e9 0e fb ff ff       	jmp    8010526f <alltraps>

80105761 <vector22>:
.globl vector22
vector22:
  pushl $0
80105761:	6a 00                	push   $0x0
  pushl $22
80105763:	6a 16                	push   $0x16
  jmp alltraps
80105765:	e9 05 fb ff ff       	jmp    8010526f <alltraps>

8010576a <vector23>:
.globl vector23
vector23:
  pushl $0
8010576a:	6a 00                	push   $0x0
  pushl $23
8010576c:	6a 17                	push   $0x17
  jmp alltraps
8010576e:	e9 fc fa ff ff       	jmp    8010526f <alltraps>

80105773 <vector24>:
.globl vector24
vector24:
  pushl $0
80105773:	6a 00                	push   $0x0
  pushl $24
80105775:	6a 18                	push   $0x18
  jmp alltraps
80105777:	e9 f3 fa ff ff       	jmp    8010526f <alltraps>

8010577c <vector25>:
.globl vector25
vector25:
  pushl $0
8010577c:	6a 00                	push   $0x0
  pushl $25
8010577e:	6a 19                	push   $0x19
  jmp alltraps
80105780:	e9 ea fa ff ff       	jmp    8010526f <alltraps>

80105785 <vector26>:
.globl vector26
vector26:
  pushl $0
80105785:	6a 00                	push   $0x0
  pushl $26
80105787:	6a 1a                	push   $0x1a
  jmp alltraps
80105789:	e9 e1 fa ff ff       	jmp    8010526f <alltraps>

8010578e <vector27>:
.globl vector27
vector27:
  pushl $0
8010578e:	6a 00                	push   $0x0
  pushl $27
80105790:	6a 1b                	push   $0x1b
  jmp alltraps
80105792:	e9 d8 fa ff ff       	jmp    8010526f <alltraps>

80105797 <vector28>:
.globl vector28
vector28:
  pushl $0
80105797:	6a 00                	push   $0x0
  pushl $28
80105799:	6a 1c                	push   $0x1c
  jmp alltraps
8010579b:	e9 cf fa ff ff       	jmp    8010526f <alltraps>

801057a0 <vector29>:
.globl vector29
vector29:
  pushl $0
801057a0:	6a 00                	push   $0x0
  pushl $29
801057a2:	6a 1d                	push   $0x1d
  jmp alltraps
801057a4:	e9 c6 fa ff ff       	jmp    8010526f <alltraps>

801057a9 <vector30>:
.globl vector30
vector30:
  pushl $0
801057a9:	6a 00                	push   $0x0
  pushl $30
801057ab:	6a 1e                	push   $0x1e
  jmp alltraps
801057ad:	e9 bd fa ff ff       	jmp    8010526f <alltraps>

801057b2 <vector31>:
.globl vector31
vector31:
  pushl $0
801057b2:	6a 00                	push   $0x0
  pushl $31
801057b4:	6a 1f                	push   $0x1f
  jmp alltraps
801057b6:	e9 b4 fa ff ff       	jmp    8010526f <alltraps>

801057bb <vector32>:
.globl vector32
vector32:
  pushl $0
801057bb:	6a 00                	push   $0x0
  pushl $32
801057bd:	6a 20                	push   $0x20
  jmp alltraps
801057bf:	e9 ab fa ff ff       	jmp    8010526f <alltraps>

801057c4 <vector33>:
.globl vector33
vector33:
  pushl $0
801057c4:	6a 00                	push   $0x0
  pushl $33
801057c6:	6a 21                	push   $0x21
  jmp alltraps
801057c8:	e9 a2 fa ff ff       	jmp    8010526f <alltraps>

801057cd <vector34>:
.globl vector34
vector34:
  pushl $0
801057cd:	6a 00                	push   $0x0
  pushl $34
801057cf:	6a 22                	push   $0x22
  jmp alltraps
801057d1:	e9 99 fa ff ff       	jmp    8010526f <alltraps>

801057d6 <vector35>:
.globl vector35
vector35:
  pushl $0
801057d6:	6a 00                	push   $0x0
  pushl $35
801057d8:	6a 23                	push   $0x23
  jmp alltraps
801057da:	e9 90 fa ff ff       	jmp    8010526f <alltraps>

801057df <vector36>:
.globl vector36
vector36:
  pushl $0
801057df:	6a 00                	push   $0x0
  pushl $36
801057e1:	6a 24                	push   $0x24
  jmp alltraps
801057e3:	e9 87 fa ff ff       	jmp    8010526f <alltraps>

801057e8 <vector37>:
.globl vector37
vector37:
  pushl $0
801057e8:	6a 00                	push   $0x0
  pushl $37
801057ea:	6a 25                	push   $0x25
  jmp alltraps
801057ec:	e9 7e fa ff ff       	jmp    8010526f <alltraps>

801057f1 <vector38>:
.globl vector38
vector38:
  pushl $0
801057f1:	6a 00                	push   $0x0
  pushl $38
801057f3:	6a 26                	push   $0x26
  jmp alltraps
801057f5:	e9 75 fa ff ff       	jmp    8010526f <alltraps>

801057fa <vector39>:
.globl vector39
vector39:
  pushl $0
801057fa:	6a 00                	push   $0x0
  pushl $39
801057fc:	6a 27                	push   $0x27
  jmp alltraps
801057fe:	e9 6c fa ff ff       	jmp    8010526f <alltraps>

80105803 <vector40>:
.globl vector40
vector40:
  pushl $0
80105803:	6a 00                	push   $0x0
  pushl $40
80105805:	6a 28                	push   $0x28
  jmp alltraps
80105807:	e9 63 fa ff ff       	jmp    8010526f <alltraps>

8010580c <vector41>:
.globl vector41
vector41:
  pushl $0
8010580c:	6a 00                	push   $0x0
  pushl $41
8010580e:	6a 29                	push   $0x29
  jmp alltraps
80105810:	e9 5a fa ff ff       	jmp    8010526f <alltraps>

80105815 <vector42>:
.globl vector42
vector42:
  pushl $0
80105815:	6a 00                	push   $0x0
  pushl $42
80105817:	6a 2a                	push   $0x2a
  jmp alltraps
80105819:	e9 51 fa ff ff       	jmp    8010526f <alltraps>

8010581e <vector43>:
.globl vector43
vector43:
  pushl $0
8010581e:	6a 00                	push   $0x0
  pushl $43
80105820:	6a 2b                	push   $0x2b
  jmp alltraps
80105822:	e9 48 fa ff ff       	jmp    8010526f <alltraps>

80105827 <vector44>:
.globl vector44
vector44:
  pushl $0
80105827:	6a 00                	push   $0x0
  pushl $44
80105829:	6a 2c                	push   $0x2c
  jmp alltraps
8010582b:	e9 3f fa ff ff       	jmp    8010526f <alltraps>

80105830 <vector45>:
.globl vector45
vector45:
  pushl $0
80105830:	6a 00                	push   $0x0
  pushl $45
80105832:	6a 2d                	push   $0x2d
  jmp alltraps
80105834:	e9 36 fa ff ff       	jmp    8010526f <alltraps>

80105839 <vector46>:
.globl vector46
vector46:
  pushl $0
80105839:	6a 00                	push   $0x0
  pushl $46
8010583b:	6a 2e                	push   $0x2e
  jmp alltraps
8010583d:	e9 2d fa ff ff       	jmp    8010526f <alltraps>

80105842 <vector47>:
.globl vector47
vector47:
  pushl $0
80105842:	6a 00                	push   $0x0
  pushl $47
80105844:	6a 2f                	push   $0x2f
  jmp alltraps
80105846:	e9 24 fa ff ff       	jmp    8010526f <alltraps>

8010584b <vector48>:
.globl vector48
vector48:
  pushl $0
8010584b:	6a 00                	push   $0x0
  pushl $48
8010584d:	6a 30                	push   $0x30
  jmp alltraps
8010584f:	e9 1b fa ff ff       	jmp    8010526f <alltraps>

80105854 <vector49>:
.globl vector49
vector49:
  pushl $0
80105854:	6a 00                	push   $0x0
  pushl $49
80105856:	6a 31                	push   $0x31
  jmp alltraps
80105858:	e9 12 fa ff ff       	jmp    8010526f <alltraps>

8010585d <vector50>:
.globl vector50
vector50:
  pushl $0
8010585d:	6a 00                	push   $0x0
  pushl $50
8010585f:	6a 32                	push   $0x32
  jmp alltraps
80105861:	e9 09 fa ff ff       	jmp    8010526f <alltraps>

80105866 <vector51>:
.globl vector51
vector51:
  pushl $0
80105866:	6a 00                	push   $0x0
  pushl $51
80105868:	6a 33                	push   $0x33
  jmp alltraps
8010586a:	e9 00 fa ff ff       	jmp    8010526f <alltraps>

8010586f <vector52>:
.globl vector52
vector52:
  pushl $0
8010586f:	6a 00                	push   $0x0
  pushl $52
80105871:	6a 34                	push   $0x34
  jmp alltraps
80105873:	e9 f7 f9 ff ff       	jmp    8010526f <alltraps>

80105878 <vector53>:
.globl vector53
vector53:
  pushl $0
80105878:	6a 00                	push   $0x0
  pushl $53
8010587a:	6a 35                	push   $0x35
  jmp alltraps
8010587c:	e9 ee f9 ff ff       	jmp    8010526f <alltraps>

80105881 <vector54>:
.globl vector54
vector54:
  pushl $0
80105881:	6a 00                	push   $0x0
  pushl $54
80105883:	6a 36                	push   $0x36
  jmp alltraps
80105885:	e9 e5 f9 ff ff       	jmp    8010526f <alltraps>

8010588a <vector55>:
.globl vector55
vector55:
  pushl $0
8010588a:	6a 00                	push   $0x0
  pushl $55
8010588c:	6a 37                	push   $0x37
  jmp alltraps
8010588e:	e9 dc f9 ff ff       	jmp    8010526f <alltraps>

80105893 <vector56>:
.globl vector56
vector56:
  pushl $0
80105893:	6a 00                	push   $0x0
  pushl $56
80105895:	6a 38                	push   $0x38
  jmp alltraps
80105897:	e9 d3 f9 ff ff       	jmp    8010526f <alltraps>

8010589c <vector57>:
.globl vector57
vector57:
  pushl $0
8010589c:	6a 00                	push   $0x0
  pushl $57
8010589e:	6a 39                	push   $0x39
  jmp alltraps
801058a0:	e9 ca f9 ff ff       	jmp    8010526f <alltraps>

801058a5 <vector58>:
.globl vector58
vector58:
  pushl $0
801058a5:	6a 00                	push   $0x0
  pushl $58
801058a7:	6a 3a                	push   $0x3a
  jmp alltraps
801058a9:	e9 c1 f9 ff ff       	jmp    8010526f <alltraps>

801058ae <vector59>:
.globl vector59
vector59:
  pushl $0
801058ae:	6a 00                	push   $0x0
  pushl $59
801058b0:	6a 3b                	push   $0x3b
  jmp alltraps
801058b2:	e9 b8 f9 ff ff       	jmp    8010526f <alltraps>

801058b7 <vector60>:
.globl vector60
vector60:
  pushl $0
801058b7:	6a 00                	push   $0x0
  pushl $60
801058b9:	6a 3c                	push   $0x3c
  jmp alltraps
801058bb:	e9 af f9 ff ff       	jmp    8010526f <alltraps>

801058c0 <vector61>:
.globl vector61
vector61:
  pushl $0
801058c0:	6a 00                	push   $0x0
  pushl $61
801058c2:	6a 3d                	push   $0x3d
  jmp alltraps
801058c4:	e9 a6 f9 ff ff       	jmp    8010526f <alltraps>

801058c9 <vector62>:
.globl vector62
vector62:
  pushl $0
801058c9:	6a 00                	push   $0x0
  pushl $62
801058cb:	6a 3e                	push   $0x3e
  jmp alltraps
801058cd:	e9 9d f9 ff ff       	jmp    8010526f <alltraps>

801058d2 <vector63>:
.globl vector63
vector63:
  pushl $0
801058d2:	6a 00                	push   $0x0
  pushl $63
801058d4:	6a 3f                	push   $0x3f
  jmp alltraps
801058d6:	e9 94 f9 ff ff       	jmp    8010526f <alltraps>

801058db <vector64>:
.globl vector64
vector64:
  pushl $0
801058db:	6a 00                	push   $0x0
  pushl $64
801058dd:	6a 40                	push   $0x40
  jmp alltraps
801058df:	e9 8b f9 ff ff       	jmp    8010526f <alltraps>

801058e4 <vector65>:
.globl vector65
vector65:
  pushl $0
801058e4:	6a 00                	push   $0x0
  pushl $65
801058e6:	6a 41                	push   $0x41
  jmp alltraps
801058e8:	e9 82 f9 ff ff       	jmp    8010526f <alltraps>

801058ed <vector66>:
.globl vector66
vector66:
  pushl $0
801058ed:	6a 00                	push   $0x0
  pushl $66
801058ef:	6a 42                	push   $0x42
  jmp alltraps
801058f1:	e9 79 f9 ff ff       	jmp    8010526f <alltraps>

801058f6 <vector67>:
.globl vector67
vector67:
  pushl $0
801058f6:	6a 00                	push   $0x0
  pushl $67
801058f8:	6a 43                	push   $0x43
  jmp alltraps
801058fa:	e9 70 f9 ff ff       	jmp    8010526f <alltraps>

801058ff <vector68>:
.globl vector68
vector68:
  pushl $0
801058ff:	6a 00                	push   $0x0
  pushl $68
80105901:	6a 44                	push   $0x44
  jmp alltraps
80105903:	e9 67 f9 ff ff       	jmp    8010526f <alltraps>

80105908 <vector69>:
.globl vector69
vector69:
  pushl $0
80105908:	6a 00                	push   $0x0
  pushl $69
8010590a:	6a 45                	push   $0x45
  jmp alltraps
8010590c:	e9 5e f9 ff ff       	jmp    8010526f <alltraps>

80105911 <vector70>:
.globl vector70
vector70:
  pushl $0
80105911:	6a 00                	push   $0x0
  pushl $70
80105913:	6a 46                	push   $0x46
  jmp alltraps
80105915:	e9 55 f9 ff ff       	jmp    8010526f <alltraps>

8010591a <vector71>:
.globl vector71
vector71:
  pushl $0
8010591a:	6a 00                	push   $0x0
  pushl $71
8010591c:	6a 47                	push   $0x47
  jmp alltraps
8010591e:	e9 4c f9 ff ff       	jmp    8010526f <alltraps>

80105923 <vector72>:
.globl vector72
vector72:
  pushl $0
80105923:	6a 00                	push   $0x0
  pushl $72
80105925:	6a 48                	push   $0x48
  jmp alltraps
80105927:	e9 43 f9 ff ff       	jmp    8010526f <alltraps>

8010592c <vector73>:
.globl vector73
vector73:
  pushl $0
8010592c:	6a 00                	push   $0x0
  pushl $73
8010592e:	6a 49                	push   $0x49
  jmp alltraps
80105930:	e9 3a f9 ff ff       	jmp    8010526f <alltraps>

80105935 <vector74>:
.globl vector74
vector74:
  pushl $0
80105935:	6a 00                	push   $0x0
  pushl $74
80105937:	6a 4a                	push   $0x4a
  jmp alltraps
80105939:	e9 31 f9 ff ff       	jmp    8010526f <alltraps>

8010593e <vector75>:
.globl vector75
vector75:
  pushl $0
8010593e:	6a 00                	push   $0x0
  pushl $75
80105940:	6a 4b                	push   $0x4b
  jmp alltraps
80105942:	e9 28 f9 ff ff       	jmp    8010526f <alltraps>

80105947 <vector76>:
.globl vector76
vector76:
  pushl $0
80105947:	6a 00                	push   $0x0
  pushl $76
80105949:	6a 4c                	push   $0x4c
  jmp alltraps
8010594b:	e9 1f f9 ff ff       	jmp    8010526f <alltraps>

80105950 <vector77>:
.globl vector77
vector77:
  pushl $0
80105950:	6a 00                	push   $0x0
  pushl $77
80105952:	6a 4d                	push   $0x4d
  jmp alltraps
80105954:	e9 16 f9 ff ff       	jmp    8010526f <alltraps>

80105959 <vector78>:
.globl vector78
vector78:
  pushl $0
80105959:	6a 00                	push   $0x0
  pushl $78
8010595b:	6a 4e                	push   $0x4e
  jmp alltraps
8010595d:	e9 0d f9 ff ff       	jmp    8010526f <alltraps>

80105962 <vector79>:
.globl vector79
vector79:
  pushl $0
80105962:	6a 00                	push   $0x0
  pushl $79
80105964:	6a 4f                	push   $0x4f
  jmp alltraps
80105966:	e9 04 f9 ff ff       	jmp    8010526f <alltraps>

8010596b <vector80>:
.globl vector80
vector80:
  pushl $0
8010596b:	6a 00                	push   $0x0
  pushl $80
8010596d:	6a 50                	push   $0x50
  jmp alltraps
8010596f:	e9 fb f8 ff ff       	jmp    8010526f <alltraps>

80105974 <vector81>:
.globl vector81
vector81:
  pushl $0
80105974:	6a 00                	push   $0x0
  pushl $81
80105976:	6a 51                	push   $0x51
  jmp alltraps
80105978:	e9 f2 f8 ff ff       	jmp    8010526f <alltraps>

8010597d <vector82>:
.globl vector82
vector82:
  pushl $0
8010597d:	6a 00                	push   $0x0
  pushl $82
8010597f:	6a 52                	push   $0x52
  jmp alltraps
80105981:	e9 e9 f8 ff ff       	jmp    8010526f <alltraps>

80105986 <vector83>:
.globl vector83
vector83:
  pushl $0
80105986:	6a 00                	push   $0x0
  pushl $83
80105988:	6a 53                	push   $0x53
  jmp alltraps
8010598a:	e9 e0 f8 ff ff       	jmp    8010526f <alltraps>

8010598f <vector84>:
.globl vector84
vector84:
  pushl $0
8010598f:	6a 00                	push   $0x0
  pushl $84
80105991:	6a 54                	push   $0x54
  jmp alltraps
80105993:	e9 d7 f8 ff ff       	jmp    8010526f <alltraps>

80105998 <vector85>:
.globl vector85
vector85:
  pushl $0
80105998:	6a 00                	push   $0x0
  pushl $85
8010599a:	6a 55                	push   $0x55
  jmp alltraps
8010599c:	e9 ce f8 ff ff       	jmp    8010526f <alltraps>

801059a1 <vector86>:
.globl vector86
vector86:
  pushl $0
801059a1:	6a 00                	push   $0x0
  pushl $86
801059a3:	6a 56                	push   $0x56
  jmp alltraps
801059a5:	e9 c5 f8 ff ff       	jmp    8010526f <alltraps>

801059aa <vector87>:
.globl vector87
vector87:
  pushl $0
801059aa:	6a 00                	push   $0x0
  pushl $87
801059ac:	6a 57                	push   $0x57
  jmp alltraps
801059ae:	e9 bc f8 ff ff       	jmp    8010526f <alltraps>

801059b3 <vector88>:
.globl vector88
vector88:
  pushl $0
801059b3:	6a 00                	push   $0x0
  pushl $88
801059b5:	6a 58                	push   $0x58
  jmp alltraps
801059b7:	e9 b3 f8 ff ff       	jmp    8010526f <alltraps>

801059bc <vector89>:
.globl vector89
vector89:
  pushl $0
801059bc:	6a 00                	push   $0x0
  pushl $89
801059be:	6a 59                	push   $0x59
  jmp alltraps
801059c0:	e9 aa f8 ff ff       	jmp    8010526f <alltraps>

801059c5 <vector90>:
.globl vector90
vector90:
  pushl $0
801059c5:	6a 00                	push   $0x0
  pushl $90
801059c7:	6a 5a                	push   $0x5a
  jmp alltraps
801059c9:	e9 a1 f8 ff ff       	jmp    8010526f <alltraps>

801059ce <vector91>:
.globl vector91
vector91:
  pushl $0
801059ce:	6a 00                	push   $0x0
  pushl $91
801059d0:	6a 5b                	push   $0x5b
  jmp alltraps
801059d2:	e9 98 f8 ff ff       	jmp    8010526f <alltraps>

801059d7 <vector92>:
.globl vector92
vector92:
  pushl $0
801059d7:	6a 00                	push   $0x0
  pushl $92
801059d9:	6a 5c                	push   $0x5c
  jmp alltraps
801059db:	e9 8f f8 ff ff       	jmp    8010526f <alltraps>

801059e0 <vector93>:
.globl vector93
vector93:
  pushl $0
801059e0:	6a 00                	push   $0x0
  pushl $93
801059e2:	6a 5d                	push   $0x5d
  jmp alltraps
801059e4:	e9 86 f8 ff ff       	jmp    8010526f <alltraps>

801059e9 <vector94>:
.globl vector94
vector94:
  pushl $0
801059e9:	6a 00                	push   $0x0
  pushl $94
801059eb:	6a 5e                	push   $0x5e
  jmp alltraps
801059ed:	e9 7d f8 ff ff       	jmp    8010526f <alltraps>

801059f2 <vector95>:
.globl vector95
vector95:
  pushl $0
801059f2:	6a 00                	push   $0x0
  pushl $95
801059f4:	6a 5f                	push   $0x5f
  jmp alltraps
801059f6:	e9 74 f8 ff ff       	jmp    8010526f <alltraps>

801059fb <vector96>:
.globl vector96
vector96:
  pushl $0
801059fb:	6a 00                	push   $0x0
  pushl $96
801059fd:	6a 60                	push   $0x60
  jmp alltraps
801059ff:	e9 6b f8 ff ff       	jmp    8010526f <alltraps>

80105a04 <vector97>:
.globl vector97
vector97:
  pushl $0
80105a04:	6a 00                	push   $0x0
  pushl $97
80105a06:	6a 61                	push   $0x61
  jmp alltraps
80105a08:	e9 62 f8 ff ff       	jmp    8010526f <alltraps>

80105a0d <vector98>:
.globl vector98
vector98:
  pushl $0
80105a0d:	6a 00                	push   $0x0
  pushl $98
80105a0f:	6a 62                	push   $0x62
  jmp alltraps
80105a11:	e9 59 f8 ff ff       	jmp    8010526f <alltraps>

80105a16 <vector99>:
.globl vector99
vector99:
  pushl $0
80105a16:	6a 00                	push   $0x0
  pushl $99
80105a18:	6a 63                	push   $0x63
  jmp alltraps
80105a1a:	e9 50 f8 ff ff       	jmp    8010526f <alltraps>

80105a1f <vector100>:
.globl vector100
vector100:
  pushl $0
80105a1f:	6a 00                	push   $0x0
  pushl $100
80105a21:	6a 64                	push   $0x64
  jmp alltraps
80105a23:	e9 47 f8 ff ff       	jmp    8010526f <alltraps>

80105a28 <vector101>:
.globl vector101
vector101:
  pushl $0
80105a28:	6a 00                	push   $0x0
  pushl $101
80105a2a:	6a 65                	push   $0x65
  jmp alltraps
80105a2c:	e9 3e f8 ff ff       	jmp    8010526f <alltraps>

80105a31 <vector102>:
.globl vector102
vector102:
  pushl $0
80105a31:	6a 00                	push   $0x0
  pushl $102
80105a33:	6a 66                	push   $0x66
  jmp alltraps
80105a35:	e9 35 f8 ff ff       	jmp    8010526f <alltraps>

80105a3a <vector103>:
.globl vector103
vector103:
  pushl $0
80105a3a:	6a 00                	push   $0x0
  pushl $103
80105a3c:	6a 67                	push   $0x67
  jmp alltraps
80105a3e:	e9 2c f8 ff ff       	jmp    8010526f <alltraps>

80105a43 <vector104>:
.globl vector104
vector104:
  pushl $0
80105a43:	6a 00                	push   $0x0
  pushl $104
80105a45:	6a 68                	push   $0x68
  jmp alltraps
80105a47:	e9 23 f8 ff ff       	jmp    8010526f <alltraps>

80105a4c <vector105>:
.globl vector105
vector105:
  pushl $0
80105a4c:	6a 00                	push   $0x0
  pushl $105
80105a4e:	6a 69                	push   $0x69
  jmp alltraps
80105a50:	e9 1a f8 ff ff       	jmp    8010526f <alltraps>

80105a55 <vector106>:
.globl vector106
vector106:
  pushl $0
80105a55:	6a 00                	push   $0x0
  pushl $106
80105a57:	6a 6a                	push   $0x6a
  jmp alltraps
80105a59:	e9 11 f8 ff ff       	jmp    8010526f <alltraps>

80105a5e <vector107>:
.globl vector107
vector107:
  pushl $0
80105a5e:	6a 00                	push   $0x0
  pushl $107
80105a60:	6a 6b                	push   $0x6b
  jmp alltraps
80105a62:	e9 08 f8 ff ff       	jmp    8010526f <alltraps>

80105a67 <vector108>:
.globl vector108
vector108:
  pushl $0
80105a67:	6a 00                	push   $0x0
  pushl $108
80105a69:	6a 6c                	push   $0x6c
  jmp alltraps
80105a6b:	e9 ff f7 ff ff       	jmp    8010526f <alltraps>

80105a70 <vector109>:
.globl vector109
vector109:
  pushl $0
80105a70:	6a 00                	push   $0x0
  pushl $109
80105a72:	6a 6d                	push   $0x6d
  jmp alltraps
80105a74:	e9 f6 f7 ff ff       	jmp    8010526f <alltraps>

80105a79 <vector110>:
.globl vector110
vector110:
  pushl $0
80105a79:	6a 00                	push   $0x0
  pushl $110
80105a7b:	6a 6e                	push   $0x6e
  jmp alltraps
80105a7d:	e9 ed f7 ff ff       	jmp    8010526f <alltraps>

80105a82 <vector111>:
.globl vector111
vector111:
  pushl $0
80105a82:	6a 00                	push   $0x0
  pushl $111
80105a84:	6a 6f                	push   $0x6f
  jmp alltraps
80105a86:	e9 e4 f7 ff ff       	jmp    8010526f <alltraps>

80105a8b <vector112>:
.globl vector112
vector112:
  pushl $0
80105a8b:	6a 00                	push   $0x0
  pushl $112
80105a8d:	6a 70                	push   $0x70
  jmp alltraps
80105a8f:	e9 db f7 ff ff       	jmp    8010526f <alltraps>

80105a94 <vector113>:
.globl vector113
vector113:
  pushl $0
80105a94:	6a 00                	push   $0x0
  pushl $113
80105a96:	6a 71                	push   $0x71
  jmp alltraps
80105a98:	e9 d2 f7 ff ff       	jmp    8010526f <alltraps>

80105a9d <vector114>:
.globl vector114
vector114:
  pushl $0
80105a9d:	6a 00                	push   $0x0
  pushl $114
80105a9f:	6a 72                	push   $0x72
  jmp alltraps
80105aa1:	e9 c9 f7 ff ff       	jmp    8010526f <alltraps>

80105aa6 <vector115>:
.globl vector115
vector115:
  pushl $0
80105aa6:	6a 00                	push   $0x0
  pushl $115
80105aa8:	6a 73                	push   $0x73
  jmp alltraps
80105aaa:	e9 c0 f7 ff ff       	jmp    8010526f <alltraps>

80105aaf <vector116>:
.globl vector116
vector116:
  pushl $0
80105aaf:	6a 00                	push   $0x0
  pushl $116
80105ab1:	6a 74                	push   $0x74
  jmp alltraps
80105ab3:	e9 b7 f7 ff ff       	jmp    8010526f <alltraps>

80105ab8 <vector117>:
.globl vector117
vector117:
  pushl $0
80105ab8:	6a 00                	push   $0x0
  pushl $117
80105aba:	6a 75                	push   $0x75
  jmp alltraps
80105abc:	e9 ae f7 ff ff       	jmp    8010526f <alltraps>

80105ac1 <vector118>:
.globl vector118
vector118:
  pushl $0
80105ac1:	6a 00                	push   $0x0
  pushl $118
80105ac3:	6a 76                	push   $0x76
  jmp alltraps
80105ac5:	e9 a5 f7 ff ff       	jmp    8010526f <alltraps>

80105aca <vector119>:
.globl vector119
vector119:
  pushl $0
80105aca:	6a 00                	push   $0x0
  pushl $119
80105acc:	6a 77                	push   $0x77
  jmp alltraps
80105ace:	e9 9c f7 ff ff       	jmp    8010526f <alltraps>

80105ad3 <vector120>:
.globl vector120
vector120:
  pushl $0
80105ad3:	6a 00                	push   $0x0
  pushl $120
80105ad5:	6a 78                	push   $0x78
  jmp alltraps
80105ad7:	e9 93 f7 ff ff       	jmp    8010526f <alltraps>

80105adc <vector121>:
.globl vector121
vector121:
  pushl $0
80105adc:	6a 00                	push   $0x0
  pushl $121
80105ade:	6a 79                	push   $0x79
  jmp alltraps
80105ae0:	e9 8a f7 ff ff       	jmp    8010526f <alltraps>

80105ae5 <vector122>:
.globl vector122
vector122:
  pushl $0
80105ae5:	6a 00                	push   $0x0
  pushl $122
80105ae7:	6a 7a                	push   $0x7a
  jmp alltraps
80105ae9:	e9 81 f7 ff ff       	jmp    8010526f <alltraps>

80105aee <vector123>:
.globl vector123
vector123:
  pushl $0
80105aee:	6a 00                	push   $0x0
  pushl $123
80105af0:	6a 7b                	push   $0x7b
  jmp alltraps
80105af2:	e9 78 f7 ff ff       	jmp    8010526f <alltraps>

80105af7 <vector124>:
.globl vector124
vector124:
  pushl $0
80105af7:	6a 00                	push   $0x0
  pushl $124
80105af9:	6a 7c                	push   $0x7c
  jmp alltraps
80105afb:	e9 6f f7 ff ff       	jmp    8010526f <alltraps>

80105b00 <vector125>:
.globl vector125
vector125:
  pushl $0
80105b00:	6a 00                	push   $0x0
  pushl $125
80105b02:	6a 7d                	push   $0x7d
  jmp alltraps
80105b04:	e9 66 f7 ff ff       	jmp    8010526f <alltraps>

80105b09 <vector126>:
.globl vector126
vector126:
  pushl $0
80105b09:	6a 00                	push   $0x0
  pushl $126
80105b0b:	6a 7e                	push   $0x7e
  jmp alltraps
80105b0d:	e9 5d f7 ff ff       	jmp    8010526f <alltraps>

80105b12 <vector127>:
.globl vector127
vector127:
  pushl $0
80105b12:	6a 00                	push   $0x0
  pushl $127
80105b14:	6a 7f                	push   $0x7f
  jmp alltraps
80105b16:	e9 54 f7 ff ff       	jmp    8010526f <alltraps>

80105b1b <vector128>:
.globl vector128
vector128:
  pushl $0
80105b1b:	6a 00                	push   $0x0
  pushl $128
80105b1d:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105b22:	e9 48 f7 ff ff       	jmp    8010526f <alltraps>

80105b27 <vector129>:
.globl vector129
vector129:
  pushl $0
80105b27:	6a 00                	push   $0x0
  pushl $129
80105b29:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105b2e:	e9 3c f7 ff ff       	jmp    8010526f <alltraps>

80105b33 <vector130>:
.globl vector130
vector130:
  pushl $0
80105b33:	6a 00                	push   $0x0
  pushl $130
80105b35:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105b3a:	e9 30 f7 ff ff       	jmp    8010526f <alltraps>

80105b3f <vector131>:
.globl vector131
vector131:
  pushl $0
80105b3f:	6a 00                	push   $0x0
  pushl $131
80105b41:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105b46:	e9 24 f7 ff ff       	jmp    8010526f <alltraps>

80105b4b <vector132>:
.globl vector132
vector132:
  pushl $0
80105b4b:	6a 00                	push   $0x0
  pushl $132
80105b4d:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105b52:	e9 18 f7 ff ff       	jmp    8010526f <alltraps>

80105b57 <vector133>:
.globl vector133
vector133:
  pushl $0
80105b57:	6a 00                	push   $0x0
  pushl $133
80105b59:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105b5e:	e9 0c f7 ff ff       	jmp    8010526f <alltraps>

80105b63 <vector134>:
.globl vector134
vector134:
  pushl $0
80105b63:	6a 00                	push   $0x0
  pushl $134
80105b65:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105b6a:	e9 00 f7 ff ff       	jmp    8010526f <alltraps>

80105b6f <vector135>:
.globl vector135
vector135:
  pushl $0
80105b6f:	6a 00                	push   $0x0
  pushl $135
80105b71:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105b76:	e9 f4 f6 ff ff       	jmp    8010526f <alltraps>

80105b7b <vector136>:
.globl vector136
vector136:
  pushl $0
80105b7b:	6a 00                	push   $0x0
  pushl $136
80105b7d:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105b82:	e9 e8 f6 ff ff       	jmp    8010526f <alltraps>

80105b87 <vector137>:
.globl vector137
vector137:
  pushl $0
80105b87:	6a 00                	push   $0x0
  pushl $137
80105b89:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105b8e:	e9 dc f6 ff ff       	jmp    8010526f <alltraps>

80105b93 <vector138>:
.globl vector138
vector138:
  pushl $0
80105b93:	6a 00                	push   $0x0
  pushl $138
80105b95:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105b9a:	e9 d0 f6 ff ff       	jmp    8010526f <alltraps>

80105b9f <vector139>:
.globl vector139
vector139:
  pushl $0
80105b9f:	6a 00                	push   $0x0
  pushl $139
80105ba1:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105ba6:	e9 c4 f6 ff ff       	jmp    8010526f <alltraps>

80105bab <vector140>:
.globl vector140
vector140:
  pushl $0
80105bab:	6a 00                	push   $0x0
  pushl $140
80105bad:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105bb2:	e9 b8 f6 ff ff       	jmp    8010526f <alltraps>

80105bb7 <vector141>:
.globl vector141
vector141:
  pushl $0
80105bb7:	6a 00                	push   $0x0
  pushl $141
80105bb9:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105bbe:	e9 ac f6 ff ff       	jmp    8010526f <alltraps>

80105bc3 <vector142>:
.globl vector142
vector142:
  pushl $0
80105bc3:	6a 00                	push   $0x0
  pushl $142
80105bc5:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105bca:	e9 a0 f6 ff ff       	jmp    8010526f <alltraps>

80105bcf <vector143>:
.globl vector143
vector143:
  pushl $0
80105bcf:	6a 00                	push   $0x0
  pushl $143
80105bd1:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105bd6:	e9 94 f6 ff ff       	jmp    8010526f <alltraps>

80105bdb <vector144>:
.globl vector144
vector144:
  pushl $0
80105bdb:	6a 00                	push   $0x0
  pushl $144
80105bdd:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105be2:	e9 88 f6 ff ff       	jmp    8010526f <alltraps>

80105be7 <vector145>:
.globl vector145
vector145:
  pushl $0
80105be7:	6a 00                	push   $0x0
  pushl $145
80105be9:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105bee:	e9 7c f6 ff ff       	jmp    8010526f <alltraps>

80105bf3 <vector146>:
.globl vector146
vector146:
  pushl $0
80105bf3:	6a 00                	push   $0x0
  pushl $146
80105bf5:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105bfa:	e9 70 f6 ff ff       	jmp    8010526f <alltraps>

80105bff <vector147>:
.globl vector147
vector147:
  pushl $0
80105bff:	6a 00                	push   $0x0
  pushl $147
80105c01:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105c06:	e9 64 f6 ff ff       	jmp    8010526f <alltraps>

80105c0b <vector148>:
.globl vector148
vector148:
  pushl $0
80105c0b:	6a 00                	push   $0x0
  pushl $148
80105c0d:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105c12:	e9 58 f6 ff ff       	jmp    8010526f <alltraps>

80105c17 <vector149>:
.globl vector149
vector149:
  pushl $0
80105c17:	6a 00                	push   $0x0
  pushl $149
80105c19:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105c1e:	e9 4c f6 ff ff       	jmp    8010526f <alltraps>

80105c23 <vector150>:
.globl vector150
vector150:
  pushl $0
80105c23:	6a 00                	push   $0x0
  pushl $150
80105c25:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105c2a:	e9 40 f6 ff ff       	jmp    8010526f <alltraps>

80105c2f <vector151>:
.globl vector151
vector151:
  pushl $0
80105c2f:	6a 00                	push   $0x0
  pushl $151
80105c31:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105c36:	e9 34 f6 ff ff       	jmp    8010526f <alltraps>

80105c3b <vector152>:
.globl vector152
vector152:
  pushl $0
80105c3b:	6a 00                	push   $0x0
  pushl $152
80105c3d:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105c42:	e9 28 f6 ff ff       	jmp    8010526f <alltraps>

80105c47 <vector153>:
.globl vector153
vector153:
  pushl $0
80105c47:	6a 00                	push   $0x0
  pushl $153
80105c49:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105c4e:	e9 1c f6 ff ff       	jmp    8010526f <alltraps>

80105c53 <vector154>:
.globl vector154
vector154:
  pushl $0
80105c53:	6a 00                	push   $0x0
  pushl $154
80105c55:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105c5a:	e9 10 f6 ff ff       	jmp    8010526f <alltraps>

80105c5f <vector155>:
.globl vector155
vector155:
  pushl $0
80105c5f:	6a 00                	push   $0x0
  pushl $155
80105c61:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105c66:	e9 04 f6 ff ff       	jmp    8010526f <alltraps>

80105c6b <vector156>:
.globl vector156
vector156:
  pushl $0
80105c6b:	6a 00                	push   $0x0
  pushl $156
80105c6d:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105c72:	e9 f8 f5 ff ff       	jmp    8010526f <alltraps>

80105c77 <vector157>:
.globl vector157
vector157:
  pushl $0
80105c77:	6a 00                	push   $0x0
  pushl $157
80105c79:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105c7e:	e9 ec f5 ff ff       	jmp    8010526f <alltraps>

80105c83 <vector158>:
.globl vector158
vector158:
  pushl $0
80105c83:	6a 00                	push   $0x0
  pushl $158
80105c85:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105c8a:	e9 e0 f5 ff ff       	jmp    8010526f <alltraps>

80105c8f <vector159>:
.globl vector159
vector159:
  pushl $0
80105c8f:	6a 00                	push   $0x0
  pushl $159
80105c91:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105c96:	e9 d4 f5 ff ff       	jmp    8010526f <alltraps>

80105c9b <vector160>:
.globl vector160
vector160:
  pushl $0
80105c9b:	6a 00                	push   $0x0
  pushl $160
80105c9d:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105ca2:	e9 c8 f5 ff ff       	jmp    8010526f <alltraps>

80105ca7 <vector161>:
.globl vector161
vector161:
  pushl $0
80105ca7:	6a 00                	push   $0x0
  pushl $161
80105ca9:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105cae:	e9 bc f5 ff ff       	jmp    8010526f <alltraps>

80105cb3 <vector162>:
.globl vector162
vector162:
  pushl $0
80105cb3:	6a 00                	push   $0x0
  pushl $162
80105cb5:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105cba:	e9 b0 f5 ff ff       	jmp    8010526f <alltraps>

80105cbf <vector163>:
.globl vector163
vector163:
  pushl $0
80105cbf:	6a 00                	push   $0x0
  pushl $163
80105cc1:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105cc6:	e9 a4 f5 ff ff       	jmp    8010526f <alltraps>

80105ccb <vector164>:
.globl vector164
vector164:
  pushl $0
80105ccb:	6a 00                	push   $0x0
  pushl $164
80105ccd:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105cd2:	e9 98 f5 ff ff       	jmp    8010526f <alltraps>

80105cd7 <vector165>:
.globl vector165
vector165:
  pushl $0
80105cd7:	6a 00                	push   $0x0
  pushl $165
80105cd9:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105cde:	e9 8c f5 ff ff       	jmp    8010526f <alltraps>

80105ce3 <vector166>:
.globl vector166
vector166:
  pushl $0
80105ce3:	6a 00                	push   $0x0
  pushl $166
80105ce5:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105cea:	e9 80 f5 ff ff       	jmp    8010526f <alltraps>

80105cef <vector167>:
.globl vector167
vector167:
  pushl $0
80105cef:	6a 00                	push   $0x0
  pushl $167
80105cf1:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105cf6:	e9 74 f5 ff ff       	jmp    8010526f <alltraps>

80105cfb <vector168>:
.globl vector168
vector168:
  pushl $0
80105cfb:	6a 00                	push   $0x0
  pushl $168
80105cfd:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105d02:	e9 68 f5 ff ff       	jmp    8010526f <alltraps>

80105d07 <vector169>:
.globl vector169
vector169:
  pushl $0
80105d07:	6a 00                	push   $0x0
  pushl $169
80105d09:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105d0e:	e9 5c f5 ff ff       	jmp    8010526f <alltraps>

80105d13 <vector170>:
.globl vector170
vector170:
  pushl $0
80105d13:	6a 00                	push   $0x0
  pushl $170
80105d15:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105d1a:	e9 50 f5 ff ff       	jmp    8010526f <alltraps>

80105d1f <vector171>:
.globl vector171
vector171:
  pushl $0
80105d1f:	6a 00                	push   $0x0
  pushl $171
80105d21:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105d26:	e9 44 f5 ff ff       	jmp    8010526f <alltraps>

80105d2b <vector172>:
.globl vector172
vector172:
  pushl $0
80105d2b:	6a 00                	push   $0x0
  pushl $172
80105d2d:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105d32:	e9 38 f5 ff ff       	jmp    8010526f <alltraps>

80105d37 <vector173>:
.globl vector173
vector173:
  pushl $0
80105d37:	6a 00                	push   $0x0
  pushl $173
80105d39:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105d3e:	e9 2c f5 ff ff       	jmp    8010526f <alltraps>

80105d43 <vector174>:
.globl vector174
vector174:
  pushl $0
80105d43:	6a 00                	push   $0x0
  pushl $174
80105d45:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105d4a:	e9 20 f5 ff ff       	jmp    8010526f <alltraps>

80105d4f <vector175>:
.globl vector175
vector175:
  pushl $0
80105d4f:	6a 00                	push   $0x0
  pushl $175
80105d51:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105d56:	e9 14 f5 ff ff       	jmp    8010526f <alltraps>

80105d5b <vector176>:
.globl vector176
vector176:
  pushl $0
80105d5b:	6a 00                	push   $0x0
  pushl $176
80105d5d:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105d62:	e9 08 f5 ff ff       	jmp    8010526f <alltraps>

80105d67 <vector177>:
.globl vector177
vector177:
  pushl $0
80105d67:	6a 00                	push   $0x0
  pushl $177
80105d69:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105d6e:	e9 fc f4 ff ff       	jmp    8010526f <alltraps>

80105d73 <vector178>:
.globl vector178
vector178:
  pushl $0
80105d73:	6a 00                	push   $0x0
  pushl $178
80105d75:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105d7a:	e9 f0 f4 ff ff       	jmp    8010526f <alltraps>

80105d7f <vector179>:
.globl vector179
vector179:
  pushl $0
80105d7f:	6a 00                	push   $0x0
  pushl $179
80105d81:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105d86:	e9 e4 f4 ff ff       	jmp    8010526f <alltraps>

80105d8b <vector180>:
.globl vector180
vector180:
  pushl $0
80105d8b:	6a 00                	push   $0x0
  pushl $180
80105d8d:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105d92:	e9 d8 f4 ff ff       	jmp    8010526f <alltraps>

80105d97 <vector181>:
.globl vector181
vector181:
  pushl $0
80105d97:	6a 00                	push   $0x0
  pushl $181
80105d99:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105d9e:	e9 cc f4 ff ff       	jmp    8010526f <alltraps>

80105da3 <vector182>:
.globl vector182
vector182:
  pushl $0
80105da3:	6a 00                	push   $0x0
  pushl $182
80105da5:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105daa:	e9 c0 f4 ff ff       	jmp    8010526f <alltraps>

80105daf <vector183>:
.globl vector183
vector183:
  pushl $0
80105daf:	6a 00                	push   $0x0
  pushl $183
80105db1:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105db6:	e9 b4 f4 ff ff       	jmp    8010526f <alltraps>

80105dbb <vector184>:
.globl vector184
vector184:
  pushl $0
80105dbb:	6a 00                	push   $0x0
  pushl $184
80105dbd:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105dc2:	e9 a8 f4 ff ff       	jmp    8010526f <alltraps>

80105dc7 <vector185>:
.globl vector185
vector185:
  pushl $0
80105dc7:	6a 00                	push   $0x0
  pushl $185
80105dc9:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105dce:	e9 9c f4 ff ff       	jmp    8010526f <alltraps>

80105dd3 <vector186>:
.globl vector186
vector186:
  pushl $0
80105dd3:	6a 00                	push   $0x0
  pushl $186
80105dd5:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105dda:	e9 90 f4 ff ff       	jmp    8010526f <alltraps>

80105ddf <vector187>:
.globl vector187
vector187:
  pushl $0
80105ddf:	6a 00                	push   $0x0
  pushl $187
80105de1:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105de6:	e9 84 f4 ff ff       	jmp    8010526f <alltraps>

80105deb <vector188>:
.globl vector188
vector188:
  pushl $0
80105deb:	6a 00                	push   $0x0
  pushl $188
80105ded:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105df2:	e9 78 f4 ff ff       	jmp    8010526f <alltraps>

80105df7 <vector189>:
.globl vector189
vector189:
  pushl $0
80105df7:	6a 00                	push   $0x0
  pushl $189
80105df9:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105dfe:	e9 6c f4 ff ff       	jmp    8010526f <alltraps>

80105e03 <vector190>:
.globl vector190
vector190:
  pushl $0
80105e03:	6a 00                	push   $0x0
  pushl $190
80105e05:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105e0a:	e9 60 f4 ff ff       	jmp    8010526f <alltraps>

80105e0f <vector191>:
.globl vector191
vector191:
  pushl $0
80105e0f:	6a 00                	push   $0x0
  pushl $191
80105e11:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105e16:	e9 54 f4 ff ff       	jmp    8010526f <alltraps>

80105e1b <vector192>:
.globl vector192
vector192:
  pushl $0
80105e1b:	6a 00                	push   $0x0
  pushl $192
80105e1d:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105e22:	e9 48 f4 ff ff       	jmp    8010526f <alltraps>

80105e27 <vector193>:
.globl vector193
vector193:
  pushl $0
80105e27:	6a 00                	push   $0x0
  pushl $193
80105e29:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105e2e:	e9 3c f4 ff ff       	jmp    8010526f <alltraps>

80105e33 <vector194>:
.globl vector194
vector194:
  pushl $0
80105e33:	6a 00                	push   $0x0
  pushl $194
80105e35:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105e3a:	e9 30 f4 ff ff       	jmp    8010526f <alltraps>

80105e3f <vector195>:
.globl vector195
vector195:
  pushl $0
80105e3f:	6a 00                	push   $0x0
  pushl $195
80105e41:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105e46:	e9 24 f4 ff ff       	jmp    8010526f <alltraps>

80105e4b <vector196>:
.globl vector196
vector196:
  pushl $0
80105e4b:	6a 00                	push   $0x0
  pushl $196
80105e4d:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105e52:	e9 18 f4 ff ff       	jmp    8010526f <alltraps>

80105e57 <vector197>:
.globl vector197
vector197:
  pushl $0
80105e57:	6a 00                	push   $0x0
  pushl $197
80105e59:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105e5e:	e9 0c f4 ff ff       	jmp    8010526f <alltraps>

80105e63 <vector198>:
.globl vector198
vector198:
  pushl $0
80105e63:	6a 00                	push   $0x0
  pushl $198
80105e65:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105e6a:	e9 00 f4 ff ff       	jmp    8010526f <alltraps>

80105e6f <vector199>:
.globl vector199
vector199:
  pushl $0
80105e6f:	6a 00                	push   $0x0
  pushl $199
80105e71:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105e76:	e9 f4 f3 ff ff       	jmp    8010526f <alltraps>

80105e7b <vector200>:
.globl vector200
vector200:
  pushl $0
80105e7b:	6a 00                	push   $0x0
  pushl $200
80105e7d:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105e82:	e9 e8 f3 ff ff       	jmp    8010526f <alltraps>

80105e87 <vector201>:
.globl vector201
vector201:
  pushl $0
80105e87:	6a 00                	push   $0x0
  pushl $201
80105e89:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105e8e:	e9 dc f3 ff ff       	jmp    8010526f <alltraps>

80105e93 <vector202>:
.globl vector202
vector202:
  pushl $0
80105e93:	6a 00                	push   $0x0
  pushl $202
80105e95:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105e9a:	e9 d0 f3 ff ff       	jmp    8010526f <alltraps>

80105e9f <vector203>:
.globl vector203
vector203:
  pushl $0
80105e9f:	6a 00                	push   $0x0
  pushl $203
80105ea1:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ea6:	e9 c4 f3 ff ff       	jmp    8010526f <alltraps>

80105eab <vector204>:
.globl vector204
vector204:
  pushl $0
80105eab:	6a 00                	push   $0x0
  pushl $204
80105ead:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105eb2:	e9 b8 f3 ff ff       	jmp    8010526f <alltraps>

80105eb7 <vector205>:
.globl vector205
vector205:
  pushl $0
80105eb7:	6a 00                	push   $0x0
  pushl $205
80105eb9:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105ebe:	e9 ac f3 ff ff       	jmp    8010526f <alltraps>

80105ec3 <vector206>:
.globl vector206
vector206:
  pushl $0
80105ec3:	6a 00                	push   $0x0
  pushl $206
80105ec5:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105eca:	e9 a0 f3 ff ff       	jmp    8010526f <alltraps>

80105ecf <vector207>:
.globl vector207
vector207:
  pushl $0
80105ecf:	6a 00                	push   $0x0
  pushl $207
80105ed1:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105ed6:	e9 94 f3 ff ff       	jmp    8010526f <alltraps>

80105edb <vector208>:
.globl vector208
vector208:
  pushl $0
80105edb:	6a 00                	push   $0x0
  pushl $208
80105edd:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105ee2:	e9 88 f3 ff ff       	jmp    8010526f <alltraps>

80105ee7 <vector209>:
.globl vector209
vector209:
  pushl $0
80105ee7:	6a 00                	push   $0x0
  pushl $209
80105ee9:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105eee:	e9 7c f3 ff ff       	jmp    8010526f <alltraps>

80105ef3 <vector210>:
.globl vector210
vector210:
  pushl $0
80105ef3:	6a 00                	push   $0x0
  pushl $210
80105ef5:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105efa:	e9 70 f3 ff ff       	jmp    8010526f <alltraps>

80105eff <vector211>:
.globl vector211
vector211:
  pushl $0
80105eff:	6a 00                	push   $0x0
  pushl $211
80105f01:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105f06:	e9 64 f3 ff ff       	jmp    8010526f <alltraps>

80105f0b <vector212>:
.globl vector212
vector212:
  pushl $0
80105f0b:	6a 00                	push   $0x0
  pushl $212
80105f0d:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105f12:	e9 58 f3 ff ff       	jmp    8010526f <alltraps>

80105f17 <vector213>:
.globl vector213
vector213:
  pushl $0
80105f17:	6a 00                	push   $0x0
  pushl $213
80105f19:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105f1e:	e9 4c f3 ff ff       	jmp    8010526f <alltraps>

80105f23 <vector214>:
.globl vector214
vector214:
  pushl $0
80105f23:	6a 00                	push   $0x0
  pushl $214
80105f25:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105f2a:	e9 40 f3 ff ff       	jmp    8010526f <alltraps>

80105f2f <vector215>:
.globl vector215
vector215:
  pushl $0
80105f2f:	6a 00                	push   $0x0
  pushl $215
80105f31:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105f36:	e9 34 f3 ff ff       	jmp    8010526f <alltraps>

80105f3b <vector216>:
.globl vector216
vector216:
  pushl $0
80105f3b:	6a 00                	push   $0x0
  pushl $216
80105f3d:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105f42:	e9 28 f3 ff ff       	jmp    8010526f <alltraps>

80105f47 <vector217>:
.globl vector217
vector217:
  pushl $0
80105f47:	6a 00                	push   $0x0
  pushl $217
80105f49:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105f4e:	e9 1c f3 ff ff       	jmp    8010526f <alltraps>

80105f53 <vector218>:
.globl vector218
vector218:
  pushl $0
80105f53:	6a 00                	push   $0x0
  pushl $218
80105f55:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105f5a:	e9 10 f3 ff ff       	jmp    8010526f <alltraps>

80105f5f <vector219>:
.globl vector219
vector219:
  pushl $0
80105f5f:	6a 00                	push   $0x0
  pushl $219
80105f61:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105f66:	e9 04 f3 ff ff       	jmp    8010526f <alltraps>

80105f6b <vector220>:
.globl vector220
vector220:
  pushl $0
80105f6b:	6a 00                	push   $0x0
  pushl $220
80105f6d:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105f72:	e9 f8 f2 ff ff       	jmp    8010526f <alltraps>

80105f77 <vector221>:
.globl vector221
vector221:
  pushl $0
80105f77:	6a 00                	push   $0x0
  pushl $221
80105f79:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105f7e:	e9 ec f2 ff ff       	jmp    8010526f <alltraps>

80105f83 <vector222>:
.globl vector222
vector222:
  pushl $0
80105f83:	6a 00                	push   $0x0
  pushl $222
80105f85:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105f8a:	e9 e0 f2 ff ff       	jmp    8010526f <alltraps>

80105f8f <vector223>:
.globl vector223
vector223:
  pushl $0
80105f8f:	6a 00                	push   $0x0
  pushl $223
80105f91:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105f96:	e9 d4 f2 ff ff       	jmp    8010526f <alltraps>

80105f9b <vector224>:
.globl vector224
vector224:
  pushl $0
80105f9b:	6a 00                	push   $0x0
  pushl $224
80105f9d:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105fa2:	e9 c8 f2 ff ff       	jmp    8010526f <alltraps>

80105fa7 <vector225>:
.globl vector225
vector225:
  pushl $0
80105fa7:	6a 00                	push   $0x0
  pushl $225
80105fa9:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105fae:	e9 bc f2 ff ff       	jmp    8010526f <alltraps>

80105fb3 <vector226>:
.globl vector226
vector226:
  pushl $0
80105fb3:	6a 00                	push   $0x0
  pushl $226
80105fb5:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105fba:	e9 b0 f2 ff ff       	jmp    8010526f <alltraps>

80105fbf <vector227>:
.globl vector227
vector227:
  pushl $0
80105fbf:	6a 00                	push   $0x0
  pushl $227
80105fc1:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105fc6:	e9 a4 f2 ff ff       	jmp    8010526f <alltraps>

80105fcb <vector228>:
.globl vector228
vector228:
  pushl $0
80105fcb:	6a 00                	push   $0x0
  pushl $228
80105fcd:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105fd2:	e9 98 f2 ff ff       	jmp    8010526f <alltraps>

80105fd7 <vector229>:
.globl vector229
vector229:
  pushl $0
80105fd7:	6a 00                	push   $0x0
  pushl $229
80105fd9:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105fde:	e9 8c f2 ff ff       	jmp    8010526f <alltraps>

80105fe3 <vector230>:
.globl vector230
vector230:
  pushl $0
80105fe3:	6a 00                	push   $0x0
  pushl $230
80105fe5:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105fea:	e9 80 f2 ff ff       	jmp    8010526f <alltraps>

80105fef <vector231>:
.globl vector231
vector231:
  pushl $0
80105fef:	6a 00                	push   $0x0
  pushl $231
80105ff1:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105ff6:	e9 74 f2 ff ff       	jmp    8010526f <alltraps>

80105ffb <vector232>:
.globl vector232
vector232:
  pushl $0
80105ffb:	6a 00                	push   $0x0
  pushl $232
80105ffd:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80106002:	e9 68 f2 ff ff       	jmp    8010526f <alltraps>

80106007 <vector233>:
.globl vector233
vector233:
  pushl $0
80106007:	6a 00                	push   $0x0
  pushl $233
80106009:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010600e:	e9 5c f2 ff ff       	jmp    8010526f <alltraps>

80106013 <vector234>:
.globl vector234
vector234:
  pushl $0
80106013:	6a 00                	push   $0x0
  pushl $234
80106015:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010601a:	e9 50 f2 ff ff       	jmp    8010526f <alltraps>

8010601f <vector235>:
.globl vector235
vector235:
  pushl $0
8010601f:	6a 00                	push   $0x0
  pushl $235
80106021:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80106026:	e9 44 f2 ff ff       	jmp    8010526f <alltraps>

8010602b <vector236>:
.globl vector236
vector236:
  pushl $0
8010602b:	6a 00                	push   $0x0
  pushl $236
8010602d:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80106032:	e9 38 f2 ff ff       	jmp    8010526f <alltraps>

80106037 <vector237>:
.globl vector237
vector237:
  pushl $0
80106037:	6a 00                	push   $0x0
  pushl $237
80106039:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010603e:	e9 2c f2 ff ff       	jmp    8010526f <alltraps>

80106043 <vector238>:
.globl vector238
vector238:
  pushl $0
80106043:	6a 00                	push   $0x0
  pushl $238
80106045:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
8010604a:	e9 20 f2 ff ff       	jmp    8010526f <alltraps>

8010604f <vector239>:
.globl vector239
vector239:
  pushl $0
8010604f:	6a 00                	push   $0x0
  pushl $239
80106051:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80106056:	e9 14 f2 ff ff       	jmp    8010526f <alltraps>

8010605b <vector240>:
.globl vector240
vector240:
  pushl $0
8010605b:	6a 00                	push   $0x0
  pushl $240
8010605d:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80106062:	e9 08 f2 ff ff       	jmp    8010526f <alltraps>

80106067 <vector241>:
.globl vector241
vector241:
  pushl $0
80106067:	6a 00                	push   $0x0
  pushl $241
80106069:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010606e:	e9 fc f1 ff ff       	jmp    8010526f <alltraps>

80106073 <vector242>:
.globl vector242
vector242:
  pushl $0
80106073:	6a 00                	push   $0x0
  pushl $242
80106075:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
8010607a:	e9 f0 f1 ff ff       	jmp    8010526f <alltraps>

8010607f <vector243>:
.globl vector243
vector243:
  pushl $0
8010607f:	6a 00                	push   $0x0
  pushl $243
80106081:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80106086:	e9 e4 f1 ff ff       	jmp    8010526f <alltraps>

8010608b <vector244>:
.globl vector244
vector244:
  pushl $0
8010608b:	6a 00                	push   $0x0
  pushl $244
8010608d:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80106092:	e9 d8 f1 ff ff       	jmp    8010526f <alltraps>

80106097 <vector245>:
.globl vector245
vector245:
  pushl $0
80106097:	6a 00                	push   $0x0
  pushl $245
80106099:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010609e:	e9 cc f1 ff ff       	jmp    8010526f <alltraps>

801060a3 <vector246>:
.globl vector246
vector246:
  pushl $0
801060a3:	6a 00                	push   $0x0
  pushl $246
801060a5:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801060aa:	e9 c0 f1 ff ff       	jmp    8010526f <alltraps>

801060af <vector247>:
.globl vector247
vector247:
  pushl $0
801060af:	6a 00                	push   $0x0
  pushl $247
801060b1:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801060b6:	e9 b4 f1 ff ff       	jmp    8010526f <alltraps>

801060bb <vector248>:
.globl vector248
vector248:
  pushl $0
801060bb:	6a 00                	push   $0x0
  pushl $248
801060bd:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801060c2:	e9 a8 f1 ff ff       	jmp    8010526f <alltraps>

801060c7 <vector249>:
.globl vector249
vector249:
  pushl $0
801060c7:	6a 00                	push   $0x0
  pushl $249
801060c9:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801060ce:	e9 9c f1 ff ff       	jmp    8010526f <alltraps>

801060d3 <vector250>:
.globl vector250
vector250:
  pushl $0
801060d3:	6a 00                	push   $0x0
  pushl $250
801060d5:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801060da:	e9 90 f1 ff ff       	jmp    8010526f <alltraps>

801060df <vector251>:
.globl vector251
vector251:
  pushl $0
801060df:	6a 00                	push   $0x0
  pushl $251
801060e1:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801060e6:	e9 84 f1 ff ff       	jmp    8010526f <alltraps>

801060eb <vector252>:
.globl vector252
vector252:
  pushl $0
801060eb:	6a 00                	push   $0x0
  pushl $252
801060ed:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801060f2:	e9 78 f1 ff ff       	jmp    8010526f <alltraps>

801060f7 <vector253>:
.globl vector253
vector253:
  pushl $0
801060f7:	6a 00                	push   $0x0
  pushl $253
801060f9:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801060fe:	e9 6c f1 ff ff       	jmp    8010526f <alltraps>

80106103 <vector254>:
.globl vector254
vector254:
  pushl $0
80106103:	6a 00                	push   $0x0
  pushl $254
80106105:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010610a:	e9 60 f1 ff ff       	jmp    8010526f <alltraps>

8010610f <vector255>:
.globl vector255
vector255:
  pushl $0
8010610f:	6a 00                	push   $0x0
  pushl $255
80106111:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80106116:	e9 54 f1 ff ff       	jmp    8010526f <alltraps>

8010611b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010611b:	55                   	push   %ebp
8010611c:	89 e5                	mov    %esp,%ebp
8010611e:	57                   	push   %edi
8010611f:	56                   	push   %esi
80106120:	53                   	push   %ebx
80106121:	83 ec 0c             	sub    $0xc,%esp
80106124:	89 d3                	mov    %edx,%ebx
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80106126:	c1 ea 16             	shr    $0x16,%edx
80106129:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
8010612c:	8b 37                	mov    (%edi),%esi
8010612e:	f7 c6 01 00 00 00    	test   $0x1,%esi
80106134:	74 20                	je     80106156 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80106136:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
8010613c:	81 c6 00 00 00 80    	add    $0x80000000,%esi
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80106142:	c1 eb 0c             	shr    $0xc,%ebx
80106145:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
8010614b:	8d 04 9e             	lea    (%esi,%ebx,4),%eax
}
8010614e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106151:	5b                   	pop    %ebx
80106152:	5e                   	pop    %esi
80106153:	5f                   	pop    %edi
80106154:	5d                   	pop    %ebp
80106155:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80106156:	85 c9                	test   %ecx,%ecx
80106158:	74 2b                	je     80106185 <walkpgdir+0x6a>
8010615a:	e8 30 c0 ff ff       	call   8010218f <kalloc>
8010615f:	89 c6                	mov    %eax,%esi
80106161:	85 c0                	test   %eax,%eax
80106163:	74 20                	je     80106185 <walkpgdir+0x6a>
    memset(pgtab, 0, PGSIZE);
80106165:	83 ec 04             	sub    $0x4,%esp
80106168:	68 00 10 00 00       	push   $0x1000
8010616d:	6a 00                	push   $0x0
8010616f:	50                   	push   %eax
80106170:	e8 c9 de ff ff       	call   8010403e <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80106175:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010617b:	83 c8 07             	or     $0x7,%eax
8010617e:	89 07                	mov    %eax,(%edi)
80106180:	83 c4 10             	add    $0x10,%esp
80106183:	eb bd                	jmp    80106142 <walkpgdir+0x27>
      return 0;
80106185:	b8 00 00 00 00       	mov    $0x0,%eax
8010618a:	eb c2                	jmp    8010614e <walkpgdir+0x33>

8010618c <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010618c:	55                   	push   %ebp
8010618d:	89 e5                	mov    %esp,%ebp
8010618f:	57                   	push   %edi
80106190:	56                   	push   %esi
80106191:	53                   	push   %ebx
80106192:	83 ec 1c             	sub    $0x1c,%esp
80106195:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106198:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
8010619b:	89 d3                	mov    %edx,%ebx
8010619d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801061a3:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
801061a7:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801061ad:	b9 01 00 00 00       	mov    $0x1,%ecx
801061b2:	89 da                	mov    %ebx,%edx
801061b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801061b7:	e8 5f ff ff ff       	call   8010611b <walkpgdir>
801061bc:	85 c0                	test   %eax,%eax
801061be:	74 2e                	je     801061ee <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
801061c0:	f6 00 01             	testb  $0x1,(%eax)
801061c3:	75 1c                	jne    801061e1 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
801061c5:	89 f2                	mov    %esi,%edx
801061c7:	0b 55 0c             	or     0xc(%ebp),%edx
801061ca:	83 ca 01             	or     $0x1,%edx
801061cd:	89 10                	mov    %edx,(%eax)
    if(a == last)
801061cf:	39 fb                	cmp    %edi,%ebx
801061d1:	74 28                	je     801061fb <mappages+0x6f>
      break;
    a += PGSIZE;
801061d3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
801061d9:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801061df:	eb cc                	jmp    801061ad <mappages+0x21>
      panic("remap");
801061e1:	83 ec 0c             	sub    $0xc,%esp
801061e4:	68 04 73 10 80       	push   $0x80107304
801061e9:	e8 6e a1 ff ff       	call   8010035c <panic>
      return -1;
801061ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
801061f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061f6:	5b                   	pop    %ebx
801061f7:	5e                   	pop    %esi
801061f8:	5f                   	pop    %edi
801061f9:	5d                   	pop    %ebp
801061fa:	c3                   	ret    
  return 0;
801061fb:	b8 00 00 00 00       	mov    $0x0,%eax
80106200:	eb f1                	jmp    801061f3 <mappages+0x67>

80106202 <seginit>:
{
80106202:	f3 0f 1e fb          	endbr32 
80106206:	55                   	push   %ebp
80106207:	89 e5                	mov    %esp,%ebp
80106209:	53                   	push   %ebx
8010620a:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
8010620d:	e8 07 d1 ff ff       	call   80103319 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80106212:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80106218:	66 c7 80 58 4c 11 80 	movw   $0xffff,-0x7feeb3a8(%eax)
8010621f:	ff ff 
80106221:	66 c7 80 5a 4c 11 80 	movw   $0x0,-0x7feeb3a6(%eax)
80106228:	00 00 
8010622a:	c6 80 5c 4c 11 80 00 	movb   $0x0,-0x7feeb3a4(%eax)
80106231:	0f b6 88 5d 4c 11 80 	movzbl -0x7feeb3a3(%eax),%ecx
80106238:	83 e1 f0             	and    $0xfffffff0,%ecx
8010623b:	83 c9 1a             	or     $0x1a,%ecx
8010623e:	83 e1 9f             	and    $0xffffff9f,%ecx
80106241:	83 c9 80             	or     $0xffffff80,%ecx
80106244:	88 88 5d 4c 11 80    	mov    %cl,-0x7feeb3a3(%eax)
8010624a:	0f b6 88 5e 4c 11 80 	movzbl -0x7feeb3a2(%eax),%ecx
80106251:	83 c9 0f             	or     $0xf,%ecx
80106254:	83 e1 cf             	and    $0xffffffcf,%ecx
80106257:	83 c9 c0             	or     $0xffffffc0,%ecx
8010625a:	88 88 5e 4c 11 80    	mov    %cl,-0x7feeb3a2(%eax)
80106260:	c6 80 5f 4c 11 80 00 	movb   $0x0,-0x7feeb3a1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80106267:	66 c7 80 60 4c 11 80 	movw   $0xffff,-0x7feeb3a0(%eax)
8010626e:	ff ff 
80106270:	66 c7 80 62 4c 11 80 	movw   $0x0,-0x7feeb39e(%eax)
80106277:	00 00 
80106279:	c6 80 64 4c 11 80 00 	movb   $0x0,-0x7feeb39c(%eax)
80106280:	0f b6 88 65 4c 11 80 	movzbl -0x7feeb39b(%eax),%ecx
80106287:	83 e1 f0             	and    $0xfffffff0,%ecx
8010628a:	83 c9 12             	or     $0x12,%ecx
8010628d:	83 e1 9f             	and    $0xffffff9f,%ecx
80106290:	83 c9 80             	or     $0xffffff80,%ecx
80106293:	88 88 65 4c 11 80    	mov    %cl,-0x7feeb39b(%eax)
80106299:	0f b6 88 66 4c 11 80 	movzbl -0x7feeb39a(%eax),%ecx
801062a0:	83 c9 0f             	or     $0xf,%ecx
801062a3:	83 e1 cf             	and    $0xffffffcf,%ecx
801062a6:	83 c9 c0             	or     $0xffffffc0,%ecx
801062a9:	88 88 66 4c 11 80    	mov    %cl,-0x7feeb39a(%eax)
801062af:	c6 80 67 4c 11 80 00 	movb   $0x0,-0x7feeb399(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801062b6:	66 c7 80 68 4c 11 80 	movw   $0xffff,-0x7feeb398(%eax)
801062bd:	ff ff 
801062bf:	66 c7 80 6a 4c 11 80 	movw   $0x0,-0x7feeb396(%eax)
801062c6:	00 00 
801062c8:	c6 80 6c 4c 11 80 00 	movb   $0x0,-0x7feeb394(%eax)
801062cf:	c6 80 6d 4c 11 80 fa 	movb   $0xfa,-0x7feeb393(%eax)
801062d6:	0f b6 88 6e 4c 11 80 	movzbl -0x7feeb392(%eax),%ecx
801062dd:	83 c9 0f             	or     $0xf,%ecx
801062e0:	83 e1 cf             	and    $0xffffffcf,%ecx
801062e3:	83 c9 c0             	or     $0xffffffc0,%ecx
801062e6:	88 88 6e 4c 11 80    	mov    %cl,-0x7feeb392(%eax)
801062ec:	c6 80 6f 4c 11 80 00 	movb   $0x0,-0x7feeb391(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801062f3:	66 c7 80 70 4c 11 80 	movw   $0xffff,-0x7feeb390(%eax)
801062fa:	ff ff 
801062fc:	66 c7 80 72 4c 11 80 	movw   $0x0,-0x7feeb38e(%eax)
80106303:	00 00 
80106305:	c6 80 74 4c 11 80 00 	movb   $0x0,-0x7feeb38c(%eax)
8010630c:	c6 80 75 4c 11 80 f2 	movb   $0xf2,-0x7feeb38b(%eax)
80106313:	0f b6 88 76 4c 11 80 	movzbl -0x7feeb38a(%eax),%ecx
8010631a:	83 c9 0f             	or     $0xf,%ecx
8010631d:	83 e1 cf             	and    $0xffffffcf,%ecx
80106320:	83 c9 c0             	or     $0xffffffc0,%ecx
80106323:	88 88 76 4c 11 80    	mov    %cl,-0x7feeb38a(%eax)
80106329:	c6 80 77 4c 11 80 00 	movb   $0x0,-0x7feeb389(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106330:	05 50 4c 11 80       	add    $0x80114c50,%eax
  pd[0] = size-1;
80106335:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
8010633b:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
8010633f:	c1 e8 10             	shr    $0x10,%eax
80106342:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106346:	8d 45 f2             	lea    -0xe(%ebp),%eax
80106349:	0f 01 10             	lgdtl  (%eax)
}
8010634c:	83 c4 14             	add    $0x14,%esp
8010634f:	5b                   	pop    %ebx
80106350:	5d                   	pop    %ebp
80106351:	c3                   	ret    

80106352 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106352:	f3 0f 1e fb          	endbr32 
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106356:	a1 84 59 11 80       	mov    0x80115984,%eax
8010635b:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106360:	0f 22 d8             	mov    %eax,%cr3
}
80106363:	c3                   	ret    

80106364 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80106364:	f3 0f 1e fb          	endbr32 
80106368:	55                   	push   %ebp
80106369:	89 e5                	mov    %esp,%ebp
8010636b:	57                   	push   %edi
8010636c:	56                   	push   %esi
8010636d:	53                   	push   %ebx
8010636e:	83 ec 1c             	sub    $0x1c,%esp
80106371:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106374:	85 f6                	test   %esi,%esi
80106376:	0f 84 dd 00 00 00    	je     80106459 <switchuvm+0xf5>
    panic("switchuvm: no process");
  if(p->kstack == 0)
8010637c:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80106380:	0f 84 e0 00 00 00    	je     80106466 <switchuvm+0x102>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106386:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
8010638a:	0f 84 e3 00 00 00    	je     80106473 <switchuvm+0x10f>
    panic("switchuvm: no pgdir");

  pushcli();
80106390:	e8 0c db ff ff       	call   80103ea1 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106395:	e8 1f cf ff ff       	call   801032b9 <mycpu>
8010639a:	89 c3                	mov    %eax,%ebx
8010639c:	e8 18 cf ff ff       	call   801032b9 <mycpu>
801063a1:	8d 78 08             	lea    0x8(%eax),%edi
801063a4:	e8 10 cf ff ff       	call   801032b9 <mycpu>
801063a9:	83 c0 08             	add    $0x8,%eax
801063ac:	c1 e8 10             	shr    $0x10,%eax
801063af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801063b2:	e8 02 cf ff ff       	call   801032b9 <mycpu>
801063b7:	83 c0 08             	add    $0x8,%eax
801063ba:	c1 e8 18             	shr    $0x18,%eax
801063bd:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
801063c4:	67 00 
801063c6:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
801063cd:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
801063d1:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
801063d7:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
801063de:	83 e2 f0             	and    $0xfffffff0,%edx
801063e1:	83 ca 19             	or     $0x19,%edx
801063e4:	83 e2 9f             	and    $0xffffff9f,%edx
801063e7:	83 ca 80             	or     $0xffffff80,%edx
801063ea:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
801063f0:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
801063f7:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801063fd:	e8 b7 ce ff ff       	call   801032b9 <mycpu>
80106402:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106409:	83 e2 ef             	and    $0xffffffef,%edx
8010640c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106412:	e8 a2 ce ff ff       	call   801032b9 <mycpu>
80106417:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010641d:	8b 5e 08             	mov    0x8(%esi),%ebx
80106420:	e8 94 ce ff ff       	call   801032b9 <mycpu>
80106425:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010642b:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010642e:	e8 86 ce ff ff       	call   801032b9 <mycpu>
80106433:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106439:	b8 28 00 00 00       	mov    $0x28,%eax
8010643e:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106441:	8b 46 04             	mov    0x4(%esi),%eax
80106444:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106449:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010644c:	e8 91 da ff ff       	call   80103ee2 <popcli>
}
80106451:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106454:	5b                   	pop    %ebx
80106455:	5e                   	pop    %esi
80106456:	5f                   	pop    %edi
80106457:	5d                   	pop    %ebp
80106458:	c3                   	ret    
    panic("switchuvm: no process");
80106459:	83 ec 0c             	sub    $0xc,%esp
8010645c:	68 0a 73 10 80       	push   $0x8010730a
80106461:	e8 f6 9e ff ff       	call   8010035c <panic>
    panic("switchuvm: no kstack");
80106466:	83 ec 0c             	sub    $0xc,%esp
80106469:	68 20 73 10 80       	push   $0x80107320
8010646e:	e8 e9 9e ff ff       	call   8010035c <panic>
    panic("switchuvm: no pgdir");
80106473:	83 ec 0c             	sub    $0xc,%esp
80106476:	68 35 73 10 80       	push   $0x80107335
8010647b:	e8 dc 9e ff ff       	call   8010035c <panic>

80106480 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106480:	f3 0f 1e fb          	endbr32 
80106484:	55                   	push   %ebp
80106485:	89 e5                	mov    %esp,%ebp
80106487:	56                   	push   %esi
80106488:	53                   	push   %ebx
80106489:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010648c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106492:	77 4c                	ja     801064e0 <inituvm+0x60>
    panic("inituvm: more than a page");
  mem = kalloc();
80106494:	e8 f6 bc ff ff       	call   8010218f <kalloc>
80106499:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010649b:	83 ec 04             	sub    $0x4,%esp
8010649e:	68 00 10 00 00       	push   $0x1000
801064a3:	6a 00                	push   $0x0
801064a5:	50                   	push   %eax
801064a6:	e8 93 db ff ff       	call   8010403e <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801064ab:	83 c4 08             	add    $0x8,%esp
801064ae:	6a 06                	push   $0x6
801064b0:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801064b6:	50                   	push   %eax
801064b7:	b9 00 10 00 00       	mov    $0x1000,%ecx
801064bc:	ba 00 00 00 00       	mov    $0x0,%edx
801064c1:	8b 45 08             	mov    0x8(%ebp),%eax
801064c4:	e8 c3 fc ff ff       	call   8010618c <mappages>
  memmove(mem, init, sz);
801064c9:	83 c4 0c             	add    $0xc,%esp
801064cc:	56                   	push   %esi
801064cd:	ff 75 0c             	pushl  0xc(%ebp)
801064d0:	53                   	push   %ebx
801064d1:	e8 e8 db ff ff       	call   801040be <memmove>
}
801064d6:	83 c4 10             	add    $0x10,%esp
801064d9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064dc:	5b                   	pop    %ebx
801064dd:	5e                   	pop    %esi
801064de:	5d                   	pop    %ebp
801064df:	c3                   	ret    
    panic("inituvm: more than a page");
801064e0:	83 ec 0c             	sub    $0xc,%esp
801064e3:	68 49 73 10 80       	push   $0x80107349
801064e8:	e8 6f 9e ff ff       	call   8010035c <panic>

801064ed <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801064ed:	f3 0f 1e fb          	endbr32 
801064f1:	55                   	push   %ebp
801064f2:	89 e5                	mov    %esp,%ebp
801064f4:	57                   	push   %edi
801064f5:	56                   	push   %esi
801064f6:	53                   	push   %ebx
801064f7:	83 ec 0c             	sub    $0xc,%esp
801064fa:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801064fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80106500:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
80106506:	74 3c                	je     80106544 <loaduvm+0x57>
    panic("loaduvm: addr must be page aligned");
80106508:	83 ec 0c             	sub    $0xc,%esp
8010650b:	68 04 74 10 80       	push   $0x80107404
80106510:	e8 47 9e ff ff       	call   8010035c <panic>
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106515:	83 ec 0c             	sub    $0xc,%esp
80106518:	68 63 73 10 80       	push   $0x80107363
8010651d:	e8 3a 9e ff ff       	call   8010035c <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106522:	05 00 00 00 80       	add    $0x80000000,%eax
80106527:	56                   	push   %esi
80106528:	89 da                	mov    %ebx,%edx
8010652a:	03 55 14             	add    0x14(%ebp),%edx
8010652d:	52                   	push   %edx
8010652e:	50                   	push   %eax
8010652f:	ff 75 10             	pushl  0x10(%ebp)
80106532:	e8 d6 b2 ff ff       	call   8010180d <readi>
80106537:	83 c4 10             	add    $0x10,%esp
8010653a:	39 f0                	cmp    %esi,%eax
8010653c:	75 47                	jne    80106585 <loaduvm+0x98>
  for(i = 0; i < sz; i += PGSIZE){
8010653e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106544:	39 fb                	cmp    %edi,%ebx
80106546:	73 30                	jae    80106578 <loaduvm+0x8b>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106548:	89 da                	mov    %ebx,%edx
8010654a:	03 55 0c             	add    0xc(%ebp),%edx
8010654d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106552:	8b 45 08             	mov    0x8(%ebp),%eax
80106555:	e8 c1 fb ff ff       	call   8010611b <walkpgdir>
8010655a:	85 c0                	test   %eax,%eax
8010655c:	74 b7                	je     80106515 <loaduvm+0x28>
    pa = PTE_ADDR(*pte);
8010655e:	8b 00                	mov    (%eax),%eax
80106560:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106565:	89 fe                	mov    %edi,%esi
80106567:	29 de                	sub    %ebx,%esi
80106569:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010656f:	76 b1                	jbe    80106522 <loaduvm+0x35>
      n = PGSIZE;
80106571:	be 00 10 00 00       	mov    $0x1000,%esi
80106576:	eb aa                	jmp    80106522 <loaduvm+0x35>
      return -1;
  }
  return 0;
80106578:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010657d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106580:	5b                   	pop    %ebx
80106581:	5e                   	pop    %esi
80106582:	5f                   	pop    %edi
80106583:	5d                   	pop    %ebp
80106584:	c3                   	ret    
      return -1;
80106585:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010658a:	eb f1                	jmp    8010657d <loaduvm+0x90>

8010658c <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010658c:	f3 0f 1e fb          	endbr32 
80106590:	55                   	push   %ebp
80106591:	89 e5                	mov    %esp,%ebp
80106593:	57                   	push   %edi
80106594:	56                   	push   %esi
80106595:	53                   	push   %ebx
80106596:	83 ec 0c             	sub    $0xc,%esp
80106599:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010659c:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010659f:	73 11                	jae    801065b2 <deallocuvm+0x26>
    return oldsz;

  a = PGROUNDUP(newsz);
801065a1:	8b 45 10             	mov    0x10(%ebp),%eax
801065a4:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801065aa:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801065b0:	eb 19                	jmp    801065cb <deallocuvm+0x3f>
    return oldsz;
801065b2:	89 f8                	mov    %edi,%eax
801065b4:	eb 64                	jmp    8010661a <deallocuvm+0x8e>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801065b6:	c1 eb 16             	shr    $0x16,%ebx
801065b9:	83 c3 01             	add    $0x1,%ebx
801065bc:	c1 e3 16             	shl    $0x16,%ebx
801065bf:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801065c5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801065cb:	39 fb                	cmp    %edi,%ebx
801065cd:	73 48                	jae    80106617 <deallocuvm+0x8b>
    pte = walkpgdir(pgdir, (char*)a, 0);
801065cf:	b9 00 00 00 00       	mov    $0x0,%ecx
801065d4:	89 da                	mov    %ebx,%edx
801065d6:	8b 45 08             	mov    0x8(%ebp),%eax
801065d9:	e8 3d fb ff ff       	call   8010611b <walkpgdir>
801065de:	89 c6                	mov    %eax,%esi
    if(!pte)
801065e0:	85 c0                	test   %eax,%eax
801065e2:	74 d2                	je     801065b6 <deallocuvm+0x2a>
    else if((*pte & PTE_P) != 0){
801065e4:	8b 00                	mov    (%eax),%eax
801065e6:	a8 01                	test   $0x1,%al
801065e8:	74 db                	je     801065c5 <deallocuvm+0x39>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801065ea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801065ef:	74 19                	je     8010660a <deallocuvm+0x7e>
        panic("kfree");
      char *v = P2V(pa);
801065f1:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801065f6:	83 ec 0c             	sub    $0xc,%esp
801065f9:	50                   	push   %eax
801065fa:	e8 69 ba ff ff       	call   80102068 <kfree>
      *pte = 0;
801065ff:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106605:	83 c4 10             	add    $0x10,%esp
80106608:	eb bb                	jmp    801065c5 <deallocuvm+0x39>
        panic("kfree");
8010660a:	83 ec 0c             	sub    $0xc,%esp
8010660d:	68 4e 6c 10 80       	push   $0x80106c4e
80106612:	e8 45 9d ff ff       	call   8010035c <panic>
    }
  }
  return newsz;
80106617:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010661a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010661d:	5b                   	pop    %ebx
8010661e:	5e                   	pop    %esi
8010661f:	5f                   	pop    %edi
80106620:	5d                   	pop    %ebp
80106621:	c3                   	ret    

80106622 <allocuvm>:
{
80106622:	f3 0f 1e fb          	endbr32 
80106626:	55                   	push   %ebp
80106627:	89 e5                	mov    %esp,%ebp
80106629:	57                   	push   %edi
8010662a:	56                   	push   %esi
8010662b:	53                   	push   %ebx
8010662c:	83 ec 1c             	sub    $0x1c,%esp
8010662f:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106632:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106635:	85 ff                	test   %edi,%edi
80106637:	0f 88 c0 00 00 00    	js     801066fd <allocuvm+0xdb>
  if(newsz < oldsz)
8010663d:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106640:	72 11                	jb     80106653 <allocuvm+0x31>
  a = PGROUNDUP(oldsz);
80106642:	8b 45 0c             	mov    0xc(%ebp),%eax
80106645:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
8010664b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
  for(; a < newsz; a += PGSIZE){
80106651:	eb 39                	jmp    8010668c <allocuvm+0x6a>
    return oldsz;
80106653:	8b 45 0c             	mov    0xc(%ebp),%eax
80106656:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106659:	e9 a6 00 00 00       	jmp    80106704 <allocuvm+0xe2>
      cprintf("allocuvm out of memory\n");
8010665e:	83 ec 0c             	sub    $0xc,%esp
80106661:	68 81 73 10 80       	push   $0x80107381
80106666:	e8 be 9f ff ff       	call   80100629 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010666b:	83 c4 0c             	add    $0xc,%esp
8010666e:	ff 75 0c             	pushl  0xc(%ebp)
80106671:	57                   	push   %edi
80106672:	ff 75 08             	pushl  0x8(%ebp)
80106675:	e8 12 ff ff ff       	call   8010658c <deallocuvm>
      return 0;
8010667a:	83 c4 10             	add    $0x10,%esp
8010667d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106684:	eb 7e                	jmp    80106704 <allocuvm+0xe2>
  for(; a < newsz; a += PGSIZE){
80106686:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010668c:	39 fe                	cmp    %edi,%esi
8010668e:	73 74                	jae    80106704 <allocuvm+0xe2>
    mem = kalloc();
80106690:	e8 fa ba ff ff       	call   8010218f <kalloc>
80106695:	89 c3                	mov    %eax,%ebx
    if(mem == 0){
80106697:	85 c0                	test   %eax,%eax
80106699:	74 c3                	je     8010665e <allocuvm+0x3c>
    memset(mem, 0, PGSIZE);
8010669b:	83 ec 04             	sub    $0x4,%esp
8010669e:	68 00 10 00 00       	push   $0x1000
801066a3:	6a 00                	push   $0x0
801066a5:	50                   	push   %eax
801066a6:	e8 93 d9 ff ff       	call   8010403e <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801066ab:	83 c4 08             	add    $0x8,%esp
801066ae:	6a 06                	push   $0x6
801066b0:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801066b6:	50                   	push   %eax
801066b7:	b9 00 10 00 00       	mov    $0x1000,%ecx
801066bc:	89 f2                	mov    %esi,%edx
801066be:	8b 45 08             	mov    0x8(%ebp),%eax
801066c1:	e8 c6 fa ff ff       	call   8010618c <mappages>
801066c6:	83 c4 10             	add    $0x10,%esp
801066c9:	85 c0                	test   %eax,%eax
801066cb:	79 b9                	jns    80106686 <allocuvm+0x64>
      cprintf("allocuvm out of memory (2)\n");
801066cd:	83 ec 0c             	sub    $0xc,%esp
801066d0:	68 99 73 10 80       	push   $0x80107399
801066d5:	e8 4f 9f ff ff       	call   80100629 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801066da:	83 c4 0c             	add    $0xc,%esp
801066dd:	ff 75 0c             	pushl  0xc(%ebp)
801066e0:	57                   	push   %edi
801066e1:	ff 75 08             	pushl  0x8(%ebp)
801066e4:	e8 a3 fe ff ff       	call   8010658c <deallocuvm>
      kfree(mem);
801066e9:	89 1c 24             	mov    %ebx,(%esp)
801066ec:	e8 77 b9 ff ff       	call   80102068 <kfree>
      return 0;
801066f1:	83 c4 10             	add    $0x10,%esp
801066f4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801066fb:	eb 07                	jmp    80106704 <allocuvm+0xe2>
    return 0;
801066fd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106704:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106707:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010670a:	5b                   	pop    %ebx
8010670b:	5e                   	pop    %esi
8010670c:	5f                   	pop    %edi
8010670d:	5d                   	pop    %ebp
8010670e:	c3                   	ret    

8010670f <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010670f:	f3 0f 1e fb          	endbr32 
80106713:	55                   	push   %ebp
80106714:	89 e5                	mov    %esp,%ebp
80106716:	56                   	push   %esi
80106717:	53                   	push   %ebx
80106718:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010671b:	85 f6                	test   %esi,%esi
8010671d:	74 1a                	je     80106739 <freevm+0x2a>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010671f:	83 ec 04             	sub    $0x4,%esp
80106722:	6a 00                	push   $0x0
80106724:	68 00 00 00 80       	push   $0x80000000
80106729:	56                   	push   %esi
8010672a:	e8 5d fe ff ff       	call   8010658c <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010672f:	83 c4 10             	add    $0x10,%esp
80106732:	bb 00 00 00 00       	mov    $0x0,%ebx
80106737:	eb 26                	jmp    8010675f <freevm+0x50>
    panic("freevm: no pgdir");
80106739:	83 ec 0c             	sub    $0xc,%esp
8010673c:	68 b5 73 10 80       	push   $0x801073b5
80106741:	e8 16 9c ff ff       	call   8010035c <panic>
    if(pgdir[i] & PTE_P){
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106746:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010674b:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106750:	83 ec 0c             	sub    $0xc,%esp
80106753:	50                   	push   %eax
80106754:	e8 0f b9 ff ff       	call   80102068 <kfree>
80106759:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
8010675c:	83 c3 01             	add    $0x1,%ebx
8010675f:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106765:	77 09                	ja     80106770 <freevm+0x61>
    if(pgdir[i] & PTE_P){
80106767:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010676a:	a8 01                	test   $0x1,%al
8010676c:	74 ee                	je     8010675c <freevm+0x4d>
8010676e:	eb d6                	jmp    80106746 <freevm+0x37>
    }
  }
  kfree((char*)pgdir);
80106770:	83 ec 0c             	sub    $0xc,%esp
80106773:	56                   	push   %esi
80106774:	e8 ef b8 ff ff       	call   80102068 <kfree>
}
80106779:	83 c4 10             	add    $0x10,%esp
8010677c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010677f:	5b                   	pop    %ebx
80106780:	5e                   	pop    %esi
80106781:	5d                   	pop    %ebp
80106782:	c3                   	ret    

80106783 <setupkvm>:
{
80106783:	f3 0f 1e fb          	endbr32 
80106787:	55                   	push   %ebp
80106788:	89 e5                	mov    %esp,%ebp
8010678a:	56                   	push   %esi
8010678b:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
8010678c:	e8 fe b9 ff ff       	call   8010218f <kalloc>
80106791:	89 c6                	mov    %eax,%esi
80106793:	85 c0                	test   %eax,%eax
80106795:	74 55                	je     801067ec <setupkvm+0x69>
  memset(pgdir, 0, PGSIZE);
80106797:	83 ec 04             	sub    $0x4,%esp
8010679a:	68 00 10 00 00       	push   $0x1000
8010679f:	6a 00                	push   $0x0
801067a1:	50                   	push   %eax
801067a2:	e8 97 d8 ff ff       	call   8010403e <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801067a7:	83 c4 10             	add    $0x10,%esp
801067aa:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801067af:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801067b5:	73 35                	jae    801067ec <setupkvm+0x69>
                (uint)k->phys_start, k->perm) < 0) {
801067b7:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801067ba:	8b 4b 08             	mov    0x8(%ebx),%ecx
801067bd:	29 c1                	sub    %eax,%ecx
801067bf:	83 ec 08             	sub    $0x8,%esp
801067c2:	ff 73 0c             	pushl  0xc(%ebx)
801067c5:	50                   	push   %eax
801067c6:	8b 13                	mov    (%ebx),%edx
801067c8:	89 f0                	mov    %esi,%eax
801067ca:	e8 bd f9 ff ff       	call   8010618c <mappages>
801067cf:	83 c4 10             	add    $0x10,%esp
801067d2:	85 c0                	test   %eax,%eax
801067d4:	78 05                	js     801067db <setupkvm+0x58>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801067d6:	83 c3 10             	add    $0x10,%ebx
801067d9:	eb d4                	jmp    801067af <setupkvm+0x2c>
      freevm(pgdir);
801067db:	83 ec 0c             	sub    $0xc,%esp
801067de:	56                   	push   %esi
801067df:	e8 2b ff ff ff       	call   8010670f <freevm>
      return 0;
801067e4:	83 c4 10             	add    $0x10,%esp
801067e7:	be 00 00 00 00       	mov    $0x0,%esi
}
801067ec:	89 f0                	mov    %esi,%eax
801067ee:	8d 65 f8             	lea    -0x8(%ebp),%esp
801067f1:	5b                   	pop    %ebx
801067f2:	5e                   	pop    %esi
801067f3:	5d                   	pop    %ebp
801067f4:	c3                   	ret    

801067f5 <kvmalloc>:
{
801067f5:	f3 0f 1e fb          	endbr32 
801067f9:	55                   	push   %ebp
801067fa:	89 e5                	mov    %esp,%ebp
801067fc:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801067ff:	e8 7f ff ff ff       	call   80106783 <setupkvm>
80106804:	a3 84 59 11 80       	mov    %eax,0x80115984
  switchkvm();
80106809:	e8 44 fb ff ff       	call   80106352 <switchkvm>
}
8010680e:	c9                   	leave  
8010680f:	c3                   	ret    

80106810 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106810:	f3 0f 1e fb          	endbr32 
80106814:	55                   	push   %ebp
80106815:	89 e5                	mov    %esp,%ebp
80106817:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010681a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010681f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106822:	8b 45 08             	mov    0x8(%ebp),%eax
80106825:	e8 f1 f8 ff ff       	call   8010611b <walkpgdir>
  if(pte == 0)
8010682a:	85 c0                	test   %eax,%eax
8010682c:	74 05                	je     80106833 <clearpteu+0x23>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010682e:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106831:	c9                   	leave  
80106832:	c3                   	ret    
    panic("clearpteu");
80106833:	83 ec 0c             	sub    $0xc,%esp
80106836:	68 c6 73 10 80       	push   $0x801073c6
8010683b:	e8 1c 9b ff ff       	call   8010035c <panic>

80106840 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80106840:	f3 0f 1e fb          	endbr32 
80106844:	55                   	push   %ebp
80106845:	89 e5                	mov    %esp,%ebp
80106847:	57                   	push   %edi
80106848:	56                   	push   %esi
80106849:	53                   	push   %ebx
8010684a:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010684d:	e8 31 ff ff ff       	call   80106783 <setupkvm>
80106852:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106855:	85 c0                	test   %eax,%eax
80106857:	0f 84 b8 00 00 00    	je     80106915 <copyuvm+0xd5>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010685d:	bf 00 00 00 00       	mov    $0x0,%edi
80106862:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106865:	0f 83 aa 00 00 00    	jae    80106915 <copyuvm+0xd5>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010686b:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010686e:	b9 00 00 00 00       	mov    $0x0,%ecx
80106873:	89 fa                	mov    %edi,%edx
80106875:	8b 45 08             	mov    0x8(%ebp),%eax
80106878:	e8 9e f8 ff ff       	call   8010611b <walkpgdir>
8010687d:	85 c0                	test   %eax,%eax
8010687f:	74 65                	je     801068e6 <copyuvm+0xa6>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106881:	8b 00                	mov    (%eax),%eax
80106883:	a8 01                	test   $0x1,%al
80106885:	74 6c                	je     801068f3 <copyuvm+0xb3>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106887:	89 c6                	mov    %eax,%esi
80106889:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
8010688f:	25 ff 0f 00 00       	and    $0xfff,%eax
80106894:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80106897:	e8 f3 b8 ff ff       	call   8010218f <kalloc>
8010689c:	89 c3                	mov    %eax,%ebx
8010689e:	85 c0                	test   %eax,%eax
801068a0:	74 5e                	je     80106900 <copyuvm+0xc0>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801068a2:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801068a8:	83 ec 04             	sub    $0x4,%esp
801068ab:	68 00 10 00 00       	push   $0x1000
801068b0:	56                   	push   %esi
801068b1:	50                   	push   %eax
801068b2:	e8 07 d8 ff ff       	call   801040be <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
801068b7:	83 c4 08             	add    $0x8,%esp
801068ba:	ff 75 e0             	pushl  -0x20(%ebp)
801068bd:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
801068c3:	53                   	push   %ebx
801068c4:	b9 00 10 00 00       	mov    $0x1000,%ecx
801068c9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801068cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
801068cf:	e8 b8 f8 ff ff       	call   8010618c <mappages>
801068d4:	83 c4 10             	add    $0x10,%esp
801068d7:	85 c0                	test   %eax,%eax
801068d9:	78 25                	js     80106900 <copyuvm+0xc0>
  for(i = 0; i < sz; i += PGSIZE){
801068db:	81 c7 00 10 00 00    	add    $0x1000,%edi
801068e1:	e9 7c ff ff ff       	jmp    80106862 <copyuvm+0x22>
      panic("copyuvm: pte should exist");
801068e6:	83 ec 0c             	sub    $0xc,%esp
801068e9:	68 d0 73 10 80       	push   $0x801073d0
801068ee:	e8 69 9a ff ff       	call   8010035c <panic>
      panic("copyuvm: page not present");
801068f3:	83 ec 0c             	sub    $0xc,%esp
801068f6:	68 ea 73 10 80       	push   $0x801073ea
801068fb:	e8 5c 9a ff ff       	call   8010035c <panic>
      goto bad;
  }
  return d;

bad:
  freevm(d);
80106900:	83 ec 0c             	sub    $0xc,%esp
80106903:	ff 75 dc             	pushl  -0x24(%ebp)
80106906:	e8 04 fe ff ff       	call   8010670f <freevm>
  return 0;
8010690b:	83 c4 10             	add    $0x10,%esp
8010690e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106915:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106918:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010691b:	5b                   	pop    %ebx
8010691c:	5e                   	pop    %esi
8010691d:	5f                   	pop    %edi
8010691e:	5d                   	pop    %ebp
8010691f:	c3                   	ret    

80106920 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106920:	f3 0f 1e fb          	endbr32 
80106924:	55                   	push   %ebp
80106925:	89 e5                	mov    %esp,%ebp
80106927:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010692a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010692f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106932:	8b 45 08             	mov    0x8(%ebp),%eax
80106935:	e8 e1 f7 ff ff       	call   8010611b <walkpgdir>
  if((*pte & PTE_P) == 0)
8010693a:	8b 00                	mov    (%eax),%eax
8010693c:	a8 01                	test   $0x1,%al
8010693e:	74 10                	je     80106950 <uva2ka+0x30>
    return 0;
  if((*pte & PTE_U) == 0)
80106940:	a8 04                	test   $0x4,%al
80106942:	74 13                	je     80106957 <uva2ka+0x37>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106944:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106949:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010694e:	c9                   	leave  
8010694f:	c3                   	ret    
    return 0;
80106950:	b8 00 00 00 00       	mov    $0x0,%eax
80106955:	eb f7                	jmp    8010694e <uva2ka+0x2e>
    return 0;
80106957:	b8 00 00 00 00       	mov    $0x0,%eax
8010695c:	eb f0                	jmp    8010694e <uva2ka+0x2e>

8010695e <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010695e:	f3 0f 1e fb          	endbr32 
80106962:	55                   	push   %ebp
80106963:	89 e5                	mov    %esp,%ebp
80106965:	57                   	push   %edi
80106966:	56                   	push   %esi
80106967:	53                   	push   %ebx
80106968:	83 ec 0c             	sub    $0xc,%esp
8010696b:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010696e:	eb 25                	jmp    80106995 <copyout+0x37>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106970:	8b 55 0c             	mov    0xc(%ebp),%edx
80106973:	29 f2                	sub    %esi,%edx
80106975:	01 d0                	add    %edx,%eax
80106977:	83 ec 04             	sub    $0x4,%esp
8010697a:	53                   	push   %ebx
8010697b:	ff 75 10             	pushl  0x10(%ebp)
8010697e:	50                   	push   %eax
8010697f:	e8 3a d7 ff ff       	call   801040be <memmove>
    len -= n;
80106984:	29 df                	sub    %ebx,%edi
    buf += n;
80106986:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106989:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010698f:	89 45 0c             	mov    %eax,0xc(%ebp)
80106992:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106995:	85 ff                	test   %edi,%edi
80106997:	74 2f                	je     801069c8 <copyout+0x6a>
    va0 = (uint)PGROUNDDOWN(va);
80106999:	8b 75 0c             	mov    0xc(%ebp),%esi
8010699c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801069a2:	83 ec 08             	sub    $0x8,%esp
801069a5:	56                   	push   %esi
801069a6:	ff 75 08             	pushl  0x8(%ebp)
801069a9:	e8 72 ff ff ff       	call   80106920 <uva2ka>
    if(pa0 == 0)
801069ae:	83 c4 10             	add    $0x10,%esp
801069b1:	85 c0                	test   %eax,%eax
801069b3:	74 20                	je     801069d5 <copyout+0x77>
    n = PGSIZE - (va - va0);
801069b5:	89 f3                	mov    %esi,%ebx
801069b7:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801069ba:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801069c0:	39 df                	cmp    %ebx,%edi
801069c2:	73 ac                	jae    80106970 <copyout+0x12>
      n = len;
801069c4:	89 fb                	mov    %edi,%ebx
801069c6:	eb a8                	jmp    80106970 <copyout+0x12>
  }
  return 0;
801069c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801069cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801069d0:	5b                   	pop    %ebx
801069d1:	5e                   	pop    %esi
801069d2:	5f                   	pop    %edi
801069d3:	5d                   	pop    %ebp
801069d4:	c3                   	ret    
      return -1;
801069d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801069da:	eb f1                	jmp    801069cd <copyout+0x6f>
