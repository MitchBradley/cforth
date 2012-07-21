0 ccall: spi-send        { a.adr i.len -- }
1 ccall: spi-send-only   { a.adr i.len -- }
2 ccall: spi-read-slow   { a.adr i.len i.offset -- }
3 ccall: spi-read-status { -- i.status }
4 ccall: spi-send-page   { a.adr i.len i.offset -- }
5 ccall: spi-read        { a.adr i.len i.offset -- }
6 ccall: lfill           { a.adr i.len i.value -- }
7 ccall: lcheck          { a.adr i.len i.value -- i.erraddr }
8 ccall: inc-fill          { a.adr i.len -- }
9 ccall: inc-check         { a.adr i.len -- i.erraddr }
d# 10 ccall: random-fill   { a.adr i.len -- }
d# 11 ccall: random-check  { a.adr i.len -- i.erraddr }
d# 12 ccall: (inflate)     { a.compadr a.expadr i.nohdr a.workadr -- i.expsize }
d# 13 ccall: control@      { -- i.value }
d# 14 ccall: control!      { i.value -- }
d# 15 ccall: tcm-size@     { -- i.value }
d# 16 ccall: inflate-adr   { -- a.value }
d# 17 ccall: byte-checksum { a.adr i.len -- i.checksum }
d# 18 ccall: wfi           { -- }
d# 19 ccall: psr@          { -- i.value }
d# 20 ccall: psr!          { i.value -- }
d# 21 ccall: kbd-bit-in    { -- i.value }
d# 22 ccall: kbd-bit-out   { i.value -- }
d# 23 ccall: ps2-devices   { -- a.value }
d# 24 ccall: init-ps2      { -- }
d# 25 ccall: ps2-out       { i.byte i.device# -- i.ack? }
d# 26 ccall: 'one-uart     { -- a.value }
d# 27 ccall: reset-reason  { -- i.value }
d# 28 ccall: 'version      { -- a.value }
d# 29 ccall: 'build-date   { -- a.value }
d# 30 ccall: wfi-loop      { -- }
d# 31 ccall: ukey1?        { -- i.value }
d# 32 ccall: ukey2?        { -- i.value }
d# 33 ccall: ukey3?        { -- i.value }
d# 34 ccall: ukey4?        { -- i.value }
