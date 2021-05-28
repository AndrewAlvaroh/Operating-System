
_time:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#ifdef CS333_P2
#include "types.h"
#include "user.h"

int main(int argc, char *argv[]) {
   0:	f3 0f 1e fb          	endbr32 
   4:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   8:	83 e4 f0             	and    $0xfffffff0,%esp
   b:	ff 71 fc             	pushl  -0x4(%ecx)
   e:	55                   	push   %ebp
   f:	89 e5                	mov    %esp,%ebp
  11:	56                   	push   %esi
  12:	53                   	push   %ebx
  13:	51                   	push   %ecx
  14:	83 ec 0c             	sub    $0xc,%esp
  17:	8b 59 04             	mov    0x4(%ecx),%ebx
  if(argc == 1) {
  1a:	83 39 01             	cmpl   $0x1,(%ecx)
  1d:	74 42                	je     61 <main+0x61>
    printf(1, "(null) ran in 0.00\n");
  } else {
    int start = uptime();
  1f:	e8 e1 03 00 00       	call   405 <uptime>
  24:	89 c6                	mov    %eax,%esi
    int pid = fork();
  26:	e8 3a 03 00 00       	call   365 <fork>

    if (pid > 0) {
  2b:	85 c0                	test   %eax,%eax
  2d:	7f 46                	jg     75 <main+0x75>
      pid = wait();
    } else if (pid == 0) {
  2f:	75 69                	jne    9a <main+0x9a>
      exec(argv[1], argv+1);
  31:	83 ec 08             	sub    $0x8,%esp
  34:	8d 43 04             	lea    0x4(%ebx),%eax
  37:	50                   	push   %eax
  38:	ff 73 04             	pushl  0x4(%ebx)
  3b:	e8 65 03 00 00       	call   3a5 <exec>
      printf(1, "ERROR: Unknown Command\n");
  40:	83 c4 08             	add    $0x8,%esp
  43:	68 c3 07 00 00       	push   $0x7c3
  48:	6a 01                	push   $0x1
  4a:	e8 9f 04 00 00       	call   4ee <printf>
      kill(getppid());
  4f:	e8 d9 03 00 00       	call   42d <getppid>
  54:	89 04 24             	mov    %eax,(%esp)
  57:	e8 41 03 00 00       	call   39d <kill>
      exit();
  5c:	e8 0c 03 00 00       	call   36d <exit>
    printf(1, "(null) ran in 0.00\n");
  61:	83 ec 08             	sub    $0x8,%esp
  64:	68 af 07 00 00       	push   $0x7af
  69:	6a 01                	push   $0x1
  6b:	e8 7e 04 00 00       	call   4ee <printf>
  70:	83 c4 10             	add    $0x10,%esp
  73:	eb 56                	jmp    cb <main+0xcb>
      pid = wait();
  75:	e8 fb 02 00 00       	call   375 <wait>
    } else {
      printf(1, "ERROR: Fork error return -1\n");
    }

    int end = uptime();
  7a:	e8 86 03 00 00       	call   405 <uptime>
    int timelapse = end - start;
  7f:	29 f0                	sub    %esi,%eax
    int seconds = timelapse/1000;
  81:	b9 e8 03 00 00       	mov    $0x3e8,%ecx
  86:	99                   	cltd   
  87:	f7 f9                	idiv   %ecx
    int ms = timelapse%1000;
    char *msZeros = "";

    if (ms < 10) {
  89:	83 fa 09             	cmp    $0x9,%edx
  8c:	7e 20                	jle    ae <main+0xae>
      msZeros = "00";
    } else if (ms < 100) {
  8e:	83 fa 63             	cmp    $0x63,%edx
  91:	7e 3d                	jle    d0 <main+0xd0>
    char *msZeros = "";
  93:	b9 c2 07 00 00       	mov    $0x7c2,%ecx
  98:	eb 19                	jmp    b3 <main+0xb3>
      printf(1, "ERROR: Fork error return -1\n");
  9a:	83 ec 08             	sub    $0x8,%esp
  9d:	68 db 07 00 00       	push   $0x7db
  a2:	6a 01                	push   $0x1
  a4:	e8 45 04 00 00       	call   4ee <printf>
  a9:	83 c4 10             	add    $0x10,%esp
  ac:	eb cc                	jmp    7a <main+0x7a>
      msZeros = "00";
  ae:	b9 ac 07 00 00       	mov    $0x7ac,%ecx
      msZeros = "0";
    }

    printf(
  b3:	83 ec 08             	sub    $0x8,%esp
  b6:	52                   	push   %edx
  b7:	51                   	push   %ecx
  b8:	50                   	push   %eax
  b9:	ff 73 04             	pushl  0x4(%ebx)
  bc:	68 f8 07 00 00       	push   $0x7f8
  c1:	6a 01                	push   $0x1
  c3:	e8 26 04 00 00       	call   4ee <printf>
  c8:	83 c4 20             	add    $0x20,%esp
      msZeros,
      ms
    );
  }

  exit();
  cb:	e8 9d 02 00 00       	call   36d <exit>
      msZeros = "0";
  d0:	b9 ad 07 00 00       	mov    $0x7ad,%ecx
  d5:	eb dc                	jmp    b3 <main+0xb3>

000000d7 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  d7:	f3 0f 1e fb          	endbr32 
  db:	55                   	push   %ebp
  dc:	89 e5                	mov    %esp,%ebp
  de:	56                   	push   %esi
  df:	53                   	push   %ebx
  e0:	8b 75 08             	mov    0x8(%ebp),%esi
  e3:	8b 55 0c             	mov    0xc(%ebp),%edx
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  e6:	89 f0                	mov    %esi,%eax
  e8:	89 d1                	mov    %edx,%ecx
  ea:	83 c2 01             	add    $0x1,%edx
  ed:	89 c3                	mov    %eax,%ebx
  ef:	83 c0 01             	add    $0x1,%eax
  f2:	0f b6 09             	movzbl (%ecx),%ecx
  f5:	88 0b                	mov    %cl,(%ebx)
  f7:	84 c9                	test   %cl,%cl
  f9:	75 ed                	jne    e8 <strcpy+0x11>
    ;
  return os;
}
  fb:	89 f0                	mov    %esi,%eax
  fd:	5b                   	pop    %ebx
  fe:	5e                   	pop    %esi
  ff:	5d                   	pop    %ebp
 100:	c3                   	ret    

