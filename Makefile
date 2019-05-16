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

all : smw/smw.elf smw/leveledit.elf

COMMON_OBJS:=build/MapList.o build/SFont.o build/dirlist.o \
           build/eyecandy.o build/gfx.o build/global.o build/input.o \
           build/map.o build/movingplatform.o build/path.o \
           build/savepng.o \
	   build/linfunc.o \
	   build/wiz.o
SMW_OBJS:= build/HashTable.o build/ai.o build/gamemodes.o build/main.o \
           build/map.o build/menu.o build/object.o build/player.o \
           build/sfx.o build/splash.o build/uicontrol.o build/uimenu.o
LEVELEDIT_OBJS:=build/leveleditor.o

#include configuration
#here because of one .c file among a .cpp project (o_O)

build/%.o : _src/%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $<

smw/smw.elf : $(COMMON_OBJS) $(SMW_OBJS)
	$(CXX) $(CFLAGS) $^ $(LDFLAGS) -o $@

smw/leveledit.elf : $(COMMON_OBJS) $(LEVELEDIT_OBJS)
	$(CXX) $(CFLAGS) $^ $(LDFLAGS) -o $@

build/SFont.o : _src/SFont.c
	$(CC) $(CFLAGS) -o $@ -c $<

build/SDLMain.o : macosx/SDLMain.m
	$(CC) $(CFLAGS) -o $@ -c $<

Super\ Mario\ War.app : smw
	mkdir -p '$@/Contents/Resources' 
	mkdir -p '$@/Contents/MacOS'
	mkdir -p '$@/Contents/Frameworks'
	cp -r /Library/Frameworks/SDL.framework \
		/Library/Frameworks/SDL_image.framework \
		/Library/Frameworks/SDL_net.framework \
		/Library/Frameworks/SDL_mixer.framework \
		'$@/Contents/Frameworks/'
	cp smw '$@/Contents/MacOS/Super Mario War'
	cp macosx/Info.plist '$@/Contents/'
	echo -n 'APPL????' > '$@/Contents/PkgInfo'
	cp -r macosx/smw.icns gfx maps music sfx tours \
		'$@/Contents/Resources/'

ipk: all
	@rm -rf /tmp/.smw-ipk/ && mkdir -p /tmp/.smw-ipk/root/home/retrofw/games/smw /tmp/.smw-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r smw/smw.elf smw/smw.png smw/data smw/filters smw/.smw.options.bin smw/Scripts /tmp/.smw-ipk/root/home/retrofw/games/smw
	@cp smw/smw.lnk /tmp/.smw-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" smw/control > /tmp/.smw-ipk/control
	@cp smw/conffiles /tmp/.smw-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.smw-ipk/control.tar.gz -C /tmp/.smw-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.smw-ipk/data.tar.gz -C /tmp/.smw-ipk/root/ .
	@echo 2.0 > /tmp/.smw-ipk/debian-binary
	@ar r smw/smw.ipk /tmp/.smw-ipk/control.tar.gz /tmp/.smw-ipk/data.tar.gz /tmp/.smw-ipk/debian-binary

appbundle : Super\ Mario\ War.app

install : install-data install-bin install-leveledit

install-data : all
	mkdir -p $(DESTDIR)/usr/share/smw/
	cp -ravx sfx $(DESTDIR)/usr/share/smw/
	cp -ravx gfx $(DESTDIR)/usr/share/smw/
	cp -ravx music $(DESTDIR)/usr/share/smw/
	cp -ravx maps $(DESTDIR)/usr/share/smw/
	cp -ravx tours $(DESTDIR)/usr/share/smw/
	rm -rf $(DESTDIR)/usr/share/smw/*/.svn
	rm -rf $(DESTDIR)/usr/share/smw/*/*/.svn
	rm -rf $(DESTDIR)/usr/share/smw/*/*/*/.svn
	rm -rf $(DESTDIR)/usr/share/smw/*/*/*/*/.svn
	chmod a+w $(DESTDIR)/usr/share/smw/maps -R

install-bin : all
	#assume DESTDIR is the prefix for installing
	mkdir -p $(DESTDIR)/usr/bin/
	cp smw $(DESTDIR)/usr/bin/

install-leveledit : all
	mkdir -p $(DESTDIR)/usr/bin/
	cp leveledit $(DESTDIR)/usr/bin/smw-leveledit

clean :
	rm -rf build/*
	rm -f smw
	rm -f leveledit
	rm -f smw.exe
	rm -f leveledit.exe
	rm -f options.bin
	rm -rf 'Super Mario War.app'

dpkg :
	rm -f ~/src/*.dsc
	rm -f ~/src/*.diff.gz
	rm -f ~/src/*.deb
	rm -f ~/src/*.changes
	cvs-buildpackage -W ~/src -UHEAD -THEAD -rfakeroot
	sudo reprepro -b /webroot/apt include sid $(HOME)/src/*.changes
