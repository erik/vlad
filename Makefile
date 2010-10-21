#FIXME: clean this up

DMD=dmd
DMDFLAGS=-w -debug -gc -unittest
INCS=-Ivendor
SRC=$(wildcard src/*.d)
EXE=vlad

####################################

all: json.o
	$(DMD) $(SRC) $(INCS) $(DMDFLAGS) vendor/libdjson/json.o -of$(EXE)

json.o:
	@cd vendor/libdjson && $(DMD) -c json.d

clean:
	rm $(EXE) vlad.o vendor/libdjson/json.o
