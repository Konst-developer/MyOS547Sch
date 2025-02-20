fn=kernel
gcc -O0 -m32 -DSTDC_HEADERS -c $fn.c
nm -n $fn.o > $fn.txt
./getfntable $fn.txt $fn.ftb
sudo cat /home/sysprog/share/kernel24 $fn.ftb > kernel.temp
fsz=$(wc -c "./kernel.temp" | awk '{print $1}')
ld -m elf_i386  -Ttext $fsz -e _start $fn.o -o $fn.img
objcopy -O binary -R .comment -S $fn.img $fn.bin
sudo cat ./kernel.temp $fn.bin > krnl24
cp -rf ./krnl24 /home/sysprog/share
cp -rf ./kernel.c /home/sysprog/share
cp -rf ./getfntable /home/sysprog/share
cp -rf ./getfntable.cpp /home/sysprog/share
cp -rf ./sys.sh /home/sysprog/share
ndisasm -b 32 $fn.bin > $fn.lst
cp -rf ./$fn.lst /home/sysprog/share
rm -f ./kernel.temp
rm -f ./$fn.txt
rm -f ./$fn.ftb
