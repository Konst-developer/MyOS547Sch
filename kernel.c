#define uint8_t unsigned char
#define uint16_t unsigned short int
#define uint32_t unsigned int
#define uint64_t unsigned long int

//constants
const uint32_t PT_ADDRESS=0x100000;//+256
const uint32_t BUFFER_ADDRESS=0x200000;
const uint32_t FS_DATA_ADDRESS=0x100100;//+1024
const uint32_t MEMORY_BITMAP=0x100500; 
const uint32_t FAT_ADDRESS=0x120500;
const uint32_t FREE_MEM_BEGINS=0x400000;

//global variables
static uint32_t availableMemoryMB=0;
static char *videoMem=(char *)0xA8000;
static char *allMem=(char *)0;
static char hello[]="Hello World";
static unsigned int cursX=0,cursY=0;
static uint8_t textAttr=0x07;
static uint32_t sysTimer=0;

//structures
typedef struct
{
    uint8_t active;
    uint8_t headsN;
    uint16_t cylN;
    uint8_t type;
    uint8_t endHeadsN;
    uint16_t endCylN;
    uint32_t firstSector;
    uint32_t sectorsN;
} PartitionTable;
PartitionTable *PT=(PartitionTable *)PT_ADDRESS;

#pragma pack(push,1)
typedef struct
{
    char publisher[8];
    uint16_t bytesPerSector;
    uint8_t sectorsPerCluster;
    uint16_t resSect;
    uint8_t FATN;
    uint16_t descN;
    uint16_t sectN16; 
    uint8_t driveType;
    uint16_t sectPerFAT;
    uint16_t sectPerTrack;
    uint16_t sidesN;
    uint32_t hiddenSectorsN;
    uint32_t sectN32;
    uint8_t driveNumber;
    uint8_t resNT;
    uint8_t extBR;
    uint32_t logicalDriveNumber;
    char driveLabel[11];
    char FSType[8];
    char res1[5];
}FS_Data;
#pragma pack(pop)
FS_Data *FSInfo=(FS_Data *)FS_DATA_ADDRESS;

#pragma pack(push,1)
typedef struct
{
    char fileName[11];
    uint8_t attr;
    uint8_t resNT;
    uint8_t extTime;
    uint16_t fCreationTime;
    uint16_t fCreationDate;
    uint16_t lastUseDate;
    uint16_t clusterNHigh;
    uint16_t writeTime;
    uint16_t writeDate;
    uint16_t clusterNLow;
    uint32_t size;
} FileDescriptorRecord;
#pragma pack(pop)


//Headers
static void print(char * c);
static void println(char *c);
static void setCursorPosition(int x, int y);
static void clrscr();
static char *uintToStr(char *c, uint32_t n);
static uint32_t getMem();
static void incTimer();
static void delayST(uint32_t t);
static int hdd0Ready();
static int readSector(uint32_t n, uint32_t number,
                            uint32_t bufAddr);
static void readPT();
static void fillMemZeros(uint32_t addr, uint32_t count);
static void memCopy(uint32_t inAddr, uint32_t outAddr, uint32_t count);
static void readFSInfo();
static int readRootDir(int driveN, uint32_t addr);
static void memoryBitMapInit();
static uint32_t pageIsAvailable(uint32_t n);
static void markPage(uint32_t n);
static uint32_t getFreeMemoryBlock(uint32_t memorySize);
static void deletegMemoryBlock(uint32_t startPage, uint32_t memorySize);
static void freePage(uint32_t n);
static uint32_t getPageAddress(uint32_t n);
static int readCluster(uint32_t driveN, uint32_t clusterN, uint32_t addr);
static int strlen(char *s);
static int strcmp(char *s1, char *s2);
static int isCorrectSymbol(char s);
static char *fileNameDSCToStr(char *stdStr,char *dscStr);
static FileDescriptorRecord getFileInDirDSC(FileDescriptorRecord dir,char *fn);

