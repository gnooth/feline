ifeq ($(OS),Windows_NT)
	FELINE_EXE = feline.exe
else
	FELINE_EXE = feline
endif

all: $(FELINE_EXE)

$(FELINE_EXE):
	cd src && $(MAKE) ../$(FELINE_EXE)

clean:
	-rm -f feline feline.exe build
	cd src && $(MAKE) clean
