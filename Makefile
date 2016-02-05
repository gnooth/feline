ifeq ($(OS),Windows_NT)
	FELINE_EXE = feline.exe
else
	FELINE_EXE = feline
endif

all:
	cd src && $(MAKE)

clean:
	-rm -f feline feline.exe build
	cd src && $(MAKE) clean
