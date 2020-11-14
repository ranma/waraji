.PHONY: all clean

all: boot.eep

clean:
	rm -f *.ihx *.lst *.rel *.map *.sym *.mem *.rst *~ mkeep

mkeep: mkeep.c

.SUFFIXES: .s .bin .eep .ihx .rel

%.eep: %.bin mkeep
	./mkeep $< $@

%.bin: %.ihx
	objcopy -I ihex $< -O binary $@

%.ihx: %.rel
	sdld -nmuwxMY -i $@ $<

%.rel: %.s
	sdas8051 -ols $@ $<
