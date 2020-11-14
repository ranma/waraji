;-----------------------------------------------------------------------------
; Custom VSC73xx 8051 iCPU bootloader (custom upload protocol, minimal size).
;
; Copyright (C) 2015 Tobias Diedrich
; GNU GENERAL PUBLIC LICENSE Version 2 or later.
;
; This was written specifically for the D-Link DGS-1008D switches using this
; chipset.  Even for these it may not work on just any model, YMMV.
;
; Tested on:
; Model No    P/N                H/W Ver
; DGS-1008D   EGS1008DE....E1G   E1
;
; To flash this, it is necessary to unsolder the SPI flash chip.
; This is left as an exercise to the interested reader. ;)
;
; Once installed, new code can easily be uploaded over the serial port
; connector (J1) on the DGS-1008D.
;
; Assumptions made:
;   - 25MHz crystal and 156.25MHz PLL clock.
;   - iCPU configured to boot from 8KiB SPI flash, no external ram or rom.
;   - Atmel AT25640 8KiB SPI flash (32 byte pages, 3MHz clock).
;   - Flash image layout: [2-byte size] [image data] [simple checksum]
;
; DGS-1008D J1 pinout ([1] towards LEDS: [1]23456]):
;   1: VCC
;   2: VCC
;   3: TX
;   4: RX
;   5: GND
;   6: GND
;
; Serial settings: 115200 8n1
;-----------------------------------------------------------------------------

.org 0x86
DPS:
.org 0xf8
RA_DONE:
.org 0xf9
RA_BLK:
.org 0xfa
RA_AD_RD:
.org 0xfb
RA_AD_WR:
.org 0xfc
RA_DA0:
.org 0xfd
RA_DA1:
.org 0xfe
RA_DA2:
.org 0xff
RA_DA3:

.org 0x0
reset_entry:
	mov A, #0xff
	mov RCAP2H, A
	mov TL2, A
	mov TH2, A
	mov R1, A
	mov RCAP2L, #0xeb ; 115200 baud @ div 2 78.125MHz
	mov T2CON, #0x34
	mov SCON, #0x52
	mov DPTR, #0xe000 ; XRAM-mapped code/data ram
	inc DPS

	; Wait 255 '.' until '!' or time out and jump to orig_entry

	ljmp high_entry
bsl_sig_ver:
	.byte "BSL1"

payload_start:

.org (0x1ee0 - 2)
bsl_high:
high_entry:
	; Switch to fast clock
	mov RA_BLK, #0xe0   ; system block
	mov A, #0x10 ; ICPU_CTRL
	mov RA_AD_RD, A
chipreg_read_wait:
	jnb RA_DONE.0, chipreg_read_wait

	; R/W seems to be different HW regs, need to copy.
	; Reading from RA_DAx also clears the RA_DONE flag for reads.
	mov A, RA_DA3
	mov RA_DA3, A
	mov A, RA_DA2
	mov RA_DA2, A
	mov A, RA_DA1
	anl A, #0xe0
	orl A, #0x01 ; 156.25MHz / 2
	mov RA_DA1, A
	mov A, RA_DA0
	mov RA_DA0, A
	mov A, #0x10 ; ICPU_CTRL
	mov RA_AD_WR, A
chipreg_write_wait:
	jnb RA_DONE.0, chipreg_write_wait
	setb RA_DONE.0

	mov DPTR, #(0xe000 + 30) ; 32 byte eeprom page - 2 bytes code length

serial_loop:
	; Goto serial_read if we got something
	jb RI,serial_read

	mov A, #'.'
serial_write:
	clr TI
	mov SBUF, A
serial_write_wait:
	jnb TI,serial_write_wait

	dec R1
	mov A, R1
	jnz serial_loop

	sjmp relocate_payload

serial_read:
	mov A, SBUF
	clr RI
	add A, #-'!'
	; Continue waiting if it's not '!'
	jnz serial_loop

	; Send '+' as ack.
	mov SBUF, #'+'
serial_write_wait2:
	jnb TI,serial_write_wait2

	; Get length in bytes
len1_wait:
	jnb RI,len1_wait
	mov A, SBUF
	clr RI
	mov SBUF, #'1'
	mov R1, A
len2_wait:
	jnb RI,len2_wait
	mov A, SBUF
	clr RI
	mov SBUF, #'2'
	mov R2, A
	inc R1
	inc R2
	mov DPTR, #0xE000

	; Receive until length bytes are written
recv_buf_end:
serial_read_wait:
	jnb RI,serial_read_wait
	mov A, SBUF
	clr RI
	mov SBUF, #'-'
	movx @DPTR, A
	inc DPTR
	djnz R1, serial_read_wait
	djnz R2, serial_read_wait

	mov A, #'!'
	clr TI
	mov SBUF, A
serial_write_wait3:
	jnb TI,serial_write_wait3
	; Start execution of uploaded code.
	sjmp start_payload

relocate_payload:

relocate_loop:
	movx A, @DPTR
	inc DPTR
	inc DPS
	movx @DPTR, A
	inc DPTR
	inc DPS
	mov A, DPH
	cjne A, #(0xe0 + ((relocate_payload + 2) / 256)), relocate_loop

start_payload:
	inc DPS  ; Huh, clr DPS doesn't work reliably?
	ljmp 0

; 2 bytes length, 1 byte checksum,
.org (0x1f80 - 2 - 1 - 3 - 6 - 4)
eep_payload_start_addr:
	.byte payload_start + 2
eep_payload_max_len:
	.word bsl_high - payload_start
default_mac:
	.byte 0x00, 0x01, 0x5c, 0x5a, 0xa5, 0x41
default_ip:
	.byte 192, 168, 1, 1
