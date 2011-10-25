# Makefile for tricore using GLISS V2

# configuration
GLISS_PREFIX=../gliss2
WITH_DISASM=1	# comment it to prevent disassembler building
WITH_SIM=1		# comment it to prevent simulator building

MEMORY=vfast_mem
#LOADER=old_elf


# files
GOALS=
ifdef WITH_DISASM
GOALS+=carcore-disasm
endif
ifdef WITH_SIM
GOALS+=carcore-sim
endif

SUBDIRS=src sim disasm
CLEAN=carcore.nml carcore.irg
DISTCLEAN=include src disasm sim

GFLAGS=\
	-m mem:$(MEMORY) \
	-m code:code \
	-m env:void_env \
	-m loader:old_elf \
	-a disasm.c \
	-a used_regs.c
# correct fetch and decode will be chosen auto
# except if you want one of the optimized decode (for the moment)
#	-m fetch:fetch \
#	-m decode:decode \

MAIN_NMP=carcore.nmp
NMP = $(shell find nmp -name "*.nmp")


# targets
all: lib $(GOALS)

carcore.nml: $(NMP)
	(cd nmp; pwd; ../$(GLISS_PREFIX)/gep/gliss-nmp2nml.pl $(MAIN_NMP) ../$@)

carcore.irg: carcore.nml
	$(GLISS_PREFIX)/irg/mkirg $< $@

src include: carcore.irg
	$(GLISS_PREFIX)/gep/gep $(GFLAGS) $< -S

lib: src include/carcore/config.h src/disasm.c src/used_regs.c
	(cd src; make)

carcore-disasm:
	cd disasm; make

carcore-sim:
	cd sim; make

include/carcore/config.h: config.tpl
	test -d include/carcore || mkdir include/carcore
	cp config.tpl include/carcore/config.h

src/used_regs.c: carcore.irg
	$(GLISS_PREFIX)/gep/gliss-used-regs $<

src/disasm.c: carcore.irg
	$(GLISS_PREFIX)/gep/gliss-disasm $< -o $@ -c

distclean: clean
	-for d in $(SUBDIRS); do test -d $$d && (cd $$d; make distclean || exit 0); done
	-rm -rf $(DISTCLEAN)

clean: only-clean
	-for d in $(SUBDIRS); do test -d $$d && (cd $$d; make clean || exit 0); done

only-clean:
	-rm -rf $(CLEAN)
