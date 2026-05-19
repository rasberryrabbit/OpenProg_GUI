unit opgui;
{
  opgui.pas
  Open Programmer GUI - 메인 컨트롤 유닛
  원본 C 소스: opgui.c (Copyright (C) 2009-2025 Alberto Maccioni)
  Free Pascal / Lazarus 변환

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
}

{$mode objfpc}{$H+}
{$IFDEF LINUX}
  {$DEFINE UNIX}
{$ENDIF}

interface

uses
  SysUtils, Classes, Math,
  // Lazarus LCL
  Forms, Controls, StdCtrls, ComCtrls, ExtCtrls,
  Dialogs, Menus, Buttons, Spin, LMessages,
  LCLType, LCLIntf,
  // 프로젝트 내부 유닛
  common, deviceRW, fileIO, I2CSPI, icd, progAVR
  {$IFDEF UNIX}
  , BaseUnix, Unix, termio
  {$ELSE}
  , Windows
  {$ENDIF}
  ;

{ ============================================================
  상수
  ============================================================ }
const
  MAXLINES    = 600;
  CONFIG_FILE = 'opgui.ini';
  CONFIG_DIR  = '.opgui';

{ ============================================================
  열거형
  ============================================================ }
type
  TDevColumn = (dcID = 0, dcName, dcGroup);

  TSortType = (stName = 0, stGroup);

  TGroupType = (
    grpPIC1012 = 0,
    grpPIC16,
    grpPIC18,
    grpPIC24,
    grpPIC3033,
    grpAVR,
    grpMEMORY,
    NUM_GROUPS
  );

  { IO 버튼 레코드 (GTK struct io_btn → Pascal record) }
  TIOBtn = record
    Name : string;
    x, y : Integer;
    r_0  : TRadioButton;   // 출력 0
    r_1  : TRadioButton;   // 출력 1
    r_I  : TRadioButton;   // 입력
    e_I  : TLabel;         // 입력 표시 레이블
  end;

{ ============================================================
  TMainForm – LFM의 object window: TForm 에 대응
  ============================================================ }
  TMainForm = class(TForm)
    { ── 툴바 ── }
    MainToolBar  : TToolBar;
    OPEN_T       : TToolButton;
    SAVE_T       : TToolButton;
    ToolSep1     : TToolButton;
    READ_T       : TToolButton;
    WRITE_T      : TToolButton;
    ToolSep2     : TToolButton;
    STOP_T       : TToolButton;
    CONNECT_T    : TToolButton;
    INFO_T       : TToolButton;

    { ── 노트북(탭) ── }
    NOTEBOOK     : TPageControl;

    { 탭0: DATA }
    TabSheet_dati    : TTabSheet;
    DATA             : TMemo;

    { 탭1: Device }
    TabSheet_dev     : TTabSheet;
    TYPE_L           : TLabel;
    TYPE_C           : TComboBox;
    DEV_SRC_L        : TLabel;
    DEV_SRC_E        : TEdit;
    DEV_TREE         : TListView;
    DEV_INFO         : TLabel;
    DEVICE_NAME      : TLabel;
    EE_RW            : TCheckBox;
    RES_READ         : TCheckBox;
    PROG_ID          : TCheckBox;
    PROG_CAL12       : TCheckBox;
    USE_SAFLOCK      : TCheckBox;
    OSC_OPT          : TGroupBox;
    OSCCAL_L         : TLabel;
    OSCCAL           : TRadioButton;
    BKOSCCAL         : TRadioButton;
    FILECAL          : TRadioButton;
    ICD_OPT          : TGroupBox;
    ICD              : TCheckBox;
    ICD_ADDR_L       : TLabel;
    ICD_ADDR         : TEdit;
    CW_OPT           : TGroupBox;
    FORCE_CW         : TCheckBox;
    CW1_OPT          : TPanel;  CW1 : TEdit;
    CW2_OPT          : TPanel;  CW2 : TEdit;
    CW3_OPT          : TPanel;  CW3 : TEdit;
    CW4_OPT          : TPanel;  CW4 : TEdit;
    CW5_OPT          : TPanel;  CW5 : TEdit;
    CW6_OPT          : TPanel;  CW6 : TEdit;
    CW7_OPT          : TPanel;  CW7 : TEdit;
    CW8_OPT          : TPanel;  { CW8 는 PIC18 전용 표시용 }
    PIC_OPT          : TPanel;
    AVR_OPT          : TPanel;
    FUSEL            : TEdit;   FUSEL_C  : TCheckBox;
    FUSEH            : TEdit;   FUSEH_C  : TCheckBox;
    FUSEX            : TEdit;   FUSEX_C  : TCheckBox;
    FUSELCK          : TEdit;   FUSELCK_C: TCheckBox;
    FUSEL_W3K        : TButton;

    { 탭2: Options }
    TabSheet_options : TTabSheet;
    CONNECT          : TButton;
    VID              : TEdit;
    PID              : TEdit;
    TEST             : TButton;
    LOG              : TCheckBox;
    CheckBox_3VCHECK : TCheckBox;  { Name='3VCHECK' – 숫자 시작 불가 }
    S1               : TCheckBox;
    MAXERR_L         : TLabel;
    MAXERR           : TEdit;

    { 탭3: I2C/SPI }
    TabSheet_i2cspi  : TTabSheet;
    I2CMODE          : TLabel;
    I2C8BIT          : TRadioButton;
    I2C16BIT         : TRadioButton;
    SPI00            : TRadioButton;
    SPI01            : TRadioButton;
    SPI10            : TRadioButton;
    SPI11            : TRadioButton;
    NBYTE_L          : TLabel;
    NBYTE_S          : TSpinEdit;
    SPEED_L          : TLabel;
    SPEED_C          : TComboBox;
    SEND_B           : TButton;
    RECEIVE_B        : TButton;
    DATASEND_L       : TLabel;
    DATASEND         : TEdit;
    DATATR_L         : TLabel;
    DATATR           : TMemo;

    { 탭4: ICD }
    TabSheet_icd     : TTabSheet;
    ICD_ToolBar      : TToolBar;
    ICD_RUN          : TToolButton;
    ICD_HALT         : TToolButton;
    ICD_STEP         : TToolButton;
    ICD_STEPOVER     : TToolButton;
    ICD_ToolSep1     : TToolButton;
    ICD_STOP         : TToolButton;
    ICD_ToolSep2     : TToolButton;
    ICD_REFRESH      : TToolButton;
    ICD_ToolSep3     : TToolButton;
    LOADCOFF_B       : TToolButton;
    ICD_CMD_E        : TEdit;
    ICD_HELP         : TToolButton;
    ICD_SOURCE_L     : TLabel;
    ICD_SOURCE       : TMemo;
    ICD_STAT_L       : TLabel;
    ICD_STATUS       : TMemo;
    ICD_BankMenu     : TMainMenu;
    MenuItem_Bank    : TMenuItem;
    BANK0_M          : TMenuItem;
    BANK1_M          : TMenuItem;
    BANK2_M          : TMenuItem;
    BANK3_M          : TMenuItem;
    EE_M             : TMenuItem;

    { 탭5: I/O }
    TabSheet_io      : TTabSheet;
    IOEN             : TCheckBox;
    { PORTB 핀 }
    RB6_0: TRadioButton; RB6_1: TRadioButton; RB6_I: TRadioButton; RB6_L: TLabel;
    RB5_0: TRadioButton; RB5_1: TRadioButton; RB5_I: TRadioButton; RB5_L: TLabel;
    RB4_0: TRadioButton; RB4_1: TRadioButton; RB4_I: TRadioButton; RB4_L: TLabel;
    RB3_0: TRadioButton; RB3_1: TRadioButton; RB3_I: TRadioButton; RB3_L: TLabel;
    RB2_0: TRadioButton; RB2_1: TRadioButton; RB2_I: TRadioButton; RB2_L: TLabel;
    RB1_0: TRadioButton; RB1_1: TRadioButton; RB1_I: TRadioButton; RB1_L: TLabel;
    RB0_0: TRadioButton; RB0_1: TRadioButton; RB0_I: TRadioButton; RB0_L: TLabel;
    RB7_0: TRadioButton; RB7_1: TRadioButton; RB7_I: TRadioButton; RB7_L: TLabel;
    { PORTA/C 핀 }
    RC7_0: TRadioButton; RC7_1: TRadioButton; RC7_I: TRadioButton; RC7_L: TLabel;
    RC6_0: TRadioButton; RC6_1: TRadioButton; RC6_I: TRadioButton; RC6_L: TLabel;
    RA5_0: TRadioButton; RA5_1: TRadioButton; RA5_I: TRadioButton; RA5_L: TLabel;
    RA4_0: TRadioButton; RA4_1: TRadioButton; RA4_I: TRadioButton; RA4_L: TLabel;
    RA3_0: TRadioButton; RA3_1: TRadioButton; RA3_I: TRadioButton; RA3_L: TLabel;
    VDDUEN   : TCheckBox;
    VPPUEN   : TCheckBox;
    DCDCEN   : TCheckBox;
    VPP_SpinEdit : TSpinEdit;
    CMD_L    : TLabel;
    CMDSEND_L: TLabel;
    CMDSEND  : TEdit;
    CMDTR_L  : TLabel;
    CMDTR    : TMemo;
    CMDTR_B  : TButton;

    { 탭6: Utility }
    TabSheet_utility : TTabSheet;
    HEXIN    : TEdit;
    DATAOUT  : TEdit;
    ADDRIN   : TEdit;
    DATAIN   : TEdit;
    HEXOUT   : TEdit;
    HEXSAVE  : TButton;

    { 상태바 }
    STATUS_B : TStatusBar;

    { ── 이벤트 핸들러 선언 ── }
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    { 툴바 }
    procedure OPEN_TClick(Sender: TObject);
    procedure SAVE_TClick(Sender: TObject);
    procedure READ_TClick(Sender: TObject);
    procedure WRITE_TClick(Sender: TObject);
    procedure STOP_TClick(Sender: TObject);
    procedure CONNECT_TClick(Sender: TObject);
    procedure INFO_TClick(Sender: TObject);

    { Device 탭 }
    procedure TYPE_CChange(Sender: TObject);
    procedure DEV_SRC_EChange(Sender: TObject);
    procedure DEV_TREESelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure FUSEL_W3KClick(Sender: TObject);

    { Options 탭 }
    procedure CONNECTClick(Sender: TObject);
    procedure TESTClick(Sender: TObject);

    { I2C/SPI 탭 }
    procedure SEND_BClick(Sender: TObject);
    procedure RECEIVE_BClick(Sender: TObject);

    { ICD 탭 }
    procedure LOADCOFF_BClick(Sender: TObject);
    procedure ICD_RUNClick(Sender: TObject);
    procedure ICD_HALTClick(Sender: TObject);
    procedure ICD_STEPClick(Sender: TObject);
    procedure ICD_STEPOVERClick(Sender: TObject);
    procedure ICD_STOPClick(Sender: TObject);
    procedure ICD_REFRESHClick(Sender: TObject);
    procedure ICD_HELPClick(Sender: TObject);
    procedure ICD_CMD_EKeyPress(Sender: TObject; var Key: Char);
    procedure ICD_SOURCEMouseDown(Sender: TObject; Button: TMouseButton;
                                   Shift: TShiftState; X, Y: Integer);
    procedure ICD_STATUSMouseDown(Sender: TObject; Button: TMouseButton;
                                   Shift: TShiftState; X, Y: Integer);
    procedure BANK0_MClick(Sender: TObject);
    procedure BANK1_MClick(Sender: TObject);
    procedure BANK2_MClick(Sender: TObject);
    procedure BANK3_MClick(Sender: TObject);
    procedure EE_MClick(Sender: TObject);

    { IO 탭 }
    procedure IOENClick(Sender: TObject);
    procedure IORadioToggle(Sender: TObject);
    procedure VDDUENClick(Sender: TObject);
    procedure VPPUENClick(Sender: TObject);
    procedure DCDCENClick(Sender: TObject);
    procedure VPP_SpinEditChange(Sender: TObject);
    procedure CMDTR_BClick(Sender: TObject);

    { Utility 탭 }
    procedure HEXINChange(Sender: TObject);
    procedure ADDRINChange(Sender: TObject);
    procedure DATAINChange(Sender: TObject);
    procedure HEXSAVEClick(Sender: TObject);

  private
    FIOTimer   : Integer;   { g_timeout → TTimer ID }
    FIOTimerObj: TObject;   { 실제 TTimer }
    FProgress  : Integer;
    FWaitingS1 : Integer;

    procedure InitControls;
    procedure InitIOButtons;
    procedure GetOptions;
    procedure GetSelectedDevice;
    procedure AddDevices(GroupFilter: Integer; const TextFilter: string);
    procedure FilterDevType;
    procedure OnDevSelChanged;
    procedure SelectDataTab;
    procedure ApplyLocalization;
    procedure SaveConfig;
    procedure LoadConfig;

    procedure PrintMessage(const Msg: string);
    procedure PrintMessageI2C(const Msg: string);
    procedure PrintMessageCMD(const Msg: string);
    procedure MsgBox(const Msg: string);
    procedure StatusPush(const Msg: string);

    function  FindDevice(AVid, APid: Integer): Integer;
    procedure ProgID;
    function  CheckV33Regulator: Integer;
    function  CheckS1: Integer;
    procedure Connect_;
    procedure DevRead_;
    procedure DevWrite_;
    procedure I2cspiR;
    procedure I2cspiS;
    procedure CommandIO;
    procedure IOChanged;
    procedure VPPVDDActive;
    procedure DCDCActive;
    procedure HexConvert;
    procedure DataToHexConvert;
    procedure HexSave_;
    procedure Stop_;
    procedure TestHw;
    procedure WriteATfuseLowLF;
    function  StartHVReg(V: Double): Integer;
    procedure DisplayEE;
    procedure PacketIO(Delay: Double);
    procedure msDelay(Delay: Double);
    function  GetTickCount_: LongWord;
    function  htoi(const Hex: string; Length_: Integer): Integer;
    procedure OpenLogFile_;
    procedure WriteLogIO_;
    procedure CloseLogFile_;
  public
  end;

