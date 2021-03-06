UV_DIR    = libuv-v1.9.1
UV_FILE   = $(UV_DIR).tar.gz
UV_URL    = http://dist.libuv.org/dist/v1.9.1/$(UV_FILE)
	 

all:
	ruby ./rebuild-fcache.rb
	cd deps/nanovg/src   && $(CC) nanovg.c -c -fPIC
	$(AR) rc deps/libnanovg.a deps/nanovg/src/*.o
	cd deps/pugl         && ./waf configure --no-cairo --static
#	cd deps/pugl         && ./waf configure --no-cairo --static --debug
	cd deps/pugl         && ./waf
	cd src/osc-bridge    && CFLAGS="-I ../../deps/libuv-v1.9.1/include " make lib
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake
	$(CC) -shared -o libzest.so `find mruby/build/host -type f | grep -e "\.o$$" | grep -v bin` ./deps/libnanovg.a \
		./deps/libnanovg.a \
		src/osc-bridge/libosc-bridge.a \
		./deps/libuv-v1.9.1/.libs/libuv.a  -lm -lX11 -lGL -lpthread
	$(CC) test-libversion.c deps/pugl/build/libpugl-0.a -ldl -o zest -lX11 -lGL -lpthread -I deps/pugl -std=gnu99

windows:
	cd deps/nanovg/src   && $(CC) -mstackrealign nanovg.c -c
	$(AR) rc deps/libnanovg.a deps/nanovg/src/*.o
	cd deps/pugl         && CFLAGS="-mstackrealign" ./waf configure --no-cairo --static --target=win32
	cd deps/pugl         && ./waf
	cd src/osc-bridge    && CFLAGS="-mstackrealign -I ../../deps/libuv-v1.9.1/include " make lib
	cd mruby             && WINDOWS=1 MRUBY_CONFIG=../build_config.rb rake
	$(CC) -mstackrealign -shared -o libzest.dll -static-libgcc `find mruby/build/w64 -type f | grep -e "\.o$$" | grep -v bin` \
        ./deps/libnanovg.a \
        src/osc-bridge/libosc-bridge.a \
        ./deps/libuv-v1.9.1/.libs/libuv.a \
        -lm -lpthread -lws2_32 -lkernel32 -lpsapi -luserenv -liphlpapi -lglu32 -lgdi32 -lopengl32
	$(CC) -mstackrealign -DWIN32 test-libversion.c deps/pugl/build/libpugl-0.a -o zest.exe -lpthread -I deps/pugl -std=c99 -lws2_32 -lkernel32 -lpsapi -luserenv -liphlpapi -lglu32 -lgdi32 -lopengl32


builddep:
	cd deps/$(UV_DIR)    && ./autogen.sh
	cd deps/$(UV_DIR)    && CFLAGS=-fPIC ./configure
	cd deps/$(UV_DIR)    && CFLAGS=-fPIC make
	cp deps/$(UV_DIR)/.libs/libuv.a deps/

builddepwin:
	cd deps/$(UV_DIR)   && ./autogen.sh
	cd deps/$(UV_DIR)   && CFLAGS="-mstackrealign" ./configure  --host=x86_64-w64-mingw32
	cd deps/$(UV_DIR)   && LD=x86_64-w64-mingw32-gcc make
	cp deps/$(UV_DIR)/.libs/libuv.a deps/

setup:
	cd deps              && wget -4 $(UV_URL)
	cd deps              && tar xvf $(UV_FILE)

setupwin:
	cd deps              && wget -4 $(UV_URL)
	cd deps              && tar xvf $(UV_FILE)

push:
	cd src/osc-bridge      && git push
	cd src/mruby-qml-parse  && git push
	cd src/mruby-qml-spawn  && git push
	cd src/mruby-zest       && git push
	git push

status:
	cd src/osc-bridge      && git status
	cd src/mruby-qml-parse  && git status
	cd src/mruby-qml-spawn  && git status
	cd src/mruby-zest       && git status
	git status

diff:
	cd src/osc-bridge      && git diff
	cd src/mruby-qml-parse  && git diff
	cd src/mruby-qml-spawn  && git diff
	cd src/mruby-zest       && git diff
	git diff

stats:
	@echo 'main repo        commits: ' `git log --oneline | wc -l`
	@echo 'mruby-zest       commits: ' `cd src/mruby-zest      && git log --oneline | wc -l`
	@echo 'mruby-qml-parse  commits: ' `cd src/mruby-qml-parse && git log --oneline | wc -l`
	@echo 'mruby-qml-spawn  commits: ' `cd src/mruby-qml-spawn && git log --oneline | wc -l`
	@echo 'osc-bridge       commits: ' `cd src/osc-bridge      && git log --oneline | wc -l`
	@echo 'number of qml    files:' `find src/ -type f | grep -e qml$$ | wc -l`
	@echo 'number of ruby   files:' `find src/ -type f | grep -e rb$$ | wc -l`
	@echo 'number of c      files:' `find src/ -type f | grep -e c$$ | wc -l`
	@echo 'number of header files:' `find src/ -type f | grep -e h$$ | wc -l`
	@echo 'lines of OSC schema:' `wc -l src/osc-bridge/schema/test.json`
	@echo 'lines of qml:'
	@wc -l `find src/ -type f | grep qml$$` | tail -n 1
	@echo 'lines of ruby:'
	@wc -l `find src/ -type f | grep -e rb$$ | grep -v fcache` | tail -n 1
	@echo 'lines of c source:'
	@wc -l `find src/ -type f | grep -e c$$` | tail -n 1
	@echo 'lines of c header:'
	@wc -l `find src/ -type f | grep -e h$$` | tail -n 1
	@echo 'total lines of code:'
	@wc -l `find src/ -type f | grep -Ee "(qml|rb|c|h)$$" | grep -v fcache` | tail -n 1


verbose: ## Compile mruby with --trace
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake --trace

trace:
	cd mruby && MRUBY_CONFIG=../build_config.rb rake --trace

test:
	cd mruby &&  MRUBY_CONFIG=../build_config.rb rake test

rtest:
	cd src/mruby-qml-parse && ruby test-non-mruby.rb
	cd src/mruby-qml-spawn && ruby test-non-mruby.rb

run: ## Run the toolkit
	./zest osc.udp://127.0.0.1:1337

valgrind: ## Launch with valgrind
	 valgrind --leak-check=full --show-reachable=yes --log-file=leak-log.txt ./zest osc.udp://127.0.0.1:1337

callgrind: ## Launch with callgrind
	 valgrind --tool=callgrind --dump-instr=yes --collect-jumps=yes ./zest osc.udp://127.0.0.1:1337

gdb:
	 gdb --args ./zest osc.udp://127.0.0.1:1337

gltrace: ## Launch with apitrace
	/work/mytmp/apitrace/build/apitrace trace ./zest osc.udp://127.0.0.1:1337

qtrace:
	/work/mytmp/apitrace/build/qapitrace ./mruby.trace

scratch:
	 ./mruby/bin/mruby scratch.rb

clean: ## Clean Build Data
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake clean
	cd mruby             && rm -rf build/w64

pack:
	rm -rf package
	mkdir package
	mkdir package/schema
	mkdir package/qml
	mkdir package/font
	cp src/mruby-zest/qml/*             package/qml/
	cp src/mruby-zest/example/*         package/qml/
	cp src/osc-bridge/schema/test.json  package/schema/
	cp deps/nanovg/example/*.ttf        package/font/
	cp mruby/bin/mruby                  package/
	cp libzest.so                       package/
	cp zest     	                    package/
	echo 'Version 3.0.0-pre '       >>  package/VERSION
	echo 'built on: '               >>  package/VERSION
	echo `date`                     >>  package/VERSION
	rm -f zest-dist.tar
	rm -f zest-dist.tar.bz2
	tar cf zest-dist.tar package/
	bzip2 zest-dist.tar

pack32: ## Create 64bit Linux Package
	make pack
	mv zest-dist.tar.bz2 zest-dist-x86.tar.bz2

pack64: ## Create 64bit Linux Package
	make pack
	mv zest-dist.tar.bz2 zest-dist-x86_64.tar.bz2

put32: ## Push to the server
	scp zest-dist-x86.tar.bz2 mark@fundamental-code.com:/var/www/htdocs/zest/

put64: ## Push to the server
	scp zest-dist-x86_64.tar.bz2 mark@fundamental-code.com:/var/www/htdocs/zest/

packsrc:
	git-archive-all zynaddsubfx-3.0.0.tar.bz2

putsrc:
	scp zynaddsubfx-3.0.0.tar.bz2 mark@fundamental-code.com:/var/www/htdocs/zest/


.PHONY: help

help: ## This help
		@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


