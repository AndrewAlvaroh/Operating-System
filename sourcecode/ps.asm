
_ps:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:

#define MAX 16

int
main(void)
{
   0:	f3 0f 1e fb          	endbr32 
   4:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   8:	83 e4 f0             	and    $0xfffffff0,%esp
   b:	ff 71 fc             	pushl  -0x4(%ecx)
   e:	55                   	push   %ebp
   f:	89 e5                	mov    %esp,%ebp
  11:	57                   	push   %edi
  12:	56                   	push   %esi
  13:	53                   	push   %ebx
  14:	51                   	push   %ecx
  15:	81 ec 84 00 00 00    	sub    $0x84,%esp
  struct uproc *proc = malloc(sizeof(struct uproc)*MAX);
  1b:	68 c0 05 00 00       	push   $0x5c0
  20:	e8 62 07 00 00       	call   787 <malloc>
  25:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
  int procsNumber = getprocs(MAX, proc);
  2b:	83 c4 08             	add    $0x8,%esp
  2e:	50                   	push   %eax
  2f:	6a 10                	push   $0x10
  31:	e8 77 04 00 00       	call   4ad <getprocs>
  36:	89 85 78 ff ff ff    	mov    %eax,-0x88(%ebp)
  printf(1,"PID\tName\t\tUID\tGID\tPPID\tElapsed\tCPU\tState\tSize\n");
  3c:	83 c4 08             	add    $0x8,%esp
  3f:	68 18 08 00 00       	push   $0x818
  44:	6a 01                	push   $0x1
  46:	e8 0b 05 00 00       	call   556 <printf>

  int i;
  for(i = 0; i<procsNumber; i++){
  4b:	83 c4 10             	add    $0x10,%esp
  4e:	bb 00 00 00 00       	mov    $0x0,%ebx
  53:	eb 64                	jmp    b9 <main+0xb9>
    uint cpuTotalTicksSecond = cpuTotalTicks/1000;
    uint cpuTotalTicksMs = cpuTotalTicks % 1000;
    char* cpuZeros = "";

    if (elapsedTicksMs < 10) {
      zeros = "00";
  55:	c7 45 84 14 08 00 00 	movl   $0x814,-0x7c(%ebp)
    } else if (elapsedTicksMs < 100) {
      zeros = "0";
    }

    if(cpuTotalTicksMs < 10){
  5c:	83 f8 09             	cmp    $0x9,%eax
  5f:	76 1b                	jbe    7c <main+0x7c>
      cpuZeros = "00";
    } else if (cpuTotalTicksMs < 100) {
  61:	83 f8 63             	cmp    $0x63,%eax
  64:	0f 86 b6 00 00 00    	jbe    120 <main+0x120>
    char* cpuZeros = "";
  6a:	c7 45 80 75 08 00 00 	movl   $0x875,-0x80(%ebp)
  71:	eb 10                	jmp    83 <main+0x83>
      zeros = "0";
  73:	c7 45 84 15 08 00 00 	movl   $0x815,-0x7c(%ebp)
  7a:	eb e0                	jmp    5c <main+0x5c>
      cpuZeros = "00";
  7c:	c7 45 80 14 08 00 00 	movl   $0x814,-0x80(%ebp)
      cpuZeros = "0";
    }

    printf(
  83:	83 ec 04             	sub    $0x4,%esp
  86:	ff 75 c4             	pushl  -0x3c(%ebp)
  89:	8d 4d a4             	lea    -0x5c(%ebp),%ecx
  8c:	51                   	push   %ecx
  8d:	50                   	push   %eax
  8e:	ff 75 80             	pushl  -0x80(%ebp)
  91:	52                   	push   %edx
  92:	56                   	push   %esi
  93:	ff 75 84             	pushl  -0x7c(%ebp)
  96:	57                   	push   %edi
  97:	ff 75 98             	pushl  -0x68(%ebp)
  9a:	ff 75 94             	pushl  -0x6c(%ebp)
  9d:	ff 75 90             	pushl  -0x70(%ebp)
  a0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  a3:	50                   	push   %eax
  a4:	ff 75 8c             	pushl  -0x74(%ebp)
  a7:	68 48 08 00 00       	push   $0x848
  ac:	6a 01                	push   $0x1
  ae:	e8 a3 04 00 00       	call   556 <printf>
  for(i = 0; i<procsNumber; i++){
  b3:	83 c3 01             	add    $0x1,%ebx
  b6:	83 c4 40             	add    $0x40,%esp
  b9:	3b 9d 78 ff ff ff    	cmp    -0x88(%ebp),%ebx
  bf:	7d 6b                	jge    12c <main+0x12c>
    struct uproc currentProc = proc[i];
  c1:	6b f3 5c             	imul   $0x5c,%ebx,%esi
  c4:	03 b5 7c ff ff ff    	add    -0x84(%ebp),%esi
  ca:	8d 7d 8c             	lea    -0x74(%ebp),%edi
  cd:	b9 17 00 00 00       	mov    $0x17,%ecx
  d2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    uint elapsedTicks = currentProc.elapsed_ticks;
  d4:	8b 75 9c             	mov    -0x64(%ebp),%esi
    uint elapsedTicksSecond = elapsedTicks/1000;
  d7:	b9 d3 4d 62 10       	mov    $0x10624dd3,%ecx
  dc:	89 f0                	mov    %esi,%eax
  de:	f7 e1                	mul    %ecx
  e0:	89 d7                	mov    %edx,%edi
  e2:	c1 ef 06             	shr    $0x6,%edi
    uint elapsedTicksMs = elapsedTicks%1000;
  e5:	69 c7 e8 03 00 00    	imul   $0x3e8,%edi,%eax
  eb:	29 c6                	sub    %eax,%esi
    uint cpuTotalTicksSecond = cpuTotalTicks/1000;
  ed:	89 c8                	mov    %ecx,%eax
  ef:	f7 65 a0             	mull   -0x60(%ebp)
  f2:	c1 ea 06             	shr    $0x6,%edx
    uint cpuTotalTicksMs = cpuTotalTicks % 1000;
  f5:	69 c2 e8 03 00 00    	imul   $0x3e8,%edx,%eax
  fb:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  fe:	29 c1                	sub    %eax,%ecx
 100:	89 c8                	mov    %ecx,%eax
    if (elapsedTicksMs < 10) {
 102:	83 fe 09             	cmp    $0x9,%esi
 105:	0f 86 4a ff ff ff    	jbe    55 <main+0x55>
    } else if (elapsedTicksMs < 100) {
 10b:	83 fe 63             	cmp    $0x63,%esi
 10e:	0f 86 5f ff ff ff    	jbe    73 <main+0x73>
    char* zeros = "";
 114:	c7 45 84 75 08 00 00 	movl   $0x875,-0x7c(%ebp)
 11b:	e9 3c ff ff ff       	jmp    5c <main+0x5c>
      cpuZeros = "0";
 120:	c7 45 80 15 08 00 00 	movl   $0x815,-0x80(%ebp)
 127:	e9 57 ff ff ff       	jmp    83 <main+0x83>
      currentProc.state,
      currentProc.size
    );
  }

  free(proc);
 12c:	83 ec 0c             	sub    $0xc,%esp
 12f:	ff b5 7c ff ff ff    	pushl  -0x84(%ebp)
 135:	e8 89 05 00 00       	call   6c3 <free>
  exit();
 13a:	e8 96 02 00 00       	call   3d5 <exit>

0000013f <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 13f:	f3 0f 1e fb          	endbr32 
 143:	55                   	push   %ebp
 144:	89 e5                	mov    %esp,%ebp
 146:	56                   	push   %esi
 147:	53                   	push   %ebx
 148:	8b 75 08             	mov    0x8(%ebp),%esi
 14b:	8b 55 0c             	mov    0xc(%ebp),%edx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 14e:	89 f0                	mov    %esi,%eax
 150:	89 d1                	mov    %edx,%ecx
 152:	83 c2 01             	add    $0x1,%edx
 155:	89 c3                	mov    %eax,%ebx
 157:	83 c0 01             	add    $0x1,%eax
 15a:	0f b6 09             	movzbl (%ecx),%ecx
 15d:	88 0b                	mov    %cl,(%ebx)
 15f:	84 c9                	test   %cl,%cl
 161:	75 ed                	jne    150 <strcpy+0x11>
    ;
  return os;
}
 163:	89 f0                	mov    %esi,%eax
 165:	5b                   	pop    %ebx
 166:	5e                   	pop    %esi
 167:	5d                   	pop    %ebp
 168:	c3                   	ret    

00000169 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 169:	f3 0f 1e fb          	endbr32 
 16d:	55                   	push   %ebp
 16e:	89 e5                	mov    %esp,%ebp
 170:	8b 4d 08             	mov    0x8(%ebp),%ecx
 173:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
 176:	0f b6 01             	movzbl (%ecx),%eax
 179:	84 c0                	test   %al,%al
 17b:	74 0c                	je     189 <strcmp+0x20>
 17d:	3a 02                	cmp    (%edx),%al
 17f:	75 08                	jne    189 <strcmp+0x20>
    p++, q++;
 181:	83 c1 01             	add    $0x1,%ecx
 184:	83 c2 01             	add    $0x1,%edx
 187:	eb ed                	jmp    176 <strcmp+0xd>
  return (uchar)*p - (uchar)*q;
 189:	0f b6 c0             	movzbl %al,%eax
 18c:	0f b6 12             	movzbl (%edx),%edx
 18f:	29 d0                	sub    %edx,%eax
}
 191:	5d                   	pop    %ebp
 192:	c3                   	ret    

00000193 <strlen>:

uint
strlen(char *s)
{
 193:	f3 0f 1e fb          	endbr32 
 197:	55                   	push   %ebp
 198:	89 e5                	mov    %esp,%ebp
 19a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 19d:	b8 00 00 00 00       	mov    $0x0,%eax
 1a2:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
 1a6:	74 05                	je     1ad <strlen+0x1a>
 1a8:	83 c0 01             	add    $0x1,%eax
 1ab:	eb f5                	jmp    1a2 <strlen+0xf>
    ;
  return n;
}
 1ad:	5d                   	pop    %ebp
 1ae:	c3                   	ret    

000001af <memset>:

void*
memset(void *dst, int c, uint n)
{
 1af:	f3 0f 1e fb          	endbr32 
 1b3:	55                   	push   %ebp
 1b4:	89 e5                	mov    %esp,%ebp
 1b6:	57                   	push   %edi
 1b7:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 1ba:	89 d7                	mov    %edx,%edi
 1bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
 1bf:	8b 45 0c             	mov    0xc(%ebp),%eax
 1c2:	fc                   	cld    
 1c3:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 1c5:	89 d0                	mov    %edx,%eax
 1c7:	5f                   	pop    %edi
 1c8:	5d                   	pop    %ebp
 1c9:	c3                   	ret    

000001ca <strchr>:

char*
strchr(const char *s, char c)
{
 1ca:	f3 0f 1e fb          	endbr32 
 1ce:	55                   	push   %ebp
 1cf:	89 e5                	mov    %esp,%ebp
 1d1:	8b 45 08             	mov    0x8(%ebp),%eax
 1d4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 1d8:	0f b6 10             	movzbl (%eax),%edx
 1db:	84 d2                	test   %dl,%dl
 1dd:	74 09                	je     1e8 <strchr+0x1e>
    if(*s == c)
 1df:	38 ca                	cmp    %cl,%dl
 1e1:	74 0a                	je     1ed <strchr+0x23>
  for(; *s; s++)
 1e3:	83 c0 01             	add    $0x1,%eax
 1e6:	eb f0                	jmp    1d8 <strchr+0xe>
      return (char*)s;
  return 0;
 1e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
 1ed:	5d                   	pop    %ebp
 1ee:	c3                   	ret    

000001ef <gets>:

char*
gets(char *buf, int max)
{
 1ef:	f3 0f 1e fb          	endbr32 
 1f3:	55                   	push   %ebp
 1f4:	89 e5                	mov    %esp,%ebp
 1f6:	57                   	push   %edi
 1f7:	56                   	push   %esi
 1f8:	53                   	push   %ebx
 1f9:	83 ec 1c             	sub    $0x1c,%esp
 1fc:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ff:	bb 00 00 00 00       	mov    $0x0,%ebx
 204:	89 de                	mov    %ebx,%esi
 206:	83 c3 01             	add    $0x1,%ebx
 209:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
 20c:	7d 2e                	jge    23c <gets+0x4d>
    cc = read(0, &c, 1);
 20e:	83 ec 04             	sub    $0x4,%esp
 211:	6a 01                	push   $0x1
 213:	8d 45 e7             	lea    -0x19(%ebp),%eax
 216:	50                   	push   %eax
 217:	6a 00                	push   $0x0
 219:	e8 cf 01 00 00       	call   3ed <read>
    if(cc < 1)
 21e:	83 c4 10             	add    $0x10,%esp
 221:	85 c0                	test   %eax,%eax
 223:	7e 17                	jle    23c <gets+0x4d>
      break;
    buf[i++] = c;
 225:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 229:	88 04 37             	mov    %al,(%edi,%esi,1)
    if(c == '\n' || c == '\r')
 22c:	3c 0a                	cmp    $0xa,%al
 22e:	0f 94 c2             	sete   %dl
 231:	3c 0d                	cmp    $0xd,%al
 233:	0f 94 c0             	sete   %al
 236:	08 c2                	or     %al,%dl
 238:	74 ca                	je     204 <gets+0x15>
    buf[i++] = c;
 23a:	89 de                	mov    %ebx,%esi
      break;
  }
  buf[i] = '\0';
 23c:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
  return buf;
}
 240:	89 f8                	mov    %edi,%eax
 242:	8d 65 f4             	lea    -0xc(%ebp),%esp
 245:	5b                   	pop    %ebx
 246:	5e                   	pop    %esi
 247:	5f                   	pop    %edi
 248:	5d                   	pop    %ebp
 249:	c3                   	ret    

0000024a <stat>:

int
stat(char *n, struct stat *st)
{
 24a:	f3 0f 1e fb          	endbr32 
 24e:	55                   	push   %ebp
 24f:	89 e5                	mov    %esp,%ebp
 251:	56                   	push   %esi
 252:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 253:	83 ec 08             	sub    $0x8,%esp
 256:	6a 00                	push   $0x0
 258:	ff 75 08             	pushl  0x8(%ebp)
 25b:	e8 b5 01 00 00       	call   415 <open>
  if(fd < 0)
 260:	83 c4 10             	add    $0x10,%esp
 263:	85 c0                	test   %eax,%eax
 265:	78 24                	js     28b <stat+0x41>
 267:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 269:	83 ec 08             	sub    $0x8,%esp
 26c:	ff 75 0c             	pushl  0xc(%ebp)
 26f:	50                   	push   %eax
 270:	e8 b8 01 00 00       	call   42d <fstat>
 275:	89 c6                	mov    %eax,%esi
  close(fd);
 277:	89 1c 24             	mov    %ebx,(%esp)
 27a:	e8 7e 01 00 00       	call   3fd <close>
  return r;
 27f:	83 c4 10             	add    $0x10,%esp
}
 282:	89 f0                	mov    %esi,%eax
 284:	8d 65 f8             	lea    -0x8(%ebp),%esp
 287:	5b                   	pop    %ebx
 288:	5e                   	pop    %esi
 289:	5d                   	pop    %ebp
 28a:	c3                   	ret    
    return -1;
 28b:	be ff ff ff ff       	mov    $0xffffffff,%esi
 290:	eb f0                	jmp    282 <stat+0x38>

00000292 <atoi>:

#ifdef PDX_XV6
int
atoi(const char *s)
{
 292:	f3 0f 1e fb          	endbr32 
 296:	55                   	push   %ebp
 297:	89 e5                	mov    %esp,%ebp
 299:	57                   	push   %edi
 29a:	56                   	push   %esi
 29b:	53                   	push   %ebx
 29c:	8b 55 08             	mov    0x8(%ebp),%edx
  int n, sign;

  n = 0;
  while (*s == ' ') s++;
 29f:	0f b6 02             	movzbl (%edx),%eax
 2a2:	3c 20                	cmp    $0x20,%al
 2a4:	75 05                	jne    2ab <atoi+0x19>
 2a6:	83 c2 01             	add    $0x1,%edx
 2a9:	eb f4                	jmp    29f <atoi+0xd>
  sign = (*s == '-') ? -1 : 1;
 2ab:	3c 2d                	cmp    $0x2d,%al
 2ad:	74 1d                	je     2cc <atoi+0x3a>
 2af:	bf 01 00 00 00       	mov    $0x1,%edi
  if (*s == '+'  || *s == '-')
 2b4:	3c 2b                	cmp    $0x2b,%al
 2b6:	0f 94 c1             	sete   %cl
 2b9:	3c 2d                	cmp    $0x2d,%al
 2bb:	0f 94 c0             	sete   %al
 2be:	08 c1                	or     %al,%cl
 2c0:	74 03                	je     2c5 <atoi+0x33>
    s++;
 2c2:	83 c2 01             	add    $0x1,%edx
  sign = (*s == '-') ? -1 : 1;
 2c5:	b8 00 00 00 00       	mov    $0x0,%eax
 2ca:	eb 17                	jmp    2e3 <atoi+0x51>
 2cc:	bf ff ff ff ff       	mov    $0xffffffff,%edi
 2d1:	eb e1                	jmp    2b4 <atoi+0x22>
  while('0' <= *s && *s <= '9')
    n = n*10 + *s++ - '0';
 2d3:	8d 34 80             	lea    (%eax,%eax,4),%esi
 2d6:	8d 1c 36             	lea    (%esi,%esi,1),%ebx
 2d9:	83 c2 01             	add    $0x1,%edx
 2dc:	0f be c9             	movsbl %cl,%ecx
 2df:	8d 44 19 d0          	lea    -0x30(%ecx,%ebx,1),%eax
  while('0' <= *s && *s <= '9')
 2e3:	0f b6 0a             	movzbl (%edx),%ecx
 2e6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
 2e9:	80 fb 09             	cmp    $0x9,%bl
 2ec:	76 e5                	jbe    2d3 <atoi+0x41>
  return sign*n;
 2ee:	0f af c7             	imul   %edi,%eax
}
 2f1:	5b                   	pop    %ebx
 2f2:	5e                   	pop    %esi
 2f3:	5f                   	pop    %edi
 2f4:	5d                   	pop    %ebp
 2f5:	c3                   	ret    

000002f6 <atoo>:

int
atoo(const char *s)
{
 2f6:	f3 0f 1e fb          	endbr32 
 2fa:	55                   	push   %ebp
 2fb:	89 e5                	mov    %esp,%ebp
 2fd:	57                   	push   %edi
 2fe:	56                   	push   %esi
 2ff:	53                   	push   %ebx
 300:	8b 55 08             	mov    0x8(%ebp),%edx
  int n, sign;

  n = 0;
  while (*s == ' ') s++;
 303:	0f b6 0a             	movzbl (%edx),%ecx
 306:	80 f9 20             	cmp    $0x20,%cl
 309:	75 05                	jne    310 <atoo+0x1a>
 30b:	83 c2 01             	add    $0x1,%edx
 30e:	eb f3                	jmp    303 <atoo+0xd>
  sign = (*s == '-') ? -1 : 1;
 310:	80 f9 2d             	cmp    $0x2d,%cl
 313:	74 23                	je     338 <atoo+0x42>
 315:	bf 01 00 00 00       	mov    $0x1,%edi
  if (*s == '+'  || *s == '-')
 31a:	80 f9 2b             	cmp    $0x2b,%cl
 31d:	0f 94 c0             	sete   %al
 320:	89 c6                	mov    %eax,%esi
 322:	80 f9 2d             	cmp    $0x2d,%cl
 325:	0f 94 c0             	sete   %al
 328:	89 f3                	mov    %esi,%ebx
 32a:	08 c3                	or     %al,%bl
 32c:	74 03                	je     331 <atoo+0x3b>
    s++;
 32e:	83 c2 01             	add    $0x1,%edx
  sign = (*s == '-') ? -1 : 1;
 331:	b8 00 00 00 00       	mov    $0x0,%eax
 336:	eb 11                	jmp    349 <atoo+0x53>
 338:	bf ff ff ff ff       	mov    $0xffffffff,%edi
 33d:	eb db                	jmp    31a <atoo+0x24>
  while('0' <= *s && *s <= '7')
    n = n*8 + *s++ - '0';
 33f:	83 c2 01             	add    $0x1,%edx
 342:	0f be c9             	movsbl %cl,%ecx
 345:	8d 44 c1 d0          	lea    -0x30(%ecx,%eax,8),%eax
  while('0' <= *s && *s <= '7')
 349:	0f b6 0a             	movzbl (%edx),%ecx
 34c:	8d 59 d0             	lea    -0x30(%ecx),%ebx
 34f:	80 fb 07             	cmp    $0x7,%bl
 352:	76 eb                	jbe    33f <atoo+0x49>
  return sign*n;
 354:	0f af c7             	imul   %edi,%eax
}
 357:	5b                   	pop    %ebx
 358:	5e                   	pop    %esi
 359:	5f                   	pop    %edi
 35a:	5d                   	pop    %ebp
 35b:	c3                   	ret    

0000035c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
 35c:	f3 0f 1e fb          	endbr32 
 360:	55                   	push   %ebp
 361:	89 e5                	mov    %esp,%ebp
 363:	53                   	push   %ebx
 364:	8b 55 08             	mov    0x8(%ebp),%edx
 367:	8b 4d 0c             	mov    0xc(%ebp),%ecx
 36a:	8b 45 10             	mov    0x10(%ebp),%eax
    while(n > 0 && *p && *p == *q)
 36d:	eb 09                	jmp    378 <strncmp+0x1c>
      n--, p++, q++;
 36f:	83 e8 01             	sub    $0x1,%eax
 372:	83 c2 01             	add    $0x1,%edx
 375:	83 c1 01             	add    $0x1,%ecx
    while(n > 0 && *p && *p == *q)
 378:	85 c0                	test   %eax,%eax
 37a:	74 0b                	je     387 <strncmp+0x2b>
 37c:	0f b6 1a             	movzbl (%edx),%ebx
 37f:	84 db                	test   %bl,%bl
 381:	74 04                	je     387 <strncmp+0x2b>
 383:	3a 19                	cmp    (%ecx),%bl
 385:	74 e8                	je     36f <strncmp+0x13>
    if(n == 0)
 387:	85 c0                	test   %eax,%eax
 389:	74 0b                	je     396 <strncmp+0x3a>
      return 0;
    return (uchar)*p - (uchar)*q;
 38b:	0f b6 02             	movzbl (%edx),%eax
 38e:	0f b6 11             	movzbl (%ecx),%edx
 391:	29 d0                	sub    %edx,%eax
}
 393:	5b                   	pop    %ebx
 394:	5d                   	pop    %ebp
 395:	c3                   	ret    
      return 0;
 396:	b8 00 00 00 00       	mov    $0x0,%eax
 39b:	eb f6                	jmp    393 <strncmp+0x37>

0000039d <memmove>:
}
#endif // PDX_XV6

