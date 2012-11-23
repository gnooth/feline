# To build with gcc (even on Windows):
#    make forth

# To build on Windows with the Microsoft compiler and linker:
#    make forth.exe

uname_s := $(shell sh -c 'uname -s 2>/dev/null || echo not')

FLAGS =

ifneq (,$(findstring MINGW,$(uname_s)))
	FLAGS += -DWIN64
endif

forth:  main.o forth.o
	gcc main.o forth.o -o forth

main.o:	main.c Makefile
	gcc $(FLAGS) -c -o main.o main.c

ASM_SOURCES = forth.asm equates.asm macros.asm \
	arith.asm \
	branch.asm \
	bye.asm \
	cold.asm \
	constants.asm \
	dictionary.asm \
	dot.asm \
	execute.asm \
	fetch.asm \
	find.asm \
	include.asm \
	interpret.asm \
	io.asm \
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
	-rm -f forth.o*

zip:
	-rm -f forth.zip
	zip forth.zip *.c *.asm *.forth Makefile