00000101 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 101:	f3 0f 1e fb          	endbr32 
 105:	55                   	push   %ebp
 106:	89 e5                	mov    %esp,%ebp
 108:	8b 4d 08             	mov    0x8(%ebp),%ecx
 10b:	8b 55 0c             	mov    0xc(%ebp),%edx
  while(*p && *p == *q)
 10e:	0f b6 01             	movzbl (%ecx),%eax
 111:	84 c0                	test   %al,%al
 113:	74 0c                	je     121 <strcmp+0x20>
 115:	3a 02                	cmp    (%edx),%al
 117:	75 08                	jne    121 <strcmp+0x20>
    p++, q++;
 119:	83 c1 01             	add    $0x1,%ecx
 11c:	83 c2 01             	add    $0x1,%edx
 11f:	eb ed                	jmp    10e <strcmp+0xd>
  return (uchar)*p - (uchar)*q;
 121:	0f b6 c0             	movzbl %al,%eax
 124:	0f b6 12             	movzbl (%edx),%edx
 127:	29 d0                	sub    %edx,%eax
}
 129:	5d                   	pop    %ebp
 12a:	c3                   	ret    

0000012b <strlen>:

uint
strlen(char *s)
{
 12b:	f3 0f 1e fb          	endbr32 
 12f:	55                   	push   %ebp
 130:	89 e5                	mov    %esp,%ebp
 132:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int n;

  for(n = 0; s[n]; n++)
 135:	b8 00 00 00 00       	mov    $0x0,%eax
 13a:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
 13e:	74 05                	je     145 <strlen+0x1a>
 140:	83 c0 01             	add    $0x1,%eax
 143:	eb f5                	jmp    13a <strlen+0xf>
    ;
  return n;
}
 145:	5d                   	pop    %ebp
 146:	c3                   	ret    

00000147 <memset>:

void*
memset(void *dst, int c, uint n)
{
 147:	f3 0f 1e fb          	endbr32 
 14b:	55                   	push   %ebp
 14c:	89 e5                	mov    %esp,%ebp
 14e:	57                   	push   %edi
 14f:	8b 55 08             	mov    0x8(%ebp),%edx
}

static inline void
stosb(void *addr, int data, int cnt)
{
  asm volatile("cld; rep stosb" :
 152:	89 d7                	mov    %edx,%edi
 154:	8b 4d 10             	mov    0x10(%ebp),%ecx
 157:	8b 45 0c             	mov    0xc(%ebp),%eax
 15a:	fc                   	cld    
 15b:	f3 aa                	rep stos %al,%es:(%edi)
  stosb(dst, c, n);
  return dst;
}
 15d:	89 d0                	mov    %edx,%eax
 15f:	5f                   	pop    %edi
 160:	5d                   	pop    %ebp
 161:	c3                   	ret    

00000162 <strchr>:

char*
strchr(const char *s, char c)
{
 162:	f3 0f 1e fb          	endbr32 
 166:	55                   	push   %ebp
 167:	89 e5                	mov    %esp,%ebp
 169:	8b 45 08             	mov    0x8(%ebp),%eax
 16c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
  for(; *s; s++)
 170:	0f b6 10             	movzbl (%eax),%edx
 173:	84 d2                	test   %dl,%dl
 175:	74 09                	je     180 <strchr+0x1e>
    if(*s == c)
 177:	38 ca                	cmp    %cl,%dl
 179:	74 0a                	je     185 <strchr+0x23>
  for(; *s; s++)
 17b:	83 c0 01             	add    $0x1,%eax
 17e:	eb f0                	jmp    170 <strchr+0xe>
      return (char*)s;
  return 0;
 180:	b8 00 00 00 00       	mov    $0x0,%eax
}
 185:	5d                   	pop    %ebp
 186:	c3                   	ret    

00000187 <gets>:

char*
gets(char *buf, int max)
{
 187:	f3 0f 1e fb          	endbr32 
 18b:	55                   	push   %ebp
 18c:	89 e5                	mov    %esp,%ebp
 18e:	57                   	push   %edi
 18f:	56                   	push   %esi
 190:	53                   	push   %ebx
 191:	83 ec 1c             	sub    $0x1c,%esp
 194:	8b 7d 08             	mov    0x8(%ebp),%edi
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 197:	bb 00 00 00 00       	mov    $0x0,%ebx
 19c:	89 de                	mov    %ebx,%esi
 19e:	83 c3 01             	add    $0x1,%ebx
 1a1:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
 1a4:	7d 2e                	jge    1d4 <gets+0x4d>
    cc = read(0, &c, 1);
 1a6:	83 ec 04             	sub    $0x4,%esp
 1a9:	6a 01                	push   $0x1
 1ab:	8d 45 e7             	lea    -0x19(%ebp),%eax
 1ae:	50                   	push   %eax
 1af:	6a 00                	push   $0x0
 1b1:	e8 cf 01 00 00       	call   385 <read>
    if(cc < 1)
 1b6:	83 c4 10             	add    $0x10,%esp
 1b9:	85 c0                	test   %eax,%eax
 1bb:	7e 17                	jle    1d4 <gets+0x4d>
      break;
    buf[i++] = c;
 1bd:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
 1c1:	88 04 37             	mov    %al,(%edi,%esi,1)
    if(c == '\n' || c == '\r')
 1c4:	3c 0a                	cmp    $0xa,%al
 1c6:	0f 94 c2             	sete   %dl
 1c9:	3c 0d                	cmp    $0xd,%al
 1cb:	0f 94 c0             	sete   %al
 1ce:	08 c2                	or     %al,%dl
 1d0:	74 ca                	je     19c <gets+0x15>
    buf[i++] = c;
 1d2:	89 de                	mov    %ebx,%esi
      break;
  }
  buf[i] = '\0';
 1d4:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
  return buf;
}
 1d8:	89 f8                	mov    %edi,%eax
 1da:	8d 65 f4             	lea    -0xc(%ebp),%esp
 1dd:	5b                   	pop    %ebx
 1de:	5e                   	pop    %esi
 1df:	5f                   	pop    %edi
 1e0:	5d                   	pop    %ebp
 1e1:	c3                   	ret    

000001e2 <stat>:

