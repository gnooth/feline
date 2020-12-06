# If you have the right tools installed (see below), just:
#
#	make
#
# should do it, on both Windows and Linux.

# Tested with GNU Make 4.0, gcc 5.2.1 and clang 3.6.2 on Linux (Ubuntu).
# Tested with GNU Make 4.1, gcc 5.4.0 and clang 3.8.0 on Linux (Ubuntu).
# Tested with GNU Make 4.1, gcc 6.2.0 and clang 3.8.1 on Linux (Ubuntu 16.10).

# Tested with GNU Make 3.81, gcc (tdm64-1) 5.1.0 and clang 3.7.1 on Windows 10.

# NASM 2.11.08 on both Windows and Linux.
# NASM 2.12.01 on Linux.

# There is no support in this makefile for Microsoft tools.

REPOSITORY_VERSION = `git describe --dirty=*`

BUILD = `date`

ifeq ($(OS),Windows_NT)
	CC = gcc
else
#	CC = clang
	CC = gcc -no-pie
endif

CFLAGS = -std=c99 -D_GNU_SOURCE -g -m64
ASMFLAGS =

# gcc
# gcc 6.2.0 on Ubuntu 16.10 needs -no-pie
# LINKFLAGS = -m64 -no-pie

OBJS = main.o os.o terminal.o backtrace.o random.o numbers.o math.o \
	socket.o version.o feline.o

ifeq ($(OS),Windows_NT)
ifdef WINUI
	OBJS += winui.o
	ASMFLAGS += -DWINUI
endif
else
# Linux
ifdef GTKUI
	OBJS += gtkui.o
	ASMFLAGS += -DGTKUI

	PKGCONFIG = $(shell which pkg-config)
	GTK_CFLAGS = $(shell $(PKGCONFIG) --cflags gtk+-3.0)
	GTK_LIBS = $(shell $(PKGCONFIG) --libs gtk+-3.0)
endif
endif

ifeq ($(OS),Windows_NT)
	CFLAGS += -DWIN64
	ASMFLAGS += -DWIN64
	FELINE_EXE = ../feline.exe
	FELINE_HOME_EXE = feline_home.exe
else
	FELINE_EXE = ../feline
	FELINE_HOME_EXE = feline_home
endif

ifdef DEBUG
	ASMFLAGS += -DDEBUG
else
	CFLAGS += -O1
endif

ifeq ($(OS),Windows_NT)
ifdef WINUI
$(FELINE_EXE): version.h $(OBJS)
	$(CC) $(LINKFLAGS) $(OBJS) -lm -l gdi32 -l user32 -l ws2_32 -o $(FELINE_EXE)
else
$(FELINE_EXE): version.h $(OBJS)
	$(CC) $(LINKFLAGS) $(OBJS) -lm -l ws2_32 -o $(FELINE_EXE)
endif
else
# Linux
ifdef GTKUI
$(FELINE_EXE): version.h $(OBJS)
	$(CC) $(LINKFLAGS) $(OBJS) -lm -lpthread $(GTK_LIBS) -o $(FELINE_EXE)
else
$(FELINE_EXE): version.h $(OBJS)
	$(CC) $(LINKFLAGS) $(OBJS) -lm -lpthread -o $(FELINE_EXE)
endif
endif

feline_home.asm: $(FELINE_HOME_EXE)
	./feline_home

$(FELINE_HOME_EXE): feline_home.c
	$(CC) feline_home.c -o $(FELINE_HOME_EXE)

.PHONY: version.h
version.h: version.h.in
	cp version.h.in version.h
	echo "#define REPOSITORY_VERSION \"$(REPOSITORY_VERSION)\"" >> version.h
	echo "#define BUILD \"$(BUILD)\"" >> version.h

main.o: feline.h main.c
	$(CC) $(CFLAGS) -c -o main.o main.c

os.o:	feline.h os.c
	$(CC) $(CFLAGS) -c -o os.o os.c

terminal.o: feline.h terminal.c
	$(CC) $(CFLAGS) -c -o terminal.o terminal.c

backtrace.o: feline.h backtrace.c
	$(CC) $(CFLAGS) -c -o backtrace.o backtrace.c

random.o: random.c
	$(CC) $(CFLAGS) -c -o random.o random.c

numbers.o: feline.h numbers.c
	$(CC) $(CFLAGS) -c -o numbers.o numbers.c

math.o: feline.h math.c
	$(CC) $(CFLAGS) -c -o math.o math.c

socket.o: feline.h socket.c
	$(CC) $(CFLAGS) -c -o socket.o socket.c

version.o: version.h
	$(CC) $(CFLAGS) -c -o version.o version.c

gtkui.o: gtkui.c
	$(CC) $(CFLAGS) $(GTK_CFLAGS) -c -o gtkui.o gtkui.c

winui.o: winui.c
	$(CC) $(CFLAGS) $(GTK_CFLAGS) -c -o winui.o winui.c

ASM_SOURCES = feline.asm feline_home.asm externs.asm \
	macros.asm loop-macros.asm inlines.asm \
	ansi.asm \
	array.asm \
	assert.asm \
	bit-array.asm \
	bitops.asm \
	boolean.asm \
	byte-vector.asm \
	cold.asm \
	color.asm \
	combinators.asm \
	compile-word.asm \
	debug.asm \
	defer.asm \
	dynamic-scope.asm \
	equal-hashtable.asm \
	errors.asm \
	file-output-stream.asm \
	files.asm \
	fixnum-hashtable.asm \
	fixnum.asm \
	float.asm \
	format.asm \
	gc2.asm \
	generic.asm \
	handles.asm \
	hashtable.asm \
	io.asm \
	iterator.asm \
	key.asm \
	keyword.asm \
	lexer.asm \
	load.asm \
	locals.asm \
	math.asm \
	memory.asm \
	method.asm \
	move.asm \
	mutex.asm \
	numbers.asm \
	object-macros.asm \
	objects.asm \
	syntax.asm \
	primitives.asm \
	quit.asm \
	quotation.asm \
	range.asm \
	recover.asm \
	sequences.asm \
	sbuf.asm \
	slice.asm \
	slot.asm \
	socket.asm \
	stack.asm \
	stream.asm \
	string-iterator.asm \
	string-output-stream.asm \
	string.asm \
	string-slice.asm \
	symbol.asm \
	thread.asm \
	time.asm \
	tools.asm \
	tuple.asm \
	type.asm \
	uint64.asm \
	int64.asm \
	vocab.asm \
	vocabs.asm \
	vector.asm \
	wrapper.asm \
	xalloc.asm

ifeq ($(OS),Windows_NT)

ifdef WINUI
	ASM_SOURCES += winui.asm
endif

else

ifdef GTKUI
	ASM_SOURCES += gtkui.asm
endif

endif

# -felf64 even on Windows
feline.o: $(ASM_SOURCES)
	nasm $(ASMFLAGS) -g -felf64 feline.asm

# Microsoft compiler and linker
# main.obj: main.c
#	cl -Zi -c $(CFLAGS) main.c

# feline.obj: $(ASM_SOURCES)
#	nasm $(ASMFLAGS) -g -fwin64 feline.asm

# feline.exe: main.obj feline.obj
#	link /subsystem:console /machine:x64 /largeaddressaware:no feline.obj  main.obj /out:feline.exe

clean:
	-rm -f *.o *.obj
	-rm -f feline_home.asm feline_home.exe feline_home
	-rm -f version.h
