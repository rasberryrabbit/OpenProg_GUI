unit Instructions;

// programmer instructions v0.12.0
// C 헤더(instructions.h)의 #define 상수를 Object Pascal 상수로 변환

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

const

  // ── 기본 제어 ──────────────────────────────────────────────────────────────
  NOP               = $00;
  PROG_RST          = $01;   // ->10B
  PROG_ID           = $02;   // ->6B
  CHECK_INS         = $03;   // +1B  ->1B
  FLUSH             = $04;   // no echo
  VREG_EN           = $05;
  VREG_DIS          = $06;

  // ── SET_PARAMETER (0x07) 서브 파라미터 ────────────────────────────────────
  SET_PARAMETER     = $07;   // +3B: 1B parameter, 2B data
    SET_T1T2        = 0;     //   T1, T2
    SET_T3          = 1;     //   T3(H,L)
    SET_timeout     = 2;     //   timeout(H,L)
    SET_MN          = 3;     //   M, N

  // ── 대기 / ADC / VPP / 핀 제어 ───────────────────────────────────────────
  WAIT_T1           = $08;
  WAIT_T2           = $09;
  WAIT_T3           = $0A;
  WAIT_US           = $0B;   // +1B
  READ_ADC          = $0C;   //       ->2B
  SET_VPP           = $0D;   // +1B   ->1B
  EN_VPP_VCC        = $0E;   // +1B
  SET_CK_D          = $0F;   // +1B
  READ_PINS         = $10;   //       ->1B

  // ── PIC ICSP 명령 ─────────────────────────────────────────────────────────
  LOAD_CONF         = $11;   // +2B           000000
  LOAD_DATA_PROG    = $12;   // +2B           000010
  LOAD_DATA_DATA    = $13;   // +2B           000011
  READ_DATA_PROG    = $14;   //       ->2B    000100
  READ_DATA_DATA    = $15;   //       ->1B    000101
  INC_ADDR          = $16;   //               000110
  INC_ADDR_N        = $17;   // +1B           000110
  BEGIN_PROG        = $18;   //               001000
  BULK_ERASE_PROG   = $19;   //               001001
  END_PROG          = $1A;   //               001010
  BULK_ERASE_DATA   = $1B;   //               001011
  END_PROG2         = $1C;   //               001110
  ROW_ERASE_PROG    = $1D;   //               010001
  BEGIN_PROG2       = $1E;   //               011000
  CUST_CMD          = $1F;   // +1B

  // ── PIC18 / dsPIC 확장 ────────────────────────────────────────────────────
  PROG_C            = $20;   // +2B   ->1B    001000 & 001110
  CORE_INS          = $21;   // +2B           0000
  SHIFT_TABLAT      = $22;   //       ->1B    0010
  TABLE_READ        = $23;   //       ->1B    1000
  TBLR_INC_N        = $24;   // +1B   ->1+NB  1001
  TABLE_WRITE       = $25;   // +2B           1100
  TBLW_INC_N        = $26;   // +1+2NB        1101
  TBLW_PROG         = $27;   // +4B           1111
  TBLW_PROG_INC     = $28;   // +4B           1110

  // ── 직렬/병렬 통신 ────────────────────────────────────────────────────────
  SEND_DATA         = $29;   // +3B
  READ_DATA         = $2A;   // +1B   ->1B

  // ── I2C ───────────────────────────────────────────────────────────────────
  I2C_INIT          = $2B;   // +1B
  I2C_READ          = $2C;   // +3B   ->1+NB
  I2C_WRITE         = $2D;   // +3+NB ->1B
  I2C_READ2         = $2E;   // +4B   ->1+NB

  // ── SPI ───────────────────────────────────────────────────────────────────
  SPI_INIT          = $2F;   // +1B
  SPI_READ          = $30;   // +1B   ->1+NB
  SPI_WRITE         = $31;   // +1+NB ->1B

  // ── 확장 포트 / ATmega ────────────────────────────────────────────────────
  EXT_PORT          = $32;   // +2B
  AT_READ_DATA      = $33;   // +3B   ->1+2NB
  AT_LOAD_DATA      = $34;   // +3+2NB ->1B

  // ── 클럭 / dsPIC33 SIX / REGOUT ───────────────────────────────────────────
  CLOCK_GEN         = $35;   // +1B
  SIX               = $36;   // +3B
  REGOUT            = $37;   //       ->2B
  ICSP_NOP          = $38;

  // ── TX16 / RX16 ───────────────────────────────────────────────────────────
  TX16              = $39;   // +1+2NB
  RX16              = $3A;   // +1B   ->1+2NB

  // ── 무선(uW) ──────────────────────────────────────────────────────────────
  uW_INIT           = $3B;
  uWTX              = $3C;   // +1+NB
  uWRX              = $3D;   // +1B   ->+1+NB

  // ── SIX 변형 ──────────────────────────────────────────────────────────────
  SIX_LONG          = $3E;   // +3B
  SIX_N             = $3F;   // +1+3NB

  // ── 1-Wire ────────────────────────────────────────────────────────────────
  OW_RESET          = $40;   //       ->1B
  OW_WRITE          = $41;   // +1+NB
  OW_READ           = $42;   // +1B   ->1+NB

  // ── UNI/O ─────────────────────────────────────────────────────────────────
  UNIO_STBY         = $43;
  UNIO_COM          = $44;   // +2+NB ->1+NB

  // ── 포트 방향 / 핀 읽기 ───────────────────────────────────────────────────
  SET_PORT_DIR      = $45;   // +2B
  READ_B            = $46;   //       ->1B
  READ_AC           = $47;   //       ->1B

  // ── ATmega HV / SIX_LONG5 ────────────────────────────────────────────────
  AT_HV_RTX         = $48;   // +1+2NB ->1B
  SIX_LONG5         = $49;   // +3B

  // ── PIC24 / dsPIC ICSP 추가 ───────────────────────────────────────────────
  LOAD_PC           = $50;   // +2B           011101
  LOAD_DATA_INC     = $51;   // +2B           100010
  READ_DATA_INC     = $52;   //       ->2B    100100

  // ── JTAG ──────────────────────────────────────────────────────────────────
  JTAG_SET_MODE     = $53;   // +1B
  JTAG_SEND_CMD     = $54;   // +1B
  JTAG_XFER_DATA    = $55;   // +4B  ->4B
  JTAG_XFER_F_DATA  = $56;   // +4B  ->4B

  // ── ICSP8 ─────────────────────────────────────────────────────────────────
  ICSP8_SHORT       = $57;   // +1B
  ICSP8_READ        = $58;   // +1B  ->2B
  ICSP8_LOAD        = $59;   // +3B

  // ── 특수 명령 (Special Instructions) ─────────────────────────────────────
  SPI_TEST          = $EF;   // +2B   ->2B
  READ_RAM          = $F0;   // +2B   ->3B
  WRITE_RAM         = $F1;   // +3B   ->3B
  LOOP_INS          = $F2;   // 'LOOP'는 Pascal 예약어 → LOOP_INS 로 변경
  TBLRD             = $F3;   // +3B   ->2B
  TBLWT             = $F4;   // +5B
  REPEAT_INS        = $F5;   // 'REPEAT'는 Pascal 예약어 → REPEAT_INS 로 변경
  REPEAT_END        = $F6;

  // ── 범위 경계 ──────────────────────────────────────────────────────────────
  MAX_INS           = $59;   // 마지막 일반 명령 코드

implementation

end.
