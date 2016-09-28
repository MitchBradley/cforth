\ See license at end of file
purpose: Load file for FAT file system support package

fload ${BP}/ofw/fs/fatfs/setup.fth       \ System interface definitions
fload ${BP}/ofw/fs/fatfs/leops.fth       \ Little-endian (Intel) memory access

fload ${BP}/ofw/fs/fatfs/dosdate.fth     \ Conv. to and from DOS packed date/time
fload ${BP}/ofw/fs/fatfs/bpb.fth	 \ BPB definitions
fload ${BP}/ofw/fs/fatfs/diskio.fth      \ Interface to device driver
fload ${BP}/ofw/fs/fatfs/dirent.fth      \ Dir.entry structure & file attrib. defs
fload ${BP}/ofw/fs/fatfs/device.fth      \ Init-fat-cache, ?read-bpb, Set-device
fload ${BP}/ofw/fs/fatfs/rwclusts.fth    \ Cluster access, R/W, cl>sector
fload ${BP}/ofw/fs/fatfs/fat.fth         \ File Attribute Table operations
fload ${BP}/ofw/fs/fatfs/lookup.fth      \ Directory searches
fload ${BP}/ofw/fs/fatfs/fh.fth          \ File Handle descriptor and operations
fload ${BP}/ofw/fs/fatfs/read.fth        \ Opening & seeking for read
fload ${BP}/ofw/fs/fatfs/write.fth       \ Extend-file, dos-write, dos-close
fload ${BP}/ofw/fs/fatfs/create.fth      \ Creating directory entries & new files
fload ${BP}/ofw/fs/fatfs/makefs.fth      \
\ fload ${BP}/ofw/fs/fatfs/command.fth   \ Various user interface commands

\ fload ${BP}/ofw/fs/fatfs/sysdos.fth      \ Forth stream file interface
fload ${BP}/ofw/fs/fatfs/enumdir.fth     \ Enumerate directory entries

fload ${CBP}/ofw/fs/fatfs/methods2.fth     \ External interface methods
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