{ ============================================================
  전역 변수 (common.h extern + opgui.c 파일 범위)
  ============================================================ }
var
  MainForm : TMainForm;

  { 설정 변수 }
  saveLog        : Integer = 0;
  programID      : Integer = 0;
  load_osccal    : Integer = 0;
  load_BKosccal  : Integer = 0;
  use_osccal     : Integer = 1;
  use_BKosccal   : Integer = 0;
  load_calibword : Integer = 0;
  max_err        : Integer = 200;
  AVRlock        : Integer = $100;
  AVRfuse        : Integer = $100;
  AVRfuse_h      : Integer = $100;
  AVRfuse_x      : Integer = $100;
  ICDenable      : Integer = 0;
  ICDaddr        : Integer = $1FF0;
  FWVersion      : Integer = 0;
  HwID           : Integer = 0;
  RWstop         : Integer = 0;
  useSAFLOCK_flag: Integer = 0;

  { 디바이스/파일 변수 }
  logfile        : Text;
  LogFileName    : string = '';
  loadfile_      : string = '';
  savefile_      : string = '';
  CoffFileName   : string = '';

  vid     : Integer = $1209;
  pid     : Integer = $5432;
  new_vid : Integer = $1209;
  new_pid : Integer = $5432;
  old_vid : Integer = $04D8;
  old_pid : Integer = $0100;

  memCODE_W   : PWord = nil;
  size_       : Integer = 0;
  sizeW       : Integer = 0;
  sizeEE      : Integer = 0;
  sizeCONFIG  : Integer = 0;
  sizeUSERID  : Integer = 0;
  memCODE     : PByte = nil;
  memEE       : PByte = nil;
  memID       : array[0..511] of Byte;
  memCONFIG_  : array[0..47] of Byte;
  memUSERID   : array[0..7] of Byte;
  hvreg       : Double = 0;

  DeviceDetected : Integer = 0;
  IOTimer_       : Integer = 0;
  skipV33check   : Integer = 0;
  waitS1         : Integer = 0;
  forceConfig    : Integer = 0;

  ee_      : Integer = 0;
  readRes  : Integer = 0;
  dev      : string = '';
  devType  : Integer = -1;
  str_     : string = '';
  cur_path    : string = '';
  cur_pathEE  : string = '';
  strings_arr : TStringArray;   { strings[] → dynamic array }

  { IO 버튼 배열 (13개: RB0..RB7, RC7, RC6, RA5, RA4, RA3) }
  ioButtons : array[0..12] of TIOBtn;

  statusID : Integer = 0;

  { 디바이스 그룹 이름 }
  groupNames : array[0..6] of string = (
    'PIC10/12', 'PIC16', 'PIC18', 'PIC24',
    'PIC30/33', 'ATMEL AVR', 'MEMORY'
  );
  GROUP_ALL : string = '*';

  { USB 통신 버퍼 }
  {$IFDEF UNIX}
  fd         : Integer = -1;
  path_      : string = '';
  bufferU    : array[0..127] of Byte;
  bufferI    : array[0..127] of Byte;
  {$ELSE}
  bufferU0   : array[0..127] of Byte;
  bufferI0   : array[0..127] of Byte;
  bufferU    : PByte = nil;
  bufferI    : PByte = nil;
  WriteHandle: THandle = 0;
  ReadHandle : THandle = 0;
  {$ENDIF}

implementation

{$R *.lfm}

uses
  StrUtils;

{ ============================================================
  TMainForm.FormCreate  (← main() 의 gtk_init / builder / Init 블록)
  ============================================================ }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  bufferI := @bufferI0[1];
  bufferU := @bufferU0[1];
  bufferI0[0] := 0;
  bufferU0[0] := 0;
  {$ENDIF}

  LoadConfig;
  ApplyLocalization;
  InitControls;
  InitIOButtons;

  { 초기 메모리 할당 }
  sizeW := $8400;
  GetMem(memCODE_W, sizeW * SizeOf(Word));
  FillChar(memCODE_W^, sizeW * SizeOf(Word), $FF);

  { USB 장치 연결 }
  DeviceDetected := FindDevice(vid, pid);
  if DeviceDetected = 0 then
  begin
    DeviceDetected := FindDevice(new_vid, new_pid);
    if DeviceDetected <> 0 then
    begin
      vid := new_vid;
      pid := new_pid;
    end;
  end;
  if DeviceDetected = 0 then
    DeviceDetected := FindDevice(old_vid, old_pid);

  ProgID;
end;

{ ============================================================
  FormDestroy  (← Xclose / delete_event)
  ============================================================ }
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  SaveConfig;
  if Assigned(memCODE_W) then FreeMem(memCODE_W);
  if Assigned(memCODE)   then FreeMem(memCODE);
  if Assigned(memEE)     then FreeMem(memEE);
end;

{ ============================================================
  ApplyLocalization  (← main()의 strinit/strings 설정 블록)
  ============================================================ }
procedure TMainForm.ApplyLocalization;
begin
  { Lazarus 환경에서는 resourcestring 또는 외부 .po/.mo 사용.
    원본 strings[] 배열 참조는 strings_arr[]로 대체.
    여기서는 툴팁/레이블을 직접 설정. }
  Caption := 'opgui v' + {$I version.inc} 'dev';

  { 툴바 힌트 }
  OPEN_T.Hint     := '파일 열기';
  SAVE_T.Hint     := '파일 저장';
  READ_T.Hint     := '디바이스 읽기';
  WRITE_T.Hint    := '디바이스 쓰기';
  STOP_T.Hint     := '중지';
  CONNECT_T.Hint  := '재연결';
  INFO_T.Hint     := '정보';
  STOP_T.Enabled  := False;

  { 디바이스 탭 레이블 }
  TYPE_L.Caption    := '종류 필터';
  DEV_SRC_L.Caption := '필터';
  EE_RW.Caption     := 'EEPROM 읽기/쓰기';
  RES_READ.Caption  := '예약 영역 읽기';
  PROG_ID.Caption   := 'ID & BKOscCal 쓰기';
  PROG_CAL12.Caption:= 'Calib 1,2 쓰기';
  USE_SAFLOCK.Caption := 'SAFLOCK 사용';
  OSCCAL_L.Caption  := 'OscCal 쓰기';
  OSCCAL.Caption    := 'OSCCal';
  BKOSCCAL.Caption  := 'Backup OSCCal';
  FILECAL.Caption   := '파일에서';
  ICD.Caption       := 'ICD 활성화';
  ICD_ADDR_L.Caption:= 'ICD 루틴 주소';
  FORCE_CW.Caption  := '설정 워드 강제';

  { AVR 퓨즈 }
  FUSEL_C.Caption   := '퓨즈 Low 쓰기';
  FUSEH_C.Caption   := '퓨즈 High 쓰기';
  FUSEX_C.Caption   := '퓨즈 Ext 쓰기';
  FUSELCK_C.Caption := '잠금 쓰기';
  FUSEL_W3K.Caption := '퓨즈 Low 쓰기 @3kHz';

  { 옵션 탭 }
  CONNECT.Caption       := '재연결';
  TEST.Caption          := '하드웨어 테스트';
  LOG.Caption           := '활동 로그';
  CheckBox_3VCHECK.Caption := '3.3V 레귤레이터 체크 안 함';
  S1.Caption            := 'S1 누를 때까지 대기';
  MAXERR_L.Caption      := '최대 오류 수';

  { I2C 탭 }
  I2CMODE.Caption   := '모드';
  NBYTE_L.Caption   := '바이트 수';
  SPEED_L.Caption   := '속도';
  SEND_B.Caption    := '전송';
  RECEIVE_B.Caption := '수신';
  DATASEND_L.Caption:= '전송 데이터';
  DATATR_L.Caption  := '전송된 데이터';

  { ICD 탭 }
  ICD_SOURCE_L.Caption := '소스';
  ICD_STAT_L.Caption   := '상태';
  BANK0_M.Caption      := '뱅크 0';
  BANK1_M.Caption      := '뱅크 1';
  BANK2_M.Caption      := '뱅크 2';
  BANK3_M.Caption      := '뱅크 3';
  EE_M.Caption         := 'EEPROM';

  { IO 탭 }
  IOEN.Caption     := 'IO 활성화';
  CMD_L.Caption    := '수동 명령';
  CMDSEND_L.Caption:= '전송 데이터';
  CMDTR_L.Caption  := '전송된 데이터';
  CMDTR_B.Caption  := '전송';

  { Utility 탭 }
  HEXSAVE.Caption  := '저장';