//0
static void _start()
{
    char s[11];
    clrscr();
    textAttr=0x0C;
    println("myOS 2025 32 bit v0.01");
    textAttr=0x07;
    println(uintToStr(s,2025*5));
    print(uintToStr(s,getMem()));
    println(" Mb of RAM Available");
    for(int i=0; i<80; i++)
    {
        print("#");
        delayST(1);
    }

    readPT();
    readFSInfo();
    print("Partition 0 starts: ");
    println(uintToStr(s,PT[0].firstSector));
    print("Partition 0 sectors: ");
    println(uintToStr(s,PT[0].sectorsN));
    print("Number of sectors in Cluster: ");
    println(uintToStr(s,FSInfo[0].sectorsPerCluster));

    FileDescriptorRecord fd;
    fd.clusterNLow=0;
    char fn2[]="MSDOS.SYS";
    fd=getFileInDirDSC(fd,fn2);
    int nn=fd.clusterNLow;
    println(uintToStr(s,nn));
    readCluster(0,nn,BUFFER_ADDRESS);
    for(int i=0;i<512;i++){
        videoMem[3000+i*2]=allMem[BUFFER_ADDRESS+i];
        videoMem[3000+i*2+1]=0x0A;
    }

    // readRootDir(0,BUFFER_ADDRESS);
    // FileDescriptorRecord *fd = (FileDescriptorRecord *)BUFFER_ADDRESS;
    // char fn[13];
    // for(int i=0;i<10;i++)
    // {
    //     int n=0;
    //     for(int j=0;j<8;j++)
    //         if(fd[i].fileName[j]!=32)
    //         {
    //             fn[n]=fd[i].fileName[j];
    //             n++;
    //         }
    //     fn[n++]='.';
    //     for(int j=8;j<11;j++)
    //         if(fd[i].fileName[j]!=32)
    //         {
    //             fn[n]=fd[i].fileName[j];
    //             n++;
    //         }
    //     fn[n]=0;
    //     println(fn);
    // }
    
    //readCluster(0,2,BUFFER_ADDRESS);
    // for(int i=0;i<960;i++){
    //     videoMem[1600+i*2]=allMem[BUFFER_ADDRESS+i];
    //     videoMem[1600+i*2+1]=textAttr;
    // }

    markPage(0);
    markPage(2);
    markPage(5);
    println(uintToStr(s,getFreeMemoryBlock(100)));
    println(uintToStr(s,getFreeMemoryBlock(10000)));


}

//1 print string on screen
static void print(char * c)
{
    int i=0;
    int vAdr = (80*cursY+cursX)*2;
    while(c[i] != 0)
    {
        if(c[i] !=10 )
        {
            videoMem[vAdr + i*2] = c[i];
            videoMem[vAdr + i*2+1]=textAttr;
            cursX++;
        }
        else
        {
            cursX=0;
            cursY++;
            vAdr=(80*cursY+cursX)*2 - i*2;
        }
        i++;
        if(cursX==80)
        {
            cursX=0;
            cursY++;
        }
        if(cursY==25)
        {
            cursY=24;
            int *vm=(int *)videoMem;
            for(int j=0; j<960; j++)
                vm[j] = vm[j+40];
            for (int j=960; j<1000; j++)
                vm[j]=0x07000700;
            vAdr=24*160 - i*2;
        } 
    }
    setCursorPosition(cursX,cursY);
}
//2
static void println(char *c)
{
    print(c);
    print("\n");
}
//3
static void setCursorPosition(int x, int y)
{
    int c = y*80 + x;
    cursX = x;
    cursY = y;
    __asm__("movl %0, %%eax\n\t"
            "movl %%eax, %%ecx\n\t"
            "movw $0x3D4, %%dx\n\t"
            "movb $0x0F, %%al\n\t"
            "out %%al, %%dx\n\t"
            "movl %%ecx, %%eax\n\t"
            "movw $0x3D5, %%dx\n\t"
            "out %%al, %%dx\n\t"

            "movw $0x3D4, %%dx\n\t"
            "movb $0x0E, %%al\n\t"
            "out %%al, %%dx\n\t"
            "movl %%ecx, %%eax\n\t"
            "shrl $8, %%eax\n\t"
            "movw $0x3D5, %%dx\n\t"
            "out %%al, %%dx\n\t"
            :
            : "r"(c)
            : "eax");
}
//4
static void clrscr()
{
    int *vm=(int *)videoMem;
    for(int i=0; i<1000; i++)
        vm[i]=0x07000700;
    setCursorPosition(0,0);
}
//5 
static char *uintToStr(char *c, uint32_t n)
{
    c[10]=0;
    int j=9;
    char decStr[]="0123456789";
    do
    {
        c[j]=decStr[n%10];
        n/=10;
        j--;

    } while (n!=0);
    if(j>=0)
    {
        for(int i=0; i<10-j; i++)
            c[i]=c[j+i+1];
    }
    return c;
} 
//6
static void __stack_chk_fail_local(){}

//7 returns Memory Volume, Mb
// static uint32_t getMem()
// {
//     uint32_t m=1, p=0x170000;
//     allMem[p]=0x1E;
//     while (allMem[p] == 0x1E)
//     {
//         p+=0x100000;
//         allMem[p]=0x1E;
//         m++;
//     }
//     return m;
// }

