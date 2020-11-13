$29 constant vl-i2c-slave
: ?vl-abort  ( flag -- )  abort" Vl I2C Failed"  ;
: vl-b@  ( reg# -- b )  vl-i2c-slave false i2c-b@  ;
: vl-b!  ( b reg# -- )  vl-i2c-slave i2c-b! ?vl-abort  ;
: vl-w@  ( reg# -- b )  vl-i2c-slave false i2c-be-w@  ;
: vl-w!  ( b reg# -- )  vl-i2c-slave i2c-be-w! ?vl-abort  ;

1 buffer: vl-i2c-reg
8 buffer: vl-i2c-buf

: vl-read  ( adr len reg# -- )
   vl-i2c-reg c!
   vl-i2c-reg 1  2swap  vl-i2c-slave false  i2c-write-read ?vl-abort
;
: vl-write  ( adr len reg# -- )
   vl-i2c-buf c!                  ( adr len )
   tuck  vl-i2c-buf 1+  swap move ( len )
   vl-i2c-buf swap 1+  0 0   vl-i2c-slave false  i2c-write-read ?vl-abort
;

: vl-l@  ( reg# -- l )
   vl-i2c-buf 4  rot  vl-read
   vl-i2c-buf be-l@
;
: vl-l!  ( l reg# -- )
   vl-i2c-buf c!
   vl-i2c-buf 1+ be-l!
   vl-i2c-reg 5  0 0  vl-i2c-slave false  i2c-write-read ?vl-abort
;

#1000 value io-timeout

$00 constant SYSRANGE_START

$0C constant THRESH_HIGH
$0E constant THRESH_LOW

$01 constant SEQUENCE
$09 constant RANGE
$04 constant INTERMEASUREMENT_PERIOD

$0A constant INTERRUPT_GPIO

$84 constant GPIO_HV_MUX_ACTIVE_HIGH

$0B constant INTERRUPT_CLEAR

$13 constant INTERRUPT_STATUS
$14 constant RANGE_STATUS

$BC constant CORE_AMBIENT_WINDOW_EVENTS_RTN
$C0 constant CORE_RANGING_TOTAL_EVENTS_RTN
$D0 constant CORE_AMBIENT_WINDOW_EVENTS_REF
$D4 constant CORE_RANGING_TOTAL_EVENTS_REF
$B6 constant PEAK_SIGNAL_RATE_REF

$28 constant ALGO_PART_TO_PART_RANGE_OFFSET_MM

$8A constant I2C_SLAVE_DEVICE_ADDRESS

$60 constant MSRC_CONTROL

$27 constant PRE_MIN_SNR
$56 constant PRE_VALID_PHASE_LOW
$57 constant PRE_VALID_PHASE_HIGH
$64 constant PRE_RANGE_MIN_COUNT_RATE_RTN_LIMIT

$67 constant FINAL_MIN_SNR
$47 constant FINAL_VALID_PHASE_LOW
$48 constant FINAL_VALID_PHASE_HIGH
$44 constant FINAL_MIN_COUNT_RATE_RTN_LIMIT

$61 constant PRE_SIGMA_THRESH_HI
$62 constant PRE_SIGMA_THRESH_LO

$50 constant PRE_VCSEL_PERIOD
$51 constant PRE_MACROP_HI
$52 constant PRE_MACROP_LO

$81 constant HISTOGRAM_BIN
$33 constant HISTOGRAM_INITIAL_PHASE_SELECT
$55 constant HISTOGRAM_READOUT_CTRL

$70 constant FINAL_VCSEL_PERIOD
$71 constant FINAL_MACROP_HI
$72 constant FINAL_MACROP_LO
$20 constant CROSSTALK_COMPENSATION_PEAK_RATE_MCPS

$46 constant MSRC_MACROP

$BF constant SOFT_RESET_GO2_SOFT_RESET_N
$C0 constant IDENTIFICATION_MODEL_ID
$C2 constant IDENTIFICATION_REVISION_ID

$F8 constant OSC_CALIBRATE_VAL

$32 constant VCSEL_WIDTH
$B0 constant SPAD_ENABLES_REFS

$B6 constant REF_EN_START_SELECT
$4E constant SPAD_NUM_REQUESTED_REF_SPAD
$4F constant SPAD_REF_EN_START_OFFSET
$80 constant POWER_MANAGEMENT_GO1_POWER_FORCE

$89 constant VHV_PAD_SCL_SDA__EXTSUP_HV

$30 constant ALGO_PHASECAL_LIMIT
$30 constant ALGO_PHASECAL_TIMEOUT

\ Decode VCSEL (vertical cavity surface emitting laser) pulse period in PCLKs
\ from register value
\ based on VL53L0X_decode_vcsel_period()
: decodeVcselPeriod ( reg -- pclks )  1+ 2*  ;
: encodeVcselPeriod ( pclks -- reg )  u2/ 1-  ;

\ Calculate macro period in *nanoseconds* from VCSEL period in PCLKs
\ based on VL53L0X_calc_macro_period_ps()
\ PLL_period_ps = 1655; macro_period_vclks = 2304
: calcMacroPeriod ( pclks -- ns )  #2304 *  #1655 *  #500 +  #1000 /  ;

\ Convert sequence step timeout from microseconds to MCLKs with given VCSEL period in PCLKs
\ based on VL53L0X_calc_timeout_mclks()
: UsToMclks ( us pclks -- mclks )
   calcMacroPeriod                   ( us ns )
   tuck 2/  swap #1000 *  +          ( ns ms )
   swap /                            ( mclks )
;

: MclksToUs ( mclks pclks -- us )
   calcMacroPeriod              ( mclks ns )
   tuck *  swap 2/ +  #1000 /   ( us )
;

: decodeTimeout  ( regval -- mclks )
   wbsplit  ( low high )
   rshift 1+
;

\ Encode sequence step timeout register value from timeout in MCLKs
\ based on VL53L0X_encode_timeout()
: encodeTimeout  ( mclks -- regval )
   dup 0=  if  exit  then        ( mclks )
   1-  0                         ( mclks' shift )
   begin  over $ff00 and  while  ( mclks shift )
      swap u2/  swap 1+          ( mclks' shift' )
   repeat                        ( mclks shift )
   bwjoin                        ( regval )
;


: clear-interrupts  ( -- )  $01 INTERRUPT_CLEAR vl-b!  ;

: wait-interrupt  ( -- )
   get-msecs io-timeout +        ( limit-ms )
   begin                         ( limit-ms )
      INTERRUPT_STATUS vl-b@ 7 and  if  drop exit  then  ( limit-ms )
      dup get-msecs -  0<        ( limit-ms )
   until                         ( limit-ms )
   drop 
;

\ based on VL53L0X_perform_single_ref_calibration()
: performSingleRefCalibration ( vhv_init_byte -- )
  1 or  SYSRANGE_START vl-b!  \ VL53L0X_REG_SYSRANGE_MODE_START_STOP
  wait-interrupt
  clear-interrupts
  $00 SYSRANGE_START vl-b!
;
: calibrate  ( vhv_init_byte sequence -- )
   SEQUENCE vl-b@ >r   ( vhv_init_byte sequence r: old-sequence )
   SEQUENCE vl-b!      ( vhv_init_byte )
   performSingleRefCalibration  ( r: old-sequence )
   r> SEQUENCE vl-b!
;

: start-ranging  ( mode -- )  SYSRANGE_START vl-b!  ;

0 value spad-info
\ Get reference SPAD (single photon avalanche diode) count and type
\ based on VL53L0X_get_info_from_device(),
\ but only gets reference SPAD count and type
: getSpadInfo  ( count, bool * type_is_aperture -- )
   $01 $80 vl-b!
   $01 $FF vl-b!
   $00 $00 vl-b!
   $06 $FF vl-b!
   $83 vl-b@ $04 or  $83 vl-b!
   $07 $FF vl-b!
   $01 $81 vl-b!
   $01 $80 vl-b!
   $6b $94 vl-b!
   $00 $83 vl-b!

   $00 $83 vl-b!
   get-msecs  io-timeout +   ( limit-msecs )
   begin
      dup get-msecs - 0<  if  drop exit  then
      $83 vl-b@
   until
   $01 $83 vl-b!

   $92 vl-b@ to spad-info

   $00 $81 vl-b!
   $06 $FF vl-b!
   $83 vl-b@  $04 invert and  $83 vl-b!
   $01 $FF vl-b!
   $01 $00 vl-b!

   $00 $FF vl-b!
   $00 $80 vl-b!
;

: bitclear  ( adr bit# -- )
   8 /mod                   ( adr bit# byte# )
   rot +                    ( bit# adr' )
   tuck c@                  ( adr bit# byte )
   1 rot lshift invert and  ( adr byte' )
   swap c!                  ( )
;

6 buffer: ref-spad-map

: set-reference-spads  ( -- )
   getSpadInfo

   \ The SPAD map (RefGoodSpadMap) is read by VL53L0X_get_info_from_device() in
   \ the API, but the same data seems to be more easily readable from
   \ SPAD_ENABLES_REF_0 through _6, so read it from there
   ref-spad-map 6 SPAD_ENABLES_REFS vl-read

   \ -- VL53L0X_set_reference_spads() begin (assume NVM values are valid)

   $01 $FF vl-b!
   $00 SPAD_REF_EN_START_OFFSET vl-b!
   $2c SPAD_NUM_REQUESTED_REF_SPAD vl-b!
   $00 $FF vl-b!
   $b4 REF_EN_START_SELECT vl-b!

   spad-info $80 and  if  #12  else  0  then  ( first-spad )
   spad-info $7f and                          ( first-spad spad-count )
   0                                          ( first-spad spad-count #spads )
   #48 0  do                                  ( first-spad spad-count #spads )
      2dup =                                  ( first-spad spad-count #spads =? )
      i 4 pick <  or  if                      ( first-spad spad-count #spads )
         \ This bit is lower than the first one that should be enabled, or
         \ spad_count bits have already been enabled, so zero this bit
         ref-spad-map i bitclear
      else                                   ( first-spad spad-count #spads )
         1+                                  ( first-spad spad-count #spads' )
      then                                   ( first-spad spad-count #spads' )
   loop                                      ( first-spad spad-count #spads' )
   3drop

   ref-spad-map 6 SPAD_ENABLES_REFS vl-write
;

create tunings
   $01 c, $FF c,
   $00 c, $00 c,
   $00 c, $FF c,
   $00 c, $09 c,
   $00 c, $10 c,
   $00 c, $11 c,
   $01 c, $24 c,
   $FF c, $25 c,
   $00 c, $75 c,
   $01 c, $FF c,
   $2C c, $4E c,
   $00 c, $48 c,
   $20 c, $30 c,
   $00 c, $FF c,
   $09 c, $30 c,
   $00 c, $54 c,
   $04 c, $31 c,
   $03 c, $32 c,
   $83 c, $40 c,
   $25 c, $46 c,
   $00 c, $60 c,
   $00 c, $27 c,
   $06 c, $50 c,
   $00 c, $51 c,
   $96 c, $52 c,
   $08 c, $56 c,
   $30 c, $57 c,
   $00 c, $61 c,
   $00 c, $62 c,
   $00 c, $64 c,
   $00 c, $65 c,
   $A0 c, $66 c,
   $01 c, $FF c,
   $32 c, $22 c,
   $14 c, $47 c,
   $FF c, $49 c,
   $00 c, $4A c,
   $00 c, $FF c,
   $0A c, $7A c,
   $00 c, $7B c,
   $21 c, $78 c,
   $01 c, $FF c,
   $34 c, $23 c,
   $00 c, $42 c,
   $FF c, $44 c,
   $26 c, $45 c,
   $05 c, $46 c,
   $40 c, $40 c,
   $06 c, $0E c,
   $1A c, $20 c,
   $40 c, $43 c,
   $00 c, $FF c,
   $03 c, $34 c,
   $44 c, $35 c,
   $01 c, $FF c,
   $04 c, $31 c,
   $09 c, $4B c,
   $05 c, $4C c,
   $04 c, $4D c,
   $00 c, $FF c,
   $00 c, $44 c,
   $20 c, $45 c,
   $08 c, $47 c,
   $28 c, $48 c,
   $00 c, $67 c,
   $04 c, $70 c,
   $01 c, $71 c,
   $FE c, $72 c,
   $00 c, $76 c,
   $00 c, $77 c,
   $01 c, $FF c,
   $01 c, $0D c,
   $00 c, $FF c,
   $01 c, $80 c,
   $F8 c, $01 c,
   $01 c, $FF c,
   $01 c, $8E c,
   $01 c, $00 c,
   $00 c, $FF c,
   $00 c, $80 c,
here tunings - constant /tunings

: set-registers  ( adr len -- )
   bounds ?do
      i c@  i 1+ c@  vl-b!
   2 +loop
;

0 value enables
: getEnables  ( -- )  $01 vl-b@ to enables ;     \ final_range pre_range X tcc  dss msrc  X X
$04 constant msrc
$08 constant dss
$10 constant tcc
$40 constant pre_range
$80 constant final_range

0 value msrc_dss_tcc_us
0 value pre_us
0 value final_us

0 value msrc_dss_tcc_mclks
0 value pre_mclks
0 value final_mclks

0 value pre_pclks
0 value final_pclks

: getTimeouts  ( -- )
   getEnables

   PRE_VCSEL_PERIOD vl-b@ decodeVcselPeriod to pre_pclks

   MSRC_MACROP vl-b@ 1+ to msrc_dss_tcc_mclks
   msrc_dss_tcc_mclks pre_pclks +  MclksToUs to msrc_dss_tcc_us

   PRE_MACROP_HI vl-w@  decodeTimeout to pre_mclks

   pre_mclks pre_pclks MclksToUs  to pre_us

   FINAL_VCSEL_PERIOD vl-b@  decodeVcselPeriod to final_pclks

   FINAL_MACROP_HI vl-w@ decodeTimeout  ( final_mclks )

   enables pre_range and  if  pre_mclks -   then   ( final_mclks )
  
   final_pclks MclksToUs  to final_us   ( )
;

#1910 constant getStartOH
#1320 constant SetStartOH
#960 constant EndOH
#660 constant MsrcOH
#590 constant TccOH
#690 constant DssOH
#660 constant PreRangeOH
#550 constant FinalRangeOH

\ Get the measurement timing budget in microseconds
\ based on VL53L0X_get_measurement_timing_budget_micro_seconds()
0 value budget_us
: getTiming ( -- )
   getTimeouts

   \ "Start and end overhead times always present"
   getStartOH EndOH +   ( us )

   enables tcc and  if  msrc_dss_tcc_us +  TccOH +  then  ( us )

   enables dss and  if    ( us )
      msrc_dss_tcc_us DssOH +  2* +
   else                   ( us )
      enables msrc and  if  msrc_dss_tcc_us +  MsrcOH +  then    ( us )
   then                   ( us )

   enables pre_range and  if  pre_us +  PreRangeOH +  then       ( us )
   enables final_range and  if  final_us +  FinalRangeOH +  then ( us )

   to budget_us    ( )
;

\ Set the measurement timing budget in microseconds, which is the time allowed
\ for one measurement; the ST API and this library take care of splitting the
\ timing budget among the sub-steps in the ranging sequence. A longer timing
\ budget allows for more accurate measurements. Increasing the budget by a
\ factor of N decreases the range measurement standard deviation by a factor of
\ sqrt(N). Defaults to about 33 milliseconds; the minimum is 20 ms.
\ based on VL53L0X_set_measurement_timing_budget_micro_seconds()
: setTiming  ( -- )
   budget_us #20000 <  if  exit  then

   getTimeouts

   SetStartOH EndOH +   ( us )

   enables tcc and  if  msrc_dss_tcc_us + TccOH +  then  ( us )

   enables dss and  if
      msrc_dss_tcc_us DssOH +  2*  +
   else
      enables msrc and  if
         msrc_dss_tcc_us + MsrcOH +
      then
   then

   enables pre_range and  if  pre_us + PreRangeOH +  then  ( us )

   enables final_range and  if   ( us )
      FinalRangeOH +              ( us )

      \ "Note that the final range timeout is determined by the timing
      \ budget and the sum of all other timeouts within the sequence.
      \ If there is no room for the final range timeout, then an error
      \ will be set. Otherwise the remaining time will be applied to
      \ the final range."

      budget_us swap -             ( final-us )
      dup 0<  if  drop exit  then  ( final-us )

      \ (SequenceStepId == VL53L0X_SEQUENCESTEP_FINAL_RANGE)
      \ "For the final range timeout, the pre-range timeout
      \  must be added. To do this both final and pre-range
      \  timeouts must be expressed in macro periods MClks
      \  because they have different vcsel periods."

      final_pclks UsToMclks  ( mclks )

      enables pre_range and  if  pre_mclks +   then   ( mclks )

      encodeTimeout FINAL_MACROP_HI vl-w!
   then
;

0 value stop_variable

: init-vl53l0x  ( -- )
   \ sensor uses 1V8 mode for I/O by default; switch to 2V8 mode if necessary
[ifdef] io-2v8
   $89 vl-b@  1 or  $89 vl-b!
[then]
   $00 $88 vl-b!    \ Set I2C standard mode

   $01 $80 vl-b!
   $01 $FF vl-b!
   $00 $00 vl-b!
   $91 vl-b@ to stop_variable
   $01 $00 vl-b!
   $00 $FF vl-b!
   $00 $80 vl-b!

   \ disable SIGNAL_RATE_MSRC (bit 1) and SIGNAL_RATE_PRE_RANGE (bit 4) limit checks
   $60 vl-b@ $12 or $60 vl-b!

   \ set final range signal rate limit to 0.25 MCPS (million counts per second)
   #32 $44 vl-w!  \ 1.0 is represented by 128, so 32 is 0.25

   $ff SEQUENCE vl-b!

   \ VL53L0X_DataInit() end

   \ VL53L0X_StaticInit() begin

   set-reference-spads

   \ -- VL53L0X_load_tuning_settings() begin
   \ DefaultTuningSettings from vl53l0x_tuning.h

   tunings /tunings set-registers

   \ -- VL53L0X_load_tuning_settings() end

   \ "Set interrupt config to new sample ready"
   \ -- VL53L0X_SetGpioConfig() begin

   $04 INTERRUPT_GPIO vl-b!
   $84 vl-b@ $10 invert and $84 vl-b!  \ GPIO_HV_MUX_ACTIVE_HIGH
   clear-interrupts

   \ -- VL53L0X_SetGpioConfig() end

   getTiming

   \ "Disable MSRC and TCC by default"
   \ MSRC = Minimum Signal Rate Check
   \ TCC = Target CentreCheck
   $e8 SEQUENCE vl-b!

   setTiming \ Recalculate timing budget

   \ VL53L0X_StaticInit() end

   $40 $01 calibrate    \ calibrate vhv
   $00 $02 calibrate    \ calibrate phase
;

: set-vcsel-timings  ( limit timeout width phase-low phase-high -- )
   FINAL_VALID_PHASE_HIGH vl-b!
   FINAL_VALID_PHASE_LOW vl-b!
   VCSEL_WIDTH vl-b!
   ALGO_PHASECAL_TIMEOUT vl-b!
   $01 $ff vl-b!
   ALGO_PHASECAL_LIMIT vl-b!
   $00 $ff vl-b!
;

: phase-cal  ( -- )
   \ Re-apply the timing budget
   setTiming

   \ Recalibrate the phase after having changed the vcsel period
   SEQUENCE vl-b@       ( old-val )
   $02 SEQUENCE vl-b!   ( old-val )
   $00 performSingleRefCalibration
   SEQUENCE vl-b!       ( )
;

\ Set the VCSEL (vertical cavity surface emitting laser) pulse period for the
\ given period type (pre-range or final range) to the given value in PCLKs.
\ Longer periods seem to increase the potential range of the sensor.
\ Valid values are (even numbers only):
\  pre:  12 to 18 (initialized default: 14)
\  final: 8 to 14 (initialized default: 10)
\ based on VL53L0X_set_vcsel_pulse_period()
: setPrePulsePeriod  ( pclks -- )
   getTimeouts

   \ "Set phase check limits"
   dup case                     ( pclks )
      #12 of  $18  endof
      #14 of  $30  endof
      #16 of  $40  endof
      #18 of  $50  endof
      ( default )  2drop exit
   endcase                      ( pclks regval )
   PRE_VALID_PHASE_HIGH vl-b!    ( pclks )
   $08 PRE_VALID_PHASE_LOW vl-b! ( pclks )

   dup encodeVcselPeriod PRE_VCSEL_PERIOD vl-b!  ( pclks )

   \ update timeouts

   \ set_sequence_step_timeout() begin
   \ (SequenceStepId == VL53L0X_SEQUENCESTEP_PRE_RANGE)

   pre_us over UsToMclks                ( pclks mclks )
   encodeTimeout PRE_MACROP_HI vl-w!  ( pclks )

   \ set_sequence_step_timeout() end

   \ set_sequence_step_timeout() begin
   \ (SequenceStepId == VL53L0X_SEQUENCESTEP_MSRC)

   msrc_dss_tcc_us swap UsToMclks  ( mclks )
   #256 min  1-  MSRC_MACROP vl-b!

   \ set_sequence_step_timeout() end
   phase-cal
;

: setFinalPulsePeriod  ( pclks -- )
   getTimeouts

   \ "Apply specific settings for the requested clock period"
   \ "Re-calculate and apply timeouts, in macro periods"

   \ "When the VCSEL period for the pre or final range is changed,
   \ the corresponding timeout must be read from the device using
   \ the current VCSEL period, then the new VCSEL period can be
   \ applied. The timeout then must be written back to the device
   \ using the new VCSEL period.
   \
   \ For the MSRC timeout, the same applies - this timeout being
   \ dependant on the pre-range vcsel period."

   dup case             ( pclks )
      #08 of   $30 $0c $02 $08 $10 set-vcsel-timings  endof
      #10 of   $20 $09 $03 $08 $28 set-vcsel-timings  endof
      #12 of   $20 $08 $03 $08 $38 set-vcsel-timings  endof
      #14 of   $20 $07 $03 $08 $48 set-vcsel-timings  endof
      ( default )  2drop exit
   endcase

   dup encodeVcselPeriod FINAL_VCSEL_PERIOD vl-b!    \ apply new VCSEL period

   \ update timeouts

   \ (SequenceStepId == VL53L0X_SEQUENCESTEP_FINAL_RANGE)

   \ "For the final range timeout, the pre-range timeout
   \  must be added. To do this both final and pre-range
   \  timeouts must be expressed in macro periods MClks
   \  because they have different vcsel periods."

   final_us swap UsToMclks   ( mclks )
   enables pre_range and  if  pre_mclks +  then  ( mclks )

   encodeTimeout FINAL_MACROP_HI vl-w!

   phase-cal
;

: continuous-on  ( -- )
   $01 $80 vl-b!
   $01 $FF vl-b!
   $00 $00 vl-b!
   stop_variable $91 vl-b!
   $01 $00 vl-b!
   $00 $FF vl-b!
   $00 $80 vl-b!
;

\ Start continuous ranging measurements. If period_ms (optional) is 0 or not
\ given, continuous back-to-back mode is used (the sensor takes measurements as
\ often as possible); otherwise, continuous timed mode is used, with the given
\ inter-measurement period in milliseconds determining how often the sensor
\ takes a measurement.
\ based on VL53L0X_StartMeasurement()
: startContinuous ( period_ms -- )
  continuous-on         ( period_ms )
  ?dup  if              ( period_ms )
    \ continuous timed mode
    OSC_CALIBRATE_VAL vl-w@        ( period_ms osc_cal_val )
    ?dup  if  *  then              ( period_ms )

    INTERMEASUREMENT_PERIOD vl-l!  ( )

    $04 start-ranging \ timed mode
  else
    $02 start-ranging \ backtoback mode
  then
;

\ Stop continuous measurements
\ based on VL53L0X_StopMeasurement()
: stopContinuous ( -- )
   $01 start-ranging \ singleshot mode

   $01 $FF vl-b!
   $00 $00 vl-b!
   $00 $91 vl-b!
   $01 $00 vl-b!
   $00 $FF vl-b!
;

\ Returns a range reading in millimeters when continuous mode is active
\ (readRangeSingleMillimeters() also calls this function after starting a
\ single-shot range measurement)
: readRangeContinuousMillimeters  ( -- mm )
   get-msecs io-timeout +             ( limit-ms )
   begin                              ( limit-ms )
      dup get-msecs - 0<  if  drop #65535 exit  then  ( limit-ms )
      INTERRUPT_STATUS vl-b@ 7 and    ( limit-ms flag )
   until                              ( limit-ms )
   drop                               ( )

   \ assumptions: Linearity Corrective Gain is 1000 (default);
   \ fractional ranging is not enabled
   RANGE_STATUS #10 + vl-w@   ( mm )
   clear-interrupts  ( mm )
;

\ Performs a single-shot range measurement and returns the reading in mm
\ based on VL53L0X_PerformSingleRangingMeasurement()
: readRangeSingleMillimeters ( -- mm )
   continuous-on

   $01 start-ranging \ singleshot mode

   \ "Wait until start bit has been cleared"
   get-msecs io-timeout +      ( limit-ms )
   begin                       ( limit-ms )
      dup get-msecs - 0<  if   ( limit-ms )
         drop #65535 exit      ( -- mm )
      then                     ( limit-ms )
      SYSRANGE_START vl-b@ 1 and  0= ( limit-ms flag )
   until                       ( limit-ms )
   drop                        ( )

   readRangeContinuousMillimeters
;
