#FIXME: clean this up

DMD=dmd
DMDFLAGS=-w -debug -gc -unittest -D
SRC=$(wildcard *.d)
EXE=vlad

####################################

all:
	$(DMD) $(SRC) $(DMDFlAGS) -of$(EXE)