static uint32_t getMem()
{
    uint32_t m=1, p=0xF0000, step=0x10000,v=10;
    allMem[p]=0x1E;
    while (v>5)
    {
        v=0;
        for(int i=0;i<16;i++)
        {
            p+=step;
            allMem[p]=0x1E;
            if (allMem[p]==0x1E)v++;
        }
        if (v>5)m++;
    }
    availableMemoryMB=m;
    return m;
}

//8
static void incTimer()
{
    sysTimer++;
}

//9
static void delayST(uint32_t t)
{
    int destTime = sysTimer + t;
    while(sysTimer < destTime);
}

//10
static int hdd0Ready()
{
    int ready=0;
    __asm__("pusha\n\t"
            "movl $4,%%ebx\n\t"
            "movl $0xE0, %%eax\n\t"
            "movl $0x1F6, %%edx\n\t"
            "out %%al, %%dx\n\t"
            "movl $0x1F7, %%edx\n\t"
            "_busy:\n\t"
            "movl $0xFFFF, %%ecx\n\t"
            "_lp1:\n\t"
            "loop _lp1\n\t"
            "dec %%bx\n\t"
            "jz _stp\n\t"
            "in %%dx, %%al\n\t"
            "test $0b10001000, %%al\n\t"
            "jnz _busy\n\t"
            "test $0b01000000, %%al\n\t"
            "jz _busy\n\t"
            "movl $1, %0\n\t"
            "_stp:\n\t"
            "popa\n\t"
            :"=r"(ready)
            :
            :"cc");
    return ready;
} 
//11
static int readSector(uint32_t n, uint32_t number,
                            uint32_t bufAddr)
{
    int done=0;
    __asm__("pusha\n\t"
            "movl $0x3F6, %edx\n\t"
            "movl $2, %eax\n\t"
            "out %al, %dx\n\t");
    if(hdd0Ready())
    {
        __asm__("movl %[arg_a],%%ecx\n\t"
                "push %%ecx\n\t"
                "shr $24, %%ecx\n\t"
                "or $0xE0,%%cl\n\t"
                "movl $0x1F6, %%edx\n\t"
                "mov %%cl,%%al\n\t"
                "out %%al, %%dx\n\t"

                "pop %%eax\n\t"
                "movl $0x1F3, %%edx\n\t"
                "out %%al,%%dx\n\t"
                "shr $8, %%eax\n\t"
                "movl $0x1F4, %%edx\n\t"
                "out %%al,%%dx\n\t"
                "shr $8, %%eax\n\t"
                "movl $0x1F5, %%edx\n\t"
                "out %%al,%%dx\n\t"

                "movl %[arg_c], %%eax\n\t"
                "movl $0x1F2, %%edx\n\t"\
                "out %%al,%%dx\n\t"
                "mov $0xC4, %%al\n\t"
                "movl $0x1F7, %%edx\n\t"
                "out %%al,%%dx\n\t"

                "movl $0x3F6, %%edx\n\t"
                "_l0011:\n\t"
                "in %%dx, %%al\n\t"
                "test $0x80, %%al\n\t"
                "jnz _l0011\n\t"

                "movl $0x1F7, %%edx\n\t"
                "_l0021:\n\t"
                "in %%dx, %%al\n\t"
                "test $0x08, %%al\n\t"
                "jz _l0021\n\t"

                "push %%es\n\t"
                "movl $0x10, %%eax\n\t"
                "movw %%ax, %%es\n\t"
                "movl %[arg_b], %%edi\n\t"
                "cld\n\t"
                "movl %[arg_c],%%eax\n\t"
                "shl $8, %%eax\n\t"
                "movl %%eax, %%ecx\n\t"
                "movl $0x1F0, %%edx\n\t"
                "rep insw\n\t"

                "movl $0x3F6, %%edx\n\t"
                "movl $0, %%eax\n\t"
                "out %%al, %%dx\n\t"

                "pop %%es\n\t"
                "popa\n\t"
                :
                :[arg_a] "m"(n), [arg_b] "m"(bufAddr), [arg_c] "m"(number)
                :"cc");
        done=1;
    }   
    return done;     
}
//12
static void memCopy(uint32_t inAddr, uint32_t outAddr, uint32_t count)
{
    for(uint32_t i=0; i<count;i++)
        allMem[outAddr+i]=allMem[inAddr+i];
}
//13
static void fillMemZeros(uint32_t addr, uint32_t count)
{
    for(uint32_t i=0; i<count;i++)
        allMem[addr + i] = 0;
}
//14
static void readPT()
{
    readSector(0,1,BUFFER_ADDRESS);
    fillMemZeros(PT_ADDRESS,256);
    memCopy(BUFFER_ADDRESS+0x1BE,PT_ADDRESS,64);
}
//15
static void readFSInfo()
{
    fillMemZeros(FS_DATA_ADDRESS,1024);
    for(int i=0; i<16; i++)
    {
        uint32_t sN=PT[i].firstSector;
                    //(PT+i)->firstSector;
        if(sN>0){
            readSector(sN,1,BUFFER_ADDRESS);
            memCopy(BUFFER_ADDRESS+3,FS_DATA_ADDRESS+i*64,59);
        }
    }
}
//16
static int readRootDir(int driveN, uint32_t addr)
{
    int Done=0;
    uint32_t fstSect=FSInfo[driveN].hiddenSectorsN;
    fstSect+= FSInfo[driveN].resSect;
    fstSect+=FSInfo[driveN].FATN*FSInfo[driveN].sectPerFAT;
    int nn=FSInfo[driveN].descN>>4;
    Done=readSector(fstSect,nn, addr);
    return Done;
}