end;

{ ============================================================
  InitControls  (← main()의 gtk_builder_get_object 블록)
  ============================================================ }
procedure TMainForm.InitControls;
var
  text_: string;
  i: Integer;
begin
  { VID / PID / MAXERR 초기값 }
  text_ := Format('%04X', [vid]);
  VID.Text := text_;
  text_ := Format('%04X', [pid]);
  PID.Text := text_;
  MAXERR.Text := IntToStr(max_err);

  { 디바이스 유형 콤보 채우기 }
  TYPE_C.Items.Clear;
  TYPE_C.Items.Add(GROUP_ALL);
  for i := 0 to Ord(NUM_GROUPS) - 1 do
    TYPE_C.Items.Add(groupNames[i]);
  TYPE_C.ItemIndex := 0;

  { DEV_TREE 컬럼 설정 }
  DEV_TREE.ViewStyle := vsReport;
  DEV_TREE.Columns.Clear;
  with DEV_TREE.Columns.Add do begin Caption := '디바이스'; Width := 125; end;
  with DEV_TREE.Columns.Add do begin Caption := '종류';     Width := 125; end;

  { 처음에 PIC/AVR 패널 숨기기 }
  PIC_OPT.Visible := False;
  AVR_OPT.Visible := False;

  { dev 변수에 따라 그룹 선택 → AddDevices 호출됨 }
  if dev <> '' then
    FilterDevType
  else
  begin
    TYPE_C.ItemIndex := 0;
    AddDevices(-1, '');
  end;

  { STOP 버튼 비활성화 }
  STOP_T.Enabled := False;
  READ_T.Enabled := False;
  WRITE_T.Enabled := False;
end;

{ ============================================================
  InitIOButtons  (← main()의 ioButtons[] 설정 블록)
  ============================================================ }
procedure TMainForm.InitIOButtons;
var
  i: Integer;
begin
  ioButtons[0].r_0 := RB0_0; ioButtons[0].r_1 := RB0_1;
  ioButtons[0].r_I := RB0_I; ioButtons[0].e_I := RB0_L;
  ioButtons[1].r_0 := RB1_0; ioButtons[1].r_1 := RB1_1;
  ioButtons[1].r_I := RB1_I; ioButtons[1].e_I := RB1_L;
  ioButtons[2].r_0 := RB2_0; ioButtons[2].r_1 := RB2_1;
  ioButtons[2].r_I := RB2_I; ioButtons[2].e_I := RB2_L;
  ioButtons[3].r_0 := RB3_0; ioButtons[3].r_1 := RB3_1;
  ioButtons[3].r_I := RB3_I; ioButtons[3].e_I := RB3_L;
  ioButtons[4].r_0 := RB4_0; ioButtons[4].r_1 := RB4_1;
  ioButtons[4].r_I := RB4_I; ioButtons[4].e_I := RB4_L;
  ioButtons[5].r_0 := RB5_0; ioButtons[5].r_1 := RB5_1;
  ioButtons[5].r_I := RB5_I; ioButtons[5].e_I := RB5_L;
  ioButtons[6].r_0 := RB6_0; ioButtons[6].r_1 := RB6_1;
  ioButtons[6].r_I := RB6_I; ioButtons[6].e_I := RB6_L;
  ioButtons[7].r_0 := RB7_0; ioButtons[7].r_1 := RB7_1;
  ioButtons[7].r_I := RB7_I; ioButtons[7].e_I := RB7_L;
  ioButtons[8].r_0 := RC7_0; ioButtons[8].r_1 := RC7_1;
  ioButtons[8].r_I := RC7_I; ioButtons[8].e_I := RC7_L;
  ioButtons[9].r_0 := RC6_0; ioButtons[9].r_1 := RC6_1;
  ioButtons[9].r_I := RC6_I; ioButtons[9].e_I := RC6_L;
  ioButtons[10].r_0:= RA5_0; ioButtons[10].r_1:= RA5_1;
  ioButtons[10].r_I:= RA5_I; ioButtons[10].e_I:= RA5_L;
  ioButtons[11].r_0:= RA4_0; ioButtons[11].r_1:= RA4_1;
  ioButtons[11].r_I:= RA4_I; ioButtons[11].e_I:= RA4_L;
  ioButtons[12].r_0:= RA3_0; ioButtons[12].r_1:= RA3_1;
  ioButtons[12].r_I:= RA3_I; ioButtons[12].e_I:= RA3_L;

  { 모든 IO 버튼을 INPUT(r_I) 기본값으로, 이벤트 연결 }
  for i := 0 to 12 do
  begin
    ioButtons[i].r_I.Checked := True;
    ioButtons[i].r_0.OnClick := @IORadioToggle;
    ioButtons[i].r_1.OnClick := @IORadioToggle;
    ioButtons[i].r_I.OnClick := @IORadioToggle;
  end;
end;

{ ============================================================
  LoadConfig / SaveConfig  (← main()의 INI 읽기/쓰기)
  ============================================================ }
procedure TMainForm.LoadConfig;
var
  fname, homedir, line, temp: string;
  f: TextFile;
  X: Integer;
begin
  homedir := GetUserDir;
  fname := IncludeTrailingPathDelimiter(homedir) +
           IncludeTrailingPathDelimiter(CONFIG_DIR) + CONFIG_FILE;
  if not FileExists(fname) then Exit;
  AssignFile(f, fname);
  try
    Reset(f);
    while not Eof(f) do
    begin
      ReadLn(f, line);
      line := Trim(line);
      if Copy(line, 1, 7) = 'device ' then
        dev := Trim(Copy(line, 8, MaxInt))
      else if Copy(line, 1, 4) = 'vid ' then
        TryStrToInt('$' + Trim(Copy(line, 5, MaxInt)), vid)
      else if Copy(line, 1, 4) = 'pid ' then
        TryStrToInt('$' + Trim(Copy(line, 5, MaxInt)), pid)
      else if Copy(line, 1, 7) = 'maxerr ' then
        TryStrToInt(Trim(Copy(line, 8, MaxInt)), max_err);
    end;
    CloseFile(f);
  except
    { 무시 }
  end;
end;

procedure TMainForm.SaveConfig;
var
  fname, homedir: string;
  f: TextFile;
begin
  homedir := GetUserDir;
  fname := IncludeTrailingPathDelimiter(homedir) +
           IncludeTrailingPathDelimiter(CONFIG_DIR) + CONFIG_FILE;
  ForceDirectories(ExtractFileDir(fname));
  AssignFile(f, fname);
  try
    Rewrite(f);
    WriteLn(f, 'device ' + dev);
    WriteLn(f, 'maxerr ' + IntToStr(max_err));
    WriteLn(f, 'vid ' + IntToHex(vid, 4));
    WriteLn(f, 'pid ' + IntToHex(pid, 4));
    CloseFile(f);
  except
    { 무시 }
  end;
end;

{ ============================================================
  PrintMessage  (← void PrintMessage)
  ============================================================ }
procedure TMainForm.PrintMessage(const Msg: string);
begin
  DATA.Lines.Add(Msg);
  { 최대 라인 수 제한 }
  while DATA.Lines.Count > MAXLINES + 10 do
    DATA.Lines.Delete(0);
  { 스크롤 맨 아래로 }
  SendMessage(DATA.Handle, WM_VSCROLL, SB_BOTTOM, 0);
  Application.ProcessMessages;
end;

{ ============================================================
  PrintMessageI2C  (← void PrintMessageI2C)
  ============================================================ }
procedure TMainForm.PrintMessageI2C(const Msg: string);
begin
  DATATR.Lines.Clear;
  DATATR.Lines.Add(Msg);
  Application.ProcessMessages;
end;

{ ============================================================
  PrintMessageCMD  (← void PrintMessageCMD)
  ============================================================ }
procedure TMainForm.PrintMessageCMD(const Msg: string);
begin
  CMDTR.Lines.Clear;
  CMDTR.Lines.Add(Msg);
end;

{ ============================================================
  StatusPush  (← gtk_statusbar_push)
  ============================================================ }
procedure TMainForm.StatusPush(const Msg: string);
begin
  STATUS_B.SimpleText := Msg;
  Application.ProcessMessages;
end;

{ ============================================================
  MsgBox  (← void MsgBox)
  ============================================================ }
procedure TMainForm.MsgBox(const Msg: string);
begin
  MessageDlg(Msg, mtInformation, [mbOK], 0);
end;

{ ============================================================
  SelectDataTab  (← void selectDataTab)
  ============================================================ }
procedure TMainForm.SelectDataTab;
begin
  NOTEBOOK.ActivePage := TabSheet_dati;
end;

{ ============================================================
  GetOptions  (← void getOptions)
  ============================================================ }
procedure TMainForm.GetOptions;
var
  i, cw1, cw2, cw3, cw4, cw5, cw6, cw7: Integer;
  icdVal: Integer;