int
stat(char *n, struct stat *st)
{
 1e2:	f3 0f 1e fb          	endbr32 
 1e6:	55                   	push   %ebp
 1e7:	89 e5                	mov    %esp,%ebp
 1e9:	56                   	push   %esi
 1ea:	53                   	push   %ebx
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1eb:	83 ec 08             	sub    $0x8,%esp
 1ee:	6a 00                	push   $0x0
 1f0:	ff 75 08             	pushl  0x8(%ebp)
 1f3:	e8 b5 01 00 00       	call   3ad <open>
  if(fd < 0)
 1f8:	83 c4 10             	add    $0x10,%esp
 1fb:	85 c0                	test   %eax,%eax
 1fd:	78 24                	js     223 <stat+0x41>
 1ff:	89 c3                	mov    %eax,%ebx
    return -1;
  r = fstat(fd, st);
 201:	83 ec 08             	sub    $0x8,%esp
 204:	ff 75 0c             	pushl  0xc(%ebp)
 207:	50                   	push   %eax
 208:	e8 b8 01 00 00       	call   3c5 <fstat>
 20d:	89 c6                	mov    %eax,%esi
  close(fd);
 20f:	89 1c 24             	mov    %ebx,(%esp)
 212:	e8 7e 01 00 00       	call   395 <close>
  return r;
 217:	83 c4 10             	add    $0x10,%esp
}
 21a:	89 f0                	mov    %esi,%eax
 21c:	8d 65 f8             	lea    -0x8(%ebp),%esp
 21f:	5b                   	pop    %ebx
 220:	5e                   	pop    %esi
 221:	5d                   	pop    %ebp
 222:	c3                   	ret    
    return -1;
 223:	be ff ff ff ff       	mov    $0xffffffff,%esi
 228:	eb f0                	jmp    21a <stat+0x38>

0000022a <atoi>:

#ifdef PDX_XV6
int
atoi(const char *s)
{
 22a:	f3 0f 1e fb          	endbr32 
 22e:	55                   	push   %ebp
 22f:	89 e5                	mov    %esp,%ebp
 231:	57                   	push   %edi
 232:	56                   	push   %esi
 233:	53                   	push   %ebx
 234:	8b 55 08             	mov    0x8(%ebp),%edx
  int n, sign;

  n = 0;
  while (*s == ' ') s++;
 237:	0f b6 02             	movzbl (%edx),%eax
 23a:	3c 20                	cmp    $0x20,%al
 23c:	75 05                	jne    243 <atoi+0x19>
 23e:	83 c2 01             	add    $0x1,%edx
 241:	eb f4                	jmp    237 <atoi+0xd>
  sign = (*s == '-') ? -1 : 1;
 243:	3c 2d                	cmp    $0x2d,%al
 245:	74 1d                	je     264 <atoi+0x3a>
 247:	bf 01 00 00 00       	mov    $0x1,%edi
  if (*s == '+'  || *s == '-')
 24c:	3c 2b                	cmp    $0x2b,%al
 24e:	0f 94 c1             	sete   %cl
 251:	3c 2d                	cmp    $0x2d,%al
 253:	0f 94 c0             	sete   %al
 256:	08 c1                	or     %al,%cl
 258:	74 03                	je     25d <atoi+0x33>
    s++;
 25a:	83 c2 01             	add    $0x1,%edx
  sign = (*s == '-') ? -1 : 1;
 25d:	b8 00 00 00 00       	mov    $0x0,%eax
 262:	eb 17                	jmp    27b <atoi+0x51>
 264:	bf ff ff ff ff       	mov    $0xffffffff,%edi
 269:	eb e1                	jmp    24c <atoi+0x22>
  while('0' <= *s && *s <= '9')
    n = n*10 + *s++ - '0';
 26b:	8d 34 80             	lea    (%eax,%eax,4),%esi
 26e:	8d 1c 36             	lea    (%esi,%esi,1),%ebx
 271:	83 c2 01             	add    $0x1,%edx
 274:	0f be c9             	movsbl %cl,%ecx
 277:	8d 44 19 d0          	lea    -0x30(%ecx,%ebx,1),%eax
  while('0' <= *s && *s <= '9')
 27b:	0f b6 0a             	movzbl (%edx),%ecx
 27e:	8d 59 d0             	lea    -0x30(%ecx),%ebx
 281:	80 fb 09             	cmp    $0x9,%bl
 284:	76 e5                	jbe    26b <atoi+0x41>
  return sign*n;
 286:	0f af c7             	imul   %edi,%eax
}
 289:	5b                   	pop    %ebx
 28a:	5e                   	pop    %esi
 28b:	5f                   	pop    %edi
 28c:	5d                   	pop    %ebp
 28d:	c3                   	ret    

0000028e <atoo>:

int
atoo(const char *s)
{
 28e:	f3 0f 1e fb          	endbr32 
 292:	55                   	push   %ebp
 293:	89 e5                	mov    %esp,%ebp
 295:	57                   	push   %edi
 296:	56                   	push   %esi
 297:	53                   	push   %ebx
 298:	8b 55 08             	mov    0x8(%ebp),%edx
  int n, sign;

  n = 0;
  while (*s == ' ') s++;
 29b:	0f b6 0a             	movzbl (%edx),%ecx
 29e:	80 f9 20             	cmp    $0x20,%cl
 2a1:	75 05                	jne    2a8 <atoo+0x1a>
 2a3:	83 c2 01             	add    $0x1,%edx
 2a6:	eb f3                	jmp    29b <atoo+0xd>
  sign = (*s == '-') ? -1 : 1;
 2a8:	80 f9 2d             	cmp    $0x2d,%cl
 2ab:	74 23                	je     2d0 <atoo+0x42>
 2ad:	bf 01 00 00 00       	mov    $0x1,%edi
  if (*s == '+'  || *s == '-')
 2b2:	80 f9 2b             	cmp    $0x2b,%cl
 2b5:	0f 94 c0             	sete   %al
 2b8:	89 c6                	mov    %eax,%esi
 2ba:	80 f9 2d             	cmp    $0x2d,%cl
 2bd:	0f 94 c0             	sete   %al
 2c0:	89 f3                	mov    %esi,%ebx
 2c2:	08 c3                	or     %al,%bl
 2c4:	74 03                	je     2c9 <atoo+0x3b>
    s++;
 2c6:	83 c2 01             	add    $0x1,%edx
  sign = (*s == '-') ? -1 : 1;
 2c9:	b8 00 00 00 00       	mov    $0x0,%eax
 2ce:	eb 11                	jmp    2e1 <atoo+0x53>
 2d0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
 2d5:	eb db                	jmp    2b2 <atoo+0x24>
  while('0' <= *s && *s <= '7')
    n = n*8 + *s++ - '0';
 2d7:	83 c2 01             	add    $0x1,%edx
 2da:	0f be c9             	movsbl %cl,%ecx
 2dd:	8d 44 c1 d0          	lea    -0x30(%ecx,%eax,8),%eax
  while('0' <= *s && *s <= '7')
 2e1:	0f b6 0a             	movzbl (%edx),%ecx
 2e4:	8d 59 d0             	lea    -0x30(%ecx),%ebx
 2e7:	80 fb 07             	cmp    $0x7,%bl
 2ea:	76 eb                	jbe    2d7 <atoo+0x49>
  return sign*n;
 2ec:	0f af c7             	imul   %edi,%eax
}
 2ef:	5b                   	pop    %ebx
 2f0:	5e                   	pop    %esi
 2f1:	5f                   	pop    %edi
 2f2:	5d                   	pop    %ebp
 2f3:	c3                   	ret    

