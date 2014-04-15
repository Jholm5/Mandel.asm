Mandel.asm
==========

This is a MandelBrot program built in assembly language. It still needs color blending to be complete. 


This program needs to run in Terminal in linux with the following commands done. 

nasm -f elf64 -g -F dwarf mandel.asm        # assembles the program
ld -g -o mandel mandel.o                    # links the program to the file
./mandel                                    # run's the program

You will get a Fractal.ppm built in the folder you saved the mandel.asm