void*
memmove(void *vdst, void *vsrc, int n)
{
 39d:	f3 0f 1e fb          	endbr32 
 3a1:	55                   	push   %ebp
 3a2:	89 e5                	mov    %esp,%ebp
 3a4:	56                   	push   %esi
 3a5:	53                   	push   %ebx
 3a6:	8b 75 08             	mov    0x8(%ebp),%esi
 3a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
 3ac:	8b 45 10             	mov    0x10(%ebp),%eax
  char *dst, *src;

  dst = vdst;
 3af:	89 f2                	mov    %esi,%edx
  src = vsrc;
  while(n-- > 0)
 3b1:	8d 58 ff             	lea    -0x1(%eax),%ebx
 3b4:	85 c0                	test   %eax,%eax
 3b6:	7e 0f                	jle    3c7 <memmove+0x2a>
    *dst++ = *src++;
 3b8:	0f b6 01             	movzbl (%ecx),%eax
 3bb:	88 02                	mov    %al,(%edx)
 3bd:	8d 49 01             	lea    0x1(%ecx),%ecx
 3c0:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
 3c3:	89 d8                	mov    %ebx,%eax
 3c5:	eb ea                	jmp    3b1 <memmove+0x14>
  return vdst;
}
 3c7:	89 f0                	mov    %esi,%eax
 3c9:	5b                   	pop    %ebx
 3ca:	5e                   	pop    %esi
 3cb:	5d                   	pop    %ebp
 3cc:	c3                   	ret    

