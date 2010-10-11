#FIXME: clean this up

DMD=dmd
DMDFLAGS=-w -debug -gc -unittest -D
INCS=-Ivendor
SRC=$(wildcard *.d)
EXE=vlad

####################################

all: json.o
	$(DMD) $(SRC) $(INCS) $(DMDFlAGS) vendor/libdjson/json.o -of$(EXE)

json.o:
	@cd vendor/libdjson && $(DMD) -c json.d
