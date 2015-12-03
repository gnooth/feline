# On Windows, to build with the experimental Windows UI (not recommended):
#
#       make WINDOWS_UI=1
#
# Otherwise just:
#
#       make
#
# should do it, on both Windows and Linux.

# Tested with gcc 5.2.1 and clang 3.6.2 on Linux (Ubuntu).
# Tested with gcc (tdm64-1) 5.1.0 on Windows 10.
# NASM 2.11.08 on Windows, 2.11.05 on Linux.
# No support in this makefile for Microsoft tools.
CC = gcc

CFLAGS = --std=c99 -D_GNU_SOURCE -g -m64
ASMFLAGS =
LINKFLAGS = -m64

OBJS = main.o os.o terminal.o forth.o

ifeq ($(OS),Windows_NT)
	CFLAGS += -DWIN64 -DWIN64_NATIVE
	ASMFLAGS += -DWIN64 -DWIN64_NATIVE
	FORTH_EXE = forth.exe
	FORTH_HOME_EXE = forth_home.exe
else
	FORTH_EXE = forth
	FORTH_HOME_EXE = forth_home
endif

ifeq ($(OS),Windows_NT)
ifdef WINDOWS_UI
	CFLAGS += -DWINDOWS_UI
	ASMFLAGS += -DWINDOWS_UI
	LINKFLAGS += -mwindows
	OBJS += windows-ui.o winkey.o
endif
endif

$(FORTH_EXE):  $(OBJS)
	$(CC) $(LINKFLAGS) $(OBJS) -o forth

forth_home.asm: $(FORTH_HOME_EXE)
	./forth_home

$(FORTH_HOME_EXE): forth_home.c
	$(CC) forth_home.c -o forth_home

main.o:	forth.h windows-ui.h main.c Makefile
	$(CC) $(CFLAGS) -c -o main.o main.c

os.o:	forth.h os.c Makefile
	$(CC) $(CFLAGS) -c -o os.o os.c

terminal.o: forth.h windows-ui.h terminal.c Makefile
	$(CC) $(CFLAGS) -c -o terminal.o terminal.c

windows-ui.o: forth.h windows-ui.h windows-ui.c Makefile
	$(CC) $(CFLAGS) -c -o windows-ui.o windows-ui.c

winkey.o: forth.h windows-ui.h winkey.c Makefile
	$(CC) $(CFLAGS) -c -o winkey.o winkey.c

ASM_SOURCES = forth.asm forth_home.asm equates.asm macros.asm inlines.asm \
	align.asm \
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
	exceptions.asm \
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
	optimizer.asm \
	parse.asm \
	quit.asm \
	stack.asm \
	store.asm \
	string.asm \
	strings.asm \
	tools.asm \
	value.asm

# -felf64 even on Windows
forth.o: $(ASM_SOURCES) Makefile
	nasm $(ASMFLAGS) -g -felf64 forth.asm

# Microsoft compiler and linker
# main.obj: main.c
# 	cl -Zi -c $(CFLAGS) main.c

# forth.obj: $(ASM_SOURCES)
# 	nasm $(ASMFLAGS) -g -fwin64 forth.asm

# forth.exe: main.obj forth.obj
# 	link /subsystem:console /machine:x64 /largeaddressaware:no forth.obj  main.obj /out:forth.exe

clean:
	-rm -f forth
	-rm -f forth.exe
	-rm -f main.o*
	-rm -f os.o*
	-rm -f terminal.o*
	-rm -f forth.o*
	-rm -f forth_home.asm forth_home.exe forth_home

zip:
	-rm -f forth.zip
	zip forth.zip *.c *.h *.asm *.forth tests/*.forth Makefile