000002f4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
 2f4:	f3 0f 1e fb          	endbr32 
 2f8:	55                   	push   %ebp
 2f9:	89 e5                	mov    %esp,%ebp
 2fb:	53                   	push   %ebx
 2fc:	8b 55 08             	mov    0x8(%ebp),%edx
 2ff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
 302:	8b 45 10             	mov    0x10(%ebp),%eax
    while(n > 0 && *p && *p == *q)
 305:	eb 09                	jmp    310 <strncmp+0x1c>
      n--, p++, q++;
 307:	83 e8 01             	sub    $0x1,%eax
 30a:	83 c2 01             	add    $0x1,%edx
 30d:	83 c1 01             	add    $0x1,%ecx
    while(n > 0 && *p && *p == *q)
 310:	85 c0                	test   %eax,%eax
 312:	74 0b                	je     31f <strncmp+0x2b>
 314:	0f b6 1a             	movzbl (%edx),%ebx
 317:	84 db                	test   %bl,%bl
 319:	74 04                	je     31f <strncmp+0x2b>
 31b:	3a 19                	cmp    (%ecx),%bl
 31d:	74 e8                	je     307 <strncmp+0x13>
    if(n == 0)
 31f:	85 c0                	test   %eax,%eax
 321:	74 0b                	je     32e <strncmp+0x3a>
      return 0;
    return (uchar)*p - (uchar)*q;
 323:	0f b6 02             	movzbl (%edx),%eax
 326:	0f b6 11             	movzbl (%ecx),%edx
 329:	29 d0                	sub    %edx,%eax
}
 32b:	5b                   	pop    %ebx
 32c:	5d                   	pop    %ebp
 32d:	c3                   	ret    
      return 0;
 32e:	b8 00 00 00 00       	mov    $0x0,%eax
 333:	eb f6                	jmp    32b <strncmp+0x37>

00000335 <memmove>:
}
#endif // PDX_XV6

void*
memmove(void *vdst, void *vsrc, int n)
{
 335:	f3 0f 1e fb          	endbr32 
 339:	55                   	push   %ebp
 33a:	89 e5                	mov    %esp,%ebp
 33c:	56                   	push   %esi
 33d:	53                   	push   %ebx
 33e:	8b 75 08             	mov    0x8(%ebp),%esi
 341:	8b 4d 0c             	mov    0xc(%ebp),%ecx
 344:	8b 45 10             	mov    0x10(%ebp),%eax
  char *dst, *src;

  dst = vdst;
 347:	89 f2                	mov    %esi,%edx
  src = vsrc;
  while(n-- > 0)
 349:	8d 58 ff             	lea    -0x1(%eax),%ebx
 34c:	85 c0                	test   %eax,%eax
 34e:	7e 0f                	jle    35f <memmove+0x2a>
    *dst++ = *src++;
 350:	0f b6 01             	movzbl (%ecx),%eax
 353:	88 02                	mov    %al,(%edx)
 355:	8d 49 01             	lea    0x1(%ecx),%ecx
 358:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
 35b:	89 d8                	mov    %ebx,%eax
 35d:	eb ea                	jmp    349 <memmove+0x14>
  return vdst;
}
 35f:	89 f0                	mov    %esi,%eax
 361:	5b                   	pop    %ebx
 362:	5e                   	pop    %esi
 363:	5d                   	pop    %ebp
 364:	c3                   	ret    

00000365 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 365:	b8 01 00 00 00       	mov    $0x1,%eax
 36a:	cd 40                	int    $0x40
 36c:	c3                   	ret    

0000036d <exit>:
SYSCALL(exit)
 36d:	b8 02 00 00 00       	mov    $0x2,%eax
 372:	cd 40                	int    $0x40
 374:	c3                   	ret    

00000375 <wait>:
SYSCALL(wait)
 375:	b8 03 00 00 00       	mov    $0x3,%eax
 37a:	cd 40                	int    $0x40
 37c:	c3                   	ret    

0000037d <pipe>:
SYSCALL(pipe)
 37d:	b8 04 00 00 00       	mov    $0x4,%eax
 382:	cd 40                	int    $0x40
 384:	c3                   	ret    

00000385 <read>:
SYSCALL(read)
 385:	b8 05 00 00 00       	mov    $0x5,%eax
 38a:	cd 40                	int    $0x40
 38c:	c3                   	ret    

0000038d <write>:
SYSCALL(write)
 38d:	b8 10 00 00 00       	mov    $0x10,%eax
 392:	cd 40                	int    $0x40
 394:	c3                   	ret    

00000395 <close>:
SYSCALL(close)
 395:	b8 15 00 00 00       	mov    $0x15,%eax
 39a:	cd 40                	int    $0x40
 39c:	c3                   	ret    

0000039d <kill>:
SYSCALL(kill)
 39d:	b8 06 00 00 00       	mov    $0x6,%eax
 3a2:	cd 40                	int    $0x40
 3a4:	c3                   	ret    

