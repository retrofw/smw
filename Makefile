CHAINPREFIX := /opt/mipsel-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC = $(CROSS_COMPILE)gcc
CXX = $(CROSS_COMPILE)g++
STRIP = $(CROSS_COMPILE)strip

SYSROOT     := $(shell $(CC) --print-sysroot)
SDL_CFLAGS  := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS    := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

CFLAGS=-Ofast -mplt -Wall -I. -DLINUXFUNC -DPREFIXPATH=\"data\" $(SDL_CFLAGS)
LDFLAGS=-lSDL -lSDL_image -lSDL_mixer -lpng -lz -flto -s $(SDL_LIBS)

COMMON_OBJS:=/tmp/smw/MapList.o /tmp/smw/SFont.o /tmp/smw/dirlist.o \
           /tmp/smw/eyecandy.o /tmp/smw/gfx.o /tmp/smw/global.o /tmp/smw/input.o \
           /tmp/smw/map.o /tmp/smw/movingplatform.o /tmp/smw/path.o \
           /tmp/smw/savepng.o \
	   /tmp/smw/linfunc.o \
	   /tmp/smw/wiz.o
SMW_OBJS:= /tmp/smw/HashTable.o /tmp/smw/ai.o /tmp/smw/gamemodes.o /tmp/smw/main.o \
           /tmp/smw/map.o /tmp/smw/menu.o /tmp/smw/object.o /tmp/smw/player.o \
           /tmp/smw/sfx.o /tmp/smw/splash.o /tmp/smw/uicontrol.o /tmp/smw/uimenu.o
LEVELEDIT_OBJS:=/tmp/smw/leveleditor.o

#include configuration
#here because of one .c file among a .cpp project (o_O)
all: smw/smw.dge smw/leveledit.dge

/tmp/smw/%.o : src/%.cpp
	mkdir -p /tmp/smw
	$(CXX) $(CFLAGS) -o $@ -c $<

smw/smw.dge : $(COMMON_OBJS) $(SMW_OBJS)
	mkdir -p /tmp/smw
	$(CXX) $(CFLAGS) $^ $(LDFLAGS) -o $@

smw/leveledit.dge : $(COMMON_OBJS) $(LEVELEDIT_OBJS)
	mkdir -p /tmp/smw
	$(CXX) $(CFLAGS) $^ $(LDFLAGS) -o $@

/tmp/smw/SFont.o : src/SFont.c
	$(CC) $(CFLAGS) -o $@ -c $<

/tmp/smw/SDLMain.o : macosx/SDLMain.m
	$(CC) $(CFLAGS) -o $@ -c $<

clean :
	rm -rf /tmp/smw/* \
	smw/smw.dge \
	smw/leveledit.dge \
	options.bin \
	'Super Mario War.app'

ipk: all
	@rm -rf /tmp/.smw-ipk/ && mkdir -p /tmp/.smw-ipk/root/home/retrofw/games/smw /tmp/.smw-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r smw/smw.dge smw/smw.png smw/data smw/filters smw/.smw.options.bin smw/Scripts /tmp/.smw-ipk/root/home/retrofw/games/smw
	@cp smw/smw.lnk /tmp/.smw-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" smw/control > /tmp/.smw-ipk/control
	@cp smw/conffiles /tmp/.smw-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.smw-ipk/control.tar.gz -C /tmp/.smw-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.smw-ipk/data.tar.gz -C /tmp/.smw-ipk/root/ .
	@echo 2.0 > /tmp/.smw-ipk/debian-binary
	@ar r smw/smw.ipk /tmp/.smw-ipk/control.tar.gz /tmp/.smw-ipk/data.tar.gz /tmp/.smw-ipk/debian-binary

opk: all
	@mksquashfs \
	smw/default.retrofw.desktop \
	smw/smw.dge \
	smw/smw.png \
	smw/data \
	smw/filters \
	smw/.smw.options.bin \
	smw/Scripts \
	smw/smw.opk \
	-all-root -noappend -no-exports -no-xattrs
