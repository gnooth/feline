ifeq ($(OS),Windows_NT)
	FELINE_EXE = feline.exe
else
	FELINE_EXE = feline
endif

all: FELINE_EXE

FELINE_EXE: ./gmp/.libs/libgmp.a
	cd src && $(MAKE)

./gmp/.libs/libgmp.a:
	if [ ! -f gmp/Makefile ]; then \
	  cd gmp && ./configure; \
	fi
	cd gmp && $(MAKE)

clean:
	-rm -f feline feline.exe build
	if [ -f gmp/Makefile ]; then \
	  cd gmp && $(MAKE) clean; \
	fi
	cd src && $(MAKE) clean