000003cd <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 3cd:	b8 01 00 00 00       	mov    $0x1,%eax
 3d2:	cd 40                	int    $0x40
 3d4:	c3                   	ret    

000003d5 <exit>:
SYSCALL(exit)
 3d5:	b8 02 00 00 00       	mov    $0x2,%eax
 3da:	cd 40                	int    $0x40
 3dc:	c3                   	ret    

000003dd <wait>:
SYSCALL(wait)
 3dd:	b8 03 00 00 00       	mov    $0x3,%eax
 3e2:	cd 40                	int    $0x40
 3e4:	c3                   	ret    

000003e5 <pipe>:
SYSCALL(pipe)
 3e5:	b8 04 00 00 00       	mov    $0x4,%eax
 3ea:	cd 40                	int    $0x40
 3ec:	c3                   	ret    

000003ed <read>:
SYSCALL(read)
 3ed:	b8 05 00 00 00       	mov    $0x5,%eax
 3f2:	cd 40                	int    $0x40
 3f4:	c3                   	ret    

000003f5 <write>:
SYSCALL(write)
 3f5:	b8 10 00 00 00       	mov    $0x10,%eax
 3fa:	cd 40                	int    $0x40
 3fc:	c3                   	ret    

000003fd <close>:
SYSCALL(close)
 3fd:	b8 15 00 00 00       	mov    $0x15,%eax
 402:	cd 40                	int    $0x40
 404:	c3                   	ret    

