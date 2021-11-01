DEFAULT_MODULES = llvm-gcc llvm2 minisat stp klee-uclibc klee z3 clang bear runtime frontend maxsmt synthesis
DEFAULT_32_MODULES = llvm-gcc-32 llvm2-32 minisat-32 stp-32 klee-uclibc-32 klee-32 z3 clang bear runtime-32 frontend maxsmt synthesis
OPTIONAL_MODULES = nsynth semfix
CLEAN_MODULES = $(addprefix clean-, $(DEFAULT_MODULES)) $(addprefix clean-, $(OPTIONAL_MODULES))

help:
	@echo ~~~~~~~~~~~~~~~~~~ Angelix ~~~~~~~~~~~~~~~~~~
	@echo Semantics-based Automated Program Repair Tool
	@echo
	@echo \'make default\''          'build default modules
	@echo \'make default-32\''   'build default 32b modules
	@echo \'make all\''                  'build all modules
	@echo \'make all-32\''       'build all and 32b modules
	@echo \'make MODULE\''                    'build module
	@echo \'make clean-all\''            'clean all modules
	@echo \'make clean-MODULE\''              'clean module
	@echo \'make test\''                         'run tests
	@echo \'make test-semfix\''           'run semfix tests
	@echo \'make docker\''              'build docker image
	@echo
	@echo Default modules:
	@echo -n ' '$(foreach module, $(DEFAULT_MODULES),"* $(module)\n")
	@echo
	@echo Optional modules:
	@echo -n ' '$(foreach module, $(OPTIONAL_MODULES),"* $(module)\n")

default: $(DEFAULT_MODULES)
default-32: $(DEFAULT_32_MODULES)
all: $(DEFAULT_MODULES) $(OPTIONAL_MODULES)
all-32: $(DEFAULT_MODULES) $(DEFAULT_32_MODULES) $(OPTIONAL_MODULES)
clean-all: $(CLEAN_MODULES)

.PHONY: help all $(DEFAULT_MODULES) $(OPTIONAL_MODULES) clean-all $(CLEAN_MODULES) test test-semfix docker

# Information for retrieving dependencies

DOWNLOAD=wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 --tries=5 --continue

GLIBC_VERSION=$(lastword $(shell ldd --version | head -n 1))
GLIBC_PLUS_2_25=$(shell expr $(GLIBC_VERSION) \>= 2.25)
APPLIED_KLEE_PATCH=$(shell (patch -p0 --forward --dry-run < glibc-klee.patch > /dev/null 2>&1  ; echo $$?)  )

LLVM_GCC32=llvm-gcc-4.2-2.9-i686-linux
LLVM_GCC32_ARCHIVE=$(LLVM_GCC32).tgz
LLVM_GCC32_URL=https://llvm.org/releases/2.9/$(LLVM_GCC32_ARCHIVE)
LLVM_GCC32_DIR=$(ANGELIX_ROOT)/build/$(LLVM_GCC32)
LLVM2_32_DIR=$(LLVM2_DIR)_32
FLAGS_32="-m32"
KLEE_32_DIR=$(KLEE_DIR)_32
LLVM29_DIR=llvm-2.9

LLVM_GCC=llvm-gcc4.2-2.9-x86_64-linux
LLVM_GCC_URL=http://llvm.org/releases/2.9/llvm-gcc4.2-2.9-x86_64-linux.tar.bz2
LLVM_GCC_ARCHIVE=llvm-gcc4.2-2.9-x86_64-linux.tar.bz2
LLVM2_PATCH_URL=http://www.mail-archive.com/klee-dev@imperial.ac.uk/msg01302/unistd-llvm-2.9-jit.patch
LLVM2_PATCH=unistd-llvm-2.9-jit.patch
LLVM2_URL=http://llvm.org/releases/2.9/llvm-2.9.tgz
LLVM2_ARCHIVE=llvm-2.9.tgz
LLVM3_URL=http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
LLVM3_ARCHIVE=llvm-3.7.0.src.tar.xz
CLANG_URL=http://llvm.org/releases/3.7.0/cfe-3.7.0.src.tar.xz
CLANG_ARCHIVE=cfe-3.7.0.src.tar.xz
CLANG_TOOLS_EXTRA_URL=https://github.com/llvm-mirror/clang-tools-extra.git
COMPILER_RT_URL=http://llvm.org/releases/3.7.0/compiler-rt-3.7.0.src.tar.xz
COMPILER_RT_ARCHIVE=compiler-rt-3.7.0.src.tar.xz
STP_URL=https://github.com/stp/stp.git
MINISAT_URL=https://github.com/niklasso/minisat.git
Z3_URL=https://github.com/mechtaev/z3.git
Z3_2_19_URL=https://github.com/Z3Prover/bin/raw/master/legacy/z3-2.19.tar.gz
Z3_2_19_ARCHIVE=z3-2.19.tar.gz
KLEE_UCLIBC_URL=https://github.com/klee/klee-uclibc.git

