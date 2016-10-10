\ Load Open Firmware.
\ This is CForth-specific but it is supposed to be independent of
\ any particular hardware platform.

fl ${CBP}/ofw/ofw-support.fth

create ext2fs-support
create nfts-support
create omit-fb-support
create resident-packages

fl ../lib/crc32.fth

fl ${CBP}/ofw/objsup.fth
fl ${CBP}/ofw/objects.fth
fl ${BP}/forth/lib/linklist.fth
fl ${BP}/forth/lib/parses1.fth
fl ${BP}/forth/lib/cirstack.fth

fl ${CBP}/ofw/nullfb.fth

fl $(BP)/forth/lib/fileed.fth
fl $(BP)/forth/lib/editcmd.fth
fl $(BP)/forth/lib/cmdcpl.fth
fl $(BP)/forth/lib/fcmdcpl.fth

fl ${CBP}/ofw/core/ofwcore.fth
fl ${CBP}/ofw/core/deblock.fth
fl ${BP}/forth/lib/seechain.fth

fl ../lib/stringar.fth

\ : fl parse-word 2dup type space included ;
\ alias fload fl

fl ${BP}/ofw/disklabel/gpttools.fth

fload ${BP}/ofw/confvar/loadcv.fth	\ Configuration option management

alias rb@ c@
alias rb! c!
alias rw@ w@
alias rw! w!
alias rl@ l@
alias rl! l!

fload ${BP}/ofw/fcode/loadfcod.fth	\ Fcode interpreter
fload ${BP}/ofw/fcode/regcodes.fth	\ Register access words