00000405 <kill>:
SYSCALL(kill)
 405:	b8 06 00 00 00       	mov    $0x6,%eax
 40a:	cd 40                	int    $0x40
 40c:	c3                   	ret    

0000040d <exec>:
SYSCALL(exec)
 40d:	b8 07 00 00 00       	mov    $0x7,%eax
 412:	cd 40                	int    $0x40
 414:	c3                   	ret    

00000415 <open>:
SYSCALL(open)
 415:	b8 0f 00 00 00       	mov    $0xf,%eax
 41a:	cd 40                	int    $0x40
 41c:	c3                   	ret    

0000041d <mknod>:
SYSCALL(mknod)
 41d:	b8 11 00 00 00       	mov    $0x11,%eax
 422:	cd 40                	int    $0x40
 424:	c3                   	ret    

00000425 <unlink>:
SYSCALL(unlink)
 425:	b8 12 00 00 00       	mov    $0x12,%eax
 42a:	cd 40                	int    $0x40
 42c:	c3                   	ret    

0000042d <fstat>:
SYSCALL(fstat)
 42d:	b8 08 00 00 00       	mov    $0x8,%eax
 432:	cd 40                	int    $0x40
 434:	c3                   	ret    

00000435 <link>:
SYSCALL(link)
 435:	b8 13 00 00 00       	mov    $0x13,%eax
 43a:	cd 40                	int    $0x40
 43c:	c3                   	ret    