KLEE_UCLIBC=klee-uclibc
KLEE_UCLIBC_32=$(KLEE_UCLIBC)_32
KLEE_UCLIBC_32_DIR=$(KLEE_UCLIBC_DIR)_32

BEAR_URL=https://github.com/rizsotto/Bear.git
BEAR_VERSION=2.1.4
STP_VERSION=2.1.2
MAXSMT_URL=https://github.com/mechtaev/maxsmt-playground.git
LOCAL_LIB_URL=http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/local-lib-2.000018.tar.gz
LOCAL_LIB_ARCHIVE=local-lib-2.000018.tar.gz

# Testing #

test:
	python3 tests/tests.py

test-semfix:
	python3 tests/semfix-tests.py

# LLVM-GCC #

llvm-gcc: build/$(LLVM_GCC_ARCHIVE)
	cd build && [ -d $(LLVM_GCC) ] || tar xf $(LLVM_GCC_ARCHIVE)

build/$(LLVM_GCC_ARCHIVE):
	cd build && $(DOWNLOAD) $(LLVM_GCC_URL)

# LLVM-GCC32 #

llvm-gcc-32: build/$(LLVM_GCC32_ARCHIVE)
	cd build && [ -d $(LLVM_GCC32) ] || tar xf $(LLVM_GCC32_ARCHIVE)

build/$(LLVM_GCC32_ARCHIVE):
	cd build && $(DOWNLOAD) $(LLVM_GCC32_URL)

clean-llvm-gcc:

# LLVM2 #

llvm2-32: llvm2-setup-32
	cd $(LLVM2_32_DIR) && CFLAGS=$(FLAGS_32) CPPFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) ./configure --enable-optimized --enable-assertions --with-llvmgccdir=$(LLVM_GCC32_DIR) && \
	CFLAGS=$(FLAGS_32) CPPFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) make


llvm2-setup-32: 
	[ -d $(LLVM2_32_DIR) ] || \
	mkdir tmp && \
	cd tmp && $(DOWNLOAD) $(LLVM2_URL) \
	&& $(DOWNLOAD) $(LLVM2_PATCH_URL) \
	&& tar xf $(LLVM2_ARCHIVE) \
	&& patch -p0 -N < $(LLVM2_PATCH) \
	&& mv $(LLVM29_DIR) $(LLVM2_32_DIR) && cd .. && rm -rf tmp

llvm2-setup: build/$(LLVM2_ARCHIVE) build/$(LLVM2_PATCH)
	cd build && [ -d $(LLVM2_DIR) ] || ( tar xf $(LLVM2_ARCHIVE) && patch -p0 -N < $(LLVM2_PATCH) )

llvm2: build/$(LLVM2_ARCHIVE) build/$(LLVM2_PATCH) llvm2-setup
	cd $(LLVM2_DIR) && ./configure --enable-optimized --enable-assertions && \
	make

build/$(LLVM2_ARCHIVE):
	cd build && $(DOWNLOAD) $(LLVM2_URL)

build/$(LLVM2_PATCH):
	cd build && $(DOWNLOAD) $(LLVM2_PATCH_URL)

clean-llvm2:
	rm -rf $(LLVM2_DIR)/build

# STP #

stp: $(STP_DIR)
	cd $(STP_DIR) && mkdir -p build && cd build && cmake -DMINISAT_LIBRARY="$(MINISAT_DIR)/build/libminisat.so.2" -DMINISAT_INCLUDE_DIR="$(MINISAT_DIR)" -G 'Unix Makefiles' $(STP_DIR) && make