//17
static void memoryBitMapInit()
{
    uint32_t firstUnavailablePage=(availableMemoryMB*0x100000-FREE_MEM_BEGINS - 0x10000)>>12;
    uint32_t firstByte=firstUnavailablePage >> 3;
    uint32_t firstBit=firstUnavailablePage-(firstByte<<3);
    for(int i=0;i<firstByte;i++)
        allMem[MEMORY_BITMAP+i]=0;
    if(firstBit>0){
        uint8_t curByte=1;
        curByte<<=firstBit;
        for(int i=firstBit+1;i<8;i++)
            curByte = curByte | (curByte<<1);
          allMem[MEMORY_BITMAP+firstByte]=curByte;  
          firstByte++;
    }
    for(int i=firstByte;i<0x20000;i++)
        allMem[MEMORY_BITMAP+i]=0xFF;
}

//18
static uint32_t pageIsAvailable(uint32_t n)
{
    uint32_t byteN = n>>3;
    uint32_t bitN = n - (byteN<<3);
    uint8_t curByte = 1;
    curByte <<= bitN;
    uint8_t cc=allMem[MEMORY_BITMAP+byteN];
    uint32_t res = cc & curByte;
    if(res) return 0;
    else return 1;
}
//19
static void markPage(uint32_t n)
{
    uint32_t byteN = n>>3;
    uint32_t bitN = n - (byteN<<3);
    uint8_t curByte = 1;
    curByte <<= bitN;
    allMem[MEMORY_BITMAP+byteN] |=curByte;
}
//20
static uint32_t getFreeMemoryBlock(uint32_t memorySize)
{
    uint32_t pagesN = memorySize>>12;
    if((memorySize-pagesN<<12)>0)
        pagesN++;
    uint32_t n=0, fstPage=0,curPage;
    while(n<pagesN && fstPage<0x100000)
    {
        n=0;
        curPage=fstPage;
        while(n<pagesN && pageIsAvailable(curPage)&&curPage<0x100000){
            n++;
            curPage++;
        }
        if(n<pagesN)
            fstPage=curPage+1;
    }
    if(n<pagesN)
        return 0xFFFFFFFF;
    else{
        for(int i=0;i<pagesN;i++)
            markPage(fstPage+i);
        return fstPage;
    }    
}
//21
static void deleteMemoryBlock(uint32_t startPage, uint32_t memorySize)
{
    uint32_t pagesN = memorySize>>12;
    if((memorySize-pagesN<<12)>0)
        pagesN++;
    for(int i=0;i<pagesN;i++)
        freePage(startPage+i);
}
//22
static void freePage(uint32_t n)
{
    uint32_t byteN=n>>3;
    uint32_t bitN = n - (byteN<<3);
    uint8_t curByte=1;
    curByte <<= bitN;
    curByte = ~curByte;
    allMem[MEMORY_BITMAP+byteN]&=curByte;
}
//23
static uint32_t getPageAddress(uint32_t n)
{
    uint32_t addr=FREE_MEM_BEGINS+(n<<12);
    return addr;
}
//24
static int readCluster(uint32_t driveN, uint32_t clusterN, uint32_t addr)
{
    int Done=0;
    if(clusterN>1)
    {
        int sn=FSInfo[driveN].sectorsPerCluster;
      //int sn=(FSInfo+driveN)->sectorsPerCluster;
        int fs=FSInfo[driveN].hiddenSectorsN;
        fs+=FSInfo[driveN].resSect;
        fs+=FSInfo[driveN].FATN*FSInfo[driveN].sectPerFAT;
        fs+=FSInfo[driveN].descN>>4;
        fs+=(clusterN-2)*sn;
        Done=readSector(fs,sn,addr);
    }
    return Done;
}
//25
static int strlen(char *s)
{
    int i=0;
    while(s[i++]);
    return i-1;
}
//26
static int strcmp(char *s1, char *s2)
{
    int cmp=0;
    if(strlen(s1) && strlen(s2))
    {
        int i=0;
        while(s1[i] && s2[i])
        {
            if(s1[i]>s2[i])
            {
                cmp=1;
                break;
            }
            else if(s1[i]<s2[i])
            {
                cmp=-1;
                break;
            }
            i++;
        }
        if(cmp==0&&s1[i]==0&&s2[i]==0)
            return 0;
        else if(cmp==0&&s1[i]>0&&s2[i]==0)
            return 1;
        else if(cmp==0&&s1[i]==0&&s2[i]>0)
            return -1;
        else return cmp;
    }
    else if(strlen(s1)>0 && strlen(s2)==0)
        return 1;
    else if(strlen(s1)==0 && strlen(s2)>0)
        return -1;
    else return 0;
}
//27
static void loadFAT()
{
    uint32_t n=FSInfo[0].hiddenSectorsN+FSInfo[0].resSect;
    uint32_t sectors=FSInfo[0].sectPerFAT;
    readSector(n,sectors,FAT_ADDRESS);
}
//28
static FileDescriptorRecord getFileInDirDSC(FileDescriptorRecord dir,char *fn)
{
    FileDescriptorRecord fdr;
    fdr.fileName[0]=0;
    uint16_t *FAT=(uint16_t *)FAT_ADDRESS;
    FileDescriptorRecord *fd;
    uint32_t dirAddress=0,memSize=0,firstPage=0; 
    uint32_t clusterSize=FSInfo[0].sectorsPerCluster;
    clusterSize<<=9;
    char fn2[13];
    if(dir.clusterNLow==0){
        memSize=FSInfo[0].descN;
        memSize<<=5;
        firstPage=getFreeMemoryBlock(memSize);
        dirAddress=getPageAddress(firstPage);
        readRootDir(0,dirAddress);
        fd=(FileDescriptorRecord *)dirAddress;
        uint32_t nn=0;
        while(fd[nn].fileName[0]){
            print(fileNameDSCToStr(fn2,fd[nn].fileName));
            print(":");
            char s[13];
            print(uintToStr(s,strcmp(fileNameDSCToStr(fn2,fd[nn].fileName),fn)));
            print("; ");
            
            if(strcmp(fileNameDSCToStr(fn2,fd[nn].fileName),fn)==0)
            {
                fdr=fd[nn];
                
                
                //fdr.clusterNLow=fd[nn].clusterNLow;
                return fdr;
            }
            nn++;
        }
        deleteMemoryBlock(firstPage,memSize);
    }
    else
    {
        uint16_t nCl=dir.clusterNLow;
        uint16_t nextCluster=FAT[nCl];
        firstPage=getFreeMemoryBlock(clusterSize);
        dirAddress=getPageAddress(firstPage);
        while(1)
        {
            readCluster(0,nCl,dirAddress);
            fd=(FileDescriptorRecord *)dirAddress;
            uint32_t nn=0;
            while(fd[nn].fileName[0]){
                if(strcmp(fileNameDSCToStr(fn2,fd[nn].fileName),fn)==0)
                {
                    fdr=fd[nn];
                    return fdr;
                }
                nn++;
            }
            if(nextCluster==0xFFFF)
                break;
            else
            {
                nCl=nextCluster;
                nextCluster=FAT[nCl];
            }
        }
        deleteMemoryBlock(firstPage,clusterSize);
    }
    return fdr;
}
//29
static char *fileNameDSCToStr(char *stdStr,char *dscStr)
{
    int n=0;
    for(int i=0;i<8;i++){
        if(isCorrectSymbol(dscStr[i]))
        {
            stdStr[n]=dscStr[i];
            n++;
        }
    }
    if(isCorrectSymbol(dscStr[8]))
    {
        stdStr[n++]='.';
        for(int i=8;i<11;i++){
            if(isCorrectSymbol(dscStr[i]))
            {
                stdStr[n]=dscStr[i];
                n++;
            }
        }        
    }
    stdStr[n]=0;
    return stdStr;
}
//30
static int isCorrectSymbol(char s)
{
    int isCorrect=0, i=0;
    char correctSymbols[]="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$@&()^_~`{}";
    while(correctSymbols[i])
    {
        if(correctSymbols[i]==s)
        {
            isCorrect=1;
            break;
        }
        i++;
    }
    return isCorrect;
}
