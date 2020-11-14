.PHONY: all clean

all: bsl1.eep xmodem.eep

clean:
	rm -f *~ *.ihx *.lst *.bin *.eep mkeep


bsl1.eep: bsl1.bin mkeep
	./mkeep $< $@

xmodem.eep: xmodem.bin mkeep
	./mkeep $< $@

mkeep: mkeep.c
bpeeprom: bpeeprom.c

.SUFFIXES: .asm .s .bin .bsl .eep .c .ihx .rel

.ihx.bin:
	objcopy -I ihex -O binary $< $@

.asm.ihx:
	as31 -Fhex -l -O$@ $<