stp-32: $(STP_DIR)
	cd $(STP_DIR) && mkdir -p build32 && cd build32 && \
	CFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) CPPFLAGS=$(FLAGS_32) cmake -DCMAKE_EXE_LINKER_FLAGS=$(FLAGS_32) -DCMAKE_SHARED_LINKER_FLAGS=$(FLAGS_32) \
	-DMINISAT_LIBRARY="$(MINISAT_DIR)/build32/libminisat.so.2" -DMINISAT_INCLUDE_DIR="$(MINISAT_DIR)" -G 'Unix Makefiles' $(STP_DIR) && \
	make

$(STP_DIR):
	cd build && git clone --branch $(STP_VERSION) $(STP_URL)

clean-stp:
	rm -rf $(STP_DIR)/build

# MINISAT #

minisat: $(MINISAT_DIR)
	cd $(MINISAT_DIR) && mkdir -p build && cd build && cmake -G 'Unix Makefiles' $(MINISAT_DIR) && make

minisat-32: $(MINISAT_DIR)
	cd $(MINISAT_DIR) && mkdir -p build32 && cd build32 && CFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) cmake -G 'Unix Makefiles' $(MINISAT_DIR) && make


$(MINISAT_DIR):
	cd build && git clone --depth=1 $(MINISAT_URL)

clean-minisat:
	rm -rf $(MINISAT_DIR)/build

# KLEE-UCLIBC #

klee-uclibc: $(KLEE_UCLIBC_DIR)
	cd $(KLEE_UCLIBC_DIR) && ./configure --make-llvm-lib && make -j2

klee-uclibc-32: $(KLEE_UCLIBC_32_DIR)
	cd $(KLEE_UCLIBC_32_DIR) && \
	CFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) CPPFLAGS=$(FLAGS_32) ./configure --make-llvm-lib --with-llvm-config "$(LLVM2_32_DIR)/Release+Asserts/bin/llvm-config" && \
	make KLEE_CFLAGS=$(FLAGS_32) -j2

$(KLEE_UCLIBC_DIR):
	cd build && git clone --depth=1 $(KLEE_UCLIBC_URL)

$(KLEE_UCLIBC_32_DIR):
	cd build && git clone --depth=1 $(KLEE_UCLIBC_URL) $(KLEE_UCLIBC_32)

clean-klee-uclibc:
	cd $(KLEE_UCLIBC_DIR) && make clean

# KLEE #

klee-glibc-patch:
	@[ $(GLIBC_PLUS_2_25) -eq 0 ] || [ $(APPLIED_KLEE_PATCH) -eq 1 ] || patch -p0 --forward < glibc-klee.patch

klee: klee-glibc-patch
	cd $(KLEE_DIR) && ./configure --with-llvm=$(LLVM2_DIR) --with-stp=$(STP_DIR)/build --with-uclibc=$(KLEE_UCLIBC_DIR) --enable-posix-runtime && make ENABLE_OPTIMIZED=1

klee-32:
	[ -d $(KLEE_32_DIR) ] || cp -r $(KLEE_DIR) $(KLEE_32_DIR) && cd $(KLEE_32_DIR) && make clean
	cd $(KLEE_32_DIR) && CFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) CPPFLAGS=$(FLAGS_32) ./configure --with-llvm=$(LLVM2_32_DIR) --with-stp=$(STP_DIR)/build32 --with-uclibc=$(KLEE_UCLIBC_32_DIR) --enable-posix-runtime && \
	CFLAGS=$(FLAGS_32) CXXFLAGS=$(FLAGS_32) CPPFLAGS=$(FLAGS_32) make VERBOSE=1 ENABLE_OPTIMIZED=1
	[ -L $(KLEE_DIR)/Release+Asserts/lib/32 ] || ln -sf $(KLEE_32_DIR)/Release+Asserts/lib $(KLEE_DIR)/Release+Asserts/lib/32

clean-klee:
	cd $(KLEE_DIR) && make clean

# Angelix runtime #