000003a5 <exec>:
SYSCALL(exec)
 3a5:	b8 07 00 00 00       	mov    $0x7,%eax
 3aa:	cd 40                	int    $0x40
 3ac:	c3                   	ret    

000003ad <open>:
SYSCALL(open)
 3ad:	b8 0f 00 00 00       	mov    $0xf,%eax
 3b2:	cd 40                	int    $0x40
 3b4:	c3                   	ret    

000003b5 <mknod>:
SYSCALL(mknod)
 3b5:	b8 11 00 00 00       	mov    $0x11,%eax
 3ba:	cd 40                	int    $0x40
 3bc:	c3                   	ret    

000003bd <unlink>:
SYSCALL(unlink)
 3bd:	b8 12 00 00 00       	mov    $0x12,%eax
 3c2:	cd 40                	int    $0x40
 3c4:	c3                   	ret    

000003c5 <fstat>:
SYSCALL(fstat)
 3c5:	b8 08 00 00 00       	mov    $0x8,%eax
 3ca:	cd 40                	int    $0x40
 3cc:	c3                   	ret    

000003cd <link>:
SYSCALL(link)
 3cd:	b8 13 00 00 00       	mov    $0x13,%eax
 3d2:	cd 40                	int    $0x40
 3d4:	c3                   	ret    

000003d5 <mkdir>:
SYSCALL(mkdir)
 3d5:	b8 14 00 00 00       	mov    $0x14,%eax
 3da:	cd 40                	int    $0x40
 3dc:	c3                   	ret    

000003dd <chdir>:
SYSCALL(chdir)
 3dd:	b8 09 00 00 00       	mov    $0x9,%eax
 3e2:	cd 40                	int    $0x40
 3e4:	c3                   	ret    

000003e5 <dup>:
SYSCALL(dup)
 3e5:	b8 0a 00 00 00       	mov    $0xa,%eax
 3ea:	cd 40                	int    $0x40
 3ec:	c3                   	ret    

000003ed <getpid>:
SYSCALL(getpid)
 3ed:	b8 0b 00 00 00       	mov    $0xb,%eax
 3f2:	cd 40                	int    $0x40
 3f4:	c3                   	ret    

000003f5 <sbrk>:
SYSCALL(sbrk)
 3f5:	b8 0c 00 00 00       	mov    $0xc,%eax
 3fa:	cd 40                	int    $0x40
 3fc:	c3                   	ret    

000003fd <sleep>:
SYSCALL(sleep)
 3fd:	b8 0d 00 00 00       	mov    $0xd,%eax
 402:	cd 40                	int    $0x40
 404:	c3                   	ret    

00000405 <uptime>:
SYSCALL(uptime)
 405:	b8 0e 00 00 00       	mov    $0xe,%eax
 40a:	cd 40                	int    $0x40
 40c:	c3                   	ret    

0000040d <halt>:
SYSCALL(halt)
 40d:	b8 16 00 00 00       	mov    $0x16,%eax
 412:	cd 40                	int    $0x40
 414:	c3                   	ret    

00000415 <date>:
SYSCALL(date)
 415:	b8 17 00 00 00       	mov    $0x17,%eax
 41a:	cd 40                	int    $0x40
 41c:	c3                   	ret    

0000041d <getuid>:
SYSCALL(getuid)
 41d:	b8 18 00 00 00       	mov    $0x18,%eax
 422:	cd 40                	int    $0x40
 424:	c3                   	ret    

00000425 <getgid>:
SYSCALL(getgid)
 425:	b8 19 00 00 00       	mov    $0x19,%eax
 42a:	cd 40                	int    $0x40
 42c:	c3                   	ret    

0000042d <getppid>:
SYSCALL(getppid)
 42d:	b8 1a 00 00 00       	mov    $0x1a,%eax
 432:	cd 40                	int    $0x40
 434:	c3                   	ret    

00000435 <setuid>:
SYSCALL(setuid)
 435:	b8 1b 00 00 00       	mov    $0x1b,%eax
 43a:	cd 40                	int    $0x40
 43c:	c3                   	ret    

0000043d <setgid>:
SYSCALL(setgid)
 43d:	b8 1c 00 00 00       	mov    $0x1c,%eax
 442:	cd 40                	int    $0x40
 444:	c3                   	ret    

00000445 <getprocs>:
 445:	b8 1d 00 00 00       	mov    $0x1d,%eax
 44a:	cd 40                	int    $0x40
 44c:	c3                   	ret    

0000044d <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 44d:	55                   	push   %ebp
 44e:	89 e5                	mov    %esp,%ebp
 450:	83 ec 1c             	sub    $0x1c,%esp
 453:	88 55 f4             	mov    %dl,-0xc(%ebp)
  write(fd, &c, 1);
 456:	6a 01                	push   $0x1
 458:	8d 55 f4             	lea    -0xc(%ebp),%edx
 45b:	52                   	push   %edx
 45c:	50                   	push   %eax
 45d:	e8 2b ff ff ff       	call   38d <write>
}
 462:	83 c4 10             	add    $0x10,%esp
 465:	c9                   	leave  
 466:	c3                   	ret    