begin
  TryStrToInt('$' + Trim(VID.Text), vid);
  TryStrToInt('$' + Trim(PID.Text), pid);
  saveLog       := Ord(LOG.Checked);
  ee_           := IfThen(EE_RW.Checked, $FFFF, 0);
  programID     := Ord(PROG_ID.Checked);
  TryStrToInt(MAXERR.Text, max_err);
  load_calibword  := Ord(PROG_CAL12.Checked);
  useSAFLOCK_flag := Ord(USE_SAFLOCK.Checked);
  load_osccal     := Ord(not OSCCAL.Checked);
  load_BKosccal   := Ord(BKOSCCAL.Checked);
  ICDenable       := Ord(ICD.Checked);
  readRes         := Ord(RES_READ.Checked);
  skipV33check    := Ord(CheckBox_3VCHECK.Checked);
  waitS1          := Ord(S1.Checked);

  if not TryStrToInt('$' + Trim(ICD_ADDR.Text), icdVal) then
    icdVal := $1FF0;
  if (icdVal < 0) or (icdVal > $FFFF) then icdVal := $1FF0;
  ICDaddr := icdVal;

  { AVR 퓨즈 }
  AVRfuse := $100; AVRfuse_h := $100; AVRfuse_x := $100; AVRlock := $100;
  if FUSEL_C.Checked then
    if not TryStrToInt('$' + Trim(FUSEL.Text), AVRfuse) then AVRfuse := $100
    else if (AVRfuse < 0) or (AVRfuse > $FF) then AVRfuse := $100;
  if FUSEH_C.Checked then
    if not TryStrToInt('$' + Trim(FUSEH.Text), AVRfuse_h) then AVRfuse_h := $100
    else if (AVRfuse_h < 0) or (AVRfuse_h > $FF) then AVRfuse_h := $100;
  if FUSEX_C.Checked then
    if not TryStrToInt('$' + Trim(FUSEX.Text), AVRfuse_x) then AVRfuse_x := $100
    else if (AVRfuse_x < 0) or (AVRfuse_x > $FF) then AVRfuse_x := $100;
  if FUSELCK_C.Checked then
    if not TryStrToInt('$' + Trim(FUSELCK.Text), AVRlock) then AVRlock := $100
    else if (AVRlock < 0) or (AVRlock > $FF) then AVRlock := $100;

  { Config Word 강제 적용 }
  if FORCE_CW.Checked then
  begin
    cw1:=$10000; cw2:=$10000; cw3:=$10000; cw4:=$10000;
    cw5:=$10000; cw6:=$10000; cw7:=$10000;
    TryStrToInt('$'+Trim(CW1.Text), cw1);
    TryStrToInt('$'+Trim(CW2.Text), cw2);
    TryStrToInt('$'+Trim(CW3.Text), cw3);
    TryStrToInt('$'+Trim(CW4.Text), cw4);
    TryStrToInt('$'+Trim(CW5.Text), cw5);
    TryStrToInt('$'+Trim(CW6.Text), cw6);
    TryStrToInt('$'+Trim(CW7.Text), cw7);

    if devType = Ord(grpPIC16) then
    begin
      if ((Copy(dev,1,4)='16F1') or (Copy(dev,1,4)='12F1')) and (sizeW > $8008) then
      begin
        if cw1 <= $3FFF then memCODE_W[$8007] := cw1;
        if cw2 <= $3FFF then memCODE_W[$8008] := cw2;
      end
      else
      begin
        if (cw1 <= $3FFF) and (sizeW > $2007) then memCODE_W[$2007] := cw1;
        if (cw2 <= $3FFF) and (sizeW > $2008) then memCODE_W[$2008] := cw2;
      end;
    end
    else if devType = Ord(grpPIC1012) then
    begin
      if (cw1 <= $FFF) and (sizeW > $FFF) then memCODE_W[$FFF] := cw1;
    end
    else if devType = Ord(grpPIC18) then
    begin
      if cw1 <= $FFFF then begin memCONFIG_[0]:=cw1 and $FF; memCONFIG_[1]:=(cw1 shr 8) and $FF; end;
      if cw2 <= $FFFF then begin memCONFIG_[2]:=cw2 and $FF; memCONFIG_[3]:=(cw2 shr 8) and $FF; end;
      if cw3 <= $FFFF then begin memCONFIG_[4]:=cw3 and $FF; memCONFIG_[5]:=(cw3 shr 8) and $FF; end;
      if cw4 <= $FFFF then begin memCONFIG_[6]:=cw4 and $FF; memCONFIG_[7]:=(cw4 shr 8) and $FF; end;
      if cw5 <= $FFFF then begin memCONFIG_[8]:=cw5 and $FF; memCONFIG_[9]:=(cw5 shr 8) and $FF; end;
      if cw6 <= $FFFF then begin memCONFIG_[10]:=cw6 and $FF; memCONFIG_[11]:=(cw6 shr 8) and $FF; end;
      if cw7 <= $FFFF then begin memCONFIG_[12]:=cw7 and $FF; memCONFIG_[13]:=(cw7 shr 8) and $FF; end;
      PrintMessage('설정 워드 강제 적용');
      for i := 0 to 6 do
        PrintMessage(Format('CONFIG%dH: 0x%02X  CONFIG%dL: 0x%02X',
          [i+1, memCONFIG_[i*2+1], i+1, memCONFIG_[i*2]]));
    end;
  end;
end;

{ ============================================================
  GetSelectedDevice  (← void GetSelectedDevice)
  ============================================================ }
procedure TMainForm.GetSelectedDevice;
begin
  if DEV_TREE.Selected <> nil then
  begin
    dev := DEV_TREE.Selected.Caption;
    READ_T.Enabled  := True;
    WRITE_T.Enabled := True;
  end
  else
  begin
    dev := '';
    READ_T.Enabled  := False;
    WRITE_T.Enabled := False;
  end;
end;

{ ============================================================
  AddDevices  (← void AddDevices)
  ============================================================ }
procedure TMainForm.AddDevices(GroupFilter: Integer; const TextFilter: string);
var
  i: Integer;
  item: TListItem;
  devName, grpName, filtUp, devUp: string;
  info: TDevInfo;
  grpIdx: Integer;
begin
  DEV_TREE.Items.Clear;
  filtUp := UpperCase(TextFilter);

  for i := 0 to NDEVLIST - 1 do
  begin
    devName := DEVLIST[i].device;
    info := GetDevInfo(devName);
    grpIdx := nameToGroup(devName);
    if grpIdx = -1 then Continue;
    devUp := UpperCase(devName);
    if (filtUp <> '') and (Pos(filtUp, devUp) = 0) then Continue;
    if (GroupFilter <> -1) and (grpIdx <> GroupFilter) then Continue;

    grpName := groupNames[grpIdx];
    item := DEV_TREE.Items.Add;
    item.Caption := devName;
    item.SubItems.Add(grpName);
  end;

  { 저장된 dev 선택 }
  if dev <> '' then
    for i := 0 to DEV_TREE.Items.Count - 1 do
      if DEV_TREE.Items[i].Caption = dev then
      begin
        DEV_TREE.Items[i].Selected := True;
        Break;
      end;
end;

{ ============================================================
  FilterDevType  (← void FilterDevType)
  ============================================================ }
procedure TMainForm.FilterDevType;
var
  selName: string;
  selGroup, i: Integer;
begin
  selName := TYPE_C.Text;
  selGroup := -1;
  for i := 0 to Ord(NUM_GROUPS) - 1 do
    if groupNames[i] = selName then begin selGroup := i; Break; end;
  AddDevices(selGroup, DEV_SRC_E.Text);
  OnDevSelChanged;
end;

{ ============================================================
  OnDevSelChanged  (← void onDevSel_Changed)
  ============================================================ }
procedure TMainForm.OnDevSelChanged;
var
  info: TDevInfo;
begin
  GetSelectedDevice;
  if dev = '' then Exit;
  info := GetDevInfo(dev);
  DEVICE_NAME.Caption := Format('<b>%s: %s</b>', ['Device', dev]);
  devType := info.family;
  DEV_INFO.Caption := info.features;

  { PIC / AVR / 메모리 패널 표시 }
  PIC_OPT.Visible := devType in [Ord(grpPIC1012), Ord(grpPIC16),
                                  Ord(grpPIC18), Ord(grpPIC24)];
  AVR_OPT.Visible := devType = Ord(grpAVR);
  EE_RW.Visible   := devType in [Ord(grpPIC1012), Ord(grpPIC16),
                                  Ord(grpPIC18), Ord(grpPIC24), Ord(grpAVR)];

  { ICD 옵션 (PIC16만) }
  ICD_OPT.Visible := devType = Ord(grpPIC16);

  { OSC 옵션 (PIC12, PIC16) }
  OSC_OPT.Visible := devType in [Ord(grpPIC1012), Ord(grpPIC16)];

  { ID / BKCal 쓰기 옵션 }
  PROG_ID.Visible     := devType in [Ord(grpPIC1012), Ord(grpPIC16), Ord(grpPIC18)];
  PROG_CAL12.Visible  := devType = Ord(grpPIC16);

  { Config Word 패널 }
  CW_OPT.Visible := devType in [Ord(grpPIC1012), Ord(grpPIC16), Ord(grpPIC18)];
  if CW_OPT.Visible then
  begin
    CW2_OPT.Visible := devType in [Ord(grpPIC16), Ord(grpPIC18)];
    CW3_OPT.Visible := devType = Ord(grpPIC18);
    CW4_OPT.Visible := devType = Ord(grpPIC18);
    CW5_OPT.Visible := devType = Ord(grpPIC18);
    CW6_OPT.Visible := devType = Ord(grpPIC18);
    CW7_OPT.Visible := devType = Ord(grpPIC18);
    CW8_OPT.Visible := devType = Ord(grpPIC18);
  end
  else
    FORCE_CW.Checked := False;

  StatusPush(dev);
end;

{ ============================================================
  Fopen  (← void Fopen)  Open 툴버튼
  ============================================================ }
procedure TMainForm.OPEN_TClick(Sender: TObject);
var
  dlg: TOpenDialog;
begin
  GetSelectedDevice;
  if FProgress <> 0 then Exit;
  Inc(FProgress);
  dlg := TOpenDialog.Create(Self);
  try
    dlg.Title := '파일 열기';
    if cur_path <> '' then dlg.InitialDir := cur_path;
    if dlg.Execute then
    begin
      cur_path := ExtractFileDir(dlg.FileName);
      Load(devType, dlg.FileName);
      if devType = Ord(grpAVR) then
      begin
        { AVR: EEPROM 별도 파일 }
        var dlg2 := TOpenDialog.Create(Self);
        try
          dlg2.Title := 'EEPROM 파일 열기';
          if cur_pathEE <> '' then dlg2.InitialDir := cur_pathEE;
          if dlg2.Execute then
          begin
            cur_pathEE := ExtractFileDir(dlg2.FileName);
            LoadEE(devType, dlg2.FileName);
          end;
        finally
          dlg2.Free;
        end;
      end;
    end;
  finally
    dlg.Free;
    Dec(FProgress);
  end;
