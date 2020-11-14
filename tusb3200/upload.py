#!/usr/bin/env python3

import sys
import time
import usb

BTC_GET_BOOTCODE_STATUS = 0x80
BTC_REBOOT = 0x85
BTC_EXTERNAL_MEMORY_READ = 0x90
BTC_I2C_MEMORY_READ = 0x92
GET_STATUS = 0x00
GET_DESCRIPTOR = 0x06

dev = usb.core.find(idVendor=0x0451, idProduct=0x3200)
if dev:
  dev.set_configuration()
  print('Found TUSB3200 in maskrom DFU mode, uploading stage2 bootloader...')

  # Original TUSB3200 bootrom has very limited api, can upload at most
  # 4096 bytes?
  # Maybe a local HCI limitation, but I'm getting errors when trying to
  # upload more than 4KiB.
  fname = "boot.bin"
  if len(sys.argv) > 1:
    fname = sys.argv[1]
  print('Sending %r to device' % fname)
  with open(fname, "rb") as f:
    data = f.read()
    print('Sending %d bytes...' % len(data))
    dev.ctrl_transfer(0x41, 0x01, 0, 0, data)

  for x in range(5):
    dev = usb.core.find(idVendor=0x0451, idProduct=0x3210)
    if dev:
      break
    time.sleep(1)

else:
  dev = usb.core.find(idVendor=0x0451, idProduct=0x3210)
  if not dev:
    raise ValueError("No devices found")

if not dev:
  raise ValueError("Failed to find new device after stage1 upload")

dev.set_configuration()

# These are implemented by boot.bin and are compatible with the newer
# TUSB3210 (with some extensions), see also sllu025a.pdf
# (https://www.ti.com/lit/pdf/sllu025)

def read_xram(a):
  return dev.ctrl_transfer(0xc0, 0x90, 0, a, 1)[0]

def write_xram(a, d):
  return dev.ctrl_transfer(0x40, 0x91, d, a, 0)

def read_i2c(a):
  return dev.ctrl_transfer(0xc0, 0x92, 0, a, 1)[0]

def write_i2c(a, d):
  return dev.ctrl_transfer(0x40, 0x93, d, a, 0)

def read_code(a):
  return dev.ctrl_transfer(0xc0, 0x94, 0, a, 1)[0]

def write_code(a, d):
  return dev.ctrl_transfer(0x40, 0x95, d, a, 0)

def read_iram(a):
  return dev.ctrl_transfer(0xc0, 0x96, 0, a, 1)[0]

def write_iram(a, d):
  return dev.ctrl_transfer(0x40, 0x97, d, a, 0)

def read_sfr(a):
  return dev.ctrl_transfer(0xc0, 0x98, 0, a, 1)[0]

def write_sfr(a, d):
  return dev.ctrl_transfer(0x40, 0x99, d, a, 0)

def reboot_bootloader():
  return dev.ctrl_transfer(0x40, 0x85, 0, 0, 0)

for a in range(256):
  d = read_sfr(a)
  print('sfr@%02x=%02x' % (a, d))

# Reboot back into the original bootloader:
#time.sleep(2)
#reboot_bootloader()