0000043d <mkdir>:
SYSCALL(mkdir)
 43d:	b8 14 00 00 00       	mov    $0x14,%eax
 442:	cd 40                	int    $0x40
 444:	c3                   	ret    

00000445 <chdir>:
SYSCALL(chdir)
 445:	b8 09 00 00 00       	mov    $0x9,%eax
 44a:	cd 40                	int    $0x40
 44c:	c3                   	ret    

0000044d <dup>:
SYSCALL(dup)
 44d:	b8 0a 00 00 00       	mov    $0xa,%eax
 452:	cd 40                	int    $0x40
 454:	c3                   	ret    

00000455 <getpid>:
SYSCALL(getpid)
 455:	b8 0b 00 00 00       	mov    $0xb,%eax
 45a:	cd 40                	int    $0x40
 45c:	c3                   	ret    

0000045d <sbrk>:
SYSCALL(sbrk)
 45d:	b8 0c 00 00 00       	mov    $0xc,%eax
 462:	cd 40                	int    $0x40
 464:	c3                   	ret    

00000465 <sleep>:
SYSCALL(sleep)
 465:	b8 0d 00 00 00       	mov    $0xd,%eax
 46a:	cd 40                	int    $0x40
 46c:	c3                   	ret    

0000046d <uptime>:
SYSCALL(uptime)
 46d:	b8 0e 00 00 00       	mov    $0xe,%eax
 472:	cd 40                	int    $0x40
 474:	c3                   	ret    

00000475 <halt>:
SYSCALL(halt)
 475:	b8 16 00 00 00       	mov    $0x16,%eax
 47a:	cd 40                	int    $0x40
 47c:	c3                   	ret    

0000047d <date>:
SYSCALL(date)
 47d:	b8 17 00 00 00       	mov    $0x17,%eax
 482:	cd 40                	int    $0x40
 484:	c3                   	ret    

00000485 <getuid>:
SYSCALL(getuid)
 485:	b8 18 00 00 00       	mov    $0x18,%eax
 48a:	cd 40                	int    $0x40
 48c:	c3                   	ret    

0000048d <getgid>:
SYSCALL(getgid)
 48d:	b8 19 00 00 00       	mov    $0x19,%eax
 492:	cd 40                	int    $0x40
 494:	c3                   	ret    

00000495 <getppid>:
SYSCALL(getppid)
 495:	b8 1a 00 00 00       	mov    $0x1a,%eax
 49a:	cd 40                	int    $0x40
 49c:	c3                   	ret    

0000049d <setuid>:
SYSCALL(setuid)
 49d:	b8 1b 00 00 00       	mov    $0x1b,%eax
 4a2:	cd 40                	int    $0x40
 4a4:	c3                   	ret    

