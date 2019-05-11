
export FW_VER := 2.8a

PROJ := FlashFloppy
VER := v$(FW_VER)

SUBDIRS += src bootloader reloader

.PHONY: all clean flash start serial gotek

ifneq ($(RULES_MK),y)

.DEFAULT_GOAL := gotek
export ROOT := $(CURDIR)

all:
	$(MAKE) -f $(ROOT)/Rules.mk all

clean:
	rm -f *.hex *.upd *.rld *.dfu *.html
	$(MAKE) -f $(ROOT)/Rules.mk $@

gotek: export gotek=y
gotek: all
	mv FF.dfu FF_Gotek-$(VER).dfu
	mv FF.upd FF_Gotek-$(VER).upd
	mv FF.hex FF_Gotek-$(VER).hex
	mv BL.rld FF_Gotek-Bootloader-$(VER).rld
	mv RL.upd FF_Gotek-Reloader-$(VER).upd

HXC_FF_URL := https://www.github.com/keirf/HxC_FF_File_Selector
HXC_FF_URL := $(HXC_FF_URL)/releases/download
HXC_FF_VER := v5-FF

dist:
	rm -rf flashfloppy-*
	mkdir -p flashfloppy-$(VER)/reloader
	$(MAKE) clean
	$(MAKE) gotek
	cp -a FF_Gotek-$(VER).dfu flashfloppy-$(VER)/
	cp -a FF_Gotek-$(VER).upd flashfloppy-$(VER)/
	cp -a FF_Gotek-$(VER).hex flashfloppy-$(VER)/
	cp -a FF_Gotek-Reloader-$(VER).upd flashfloppy-$(VER)/reloader/
	cp -a FF_Gotek-Bootloader-$(VER).rld flashfloppy-$(VER)/reloader/
	$(MAKE) clean
	cp -a COPYING flashfloppy-$(VER)/
	cp -a README.md flashfloppy-$(VER)/
	cp -a RELEASE_NOTES flashfloppy-$(VER)/
	cp -a examples flashfloppy-$(VER)/
	[ -e HxC_Compat_Mode-$(HXC_FF_VER).zip ] || \
	wget -q --show-progress $(HXC_FF_URL)/$(HXC_FF_VER)/HxC_Compat_Mode-$(HXC_FF_VER).zip
	rm -rf index.html
	unzip -q HxC_Compat_Mode-$(HXC_FF_VER).zip
	mv HxC_Compat_Mode flashfloppy-$(VER)
	mkdir -p flashfloppy-$(VER)/scripts
	cp -a scripts/edsk* flashfloppy-$(VER)/scripts/
	cp -a scripts/mk_hfe.py flashfloppy-$(VER)/scripts/
	zip -r flashfloppy-$(VER).zip flashfloppy-$(VER)

mrproper: clean
	rm -rf flashfloppy-*
	rm -rf HxC_Compat_Mode-$(HXC_FF_VER).zip

else

all:
	$(MAKE) -C src -f $(ROOT)/Rules.mk $(PROJ).elf $(PROJ).bin $(PROJ).hex
	bootloader=y $(MAKE) -C bootloader -f $(ROOT)/Rules.mk \
		Bootloader.elf Bootloader.bin Bootloader.hex
	reloader=y $(MAKE) -C reloader -f $(ROOT)/Rules.mk \
		Reloader.elf Reloader.bin Reloader.hex
	srec_cat bootloader/Bootloader.hex -Intel src/$(PROJ).hex -Intel \
	-o FF.hex -Intel
	$(PYTHON) ./scripts/mk_update.py src/$(PROJ).bin FF.upd
	$(PYTHON) ./scripts/mk_update.py bootloader/Bootloader.bin BL.rld
	$(PYTHON) ./scripts/mk_update.py reloader/Reloader.bin RL.upd
	$(PYTHON) ./scripts/dfu-convert.py -i FF.hex FF.dfu

endif

BAUD=115200
DEV=/dev/ttyUSB0

flash:
	sudo stm32flash -b $(BAUD) -w FF_Gotek-$(VER).hex $(DEV)

start:
	sudo stm32flash -b $(BAUD) -g 0 $(DEV)

serial:
	sudo miniterm.py $(DEV) 3000000