end;

{ ============================================================
  Fsave  (← void Fsave)  Save 툴버튼
  ============================================================ }
procedure TMainForm.SAVE_TClick(Sender: TObject);
var
  dlg: TSaveDialog;
begin
  if FProgress <> 0 then Exit;
  Inc(FProgress);
  dlg := TSaveDialog.Create(Self);
  try
    dlg.Title := '파일 저장';
    dlg.Options := dlg.Options + [ofOverwritePrompt];
    if cur_path <> '' then dlg.InitialDir := cur_path;
    if dlg.Execute then
    begin
      cur_path := ExtractFileDir(dlg.FileName);
      Save(devType, dlg.FileName);
      PrintMessage(Format('파일 저장됨: %s', [dlg.FileName]));
      if devType = Ord(grpAVR) then
      begin
        var dlg2 := TSaveDialog.Create(Self);
        try
          dlg2.Title := 'EEPROM 파일 저장';
          dlg2.Options := dlg2.Options + [ofOverwritePrompt];
          if cur_pathEE = '' then cur_pathEE := cur_path;
          dlg2.InitialDir := cur_pathEE;
          if dlg2.Execute then
          begin
            cur_pathEE := ExtractFileDir(dlg2.FileName);
            SaveEE(devType, dlg2.FileName);
            PrintMessage(Format('파일 저장됨: %s', [dlg2.FileName]));
          end;
        finally
          dlg2.Free;
        end;
      end;
    end;
  finally
    dlg.Free;
    Dec(FProgress);
  end;
end;

{ ============================================================
  DevRead  (← void DevRead)
  ============================================================ }
procedure TMainForm.READ_TClick(Sender: TObject);
var
  i: Integer;
  S1pressed: Integer;
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  SelectDataTab;
  StatusPush('');
  GetOptions;
  RWstop := 0;

  if (FWaitingS1 = 0) and (waitS1 <> 0) then
  begin
    FWaitingS1 := 1;
    S1pressed := 0;
    PrintMessage('S1을 눌러 시작하세요');
    i := 0;
    while (S1pressed = 0) and (waitS1 <> 0) and (FWaitingS1 <> 0) do
    begin
      S1pressed := CheckS1;
      msDelay(50);
      PrintMessage('.');
      if i mod 64 = 63 then PrintMessage(LineEnding);
      Application.ProcessMessages;
      msDelay(50);
      Inc(i);
    end;
    PrintMessage(LineEnding);
    if (FProgress = 0) and (S1pressed <> 0) then
    begin
      STOP_T.Enabled := True;
      Inc(FProgress);
      Read(dev, ee_, readRes);
      Dec(FProgress);
      STOP_T.Enabled := False;
    end;
    FWaitingS1 := 0;
  end
  else if FWaitingS1 <> 0 then
    FWaitingS1 := 0
  else if FProgress = 0 then
  begin
    STOP_T.Enabled := True;
    Inc(FProgress);
    Read(dev, ee_, readRes);
    Dec(FProgress);
    STOP_T.Enabled := False;
  end;
end;

{ ============================================================
  DevWrite  (← void DevWrite)
  ============================================================ }
procedure TMainForm.WRITE_TClick(Sender: TObject);
var
  i: Integer;
  S1pressed: Integer;
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  SelectDataTab;
  StatusPush('');
  RWstop := 0;
  GetOptions;

  if (FWaitingS1 = 0) and (waitS1 <> 0) then
  begin
    FWaitingS1 := 1;
    S1pressed := 0;
    PrintMessage('S1을 눌러 시작하세요');
    i := 0;
    while (S1pressed = 0) and (waitS1 <> 0) and (FWaitingS1 <> 0) do
    begin
      S1pressed := CheckS1;
      msDelay(50);
      PrintMessage('.');
      if i mod 64 = 63 then PrintMessage(LineEnding);
      Application.ProcessMessages;
      msDelay(50);
      Inc(i);
    end;
    PrintMessage(LineEnding);
    if (FProgress = 0) and (S1pressed <> 0) then
    begin
      STOP_T.Enabled := True;
      Inc(FProgress);
      Write_(dev, ee_);
      Dec(FProgress);
      STOP_T.Enabled := False;
    end;
    FWaitingS1 := 0;
  end
  else if FWaitingS1 <> 0 then
    FWaitingS1 := 0
  else if FProgress = 0 then
  begin
    STOP_T.Enabled := True;
    Inc(FProgress);
    Write_(dev, ee_);
    Dec(FProgress);
    STOP_T.Enabled := False;
  end;
end;

{ ============================================================
  Stop  (← void Stop)
  ============================================================ }
procedure TMainForm.STOP_TClick(Sender: TObject);
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  if (FProgress = 1) and (RWstop = 0) then
  begin
    RWstop := 1;
    PrintMessage('중지 중...');
  end;
end;

{ ============================================================
  Connect  (← void Connect)
  ============================================================ }
procedure TMainForm.CONNECT_TClick(Sender: TObject);
begin
  Connect_;
end;

procedure TMainForm.CONNECTClick(Sender: TObject);
begin
  Connect_;
end;

procedure TMainForm.Connect_;
begin
  TryStrToInt('$' + Trim(VID.Text), vid);
  TryStrToInt('$' + Trim(PID.Text), pid);
  DeviceDetected := FindDevice(vid, pid);
  if DeviceDetected = 0 then
  begin
    DeviceDetected := FindDevice(new_vid, new_pid);
    if DeviceDetected <> 0 then begin vid := new_vid; pid := new_pid; end;
  end;
  if DeviceDetected = 0 then
    DeviceDetected := FindDevice(old_vid, old_pid);
  hvreg := 0;
  ProgID;
end;

{ ============================================================
  Info  (← void info)
  ============================================================ }
procedure TMainForm.INFO_TClick(Sender: TObject);
begin
  with TAboutBox.Create(Self) do
  try
    ShowModal;
  finally
    Free;
  end;
  { 간단 대체: }
  // MessageDlg('OPGUI' + LineEnding + 'Copyright (C) 2009-2025 Alberto Maccioni',
  //             mtInformation, [mbOK], 0);
end;

{ ============================================================
  DEV_TREE 선택 변경
  ============================================================ }
procedure TMainForm.DEV_TREESelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected then OnDevSelChanged;
end;

procedure TMainForm.TYPE_CChange(Sender: TObject);
begin
  FilterDevType;
end;

procedure TMainForm.DEV_SRC_EChange(Sender: TObject);
begin
  FilterDevType;
end;

{ ============================================================
  WriteATfuseLowLF  (← void WriteATfuseLowLF)
  ============================================================ }
procedure TMainForm.FUSEL_W3KClick(Sender: TObject);
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  if FProgress <> 0 then Exit;
  GetOptions;
  if FUSEL_C.Checked then
  begin
    Inc(FProgress);
    if AVRfuse < $100 then WriteATfuseSlow(AVRfuse);
    Dec(FProgress);
  end;
end;

{ ============================================================
  TestHw  (← void TestHw)
  ============================================================ }
procedure TMainForm.TESTClick(Sender: TObject);
begin
  TestHw;
end;

procedure TMainForm.TestHw;
var
  j, i, x, r: Integer;
  s: string;
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  StartHVReg(13);
  j := 0;
  MsgBox('하드웨어 테스트 중...');
  bufferU[j] := SET_CK_D;   Inc(j);
  bufferU[j] := $00;        Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $05;        Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  MsgBox('테스트:' + LineEnding +
         ' VDDU=5V' + LineEnding + ' VPPU=13V' + LineEnding +
         ' PGD(RB5)=0V' + LineEnding + ' PGC(RB6)=0V' + LineEnding +
         ' PGM(RB7)=0V');
  j := 0;
  bufferU[j] := SET_CK_D;   Inc(j); bufferU[j] := $15; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $01; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  MsgBox('테스트:' + LineEnding +
         ' VDDU=5V' + LineEnding + ' VPPU=0V' + LineEnding +
         ' PGD(RB5)=5V' + LineEnding + ' PGC(RB6)=5V' + LineEnding +
         ' PGM(RB7)=5V');
  j := 0;
  bufferU[j] := SET_CK_D;   Inc(j); bufferU[j] := $01; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $04; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  MsgBox('테스트:' + LineEnding +
         ' VDDU=0V' + LineEnding + ' VPPU=13V' + LineEnding +
         ' PGD(RB5)=5V' + LineEnding + ' PGC(RB6)=0V' + LineEnding +
         ' PGM(RB7)=0V');
  j := 0;
  bufferU[j] := SET_CK_D;   Inc(j); bufferU[j] := $04; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $00; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  MsgBox('테스트:' + LineEnding +
         ' VDDU=0V' + LineEnding + ' VPPU=0V' + LineEnding +
         ' PGD(RB5)=0V' + LineEnding + ' PGC(RB6)=5V' + LineEnding +
         ' PGM(RB7)=0V');
  j := 0;
  bufferU[j] := SET_CK_D;   Inc(j); bufferU[j] := $00; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $00; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  if FWVersion >= $900 then
  begin
    s := '0000000000000';
    PrintMessage('IO 테스트' + LineEnding + 'RC|RA|--RB--|' + LineEnding);
    for i := 0 to 12 do
    begin
      x := 1 shl i;
      j := 0;
      bufferU[j] := EN_VPP_VCC;  Inc(j); bufferU[j] := $00;         Inc(j);
      bufferU[j] := SET_PORT_DIR; Inc(j); bufferU[j] := $00;         Inc(j);
      bufferU[j] := $00;          Inc(j); bufferU[j] := EXT_PORT;    Inc(j);
      bufferU[j] := x and $FF;   Inc(j); bufferU[j] := (x shr 5) and $FF; Inc(j);
      bufferU[j] := READ_B;       Inc(j); bufferU[j] := READ_AC;     Inc(j);
      bufferU[j] := FLUSH;        Inc(j);
      while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
      PacketIO(5);
      j := 0;
      while (j < DIMBUF - 1) and (bufferI[j] <> READ_B) do Inc(j);
      r := bufferI[j + 1];
      Inc(j, 2);
      while (j < DIMBUF - 1) and (bufferI[j] <> READ_AC) do Inc(j);
      r := r + ((bufferI[j + 1] and $F8) shl 5);
      for j := 0 to 12 do
        if (x and (1 shl j)) <> 0 then s[13 - j] := '1'
        else s[13 - j] := '0';
      if r = x then PrintMessage(s + ' (OK)' + LineEnding)
      else PrintMessage(s + ' (오류)' + LineEnding);
    end;
  end;