000004a5 <setgid>:
SYSCALL(setgid)
 4a5:	b8 1c 00 00 00       	mov    $0x1c,%eax
 4aa:	cd 40                	int    $0x40
 4ac:	c3                   	ret    

000004ad <getprocs>:
 4ad:	b8 1d 00 00 00       	mov    $0x1d,%eax
 4b2:	cd 40                	int    $0x40
 4b4:	c3                   	ret    

000004b5 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 4b5:	55                   	push   %ebp
 4b6:	89 e5                	mov    %esp,%ebp
 4b8:	83 ec 1c             	sub    $0x1c,%esp
 4bb:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 4be:	6a 01                	push   $0x1
 4c0:	8d 55 f4             	lea    -0xc(%ebp),%edx
 4c3:	52                   	push   %edx
 4c4:	50                   	push   %eax
 4c5:	e8 2b ff ff ff       	call   3f5 <write>
}
 4ca:	83 c4 10             	add    $0x10,%esp
 4cd:	c9                   	leave  
 4ce:	c3                   	ret    

000004cf <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4cf:	55                   	push   %ebp
 4d0:	89 e5                	mov    %esp,%ebp
 4d2:	57                   	push   %edi
 4d3:	56                   	push   %esi
 4d4:	53                   	push   %ebx
 4d5:	83 ec 2c             	sub    $0x2c,%esp
 4d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
 4db:	89 d6                	mov    %edx,%esi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4dd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 4e1:	0f 95 c2             	setne  %dl
 4e4:	89 f0                	mov    %esi,%eax
 4e6:	c1 e8 1f             	shr    $0x1f,%eax
 4e9:	84 c2                	test   %al,%dl
 4eb:	74 42                	je     52f <printint+0x60>
    neg = 1;
    x = -xx;
 4ed:	f7 de                	neg    %esi
    neg = 1;
 4ef:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 4f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  do{
    buf[i++] = digits[x % base];
 4fb:	89 f0                	mov    %esi,%eax
 4fd:	ba 00 00 00 00       	mov    $0x0,%edx
 502:	f7 f1                	div    %ecx
 504:	89 df                	mov    %ebx,%edi
 506:	83 c3 01             	add    $0x1,%ebx
 509:	0f b6 92 78 08 00 00 	movzbl 0x878(%edx),%edx
 510:	88 54 3d d8          	mov    %dl,-0x28(%ebp,%edi,1)
  }while((x /= base) != 0);
 514:	89 f2                	mov    %esi,%edx
 516:	89 c6                	mov    %eax,%esi
 518:	39 d1                	cmp    %edx,%ecx
 51a:	76 df                	jbe    4fb <printint+0x2c>
  if(neg)
 51c:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 520:	74 2f                	je     551 <printint+0x82>
    buf[i++] = '-';
 522:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
 527:	8d 5f 02             	lea    0x2(%edi),%ebx
 52a:	8b 75 d0             	mov    -0x30(%ebp),%esi
 52d:	eb 15                	jmp    544 <printint+0x75>
  neg = 0;
 52f:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 536:	eb be                	jmp    4f6 <printint+0x27>

  while(--i >= 0)
    putc(fd, buf[i]);
 538:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 53d:	89 f0                	mov    %esi,%eax
 53f:	e8 71 ff ff ff       	call   4b5 <putc>
  while(--i >= 0)
 544:	83 eb 01             	sub    $0x1,%ebx
 547:	79 ef                	jns    538 <printint+0x69>
}
 549:	83 c4 2c             	add    $0x2c,%esp
 54c:	5b                   	pop    %ebx
 54d:	5e                   	pop    %esi
 54e:	5f                   	pop    %edi
 54f:	5d                   	pop    %ebp
 550:	c3                   	ret    
 551:	8b 75 d0             	mov    -0x30(%ebp),%esi
 554:	eb ee                	jmp    544 <printint+0x75>