00000467 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 467:	55                   	push   %ebp
 468:	89 e5                	mov    %esp,%ebp
 46a:	57                   	push   %edi
 46b:	56                   	push   %esi
 46c:	53                   	push   %ebx
 46d:	83 ec 2c             	sub    $0x2c,%esp
 470:	89 45 d0             	mov    %eax,-0x30(%ebp)
 473:	89 d6                	mov    %edx,%esi
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 475:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
 479:	0f 95 c2             	setne  %dl
 47c:	89 f0                	mov    %esi,%eax
 47e:	c1 e8 1f             	shr    $0x1f,%eax
 481:	84 c2                	test   %al,%dl
 483:	74 42                	je     4c7 <printint+0x60>
    neg = 1;
    x = -xx;
 485:	f7 de                	neg    %esi
    neg = 1;
 487:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
  } else {
    x = xx;
  }

  i = 0;
 48e:	bb 00 00 00 00       	mov    $0x0,%ebx
  do{
    buf[i++] = digits[x % base];
 493:	89 f0                	mov    %esi,%eax
 495:	ba 00 00 00 00       	mov    $0x0,%edx
 49a:	f7 f1                	div    %ecx
 49c:	89 df                	mov    %ebx,%edi
 49e:	83 c3 01             	add    $0x1,%ebx
 4a1:	0f b6 92 14 08 00 00 	movzbl 0x814(%edx),%edx
 4a8:	88 54 3d d8          	mov    %dl,-0x28(%ebp,%edi,1)
  }while((x /= base) != 0);
 4ac:	89 f2                	mov    %esi,%edx
 4ae:	89 c6                	mov    %eax,%esi
 4b0:	39 d1                	cmp    %edx,%ecx
 4b2:	76 df                	jbe    493 <printint+0x2c>
  if(neg)
 4b4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
 4b8:	74 2f                	je     4e9 <printint+0x82>
    buf[i++] = '-';
 4ba:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
 4bf:	8d 5f 02             	lea    0x2(%edi),%ebx
 4c2:	8b 75 d0             	mov    -0x30(%ebp),%esi
 4c5:	eb 15                	jmp    4dc <printint+0x75>
  neg = 0;
 4c7:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
 4ce:	eb be                	jmp    48e <printint+0x27>

  while(--i >= 0)
    putc(fd, buf[i]);
 4d0:	0f be 54 1d d8       	movsbl -0x28(%ebp,%ebx,1),%edx
 4d5:	89 f0                	mov    %esi,%eax
 4d7:	e8 71 ff ff ff       	call   44d <putc>
  while(--i >= 0)
 4dc:	83 eb 01             	sub    $0x1,%ebx
 4df:	79 ef                	jns    4d0 <printint+0x69>
}
 4e1:	83 c4 2c             	add    $0x2c,%esp
 4e4:	5b                   	pop    %ebx
 4e5:	5e                   	pop    %esi
 4e6:	5f                   	pop    %edi
 4e7:	5d                   	pop    %ebp
 4e8:	c3                   	ret    
 4e9:	8b 75 d0             	mov    -0x30(%ebp),%esi
 4ec:	eb ee                	jmp    4dc <printint+0x75>

