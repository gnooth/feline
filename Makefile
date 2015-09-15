# To build with gcc (even on Windows):
#    make forth

# To build on Windows with the Microsoft compiler and linker:
#    make forth.exe

FLAGS =

ifeq ($(OS),Windows_NT)
	FLAGS += -DWIN64 -DWIN64_NATIVE
endif

forth:  forth_home.h main.o terminal.o forth.o
	gcc main.o terminal.o forth.o -o forth

forth_home.h: forth_home
	./forth_home

forth_home: forth_home.c
	gcc forth_home.c -o forth_home

main.o:	forth.h main.c Makefile
	gcc -D_GNU_SOURCE $(FLAGS) -c -o main.o main.c

terminal.o: forth.h terminal.c Makefile
	gcc -D_GNU_SOURCE $(FLAGS) -c -o terminal.o terminal.c

ASM_SOURCES = forth.asm equates.asm macros.asm inlines.asm \
	ansi.asm \
	arith.asm \
	branch.asm \
	bye.asm \
	cold.asm \
	compiler.asm \
	constants.asm \
	dictionary.asm \
	dot.asm \
	double.asm \
	execute.asm \
	fetch.asm \
	find.asm \
	include.asm \
	interpret.asm \
	io.asm \
	locals.asm \
	loop.asm \
	memory.asm \
	number.asm \
	parse.asm \
	quit.asm \
	stack.asm \
	store.asm \
	strings.asm \
	tools.asm \
	value.asm

forth.o: $(ASM_SOURCES)
	nasm $(FLAGS) -g -felf64 forth.asm	# -felf64 even on Windows

# Microsoft compiler and linker
main.obj: main.c
	cl -Zi -c $(FLAGS) main.c

forth.obj: $(ASM_SOURCES)
	nasm $(FLAGS) -g -fwin64 forth.asm

forth.exe: main.obj forth.obj
	link /subsystem:console /machine:x64 /largeaddressaware:no forth.obj  main.obj /out:forth.exe

clean:
	-rm -f forth
	-rm -f forth.exe
	-rm -f main.o*
	-rm -f terminal.o*
	-rm -f forth.o*
	-rm -f forth_home.h forth_home.exe forth_home

zip:
	-rm -f forth.zip
	zip forth.zip *.c *.asm *.forth tests/*.forth Makefile