00000556 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 556:	f3 0f 1e fb          	endbr32 
 55a:	55                   	push   %ebp
 55b:	89 e5                	mov    %esp,%ebp
 55d:	57                   	push   %edi
 55e:	56                   	push   %esi
 55f:	53                   	push   %ebx
 560:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 563:	8d 45 10             	lea    0x10(%ebp),%eax
 566:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 569:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 56e:	bb 00 00 00 00       	mov    $0x0,%ebx
 573:	eb 14                	jmp    589 <printf+0x33>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 575:	89 fa                	mov    %edi,%edx
 577:	8b 45 08             	mov    0x8(%ebp),%eax
 57a:	e8 36 ff ff ff       	call   4b5 <putc>
 57f:	eb 05                	jmp    586 <printf+0x30>
      }
    } else if(state == '%'){
 581:	83 fe 25             	cmp    $0x25,%esi
 584:	74 25                	je     5ab <printf+0x55>
  for(i = 0; fmt[i]; i++){
 586:	83 c3 01             	add    $0x1,%ebx
 589:	8b 45 0c             	mov    0xc(%ebp),%eax
 58c:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 590:	84 c0                	test   %al,%al
 592:	0f 84 23 01 00 00    	je     6bb <printf+0x165>
    c = fmt[i] & 0xff;
 598:	0f be f8             	movsbl %al,%edi
 59b:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 59e:	85 f6                	test   %esi,%esi
 5a0:	75 df                	jne    581 <printf+0x2b>
      if(c == '%'){
 5a2:	83 f8 25             	cmp    $0x25,%eax
 5a5:	75 ce                	jne    575 <printf+0x1f>
        state = '%';
 5a7:	89 c6                	mov    %eax,%esi
 5a9:	eb db                	jmp    586 <printf+0x30>
      if(c == 'd'){
 5ab:	83 f8 64             	cmp    $0x64,%eax
 5ae:	74 49                	je     5f9 <printf+0xa3>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 5b0:	83 f8 78             	cmp    $0x78,%eax
 5b3:	0f 94 c1             	sete   %cl
 5b6:	83 f8 70             	cmp    $0x70,%eax
 5b9:	0f 94 c2             	sete   %dl
 5bc:	08 d1                	or     %dl,%cl
 5be:	75 63                	jne    623 <printf+0xcd>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 5c0:	83 f8 73             	cmp    $0x73,%eax
 5c3:	0f 84 84 00 00 00    	je     64d <printf+0xf7>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5c9:	83 f8 63             	cmp    $0x63,%eax
 5cc:	0f 84 b7 00 00 00    	je     689 <printf+0x133>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 5d2:	83 f8 25             	cmp    $0x25,%eax
 5d5:	0f 84 cc 00 00 00    	je     6a7 <printf+0x151>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5db:	ba 25 00 00 00       	mov    $0x25,%edx
 5e0:	8b 45 08             	mov    0x8(%ebp),%eax
 5e3:	e8 cd fe ff ff       	call   4b5 <putc>
        putc(fd, c);
 5e8:	89 fa                	mov    %edi,%edx
 5ea:	8b 45 08             	mov    0x8(%ebp),%eax
 5ed:	e8 c3 fe ff ff       	call   4b5 <putc>
      }
      state = 0;
 5f2:	be 00 00 00 00       	mov    $0x0,%esi
 5f7:	eb 8d                	jmp    586 <printf+0x30>
        printint(fd, *ap, 10, 1);
 5f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 5fc:	8b 17                	mov    (%edi),%edx
 5fe:	83 ec 0c             	sub    $0xc,%esp
 601:	6a 01                	push   $0x1
 603:	b9 0a 00 00 00       	mov    $0xa,%ecx
 608:	8b 45 08             	mov    0x8(%ebp),%eax
 60b:	e8 bf fe ff ff       	call   4cf <printint>
        ap++;
 610:	83 c7 04             	add    $0x4,%edi
 613:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 616:	83 c4 10             	add    $0x10,%esp
      state = 0;
 619:	be 00 00 00 00       	mov    $0x0,%esi
 61e:	e9 63 ff ff ff       	jmp    586 <printf+0x30>
        printint(fd, *ap, 16, 0);
 623:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 626:	8b 17                	mov    (%edi),%edx
 628:	83 ec 0c             	sub    $0xc,%esp
 62b:	6a 00                	push   $0x0
 62d:	b9 10 00 00 00       	mov    $0x10,%ecx
 632:	8b 45 08             	mov    0x8(%ebp),%eax
 635:	e8 95 fe ff ff       	call   4cf <printint>
        ap++;
 63a:	83 c7 04             	add    $0x4,%edi
 63d:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 640:	83 c4 10             	add    $0x10,%esp
      state = 0;
 643:	be 00 00 00 00       	mov    $0x0,%esi
 648:	e9 39 ff ff ff       	jmp    586 <printf+0x30>
        s = (char*)*ap;
 64d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 650:	8b 30                	mov    (%eax),%esi
        ap++;
 652:	83 c0 04             	add    $0x4,%eax
 655:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 658:	85 f6                	test   %esi,%esi
 65a:	75 28                	jne    684 <printf+0x12e>
          s = "(null)";
 65c:	be 6f 08 00 00       	mov    $0x86f,%esi
 661:	8b 7d 08             	mov    0x8(%ebp),%edi
 664:	eb 0d                	jmp    673 <printf+0x11d>
          putc(fd, *s);
 666:	0f be d2             	movsbl %dl,%edx
 669:	89 f8                	mov    %edi,%eax
 66b:	e8 45 fe ff ff       	call   4b5 <putc>
          s++;
 670:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 673:	0f b6 16             	movzbl (%esi),%edx
 676:	84 d2                	test   %dl,%dl
 678:	75 ec                	jne    666 <printf+0x110>
      state = 0;
 67a:	be 00 00 00 00       	mov    $0x0,%esi
 67f:	e9 02 ff ff ff       	jmp    586 <printf+0x30>
 684:	8b 7d 08             	mov    0x8(%ebp),%edi
 687:	eb ea                	jmp    673 <printf+0x11d>
        putc(fd, *ap);
 689:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 68c:	0f be 17             	movsbl (%edi),%edx
 68f:	8b 45 08             	mov    0x8(%ebp),%eax
 692:	e8 1e fe ff ff       	call   4b5 <putc>
        ap++;
 697:	83 c7 04             	add    $0x4,%edi
 69a:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 69d:	be 00 00 00 00       	mov    $0x0,%esi
 6a2:	e9 df fe ff ff       	jmp    586 <printf+0x30>
        putc(fd, c);
 6a7:	89 fa                	mov    %edi,%edx
 6a9:	8b 45 08             	mov    0x8(%ebp),%eax
 6ac:	e8 04 fe ff ff       	call   4b5 <putc>
      state = 0;
 6b1:	be 00 00 00 00       	mov    $0x0,%esi
 6b6:	e9 cb fe ff ff       	jmp    586 <printf+0x30>
    }
  }
}
 6bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
 6be:	5b                   	pop    %ebx
 6bf:	5e                   	pop    %esi
 6c0:	5f                   	pop    %edi
 6c1:	5d                   	pop    %ebp
 6c2:	c3                   	ret    

