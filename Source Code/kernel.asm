
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
80100028:	bc 20 d6 10 80       	mov    $0x8010d620,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 53 2b 10 80       	mov    $0x80102b53,%eax
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
80100041:	68 20 d6 10 80       	push   $0x8010d620
80100046:	e8 63 3d 00 00       	call   80103dae <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 70 1d 11 80    	mov    0x80111d70,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb 1c 1d 11 80    	cmp    $0x80111d1c,%ebx
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
80100077:	68 20 d6 10 80       	push   $0x8010d620
8010007c:	e8 96 3d 00 00       	call   80103e17 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 15 3b 00 00       	call   80103ba1 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 6c 1d 11 80    	mov    0x80111d6c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb 1c 1d 11 80    	cmp    $0x80111d1c,%ebx
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
801000c5:	68 20 d6 10 80       	push   $0x8010d620
801000ca:	e8 48 3d 00 00       	call   80103e17 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 c7 3a 00 00       	call   80103ba1 <acquiresleep>
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
801000ea:	68 a0 66 10 80       	push   $0x801066a0
801000ef:	e8 68 02 00 00       	call   8010035c <panic>

801000f4 <binit>:
{
801000f4:	f3 0f 1e fb          	endbr32 
801000f8:	55                   	push   %ebp
801000f9:	89 e5                	mov    %esp,%ebp
801000fb:	53                   	push   %ebx
801000fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000ff:	68 b1 66 10 80       	push   $0x801066b1
80100104:	68 20 d6 10 80       	push   $0x8010d620
80100109:	e8 50 3b 00 00       	call   80103c5e <initlock>
  bcache.head.prev = &bcache.head;
8010010e:	c7 05 6c 1d 11 80 1c 	movl   $0x80111d1c,0x80111d6c
80100115:	1d 11 80 
  bcache.head.next = &bcache.head;
80100118:	c7 05 70 1d 11 80 1c 	movl   $0x80111d1c,0x80111d70
8010011f:	1d 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100122:	83 c4 10             	add    $0x10,%esp
80100125:	bb 54 d6 10 80       	mov    $0x8010d654,%ebx
8010012a:	eb 37                	jmp    80100163 <binit+0x6f>
    b->next = bcache.head.next;
8010012c:	a1 70 1d 11 80       	mov    0x80111d70,%eax
80100131:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100134:	c7 43 50 1c 1d 11 80 	movl   $0x80111d1c,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
8010013b:	83 ec 08             	sub    $0x8,%esp
8010013e:	68 b8 66 10 80       	push   $0x801066b8
80100143:	8d 43 0c             	lea    0xc(%ebx),%eax
80100146:	50                   	push   %eax
80100147:	e8 1e 3a 00 00       	call   80103b6a <initsleeplock>
    bcache.head.next->prev = b;
8010014c:	a1 70 1d 11 80       	mov    0x80111d70,%eax
80100151:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100154:	89 1d 70 1d 11 80    	mov    %ebx,0x80111d70
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010015a:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
80100160:	83 c4 10             	add    $0x10,%esp
80100163:	81 fb 1c 1d 11 80    	cmp    $0x80111d1c,%ebx
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
80100198:	e8 2a 1d 00 00       	call   80101ec7 <iderw>
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
801001b4:	e8 7a 3a 00 00       	call   80103c33 <holdingsleep>
801001b9:	83 c4 10             	add    $0x10,%esp
801001bc:	85 c0                	test   %eax,%eax
801001be:	74 14                	je     801001d4 <bwrite+0x32>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001c0:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001c3:	83 ec 0c             	sub    $0xc,%esp
801001c6:	53                   	push   %ebx
801001c7:	e8 fb 1c 00 00       	call   80101ec7 <iderw>
}
801001cc:	83 c4 10             	add    $0x10,%esp
801001cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001d2:	c9                   	leave  
801001d3:	c3                   	ret    
    panic("bwrite");
801001d4:	83 ec 0c             	sub    $0xc,%esp
801001d7:	68 bf 66 10 80       	push   $0x801066bf
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
801001f4:	e8 3a 3a 00 00       	call   80103c33 <holdingsleep>
801001f9:	83 c4 10             	add    $0x10,%esp
801001fc:	85 c0                	test   %eax,%eax
801001fe:	74 6b                	je     8010026b <brelse+0x8a>
    panic("brelse");

  releasesleep(&b->lock);
80100200:	83 ec 0c             	sub    $0xc,%esp
80100203:	56                   	push   %esi
80100204:	e8 eb 39 00 00       	call   80103bf4 <releasesleep>

  acquire(&bcache.lock);
80100209:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
80100210:	e8 99 3b 00 00       	call   80103dae <acquire>
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
80100237:	a1 70 1d 11 80       	mov    0x80111d70,%eax
8010023c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010023f:	c7 43 50 1c 1d 11 80 	movl   $0x80111d1c,0x50(%ebx)
    bcache.head.next->prev = b;
80100246:	a1 70 1d 11 80       	mov    0x80111d70,%eax
8010024b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010024e:	89 1d 70 1d 11 80    	mov    %ebx,0x80111d70
  }
  
  release(&bcache.lock);
80100254:	83 ec 0c             	sub    $0xc,%esp
80100257:	68 20 d6 10 80       	push   $0x8010d620
8010025c:	e8 b6 3b 00 00       	call   80103e17 <release>
}
80100261:	83 c4 10             	add    $0x10,%esp
80100264:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100267:	5b                   	pop    %ebx
80100268:	5e                   	pop    %esi
80100269:	5d                   	pop    %ebp
8010026a:	c3                   	ret    
    panic("brelse");
8010026b:	83 ec 0c             	sub    $0xc,%esp
8010026e:	68 c6 66 10 80       	push   $0x801066c6
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
8010028f:	e8 3a 14 00 00       	call   801016ce <iunlock>
  target = n;
80100294:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100297:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010029e:	e8 0b 3b 00 00       	call   80103dae <acquire>
  while(n > 0){
801002a3:	83 c4 10             	add    $0x10,%esp
801002a6:	85 db                	test   %ebx,%ebx
801002a8:	0f 8e 8f 00 00 00    	jle    8010033d <consoleread+0xc5>
    while(input.r == input.w){
801002ae:	a1 00 20 11 80       	mov    0x80112000,%eax
801002b3:	3b 05 04 20 11 80    	cmp    0x80112004,%eax
801002b9:	75 47                	jne    80100302 <consoleread+0x8a>
      if(myproc()->killed){
801002bb:	e8 5a 30 00 00       	call   8010331a <myproc>
801002c0:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
801002c4:	75 17                	jne    801002dd <consoleread+0x65>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002c6:	83 ec 08             	sub    $0x8,%esp
801002c9:	68 20 a5 10 80       	push   $0x8010a520
801002ce:	68 00 20 11 80       	push   $0x80112000
801002d3:	e8 2f 35 00 00       	call   80103807 <sleep>
801002d8:	83 c4 10             	add    $0x10,%esp
801002db:	eb d1                	jmp    801002ae <consoleread+0x36>
        release(&cons.lock);
801002dd:	83 ec 0c             	sub    $0xc,%esp
801002e0:	68 20 a5 10 80       	push   $0x8010a520
801002e5:	e8 2d 3b 00 00       	call   80103e17 <release>
        ilock(ip);
801002ea:	89 3c 24             	mov    %edi,(%esp)
801002ed:	e8 16 13 00 00       	call   80101608 <ilock>
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
80100305:	89 15 00 20 11 80    	mov    %edx,0x80112000
8010030b:	89 c2                	mov    %eax,%edx
8010030d:	83 e2 7f             	and    $0x7f,%edx
80100310:	0f b6 92 80 1f 11 80 	movzbl -0x7feee080(%edx),%edx
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
80100338:	a3 00 20 11 80       	mov    %eax,0x80112000
  release(&cons.lock);
8010033d:	83 ec 0c             	sub    $0xc,%esp
80100340:	68 20 a5 10 80       	push   $0x8010a520
80100345:	e8 cd 3a 00 00       	call   80103e17 <release>
  ilock(ip);
8010034a:	89 3c 24             	mov    %edi,(%esp)
8010034d:	e8 b6 12 00 00       	call   80101608 <ilock>
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
80100372:	e8 e0 20 00 00       	call   80102457 <lapicid>
80100377:	83 ec 08             	sub    $0x8,%esp
8010037a:	50                   	push   %eax
8010037b:	68 cd 66 10 80       	push   $0x801066cd
80100380:	e8 a4 02 00 00       	call   80100629 <cprintf>
  cprintf(s);
80100385:	83 c4 04             	add    $0x4,%esp
80100388:	ff 75 08             	pushl  0x8(%ebp)
8010038b:	e8 99 02 00 00       	call   80100629 <cprintf>
  cprintf("\n");
80100390:	c7 04 24 3b 70 10 80 	movl   $0x8010703b,(%esp)
80100397:	e8 8d 02 00 00       	call   80100629 <cprintf>
  getcallerpcs(&s, pcs);
8010039c:	83 c4 08             	add    $0x8,%esp
8010039f:	8d 45 d0             	lea    -0x30(%ebp),%eax
801003a2:	50                   	push   %eax
801003a3:	8d 45 08             	lea    0x8(%ebp),%eax
801003a6:	50                   	push   %eax
801003a7:	e8 d1 38 00 00       	call   80103c7d <getcallerpcs>
  for(i=0; i<10; i++)
801003ac:	83 c4 10             	add    $0x10,%esp
801003af:	bb 00 00 00 00       	mov    $0x0,%ebx
801003b4:	eb 17                	jmp    801003cd <panic+0x71>
    cprintf(" %p", pcs[i]);
801003b6:	83 ec 08             	sub    $0x8,%esp
801003b9:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003bd:	68 e1 66 10 80       	push   $0x801066e1
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
801004b0:	68 e5 66 10 80       	push   $0x801066e5
801004b5:	e8 a2 fe ff ff       	call   8010035c <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004ba:	83 ec 04             	sub    $0x4,%esp
801004bd:	68 60 0e 00 00       	push   $0xe60
801004c2:	68 a0 80 0b 80       	push   $0x800b80a0
801004c7:	68 00 80 0b 80       	push   $0x800b8000
801004cc:	e8 11 3a 00 00       	call   80103ee2 <memmove>
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
801004eb:	e8 72 39 00 00       	call   80103e62 <memset>
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
80100518:	e8 47 4d 00 00       	call   80105264 <uartputc>
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
80100531:	e8 2e 4d 00 00       	call   80105264 <uartputc>
80100536:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010053d:	e8 22 4d 00 00       	call   80105264 <uartputc>
80100542:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100549:	e8 16 4d 00 00       	call   80105264 <uartputc>
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
80100586:	0f b6 92 24 67 10 80 	movzbl -0x7fef98dc(%edx),%edx
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
801005dc:	e8 ed 10 00 00       	call   801016ce <iunlock>
  acquire(&cons.lock);
801005e1:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005e8:	e8 c1 37 00 00       	call   80103dae <acquire>
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
8010060f:	e8 03 38 00 00       	call   80103e17 <release>
  ilock(ip);
80100614:	83 c4 04             	add    $0x4,%esp
80100617:	ff 75 08             	pushl  0x8(%ebp)
8010061a:	e8 e9 0f 00 00       	call   80101608 <ilock>

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
8010065a:	e8 4f 37 00 00       	call   80103dae <acquire>
8010065f:	83 c4 10             	add    $0x10,%esp
80100662:	eb de                	jmp    80100642 <cprintf+0x19>
    panic("null fmt");
80100664:	83 ec 0c             	sub    $0xc,%esp
80100667:	68 ff 66 10 80       	push   $0x801066ff
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
801006f3:	bb f8 66 10 80       	mov    $0x801066f8,%ebx
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
8010074f:	e8 c3 36 00 00       	call   80103e17 <release>
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
80100763:	68 08 67 10 80       	push   $0x80106708
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
80100793:	e8 16 36 00 00       	call   80103dae <acquire>
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
801007c6:	a1 08 20 11 80       	mov    0x80112008,%eax
801007cb:	89 c2                	mov    %eax,%edx
801007cd:	2b 15 00 20 11 80    	sub    0x80112000,%edx
801007d3:	83 fa 7f             	cmp    $0x7f,%edx
801007d6:	0f 87 a5 00 00 00    	ja     80100881 <consoleintr+0x103>
        c = (c == '\r') ? '\n' : c;
801007dc:	83 fb 0d             	cmp    $0xd,%ebx
801007df:	0f 84 84 00 00 00    	je     80100869 <consoleintr+0xeb>
        input.buf[input.e++ % INPUT_BUF] = c;
801007e5:	8d 50 01             	lea    0x1(%eax),%edx
801007e8:	89 15 08 20 11 80    	mov    %edx,0x80112008
801007ee:	83 e0 7f             	and    $0x7f,%eax
801007f1:	88 98 80 1f 11 80    	mov    %bl,-0x7feee080(%eax)
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
8010080e:	a1 00 20 11 80       	mov    0x80112000,%eax
80100813:	83 e8 80             	sub    $0xffffff80,%eax
80100816:	39 05 08 20 11 80    	cmp    %eax,0x80112008
8010081c:	75 63                	jne    80100881 <consoleintr+0x103>
          input.w = input.e;
8010081e:	a1 08 20 11 80       	mov    0x80112008,%eax
80100823:	a3 04 20 11 80       	mov    %eax,0x80112004
          wakeup(&input.r);
80100828:	83 ec 0c             	sub    $0xc,%esp
8010082b:	68 00 20 11 80       	push   $0x80112000
80100830:	e8 3e 31 00 00       	call   80103973 <wakeup>
80100835:	83 c4 10             	add    $0x10,%esp
80100838:	eb 47                	jmp    80100881 <consoleintr+0x103>
        input.e--;
8010083a:	a3 08 20 11 80       	mov    %eax,0x80112008
        consputc(BACKSPACE);
8010083f:	b8 00 01 00 00       	mov    $0x100,%eax
80100844:	e8 af fc ff ff       	call   801004f8 <consputc>
      while(input.e != input.w &&
80100849:	a1 08 20 11 80       	mov    0x80112008,%eax
8010084e:	3b 05 04 20 11 80    	cmp    0x80112004,%eax
80100854:	74 2b                	je     80100881 <consoleintr+0x103>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	89 c2                	mov    %eax,%edx
8010085b:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010085e:	80 ba 80 1f 11 80 0a 	cmpb   $0xa,-0x7feee080(%edx)
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
801008a2:	a1 08 20 11 80       	mov    0x80112008,%eax
801008a7:	3b 05 04 20 11 80    	cmp    0x80112004,%eax
801008ad:	74 d2                	je     80100881 <consoleintr+0x103>
        input.e--;
801008af:	83 e8 01             	sub    $0x1,%eax
801008b2:	a3 08 20 11 80       	mov    %eax,0x80112008
        consputc(BACKSPACE);
801008b7:	b8 00 01 00 00       	mov    $0x100,%eax
801008bc:	e8 37 fc ff ff       	call   801004f8 <consputc>
801008c1:	eb be                	jmp    80100881 <consoleintr+0x103>
  release(&cons.lock);
801008c3:	83 ec 0c             	sub    $0xc,%esp
801008c6:	68 20 a5 10 80       	push   $0x8010a520
801008cb:	e8 47 35 00 00       	call   80103e17 <release>
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
801008ec:	e8 ae 31 00 00       	call   80103a9f <procdump>
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
801008fd:	68 1c 67 10 80       	push   $0x8010671c
80100902:	68 20 a5 10 80       	push   $0x8010a520
80100907:	e8 52 33 00 00       	call   80103c5e <initlock>

  devsw[CONSOLE].write = consolewrite;
8010090c:	c7 05 cc 29 11 80 c6 	movl   $0x801005c6,0x801129cc
80100913:	05 10 80 
  devsw[CONSOLE].read = consoleread;
80100916:	c7 05 c8 29 11 80 78 	movl   $0x80100278,0x801129c8
8010091d:	02 10 80 
  cons.locking = 1;
80100920:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
80100927:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
8010092a:	83 c4 08             	add    $0x8,%esp
8010092d:	6a 00                	push   $0x0
8010092f:	6a 01                	push   $0x1
80100931:	e8 03 17 00 00       	call   80102039 <ioapicenable>
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
8010094b:	e8 ca 29 00 00       	call   8010331a <myproc>
80100950:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)

  begin_op();
80100956:	e8 32 1f 00 00       	call   8010288d <begin_op>

  if((ip = namei(path)) == 0){
8010095b:	83 ec 0c             	sub    $0xc,%esp
8010095e:	ff 75 08             	pushl  0x8(%ebp)
80100961:	e8 27 13 00 00       	call   80101c8d <namei>
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
80100973:	e8 90 0c 00 00       	call   80101608 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100978:	6a 34                	push   $0x34
8010097a:	6a 00                	push   $0x0
8010097c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100982:	50                   	push   %eax
80100983:	53                   	push   %ebx
80100984:	e8 85 0e 00 00       	call   8010180e <readi>
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
8010099f:	0f 84 ba 02 00 00    	je     80100c5f <exec+0x324>
    iunlockput(ip);
801009a5:	83 ec 0c             	sub    $0xc,%esp
801009a8:	53                   	push   %ebx
801009a9:	e8 0d 0e 00 00       	call   801017bb <iunlockput>
    end_op();
801009ae:	e8 58 1f 00 00       	call   8010290b <end_op>
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
801009c3:	e8 43 1f 00 00       	call   8010290b <end_op>
    return -1;
801009c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801009cd:	eb ec                	jmp    801009bb <exec+0x80>
  if((pgdir = setupkvm()) == 0)
801009cf:	e8 72 5a 00 00       	call   80106446 <setupkvm>
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
80100a20:	e8 e9 0d 00 00       	call   8010180e <readi>
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
80100a63:	e8 7d 58 00 00       	call   801062e5 <allocuvm>
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
80100a95:	e8 16 57 00 00       	call   801061b0 <loaduvm>
80100a9a:	83 c4 20             	add    $0x20,%esp
80100a9d:	85 c0                	test   %eax,%eax
80100a9f:	0f 89 4f ff ff ff    	jns    801009f4 <exec+0xb9>
80100aa5:	eb 44                	jmp    80100aeb <exec+0x1b0>
  iunlockput(ip);
80100aa7:	83 ec 0c             	sub    $0xc,%esp
80100aaa:	53                   	push   %ebx
80100aab:	e8 0b 0d 00 00       	call   801017bb <iunlockput>
  end_op();
80100ab0:	e8 56 1e 00 00       	call   8010290b <end_op>
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
80100ad2:	e8 0e 58 00 00       	call   801062e5 <allocuvm>
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
80100afd:	e8 d0 58 00 00       	call   801063d2 <freevm>
80100b02:	83 c4 10             	add    $0x10,%esp
80100b05:	e9 93 fe ff ff       	jmp    8010099d <exec+0x62>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100b0a:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100b10:	83 ec 08             	sub    $0x8,%esp
80100b13:	50                   	push   %eax
80100b14:	57                   	push   %edi
80100b15:	e8 b9 59 00 00       	call   801064d3 <clearpteu>
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
80100b31:	0f 87 14 01 00 00    	ja     80100c4b <exec+0x310>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100b37:	83 ec 0c             	sub    $0xc,%esp
80100b3a:	50                   	push   %eax
80100b3b:	e8 e3 34 00 00       	call   80104023 <strlen>
80100b40:	29 c6                	sub    %eax,%esi
80100b42:	83 ee 01             	sub    $0x1,%esi
80100b45:	83 e6 fc             	and    $0xfffffffc,%esi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100b48:	83 c4 04             	add    $0x4,%esp
80100b4b:	ff 33                	pushl  (%ebx)
80100b4d:	e8 d1 34 00 00       	call   80104023 <strlen>
80100b52:	83 c0 01             	add    $0x1,%eax
80100b55:	50                   	push   %eax
80100b56:	ff 33                	pushl  (%ebx)
80100b58:	56                   	push   %esi
80100b59:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100b5f:	e8 bd 5a 00 00       	call   80106621 <copyout>
80100b64:	83 c4 20             	add    $0x20,%esp
80100b67:	85 c0                	test   %eax,%eax
80100b69:	0f 88 e6 00 00 00    	js     80100c55 <exec+0x31a>
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
80100bc5:	e8 57 5a 00 00       	call   80106621 <copyout>
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
80100bf8:	83 c0 70             	add    $0x70,%eax
80100bfb:	83 ec 04             	sub    $0x4,%esp
80100bfe:	6a 10                	push   $0x10
80100c00:	52                   	push   %edx
80100c01:	50                   	push   %eax
80100c02:	e8 db 33 00 00       	call   80103fe2 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100c07:	8b 5f 08             	mov    0x8(%edi),%ebx
  curproc->pgdir = pgdir;
80100c0a:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100c10:	89 4f 08             	mov    %ecx,0x8(%edi)
  curproc->sz = sz;
80100c13:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100c19:	89 4f 04             	mov    %ecx,0x4(%edi)
  curproc->tf->eip = elf.entry;  // main
80100c1c:	8b 47 1c             	mov    0x1c(%edi),%eax
80100c1f:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100c25:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100c28:	8b 47 1c             	mov    0x1c(%edi),%eax
80100c2b:	89 70 44             	mov    %esi,0x44(%eax)
  switchuvm(curproc);
80100c2e:	89 3c 24             	mov    %edi,(%esp)
80100c31:	e8 f1 53 00 00       	call   80106027 <switchuvm>
  freevm(oldpgdir);
80100c36:	89 1c 24             	mov    %ebx,(%esp)
80100c39:	e8 94 57 00 00       	call   801063d2 <freevm>
  return 0;
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	b8 00 00 00 00       	mov    $0x0,%eax
80100c46:	e9 70 fd ff ff       	jmp    801009bb <exec+0x80>
  ip = 0;
80100c4b:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c50:	e9 96 fe ff ff       	jmp    80100aeb <exec+0x1b0>
80100c55:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c5a:	e9 8c fe ff ff       	jmp    80100aeb <exec+0x1b0>
  return -1;
80100c5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c64:	e9 52 fd ff ff       	jmp    801009bb <exec+0x80>

80100c69 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c69:	f3 0f 1e fb          	endbr32 
80100c6d:	55                   	push   %ebp
80100c6e:	89 e5                	mov    %esp,%ebp
80100c70:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c73:	68 35 67 10 80       	push   $0x80106735
80100c78:	68 20 20 11 80       	push   $0x80112020
80100c7d:	e8 dc 2f 00 00       	call   80103c5e <initlock>
}
80100c82:	83 c4 10             	add    $0x10,%esp
80100c85:	c9                   	leave  
80100c86:	c3                   	ret    

80100c87 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c87:	f3 0f 1e fb          	endbr32 
80100c8b:	55                   	push   %ebp
80100c8c:	89 e5                	mov    %esp,%ebp
80100c8e:	53                   	push   %ebx
80100c8f:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c92:	68 20 20 11 80       	push   $0x80112020
80100c97:	e8 12 31 00 00       	call   80103dae <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c9c:	83 c4 10             	add    $0x10,%esp
80100c9f:	bb 54 20 11 80       	mov    $0x80112054,%ebx
80100ca4:	eb 03                	jmp    80100ca9 <filealloc+0x22>
80100ca6:	83 c3 18             	add    $0x18,%ebx
80100ca9:	81 fb b4 29 11 80    	cmp    $0x801129b4,%ebx
80100caf:	73 24                	jae    80100cd5 <filealloc+0x4e>
    if(f->ref == 0){
80100cb1:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100cb5:	75 ef                	jne    80100ca6 <filealloc+0x1f>
      f->ref = 1;
80100cb7:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100cbe:	83 ec 0c             	sub    $0xc,%esp
80100cc1:	68 20 20 11 80       	push   $0x80112020
80100cc6:	e8 4c 31 00 00       	call   80103e17 <release>
      return f;
80100ccb:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100cce:	89 d8                	mov    %ebx,%eax
80100cd0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd3:	c9                   	leave  
80100cd4:	c3                   	ret    
  release(&ftable.lock);
80100cd5:	83 ec 0c             	sub    $0xc,%esp
80100cd8:	68 20 20 11 80       	push   $0x80112020
80100cdd:	e8 35 31 00 00       	call   80103e17 <release>
  return 0;
80100ce2:	83 c4 10             	add    $0x10,%esp
80100ce5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100cea:	eb e2                	jmp    80100cce <filealloc+0x47>

80100cec <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100cec:	f3 0f 1e fb          	endbr32 
80100cf0:	55                   	push   %ebp
80100cf1:	89 e5                	mov    %esp,%ebp
80100cf3:	53                   	push   %ebx
80100cf4:	83 ec 10             	sub    $0x10,%esp
80100cf7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100cfa:	68 20 20 11 80       	push   $0x80112020
80100cff:	e8 aa 30 00 00       	call   80103dae <acquire>
  if(f->ref < 1)
80100d04:	8b 43 04             	mov    0x4(%ebx),%eax
80100d07:	83 c4 10             	add    $0x10,%esp
80100d0a:	85 c0                	test   %eax,%eax
80100d0c:	7e 1a                	jle    80100d28 <filedup+0x3c>
    panic("filedup");
  f->ref++;
80100d0e:	83 c0 01             	add    $0x1,%eax
80100d11:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100d14:	83 ec 0c             	sub    $0xc,%esp
80100d17:	68 20 20 11 80       	push   $0x80112020
80100d1c:	e8 f6 30 00 00       	call   80103e17 <release>
  return f;
}
80100d21:	89 d8                	mov    %ebx,%eax
80100d23:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d26:	c9                   	leave  
80100d27:	c3                   	ret    
    panic("filedup");
80100d28:	83 ec 0c             	sub    $0xc,%esp
80100d2b:	68 3c 67 10 80       	push   $0x8010673c
80100d30:	e8 27 f6 ff ff       	call   8010035c <panic>

80100d35 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100d35:	f3 0f 1e fb          	endbr32 
80100d39:	55                   	push   %ebp
80100d3a:	89 e5                	mov    %esp,%ebp
80100d3c:	53                   	push   %ebx
80100d3d:	83 ec 30             	sub    $0x30,%esp
80100d40:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100d43:	68 20 20 11 80       	push   $0x80112020
80100d48:	e8 61 30 00 00       	call   80103dae <acquire>
  if(f->ref < 1)
80100d4d:	8b 43 04             	mov    0x4(%ebx),%eax
80100d50:	83 c4 10             	add    $0x10,%esp
80100d53:	85 c0                	test   %eax,%eax
80100d55:	7e 65                	jle    80100dbc <fileclose+0x87>
    panic("fileclose");
  if(--f->ref > 0){
80100d57:	83 e8 01             	sub    $0x1,%eax
80100d5a:	89 43 04             	mov    %eax,0x4(%ebx)
80100d5d:	85 c0                	test   %eax,%eax
80100d5f:	7f 68                	jg     80100dc9 <fileclose+0x94>
    release(&ftable.lock);
    return;
  }
  ff = *f;
80100d61:	8b 03                	mov    (%ebx),%eax
80100d63:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d66:	8b 43 08             	mov    0x8(%ebx),%eax
80100d69:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d6c:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d6f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d72:	8b 43 10             	mov    0x10(%ebx),%eax
80100d75:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d78:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d7f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d85:	83 ec 0c             	sub    $0xc,%esp
80100d88:	68 20 20 11 80       	push   $0x80112020
80100d8d:	e8 85 30 00 00       	call   80103e17 <release>

  if(ff.type == FD_PIPE)
80100d92:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d95:	83 c4 10             	add    $0x10,%esp
80100d98:	83 f8 01             	cmp    $0x1,%eax
80100d9b:	74 41                	je     80100dde <fileclose+0xa9>
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE){
80100d9d:	83 f8 02             	cmp    $0x2,%eax
80100da0:	75 37                	jne    80100dd9 <fileclose+0xa4>
    begin_op();
80100da2:	e8 e6 1a 00 00       	call   8010288d <begin_op>
    iput(ff.ip);
80100da7:	83 ec 0c             	sub    $0xc,%esp
80100daa:	ff 75 f0             	pushl  -0x10(%ebp)
80100dad:	e8 65 09 00 00       	call   80101717 <iput>
    end_op();
80100db2:	e8 54 1b 00 00       	call   8010290b <end_op>
80100db7:	83 c4 10             	add    $0x10,%esp
80100dba:	eb 1d                	jmp    80100dd9 <fileclose+0xa4>
    panic("fileclose");
80100dbc:	83 ec 0c             	sub    $0xc,%esp
80100dbf:	68 44 67 10 80       	push   $0x80106744
80100dc4:	e8 93 f5 ff ff       	call   8010035c <panic>
    release(&ftable.lock);
80100dc9:	83 ec 0c             	sub    $0xc,%esp
80100dcc:	68 20 20 11 80       	push   $0x80112020
80100dd1:	e8 41 30 00 00       	call   80103e17 <release>
    return;
80100dd6:	83 c4 10             	add    $0x10,%esp
  }
}
80100dd9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ddc:	c9                   	leave  
80100ddd:	c3                   	ret    
    pipeclose(ff.pipe, ff.writable);
80100dde:	83 ec 08             	sub    $0x8,%esp
80100de1:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100de5:	50                   	push   %eax
80100de6:	ff 75 ec             	pushl  -0x14(%ebp)
80100de9:	e8 32 21 00 00       	call   80102f20 <pipeclose>
80100dee:	83 c4 10             	add    $0x10,%esp
80100df1:	eb e6                	jmp    80100dd9 <fileclose+0xa4>

80100df3 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100df3:	f3 0f 1e fb          	endbr32 
80100df7:	55                   	push   %ebp
80100df8:	89 e5                	mov    %esp,%ebp
80100dfa:	53                   	push   %ebx
80100dfb:	83 ec 04             	sub    $0x4,%esp
80100dfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100e01:	83 3b 02             	cmpl   $0x2,(%ebx)
80100e04:	75 31                	jne    80100e37 <filestat+0x44>
    ilock(f->ip);
80100e06:	83 ec 0c             	sub    $0xc,%esp
80100e09:	ff 73 10             	pushl  0x10(%ebx)
80100e0c:	e8 f7 07 00 00       	call   80101608 <ilock>
    stati(f->ip, st);
80100e11:	83 c4 08             	add    $0x8,%esp
80100e14:	ff 75 0c             	pushl  0xc(%ebp)
80100e17:	ff 73 10             	pushl  0x10(%ebx)
80100e1a:	e8 c0 09 00 00       	call   801017df <stati>
    iunlock(f->ip);
80100e1f:	83 c4 04             	add    $0x4,%esp
80100e22:	ff 73 10             	pushl  0x10(%ebx)
80100e25:	e8 a4 08 00 00       	call   801016ce <iunlock>
    return 0;
80100e2a:	83 c4 10             	add    $0x10,%esp
80100e2d:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100e32:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100e35:	c9                   	leave  
80100e36:	c3                   	ret    
  return -1;
80100e37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100e3c:	eb f4                	jmp    80100e32 <filestat+0x3f>

80100e3e <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100e3e:	f3 0f 1e fb          	endbr32 
80100e42:	55                   	push   %ebp
80100e43:	89 e5                	mov    %esp,%ebp
80100e45:	56                   	push   %esi
80100e46:	53                   	push   %ebx
80100e47:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100e4a:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100e4e:	74 70                	je     80100ec0 <fileread+0x82>
    return -1;
  if(f->type == FD_PIPE)
80100e50:	8b 03                	mov    (%ebx),%eax
80100e52:	83 f8 01             	cmp    $0x1,%eax
80100e55:	74 44                	je     80100e9b <fileread+0x5d>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e57:	83 f8 02             	cmp    $0x2,%eax
80100e5a:	75 57                	jne    80100eb3 <fileread+0x75>
    ilock(f->ip);
80100e5c:	83 ec 0c             	sub    $0xc,%esp
80100e5f:	ff 73 10             	pushl  0x10(%ebx)
80100e62:	e8 a1 07 00 00       	call   80101608 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100e67:	ff 75 10             	pushl  0x10(%ebp)
80100e6a:	ff 73 14             	pushl  0x14(%ebx)
80100e6d:	ff 75 0c             	pushl  0xc(%ebp)
80100e70:	ff 73 10             	pushl  0x10(%ebx)
80100e73:	e8 96 09 00 00       	call   8010180e <readi>
80100e78:	89 c6                	mov    %eax,%esi
80100e7a:	83 c4 20             	add    $0x20,%esp
80100e7d:	85 c0                	test   %eax,%eax
80100e7f:	7e 03                	jle    80100e84 <fileread+0x46>
      f->off += r;
80100e81:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e84:	83 ec 0c             	sub    $0xc,%esp
80100e87:	ff 73 10             	pushl  0x10(%ebx)
80100e8a:	e8 3f 08 00 00       	call   801016ce <iunlock>
    return r;
80100e8f:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e92:	89 f0                	mov    %esi,%eax
80100e94:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e97:	5b                   	pop    %ebx
80100e98:	5e                   	pop    %esi
80100e99:	5d                   	pop    %ebp
80100e9a:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e9b:	83 ec 04             	sub    $0x4,%esp
80100e9e:	ff 75 10             	pushl  0x10(%ebp)
80100ea1:	ff 75 0c             	pushl  0xc(%ebp)
80100ea4:	ff 73 0c             	pushl  0xc(%ebx)
80100ea7:	e8 ce 21 00 00       	call   8010307a <piperead>
80100eac:	89 c6                	mov    %eax,%esi
80100eae:	83 c4 10             	add    $0x10,%esp
80100eb1:	eb df                	jmp    80100e92 <fileread+0x54>
  panic("fileread");
80100eb3:	83 ec 0c             	sub    $0xc,%esp
80100eb6:	68 4e 67 10 80       	push   $0x8010674e
80100ebb:	e8 9c f4 ff ff       	call   8010035c <panic>
    return -1;
80100ec0:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100ec5:	eb cb                	jmp    80100e92 <fileread+0x54>

80100ec7 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100ec7:	f3 0f 1e fb          	endbr32 
80100ecb:	55                   	push   %ebp
80100ecc:	89 e5                	mov    %esp,%ebp
80100ece:	57                   	push   %edi
80100ecf:	56                   	push   %esi
80100ed0:	53                   	push   %ebx
80100ed1:	83 ec 1c             	sub    $0x1c,%esp
80100ed4:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;

  if(f->writable == 0)
80100ed7:	80 7e 09 00          	cmpb   $0x0,0x9(%esi)
80100edb:	0f 84 cc 00 00 00    	je     80100fad <filewrite+0xe6>
    return -1;
  if(f->type == FD_PIPE)
80100ee1:	8b 06                	mov    (%esi),%eax
80100ee3:	83 f8 01             	cmp    $0x1,%eax
80100ee6:	74 10                	je     80100ef8 <filewrite+0x31>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100ee8:	83 f8 02             	cmp    $0x2,%eax
80100eeb:	0f 85 af 00 00 00    	jne    80100fa0 <filewrite+0xd9>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100ef1:	bf 00 00 00 00       	mov    $0x0,%edi
80100ef6:	eb 67                	jmp    80100f5f <filewrite+0x98>
    return pipewrite(f->pipe, addr, n);
80100ef8:	83 ec 04             	sub    $0x4,%esp
80100efb:	ff 75 10             	pushl  0x10(%ebp)
80100efe:	ff 75 0c             	pushl  0xc(%ebp)
80100f01:	ff 76 0c             	pushl  0xc(%esi)
80100f04:	e8 a7 20 00 00       	call   80102fb0 <pipewrite>
80100f09:	83 c4 10             	add    $0x10,%esp
80100f0c:	e9 82 00 00 00       	jmp    80100f93 <filewrite+0xcc>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100f11:	e8 77 19 00 00       	call   8010288d <begin_op>
      ilock(f->ip);
80100f16:	83 ec 0c             	sub    $0xc,%esp
80100f19:	ff 76 10             	pushl  0x10(%esi)
80100f1c:	e8 e7 06 00 00       	call   80101608 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100f21:	ff 75 e4             	pushl  -0x1c(%ebp)
80100f24:	ff 76 14             	pushl  0x14(%esi)
80100f27:	89 f8                	mov    %edi,%eax
80100f29:	03 45 0c             	add    0xc(%ebp),%eax
80100f2c:	50                   	push   %eax
80100f2d:	ff 76 10             	pushl  0x10(%esi)
80100f30:	e8 da 09 00 00       	call   8010190f <writei>
80100f35:	89 c3                	mov    %eax,%ebx
80100f37:	83 c4 20             	add    $0x20,%esp
80100f3a:	85 c0                	test   %eax,%eax
80100f3c:	7e 03                	jle    80100f41 <filewrite+0x7a>
        f->off += r;
80100f3e:	01 46 14             	add    %eax,0x14(%esi)
      iunlock(f->ip);
80100f41:	83 ec 0c             	sub    $0xc,%esp
80100f44:	ff 76 10             	pushl  0x10(%esi)
80100f47:	e8 82 07 00 00       	call   801016ce <iunlock>
      end_op();
80100f4c:	e8 ba 19 00 00       	call   8010290b <end_op>

      if(r < 0)
80100f51:	83 c4 10             	add    $0x10,%esp
80100f54:	85 db                	test   %ebx,%ebx
80100f56:	78 31                	js     80100f89 <filewrite+0xc2>
        break;
      if(r != n1)
80100f58:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
80100f5b:	75 1f                	jne    80100f7c <filewrite+0xb5>
        panic("short filewrite");
      i += r;
80100f5d:	01 df                	add    %ebx,%edi
    while(i < n){
80100f5f:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f62:	7d 25                	jge    80100f89 <filewrite+0xc2>
      int n1 = n - i;
80100f64:	8b 45 10             	mov    0x10(%ebp),%eax
80100f67:	29 f8                	sub    %edi,%eax
80100f69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100f6c:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f71:	7e 9e                	jle    80100f11 <filewrite+0x4a>
        n1 = max;
80100f73:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f7a:	eb 95                	jmp    80100f11 <filewrite+0x4a>
        panic("short filewrite");
80100f7c:	83 ec 0c             	sub    $0xc,%esp
80100f7f:	68 57 67 10 80       	push   $0x80106757
80100f84:	e8 d3 f3 ff ff       	call   8010035c <panic>
    }
    return i == n ? n : -1;
80100f89:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f8c:	74 0d                	je     80100f9b <filewrite+0xd4>
80100f8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  panic("filewrite");
}
80100f93:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f96:	5b                   	pop    %ebx
80100f97:	5e                   	pop    %esi
80100f98:	5f                   	pop    %edi
80100f99:	5d                   	pop    %ebp
80100f9a:	c3                   	ret    
    return i == n ? n : -1;
80100f9b:	8b 45 10             	mov    0x10(%ebp),%eax
80100f9e:	eb f3                	jmp    80100f93 <filewrite+0xcc>
  panic("filewrite");
80100fa0:	83 ec 0c             	sub    $0xc,%esp
80100fa3:	68 5d 67 10 80       	push   $0x8010675d
80100fa8:	e8 af f3 ff ff       	call   8010035c <panic>
    return -1;
80100fad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100fb2:	eb df                	jmp    80100f93 <filewrite+0xcc>

80100fb4 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100fb4:	55                   	push   %ebp
80100fb5:	89 e5                	mov    %esp,%ebp
80100fb7:	57                   	push   %edi
80100fb8:	56                   	push   %esi
80100fb9:	53                   	push   %ebx
80100fba:	83 ec 0c             	sub    $0xc,%esp
80100fbd:	89 d6                	mov    %edx,%esi
  char *s;
  int len;

  while(*path == '/')
80100fbf:	0f b6 10             	movzbl (%eax),%edx
80100fc2:	80 fa 2f             	cmp    $0x2f,%dl
80100fc5:	75 05                	jne    80100fcc <skipelem+0x18>
    path++;
80100fc7:	83 c0 01             	add    $0x1,%eax
80100fca:	eb f3                	jmp    80100fbf <skipelem+0xb>
  if(*path == 0)
80100fcc:	84 d2                	test   %dl,%dl
80100fce:	74 59                	je     80101029 <skipelem+0x75>
80100fd0:	89 c3                	mov    %eax,%ebx
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80100fd2:	0f b6 13             	movzbl (%ebx),%edx
80100fd5:	80 fa 2f             	cmp    $0x2f,%dl
80100fd8:	0f 95 c1             	setne  %cl
80100fdb:	84 d2                	test   %dl,%dl
80100fdd:	0f 95 c2             	setne  %dl
80100fe0:	84 d1                	test   %dl,%cl
80100fe2:	74 05                	je     80100fe9 <skipelem+0x35>
    path++;
80100fe4:	83 c3 01             	add    $0x1,%ebx
80100fe7:	eb e9                	jmp    80100fd2 <skipelem+0x1e>
  len = path - s;
80100fe9:	89 df                	mov    %ebx,%edi
80100feb:	29 c7                	sub    %eax,%edi
  if(len >= DIRSIZ)
80100fed:	83 ff 0d             	cmp    $0xd,%edi
80100ff0:	7e 11                	jle    80101003 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100ff2:	83 ec 04             	sub    $0x4,%esp
80100ff5:	6a 0e                	push   $0xe
80100ff7:	50                   	push   %eax
80100ff8:	56                   	push   %esi
80100ff9:	e8 e4 2e 00 00       	call   80103ee2 <memmove>
80100ffe:	83 c4 10             	add    $0x10,%esp
80101001:	eb 17                	jmp    8010101a <skipelem+0x66>
  else {
    memmove(name, s, len);
80101003:	83 ec 04             	sub    $0x4,%esp
80101006:	57                   	push   %edi
80101007:	50                   	push   %eax
80101008:	56                   	push   %esi
80101009:	e8 d4 2e 00 00       	call   80103ee2 <memmove>
    name[len] = 0;
8010100e:	c6 04 3e 00          	movb   $0x0,(%esi,%edi,1)
80101012:	83 c4 10             	add    $0x10,%esp
80101015:	eb 03                	jmp    8010101a <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80101017:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
8010101a:	80 3b 2f             	cmpb   $0x2f,(%ebx)
8010101d:	74 f8                	je     80101017 <skipelem+0x63>
  return path;
}
8010101f:	89 d8                	mov    %ebx,%eax
80101021:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101024:	5b                   	pop    %ebx
80101025:	5e                   	pop    %esi
80101026:	5f                   	pop    %edi
80101027:	5d                   	pop    %ebp
80101028:	c3                   	ret    
    return 0;
80101029:	bb 00 00 00 00       	mov    $0x0,%ebx
8010102e:	eb ef                	jmp    8010101f <skipelem+0x6b>

80101030 <bzero>:
{
80101030:	55                   	push   %ebp
80101031:	89 e5                	mov    %esp,%ebp
80101033:	53                   	push   %ebx
80101034:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80101037:	52                   	push   %edx
80101038:	50                   	push   %eax
80101039:	e8 32 f1 ff ff       	call   80100170 <bread>
8010103e:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80101040:	8d 40 5c             	lea    0x5c(%eax),%eax
80101043:	83 c4 0c             	add    $0xc,%esp
80101046:	68 00 02 00 00       	push   $0x200
8010104b:	6a 00                	push   $0x0
8010104d:	50                   	push   %eax
8010104e:	e8 0f 2e 00 00       	call   80103e62 <memset>
  log_write(bp);
80101053:	89 1c 24             	mov    %ebx,(%esp)
80101056:	e8 63 19 00 00       	call   801029be <log_write>
  brelse(bp);
8010105b:	89 1c 24             	mov    %ebx,(%esp)
8010105e:	e8 7e f1 ff ff       	call   801001e1 <brelse>
}
80101063:	83 c4 10             	add    $0x10,%esp
80101066:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101069:	c9                   	leave  
8010106a:	c3                   	ret    

8010106b <balloc>:
{
8010106b:	55                   	push   %ebp
8010106c:	89 e5                	mov    %esp,%ebp
8010106e:	57                   	push   %edi
8010106f:	56                   	push   %esi
80101070:	53                   	push   %ebx
80101071:	83 ec 1c             	sub    $0x1c,%esp
80101074:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101077:	be 00 00 00 00       	mov    $0x0,%esi
8010107c:	eb 14                	jmp    80101092 <balloc+0x27>
    brelse(bp);
8010107e:	83 ec 0c             	sub    $0xc,%esp
80101081:	ff 75 e4             	pushl  -0x1c(%ebp)
80101084:	e8 58 f1 ff ff       	call   801001e1 <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101089:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010108f:	83 c4 10             	add    $0x10,%esp
80101092:	39 35 20 2a 11 80    	cmp    %esi,0x80112a20
80101098:	76 75                	jbe    8010110f <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010109a:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
801010a0:	85 f6                	test   %esi,%esi
801010a2:	0f 49 c6             	cmovns %esi,%eax
801010a5:	c1 f8 0c             	sar    $0xc,%eax
801010a8:	83 ec 08             	sub    $0x8,%esp
801010ab:	03 05 38 2a 11 80    	add    0x80112a38,%eax
801010b1:	50                   	push   %eax
801010b2:	ff 75 d8             	pushl  -0x28(%ebp)
801010b5:	e8 b6 f0 ff ff       	call   80100170 <bread>
801010ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801010bd:	83 c4 10             	add    $0x10,%esp
801010c0:	b8 00 00 00 00       	mov    $0x0,%eax
801010c5:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801010ca:	7f b2                	jg     8010107e <balloc+0x13>
801010cc:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
801010cf:	89 5d e0             	mov    %ebx,-0x20(%ebp)
801010d2:	3b 1d 20 2a 11 80    	cmp    0x80112a20,%ebx
801010d8:	73 a4                	jae    8010107e <balloc+0x13>
      m = 1 << (bi % 8);
801010da:	99                   	cltd   
801010db:	c1 ea 1d             	shr    $0x1d,%edx
801010de:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801010e1:	83 e1 07             	and    $0x7,%ecx
801010e4:	29 d1                	sub    %edx,%ecx
801010e6:	ba 01 00 00 00       	mov    $0x1,%edx
801010eb:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801010ed:	8d 48 07             	lea    0x7(%eax),%ecx
801010f0:	85 c0                	test   %eax,%eax
801010f2:	0f 49 c8             	cmovns %eax,%ecx
801010f5:	c1 f9 03             	sar    $0x3,%ecx
801010f8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
801010fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801010fe:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101103:	0f b6 f9             	movzbl %cl,%edi
80101106:	85 d7                	test   %edx,%edi
80101108:	74 12                	je     8010111c <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010110a:	83 c0 01             	add    $0x1,%eax
8010110d:	eb b6                	jmp    801010c5 <balloc+0x5a>
  panic("balloc: out of blocks");
8010110f:	83 ec 0c             	sub    $0xc,%esp
80101112:	68 67 67 10 80       	push   $0x80106767
80101117:	e8 40 f2 ff ff       	call   8010035c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
8010111c:	09 ca                	or     %ecx,%edx
8010111e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101121:	8b 75 dc             	mov    -0x24(%ebp),%esi
80101124:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
80101128:	83 ec 0c             	sub    $0xc,%esp
8010112b:	89 c6                	mov    %eax,%esi
8010112d:	50                   	push   %eax
8010112e:	e8 8b 18 00 00       	call   801029be <log_write>
        brelse(bp);
80101133:	89 34 24             	mov    %esi,(%esp)
80101136:	e8 a6 f0 ff ff       	call   801001e1 <brelse>
        bzero(dev, b + bi);
8010113b:	89 da                	mov    %ebx,%edx
8010113d:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101140:	e8 eb fe ff ff       	call   80101030 <bzero>
}
80101145:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101148:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114b:	5b                   	pop    %ebx
8010114c:	5e                   	pop    %esi
8010114d:	5f                   	pop    %edi
8010114e:	5d                   	pop    %ebp
8010114f:	c3                   	ret    

80101150 <bmap>:
{
80101150:	55                   	push   %ebp
80101151:	89 e5                	mov    %esp,%ebp
80101153:	57                   	push   %edi
80101154:	56                   	push   %esi
80101155:	53                   	push   %ebx
80101156:	83 ec 1c             	sub    $0x1c,%esp
80101159:	89 c3                	mov    %eax,%ebx
8010115b:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
8010115d:	83 fa 0b             	cmp    $0xb,%edx
80101160:	76 45                	jbe    801011a7 <bmap+0x57>
  bn -= NDIRECT;
80101162:	8d 72 f4             	lea    -0xc(%edx),%esi
  if(bn < NINDIRECT){
80101165:	83 fe 7f             	cmp    $0x7f,%esi
80101168:	77 7f                	ja     801011e9 <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
8010116a:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101170:	85 c0                	test   %eax,%eax
80101172:	74 4a                	je     801011be <bmap+0x6e>
    bp = bread(ip->dev, addr);
80101174:	83 ec 08             	sub    $0x8,%esp
80101177:	50                   	push   %eax
80101178:	ff 33                	pushl  (%ebx)
8010117a:	e8 f1 ef ff ff       	call   80100170 <bread>
8010117f:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101181:	8d 44 b0 5c          	lea    0x5c(%eax,%esi,4),%eax
80101185:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101188:	8b 30                	mov    (%eax),%esi
8010118a:	83 c4 10             	add    $0x10,%esp
8010118d:	85 f6                	test   %esi,%esi
8010118f:	74 3c                	je     801011cd <bmap+0x7d>
    brelse(bp);
80101191:	83 ec 0c             	sub    $0xc,%esp
80101194:	57                   	push   %edi
80101195:	e8 47 f0 ff ff       	call   801001e1 <brelse>
    return addr;
8010119a:	83 c4 10             	add    $0x10,%esp
}
8010119d:	89 f0                	mov    %esi,%eax
8010119f:	8d 65 f4             	lea    -0xc(%ebp),%esp
801011a2:	5b                   	pop    %ebx
801011a3:	5e                   	pop    %esi
801011a4:	5f                   	pop    %edi
801011a5:	5d                   	pop    %ebp
801011a6:	c3                   	ret    
    if((addr = ip->addrs[bn]) == 0)
801011a7:	8b 74 90 5c          	mov    0x5c(%eax,%edx,4),%esi
801011ab:	85 f6                	test   %esi,%esi
801011ad:	75 ee                	jne    8010119d <bmap+0x4d>
      ip->addrs[bn] = addr = balloc(ip->dev);
801011af:	8b 00                	mov    (%eax),%eax
801011b1:	e8 b5 fe ff ff       	call   8010106b <balloc>
801011b6:	89 c6                	mov    %eax,%esi
801011b8:	89 44 bb 5c          	mov    %eax,0x5c(%ebx,%edi,4)
    return addr;
801011bc:	eb df                	jmp    8010119d <bmap+0x4d>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801011be:	8b 03                	mov    (%ebx),%eax
801011c0:	e8 a6 fe ff ff       	call   8010106b <balloc>
801011c5:	89 83 8c 00 00 00    	mov    %eax,0x8c(%ebx)
801011cb:	eb a7                	jmp    80101174 <bmap+0x24>
      a[bn] = addr = balloc(ip->dev);
801011cd:	8b 03                	mov    (%ebx),%eax
801011cf:	e8 97 fe ff ff       	call   8010106b <balloc>
801011d4:	89 c6                	mov    %eax,%esi
801011d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011d9:	89 30                	mov    %esi,(%eax)
      log_write(bp);
801011db:	83 ec 0c             	sub    $0xc,%esp
801011de:	57                   	push   %edi
801011df:	e8 da 17 00 00       	call   801029be <log_write>
801011e4:	83 c4 10             	add    $0x10,%esp
801011e7:	eb a8                	jmp    80101191 <bmap+0x41>
  panic("bmap: out of range");
801011e9:	83 ec 0c             	sub    $0xc,%esp
801011ec:	68 7d 67 10 80       	push   $0x8010677d
801011f1:	e8 66 f1 ff ff       	call   8010035c <panic>

801011f6 <iget>:
{
801011f6:	55                   	push   %ebp
801011f7:	89 e5                	mov    %esp,%ebp
801011f9:	57                   	push   %edi
801011fa:	56                   	push   %esi
801011fb:	53                   	push   %ebx
801011fc:	83 ec 28             	sub    $0x28,%esp
801011ff:	89 c7                	mov    %eax,%edi
80101201:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101204:	68 40 2a 11 80       	push   $0x80112a40
80101209:	e8 a0 2b 00 00       	call   80103dae <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010120e:	83 c4 10             	add    $0x10,%esp
  empty = 0;
80101211:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101216:	bb 74 2a 11 80       	mov    $0x80112a74,%ebx
8010121b:	eb 0a                	jmp    80101227 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010121d:	85 f6                	test   %esi,%esi
8010121f:	74 3b                	je     8010125c <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101221:	81 c3 90 00 00 00    	add    $0x90,%ebx
80101227:	81 fb 94 46 11 80    	cmp    $0x80114694,%ebx
8010122d:	73 35                	jae    80101264 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010122f:	8b 43 08             	mov    0x8(%ebx),%eax
80101232:	85 c0                	test   %eax,%eax
80101234:	7e e7                	jle    8010121d <iget+0x27>
80101236:	39 3b                	cmp    %edi,(%ebx)
80101238:	75 e3                	jne    8010121d <iget+0x27>
8010123a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010123d:	39 4b 04             	cmp    %ecx,0x4(%ebx)
80101240:	75 db                	jne    8010121d <iget+0x27>
      ip->ref++;
80101242:	83 c0 01             	add    $0x1,%eax
80101245:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
80101248:	83 ec 0c             	sub    $0xc,%esp
8010124b:	68 40 2a 11 80       	push   $0x80112a40
80101250:	e8 c2 2b 00 00       	call   80103e17 <release>
      return ip;
80101255:	83 c4 10             	add    $0x10,%esp
80101258:	89 de                	mov    %ebx,%esi
8010125a:	eb 32                	jmp    8010128e <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010125c:	85 c0                	test   %eax,%eax
8010125e:	75 c1                	jne    80101221 <iget+0x2b>
      empty = ip;
80101260:	89 de                	mov    %ebx,%esi
80101262:	eb bd                	jmp    80101221 <iget+0x2b>
  if(empty == 0)
80101264:	85 f6                	test   %esi,%esi
80101266:	74 30                	je     80101298 <iget+0xa2>
  ip->dev = dev;
80101268:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
8010126a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010126d:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101270:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101277:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010127e:	83 ec 0c             	sub    $0xc,%esp
80101281:	68 40 2a 11 80       	push   $0x80112a40
80101286:	e8 8c 2b 00 00       	call   80103e17 <release>
  return ip;
8010128b:	83 c4 10             	add    $0x10,%esp
}
8010128e:	89 f0                	mov    %esi,%eax
80101290:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101293:	5b                   	pop    %ebx
80101294:	5e                   	pop    %esi
80101295:	5f                   	pop    %edi
80101296:	5d                   	pop    %ebp
80101297:	c3                   	ret    
    panic("iget: no inodes");
80101298:	83 ec 0c             	sub    $0xc,%esp
8010129b:	68 90 67 10 80       	push   $0x80106790
801012a0:	e8 b7 f0 ff ff       	call   8010035c <panic>

801012a5 <readsb>:
{
801012a5:	f3 0f 1e fb          	endbr32 
801012a9:	55                   	push   %ebp
801012aa:	89 e5                	mov    %esp,%ebp
801012ac:	53                   	push   %ebx
801012ad:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
801012b0:	6a 01                	push   $0x1
801012b2:	ff 75 08             	pushl  0x8(%ebp)
801012b5:	e8 b6 ee ff ff       	call   80100170 <bread>
801012ba:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
801012bc:	8d 40 5c             	lea    0x5c(%eax),%eax
801012bf:	83 c4 0c             	add    $0xc,%esp
801012c2:	6a 1c                	push   $0x1c
801012c4:	50                   	push   %eax
801012c5:	ff 75 0c             	pushl  0xc(%ebp)
801012c8:	e8 15 2c 00 00       	call   80103ee2 <memmove>
  brelse(bp);
801012cd:	89 1c 24             	mov    %ebx,(%esp)
801012d0:	e8 0c ef ff ff       	call   801001e1 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801012db:	c9                   	leave  
801012dc:	c3                   	ret    

801012dd <bfree>:
{
801012dd:	55                   	push   %ebp
801012de:	89 e5                	mov    %esp,%ebp
801012e0:	57                   	push   %edi
801012e1:	56                   	push   %esi
801012e2:	53                   	push   %ebx
801012e3:	83 ec 14             	sub    $0x14,%esp
801012e6:	89 c3                	mov    %eax,%ebx
801012e8:	89 d6                	mov    %edx,%esi
  readsb(dev, &sb);
801012ea:	68 20 2a 11 80       	push   $0x80112a20
801012ef:	50                   	push   %eax
801012f0:	e8 b0 ff ff ff       	call   801012a5 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
801012f5:	89 f0                	mov    %esi,%eax
801012f7:	c1 e8 0c             	shr    $0xc,%eax
801012fa:	83 c4 08             	add    $0x8,%esp
801012fd:	03 05 38 2a 11 80    	add    0x80112a38,%eax
80101303:	50                   	push   %eax
80101304:	53                   	push   %ebx
80101305:	e8 66 ee ff ff       	call   80100170 <bread>
8010130a:	89 c3                	mov    %eax,%ebx
  bi = b % BPB;
8010130c:	89 f7                	mov    %esi,%edi
8010130e:	81 e7 ff 0f 00 00    	and    $0xfff,%edi
  m = 1 << (bi % 8);
80101314:	89 f1                	mov    %esi,%ecx
80101316:	83 e1 07             	and    $0x7,%ecx
80101319:	b8 01 00 00 00       	mov    $0x1,%eax
8010131e:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
80101320:	83 c4 10             	add    $0x10,%esp
80101323:	c1 ff 03             	sar    $0x3,%edi
80101326:	0f b6 54 3b 5c       	movzbl 0x5c(%ebx,%edi,1),%edx
8010132b:	0f b6 ca             	movzbl %dl,%ecx
8010132e:	85 c1                	test   %eax,%ecx
80101330:	74 24                	je     80101356 <bfree+0x79>
  bp->data[bi/8] &= ~m;
80101332:	f7 d0                	not    %eax
80101334:	21 d0                	and    %edx,%eax
80101336:	88 44 3b 5c          	mov    %al,0x5c(%ebx,%edi,1)
  log_write(bp);
8010133a:	83 ec 0c             	sub    $0xc,%esp
8010133d:	53                   	push   %ebx
8010133e:	e8 7b 16 00 00       	call   801029be <log_write>
  brelse(bp);
80101343:	89 1c 24             	mov    %ebx,(%esp)
80101346:	e8 96 ee ff ff       	call   801001e1 <brelse>
}
8010134b:	83 c4 10             	add    $0x10,%esp
8010134e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101351:	5b                   	pop    %ebx
80101352:	5e                   	pop    %esi
80101353:	5f                   	pop    %edi
80101354:	5d                   	pop    %ebp
80101355:	c3                   	ret    
    panic("freeing free block");
80101356:	83 ec 0c             	sub    $0xc,%esp
80101359:	68 a0 67 10 80       	push   $0x801067a0
8010135e:	e8 f9 ef ff ff       	call   8010035c <panic>

80101363 <iinit>:
{
80101363:	f3 0f 1e fb          	endbr32 
80101367:	55                   	push   %ebp
80101368:	89 e5                	mov    %esp,%ebp
8010136a:	53                   	push   %ebx
8010136b:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
8010136e:	68 b3 67 10 80       	push   $0x801067b3
80101373:	68 40 2a 11 80       	push   $0x80112a40
80101378:	e8 e1 28 00 00       	call   80103c5e <initlock>
  for(i = 0; i < NINODE; i++) {
8010137d:	83 c4 10             	add    $0x10,%esp
80101380:	bb 00 00 00 00       	mov    $0x0,%ebx
80101385:	83 fb 31             	cmp    $0x31,%ebx
80101388:	7f 23                	jg     801013ad <iinit+0x4a>
    initsleeplock(&icache.inode[i].lock, "inode");
8010138a:	83 ec 08             	sub    $0x8,%esp
8010138d:	68 ba 67 10 80       	push   $0x801067ba
80101392:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101395:	89 d0                	mov    %edx,%eax
80101397:	c1 e0 04             	shl    $0x4,%eax
8010139a:	05 80 2a 11 80       	add    $0x80112a80,%eax
8010139f:	50                   	push   %eax
801013a0:	e8 c5 27 00 00       	call   80103b6a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
801013a5:	83 c3 01             	add    $0x1,%ebx
801013a8:	83 c4 10             	add    $0x10,%esp
801013ab:	eb d8                	jmp    80101385 <iinit+0x22>
  readsb(dev, &sb);
801013ad:	83 ec 08             	sub    $0x8,%esp
801013b0:	68 20 2a 11 80       	push   $0x80112a20
801013b5:	ff 75 08             	pushl  0x8(%ebp)
801013b8:	e8 e8 fe ff ff       	call   801012a5 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
801013bd:	ff 35 38 2a 11 80    	pushl  0x80112a38
801013c3:	ff 35 34 2a 11 80    	pushl  0x80112a34
801013c9:	ff 35 30 2a 11 80    	pushl  0x80112a30
801013cf:	ff 35 2c 2a 11 80    	pushl  0x80112a2c
801013d5:	ff 35 28 2a 11 80    	pushl  0x80112a28
801013db:	ff 35 24 2a 11 80    	pushl  0x80112a24
801013e1:	ff 35 20 2a 11 80    	pushl  0x80112a20
801013e7:	68 20 68 10 80       	push   $0x80106820
801013ec:	e8 38 f2 ff ff       	call   80100629 <cprintf>
}
801013f1:	83 c4 30             	add    $0x30,%esp
801013f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801013f7:	c9                   	leave  
801013f8:	c3                   	ret    

801013f9 <ialloc>:
{
801013f9:	f3 0f 1e fb          	endbr32 
801013fd:	55                   	push   %ebp
801013fe:	89 e5                	mov    %esp,%ebp
80101400:	57                   	push   %edi
80101401:	56                   	push   %esi
80101402:	53                   	push   %ebx
80101403:	83 ec 1c             	sub    $0x1c,%esp
80101406:	8b 45 0c             	mov    0xc(%ebp),%eax
80101409:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010140c:	bb 01 00 00 00       	mov    $0x1,%ebx
80101411:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101414:	39 1d 28 2a 11 80    	cmp    %ebx,0x80112a28
8010141a:	76 76                	jbe    80101492 <ialloc+0x99>
    bp = bread(dev, IBLOCK(inum, sb));
8010141c:	89 d8                	mov    %ebx,%eax
8010141e:	c1 e8 03             	shr    $0x3,%eax
80101421:	83 ec 08             	sub    $0x8,%esp
80101424:	03 05 34 2a 11 80    	add    0x80112a34,%eax
8010142a:	50                   	push   %eax
8010142b:	ff 75 08             	pushl  0x8(%ebp)
8010142e:	e8 3d ed ff ff       	call   80100170 <bread>
80101433:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
80101435:	89 d8                	mov    %ebx,%eax
80101437:	83 e0 07             	and    $0x7,%eax
8010143a:	c1 e0 06             	shl    $0x6,%eax
8010143d:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
80101441:	83 c4 10             	add    $0x10,%esp
80101444:	66 83 3f 00          	cmpw   $0x0,(%edi)
80101448:	74 11                	je     8010145b <ialloc+0x62>
    brelse(bp);
8010144a:	83 ec 0c             	sub    $0xc,%esp
8010144d:	56                   	push   %esi
8010144e:	e8 8e ed ff ff       	call   801001e1 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
80101453:	83 c3 01             	add    $0x1,%ebx
80101456:	83 c4 10             	add    $0x10,%esp
80101459:	eb b6                	jmp    80101411 <ialloc+0x18>
      memset(dip, 0, sizeof(*dip));
8010145b:	83 ec 04             	sub    $0x4,%esp
8010145e:	6a 40                	push   $0x40
80101460:	6a 00                	push   $0x0
80101462:	57                   	push   %edi
80101463:	e8 fa 29 00 00       	call   80103e62 <memset>
      dip->type = type;
80101468:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010146c:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
8010146f:	89 34 24             	mov    %esi,(%esp)
80101472:	e8 47 15 00 00       	call   801029be <log_write>
      brelse(bp);
80101477:	89 34 24             	mov    %esi,(%esp)
8010147a:	e8 62 ed ff ff       	call   801001e1 <brelse>
      return iget(dev, inum);
8010147f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101482:	8b 45 08             	mov    0x8(%ebp),%eax
80101485:	e8 6c fd ff ff       	call   801011f6 <iget>
}
8010148a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010148d:	5b                   	pop    %ebx
8010148e:	5e                   	pop    %esi
8010148f:	5f                   	pop    %edi
80101490:	5d                   	pop    %ebp
80101491:	c3                   	ret    
  panic("ialloc: no inodes");
80101492:	83 ec 0c             	sub    $0xc,%esp
80101495:	68 c0 67 10 80       	push   $0x801067c0
8010149a:	e8 bd ee ff ff       	call   8010035c <panic>

8010149f <iupdate>:
{
8010149f:	f3 0f 1e fb          	endbr32 
801014a3:	55                   	push   %ebp
801014a4:	89 e5                	mov    %esp,%ebp
801014a6:	56                   	push   %esi
801014a7:	53                   	push   %ebx
801014a8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801014ab:	8b 43 04             	mov    0x4(%ebx),%eax
801014ae:	c1 e8 03             	shr    $0x3,%eax
801014b1:	83 ec 08             	sub    $0x8,%esp
801014b4:	03 05 34 2a 11 80    	add    0x80112a34,%eax
801014ba:	50                   	push   %eax
801014bb:	ff 33                	pushl  (%ebx)
801014bd:	e8 ae ec ff ff       	call   80100170 <bread>
801014c2:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801014c4:	8b 43 04             	mov    0x4(%ebx),%eax
801014c7:	83 e0 07             	and    $0x7,%eax
801014ca:	c1 e0 06             	shl    $0x6,%eax
801014cd:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
801014d1:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
801014d5:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801014d8:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
801014dc:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801014e0:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
801014e4:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801014e8:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
801014ec:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801014f0:	8b 53 58             	mov    0x58(%ebx),%edx
801014f3:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801014f6:	83 c3 5c             	add    $0x5c,%ebx
801014f9:	83 c0 0c             	add    $0xc,%eax
801014fc:	83 c4 0c             	add    $0xc,%esp
801014ff:	6a 34                	push   $0x34
80101501:	53                   	push   %ebx
80101502:	50                   	push   %eax
80101503:	e8 da 29 00 00       	call   80103ee2 <memmove>
  log_write(bp);
80101508:	89 34 24             	mov    %esi,(%esp)
8010150b:	e8 ae 14 00 00       	call   801029be <log_write>
  brelse(bp);
80101510:	89 34 24             	mov    %esi,(%esp)
80101513:	e8 c9 ec ff ff       	call   801001e1 <brelse>
}
80101518:	83 c4 10             	add    $0x10,%esp
8010151b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010151e:	5b                   	pop    %ebx
8010151f:	5e                   	pop    %esi
80101520:	5d                   	pop    %ebp
80101521:	c3                   	ret    

80101522 <itrunc>:
{
80101522:	55                   	push   %ebp
80101523:	89 e5                	mov    %esp,%ebp
80101525:	57                   	push   %edi
80101526:	56                   	push   %esi
80101527:	53                   	push   %ebx
80101528:	83 ec 1c             	sub    $0x1c,%esp
8010152b:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
8010152d:	bb 00 00 00 00       	mov    $0x0,%ebx
80101532:	eb 03                	jmp    80101537 <itrunc+0x15>
80101534:	83 c3 01             	add    $0x1,%ebx
80101537:	83 fb 0b             	cmp    $0xb,%ebx
8010153a:	7f 19                	jg     80101555 <itrunc+0x33>
    if(ip->addrs[i]){
8010153c:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
80101540:	85 d2                	test   %edx,%edx
80101542:	74 f0                	je     80101534 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
80101544:	8b 06                	mov    (%esi),%eax
80101546:	e8 92 fd ff ff       	call   801012dd <bfree>
      ip->addrs[i] = 0;
8010154b:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
80101552:	00 
80101553:	eb df                	jmp    80101534 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
80101555:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
8010155b:	85 c0                	test   %eax,%eax
8010155d:	75 1b                	jne    8010157a <itrunc+0x58>
  ip->size = 0;
8010155f:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
80101566:	83 ec 0c             	sub    $0xc,%esp
80101569:	56                   	push   %esi
8010156a:	e8 30 ff ff ff       	call   8010149f <iupdate>
}
8010156f:	83 c4 10             	add    $0x10,%esp
80101572:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101575:	5b                   	pop    %ebx
80101576:	5e                   	pop    %esi
80101577:	5f                   	pop    %edi
80101578:	5d                   	pop    %ebp
80101579:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
8010157a:	83 ec 08             	sub    $0x8,%esp
8010157d:	50                   	push   %eax
8010157e:	ff 36                	pushl  (%esi)
80101580:	e8 eb eb ff ff       	call   80100170 <bread>
80101585:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101588:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
8010158b:	83 c4 10             	add    $0x10,%esp
8010158e:	bb 00 00 00 00       	mov    $0x0,%ebx
80101593:	eb 0a                	jmp    8010159f <itrunc+0x7d>
        bfree(ip->dev, a[j]);
80101595:	8b 06                	mov    (%esi),%eax
80101597:	e8 41 fd ff ff       	call   801012dd <bfree>
    for(j = 0; j < NINDIRECT; j++){
8010159c:	83 c3 01             	add    $0x1,%ebx
8010159f:	83 fb 7f             	cmp    $0x7f,%ebx
801015a2:	77 09                	ja     801015ad <itrunc+0x8b>
      if(a[j])
801015a4:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
801015a7:	85 d2                	test   %edx,%edx
801015a9:	74 f1                	je     8010159c <itrunc+0x7a>
801015ab:	eb e8                	jmp    80101595 <itrunc+0x73>
    brelse(bp);
801015ad:	83 ec 0c             	sub    $0xc,%esp
801015b0:	ff 75 e4             	pushl  -0x1c(%ebp)
801015b3:	e8 29 ec ff ff       	call   801001e1 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
801015b8:	8b 06                	mov    (%esi),%eax
801015ba:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
801015c0:	e8 18 fd ff ff       	call   801012dd <bfree>
    ip->addrs[NDIRECT] = 0;
801015c5:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
801015cc:	00 00 00 
801015cf:	83 c4 10             	add    $0x10,%esp
801015d2:	eb 8b                	jmp    8010155f <itrunc+0x3d>

801015d4 <idup>:
{
801015d4:	f3 0f 1e fb          	endbr32 
801015d8:	55                   	push   %ebp
801015d9:	89 e5                	mov    %esp,%ebp
801015db:	53                   	push   %ebx
801015dc:	83 ec 10             	sub    $0x10,%esp
801015df:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
801015e2:	68 40 2a 11 80       	push   $0x80112a40
801015e7:	e8 c2 27 00 00       	call   80103dae <acquire>
  ip->ref++;
801015ec:	8b 43 08             	mov    0x8(%ebx),%eax
801015ef:	83 c0 01             	add    $0x1,%eax
801015f2:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801015f5:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
801015fc:	e8 16 28 00 00       	call   80103e17 <release>
}
80101601:	89 d8                	mov    %ebx,%eax
80101603:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101606:	c9                   	leave  
80101607:	c3                   	ret    

80101608 <ilock>:
{
80101608:	f3 0f 1e fb          	endbr32 
8010160c:	55                   	push   %ebp
8010160d:	89 e5                	mov    %esp,%ebp
8010160f:	56                   	push   %esi
80101610:	53                   	push   %ebx
80101611:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101614:	85 db                	test   %ebx,%ebx
80101616:	74 22                	je     8010163a <ilock+0x32>
80101618:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
8010161c:	7e 1c                	jle    8010163a <ilock+0x32>
  acquiresleep(&ip->lock);
8010161e:	83 ec 0c             	sub    $0xc,%esp
80101621:	8d 43 0c             	lea    0xc(%ebx),%eax
80101624:	50                   	push   %eax
80101625:	e8 77 25 00 00       	call   80103ba1 <acquiresleep>
  if(ip->valid == 0){
8010162a:	83 c4 10             	add    $0x10,%esp
8010162d:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101631:	74 14                	je     80101647 <ilock+0x3f>
}
80101633:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101636:	5b                   	pop    %ebx
80101637:	5e                   	pop    %esi
80101638:	5d                   	pop    %ebp
80101639:	c3                   	ret    
    panic("ilock");
8010163a:	83 ec 0c             	sub    $0xc,%esp
8010163d:	68 d2 67 10 80       	push   $0x801067d2
80101642:	e8 15 ed ff ff       	call   8010035c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101647:	8b 43 04             	mov    0x4(%ebx),%eax
8010164a:	c1 e8 03             	shr    $0x3,%eax
8010164d:	83 ec 08             	sub    $0x8,%esp
80101650:	03 05 34 2a 11 80    	add    0x80112a34,%eax
80101656:	50                   	push   %eax
80101657:	ff 33                	pushl  (%ebx)
80101659:	e8 12 eb ff ff       	call   80100170 <bread>
8010165e:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101660:	8b 43 04             	mov    0x4(%ebx),%eax
80101663:	83 e0 07             	and    $0x7,%eax
80101666:	c1 e0 06             	shl    $0x6,%eax
80101669:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
8010166d:	0f b7 10             	movzwl (%eax),%edx
80101670:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
80101674:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101678:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
8010167c:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101680:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
80101684:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101688:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
8010168c:	8b 50 08             	mov    0x8(%eax),%edx
8010168f:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101692:	83 c0 0c             	add    $0xc,%eax
80101695:	8d 53 5c             	lea    0x5c(%ebx),%edx
80101698:	83 c4 0c             	add    $0xc,%esp
8010169b:	6a 34                	push   $0x34
8010169d:	50                   	push   %eax
8010169e:	52                   	push   %edx
8010169f:	e8 3e 28 00 00       	call   80103ee2 <memmove>
    brelse(bp);
801016a4:	89 34 24             	mov    %esi,(%esp)
801016a7:	e8 35 eb ff ff       	call   801001e1 <brelse>
    ip->valid = 1;
801016ac:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
801016b3:	83 c4 10             	add    $0x10,%esp
801016b6:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
801016bb:	0f 85 72 ff ff ff    	jne    80101633 <ilock+0x2b>
      panic("ilock: no type");
801016c1:	83 ec 0c             	sub    $0xc,%esp
801016c4:	68 d8 67 10 80       	push   $0x801067d8
801016c9:	e8 8e ec ff ff       	call   8010035c <panic>

801016ce <iunlock>:
{
801016ce:	f3 0f 1e fb          	endbr32 
801016d2:	55                   	push   %ebp
801016d3:	89 e5                	mov    %esp,%ebp
801016d5:	56                   	push   %esi
801016d6:	53                   	push   %ebx
801016d7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
801016da:	85 db                	test   %ebx,%ebx
801016dc:	74 2c                	je     8010170a <iunlock+0x3c>
801016de:	8d 73 0c             	lea    0xc(%ebx),%esi
801016e1:	83 ec 0c             	sub    $0xc,%esp
801016e4:	56                   	push   %esi
801016e5:	e8 49 25 00 00       	call   80103c33 <holdingsleep>
801016ea:	83 c4 10             	add    $0x10,%esp
801016ed:	85 c0                	test   %eax,%eax
801016ef:	74 19                	je     8010170a <iunlock+0x3c>
801016f1:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
801016f5:	7e 13                	jle    8010170a <iunlock+0x3c>
  releasesleep(&ip->lock);
801016f7:	83 ec 0c             	sub    $0xc,%esp
801016fa:	56                   	push   %esi
801016fb:	e8 f4 24 00 00       	call   80103bf4 <releasesleep>
}
80101700:	83 c4 10             	add    $0x10,%esp
80101703:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101706:	5b                   	pop    %ebx
80101707:	5e                   	pop    %esi
80101708:	5d                   	pop    %ebp
80101709:	c3                   	ret    
    panic("iunlock");
8010170a:	83 ec 0c             	sub    $0xc,%esp
8010170d:	68 e7 67 10 80       	push   $0x801067e7
80101712:	e8 45 ec ff ff       	call   8010035c <panic>

80101717 <iput>:
{
80101717:	f3 0f 1e fb          	endbr32 
8010171b:	55                   	push   %ebp
8010171c:	89 e5                	mov    %esp,%ebp
8010171e:	57                   	push   %edi
8010171f:	56                   	push   %esi
80101720:	53                   	push   %ebx
80101721:	83 ec 18             	sub    $0x18,%esp
80101724:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101727:	8d 73 0c             	lea    0xc(%ebx),%esi
8010172a:	56                   	push   %esi
8010172b:	e8 71 24 00 00       	call   80103ba1 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
80101730:	83 c4 10             	add    $0x10,%esp
80101733:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101737:	74 07                	je     80101740 <iput+0x29>
80101739:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010173e:	74 35                	je     80101775 <iput+0x5e>
  releasesleep(&ip->lock);
80101740:	83 ec 0c             	sub    $0xc,%esp
80101743:	56                   	push   %esi
80101744:	e8 ab 24 00 00       	call   80103bf4 <releasesleep>
  acquire(&icache.lock);
80101749:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
80101750:	e8 59 26 00 00       	call   80103dae <acquire>
  ip->ref--;
80101755:	8b 43 08             	mov    0x8(%ebx),%eax
80101758:	83 e8 01             	sub    $0x1,%eax
8010175b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010175e:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
80101765:	e8 ad 26 00 00       	call   80103e17 <release>
}
8010176a:	83 c4 10             	add    $0x10,%esp
8010176d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101770:	5b                   	pop    %ebx
80101771:	5e                   	pop    %esi
80101772:	5f                   	pop    %edi
80101773:	5d                   	pop    %ebp
80101774:	c3                   	ret    
    acquire(&icache.lock);
80101775:	83 ec 0c             	sub    $0xc,%esp
80101778:	68 40 2a 11 80       	push   $0x80112a40
8010177d:	e8 2c 26 00 00       	call   80103dae <acquire>
    int r = ip->ref;
80101782:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
80101785:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
8010178c:	e8 86 26 00 00       	call   80103e17 <release>
    if(r == 1){
80101791:	83 c4 10             	add    $0x10,%esp
80101794:	83 ff 01             	cmp    $0x1,%edi
80101797:	75 a7                	jne    80101740 <iput+0x29>
      itrunc(ip);
80101799:	89 d8                	mov    %ebx,%eax
8010179b:	e8 82 fd ff ff       	call   80101522 <itrunc>
      ip->type = 0;
801017a0:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
801017a6:	83 ec 0c             	sub    $0xc,%esp
801017a9:	53                   	push   %ebx
801017aa:	e8 f0 fc ff ff       	call   8010149f <iupdate>
      ip->valid = 0;
801017af:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
801017b6:	83 c4 10             	add    $0x10,%esp
801017b9:	eb 85                	jmp    80101740 <iput+0x29>

801017bb <iunlockput>:
{
801017bb:	f3 0f 1e fb          	endbr32 
801017bf:	55                   	push   %ebp
801017c0:	89 e5                	mov    %esp,%ebp
801017c2:	53                   	push   %ebx
801017c3:	83 ec 10             	sub    $0x10,%esp
801017c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
801017c9:	53                   	push   %ebx
801017ca:	e8 ff fe ff ff       	call   801016ce <iunlock>
  iput(ip);
801017cf:	89 1c 24             	mov    %ebx,(%esp)
801017d2:	e8 40 ff ff ff       	call   80101717 <iput>
}
801017d7:	83 c4 10             	add    $0x10,%esp
801017da:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801017dd:	c9                   	leave  
801017de:	c3                   	ret    

801017df <stati>:
{
801017df:	f3 0f 1e fb          	endbr32 
801017e3:	55                   	push   %ebp
801017e4:	89 e5                	mov    %esp,%ebp
801017e6:	8b 55 08             	mov    0x8(%ebp),%edx
801017e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
801017ec:	8b 0a                	mov    (%edx),%ecx
801017ee:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
801017f1:	8b 4a 04             	mov    0x4(%edx),%ecx
801017f4:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
801017f7:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
801017fb:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
801017fe:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101802:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
80101806:	8b 52 58             	mov    0x58(%edx),%edx
80101809:	89 50 10             	mov    %edx,0x10(%eax)
}
8010180c:	5d                   	pop    %ebp
8010180d:	c3                   	ret    

8010180e <readi>:
{
8010180e:	f3 0f 1e fb          	endbr32 
80101812:	55                   	push   %ebp
80101813:	89 e5                	mov    %esp,%ebp
80101815:	57                   	push   %edi
80101816:	56                   	push   %esi
80101817:	53                   	push   %ebx
80101818:	83 ec 1c             	sub    $0x1c,%esp
8010181b:	8b 75 10             	mov    0x10(%ebp),%esi
  if(ip->type == T_DEV){
8010181e:	8b 45 08             	mov    0x8(%ebp),%eax
80101821:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101826:	74 2c                	je     80101854 <readi+0x46>
  if(off > ip->size || off + n < off)
80101828:	8b 45 08             	mov    0x8(%ebp),%eax
8010182b:	8b 40 58             	mov    0x58(%eax),%eax
8010182e:	39 f0                	cmp    %esi,%eax
80101830:	0f 82 cb 00 00 00    	jb     80101901 <readi+0xf3>
80101836:	89 f2                	mov    %esi,%edx
80101838:	03 55 14             	add    0x14(%ebp),%edx
8010183b:	0f 82 c7 00 00 00    	jb     80101908 <readi+0xfa>
  if(off + n > ip->size)
80101841:	39 d0                	cmp    %edx,%eax
80101843:	73 05                	jae    8010184a <readi+0x3c>
    n = ip->size - off;
80101845:	29 f0                	sub    %esi,%eax
80101847:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010184a:	bf 00 00 00 00       	mov    $0x0,%edi
8010184f:	e9 8f 00 00 00       	jmp    801018e3 <readi+0xd5>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101854:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101858:	66 83 f8 09          	cmp    $0x9,%ax
8010185c:	0f 87 91 00 00 00    	ja     801018f3 <readi+0xe5>
80101862:	98                   	cwtl   
80101863:	8b 04 c5 c0 29 11 80 	mov    -0x7feed640(,%eax,8),%eax
8010186a:	85 c0                	test   %eax,%eax
8010186c:	0f 84 88 00 00 00    	je     801018fa <readi+0xec>
    return devsw[ip->major].read(ip, dst, n);
80101872:	83 ec 04             	sub    $0x4,%esp
80101875:	ff 75 14             	pushl  0x14(%ebp)
80101878:	ff 75 0c             	pushl  0xc(%ebp)
8010187b:	ff 75 08             	pushl  0x8(%ebp)
8010187e:	ff d0                	call   *%eax
80101880:	83 c4 10             	add    $0x10,%esp
80101883:	eb 66                	jmp    801018eb <readi+0xdd>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101885:	89 f2                	mov    %esi,%edx
80101887:	c1 ea 09             	shr    $0x9,%edx
8010188a:	8b 45 08             	mov    0x8(%ebp),%eax
8010188d:	e8 be f8 ff ff       	call   80101150 <bmap>
80101892:	83 ec 08             	sub    $0x8,%esp
80101895:	50                   	push   %eax
80101896:	8b 45 08             	mov    0x8(%ebp),%eax
80101899:	ff 30                	pushl  (%eax)
8010189b:	e8 d0 e8 ff ff       	call   80100170 <bread>
801018a0:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
801018a2:	89 f0                	mov    %esi,%eax
801018a4:	25 ff 01 00 00       	and    $0x1ff,%eax
801018a9:	bb 00 02 00 00       	mov    $0x200,%ebx
801018ae:	29 c3                	sub    %eax,%ebx
801018b0:	8b 55 14             	mov    0x14(%ebp),%edx
801018b3:	29 fa                	sub    %edi,%edx
801018b5:	83 c4 0c             	add    $0xc,%esp
801018b8:	39 d3                	cmp    %edx,%ebx
801018ba:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
801018bd:	53                   	push   %ebx
801018be:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
801018c1:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
801018c5:	50                   	push   %eax
801018c6:	ff 75 0c             	pushl  0xc(%ebp)
801018c9:	e8 14 26 00 00       	call   80103ee2 <memmove>
    brelse(bp);
801018ce:	83 c4 04             	add    $0x4,%esp
801018d1:	ff 75 e4             	pushl  -0x1c(%ebp)
801018d4:	e8 08 e9 ff ff       	call   801001e1 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801018d9:	01 df                	add    %ebx,%edi
801018db:	01 de                	add    %ebx,%esi
801018dd:	01 5d 0c             	add    %ebx,0xc(%ebp)
801018e0:	83 c4 10             	add    $0x10,%esp
801018e3:	39 7d 14             	cmp    %edi,0x14(%ebp)
801018e6:	77 9d                	ja     80101885 <readi+0x77>
  return n;
801018e8:	8b 45 14             	mov    0x14(%ebp),%eax
}
801018eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801018ee:	5b                   	pop    %ebx
801018ef:	5e                   	pop    %esi
801018f0:	5f                   	pop    %edi
801018f1:	5d                   	pop    %ebp
801018f2:	c3                   	ret    
      return -1;
801018f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018f8:	eb f1                	jmp    801018eb <readi+0xdd>
801018fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018ff:	eb ea                	jmp    801018eb <readi+0xdd>
    return -1;
80101901:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101906:	eb e3                	jmp    801018eb <readi+0xdd>
80101908:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010190d:	eb dc                	jmp    801018eb <readi+0xdd>

8010190f <writei>:
{
8010190f:	f3 0f 1e fb          	endbr32 
80101913:	55                   	push   %ebp
80101914:	89 e5                	mov    %esp,%ebp
80101916:	57                   	push   %edi
80101917:	56                   	push   %esi
80101918:	53                   	push   %ebx
80101919:	83 ec 1c             	sub    $0x1c,%esp
8010191c:	8b 75 10             	mov    0x10(%ebp),%esi
  if(ip->type == T_DEV){
8010191f:	8b 45 08             	mov    0x8(%ebp),%eax
80101922:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101927:	0f 84 9b 00 00 00    	je     801019c8 <writei+0xb9>
  if(off > ip->size || off + n < off)
8010192d:	8b 45 08             	mov    0x8(%ebp),%eax
80101930:	39 70 58             	cmp    %esi,0x58(%eax)
80101933:	0f 82 f0 00 00 00    	jb     80101a29 <writei+0x11a>
80101939:	89 f0                	mov    %esi,%eax
8010193b:	03 45 14             	add    0x14(%ebp),%eax
8010193e:	0f 82 ec 00 00 00    	jb     80101a30 <writei+0x121>
  if(off + n > MAXFILE*BSIZE)
80101944:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101949:	0f 87 e8 00 00 00    	ja     80101a37 <writei+0x128>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010194f:	bf 00 00 00 00       	mov    $0x0,%edi
80101954:	3b 7d 14             	cmp    0x14(%ebp),%edi
80101957:	0f 83 94 00 00 00    	jae    801019f1 <writei+0xe2>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010195d:	89 f2                	mov    %esi,%edx
8010195f:	c1 ea 09             	shr    $0x9,%edx
80101962:	8b 45 08             	mov    0x8(%ebp),%eax
80101965:	e8 e6 f7 ff ff       	call   80101150 <bmap>
8010196a:	83 ec 08             	sub    $0x8,%esp
8010196d:	50                   	push   %eax
8010196e:	8b 45 08             	mov    0x8(%ebp),%eax
80101971:	ff 30                	pushl  (%eax)
80101973:	e8 f8 e7 ff ff       	call   80100170 <bread>
80101978:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
8010197a:	89 f0                	mov    %esi,%eax
8010197c:	25 ff 01 00 00       	and    $0x1ff,%eax
80101981:	bb 00 02 00 00       	mov    $0x200,%ebx
80101986:	29 c3                	sub    %eax,%ebx
80101988:	8b 55 14             	mov    0x14(%ebp),%edx
8010198b:	29 fa                	sub    %edi,%edx
8010198d:	83 c4 0c             	add    $0xc,%esp
80101990:	39 d3                	cmp    %edx,%ebx
80101992:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
80101995:	53                   	push   %ebx
80101996:	ff 75 0c             	pushl  0xc(%ebp)
80101999:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
8010199c:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
801019a0:	50                   	push   %eax
801019a1:	e8 3c 25 00 00       	call   80103ee2 <memmove>
    log_write(bp);
801019a6:	83 c4 04             	add    $0x4,%esp
801019a9:	ff 75 e4             	pushl  -0x1c(%ebp)
801019ac:	e8 0d 10 00 00       	call   801029be <log_write>
    brelse(bp);
801019b1:	83 c4 04             	add    $0x4,%esp
801019b4:	ff 75 e4             	pushl  -0x1c(%ebp)
801019b7:	e8 25 e8 ff ff       	call   801001e1 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801019bc:	01 df                	add    %ebx,%edi
801019be:	01 de                	add    %ebx,%esi
801019c0:	01 5d 0c             	add    %ebx,0xc(%ebp)
801019c3:	83 c4 10             	add    $0x10,%esp
801019c6:	eb 8c                	jmp    80101954 <writei+0x45>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801019c8:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801019cc:	66 83 f8 09          	cmp    $0x9,%ax
801019d0:	77 49                	ja     80101a1b <writei+0x10c>
801019d2:	98                   	cwtl   
801019d3:	8b 04 c5 c4 29 11 80 	mov    -0x7feed63c(,%eax,8),%eax
801019da:	85 c0                	test   %eax,%eax
801019dc:	74 44                	je     80101a22 <writei+0x113>
    return devsw[ip->major].write(ip, src, n);
801019de:	83 ec 04             	sub    $0x4,%esp
801019e1:	ff 75 14             	pushl  0x14(%ebp)
801019e4:	ff 75 0c             	pushl  0xc(%ebp)
801019e7:	ff 75 08             	pushl  0x8(%ebp)
801019ea:	ff d0                	call   *%eax
801019ec:	83 c4 10             	add    $0x10,%esp
801019ef:	eb 11                	jmp    80101a02 <writei+0xf3>
  if(n > 0 && off > ip->size){
801019f1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801019f5:	74 08                	je     801019ff <writei+0xf0>
801019f7:	8b 45 08             	mov    0x8(%ebp),%eax
801019fa:	39 70 58             	cmp    %esi,0x58(%eax)
801019fd:	72 0b                	jb     80101a0a <writei+0xfb>
  return n;
801019ff:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101a02:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a05:	5b                   	pop    %ebx
80101a06:	5e                   	pop    %esi
80101a07:	5f                   	pop    %edi
80101a08:	5d                   	pop    %ebp
80101a09:	c3                   	ret    
    ip->size = off;
80101a0a:	89 70 58             	mov    %esi,0x58(%eax)
    iupdate(ip);
80101a0d:	83 ec 0c             	sub    $0xc,%esp
80101a10:	50                   	push   %eax
80101a11:	e8 89 fa ff ff       	call   8010149f <iupdate>
80101a16:	83 c4 10             	add    $0x10,%esp
80101a19:	eb e4                	jmp    801019ff <writei+0xf0>
      return -1;
80101a1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a20:	eb e0                	jmp    80101a02 <writei+0xf3>
80101a22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a27:	eb d9                	jmp    80101a02 <writei+0xf3>
    return -1;
80101a29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a2e:	eb d2                	jmp    80101a02 <writei+0xf3>
80101a30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a35:	eb cb                	jmp    80101a02 <writei+0xf3>
    return -1;
80101a37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a3c:	eb c4                	jmp    80101a02 <writei+0xf3>

80101a3e <namecmp>:
{
80101a3e:	f3 0f 1e fb          	endbr32 
80101a42:	55                   	push   %ebp
80101a43:	89 e5                	mov    %esp,%ebp
80101a45:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
80101a48:	6a 0e                	push   $0xe
80101a4a:	ff 75 0c             	pushl  0xc(%ebp)
80101a4d:	ff 75 08             	pushl  0x8(%ebp)
80101a50:	e8 ff 24 00 00       	call   80103f54 <strncmp>
}
80101a55:	c9                   	leave  
80101a56:	c3                   	ret    

80101a57 <dirlookup>:
{
80101a57:	f3 0f 1e fb          	endbr32 
80101a5b:	55                   	push   %ebp
80101a5c:	89 e5                	mov    %esp,%ebp
80101a5e:	57                   	push   %edi
80101a5f:	56                   	push   %esi
80101a60:	53                   	push   %ebx
80101a61:	83 ec 1c             	sub    $0x1c,%esp
80101a64:	8b 75 08             	mov    0x8(%ebp),%esi
80101a67:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
80101a6a:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101a6f:	75 07                	jne    80101a78 <dirlookup+0x21>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101a71:	bb 00 00 00 00       	mov    $0x0,%ebx
80101a76:	eb 1d                	jmp    80101a95 <dirlookup+0x3e>
    panic("dirlookup not DIR");
80101a78:	83 ec 0c             	sub    $0xc,%esp
80101a7b:	68 ef 67 10 80       	push   $0x801067ef
80101a80:	e8 d7 e8 ff ff       	call   8010035c <panic>
      panic("dirlookup read");
80101a85:	83 ec 0c             	sub    $0xc,%esp
80101a88:	68 01 68 10 80       	push   $0x80106801
80101a8d:	e8 ca e8 ff ff       	call   8010035c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101a92:	83 c3 10             	add    $0x10,%ebx
80101a95:	39 5e 58             	cmp    %ebx,0x58(%esi)
80101a98:	76 48                	jbe    80101ae2 <dirlookup+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101a9a:	6a 10                	push   $0x10
80101a9c:	53                   	push   %ebx
80101a9d:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101aa0:	50                   	push   %eax
80101aa1:	56                   	push   %esi
80101aa2:	e8 67 fd ff ff       	call   8010180e <readi>
80101aa7:	83 c4 10             	add    $0x10,%esp
80101aaa:	83 f8 10             	cmp    $0x10,%eax
80101aad:	75 d6                	jne    80101a85 <dirlookup+0x2e>
    if(de.inum == 0)
80101aaf:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101ab4:	74 dc                	je     80101a92 <dirlookup+0x3b>
    if(namecmp(name, de.name) == 0){
80101ab6:	83 ec 08             	sub    $0x8,%esp
80101ab9:	8d 45 da             	lea    -0x26(%ebp),%eax
80101abc:	50                   	push   %eax
80101abd:	57                   	push   %edi
80101abe:	e8 7b ff ff ff       	call   80101a3e <namecmp>
80101ac3:	83 c4 10             	add    $0x10,%esp
80101ac6:	85 c0                	test   %eax,%eax
80101ac8:	75 c8                	jne    80101a92 <dirlookup+0x3b>
      if(poff)
80101aca:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101ace:	74 05                	je     80101ad5 <dirlookup+0x7e>
        *poff = off;
80101ad0:	8b 45 10             	mov    0x10(%ebp),%eax
80101ad3:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101ad5:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101ad9:	8b 06                	mov    (%esi),%eax
80101adb:	e8 16 f7 ff ff       	call   801011f6 <iget>
80101ae0:	eb 05                	jmp    80101ae7 <dirlookup+0x90>
  return 0;
80101ae2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101ae7:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101aea:	5b                   	pop    %ebx
80101aeb:	5e                   	pop    %esi
80101aec:	5f                   	pop    %edi
80101aed:	5d                   	pop    %ebp
80101aee:	c3                   	ret    

80101aef <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101aef:	55                   	push   %ebp
80101af0:	89 e5                	mov    %esp,%ebp
80101af2:	57                   	push   %edi
80101af3:	56                   	push   %esi
80101af4:	53                   	push   %ebx
80101af5:	83 ec 1c             	sub    $0x1c,%esp
80101af8:	89 c3                	mov    %eax,%ebx
80101afa:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101afd:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101b00:	80 38 2f             	cmpb   $0x2f,(%eax)
80101b03:	74 17                	je     80101b1c <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101b05:	e8 10 18 00 00       	call   8010331a <myproc>
80101b0a:	83 ec 0c             	sub    $0xc,%esp
80101b0d:	ff 70 6c             	pushl  0x6c(%eax)
80101b10:	e8 bf fa ff ff       	call   801015d4 <idup>
80101b15:	89 c6                	mov    %eax,%esi
80101b17:	83 c4 10             	add    $0x10,%esp
80101b1a:	eb 53                	jmp    80101b6f <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101b1c:	ba 01 00 00 00       	mov    $0x1,%edx
80101b21:	b8 01 00 00 00       	mov    $0x1,%eax
80101b26:	e8 cb f6 ff ff       	call   801011f6 <iget>
80101b2b:	89 c6                	mov    %eax,%esi
80101b2d:	eb 40                	jmp    80101b6f <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101b2f:	83 ec 0c             	sub    $0xc,%esp
80101b32:	56                   	push   %esi
80101b33:	e8 83 fc ff ff       	call   801017bb <iunlockput>
      return 0;
80101b38:	83 c4 10             	add    $0x10,%esp
80101b3b:	be 00 00 00 00       	mov    $0x0,%esi
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101b40:	89 f0                	mov    %esi,%eax
80101b42:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101b45:	5b                   	pop    %ebx
80101b46:	5e                   	pop    %esi
80101b47:	5f                   	pop    %edi
80101b48:	5d                   	pop    %ebp
80101b49:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101b4a:	83 ec 04             	sub    $0x4,%esp
80101b4d:	6a 00                	push   $0x0
80101b4f:	ff 75 e4             	pushl  -0x1c(%ebp)
80101b52:	56                   	push   %esi
80101b53:	e8 ff fe ff ff       	call   80101a57 <dirlookup>
80101b58:	89 c7                	mov    %eax,%edi
80101b5a:	83 c4 10             	add    $0x10,%esp
80101b5d:	85 c0                	test   %eax,%eax
80101b5f:	74 4a                	je     80101bab <namex+0xbc>
    iunlockput(ip);
80101b61:	83 ec 0c             	sub    $0xc,%esp
80101b64:	56                   	push   %esi
80101b65:	e8 51 fc ff ff       	call   801017bb <iunlockput>
80101b6a:	83 c4 10             	add    $0x10,%esp
    ip = next;
80101b6d:	89 fe                	mov    %edi,%esi
  while((path = skipelem(path, name)) != 0){
80101b6f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101b72:	89 d8                	mov    %ebx,%eax
80101b74:	e8 3b f4 ff ff       	call   80100fb4 <skipelem>
80101b79:	89 c3                	mov    %eax,%ebx
80101b7b:	85 c0                	test   %eax,%eax
80101b7d:	74 3c                	je     80101bbb <namex+0xcc>
    ilock(ip);
80101b7f:	83 ec 0c             	sub    $0xc,%esp
80101b82:	56                   	push   %esi
80101b83:	e8 80 fa ff ff       	call   80101608 <ilock>
    if(ip->type != T_DIR){
80101b88:	83 c4 10             	add    $0x10,%esp
80101b8b:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101b90:	75 9d                	jne    80101b2f <namex+0x40>
    if(nameiparent && *path == '\0'){
80101b92:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b96:	74 b2                	je     80101b4a <namex+0x5b>
80101b98:	80 3b 00             	cmpb   $0x0,(%ebx)
80101b9b:	75 ad                	jne    80101b4a <namex+0x5b>
      iunlock(ip);
80101b9d:	83 ec 0c             	sub    $0xc,%esp
80101ba0:	56                   	push   %esi
80101ba1:	e8 28 fb ff ff       	call   801016ce <iunlock>
      return ip;
80101ba6:	83 c4 10             	add    $0x10,%esp
80101ba9:	eb 95                	jmp    80101b40 <namex+0x51>
      iunlockput(ip);
80101bab:	83 ec 0c             	sub    $0xc,%esp
80101bae:	56                   	push   %esi
80101baf:	e8 07 fc ff ff       	call   801017bb <iunlockput>
      return 0;
80101bb4:	83 c4 10             	add    $0x10,%esp
80101bb7:	89 fe                	mov    %edi,%esi
80101bb9:	eb 85                	jmp    80101b40 <namex+0x51>
  if(nameiparent){
80101bbb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101bbf:	0f 84 7b ff ff ff    	je     80101b40 <namex+0x51>
    iput(ip);
80101bc5:	83 ec 0c             	sub    $0xc,%esp
80101bc8:	56                   	push   %esi
80101bc9:	e8 49 fb ff ff       	call   80101717 <iput>
    return 0;
80101bce:	83 c4 10             	add    $0x10,%esp
80101bd1:	89 de                	mov    %ebx,%esi
80101bd3:	e9 68 ff ff ff       	jmp    80101b40 <namex+0x51>

80101bd8 <dirlink>:
{
80101bd8:	f3 0f 1e fb          	endbr32 
80101bdc:	55                   	push   %ebp
80101bdd:	89 e5                	mov    %esp,%ebp
80101bdf:	57                   	push   %edi
80101be0:	56                   	push   %esi
80101be1:	53                   	push   %ebx
80101be2:	83 ec 20             	sub    $0x20,%esp
80101be5:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101be8:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101beb:	6a 00                	push   $0x0
80101bed:	57                   	push   %edi
80101bee:	53                   	push   %ebx
80101bef:	e8 63 fe ff ff       	call   80101a57 <dirlookup>
80101bf4:	83 c4 10             	add    $0x10,%esp
80101bf7:	85 c0                	test   %eax,%eax
80101bf9:	75 07                	jne    80101c02 <dirlink+0x2a>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101bfb:	b8 00 00 00 00       	mov    $0x0,%eax
80101c00:	eb 23                	jmp    80101c25 <dirlink+0x4d>
    iput(ip);
80101c02:	83 ec 0c             	sub    $0xc,%esp
80101c05:	50                   	push   %eax
80101c06:	e8 0c fb ff ff       	call   80101717 <iput>
    return -1;
80101c0b:	83 c4 10             	add    $0x10,%esp
80101c0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c13:	eb 63                	jmp    80101c78 <dirlink+0xa0>
      panic("dirlink read");
80101c15:	83 ec 0c             	sub    $0xc,%esp
80101c18:	68 10 68 10 80       	push   $0x80106810
80101c1d:	e8 3a e7 ff ff       	call   8010035c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101c22:	8d 46 10             	lea    0x10(%esi),%eax
80101c25:	89 c6                	mov    %eax,%esi
80101c27:	39 43 58             	cmp    %eax,0x58(%ebx)
80101c2a:	76 1c                	jbe    80101c48 <dirlink+0x70>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101c2c:	6a 10                	push   $0x10
80101c2e:	50                   	push   %eax
80101c2f:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101c32:	50                   	push   %eax
80101c33:	53                   	push   %ebx
80101c34:	e8 d5 fb ff ff       	call   8010180e <readi>
80101c39:	83 c4 10             	add    $0x10,%esp
80101c3c:	83 f8 10             	cmp    $0x10,%eax
80101c3f:	75 d4                	jne    80101c15 <dirlink+0x3d>
    if(de.inum == 0)
80101c41:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101c46:	75 da                	jne    80101c22 <dirlink+0x4a>
  strncpy(de.name, name, DIRSIZ);
80101c48:	83 ec 04             	sub    $0x4,%esp
80101c4b:	6a 0e                	push   $0xe
80101c4d:	57                   	push   %edi
80101c4e:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101c51:	8d 45 da             	lea    -0x26(%ebp),%eax
80101c54:	50                   	push   %eax
80101c55:	e8 3b 23 00 00       	call   80103f95 <strncpy>
  de.inum = inum;
80101c5a:	8b 45 10             	mov    0x10(%ebp),%eax
80101c5d:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101c61:	6a 10                	push   $0x10
80101c63:	56                   	push   %esi
80101c64:	57                   	push   %edi
80101c65:	53                   	push   %ebx
80101c66:	e8 a4 fc ff ff       	call   8010190f <writei>
80101c6b:	83 c4 20             	add    $0x20,%esp
80101c6e:	83 f8 10             	cmp    $0x10,%eax
80101c71:	75 0d                	jne    80101c80 <dirlink+0xa8>
  return 0;
80101c73:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c78:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101c7b:	5b                   	pop    %ebx
80101c7c:	5e                   	pop    %esi
80101c7d:	5f                   	pop    %edi
80101c7e:	5d                   	pop    %ebp
80101c7f:	c3                   	ret    
    panic("dirlink");
80101c80:	83 ec 0c             	sub    $0xc,%esp
80101c83:	68 38 6e 10 80       	push   $0x80106e38
80101c88:	e8 cf e6 ff ff       	call   8010035c <panic>

80101c8d <namei>:

struct inode*
namei(char *path)
{
80101c8d:	f3 0f 1e fb          	endbr32 
80101c91:	55                   	push   %ebp
80101c92:	89 e5                	mov    %esp,%ebp
80101c94:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101c97:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101c9a:	ba 00 00 00 00       	mov    $0x0,%edx
80101c9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca2:	e8 48 fe ff ff       	call   80101aef <namex>
}
80101ca7:	c9                   	leave  
80101ca8:	c3                   	ret    

80101ca9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101ca9:	f3 0f 1e fb          	endbr32 
80101cad:	55                   	push   %ebp
80101cae:	89 e5                	mov    %esp,%ebp
80101cb0:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101cb3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101cb6:	ba 01 00 00 00       	mov    $0x1,%edx
80101cbb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbe:	e8 2c fe ff ff       	call   80101aef <namex>
}
80101cc3:	c9                   	leave  
80101cc4:	c3                   	ret    

80101cc5 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101cc5:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101cc7:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ccc:	ec                   	in     (%dx),%al
80101ccd:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101ccf:	83 e0 c0             	and    $0xffffffc0,%eax
80101cd2:	3c 40                	cmp    $0x40,%al
80101cd4:	75 f1                	jne    80101cc7 <idewait+0x2>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101cd6:	85 c9                	test   %ecx,%ecx
80101cd8:	74 0a                	je     80101ce4 <idewait+0x1f>
80101cda:	f6 c2 21             	test   $0x21,%dl
80101cdd:	75 08                	jne    80101ce7 <idewait+0x22>
    return -1;
  return 0;
80101cdf:	b9 00 00 00 00       	mov    $0x0,%ecx
}
80101ce4:	89 c8                	mov    %ecx,%eax
80101ce6:	c3                   	ret    
    return -1;
80101ce7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
80101cec:	eb f6                	jmp    80101ce4 <idewait+0x1f>

80101cee <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101cee:	55                   	push   %ebp
80101cef:	89 e5                	mov    %esp,%ebp
80101cf1:	56                   	push   %esi
80101cf2:	53                   	push   %ebx
  if(b == 0)
80101cf3:	85 c0                	test   %eax,%eax
80101cf5:	0f 84 91 00 00 00    	je     80101d8c <idestart+0x9e>
80101cfb:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101cfd:	8b 58 08             	mov    0x8(%eax),%ebx
80101d00:	81 fb cf 07 00 00    	cmp    $0x7cf,%ebx
80101d06:	0f 87 8d 00 00 00    	ja     80101d99 <idestart+0xab>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101d0c:	b8 00 00 00 00       	mov    $0x0,%eax
80101d11:	e8 af ff ff ff       	call   80101cc5 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d16:	b8 00 00 00 00       	mov    $0x0,%eax
80101d1b:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101d20:	ee                   	out    %al,(%dx)
80101d21:	b8 01 00 00 00       	mov    $0x1,%eax
80101d26:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101d2b:	ee                   	out    %al,(%dx)
80101d2c:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101d31:	89 d8                	mov    %ebx,%eax
80101d33:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101d34:	89 d8                	mov    %ebx,%eax
80101d36:	c1 f8 08             	sar    $0x8,%eax
80101d39:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101d3e:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101d3f:	89 d8                	mov    %ebx,%eax
80101d41:	c1 f8 10             	sar    $0x10,%eax
80101d44:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101d49:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101d4a:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101d4e:	c1 e0 04             	shl    $0x4,%eax
80101d51:	83 e0 10             	and    $0x10,%eax
80101d54:	c1 fb 18             	sar    $0x18,%ebx
80101d57:	83 e3 0f             	and    $0xf,%ebx
80101d5a:	09 d8                	or     %ebx,%eax
80101d5c:	83 c8 e0             	or     $0xffffffe0,%eax
80101d5f:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d64:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101d65:	f6 06 04             	testb  $0x4,(%esi)
80101d68:	74 3c                	je     80101da6 <idestart+0xb8>
80101d6a:	b8 30 00 00 00       	mov    $0x30,%eax
80101d6f:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d74:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
80101d75:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101d78:	b9 80 00 00 00       	mov    $0x80,%ecx
80101d7d:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101d82:	fc                   	cld    
80101d83:	f3 6f                	rep outsl %ds:(%esi),(%dx)
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101d85:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101d88:	5b                   	pop    %ebx
80101d89:	5e                   	pop    %esi
80101d8a:	5d                   	pop    %ebp
80101d8b:	c3                   	ret    
    panic("idestart");
80101d8c:	83 ec 0c             	sub    $0xc,%esp
80101d8f:	68 73 68 10 80       	push   $0x80106873
80101d94:	e8 c3 e5 ff ff       	call   8010035c <panic>
    panic("incorrect blockno");
80101d99:	83 ec 0c             	sub    $0xc,%esp
80101d9c:	68 7c 68 10 80       	push   $0x8010687c
80101da1:	e8 b6 e5 ff ff       	call   8010035c <panic>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101da6:	b8 20 00 00 00       	mov    $0x20,%eax
80101dab:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101db0:	ee                   	out    %al,(%dx)
}
80101db1:	eb d2                	jmp    80101d85 <idestart+0x97>

80101db3 <ideinit>:
{
80101db3:	f3 0f 1e fb          	endbr32 
80101db7:	55                   	push   %ebp
80101db8:	89 e5                	mov    %esp,%ebp
80101dba:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101dbd:	68 8e 68 10 80       	push   $0x8010688e
80101dc2:	68 80 a5 10 80       	push   $0x8010a580
80101dc7:	e8 92 1e 00 00       	call   80103c5e <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101dcc:	83 c4 08             	add    $0x8,%esp
80101dcf:	a1 60 4d 11 80       	mov    0x80114d60,%eax
80101dd4:	83 e8 01             	sub    $0x1,%eax
80101dd7:	50                   	push   %eax
80101dd8:	6a 0e                	push   $0xe
80101dda:	e8 5a 02 00 00       	call   80102039 <ioapicenable>
  idewait(0);
80101ddf:	b8 00 00 00 00       	mov    $0x0,%eax
80101de4:	e8 dc fe ff ff       	call   80101cc5 <idewait>
80101de9:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101dee:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101df3:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101df4:	83 c4 10             	add    $0x10,%esp
80101df7:	b9 00 00 00 00       	mov    $0x0,%ecx
80101dfc:	eb 03                	jmp    80101e01 <ideinit+0x4e>
80101dfe:	83 c1 01             	add    $0x1,%ecx
80101e01:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101e07:	7f 14                	jg     80101e1d <ideinit+0x6a>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101e09:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101e0e:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101e0f:	84 c0                	test   %al,%al
80101e11:	74 eb                	je     80101dfe <ideinit+0x4b>
      havedisk1 = 1;
80101e13:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
80101e1a:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101e1d:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101e22:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101e27:	ee                   	out    %al,(%dx)
}
80101e28:	c9                   	leave  
80101e29:	c3                   	ret    

80101e2a <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101e2a:	f3 0f 1e fb          	endbr32 
80101e2e:	55                   	push   %ebp
80101e2f:	89 e5                	mov    %esp,%ebp
80101e31:	57                   	push   %edi
80101e32:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101e33:	83 ec 0c             	sub    $0xc,%esp
80101e36:	68 80 a5 10 80       	push   $0x8010a580
80101e3b:	e8 6e 1f 00 00       	call   80103dae <acquire>

  if((b = idequeue) == 0){
80101e40:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101e46:	83 c4 10             	add    $0x10,%esp
80101e49:	85 db                	test   %ebx,%ebx
80101e4b:	74 48                	je     80101e95 <ideintr+0x6b>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101e4d:	8b 43 58             	mov    0x58(%ebx),%eax
80101e50:	a3 64 a5 10 80       	mov    %eax,0x8010a564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101e55:	f6 03 04             	testb  $0x4,(%ebx)
80101e58:	74 4d                	je     80101ea7 <ideintr+0x7d>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101e5a:	8b 03                	mov    (%ebx),%eax
80101e5c:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101e5f:	83 e0 fb             	and    $0xfffffffb,%eax
80101e62:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101e64:	83 ec 0c             	sub    $0xc,%esp
80101e67:	53                   	push   %ebx
80101e68:	e8 06 1b 00 00       	call   80103973 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101e6d:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101e72:	83 c4 10             	add    $0x10,%esp
80101e75:	85 c0                	test   %eax,%eax
80101e77:	74 05                	je     80101e7e <ideintr+0x54>
    idestart(idequeue);
80101e79:	e8 70 fe ff ff       	call   80101cee <idestart>

  release(&idelock);
80101e7e:	83 ec 0c             	sub    $0xc,%esp
80101e81:	68 80 a5 10 80       	push   $0x8010a580
80101e86:	e8 8c 1f 00 00       	call   80103e17 <release>
80101e8b:	83 c4 10             	add    $0x10,%esp
}
80101e8e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101e91:	5b                   	pop    %ebx
80101e92:	5f                   	pop    %edi
80101e93:	5d                   	pop    %ebp
80101e94:	c3                   	ret    
    release(&idelock);
80101e95:	83 ec 0c             	sub    $0xc,%esp
80101e98:	68 80 a5 10 80       	push   $0x8010a580
80101e9d:	e8 75 1f 00 00       	call   80103e17 <release>
    return;
80101ea2:	83 c4 10             	add    $0x10,%esp
80101ea5:	eb e7                	jmp    80101e8e <ideintr+0x64>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101ea7:	b8 01 00 00 00       	mov    $0x1,%eax
80101eac:	e8 14 fe ff ff       	call   80101cc5 <idewait>
80101eb1:	85 c0                	test   %eax,%eax
80101eb3:	78 a5                	js     80101e5a <ideintr+0x30>
    insl(0x1f0, b->data, BSIZE/4);
80101eb5:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101eb8:	b9 80 00 00 00       	mov    $0x80,%ecx
80101ebd:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101ec2:	fc                   	cld    
80101ec3:	f3 6d                	rep insl (%dx),%es:(%edi)
}
80101ec5:	eb 93                	jmp    80101e5a <ideintr+0x30>

80101ec7 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101ec7:	f3 0f 1e fb          	endbr32 
80101ecb:	55                   	push   %ebp
80101ecc:	89 e5                	mov    %esp,%ebp
80101ece:	53                   	push   %ebx
80101ecf:	83 ec 10             	sub    $0x10,%esp
80101ed2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101ed5:	8d 43 0c             	lea    0xc(%ebx),%eax
80101ed8:	50                   	push   %eax
80101ed9:	e8 55 1d 00 00       	call   80103c33 <holdingsleep>
80101ede:	83 c4 10             	add    $0x10,%esp
80101ee1:	85 c0                	test   %eax,%eax
80101ee3:	74 37                	je     80101f1c <iderw+0x55>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101ee5:	8b 03                	mov    (%ebx),%eax
80101ee7:	83 e0 06             	and    $0x6,%eax
80101eea:	83 f8 02             	cmp    $0x2,%eax
80101eed:	74 3a                	je     80101f29 <iderw+0x62>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101eef:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101ef3:	74 09                	je     80101efe <iderw+0x37>
80101ef5:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101efc:	74 38                	je     80101f36 <iderw+0x6f>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101efe:	83 ec 0c             	sub    $0xc,%esp
80101f01:	68 80 a5 10 80       	push   $0x8010a580
80101f06:	e8 a3 1e 00 00       	call   80103dae <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101f0b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101f12:	83 c4 10             	add    $0x10,%esp
80101f15:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101f1a:	eb 2a                	jmp    80101f46 <iderw+0x7f>
    panic("iderw: buf not locked");
80101f1c:	83 ec 0c             	sub    $0xc,%esp
80101f1f:	68 92 68 10 80       	push   $0x80106892
80101f24:	e8 33 e4 ff ff       	call   8010035c <panic>
    panic("iderw: nothing to do");
80101f29:	83 ec 0c             	sub    $0xc,%esp
80101f2c:	68 a8 68 10 80       	push   $0x801068a8
80101f31:	e8 26 e4 ff ff       	call   8010035c <panic>
    panic("iderw: ide disk 1 not present");
80101f36:	83 ec 0c             	sub    $0xc,%esp
80101f39:	68 bd 68 10 80       	push   $0x801068bd
80101f3e:	e8 19 e4 ff ff       	call   8010035c <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101f43:	8d 50 58             	lea    0x58(%eax),%edx
80101f46:	8b 02                	mov    (%edx),%eax
80101f48:	85 c0                	test   %eax,%eax
80101f4a:	75 f7                	jne    80101f43 <iderw+0x7c>
    ;
  *pp = b;
80101f4c:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101f4e:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101f54:	75 1a                	jne    80101f70 <iderw+0xa9>
    idestart(b);
80101f56:	89 d8                	mov    %ebx,%eax
80101f58:	e8 91 fd ff ff       	call   80101cee <idestart>
80101f5d:	eb 11                	jmp    80101f70 <iderw+0xa9>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101f5f:	83 ec 08             	sub    $0x8,%esp
80101f62:	68 80 a5 10 80       	push   $0x8010a580
80101f67:	53                   	push   %ebx
80101f68:	e8 9a 18 00 00       	call   80103807 <sleep>
80101f6d:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101f70:	8b 03                	mov    (%ebx),%eax
80101f72:	83 e0 06             	and    $0x6,%eax
80101f75:	83 f8 02             	cmp    $0x2,%eax
80101f78:	75 e5                	jne    80101f5f <iderw+0x98>
  }


  release(&idelock);
80101f7a:	83 ec 0c             	sub    $0xc,%esp
80101f7d:	68 80 a5 10 80       	push   $0x8010a580
80101f82:	e8 90 1e 00 00       	call   80103e17 <release>
}
80101f87:	83 c4 10             	add    $0x10,%esp
80101f8a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101f8d:	c9                   	leave  
80101f8e:	c3                   	ret    

80101f8f <ioapicread>:
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
80101f8f:	8b 15 94 46 11 80    	mov    0x80114694,%edx
80101f95:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101f97:	a1 94 46 11 80       	mov    0x80114694,%eax
80101f9c:	8b 40 10             	mov    0x10(%eax),%eax
}
80101f9f:	c3                   	ret    

80101fa0 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
80101fa0:	8b 0d 94 46 11 80    	mov    0x80114694,%ecx
80101fa6:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101fa8:	a1 94 46 11 80       	mov    0x80114694,%eax
80101fad:	89 50 10             	mov    %edx,0x10(%eax)
}
80101fb0:	c3                   	ret    

80101fb1 <ioapicinit>:

void
ioapicinit(void)
{
80101fb1:	f3 0f 1e fb          	endbr32 
80101fb5:	55                   	push   %ebp
80101fb6:	89 e5                	mov    %esp,%ebp
80101fb8:	57                   	push   %edi
80101fb9:	56                   	push   %esi
80101fba:	53                   	push   %ebx
80101fbb:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101fbe:	c7 05 94 46 11 80 00 	movl   $0xfec00000,0x80114694
80101fc5:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101fc8:	b8 01 00 00 00       	mov    $0x1,%eax
80101fcd:	e8 bd ff ff ff       	call   80101f8f <ioapicread>
80101fd2:	c1 e8 10             	shr    $0x10,%eax
80101fd5:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101fd8:	b8 00 00 00 00       	mov    $0x0,%eax
80101fdd:	e8 ad ff ff ff       	call   80101f8f <ioapicread>
80101fe2:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101fe5:	0f b6 15 c0 47 11 80 	movzbl 0x801147c0,%edx
80101fec:	39 c2                	cmp    %eax,%edx
80101fee:	75 2f                	jne    8010201f <ioapicinit+0x6e>
{
80101ff0:	bb 00 00 00 00       	mov    $0x0,%ebx
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80101ff5:	39 fb                	cmp    %edi,%ebx
80101ff7:	7f 38                	jg     80102031 <ioapicinit+0x80>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101ff9:	8d 53 20             	lea    0x20(%ebx),%edx
80101ffc:	81 ca 00 00 01 00    	or     $0x10000,%edx
80102002:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80102006:	89 f0                	mov    %esi,%eax
80102008:	e8 93 ff ff ff       	call   80101fa0 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010200d:	8d 46 01             	lea    0x1(%esi),%eax
80102010:	ba 00 00 00 00       	mov    $0x0,%edx
80102015:	e8 86 ff ff ff       	call   80101fa0 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
8010201a:	83 c3 01             	add    $0x1,%ebx
8010201d:	eb d6                	jmp    80101ff5 <ioapicinit+0x44>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010201f:	83 ec 0c             	sub    $0xc,%esp
80102022:	68 dc 68 10 80       	push   $0x801068dc
80102027:	e8 fd e5 ff ff       	call   80100629 <cprintf>
8010202c:	83 c4 10             	add    $0x10,%esp
8010202f:	eb bf                	jmp    80101ff0 <ioapicinit+0x3f>
  }
}
80102031:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102034:	5b                   	pop    %ebx
80102035:	5e                   	pop    %esi
80102036:	5f                   	pop    %edi
80102037:	5d                   	pop    %ebp
80102038:	c3                   	ret    

80102039 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102039:	f3 0f 1e fb          	endbr32 
8010203d:	55                   	push   %ebp
8010203e:	89 e5                	mov    %esp,%ebp
80102040:	53                   	push   %ebx
80102041:	83 ec 04             	sub    $0x4,%esp
80102044:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102047:	8d 50 20             	lea    0x20(%eax),%edx
8010204a:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
8010204e:	89 d8                	mov    %ebx,%eax
80102050:	e8 4b ff ff ff       	call   80101fa0 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102055:	8b 55 0c             	mov    0xc(%ebp),%edx
80102058:	c1 e2 18             	shl    $0x18,%edx
8010205b:	8d 43 01             	lea    0x1(%ebx),%eax
8010205e:	e8 3d ff ff ff       	call   80101fa0 <ioapicwrite>
}
80102063:	83 c4 04             	add    $0x4,%esp
80102066:	5b                   	pop    %ebx
80102067:	5d                   	pop    %ebp
80102068:	c3                   	ret    

80102069 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102069:	f3 0f 1e fb          	endbr32 
8010206d:	55                   	push   %ebp
8010206e:	89 e5                	mov    %esp,%ebp
80102070:	53                   	push   %ebx
80102071:	83 ec 04             	sub    $0x4,%esp
80102074:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102077:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
8010207d:	75 4c                	jne    801020cb <kfree+0x62>
8010207f:	81 fb 88 55 11 80    	cmp    $0x80115588,%ebx
80102085:	72 44                	jb     801020cb <kfree+0x62>
80102087:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010208d:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102092:	77 37                	ja     801020cb <kfree+0x62>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102094:	83 ec 04             	sub    $0x4,%esp
80102097:	68 00 10 00 00       	push   $0x1000
8010209c:	6a 01                	push   $0x1
8010209e:	53                   	push   %ebx
8010209f:	e8 be 1d 00 00       	call   80103e62 <memset>

  if(kmem.use_lock)
801020a4:	83 c4 10             	add    $0x10,%esp
801020a7:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801020ae:	75 28                	jne    801020d8 <kfree+0x6f>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
801020b0:	a1 d8 46 11 80       	mov    0x801146d8,%eax
801020b5:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
801020b7:	89 1d d8 46 11 80    	mov    %ebx,0x801146d8
  if(kmem.use_lock)
801020bd:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801020c4:	75 24                	jne    801020ea <kfree+0x81>
    release(&kmem.lock);
}
801020c6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020c9:	c9                   	leave  
801020ca:	c3                   	ret    
    panic("kfree");
801020cb:	83 ec 0c             	sub    $0xc,%esp
801020ce:	68 0e 69 10 80       	push   $0x8010690e
801020d3:	e8 84 e2 ff ff       	call   8010035c <panic>
    acquire(&kmem.lock);
801020d8:	83 ec 0c             	sub    $0xc,%esp
801020db:	68 a0 46 11 80       	push   $0x801146a0
801020e0:	e8 c9 1c 00 00       	call   80103dae <acquire>
801020e5:	83 c4 10             	add    $0x10,%esp
801020e8:	eb c6                	jmp    801020b0 <kfree+0x47>
    release(&kmem.lock);
801020ea:	83 ec 0c             	sub    $0xc,%esp
801020ed:	68 a0 46 11 80       	push   $0x801146a0
801020f2:	e8 20 1d 00 00       	call   80103e17 <release>
801020f7:	83 c4 10             	add    $0x10,%esp
}
801020fa:	eb ca                	jmp    801020c6 <kfree+0x5d>

801020fc <freerange>:
{
801020fc:	f3 0f 1e fb          	endbr32 
80102100:	55                   	push   %ebp
80102101:	89 e5                	mov    %esp,%ebp
80102103:	56                   	push   %esi
80102104:	53                   	push   %ebx
80102105:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
80102108:	8b 45 08             	mov    0x8(%ebp),%eax
8010210b:	05 ff 0f 00 00       	add    $0xfff,%eax
80102110:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102115:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010211b:	39 de                	cmp    %ebx,%esi
8010211d:	77 10                	ja     8010212f <freerange+0x33>
    kfree(p);
8010211f:	83 ec 0c             	sub    $0xc,%esp
80102122:	50                   	push   %eax
80102123:	e8 41 ff ff ff       	call   80102069 <kfree>
80102128:	83 c4 10             	add    $0x10,%esp
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010212b:	89 f0                	mov    %esi,%eax
8010212d:	eb e6                	jmp    80102115 <freerange+0x19>
}
8010212f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102132:	5b                   	pop    %ebx
80102133:	5e                   	pop    %esi
80102134:	5d                   	pop    %ebp
80102135:	c3                   	ret    

80102136 <kinit1>:
{
80102136:	f3 0f 1e fb          	endbr32 
8010213a:	55                   	push   %ebp
8010213b:	89 e5                	mov    %esp,%ebp
8010213d:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102140:	68 14 69 10 80       	push   $0x80106914
80102145:	68 a0 46 11 80       	push   $0x801146a0
8010214a:	e8 0f 1b 00 00       	call   80103c5e <initlock>
  kmem.use_lock = 0;
8010214f:	c7 05 d4 46 11 80 00 	movl   $0x0,0x801146d4
80102156:	00 00 00 
  freerange(vstart, vend);
80102159:	83 c4 08             	add    $0x8,%esp
8010215c:	ff 75 0c             	pushl  0xc(%ebp)
8010215f:	ff 75 08             	pushl  0x8(%ebp)
80102162:	e8 95 ff ff ff       	call   801020fc <freerange>
}
80102167:	83 c4 10             	add    $0x10,%esp
8010216a:	c9                   	leave  
8010216b:	c3                   	ret    

8010216c <kinit2>:
{
8010216c:	f3 0f 1e fb          	endbr32 
80102170:	55                   	push   %ebp
80102171:	89 e5                	mov    %esp,%ebp
80102173:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
80102176:	ff 75 0c             	pushl  0xc(%ebp)
80102179:	ff 75 08             	pushl  0x8(%ebp)
8010217c:	e8 7b ff ff ff       	call   801020fc <freerange>
  kmem.use_lock = 1;
80102181:	c7 05 d4 46 11 80 01 	movl   $0x1,0x801146d4
80102188:	00 00 00 
}
8010218b:	83 c4 10             	add    $0x10,%esp
8010218e:	c9                   	leave  
8010218f:	c3                   	ret    

80102190 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102190:	f3 0f 1e fb          	endbr32 
80102194:	55                   	push   %ebp
80102195:	89 e5                	mov    %esp,%ebp
80102197:	53                   	push   %ebx
80102198:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
8010219b:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801021a2:	75 21                	jne    801021c5 <kalloc+0x35>
    acquire(&kmem.lock);
  r = kmem.freelist;
801021a4:	8b 1d d8 46 11 80    	mov    0x801146d8,%ebx
  if(r)
801021aa:	85 db                	test   %ebx,%ebx
801021ac:	74 07                	je     801021b5 <kalloc+0x25>
    kmem.freelist = r->next;
801021ae:	8b 03                	mov    (%ebx),%eax
801021b0:	a3 d8 46 11 80       	mov    %eax,0x801146d8
  if(kmem.use_lock)
801021b5:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801021bc:	75 19                	jne    801021d7 <kalloc+0x47>
    release(&kmem.lock);
  return (char*)r;
}
801021be:	89 d8                	mov    %ebx,%eax
801021c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801021c3:	c9                   	leave  
801021c4:	c3                   	ret    
    acquire(&kmem.lock);
801021c5:	83 ec 0c             	sub    $0xc,%esp
801021c8:	68 a0 46 11 80       	push   $0x801146a0
801021cd:	e8 dc 1b 00 00       	call   80103dae <acquire>
801021d2:	83 c4 10             	add    $0x10,%esp
801021d5:	eb cd                	jmp    801021a4 <kalloc+0x14>
    release(&kmem.lock);
801021d7:	83 ec 0c             	sub    $0xc,%esp
801021da:	68 a0 46 11 80       	push   $0x801146a0
801021df:	e8 33 1c 00 00       	call   80103e17 <release>
801021e4:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801021e7:	eb d5                	jmp    801021be <kalloc+0x2e>

801021e9 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021e9:	f3 0f 1e fb          	endbr32 
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021ed:	ba 64 00 00 00       	mov    $0x64,%edx
801021f2:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021f3:	a8 01                	test   $0x1,%al
801021f5:	0f 84 ad 00 00 00    	je     801022a8 <kbdgetc+0xbf>
801021fb:	ba 60 00 00 00       	mov    $0x60,%edx
80102200:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102201:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102204:	3c e0                	cmp    $0xe0,%al
80102206:	74 5b                	je     80102263 <kbdgetc+0x7a>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102208:	84 c0                	test   %al,%al
8010220a:	78 64                	js     80102270 <kbdgetc+0x87>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010220c:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102212:	f6 c1 40             	test   $0x40,%cl
80102215:	74 0f                	je     80102226 <kbdgetc+0x3d>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102217:	83 c8 80             	or     $0xffffff80,%eax
8010221a:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010221d:	83 e1 bf             	and    $0xffffffbf,%ecx
80102220:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
80102226:	0f b6 8a 40 6a 10 80 	movzbl -0x7fef95c0(%edx),%ecx
8010222d:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
80102233:	0f b6 82 40 69 10 80 	movzbl -0x7fef96c0(%edx),%eax
8010223a:	31 c1                	xor    %eax,%ecx
8010223c:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102242:	89 c8                	mov    %ecx,%eax
80102244:	83 e0 03             	and    $0x3,%eax
80102247:	8b 04 85 20 69 10 80 	mov    -0x7fef96e0(,%eax,4),%eax
8010224e:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102252:	f6 c1 08             	test   $0x8,%cl
80102255:	74 56                	je     801022ad <kbdgetc+0xc4>
    if('a' <= c && c <= 'z')
80102257:	8d 50 9f             	lea    -0x61(%eax),%edx
8010225a:	83 fa 19             	cmp    $0x19,%edx
8010225d:	77 3d                	ja     8010229c <kbdgetc+0xb3>
      c += 'A' - 'a';
8010225f:	83 e8 20             	sub    $0x20,%eax
80102262:	c3                   	ret    
    shift |= E0ESC;
80102263:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
8010226a:	b8 00 00 00 00       	mov    $0x0,%eax
8010226f:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102270:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102276:	f6 c1 40             	test   $0x40,%cl
80102279:	75 05                	jne    80102280 <kbdgetc+0x97>
8010227b:	89 c2                	mov    %eax,%edx
8010227d:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102280:	0f b6 82 40 6a 10 80 	movzbl -0x7fef95c0(%edx),%eax
80102287:	83 c8 40             	or     $0x40,%eax
8010228a:	0f b6 c0             	movzbl %al,%eax
8010228d:	f7 d0                	not    %eax
8010228f:	21 c8                	and    %ecx,%eax
80102291:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
80102296:	b8 00 00 00 00       	mov    $0x0,%eax
8010229b:	c3                   	ret    
    else if('A' <= c && c <= 'Z')
8010229c:	8d 50 bf             	lea    -0x41(%eax),%edx
8010229f:	83 fa 19             	cmp    $0x19,%edx
801022a2:	77 09                	ja     801022ad <kbdgetc+0xc4>
      c += 'a' - 'A';
801022a4:	83 c0 20             	add    $0x20,%eax
  }
  return c;
801022a7:	c3                   	ret    
    return -1;
801022a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801022ad:	c3                   	ret    

801022ae <kbdintr>:

void
kbdintr(void)
{
801022ae:	f3 0f 1e fb          	endbr32 
801022b2:	55                   	push   %ebp
801022b3:	89 e5                	mov    %esp,%ebp
801022b5:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801022b8:	68 e9 21 10 80       	push   $0x801021e9
801022bd:	e8 bc e4 ff ff       	call   8010077e <consoleintr>
}
801022c2:	83 c4 10             	add    $0x10,%esp
801022c5:	c9                   	leave  
801022c6:	c3                   	ret    

801022c7 <lapicw>:

//PAGEBREAK!
static void
lapicw(int index, int value)
{
  lapic[index] = value;
801022c7:	8b 0d dc 46 11 80    	mov    0x801146dc,%ecx
801022cd:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801022d0:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801022d2:	a1 dc 46 11 80       	mov    0x801146dc,%eax
801022d7:	8b 40 20             	mov    0x20(%eax),%eax
}
801022da:	c3                   	ret    

801022db <cmos_read>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022db:	ba 70 00 00 00       	mov    $0x70,%edx
801022e0:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022e1:	ba 71 00 00 00       	mov    $0x71,%edx
801022e6:	ec                   	in     (%dx),%al
static uint cmos_read(uint reg)
{
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022e7:	0f b6 c0             	movzbl %al,%eax
}
801022ea:	c3                   	ret    

801022eb <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801022eb:	55                   	push   %ebp
801022ec:	89 e5                	mov    %esp,%ebp
801022ee:	53                   	push   %ebx
801022ef:	83 ec 04             	sub    $0x4,%esp
801022f2:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022f4:	b8 00 00 00 00       	mov    $0x0,%eax
801022f9:	e8 dd ff ff ff       	call   801022db <cmos_read>
801022fe:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102300:	b8 02 00 00 00       	mov    $0x2,%eax
80102305:	e8 d1 ff ff ff       	call   801022db <cmos_read>
8010230a:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010230d:	b8 04 00 00 00       	mov    $0x4,%eax
80102312:	e8 c4 ff ff ff       	call   801022db <cmos_read>
80102317:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010231a:	b8 07 00 00 00       	mov    $0x7,%eax
8010231f:	e8 b7 ff ff ff       	call   801022db <cmos_read>
80102324:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102327:	b8 08 00 00 00       	mov    $0x8,%eax
8010232c:	e8 aa ff ff ff       	call   801022db <cmos_read>
80102331:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102334:	b8 09 00 00 00       	mov    $0x9,%eax
80102339:	e8 9d ff ff ff       	call   801022db <cmos_read>
8010233e:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102341:	83 c4 04             	add    $0x4,%esp
80102344:	5b                   	pop    %ebx
80102345:	5d                   	pop    %ebp
80102346:	c3                   	ret    

80102347 <lapicinit>:
{
80102347:	f3 0f 1e fb          	endbr32 
  if(!lapic)
8010234b:	83 3d dc 46 11 80 00 	cmpl   $0x0,0x801146dc
80102352:	0f 84 fe 00 00 00    	je     80102456 <lapicinit+0x10f>
{
80102358:	55                   	push   %ebp
80102359:	89 e5                	mov    %esp,%ebp
8010235b:	83 ec 08             	sub    $0x8,%esp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010235e:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102363:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102368:	e8 5a ff ff ff       	call   801022c7 <lapicw>
  lapicw(TDCR, X1);
8010236d:	ba 0b 00 00 00       	mov    $0xb,%edx
80102372:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102377:	e8 4b ff ff ff       	call   801022c7 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010237c:	ba 20 00 02 00       	mov    $0x20020,%edx
80102381:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102386:	e8 3c ff ff ff       	call   801022c7 <lapicw>
  lapicw(TICR, 1000000);
8010238b:	ba 40 42 0f 00       	mov    $0xf4240,%edx
80102390:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102395:	e8 2d ff ff ff       	call   801022c7 <lapicw>
  lapicw(LINT0, MASKED);
8010239a:	ba 00 00 01 00       	mov    $0x10000,%edx
8010239f:	b8 d4 00 00 00       	mov    $0xd4,%eax
801023a4:	e8 1e ff ff ff       	call   801022c7 <lapicw>
  lapicw(LINT1, MASKED);
801023a9:	ba 00 00 01 00       	mov    $0x10000,%edx
801023ae:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023b3:	e8 0f ff ff ff       	call   801022c7 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801023b8:	a1 dc 46 11 80       	mov    0x801146dc,%eax
801023bd:	8b 40 30             	mov    0x30(%eax),%eax
801023c0:	c1 e8 10             	shr    $0x10,%eax
801023c3:	a8 fc                	test   $0xfc,%al
801023c5:	75 7b                	jne    80102442 <lapicinit+0xfb>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801023c7:	ba 33 00 00 00       	mov    $0x33,%edx
801023cc:	b8 dc 00 00 00       	mov    $0xdc,%eax
801023d1:	e8 f1 fe ff ff       	call   801022c7 <lapicw>
  lapicw(ESR, 0);
801023d6:	ba 00 00 00 00       	mov    $0x0,%edx
801023db:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023e0:	e8 e2 fe ff ff       	call   801022c7 <lapicw>
  lapicw(ESR, 0);
801023e5:	ba 00 00 00 00       	mov    $0x0,%edx
801023ea:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023ef:	e8 d3 fe ff ff       	call   801022c7 <lapicw>
  lapicw(EOI, 0);
801023f4:	ba 00 00 00 00       	mov    $0x0,%edx
801023f9:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023fe:	e8 c4 fe ff ff       	call   801022c7 <lapicw>
  lapicw(ICRHI, 0);
80102403:	ba 00 00 00 00       	mov    $0x0,%edx
80102408:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010240d:	e8 b5 fe ff ff       	call   801022c7 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102412:	ba 00 85 08 00       	mov    $0x88500,%edx
80102417:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010241c:	e8 a6 fe ff ff       	call   801022c7 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102421:	a1 dc 46 11 80       	mov    0x801146dc,%eax
80102426:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010242c:	f6 c4 10             	test   $0x10,%ah
8010242f:	75 f0                	jne    80102421 <lapicinit+0xda>
  lapicw(TPR, 0);
80102431:	ba 00 00 00 00       	mov    $0x0,%edx
80102436:	b8 20 00 00 00       	mov    $0x20,%eax
8010243b:	e8 87 fe ff ff       	call   801022c7 <lapicw>
}
80102440:	c9                   	leave  
80102441:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102442:	ba 00 00 01 00       	mov    $0x10000,%edx
80102447:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010244c:	e8 76 fe ff ff       	call   801022c7 <lapicw>
80102451:	e9 71 ff ff ff       	jmp    801023c7 <lapicinit+0x80>
80102456:	c3                   	ret    

80102457 <lapicid>:
{
80102457:	f3 0f 1e fb          	endbr32 
  if (!lapic)
8010245b:	a1 dc 46 11 80       	mov    0x801146dc,%eax
80102460:	85 c0                	test   %eax,%eax
80102462:	74 07                	je     8010246b <lapicid+0x14>
  return lapic[ID] >> 24;
80102464:	8b 40 20             	mov    0x20(%eax),%eax
80102467:	c1 e8 18             	shr    $0x18,%eax
8010246a:	c3                   	ret    
    return 0;
8010246b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102470:	c3                   	ret    

80102471 <lapiceoi>:
{
80102471:	f3 0f 1e fb          	endbr32 
  if(lapic)
80102475:	83 3d dc 46 11 80 00 	cmpl   $0x0,0x801146dc
8010247c:	74 17                	je     80102495 <lapiceoi+0x24>
{
8010247e:	55                   	push   %ebp
8010247f:	89 e5                	mov    %esp,%ebp
80102481:	83 ec 08             	sub    $0x8,%esp
    lapicw(EOI, 0);
80102484:	ba 00 00 00 00       	mov    $0x0,%edx
80102489:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010248e:	e8 34 fe ff ff       	call   801022c7 <lapicw>
}
80102493:	c9                   	leave  
80102494:	c3                   	ret    
80102495:	c3                   	ret    

80102496 <microdelay>:
{
80102496:	f3 0f 1e fb          	endbr32 
}
8010249a:	c3                   	ret    

8010249b <lapicstartap>:
{
8010249b:	f3 0f 1e fb          	endbr32 
8010249f:	55                   	push   %ebp
801024a0:	89 e5                	mov    %esp,%ebp
801024a2:	57                   	push   %edi
801024a3:	56                   	push   %esi
801024a4:	53                   	push   %ebx
801024a5:	83 ec 0c             	sub    $0xc,%esp
801024a8:	8b 75 08             	mov    0x8(%ebp),%esi
801024ab:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024ae:	b8 0f 00 00 00       	mov    $0xf,%eax
801024b3:	ba 70 00 00 00       	mov    $0x70,%edx
801024b8:	ee                   	out    %al,(%dx)
801024b9:	b8 0a 00 00 00       	mov    $0xa,%eax
801024be:	ba 71 00 00 00       	mov    $0x71,%edx
801024c3:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801024c4:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801024cb:	00 00 
  wrv[1] = addr >> 4;
801024cd:	89 f8                	mov    %edi,%eax
801024cf:	c1 e8 04             	shr    $0x4,%eax
801024d2:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801024d8:	c1 e6 18             	shl    $0x18,%esi
801024db:	89 f2                	mov    %esi,%edx
801024dd:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024e2:	e8 e0 fd ff ff       	call   801022c7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801024e7:	ba 00 c5 00 00       	mov    $0xc500,%edx
801024ec:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024f1:	e8 d1 fd ff ff       	call   801022c7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024f6:	ba 00 85 00 00       	mov    $0x8500,%edx
801024fb:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102500:	e8 c2 fd ff ff       	call   801022c7 <lapicw>
  for(i = 0; i < 2; i++){
80102505:	bb 00 00 00 00       	mov    $0x0,%ebx
8010250a:	eb 21                	jmp    8010252d <lapicstartap+0x92>
    lapicw(ICRHI, apicid<<24);
8010250c:	89 f2                	mov    %esi,%edx
8010250e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102513:	e8 af fd ff ff       	call   801022c7 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102518:	89 fa                	mov    %edi,%edx
8010251a:	c1 ea 0c             	shr    $0xc,%edx
8010251d:	80 ce 06             	or     $0x6,%dh
80102520:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102525:	e8 9d fd ff ff       	call   801022c7 <lapicw>
  for(i = 0; i < 2; i++){
8010252a:	83 c3 01             	add    $0x1,%ebx
8010252d:	83 fb 01             	cmp    $0x1,%ebx
80102530:	7e da                	jle    8010250c <lapicstartap+0x71>
}
80102532:	83 c4 0c             	add    $0xc,%esp
80102535:	5b                   	pop    %ebx
80102536:	5e                   	pop    %esi
80102537:	5f                   	pop    %edi
80102538:	5d                   	pop    %ebp
80102539:	c3                   	ret    

8010253a <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
8010253a:	f3 0f 1e fb          	endbr32 
8010253e:	55                   	push   %ebp
8010253f:	89 e5                	mov    %esp,%ebp
80102541:	57                   	push   %edi
80102542:	56                   	push   %esi
80102543:	53                   	push   %ebx
80102544:	83 ec 3c             	sub    $0x3c,%esp
80102547:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010254a:	b8 0b 00 00 00       	mov    $0xb,%eax
8010254f:	e8 87 fd ff ff       	call   801022db <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102554:	83 e0 04             	and    $0x4,%eax
80102557:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102559:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010255c:	e8 8a fd ff ff       	call   801022eb <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102561:	b8 0a 00 00 00       	mov    $0xa,%eax
80102566:	e8 70 fd ff ff       	call   801022db <cmos_read>
8010256b:	a8 80                	test   $0x80,%al
8010256d:	75 ea                	jne    80102559 <cmostime+0x1f>
        continue;
    fill_rtcdate(&t2);
8010256f:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102572:	89 d8                	mov    %ebx,%eax
80102574:	e8 72 fd ff ff       	call   801022eb <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102579:	83 ec 04             	sub    $0x4,%esp
8010257c:	6a 18                	push   $0x18
8010257e:	53                   	push   %ebx
8010257f:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102582:	50                   	push   %eax
80102583:	e8 21 19 00 00       	call   80103ea9 <memcmp>
80102588:	83 c4 10             	add    $0x10,%esp
8010258b:	85 c0                	test   %eax,%eax
8010258d:	75 ca                	jne    80102559 <cmostime+0x1f>
      break;
  }

  // convert
  if(bcd) {
8010258f:	85 ff                	test   %edi,%edi
80102591:	75 78                	jne    8010260b <cmostime+0xd1>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102593:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102596:	89 c2                	mov    %eax,%edx
80102598:	c1 ea 04             	shr    $0x4,%edx
8010259b:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010259e:	83 e0 0f             	and    $0xf,%eax
801025a1:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801025a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025aa:	89 c2                	mov    %eax,%edx
801025ac:	c1 ea 04             	shr    $0x4,%edx
801025af:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025b2:	83 e0 0f             	and    $0xf,%eax
801025b5:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801025bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
801025be:	89 c2                	mov    %eax,%edx
801025c0:	c1 ea 04             	shr    $0x4,%edx
801025c3:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025c6:	83 e0 0f             	and    $0xf,%eax
801025c9:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025cc:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801025cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
801025d2:	89 c2                	mov    %eax,%edx
801025d4:	c1 ea 04             	shr    $0x4,%edx
801025d7:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025da:	83 e0 0f             	and    $0xf,%eax
801025dd:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025e0:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801025e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801025e6:	89 c2                	mov    %eax,%edx
801025e8:	c1 ea 04             	shr    $0x4,%edx
801025eb:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025ee:	83 e0 0f             	and    $0xf,%eax
801025f1:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801025fa:	89 c2                	mov    %eax,%edx
801025fc:	c1 ea 04             	shr    $0x4,%edx
801025ff:	8d 14 92             	lea    (%edx,%edx,4),%edx
80102602:	83 e0 0f             	and    $0xf,%eax
80102605:	8d 04 50             	lea    (%eax,%edx,2),%eax
80102608:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010260b:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010260e:	89 06                	mov    %eax,(%esi)
80102610:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102613:	89 46 04             	mov    %eax,0x4(%esi)
80102616:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102619:	89 46 08             	mov    %eax,0x8(%esi)
8010261c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010261f:	89 46 0c             	mov    %eax,0xc(%esi)
80102622:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102625:	89 46 10             	mov    %eax,0x10(%esi)
80102628:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010262b:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010262e:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102635:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102638:	5b                   	pop    %ebx
80102639:	5e                   	pop    %esi
8010263a:	5f                   	pop    %edi
8010263b:	5d                   	pop    %ebp
8010263c:	c3                   	ret    

8010263d <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010263d:	55                   	push   %ebp
8010263e:	89 e5                	mov    %esp,%ebp
80102640:	53                   	push   %ebx
80102641:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102644:	ff 35 14 47 11 80    	pushl  0x80114714
8010264a:	ff 35 24 47 11 80    	pushl  0x80114724
80102650:	e8 1b db ff ff       	call   80100170 <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102655:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102658:	89 1d 28 47 11 80    	mov    %ebx,0x80114728
  for (i = 0; i < log.lh.n; i++) {
8010265e:	83 c4 10             	add    $0x10,%esp
80102661:	ba 00 00 00 00       	mov    $0x0,%edx
80102666:	39 d3                	cmp    %edx,%ebx
80102668:	7e 10                	jle    8010267a <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
8010266a:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010266e:	89 0c 95 2c 47 11 80 	mov    %ecx,-0x7feeb8d4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102675:	83 c2 01             	add    $0x1,%edx
80102678:	eb ec                	jmp    80102666 <read_head+0x29>
  }
  brelse(buf);
8010267a:	83 ec 0c             	sub    $0xc,%esp
8010267d:	50                   	push   %eax
8010267e:	e8 5e db ff ff       	call   801001e1 <brelse>
}
80102683:	83 c4 10             	add    $0x10,%esp
80102686:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102689:	c9                   	leave  
8010268a:	c3                   	ret    

8010268b <install_trans>:
{
8010268b:	55                   	push   %ebp
8010268c:	89 e5                	mov    %esp,%ebp
8010268e:	57                   	push   %edi
8010268f:	56                   	push   %esi
80102690:	53                   	push   %ebx
80102691:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102694:	be 00 00 00 00       	mov    $0x0,%esi
80102699:	39 35 28 47 11 80    	cmp    %esi,0x80114728
8010269f:	7e 68                	jle    80102709 <install_trans+0x7e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801026a1:	89 f0                	mov    %esi,%eax
801026a3:	03 05 14 47 11 80    	add    0x80114714,%eax
801026a9:	83 c0 01             	add    $0x1,%eax
801026ac:	83 ec 08             	sub    $0x8,%esp
801026af:	50                   	push   %eax
801026b0:	ff 35 24 47 11 80    	pushl  0x80114724
801026b6:	e8 b5 da ff ff       	call   80100170 <bread>
801026bb:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026bd:	83 c4 08             	add    $0x8,%esp
801026c0:	ff 34 b5 2c 47 11 80 	pushl  -0x7feeb8d4(,%esi,4)
801026c7:	ff 35 24 47 11 80    	pushl  0x80114724
801026cd:	e8 9e da ff ff       	call   80100170 <bread>
801026d2:	89 c3                	mov    %eax,%ebx
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801026d4:	8d 57 5c             	lea    0x5c(%edi),%edx
801026d7:	8d 40 5c             	lea    0x5c(%eax),%eax
801026da:	83 c4 0c             	add    $0xc,%esp
801026dd:	68 00 02 00 00       	push   $0x200
801026e2:	52                   	push   %edx
801026e3:	50                   	push   %eax
801026e4:	e8 f9 17 00 00       	call   80103ee2 <memmove>
    bwrite(dbuf);  // write dst to disk
801026e9:	89 1c 24             	mov    %ebx,(%esp)
801026ec:	e8 b1 da ff ff       	call   801001a2 <bwrite>
    brelse(lbuf);
801026f1:	89 3c 24             	mov    %edi,(%esp)
801026f4:	e8 e8 da ff ff       	call   801001e1 <brelse>
    brelse(dbuf);
801026f9:	89 1c 24             	mov    %ebx,(%esp)
801026fc:	e8 e0 da ff ff       	call   801001e1 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102701:	83 c6 01             	add    $0x1,%esi
80102704:	83 c4 10             	add    $0x10,%esp
80102707:	eb 90                	jmp    80102699 <install_trans+0xe>
}
80102709:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010270c:	5b                   	pop    %ebx
8010270d:	5e                   	pop    %esi
8010270e:	5f                   	pop    %edi
8010270f:	5d                   	pop    %ebp
80102710:	c3                   	ret    

80102711 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102711:	55                   	push   %ebp
80102712:	89 e5                	mov    %esp,%ebp
80102714:	53                   	push   %ebx
80102715:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102718:	ff 35 14 47 11 80    	pushl  0x80114714
8010271e:	ff 35 24 47 11 80    	pushl  0x80114724
80102724:	e8 47 da ff ff       	call   80100170 <bread>
80102729:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010272b:	8b 0d 28 47 11 80    	mov    0x80114728,%ecx
80102731:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102734:	83 c4 10             	add    $0x10,%esp
80102737:	b8 00 00 00 00       	mov    $0x0,%eax
8010273c:	39 c1                	cmp    %eax,%ecx
8010273e:	7e 10                	jle    80102750 <write_head+0x3f>
    hb->block[i] = log.lh.block[i];
80102740:	8b 14 85 2c 47 11 80 	mov    -0x7feeb8d4(,%eax,4),%edx
80102747:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010274b:	83 c0 01             	add    $0x1,%eax
8010274e:	eb ec                	jmp    8010273c <write_head+0x2b>
  }
  bwrite(buf);
80102750:	83 ec 0c             	sub    $0xc,%esp
80102753:	53                   	push   %ebx
80102754:	e8 49 da ff ff       	call   801001a2 <bwrite>
  brelse(buf);
80102759:	89 1c 24             	mov    %ebx,(%esp)
8010275c:	e8 80 da ff ff       	call   801001e1 <brelse>
}
80102761:	83 c4 10             	add    $0x10,%esp
80102764:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102767:	c9                   	leave  
80102768:	c3                   	ret    

80102769 <recover_from_log>:

static void
recover_from_log(void)
{
80102769:	55                   	push   %ebp
8010276a:	89 e5                	mov    %esp,%ebp
8010276c:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010276f:	e8 c9 fe ff ff       	call   8010263d <read_head>
  install_trans(); // if committed, copy from log to disk
80102774:	e8 12 ff ff ff       	call   8010268b <install_trans>
  log.lh.n = 0;
80102779:	c7 05 28 47 11 80 00 	movl   $0x0,0x80114728
80102780:	00 00 00 
  write_head(); // clear the log
80102783:	e8 89 ff ff ff       	call   80102711 <write_head>
}
80102788:	c9                   	leave  
80102789:	c3                   	ret    

8010278a <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
8010278a:	55                   	push   %ebp
8010278b:	89 e5                	mov    %esp,%ebp
8010278d:	57                   	push   %edi
8010278e:	56                   	push   %esi
8010278f:	53                   	push   %ebx
80102790:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102793:	be 00 00 00 00       	mov    $0x0,%esi
80102798:	39 35 28 47 11 80    	cmp    %esi,0x80114728
8010279e:	7e 68                	jle    80102808 <write_log+0x7e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801027a0:	89 f0                	mov    %esi,%eax
801027a2:	03 05 14 47 11 80    	add    0x80114714,%eax
801027a8:	83 c0 01             	add    $0x1,%eax
801027ab:	83 ec 08             	sub    $0x8,%esp
801027ae:	50                   	push   %eax
801027af:	ff 35 24 47 11 80    	pushl  0x80114724
801027b5:	e8 b6 d9 ff ff       	call   80100170 <bread>
801027ba:	89 c3                	mov    %eax,%ebx
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027bc:	83 c4 08             	add    $0x8,%esp
801027bf:	ff 34 b5 2c 47 11 80 	pushl  -0x7feeb8d4(,%esi,4)
801027c6:	ff 35 24 47 11 80    	pushl  0x80114724
801027cc:	e8 9f d9 ff ff       	call   80100170 <bread>
801027d1:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801027d3:	8d 50 5c             	lea    0x5c(%eax),%edx
801027d6:	8d 43 5c             	lea    0x5c(%ebx),%eax
801027d9:	83 c4 0c             	add    $0xc,%esp
801027dc:	68 00 02 00 00       	push   $0x200
801027e1:	52                   	push   %edx
801027e2:	50                   	push   %eax
801027e3:	e8 fa 16 00 00       	call   80103ee2 <memmove>
    bwrite(to);  // write the log
801027e8:	89 1c 24             	mov    %ebx,(%esp)
801027eb:	e8 b2 d9 ff ff       	call   801001a2 <bwrite>
    brelse(from);
801027f0:	89 3c 24             	mov    %edi,(%esp)
801027f3:	e8 e9 d9 ff ff       	call   801001e1 <brelse>
    brelse(to);
801027f8:	89 1c 24             	mov    %ebx,(%esp)
801027fb:	e8 e1 d9 ff ff       	call   801001e1 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102800:	83 c6 01             	add    $0x1,%esi
80102803:	83 c4 10             	add    $0x10,%esp
80102806:	eb 90                	jmp    80102798 <write_log+0xe>
  }
}
80102808:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010280b:	5b                   	pop    %ebx
8010280c:	5e                   	pop    %esi
8010280d:	5f                   	pop    %edi
8010280e:	5d                   	pop    %ebp
8010280f:	c3                   	ret    

80102810 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102810:	83 3d 28 47 11 80 00 	cmpl   $0x0,0x80114728
80102817:	7f 01                	jg     8010281a <commit+0xa>
80102819:	c3                   	ret    
{
8010281a:	55                   	push   %ebp
8010281b:	89 e5                	mov    %esp,%ebp
8010281d:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102820:	e8 65 ff ff ff       	call   8010278a <write_log>
    write_head();    // Write header to disk -- the real commit
80102825:	e8 e7 fe ff ff       	call   80102711 <write_head>
    install_trans(); // Now install writes to home locations
8010282a:	e8 5c fe ff ff       	call   8010268b <install_trans>
    log.lh.n = 0;
8010282f:	c7 05 28 47 11 80 00 	movl   $0x0,0x80114728
80102836:	00 00 00 
    write_head();    // Erase the transaction from the log
80102839:	e8 d3 fe ff ff       	call   80102711 <write_head>
  }
}
8010283e:	c9                   	leave  
8010283f:	c3                   	ret    

80102840 <initlog>:
{
80102840:	f3 0f 1e fb          	endbr32 
80102844:	55                   	push   %ebp
80102845:	89 e5                	mov    %esp,%ebp
80102847:	53                   	push   %ebx
80102848:	83 ec 2c             	sub    $0x2c,%esp
8010284b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010284e:	68 40 6b 10 80       	push   $0x80106b40
80102853:	68 e0 46 11 80       	push   $0x801146e0
80102858:	e8 01 14 00 00       	call   80103c5e <initlock>
  readsb(dev, &sb);
8010285d:	83 c4 08             	add    $0x8,%esp
80102860:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102863:	50                   	push   %eax
80102864:	53                   	push   %ebx
80102865:	e8 3b ea ff ff       	call   801012a5 <readsb>
  log.start = sb.logstart;
8010286a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010286d:	a3 14 47 11 80       	mov    %eax,0x80114714
  log.size = sb.nlog;
80102872:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102875:	a3 18 47 11 80       	mov    %eax,0x80114718
  log.dev = dev;
8010287a:	89 1d 24 47 11 80    	mov    %ebx,0x80114724
  recover_from_log();
80102880:	e8 e4 fe ff ff       	call   80102769 <recover_from_log>
}
80102885:	83 c4 10             	add    $0x10,%esp
80102888:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010288b:	c9                   	leave  
8010288c:	c3                   	ret    

8010288d <begin_op>:
{
8010288d:	f3 0f 1e fb          	endbr32 
80102891:	55                   	push   %ebp
80102892:	89 e5                	mov    %esp,%ebp
80102894:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102897:	68 e0 46 11 80       	push   $0x801146e0
8010289c:	e8 0d 15 00 00       	call   80103dae <acquire>
801028a1:	83 c4 10             	add    $0x10,%esp
801028a4:	eb 15                	jmp    801028bb <begin_op+0x2e>
      sleep(&log, &log.lock);
801028a6:	83 ec 08             	sub    $0x8,%esp
801028a9:	68 e0 46 11 80       	push   $0x801146e0
801028ae:	68 e0 46 11 80       	push   $0x801146e0
801028b3:	e8 4f 0f 00 00       	call   80103807 <sleep>
801028b8:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028bb:	83 3d 20 47 11 80 00 	cmpl   $0x0,0x80114720
801028c2:	75 e2                	jne    801028a6 <begin_op+0x19>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801028c4:	a1 1c 47 11 80       	mov    0x8011471c,%eax
801028c9:	83 c0 01             	add    $0x1,%eax
801028cc:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028cf:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801028d2:	03 15 28 47 11 80    	add    0x80114728,%edx
801028d8:	83 fa 1e             	cmp    $0x1e,%edx
801028db:	7e 17                	jle    801028f4 <begin_op+0x67>
      sleep(&log, &log.lock);
801028dd:	83 ec 08             	sub    $0x8,%esp
801028e0:	68 e0 46 11 80       	push   $0x801146e0
801028e5:	68 e0 46 11 80       	push   $0x801146e0
801028ea:	e8 18 0f 00 00       	call   80103807 <sleep>
801028ef:	83 c4 10             	add    $0x10,%esp
801028f2:	eb c7                	jmp    801028bb <begin_op+0x2e>
      log.outstanding += 1;
801028f4:	a3 1c 47 11 80       	mov    %eax,0x8011471c
      release(&log.lock);
801028f9:	83 ec 0c             	sub    $0xc,%esp
801028fc:	68 e0 46 11 80       	push   $0x801146e0
80102901:	e8 11 15 00 00       	call   80103e17 <release>
}
80102906:	83 c4 10             	add    $0x10,%esp
80102909:	c9                   	leave  
8010290a:	c3                   	ret    

8010290b <end_op>:
{
8010290b:	f3 0f 1e fb          	endbr32 
8010290f:	55                   	push   %ebp
80102910:	89 e5                	mov    %esp,%ebp
80102912:	53                   	push   %ebx
80102913:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102916:	68 e0 46 11 80       	push   $0x801146e0
8010291b:	e8 8e 14 00 00       	call   80103dae <acquire>
  log.outstanding -= 1;
80102920:	a1 1c 47 11 80       	mov    0x8011471c,%eax
80102925:	83 e8 01             	sub    $0x1,%eax
80102928:	a3 1c 47 11 80       	mov    %eax,0x8011471c
  if(log.committing)
8010292d:	8b 1d 20 47 11 80    	mov    0x80114720,%ebx
80102933:	83 c4 10             	add    $0x10,%esp
80102936:	85 db                	test   %ebx,%ebx
80102938:	75 2c                	jne    80102966 <end_op+0x5b>
  if(log.outstanding == 0){
8010293a:	85 c0                	test   %eax,%eax
8010293c:	75 35                	jne    80102973 <end_op+0x68>
    log.committing = 1;
8010293e:	c7 05 20 47 11 80 01 	movl   $0x1,0x80114720
80102945:	00 00 00 
    do_commit = 1;
80102948:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
8010294d:	83 ec 0c             	sub    $0xc,%esp
80102950:	68 e0 46 11 80       	push   $0x801146e0
80102955:	e8 bd 14 00 00       	call   80103e17 <release>
  if(do_commit){
8010295a:	83 c4 10             	add    $0x10,%esp
8010295d:	85 db                	test   %ebx,%ebx
8010295f:	75 24                	jne    80102985 <end_op+0x7a>
}
80102961:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102964:	c9                   	leave  
80102965:	c3                   	ret    
    panic("log.committing");
80102966:	83 ec 0c             	sub    $0xc,%esp
80102969:	68 44 6b 10 80       	push   $0x80106b44
8010296e:	e8 e9 d9 ff ff       	call   8010035c <panic>
    wakeup(&log);
80102973:	83 ec 0c             	sub    $0xc,%esp
80102976:	68 e0 46 11 80       	push   $0x801146e0
8010297b:	e8 f3 0f 00 00       	call   80103973 <wakeup>
80102980:	83 c4 10             	add    $0x10,%esp
80102983:	eb c8                	jmp    8010294d <end_op+0x42>
    commit();
80102985:	e8 86 fe ff ff       	call   80102810 <commit>
    acquire(&log.lock);
8010298a:	83 ec 0c             	sub    $0xc,%esp
8010298d:	68 e0 46 11 80       	push   $0x801146e0
80102992:	e8 17 14 00 00       	call   80103dae <acquire>
    log.committing = 0;
80102997:	c7 05 20 47 11 80 00 	movl   $0x0,0x80114720
8010299e:	00 00 00 
    wakeup(&log);
801029a1:	c7 04 24 e0 46 11 80 	movl   $0x801146e0,(%esp)
801029a8:	e8 c6 0f 00 00       	call   80103973 <wakeup>
    release(&log.lock);
801029ad:	c7 04 24 e0 46 11 80 	movl   $0x801146e0,(%esp)
801029b4:	e8 5e 14 00 00       	call   80103e17 <release>
801029b9:	83 c4 10             	add    $0x10,%esp
}
801029bc:	eb a3                	jmp    80102961 <end_op+0x56>

801029be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801029be:	f3 0f 1e fb          	endbr32 
801029c2:	55                   	push   %ebp
801029c3:	89 e5                	mov    %esp,%ebp
801029c5:	53                   	push   %ebx
801029c6:	83 ec 04             	sub    $0x4,%esp
801029c9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801029cc:	8b 15 28 47 11 80    	mov    0x80114728,%edx
801029d2:	83 fa 1d             	cmp    $0x1d,%edx
801029d5:	7f 45                	jg     80102a1c <log_write+0x5e>
801029d7:	a1 18 47 11 80       	mov    0x80114718,%eax
801029dc:	83 e8 01             	sub    $0x1,%eax
801029df:	39 c2                	cmp    %eax,%edx
801029e1:	7d 39                	jge    80102a1c <log_write+0x5e>
    panic("too big a transaction");
  if (log.outstanding < 1)
801029e3:	83 3d 1c 47 11 80 00 	cmpl   $0x0,0x8011471c
801029ea:	7e 3d                	jle    80102a29 <log_write+0x6b>
    panic("log_write outside of trans");

  acquire(&log.lock);
801029ec:	83 ec 0c             	sub    $0xc,%esp
801029ef:	68 e0 46 11 80       	push   $0x801146e0
801029f4:	e8 b5 13 00 00       	call   80103dae <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029f9:	83 c4 10             	add    $0x10,%esp
801029fc:	b8 00 00 00 00       	mov    $0x0,%eax
80102a01:	8b 15 28 47 11 80    	mov    0x80114728,%edx
80102a07:	39 c2                	cmp    %eax,%edx
80102a09:	7e 2b                	jle    80102a36 <log_write+0x78>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a0b:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a0e:	39 0c 85 2c 47 11 80 	cmp    %ecx,-0x7feeb8d4(,%eax,4)
80102a15:	74 1f                	je     80102a36 <log_write+0x78>
  for (i = 0; i < log.lh.n; i++) {
80102a17:	83 c0 01             	add    $0x1,%eax
80102a1a:	eb e5                	jmp    80102a01 <log_write+0x43>
    panic("too big a transaction");
80102a1c:	83 ec 0c             	sub    $0xc,%esp
80102a1f:	68 53 6b 10 80       	push   $0x80106b53
80102a24:	e8 33 d9 ff ff       	call   8010035c <panic>
    panic("log_write outside of trans");
80102a29:	83 ec 0c             	sub    $0xc,%esp
80102a2c:	68 69 6b 10 80       	push   $0x80106b69
80102a31:	e8 26 d9 ff ff       	call   8010035c <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a36:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a39:	89 0c 85 2c 47 11 80 	mov    %ecx,-0x7feeb8d4(,%eax,4)
  if (i == log.lh.n)
80102a40:	39 c2                	cmp    %eax,%edx
80102a42:	74 18                	je     80102a5c <log_write+0x9e>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a44:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a47:	83 ec 0c             	sub    $0xc,%esp
80102a4a:	68 e0 46 11 80       	push   $0x801146e0
80102a4f:	e8 c3 13 00 00       	call   80103e17 <release>
}
80102a54:	83 c4 10             	add    $0x10,%esp
80102a57:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a5a:	c9                   	leave  
80102a5b:	c3                   	ret    
    log.lh.n++;
80102a5c:	83 c2 01             	add    $0x1,%edx
80102a5f:	89 15 28 47 11 80    	mov    %edx,0x80114728
80102a65:	eb dd                	jmp    80102a44 <log_write+0x86>

80102a67 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a67:	55                   	push   %ebp
80102a68:	89 e5                	mov    %esp,%ebp
80102a6a:	53                   	push   %ebx
80102a6b:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a6e:	68 8a 00 00 00       	push   $0x8a
80102a73:	68 8c a4 10 80       	push   $0x8010a48c
80102a78:	68 00 70 00 80       	push   $0x80007000
80102a7d:	e8 60 14 00 00       	call   80103ee2 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a82:	83 c4 10             	add    $0x10,%esp
80102a85:	bb e0 47 11 80       	mov    $0x801147e0,%ebx
80102a8a:	eb 47                	jmp    80102ad3 <startothers+0x6c>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a8c:	e8 ff f6 ff ff       	call   80102190 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a91:	05 00 10 00 00       	add    $0x1000,%eax
80102a96:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void**)(code-8) = mpenter;
80102a9b:	c7 05 f8 6f 00 80 35 	movl   $0x80102b35,0x80006ff8
80102aa2:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102aa5:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102aac:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102aaf:	83 ec 08             	sub    $0x8,%esp
80102ab2:	68 00 70 00 00       	push   $0x7000
80102ab7:	0f b6 03             	movzbl (%ebx),%eax
80102aba:	50                   	push   %eax
80102abb:	e8 db f9 ff ff       	call   8010249b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102ac0:	83 c4 10             	add    $0x10,%esp
80102ac3:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ac9:	85 c0                	test   %eax,%eax
80102acb:	74 f6                	je     80102ac3 <startothers+0x5c>
  for(c = cpus; c < cpus+ncpu; c++){
80102acd:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ad3:	69 05 60 4d 11 80 b0 	imul   $0xb0,0x80114d60,%eax
80102ada:	00 00 00 
80102add:	05 e0 47 11 80       	add    $0x801147e0,%eax
80102ae2:	39 d8                	cmp    %ebx,%eax
80102ae4:	76 0b                	jbe    80102af1 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102ae6:	e8 b0 07 00 00       	call   8010329b <mycpu>
80102aeb:	39 c3                	cmp    %eax,%ebx
80102aed:	74 de                	je     80102acd <startothers+0x66>
80102aef:	eb 9b                	jmp    80102a8c <startothers+0x25>
      ;
  }
}
80102af1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102af4:	c9                   	leave  
80102af5:	c3                   	ret    

80102af6 <mpmain>:
{
80102af6:	55                   	push   %ebp
80102af7:	89 e5                	mov    %esp,%ebp
80102af9:	53                   	push   %ebx
80102afa:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102afd:	e8 f9 07 00 00       	call   801032fb <cpuid>
80102b02:	89 c3                	mov    %eax,%ebx
80102b04:	e8 f2 07 00 00       	call   801032fb <cpuid>
80102b09:	83 ec 04             	sub    $0x4,%esp
80102b0c:	53                   	push   %ebx
80102b0d:	50                   	push   %eax
80102b0e:	68 84 6b 10 80       	push   $0x80106b84
80102b13:	e8 11 db ff ff       	call   80100629 <cprintf>
  idtinit();       // load idt register
80102b18:	e8 d1 24 00 00       	call   80104fee <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b1d:	e8 79 07 00 00       	call   8010329b <mycpu>
80102b22:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b24:	b8 01 00 00 00       	mov    $0x1,%eax
80102b29:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b30:	e8 79 0a 00 00       	call   801035ae <scheduler>

80102b35 <mpenter>:
{
80102b35:	f3 0f 1e fb          	endbr32 
80102b39:	55                   	push   %ebp
80102b3a:	89 e5                	mov    %esp,%ebp
80102b3c:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b3f:	e8 d1 34 00 00       	call   80106015 <switchkvm>
  seginit();
80102b44:	e8 7c 33 00 00       	call   80105ec5 <seginit>
  lapicinit();
80102b49:	e8 f9 f7 ff ff       	call   80102347 <lapicinit>
  mpmain();
80102b4e:	e8 a3 ff ff ff       	call   80102af6 <mpmain>

80102b53 <main>:
{
80102b53:	f3 0f 1e fb          	endbr32 
80102b57:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b5b:	83 e4 f0             	and    $0xfffffff0,%esp
80102b5e:	ff 71 fc             	pushl  -0x4(%ecx)
80102b61:	55                   	push   %ebp
80102b62:	89 e5                	mov    %esp,%ebp
80102b64:	51                   	push   %ecx
80102b65:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b68:	68 00 00 40 80       	push   $0x80400000
80102b6d:	68 88 55 11 80       	push   $0x80115588
80102b72:	e8 bf f5 ff ff       	call   80102136 <kinit1>
  kvmalloc();      // kernel page table
80102b77:	e8 3c 39 00 00       	call   801064b8 <kvmalloc>
  mpinit();        // detect other processors
80102b7c:	e8 c1 01 00 00       	call   80102d42 <mpinit>
  lapicinit();     // interrupt controller
80102b81:	e8 c1 f7 ff ff       	call   80102347 <lapicinit>
  seginit();       // segment descriptors
80102b86:	e8 3a 33 00 00       	call   80105ec5 <seginit>
  picinit();       // disable pic
80102b8b:	e8 8c 02 00 00       	call   80102e1c <picinit>
  ioapicinit();    // another interrupt controller
80102b90:	e8 1c f4 ff ff       	call   80101fb1 <ioapicinit>
  consoleinit();   // console hardware
80102b95:	e8 59 dd ff ff       	call   801008f3 <consoleinit>
  uartinit();      // serial port
80102b9a:	e8 0e 27 00 00       	call   801052ad <uartinit>
  pinit();         // process table
80102b9f:	e8 d9 06 00 00       	call   8010327d <pinit>
  tvinit();        // trap vectors
80102ba4:	e8 ac 23 00 00       	call   80104f55 <tvinit>
  binit();         // buffer cache
80102ba9:	e8 46 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102bae:	e8 b6 e0 ff ff       	call   80100c69 <fileinit>
  ideinit();       // disk 
80102bb3:	e8 fb f1 ff ff       	call   80101db3 <ideinit>
  startothers();   // start other processors
80102bb8:	e8 aa fe ff ff       	call   80102a67 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102bbd:	83 c4 08             	add    $0x8,%esp
80102bc0:	68 00 00 00 8e       	push   $0x8e000000
80102bc5:	68 00 00 40 80       	push   $0x80400000
80102bca:	e8 9d f5 ff ff       	call   8010216c <kinit2>
  userinit();      // first user process
80102bcf:	e8 6e 07 00 00       	call   80103342 <userinit>
  mpmain();        // finish this processor's setup
80102bd4:	e8 1d ff ff ff       	call   80102af6 <mpmain>

80102bd9 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102bd9:	55                   	push   %ebp
80102bda:	89 e5                	mov    %esp,%ebp
80102bdc:	56                   	push   %esi
80102bdd:	53                   	push   %ebx
80102bde:	89 c6                	mov    %eax,%esi
  int i, sum;

  sum = 0;
80102be0:	b8 00 00 00 00       	mov    $0x0,%eax
  for(i=0; i<len; i++)
80102be5:	b9 00 00 00 00       	mov    $0x0,%ecx
80102bea:	39 d1                	cmp    %edx,%ecx
80102bec:	7d 0b                	jge    80102bf9 <sum+0x20>
    sum += addr[i];
80102bee:	0f b6 1c 0e          	movzbl (%esi,%ecx,1),%ebx
80102bf2:	01 d8                	add    %ebx,%eax
  for(i=0; i<len; i++)
80102bf4:	83 c1 01             	add    $0x1,%ecx
80102bf7:	eb f1                	jmp    80102bea <sum+0x11>
  return sum;
}
80102bf9:	5b                   	pop    %ebx
80102bfa:	5e                   	pop    %esi
80102bfb:	5d                   	pop    %ebp
80102bfc:	c3                   	ret    

80102bfd <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102bfd:	55                   	push   %ebp
80102bfe:	89 e5                	mov    %esp,%ebp
80102c00:	56                   	push   %esi
80102c01:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c02:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c08:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c0a:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c0c:	eb 03                	jmp    80102c11 <mpsearch1+0x14>
80102c0e:	83 c3 10             	add    $0x10,%ebx
80102c11:	39 f3                	cmp    %esi,%ebx
80102c13:	73 29                	jae    80102c3e <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c15:	83 ec 04             	sub    $0x4,%esp
80102c18:	6a 04                	push   $0x4
80102c1a:	68 98 6b 10 80       	push   $0x80106b98
80102c1f:	53                   	push   %ebx
80102c20:	e8 84 12 00 00       	call   80103ea9 <memcmp>
80102c25:	83 c4 10             	add    $0x10,%esp
80102c28:	85 c0                	test   %eax,%eax
80102c2a:	75 e2                	jne    80102c0e <mpsearch1+0x11>
80102c2c:	ba 10 00 00 00       	mov    $0x10,%edx
80102c31:	89 d8                	mov    %ebx,%eax
80102c33:	e8 a1 ff ff ff       	call   80102bd9 <sum>
80102c38:	84 c0                	test   %al,%al
80102c3a:	75 d2                	jne    80102c0e <mpsearch1+0x11>
80102c3c:	eb 05                	jmp    80102c43 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c3e:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c43:	89 d8                	mov    %ebx,%eax
80102c45:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c48:	5b                   	pop    %ebx
80102c49:	5e                   	pop    %esi
80102c4a:	5d                   	pop    %ebp
80102c4b:	c3                   	ret    

80102c4c <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c4c:	55                   	push   %ebp
80102c4d:	89 e5                	mov    %esp,%ebp
80102c4f:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c52:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c59:	c1 e0 08             	shl    $0x8,%eax
80102c5c:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c63:	09 d0                	or     %edx,%eax
80102c65:	c1 e0 04             	shl    $0x4,%eax
80102c68:	74 1f                	je     80102c89 <mpsearch+0x3d>
    if((mp = mpsearch1(p, 1024)))
80102c6a:	ba 00 04 00 00       	mov    $0x400,%edx
80102c6f:	e8 89 ff ff ff       	call   80102bfd <mpsearch1>
80102c74:	85 c0                	test   %eax,%eax
80102c76:	75 0f                	jne    80102c87 <mpsearch+0x3b>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c78:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c7d:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c82:	e8 76 ff ff ff       	call   80102bfd <mpsearch1>
}
80102c87:	c9                   	leave  
80102c88:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c89:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c90:	c1 e0 08             	shl    $0x8,%eax
80102c93:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c9a:	09 d0                	or     %edx,%eax
80102c9c:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c9f:	2d 00 04 00 00       	sub    $0x400,%eax
80102ca4:	ba 00 04 00 00       	mov    $0x400,%edx
80102ca9:	e8 4f ff ff ff       	call   80102bfd <mpsearch1>
80102cae:	85 c0                	test   %eax,%eax
80102cb0:	75 d5                	jne    80102c87 <mpsearch+0x3b>
80102cb2:	eb c4                	jmp    80102c78 <mpsearch+0x2c>

80102cb4 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102cb4:	55                   	push   %ebp
80102cb5:	89 e5                	mov    %esp,%ebp
80102cb7:	57                   	push   %edi
80102cb8:	56                   	push   %esi
80102cb9:	53                   	push   %ebx
80102cba:	83 ec 1c             	sub    $0x1c,%esp
80102cbd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102cc0:	e8 87 ff ff ff       	call   80102c4c <mpsearch>
80102cc5:	89 c3                	mov    %eax,%ebx
80102cc7:	85 c0                	test   %eax,%eax
80102cc9:	74 5a                	je     80102d25 <mpconfig+0x71>
80102ccb:	8b 70 04             	mov    0x4(%eax),%esi
80102cce:	85 f6                	test   %esi,%esi
80102cd0:	74 57                	je     80102d29 <mpconfig+0x75>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102cd2:	8d be 00 00 00 80    	lea    -0x80000000(%esi),%edi
  if(memcmp(conf, "PCMP", 4) != 0)
80102cd8:	83 ec 04             	sub    $0x4,%esp
80102cdb:	6a 04                	push   $0x4
80102cdd:	68 9d 6b 10 80       	push   $0x80106b9d
80102ce2:	57                   	push   %edi
80102ce3:	e8 c1 11 00 00       	call   80103ea9 <memcmp>
80102ce8:	83 c4 10             	add    $0x10,%esp
80102ceb:	85 c0                	test   %eax,%eax
80102ced:	75 3e                	jne    80102d2d <mpconfig+0x79>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102cef:	0f b6 86 06 00 00 80 	movzbl -0x7ffffffa(%esi),%eax
80102cf6:	3c 01                	cmp    $0x1,%al
80102cf8:	0f 95 c2             	setne  %dl
80102cfb:	3c 04                	cmp    $0x4,%al
80102cfd:	0f 95 c0             	setne  %al
80102d00:	84 c2                	test   %al,%dl
80102d02:	75 30                	jne    80102d34 <mpconfig+0x80>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d04:	0f b7 96 04 00 00 80 	movzwl -0x7ffffffc(%esi),%edx
80102d0b:	89 f8                	mov    %edi,%eax
80102d0d:	e8 c7 fe ff ff       	call   80102bd9 <sum>
80102d12:	84 c0                	test   %al,%al
80102d14:	75 25                	jne    80102d3b <mpconfig+0x87>
    return 0;
  *pmp = mp;
80102d16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d19:	89 18                	mov    %ebx,(%eax)
  return conf;
}
80102d1b:	89 f8                	mov    %edi,%eax
80102d1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d20:	5b                   	pop    %ebx
80102d21:	5e                   	pop    %esi
80102d22:	5f                   	pop    %edi
80102d23:	5d                   	pop    %ebp
80102d24:	c3                   	ret    
    return 0;
80102d25:	89 c7                	mov    %eax,%edi
80102d27:	eb f2                	jmp    80102d1b <mpconfig+0x67>
80102d29:	89 f7                	mov    %esi,%edi
80102d2b:	eb ee                	jmp    80102d1b <mpconfig+0x67>
    return 0;
80102d2d:	bf 00 00 00 00       	mov    $0x0,%edi
80102d32:	eb e7                	jmp    80102d1b <mpconfig+0x67>
    return 0;
80102d34:	bf 00 00 00 00       	mov    $0x0,%edi
80102d39:	eb e0                	jmp    80102d1b <mpconfig+0x67>
    return 0;
80102d3b:	bf 00 00 00 00       	mov    $0x0,%edi
80102d40:	eb d9                	jmp    80102d1b <mpconfig+0x67>

80102d42 <mpinit>:

void
mpinit(void)
{
80102d42:	f3 0f 1e fb          	endbr32 
80102d46:	55                   	push   %ebp
80102d47:	89 e5                	mov    %esp,%ebp
80102d49:	57                   	push   %edi
80102d4a:	56                   	push   %esi
80102d4b:	53                   	push   %ebx
80102d4c:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d4f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d52:	e8 5d ff ff ff       	call   80102cb4 <mpconfig>
80102d57:	85 c0                	test   %eax,%eax
80102d59:	74 19                	je     80102d74 <mpinit+0x32>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d5b:	8b 50 24             	mov    0x24(%eax),%edx
80102d5e:	89 15 dc 46 11 80    	mov    %edx,0x801146dc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d64:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d67:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d6b:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d6d:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d72:	eb 20                	jmp    80102d94 <mpinit+0x52>
    panic("Expect to run on an SMP");
80102d74:	83 ec 0c             	sub    $0xc,%esp
80102d77:	68 a2 6b 10 80       	push   $0x80106ba2
80102d7c:	e8 db d5 ff ff       	call   8010035c <panic>
    switch(*p){
80102d81:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d86:	eb 0c                	jmp    80102d94 <mpinit+0x52>
80102d88:	83 e8 03             	sub    $0x3,%eax
80102d8b:	3c 01                	cmp    $0x1,%al
80102d8d:	76 1a                	jbe    80102da9 <mpinit+0x67>
80102d8f:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d94:	39 ca                	cmp    %ecx,%edx
80102d96:	73 4d                	jae    80102de5 <mpinit+0xa3>
    switch(*p){
80102d98:	0f b6 02             	movzbl (%edx),%eax
80102d9b:	3c 02                	cmp    $0x2,%al
80102d9d:	74 38                	je     80102dd7 <mpinit+0x95>
80102d9f:	77 e7                	ja     80102d88 <mpinit+0x46>
80102da1:	84 c0                	test   %al,%al
80102da3:	74 09                	je     80102dae <mpinit+0x6c>
80102da5:	3c 01                	cmp    $0x1,%al
80102da7:	75 d8                	jne    80102d81 <mpinit+0x3f>
      p += sizeof(struct mpioapic);
      continue;
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102da9:	83 c2 08             	add    $0x8,%edx
      continue;
80102dac:	eb e6                	jmp    80102d94 <mpinit+0x52>
      if(ncpu < NCPU) {
80102dae:	8b 35 60 4d 11 80    	mov    0x80114d60,%esi
80102db4:	83 fe 07             	cmp    $0x7,%esi
80102db7:	7f 19                	jg     80102dd2 <mpinit+0x90>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102db9:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dbd:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102dc3:	88 87 e0 47 11 80    	mov    %al,-0x7feeb820(%edi)
        ncpu++;
80102dc9:	83 c6 01             	add    $0x1,%esi
80102dcc:	89 35 60 4d 11 80    	mov    %esi,0x80114d60
      p += sizeof(struct mpproc);
80102dd2:	83 c2 14             	add    $0x14,%edx
      continue;
80102dd5:	eb bd                	jmp    80102d94 <mpinit+0x52>
      ioapicid = ioapic->apicno;
80102dd7:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ddb:	a2 c0 47 11 80       	mov    %al,0x801147c0
      p += sizeof(struct mpioapic);
80102de0:	83 c2 08             	add    $0x8,%edx
      continue;
80102de3:	eb af                	jmp    80102d94 <mpinit+0x52>
    default:
      ismp = 0;
      break;
    }
  }
  if(!ismp)
80102de5:	85 db                	test   %ebx,%ebx
80102de7:	74 26                	je     80102e0f <mpinit+0xcd>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102de9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102dec:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102df0:	74 15                	je     80102e07 <mpinit+0xc5>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102df2:	b8 70 00 00 00       	mov    $0x70,%eax
80102df7:	ba 22 00 00 00       	mov    $0x22,%edx
80102dfc:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dfd:	ba 23 00 00 00       	mov    $0x23,%edx
80102e02:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e03:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e06:	ee                   	out    %al,(%dx)
  }
}
80102e07:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e0a:	5b                   	pop    %ebx
80102e0b:	5e                   	pop    %esi
80102e0c:	5f                   	pop    %edi
80102e0d:	5d                   	pop    %ebp
80102e0e:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e0f:	83 ec 0c             	sub    $0xc,%esp
80102e12:	68 bc 6b 10 80       	push   $0x80106bbc
80102e17:	e8 40 d5 ff ff       	call   8010035c <panic>

80102e1c <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e1c:	f3 0f 1e fb          	endbr32 
80102e20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e25:	ba 21 00 00 00       	mov    $0x21,%edx
80102e2a:	ee                   	out    %al,(%dx)
80102e2b:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e30:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e31:	c3                   	ret    

80102e32 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e32:	f3 0f 1e fb          	endbr32 
80102e36:	55                   	push   %ebp
80102e37:	89 e5                	mov    %esp,%ebp
80102e39:	57                   	push   %edi
80102e3a:	56                   	push   %esi
80102e3b:	53                   	push   %ebx
80102e3c:	83 ec 0c             	sub    $0xc,%esp
80102e3f:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e42:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e45:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e4b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e51:	e8 31 de ff ff       	call   80100c87 <filealloc>
80102e56:	89 03                	mov    %eax,(%ebx)
80102e58:	85 c0                	test   %eax,%eax
80102e5a:	0f 84 88 00 00 00    	je     80102ee8 <pipealloc+0xb6>
80102e60:	e8 22 de ff ff       	call   80100c87 <filealloc>
80102e65:	89 06                	mov    %eax,(%esi)
80102e67:	85 c0                	test   %eax,%eax
80102e69:	74 7d                	je     80102ee8 <pipealloc+0xb6>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e6b:	e8 20 f3 ff ff       	call   80102190 <kalloc>
80102e70:	89 c7                	mov    %eax,%edi
80102e72:	85 c0                	test   %eax,%eax
80102e74:	74 72                	je     80102ee8 <pipealloc+0xb6>
    goto bad;
  p->readopen = 1;
80102e76:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e7d:	00 00 00 
  p->writeopen = 1;
80102e80:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e87:	00 00 00 
  p->nwrite = 0;
80102e8a:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e91:	00 00 00 
  p->nread = 0;
80102e94:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e9b:	00 00 00 
  initlock(&p->lock, "pipe");
80102e9e:	83 ec 08             	sub    $0x8,%esp
80102ea1:	68 db 6b 10 80       	push   $0x80106bdb
80102ea6:	50                   	push   %eax
80102ea7:	e8 b2 0d 00 00       	call   80103c5e <initlock>
  (*f0)->type = FD_PIPE;
80102eac:	8b 03                	mov    (%ebx),%eax
80102eae:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102eb4:	8b 03                	mov    (%ebx),%eax
80102eb6:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102eba:	8b 03                	mov    (%ebx),%eax
80102ebc:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102ec0:	8b 03                	mov    (%ebx),%eax
80102ec2:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102ec5:	8b 06                	mov    (%esi),%eax
80102ec7:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102ecd:	8b 06                	mov    (%esi),%eax
80102ecf:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102ed3:	8b 06                	mov    (%esi),%eax
80102ed5:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102ed9:	8b 06                	mov    (%esi),%eax
80102edb:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102ede:	83 c4 10             	add    $0x10,%esp
80102ee1:	b8 00 00 00 00       	mov    $0x0,%eax
80102ee6:	eb 29                	jmp    80102f11 <pipealloc+0xdf>

//PAGEBREAK: 20
 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102ee8:	8b 03                	mov    (%ebx),%eax
80102eea:	85 c0                	test   %eax,%eax
80102eec:	74 0c                	je     80102efa <pipealloc+0xc8>
    fileclose(*f0);
80102eee:	83 ec 0c             	sub    $0xc,%esp
80102ef1:	50                   	push   %eax
80102ef2:	e8 3e de ff ff       	call   80100d35 <fileclose>
80102ef7:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102efa:	8b 06                	mov    (%esi),%eax
80102efc:	85 c0                	test   %eax,%eax
80102efe:	74 19                	je     80102f19 <pipealloc+0xe7>
    fileclose(*f1);
80102f00:	83 ec 0c             	sub    $0xc,%esp
80102f03:	50                   	push   %eax
80102f04:	e8 2c de ff ff       	call   80100d35 <fileclose>
80102f09:	83 c4 10             	add    $0x10,%esp
  return -1;
80102f0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102f11:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f14:	5b                   	pop    %ebx
80102f15:	5e                   	pop    %esi
80102f16:	5f                   	pop    %edi
80102f17:	5d                   	pop    %ebp
80102f18:	c3                   	ret    
  return -1;
80102f19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f1e:	eb f1                	jmp    80102f11 <pipealloc+0xdf>

80102f20 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f20:	f3 0f 1e fb          	endbr32 
80102f24:	55                   	push   %ebp
80102f25:	89 e5                	mov    %esp,%ebp
80102f27:	53                   	push   %ebx
80102f28:	83 ec 10             	sub    $0x10,%esp
80102f2b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f2e:	53                   	push   %ebx
80102f2f:	e8 7a 0e 00 00       	call   80103dae <acquire>
  if(writable){
80102f34:	83 c4 10             	add    $0x10,%esp
80102f37:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f3b:	74 3f                	je     80102f7c <pipeclose+0x5c>
    p->writeopen = 0;
80102f3d:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f44:	00 00 00 
    wakeup(&p->nread);
80102f47:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f4d:	83 ec 0c             	sub    $0xc,%esp
80102f50:	50                   	push   %eax
80102f51:	e8 1d 0a 00 00       	call   80103973 <wakeup>
80102f56:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f59:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f60:	75 09                	jne    80102f6b <pipeclose+0x4b>
80102f62:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f69:	74 2f                	je     80102f9a <pipeclose+0x7a>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f6b:	83 ec 0c             	sub    $0xc,%esp
80102f6e:	53                   	push   %ebx
80102f6f:	e8 a3 0e 00 00       	call   80103e17 <release>
80102f74:	83 c4 10             	add    $0x10,%esp
}
80102f77:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f7a:	c9                   	leave  
80102f7b:	c3                   	ret    
    p->readopen = 0;
80102f7c:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f83:	00 00 00 
    wakeup(&p->nwrite);
80102f86:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f8c:	83 ec 0c             	sub    $0xc,%esp
80102f8f:	50                   	push   %eax
80102f90:	e8 de 09 00 00       	call   80103973 <wakeup>
80102f95:	83 c4 10             	add    $0x10,%esp
80102f98:	eb bf                	jmp    80102f59 <pipeclose+0x39>
    release(&p->lock);
80102f9a:	83 ec 0c             	sub    $0xc,%esp
80102f9d:	53                   	push   %ebx
80102f9e:	e8 74 0e 00 00       	call   80103e17 <release>
    kfree((char*)p);
80102fa3:	89 1c 24             	mov    %ebx,(%esp)
80102fa6:	e8 be f0 ff ff       	call   80102069 <kfree>
80102fab:	83 c4 10             	add    $0x10,%esp
80102fae:	eb c7                	jmp    80102f77 <pipeclose+0x57>

80102fb0 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80102fb0:	f3 0f 1e fb          	endbr32 
80102fb4:	55                   	push   %ebp
80102fb5:	89 e5                	mov    %esp,%ebp
80102fb7:	57                   	push   %edi
80102fb8:	56                   	push   %esi
80102fb9:	53                   	push   %ebx
80102fba:	83 ec 18             	sub    $0x18,%esp
80102fbd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fc0:	89 de                	mov    %ebx,%esi
80102fc2:	53                   	push   %ebx
80102fc3:	e8 e6 0d 00 00       	call   80103dae <acquire>
  for(i = 0; i < n; i++){
80102fc8:	83 c4 10             	add    $0x10,%esp
80102fcb:	bf 00 00 00 00       	mov    $0x0,%edi
80102fd0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102fd3:	7c 41                	jl     80103016 <pipewrite+0x66>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102fd5:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fdb:	83 ec 0c             	sub    $0xc,%esp
80102fde:	50                   	push   %eax
80102fdf:	e8 8f 09 00 00       	call   80103973 <wakeup>
  release(&p->lock);
80102fe4:	89 1c 24             	mov    %ebx,(%esp)
80102fe7:	e8 2b 0e 00 00       	call   80103e17 <release>
  return n;
80102fec:	83 c4 10             	add    $0x10,%esp
80102fef:	8b 45 10             	mov    0x10(%ebp),%eax
80102ff2:	eb 5c                	jmp    80103050 <pipewrite+0xa0>
      wakeup(&p->nread);
80102ff4:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ffa:	83 ec 0c             	sub    $0xc,%esp
80102ffd:	50                   	push   %eax
80102ffe:	e8 70 09 00 00       	call   80103973 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103003:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103009:	83 c4 08             	add    $0x8,%esp
8010300c:	56                   	push   %esi
8010300d:	50                   	push   %eax
8010300e:	e8 f4 07 00 00       	call   80103807 <sleep>
80103013:	83 c4 10             	add    $0x10,%esp
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103016:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
8010301c:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103022:	05 00 02 00 00       	add    $0x200,%eax
80103027:	39 c2                	cmp    %eax,%edx
80103029:	75 2d                	jne    80103058 <pipewrite+0xa8>
      if(p->readopen == 0 || myproc()->killed){
8010302b:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103032:	74 0b                	je     8010303f <pipewrite+0x8f>
80103034:	e8 e1 02 00 00       	call   8010331a <myproc>
80103039:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
8010303d:	74 b5                	je     80102ff4 <pipewrite+0x44>
        release(&p->lock);
8010303f:	83 ec 0c             	sub    $0xc,%esp
80103042:	53                   	push   %ebx
80103043:	e8 cf 0d 00 00       	call   80103e17 <release>
        return -1;
80103048:	83 c4 10             	add    $0x10,%esp
8010304b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103050:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103053:	5b                   	pop    %ebx
80103054:	5e                   	pop    %esi
80103055:	5f                   	pop    %edi
80103056:	5d                   	pop    %ebp
80103057:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103058:	8d 42 01             	lea    0x1(%edx),%eax
8010305b:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103061:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103067:	8b 45 0c             	mov    0xc(%ebp),%eax
8010306a:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010306e:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103072:	83 c7 01             	add    $0x1,%edi
80103075:	e9 56 ff ff ff       	jmp    80102fd0 <pipewrite+0x20>

8010307a <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010307a:	f3 0f 1e fb          	endbr32 
8010307e:	55                   	push   %ebp
8010307f:	89 e5                	mov    %esp,%ebp
80103081:	57                   	push   %edi
80103082:	56                   	push   %esi
80103083:	53                   	push   %ebx
80103084:	83 ec 18             	sub    $0x18,%esp
80103087:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
8010308a:	89 df                	mov    %ebx,%edi
8010308c:	53                   	push   %ebx
8010308d:	e8 1c 0d 00 00       	call   80103dae <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103092:	83 c4 10             	add    $0x10,%esp
80103095:	eb 13                	jmp    801030aa <piperead+0x30>
    if(myproc()->killed){
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103097:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010309d:	83 ec 08             	sub    $0x8,%esp
801030a0:	57                   	push   %edi
801030a1:	50                   	push   %eax
801030a2:	e8 60 07 00 00       	call   80103807 <sleep>
801030a7:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030aa:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030b0:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030b6:	75 28                	jne    801030e0 <piperead+0x66>
801030b8:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030be:	85 f6                	test   %esi,%esi
801030c0:	74 23                	je     801030e5 <piperead+0x6b>
    if(myproc()->killed){
801030c2:	e8 53 02 00 00       	call   8010331a <myproc>
801030c7:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
801030cb:	74 ca                	je     80103097 <piperead+0x1d>
      release(&p->lock);
801030cd:	83 ec 0c             	sub    $0xc,%esp
801030d0:	53                   	push   %ebx
801030d1:	e8 41 0d 00 00       	call   80103e17 <release>
      return -1;
801030d6:	83 c4 10             	add    $0x10,%esp
801030d9:	be ff ff ff ff       	mov    $0xffffffff,%esi
801030de:	eb 50                	jmp    80103130 <piperead+0xb6>
801030e0:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030e5:	3b 75 10             	cmp    0x10(%ebp),%esi
801030e8:	7d 2c                	jge    80103116 <piperead+0x9c>
    if(p->nread == p->nwrite)
801030ea:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801030f0:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801030f6:	74 1e                	je     80103116 <piperead+0x9c>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801030f8:	8d 50 01             	lea    0x1(%eax),%edx
801030fb:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103101:	25 ff 01 00 00       	and    $0x1ff,%eax
80103106:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010310b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010310e:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103111:	83 c6 01             	add    $0x1,%esi
80103114:	eb cf                	jmp    801030e5 <piperead+0x6b>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103116:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010311c:	83 ec 0c             	sub    $0xc,%esp
8010311f:	50                   	push   %eax
80103120:	e8 4e 08 00 00       	call   80103973 <wakeup>
  release(&p->lock);
80103125:	89 1c 24             	mov    %ebx,(%esp)
80103128:	e8 ea 0c 00 00       	call   80103e17 <release>
  return i;
8010312d:	83 c4 10             	add    $0x10,%esp
}
80103130:	89 f0                	mov    %esi,%eax
80103132:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103135:	5b                   	pop    %ebx
80103136:	5e                   	pop    %esi
80103137:	5f                   	pop    %edi
80103138:	5d                   	pop    %ebp
80103139:	c3                   	ret    

8010313a <wakeup1>:
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010313a:	ba 14 a6 10 80       	mov    $0x8010a614,%edx
8010313f:	eb 0a                	jmp    8010314b <wakeup1+0x11>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
80103141:	c7 42 10 03 00 00 00 	movl   $0x3,0x10(%edx)
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103148:	83 ea 80             	sub    $0xffffff80,%edx
8010314b:	81 fa 14 c6 10 80    	cmp    $0x8010c614,%edx
80103151:	73 0d                	jae    80103160 <wakeup1+0x26>
    if(p->state == SLEEPING && p->chan == chan)
80103153:	83 7a 10 02          	cmpl   $0x2,0x10(%edx)
80103157:	75 ef                	jne    80103148 <wakeup1+0xe>
80103159:	39 42 24             	cmp    %eax,0x24(%edx)
8010315c:	75 ea                	jne    80103148 <wakeup1+0xe>
8010315e:	eb e1                	jmp    80103141 <wakeup1+0x7>
}
80103160:	c3                   	ret    

80103161 <allocproc>:
{
80103161:	55                   	push   %ebp
80103162:	89 e5                	mov    %esp,%ebp
80103164:	53                   	push   %ebx
80103165:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103168:	68 e0 a5 10 80       	push   $0x8010a5e0
8010316d:	e8 3c 0c 00 00       	call   80103dae <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103172:	83 c4 10             	add    $0x10,%esp
80103175:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
8010317a:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
80103180:	73 0b                	jae    8010318d <allocproc+0x2c>
    if(p->state == UNUSED) {
80103182:	83 7b 10 00          	cmpl   $0x0,0x10(%ebx)
80103186:	74 0c                	je     80103194 <allocproc+0x33>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103188:	83 eb 80             	sub    $0xffffff80,%ebx
8010318b:	eb ed                	jmp    8010317a <allocproc+0x19>
  int found = 0;
8010318d:	b8 00 00 00 00       	mov    $0x0,%eax
80103192:	eb 05                	jmp    80103199 <allocproc+0x38>
      found = 1;
80103194:	b8 01 00 00 00       	mov    $0x1,%eax
  if (!found) {
80103199:	85 c0                	test   %eax,%eax
8010319b:	74 77                	je     80103214 <allocproc+0xb3>
  p->state = EMBRYO;
8010319d:	c7 43 10 01 00 00 00 	movl   $0x1,0x10(%ebx)
  p->pid = nextpid++;
801031a4:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801031a9:	8d 50 01             	lea    0x1(%eax),%edx
801031ac:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801031b2:	89 43 14             	mov    %eax,0x14(%ebx)
  release(&ptable.lock);
801031b5:	83 ec 0c             	sub    $0xc,%esp
801031b8:	68 e0 a5 10 80       	push   $0x8010a5e0
801031bd:	e8 55 0c 00 00       	call   80103e17 <release>
  if((p->kstack = kalloc()) == 0){
801031c2:	e8 c9 ef ff ff       	call   80102190 <kalloc>
801031c7:	89 43 0c             	mov    %eax,0xc(%ebx)
801031ca:	83 c4 10             	add    $0x10,%esp
801031cd:	85 c0                	test   %eax,%eax
801031cf:	74 5a                	je     8010322b <allocproc+0xca>
  sp -= sizeof *p->tf;
801031d1:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031d7:	89 53 1c             	mov    %edx,0x1c(%ebx)
  *(uint*)sp = (uint)trapret;
801031da:	c7 80 b0 0f 00 00 4a 	movl   $0x80104f4a,0xfb0(%eax)
801031e1:	4f 10 80 
  sp -= sizeof *p->context;
801031e4:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801031e9:	89 43 20             	mov    %eax,0x20(%ebx)
  memset(p->context, 0, sizeof *p->context);
801031ec:	83 ec 04             	sub    $0x4,%esp
801031ef:	6a 14                	push   $0x14
801031f1:	6a 00                	push   $0x0
801031f3:	50                   	push   %eax
801031f4:	e8 69 0c 00 00       	call   80103e62 <memset>
  p->context->eip = (uint)forkret;
801031f9:	8b 43 20             	mov    0x20(%ebx),%eax
801031fc:	c7 40 10 36 32 10 80 	movl   $0x80103236,0x10(%eax)
  p->start_ticks = ticks;
80103203:	a1 80 55 11 80       	mov    0x80115580,%eax
80103208:	89 03                	mov    %eax,(%ebx)
  return p;
8010320a:	83 c4 10             	add    $0x10,%esp
}
8010320d:	89 d8                	mov    %ebx,%eax
8010320f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103212:	c9                   	leave  
80103213:	c3                   	ret    
    release(&ptable.lock);
80103214:	83 ec 0c             	sub    $0xc,%esp
80103217:	68 e0 a5 10 80       	push   $0x8010a5e0
8010321c:	e8 f6 0b 00 00       	call   80103e17 <release>
    return 0;
80103221:	83 c4 10             	add    $0x10,%esp
80103224:	bb 00 00 00 00       	mov    $0x0,%ebx
80103229:	eb e2                	jmp    8010320d <allocproc+0xac>
    p->state = UNUSED;
8010322b:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
    return 0;
80103232:	89 c3                	mov    %eax,%ebx
80103234:	eb d7                	jmp    8010320d <allocproc+0xac>

80103236 <forkret>:
{
80103236:	f3 0f 1e fb          	endbr32 
8010323a:	55                   	push   %ebp
8010323b:	89 e5                	mov    %esp,%ebp
8010323d:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103240:	68 e0 a5 10 80       	push   $0x8010a5e0
80103245:	e8 cd 0b 00 00       	call   80103e17 <release>
  if (first) {
8010324a:	83 c4 10             	add    $0x10,%esp
8010324d:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103254:	75 02                	jne    80103258 <forkret+0x22>
}
80103256:	c9                   	leave  
80103257:	c3                   	ret    
    first = 0;
80103258:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010325f:	00 00 00 
    iinit(ROOTDEV);
80103262:	83 ec 0c             	sub    $0xc,%esp
80103265:	6a 01                	push   $0x1
80103267:	e8 f7 e0 ff ff       	call   80101363 <iinit>
    initlog(ROOTDEV);
8010326c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103273:	e8 c8 f5 ff ff       	call   80102840 <initlog>
80103278:	83 c4 10             	add    $0x10,%esp
}
8010327b:	eb d9                	jmp    80103256 <forkret+0x20>

8010327d <pinit>:
{
8010327d:	f3 0f 1e fb          	endbr32 
80103281:	55                   	push   %ebp
80103282:	89 e5                	mov    %esp,%ebp
80103284:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103287:	68 e0 6b 10 80       	push   $0x80106be0
8010328c:	68 e0 a5 10 80       	push   $0x8010a5e0
80103291:	e8 c8 09 00 00       	call   80103c5e <initlock>
}
80103296:	83 c4 10             	add    $0x10,%esp
80103299:	c9                   	leave  
8010329a:	c3                   	ret    

8010329b <mycpu>:
{
8010329b:	f3 0f 1e fb          	endbr32 
8010329f:	55                   	push   %ebp
801032a0:	89 e5                	mov    %esp,%ebp
801032a2:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032a5:	9c                   	pushf  
801032a6:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032a7:	f6 c4 02             	test   $0x2,%ah
801032aa:	75 28                	jne    801032d4 <mycpu+0x39>
  apicid = lapicid();
801032ac:	e8 a6 f1 ff ff       	call   80102457 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032b1:	ba 00 00 00 00       	mov    $0x0,%edx
801032b6:	39 15 60 4d 11 80    	cmp    %edx,0x80114d60
801032bc:	7e 30                	jle    801032ee <mycpu+0x53>
    if (cpus[i].apicid == apicid) {
801032be:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032c4:	0f b6 89 e0 47 11 80 	movzbl -0x7feeb820(%ecx),%ecx
801032cb:	39 c1                	cmp    %eax,%ecx
801032cd:	74 12                	je     801032e1 <mycpu+0x46>
  for (i = 0; i < ncpu; ++i) {
801032cf:	83 c2 01             	add    $0x1,%edx
801032d2:	eb e2                	jmp    801032b6 <mycpu+0x1b>
    panic("mycpu called with interrupts enabled\n");
801032d4:	83 ec 0c             	sub    $0xc,%esp
801032d7:	68 cc 6c 10 80       	push   $0x80106ccc
801032dc:	e8 7b d0 ff ff       	call   8010035c <panic>
      return &cpus[i];
801032e1:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801032e7:	05 e0 47 11 80       	add    $0x801147e0,%eax
}
801032ec:	c9                   	leave  
801032ed:	c3                   	ret    
  panic("unknown apicid\n");
801032ee:	83 ec 0c             	sub    $0xc,%esp
801032f1:	68 e7 6b 10 80       	push   $0x80106be7
801032f6:	e8 61 d0 ff ff       	call   8010035c <panic>

801032fb <cpuid>:
cpuid() {
801032fb:	f3 0f 1e fb          	endbr32 
801032ff:	55                   	push   %ebp
80103300:	89 e5                	mov    %esp,%ebp
80103302:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103305:	e8 91 ff ff ff       	call   8010329b <mycpu>
8010330a:	2d e0 47 11 80       	sub    $0x801147e0,%eax
8010330f:	c1 f8 04             	sar    $0x4,%eax
80103312:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103318:	c9                   	leave  
80103319:	c3                   	ret    

8010331a <myproc>:
myproc(void) {
8010331a:	f3 0f 1e fb          	endbr32 
8010331e:	55                   	push   %ebp
8010331f:	89 e5                	mov    %esp,%ebp
80103321:	53                   	push   %ebx
80103322:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103325:	e8 9b 09 00 00       	call   80103cc5 <pushcli>
  c = mycpu();
8010332a:	e8 6c ff ff ff       	call   8010329b <mycpu>
  p = c->proc;
8010332f:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103335:	e8 cc 09 00 00       	call   80103d06 <popcli>
}
8010333a:	89 d8                	mov    %ebx,%eax
8010333c:	83 c4 04             	add    $0x4,%esp
8010333f:	5b                   	pop    %ebx
80103340:	5d                   	pop    %ebp
80103341:	c3                   	ret    

80103342 <userinit>:
{
80103342:	f3 0f 1e fb          	endbr32 
80103346:	55                   	push   %ebp
80103347:	89 e5                	mov    %esp,%ebp
80103349:	53                   	push   %ebx
8010334a:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010334d:	e8 0f fe ff ff       	call   80103161 <allocproc>
80103352:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103354:	a3 c0 a5 10 80       	mov    %eax,0x8010a5c0
  if((p->pgdir = setupkvm()) == 0)
80103359:	e8 e8 30 00 00       	call   80106446 <setupkvm>
8010335e:	89 43 08             	mov    %eax,0x8(%ebx)
80103361:	85 c0                	test   %eax,%eax
80103363:	0f 84 b9 00 00 00    	je     80103422 <userinit+0xe0>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103369:	83 ec 04             	sub    $0x4,%esp
8010336c:	68 2c 00 00 00       	push   $0x2c
80103371:	68 60 a4 10 80       	push   $0x8010a460
80103376:	50                   	push   %eax
80103377:	e8 c7 2d 00 00       	call   80106143 <inituvm>
  p->sz = PGSIZE;
8010337c:	c7 43 04 00 10 00 00 	movl   $0x1000,0x4(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103383:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103386:	83 c4 0c             	add    $0xc,%esp
80103389:	6a 4c                	push   $0x4c
8010338b:	6a 00                	push   $0x0
8010338d:	50                   	push   %eax
8010338e:	e8 cf 0a 00 00       	call   80103e62 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103393:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103396:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010339c:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010339f:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033a5:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033a8:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033ac:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033b0:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033b3:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033b7:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033bb:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033be:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033c5:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033c8:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033cf:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033d2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033d9:	8d 43 70             	lea    0x70(%ebx),%eax
801033dc:	83 c4 0c             	add    $0xc,%esp
801033df:	6a 10                	push   $0x10
801033e1:	68 10 6c 10 80       	push   $0x80106c10
801033e6:	50                   	push   %eax
801033e7:	e8 f6 0b 00 00       	call   80103fe2 <safestrcpy>
  p->cwd = namei("/");
801033ec:	c7 04 24 19 6c 10 80 	movl   $0x80106c19,(%esp)
801033f3:	e8 95 e8 ff ff       	call   80101c8d <namei>
801033f8:	89 43 6c             	mov    %eax,0x6c(%ebx)
  acquire(&ptable.lock);
801033fb:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103402:	e8 a7 09 00 00       	call   80103dae <acquire>
  p->state = RUNNABLE;
80103407:	c7 43 10 03 00 00 00 	movl   $0x3,0x10(%ebx)
  release(&ptable.lock);
8010340e:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103415:	e8 fd 09 00 00       	call   80103e17 <release>
}
8010341a:	83 c4 10             	add    $0x10,%esp
8010341d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103420:	c9                   	leave  
80103421:	c3                   	ret    
    panic("userinit: out of memory?");
80103422:	83 ec 0c             	sub    $0xc,%esp
80103425:	68 f7 6b 10 80       	push   $0x80106bf7
8010342a:	e8 2d cf ff ff       	call   8010035c <panic>

8010342f <growproc>:
{
8010342f:	f3 0f 1e fb          	endbr32 
80103433:	55                   	push   %ebp
80103434:	89 e5                	mov    %esp,%ebp
80103436:	56                   	push   %esi
80103437:	53                   	push   %ebx
80103438:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010343b:	e8 da fe ff ff       	call   8010331a <myproc>
80103440:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103442:	8b 40 04             	mov    0x4(%eax),%eax
  if(n > 0){
80103445:	85 f6                	test   %esi,%esi
80103447:	7f 1d                	jg     80103466 <growproc+0x37>
  } else if(n < 0){
80103449:	78 38                	js     80103483 <growproc+0x54>
  curproc->sz = sz;
8010344b:	89 43 04             	mov    %eax,0x4(%ebx)
  switchuvm(curproc);
8010344e:	83 ec 0c             	sub    $0xc,%esp
80103451:	53                   	push   %ebx
80103452:	e8 d0 2b 00 00       	call   80106027 <switchuvm>
  return 0;
80103457:	83 c4 10             	add    $0x10,%esp
8010345a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010345f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103462:	5b                   	pop    %ebx
80103463:	5e                   	pop    %esi
80103464:	5d                   	pop    %ebp
80103465:	c3                   	ret    
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103466:	83 ec 04             	sub    $0x4,%esp
80103469:	01 c6                	add    %eax,%esi
8010346b:	56                   	push   %esi
8010346c:	50                   	push   %eax
8010346d:	ff 73 08             	pushl  0x8(%ebx)
80103470:	e8 70 2e 00 00       	call   801062e5 <allocuvm>
80103475:	83 c4 10             	add    $0x10,%esp
80103478:	85 c0                	test   %eax,%eax
8010347a:	75 cf                	jne    8010344b <growproc+0x1c>
      return -1;
8010347c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103481:	eb dc                	jmp    8010345f <growproc+0x30>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103483:	83 ec 04             	sub    $0x4,%esp
80103486:	01 c6                	add    %eax,%esi
80103488:	56                   	push   %esi
80103489:	50                   	push   %eax
8010348a:	ff 73 08             	pushl  0x8(%ebx)
8010348d:	e8 bd 2d 00 00       	call   8010624f <deallocuvm>
80103492:	83 c4 10             	add    $0x10,%esp
80103495:	85 c0                	test   %eax,%eax
80103497:	75 b2                	jne    8010344b <growproc+0x1c>
      return -1;
80103499:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010349e:	eb bf                	jmp    8010345f <growproc+0x30>

801034a0 <fork>:
{
801034a0:	f3 0f 1e fb          	endbr32 
801034a4:	55                   	push   %ebp
801034a5:	89 e5                	mov    %esp,%ebp
801034a7:	57                   	push   %edi
801034a8:	56                   	push   %esi
801034a9:	53                   	push   %ebx
801034aa:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034ad:	e8 68 fe ff ff       	call   8010331a <myproc>
801034b2:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034b4:	e8 a8 fc ff ff       	call   80103161 <allocproc>
801034b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034bc:	85 c0                	test   %eax,%eax
801034be:	0f 84 e3 00 00 00    	je     801035a7 <fork+0x107>
801034c4:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801034c6:	83 ec 08             	sub    $0x8,%esp
801034c9:	ff 73 04             	pushl  0x4(%ebx)
801034cc:	ff 73 08             	pushl  0x8(%ebx)
801034cf:	e8 2f 30 00 00       	call   80106503 <copyuvm>
801034d4:	89 47 08             	mov    %eax,0x8(%edi)
801034d7:	83 c4 10             	add    $0x10,%esp
801034da:	85 c0                	test   %eax,%eax
801034dc:	74 2c                	je     8010350a <fork+0x6a>
  np->sz = curproc->sz;
801034de:	8b 43 04             	mov    0x4(%ebx),%eax
801034e1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034e4:	89 41 04             	mov    %eax,0x4(%ecx)
  np->parent = curproc;
801034e7:	89 c8                	mov    %ecx,%eax
801034e9:	89 59 18             	mov    %ebx,0x18(%ecx)
  *np->tf = *curproc->tf;
801034ec:	8b 73 1c             	mov    0x1c(%ebx),%esi
801034ef:	8b 79 1c             	mov    0x1c(%ecx),%edi
801034f2:	b9 13 00 00 00       	mov    $0x13,%ecx
801034f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801034f9:	8b 40 1c             	mov    0x1c(%eax),%eax
801034fc:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103503:	be 00 00 00 00       	mov    $0x0,%esi
80103508:	eb 3c                	jmp    80103546 <fork+0xa6>
    kfree(np->kstack);
8010350a:	83 ec 0c             	sub    $0xc,%esp
8010350d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103510:	ff 73 0c             	pushl  0xc(%ebx)
80103513:	e8 51 eb ff ff       	call   80102069 <kfree>
    np->kstack = 0;
80103518:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    np->state = UNUSED;
8010351f:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
    return -1;
80103526:	83 c4 10             	add    $0x10,%esp
80103529:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010352e:	eb 6f                	jmp    8010359f <fork+0xff>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103530:	83 ec 0c             	sub    $0xc,%esp
80103533:	50                   	push   %eax
80103534:	e8 b3 d7 ff ff       	call   80100cec <filedup>
80103539:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010353c:	89 44 b2 2c          	mov    %eax,0x2c(%edx,%esi,4)
80103540:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NOFILE; i++)
80103543:	83 c6 01             	add    $0x1,%esi
80103546:	83 fe 0f             	cmp    $0xf,%esi
80103549:	7f 0a                	jg     80103555 <fork+0xb5>
    if(curproc->ofile[i])
8010354b:	8b 44 b3 2c          	mov    0x2c(%ebx,%esi,4),%eax
8010354f:	85 c0                	test   %eax,%eax
80103551:	75 dd                	jne    80103530 <fork+0x90>
80103553:	eb ee                	jmp    80103543 <fork+0xa3>
  np->cwd = idup(curproc->cwd);
80103555:	83 ec 0c             	sub    $0xc,%esp
80103558:	ff 73 6c             	pushl  0x6c(%ebx)
8010355b:	e8 74 e0 ff ff       	call   801015d4 <idup>
80103560:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103563:	89 47 6c             	mov    %eax,0x6c(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103566:	83 c3 70             	add    $0x70,%ebx
80103569:	8d 47 70             	lea    0x70(%edi),%eax
8010356c:	83 c4 0c             	add    $0xc,%esp
8010356f:	6a 10                	push   $0x10
80103571:	53                   	push   %ebx
80103572:	50                   	push   %eax
80103573:	e8 6a 0a 00 00       	call   80103fe2 <safestrcpy>
  pid = np->pid;
80103578:	8b 5f 14             	mov    0x14(%edi),%ebx
  acquire(&ptable.lock);
8010357b:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103582:	e8 27 08 00 00       	call   80103dae <acquire>
  np->state = RUNNABLE;
80103587:	c7 47 10 03 00 00 00 	movl   $0x3,0x10(%edi)
  release(&ptable.lock);
8010358e:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103595:	e8 7d 08 00 00       	call   80103e17 <release>
  return pid;
8010359a:	89 d8                	mov    %ebx,%eax
8010359c:	83 c4 10             	add    $0x10,%esp
}
8010359f:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035a2:	5b                   	pop    %ebx
801035a3:	5e                   	pop    %esi
801035a4:	5f                   	pop    %edi
801035a5:	5d                   	pop    %ebp
801035a6:	c3                   	ret    
    return -1;
801035a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035ac:	eb f1                	jmp    8010359f <fork+0xff>

801035ae <scheduler>:
{
801035ae:	f3 0f 1e fb          	endbr32 
801035b2:	55                   	push   %ebp
801035b3:	89 e5                	mov    %esp,%ebp
801035b5:	57                   	push   %edi
801035b6:	56                   	push   %esi
801035b7:	53                   	push   %ebx
801035b8:	83 ec 0c             	sub    $0xc,%esp
  struct cpu *c = mycpu();
801035bb:	e8 db fc ff ff       	call   8010329b <mycpu>
801035c0:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035c2:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035c9:	00 00 00 
801035cc:	eb 65                	jmp    80103633 <scheduler+0x85>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035ce:	83 eb 80             	sub    $0xffffff80,%ebx
801035d1:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
801035d7:	73 44                	jae    8010361d <scheduler+0x6f>
      if(p->state != RUNNABLE)
801035d9:	83 7b 10 03          	cmpl   $0x3,0x10(%ebx)
801035dd:	75 ef                	jne    801035ce <scheduler+0x20>
      c->proc = p;
801035df:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035e5:	83 ec 0c             	sub    $0xc,%esp
801035e8:	53                   	push   %ebx
801035e9:	e8 39 2a 00 00       	call   80106027 <switchuvm>
      p->state = RUNNING;
801035ee:	c7 43 10 04 00 00 00 	movl   $0x4,0x10(%ebx)
      swtch(&(c->scheduler), p->context);
801035f5:	83 c4 08             	add    $0x8,%esp
801035f8:	ff 73 20             	pushl  0x20(%ebx)
801035fb:	8d 46 04             	lea    0x4(%esi),%eax
801035fe:	50                   	push   %eax
801035ff:	e8 3b 0a 00 00       	call   8010403f <swtch>
      switchkvm();
80103604:	e8 0c 2a 00 00       	call   80106015 <switchkvm>
      c->proc = 0;
80103609:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103610:	00 00 00 
80103613:	83 c4 10             	add    $0x10,%esp
      idle = 0;  // not idle this timeslice
80103616:	bf 00 00 00 00       	mov    $0x0,%edi
8010361b:	eb b1                	jmp    801035ce <scheduler+0x20>
    release(&ptable.lock);
8010361d:	83 ec 0c             	sub    $0xc,%esp
80103620:	68 e0 a5 10 80       	push   $0x8010a5e0
80103625:	e8 ed 07 00 00       	call   80103e17 <release>
    if (idle) {
8010362a:	83 c4 10             	add    $0x10,%esp
8010362d:	85 ff                	test   %edi,%edi
8010362f:	74 02                	je     80103633 <scheduler+0x85>
  asm volatile("sti");
80103631:	fb                   	sti    

// hlt() added by Noah Zentzis, Fall 2016.
static inline void
hlt()
{
  asm volatile("hlt");
80103632:	f4                   	hlt    
80103633:	fb                   	sti    
    acquire(&ptable.lock);
80103634:	83 ec 0c             	sub    $0xc,%esp
80103637:	68 e0 a5 10 80       	push   $0x8010a5e0
8010363c:	e8 6d 07 00 00       	call   80103dae <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103641:	83 c4 10             	add    $0x10,%esp
    idle = 1;  // assume idle unless we schedule a process
80103644:	bf 01 00 00 00       	mov    $0x1,%edi
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103649:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
8010364e:	eb 81                	jmp    801035d1 <scheduler+0x23>

80103650 <sched>:
{
80103650:	f3 0f 1e fb          	endbr32 
80103654:	55                   	push   %ebp
80103655:	89 e5                	mov    %esp,%ebp
80103657:	56                   	push   %esi
80103658:	53                   	push   %ebx
  struct proc *p = myproc();
80103659:	e8 bc fc ff ff       	call   8010331a <myproc>
8010365e:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103660:	83 ec 0c             	sub    $0xc,%esp
80103663:	68 e0 a5 10 80       	push   $0x8010a5e0
80103668:	e8 fd 06 00 00       	call   80103d6a <holding>
8010366d:	83 c4 10             	add    $0x10,%esp
80103670:	85 c0                	test   %eax,%eax
80103672:	74 4f                	je     801036c3 <sched+0x73>
  if(mycpu()->ncli != 1)
80103674:	e8 22 fc ff ff       	call   8010329b <mycpu>
80103679:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103680:	75 4e                	jne    801036d0 <sched+0x80>
  if(p->state == RUNNING)
80103682:	83 7b 10 04          	cmpl   $0x4,0x10(%ebx)
80103686:	74 55                	je     801036dd <sched+0x8d>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103688:	9c                   	pushf  
80103689:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010368a:	f6 c4 02             	test   $0x2,%ah
8010368d:	75 5b                	jne    801036ea <sched+0x9a>
  intena = mycpu()->intena;
8010368f:	e8 07 fc ff ff       	call   8010329b <mycpu>
80103694:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010369a:	e8 fc fb ff ff       	call   8010329b <mycpu>
8010369f:	83 ec 08             	sub    $0x8,%esp
801036a2:	ff 70 04             	pushl  0x4(%eax)
801036a5:	83 c3 20             	add    $0x20,%ebx
801036a8:	53                   	push   %ebx
801036a9:	e8 91 09 00 00       	call   8010403f <swtch>
  mycpu()->intena = intena;
801036ae:	e8 e8 fb ff ff       	call   8010329b <mycpu>
801036b3:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801036b9:	83 c4 10             	add    $0x10,%esp
801036bc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036bf:	5b                   	pop    %ebx
801036c0:	5e                   	pop    %esi
801036c1:	5d                   	pop    %ebp
801036c2:	c3                   	ret    
    panic("sched ptable.lock");
801036c3:	83 ec 0c             	sub    $0xc,%esp
801036c6:	68 1b 6c 10 80       	push   $0x80106c1b
801036cb:	e8 8c cc ff ff       	call   8010035c <panic>
    panic("sched locks");
801036d0:	83 ec 0c             	sub    $0xc,%esp
801036d3:	68 2d 6c 10 80       	push   $0x80106c2d
801036d8:	e8 7f cc ff ff       	call   8010035c <panic>
    panic("sched running");
801036dd:	83 ec 0c             	sub    $0xc,%esp
801036e0:	68 39 6c 10 80       	push   $0x80106c39
801036e5:	e8 72 cc ff ff       	call   8010035c <panic>
    panic("sched interruptible");
801036ea:	83 ec 0c             	sub    $0xc,%esp
801036ed:	68 47 6c 10 80       	push   $0x80106c47
801036f2:	e8 65 cc ff ff       	call   8010035c <panic>

801036f7 <exit>:
{
801036f7:	f3 0f 1e fb          	endbr32 
801036fb:	55                   	push   %ebp
801036fc:	89 e5                	mov    %esp,%ebp
801036fe:	56                   	push   %esi
801036ff:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103700:	e8 15 fc ff ff       	call   8010331a <myproc>
  if(curproc == initproc)
80103705:	39 05 c0 a5 10 80    	cmp    %eax,0x8010a5c0
8010370b:	74 09                	je     80103716 <exit+0x1f>
8010370d:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
8010370f:	bb 00 00 00 00       	mov    $0x0,%ebx
80103714:	eb 24                	jmp    8010373a <exit+0x43>
    panic("init exiting");
80103716:	83 ec 0c             	sub    $0xc,%esp
80103719:	68 5b 6c 10 80       	push   $0x80106c5b
8010371e:	e8 39 cc ff ff       	call   8010035c <panic>
      fileclose(curproc->ofile[fd]);
80103723:	83 ec 0c             	sub    $0xc,%esp
80103726:	50                   	push   %eax
80103727:	e8 09 d6 ff ff       	call   80100d35 <fileclose>
      curproc->ofile[fd] = 0;
8010372c:	c7 44 9e 2c 00 00 00 	movl   $0x0,0x2c(%esi,%ebx,4)
80103733:	00 
80103734:	83 c4 10             	add    $0x10,%esp
  for(fd = 0; fd < NOFILE; fd++){
80103737:	83 c3 01             	add    $0x1,%ebx
8010373a:	83 fb 0f             	cmp    $0xf,%ebx
8010373d:	7f 0a                	jg     80103749 <exit+0x52>
    if(curproc->ofile[fd]){
8010373f:	8b 44 9e 2c          	mov    0x2c(%esi,%ebx,4),%eax
80103743:	85 c0                	test   %eax,%eax
80103745:	75 dc                	jne    80103723 <exit+0x2c>
80103747:	eb ee                	jmp    80103737 <exit+0x40>
  begin_op();
80103749:	e8 3f f1 ff ff       	call   8010288d <begin_op>
  iput(curproc->cwd);
8010374e:	83 ec 0c             	sub    $0xc,%esp
80103751:	ff 76 6c             	pushl  0x6c(%esi)
80103754:	e8 be df ff ff       	call   80101717 <iput>
  end_op();
80103759:	e8 ad f1 ff ff       	call   8010290b <end_op>
  curproc->cwd = 0;
8010375e:	c7 46 6c 00 00 00 00 	movl   $0x0,0x6c(%esi)
  acquire(&ptable.lock);
80103765:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
8010376c:	e8 3d 06 00 00       	call   80103dae <acquire>
  wakeup1(curproc->parent);
80103771:	8b 46 18             	mov    0x18(%esi),%eax
80103774:	e8 c1 f9 ff ff       	call   8010313a <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103779:	83 c4 10             	add    $0x10,%esp
8010377c:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80103781:	eb 03                	jmp    80103786 <exit+0x8f>
80103783:	83 eb 80             	sub    $0xffffff80,%ebx
80103786:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
8010378c:	73 1a                	jae    801037a8 <exit+0xb1>
    if(p->parent == curproc){
8010378e:	39 73 18             	cmp    %esi,0x18(%ebx)
80103791:	75 f0                	jne    80103783 <exit+0x8c>
      p->parent = initproc;
80103793:	a1 c0 a5 10 80       	mov    0x8010a5c0,%eax
80103798:	89 43 18             	mov    %eax,0x18(%ebx)
      if(p->state == ZOMBIE)
8010379b:	83 7b 10 05          	cmpl   $0x5,0x10(%ebx)
8010379f:	75 e2                	jne    80103783 <exit+0x8c>
        wakeup1(initproc);
801037a1:	e8 94 f9 ff ff       	call   8010313a <wakeup1>
801037a6:	eb db                	jmp    80103783 <exit+0x8c>
  curproc->state = ZOMBIE;
801037a8:	c7 46 10 05 00 00 00 	movl   $0x5,0x10(%esi)
  curproc->sz = 0;
801037af:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
  sched();
801037b6:	e8 95 fe ff ff       	call   80103650 <sched>
  panic("zombie exit");
801037bb:	83 ec 0c             	sub    $0xc,%esp
801037be:	68 68 6c 10 80       	push   $0x80106c68
801037c3:	e8 94 cb ff ff       	call   8010035c <panic>

801037c8 <yield>:
{
801037c8:	f3 0f 1e fb          	endbr32 
801037cc:	55                   	push   %ebp
801037cd:	89 e5                	mov    %esp,%ebp
801037cf:	53                   	push   %ebx
801037d0:	83 ec 04             	sub    $0x4,%esp
  struct proc *curproc = myproc();
801037d3:	e8 42 fb ff ff       	call   8010331a <myproc>
801037d8:	89 c3                	mov    %eax,%ebx
  acquire(&ptable.lock);  //DOC: yieldlock
801037da:	83 ec 0c             	sub    $0xc,%esp
801037dd:	68 e0 a5 10 80       	push   $0x8010a5e0
801037e2:	e8 c7 05 00 00       	call   80103dae <acquire>
  curproc->state = RUNNABLE;
801037e7:	c7 43 10 03 00 00 00 	movl   $0x3,0x10(%ebx)
  sched();
801037ee:	e8 5d fe ff ff       	call   80103650 <sched>
  release(&ptable.lock);
801037f3:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
801037fa:	e8 18 06 00 00       	call   80103e17 <release>
}
801037ff:	83 c4 10             	add    $0x10,%esp
80103802:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103805:	c9                   	leave  
80103806:	c3                   	ret    

80103807 <sleep>:
{
80103807:	f3 0f 1e fb          	endbr32 
8010380b:	55                   	push   %ebp
8010380c:	89 e5                	mov    %esp,%ebp
8010380e:	56                   	push   %esi
8010380f:	53                   	push   %ebx
80103810:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct proc *p = myproc();
80103813:	e8 02 fb ff ff       	call   8010331a <myproc>
  if(p == 0)
80103818:	85 c0                	test   %eax,%eax
8010381a:	74 72                	je     8010388e <sleep+0x87>
8010381c:	89 c3                	mov    %eax,%ebx
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010381e:	81 fe e0 a5 10 80    	cmp    $0x8010a5e0,%esi
80103824:	74 20                	je     80103846 <sleep+0x3f>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103826:	83 ec 0c             	sub    $0xc,%esp
80103829:	68 e0 a5 10 80       	push   $0x8010a5e0
8010382e:	e8 7b 05 00 00       	call   80103dae <acquire>
    if (lk) release(lk);
80103833:	83 c4 10             	add    $0x10,%esp
80103836:	85 f6                	test   %esi,%esi
80103838:	74 0c                	je     80103846 <sleep+0x3f>
8010383a:	83 ec 0c             	sub    $0xc,%esp
8010383d:	56                   	push   %esi
8010383e:	e8 d4 05 00 00       	call   80103e17 <release>
80103843:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103846:	8b 45 08             	mov    0x8(%ebp),%eax
80103849:	89 43 24             	mov    %eax,0x24(%ebx)
  p->state = SLEEPING;
8010384c:	c7 43 10 02 00 00 00 	movl   $0x2,0x10(%ebx)
  sched();
80103853:	e8 f8 fd ff ff       	call   80103650 <sched>
  p->chan = 0;
80103858:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010385f:	81 fe e0 a5 10 80    	cmp    $0x8010a5e0,%esi
80103865:	74 20                	je     80103887 <sleep+0x80>
    release(&ptable.lock);
80103867:	83 ec 0c             	sub    $0xc,%esp
8010386a:	68 e0 a5 10 80       	push   $0x8010a5e0
8010386f:	e8 a3 05 00 00       	call   80103e17 <release>
    if (lk) acquire(lk);
80103874:	83 c4 10             	add    $0x10,%esp
80103877:	85 f6                	test   %esi,%esi
80103879:	74 0c                	je     80103887 <sleep+0x80>
8010387b:	83 ec 0c             	sub    $0xc,%esp
8010387e:	56                   	push   %esi
8010387f:	e8 2a 05 00 00       	call   80103dae <acquire>
80103884:	83 c4 10             	add    $0x10,%esp
}
80103887:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010388a:	5b                   	pop    %ebx
8010388b:	5e                   	pop    %esi
8010388c:	5d                   	pop    %ebp
8010388d:	c3                   	ret    
    panic("sleep");
8010388e:	83 ec 0c             	sub    $0xc,%esp
80103891:	68 74 6c 10 80       	push   $0x80106c74
80103896:	e8 c1 ca ff ff       	call   8010035c <panic>

8010389b <wait>:
{
8010389b:	f3 0f 1e fb          	endbr32 
8010389f:	55                   	push   %ebp
801038a0:	89 e5                	mov    %esp,%ebp
801038a2:	56                   	push   %esi
801038a3:	53                   	push   %ebx
  struct proc *curproc = myproc();
801038a4:	e8 71 fa ff ff       	call   8010331a <myproc>
801038a9:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801038ab:	83 ec 0c             	sub    $0xc,%esp
801038ae:	68 e0 a5 10 80       	push   $0x8010a5e0
801038b3:	e8 f6 04 00 00       	call   80103dae <acquire>
801038b8:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801038bb:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038c0:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
801038c5:	eb 5b                	jmp    80103922 <wait+0x87>
        pid = p->pid;
801038c7:	8b 73 14             	mov    0x14(%ebx),%esi
        kfree(p->kstack);
801038ca:	83 ec 0c             	sub    $0xc,%esp
801038cd:	ff 73 0c             	pushl  0xc(%ebx)
801038d0:	e8 94 e7 ff ff       	call   80102069 <kfree>
        p->kstack = 0;
801038d5:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        freevm(p->pgdir);
801038dc:	83 c4 04             	add    $0x4,%esp
801038df:	ff 73 08             	pushl  0x8(%ebx)
801038e2:	e8 eb 2a 00 00       	call   801063d2 <freevm>
        p->pid = 0;
801038e7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->parent = 0;
801038ee:	c7 43 18 00 00 00 00 	movl   $0x0,0x18(%ebx)
        p->name[0] = 0;
801038f5:	c6 43 70 00          	movb   $0x0,0x70(%ebx)
        p->killed = 0;
801038f9:	c7 43 28 00 00 00 00 	movl   $0x0,0x28(%ebx)
        p->state = UNUSED;
80103900:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        release(&ptable.lock);
80103907:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
8010390e:	e8 04 05 00 00       	call   80103e17 <release>
        return pid;
80103913:	89 f0                	mov    %esi,%eax
80103915:	83 c4 10             	add    $0x10,%esp
}
80103918:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010391b:	5b                   	pop    %ebx
8010391c:	5e                   	pop    %esi
8010391d:	5d                   	pop    %ebp
8010391e:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010391f:	83 eb 80             	sub    $0xffffff80,%ebx
80103922:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
80103928:	73 12                	jae    8010393c <wait+0xa1>
      if(p->parent != curproc)
8010392a:	39 73 18             	cmp    %esi,0x18(%ebx)
8010392d:	75 f0                	jne    8010391f <wait+0x84>
      if(p->state == ZOMBIE){
8010392f:	83 7b 10 05          	cmpl   $0x5,0x10(%ebx)
80103933:	74 92                	je     801038c7 <wait+0x2c>
      havekids = 1;
80103935:	b8 01 00 00 00       	mov    $0x1,%eax
8010393a:	eb e3                	jmp    8010391f <wait+0x84>
    if(!havekids || curproc->killed){
8010393c:	85 c0                	test   %eax,%eax
8010393e:	74 06                	je     80103946 <wait+0xab>
80103940:	83 7e 28 00          	cmpl   $0x0,0x28(%esi)
80103944:	74 17                	je     8010395d <wait+0xc2>
      release(&ptable.lock);
80103946:	83 ec 0c             	sub    $0xc,%esp
80103949:	68 e0 a5 10 80       	push   $0x8010a5e0
8010394e:	e8 c4 04 00 00       	call   80103e17 <release>
      return -1;
80103953:	83 c4 10             	add    $0x10,%esp
80103956:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010395b:	eb bb                	jmp    80103918 <wait+0x7d>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
8010395d:	83 ec 08             	sub    $0x8,%esp
80103960:	68 e0 a5 10 80       	push   $0x8010a5e0
80103965:	56                   	push   %esi
80103966:	e8 9c fe ff ff       	call   80103807 <sleep>
    havekids = 0;
8010396b:	83 c4 10             	add    $0x10,%esp
8010396e:	e9 48 ff ff ff       	jmp    801038bb <wait+0x20>

80103973 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103973:	f3 0f 1e fb          	endbr32 
80103977:	55                   	push   %ebp
80103978:	89 e5                	mov    %esp,%ebp
8010397a:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010397d:	68 e0 a5 10 80       	push   $0x8010a5e0
80103982:	e8 27 04 00 00       	call   80103dae <acquire>
  wakeup1(chan);
80103987:	8b 45 08             	mov    0x8(%ebp),%eax
8010398a:	e8 ab f7 ff ff       	call   8010313a <wakeup1>
  release(&ptable.lock);
8010398f:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103996:	e8 7c 04 00 00       	call   80103e17 <release>
}
8010399b:	83 c4 10             	add    $0x10,%esp
8010399e:	c9                   	leave  
8010399f:	c3                   	ret    

801039a0 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801039a0:	f3 0f 1e fb          	endbr32 
801039a4:	55                   	push   %ebp
801039a5:	89 e5                	mov    %esp,%ebp
801039a7:	53                   	push   %ebx
801039a8:	83 ec 10             	sub    $0x10,%esp
801039ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
801039ae:	68 e0 a5 10 80       	push   $0x8010a5e0
801039b3:	e8 f6 03 00 00       	call   80103dae <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039b8:	83 c4 10             	add    $0x10,%esp
801039bb:	b8 14 a6 10 80       	mov    $0x8010a614,%eax
801039c0:	3d 14 c6 10 80       	cmp    $0x8010c614,%eax
801039c5:	73 3a                	jae    80103a01 <kill+0x61>
    if(p->pid == pid){
801039c7:	39 58 14             	cmp    %ebx,0x14(%eax)
801039ca:	74 05                	je     801039d1 <kill+0x31>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039cc:	83 e8 80             	sub    $0xffffff80,%eax
801039cf:	eb ef                	jmp    801039c0 <kill+0x20>
      p->killed = 1;
801039d1:	c7 40 28 01 00 00 00 	movl   $0x1,0x28(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801039d8:	83 78 10 02          	cmpl   $0x2,0x10(%eax)
801039dc:	74 1a                	je     801039f8 <kill+0x58>
        p->state = RUNNABLE;
      release(&ptable.lock);
801039de:	83 ec 0c             	sub    $0xc,%esp
801039e1:	68 e0 a5 10 80       	push   $0x8010a5e0
801039e6:	e8 2c 04 00 00       	call   80103e17 <release>
      return 0;
801039eb:	83 c4 10             	add    $0x10,%esp
801039ee:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039f6:	c9                   	leave  
801039f7:	c3                   	ret    
        p->state = RUNNABLE;
801039f8:	c7 40 10 03 00 00 00 	movl   $0x3,0x10(%eax)
801039ff:	eb dd                	jmp    801039de <kill+0x3e>
  release(&ptable.lock);
80103a01:	83 ec 0c             	sub    $0xc,%esp
80103a04:	68 e0 a5 10 80       	push   $0x8010a5e0
80103a09:	e8 09 04 00 00       	call   80103e17 <release>
  return -1;
80103a0e:	83 c4 10             	add    $0x10,%esp
80103a11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a16:	eb db                	jmp    801039f3 <kill+0x53>

80103a18 <procdumpP1>:
  return;
}
#elif defined(CS333_P1)
void
procdumpP1(struct proc *p, char *state_string)
{
80103a18:	f3 0f 1e fb          	endbr32 
80103a1c:	55                   	push   %ebp
80103a1d:	89 e5                	mov    %esp,%ebp
80103a1f:	57                   	push   %edi
80103a20:	56                   	push   %esi
80103a21:	53                   	push   %ebx
80103a22:	83 ec 0c             	sub    $0xc,%esp
80103a25:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int elapsed_s;
  int elapsed_ms;

  elapsed_ms = ticks - p->start_ticks;
80103a28:	8b 1d 80 55 11 80    	mov    0x80115580,%ebx
80103a2e:	2b 19                	sub    (%ecx),%ebx
  elapsed_s = elapsed_ms / 1000;
80103a30:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
80103a35:	89 d8                	mov    %ebx,%eax
80103a37:	f7 ea                	imul   %edx
80103a39:	c1 fa 06             	sar    $0x6,%edx
80103a3c:	89 d8                	mov    %ebx,%eax
80103a3e:	c1 f8 1f             	sar    $0x1f,%eax
80103a41:	29 c2                	sub    %eax,%edx
  elapsed_ms = elapsed_ms % 1000;
80103a43:	69 c2 e8 03 00 00    	imul   $0x3e8,%edx,%eax
80103a49:	29 c3                	sub    %eax,%ebx
80103a4b:	89 d8                	mov    %ebx,%eax

  char* nol = "";
  if(elapsed_ms < 100 && elapsed_ms >= 10)
80103a4d:	8d 5b f6             	lea    -0xa(%ebx),%ebx
80103a50:	83 fb 59             	cmp    $0x59,%ebx
80103a53:	76 43                	jbe    80103a98 <procdumpP1+0x80>
  char* nol = "";
80103a55:	bb 99 6c 10 80       	mov    $0x80106c99,%ebx
    nol = "0";
  if(elapsed_ms < 10)
80103a5a:	83 f8 09             	cmp    $0x9,%eax
80103a5d:	7f 05                	jg     80103a64 <procdumpP1+0x4c>
  nol = "00";
80103a5f:	bb 7a 6c 10 80       	mov    $0x80106c7a,%ebx

  cprintf("%d\t%s\t%s%d.%s%d\t%s\t%d\t", 
  p->pid, p->name, "     ",elapsed_s, nol, elapsed_ms, states[p->state], p->sz);
80103a64:	8d 71 70             	lea    0x70(%ecx),%esi
  cprintf("%d\t%s\t%s%d.%s%d\t%s\t%d\t", 
80103a67:	83 ec 0c             	sub    $0xc,%esp
80103a6a:	ff 71 04             	pushl  0x4(%ecx)
80103a6d:	8b 79 10             	mov    0x10(%ecx),%edi
80103a70:	ff 34 bd 20 6d 10 80 	pushl  -0x7fef92e0(,%edi,4)
80103a77:	50                   	push   %eax
80103a78:	53                   	push   %ebx
80103a79:	52                   	push   %edx
80103a7a:	68 7d 6c 10 80       	push   $0x80106c7d
80103a7f:	56                   	push   %esi
80103a80:	ff 71 14             	pushl  0x14(%ecx)
80103a83:	68 83 6c 10 80       	push   $0x80106c83
80103a88:	e8 9c cb ff ff       	call   80100629 <cprintf>
  return;
80103a8d:	83 c4 30             	add    $0x30,%esp
}
80103a90:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103a93:	5b                   	pop    %ebx
80103a94:	5e                   	pop    %esi
80103a95:	5f                   	pop    %edi
80103a96:	5d                   	pop    %ebp
80103a97:	c3                   	ret    
    nol = "0";
80103a98:	bb 7b 6c 10 80       	mov    $0x80106c7b,%ebx
80103a9d:	eb bb                	jmp    80103a5a <procdumpP1+0x42>

80103a9f <procdump>:
#endif

void
procdump(void)
{
80103a9f:	f3 0f 1e fb          	endbr32 
80103aa3:	55                   	push   %ebp
80103aa4:	89 e5                	mov    %esp,%ebp
80103aa6:	56                   	push   %esi
80103aa7:	53                   	push   %ebx
80103aa8:	83 ec 3c             	sub    $0x3c,%esp
#define HEADER "\nPID\tName         Elapsed\tState\tSize\t PCs\n"
#else
#define HEADER "\n"
#endif

  cprintf(HEADER);  // not conditionally compiled as must work in all project states
80103aab:	68 f4 6c 10 80       	push   $0x80106cf4
80103ab0:	e8 74 cb ff ff       	call   80100629 <cprintf>

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ab5:	83 c4 10             	add    $0x10,%esp
80103ab8:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80103abd:	eb 2b                	jmp    80103aea <procdump+0x4b>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103abf:	b8 9a 6c 10 80       	mov    $0x80106c9a,%eax
    // see TODOs above this function
    // P2 and P3 are identical and the P4 change is minor
#if defined(CS333_P2)
    procdumpP2P3P4(p, state);
#elif defined(CS333_P1)
    procdumpP1(p, state);
80103ac4:	83 ec 08             	sub    $0x8,%esp
80103ac7:	50                   	push   %eax
80103ac8:	53                   	push   %ebx
80103ac9:	e8 4a ff ff ff       	call   80103a18 <procdumpP1>
#else
    cprintf("%d\t%s\t%s\t", p->pid, p->name, state);
#endif

    if(p->state == SLEEPING){
80103ace:	83 c4 10             	add    $0x10,%esp
80103ad1:	83 7b 10 02          	cmpl   $0x2,0x10(%ebx)
80103ad5:	74 39                	je     80103b10 <procdump+0x71>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103ad7:	83 ec 0c             	sub    $0xc,%esp
80103ada:	68 3b 70 10 80       	push   $0x8010703b
80103adf:	e8 45 cb ff ff       	call   80100629 <cprintf>
80103ae4:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ae7:	83 eb 80             	sub    $0xffffff80,%ebx
80103aea:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
80103af0:	73 61                	jae    80103b53 <procdump+0xb4>
    if(p->state == UNUSED)
80103af2:	8b 43 10             	mov    0x10(%ebx),%eax
80103af5:	85 c0                	test   %eax,%eax
80103af7:	74 ee                	je     80103ae7 <procdump+0x48>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103af9:	83 f8 05             	cmp    $0x5,%eax
80103afc:	77 c1                	ja     80103abf <procdump+0x20>
80103afe:	8b 04 85 20 6d 10 80 	mov    -0x7fef92e0(,%eax,4),%eax
80103b05:	85 c0                	test   %eax,%eax
80103b07:	75 bb                	jne    80103ac4 <procdump+0x25>
      state = "???";
80103b09:	b8 9a 6c 10 80       	mov    $0x80106c9a,%eax
80103b0e:	eb b4                	jmp    80103ac4 <procdump+0x25>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103b10:	8b 43 20             	mov    0x20(%ebx),%eax
80103b13:	8b 40 0c             	mov    0xc(%eax),%eax
80103b16:	83 c0 08             	add    $0x8,%eax
80103b19:	83 ec 08             	sub    $0x8,%esp
80103b1c:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103b1f:	52                   	push   %edx
80103b20:	50                   	push   %eax
80103b21:	e8 57 01 00 00       	call   80103c7d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103b26:	83 c4 10             	add    $0x10,%esp
80103b29:	be 00 00 00 00       	mov    $0x0,%esi
80103b2e:	eb 14                	jmp    80103b44 <procdump+0xa5>
        cprintf(" %p", pc[i]);
80103b30:	83 ec 08             	sub    $0x8,%esp
80103b33:	50                   	push   %eax
80103b34:	68 e1 66 10 80       	push   $0x801066e1
80103b39:	e8 eb ca ff ff       	call   80100629 <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103b3e:	83 c6 01             	add    $0x1,%esi
80103b41:	83 c4 10             	add    $0x10,%esp
80103b44:	83 fe 09             	cmp    $0x9,%esi
80103b47:	7f 8e                	jg     80103ad7 <procdump+0x38>
80103b49:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103b4d:	85 c0                	test   %eax,%eax
80103b4f:	75 df                	jne    80103b30 <procdump+0x91>
80103b51:	eb 84                	jmp    80103ad7 <procdump+0x38>
  }
#ifdef CS333_P1
  cprintf("$ ");  // simulate shell prompt
80103b53:	83 ec 0c             	sub    $0xc,%esp
80103b56:	68 9e 6c 10 80       	push   $0x80106c9e
80103b5b:	e8 c9 ca ff ff       	call   80100629 <cprintf>
#endif // CS333_P1
}
80103b60:	83 c4 10             	add    $0x10,%esp
80103b63:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b66:	5b                   	pop    %ebx
80103b67:	5e                   	pop    %esi
80103b68:	5d                   	pop    %ebp
80103b69:	c3                   	ret    

80103b6a <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103b6a:	f3 0f 1e fb          	endbr32 
80103b6e:	55                   	push   %ebp
80103b6f:	89 e5                	mov    %esp,%ebp
80103b71:	53                   	push   %ebx
80103b72:	83 ec 0c             	sub    $0xc,%esp
80103b75:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103b78:	68 38 6d 10 80       	push   $0x80106d38
80103b7d:	8d 43 04             	lea    0x4(%ebx),%eax
80103b80:	50                   	push   %eax
80103b81:	e8 d8 00 00 00       	call   80103c5e <initlock>
  lk->name = name;
80103b86:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b89:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103b8c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b92:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103b99:	83 c4 10             	add    $0x10,%esp
80103b9c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b9f:	c9                   	leave  
80103ba0:	c3                   	ret    

80103ba1 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103ba1:	f3 0f 1e fb          	endbr32 
80103ba5:	55                   	push   %ebp
80103ba6:	89 e5                	mov    %esp,%ebp
80103ba8:	56                   	push   %esi
80103ba9:	53                   	push   %ebx
80103baa:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103bad:	8d 73 04             	lea    0x4(%ebx),%esi
80103bb0:	83 ec 0c             	sub    $0xc,%esp
80103bb3:	56                   	push   %esi
80103bb4:	e8 f5 01 00 00       	call   80103dae <acquire>
  while (lk->locked) {
80103bb9:	83 c4 10             	add    $0x10,%esp
80103bbc:	83 3b 00             	cmpl   $0x0,(%ebx)
80103bbf:	74 0f                	je     80103bd0 <acquiresleep+0x2f>
    sleep(lk, &lk->lk);
80103bc1:	83 ec 08             	sub    $0x8,%esp
80103bc4:	56                   	push   %esi
80103bc5:	53                   	push   %ebx
80103bc6:	e8 3c fc ff ff       	call   80103807 <sleep>
80103bcb:	83 c4 10             	add    $0x10,%esp
80103bce:	eb ec                	jmp    80103bbc <acquiresleep+0x1b>
  }
  lk->locked = 1;
80103bd0:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103bd6:	e8 3f f7 ff ff       	call   8010331a <myproc>
80103bdb:	8b 40 14             	mov    0x14(%eax),%eax
80103bde:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103be1:	83 ec 0c             	sub    $0xc,%esp
80103be4:	56                   	push   %esi
80103be5:	e8 2d 02 00 00       	call   80103e17 <release>
}
80103bea:	83 c4 10             	add    $0x10,%esp
80103bed:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bf0:	5b                   	pop    %ebx
80103bf1:	5e                   	pop    %esi
80103bf2:	5d                   	pop    %ebp
80103bf3:	c3                   	ret    

80103bf4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103bf4:	f3 0f 1e fb          	endbr32 
80103bf8:	55                   	push   %ebp
80103bf9:	89 e5                	mov    %esp,%ebp
80103bfb:	56                   	push   %esi
80103bfc:	53                   	push   %ebx
80103bfd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c00:	8d 73 04             	lea    0x4(%ebx),%esi
80103c03:	83 ec 0c             	sub    $0xc,%esp
80103c06:	56                   	push   %esi
80103c07:	e8 a2 01 00 00       	call   80103dae <acquire>
  lk->locked = 0;
80103c0c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c12:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103c19:	89 1c 24             	mov    %ebx,(%esp)
80103c1c:	e8 52 fd ff ff       	call   80103973 <wakeup>
  release(&lk->lk);
80103c21:	89 34 24             	mov    %esi,(%esp)
80103c24:	e8 ee 01 00 00       	call   80103e17 <release>
}
80103c29:	83 c4 10             	add    $0x10,%esp
80103c2c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c2f:	5b                   	pop    %ebx
80103c30:	5e                   	pop    %esi
80103c31:	5d                   	pop    %ebp
80103c32:	c3                   	ret    

80103c33 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103c33:	f3 0f 1e fb          	endbr32 
80103c37:	55                   	push   %ebp
80103c38:	89 e5                	mov    %esp,%ebp
80103c3a:	56                   	push   %esi
80103c3b:	53                   	push   %ebx
80103c3c:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;
  
  acquire(&lk->lk);
80103c3f:	8d 5e 04             	lea    0x4(%esi),%ebx
80103c42:	83 ec 0c             	sub    $0xc,%esp
80103c45:	53                   	push   %ebx
80103c46:	e8 63 01 00 00       	call   80103dae <acquire>
  r = lk->locked;
80103c4b:	8b 36                	mov    (%esi),%esi
  release(&lk->lk);
80103c4d:	89 1c 24             	mov    %ebx,(%esp)
80103c50:	e8 c2 01 00 00       	call   80103e17 <release>
  return r;
}
80103c55:	89 f0                	mov    %esi,%eax
80103c57:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c5a:	5b                   	pop    %ebx
80103c5b:	5e                   	pop    %esi
80103c5c:	5d                   	pop    %ebp
80103c5d:	c3                   	ret    

80103c5e <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103c5e:	f3 0f 1e fb          	endbr32 
80103c62:	55                   	push   %ebp
80103c63:	89 e5                	mov    %esp,%ebp
80103c65:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103c68:	8b 55 0c             	mov    0xc(%ebp),%edx
80103c6b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103c6e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103c74:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103c7b:	5d                   	pop    %ebp
80103c7c:	c3                   	ret    

80103c7d <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103c7d:	f3 0f 1e fb          	endbr32 
80103c81:	55                   	push   %ebp
80103c82:	89 e5                	mov    %esp,%ebp
80103c84:	53                   	push   %ebx
80103c85:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103c88:	8b 45 08             	mov    0x8(%ebp),%eax
80103c8b:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103c8e:	b8 00 00 00 00       	mov    $0x0,%eax
80103c93:	83 f8 09             	cmp    $0x9,%eax
80103c96:	7f 25                	jg     80103cbd <getcallerpcs+0x40>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103c98:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103c9e:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103ca4:	77 17                	ja     80103cbd <getcallerpcs+0x40>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103ca6:	8b 5a 04             	mov    0x4(%edx),%ebx
80103ca9:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103cac:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103cae:	83 c0 01             	add    $0x1,%eax
80103cb1:	eb e0                	jmp    80103c93 <getcallerpcs+0x16>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103cb3:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103cba:	83 c0 01             	add    $0x1,%eax
80103cbd:	83 f8 09             	cmp    $0x9,%eax
80103cc0:	7e f1                	jle    80103cb3 <getcallerpcs+0x36>
}
80103cc2:	5b                   	pop    %ebx
80103cc3:	5d                   	pop    %ebp
80103cc4:	c3                   	ret    

80103cc5 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103cc5:	f3 0f 1e fb          	endbr32 
80103cc9:	55                   	push   %ebp
80103cca:	89 e5                	mov    %esp,%ebp
80103ccc:	53                   	push   %ebx
80103ccd:	83 ec 04             	sub    $0x4,%esp
80103cd0:	9c                   	pushf  
80103cd1:	5b                   	pop    %ebx
  asm volatile("cli");
80103cd2:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103cd3:	e8 c3 f5 ff ff       	call   8010329b <mycpu>
80103cd8:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103cdf:	74 12                	je     80103cf3 <pushcli+0x2e>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103ce1:	e8 b5 f5 ff ff       	call   8010329b <mycpu>
80103ce6:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103ced:	83 c4 04             	add    $0x4,%esp
80103cf0:	5b                   	pop    %ebx
80103cf1:	5d                   	pop    %ebp
80103cf2:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103cf3:	e8 a3 f5 ff ff       	call   8010329b <mycpu>
80103cf8:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103cfe:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103d04:	eb db                	jmp    80103ce1 <pushcli+0x1c>

80103d06 <popcli>:

void
popcli(void)
{
80103d06:	f3 0f 1e fb          	endbr32 
80103d0a:	55                   	push   %ebp
80103d0b:	89 e5                	mov    %esp,%ebp
80103d0d:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103d10:	9c                   	pushf  
80103d11:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103d12:	f6 c4 02             	test   $0x2,%ah
80103d15:	75 28                	jne    80103d3f <popcli+0x39>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103d17:	e8 7f f5 ff ff       	call   8010329b <mycpu>
80103d1c:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103d22:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103d25:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103d2b:	85 d2                	test   %edx,%edx
80103d2d:	78 1d                	js     80103d4c <popcli+0x46>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d2f:	e8 67 f5 ff ff       	call   8010329b <mycpu>
80103d34:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d3b:	74 1c                	je     80103d59 <popcli+0x53>
    sti();
}
80103d3d:	c9                   	leave  
80103d3e:	c3                   	ret    
    panic("popcli - interruptible");
80103d3f:	83 ec 0c             	sub    $0xc,%esp
80103d42:	68 43 6d 10 80       	push   $0x80106d43
80103d47:	e8 10 c6 ff ff       	call   8010035c <panic>
    panic("popcli");
80103d4c:	83 ec 0c             	sub    $0xc,%esp
80103d4f:	68 5a 6d 10 80       	push   $0x80106d5a
80103d54:	e8 03 c6 ff ff       	call   8010035c <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d59:	e8 3d f5 ff ff       	call   8010329b <mycpu>
80103d5e:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103d65:	74 d6                	je     80103d3d <popcli+0x37>
  asm volatile("sti");
80103d67:	fb                   	sti    
}
80103d68:	eb d3                	jmp    80103d3d <popcli+0x37>

80103d6a <holding>:
{
80103d6a:	f3 0f 1e fb          	endbr32 
80103d6e:	55                   	push   %ebp
80103d6f:	89 e5                	mov    %esp,%ebp
80103d71:	53                   	push   %ebx
80103d72:	83 ec 04             	sub    $0x4,%esp
80103d75:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103d78:	e8 48 ff ff ff       	call   80103cc5 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103d7d:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d80:	75 12                	jne    80103d94 <holding+0x2a>
80103d82:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103d87:	e8 7a ff ff ff       	call   80103d06 <popcli>
}
80103d8c:	89 d8                	mov    %ebx,%eax
80103d8e:	83 c4 04             	add    $0x4,%esp
80103d91:	5b                   	pop    %ebx
80103d92:	5d                   	pop    %ebp
80103d93:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103d94:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103d97:	e8 ff f4 ff ff       	call   8010329b <mycpu>
80103d9c:	39 c3                	cmp    %eax,%ebx
80103d9e:	74 07                	je     80103da7 <holding+0x3d>
80103da0:	bb 00 00 00 00       	mov    $0x0,%ebx
80103da5:	eb e0                	jmp    80103d87 <holding+0x1d>
80103da7:	bb 01 00 00 00       	mov    $0x1,%ebx
80103dac:	eb d9                	jmp    80103d87 <holding+0x1d>

80103dae <acquire>:
{
80103dae:	f3 0f 1e fb          	endbr32 
80103db2:	55                   	push   %ebp
80103db3:	89 e5                	mov    %esp,%ebp
80103db5:	53                   	push   %ebx
80103db6:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103db9:	e8 07 ff ff ff       	call   80103cc5 <pushcli>
  if(holding(lk))
80103dbe:	83 ec 0c             	sub    $0xc,%esp
80103dc1:	ff 75 08             	pushl  0x8(%ebp)
80103dc4:	e8 a1 ff ff ff       	call   80103d6a <holding>
80103dc9:	83 c4 10             	add    $0x10,%esp
80103dcc:	85 c0                	test   %eax,%eax
80103dce:	75 3a                	jne    80103e0a <acquire+0x5c>
  while(xchg(&lk->locked, 1) != 0)
80103dd0:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103dd3:	b8 01 00 00 00       	mov    $0x1,%eax
80103dd8:	f0 87 02             	lock xchg %eax,(%edx)
80103ddb:	85 c0                	test   %eax,%eax
80103ddd:	75 f1                	jne    80103dd0 <acquire+0x22>
  __sync_synchronize();
80103ddf:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103de4:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103de7:	e8 af f4 ff ff       	call   8010329b <mycpu>
80103dec:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103def:	8b 45 08             	mov    0x8(%ebp),%eax
80103df2:	83 c0 0c             	add    $0xc,%eax
80103df5:	83 ec 08             	sub    $0x8,%esp
80103df8:	50                   	push   %eax
80103df9:	8d 45 08             	lea    0x8(%ebp),%eax
80103dfc:	50                   	push   %eax
80103dfd:	e8 7b fe ff ff       	call   80103c7d <getcallerpcs>
}
80103e02:	83 c4 10             	add    $0x10,%esp
80103e05:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e08:	c9                   	leave  
80103e09:	c3                   	ret    
    panic("acquire");
80103e0a:	83 ec 0c             	sub    $0xc,%esp
80103e0d:	68 61 6d 10 80       	push   $0x80106d61
80103e12:	e8 45 c5 ff ff       	call   8010035c <panic>

80103e17 <release>:
{
80103e17:	f3 0f 1e fb          	endbr32 
80103e1b:	55                   	push   %ebp
80103e1c:	89 e5                	mov    %esp,%ebp
80103e1e:	53                   	push   %ebx
80103e1f:	83 ec 10             	sub    $0x10,%esp
80103e22:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103e25:	53                   	push   %ebx
80103e26:	e8 3f ff ff ff       	call   80103d6a <holding>
80103e2b:	83 c4 10             	add    $0x10,%esp
80103e2e:	85 c0                	test   %eax,%eax
80103e30:	74 23                	je     80103e55 <release+0x3e>
  lk->pcs[0] = 0;
80103e32:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103e39:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103e40:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103e45:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103e4b:	e8 b6 fe ff ff       	call   80103d06 <popcli>
}
80103e50:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e53:	c9                   	leave  
80103e54:	c3                   	ret    
    panic("release");
80103e55:	83 ec 0c             	sub    $0xc,%esp
80103e58:	68 69 6d 10 80       	push   $0x80106d69
80103e5d:	e8 fa c4 ff ff       	call   8010035c <panic>

80103e62 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103e62:	f3 0f 1e fb          	endbr32 
80103e66:	55                   	push   %ebp
80103e67:	89 e5                	mov    %esp,%ebp
80103e69:	57                   	push   %edi
80103e6a:	53                   	push   %ebx
80103e6b:	8b 55 08             	mov    0x8(%ebp),%edx
80103e6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e71:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103e74:	f6 c2 03             	test   $0x3,%dl
80103e77:	75 25                	jne    80103e9e <memset+0x3c>
80103e79:	f6 c1 03             	test   $0x3,%cl
80103e7c:	75 20                	jne    80103e9e <memset+0x3c>
    c &= 0xFF;
80103e7e:	0f b6 f8             	movzbl %al,%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103e81:	c1 e9 02             	shr    $0x2,%ecx
80103e84:	c1 e0 18             	shl    $0x18,%eax
80103e87:	89 fb                	mov    %edi,%ebx
80103e89:	c1 e3 10             	shl    $0x10,%ebx
80103e8c:	09 d8                	or     %ebx,%eax
80103e8e:	89 fb                	mov    %edi,%ebx
80103e90:	c1 e3 08             	shl    $0x8,%ebx
80103e93:	09 d8                	or     %ebx,%eax
80103e95:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103e97:	89 d7                	mov    %edx,%edi
80103e99:	fc                   	cld    
80103e9a:	f3 ab                	rep stos %eax,%es:(%edi)
}
80103e9c:	eb 05                	jmp    80103ea3 <memset+0x41>
  asm volatile("cld; rep stosb" :
80103e9e:	89 d7                	mov    %edx,%edi
80103ea0:	fc                   	cld    
80103ea1:	f3 aa                	rep stos %al,%es:(%edi)
  } else
    stosb(dst, c, n);
  return dst;
}
80103ea3:	89 d0                	mov    %edx,%eax
80103ea5:	5b                   	pop    %ebx
80103ea6:	5f                   	pop    %edi
80103ea7:	5d                   	pop    %ebp
80103ea8:	c3                   	ret    

80103ea9 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103ea9:	f3 0f 1e fb          	endbr32 
80103ead:	55                   	push   %ebp
80103eae:	89 e5                	mov    %esp,%ebp
80103eb0:	56                   	push   %esi
80103eb1:	53                   	push   %ebx
80103eb2:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103eb5:	8b 55 0c             	mov    0xc(%ebp),%edx
80103eb8:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103ebb:	8d 70 ff             	lea    -0x1(%eax),%esi
80103ebe:	85 c0                	test   %eax,%eax
80103ec0:	74 1c                	je     80103ede <memcmp+0x35>
    if(*s1 != *s2)
80103ec2:	0f b6 01             	movzbl (%ecx),%eax
80103ec5:	0f b6 1a             	movzbl (%edx),%ebx
80103ec8:	38 d8                	cmp    %bl,%al
80103eca:	75 0a                	jne    80103ed6 <memcmp+0x2d>
      return *s1 - *s2;
    s1++, s2++;
80103ecc:	83 c1 01             	add    $0x1,%ecx
80103ecf:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103ed2:	89 f0                	mov    %esi,%eax
80103ed4:	eb e5                	jmp    80103ebb <memcmp+0x12>
      return *s1 - *s2;
80103ed6:	0f b6 c0             	movzbl %al,%eax
80103ed9:	0f b6 db             	movzbl %bl,%ebx
80103edc:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103ede:	5b                   	pop    %ebx
80103edf:	5e                   	pop    %esi
80103ee0:	5d                   	pop    %ebp
80103ee1:	c3                   	ret    

80103ee2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103ee2:	f3 0f 1e fb          	endbr32 
80103ee6:	55                   	push   %ebp
80103ee7:	89 e5                	mov    %esp,%ebp
80103ee9:	56                   	push   %esi
80103eea:	53                   	push   %ebx
80103eeb:	8b 75 08             	mov    0x8(%ebp),%esi
80103eee:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ef1:	8b 45 10             	mov    0x10(%ebp),%eax
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103ef4:	39 f2                	cmp    %esi,%edx
80103ef6:	73 3a                	jae    80103f32 <memmove+0x50>
80103ef8:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80103efb:	39 f1                	cmp    %esi,%ecx
80103efd:	76 37                	jbe    80103f36 <memmove+0x54>
    s += n;
    d += n;
80103eff:	8d 14 06             	lea    (%esi,%eax,1),%edx
    while(n-- > 0)
80103f02:	8d 58 ff             	lea    -0x1(%eax),%ebx
80103f05:	85 c0                	test   %eax,%eax
80103f07:	74 23                	je     80103f2c <memmove+0x4a>
      *--d = *--s;
80103f09:	83 e9 01             	sub    $0x1,%ecx
80103f0c:	83 ea 01             	sub    $0x1,%edx
80103f0f:	0f b6 01             	movzbl (%ecx),%eax
80103f12:	88 02                	mov    %al,(%edx)
    while(n-- > 0)
80103f14:	89 d8                	mov    %ebx,%eax
80103f16:	eb ea                	jmp    80103f02 <memmove+0x20>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103f18:	0f b6 02             	movzbl (%edx),%eax
80103f1b:	88 01                	mov    %al,(%ecx)
80103f1d:	8d 49 01             	lea    0x1(%ecx),%ecx
80103f20:	8d 52 01             	lea    0x1(%edx),%edx
    while(n-- > 0)
80103f23:	89 d8                	mov    %ebx,%eax
80103f25:	8d 58 ff             	lea    -0x1(%eax),%ebx
80103f28:	85 c0                	test   %eax,%eax
80103f2a:	75 ec                	jne    80103f18 <memmove+0x36>

  return dst;
}
80103f2c:	89 f0                	mov    %esi,%eax
80103f2e:	5b                   	pop    %ebx
80103f2f:	5e                   	pop    %esi
80103f30:	5d                   	pop    %ebp
80103f31:	c3                   	ret    
80103f32:	89 f1                	mov    %esi,%ecx
80103f34:	eb ef                	jmp    80103f25 <memmove+0x43>
80103f36:	89 f1                	mov    %esi,%ecx
80103f38:	eb eb                	jmp    80103f25 <memmove+0x43>

80103f3a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103f3a:	f3 0f 1e fb          	endbr32 
80103f3e:	55                   	push   %ebp
80103f3f:	89 e5                	mov    %esp,%ebp
80103f41:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80103f44:	ff 75 10             	pushl  0x10(%ebp)
80103f47:	ff 75 0c             	pushl  0xc(%ebp)
80103f4a:	ff 75 08             	pushl  0x8(%ebp)
80103f4d:	e8 90 ff ff ff       	call   80103ee2 <memmove>
}
80103f52:	c9                   	leave  
80103f53:	c3                   	ret    

80103f54 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103f54:	f3 0f 1e fb          	endbr32 
80103f58:	55                   	push   %ebp
80103f59:	89 e5                	mov    %esp,%ebp
80103f5b:	53                   	push   %ebx
80103f5c:	8b 55 08             	mov    0x8(%ebp),%edx
80103f5f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f62:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103f65:	eb 09                	jmp    80103f70 <strncmp+0x1c>
    n--, p++, q++;
80103f67:	83 e8 01             	sub    $0x1,%eax
80103f6a:	83 c2 01             	add    $0x1,%edx
80103f6d:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103f70:	85 c0                	test   %eax,%eax
80103f72:	74 0b                	je     80103f7f <strncmp+0x2b>
80103f74:	0f b6 1a             	movzbl (%edx),%ebx
80103f77:	84 db                	test   %bl,%bl
80103f79:	74 04                	je     80103f7f <strncmp+0x2b>
80103f7b:	3a 19                	cmp    (%ecx),%bl
80103f7d:	74 e8                	je     80103f67 <strncmp+0x13>
  if(n == 0)
80103f7f:	85 c0                	test   %eax,%eax
80103f81:	74 0b                	je     80103f8e <strncmp+0x3a>
    return 0;
  return (uchar)*p - (uchar)*q;
80103f83:	0f b6 02             	movzbl (%edx),%eax
80103f86:	0f b6 11             	movzbl (%ecx),%edx
80103f89:	29 d0                	sub    %edx,%eax
}
80103f8b:	5b                   	pop    %ebx
80103f8c:	5d                   	pop    %ebp
80103f8d:	c3                   	ret    
    return 0;
80103f8e:	b8 00 00 00 00       	mov    $0x0,%eax
80103f93:	eb f6                	jmp    80103f8b <strncmp+0x37>

80103f95 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103f95:	f3 0f 1e fb          	endbr32 
80103f99:	55                   	push   %ebp
80103f9a:	89 e5                	mov    %esp,%ebp
80103f9c:	57                   	push   %edi
80103f9d:	56                   	push   %esi
80103f9e:	53                   	push   %ebx
80103f9f:	8b 7d 08             	mov    0x8(%ebp),%edi
80103fa2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103fa5:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103fa8:	89 fa                	mov    %edi,%edx
80103faa:	eb 04                	jmp    80103fb0 <strncpy+0x1b>
80103fac:	89 f1                	mov    %esi,%ecx
80103fae:	89 da                	mov    %ebx,%edx
80103fb0:	89 c3                	mov    %eax,%ebx
80103fb2:	83 e8 01             	sub    $0x1,%eax
80103fb5:	85 db                	test   %ebx,%ebx
80103fb7:	7e 1b                	jle    80103fd4 <strncpy+0x3f>
80103fb9:	8d 71 01             	lea    0x1(%ecx),%esi
80103fbc:	8d 5a 01             	lea    0x1(%edx),%ebx
80103fbf:	0f b6 09             	movzbl (%ecx),%ecx
80103fc2:	88 0a                	mov    %cl,(%edx)
80103fc4:	84 c9                	test   %cl,%cl
80103fc6:	75 e4                	jne    80103fac <strncpy+0x17>
80103fc8:	89 da                	mov    %ebx,%edx
80103fca:	eb 08                	jmp    80103fd4 <strncpy+0x3f>
    ;
  while(n-- > 0)
    *s++ = 0;
80103fcc:	c6 02 00             	movb   $0x0,(%edx)
  while(n-- > 0)
80103fcf:	89 c8                	mov    %ecx,%eax
    *s++ = 0;
80103fd1:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
80103fd4:	8d 48 ff             	lea    -0x1(%eax),%ecx
80103fd7:	85 c0                	test   %eax,%eax
80103fd9:	7f f1                	jg     80103fcc <strncpy+0x37>
  return os;
}
80103fdb:	89 f8                	mov    %edi,%eax
80103fdd:	5b                   	pop    %ebx
80103fde:	5e                   	pop    %esi
80103fdf:	5f                   	pop    %edi
80103fe0:	5d                   	pop    %ebp
80103fe1:	c3                   	ret    

80103fe2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103fe2:	f3 0f 1e fb          	endbr32 
80103fe6:	55                   	push   %ebp
80103fe7:	89 e5                	mov    %esp,%ebp
80103fe9:	57                   	push   %edi
80103fea:	56                   	push   %esi
80103feb:	53                   	push   %ebx
80103fec:	8b 7d 08             	mov    0x8(%ebp),%edi
80103fef:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103ff2:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  if(n <= 0)
80103ff5:	85 c0                	test   %eax,%eax
80103ff7:	7e 23                	jle    8010401c <safestrcpy+0x3a>
80103ff9:	89 fa                	mov    %edi,%edx
80103ffb:	eb 04                	jmp    80104001 <safestrcpy+0x1f>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103ffd:	89 f1                	mov    %esi,%ecx
80103fff:	89 da                	mov    %ebx,%edx
80104001:	83 e8 01             	sub    $0x1,%eax
80104004:	85 c0                	test   %eax,%eax
80104006:	7e 11                	jle    80104019 <safestrcpy+0x37>
80104008:	8d 71 01             	lea    0x1(%ecx),%esi
8010400b:	8d 5a 01             	lea    0x1(%edx),%ebx
8010400e:	0f b6 09             	movzbl (%ecx),%ecx
80104011:	88 0a                	mov    %cl,(%edx)
80104013:	84 c9                	test   %cl,%cl
80104015:	75 e6                	jne    80103ffd <safestrcpy+0x1b>
80104017:	89 da                	mov    %ebx,%edx
    ;
  *s = 0;
80104019:	c6 02 00             	movb   $0x0,(%edx)
  return os;
}
8010401c:	89 f8                	mov    %edi,%eax
8010401e:	5b                   	pop    %ebx
8010401f:	5e                   	pop    %esi
80104020:	5f                   	pop    %edi
80104021:	5d                   	pop    %ebp
80104022:	c3                   	ret    

80104023 <strlen>:

int
strlen(const char *s)
{
80104023:	f3 0f 1e fb          	endbr32 
80104027:	55                   	push   %ebp
80104028:	89 e5                	mov    %esp,%ebp
8010402a:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
8010402d:	b8 00 00 00 00       	mov    $0x0,%eax
80104032:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80104036:	74 05                	je     8010403d <strlen+0x1a>
80104038:	83 c0 01             	add    $0x1,%eax
8010403b:	eb f5                	jmp    80104032 <strlen+0xf>
    ;
  return n;
}
8010403d:	5d                   	pop    %ebp
8010403e:	c3                   	ret    

8010403f <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
8010403f:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104043:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80104047:	55                   	push   %ebp
  pushl %ebx
80104048:	53                   	push   %ebx
  pushl %esi
80104049:	56                   	push   %esi
  pushl %edi
8010404a:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010404b:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010404d:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010404f:	5f                   	pop    %edi
  popl %esi
80104050:	5e                   	pop    %esi
  popl %ebx
80104051:	5b                   	pop    %ebx
  popl %ebp
80104052:	5d                   	pop    %ebp
  ret
80104053:	c3                   	ret    

80104054 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104054:	f3 0f 1e fb          	endbr32 
80104058:	55                   	push   %ebp
80104059:	89 e5                	mov    %esp,%ebp
8010405b:	53                   	push   %ebx
8010405c:	83 ec 04             	sub    $0x4,%esp
8010405f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104062:	e8 b3 f2 ff ff       	call   8010331a <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104067:	8b 40 04             	mov    0x4(%eax),%eax
8010406a:	39 d8                	cmp    %ebx,%eax
8010406c:	76 19                	jbe    80104087 <fetchint+0x33>
8010406e:	8d 53 04             	lea    0x4(%ebx),%edx
80104071:	39 d0                	cmp    %edx,%eax
80104073:	72 19                	jb     8010408e <fetchint+0x3a>
    return -1;
  *ip = *(int*)(addr);
80104075:	8b 13                	mov    (%ebx),%edx
80104077:	8b 45 0c             	mov    0xc(%ebp),%eax
8010407a:	89 10                	mov    %edx,(%eax)
  return 0;
8010407c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104081:	83 c4 04             	add    $0x4,%esp
80104084:	5b                   	pop    %ebx
80104085:	5d                   	pop    %ebp
80104086:	c3                   	ret    
    return -1;
80104087:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010408c:	eb f3                	jmp    80104081 <fetchint+0x2d>
8010408e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104093:	eb ec                	jmp    80104081 <fetchint+0x2d>

80104095 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104095:	f3 0f 1e fb          	endbr32 
80104099:	55                   	push   %ebp
8010409a:	89 e5                	mov    %esp,%ebp
8010409c:	53                   	push   %ebx
8010409d:	83 ec 04             	sub    $0x4,%esp
801040a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801040a3:	e8 72 f2 ff ff       	call   8010331a <myproc>

  if(addr >= curproc->sz)
801040a8:	39 58 04             	cmp    %ebx,0x4(%eax)
801040ab:	76 27                	jbe    801040d4 <fetchstr+0x3f>
    return -1;
  *pp = (char*)addr;
801040ad:	8b 55 0c             	mov    0xc(%ebp),%edx
801040b0:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801040b2:	8b 50 04             	mov    0x4(%eax),%edx
  for(s = *pp; s < ep; s++){
801040b5:	89 d8                	mov    %ebx,%eax
801040b7:	39 d0                	cmp    %edx,%eax
801040b9:	73 0e                	jae    801040c9 <fetchstr+0x34>
    if(*s == 0)
801040bb:	80 38 00             	cmpb   $0x0,(%eax)
801040be:	74 05                	je     801040c5 <fetchstr+0x30>
  for(s = *pp; s < ep; s++){
801040c0:	83 c0 01             	add    $0x1,%eax
801040c3:	eb f2                	jmp    801040b7 <fetchstr+0x22>
      return s - *pp;
801040c5:	29 d8                	sub    %ebx,%eax
801040c7:	eb 05                	jmp    801040ce <fetchstr+0x39>
  }
  return -1;
801040c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801040ce:	83 c4 04             	add    $0x4,%esp
801040d1:	5b                   	pop    %ebx
801040d2:	5d                   	pop    %ebp
801040d3:	c3                   	ret    
    return -1;
801040d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040d9:	eb f3                	jmp    801040ce <fetchstr+0x39>

801040db <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801040db:	f3 0f 1e fb          	endbr32 
801040df:	55                   	push   %ebp
801040e0:	89 e5                	mov    %esp,%ebp
801040e2:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801040e5:	e8 30 f2 ff ff       	call   8010331a <myproc>
801040ea:	8b 50 1c             	mov    0x1c(%eax),%edx
801040ed:	8b 45 08             	mov    0x8(%ebp),%eax
801040f0:	c1 e0 02             	shl    $0x2,%eax
801040f3:	03 42 44             	add    0x44(%edx),%eax
801040f6:	83 ec 08             	sub    $0x8,%esp
801040f9:	ff 75 0c             	pushl  0xc(%ebp)
801040fc:	83 c0 04             	add    $0x4,%eax
801040ff:	50                   	push   %eax
80104100:	e8 4f ff ff ff       	call   80104054 <fetchint>
}
80104105:	c9                   	leave  
80104106:	c3                   	ret    

80104107 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104107:	f3 0f 1e fb          	endbr32 
8010410b:	55                   	push   %ebp
8010410c:	89 e5                	mov    %esp,%ebp
8010410e:	56                   	push   %esi
8010410f:	53                   	push   %ebx
80104110:	83 ec 10             	sub    $0x10,%esp
80104113:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104116:	e8 ff f1 ff ff       	call   8010331a <myproc>
8010411b:	89 c6                	mov    %eax,%esi

  if(argint(n, &i) < 0)
8010411d:	83 ec 08             	sub    $0x8,%esp
80104120:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104123:	50                   	push   %eax
80104124:	ff 75 08             	pushl  0x8(%ebp)
80104127:	e8 af ff ff ff       	call   801040db <argint>
8010412c:	83 c4 10             	add    $0x10,%esp
8010412f:	85 c0                	test   %eax,%eax
80104131:	78 25                	js     80104158 <argptr+0x51>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104133:	85 db                	test   %ebx,%ebx
80104135:	78 28                	js     8010415f <argptr+0x58>
80104137:	8b 56 04             	mov    0x4(%esi),%edx
8010413a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010413d:	39 c2                	cmp    %eax,%edx
8010413f:	76 25                	jbe    80104166 <argptr+0x5f>
80104141:	01 c3                	add    %eax,%ebx
80104143:	39 da                	cmp    %ebx,%edx
80104145:	72 26                	jb     8010416d <argptr+0x66>
    return -1;
  *pp = (char*)i;
80104147:	8b 55 0c             	mov    0xc(%ebp),%edx
8010414a:	89 02                	mov    %eax,(%edx)
  return 0;
8010414c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104151:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104154:	5b                   	pop    %ebx
80104155:	5e                   	pop    %esi
80104156:	5d                   	pop    %ebp
80104157:	c3                   	ret    
    return -1;
80104158:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010415d:	eb f2                	jmp    80104151 <argptr+0x4a>
    return -1;
8010415f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104164:	eb eb                	jmp    80104151 <argptr+0x4a>
80104166:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010416b:	eb e4                	jmp    80104151 <argptr+0x4a>
8010416d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104172:	eb dd                	jmp    80104151 <argptr+0x4a>

80104174 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104174:	f3 0f 1e fb          	endbr32 
80104178:	55                   	push   %ebp
80104179:	89 e5                	mov    %esp,%ebp
8010417b:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010417e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104181:	50                   	push   %eax
80104182:	ff 75 08             	pushl  0x8(%ebp)
80104185:	e8 51 ff ff ff       	call   801040db <argint>
8010418a:	83 c4 10             	add    $0x10,%esp
8010418d:	85 c0                	test   %eax,%eax
8010418f:	78 13                	js     801041a4 <argstr+0x30>
    return -1;
  return fetchstr(addr, pp);
80104191:	83 ec 08             	sub    $0x8,%esp
80104194:	ff 75 0c             	pushl  0xc(%ebp)
80104197:	ff 75 f4             	pushl  -0xc(%ebp)
8010419a:	e8 f6 fe ff ff       	call   80104095 <fetchstr>
8010419f:	83 c4 10             	add    $0x10,%esp
}
801041a2:	c9                   	leave  
801041a3:	c3                   	ret    
    return -1;
801041a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041a9:	eb f7                	jmp    801041a2 <argstr+0x2e>

801041ab <syscall>:
};
#endif // PRINT_SYSCALLS

void
syscall(void)
{
801041ab:	f3 0f 1e fb          	endbr32 
801041af:	55                   	push   %ebp
801041b0:	89 e5                	mov    %esp,%ebp
801041b2:	53                   	push   %ebx
801041b3:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801041b6:	e8 5f f1 ff ff       	call   8010331a <myproc>
801041bb:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801041bd:	8b 40 1c             	mov    0x1c(%eax),%eax
801041c0:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801041c3:	8d 50 ff             	lea    -0x1(%eax),%edx
801041c6:	83 fa 16             	cmp    $0x16,%edx
801041c9:	77 17                	ja     801041e2 <syscall+0x37>
801041cb:	8b 14 85 a0 6d 10 80 	mov    -0x7fef9260(,%eax,4),%edx
801041d2:	85 d2                	test   %edx,%edx
801041d4:	74 0c                	je     801041e2 <syscall+0x37>
    curproc->tf->eax = syscalls[num]();
801041d6:	ff d2                	call   *%edx
801041d8:	89 c2                	mov    %eax,%edx
801041da:	8b 43 1c             	mov    0x1c(%ebx),%eax
801041dd:	89 50 1c             	mov    %edx,0x1c(%eax)
801041e0:	eb 1f                	jmp    80104201 <syscall+0x56>
    #ifdef PRINT_SYSCALLS
      cprintf("%s -> %d \n",syscallnames[num], num);
    #endif
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
801041e2:	8d 53 70             	lea    0x70(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801041e5:	50                   	push   %eax
801041e6:	52                   	push   %edx
801041e7:	ff 73 14             	pushl  0x14(%ebx)
801041ea:	68 71 6d 10 80       	push   $0x80106d71
801041ef:	e8 35 c4 ff ff       	call   80100629 <cprintf>
    curproc->tf->eax = -1;
801041f4:	8b 43 1c             	mov    0x1c(%ebx),%eax
801041f7:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801041fe:	83 c4 10             	add    $0x10,%esp
  }
}
80104201:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104204:	c9                   	leave  
80104205:	c3                   	ret    

80104206 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104206:	55                   	push   %ebp
80104207:	89 e5                	mov    %esp,%ebp
80104209:	56                   	push   %esi
8010420a:	53                   	push   %ebx
8010420b:	83 ec 18             	sub    $0x18,%esp
8010420e:	89 d6                	mov    %edx,%esi
80104210:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104212:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104215:	52                   	push   %edx
80104216:	50                   	push   %eax
80104217:	e8 bf fe ff ff       	call   801040db <argint>
8010421c:	83 c4 10             	add    $0x10,%esp
8010421f:	85 c0                	test   %eax,%eax
80104221:	78 35                	js     80104258 <argfd+0x52>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104223:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104227:	77 28                	ja     80104251 <argfd+0x4b>
80104229:	e8 ec f0 ff ff       	call   8010331a <myproc>
8010422e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104231:	8b 44 90 2c          	mov    0x2c(%eax,%edx,4),%eax
80104235:	85 c0                	test   %eax,%eax
80104237:	74 18                	je     80104251 <argfd+0x4b>
    return -1;
  if(pfd)
80104239:	85 f6                	test   %esi,%esi
8010423b:	74 02                	je     8010423f <argfd+0x39>
    *pfd = fd;
8010423d:	89 16                	mov    %edx,(%esi)
  if(pf)
8010423f:	85 db                	test   %ebx,%ebx
80104241:	74 1c                	je     8010425f <argfd+0x59>
    *pf = f;
80104243:	89 03                	mov    %eax,(%ebx)
  return 0;
80104245:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010424a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010424d:	5b                   	pop    %ebx
8010424e:	5e                   	pop    %esi
8010424f:	5d                   	pop    %ebp
80104250:	c3                   	ret    
    return -1;
80104251:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104256:	eb f2                	jmp    8010424a <argfd+0x44>
    return -1;
80104258:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010425d:	eb eb                	jmp    8010424a <argfd+0x44>
  return 0;
8010425f:	b8 00 00 00 00       	mov    $0x0,%eax
80104264:	eb e4                	jmp    8010424a <argfd+0x44>

80104266 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104266:	55                   	push   %ebp
80104267:	89 e5                	mov    %esp,%ebp
80104269:	53                   	push   %ebx
8010426a:	83 ec 04             	sub    $0x4,%esp
8010426d:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010426f:	e8 a6 f0 ff ff       	call   8010331a <myproc>
80104274:	89 c2                	mov    %eax,%edx

  for(fd = 0; fd < NOFILE; fd++){
80104276:	b8 00 00 00 00       	mov    $0x0,%eax
8010427b:	83 f8 0f             	cmp    $0xf,%eax
8010427e:	7f 12                	jg     80104292 <fdalloc+0x2c>
    if(curproc->ofile[fd] == 0){
80104280:	83 7c 82 2c 00       	cmpl   $0x0,0x2c(%edx,%eax,4)
80104285:	74 05                	je     8010428c <fdalloc+0x26>
  for(fd = 0; fd < NOFILE; fd++){
80104287:	83 c0 01             	add    $0x1,%eax
8010428a:	eb ef                	jmp    8010427b <fdalloc+0x15>
      curproc->ofile[fd] = f;
8010428c:	89 5c 82 2c          	mov    %ebx,0x2c(%edx,%eax,4)
      return fd;
80104290:	eb 05                	jmp    80104297 <fdalloc+0x31>
    }
  }
  return -1;
80104292:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104297:	83 c4 04             	add    $0x4,%esp
8010429a:	5b                   	pop    %ebx
8010429b:	5d                   	pop    %ebp
8010429c:	c3                   	ret    

8010429d <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010429d:	55                   	push   %ebp
8010429e:	89 e5                	mov    %esp,%ebp
801042a0:	56                   	push   %esi
801042a1:	53                   	push   %ebx
801042a2:	83 ec 10             	sub    $0x10,%esp
801042a5:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042a7:	b8 20 00 00 00       	mov    $0x20,%eax
801042ac:	89 c6                	mov    %eax,%esi
801042ae:	39 43 58             	cmp    %eax,0x58(%ebx)
801042b1:	76 2e                	jbe    801042e1 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801042b3:	6a 10                	push   $0x10
801042b5:	50                   	push   %eax
801042b6:	8d 45 e8             	lea    -0x18(%ebp),%eax
801042b9:	50                   	push   %eax
801042ba:	53                   	push   %ebx
801042bb:	e8 4e d5 ff ff       	call   8010180e <readi>
801042c0:	83 c4 10             	add    $0x10,%esp
801042c3:	83 f8 10             	cmp    $0x10,%eax
801042c6:	75 0c                	jne    801042d4 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801042c8:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801042cd:	75 1e                	jne    801042ed <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042cf:	8d 46 10             	lea    0x10(%esi),%eax
801042d2:	eb d8                	jmp    801042ac <isdirempty+0xf>
      panic("isdirempty: readi");
801042d4:	83 ec 0c             	sub    $0xc,%esp
801042d7:	68 00 6e 10 80       	push   $0x80106e00
801042dc:	e8 7b c0 ff ff       	call   8010035c <panic>
      return 0;
  }
  return 1;
801042e1:	b8 01 00 00 00       	mov    $0x1,%eax
}
801042e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042e9:	5b                   	pop    %ebx
801042ea:	5e                   	pop    %esi
801042eb:	5d                   	pop    %ebp
801042ec:	c3                   	ret    
      return 0;
801042ed:	b8 00 00 00 00       	mov    $0x0,%eax
801042f2:	eb f2                	jmp    801042e6 <isdirempty+0x49>

801042f4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801042f4:	55                   	push   %ebp
801042f5:	89 e5                	mov    %esp,%ebp
801042f7:	57                   	push   %edi
801042f8:	56                   	push   %esi
801042f9:	53                   	push   %ebx
801042fa:	83 ec 44             	sub    $0x44,%esp
801042fd:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104300:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104303:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104306:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104309:	52                   	push   %edx
8010430a:	50                   	push   %eax
8010430b:	e8 99 d9 ff ff       	call   80101ca9 <nameiparent>
80104310:	89 c6                	mov    %eax,%esi
80104312:	83 c4 10             	add    $0x10,%esp
80104315:	85 c0                	test   %eax,%eax
80104317:	0f 84 35 01 00 00    	je     80104452 <create+0x15e>
    return 0;
  ilock(dp);
8010431d:	83 ec 0c             	sub    $0xc,%esp
80104320:	50                   	push   %eax
80104321:	e8 e2 d2 ff ff       	call   80101608 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104326:	83 c4 0c             	add    $0xc,%esp
80104329:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010432c:	50                   	push   %eax
8010432d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104330:	50                   	push   %eax
80104331:	56                   	push   %esi
80104332:	e8 20 d7 ff ff       	call   80101a57 <dirlookup>
80104337:	89 c3                	mov    %eax,%ebx
80104339:	83 c4 10             	add    $0x10,%esp
8010433c:	85 c0                	test   %eax,%eax
8010433e:	74 3d                	je     8010437d <create+0x89>
    iunlockput(dp);
80104340:	83 ec 0c             	sub    $0xc,%esp
80104343:	56                   	push   %esi
80104344:	e8 72 d4 ff ff       	call   801017bb <iunlockput>
    ilock(ip);
80104349:	89 1c 24             	mov    %ebx,(%esp)
8010434c:	e8 b7 d2 ff ff       	call   80101608 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104351:	83 c4 10             	add    $0x10,%esp
80104354:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104359:	75 07                	jne    80104362 <create+0x6e>
8010435b:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104360:	74 11                	je     80104373 <create+0x7f>
      return ip;
    iunlockput(ip);
80104362:	83 ec 0c             	sub    $0xc,%esp
80104365:	53                   	push   %ebx
80104366:	e8 50 d4 ff ff       	call   801017bb <iunlockput>
    return 0;
8010436b:	83 c4 10             	add    $0x10,%esp
8010436e:	bb 00 00 00 00       	mov    $0x0,%ebx
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104373:	89 d8                	mov    %ebx,%eax
80104375:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104378:	5b                   	pop    %ebx
80104379:	5e                   	pop    %esi
8010437a:	5f                   	pop    %edi
8010437b:	5d                   	pop    %ebp
8010437c:	c3                   	ret    
  if((ip = ialloc(dp->dev, type)) == 0)
8010437d:	83 ec 08             	sub    $0x8,%esp
80104380:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104384:	50                   	push   %eax
80104385:	ff 36                	pushl  (%esi)
80104387:	e8 6d d0 ff ff       	call   801013f9 <ialloc>
8010438c:	89 c3                	mov    %eax,%ebx
8010438e:	83 c4 10             	add    $0x10,%esp
80104391:	85 c0                	test   %eax,%eax
80104393:	74 52                	je     801043e7 <create+0xf3>
  ilock(ip);
80104395:	83 ec 0c             	sub    $0xc,%esp
80104398:	50                   	push   %eax
80104399:	e8 6a d2 ff ff       	call   80101608 <ilock>
  ip->major = major;
8010439e:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801043a2:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801043a6:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801043aa:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801043b0:	89 1c 24             	mov    %ebx,(%esp)
801043b3:	e8 e7 d0 ff ff       	call   8010149f <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801043b8:	83 c4 10             	add    $0x10,%esp
801043bb:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801043c0:	74 32                	je     801043f4 <create+0x100>
  if(dirlink(dp, name, ip->inum) < 0)
801043c2:	83 ec 04             	sub    $0x4,%esp
801043c5:	ff 73 04             	pushl  0x4(%ebx)
801043c8:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043cb:	50                   	push   %eax
801043cc:	56                   	push   %esi
801043cd:	e8 06 d8 ff ff       	call   80101bd8 <dirlink>
801043d2:	83 c4 10             	add    $0x10,%esp
801043d5:	85 c0                	test   %eax,%eax
801043d7:	78 6c                	js     80104445 <create+0x151>
  iunlockput(dp);
801043d9:	83 ec 0c             	sub    $0xc,%esp
801043dc:	56                   	push   %esi
801043dd:	e8 d9 d3 ff ff       	call   801017bb <iunlockput>
  return ip;
801043e2:	83 c4 10             	add    $0x10,%esp
801043e5:	eb 8c                	jmp    80104373 <create+0x7f>
    panic("create: ialloc");
801043e7:	83 ec 0c             	sub    $0xc,%esp
801043ea:	68 12 6e 10 80       	push   $0x80106e12
801043ef:	e8 68 bf ff ff       	call   8010035c <panic>
    dp->nlink++;  // for ".."
801043f4:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801043f8:	83 c0 01             	add    $0x1,%eax
801043fb:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801043ff:	83 ec 0c             	sub    $0xc,%esp
80104402:	56                   	push   %esi
80104403:	e8 97 d0 ff ff       	call   8010149f <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104408:	83 c4 0c             	add    $0xc,%esp
8010440b:	ff 73 04             	pushl  0x4(%ebx)
8010440e:	68 22 6e 10 80       	push   $0x80106e22
80104413:	53                   	push   %ebx
80104414:	e8 bf d7 ff ff       	call   80101bd8 <dirlink>
80104419:	83 c4 10             	add    $0x10,%esp
8010441c:	85 c0                	test   %eax,%eax
8010441e:	78 18                	js     80104438 <create+0x144>
80104420:	83 ec 04             	sub    $0x4,%esp
80104423:	ff 76 04             	pushl  0x4(%esi)
80104426:	68 21 6e 10 80       	push   $0x80106e21
8010442b:	53                   	push   %ebx
8010442c:	e8 a7 d7 ff ff       	call   80101bd8 <dirlink>
80104431:	83 c4 10             	add    $0x10,%esp
80104434:	85 c0                	test   %eax,%eax
80104436:	79 8a                	jns    801043c2 <create+0xce>
      panic("create dots");
80104438:	83 ec 0c             	sub    $0xc,%esp
8010443b:	68 24 6e 10 80       	push   $0x80106e24
80104440:	e8 17 bf ff ff       	call   8010035c <panic>
    panic("create: dirlink");
80104445:	83 ec 0c             	sub    $0xc,%esp
80104448:	68 30 6e 10 80       	push   $0x80106e30
8010444d:	e8 0a bf ff ff       	call   8010035c <panic>
    return 0;
80104452:	89 c3                	mov    %eax,%ebx
80104454:	e9 1a ff ff ff       	jmp    80104373 <create+0x7f>

80104459 <sys_dup>:
{
80104459:	f3 0f 1e fb          	endbr32 
8010445d:	55                   	push   %ebp
8010445e:	89 e5                	mov    %esp,%ebp
80104460:	53                   	push   %ebx
80104461:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104464:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104467:	ba 00 00 00 00       	mov    $0x0,%edx
8010446c:	b8 00 00 00 00       	mov    $0x0,%eax
80104471:	e8 90 fd ff ff       	call   80104206 <argfd>
80104476:	85 c0                	test   %eax,%eax
80104478:	78 23                	js     8010449d <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
8010447a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447d:	e8 e4 fd ff ff       	call   80104266 <fdalloc>
80104482:	89 c3                	mov    %eax,%ebx
80104484:	85 c0                	test   %eax,%eax
80104486:	78 1c                	js     801044a4 <sys_dup+0x4b>
  filedup(f);
80104488:	83 ec 0c             	sub    $0xc,%esp
8010448b:	ff 75 f4             	pushl  -0xc(%ebp)
8010448e:	e8 59 c8 ff ff       	call   80100cec <filedup>
  return fd;
80104493:	83 c4 10             	add    $0x10,%esp
}
80104496:	89 d8                	mov    %ebx,%eax
80104498:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010449b:	c9                   	leave  
8010449c:	c3                   	ret    
    return -1;
8010449d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044a2:	eb f2                	jmp    80104496 <sys_dup+0x3d>
    return -1;
801044a4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044a9:	eb eb                	jmp    80104496 <sys_dup+0x3d>

801044ab <sys_read>:
{
801044ab:	f3 0f 1e fb          	endbr32 
801044af:	55                   	push   %ebp
801044b0:	89 e5                	mov    %esp,%ebp
801044b2:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044b5:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044b8:	ba 00 00 00 00       	mov    $0x0,%edx
801044bd:	b8 00 00 00 00       	mov    $0x0,%eax
801044c2:	e8 3f fd ff ff       	call   80104206 <argfd>
801044c7:	85 c0                	test   %eax,%eax
801044c9:	78 43                	js     8010450e <sys_read+0x63>
801044cb:	83 ec 08             	sub    $0x8,%esp
801044ce:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044d1:	50                   	push   %eax
801044d2:	6a 02                	push   $0x2
801044d4:	e8 02 fc ff ff       	call   801040db <argint>
801044d9:	83 c4 10             	add    $0x10,%esp
801044dc:	85 c0                	test   %eax,%eax
801044de:	78 2e                	js     8010450e <sys_read+0x63>
801044e0:	83 ec 04             	sub    $0x4,%esp
801044e3:	ff 75 f0             	pushl  -0x10(%ebp)
801044e6:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044e9:	50                   	push   %eax
801044ea:	6a 01                	push   $0x1
801044ec:	e8 16 fc ff ff       	call   80104107 <argptr>
801044f1:	83 c4 10             	add    $0x10,%esp
801044f4:	85 c0                	test   %eax,%eax
801044f6:	78 16                	js     8010450e <sys_read+0x63>
  return fileread(f, p, n);
801044f8:	83 ec 04             	sub    $0x4,%esp
801044fb:	ff 75 f0             	pushl  -0x10(%ebp)
801044fe:	ff 75 ec             	pushl  -0x14(%ebp)
80104501:	ff 75 f4             	pushl  -0xc(%ebp)
80104504:	e8 35 c9 ff ff       	call   80100e3e <fileread>
80104509:	83 c4 10             	add    $0x10,%esp
}
8010450c:	c9                   	leave  
8010450d:	c3                   	ret    
    return -1;
8010450e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104513:	eb f7                	jmp    8010450c <sys_read+0x61>

80104515 <sys_write>:
{
80104515:	f3 0f 1e fb          	endbr32 
80104519:	55                   	push   %ebp
8010451a:	89 e5                	mov    %esp,%ebp
8010451c:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010451f:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104522:	ba 00 00 00 00       	mov    $0x0,%edx
80104527:	b8 00 00 00 00       	mov    $0x0,%eax
8010452c:	e8 d5 fc ff ff       	call   80104206 <argfd>
80104531:	85 c0                	test   %eax,%eax
80104533:	78 43                	js     80104578 <sys_write+0x63>
80104535:	83 ec 08             	sub    $0x8,%esp
80104538:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010453b:	50                   	push   %eax
8010453c:	6a 02                	push   $0x2
8010453e:	e8 98 fb ff ff       	call   801040db <argint>
80104543:	83 c4 10             	add    $0x10,%esp
80104546:	85 c0                	test   %eax,%eax
80104548:	78 2e                	js     80104578 <sys_write+0x63>
8010454a:	83 ec 04             	sub    $0x4,%esp
8010454d:	ff 75 f0             	pushl  -0x10(%ebp)
80104550:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104553:	50                   	push   %eax
80104554:	6a 01                	push   $0x1
80104556:	e8 ac fb ff ff       	call   80104107 <argptr>
8010455b:	83 c4 10             	add    $0x10,%esp
8010455e:	85 c0                	test   %eax,%eax
80104560:	78 16                	js     80104578 <sys_write+0x63>
  return filewrite(f, p, n);
80104562:	83 ec 04             	sub    $0x4,%esp
80104565:	ff 75 f0             	pushl  -0x10(%ebp)
80104568:	ff 75 ec             	pushl  -0x14(%ebp)
8010456b:	ff 75 f4             	pushl  -0xc(%ebp)
8010456e:	e8 54 c9 ff ff       	call   80100ec7 <filewrite>
80104573:	83 c4 10             	add    $0x10,%esp
}
80104576:	c9                   	leave  
80104577:	c3                   	ret    
    return -1;
80104578:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010457d:	eb f7                	jmp    80104576 <sys_write+0x61>

8010457f <sys_close>:
{
8010457f:	f3 0f 1e fb          	endbr32 
80104583:	55                   	push   %ebp
80104584:	89 e5                	mov    %esp,%ebp
80104586:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104589:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010458c:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010458f:	b8 00 00 00 00       	mov    $0x0,%eax
80104594:	e8 6d fc ff ff       	call   80104206 <argfd>
80104599:	85 c0                	test   %eax,%eax
8010459b:	78 25                	js     801045c2 <sys_close+0x43>
  myproc()->ofile[fd] = 0;
8010459d:	e8 78 ed ff ff       	call   8010331a <myproc>
801045a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045a5:	c7 44 90 2c 00 00 00 	movl   $0x0,0x2c(%eax,%edx,4)
801045ac:	00 
  fileclose(f);
801045ad:	83 ec 0c             	sub    $0xc,%esp
801045b0:	ff 75 f0             	pushl  -0x10(%ebp)
801045b3:	e8 7d c7 ff ff       	call   80100d35 <fileclose>
  return 0;
801045b8:	83 c4 10             	add    $0x10,%esp
801045bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045c0:	c9                   	leave  
801045c1:	c3                   	ret    
    return -1;
801045c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045c7:	eb f7                	jmp    801045c0 <sys_close+0x41>

801045c9 <sys_fstat>:
{
801045c9:	f3 0f 1e fb          	endbr32 
801045cd:	55                   	push   %ebp
801045ce:	89 e5                	mov    %esp,%ebp
801045d0:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801045d3:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045d6:	ba 00 00 00 00       	mov    $0x0,%edx
801045db:	b8 00 00 00 00       	mov    $0x0,%eax
801045e0:	e8 21 fc ff ff       	call   80104206 <argfd>
801045e5:	85 c0                	test   %eax,%eax
801045e7:	78 2a                	js     80104613 <sys_fstat+0x4a>
801045e9:	83 ec 04             	sub    $0x4,%esp
801045ec:	6a 14                	push   $0x14
801045ee:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045f1:	50                   	push   %eax
801045f2:	6a 01                	push   $0x1
801045f4:	e8 0e fb ff ff       	call   80104107 <argptr>
801045f9:	83 c4 10             	add    $0x10,%esp
801045fc:	85 c0                	test   %eax,%eax
801045fe:	78 13                	js     80104613 <sys_fstat+0x4a>
  return filestat(f, st);
80104600:	83 ec 08             	sub    $0x8,%esp
80104603:	ff 75 f0             	pushl  -0x10(%ebp)
80104606:	ff 75 f4             	pushl  -0xc(%ebp)
80104609:	e8 e5 c7 ff ff       	call   80100df3 <filestat>
8010460e:	83 c4 10             	add    $0x10,%esp
}
80104611:	c9                   	leave  
80104612:	c3                   	ret    
    return -1;
80104613:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104618:	eb f7                	jmp    80104611 <sys_fstat+0x48>

8010461a <sys_link>:
{
8010461a:	f3 0f 1e fb          	endbr32 
8010461e:	55                   	push   %ebp
8010461f:	89 e5                	mov    %esp,%ebp
80104621:	56                   	push   %esi
80104622:	53                   	push   %ebx
80104623:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104626:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104629:	50                   	push   %eax
8010462a:	6a 00                	push   $0x0
8010462c:	e8 43 fb ff ff       	call   80104174 <argstr>
80104631:	83 c4 10             	add    $0x10,%esp
80104634:	85 c0                	test   %eax,%eax
80104636:	0f 88 d3 00 00 00    	js     8010470f <sys_link+0xf5>
8010463c:	83 ec 08             	sub    $0x8,%esp
8010463f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104642:	50                   	push   %eax
80104643:	6a 01                	push   $0x1
80104645:	e8 2a fb ff ff       	call   80104174 <argstr>
8010464a:	83 c4 10             	add    $0x10,%esp
8010464d:	85 c0                	test   %eax,%eax
8010464f:	0f 88 ba 00 00 00    	js     8010470f <sys_link+0xf5>
  begin_op();
80104655:	e8 33 e2 ff ff       	call   8010288d <begin_op>
  if((ip = namei(old)) == 0){
8010465a:	83 ec 0c             	sub    $0xc,%esp
8010465d:	ff 75 e0             	pushl  -0x20(%ebp)
80104660:	e8 28 d6 ff ff       	call   80101c8d <namei>
80104665:	89 c3                	mov    %eax,%ebx
80104667:	83 c4 10             	add    $0x10,%esp
8010466a:	85 c0                	test   %eax,%eax
8010466c:	0f 84 a4 00 00 00    	je     80104716 <sys_link+0xfc>
  ilock(ip);
80104672:	83 ec 0c             	sub    $0xc,%esp
80104675:	50                   	push   %eax
80104676:	e8 8d cf ff ff       	call   80101608 <ilock>
  if(ip->type == T_DIR){
8010467b:	83 c4 10             	add    $0x10,%esp
8010467e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104683:	0f 84 99 00 00 00    	je     80104722 <sys_link+0x108>
  ip->nlink++;
80104689:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010468d:	83 c0 01             	add    $0x1,%eax
80104690:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104694:	83 ec 0c             	sub    $0xc,%esp
80104697:	53                   	push   %ebx
80104698:	e8 02 ce ff ff       	call   8010149f <iupdate>
  iunlock(ip);
8010469d:	89 1c 24             	mov    %ebx,(%esp)
801046a0:	e8 29 d0 ff ff       	call   801016ce <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801046a5:	83 c4 08             	add    $0x8,%esp
801046a8:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046ab:	50                   	push   %eax
801046ac:	ff 75 e4             	pushl  -0x1c(%ebp)
801046af:	e8 f5 d5 ff ff       	call   80101ca9 <nameiparent>
801046b4:	89 c6                	mov    %eax,%esi
801046b6:	83 c4 10             	add    $0x10,%esp
801046b9:	85 c0                	test   %eax,%eax
801046bb:	0f 84 85 00 00 00    	je     80104746 <sys_link+0x12c>
  ilock(dp);
801046c1:	83 ec 0c             	sub    $0xc,%esp
801046c4:	50                   	push   %eax
801046c5:	e8 3e cf ff ff       	call   80101608 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801046ca:	83 c4 10             	add    $0x10,%esp
801046cd:	8b 03                	mov    (%ebx),%eax
801046cf:	39 06                	cmp    %eax,(%esi)
801046d1:	75 67                	jne    8010473a <sys_link+0x120>
801046d3:	83 ec 04             	sub    $0x4,%esp
801046d6:	ff 73 04             	pushl  0x4(%ebx)
801046d9:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046dc:	50                   	push   %eax
801046dd:	56                   	push   %esi
801046de:	e8 f5 d4 ff ff       	call   80101bd8 <dirlink>
801046e3:	83 c4 10             	add    $0x10,%esp
801046e6:	85 c0                	test   %eax,%eax
801046e8:	78 50                	js     8010473a <sys_link+0x120>
  iunlockput(dp);
801046ea:	83 ec 0c             	sub    $0xc,%esp
801046ed:	56                   	push   %esi
801046ee:	e8 c8 d0 ff ff       	call   801017bb <iunlockput>
  iput(ip);
801046f3:	89 1c 24             	mov    %ebx,(%esp)
801046f6:	e8 1c d0 ff ff       	call   80101717 <iput>
  end_op();
801046fb:	e8 0b e2 ff ff       	call   8010290b <end_op>
  return 0;
80104700:	83 c4 10             	add    $0x10,%esp
80104703:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104708:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010470b:	5b                   	pop    %ebx
8010470c:	5e                   	pop    %esi
8010470d:	5d                   	pop    %ebp
8010470e:	c3                   	ret    
    return -1;
8010470f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104714:	eb f2                	jmp    80104708 <sys_link+0xee>
    end_op();
80104716:	e8 f0 e1 ff ff       	call   8010290b <end_op>
    return -1;
8010471b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104720:	eb e6                	jmp    80104708 <sys_link+0xee>
    iunlockput(ip);
80104722:	83 ec 0c             	sub    $0xc,%esp
80104725:	53                   	push   %ebx
80104726:	e8 90 d0 ff ff       	call   801017bb <iunlockput>
    end_op();
8010472b:	e8 db e1 ff ff       	call   8010290b <end_op>
    return -1;
80104730:	83 c4 10             	add    $0x10,%esp
80104733:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104738:	eb ce                	jmp    80104708 <sys_link+0xee>
    iunlockput(dp);
8010473a:	83 ec 0c             	sub    $0xc,%esp
8010473d:	56                   	push   %esi
8010473e:	e8 78 d0 ff ff       	call   801017bb <iunlockput>
    goto bad;
80104743:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104746:	83 ec 0c             	sub    $0xc,%esp
80104749:	53                   	push   %ebx
8010474a:	e8 b9 ce ff ff       	call   80101608 <ilock>
  ip->nlink--;
8010474f:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104753:	83 e8 01             	sub    $0x1,%eax
80104756:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010475a:	89 1c 24             	mov    %ebx,(%esp)
8010475d:	e8 3d cd ff ff       	call   8010149f <iupdate>
  iunlockput(ip);
80104762:	89 1c 24             	mov    %ebx,(%esp)
80104765:	e8 51 d0 ff ff       	call   801017bb <iunlockput>
  end_op();
8010476a:	e8 9c e1 ff ff       	call   8010290b <end_op>
  return -1;
8010476f:	83 c4 10             	add    $0x10,%esp
80104772:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104777:	eb 8f                	jmp    80104708 <sys_link+0xee>

80104779 <sys_unlink>:
{
80104779:	f3 0f 1e fb          	endbr32 
8010477d:	55                   	push   %ebp
8010477e:	89 e5                	mov    %esp,%ebp
80104780:	57                   	push   %edi
80104781:	56                   	push   %esi
80104782:	53                   	push   %ebx
80104783:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104786:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104789:	50                   	push   %eax
8010478a:	6a 00                	push   $0x0
8010478c:	e8 e3 f9 ff ff       	call   80104174 <argstr>
80104791:	83 c4 10             	add    $0x10,%esp
80104794:	85 c0                	test   %eax,%eax
80104796:	0f 88 83 01 00 00    	js     8010491f <sys_unlink+0x1a6>
  begin_op();
8010479c:	e8 ec e0 ff ff       	call   8010288d <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801047a1:	83 ec 08             	sub    $0x8,%esp
801047a4:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047a7:	50                   	push   %eax
801047a8:	ff 75 c4             	pushl  -0x3c(%ebp)
801047ab:	e8 f9 d4 ff ff       	call   80101ca9 <nameiparent>
801047b0:	89 c6                	mov    %eax,%esi
801047b2:	83 c4 10             	add    $0x10,%esp
801047b5:	85 c0                	test   %eax,%eax
801047b7:	0f 84 ed 00 00 00    	je     801048aa <sys_unlink+0x131>
  ilock(dp);
801047bd:	83 ec 0c             	sub    $0xc,%esp
801047c0:	50                   	push   %eax
801047c1:	e8 42 ce ff ff       	call   80101608 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801047c6:	83 c4 08             	add    $0x8,%esp
801047c9:	68 22 6e 10 80       	push   $0x80106e22
801047ce:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047d1:	50                   	push   %eax
801047d2:	e8 67 d2 ff ff       	call   80101a3e <namecmp>
801047d7:	83 c4 10             	add    $0x10,%esp
801047da:	85 c0                	test   %eax,%eax
801047dc:	0f 84 fc 00 00 00    	je     801048de <sys_unlink+0x165>
801047e2:	83 ec 08             	sub    $0x8,%esp
801047e5:	68 21 6e 10 80       	push   $0x80106e21
801047ea:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047ed:	50                   	push   %eax
801047ee:	e8 4b d2 ff ff       	call   80101a3e <namecmp>
801047f3:	83 c4 10             	add    $0x10,%esp
801047f6:	85 c0                	test   %eax,%eax
801047f8:	0f 84 e0 00 00 00    	je     801048de <sys_unlink+0x165>
  if((ip = dirlookup(dp, name, &off)) == 0)
801047fe:	83 ec 04             	sub    $0x4,%esp
80104801:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104804:	50                   	push   %eax
80104805:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104808:	50                   	push   %eax
80104809:	56                   	push   %esi
8010480a:	e8 48 d2 ff ff       	call   80101a57 <dirlookup>
8010480f:	89 c3                	mov    %eax,%ebx
80104811:	83 c4 10             	add    $0x10,%esp
80104814:	85 c0                	test   %eax,%eax
80104816:	0f 84 c2 00 00 00    	je     801048de <sys_unlink+0x165>
  ilock(ip);
8010481c:	83 ec 0c             	sub    $0xc,%esp
8010481f:	50                   	push   %eax
80104820:	e8 e3 cd ff ff       	call   80101608 <ilock>
  if(ip->nlink < 1)
80104825:	83 c4 10             	add    $0x10,%esp
80104828:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010482d:	0f 8e 83 00 00 00    	jle    801048b6 <sys_unlink+0x13d>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104833:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104838:	0f 84 85 00 00 00    	je     801048c3 <sys_unlink+0x14a>
  memset(&de, 0, sizeof(de));
8010483e:	83 ec 04             	sub    $0x4,%esp
80104841:	6a 10                	push   $0x10
80104843:	6a 00                	push   $0x0
80104845:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104848:	57                   	push   %edi
80104849:	e8 14 f6 ff ff       	call   80103e62 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010484e:	6a 10                	push   $0x10
80104850:	ff 75 c0             	pushl  -0x40(%ebp)
80104853:	57                   	push   %edi
80104854:	56                   	push   %esi
80104855:	e8 b5 d0 ff ff       	call   8010190f <writei>
8010485a:	83 c4 20             	add    $0x20,%esp
8010485d:	83 f8 10             	cmp    $0x10,%eax
80104860:	0f 85 90 00 00 00    	jne    801048f6 <sys_unlink+0x17d>
  if(ip->type == T_DIR){
80104866:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010486b:	0f 84 92 00 00 00    	je     80104903 <sys_unlink+0x18a>
  iunlockput(dp);
80104871:	83 ec 0c             	sub    $0xc,%esp
80104874:	56                   	push   %esi
80104875:	e8 41 cf ff ff       	call   801017bb <iunlockput>
  ip->nlink--;
8010487a:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010487e:	83 e8 01             	sub    $0x1,%eax
80104881:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104885:	89 1c 24             	mov    %ebx,(%esp)
80104888:	e8 12 cc ff ff       	call   8010149f <iupdate>
  iunlockput(ip);
8010488d:	89 1c 24             	mov    %ebx,(%esp)
80104890:	e8 26 cf ff ff       	call   801017bb <iunlockput>
  end_op();
80104895:	e8 71 e0 ff ff       	call   8010290b <end_op>
  return 0;
8010489a:	83 c4 10             	add    $0x10,%esp
8010489d:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048a5:	5b                   	pop    %ebx
801048a6:	5e                   	pop    %esi
801048a7:	5f                   	pop    %edi
801048a8:	5d                   	pop    %ebp
801048a9:	c3                   	ret    
    end_op();
801048aa:	e8 5c e0 ff ff       	call   8010290b <end_op>
    return -1;
801048af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048b4:	eb ec                	jmp    801048a2 <sys_unlink+0x129>
    panic("unlink: nlink < 1");
801048b6:	83 ec 0c             	sub    $0xc,%esp
801048b9:	68 40 6e 10 80       	push   $0x80106e40
801048be:	e8 99 ba ff ff       	call   8010035c <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048c3:	89 d8                	mov    %ebx,%eax
801048c5:	e8 d3 f9 ff ff       	call   8010429d <isdirempty>
801048ca:	85 c0                	test   %eax,%eax
801048cc:	0f 85 6c ff ff ff    	jne    8010483e <sys_unlink+0xc5>
    iunlockput(ip);
801048d2:	83 ec 0c             	sub    $0xc,%esp
801048d5:	53                   	push   %ebx
801048d6:	e8 e0 ce ff ff       	call   801017bb <iunlockput>
    goto bad;
801048db:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801048de:	83 ec 0c             	sub    $0xc,%esp
801048e1:	56                   	push   %esi
801048e2:	e8 d4 ce ff ff       	call   801017bb <iunlockput>
  end_op();
801048e7:	e8 1f e0 ff ff       	call   8010290b <end_op>
  return -1;
801048ec:	83 c4 10             	add    $0x10,%esp
801048ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048f4:	eb ac                	jmp    801048a2 <sys_unlink+0x129>
    panic("unlink: writei");
801048f6:	83 ec 0c             	sub    $0xc,%esp
801048f9:	68 52 6e 10 80       	push   $0x80106e52
801048fe:	e8 59 ba ff ff       	call   8010035c <panic>
    dp->nlink--;
80104903:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104907:	83 e8 01             	sub    $0x1,%eax
8010490a:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010490e:	83 ec 0c             	sub    $0xc,%esp
80104911:	56                   	push   %esi
80104912:	e8 88 cb ff ff       	call   8010149f <iupdate>
80104917:	83 c4 10             	add    $0x10,%esp
8010491a:	e9 52 ff ff ff       	jmp    80104871 <sys_unlink+0xf8>
    return -1;
8010491f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104924:	e9 79 ff ff ff       	jmp    801048a2 <sys_unlink+0x129>

80104929 <sys_open>:

int
sys_open(void)
{
80104929:	f3 0f 1e fb          	endbr32 
8010492d:	55                   	push   %ebp
8010492e:	89 e5                	mov    %esp,%ebp
80104930:	57                   	push   %edi
80104931:	56                   	push   %esi
80104932:	53                   	push   %ebx
80104933:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104936:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104939:	50                   	push   %eax
8010493a:	6a 00                	push   $0x0
8010493c:	e8 33 f8 ff ff       	call   80104174 <argstr>
80104941:	83 c4 10             	add    $0x10,%esp
80104944:	85 c0                	test   %eax,%eax
80104946:	0f 88 a0 00 00 00    	js     801049ec <sys_open+0xc3>
8010494c:	83 ec 08             	sub    $0x8,%esp
8010494f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104952:	50                   	push   %eax
80104953:	6a 01                	push   $0x1
80104955:	e8 81 f7 ff ff       	call   801040db <argint>
8010495a:	83 c4 10             	add    $0x10,%esp
8010495d:	85 c0                	test   %eax,%eax
8010495f:	0f 88 87 00 00 00    	js     801049ec <sys_open+0xc3>
    return -1;

  begin_op();
80104965:	e8 23 df ff ff       	call   8010288d <begin_op>

  if(omode & O_CREATE){
8010496a:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
8010496e:	0f 84 8b 00 00 00    	je     801049ff <sys_open+0xd6>
    ip = create(path, T_FILE, 0, 0);
80104974:	83 ec 0c             	sub    $0xc,%esp
80104977:	6a 00                	push   $0x0
80104979:	b9 00 00 00 00       	mov    $0x0,%ecx
8010497e:	ba 02 00 00 00       	mov    $0x2,%edx
80104983:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104986:	e8 69 f9 ff ff       	call   801042f4 <create>
8010498b:	89 c6                	mov    %eax,%esi
    if(ip == 0){
8010498d:	83 c4 10             	add    $0x10,%esp
80104990:	85 c0                	test   %eax,%eax
80104992:	74 5f                	je     801049f3 <sys_open+0xca>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104994:	e8 ee c2 ff ff       	call   80100c87 <filealloc>
80104999:	89 c3                	mov    %eax,%ebx
8010499b:	85 c0                	test   %eax,%eax
8010499d:	0f 84 b5 00 00 00    	je     80104a58 <sys_open+0x12f>
801049a3:	e8 be f8 ff ff       	call   80104266 <fdalloc>
801049a8:	89 c7                	mov    %eax,%edi
801049aa:	85 c0                	test   %eax,%eax
801049ac:	0f 88 a6 00 00 00    	js     80104a58 <sys_open+0x12f>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801049b2:	83 ec 0c             	sub    $0xc,%esp
801049b5:	56                   	push   %esi
801049b6:	e8 13 cd ff ff       	call   801016ce <iunlock>
  end_op();
801049bb:	e8 4b df ff ff       	call   8010290b <end_op>

  f->type = FD_INODE;
801049c0:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801049c6:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801049c9:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801049d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049d3:	83 c4 10             	add    $0x10,%esp
801049d6:	a8 01                	test   $0x1,%al
801049d8:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801049dc:	a8 03                	test   $0x3,%al
801049de:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801049e2:	89 f8                	mov    %edi,%eax
801049e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801049e7:	5b                   	pop    %ebx
801049e8:	5e                   	pop    %esi
801049e9:	5f                   	pop    %edi
801049ea:	5d                   	pop    %ebp
801049eb:	c3                   	ret    
    return -1;
801049ec:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049f1:	eb ef                	jmp    801049e2 <sys_open+0xb9>
      end_op();
801049f3:	e8 13 df ff ff       	call   8010290b <end_op>
      return -1;
801049f8:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049fd:	eb e3                	jmp    801049e2 <sys_open+0xb9>
    if((ip = namei(path)) == 0){
801049ff:	83 ec 0c             	sub    $0xc,%esp
80104a02:	ff 75 e4             	pushl  -0x1c(%ebp)
80104a05:	e8 83 d2 ff ff       	call   80101c8d <namei>
80104a0a:	89 c6                	mov    %eax,%esi
80104a0c:	83 c4 10             	add    $0x10,%esp
80104a0f:	85 c0                	test   %eax,%eax
80104a11:	74 39                	je     80104a4c <sys_open+0x123>
    ilock(ip);
80104a13:	83 ec 0c             	sub    $0xc,%esp
80104a16:	50                   	push   %eax
80104a17:	e8 ec cb ff ff       	call   80101608 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104a1c:	83 c4 10             	add    $0x10,%esp
80104a1f:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104a24:	0f 85 6a ff ff ff    	jne    80104994 <sys_open+0x6b>
80104a2a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104a2e:	0f 84 60 ff ff ff    	je     80104994 <sys_open+0x6b>
      iunlockput(ip);
80104a34:	83 ec 0c             	sub    $0xc,%esp
80104a37:	56                   	push   %esi
80104a38:	e8 7e cd ff ff       	call   801017bb <iunlockput>
      end_op();
80104a3d:	e8 c9 de ff ff       	call   8010290b <end_op>
      return -1;
80104a42:	83 c4 10             	add    $0x10,%esp
80104a45:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a4a:	eb 96                	jmp    801049e2 <sys_open+0xb9>
      end_op();
80104a4c:	e8 ba de ff ff       	call   8010290b <end_op>
      return -1;
80104a51:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a56:	eb 8a                	jmp    801049e2 <sys_open+0xb9>
    if(f)
80104a58:	85 db                	test   %ebx,%ebx
80104a5a:	74 0c                	je     80104a68 <sys_open+0x13f>
      fileclose(f);
80104a5c:	83 ec 0c             	sub    $0xc,%esp
80104a5f:	53                   	push   %ebx
80104a60:	e8 d0 c2 ff ff       	call   80100d35 <fileclose>
80104a65:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104a68:	83 ec 0c             	sub    $0xc,%esp
80104a6b:	56                   	push   %esi
80104a6c:	e8 4a cd ff ff       	call   801017bb <iunlockput>
    end_op();
80104a71:	e8 95 de ff ff       	call   8010290b <end_op>
    return -1;
80104a76:	83 c4 10             	add    $0x10,%esp
80104a79:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a7e:	e9 5f ff ff ff       	jmp    801049e2 <sys_open+0xb9>

80104a83 <sys_mkdir>:

int
sys_mkdir(void)
{
80104a83:	f3 0f 1e fb          	endbr32 
80104a87:	55                   	push   %ebp
80104a88:	89 e5                	mov    %esp,%ebp
80104a8a:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104a8d:	e8 fb dd ff ff       	call   8010288d <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104a92:	83 ec 08             	sub    $0x8,%esp
80104a95:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a98:	50                   	push   %eax
80104a99:	6a 00                	push   $0x0
80104a9b:	e8 d4 f6 ff ff       	call   80104174 <argstr>
80104aa0:	83 c4 10             	add    $0x10,%esp
80104aa3:	85 c0                	test   %eax,%eax
80104aa5:	78 36                	js     80104add <sys_mkdir+0x5a>
80104aa7:	83 ec 0c             	sub    $0xc,%esp
80104aaa:	6a 00                	push   $0x0
80104aac:	b9 00 00 00 00       	mov    $0x0,%ecx
80104ab1:	ba 01 00 00 00       	mov    $0x1,%edx
80104ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab9:	e8 36 f8 ff ff       	call   801042f4 <create>
80104abe:	83 c4 10             	add    $0x10,%esp
80104ac1:	85 c0                	test   %eax,%eax
80104ac3:	74 18                	je     80104add <sys_mkdir+0x5a>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104ac5:	83 ec 0c             	sub    $0xc,%esp
80104ac8:	50                   	push   %eax
80104ac9:	e8 ed cc ff ff       	call   801017bb <iunlockput>
  end_op();
80104ace:	e8 38 de ff ff       	call   8010290b <end_op>
  return 0;
80104ad3:	83 c4 10             	add    $0x10,%esp
80104ad6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104adb:	c9                   	leave  
80104adc:	c3                   	ret    
    end_op();
80104add:	e8 29 de ff ff       	call   8010290b <end_op>
    return -1;
80104ae2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ae7:	eb f2                	jmp    80104adb <sys_mkdir+0x58>

80104ae9 <sys_mknod>:

int
sys_mknod(void)
{
80104ae9:	f3 0f 1e fb          	endbr32 
80104aed:	55                   	push   %ebp
80104aee:	89 e5                	mov    %esp,%ebp
80104af0:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104af3:	e8 95 dd ff ff       	call   8010288d <begin_op>
  if((argstr(0, &path)) < 0 ||
80104af8:	83 ec 08             	sub    $0x8,%esp
80104afb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104afe:	50                   	push   %eax
80104aff:	6a 00                	push   $0x0
80104b01:	e8 6e f6 ff ff       	call   80104174 <argstr>
80104b06:	83 c4 10             	add    $0x10,%esp
80104b09:	85 c0                	test   %eax,%eax
80104b0b:	78 62                	js     80104b6f <sys_mknod+0x86>
     argint(1, &major) < 0 ||
80104b0d:	83 ec 08             	sub    $0x8,%esp
80104b10:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b13:	50                   	push   %eax
80104b14:	6a 01                	push   $0x1
80104b16:	e8 c0 f5 ff ff       	call   801040db <argint>
  if((argstr(0, &path)) < 0 ||
80104b1b:	83 c4 10             	add    $0x10,%esp
80104b1e:	85 c0                	test   %eax,%eax
80104b20:	78 4d                	js     80104b6f <sys_mknod+0x86>
     argint(2, &minor) < 0 ||
80104b22:	83 ec 08             	sub    $0x8,%esp
80104b25:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b28:	50                   	push   %eax
80104b29:	6a 02                	push   $0x2
80104b2b:	e8 ab f5 ff ff       	call   801040db <argint>
     argint(1, &major) < 0 ||
80104b30:	83 c4 10             	add    $0x10,%esp
80104b33:	85 c0                	test   %eax,%eax
80104b35:	78 38                	js     80104b6f <sys_mknod+0x86>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104b37:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
80104b3b:	83 ec 0c             	sub    $0xc,%esp
80104b3e:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104b42:	50                   	push   %eax
80104b43:	ba 03 00 00 00       	mov    $0x3,%edx
80104b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b4b:	e8 a4 f7 ff ff       	call   801042f4 <create>
     argint(2, &minor) < 0 ||
80104b50:	83 c4 10             	add    $0x10,%esp
80104b53:	85 c0                	test   %eax,%eax
80104b55:	74 18                	je     80104b6f <sys_mknod+0x86>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b57:	83 ec 0c             	sub    $0xc,%esp
80104b5a:	50                   	push   %eax
80104b5b:	e8 5b cc ff ff       	call   801017bb <iunlockput>
  end_op();
80104b60:	e8 a6 dd ff ff       	call   8010290b <end_op>
  return 0;
80104b65:	83 c4 10             	add    $0x10,%esp
80104b68:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b6d:	c9                   	leave  
80104b6e:	c3                   	ret    
    end_op();
80104b6f:	e8 97 dd ff ff       	call   8010290b <end_op>
    return -1;
80104b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b79:	eb f2                	jmp    80104b6d <sys_mknod+0x84>

80104b7b <sys_chdir>:

int
sys_chdir(void)
{
80104b7b:	f3 0f 1e fb          	endbr32 
80104b7f:	55                   	push   %ebp
80104b80:	89 e5                	mov    %esp,%ebp
80104b82:	56                   	push   %esi
80104b83:	53                   	push   %ebx
80104b84:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104b87:	e8 8e e7 ff ff       	call   8010331a <myproc>
80104b8c:	89 c6                	mov    %eax,%esi

  begin_op();
80104b8e:	e8 fa dc ff ff       	call   8010288d <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104b93:	83 ec 08             	sub    $0x8,%esp
80104b96:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b99:	50                   	push   %eax
80104b9a:	6a 00                	push   $0x0
80104b9c:	e8 d3 f5 ff ff       	call   80104174 <argstr>
80104ba1:	83 c4 10             	add    $0x10,%esp
80104ba4:	85 c0                	test   %eax,%eax
80104ba6:	78 52                	js     80104bfa <sys_chdir+0x7f>
80104ba8:	83 ec 0c             	sub    $0xc,%esp
80104bab:	ff 75 f4             	pushl  -0xc(%ebp)
80104bae:	e8 da d0 ff ff       	call   80101c8d <namei>
80104bb3:	89 c3                	mov    %eax,%ebx
80104bb5:	83 c4 10             	add    $0x10,%esp
80104bb8:	85 c0                	test   %eax,%eax
80104bba:	74 3e                	je     80104bfa <sys_chdir+0x7f>
    end_op();
    return -1;
  }
  ilock(ip);
80104bbc:	83 ec 0c             	sub    $0xc,%esp
80104bbf:	50                   	push   %eax
80104bc0:	e8 43 ca ff ff       	call   80101608 <ilock>
  if(ip->type != T_DIR){
80104bc5:	83 c4 10             	add    $0x10,%esp
80104bc8:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104bcd:	75 37                	jne    80104c06 <sys_chdir+0x8b>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104bcf:	83 ec 0c             	sub    $0xc,%esp
80104bd2:	53                   	push   %ebx
80104bd3:	e8 f6 ca ff ff       	call   801016ce <iunlock>
  iput(curproc->cwd);
80104bd8:	83 c4 04             	add    $0x4,%esp
80104bdb:	ff 76 6c             	pushl  0x6c(%esi)
80104bde:	e8 34 cb ff ff       	call   80101717 <iput>
  end_op();
80104be3:	e8 23 dd ff ff       	call   8010290b <end_op>
  curproc->cwd = ip;
80104be8:	89 5e 6c             	mov    %ebx,0x6c(%esi)
  return 0;
80104beb:	83 c4 10             	add    $0x10,%esp
80104bee:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bf3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104bf6:	5b                   	pop    %ebx
80104bf7:	5e                   	pop    %esi
80104bf8:	5d                   	pop    %ebp
80104bf9:	c3                   	ret    
    end_op();
80104bfa:	e8 0c dd ff ff       	call   8010290b <end_op>
    return -1;
80104bff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c04:	eb ed                	jmp    80104bf3 <sys_chdir+0x78>
    iunlockput(ip);
80104c06:	83 ec 0c             	sub    $0xc,%esp
80104c09:	53                   	push   %ebx
80104c0a:	e8 ac cb ff ff       	call   801017bb <iunlockput>
    end_op();
80104c0f:	e8 f7 dc ff ff       	call   8010290b <end_op>
    return -1;
80104c14:	83 c4 10             	add    $0x10,%esp
80104c17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c1c:	eb d5                	jmp    80104bf3 <sys_chdir+0x78>

80104c1e <sys_exec>:

int
sys_exec(void)
{
80104c1e:	f3 0f 1e fb          	endbr32 
80104c22:	55                   	push   %ebp
80104c23:	89 e5                	mov    %esp,%ebp
80104c25:	53                   	push   %ebx
80104c26:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104c2c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c2f:	50                   	push   %eax
80104c30:	6a 00                	push   $0x0
80104c32:	e8 3d f5 ff ff       	call   80104174 <argstr>
80104c37:	83 c4 10             	add    $0x10,%esp
80104c3a:	85 c0                	test   %eax,%eax
80104c3c:	78 38                	js     80104c76 <sys_exec+0x58>
80104c3e:	83 ec 08             	sub    $0x8,%esp
80104c41:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104c47:	50                   	push   %eax
80104c48:	6a 01                	push   $0x1
80104c4a:	e8 8c f4 ff ff       	call   801040db <argint>
80104c4f:	83 c4 10             	add    $0x10,%esp
80104c52:	85 c0                	test   %eax,%eax
80104c54:	78 20                	js     80104c76 <sys_exec+0x58>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104c56:	83 ec 04             	sub    $0x4,%esp
80104c59:	68 80 00 00 00       	push   $0x80
80104c5e:	6a 00                	push   $0x0
80104c60:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c66:	50                   	push   %eax
80104c67:	e8 f6 f1 ff ff       	call   80103e62 <memset>
80104c6c:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104c6f:	bb 00 00 00 00       	mov    $0x0,%ebx
80104c74:	eb 2c                	jmp    80104ca2 <sys_exec+0x84>
    return -1;
80104c76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c7b:	eb 78                	jmp    80104cf5 <sys_exec+0xd7>
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
80104c7d:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104c84:	00 00 00 00 
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80104c88:	83 ec 08             	sub    $0x8,%esp
80104c8b:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c91:	50                   	push   %eax
80104c92:	ff 75 f4             	pushl  -0xc(%ebp)
80104c95:	e8 a1 bc ff ff       	call   8010093b <exec>
80104c9a:	83 c4 10             	add    $0x10,%esp
80104c9d:	eb 56                	jmp    80104cf5 <sys_exec+0xd7>
  for(i=0;; i++){
80104c9f:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104ca2:	83 fb 1f             	cmp    $0x1f,%ebx
80104ca5:	77 49                	ja     80104cf0 <sys_exec+0xd2>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104ca7:	83 ec 08             	sub    $0x8,%esp
80104caa:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104cb0:	50                   	push   %eax
80104cb1:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104cb7:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104cba:	50                   	push   %eax
80104cbb:	e8 94 f3 ff ff       	call   80104054 <fetchint>
80104cc0:	83 c4 10             	add    $0x10,%esp
80104cc3:	85 c0                	test   %eax,%eax
80104cc5:	78 33                	js     80104cfa <sys_exec+0xdc>
    if(uarg == 0){
80104cc7:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104ccd:	85 c0                	test   %eax,%eax
80104ccf:	74 ac                	je     80104c7d <sys_exec+0x5f>
    if(fetchstr(uarg, &argv[i]) < 0)
80104cd1:	83 ec 08             	sub    $0x8,%esp
80104cd4:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104cdb:	52                   	push   %edx
80104cdc:	50                   	push   %eax
80104cdd:	e8 b3 f3 ff ff       	call   80104095 <fetchstr>
80104ce2:	83 c4 10             	add    $0x10,%esp
80104ce5:	85 c0                	test   %eax,%eax
80104ce7:	79 b6                	jns    80104c9f <sys_exec+0x81>
      return -1;
80104ce9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cee:	eb 05                	jmp    80104cf5 <sys_exec+0xd7>
      return -1;
80104cf0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104cf5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104cf8:	c9                   	leave  
80104cf9:	c3                   	ret    
      return -1;
80104cfa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cff:	eb f4                	jmp    80104cf5 <sys_exec+0xd7>

80104d01 <sys_pipe>:

int
sys_pipe(void)
{
80104d01:	f3 0f 1e fb          	endbr32 
80104d05:	55                   	push   %ebp
80104d06:	89 e5                	mov    %esp,%ebp
80104d08:	53                   	push   %ebx
80104d09:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104d0c:	6a 08                	push   $0x8
80104d0e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d11:	50                   	push   %eax
80104d12:	6a 00                	push   $0x0
80104d14:	e8 ee f3 ff ff       	call   80104107 <argptr>
80104d19:	83 c4 10             	add    $0x10,%esp
80104d1c:	85 c0                	test   %eax,%eax
80104d1e:	78 79                	js     80104d99 <sys_pipe+0x98>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104d20:	83 ec 08             	sub    $0x8,%esp
80104d23:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d26:	50                   	push   %eax
80104d27:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d2a:	50                   	push   %eax
80104d2b:	e8 02 e1 ff ff       	call   80102e32 <pipealloc>
80104d30:	83 c4 10             	add    $0x10,%esp
80104d33:	85 c0                	test   %eax,%eax
80104d35:	78 69                	js     80104da0 <sys_pipe+0x9f>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104d37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d3a:	e8 27 f5 ff ff       	call   80104266 <fdalloc>
80104d3f:	89 c3                	mov    %eax,%ebx
80104d41:	85 c0                	test   %eax,%eax
80104d43:	78 21                	js     80104d66 <sys_pipe+0x65>
80104d45:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d48:	e8 19 f5 ff ff       	call   80104266 <fdalloc>
80104d4d:	85 c0                	test   %eax,%eax
80104d4f:	78 15                	js     80104d66 <sys_pipe+0x65>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104d51:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d54:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104d56:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d59:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104d5c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d64:	c9                   	leave  
80104d65:	c3                   	ret    
    if(fd0 >= 0)
80104d66:	85 db                	test   %ebx,%ebx
80104d68:	79 20                	jns    80104d8a <sys_pipe+0x89>
    fileclose(rf);
80104d6a:	83 ec 0c             	sub    $0xc,%esp
80104d6d:	ff 75 f0             	pushl  -0x10(%ebp)
80104d70:	e8 c0 bf ff ff       	call   80100d35 <fileclose>
    fileclose(wf);
80104d75:	83 c4 04             	add    $0x4,%esp
80104d78:	ff 75 ec             	pushl  -0x14(%ebp)
80104d7b:	e8 b5 bf ff ff       	call   80100d35 <fileclose>
    return -1;
80104d80:	83 c4 10             	add    $0x10,%esp
80104d83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d88:	eb d7                	jmp    80104d61 <sys_pipe+0x60>
      myproc()->ofile[fd0] = 0;
80104d8a:	e8 8b e5 ff ff       	call   8010331a <myproc>
80104d8f:	c7 44 98 2c 00 00 00 	movl   $0x0,0x2c(%eax,%ebx,4)
80104d96:	00 
80104d97:	eb d1                	jmp    80104d6a <sys_pipe+0x69>
    return -1;
80104d99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d9e:	eb c1                	jmp    80104d61 <sys_pipe+0x60>
    return -1;
80104da0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104da5:	eb ba                	jmp    80104d61 <sys_pipe+0x60>

80104da7 <sys_fork>:
#include "pdx-kernel.h"
#endif // PDX_XV6

int
sys_fork(void)
{
80104da7:	f3 0f 1e fb          	endbr32 
80104dab:	55                   	push   %ebp
80104dac:	89 e5                	mov    %esp,%ebp
80104dae:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104db1:	e8 ea e6 ff ff       	call   801034a0 <fork>
}
80104db6:	c9                   	leave  
80104db7:	c3                   	ret    

80104db8 <sys_exit>:

int
sys_exit(void)
{
80104db8:	f3 0f 1e fb          	endbr32 
80104dbc:	55                   	push   %ebp
80104dbd:	89 e5                	mov    %esp,%ebp
80104dbf:	83 ec 08             	sub    $0x8,%esp
  exit();
80104dc2:	e8 30 e9 ff ff       	call   801036f7 <exit>
  return 0;  // not reached
}
80104dc7:	b8 00 00 00 00       	mov    $0x0,%eax
80104dcc:	c9                   	leave  
80104dcd:	c3                   	ret    

80104dce <sys_wait>:

int
sys_wait(void)
{
80104dce:	f3 0f 1e fb          	endbr32 
80104dd2:	55                   	push   %ebp
80104dd3:	89 e5                	mov    %esp,%ebp
80104dd5:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104dd8:	e8 be ea ff ff       	call   8010389b <wait>
}
80104ddd:	c9                   	leave  
80104dde:	c3                   	ret    

80104ddf <sys_kill>:

int
sys_kill(void)
{
80104ddf:	f3 0f 1e fb          	endbr32 
80104de3:	55                   	push   %ebp
80104de4:	89 e5                	mov    %esp,%ebp
80104de6:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104de9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dec:	50                   	push   %eax
80104ded:	6a 00                	push   $0x0
80104def:	e8 e7 f2 ff ff       	call   801040db <argint>
80104df4:	83 c4 10             	add    $0x10,%esp
80104df7:	85 c0                	test   %eax,%eax
80104df9:	78 10                	js     80104e0b <sys_kill+0x2c>
    return -1;
  return kill(pid);
80104dfb:	83 ec 0c             	sub    $0xc,%esp
80104dfe:	ff 75 f4             	pushl  -0xc(%ebp)
80104e01:	e8 9a eb ff ff       	call   801039a0 <kill>
80104e06:	83 c4 10             	add    $0x10,%esp
}
80104e09:	c9                   	leave  
80104e0a:	c3                   	ret    
    return -1;
80104e0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e10:	eb f7                	jmp    80104e09 <sys_kill+0x2a>

80104e12 <sys_getpid>:

int
sys_getpid(void)
{
80104e12:	f3 0f 1e fb          	endbr32 
80104e16:	55                   	push   %ebp
80104e17:	89 e5                	mov    %esp,%ebp
80104e19:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104e1c:	e8 f9 e4 ff ff       	call   8010331a <myproc>
80104e21:	8b 40 14             	mov    0x14(%eax),%eax
}
80104e24:	c9                   	leave  
80104e25:	c3                   	ret    

80104e26 <sys_sbrk>:

int
sys_sbrk(void)
{
80104e26:	f3 0f 1e fb          	endbr32 
80104e2a:	55                   	push   %ebp
80104e2b:	89 e5                	mov    %esp,%ebp
80104e2d:	53                   	push   %ebx
80104e2e:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104e31:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e34:	50                   	push   %eax
80104e35:	6a 00                	push   $0x0
80104e37:	e8 9f f2 ff ff       	call   801040db <argint>
80104e3c:	83 c4 10             	add    $0x10,%esp
80104e3f:	85 c0                	test   %eax,%eax
80104e41:	78 21                	js     80104e64 <sys_sbrk+0x3e>
    return -1;
  addr = myproc()->sz;
80104e43:	e8 d2 e4 ff ff       	call   8010331a <myproc>
80104e48:	8b 58 04             	mov    0x4(%eax),%ebx
  if(growproc(n) < 0)
80104e4b:	83 ec 0c             	sub    $0xc,%esp
80104e4e:	ff 75 f4             	pushl  -0xc(%ebp)
80104e51:	e8 d9 e5 ff ff       	call   8010342f <growproc>
80104e56:	83 c4 10             	add    $0x10,%esp
80104e59:	85 c0                	test   %eax,%eax
80104e5b:	78 0e                	js     80104e6b <sys_sbrk+0x45>
    return -1;
  return addr;
}
80104e5d:	89 d8                	mov    %ebx,%eax
80104e5f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e62:	c9                   	leave  
80104e63:	c3                   	ret    
    return -1;
80104e64:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e69:	eb f2                	jmp    80104e5d <sys_sbrk+0x37>
    return -1;
80104e6b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e70:	eb eb                	jmp    80104e5d <sys_sbrk+0x37>

80104e72 <sys_date>:

int
sys_date ( void )
{
80104e72:	f3 0f 1e fb          	endbr32 
80104e76:	55                   	push   %ebp
80104e77:	89 e5                	mov    %esp,%ebp
80104e79:	83 ec 1c             	sub    $0x1c,%esp
  struct rtcdate *d ;
  if (argptr ( 0 ,( void*)&d , sizeof ( struct rtcdate)) < 0)
80104e7c:	6a 18                	push   $0x18
80104e7e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e81:	50                   	push   %eax
80104e82:	6a 00                	push   $0x0
80104e84:	e8 7e f2 ff ff       	call   80104107 <argptr>
80104e89:	83 c4 10             	add    $0x10,%esp
80104e8c:	85 c0                	test   %eax,%eax
80104e8e:	78 15                	js     80104ea5 <sys_date+0x33>
    return -1;
  cmostime(d);
80104e90:	83 ec 0c             	sub    $0xc,%esp
80104e93:	ff 75 f4             	pushl  -0xc(%ebp)
80104e96:	e8 9f d6 ff ff       	call   8010253a <cmostime>
  return 0;
80104e9b:	83 c4 10             	add    $0x10,%esp
80104e9e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ea3:	c9                   	leave  
80104ea4:	c3                   	ret    
    return -1;
80104ea5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eaa:	eb f7                	jmp    80104ea3 <sys_date+0x31>

80104eac <sys_sleep>:

int
sys_sleep(void)
{
80104eac:	f3 0f 1e fb          	endbr32 
80104eb0:	55                   	push   %ebp
80104eb1:	89 e5                	mov    %esp,%ebp
80104eb3:	53                   	push   %ebx
80104eb4:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104eb7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104eba:	50                   	push   %eax
80104ebb:	6a 00                	push   $0x0
80104ebd:	e8 19 f2 ff ff       	call   801040db <argint>
80104ec2:	83 c4 10             	add    $0x10,%esp
80104ec5:	85 c0                	test   %eax,%eax
80104ec7:	78 3b                	js     80104f04 <sys_sleep+0x58>
    return -1;
  ticks0 = ticks;
80104ec9:	8b 1d 80 55 11 80    	mov    0x80115580,%ebx
  while(ticks - ticks0 < n){
80104ecf:	a1 80 55 11 80       	mov    0x80115580,%eax
80104ed4:	29 d8                	sub    %ebx,%eax
80104ed6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104ed9:	73 1f                	jae    80104efa <sys_sleep+0x4e>
    if(myproc()->killed){
80104edb:	e8 3a e4 ff ff       	call   8010331a <myproc>
80104ee0:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
80104ee4:	75 25                	jne    80104f0b <sys_sleep+0x5f>
      return -1;
    }
    sleep(&ticks, (struct spinlock *)0);
80104ee6:	83 ec 08             	sub    $0x8,%esp
80104ee9:	6a 00                	push   $0x0
80104eeb:	68 80 55 11 80       	push   $0x80115580
80104ef0:	e8 12 e9 ff ff       	call   80103807 <sleep>
80104ef5:	83 c4 10             	add    $0x10,%esp
80104ef8:	eb d5                	jmp    80104ecf <sys_sleep+0x23>
  }
  return 0;
80104efa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104eff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f02:	c9                   	leave  
80104f03:	c3                   	ret    
    return -1;
80104f04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f09:	eb f4                	jmp    80104eff <sys_sleep+0x53>
      return -1;
80104f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f10:	eb ed                	jmp    80104eff <sys_sleep+0x53>

80104f12 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104f12:	f3 0f 1e fb          	endbr32 
  uint xticks;

  xticks = ticks;
  return xticks;
}
80104f16:	a1 80 55 11 80       	mov    0x80115580,%eax
80104f1b:	c3                   	ret    

80104f1c <sys_halt>:

#ifdef PDX_XV6
// shutdown QEMU
int
sys_halt(void)
{
80104f1c:	f3 0f 1e fb          	endbr32 
80104f20:	55                   	push   %ebp
80104f21:	89 e5                	mov    %esp,%ebp
80104f23:	83 ec 08             	sub    $0x8,%esp
  do_shutdown();  // never returns
80104f26:	e8 2e b8 ff ff       	call   80100759 <do_shutdown>
  return 0;
}
80104f2b:	b8 00 00 00 00       	mov    $0x0,%eax
80104f30:	c9                   	leave  
80104f31:	c3                   	ret    

80104f32 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104f32:	1e                   	push   %ds
  pushl %es
80104f33:	06                   	push   %es
  pushl %fs
80104f34:	0f a0                	push   %fs
  pushl %gs
80104f36:	0f a8                	push   %gs
  pushal
80104f38:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104f39:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104f3d:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104f3f:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104f41:	54                   	push   %esp
  call trap
80104f42:	e8 cf 00 00 00       	call   80105016 <trap>
  addl $4, %esp
80104f47:	83 c4 04             	add    $0x4,%esp

80104f4a <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104f4a:	61                   	popa   
  popl %gs
80104f4b:	0f a9                	pop    %gs
  popl %fs
80104f4d:	0f a1                	pop    %fs
  popl %es
80104f4f:	07                   	pop    %es
  popl %ds
80104f50:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104f51:	83 c4 08             	add    $0x8,%esp
  iret
80104f54:	cf                   	iret   

80104f55 <tvinit>:
uint ticks;
#endif // PDX_XV6

void
tvinit(void)
{
80104f55:	f3 0f 1e fb          	endbr32 
  int i;

  for(i = 0; i < 256; i++)
80104f59:	b8 00 00 00 00       	mov    $0x0,%eax
80104f5e:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f63:	7f 4c                	jg     80104fb1 <tvinit+0x5c>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104f65:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104f6c:	66 89 0c c5 80 4d 11 	mov    %cx,-0x7feeb280(,%eax,8)
80104f73:	80 
80104f74:	66 c7 04 c5 82 4d 11 	movw   $0x8,-0x7feeb27e(,%eax,8)
80104f7b:	80 08 00 
80104f7e:	c6 04 c5 84 4d 11 80 	movb   $0x0,-0x7feeb27c(,%eax,8)
80104f85:	00 
80104f86:	0f b6 14 c5 85 4d 11 	movzbl -0x7feeb27b(,%eax,8),%edx
80104f8d:	80 
80104f8e:	83 e2 f0             	and    $0xfffffff0,%edx
80104f91:	83 ca 0e             	or     $0xe,%edx
80104f94:	83 e2 8f             	and    $0xffffff8f,%edx
80104f97:	83 ca 80             	or     $0xffffff80,%edx
80104f9a:	88 14 c5 85 4d 11 80 	mov    %dl,-0x7feeb27b(,%eax,8)
80104fa1:	c1 e9 10             	shr    $0x10,%ecx
80104fa4:	66 89 0c c5 86 4d 11 	mov    %cx,-0x7feeb27a(,%eax,8)
80104fab:	80 
  for(i = 0; i < 256; i++)
80104fac:	83 c0 01             	add    $0x1,%eax
80104faf:	eb ad                	jmp    80104f5e <tvinit+0x9>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104fb1:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104fb7:	66 89 15 80 4f 11 80 	mov    %dx,0x80114f80
80104fbe:	66 c7 05 82 4f 11 80 	movw   $0x8,0x80114f82
80104fc5:	08 00 
80104fc7:	c6 05 84 4f 11 80 00 	movb   $0x0,0x80114f84
80104fce:	0f b6 05 85 4f 11 80 	movzbl 0x80114f85,%eax
80104fd5:	83 c8 0f             	or     $0xf,%eax
80104fd8:	83 e0 ef             	and    $0xffffffef,%eax
80104fdb:	83 c8 e0             	or     $0xffffffe0,%eax
80104fde:	a2 85 4f 11 80       	mov    %al,0x80114f85
80104fe3:	c1 ea 10             	shr    $0x10,%edx
80104fe6:	66 89 15 86 4f 11 80 	mov    %dx,0x80114f86

#ifndef PDX_XV6
  initlock(&tickslock, "time");
#endif // PDX_XV6
}
80104fed:	c3                   	ret    

80104fee <idtinit>:

void
idtinit(void)
{
80104fee:	f3 0f 1e fb          	endbr32 
80104ff2:	55                   	push   %ebp
80104ff3:	89 e5                	mov    %esp,%ebp
80104ff5:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104ff8:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104ffe:	b8 80 4d 11 80       	mov    $0x80114d80,%eax
80105003:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80105007:	c1 e8 10             	shr    $0x10,%eax
8010500a:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010500e:	8d 45 fa             	lea    -0x6(%ebp),%eax
80105011:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80105014:	c9                   	leave  
80105015:	c3                   	ret    

80105016 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80105016:	f3 0f 1e fb          	endbr32 
8010501a:	55                   	push   %ebp
8010501b:	89 e5                	mov    %esp,%ebp
8010501d:	57                   	push   %edi
8010501e:	56                   	push   %esi
8010501f:	53                   	push   %ebx
80105020:	83 ec 1c             	sub    $0x1c,%esp
80105023:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105026:	8b 43 30             	mov    0x30(%ebx),%eax
80105029:	83 f8 40             	cmp    $0x40,%eax
8010502c:	74 14                	je     80105042 <trap+0x2c>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
8010502e:	83 e8 20             	sub    $0x20,%eax
80105031:	83 f8 1f             	cmp    $0x1f,%eax
80105034:	0f 87 23 01 00 00    	ja     8010515d <trap+0x147>
8010503a:	3e ff 24 85 04 6f 10 	notrack jmp *-0x7fef90fc(,%eax,4)
80105041:	80 
    if(myproc()->killed)
80105042:	e8 d3 e2 ff ff       	call   8010331a <myproc>
80105047:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
8010504b:	75 1f                	jne    8010506c <trap+0x56>
    myproc()->tf = tf;
8010504d:	e8 c8 e2 ff ff       	call   8010331a <myproc>
80105052:	89 58 1c             	mov    %ebx,0x1c(%eax)
    syscall();
80105055:	e8 51 f1 ff ff       	call   801041ab <syscall>
    if(myproc()->killed)
8010505a:	e8 bb e2 ff ff       	call   8010331a <myproc>
8010505f:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
80105063:	74 7e                	je     801050e3 <trap+0xcd>
      exit();
80105065:	e8 8d e6 ff ff       	call   801036f7 <exit>
    return;
8010506a:	eb 77                	jmp    801050e3 <trap+0xcd>
      exit();
8010506c:	e8 86 e6 ff ff       	call   801036f7 <exit>
80105071:	eb da                	jmp    8010504d <trap+0x37>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105073:	e8 83 e2 ff ff       	call   801032fb <cpuid>
80105078:	85 c0                	test   %eax,%eax
8010507a:	74 6f                	je     801050eb <trap+0xd5>
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
#endif // PDX_XV6
    }
    lapiceoi();
8010507c:	e8 f0 d3 ff ff       	call   80102471 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105081:	e8 94 e2 ff ff       	call   8010331a <myproc>
80105086:	85 c0                	test   %eax,%eax
80105088:	74 1c                	je     801050a6 <trap+0x90>
8010508a:	e8 8b e2 ff ff       	call   8010331a <myproc>
8010508f:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
80105093:	74 11                	je     801050a6 <trap+0x90>
80105095:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105099:	83 e0 03             	and    $0x3,%eax
8010509c:	66 83 f8 03          	cmp    $0x3,%ax
801050a0:	0f 84 4a 01 00 00    	je     801051f0 <trap+0x1da>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
801050a6:	e8 6f e2 ff ff       	call   8010331a <myproc>
801050ab:	85 c0                	test   %eax,%eax
801050ad:	74 0f                	je     801050be <trap+0xa8>
801050af:	e8 66 e2 ff ff       	call   8010331a <myproc>
801050b4:	83 78 10 04          	cmpl   $0x4,0x10(%eax)
801050b8:	0f 84 3c 01 00 00    	je     801051fa <trap+0x1e4>
    tf->trapno == T_IRQ0+IRQ_TIMER)
#endif // PDX_XV6
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801050be:	e8 57 e2 ff ff       	call   8010331a <myproc>
801050c3:	85 c0                	test   %eax,%eax
801050c5:	74 1c                	je     801050e3 <trap+0xcd>
801050c7:	e8 4e e2 ff ff       	call   8010331a <myproc>
801050cc:	83 78 28 00          	cmpl   $0x0,0x28(%eax)
801050d0:	74 11                	je     801050e3 <trap+0xcd>
801050d2:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801050d6:	83 e0 03             	and    $0x3,%eax
801050d9:	66 83 f8 03          	cmp    $0x3,%ax
801050dd:	0f 84 4a 01 00 00    	je     8010522d <trap+0x217>
    exit();
}
801050e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801050e6:	5b                   	pop    %ebx
801050e7:	5e                   	pop    %esi
801050e8:	5f                   	pop    %edi
801050e9:	5d                   	pop    %ebp
801050ea:	c3                   	ret    
// atom_inc() necessary for removal of tickslock
// other atomic ops added for completeness
static inline void
atom_inc(volatile int *num)
{
  asm volatile ( "lock incl %0" : "=m" (*num));
801050eb:	f0 ff 05 80 55 11 80 	lock incl 0x80115580
      wakeup(&ticks);
801050f2:	83 ec 0c             	sub    $0xc,%esp
801050f5:	68 80 55 11 80       	push   $0x80115580
801050fa:	e8 74 e8 ff ff       	call   80103973 <wakeup>
801050ff:	83 c4 10             	add    $0x10,%esp
80105102:	e9 75 ff ff ff       	jmp    8010507c <trap+0x66>
    ideintr();
80105107:	e8 1e cd ff ff       	call   80101e2a <ideintr>
    lapiceoi();
8010510c:	e8 60 d3 ff ff       	call   80102471 <lapiceoi>
    break;
80105111:	e9 6b ff ff ff       	jmp    80105081 <trap+0x6b>
    kbdintr();
80105116:	e8 93 d1 ff ff       	call   801022ae <kbdintr>
    lapiceoi();
8010511b:	e8 51 d3 ff ff       	call   80102471 <lapiceoi>
    break;
80105120:	e9 5c ff ff ff       	jmp    80105081 <trap+0x6b>
    uartintr();
80105125:	e8 29 02 00 00       	call   80105353 <uartintr>
    lapiceoi();
8010512a:	e8 42 d3 ff ff       	call   80102471 <lapiceoi>
    break;
8010512f:	e9 4d ff ff ff       	jmp    80105081 <trap+0x6b>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105134:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105137:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010513b:	e8 bb e1 ff ff       	call   801032fb <cpuid>
80105140:	57                   	push   %edi
80105141:	0f b7 f6             	movzwl %si,%esi
80105144:	56                   	push   %esi
80105145:	50                   	push   %eax
80105146:	68 64 6e 10 80       	push   $0x80106e64
8010514b:	e8 d9 b4 ff ff       	call   80100629 <cprintf>
    lapiceoi();
80105150:	e8 1c d3 ff ff       	call   80102471 <lapiceoi>
    break;
80105155:	83 c4 10             	add    $0x10,%esp
80105158:	e9 24 ff ff ff       	jmp    80105081 <trap+0x6b>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010515d:	e8 b8 e1 ff ff       	call   8010331a <myproc>
80105162:	85 c0                	test   %eax,%eax
80105164:	74 5f                	je     801051c5 <trap+0x1af>
80105166:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010516a:	74 59                	je     801051c5 <trap+0x1af>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010516c:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010516f:	8b 43 38             	mov    0x38(%ebx),%eax
80105172:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105175:	e8 81 e1 ff ff       	call   801032fb <cpuid>
8010517a:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010517d:	8b 4b 34             	mov    0x34(%ebx),%ecx
80105180:	89 4d dc             	mov    %ecx,-0x24(%ebp)
80105183:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105186:	e8 8f e1 ff ff       	call   8010331a <myproc>
8010518b:	8d 50 70             	lea    0x70(%eax),%edx
8010518e:	89 55 d8             	mov    %edx,-0x28(%ebp)
80105191:	e8 84 e1 ff ff       	call   8010331a <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105196:	57                   	push   %edi
80105197:	ff 75 e4             	pushl  -0x1c(%ebp)
8010519a:	ff 75 e0             	pushl  -0x20(%ebp)
8010519d:	ff 75 dc             	pushl  -0x24(%ebp)
801051a0:	56                   	push   %esi
801051a1:	ff 75 d8             	pushl  -0x28(%ebp)
801051a4:	ff 70 14             	pushl  0x14(%eax)
801051a7:	68 bc 6e 10 80       	push   $0x80106ebc
801051ac:	e8 78 b4 ff ff       	call   80100629 <cprintf>
    myproc()->killed = 1;
801051b1:	83 c4 20             	add    $0x20,%esp
801051b4:	e8 61 e1 ff ff       	call   8010331a <myproc>
801051b9:	c7 40 28 01 00 00 00 	movl   $0x1,0x28(%eax)
801051c0:	e9 bc fe ff ff       	jmp    80105081 <trap+0x6b>
801051c5:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801051c8:	8b 73 38             	mov    0x38(%ebx),%esi
801051cb:	e8 2b e1 ff ff       	call   801032fb <cpuid>
801051d0:	83 ec 0c             	sub    $0xc,%esp
801051d3:	57                   	push   %edi
801051d4:	56                   	push   %esi
801051d5:	50                   	push   %eax
801051d6:	ff 73 30             	pushl  0x30(%ebx)
801051d9:	68 88 6e 10 80       	push   $0x80106e88
801051de:	e8 46 b4 ff ff       	call   80100629 <cprintf>
      panic("trap");
801051e3:	83 c4 14             	add    $0x14,%esp
801051e6:	68 ff 6e 10 80       	push   $0x80106eff
801051eb:	e8 6c b1 ff ff       	call   8010035c <panic>
    exit();
801051f0:	e8 02 e5 ff ff       	call   801036f7 <exit>
801051f5:	e9 ac fe ff ff       	jmp    801050a6 <trap+0x90>
  if(myproc() && myproc()->state == RUNNING &&
801051fa:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801051fe:	0f 85 ba fe ff ff    	jne    801050be <trap+0xa8>
    tf->trapno == T_IRQ0+IRQ_TIMER && ticks%SCHED_INTERVAL==0)
80105204:	8b 0d 80 55 11 80    	mov    0x80115580,%ecx
8010520a:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
8010520f:	89 c8                	mov    %ecx,%eax
80105211:	f7 e2                	mul    %edx
80105213:	c1 ea 03             	shr    $0x3,%edx
80105216:	8d 04 92             	lea    (%edx,%edx,4),%eax
80105219:	01 c0                	add    %eax,%eax
8010521b:	39 c1                	cmp    %eax,%ecx
8010521d:	0f 85 9b fe ff ff    	jne    801050be <trap+0xa8>
    yield();
80105223:	e8 a0 e5 ff ff       	call   801037c8 <yield>
80105228:	e9 91 fe ff ff       	jmp    801050be <trap+0xa8>
    exit();
8010522d:	e8 c5 e4 ff ff       	call   801036f7 <exit>
80105232:	e9 ac fe ff ff       	jmp    801050e3 <trap+0xcd>

80105237 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105237:	f3 0f 1e fb          	endbr32 
  if(!uart)
8010523b:	83 3d 14 c6 10 80 00 	cmpl   $0x0,0x8010c614
80105242:	74 14                	je     80105258 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105244:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105249:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010524a:	a8 01                	test   $0x1,%al
8010524c:	74 10                	je     8010525e <uartgetc+0x27>
8010524e:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105253:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105254:	0f b6 c0             	movzbl %al,%eax
80105257:	c3                   	ret    
    return -1;
80105258:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010525d:	c3                   	ret    
    return -1;
8010525e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105263:	c3                   	ret    

80105264 <uartputc>:
{
80105264:	f3 0f 1e fb          	endbr32 
  if(!uart)
80105268:	83 3d 14 c6 10 80 00 	cmpl   $0x0,0x8010c614
8010526f:	74 3b                	je     801052ac <uartputc+0x48>
{
80105271:	55                   	push   %ebp
80105272:	89 e5                	mov    %esp,%ebp
80105274:	53                   	push   %ebx
80105275:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105278:	bb 00 00 00 00       	mov    $0x0,%ebx
8010527d:	83 fb 7f             	cmp    $0x7f,%ebx
80105280:	7f 1c                	jg     8010529e <uartputc+0x3a>
80105282:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105287:	ec                   	in     (%dx),%al
80105288:	a8 20                	test   $0x20,%al
8010528a:	75 12                	jne    8010529e <uartputc+0x3a>
    microdelay(10);
8010528c:	83 ec 0c             	sub    $0xc,%esp
8010528f:	6a 0a                	push   $0xa
80105291:	e8 00 d2 ff ff       	call   80102496 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105296:	83 c3 01             	add    $0x1,%ebx
80105299:	83 c4 10             	add    $0x10,%esp
8010529c:	eb df                	jmp    8010527d <uartputc+0x19>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010529e:	8b 45 08             	mov    0x8(%ebp),%eax
801052a1:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052a6:	ee                   	out    %al,(%dx)
}
801052a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801052aa:	c9                   	leave  
801052ab:	c3                   	ret    
801052ac:	c3                   	ret    

801052ad <uartinit>:
{
801052ad:	f3 0f 1e fb          	endbr32 
801052b1:	55                   	push   %ebp
801052b2:	89 e5                	mov    %esp,%ebp
801052b4:	56                   	push   %esi
801052b5:	53                   	push   %ebx
801052b6:	b9 00 00 00 00       	mov    $0x0,%ecx
801052bb:	ba fa 03 00 00       	mov    $0x3fa,%edx
801052c0:	89 c8                	mov    %ecx,%eax
801052c2:	ee                   	out    %al,(%dx)
801052c3:	be fb 03 00 00       	mov    $0x3fb,%esi
801052c8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801052cd:	89 f2                	mov    %esi,%edx
801052cf:	ee                   	out    %al,(%dx)
801052d0:	b8 0c 00 00 00       	mov    $0xc,%eax
801052d5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052da:	ee                   	out    %al,(%dx)
801052db:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801052e0:	89 c8                	mov    %ecx,%eax
801052e2:	89 da                	mov    %ebx,%edx
801052e4:	ee                   	out    %al,(%dx)
801052e5:	b8 03 00 00 00       	mov    $0x3,%eax
801052ea:	89 f2                	mov    %esi,%edx
801052ec:	ee                   	out    %al,(%dx)
801052ed:	ba fc 03 00 00       	mov    $0x3fc,%edx
801052f2:	89 c8                	mov    %ecx,%eax
801052f4:	ee                   	out    %al,(%dx)
801052f5:	b8 01 00 00 00       	mov    $0x1,%eax
801052fa:	89 da                	mov    %ebx,%edx
801052fc:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052fd:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105302:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105303:	3c ff                	cmp    $0xff,%al
80105305:	74 45                	je     8010534c <uartinit+0x9f>
  uart = 1;
80105307:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
8010530e:	00 00 00 
80105311:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105316:	ec                   	in     (%dx),%al
80105317:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010531c:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010531d:	83 ec 08             	sub    $0x8,%esp
80105320:	6a 00                	push   $0x0
80105322:	6a 04                	push   $0x4
80105324:	e8 10 cd ff ff       	call   80102039 <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105329:	83 c4 10             	add    $0x10,%esp
8010532c:	bb 84 6f 10 80       	mov    $0x80106f84,%ebx
80105331:	eb 12                	jmp    80105345 <uartinit+0x98>
    uartputc(*p);
80105333:	83 ec 0c             	sub    $0xc,%esp
80105336:	0f be c0             	movsbl %al,%eax
80105339:	50                   	push   %eax
8010533a:	e8 25 ff ff ff       	call   80105264 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010533f:	83 c3 01             	add    $0x1,%ebx
80105342:	83 c4 10             	add    $0x10,%esp
80105345:	0f b6 03             	movzbl (%ebx),%eax
80105348:	84 c0                	test   %al,%al
8010534a:	75 e7                	jne    80105333 <uartinit+0x86>
}
8010534c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010534f:	5b                   	pop    %ebx
80105350:	5e                   	pop    %esi
80105351:	5d                   	pop    %ebp
80105352:	c3                   	ret    

80105353 <uartintr>:

void
uartintr(void)
{
80105353:	f3 0f 1e fb          	endbr32 
80105357:	55                   	push   %ebp
80105358:	89 e5                	mov    %esp,%ebp
8010535a:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
8010535d:	68 37 52 10 80       	push   $0x80105237
80105362:	e8 17 b4 ff ff       	call   8010077e <consoleintr>
}
80105367:	83 c4 10             	add    $0x10,%esp
8010536a:	c9                   	leave  
8010536b:	c3                   	ret    

8010536c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010536c:	6a 00                	push   $0x0
  pushl $0
8010536e:	6a 00                	push   $0x0
  jmp alltraps
80105370:	e9 bd fb ff ff       	jmp    80104f32 <alltraps>

80105375 <vector1>:
.globl vector1
vector1:
  pushl $0
80105375:	6a 00                	push   $0x0
  pushl $1
80105377:	6a 01                	push   $0x1
  jmp alltraps
80105379:	e9 b4 fb ff ff       	jmp    80104f32 <alltraps>

8010537e <vector2>:
.globl vector2
vector2:
  pushl $0
8010537e:	6a 00                	push   $0x0
  pushl $2
80105380:	6a 02                	push   $0x2
  jmp alltraps
80105382:	e9 ab fb ff ff       	jmp    80104f32 <alltraps>

80105387 <vector3>:
.globl vector3
vector3:
  pushl $0
80105387:	6a 00                	push   $0x0
  pushl $3
80105389:	6a 03                	push   $0x3
  jmp alltraps
8010538b:	e9 a2 fb ff ff       	jmp    80104f32 <alltraps>

80105390 <vector4>:
.globl vector4
vector4:
  pushl $0
80105390:	6a 00                	push   $0x0
  pushl $4
80105392:	6a 04                	push   $0x4
  jmp alltraps
80105394:	e9 99 fb ff ff       	jmp    80104f32 <alltraps>

80105399 <vector5>:
.globl vector5
vector5:
  pushl $0
80105399:	6a 00                	push   $0x0
  pushl $5
8010539b:	6a 05                	push   $0x5
  jmp alltraps
8010539d:	e9 90 fb ff ff       	jmp    80104f32 <alltraps>

801053a2 <vector6>:
.globl vector6
vector6:
  pushl $0
801053a2:	6a 00                	push   $0x0
  pushl $6
801053a4:	6a 06                	push   $0x6
  jmp alltraps
801053a6:	e9 87 fb ff ff       	jmp    80104f32 <alltraps>

801053ab <vector7>:
.globl vector7
vector7:
  pushl $0
801053ab:	6a 00                	push   $0x0
  pushl $7
801053ad:	6a 07                	push   $0x7
  jmp alltraps
801053af:	e9 7e fb ff ff       	jmp    80104f32 <alltraps>

801053b4 <vector8>:
.globl vector8
vector8:
  pushl $8
801053b4:	6a 08                	push   $0x8
  jmp alltraps
801053b6:	e9 77 fb ff ff       	jmp    80104f32 <alltraps>

801053bb <vector9>:
.globl vector9
vector9:
  pushl $0
801053bb:	6a 00                	push   $0x0
  pushl $9
801053bd:	6a 09                	push   $0x9
  jmp alltraps
801053bf:	e9 6e fb ff ff       	jmp    80104f32 <alltraps>

801053c4 <vector10>:
.globl vector10
vector10:
  pushl $10
801053c4:	6a 0a                	push   $0xa
  jmp alltraps
801053c6:	e9 67 fb ff ff       	jmp    80104f32 <alltraps>

801053cb <vector11>:
.globl vector11
vector11:
  pushl $11
801053cb:	6a 0b                	push   $0xb
  jmp alltraps
801053cd:	e9 60 fb ff ff       	jmp    80104f32 <alltraps>

801053d2 <vector12>:
.globl vector12
vector12:
  pushl $12
801053d2:	6a 0c                	push   $0xc
  jmp alltraps
801053d4:	e9 59 fb ff ff       	jmp    80104f32 <alltraps>

801053d9 <vector13>:
.globl vector13
vector13:
  pushl $13
801053d9:	6a 0d                	push   $0xd
  jmp alltraps
801053db:	e9 52 fb ff ff       	jmp    80104f32 <alltraps>

801053e0 <vector14>:
.globl vector14
vector14:
  pushl $14
801053e0:	6a 0e                	push   $0xe
  jmp alltraps
801053e2:	e9 4b fb ff ff       	jmp    80104f32 <alltraps>

801053e7 <vector15>:
.globl vector15
vector15:
  pushl $0
801053e7:	6a 00                	push   $0x0
  pushl $15
801053e9:	6a 0f                	push   $0xf
  jmp alltraps
801053eb:	e9 42 fb ff ff       	jmp    80104f32 <alltraps>

801053f0 <vector16>:
.globl vector16
vector16:
  pushl $0
801053f0:	6a 00                	push   $0x0
  pushl $16
801053f2:	6a 10                	push   $0x10
  jmp alltraps
801053f4:	e9 39 fb ff ff       	jmp    80104f32 <alltraps>

801053f9 <vector17>:
.globl vector17
vector17:
  pushl $17
801053f9:	6a 11                	push   $0x11
  jmp alltraps
801053fb:	e9 32 fb ff ff       	jmp    80104f32 <alltraps>

80105400 <vector18>:
.globl vector18
vector18:
  pushl $0
80105400:	6a 00                	push   $0x0
  pushl $18
80105402:	6a 12                	push   $0x12
  jmp alltraps
80105404:	e9 29 fb ff ff       	jmp    80104f32 <alltraps>

80105409 <vector19>:
.globl vector19
vector19:
  pushl $0
80105409:	6a 00                	push   $0x0
  pushl $19
8010540b:	6a 13                	push   $0x13
  jmp alltraps
8010540d:	e9 20 fb ff ff       	jmp    80104f32 <alltraps>

80105412 <vector20>:
.globl vector20
vector20:
  pushl $0
80105412:	6a 00                	push   $0x0
  pushl $20
80105414:	6a 14                	push   $0x14
  jmp alltraps
80105416:	e9 17 fb ff ff       	jmp    80104f32 <alltraps>

8010541b <vector21>:
.globl vector21
vector21:
  pushl $0
8010541b:	6a 00                	push   $0x0
  pushl $21
8010541d:	6a 15                	push   $0x15
  jmp alltraps
8010541f:	e9 0e fb ff ff       	jmp    80104f32 <alltraps>

80105424 <vector22>:
.globl vector22
vector22:
  pushl $0
80105424:	6a 00                	push   $0x0
  pushl $22
80105426:	6a 16                	push   $0x16
  jmp alltraps
80105428:	e9 05 fb ff ff       	jmp    80104f32 <alltraps>

8010542d <vector23>:
.globl vector23
vector23:
  pushl $0
8010542d:	6a 00                	push   $0x0
  pushl $23
8010542f:	6a 17                	push   $0x17
  jmp alltraps
80105431:	e9 fc fa ff ff       	jmp    80104f32 <alltraps>

80105436 <vector24>:
.globl vector24
vector24:
  pushl $0
80105436:	6a 00                	push   $0x0
  pushl $24
80105438:	6a 18                	push   $0x18
  jmp alltraps
8010543a:	e9 f3 fa ff ff       	jmp    80104f32 <alltraps>

8010543f <vector25>:
.globl vector25
vector25:
  pushl $0
8010543f:	6a 00                	push   $0x0
  pushl $25
80105441:	6a 19                	push   $0x19
  jmp alltraps
80105443:	e9 ea fa ff ff       	jmp    80104f32 <alltraps>

80105448 <vector26>:
.globl vector26
vector26:
  pushl $0
80105448:	6a 00                	push   $0x0
  pushl $26
8010544a:	6a 1a                	push   $0x1a
  jmp alltraps
8010544c:	e9 e1 fa ff ff       	jmp    80104f32 <alltraps>

80105451 <vector27>:
.globl vector27
vector27:
  pushl $0
80105451:	6a 00                	push   $0x0
  pushl $27
80105453:	6a 1b                	push   $0x1b
  jmp alltraps
80105455:	e9 d8 fa ff ff       	jmp    80104f32 <alltraps>

8010545a <vector28>:
.globl vector28
vector28:
  pushl $0
8010545a:	6a 00                	push   $0x0
  pushl $28
8010545c:	6a 1c                	push   $0x1c
  jmp alltraps
8010545e:	e9 cf fa ff ff       	jmp    80104f32 <alltraps>

80105463 <vector29>:
.globl vector29
vector29:
  pushl $0
80105463:	6a 00                	push   $0x0
  pushl $29
80105465:	6a 1d                	push   $0x1d
  jmp alltraps
80105467:	e9 c6 fa ff ff       	jmp    80104f32 <alltraps>

8010546c <vector30>:
.globl vector30
vector30:
  pushl $0
8010546c:	6a 00                	push   $0x0
  pushl $30
8010546e:	6a 1e                	push   $0x1e
  jmp alltraps
80105470:	e9 bd fa ff ff       	jmp    80104f32 <alltraps>

80105475 <vector31>:
.globl vector31
vector31:
  pushl $0
80105475:	6a 00                	push   $0x0
  pushl $31
80105477:	6a 1f                	push   $0x1f
  jmp alltraps
80105479:	e9 b4 fa ff ff       	jmp    80104f32 <alltraps>

8010547e <vector32>:
.globl vector32
vector32:
  pushl $0
8010547e:	6a 00                	push   $0x0
  pushl $32
80105480:	6a 20                	push   $0x20
  jmp alltraps
80105482:	e9 ab fa ff ff       	jmp    80104f32 <alltraps>

80105487 <vector33>:
.globl vector33
vector33:
  pushl $0
80105487:	6a 00                	push   $0x0
  pushl $33
80105489:	6a 21                	push   $0x21
  jmp alltraps
8010548b:	e9 a2 fa ff ff       	jmp    80104f32 <alltraps>

80105490 <vector34>:
.globl vector34
vector34:
  pushl $0
80105490:	6a 00                	push   $0x0
  pushl $34
80105492:	6a 22                	push   $0x22
  jmp alltraps
80105494:	e9 99 fa ff ff       	jmp    80104f32 <alltraps>

80105499 <vector35>:
.globl vector35
vector35:
  pushl $0
80105499:	6a 00                	push   $0x0
  pushl $35
8010549b:	6a 23                	push   $0x23
  jmp alltraps
8010549d:	e9 90 fa ff ff       	jmp    80104f32 <alltraps>

801054a2 <vector36>:
.globl vector36
vector36:
  pushl $0
801054a2:	6a 00                	push   $0x0
  pushl $36
801054a4:	6a 24                	push   $0x24
  jmp alltraps
801054a6:	e9 87 fa ff ff       	jmp    80104f32 <alltraps>

801054ab <vector37>:
.globl vector37
vector37:
  pushl $0
801054ab:	6a 00                	push   $0x0
  pushl $37
801054ad:	6a 25                	push   $0x25
  jmp alltraps
801054af:	e9 7e fa ff ff       	jmp    80104f32 <alltraps>

801054b4 <vector38>:
.globl vector38
vector38:
  pushl $0
801054b4:	6a 00                	push   $0x0
  pushl $38
801054b6:	6a 26                	push   $0x26
  jmp alltraps
801054b8:	e9 75 fa ff ff       	jmp    80104f32 <alltraps>

801054bd <vector39>:
.globl vector39
vector39:
  pushl $0
801054bd:	6a 00                	push   $0x0
  pushl $39
801054bf:	6a 27                	push   $0x27
  jmp alltraps
801054c1:	e9 6c fa ff ff       	jmp    80104f32 <alltraps>

801054c6 <vector40>:
.globl vector40
vector40:
  pushl $0
801054c6:	6a 00                	push   $0x0
  pushl $40
801054c8:	6a 28                	push   $0x28
  jmp alltraps
801054ca:	e9 63 fa ff ff       	jmp    80104f32 <alltraps>

801054cf <vector41>:
.globl vector41
vector41:
  pushl $0
801054cf:	6a 00                	push   $0x0
  pushl $41
801054d1:	6a 29                	push   $0x29
  jmp alltraps
801054d3:	e9 5a fa ff ff       	jmp    80104f32 <alltraps>

801054d8 <vector42>:
.globl vector42
vector42:
  pushl $0
801054d8:	6a 00                	push   $0x0
  pushl $42
801054da:	6a 2a                	push   $0x2a
  jmp alltraps
801054dc:	e9 51 fa ff ff       	jmp    80104f32 <alltraps>

801054e1 <vector43>:
.globl vector43
vector43:
  pushl $0
801054e1:	6a 00                	push   $0x0
  pushl $43
801054e3:	6a 2b                	push   $0x2b
  jmp alltraps
801054e5:	e9 48 fa ff ff       	jmp    80104f32 <alltraps>

801054ea <vector44>:
.globl vector44
vector44:
  pushl $0
801054ea:	6a 00                	push   $0x0
  pushl $44
801054ec:	6a 2c                	push   $0x2c
  jmp alltraps
801054ee:	e9 3f fa ff ff       	jmp    80104f32 <alltraps>

801054f3 <vector45>:
.globl vector45
vector45:
  pushl $0
801054f3:	6a 00                	push   $0x0
  pushl $45
801054f5:	6a 2d                	push   $0x2d
  jmp alltraps
801054f7:	e9 36 fa ff ff       	jmp    80104f32 <alltraps>

801054fc <vector46>:
.globl vector46
vector46:
  pushl $0
801054fc:	6a 00                	push   $0x0
  pushl $46
801054fe:	6a 2e                	push   $0x2e
  jmp alltraps
80105500:	e9 2d fa ff ff       	jmp    80104f32 <alltraps>

80105505 <vector47>:
.globl vector47
vector47:
  pushl $0
80105505:	6a 00                	push   $0x0
  pushl $47
80105507:	6a 2f                	push   $0x2f
  jmp alltraps
80105509:	e9 24 fa ff ff       	jmp    80104f32 <alltraps>

8010550e <vector48>:
.globl vector48
vector48:
  pushl $0
8010550e:	6a 00                	push   $0x0
  pushl $48
80105510:	6a 30                	push   $0x30
  jmp alltraps
80105512:	e9 1b fa ff ff       	jmp    80104f32 <alltraps>

80105517 <vector49>:
.globl vector49
vector49:
  pushl $0
80105517:	6a 00                	push   $0x0
  pushl $49
80105519:	6a 31                	push   $0x31
  jmp alltraps
8010551b:	e9 12 fa ff ff       	jmp    80104f32 <alltraps>

80105520 <vector50>:
.globl vector50
vector50:
  pushl $0
80105520:	6a 00                	push   $0x0
  pushl $50
80105522:	6a 32                	push   $0x32
  jmp alltraps
80105524:	e9 09 fa ff ff       	jmp    80104f32 <alltraps>

80105529 <vector51>:
.globl vector51
vector51:
  pushl $0
80105529:	6a 00                	push   $0x0
  pushl $51
8010552b:	6a 33                	push   $0x33
  jmp alltraps
8010552d:	e9 00 fa ff ff       	jmp    80104f32 <alltraps>

80105532 <vector52>:
.globl vector52
vector52:
  pushl $0
80105532:	6a 00                	push   $0x0
  pushl $52
80105534:	6a 34                	push   $0x34
  jmp alltraps
80105536:	e9 f7 f9 ff ff       	jmp    80104f32 <alltraps>

8010553b <vector53>:
.globl vector53
vector53:
  pushl $0
8010553b:	6a 00                	push   $0x0
  pushl $53
8010553d:	6a 35                	push   $0x35
  jmp alltraps
8010553f:	e9 ee f9 ff ff       	jmp    80104f32 <alltraps>

80105544 <vector54>:
.globl vector54
vector54:
  pushl $0
80105544:	6a 00                	push   $0x0
  pushl $54
80105546:	6a 36                	push   $0x36
  jmp alltraps
80105548:	e9 e5 f9 ff ff       	jmp    80104f32 <alltraps>

8010554d <vector55>:
.globl vector55
vector55:
  pushl $0
8010554d:	6a 00                	push   $0x0
  pushl $55
8010554f:	6a 37                	push   $0x37
  jmp alltraps
80105551:	e9 dc f9 ff ff       	jmp    80104f32 <alltraps>

80105556 <vector56>:
.globl vector56
vector56:
  pushl $0
80105556:	6a 00                	push   $0x0
  pushl $56
80105558:	6a 38                	push   $0x38
  jmp alltraps
8010555a:	e9 d3 f9 ff ff       	jmp    80104f32 <alltraps>

8010555f <vector57>:
.globl vector57
vector57:
  pushl $0
8010555f:	6a 00                	push   $0x0
  pushl $57
80105561:	6a 39                	push   $0x39
  jmp alltraps
80105563:	e9 ca f9 ff ff       	jmp    80104f32 <alltraps>

80105568 <vector58>:
.globl vector58
vector58:
  pushl $0
80105568:	6a 00                	push   $0x0
  pushl $58
8010556a:	6a 3a                	push   $0x3a
  jmp alltraps
8010556c:	e9 c1 f9 ff ff       	jmp    80104f32 <alltraps>

80105571 <vector59>:
.globl vector59
vector59:
  pushl $0
80105571:	6a 00                	push   $0x0
  pushl $59
80105573:	6a 3b                	push   $0x3b
  jmp alltraps
80105575:	e9 b8 f9 ff ff       	jmp    80104f32 <alltraps>

8010557a <vector60>:
.globl vector60
vector60:
  pushl $0
8010557a:	6a 00                	push   $0x0
  pushl $60
8010557c:	6a 3c                	push   $0x3c
  jmp alltraps
8010557e:	e9 af f9 ff ff       	jmp    80104f32 <alltraps>

80105583 <vector61>:
.globl vector61
vector61:
  pushl $0
80105583:	6a 00                	push   $0x0
  pushl $61
80105585:	6a 3d                	push   $0x3d
  jmp alltraps
80105587:	e9 a6 f9 ff ff       	jmp    80104f32 <alltraps>

8010558c <vector62>:
.globl vector62
vector62:
  pushl $0
8010558c:	6a 00                	push   $0x0
  pushl $62
8010558e:	6a 3e                	push   $0x3e
  jmp alltraps
80105590:	e9 9d f9 ff ff       	jmp    80104f32 <alltraps>

80105595 <vector63>:
.globl vector63
vector63:
  pushl $0
80105595:	6a 00                	push   $0x0
  pushl $63
80105597:	6a 3f                	push   $0x3f
  jmp alltraps
80105599:	e9 94 f9 ff ff       	jmp    80104f32 <alltraps>

8010559e <vector64>:
.globl vector64
vector64:
  pushl $0
8010559e:	6a 00                	push   $0x0
  pushl $64
801055a0:	6a 40                	push   $0x40
  jmp alltraps
801055a2:	e9 8b f9 ff ff       	jmp    80104f32 <alltraps>

801055a7 <vector65>:
.globl vector65
vector65:
  pushl $0
801055a7:	6a 00                	push   $0x0
  pushl $65
801055a9:	6a 41                	push   $0x41
  jmp alltraps
801055ab:	e9 82 f9 ff ff       	jmp    80104f32 <alltraps>

801055b0 <vector66>:
.globl vector66
vector66:
  pushl $0
801055b0:	6a 00                	push   $0x0
  pushl $66
801055b2:	6a 42                	push   $0x42
  jmp alltraps
801055b4:	e9 79 f9 ff ff       	jmp    80104f32 <alltraps>

801055b9 <vector67>:
.globl vector67
vector67:
  pushl $0
801055b9:	6a 00                	push   $0x0
  pushl $67
801055bb:	6a 43                	push   $0x43
  jmp alltraps
801055bd:	e9 70 f9 ff ff       	jmp    80104f32 <alltraps>

801055c2 <vector68>:
.globl vector68
vector68:
  pushl $0
801055c2:	6a 00                	push   $0x0
  pushl $68
801055c4:	6a 44                	push   $0x44
  jmp alltraps
801055c6:	e9 67 f9 ff ff       	jmp    80104f32 <alltraps>

801055cb <vector69>:
.globl vector69
vector69:
  pushl $0
801055cb:	6a 00                	push   $0x0
  pushl $69
801055cd:	6a 45                	push   $0x45
  jmp alltraps
801055cf:	e9 5e f9 ff ff       	jmp    80104f32 <alltraps>

801055d4 <vector70>:
.globl vector70
vector70:
  pushl $0
801055d4:	6a 00                	push   $0x0
  pushl $70
801055d6:	6a 46                	push   $0x46
  jmp alltraps
801055d8:	e9 55 f9 ff ff       	jmp    80104f32 <alltraps>

801055dd <vector71>:
.globl vector71
vector71:
  pushl $0
801055dd:	6a 00                	push   $0x0
  pushl $71
801055df:	6a 47                	push   $0x47
  jmp alltraps
801055e1:	e9 4c f9 ff ff       	jmp    80104f32 <alltraps>

801055e6 <vector72>:
.globl vector72
vector72:
  pushl $0
801055e6:	6a 00                	push   $0x0
  pushl $72
801055e8:	6a 48                	push   $0x48
  jmp alltraps
801055ea:	e9 43 f9 ff ff       	jmp    80104f32 <alltraps>

801055ef <vector73>:
.globl vector73
vector73:
  pushl $0
801055ef:	6a 00                	push   $0x0
  pushl $73
801055f1:	6a 49                	push   $0x49
  jmp alltraps
801055f3:	e9 3a f9 ff ff       	jmp    80104f32 <alltraps>

801055f8 <vector74>:
.globl vector74
vector74:
  pushl $0
801055f8:	6a 00                	push   $0x0
  pushl $74
801055fa:	6a 4a                	push   $0x4a
  jmp alltraps
801055fc:	e9 31 f9 ff ff       	jmp    80104f32 <alltraps>

80105601 <vector75>:
.globl vector75
vector75:
  pushl $0
80105601:	6a 00                	push   $0x0
  pushl $75
80105603:	6a 4b                	push   $0x4b
  jmp alltraps
80105605:	e9 28 f9 ff ff       	jmp    80104f32 <alltraps>

8010560a <vector76>:
.globl vector76
vector76:
  pushl $0
8010560a:	6a 00                	push   $0x0
  pushl $76
8010560c:	6a 4c                	push   $0x4c
  jmp alltraps
8010560e:	e9 1f f9 ff ff       	jmp    80104f32 <alltraps>

80105613 <vector77>:
.globl vector77
vector77:
  pushl $0
80105613:	6a 00                	push   $0x0
  pushl $77
80105615:	6a 4d                	push   $0x4d
  jmp alltraps
80105617:	e9 16 f9 ff ff       	jmp    80104f32 <alltraps>

8010561c <vector78>:
.globl vector78
vector78:
  pushl $0
8010561c:	6a 00                	push   $0x0
  pushl $78
8010561e:	6a 4e                	push   $0x4e
  jmp alltraps
80105620:	e9 0d f9 ff ff       	jmp    80104f32 <alltraps>

80105625 <vector79>:
.globl vector79
vector79:
  pushl $0
80105625:	6a 00                	push   $0x0
  pushl $79
80105627:	6a 4f                	push   $0x4f
  jmp alltraps
80105629:	e9 04 f9 ff ff       	jmp    80104f32 <alltraps>

8010562e <vector80>:
.globl vector80
vector80:
  pushl $0
8010562e:	6a 00                	push   $0x0
  pushl $80
80105630:	6a 50                	push   $0x50
  jmp alltraps
80105632:	e9 fb f8 ff ff       	jmp    80104f32 <alltraps>

80105637 <vector81>:
.globl vector81
vector81:
  pushl $0
80105637:	6a 00                	push   $0x0
  pushl $81
80105639:	6a 51                	push   $0x51
  jmp alltraps
8010563b:	e9 f2 f8 ff ff       	jmp    80104f32 <alltraps>

80105640 <vector82>:
.globl vector82
vector82:
  pushl $0
80105640:	6a 00                	push   $0x0
  pushl $82
80105642:	6a 52                	push   $0x52
  jmp alltraps
80105644:	e9 e9 f8 ff ff       	jmp    80104f32 <alltraps>

80105649 <vector83>:
.globl vector83
vector83:
  pushl $0
80105649:	6a 00                	push   $0x0
  pushl $83
8010564b:	6a 53                	push   $0x53
  jmp alltraps
8010564d:	e9 e0 f8 ff ff       	jmp    80104f32 <alltraps>

80105652 <vector84>:
.globl vector84
vector84:
  pushl $0
80105652:	6a 00                	push   $0x0
  pushl $84
80105654:	6a 54                	push   $0x54
  jmp alltraps
80105656:	e9 d7 f8 ff ff       	jmp    80104f32 <alltraps>

8010565b <vector85>:
.globl vector85
vector85:
  pushl $0
8010565b:	6a 00                	push   $0x0
  pushl $85
8010565d:	6a 55                	push   $0x55
  jmp alltraps
8010565f:	e9 ce f8 ff ff       	jmp    80104f32 <alltraps>

80105664 <vector86>:
.globl vector86
vector86:
  pushl $0
80105664:	6a 00                	push   $0x0
  pushl $86
80105666:	6a 56                	push   $0x56
  jmp alltraps
80105668:	e9 c5 f8 ff ff       	jmp    80104f32 <alltraps>

8010566d <vector87>:
.globl vector87
vector87:
  pushl $0
8010566d:	6a 00                	push   $0x0
  pushl $87
8010566f:	6a 57                	push   $0x57
  jmp alltraps
80105671:	e9 bc f8 ff ff       	jmp    80104f32 <alltraps>

80105676 <vector88>:
.globl vector88
vector88:
  pushl $0
80105676:	6a 00                	push   $0x0
  pushl $88
80105678:	6a 58                	push   $0x58
  jmp alltraps
8010567a:	e9 b3 f8 ff ff       	jmp    80104f32 <alltraps>

8010567f <vector89>:
.globl vector89
vector89:
  pushl $0
8010567f:	6a 00                	push   $0x0
  pushl $89
80105681:	6a 59                	push   $0x59
  jmp alltraps
80105683:	e9 aa f8 ff ff       	jmp    80104f32 <alltraps>

80105688 <vector90>:
.globl vector90
vector90:
  pushl $0
80105688:	6a 00                	push   $0x0
  pushl $90
8010568a:	6a 5a                	push   $0x5a
  jmp alltraps
8010568c:	e9 a1 f8 ff ff       	jmp    80104f32 <alltraps>

80105691 <vector91>:
.globl vector91
vector91:
  pushl $0
80105691:	6a 00                	push   $0x0
  pushl $91
80105693:	6a 5b                	push   $0x5b
  jmp alltraps
80105695:	e9 98 f8 ff ff       	jmp    80104f32 <alltraps>

8010569a <vector92>:
.globl vector92
vector92:
  pushl $0
8010569a:	6a 00                	push   $0x0
  pushl $92
8010569c:	6a 5c                	push   $0x5c
  jmp alltraps
8010569e:	e9 8f f8 ff ff       	jmp    80104f32 <alltraps>

801056a3 <vector93>:
.globl vector93
vector93:
  pushl $0
801056a3:	6a 00                	push   $0x0
  pushl $93
801056a5:	6a 5d                	push   $0x5d
  jmp alltraps
801056a7:	e9 86 f8 ff ff       	jmp    80104f32 <alltraps>

801056ac <vector94>:
.globl vector94
vector94:
  pushl $0
801056ac:	6a 00                	push   $0x0
  pushl $94
801056ae:	6a 5e                	push   $0x5e
  jmp alltraps
801056b0:	e9 7d f8 ff ff       	jmp    80104f32 <alltraps>

801056b5 <vector95>:
.globl vector95
vector95:
  pushl $0
801056b5:	6a 00                	push   $0x0
  pushl $95
801056b7:	6a 5f                	push   $0x5f
  jmp alltraps
801056b9:	e9 74 f8 ff ff       	jmp    80104f32 <alltraps>

801056be <vector96>:
.globl vector96
vector96:
  pushl $0
801056be:	6a 00                	push   $0x0
  pushl $96
801056c0:	6a 60                	push   $0x60
  jmp alltraps
801056c2:	e9 6b f8 ff ff       	jmp    80104f32 <alltraps>

801056c7 <vector97>:
.globl vector97
vector97:
  pushl $0
801056c7:	6a 00                	push   $0x0
  pushl $97
801056c9:	6a 61                	push   $0x61
  jmp alltraps
801056cb:	e9 62 f8 ff ff       	jmp    80104f32 <alltraps>

801056d0 <vector98>:
.globl vector98
vector98:
  pushl $0
801056d0:	6a 00                	push   $0x0
  pushl $98
801056d2:	6a 62                	push   $0x62
  jmp alltraps
801056d4:	e9 59 f8 ff ff       	jmp    80104f32 <alltraps>

801056d9 <vector99>:
.globl vector99
vector99:
  pushl $0
801056d9:	6a 00                	push   $0x0
  pushl $99
801056db:	6a 63                	push   $0x63
  jmp alltraps
801056dd:	e9 50 f8 ff ff       	jmp    80104f32 <alltraps>

801056e2 <vector100>:
.globl vector100
vector100:
  pushl $0
801056e2:	6a 00                	push   $0x0
  pushl $100
801056e4:	6a 64                	push   $0x64
  jmp alltraps
801056e6:	e9 47 f8 ff ff       	jmp    80104f32 <alltraps>

801056eb <vector101>:
.globl vector101
vector101:
  pushl $0
801056eb:	6a 00                	push   $0x0
  pushl $101
801056ed:	6a 65                	push   $0x65
  jmp alltraps
801056ef:	e9 3e f8 ff ff       	jmp    80104f32 <alltraps>

801056f4 <vector102>:
.globl vector102
vector102:
  pushl $0
801056f4:	6a 00                	push   $0x0
  pushl $102
801056f6:	6a 66                	push   $0x66
  jmp alltraps
801056f8:	e9 35 f8 ff ff       	jmp    80104f32 <alltraps>

801056fd <vector103>:
.globl vector103
vector103:
  pushl $0
801056fd:	6a 00                	push   $0x0
  pushl $103
801056ff:	6a 67                	push   $0x67
  jmp alltraps
80105701:	e9 2c f8 ff ff       	jmp    80104f32 <alltraps>

80105706 <vector104>:
.globl vector104
vector104:
  pushl $0
80105706:	6a 00                	push   $0x0
  pushl $104
80105708:	6a 68                	push   $0x68
  jmp alltraps
8010570a:	e9 23 f8 ff ff       	jmp    80104f32 <alltraps>

8010570f <vector105>:
.globl vector105
vector105:
  pushl $0
8010570f:	6a 00                	push   $0x0
  pushl $105
80105711:	6a 69                	push   $0x69
  jmp alltraps
80105713:	e9 1a f8 ff ff       	jmp    80104f32 <alltraps>

80105718 <vector106>:
.globl vector106
vector106:
  pushl $0
80105718:	6a 00                	push   $0x0
  pushl $106
8010571a:	6a 6a                	push   $0x6a
  jmp alltraps
8010571c:	e9 11 f8 ff ff       	jmp    80104f32 <alltraps>

80105721 <vector107>:
.globl vector107
vector107:
  pushl $0
80105721:	6a 00                	push   $0x0
  pushl $107
80105723:	6a 6b                	push   $0x6b
  jmp alltraps
80105725:	e9 08 f8 ff ff       	jmp    80104f32 <alltraps>

8010572a <vector108>:
.globl vector108
vector108:
  pushl $0
8010572a:	6a 00                	push   $0x0
  pushl $108
8010572c:	6a 6c                	push   $0x6c
  jmp alltraps
8010572e:	e9 ff f7 ff ff       	jmp    80104f32 <alltraps>

80105733 <vector109>:
.globl vector109
vector109:
  pushl $0
80105733:	6a 00                	push   $0x0
  pushl $109
80105735:	6a 6d                	push   $0x6d
  jmp alltraps
80105737:	e9 f6 f7 ff ff       	jmp    80104f32 <alltraps>

8010573c <vector110>:
.globl vector110
vector110:
  pushl $0
8010573c:	6a 00                	push   $0x0
  pushl $110
8010573e:	6a 6e                	push   $0x6e
  jmp alltraps
80105740:	e9 ed f7 ff ff       	jmp    80104f32 <alltraps>

80105745 <vector111>:
.globl vector111
vector111:
  pushl $0
80105745:	6a 00                	push   $0x0
  pushl $111
80105747:	6a 6f                	push   $0x6f
  jmp alltraps
80105749:	e9 e4 f7 ff ff       	jmp    80104f32 <alltraps>

8010574e <vector112>:
.globl vector112
vector112:
  pushl $0
8010574e:	6a 00                	push   $0x0
  pushl $112
80105750:	6a 70                	push   $0x70
  jmp alltraps
80105752:	e9 db f7 ff ff       	jmp    80104f32 <alltraps>

80105757 <vector113>:
.globl vector113
vector113:
  pushl $0
80105757:	6a 00                	push   $0x0
  pushl $113
80105759:	6a 71                	push   $0x71
  jmp alltraps
8010575b:	e9 d2 f7 ff ff       	jmp    80104f32 <alltraps>

80105760 <vector114>:
.globl vector114
vector114:
  pushl $0
80105760:	6a 00                	push   $0x0
  pushl $114
80105762:	6a 72                	push   $0x72
  jmp alltraps
80105764:	e9 c9 f7 ff ff       	jmp    80104f32 <alltraps>

80105769 <vector115>:
.globl vector115
vector115:
  pushl $0
80105769:	6a 00                	push   $0x0
  pushl $115
8010576b:	6a 73                	push   $0x73
  jmp alltraps
8010576d:	e9 c0 f7 ff ff       	jmp    80104f32 <alltraps>

80105772 <vector116>:
.globl vector116
vector116:
  pushl $0
80105772:	6a 00                	push   $0x0
  pushl $116
80105774:	6a 74                	push   $0x74
  jmp alltraps
80105776:	e9 b7 f7 ff ff       	jmp    80104f32 <alltraps>

8010577b <vector117>:
.globl vector117
vector117:
  pushl $0
8010577b:	6a 00                	push   $0x0
  pushl $117
8010577d:	6a 75                	push   $0x75
  jmp alltraps
8010577f:	e9 ae f7 ff ff       	jmp    80104f32 <alltraps>

80105784 <vector118>:
.globl vector118
vector118:
  pushl $0
80105784:	6a 00                	push   $0x0
  pushl $118
80105786:	6a 76                	push   $0x76
  jmp alltraps
80105788:	e9 a5 f7 ff ff       	jmp    80104f32 <alltraps>

8010578d <vector119>:
.globl vector119
vector119:
  pushl $0
8010578d:	6a 00                	push   $0x0
  pushl $119
8010578f:	6a 77                	push   $0x77
  jmp alltraps
80105791:	e9 9c f7 ff ff       	jmp    80104f32 <alltraps>

80105796 <vector120>:
.globl vector120
vector120:
  pushl $0
80105796:	6a 00                	push   $0x0
  pushl $120
80105798:	6a 78                	push   $0x78
  jmp alltraps
8010579a:	e9 93 f7 ff ff       	jmp    80104f32 <alltraps>

8010579f <vector121>:
.globl vector121
vector121:
  pushl $0
8010579f:	6a 00                	push   $0x0
  pushl $121
801057a1:	6a 79                	push   $0x79
  jmp alltraps
801057a3:	e9 8a f7 ff ff       	jmp    80104f32 <alltraps>

801057a8 <vector122>:
.globl vector122
vector122:
  pushl $0
801057a8:	6a 00                	push   $0x0
  pushl $122
801057aa:	6a 7a                	push   $0x7a
  jmp alltraps
801057ac:	e9 81 f7 ff ff       	jmp    80104f32 <alltraps>

801057b1 <vector123>:
.globl vector123
vector123:
  pushl $0
801057b1:	6a 00                	push   $0x0
  pushl $123
801057b3:	6a 7b                	push   $0x7b
  jmp alltraps
801057b5:	e9 78 f7 ff ff       	jmp    80104f32 <alltraps>

801057ba <vector124>:
.globl vector124
vector124:
  pushl $0
801057ba:	6a 00                	push   $0x0
  pushl $124
801057bc:	6a 7c                	push   $0x7c
  jmp alltraps
801057be:	e9 6f f7 ff ff       	jmp    80104f32 <alltraps>

801057c3 <vector125>:
.globl vector125
vector125:
  pushl $0
801057c3:	6a 00                	push   $0x0
  pushl $125
801057c5:	6a 7d                	push   $0x7d
  jmp alltraps
801057c7:	e9 66 f7 ff ff       	jmp    80104f32 <alltraps>

801057cc <vector126>:
.globl vector126
vector126:
  pushl $0
801057cc:	6a 00                	push   $0x0
  pushl $126
801057ce:	6a 7e                	push   $0x7e
  jmp alltraps
801057d0:	e9 5d f7 ff ff       	jmp    80104f32 <alltraps>

801057d5 <vector127>:
.globl vector127
vector127:
  pushl $0
801057d5:	6a 00                	push   $0x0
  pushl $127
801057d7:	6a 7f                	push   $0x7f
  jmp alltraps
801057d9:	e9 54 f7 ff ff       	jmp    80104f32 <alltraps>

801057de <vector128>:
.globl vector128
vector128:
  pushl $0
801057de:	6a 00                	push   $0x0
  pushl $128
801057e0:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801057e5:	e9 48 f7 ff ff       	jmp    80104f32 <alltraps>

801057ea <vector129>:
.globl vector129
vector129:
  pushl $0
801057ea:	6a 00                	push   $0x0
  pushl $129
801057ec:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801057f1:	e9 3c f7 ff ff       	jmp    80104f32 <alltraps>

801057f6 <vector130>:
.globl vector130
vector130:
  pushl $0
801057f6:	6a 00                	push   $0x0
  pushl $130
801057f8:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801057fd:	e9 30 f7 ff ff       	jmp    80104f32 <alltraps>

80105802 <vector131>:
.globl vector131
vector131:
  pushl $0
80105802:	6a 00                	push   $0x0
  pushl $131
80105804:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105809:	e9 24 f7 ff ff       	jmp    80104f32 <alltraps>

8010580e <vector132>:
.globl vector132
vector132:
  pushl $0
8010580e:	6a 00                	push   $0x0
  pushl $132
80105810:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105815:	e9 18 f7 ff ff       	jmp    80104f32 <alltraps>

8010581a <vector133>:
.globl vector133
vector133:
  pushl $0
8010581a:	6a 00                	push   $0x0
  pushl $133
8010581c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105821:	e9 0c f7 ff ff       	jmp    80104f32 <alltraps>

80105826 <vector134>:
.globl vector134
vector134:
  pushl $0
80105826:	6a 00                	push   $0x0
  pushl $134
80105828:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010582d:	e9 00 f7 ff ff       	jmp    80104f32 <alltraps>

80105832 <vector135>:
.globl vector135
vector135:
  pushl $0
80105832:	6a 00                	push   $0x0
  pushl $135
80105834:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105839:	e9 f4 f6 ff ff       	jmp    80104f32 <alltraps>

8010583e <vector136>:
.globl vector136
vector136:
  pushl $0
8010583e:	6a 00                	push   $0x0
  pushl $136
80105840:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105845:	e9 e8 f6 ff ff       	jmp    80104f32 <alltraps>

8010584a <vector137>:
.globl vector137
vector137:
  pushl $0
8010584a:	6a 00                	push   $0x0
  pushl $137
8010584c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105851:	e9 dc f6 ff ff       	jmp    80104f32 <alltraps>

80105856 <vector138>:
.globl vector138
vector138:
  pushl $0
80105856:	6a 00                	push   $0x0
  pushl $138
80105858:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010585d:	e9 d0 f6 ff ff       	jmp    80104f32 <alltraps>

80105862 <vector139>:
.globl vector139
vector139:
  pushl $0
80105862:	6a 00                	push   $0x0
  pushl $139
80105864:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105869:	e9 c4 f6 ff ff       	jmp    80104f32 <alltraps>

8010586e <vector140>:
.globl vector140
vector140:
  pushl $0
8010586e:	6a 00                	push   $0x0
  pushl $140
80105870:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105875:	e9 b8 f6 ff ff       	jmp    80104f32 <alltraps>

8010587a <vector141>:
.globl vector141
vector141:
  pushl $0
8010587a:	6a 00                	push   $0x0
  pushl $141
8010587c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105881:	e9 ac f6 ff ff       	jmp    80104f32 <alltraps>

80105886 <vector142>:
.globl vector142
vector142:
  pushl $0
80105886:	6a 00                	push   $0x0
  pushl $142
80105888:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010588d:	e9 a0 f6 ff ff       	jmp    80104f32 <alltraps>

80105892 <vector143>:
.globl vector143
vector143:
  pushl $0
80105892:	6a 00                	push   $0x0
  pushl $143
80105894:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105899:	e9 94 f6 ff ff       	jmp    80104f32 <alltraps>

8010589e <vector144>:
.globl vector144
vector144:
  pushl $0
8010589e:	6a 00                	push   $0x0
  pushl $144
801058a0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801058a5:	e9 88 f6 ff ff       	jmp    80104f32 <alltraps>

801058aa <vector145>:
.globl vector145
vector145:
  pushl $0
801058aa:	6a 00                	push   $0x0
  pushl $145
801058ac:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801058b1:	e9 7c f6 ff ff       	jmp    80104f32 <alltraps>

801058b6 <vector146>:
.globl vector146
vector146:
  pushl $0
801058b6:	6a 00                	push   $0x0
  pushl $146
801058b8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801058bd:	e9 70 f6 ff ff       	jmp    80104f32 <alltraps>

801058c2 <vector147>:
.globl vector147
vector147:
  pushl $0
801058c2:	6a 00                	push   $0x0
  pushl $147
801058c4:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801058c9:	e9 64 f6 ff ff       	jmp    80104f32 <alltraps>

801058ce <vector148>:
.globl vector148
vector148:
  pushl $0
801058ce:	6a 00                	push   $0x0
  pushl $148
801058d0:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801058d5:	e9 58 f6 ff ff       	jmp    80104f32 <alltraps>

801058da <vector149>:
.globl vector149
vector149:
  pushl $0
801058da:	6a 00                	push   $0x0
  pushl $149
801058dc:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801058e1:	e9 4c f6 ff ff       	jmp    80104f32 <alltraps>

801058e6 <vector150>:
.globl vector150
vector150:
  pushl $0
801058e6:	6a 00                	push   $0x0
  pushl $150
801058e8:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801058ed:	e9 40 f6 ff ff       	jmp    80104f32 <alltraps>

801058f2 <vector151>:
.globl vector151
vector151:
  pushl $0
801058f2:	6a 00                	push   $0x0
  pushl $151
801058f4:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801058f9:	e9 34 f6 ff ff       	jmp    80104f32 <alltraps>

801058fe <vector152>:
.globl vector152
vector152:
  pushl $0
801058fe:	6a 00                	push   $0x0
  pushl $152
80105900:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105905:	e9 28 f6 ff ff       	jmp    80104f32 <alltraps>

8010590a <vector153>:
.globl vector153
vector153:
  pushl $0
8010590a:	6a 00                	push   $0x0
  pushl $153
8010590c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105911:	e9 1c f6 ff ff       	jmp    80104f32 <alltraps>

80105916 <vector154>:
.globl vector154
vector154:
  pushl $0
80105916:	6a 00                	push   $0x0
  pushl $154
80105918:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010591d:	e9 10 f6 ff ff       	jmp    80104f32 <alltraps>

80105922 <vector155>:
.globl vector155
vector155:
  pushl $0
80105922:	6a 00                	push   $0x0
  pushl $155
80105924:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105929:	e9 04 f6 ff ff       	jmp    80104f32 <alltraps>

8010592e <vector156>:
.globl vector156
vector156:
  pushl $0
8010592e:	6a 00                	push   $0x0
  pushl $156
80105930:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105935:	e9 f8 f5 ff ff       	jmp    80104f32 <alltraps>

8010593a <vector157>:
.globl vector157
vector157:
  pushl $0
8010593a:	6a 00                	push   $0x0
  pushl $157
8010593c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105941:	e9 ec f5 ff ff       	jmp    80104f32 <alltraps>

80105946 <vector158>:
.globl vector158
vector158:
  pushl $0
80105946:	6a 00                	push   $0x0
  pushl $158
80105948:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
8010594d:	e9 e0 f5 ff ff       	jmp    80104f32 <alltraps>

80105952 <vector159>:
.globl vector159
vector159:
  pushl $0
80105952:	6a 00                	push   $0x0
  pushl $159
80105954:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105959:	e9 d4 f5 ff ff       	jmp    80104f32 <alltraps>

8010595e <vector160>:
.globl vector160
vector160:
  pushl $0
8010595e:	6a 00                	push   $0x0
  pushl $160
80105960:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105965:	e9 c8 f5 ff ff       	jmp    80104f32 <alltraps>

8010596a <vector161>:
.globl vector161
vector161:
  pushl $0
8010596a:	6a 00                	push   $0x0
  pushl $161
8010596c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105971:	e9 bc f5 ff ff       	jmp    80104f32 <alltraps>

80105976 <vector162>:
.globl vector162
vector162:
  pushl $0
80105976:	6a 00                	push   $0x0
  pushl $162
80105978:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
8010597d:	e9 b0 f5 ff ff       	jmp    80104f32 <alltraps>

80105982 <vector163>:
.globl vector163
vector163:
  pushl $0
80105982:	6a 00                	push   $0x0
  pushl $163
80105984:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105989:	e9 a4 f5 ff ff       	jmp    80104f32 <alltraps>

8010598e <vector164>:
.globl vector164
vector164:
  pushl $0
8010598e:	6a 00                	push   $0x0
  pushl $164
80105990:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105995:	e9 98 f5 ff ff       	jmp    80104f32 <alltraps>

8010599a <vector165>:
.globl vector165
vector165:
  pushl $0
8010599a:	6a 00                	push   $0x0
  pushl $165
8010599c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801059a1:	e9 8c f5 ff ff       	jmp    80104f32 <alltraps>

801059a6 <vector166>:
.globl vector166
vector166:
  pushl $0
801059a6:	6a 00                	push   $0x0
  pushl $166
801059a8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801059ad:	e9 80 f5 ff ff       	jmp    80104f32 <alltraps>

801059b2 <vector167>:
.globl vector167
vector167:
  pushl $0
801059b2:	6a 00                	push   $0x0
  pushl $167
801059b4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801059b9:	e9 74 f5 ff ff       	jmp    80104f32 <alltraps>

801059be <vector168>:
.globl vector168
vector168:
  pushl $0
801059be:	6a 00                	push   $0x0
  pushl $168
801059c0:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801059c5:	e9 68 f5 ff ff       	jmp    80104f32 <alltraps>

801059ca <vector169>:
.globl vector169
vector169:
  pushl $0
801059ca:	6a 00                	push   $0x0
  pushl $169
801059cc:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801059d1:	e9 5c f5 ff ff       	jmp    80104f32 <alltraps>

801059d6 <vector170>:
.globl vector170
vector170:
  pushl $0
801059d6:	6a 00                	push   $0x0
  pushl $170
801059d8:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801059dd:	e9 50 f5 ff ff       	jmp    80104f32 <alltraps>

801059e2 <vector171>:
.globl vector171
vector171:
  pushl $0
801059e2:	6a 00                	push   $0x0
  pushl $171
801059e4:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801059e9:	e9 44 f5 ff ff       	jmp    80104f32 <alltraps>

801059ee <vector172>:
.globl vector172
vector172:
  pushl $0
801059ee:	6a 00                	push   $0x0
  pushl $172
801059f0:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801059f5:	e9 38 f5 ff ff       	jmp    80104f32 <alltraps>

801059fa <vector173>:
.globl vector173
vector173:
  pushl $0
801059fa:	6a 00                	push   $0x0
  pushl $173
801059fc:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105a01:	e9 2c f5 ff ff       	jmp    80104f32 <alltraps>

80105a06 <vector174>:
.globl vector174
vector174:
  pushl $0
80105a06:	6a 00                	push   $0x0
  pushl $174
80105a08:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105a0d:	e9 20 f5 ff ff       	jmp    80104f32 <alltraps>

80105a12 <vector175>:
.globl vector175
vector175:
  pushl $0
80105a12:	6a 00                	push   $0x0
  pushl $175
80105a14:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105a19:	e9 14 f5 ff ff       	jmp    80104f32 <alltraps>

80105a1e <vector176>:
.globl vector176
vector176:
  pushl $0
80105a1e:	6a 00                	push   $0x0
  pushl $176
80105a20:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105a25:	e9 08 f5 ff ff       	jmp    80104f32 <alltraps>

80105a2a <vector177>:
.globl vector177
vector177:
  pushl $0
80105a2a:	6a 00                	push   $0x0
  pushl $177
80105a2c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105a31:	e9 fc f4 ff ff       	jmp    80104f32 <alltraps>

80105a36 <vector178>:
.globl vector178
vector178:
  pushl $0
80105a36:	6a 00                	push   $0x0
  pushl $178
80105a38:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105a3d:	e9 f0 f4 ff ff       	jmp    80104f32 <alltraps>

80105a42 <vector179>:
.globl vector179
vector179:
  pushl $0
80105a42:	6a 00                	push   $0x0
  pushl $179
80105a44:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105a49:	e9 e4 f4 ff ff       	jmp    80104f32 <alltraps>

80105a4e <vector180>:
.globl vector180
vector180:
  pushl $0
80105a4e:	6a 00                	push   $0x0
  pushl $180
80105a50:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105a55:	e9 d8 f4 ff ff       	jmp    80104f32 <alltraps>

80105a5a <vector181>:
.globl vector181
vector181:
  pushl $0
80105a5a:	6a 00                	push   $0x0
  pushl $181
80105a5c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105a61:	e9 cc f4 ff ff       	jmp    80104f32 <alltraps>

80105a66 <vector182>:
.globl vector182
vector182:
  pushl $0
80105a66:	6a 00                	push   $0x0
  pushl $182
80105a68:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105a6d:	e9 c0 f4 ff ff       	jmp    80104f32 <alltraps>

80105a72 <vector183>:
.globl vector183
vector183:
  pushl $0
80105a72:	6a 00                	push   $0x0
  pushl $183
80105a74:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105a79:	e9 b4 f4 ff ff       	jmp    80104f32 <alltraps>

80105a7e <vector184>:
.globl vector184
vector184:
  pushl $0
80105a7e:	6a 00                	push   $0x0
  pushl $184
80105a80:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105a85:	e9 a8 f4 ff ff       	jmp    80104f32 <alltraps>

80105a8a <vector185>:
.globl vector185
vector185:
  pushl $0
80105a8a:	6a 00                	push   $0x0
  pushl $185
80105a8c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105a91:	e9 9c f4 ff ff       	jmp    80104f32 <alltraps>

80105a96 <vector186>:
.globl vector186
vector186:
  pushl $0
80105a96:	6a 00                	push   $0x0
  pushl $186
80105a98:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105a9d:	e9 90 f4 ff ff       	jmp    80104f32 <alltraps>

80105aa2 <vector187>:
.globl vector187
vector187:
  pushl $0
80105aa2:	6a 00                	push   $0x0
  pushl $187
80105aa4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105aa9:	e9 84 f4 ff ff       	jmp    80104f32 <alltraps>

80105aae <vector188>:
.globl vector188
vector188:
  pushl $0
80105aae:	6a 00                	push   $0x0
  pushl $188
80105ab0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105ab5:	e9 78 f4 ff ff       	jmp    80104f32 <alltraps>

80105aba <vector189>:
.globl vector189
vector189:
  pushl $0
80105aba:	6a 00                	push   $0x0
  pushl $189
80105abc:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105ac1:	e9 6c f4 ff ff       	jmp    80104f32 <alltraps>

80105ac6 <vector190>:
.globl vector190
vector190:
  pushl $0
80105ac6:	6a 00                	push   $0x0
  pushl $190
80105ac8:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105acd:	e9 60 f4 ff ff       	jmp    80104f32 <alltraps>

80105ad2 <vector191>:
.globl vector191
vector191:
  pushl $0
80105ad2:	6a 00                	push   $0x0
  pushl $191
80105ad4:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105ad9:	e9 54 f4 ff ff       	jmp    80104f32 <alltraps>

80105ade <vector192>:
.globl vector192
vector192:
  pushl $0
80105ade:	6a 00                	push   $0x0
  pushl $192
80105ae0:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105ae5:	e9 48 f4 ff ff       	jmp    80104f32 <alltraps>

80105aea <vector193>:
.globl vector193
vector193:
  pushl $0
80105aea:	6a 00                	push   $0x0
  pushl $193
80105aec:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105af1:	e9 3c f4 ff ff       	jmp    80104f32 <alltraps>

80105af6 <vector194>:
.globl vector194
vector194:
  pushl $0
80105af6:	6a 00                	push   $0x0
  pushl $194
80105af8:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105afd:	e9 30 f4 ff ff       	jmp    80104f32 <alltraps>

80105b02 <vector195>:
.globl vector195
vector195:
  pushl $0
80105b02:	6a 00                	push   $0x0
  pushl $195
80105b04:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105b09:	e9 24 f4 ff ff       	jmp    80104f32 <alltraps>

80105b0e <vector196>:
.globl vector196
vector196:
  pushl $0
80105b0e:	6a 00                	push   $0x0
  pushl $196
80105b10:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105b15:	e9 18 f4 ff ff       	jmp    80104f32 <alltraps>

80105b1a <vector197>:
.globl vector197
vector197:
  pushl $0
80105b1a:	6a 00                	push   $0x0
  pushl $197
80105b1c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105b21:	e9 0c f4 ff ff       	jmp    80104f32 <alltraps>

80105b26 <vector198>:
.globl vector198
vector198:
  pushl $0
80105b26:	6a 00                	push   $0x0
  pushl $198
80105b28:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105b2d:	e9 00 f4 ff ff       	jmp    80104f32 <alltraps>

80105b32 <vector199>:
.globl vector199
vector199:
  pushl $0
80105b32:	6a 00                	push   $0x0
  pushl $199
80105b34:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105b39:	e9 f4 f3 ff ff       	jmp    80104f32 <alltraps>

80105b3e <vector200>:
.globl vector200
vector200:
  pushl $0
80105b3e:	6a 00                	push   $0x0
  pushl $200
80105b40:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105b45:	e9 e8 f3 ff ff       	jmp    80104f32 <alltraps>

80105b4a <vector201>:
.globl vector201
vector201:
  pushl $0
80105b4a:	6a 00                	push   $0x0
  pushl $201
80105b4c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105b51:	e9 dc f3 ff ff       	jmp    80104f32 <alltraps>

80105b56 <vector202>:
.globl vector202
vector202:
  pushl $0
80105b56:	6a 00                	push   $0x0
  pushl $202
80105b58:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105b5d:	e9 d0 f3 ff ff       	jmp    80104f32 <alltraps>

80105b62 <vector203>:
.globl vector203
vector203:
  pushl $0
80105b62:	6a 00                	push   $0x0
  pushl $203
80105b64:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105b69:	e9 c4 f3 ff ff       	jmp    80104f32 <alltraps>

80105b6e <vector204>:
.globl vector204
vector204:
  pushl $0
80105b6e:	6a 00                	push   $0x0
  pushl $204
80105b70:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105b75:	e9 b8 f3 ff ff       	jmp    80104f32 <alltraps>

80105b7a <vector205>:
.globl vector205
vector205:
  pushl $0
80105b7a:	6a 00                	push   $0x0
  pushl $205
80105b7c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105b81:	e9 ac f3 ff ff       	jmp    80104f32 <alltraps>

80105b86 <vector206>:
.globl vector206
vector206:
  pushl $0
80105b86:	6a 00                	push   $0x0
  pushl $206
80105b88:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105b8d:	e9 a0 f3 ff ff       	jmp    80104f32 <alltraps>

80105b92 <vector207>:
.globl vector207
vector207:
  pushl $0
80105b92:	6a 00                	push   $0x0
  pushl $207
80105b94:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105b99:	e9 94 f3 ff ff       	jmp    80104f32 <alltraps>

80105b9e <vector208>:
.globl vector208
vector208:
  pushl $0
80105b9e:	6a 00                	push   $0x0
  pushl $208
80105ba0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105ba5:	e9 88 f3 ff ff       	jmp    80104f32 <alltraps>

80105baa <vector209>:
.globl vector209
vector209:
  pushl $0
80105baa:	6a 00                	push   $0x0
  pushl $209
80105bac:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105bb1:	e9 7c f3 ff ff       	jmp    80104f32 <alltraps>

80105bb6 <vector210>:
.globl vector210
vector210:
  pushl $0
80105bb6:	6a 00                	push   $0x0
  pushl $210
80105bb8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105bbd:	e9 70 f3 ff ff       	jmp    80104f32 <alltraps>

80105bc2 <vector211>:
.globl vector211
vector211:
  pushl $0
80105bc2:	6a 00                	push   $0x0
  pushl $211
80105bc4:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105bc9:	e9 64 f3 ff ff       	jmp    80104f32 <alltraps>

80105bce <vector212>:
.globl vector212
vector212:
  pushl $0
80105bce:	6a 00                	push   $0x0
  pushl $212
80105bd0:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105bd5:	e9 58 f3 ff ff       	jmp    80104f32 <alltraps>

80105bda <vector213>:
.globl vector213
vector213:
  pushl $0
80105bda:	6a 00                	push   $0x0
  pushl $213
80105bdc:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105be1:	e9 4c f3 ff ff       	jmp    80104f32 <alltraps>

80105be6 <vector214>:
.globl vector214
vector214:
  pushl $0
80105be6:	6a 00                	push   $0x0
  pushl $214
80105be8:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105bed:	e9 40 f3 ff ff       	jmp    80104f32 <alltraps>

80105bf2 <vector215>:
.globl vector215
vector215:
  pushl $0
80105bf2:	6a 00                	push   $0x0
  pushl $215
80105bf4:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105bf9:	e9 34 f3 ff ff       	jmp    80104f32 <alltraps>

80105bfe <vector216>:
.globl vector216
vector216:
  pushl $0
80105bfe:	6a 00                	push   $0x0
  pushl $216
80105c00:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105c05:	e9 28 f3 ff ff       	jmp    80104f32 <alltraps>

80105c0a <vector217>:
.globl vector217
vector217:
  pushl $0
80105c0a:	6a 00                	push   $0x0
  pushl $217
80105c0c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105c11:	e9 1c f3 ff ff       	jmp    80104f32 <alltraps>

80105c16 <vector218>:
.globl vector218
vector218:
  pushl $0
80105c16:	6a 00                	push   $0x0
  pushl $218
80105c18:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105c1d:	e9 10 f3 ff ff       	jmp    80104f32 <alltraps>

80105c22 <vector219>:
.globl vector219
vector219:
  pushl $0
80105c22:	6a 00                	push   $0x0
  pushl $219
80105c24:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105c29:	e9 04 f3 ff ff       	jmp    80104f32 <alltraps>

80105c2e <vector220>:
.globl vector220
vector220:
  pushl $0
80105c2e:	6a 00                	push   $0x0
  pushl $220
80105c30:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105c35:	e9 f8 f2 ff ff       	jmp    80104f32 <alltraps>

80105c3a <vector221>:
.globl vector221
vector221:
  pushl $0
80105c3a:	6a 00                	push   $0x0
  pushl $221
80105c3c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105c41:	e9 ec f2 ff ff       	jmp    80104f32 <alltraps>

80105c46 <vector222>:
.globl vector222
vector222:
  pushl $0
80105c46:	6a 00                	push   $0x0
  pushl $222
80105c48:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105c4d:	e9 e0 f2 ff ff       	jmp    80104f32 <alltraps>

80105c52 <vector223>:
.globl vector223
vector223:
  pushl $0
80105c52:	6a 00                	push   $0x0
  pushl $223
80105c54:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105c59:	e9 d4 f2 ff ff       	jmp    80104f32 <alltraps>

80105c5e <vector224>:
.globl vector224
vector224:
  pushl $0
80105c5e:	6a 00                	push   $0x0
  pushl $224
80105c60:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105c65:	e9 c8 f2 ff ff       	jmp    80104f32 <alltraps>

80105c6a <vector225>:
.globl vector225
vector225:
  pushl $0
80105c6a:	6a 00                	push   $0x0
  pushl $225
80105c6c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105c71:	e9 bc f2 ff ff       	jmp    80104f32 <alltraps>

80105c76 <vector226>:
.globl vector226
vector226:
  pushl $0
80105c76:	6a 00                	push   $0x0
  pushl $226
80105c78:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105c7d:	e9 b0 f2 ff ff       	jmp    80104f32 <alltraps>

80105c82 <vector227>:
.globl vector227
vector227:
  pushl $0
80105c82:	6a 00                	push   $0x0
  pushl $227
80105c84:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105c89:	e9 a4 f2 ff ff       	jmp    80104f32 <alltraps>

80105c8e <vector228>:
.globl vector228
vector228:
  pushl $0
80105c8e:	6a 00                	push   $0x0
  pushl $228
80105c90:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105c95:	e9 98 f2 ff ff       	jmp    80104f32 <alltraps>

80105c9a <vector229>:
.globl vector229
vector229:
  pushl $0
80105c9a:	6a 00                	push   $0x0
  pushl $229
80105c9c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105ca1:	e9 8c f2 ff ff       	jmp    80104f32 <alltraps>

80105ca6 <vector230>:
.globl vector230
vector230:
  pushl $0
80105ca6:	6a 00                	push   $0x0
  pushl $230
80105ca8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105cad:	e9 80 f2 ff ff       	jmp    80104f32 <alltraps>

80105cb2 <vector231>:
.globl vector231
vector231:
  pushl $0
80105cb2:	6a 00                	push   $0x0
  pushl $231
80105cb4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105cb9:	e9 74 f2 ff ff       	jmp    80104f32 <alltraps>

80105cbe <vector232>:
.globl vector232
vector232:
  pushl $0
80105cbe:	6a 00                	push   $0x0
  pushl $232
80105cc0:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105cc5:	e9 68 f2 ff ff       	jmp    80104f32 <alltraps>

80105cca <vector233>:
.globl vector233
vector233:
  pushl $0
80105cca:	6a 00                	push   $0x0
  pushl $233
80105ccc:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105cd1:	e9 5c f2 ff ff       	jmp    80104f32 <alltraps>

80105cd6 <vector234>:
.globl vector234
vector234:
  pushl $0
80105cd6:	6a 00                	push   $0x0
  pushl $234
80105cd8:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105cdd:	e9 50 f2 ff ff       	jmp    80104f32 <alltraps>

80105ce2 <vector235>:
.globl vector235
vector235:
  pushl $0
80105ce2:	6a 00                	push   $0x0
  pushl $235
80105ce4:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105ce9:	e9 44 f2 ff ff       	jmp    80104f32 <alltraps>

80105cee <vector236>:
.globl vector236
vector236:
  pushl $0
80105cee:	6a 00                	push   $0x0
  pushl $236
80105cf0:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105cf5:	e9 38 f2 ff ff       	jmp    80104f32 <alltraps>

80105cfa <vector237>:
.globl vector237
vector237:
  pushl $0
80105cfa:	6a 00                	push   $0x0
  pushl $237
80105cfc:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105d01:	e9 2c f2 ff ff       	jmp    80104f32 <alltraps>

80105d06 <vector238>:
.globl vector238
vector238:
  pushl $0
80105d06:	6a 00                	push   $0x0
  pushl $238
80105d08:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105d0d:	e9 20 f2 ff ff       	jmp    80104f32 <alltraps>

80105d12 <vector239>:
.globl vector239
vector239:
  pushl $0
80105d12:	6a 00                	push   $0x0
  pushl $239
80105d14:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105d19:	e9 14 f2 ff ff       	jmp    80104f32 <alltraps>

80105d1e <vector240>:
.globl vector240
vector240:
  pushl $0
80105d1e:	6a 00                	push   $0x0
  pushl $240
80105d20:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105d25:	e9 08 f2 ff ff       	jmp    80104f32 <alltraps>

80105d2a <vector241>:
.globl vector241
vector241:
  pushl $0
80105d2a:	6a 00                	push   $0x0
  pushl $241
80105d2c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105d31:	e9 fc f1 ff ff       	jmp    80104f32 <alltraps>

80105d36 <vector242>:
.globl vector242
vector242:
  pushl $0
80105d36:	6a 00                	push   $0x0
  pushl $242
80105d38:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105d3d:	e9 f0 f1 ff ff       	jmp    80104f32 <alltraps>

80105d42 <vector243>:
.globl vector243
vector243:
  pushl $0
80105d42:	6a 00                	push   $0x0
  pushl $243
80105d44:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105d49:	e9 e4 f1 ff ff       	jmp    80104f32 <alltraps>

80105d4e <vector244>:
.globl vector244
vector244:
  pushl $0
80105d4e:	6a 00                	push   $0x0
  pushl $244
80105d50:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105d55:	e9 d8 f1 ff ff       	jmp    80104f32 <alltraps>

80105d5a <vector245>:
.globl vector245
vector245:
  pushl $0
80105d5a:	6a 00                	push   $0x0
  pushl $245
80105d5c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105d61:	e9 cc f1 ff ff       	jmp    80104f32 <alltraps>

80105d66 <vector246>:
.globl vector246
vector246:
  pushl $0
80105d66:	6a 00                	push   $0x0
  pushl $246
80105d68:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105d6d:	e9 c0 f1 ff ff       	jmp    80104f32 <alltraps>

80105d72 <vector247>:
.globl vector247
vector247:
  pushl $0
80105d72:	6a 00                	push   $0x0
  pushl $247
80105d74:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105d79:	e9 b4 f1 ff ff       	jmp    80104f32 <alltraps>

80105d7e <vector248>:
.globl vector248
vector248:
  pushl $0
80105d7e:	6a 00                	push   $0x0
  pushl $248
80105d80:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105d85:	e9 a8 f1 ff ff       	jmp    80104f32 <alltraps>

80105d8a <vector249>:
.globl vector249
vector249:
  pushl $0
80105d8a:	6a 00                	push   $0x0
  pushl $249
80105d8c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105d91:	e9 9c f1 ff ff       	jmp    80104f32 <alltraps>

80105d96 <vector250>:
.globl vector250
vector250:
  pushl $0
80105d96:	6a 00                	push   $0x0
  pushl $250
80105d98:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105d9d:	e9 90 f1 ff ff       	jmp    80104f32 <alltraps>

80105da2 <vector251>:
.globl vector251
vector251:
  pushl $0
80105da2:	6a 00                	push   $0x0
  pushl $251
80105da4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105da9:	e9 84 f1 ff ff       	jmp    80104f32 <alltraps>

80105dae <vector252>:
.globl vector252
vector252:
  pushl $0
80105dae:	6a 00                	push   $0x0
  pushl $252
80105db0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105db5:	e9 78 f1 ff ff       	jmp    80104f32 <alltraps>

80105dba <vector253>:
.globl vector253
vector253:
  pushl $0
80105dba:	6a 00                	push   $0x0
  pushl $253
80105dbc:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105dc1:	e9 6c f1 ff ff       	jmp    80104f32 <alltraps>

80105dc6 <vector254>:
.globl vector254
vector254:
  pushl $0
80105dc6:	6a 00                	push   $0x0
  pushl $254
80105dc8:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105dcd:	e9 60 f1 ff ff       	jmp    80104f32 <alltraps>

80105dd2 <vector255>:
.globl vector255
vector255:
  pushl $0
80105dd2:	6a 00                	push   $0x0
  pushl $255
80105dd4:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105dd9:	e9 54 f1 ff ff       	jmp    80104f32 <alltraps>

80105dde <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105dde:	55                   	push   %ebp
80105ddf:	89 e5                	mov    %esp,%ebp
80105de1:	57                   	push   %edi
80105de2:	56                   	push   %esi
80105de3:	53                   	push   %ebx
80105de4:	83 ec 0c             	sub    $0xc,%esp
80105de7:	89 d3                	mov    %edx,%ebx
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105de9:	c1 ea 16             	shr    $0x16,%edx
80105dec:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105def:	8b 37                	mov    (%edi),%esi
80105df1:	f7 c6 01 00 00 00    	test   $0x1,%esi
80105df7:	74 20                	je     80105e19 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105df9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
80105dff:	81 c6 00 00 00 80    	add    $0x80000000,%esi
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105e05:	c1 eb 0c             	shr    $0xc,%ebx
80105e08:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
80105e0e:	8d 04 9e             	lea    (%esi,%ebx,4),%eax
}
80105e11:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e14:	5b                   	pop    %ebx
80105e15:	5e                   	pop    %esi
80105e16:	5f                   	pop    %edi
80105e17:	5d                   	pop    %ebp
80105e18:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105e19:	85 c9                	test   %ecx,%ecx
80105e1b:	74 2b                	je     80105e48 <walkpgdir+0x6a>
80105e1d:	e8 6e c3 ff ff       	call   80102190 <kalloc>
80105e22:	89 c6                	mov    %eax,%esi
80105e24:	85 c0                	test   %eax,%eax
80105e26:	74 20                	je     80105e48 <walkpgdir+0x6a>
    memset(pgtab, 0, PGSIZE);
80105e28:	83 ec 04             	sub    $0x4,%esp
80105e2b:	68 00 10 00 00       	push   $0x1000
80105e30:	6a 00                	push   $0x0
80105e32:	50                   	push   %eax
80105e33:	e8 2a e0 ff ff       	call   80103e62 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105e38:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80105e3e:	83 c8 07             	or     $0x7,%eax
80105e41:	89 07                	mov    %eax,(%edi)
80105e43:	83 c4 10             	add    $0x10,%esp
80105e46:	eb bd                	jmp    80105e05 <walkpgdir+0x27>
      return 0;
80105e48:	b8 00 00 00 00       	mov    $0x0,%eax
80105e4d:	eb c2                	jmp    80105e11 <walkpgdir+0x33>

80105e4f <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105e4f:	55                   	push   %ebp
80105e50:	89 e5                	mov    %esp,%ebp
80105e52:	57                   	push   %edi
80105e53:	56                   	push   %esi
80105e54:	53                   	push   %ebx
80105e55:	83 ec 1c             	sub    $0x1c,%esp
80105e58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105e5b:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105e5e:	89 d3                	mov    %edx,%ebx
80105e60:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105e66:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105e6a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e70:	b9 01 00 00 00       	mov    $0x1,%ecx
80105e75:	89 da                	mov    %ebx,%edx
80105e77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e7a:	e8 5f ff ff ff       	call   80105dde <walkpgdir>
80105e7f:	85 c0                	test   %eax,%eax
80105e81:	74 2e                	je     80105eb1 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105e83:	f6 00 01             	testb  $0x1,(%eax)
80105e86:	75 1c                	jne    80105ea4 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105e88:	89 f2                	mov    %esi,%edx
80105e8a:	0b 55 0c             	or     0xc(%ebp),%edx
80105e8d:	83 ca 01             	or     $0x1,%edx
80105e90:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105e92:	39 fb                	cmp    %edi,%ebx
80105e94:	74 28                	je     80105ebe <mappages+0x6f>
      break;
    a += PGSIZE;
80105e96:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e9c:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105ea2:	eb cc                	jmp    80105e70 <mappages+0x21>
      panic("remap");
80105ea4:	83 ec 0c             	sub    $0xc,%esp
80105ea7:	68 8c 6f 10 80       	push   $0x80106f8c
80105eac:	e8 ab a4 ff ff       	call   8010035c <panic>
      return -1;
80105eb1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105eb6:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105eb9:	5b                   	pop    %ebx
80105eba:	5e                   	pop    %esi
80105ebb:	5f                   	pop    %edi
80105ebc:	5d                   	pop    %ebp
80105ebd:	c3                   	ret    
  return 0;
80105ebe:	b8 00 00 00 00       	mov    $0x0,%eax
80105ec3:	eb f1                	jmp    80105eb6 <mappages+0x67>

80105ec5 <seginit>:
{
80105ec5:	f3 0f 1e fb          	endbr32 
80105ec9:	55                   	push   %ebp
80105eca:	89 e5                	mov    %esp,%ebp
80105ecc:	53                   	push   %ebx
80105ecd:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105ed0:	e8 26 d4 ff ff       	call   801032fb <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105ed5:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105edb:	66 c7 80 58 48 11 80 	movw   $0xffff,-0x7feeb7a8(%eax)
80105ee2:	ff ff 
80105ee4:	66 c7 80 5a 48 11 80 	movw   $0x0,-0x7feeb7a6(%eax)
80105eeb:	00 00 
80105eed:	c6 80 5c 48 11 80 00 	movb   $0x0,-0x7feeb7a4(%eax)
80105ef4:	0f b6 88 5d 48 11 80 	movzbl -0x7feeb7a3(%eax),%ecx
80105efb:	83 e1 f0             	and    $0xfffffff0,%ecx
80105efe:	83 c9 1a             	or     $0x1a,%ecx
80105f01:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f04:	83 c9 80             	or     $0xffffff80,%ecx
80105f07:	88 88 5d 48 11 80    	mov    %cl,-0x7feeb7a3(%eax)
80105f0d:	0f b6 88 5e 48 11 80 	movzbl -0x7feeb7a2(%eax),%ecx
80105f14:	83 c9 0f             	or     $0xf,%ecx
80105f17:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f1a:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f1d:	88 88 5e 48 11 80    	mov    %cl,-0x7feeb7a2(%eax)
80105f23:	c6 80 5f 48 11 80 00 	movb   $0x0,-0x7feeb7a1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105f2a:	66 c7 80 60 48 11 80 	movw   $0xffff,-0x7feeb7a0(%eax)
80105f31:	ff ff 
80105f33:	66 c7 80 62 48 11 80 	movw   $0x0,-0x7feeb79e(%eax)
80105f3a:	00 00 
80105f3c:	c6 80 64 48 11 80 00 	movb   $0x0,-0x7feeb79c(%eax)
80105f43:	0f b6 88 65 48 11 80 	movzbl -0x7feeb79b(%eax),%ecx
80105f4a:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f4d:	83 c9 12             	or     $0x12,%ecx
80105f50:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f53:	83 c9 80             	or     $0xffffff80,%ecx
80105f56:	88 88 65 48 11 80    	mov    %cl,-0x7feeb79b(%eax)
80105f5c:	0f b6 88 66 48 11 80 	movzbl -0x7feeb79a(%eax),%ecx
80105f63:	83 c9 0f             	or     $0xf,%ecx
80105f66:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f69:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f6c:	88 88 66 48 11 80    	mov    %cl,-0x7feeb79a(%eax)
80105f72:	c6 80 67 48 11 80 00 	movb   $0x0,-0x7feeb799(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105f79:	66 c7 80 68 48 11 80 	movw   $0xffff,-0x7feeb798(%eax)
80105f80:	ff ff 
80105f82:	66 c7 80 6a 48 11 80 	movw   $0x0,-0x7feeb796(%eax)
80105f89:	00 00 
80105f8b:	c6 80 6c 48 11 80 00 	movb   $0x0,-0x7feeb794(%eax)
80105f92:	c6 80 6d 48 11 80 fa 	movb   $0xfa,-0x7feeb793(%eax)
80105f99:	0f b6 88 6e 48 11 80 	movzbl -0x7feeb792(%eax),%ecx
80105fa0:	83 c9 0f             	or     $0xf,%ecx
80105fa3:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fa6:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fa9:	88 88 6e 48 11 80    	mov    %cl,-0x7feeb792(%eax)
80105faf:	c6 80 6f 48 11 80 00 	movb   $0x0,-0x7feeb791(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105fb6:	66 c7 80 70 48 11 80 	movw   $0xffff,-0x7feeb790(%eax)
80105fbd:	ff ff 
80105fbf:	66 c7 80 72 48 11 80 	movw   $0x0,-0x7feeb78e(%eax)
80105fc6:	00 00 
80105fc8:	c6 80 74 48 11 80 00 	movb   $0x0,-0x7feeb78c(%eax)
80105fcf:	c6 80 75 48 11 80 f2 	movb   $0xf2,-0x7feeb78b(%eax)
80105fd6:	0f b6 88 76 48 11 80 	movzbl -0x7feeb78a(%eax),%ecx
80105fdd:	83 c9 0f             	or     $0xf,%ecx
80105fe0:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fe3:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fe6:	88 88 76 48 11 80    	mov    %cl,-0x7feeb78a(%eax)
80105fec:	c6 80 77 48 11 80 00 	movb   $0x0,-0x7feeb789(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105ff3:	05 50 48 11 80       	add    $0x80114850,%eax
  pd[0] = size-1;
80105ff8:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105ffe:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106002:	c1 e8 10             	shr    $0x10,%eax
80106005:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106009:	8d 45 f2             	lea    -0xe(%ebp),%eax
8010600c:	0f 01 10             	lgdtl  (%eax)
}
8010600f:	83 c4 14             	add    $0x14,%esp
80106012:	5b                   	pop    %ebx
80106013:	5d                   	pop    %ebp
80106014:	c3                   	ret    

80106015 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106015:	f3 0f 1e fb          	endbr32 
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106019:	a1 84 55 11 80       	mov    0x80115584,%eax
8010601e:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106023:	0f 22 d8             	mov    %eax,%cr3
}
80106026:	c3                   	ret    

80106027 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80106027:	f3 0f 1e fb          	endbr32 
8010602b:	55                   	push   %ebp
8010602c:	89 e5                	mov    %esp,%ebp
8010602e:	57                   	push   %edi
8010602f:	56                   	push   %esi
80106030:	53                   	push   %ebx
80106031:	83 ec 1c             	sub    $0x1c,%esp
80106034:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106037:	85 f6                	test   %esi,%esi
80106039:	0f 84 dd 00 00 00    	je     8010611c <switchuvm+0xf5>
    panic("switchuvm: no process");
  if(p->kstack == 0)
8010603f:	83 7e 0c 00          	cmpl   $0x0,0xc(%esi)
80106043:	0f 84 e0 00 00 00    	je     80106129 <switchuvm+0x102>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106049:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
8010604d:	0f 84 e3 00 00 00    	je     80106136 <switchuvm+0x10f>
    panic("switchuvm: no pgdir");

  pushcli();
80106053:	e8 6d dc ff ff       	call   80103cc5 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106058:	e8 3e d2 ff ff       	call   8010329b <mycpu>
8010605d:	89 c3                	mov    %eax,%ebx
8010605f:	e8 37 d2 ff ff       	call   8010329b <mycpu>
80106064:	8d 78 08             	lea    0x8(%eax),%edi
80106067:	e8 2f d2 ff ff       	call   8010329b <mycpu>
8010606c:	83 c0 08             	add    $0x8,%eax
8010606f:	c1 e8 10             	shr    $0x10,%eax
80106072:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106075:	e8 21 d2 ff ff       	call   8010329b <mycpu>
8010607a:	83 c0 08             	add    $0x8,%eax
8010607d:	c1 e8 18             	shr    $0x18,%eax
80106080:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106087:	67 00 
80106089:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106090:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80106094:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
8010609a:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
801060a1:	83 e2 f0             	and    $0xfffffff0,%edx
801060a4:	83 ca 19             	or     $0x19,%edx
801060a7:	83 e2 9f             	and    $0xffffff9f,%edx
801060aa:	83 ca 80             	or     $0xffffff80,%edx
801060ad:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
801060b3:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
801060ba:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801060c0:	e8 d6 d1 ff ff       	call   8010329b <mycpu>
801060c5:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801060cc:	83 e2 ef             	and    $0xffffffef,%edx
801060cf:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
801060d5:	e8 c1 d1 ff ff       	call   8010329b <mycpu>
801060da:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
801060e0:	8b 5e 0c             	mov    0xc(%esi),%ebx
801060e3:	e8 b3 d1 ff ff       	call   8010329b <mycpu>
801060e8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060ee:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801060f1:	e8 a5 d1 ff ff       	call   8010329b <mycpu>
801060f6:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801060fc:	b8 28 00 00 00       	mov    $0x28,%eax
80106101:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106104:	8b 46 08             	mov    0x8(%esi),%eax
80106107:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010610c:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010610f:	e8 f2 db ff ff       	call   80103d06 <popcli>
}
80106114:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106117:	5b                   	pop    %ebx
80106118:	5e                   	pop    %esi
80106119:	5f                   	pop    %edi
8010611a:	5d                   	pop    %ebp
8010611b:	c3                   	ret    
    panic("switchuvm: no process");
8010611c:	83 ec 0c             	sub    $0xc,%esp
8010611f:	68 92 6f 10 80       	push   $0x80106f92
80106124:	e8 33 a2 ff ff       	call   8010035c <panic>
    panic("switchuvm: no kstack");
80106129:	83 ec 0c             	sub    $0xc,%esp
8010612c:	68 a8 6f 10 80       	push   $0x80106fa8
80106131:	e8 26 a2 ff ff       	call   8010035c <panic>
    panic("switchuvm: no pgdir");
80106136:	83 ec 0c             	sub    $0xc,%esp
80106139:	68 bd 6f 10 80       	push   $0x80106fbd
8010613e:	e8 19 a2 ff ff       	call   8010035c <panic>

80106143 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106143:	f3 0f 1e fb          	endbr32 
80106147:	55                   	push   %ebp
80106148:	89 e5                	mov    %esp,%ebp
8010614a:	56                   	push   %esi
8010614b:	53                   	push   %ebx
8010614c:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010614f:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106155:	77 4c                	ja     801061a3 <inituvm+0x60>
    panic("inituvm: more than a page");
  mem = kalloc();
80106157:	e8 34 c0 ff ff       	call   80102190 <kalloc>
8010615c:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010615e:	83 ec 04             	sub    $0x4,%esp
80106161:	68 00 10 00 00       	push   $0x1000
80106166:	6a 00                	push   $0x0
80106168:	50                   	push   %eax
80106169:	e8 f4 dc ff ff       	call   80103e62 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010616e:	83 c4 08             	add    $0x8,%esp
80106171:	6a 06                	push   $0x6
80106173:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106179:	50                   	push   %eax
8010617a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010617f:	ba 00 00 00 00       	mov    $0x0,%edx
80106184:	8b 45 08             	mov    0x8(%ebp),%eax
80106187:	e8 c3 fc ff ff       	call   80105e4f <mappages>
  memmove(mem, init, sz);
8010618c:	83 c4 0c             	add    $0xc,%esp
8010618f:	56                   	push   %esi
80106190:	ff 75 0c             	pushl  0xc(%ebp)
80106193:	53                   	push   %ebx
80106194:	e8 49 dd ff ff       	call   80103ee2 <memmove>
}
80106199:	83 c4 10             	add    $0x10,%esp
8010619c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010619f:	5b                   	pop    %ebx
801061a0:	5e                   	pop    %esi
801061a1:	5d                   	pop    %ebp
801061a2:	c3                   	ret    
    panic("inituvm: more than a page");
801061a3:	83 ec 0c             	sub    $0xc,%esp
801061a6:	68 d1 6f 10 80       	push   $0x80106fd1
801061ab:	e8 ac a1 ff ff       	call   8010035c <panic>

801061b0 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801061b0:	f3 0f 1e fb          	endbr32 
801061b4:	55                   	push   %ebp
801061b5:	89 e5                	mov    %esp,%ebp
801061b7:	57                   	push   %edi
801061b8:	56                   	push   %esi
801061b9:	53                   	push   %ebx
801061ba:	83 ec 0c             	sub    $0xc,%esp
801061bd:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801061c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801061c3:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801061c9:	74 3c                	je     80106207 <loaduvm+0x57>
    panic("loaduvm: addr must be page aligned");
801061cb:	83 ec 0c             	sub    $0xc,%esp
801061ce:	68 8c 70 10 80       	push   $0x8010708c
801061d3:	e8 84 a1 ff ff       	call   8010035c <panic>
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801061d8:	83 ec 0c             	sub    $0xc,%esp
801061db:	68 eb 6f 10 80       	push   $0x80106feb
801061e0:	e8 77 a1 ff ff       	call   8010035c <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801061e5:	05 00 00 00 80       	add    $0x80000000,%eax
801061ea:	56                   	push   %esi
801061eb:	89 da                	mov    %ebx,%edx
801061ed:	03 55 14             	add    0x14(%ebp),%edx
801061f0:	52                   	push   %edx
801061f1:	50                   	push   %eax
801061f2:	ff 75 10             	pushl  0x10(%ebp)
801061f5:	e8 14 b6 ff ff       	call   8010180e <readi>
801061fa:	83 c4 10             	add    $0x10,%esp
801061fd:	39 f0                	cmp    %esi,%eax
801061ff:	75 47                	jne    80106248 <loaduvm+0x98>
  for(i = 0; i < sz; i += PGSIZE){
80106201:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106207:	39 fb                	cmp    %edi,%ebx
80106209:	73 30                	jae    8010623b <loaduvm+0x8b>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010620b:	89 da                	mov    %ebx,%edx
8010620d:	03 55 0c             	add    0xc(%ebp),%edx
80106210:	b9 00 00 00 00       	mov    $0x0,%ecx
80106215:	8b 45 08             	mov    0x8(%ebp),%eax
80106218:	e8 c1 fb ff ff       	call   80105dde <walkpgdir>
8010621d:	85 c0                	test   %eax,%eax
8010621f:	74 b7                	je     801061d8 <loaduvm+0x28>
    pa = PTE_ADDR(*pte);
80106221:	8b 00                	mov    (%eax),%eax
80106223:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106228:	89 fe                	mov    %edi,%esi
8010622a:	29 de                	sub    %ebx,%esi
8010622c:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106232:	76 b1                	jbe    801061e5 <loaduvm+0x35>
      n = PGSIZE;
80106234:	be 00 10 00 00       	mov    $0x1000,%esi
80106239:	eb aa                	jmp    801061e5 <loaduvm+0x35>
      return -1;
  }
  return 0;
8010623b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106240:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106243:	5b                   	pop    %ebx
80106244:	5e                   	pop    %esi
80106245:	5f                   	pop    %edi
80106246:	5d                   	pop    %ebp
80106247:	c3                   	ret    
      return -1;
80106248:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010624d:	eb f1                	jmp    80106240 <loaduvm+0x90>

8010624f <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010624f:	f3 0f 1e fb          	endbr32 
80106253:	55                   	push   %ebp
80106254:	89 e5                	mov    %esp,%ebp
80106256:	57                   	push   %edi
80106257:	56                   	push   %esi
80106258:	53                   	push   %ebx
80106259:	83 ec 0c             	sub    $0xc,%esp
8010625c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010625f:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106262:	73 11                	jae    80106275 <deallocuvm+0x26>
    return oldsz;

  a = PGROUNDUP(newsz);
80106264:	8b 45 10             	mov    0x10(%ebp),%eax
80106267:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010626d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106273:	eb 19                	jmp    8010628e <deallocuvm+0x3f>
    return oldsz;
80106275:	89 f8                	mov    %edi,%eax
80106277:	eb 64                	jmp    801062dd <deallocuvm+0x8e>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106279:	c1 eb 16             	shr    $0x16,%ebx
8010627c:	83 c3 01             	add    $0x1,%ebx
8010627f:	c1 e3 16             	shl    $0x16,%ebx
80106282:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106288:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010628e:	39 fb                	cmp    %edi,%ebx
80106290:	73 48                	jae    801062da <deallocuvm+0x8b>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106292:	b9 00 00 00 00       	mov    $0x0,%ecx
80106297:	89 da                	mov    %ebx,%edx
80106299:	8b 45 08             	mov    0x8(%ebp),%eax
8010629c:	e8 3d fb ff ff       	call   80105dde <walkpgdir>
801062a1:	89 c6                	mov    %eax,%esi
    if(!pte)
801062a3:	85 c0                	test   %eax,%eax
801062a5:	74 d2                	je     80106279 <deallocuvm+0x2a>
    else if((*pte & PTE_P) != 0){
801062a7:	8b 00                	mov    (%eax),%eax
801062a9:	a8 01                	test   $0x1,%al
801062ab:	74 db                	je     80106288 <deallocuvm+0x39>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801062ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801062b2:	74 19                	je     801062cd <deallocuvm+0x7e>
        panic("kfree");
      char *v = P2V(pa);
801062b4:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801062b9:	83 ec 0c             	sub    $0xc,%esp
801062bc:	50                   	push   %eax
801062bd:	e8 a7 bd ff ff       	call   80102069 <kfree>
      *pte = 0;
801062c2:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801062c8:	83 c4 10             	add    $0x10,%esp
801062cb:	eb bb                	jmp    80106288 <deallocuvm+0x39>
        panic("kfree");
801062cd:	83 ec 0c             	sub    $0xc,%esp
801062d0:	68 0e 69 10 80       	push   $0x8010690e
801062d5:	e8 82 a0 ff ff       	call   8010035c <panic>
    }
  }
  return newsz;
801062da:	8b 45 10             	mov    0x10(%ebp),%eax
}
801062dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062e0:	5b                   	pop    %ebx
801062e1:	5e                   	pop    %esi
801062e2:	5f                   	pop    %edi
801062e3:	5d                   	pop    %ebp
801062e4:	c3                   	ret    

801062e5 <allocuvm>:
{
801062e5:	f3 0f 1e fb          	endbr32 
801062e9:	55                   	push   %ebp
801062ea:	89 e5                	mov    %esp,%ebp
801062ec:	57                   	push   %edi
801062ed:	56                   	push   %esi
801062ee:	53                   	push   %ebx
801062ef:	83 ec 1c             	sub    $0x1c,%esp
801062f2:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801062f5:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801062f8:	85 ff                	test   %edi,%edi
801062fa:	0f 88 c0 00 00 00    	js     801063c0 <allocuvm+0xdb>
  if(newsz < oldsz)
80106300:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106303:	72 11                	jb     80106316 <allocuvm+0x31>
  a = PGROUNDUP(oldsz);
80106305:	8b 45 0c             	mov    0xc(%ebp),%eax
80106308:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
8010630e:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
  for(; a < newsz; a += PGSIZE){
80106314:	eb 39                	jmp    8010634f <allocuvm+0x6a>
    return oldsz;
80106316:	8b 45 0c             	mov    0xc(%ebp),%eax
80106319:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010631c:	e9 a6 00 00 00       	jmp    801063c7 <allocuvm+0xe2>
      cprintf("allocuvm out of memory\n");
80106321:	83 ec 0c             	sub    $0xc,%esp
80106324:	68 09 70 10 80       	push   $0x80107009
80106329:	e8 fb a2 ff ff       	call   80100629 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010632e:	83 c4 0c             	add    $0xc,%esp
80106331:	ff 75 0c             	pushl  0xc(%ebp)
80106334:	57                   	push   %edi
80106335:	ff 75 08             	pushl  0x8(%ebp)
80106338:	e8 12 ff ff ff       	call   8010624f <deallocuvm>
      return 0;
8010633d:	83 c4 10             	add    $0x10,%esp
80106340:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106347:	eb 7e                	jmp    801063c7 <allocuvm+0xe2>
  for(; a < newsz; a += PGSIZE){
80106349:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010634f:	39 fe                	cmp    %edi,%esi
80106351:	73 74                	jae    801063c7 <allocuvm+0xe2>
    mem = kalloc();
80106353:	e8 38 be ff ff       	call   80102190 <kalloc>
80106358:	89 c3                	mov    %eax,%ebx
    if(mem == 0){
8010635a:	85 c0                	test   %eax,%eax
8010635c:	74 c3                	je     80106321 <allocuvm+0x3c>
    memset(mem, 0, PGSIZE);
8010635e:	83 ec 04             	sub    $0x4,%esp
80106361:	68 00 10 00 00       	push   $0x1000
80106366:	6a 00                	push   $0x0
80106368:	50                   	push   %eax
80106369:	e8 f4 da ff ff       	call   80103e62 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010636e:	83 c4 08             	add    $0x8,%esp
80106371:	6a 06                	push   $0x6
80106373:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106379:	50                   	push   %eax
8010637a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010637f:	89 f2                	mov    %esi,%edx
80106381:	8b 45 08             	mov    0x8(%ebp),%eax
80106384:	e8 c6 fa ff ff       	call   80105e4f <mappages>
80106389:	83 c4 10             	add    $0x10,%esp
8010638c:	85 c0                	test   %eax,%eax
8010638e:	79 b9                	jns    80106349 <allocuvm+0x64>
      cprintf("allocuvm out of memory (2)\n");
80106390:	83 ec 0c             	sub    $0xc,%esp
80106393:	68 21 70 10 80       	push   $0x80107021
80106398:	e8 8c a2 ff ff       	call   80100629 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010639d:	83 c4 0c             	add    $0xc,%esp
801063a0:	ff 75 0c             	pushl  0xc(%ebp)
801063a3:	57                   	push   %edi
801063a4:	ff 75 08             	pushl  0x8(%ebp)
801063a7:	e8 a3 fe ff ff       	call   8010624f <deallocuvm>
      kfree(mem);
801063ac:	89 1c 24             	mov    %ebx,(%esp)
801063af:	e8 b5 bc ff ff       	call   80102069 <kfree>
      return 0;
801063b4:	83 c4 10             	add    $0x10,%esp
801063b7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801063be:	eb 07                	jmp    801063c7 <allocuvm+0xe2>
    return 0;
801063c0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801063c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
801063cd:	5b                   	pop    %ebx
801063ce:	5e                   	pop    %esi
801063cf:	5f                   	pop    %edi
801063d0:	5d                   	pop    %ebp
801063d1:	c3                   	ret    

801063d2 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801063d2:	f3 0f 1e fb          	endbr32 
801063d6:	55                   	push   %ebp
801063d7:	89 e5                	mov    %esp,%ebp
801063d9:	56                   	push   %esi
801063da:	53                   	push   %ebx
801063db:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801063de:	85 f6                	test   %esi,%esi
801063e0:	74 1a                	je     801063fc <freevm+0x2a>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801063e2:	83 ec 04             	sub    $0x4,%esp
801063e5:	6a 00                	push   $0x0
801063e7:	68 00 00 00 80       	push   $0x80000000
801063ec:	56                   	push   %esi
801063ed:	e8 5d fe ff ff       	call   8010624f <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801063f2:	83 c4 10             	add    $0x10,%esp
801063f5:	bb 00 00 00 00       	mov    $0x0,%ebx
801063fa:	eb 26                	jmp    80106422 <freevm+0x50>
    panic("freevm: no pgdir");
801063fc:	83 ec 0c             	sub    $0xc,%esp
801063ff:	68 3d 70 10 80       	push   $0x8010703d
80106404:	e8 53 9f ff ff       	call   8010035c <panic>
    if(pgdir[i] & PTE_P){
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106409:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010640e:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106413:	83 ec 0c             	sub    $0xc,%esp
80106416:	50                   	push   %eax
80106417:	e8 4d bc ff ff       	call   80102069 <kfree>
8010641c:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
8010641f:	83 c3 01             	add    $0x1,%ebx
80106422:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106428:	77 09                	ja     80106433 <freevm+0x61>
    if(pgdir[i] & PTE_P){
8010642a:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010642d:	a8 01                	test   $0x1,%al
8010642f:	74 ee                	je     8010641f <freevm+0x4d>
80106431:	eb d6                	jmp    80106409 <freevm+0x37>
    }
  }
  kfree((char*)pgdir);
80106433:	83 ec 0c             	sub    $0xc,%esp
80106436:	56                   	push   %esi
80106437:	e8 2d bc ff ff       	call   80102069 <kfree>
}
8010643c:	83 c4 10             	add    $0x10,%esp
8010643f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106442:	5b                   	pop    %ebx
80106443:	5e                   	pop    %esi
80106444:	5d                   	pop    %ebp
80106445:	c3                   	ret    

80106446 <setupkvm>:
{
80106446:	f3 0f 1e fb          	endbr32 
8010644a:	55                   	push   %ebp
8010644b:	89 e5                	mov    %esp,%ebp
8010644d:	56                   	push   %esi
8010644e:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
8010644f:	e8 3c bd ff ff       	call   80102190 <kalloc>
80106454:	89 c6                	mov    %eax,%esi
80106456:	85 c0                	test   %eax,%eax
80106458:	74 55                	je     801064af <setupkvm+0x69>
  memset(pgdir, 0, PGSIZE);
8010645a:	83 ec 04             	sub    $0x4,%esp
8010645d:	68 00 10 00 00       	push   $0x1000
80106462:	6a 00                	push   $0x0
80106464:	50                   	push   %eax
80106465:	e8 f8 d9 ff ff       	call   80103e62 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010646a:	83 c4 10             	add    $0x10,%esp
8010646d:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
80106472:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
80106478:	73 35                	jae    801064af <setupkvm+0x69>
                (uint)k->phys_start, k->perm) < 0) {
8010647a:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010647d:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106480:	29 c1                	sub    %eax,%ecx
80106482:	83 ec 08             	sub    $0x8,%esp
80106485:	ff 73 0c             	pushl  0xc(%ebx)
80106488:	50                   	push   %eax
80106489:	8b 13                	mov    (%ebx),%edx
8010648b:	89 f0                	mov    %esi,%eax
8010648d:	e8 bd f9 ff ff       	call   80105e4f <mappages>
80106492:	83 c4 10             	add    $0x10,%esp
80106495:	85 c0                	test   %eax,%eax
80106497:	78 05                	js     8010649e <setupkvm+0x58>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106499:	83 c3 10             	add    $0x10,%ebx
8010649c:	eb d4                	jmp    80106472 <setupkvm+0x2c>
      freevm(pgdir);
8010649e:	83 ec 0c             	sub    $0xc,%esp
801064a1:	56                   	push   %esi
801064a2:	e8 2b ff ff ff       	call   801063d2 <freevm>
      return 0;
801064a7:	83 c4 10             	add    $0x10,%esp
801064aa:	be 00 00 00 00       	mov    $0x0,%esi
}
801064af:	89 f0                	mov    %esi,%eax
801064b1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064b4:	5b                   	pop    %ebx
801064b5:	5e                   	pop    %esi
801064b6:	5d                   	pop    %ebp
801064b7:	c3                   	ret    

801064b8 <kvmalloc>:
{
801064b8:	f3 0f 1e fb          	endbr32 
801064bc:	55                   	push   %ebp
801064bd:	89 e5                	mov    %esp,%ebp
801064bf:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801064c2:	e8 7f ff ff ff       	call   80106446 <setupkvm>
801064c7:	a3 84 55 11 80       	mov    %eax,0x80115584
  switchkvm();
801064cc:	e8 44 fb ff ff       	call   80106015 <switchkvm>
}
801064d1:	c9                   	leave  
801064d2:	c3                   	ret    

801064d3 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801064d3:	f3 0f 1e fb          	endbr32 
801064d7:	55                   	push   %ebp
801064d8:	89 e5                	mov    %esp,%ebp
801064da:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801064dd:	b9 00 00 00 00       	mov    $0x0,%ecx
801064e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801064e5:	8b 45 08             	mov    0x8(%ebp),%eax
801064e8:	e8 f1 f8 ff ff       	call   80105dde <walkpgdir>
  if(pte == 0)
801064ed:	85 c0                	test   %eax,%eax
801064ef:	74 05                	je     801064f6 <clearpteu+0x23>
    panic("clearpteu");
  *pte &= ~PTE_U;
801064f1:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801064f4:	c9                   	leave  
801064f5:	c3                   	ret    
    panic("clearpteu");
801064f6:	83 ec 0c             	sub    $0xc,%esp
801064f9:	68 4e 70 10 80       	push   $0x8010704e
801064fe:	e8 59 9e ff ff       	call   8010035c <panic>

80106503 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80106503:	f3 0f 1e fb          	endbr32 
80106507:	55                   	push   %ebp
80106508:	89 e5                	mov    %esp,%ebp
8010650a:	57                   	push   %edi
8010650b:	56                   	push   %esi
8010650c:	53                   	push   %ebx
8010650d:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106510:	e8 31 ff ff ff       	call   80106446 <setupkvm>
80106515:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106518:	85 c0                	test   %eax,%eax
8010651a:	0f 84 b8 00 00 00    	je     801065d8 <copyuvm+0xd5>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106520:	bf 00 00 00 00       	mov    $0x0,%edi
80106525:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106528:	0f 83 aa 00 00 00    	jae    801065d8 <copyuvm+0xd5>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010652e:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106531:	b9 00 00 00 00       	mov    $0x0,%ecx
80106536:	89 fa                	mov    %edi,%edx
80106538:	8b 45 08             	mov    0x8(%ebp),%eax
8010653b:	e8 9e f8 ff ff       	call   80105dde <walkpgdir>
80106540:	85 c0                	test   %eax,%eax
80106542:	74 65                	je     801065a9 <copyuvm+0xa6>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106544:	8b 00                	mov    (%eax),%eax
80106546:	a8 01                	test   $0x1,%al
80106548:	74 6c                	je     801065b6 <copyuvm+0xb3>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
8010654a:	89 c6                	mov    %eax,%esi
8010654c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
80106552:	25 ff 0f 00 00       	and    $0xfff,%eax
80106557:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
8010655a:	e8 31 bc ff ff       	call   80102190 <kalloc>
8010655f:	89 c3                	mov    %eax,%ebx
80106561:	85 c0                	test   %eax,%eax
80106563:	74 5e                	je     801065c3 <copyuvm+0xc0>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106565:	81 c6 00 00 00 80    	add    $0x80000000,%esi
8010656b:	83 ec 04             	sub    $0x4,%esp
8010656e:	68 00 10 00 00       	push   $0x1000
80106573:	56                   	push   %esi
80106574:	50                   	push   %eax
80106575:	e8 68 d9 ff ff       	call   80103ee2 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
8010657a:	83 c4 08             	add    $0x8,%esp
8010657d:	ff 75 e0             	pushl  -0x20(%ebp)
80106580:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
80106586:	53                   	push   %ebx
80106587:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010658c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010658f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106592:	e8 b8 f8 ff ff       	call   80105e4f <mappages>
80106597:	83 c4 10             	add    $0x10,%esp
8010659a:	85 c0                	test   %eax,%eax
8010659c:	78 25                	js     801065c3 <copyuvm+0xc0>
  for(i = 0; i < sz; i += PGSIZE){
8010659e:	81 c7 00 10 00 00    	add    $0x1000,%edi
801065a4:	e9 7c ff ff ff       	jmp    80106525 <copyuvm+0x22>
      panic("copyuvm: pte should exist");
801065a9:	83 ec 0c             	sub    $0xc,%esp
801065ac:	68 58 70 10 80       	push   $0x80107058
801065b1:	e8 a6 9d ff ff       	call   8010035c <panic>
      panic("copyuvm: page not present");
801065b6:	83 ec 0c             	sub    $0xc,%esp
801065b9:	68 72 70 10 80       	push   $0x80107072
801065be:	e8 99 9d ff ff       	call   8010035c <panic>
      goto bad;
  }
  return d;

bad:
  freevm(d);
801065c3:	83 ec 0c             	sub    $0xc,%esp
801065c6:	ff 75 dc             	pushl  -0x24(%ebp)
801065c9:	e8 04 fe ff ff       	call   801063d2 <freevm>
  return 0;
801065ce:	83 c4 10             	add    $0x10,%esp
801065d1:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801065d8:	8b 45 dc             	mov    -0x24(%ebp),%eax
801065db:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065de:	5b                   	pop    %ebx
801065df:	5e                   	pop    %esi
801065e0:	5f                   	pop    %edi
801065e1:	5d                   	pop    %ebp
801065e2:	c3                   	ret    

801065e3 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801065e3:	f3 0f 1e fb          	endbr32 
801065e7:	55                   	push   %ebp
801065e8:	89 e5                	mov    %esp,%ebp
801065ea:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801065ed:	b9 00 00 00 00       	mov    $0x0,%ecx
801065f2:	8b 55 0c             	mov    0xc(%ebp),%edx
801065f5:	8b 45 08             	mov    0x8(%ebp),%eax
801065f8:	e8 e1 f7 ff ff       	call   80105dde <walkpgdir>
  if((*pte & PTE_P) == 0)
801065fd:	8b 00                	mov    (%eax),%eax
801065ff:	a8 01                	test   $0x1,%al
80106601:	74 10                	je     80106613 <uva2ka+0x30>
    return 0;
  if((*pte & PTE_U) == 0)
80106603:	a8 04                	test   $0x4,%al
80106605:	74 13                	je     8010661a <uva2ka+0x37>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106607:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010660c:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106611:	c9                   	leave  
80106612:	c3                   	ret    
    return 0;
80106613:	b8 00 00 00 00       	mov    $0x0,%eax
80106618:	eb f7                	jmp    80106611 <uva2ka+0x2e>
    return 0;
8010661a:	b8 00 00 00 00       	mov    $0x0,%eax
8010661f:	eb f0                	jmp    80106611 <uva2ka+0x2e>

80106621 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80106621:	f3 0f 1e fb          	endbr32 
80106625:	55                   	push   %ebp
80106626:	89 e5                	mov    %esp,%ebp
80106628:	57                   	push   %edi
80106629:	56                   	push   %esi
8010662a:	53                   	push   %ebx
8010662b:	83 ec 0c             	sub    $0xc,%esp
8010662e:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80106631:	eb 25                	jmp    80106658 <copyout+0x37>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106633:	8b 55 0c             	mov    0xc(%ebp),%edx
80106636:	29 f2                	sub    %esi,%edx
80106638:	01 d0                	add    %edx,%eax
8010663a:	83 ec 04             	sub    $0x4,%esp
8010663d:	53                   	push   %ebx
8010663e:	ff 75 10             	pushl  0x10(%ebp)
80106641:	50                   	push   %eax
80106642:	e8 9b d8 ff ff       	call   80103ee2 <memmove>
    len -= n;
80106647:	29 df                	sub    %ebx,%edi
    buf += n;
80106649:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
8010664c:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106652:	89 45 0c             	mov    %eax,0xc(%ebp)
80106655:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106658:	85 ff                	test   %edi,%edi
8010665a:	74 2f                	je     8010668b <copyout+0x6a>
    va0 = (uint)PGROUNDDOWN(va);
8010665c:	8b 75 0c             	mov    0xc(%ebp),%esi
8010665f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106665:	83 ec 08             	sub    $0x8,%esp
80106668:	56                   	push   %esi
80106669:	ff 75 08             	pushl  0x8(%ebp)
8010666c:	e8 72 ff ff ff       	call   801065e3 <uva2ka>
    if(pa0 == 0)
80106671:	83 c4 10             	add    $0x10,%esp
80106674:	85 c0                	test   %eax,%eax
80106676:	74 20                	je     80106698 <copyout+0x77>
    n = PGSIZE - (va - va0);
80106678:	89 f3                	mov    %esi,%ebx
8010667a:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010667d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106683:	39 df                	cmp    %ebx,%edi
80106685:	73 ac                	jae    80106633 <copyout+0x12>
      n = len;
80106687:	89 fb                	mov    %edi,%ebx
80106689:	eb a8                	jmp    80106633 <copyout+0x12>
  }
  return 0;
8010668b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106690:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106693:	5b                   	pop    %ebx
80106694:	5e                   	pop    %esi
80106695:	5f                   	pop    %edi
80106696:	5d                   	pop    %ebp
80106697:	c3                   	ret    
      return -1;
80106698:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010669d:	eb f1                	jmp    80106690 <copyout+0x6f>