runtime:
	cd src/runtime && make
	mkdir -p $(ANGELIX_ROOT)/build/lib/klee
	mkdir -p $(ANGELIX_ROOT)/build/lib/test
	cp src/runtime/libangelix.test.a $(ANGELIX_ROOT)/build/lib/test/libangelix.a
	cp src/runtime/libangelix.klee.a $(ANGELIX_ROOT)/build/lib/klee/libangelix.a
	cd src/runtime && make clean

runtime-32:
	[ -d src/runtime_32 ] || cp -r src/runtime src/runtime_32 
	cd src/runtime_32 && CFLAGS="-m32" make
	mkdir -p $(ANGELIX_ROOT)/build/lib/klee/32
	mkdir -p $(ANGELIX_ROOT)/build/lib/test/32
	cp src/runtime_32/libangelix.test.a $(ANGELIX_ROOT)/build/lib/test/32/libangelix.a
	cp src/runtime_32/libangelix.klee.a $(ANGELIX_ROOT)/build/lib/klee/32/libangelix.a
	cd src/runtime_32 && make clean

clean-runtime:
	rm -rf $(ANGELIX_ROOT)/build/lib
	cd src/runtime && make clean

# Z3 #

z3: $(Z3_DIR)
	cd $(Z3_DIR) && python scripts/mk_make.py --java && cd build && make

$(Z3_DIR):
	cd build && git clone --depth=1 $(Z3_URL)

clean-z3:
	rm -rf $(Z3_DIR)/build

# Z3_2 #

z3_2: $(Z3_2_19_DIR)/bin/z3_semfix

$(Z3_2_19_DIR)/bin/z3_semfix: build/$(Z3_2_19_ARCHIVE)
	cd build && mkdir -p z3_tmp && tar xzf $(Z3_2_19_ARCHIVE) --directory z3_tmp \
	&& rm -rf $(Z3_2_19_DIR) && mv -f z3_tmp/z3 $(Z3_2_19_DIR) && rm -rf z3_tmp \
	&& mv $(Z3_2_19_DIR)/bin/z3 $(Z3_2_19_DIR)/bin/z3_semfix

build/$(Z3_2_19_ARCHIVE):
	cd build && $(DOWNLOAD) $(Z3_2_19_URL)

clean-z3_2:
	rm -rf $(Z3_2_19_DIR)

# local::lib
build/local-lib-2.000018/installed: build/$(LOCAL_LIB_ARCHIVE) $(LOCAL_PERL_ROOT)
	cd build && tar xzf $(LOCAL_LIB_ARCHIVE) \
	&& cd local-lib-2.000018 && perl Makefile.PL --bootstrap=$(LOCAL_PERL_ROOT) --no-manpages \
	&& make test && make install && touch installed

local_lib: build/local-lib-2.000018/installed

$(LOCAL_PERL_ROOT):
	mkdir -p $(LOCAL_PERL_ROOT)

build/$(LOCAL_LIB_ARCHIVE):
	cd build && $(DOWNLOAD) $(LOCAL_LIB_URL)

clean-local-lib:
	rm -rf build/local-lib-2.000018

# semfix #

semfix: local_lib z3_2
	perl -MCPAN -Mlocal::lib=${LOCAL_PERL_ROOT} -e 'CPAN::install(Log::Log4perl)' \
	&& perl -MCPAN -Mlocal::lib=${LOCAL_PERL_ROOT} -e 'CPAN::install(XML::Simple)'

clean-semfix: clean-z3_2 clean-local-lib
	rm -rf $(LOCAL_PERL_ROOT)

# MAX-SAT #

maxsmt: $(MAXSMT_DIR)
	mkdir -p $(MAXSMT_DIR)/lib
	cp $(Z3_JAR) $(MAXSMT_DIR)/lib/
	mkdir -p $(MAXSMT_DIR)/log
	cd $(MAXSMT_DIR) && sbt package

$(MAXSMT_DIR):
	cd build && git clone --depth=1 $(MAXSMT_URL)

clean-maxsmt:
	cd $(MAXSMT_DIR) && sbt clean

distclean-maxsmt:
	rm -rf $(MAXSMT_DIR)

# Synthesis #

synthesis:
	mkdir -p $(SYNTHESIS_DIR)/lib
	cp $(MAXSMT_JAR) $(SYNTHESIS_DIR)/lib/
	cp $(Z3_JAR) $(SYNTHESIS_DIR)/lib/
	mkdir -p $(SYNTHESIS_DIR)/log
	cd $(SYNTHESIS_DIR) && sbt assembly