end;

{ ============================================================
  I2cspiS / I2cspiR  (← void I2cspiS / I2cspiR)
  ============================================================ }
procedure TMainForm.SEND_BClick(Sender: TObject);
begin
  I2cspiS;
end;

procedure TMainForm.RECEIVE_BClick(Sender: TObject);
begin
  I2cspiR;
end;

procedure TMainForm.I2cspiS;
var
  nbyte, mode, i, x: Integer;
  tok, tokbuf: string;
  tmpbuf: array[0..127] of Byte;
  parts: TStringArray;
begin
  StatusPush('');
  saveLog := Ord(LOG.Checked);
  nbyte := NBYTE_S.Value;
  if nbyte < 0  then nbyte := 0;
  if nbyte > 57 then nbyte := 57;
  mode := 0;
  if I2C16BIT.Checked then mode := 1;
  if SPI00.Checked    then mode := 2;
  if SPI01.Checked    then mode := 3;
  if SPI10.Checked    then mode := 4;
  if SPI11.Checked    then mode := 5;
  FillChar(tmpbuf, SizeOf(tmpbuf), 0);
  tokbuf := Trim(DATASEND.Text);
  parts := tokbuf.Split([' '], TStringSplitOptions.ExcludeEmpty);
  i := 0;
  for tok in parts do
  begin
    if i >= 128 then Break;
    if TryStrToInt('$' + tok, x) then
    begin
      tmpbuf[i] := Byte(x);
      Inc(i);
    end;
  end;
  I2CSend(mode, SPEED_C.ItemIndex, nbyte, @tmpbuf[0]);
end;

procedure TMainForm.I2cspiR;
var
  nbyte, mode, i, x: Integer;
  tok, tokbuf: string;
  tmpbuf: array[0..127] of Byte;
  parts: TStringArray;
begin
  StatusPush('');
  saveLog := Ord(LOG.Checked);
  nbyte := NBYTE_S.Value;
  if nbyte < 0  then nbyte := 0;
  if nbyte > 60 then nbyte := 60;
  mode := 0;
  if I2C16BIT.Checked then mode := 1;
  if SPI00.Checked    then mode := 2;
  if SPI01.Checked    then mode := 3;
  if SPI10.Checked    then mode := 4;
  if SPI11.Checked    then mode := 5;
  FillChar(tmpbuf, SizeOf(tmpbuf), 0);
  tokbuf := Trim(DATASEND.Text);
  parts := tokbuf.Split([' '], TStringSplitOptions.ExcludeEmpty);
  i := 0;
  for tok in parts do
  begin
    if i >= 128 then Break;
    if TryStrToInt('$' + tok, x) then
    begin
      tmpbuf[i] := Byte(x);
      Inc(i);
    end;
  end;
  I2CReceive(mode, SPEED_C.ItemIndex, nbyte, @tmpbuf[0]);
end;

{ ============================================================
  CommandIO  (← void CommandIO)
  ============================================================ }
procedure TMainForm.CMDTR_BClick(Sender: TObject);
begin
  CommandIO;
end;

procedure TMainForm.CommandIO;
var
  i, x: Integer;
  tok, tokbuf, result_s: string;
  parts: TStringArray;
begin
  if DeviceDetected <> 1 then Exit;
  StatusPush('');
  saveLog := Ord(LOG.Checked);
  FillChar(bufferU, SizeOf(bufferU), 0);
  tokbuf := Trim(CMDSEND.Text);
  parts := tokbuf.Split([' '], TStringSplitOptions.ExcludeEmpty);
  i := 0;
  for tok in parts do
  begin
    if i >= DIMBUF then Break;
    if TryStrToInt('$' + tok, x) then
    begin
      bufferU[i] := Byte(x);
      Inc(i);
    end;
  end;
  PacketIO(150);
  result_s := '>[';
  for i := 0 to DIMBUF - 1 do
  begin
    result_s := result_s + Format(' %02X', [bufferU[i]]);
    if (i mod 32 = 31) and (i <> DIMBUF - 1) then
      result_s := result_s + LineEnding + '    ';
  end;
  result_s := result_s + ' ]' + LineEnding + '<[';
  for i := 0 to DIMBUF - 1 do
  begin
    result_s := result_s + Format(' %02X', [bufferI[i]]);
    if (i mod 32 = 31) and (i <> DIMBUF - 1) then
      result_s := result_s + LineEnding + '     ';
  end;
  result_s := result_s + ' ]';
  PrintMessageCMD(result_s);
end;

{ ============================================================
  IOchanged  (← void IOchanged)
  ============================================================ }
procedure TMainForm.IORadioToggle(Sender: TObject);
begin
  IOChanged;
end;

procedure TMainForm.IOChanged;
var
  i, j, z: Integer;
  trisa, trisb, trisc, latac, latb, port: Integer;
  vpp: Double;
begin
  if FProgress <> 0 then Exit;
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  if not IOEN.Checked then Exit;

  trisa := 1; trisb := 0; trisc := $30; latac := 0; latb := 0;
  for i := 0 to 12 do
  begin
    if ioButtons[i].r_1.Checked then
    begin
      if i < 8      then latb  := latb  or (1 shl i)
      else if i = 8 then latac := latac or $80
      else if i = 9 then latac := latac or $40
      else if i = 10 then latac := latac or $20
      else if i = 11 then latac := latac or $10
      else if i = 12 then latac := latac or $08;
    end
    else if ioButtons[i].r_I.Checked then
    begin
      if i < 8       then trisb := trisb or (1 shl i)
      else if i = 8  then trisc := trisc or $80
      else if i = 9  then trisc := trisc or $40
      else if i = 10 then trisa := trisa or $20
      else if i = 11 then trisa := trisa or $10
      else if i = 12 then trisa := trisa or $08;
    end;
  end;

  j := 0;
  bufferU[j] := READ_RAM;  Inc(j); bufferU[j] := $0F; Inc(j); bufferU[j] := $80; Inc(j); // PORTA
  bufferU[j] := READ_RAM;  Inc(j); bufferU[j] := $0F; Inc(j); bufferU[j] := $81; Inc(j); // PORTB
  bufferU[j] := READ_RAM;  Inc(j); bufferU[j] := $0F; Inc(j); bufferU[j] := $82; Inc(j); // PORTC
  bufferU[j] := WRITE_RAM; Inc(j); bufferU[j] := $0F; Inc(j); bufferU[j] := $92; Inc(j); bufferU[j] := trisa; Inc(j);
  bufferU[j] := WRITE_RAM; Inc(j); bufferU[j] := $0F; Inc(j); bufferU[j] := $93; Inc(j); bufferU[j] := trisb; Inc(j);
  bufferU[j] := WRITE_RAM; Inc(j); bufferU[j] := $0F; Inc(j); bufferU[j] := $94; Inc(j); bufferU[j] := trisc; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := latb; Inc(j); bufferU[j] := latac; Inc(j);
  bufferU[j] := READ_ADC;  Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  z := 0;
  while (z < DIMBUF - 3) and (bufferI[z] <> READ_RAM) do Inc(z);
  port := bufferI[z + 3];   // PORTA
  ioButtons[10].e_I.Caption := IfThen((port and $20) <> 0, '1', '0');
  ioButtons[11].e_I.Caption := IfThen((port and $10) <> 0, '1', '0');
  ioButtons[12].e_I.Caption := IfThen((port and $08) <> 0, '1', '0');
  Inc(z, 4);
  while (z < DIMBUF - 3) and (bufferI[z] <> READ_RAM) do Inc(z);
  port := bufferI[z + 3];   // PORTB
  for i := 0 to 7 do
    ioButtons[i].e_I.Caption := IfThen((port and (1 shl i)) <> 0, '1', '0');
  Inc(z, 4);
  while (z < DIMBUF - 3) and (bufferI[z] <> READ_RAM) do Inc(z);
  port := bufferI[z + 3];   // PORTC
  ioButtons[8].e_I.Caption := IfThen((port and $80) <> 0, '1', '0');
  ioButtons[9].e_I.Caption := IfThen((port and $40) <> 0, '1', '0');
  Inc(z, 4);
  while (z < DIMBUF - 2) and (bufferI[z] <> READ_ADC) do Inc(z);
  vpp := ((bufferI[z + 1] shl 8) + bufferI[z + 2]) / 1024.0 * 5 * 34 / 12;
  StatusPush(Format('VPP=%.2fV', [vpp]));
end;

{ ============================================================
  IOactive  (← void IOactive)
  ============================================================ }
procedure TMainForm.IOENClick(Sender: TObject);
begin
  if IOEN.Checked then
  begin
    if FIOTimerObj = nil then
    begin
      var t := TTimer.Create(Self);
      t.Interval := 100;
      t.OnTimer  := procedure(S: TObject) begin IOChanged; end;
      t.Enabled  := True;
      FIOTimerObj := t;
    end;
  end
  else
  begin
    if FIOTimerObj <> nil then
    begin
      TTimer(FIOTimerObj).Enabled := False;
      FreeAndNil(FIOTimerObj);
    end;
  end;
end;

{ ============================================================
  VPPVDDactive  (← void VPPVDDactive)
  ============================================================ }
procedure TMainForm.VDDUENClick(Sender: TObject); begin VPPVDDActive; end;
procedure TMainForm.VPPUENClick(Sender: TObject); begin VPPVDDActive; end;

procedure TMainForm.VPPVDDActive;
var
  j, vdd_vpp: Integer;
  s: string;
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  j := 0; vdd_vpp := 0; s := '';
  if VPPUEN.Checked then begin vdd_vpp := vdd_vpp + 4; s := s + 'VPP '; end;
  if VDDUEN.Checked then begin vdd_vpp := vdd_vpp + 1; s := s + 'VDD '; end;
  StatusPush(Trim(s));
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := vdd_vpp;    Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);
end;

{ ============================================================
  DCDCactive  (← void DCDCactive)
  ============================================================ }
procedure TMainForm.DCDCENClick(Sender: TObject);    begin DCDCActive; end;
procedure TMainForm.VPP_SpinEditChange(Sender: TObject); begin DCDCActive; end;

procedure TMainForm.DCDCActive;
var
  j, vreg: Integer;
  voltage: Double;
