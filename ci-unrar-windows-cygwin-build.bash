#!/usr/bin/env bash

HOME="$(pwd)"

if [[ ${1} =~ ^/ ]]; then
	cygwin_path="${1}"
else
	cygwin_path="${HOME}/${1:-cygwin}"
fi
source_repo="${2:-https://www.rarlab.com/rar/unrarsrc-7.1.10.tar.gz}"
source_branch="${3:-master}"

printf '%b\n' " \e[93m\U25cf\e[0m Build path = ${HOME}"
printf '\n%b\n' " \e[93m\U25cf\e[0m parameters = ${*}"
printf '\n%b\n' " \e[93m\U25cf\e[0m cygwin_path = ${cygwin_path}"
printf '\n%b\n' " \e[93m\U25cf\e[0m source_repo = ${source_repo}"
printf '\n%b\n' " \e[93m\U25cf\e[0m source_branch = ${source_branch}"

printf '\n%b\n\n' " \e[94m\U25cf\e[0m Cloning unrar git repo"

[[ -d "$HOME/unrar_build" ]] && rm -rf "$HOME/unrar_build"

if [[ ${2} =~ \.git$ ]]; then
	printf '\n%b\n\n' " \e[94m\U25cf\e[0m git clone --no-tags --single-branch --branch ${source_branch} --shallow-submodules --recurse-submodules -j$(nproc) --depth 1 ${source_repo} $HOME/unrar_build"
	git clone --no-tags --single-branch --branch "${source_branch}" --shallow-submodules --recurse-submodules -j"$(nproc)" --depth 1 "${source_repo}" "$HOME/unrar_build"
fi

if [[ ${2} =~ (\.tar.gz|\tar.xz)$ ]]; then
	printf '\n%b\n\n' " \e[94m\U25cf\e[0m git clone --no-tags --single-branch --branch ${source_branch} --shallow-submodules --recurse-submodules -j$(nproc) --depth 1 ${source_repo} $HOME/unrar_build"
	curl -L "${source_repo}" -o "unrar.tar.gz"
	mkdir -p "$HOME/unrar_build"
	tar xf "unrar.tar.gz" --strip-components=1 -C "$HOME/unrar_build"
fi

cd "$HOME/unrar_build" || exit 1

printf '\n%b\n\n' " \e[94m\U25cf\e[0m building unrar"

# Fix compilation issues for Cygwin
printf '\n%b\n' " \e[94m\U25cf\e[0m Patching for Cygwin compatibility"

# Create a Cygwin-compatible makefile
cat > makefile.cygwin << 'EOF'
#
# Makefile for UNIX - unrar

# Linux using GCC
# 2024.08.19: -march=native isn't recognized on some platforms such as RISCV64.
# Thus we removed it. Clang ARM users can add -march=armv8-a+crypto to enable
# ARM NEON crypto.
CXX=c++
CXXFLAGS=-O2 -std=c++11 -Wno-switch -Wno-dangling-else
LIBFLAGS=-fPIC
DEFINES=-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -DRAR_SMP -DUNRAR -D_GNU_SOURCE
STRIP=strip
AR=ar
LDFLAGS=-pthread
DESTDIR=/usr

##########################

COMPILE=$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(DEFINES)
LINK=$(CXX)

WHAT=UNRAR

UNRAR_OBJ=filestr.o recvol.o rs.o scantree.o qopen.o
LIB_OBJ=filestr.o scantree.o dll.o qopen.o

OBJECTS=rar.o strlist.o strfn.o pathfn.o smallfn.o global.o file.o filefn.o filcreat.o \
	archive.o arcread.o unicode.o system.o crypt.o crc.o rawread.o encname.o \
	resource.o match.o timefn.o rdwrfn.o consio.o options.o errhnd.o rarvm.o secpassword.o \
	rijndael.o getbits.o sha1.o sha256.o blake2s.o hash.o extinfo.o extract.o volume.o \
	list.o find.o unpack.o headers.o threadpool.o rs16.o cmddata.o ui.o largepage.o

.cpp.o:
	$(COMPILE) -D$(WHAT) -c $<

all:	unrar

install:	install-unrar

uninstall:	uninstall-unrar

clean:
	@rm -f *.bak *~
	@rm -f $(OBJECTS) $(UNRAR_OBJ) $(LIB_OBJ)
	@rm -f unrar libunrar.*

# We removed 'clean' from dependencies, because it prevented parallel
# 'make -Jn' builds.

unrar:	$(OBJECTS) $(UNRAR_OBJ)
	@rm -f unrar
	$(LINK) -o unrar $(LDFLAGS) $(OBJECTS) $(UNRAR_OBJ) $(LIBS)	
	$(STRIP) unrar

sfx:	WHAT=SFX_MODULE
sfx:	$(OBJECTS)
	@rm -f default.sfx
	$(LINK) -o default.sfx $(LDFLAGS) $(OBJECTS)
	$(STRIP) default.sfx

lib:	WHAT=RARDLL
lib:	CXXFLAGS+=$(LIBFLAGS)
lib:	$(OBJECTS) $(LIB_OBJ)
	@rm -f libunrar.*
	$(LINK) -shared -o libunrar.so $(LDFLAGS) $(OBJECTS) $(LIB_OBJ)
	$(AR) rcs libunrar.a $(OBJECTS) $(LIB_OBJ)

install-unrar:
			install -D unrar $(DESTDIR)/bin/unrar

uninstall-unrar:
			rm -f $(DESTDIR)/bin/unrar

install-lib:
		install libunrar.so $(DESTDIR)/lib
		install libunrar.a $(DESTDIR)/lib

uninstall-lib:
		rm -f $(DESTDIR)/lib/libunrar.so
EOF

# Patch file.cpp to fix ftruncate issue
if [ -f file.cpp ]; then
	printf '\n%b\n' " \e[94m\U25cf\e[0m Patching file.cpp for ftruncate support"
	# Add necessary includes at the top of file.cpp
	sed -i '1i #ifdef __CYGWIN__\n#include <unistd.h>\n#endif' file.cpp
fi

# Clean and build with our patched makefile
make -f makefile.cygwin clean
make -f makefile.cygwin

# If unrar (without .exe) was built, rename it
if [ -f unrar ] && [ ! -f unrar.exe ]; then
	mv unrar unrar.exe
fi

mkdir -p "${HOME}/lftp4win_bin"
cp -f "unrar.exe" "$HOME/lftp4win_bin"

printf '\n%b\n' " \e[94m\U25cf\e[0m Copy dll dependencies"
[[ -f "${cygwin_path}/bin/cygwin1.dll" ]] && cp -f "${cygwin_path}/bin/cygwin1.dll" "$HOME/lftp4win_bin"
printf '\n%b\n' " \e[92m\U25cf\e[0m Copied the dll dependencies"