clean-synthesis:
	cd $(SYNTHESIS_DIR) && sbt clean

distclean-synthesis: clean-synthesis

# Synthesis #

nsynth:
	mvn install:install-file -Dfile=$(Z3_JAR) -DgroupId=com.microsoft.z3 -DartifactId=z3 -Dversion=4 -Dpackaging=jar
	cd $(ANGELIX_ROOT)/src/nsynth && mvn package

clean-nsynth:

distclean-nsynth: clean-nsynth

# Clang #

clang: build/$(LLVM3_ARCHIVE) build/$(CLANG_ARCHIVE) build/$(COMPILER_RT_ARCHIVE)
	cd build && [ -d $(LLVM3_DIR) ] || tar xf $(LLVM3_ARCHIVE)
	mkdir -p "$(LLVM3_DIR)/tools/clang"
	cd build && tar xf $(CLANG_ARCHIVE) --directory "$(LLVM3_DIR)/tools/clang" --strip-components=1
	mkdir -p "$(LLVM3_DIR)/projects/compiler-rt"
	cd build && tar xf $(COMPILER_RT_ARCHIVE) --directory "$(LLVM3_DIR)/projects/compiler-rt" --strip-components=1
	[ $(GLIBC_PLUS_2_25) -eq 0 ] || patch -p0 -F70 < ../glibc-compiler-rt.patch
	cd "$(LLVM3_DIR)/tools/clang/tools/" && rm extra -rf && git clone --branch release_37 $(CLANG_TOOLS_EXTRA_URL) extra
	mkdir -p "$(LLVM3_DIR)/build" && cd "$(LLVM3_DIR)/build" && cmake -G "Unix Makefiles" ../ && make

build/$(LLVM3_ARCHIVE):
	cd build && $(DOWNLOAD) $(LLVM3_URL)

build/$(CLANG_ARCHIVE):
	cd build && $(DOWNLOAD) $(CLANG_URL)

build/$(COMPILER_RT_ARCHIVE):
	cd build && $(DOWNLOAD) $(COMPILER_RT_URL)

clean-clang:
	rm -rf "$(LLVM3_DIR)/build"

# Frontend #

frontend: $(LLVM3_DIR)/tools/clang/tools/angelix
	grep -q angelix "$(LLVM3_DIR)/tools/clang/tools/CMakeLists.txt" || echo 'add_subdirectory(angelix)' >> "$(LLVM3_DIR)/tools/clang/tools/CMakeLists.txt"
	cd "$(LLVM3_DIR)/build" && make
	mkdir -p "$(LLVM3_DIR)/build/bin/angelix"
	cp "$(LLVM3_DIR)/build/bin/instrument-repairable" "$(ANGELIX_ROOT)/build/bin"
	cp "$(LLVM3_DIR)/build/bin/instrument-suspicious" "$(ANGELIX_ROOT)/build/bin"
	cp "$(LLVM3_DIR)/build/bin/apply-patch" "$(ANGELIX_ROOT)/build/bin"
	cp "$(LLVM3_DIR)/build/bin/instrument-printf" "$(ANGELIX_ROOT)/build/bin"
	cp -r "$(LLVM3_DIR)/build/lib/clang/3.7.0/include/"* "$(ANGELIX_ROOT)/build/include"

$(LLVM3_DIR)/tools/clang/tools/angelix:
	ln -f -s "$(ANGELIX_ROOT)/src/frontend" "$(LLVM3_DIR)/tools/clang/tools/angelix"

clean-frontend:

# Bear #

bear: $(BEAR_DIR)
	cd "$(BEAR_DIR)" && mkdir -p build && cd build && cmake ../ && make all
	sed -i 's/exit_code = subprocess.call(args.build, env=environment)/exit_code = subprocess.call(args.build, env=environment, shell=True)/' "$(BEAR_DIR)/build/bear/bear"

$(BEAR_DIR):
	cd build && git clone --branch $(BEAR_VERSION) $(BEAR_URL)

clean-bear:
	rm -rf "$(BEAR_DIR)/build"

docker:
	docker build -t angelix .
