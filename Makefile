DMD=dmd

DMDFLAGS=-w -debug -gc -unittest
INCS=-Ivendor 

LIBLUA=vendor/lua/liblua5.1.a
LIBJSON=vendor/libdjson/json.o
LIBLUAD=vendor/luad/luad.o

LIBS=$(LIBLUA) $(LIBLUAD) $(LIBJSON)

SRC=$(wildcard src/vlad/*.d)
OBJ=$(SRC:.d=.o)

#required for Lua library (on Linux, at least; not portable)
LNFLAGS=-L/usr/lib/libdl.so

EXE=vlad

.SUFFIXES: .d .o

####################################

all: $(OBJ) json luad
	@echo "Linking..."
	@$(DMD) $(OBJ) $(INCS) $(LNFLAGS) $(DMDFLAGS) $(LIBS) -of$(EXE)

src/vlad/irc.o: src/vlad/irc.d
src/vlad/bot.o: src/vlad/bot.d src/vlad/irc.d
src/vlad/commands.o: src/vlad/commands.d src/vlad/config.d src/vlad/bot.d
src/vlad/config.o: src/vlad/config.d
src/vlad/main.o: src/vlad/main.d src/vlad/bot.d src/vlad/config.d \
src/vlad/commands.d src/vlad/lua.d
src/vlad/lua.o: src/vlad/lua.d src/vlad/irc.d src/vlad/bot.d src/vlad/config.d

.d.o:
	@echo "   dmd $<"
	@$(DMD) -c $(INCS) -Isrc $< -of$@

##### JSON

json: vendor/libdjson/json.o

vendor/libdjson/json.o: vendor/libdjson/json.d
	@echo "Building libdjson..."
	@cd vendor/libdjson && $(DMD) -c json.d

##### Lua
LUADSRC=$(wildcard vendor/luad/*.d) $(wildcard vendor/luad/c/*.d) \
$(wildcard vendor/luad/conversions/*.d)

luad: vendor/luad/luad.o

vendor/luad/luad.o: $(LUADSRC)
	@echo "Building LuaD..."
	@$(DMD) -c $(LUADSRC) $(LIBLUA) -of$(LIBLUAD)

##### 

clean:
	rm -f $(EXE) $(OBJ) 

distclean: clean
	rm -f $(LIBJSON) $(LIBLUAD)

rebuild: clean all

loc:
	@find src -type f -name "*.d" | xargs wc -l
	
.PHONY=clean distclean loc
