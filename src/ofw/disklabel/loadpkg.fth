\ See license at end of file
purpose: Load file for multi-format disk-label support package

fload ${BP}/ofw/disklabel/common.fth
fload ${BP}/ofw/fs/fatfs/partition.fth

[ifdef] cdfs-support
fload ${BP}/ofw/fs/cdfs/partition.fth
[else]
alias iso-9660? false
[then]

[ifdef] ufs-support
fload ${BP}/ofw/fs/ufs/partition.fth
[then]

[ifdef] ext2-support
fload ${BP}/ofw/fs/ext2fs/partition.fth
[else]
alias ext2? false
[then]

[ifdef] ntfs-support
fload ${BP}/ofw/fs/ntfs/partition.fth
[else]
alias ntfs? false
[then]

[ifdef] hfs-support
fload ${BP}/ofw/fs/macfs/partition.fth
[then]

fload ${BP}/ofw/disklabel/gpt.fth

[then]
fload ${BP}/ofw/disklabel/methods.fth

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
