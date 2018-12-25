PLAT ?= linux

.PHONY: all help server client deps skynet

all : deps skynet busilogger

termfxso=luaclib/termfx.so

busilogger: lualib-src/service_busilogger.c luaclib
	gcc -fPIC --shared -g -O2 -Wall  $< -o luaclib/busilogger.so -I./skynet/skynet-src

skynet:
	cd skynet && make linux

deps: 
	@cd lualib-src && $(MAKE)