begin
  {$IFNDEF DEBUG}
  if DeviceDetected <> 1 then Exit;
  {$ENDIF}
  j := 0;
  if DCDCEN.Checked then
  begin
    voltage := VPP_SpinEdit.Value;
    vreg := Round(voltage * 10.0);
    StatusPush(Format('DCDC %.1fV', [voltage]));
    bufferU[j] := VREG_EN;  Inc(j);
    bufferU[j] := SET_VPP;  Inc(j);
    bufferU[j] := vreg;     Inc(j);
    bufferU[j] := FLUSH;    Inc(j);
  end
  else
  begin
    bufferU[j] := VREG_DIS; Inc(j);
    bufferU[j] := FLUSH;    Inc(j);
  end;
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);
end;

{ ============================================================
  HexConvert  (← void HexConvert)
  ============================================================ }
procedure TMainForm.HEXINChange(Sender: TObject);
begin
  HexConvert;
end;

procedure TMainForm.HexConvert;
var
  hex, s, s2: string;
  i, address, length_, sum, rectype, x: Integer;
begin
  hex := Trim(HEXIN.Text);
  if hex = '' then begin HEXIN.Text := ''; Exit; end;
  if (hex[1] <> ':') or (Length(hex) <= 8) then
  begin
    DATAOUT.Text := '__잘못된 줄';
    Exit;
  end;
  length_ := htoi(Copy(hex, 2, 2), 2);
  address := htoi(Copy(hex, 4, 4), 4);
  if Length(hex) < 11 + length_ * 2 then
  begin
    DATAOUT.Text := '__줄이 너무 짧음';
    Exit;
  end;
  sum := 0;
  i := 1;
  while i <= length_ * 2 + 9 do
  begin
    sum := sum + htoi(Copy(hex, i + 1, 2), 2);
    Inc(i, 2);
  end;
  if (sum and $FF) <> 0 then
  begin
    DATAOUT.Text := Format('__체크섬 오류, 예상값: 0x%02X',
      [((-sum + htoi(Copy(hex, 10 + length_ * 2, 2), 2)) and $FF)]);
    Exit;
  end;
  rectype := htoi(Copy(hex, 8, 2), 2);
  case rectype of
    0: begin
         s := Format('주소: 0x%04X ', [address]);
         if length_ > 0 then s := s + '데이터: 0x';
         for i := 0 to length_ - 1 do
           s := s + Format('%02X', [htoi(Copy(hex, 10 + i * 2, 2), 2)]);
         DATAOUT.Text := s;
       end;
    4: begin
         if Length(hex) > 14 then
           DATAOUT.Text := Format('확장 선형 주소 = %04X', [htoi(Copy(hex, 10, 4), 4)]);
       end;
    else
      DATAOUT.Text := '__알 수 없는 레코드 타입';
  end;
end;

{ ============================================================
  DataToHexConvert  (← void DataToHexConvert)
  ============================================================ }
procedure TMainForm.ADDRINChange(Sender: TObject); begin DataToHexConvert; end;
procedure TMainForm.DATAINChange(Sender: TObject); begin DataToHexConvert; end;

procedure TMainForm.DataToHexConvert;
var
  hex, s, s2: string;
  i, address, length_, sum, x: Integer;
begin
  if not TryStrToInt('$' + Trim(ADDRIN.Text), address) then
    address := 0;
  hex := Trim(DATAIN.Text);
  length_ := Length(hex) and $FF;
  if length_ <= 0 then Exit;
  s := Format(':--%04X00', [address and $FFFF]);
  sum := 0;
  i := 1;
  while i + 1 <= length_ do
  begin
    x := htoi(Copy(hex, i, 2), 2);
    sum := sum + x;
    s := s + Format('%02X', [x]);
    Inc(i, 2);
  end;
  s2 := Format('%02X', [i div 2]);
  s[2] := s2[1]; s[3] := s2[2];
  sum := sum + (i div 2) + (address and $FF) + ((address shr 8) and $FF);
  s := s + Format('%02X', [(-sum) and $FF]);
  HEXOUT.Text := s;
end;

{ ============================================================
  HexSave  (← void HexSave)
  ============================================================ }
procedure TMainForm.HEXSAVEClick(Sender: TObject);
begin
  HexSave_;
end;

procedure TMainForm.HexSave_;
var
  dlg: TSaveDialog;
  f: TextFile;
begin
  if Length(HEXOUT.Text) < 11 then Exit;
  dlg := TSaveDialog.Create(Self);
  try
    dlg.Title   := '파일 저장';
    dlg.Options := dlg.Options + [ofOverwritePrompt];
    if cur_path <> '' then dlg.InitialDir := cur_path;
    if dlg.Execute then
    begin
      cur_path := ExtractFileDir(dlg.FileName);
      AssignFile(f, dlg.FileName);
      Rewrite(f);
      WriteLn(f, HEXOUT.Text);
      CloseFile(f);
    end;
  finally
    dlg.Free;
  end;
end;

{ ============================================================
  ProgID  (← void ProgID)
  ============================================================ }
procedure TMainForm.ProgID;
var
  j: Integer;
begin
  if DeviceDetected <> 1 then Exit;
  j := 0;
  bufferU[j] := PROG_RST; Inc(j);
  bufferU[j] := FLUSH;    Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);
  j := 0;
  while (j < DIMBUF - 7) and (bufferI[j] <> PROG_RST) do Inc(j);
  PrintMessage(Format('FW 버전 %d.%d.%d', [bufferI[j+1], bufferI[j+2], bufferI[j+3]]));
  FWVersion := (bufferI[j+1] shl 16) + (bufferI[j+2] shl 8) + bufferI[j+3];
  PrintMessage(Format('HW ID: %d.%d.%d', [bufferI[j+4], bufferI[j+5], bufferI[j+6]]));
  HwID := bufferI[j+6];
  case HwID of
    1: PrintMessage(' (18F2550)');
    2: PrintMessage(' (18F2450)');
    3: PrintMessage(' (18F2458/2553)');
    4: PrintMessage(' (18F25K50)');
    5: PrintMessage(' (18F25K50 all-in-one)');
    else PrintMessage(' (?)');
  end;
  { HwID=5이면 3.3V 체크 비활성화 }
  CheckBox_3VCHECK.Checked := (HwID = 5);
  CheckBox_3VCHECK.Visible := (HwID <> 5);
end;

{ ============================================================
  CheckV33Regulator  (← int CheckV33Regulator)
  ============================================================ }
function TMainForm.CheckV33Regulator: Integer;
var
  i, j: Integer;
begin
  if skipV33check <> 0 then begin Result := 1; Exit; end;
  j := 0;
  bufferU[j]:=WRITE_RAM; Inc(j); bufferU[j]:=$0F; Inc(j); bufferU[j]:=$93; Inc(j); bufferU[j]:=$FE; Inc(j);
  bufferU[j]:=EXT_PORT;  Inc(j); bufferU[j]:=$01; Inc(j); bufferU[j]:=$00; Inc(j);
  bufferU[j]:=READ_RAM;  Inc(j); bufferU[j]:=$0F; Inc(j); bufferU[j]:=$81; Inc(j);
  bufferU[j]:=EXT_PORT;  Inc(j); bufferU[j]:=$00; Inc(j); bufferU[j]:=$00; Inc(j);
  bufferU[j]:=READ_RAM;  Inc(j); bufferU[j]:=$0F; Inc(j); bufferU[j]:=$81; Inc(j);
  bufferU[j]:=WRITE_RAM; Inc(j); bufferU[j]:=$0F; Inc(j); bufferU[j]:=$93; Inc(j); bufferU[j]:=$FF; Inc(j);
  bufferU[j]:=FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  j := 0;
  while (j < DIMBUF - 3) and (bufferI[j] <> READ_RAM) do Inc(j);
  i := bufferI[j + 3] and $02;
  Inc(j, 3);
  while (j < DIMBUF - 3) and (bufferI[j] <> READ_RAM) do Inc(j);
  Result := IfThen((i + (bufferI[j + 3] and $02)) = 2, 1, 0);
end;

{ ============================================================
  CheckS1  (← int CheckS1)
  ============================================================ }
function TMainForm.CheckS1: Integer;
var
  i, j: Integer;
begin
  j := 0;
  bufferU[j] := READ_RAM; Inc(j);
  bufferU[j] := $0F;      Inc(j);
  if HwID = 5 then bufferU[j] := $80  // PORTA
  else             bufferU[j] := $84; // PORTE
  Inc(j);
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  j := 0;
  while (j < DIMBUF - 3) and (bufferI[j] <> READ_RAM) do Inc(j);
  if HwID = 5 then
    Result := IfThen((bufferI[j+3] and $80) <> 0, 1, 0)
  else
    Result := IfThen((bufferI[j+3] and $08) = 0, 1, 0);
end;

{ ============================================================
  StartHVReg  (← int StartHVReg)
  ============================================================ }
function TMainForm.StartHVReg(V: Double): Integer;
var
  j, z, vreg, v_adc: Integer;
  t0, t: LongWord;
begin
  vreg := Round(V * 10.0);
  if V = -1 then
  begin
    j := 0;
    bufferU[j] := VREG_DIS; Inc(j);
    bufferU[j] := FLUSH;    Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(5);
    msDelay(40);
    Result := -1;
    Exit;
  end;
  t := GetTickCount_; t0 := t;
  j := 0;
  bufferU[j]:=VREG_EN;       Inc(j);
  bufferU[j]:=SET_VPP;       Inc(j); bufferU[j]:=vreg;    Inc(j);
  bufferU[j]:=SET_PARAMETER; Inc(j); bufferU[j]:=SET_T3;  Inc(j);
  bufferU[j]:=2000 shr 8;    Inc(j); bufferU[j]:=2000 and $FF; Inc(j);
  bufferU[j]:=WAIT_T3;       Inc(j);
  bufferU[j]:=READ_ADC;      Inc(j);
  bufferU[j]:=FLUSH;         Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  msDelay(20);
  z := 0;
  while (z < DIMBUF - 2) and (bufferI[z] <> READ_ADC) do Inc(z);
  v_adc := (bufferI[z+1] shl 8) + bufferI[z+2];
  if v_adc = 0 then begin PrintMessage('USB 전압이 너무 낮음 (VUSB<4.5V)'); Result := 0; Exit; end;

  j := 0;
  bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := READ_ADC; Inc(j);
  bufferU[j] := FLUSH;    Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

  while ((v_adc < Round((vreg/10.0 - 1) * G)) or
         (v_adc > Round((vreg/10.0 + 1) * G))) and
        (t < t0 + 1500) do
  begin
    t := GetTickCount_;
    PacketIO(5); msDelay(20);
    z := 0;
    while (z < DIMBUF - 2) and (bufferI[z] <> READ_ADC) do Inc(z);
    v_adc := (bufferI[z+1] shl 8) + bufferI[z+2];
    if HwID = 3 then v_adc := v_adc shr 2;
  end;

  if v_adc > Round((vreg/10.0 + 1) * G) then
    begin PrintMessage('경고: 레귤레이터 전압이 너무 높음'); Result := 0; end
  else if v_adc < Round((vreg/10.0 - 1) * G) then
    begin PrintMessage('경고: 레귤레이터 전압이 너무 낮음'); Result := 0; end
  else if v_adc = 0 then
    begin PrintMessage('USB 전압이 너무 낮음'); Result := 0; end
  else
  begin
    PrintMessage(Format('레귤레이터 정상 T=%d ms VPP=%.1f V', [t - t0, v_adc / G]));
    Result := vreg;
  end;
