unit instructions;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls,
  ComCtrls,
  ExtCtrls,
  Buttons,
  Spin,
  Menus,
  LCLType;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

const
  NOP = $00;
  PROG_RST = $01;
  PROG_ID = $02;
  CHECK_INS = $03;
  FLUSH = $04;
  VREG_EN = $05;
  VREG_DIS = $06;
  SET_PARAMETER = $07;
  SET_T1T2 = 0;
  SET_T3 = 1;
  SET_timeout = 2;
  SET_MN = 3;
  WAIT_T1 = $08;
  WAIT_T2 = $09;
  WAIT_T3 = $0A;
  WAIT_US = $0B;
  READ_ADC = $0C;
  SET_VPP = $0D;
  EN_VPP_VCC = $0E;
  SET_CK_D = $0F;
  READ_PINS = $10;
  LOAD_CONF = $11;
  LOAD_DATA_PROG = $12;
  LOAD_DATA_DATA = $13;
  READ_DATA_PROG = $14;
  READ_DATA_DATA = $15;
  INC_ADDR = $16;
  INC_ADDR_N = $17;
  BEGIN_PROG = $18;
  BULK_ERASE_PROG = $19;
  END_PROG = $1A;
  BULK_ERASE_DATA = $1B;
  END_PROG2 = $1C;
  ROW_ERASE_PROG = $1D;
  BEGIN_PROG2 = $1E;
  CUST_CMD = $1F;
  PROG_C = $20;
  CORE_INS = $21;
  SHIFT_TABLAT = $22;
  TABLE_READ = $23;
  TBLR_INC_N = $24;
  TABLE_WRITE = $25;
  TBLW_INC_N = $26;
  TBLW_PROG = $27;
  TBLW_PROG_INC = $28;
  SEND_DATA = $29;
  READ_DATA = $2A;
  I2C_INIT = $2B;
  I2C_READ = $2C;
  I2C_WRITE = $2D;
  I2C_READ2 = $2E;
  SPI_INIT = $2F;
  SPI_READ = $30;
  SPI_WRITE = $31;
  EXT_PORT = $32;
  AT_READ_DATA = $33;
  AT_LOAD_DATA = $34;
  CLOCK_GEN = $35;
  SIX = $36;
  REGOUT = $37;
  ICSP_NOP = $38;
  TX16 = $39;
  RX16 = $3A;
  uW_INIT = $3B;
  uWTX = $3C;
  uWRX = $3D;
  SIX_LONG = $3E;
  SIX_N = $3F;
  OW_RESET = $40;
  OW_WRITE = $41;
  OW_READ = $42;
  UNIO_STBY = $43;
  UNIO_COM = $44;
  SET_PORT_DIR = $45;
  READ_B = $46;
  READ_AC = $47;
  AT_HV_RTX = $48;
  SIX_LONG5 = $49;
  LOAD_PC = $50;
  LOAD_DATA_INC = $51;
  READ_DATA_INC = $52;
  JTAG_SET_MODE = $53;
  JTAG_SEND_CMD = $54;
  JTAG_XFER_DATA = $55;
  JTAG_XFER_F_DATA = $56;
  ICSP8_SHORT = $57;
  ICSP8_READ = $58;
  ICSP8_LOAD = $59;
  SPI_TEST = $EF;
  READ_RAM = $F0;
  WRITE_RAM = $F1;
  LOOP = $F2;
  TBLRD = $F3;
  TBLWT = $F4;
  REPEAT = $F5;
  REPEAT_END = $F6;
  MAX_INS = $59;

implementation

end.
