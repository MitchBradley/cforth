\ OLPC boot script

\ dev.laptop.org #6210 test script
\ Exercises several OFW features on an ext2 filesystem on a USB stick
\ see associated test.sh

[ifndef] $md5sum-file
: $md5sum-file  ( prefix$ filename$ -- )
   \ Read file into memory and compute its MD5 hash
   2dup $read-file abort" Read error" ( prefix$ filename$ adr len )
   2dup $md5digest1        ( prefix$ filename$ adr len md5$ )
   2swap free-mem          ( prefix$ filename$ md5$ )

   \ Write the hash and the filename in the same format as
   \ the output of the Linux "md5sum" command.  prefix$ should
   \ be " *" to match the output of "md5sum -b" and "  "
   \ to match the output of "md5sum" without -b.

   \ Output MD5 in lower case ASCII hex
   push-hex                ( prefix$ filename$ md5$ )
   bounds  ?do             ( prefix$ filename$ )
      i c@  <# u# u# u#> type
   loop                    ( prefix$ filename$ )
   pop-base                ( prefix$ filename$ )

   \ ... followed by "  filename" or " *filename"
   ."  "                   ( prefix$ filename$ )
   2swap type              ( filename$ )
   type                    ( )
   cr
;

: md5sum  ( "file" -- )
   "  " safe-parse-word $md5sum-file
;
[then]

0 value a-adr
0 value a-len
0 value b-adr
0 value b-len

: (read-files)  ( "a" "b" -- )
   safe-parse-word $read-file abort" Read error"
   to b-len to b-adr
   safe-parse-word $read-file abort" Read error"
   to a-len to a-adr
;

: (compare-files)  ( -- equal-flag )
   a-len b-len = if
      a-adr b-adr b-len comp 0=
   else
      false
   then
;

: (free-files)
   a-adr a-len free-mem
   b-adr b-len free-mem
;

: compare-files
   (read-files) (compare-files) (free-files)
   if ." files equal" cr else ." files differ" cr then
;

: compare-md5-files
   (read-files)
   d# 32 to a-len
   d# 32 to b-len
   (compare-files)
   (free-files)
   if ." checksums equal" cr else ." checksums differ" cr then
;

visible
no-page

.( test.fth ticket #6210 ofw ext2 filesystem tests ) cr

.( test 0001 define u: ) cr
volume: u:

.( test 0002 reference u: ) cr
u:

.( test 0003 directory ) cr
dir

.( test 0004 directory by name ) cr
dir boot\*.fth

.( test 0005 chdir down ) cr
chdir directory

.( test 0006 directory of subdirectory after chdir ) cr
dir

.( test 0007 chdir up ) cr
chdir ..

.( test 0008 directory of main directory after chdir ) cr
dir

.( test 0009 disk free ) cr
disk-free u:\

.( test 0010 display a file ) cr
more u:\hello

.( test 0011 display a file with a hyphen in file name ) cr
more u:\hello-world

.( test 0012 display a link ) cr
more u:\hello-link

.( test 0013 directory of subdirectory by name ) cr
dir u:\directory

.( test 0014 display a file in subdirectory ) cr
more u:\directory\hw

.( test 0015 copy a file ) cr
copy u:\hello-world u:\copy
.(           ) compare-files u:\hello-world u:\copy

.( test 0016 display the copy ) cr
more u:\copy

.( test 0017 rename the copy ) cr
rename u:\copy u:\renamed

.( test 0018 delete the renamed copy ) cr
del u:\renamed

.( test 0019 delete a non-existent file ) cr
del u:\vapour

.( test 0020 calculate md5sum of a test file ) cr
.(           ) md5sum u:\hello-world

.( test 0021 calculate md5sum of a test file and save to a file ) cr
del u:\tmp.md5
to-file u:\tmp.md5  md5sum u:\hello-world
.(           ) compare-md5-files u:\tmp.md5 u:\hello-world.md5
del u:\tmp.md5

.( test 0022 dump forth dictionary to file ) cr
to-file u:\words.txt  words
to-file u:\words.tmp  words
.(           ) compare-files u:\words.txt u:\words.tmp
del u:\words.txt
del u:\words.tmp

.( test 0023 glob file copy ) cr

.(           create input files ... )
.( a ) to-file u:\a.tst  cr
.( b ) to-file u:\b.tst  cr
.( c ) to-file u:\c.tst  cr
.( d ) to-file u:\d.tst  cr
.( e ) to-file u:\e.tst  cr
.( f ) to-file u:\f.tst  cr
cr

.(           create directory ... )
mkdir u:\j
.( ok ) cr

.(           copy ... )
copy u:\*.tst u:\j
.( ok ) cr

.(           delete copies ... )
.( a ) del u:\j\a.tst
.( b ) del u:\j\b.tst
.( c ) del u:\j\c.tst
.( d ) del u:\j\d.tst
.( e ) del u:\j\e.tst
.( f ) del u:\j\f.tst
.( ok ) cr

.(           delete directory ... )
rmdir u:\j
.( ok ) cr

.(           delete input files )
.( a ) del u:\a.tst
.( b ) del u:\b.tst
.( c ) del u:\c.tst
.( d ) del u:\d.tst
.( e ) del u:\e.tst
.( f ) del u:\f.tst
.( ok ) cr

.( test complete ) cr