end;

{ ============================================================
  DisplayEE  (← void DisplayEE)
  ============================================================ }
procedure TMainForm.DisplayEE;
var
  s, t, v, aux: string;
  valid, empty, lines, i, j, max_: Integer;
  ch: Char;
begin
  s := ''; v := ''; aux := '';
  valid := 0; empty := 1; lines := 0;
  PrintMessage(LineEnding + 'EEPROM 메모리:' + LineEnding);
  max_ := IfThen(sizeEE > 7000, 7000, sizeEE);
  i := 0;
  while i < max_ do
  begin
    valid := 0; s := ''; v := '';
    j := i;
    while (j < i + COL) and (j < sizeEE) do
    begin
      s := s + Format('%02X ', [memEE^[j]]);
      ch := Char(memEE^[j]);
      if (Ord(ch) >= 32) and (memEE^[j] < $FF) then v := v + ch
      else v := v + '.';
      if memEE^[j] < $FF then valid := 1;
      Inc(j);
    end;
    if valid <> 0 then
    begin
      t := Format('%04X: %s %s', [i, s, v]) + LineEnding;
      aux := aux + t;
      empty := 0; Inc(lines);
      if lines > 500 then
      begin
        aux := aux + '(...)' + LineEnding;
        i := max_ - COL * 2;
        lines := 490;
      end;
    end;
    Inc(i, COL);
  end;
  if empty <> 0 then PrintMessage('(비어 있음)')
  else
  begin
    PrintMessage(aux);
    if sizeEE > max_ then PrintMessage('(...)' + LineEnding);
  end;
end;

{ ============================================================
  PacketIO  (← void PacketIO)  Linux/Windows 분기
  ============================================================ }
procedure TMainForm.PacketIO(Delay: Double);
const
  TIMEOUT_MS = 50;
var
  delay0: Integer;
{$IFDEF UNIX}
  res: Integer;
  set_: TFDSet;
  tv: TTimeVal;
{$ELSE}
  Result_: DWORD;
{$ENDIF}
begin
  delay0 := Round(Delay);
  if (saveLog <> 0) and (TextRec(logfile).Mode <> 0) then
    WriteLn(logfile, Format('PacketIO(%.2f)', [Delay]));

{$IFDEF UNIX}
  fpFD_ZERO(set_);
  fpFD_SET(fd, set_);
  tv.tv_sec  := 0;
  tv.tv_usec := TIMEOUT_MS * 1000;
  Delay := Delay - (TIMEOUT_MS - 10);
  if Delay < 0 then Delay := 0;
  res := fpWrite(fd, bufferU, DIMBUF);
  if res < 0 then PrintMessage('쓰기 오류');
  fpUSleep(Round(Delay * 1000.0));
  res := fpSelect(fd + 1, @set_, nil, nil, @tv);
  if res = -1 then begin PrintMessage('IO 오류'); Exit; end
  else if res = 0 then begin PrintMessage('통신 타임아웃'); Exit; end;
  res := fpRead(fd, bufferI, DIMBUF);
  if res < 0 then PrintMessage('읽기 오류');
{$ELSE}
  { Windows HID 통신 }
  WriteFile(WriteHandle, bufferU0, DIMBUF + 1, nil, nil);
  Sleep(Round(Delay));
  ReadFile(ReadHandle, bufferI0, DIMBUF + 1, nil, @HIDOverlapped);
  Result_ := WaitForSingleObject(hEventObject, TIMEOUT_MS);
  if Result_ <> WAIT_OBJECT_0 then PrintMessage('통신 타임아웃');
  ResetEvent(hEventObject);
{$ENDIF}

  if (saveLog <> 0) and (TextRec(logfile).Mode <> 0) then
    WriteLogIO_;
end;

{ ============================================================
  msDelay  (← void msDelay)
  ============================================================ }
procedure TMainForm.msDelay(Delay: Double);
begin
{$IFDEF UNIX}
  fpUSleep(Round(Delay * 1000.0));
{$ELSE}
  Sleep(Round(Delay));
{$ENDIF}
end;

{ ============================================================
  GetTickCount_  (← DWORD GetTickCount / Linux)
  ============================================================ }
function TMainForm.GetTickCount_: LongWord;
begin
{$IFDEF UNIX}
  Result := LongWord(LCLIntf.GetTickCount);
{$ELSE}
  Result := Windows.GetTickCount;
{$ENDIF}
end;

{ ============================================================
  htoi  (← unsigned int htoi)
  ============================================================ }
function TMainForm.htoi(const Hex: string; Length_: Integer): Integer;
var
  s: string;
begin
  s := Copy(Hex, 1, Length_);
  if not TryStrToInt('$' + s, Result) then Result := 0;
end;

{ ============================================================
  FindDevice  (← int FindDevice)  Linux/Windows 분기
  ============================================================ }
function TMainForm.FindDevice(AVid, APid: Integer): Integer;
{$IFDEF UNIX}
var
  i: Integer;
  device_info: record vendor, product, bustype: Word; end; { hidraw_devinfo 근사 }
  p: string;
begin
  Result := 0;
  if path_ = '' then
  begin
    { /dev/openprogrammer 우선 시도 }
    fd := fpOpen('/dev/openprogrammer', O_RDWR or O_NONBLOCK);
    if fd > 0 then
    begin
      { ioctl HIDIOCGRAWINFO: BaseUnix.fpIoctl 사용 }
      path_ := '/dev/openprogrammer';
      { VID/PID 확인은 단순화 – 실제로는 ioctl 호출 필요 }
    end;
    if fd <= 0 then
    begin
      for i := 0 to 15 do
      begin
        p := Format('/dev/hidraw%d', [i]);
        fd := fpOpen(p, O_RDWR or O_NONBLOCK);
        if fd > 0 then
        begin
          { ioctl로 VID/PID 확인 (실제 구현 필요) }
          path_ := p;
          Break;
        end;
      end;
      if i = 16 then
      begin
        PrintMessage('프로그래머를 찾을 수 없음');
        path_ := '';
        Result := 0;
        Exit;
      end;
    end;
  end
  else
  begin
    fd := fpOpen(path_, O_RDWR or O_NONBLOCK);
    if fd < 0 then begin PrintMessage('디바이스를 열 수 없음'); Result := 0; Exit; end;
  end;
  PrintMessage(Format('프로그래머 감지: %s', [path_]));
  Result := 1;
end;
{$ELSE}
{ Windows: SetupAPI / HID 다이나믹 로드 }
var
  MyDeviceDetected: Boolean;
  { 실제 구현에서는 LoadLibrary('hid.dll') + SetupDiGetClassDevs 등 사용 }
begin
  MyDeviceDetected := False;
  { TODO: Windows HID 열거 구현 (원본 C 코드의 do..while 블록 참고) }
  if not MyDeviceDetected then
    PrintMessage('프로그래머를 찾을 수 없음')
  else
  begin
    PrintMessage(Format('프로그래머 감지: VID=0x%04X PID=0x%04X', [AVid, APid]));
  end;
  Result := IfThen(MyDeviceDetected, 1, 0);
end;
{$ENDIF}

{ ============================================================
  로그 파일 헬퍼  (← OpenLogFile / WriteLogIO / CloseLogFile)
  ============================================================ }
procedure TMainForm.OpenLogFile_;
begin
  if LogFileName = '' then LogFileName := 'opgui.log';
  AssignFile(logfile, LogFileName);
  try Rewrite(logfile); except end;
end;

procedure TMainForm.WriteLogIO_;
var
  i: Integer;
  s: string;
begin
  if TextRec(logfile).Mode = 0 then Exit;
  s := '>[';
  for i := 0 to DIMBUF - 1 do s := s + Format(' %02X', [bufferU[i]]);
  WriteLn(logfile, s + ' ]');
  s := '<[';
  for i := 0 to DIMBUF - 1 do s := s + Format(' %02X', [bufferI[i]]);
  WriteLn(logfile, s + ' ]');
end;

procedure TMainForm.CloseLogFile_;
begin
  try CloseFile(logfile); except end;
end;

{ ============================================================
  ICD 탭 핸들러 – icd 유닛에 위임
  ============================================================ }
procedure TMainForm.LOADCOFF_BClick(Sender: TObject); begin loadCoff(Self); end;
procedure TMainForm.ICD_RUNClick(Sender: TObject);    begin icdRun(Self);   end;
procedure TMainForm.ICD_HALTClick(Sender: TObject);   begin icdHalt(Self);  end;
procedure TMainForm.ICD_STEPClick(Sender: TObject);   begin icdStep(Self);  end;
procedure TMainForm.ICD_STEPOVERClick(Sender: TObject); begin icdStepOver(Self); end;
procedure TMainForm.ICD_STOPClick(Sender: TObject);   begin icdStop(Self);  end;
procedure TMainForm.ICD_REFRESHClick(Sender: TObject); begin icdRefresh(Self); end;
procedure TMainForm.ICD_HELPClick(Sender: TObject);   begin ICDHelp(Self);  end;
procedure TMainForm.ICD_CMD_EKeyPress(Sender: TObject; var Key: Char);
begin
  icdCommand_key_event(Sender, Key);
end;
procedure TMainForm.ICD_SOURCEMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  source_mouse_event(Sender, Button, Shift, X, Y);
end;
procedure TMainForm.ICD_STATUSMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  icdStatus_mouse_event(Sender, Button, Shift, X, Y);
end;
procedure TMainForm.BANK0_MClick(Sender: TObject); begin icdShowBank(0); end;
procedure TMainForm.BANK1_MClick(Sender: TObject); begin icdShowBank(1); end;
procedure TMainForm.BANK2_MClick(Sender: TObject); begin icdShowBank(2); end;
procedure TMainForm.BANK3_MClick(Sender: TObject); begin icdShowBank(3); end;
procedure TMainForm.EE_MClick(Sender: TObject);    begin icdShowEE;      end;

end.
