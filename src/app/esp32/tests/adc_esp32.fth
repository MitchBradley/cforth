\  adc_esp32.fth

#32 constant /adc_chars
  0 value    &adc_chars
  0 constant vref  \ The reference voltage stored in eFuse during factory calibration

: init-adc ( adc-channel bit_precision attenuation -- )
   &adc_chars 0=   \ Assumes: vref, bit_precision and attenuation are the same for
      if    /adc_chars allocate throw to &adc_chars       \ the used adc-channels.
      then
   >r dup adc-width!
   r@ rot adc-atten!
\ ( a.adc_chars i.vref i.bi_width i.atten i.adc_num -- i.res )
    &adc_chars  vref   rot        r>      1 get-adc-chars drop ;

: read-adc-mv ( adc-channel - mV )
   &adc_chars swap  adc@  adc-mv ;

#10 constant #samples

: adc-mv-av ( adc-channel - mV )
   #samples >r 0 r@ 0
      do  over read-adc-mv +
      loop
   r> / nip ;

\ EG:
\ decimal 5 dup 3 3 init-adc adc-mv-av .

0 [if]

\ Used test circuit:
\           10K           10K
\  Gnd ___/\/\/\/\______/\/\/\/\____Vcc
\                   |
\                  To ADC

decimal

: test-adc ( adc-channel - )
   dup #3 #3 init-adc
   cr ." adc@ read-adc-mv"
   #10 >r 0 r@ 0
     do   cr  over  adc@ . over read-adc-mv dup . +
     loop
   cr ." Average read-adc-mv: " tuck r> / . 2drop
   &adc_chars free drop 0 to &adc_chars ;

5 test-adc

[then]

0 [if]
\ Measuring with a DVM: 1644-1946 mV
\ Seen in test-adc:

adc@ read-adc-mv
1839 1626
1858 1626
1841 1644
1828 1625
1834 1639
1826 1632
1857 1635
1835 1639
1858 1645
1834 1639
Average read-adc-mv: 1635 \ Seen minimal

adc@ read-adc-mv
1886 1674
1895 1690
1895 1669
1884 1676
1905 1690
1875 1665
1894 1675
1915 1746
1891 1674
1894 1682
Average read-adc-mv: 1684 \ Seen maximal

[then]
\ /s