000006c3 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6c3:	f3 0f 1e fb          	endbr32 
 6c7:	55                   	push   %ebp
 6c8:	89 e5                	mov    %esp,%ebp
 6ca:	57                   	push   %edi
 6cb:	56                   	push   %esi
 6cc:	53                   	push   %ebx
 6cd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6d0:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d3:	a1 80 0b 00 00       	mov    0xb80,%eax
 6d8:	eb 02                	jmp    6dc <free+0x19>
 6da:	89 d0                	mov    %edx,%eax
 6dc:	39 c8                	cmp    %ecx,%eax
 6de:	73 04                	jae    6e4 <free+0x21>
 6e0:	39 08                	cmp    %ecx,(%eax)
 6e2:	77 12                	ja     6f6 <free+0x33>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e4:	8b 10                	mov    (%eax),%edx
 6e6:	39 c2                	cmp    %eax,%edx
 6e8:	77 f0                	ja     6da <free+0x17>
 6ea:	39 c8                	cmp    %ecx,%eax
 6ec:	72 08                	jb     6f6 <free+0x33>
 6ee:	39 ca                	cmp    %ecx,%edx
 6f0:	77 04                	ja     6f6 <free+0x33>
 6f2:	89 d0                	mov    %edx,%eax
 6f4:	eb e6                	jmp    6dc <free+0x19>
      break;
  if(bp + bp->s.size == p->s.ptr){
 6f6:	8b 73 fc             	mov    -0x4(%ebx),%esi
 6f9:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 6fc:	8b 10                	mov    (%eax),%edx
 6fe:	39 d7                	cmp    %edx,%edi
 700:	74 19                	je     71b <free+0x58>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 702:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 705:	8b 50 04             	mov    0x4(%eax),%edx
 708:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 70b:	39 ce                	cmp    %ecx,%esi
 70d:	74 1b                	je     72a <free+0x67>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 70f:	89 08                	mov    %ecx,(%eax)
  freep = p;
 711:	a3 80 0b 00 00       	mov    %eax,0xb80
}
 716:	5b                   	pop    %ebx
 717:	5e                   	pop    %esi
 718:	5f                   	pop    %edi
 719:	5d                   	pop    %ebp
 71a:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 71b:	03 72 04             	add    0x4(%edx),%esi
 71e:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 721:	8b 10                	mov    (%eax),%edx
 723:	8b 12                	mov    (%edx),%edx
 725:	89 53 f8             	mov    %edx,-0x8(%ebx)
 728:	eb db                	jmp    705 <free+0x42>
    p->s.size += bp->s.size;
 72a:	03 53 fc             	add    -0x4(%ebx),%edx
 72d:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 730:	8b 53 f8             	mov    -0x8(%ebx),%edx
 733:	89 10                	mov    %edx,(%eax)
 735:	eb da                	jmp    711 <free+0x4e>

00000737 <morecore>:

static Header*
morecore(uint nu)
{
 737:	55                   	push   %ebp
 738:	89 e5                	mov    %esp,%ebp
 73a:	53                   	push   %ebx
 73b:	83 ec 04             	sub    $0x4,%esp
 73e:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 740:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 745:	77 05                	ja     74c <morecore+0x15>
    nu = 4096;
 747:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 74c:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 753:	83 ec 0c             	sub    $0xc,%esp
 756:	50                   	push   %eax
 757:	e8 01 fd ff ff       	call   45d <sbrk>
  if(p == (char*)-1)
 75c:	83 c4 10             	add    $0x10,%esp
 75f:	83 f8 ff             	cmp    $0xffffffff,%eax
 762:	74 1c                	je     780 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 764:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 767:	83 c0 08             	add    $0x8,%eax
 76a:	83 ec 0c             	sub    $0xc,%esp
 76d:	50                   	push   %eax
 76e:	e8 50 ff ff ff       	call   6c3 <free>
  return freep;
 773:	a1 80 0b 00 00       	mov    0xb80,%eax
 778:	83 c4 10             	add    $0x10,%esp
}
 77b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 77e:	c9                   	leave  
 77f:	c3                   	ret    
    return 0;
 780:	b8 00 00 00 00       	mov    $0x0,%eax
 785:	eb f4                	jmp    77b <morecore+0x44>

00000787 <malloc>:

void*
malloc(uint nbytes)
{
 787:	f3 0f 1e fb          	endbr32 
 78b:	55                   	push   %ebp
 78c:	89 e5                	mov    %esp,%ebp
 78e:	53                   	push   %ebx
 78f:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 792:	8b 45 08             	mov    0x8(%ebp),%eax
 795:	8d 58 07             	lea    0x7(%eax),%ebx
 798:	c1 eb 03             	shr    $0x3,%ebx
 79b:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 79e:	8b 0d 80 0b 00 00    	mov    0xb80,%ecx
 7a4:	85 c9                	test   %ecx,%ecx
 7a6:	74 04                	je     7ac <malloc+0x25>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7a8:	8b 01                	mov    (%ecx),%eax
 7aa:	eb 4b                	jmp    7f7 <malloc+0x70>
    base.s.ptr = freep = prevp = &base;
 7ac:	c7 05 80 0b 00 00 84 	movl   $0xb84,0xb80
 7b3:	0b 00 00 
 7b6:	c7 05 84 0b 00 00 84 	movl   $0xb84,0xb84
 7bd:	0b 00 00 
    base.s.size = 0;
 7c0:	c7 05 88 0b 00 00 00 	movl   $0x0,0xb88
 7c7:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 7ca:	b9 84 0b 00 00       	mov    $0xb84,%ecx
 7cf:	eb d7                	jmp    7a8 <malloc+0x21>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 7d1:	74 1a                	je     7ed <malloc+0x66>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 7d3:	29 da                	sub    %ebx,%edx
 7d5:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 7d8:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 7db:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 7de:	89 0d 80 0b 00 00    	mov    %ecx,0xb80
      return (void*)(p + 1);
 7e4:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7e7:	83 c4 04             	add    $0x4,%esp
 7ea:	5b                   	pop    %ebx
 7eb:	5d                   	pop    %ebp
 7ec:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 7ed:	8b 10                	mov    (%eax),%edx
 7ef:	89 11                	mov    %edx,(%ecx)
 7f1:	eb eb                	jmp    7de <malloc+0x57>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f3:	89 c1                	mov    %eax,%ecx
 7f5:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 7f7:	8b 50 04             	mov    0x4(%eax),%edx
 7fa:	39 da                	cmp    %ebx,%edx
 7fc:	73 d3                	jae    7d1 <malloc+0x4a>
    if(p == freep)
 7fe:	39 05 80 0b 00 00    	cmp    %eax,0xb80
 804:	75 ed                	jne    7f3 <malloc+0x6c>
      if((p = morecore(nunits)) == 0)
 806:	89 d8                	mov    %ebx,%eax
 808:	e8 2a ff ff ff       	call   737 <morecore>
 80d:	85 c0                	test   %eax,%eax
 80f:	75 e2                	jne    7f3 <malloc+0x6c>
 811:	eb d4                	jmp    7e7 <malloc+0x60>
