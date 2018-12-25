# Tue 13:48 March 21

CFLAGS = -fPIC -O3 -Wall -std=c99 -pedantic
CFLAGS += -I../skynet/3rd/lua
CPPFLAGS = -g -fPIC -Wall -std=c++0x
CPPFLAGS += -I../skynet/3rd/lua
LFLAGS = -shared -llua -L../skynet/3rd/lua/

INOTIFY_SO  = ../luaclib/inotify.so
LUASOCKET_SO = ../luaclib/socket.so
SKIPLIST_SO = ../luaclib/skiplist.so
CJSON_SO = ../luaclib/cjson.so
ZLIB_SO = ../luaclib/zlib.so

all: $(LUASOCKET_SO) $(SKIPLIST_SO) \
    $(CJSON_SO) $(ZLIB_SO)

$(LUASOCKET_SO) : ./luasocket
	PLAT=linux DEBUG=NODEBUG LUAV=5.3 LUAINC_linux=../../../skynet/3rd/lua $(MAKE) -C ./luasocket
	cp -f ./luasocket/src/socket-3.0-rc1.so $@
	cp -f ./luasocket/src/mime-1.0.3.so ../luaclib/mime.so

$(INOTIFY_SO): linotify.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $<

$(SKIPLIST_SO): ./skiplist/skiplist.h ./skiplist/skiplist.c ./skiplist/lua-skiplist.c
	$(CC) $(LFLAGS) $(CFLAGS)  -I./skiplis $^ -o $@

$(CJSON_SO):
	@cd ./lua-cjson-2.1.0/ && $(MAKE)
	cp ./lua-cjson-2.1.0/cjson.so $@

$(LUACURL_SO): luacurl.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $<

$(ZLIB_SO): lua_zlib.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $<

clean:
	$(RM) $(PROTOBUF_SO) $(LUASOCKET_SO) $(SKIPLIST_SO) $(PROTOBUF_REG) \
	$(CJSON_SO) $(WEBCLIENT_SO) ../luaclib/mime.so $(ZLIB_SO)

.PHONY: all clean