000004ee <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 4ee:	f3 0f 1e fb          	endbr32 
 4f2:	55                   	push   %ebp
 4f3:	89 e5                	mov    %esp,%ebp
 4f5:	57                   	push   %edi
 4f6:	56                   	push   %esi
 4f7:	53                   	push   %ebx
 4f8:	83 ec 1c             	sub    $0x1c,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
 4fb:	8d 45 10             	lea    0x10(%ebp),%eax
 4fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  state = 0;
 501:	be 00 00 00 00       	mov    $0x0,%esi
  for(i = 0; fmt[i]; i++){
 506:	bb 00 00 00 00       	mov    $0x0,%ebx
 50b:	eb 14                	jmp    521 <printf+0x33>
    c = fmt[i] & 0xff;
    if(state == 0){
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
 50d:	89 fa                	mov    %edi,%edx
 50f:	8b 45 08             	mov    0x8(%ebp),%eax
 512:	e8 36 ff ff ff       	call   44d <putc>
 517:	eb 05                	jmp    51e <printf+0x30>
      }
    } else if(state == '%'){
 519:	83 fe 25             	cmp    $0x25,%esi
 51c:	74 25                	je     543 <printf+0x55>
  for(i = 0; fmt[i]; i++){
 51e:	83 c3 01             	add    $0x1,%ebx
 521:	8b 45 0c             	mov    0xc(%ebp),%eax
 524:	0f b6 04 18          	movzbl (%eax,%ebx,1),%eax
 528:	84 c0                	test   %al,%al
 52a:	0f 84 23 01 00 00    	je     653 <printf+0x165>
    c = fmt[i] & 0xff;
 530:	0f be f8             	movsbl %al,%edi
 533:	0f b6 c0             	movzbl %al,%eax
    if(state == 0){
 536:	85 f6                	test   %esi,%esi
 538:	75 df                	jne    519 <printf+0x2b>
      if(c == '%'){
 53a:	83 f8 25             	cmp    $0x25,%eax
 53d:	75 ce                	jne    50d <printf+0x1f>
        state = '%';
 53f:	89 c6                	mov    %eax,%esi
 541:	eb db                	jmp    51e <printf+0x30>
      if(c == 'd'){
 543:	83 f8 64             	cmp    $0x64,%eax
 546:	74 49                	je     591 <printf+0xa3>
        printint(fd, *ap, 10, 1);
        ap++;
      } else if(c == 'x' || c == 'p'){
 548:	83 f8 78             	cmp    $0x78,%eax
 54b:	0f 94 c1             	sete   %cl
 54e:	83 f8 70             	cmp    $0x70,%eax
 551:	0f 94 c2             	sete   %dl
 554:	08 d1                	or     %dl,%cl
 556:	75 63                	jne    5bb <printf+0xcd>
        printint(fd, *ap, 16, 0);
        ap++;
      } else if(c == 's'){
 558:	83 f8 73             	cmp    $0x73,%eax
 55b:	0f 84 84 00 00 00    	je     5e5 <printf+0xf7>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 561:	83 f8 63             	cmp    $0x63,%eax
 564:	0f 84 b7 00 00 00    	je     621 <printf+0x133>
        putc(fd, *ap);
        ap++;
      } else if(c == '%'){
 56a:	83 f8 25             	cmp    $0x25,%eax
 56d:	0f 84 cc 00 00 00    	je     63f <printf+0x151>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 573:	ba 25 00 00 00       	mov    $0x25,%edx
 578:	8b 45 08             	mov    0x8(%ebp),%eax
 57b:	e8 cd fe ff ff       	call   44d <putc>
        putc(fd, c);
 580:	89 fa                	mov    %edi,%edx
 582:	8b 45 08             	mov    0x8(%ebp),%eax
 585:	e8 c3 fe ff ff       	call   44d <putc>
      }
      state = 0;
 58a:	be 00 00 00 00       	mov    $0x0,%esi
 58f:	eb 8d                	jmp    51e <printf+0x30>
        printint(fd, *ap, 10, 1);
 591:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 594:	8b 17                	mov    (%edi),%edx
 596:	83 ec 0c             	sub    $0xc,%esp
 599:	6a 01                	push   $0x1
 59b:	b9 0a 00 00 00       	mov    $0xa,%ecx
 5a0:	8b 45 08             	mov    0x8(%ebp),%eax
 5a3:	e8 bf fe ff ff       	call   467 <printint>
        ap++;
 5a8:	83 c7 04             	add    $0x4,%edi
 5ab:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 5ae:	83 c4 10             	add    $0x10,%esp
      state = 0;
 5b1:	be 00 00 00 00       	mov    $0x0,%esi
 5b6:	e9 63 ff ff ff       	jmp    51e <printf+0x30>
        printint(fd, *ap, 16, 0);
 5bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 5be:	8b 17                	mov    (%edi),%edx
 5c0:	83 ec 0c             	sub    $0xc,%esp
 5c3:	6a 00                	push   $0x0
 5c5:	b9 10 00 00 00       	mov    $0x10,%ecx
 5ca:	8b 45 08             	mov    0x8(%ebp),%eax
 5cd:	e8 95 fe ff ff       	call   467 <printint>
        ap++;
 5d2:	83 c7 04             	add    $0x4,%edi
 5d5:	89 7d e4             	mov    %edi,-0x1c(%ebp)
 5d8:	83 c4 10             	add    $0x10,%esp
      state = 0;
 5db:	be 00 00 00 00       	mov    $0x0,%esi
 5e0:	e9 39 ff ff ff       	jmp    51e <printf+0x30>
        s = (char*)*ap;
 5e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5e8:	8b 30                	mov    (%eax),%esi
        ap++;
 5ea:	83 c0 04             	add    $0x4,%eax
 5ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        if(s == 0)
 5f0:	85 f6                	test   %esi,%esi
 5f2:	75 28                	jne    61c <printf+0x12e>
          s = "(null)";
 5f4:	be 0b 08 00 00       	mov    $0x80b,%esi
 5f9:	8b 7d 08             	mov    0x8(%ebp),%edi
 5fc:	eb 0d                	jmp    60b <printf+0x11d>
          putc(fd, *s);
 5fe:	0f be d2             	movsbl %dl,%edx
 601:	89 f8                	mov    %edi,%eax
 603:	e8 45 fe ff ff       	call   44d <putc>
          s++;
 608:	83 c6 01             	add    $0x1,%esi
        while(*s != 0){
 60b:	0f b6 16             	movzbl (%esi),%edx
 60e:	84 d2                	test   %dl,%dl
 610:	75 ec                	jne    5fe <printf+0x110>
      state = 0;
 612:	be 00 00 00 00       	mov    $0x0,%esi
 617:	e9 02 ff ff ff       	jmp    51e <printf+0x30>
 61c:	8b 7d 08             	mov    0x8(%ebp),%edi
 61f:	eb ea                	jmp    60b <printf+0x11d>
        putc(fd, *ap);
 621:	8b 7d e4             	mov    -0x1c(%ebp),%edi
 624:	0f be 17             	movsbl (%edi),%edx
 627:	8b 45 08             	mov    0x8(%ebp),%eax
 62a:	e8 1e fe ff ff       	call   44d <putc>
        ap++;
 62f:	83 c7 04             	add    $0x4,%edi
 632:	89 7d e4             	mov    %edi,-0x1c(%ebp)
      state = 0;
 635:	be 00 00 00 00       	mov    $0x0,%esi
 63a:	e9 df fe ff ff       	jmp    51e <printf+0x30>
        putc(fd, c);
 63f:	89 fa                	mov    %edi,%edx
 641:	8b 45 08             	mov    0x8(%ebp),%eax
 644:	e8 04 fe ff ff       	call   44d <putc>
      state = 0;
 649:	be 00 00 00 00       	mov    $0x0,%esi
 64e:	e9 cb fe ff ff       	jmp    51e <printf+0x30>
    }
  }
}
 653:	8d 65 f4             	lea    -0xc(%ebp),%esp
 656:	5b                   	pop    %ebx
 657:	5e                   	pop    %esi
 658:	5f                   	pop    %edi
 659:	5d                   	pop    %ebp
 65a:	c3                   	ret    

0000065b <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 65b:	f3 0f 1e fb          	endbr32 
 65f:	55                   	push   %ebp
 660:	89 e5                	mov    %esp,%ebp
 662:	57                   	push   %edi
 663:	56                   	push   %esi
 664:	53                   	push   %ebx
 665:	8b 5d 08             	mov    0x8(%ebp),%ebx
  Header *bp, *p;

  bp = (Header*)ap - 1;
 668:	8d 4b f8             	lea    -0x8(%ebx),%ecx
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 66b:	a1 18 0b 00 00       	mov    0xb18,%eax
 670:	eb 02                	jmp    674 <free+0x19>
 672:	89 d0                	mov    %edx,%eax
 674:	39 c8                	cmp    %ecx,%eax
 676:	73 04                	jae    67c <free+0x21>
 678:	39 08                	cmp    %ecx,(%eax)
 67a:	77 12                	ja     68e <free+0x33>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 67c:	8b 10                	mov    (%eax),%edx
 67e:	39 c2                	cmp    %eax,%edx
 680:	77 f0                	ja     672 <free+0x17>
 682:	39 c8                	cmp    %ecx,%eax
 684:	72 08                	jb     68e <free+0x33>
 686:	39 ca                	cmp    %ecx,%edx
 688:	77 04                	ja     68e <free+0x33>
 68a:	89 d0                	mov    %edx,%eax
 68c:	eb e6                	jmp    674 <free+0x19>
      break;
  if(bp + bp->s.size == p->s.ptr){
 68e:	8b 73 fc             	mov    -0x4(%ebx),%esi
 691:	8d 3c f1             	lea    (%ecx,%esi,8),%edi
 694:	8b 10                	mov    (%eax),%edx
 696:	39 d7                	cmp    %edx,%edi
 698:	74 19                	je     6b3 <free+0x58>
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
 69a:	89 53 f8             	mov    %edx,-0x8(%ebx)
  if(p + p->s.size == bp){
 69d:	8b 50 04             	mov    0x4(%eax),%edx
 6a0:	8d 34 d0             	lea    (%eax,%edx,8),%esi
 6a3:	39 ce                	cmp    %ecx,%esi
 6a5:	74 1b                	je     6c2 <free+0x67>
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
 6a7:	89 08                	mov    %ecx,(%eax)
  freep = p;
 6a9:	a3 18 0b 00 00       	mov    %eax,0xb18
}
 6ae:	5b                   	pop    %ebx
 6af:	5e                   	pop    %esi
 6b0:	5f                   	pop    %edi
 6b1:	5d                   	pop    %ebp
 6b2:	c3                   	ret    
    bp->s.size += p->s.ptr->s.size;
 6b3:	03 72 04             	add    0x4(%edx),%esi
 6b6:	89 73 fc             	mov    %esi,-0x4(%ebx)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b9:	8b 10                	mov    (%eax),%edx
 6bb:	8b 12                	mov    (%edx),%edx
 6bd:	89 53 f8             	mov    %edx,-0x8(%ebx)
 6c0:	eb db                	jmp    69d <free+0x42>
    p->s.size += bp->s.size;
 6c2:	03 53 fc             	add    -0x4(%ebx),%edx
 6c5:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 6c8:	8b 53 f8             	mov    -0x8(%ebx),%edx
 6cb:	89 10                	mov    %edx,(%eax)
 6cd:	eb da                	jmp    6a9 <free+0x4e>

000006cf <morecore>:

static Header*
morecore(uint nu)
{
 6cf:	55                   	push   %ebp
 6d0:	89 e5                	mov    %esp,%ebp
 6d2:	53                   	push   %ebx
 6d3:	83 ec 04             	sub    $0x4,%esp
 6d6:	89 c3                	mov    %eax,%ebx
  char *p;
  Header *hp;

  if(nu < 4096)
 6d8:	3d ff 0f 00 00       	cmp    $0xfff,%eax
 6dd:	77 05                	ja     6e4 <morecore+0x15>
    nu = 4096;
 6df:	bb 00 10 00 00       	mov    $0x1000,%ebx
  p = sbrk(nu * sizeof(Header));
 6e4:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
 6eb:	83 ec 0c             	sub    $0xc,%esp
 6ee:	50                   	push   %eax
 6ef:	e8 01 fd ff ff       	call   3f5 <sbrk>
  if(p == (char*)-1)
 6f4:	83 c4 10             	add    $0x10,%esp
 6f7:	83 f8 ff             	cmp    $0xffffffff,%eax
 6fa:	74 1c                	je     718 <morecore+0x49>
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
 6fc:	89 58 04             	mov    %ebx,0x4(%eax)
  free((void*)(hp + 1));
 6ff:	83 c0 08             	add    $0x8,%eax
 702:	83 ec 0c             	sub    $0xc,%esp
 705:	50                   	push   %eax
 706:	e8 50 ff ff ff       	call   65b <free>
  return freep;
 70b:	a1 18 0b 00 00       	mov    0xb18,%eax
 710:	83 c4 10             	add    $0x10,%esp
}
 713:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 716:	c9                   	leave  
 717:	c3                   	ret    
    return 0;
 718:	b8 00 00 00 00       	mov    $0x0,%eax
 71d:	eb f4                	jmp    713 <morecore+0x44>

0000071f <malloc>:

void*
malloc(uint nbytes)
{
 71f:	f3 0f 1e fb          	endbr32 
 723:	55                   	push   %ebp
 724:	89 e5                	mov    %esp,%ebp
 726:	53                   	push   %ebx
 727:	83 ec 04             	sub    $0x4,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 72a:	8b 45 08             	mov    0x8(%ebp),%eax
 72d:	8d 58 07             	lea    0x7(%eax),%ebx
 730:	c1 eb 03             	shr    $0x3,%ebx
 733:	83 c3 01             	add    $0x1,%ebx
  if((prevp = freep) == 0){
 736:	8b 0d 18 0b 00 00    	mov    0xb18,%ecx
 73c:	85 c9                	test   %ecx,%ecx
 73e:	74 04                	je     744 <malloc+0x25>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 740:	8b 01                	mov    (%ecx),%eax
 742:	eb 4b                	jmp    78f <malloc+0x70>
    base.s.ptr = freep = prevp = &base;
 744:	c7 05 18 0b 00 00 1c 	movl   $0xb1c,0xb18
 74b:	0b 00 00 
 74e:	c7 05 1c 0b 00 00 1c 	movl   $0xb1c,0xb1c
 755:	0b 00 00 
    base.s.size = 0;
 758:	c7 05 20 0b 00 00 00 	movl   $0x0,0xb20
 75f:	00 00 00 
    base.s.ptr = freep = prevp = &base;
 762:	b9 1c 0b 00 00       	mov    $0xb1c,%ecx
 767:	eb d7                	jmp    740 <malloc+0x21>
    if(p->s.size >= nunits){
      if(p->s.size == nunits)
 769:	74 1a                	je     785 <malloc+0x66>
        prevp->s.ptr = p->s.ptr;
      else {
        p->s.size -= nunits;
 76b:	29 da                	sub    %ebx,%edx
 76d:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 770:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        p->s.size = nunits;
 773:	89 58 04             	mov    %ebx,0x4(%eax)
      }
      freep = prevp;
 776:	89 0d 18 0b 00 00    	mov    %ecx,0xb18
      return (void*)(p + 1);
 77c:	83 c0 08             	add    $0x8,%eax
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 77f:	83 c4 04             	add    $0x4,%esp
 782:	5b                   	pop    %ebx
 783:	5d                   	pop    %ebp
 784:	c3                   	ret    
        prevp->s.ptr = p->s.ptr;
 785:	8b 10                	mov    (%eax),%edx
 787:	89 11                	mov    %edx,(%ecx)
 789:	eb eb                	jmp    776 <malloc+0x57>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 78b:	89 c1                	mov    %eax,%ecx
 78d:	8b 00                	mov    (%eax),%eax
    if(p->s.size >= nunits){
 78f:	8b 50 04             	mov    0x4(%eax),%edx
 792:	39 da                	cmp    %ebx,%edx
 794:	73 d3                	jae    769 <malloc+0x4a>
    if(p == freep)
 796:	39 05 18 0b 00 00    	cmp    %eax,0xb18
 79c:	75 ed                	jne    78b <malloc+0x6c>
      if((p = morecore(nunits)) == 0)
 79e:	89 d8                	mov    %ebx,%eax
 7a0:	e8 2a ff ff ff       	call   6cf <morecore>
 7a5:	85 c0                	test   %eax,%eax
 7a7:	75 e2                	jne    78b <malloc+0x6c>
 7a9:	eb d4                	jmp    77f <malloc+0x60>
