unit opgui;

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
  LCLType,
  common,
  i2cspi,
  coff,
  icd,
  devicerw,
  fileio,
  progavr,
  glib_types,
  gtk_types,
  libc_types,
  sys_types,
  mainform;

const
  NL = #10;
  MAXLINES = 600;
  CONFIG_FILE = 'opgui.ini';
  CONFIG_DIR = '.opgui';
  MinDly = 0;
  TIMEOUT = 50;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

  Tio_btn = record
    name_: PChar;
    x: Integer;
    y: Integer;
    r_0: PControl;
    r_1: PControl;
    r_I: PControl;
    e_I: PControl;
  end;

type
  TDWORD = Cardinal;
  TWORD = Word;
  TBYTE = Byte;
  Tfilehdr_t = record
    f_magic: Word;
    f_nscns: Word;
    f_timdat: Cardinal;
    f_symptr: Cardinal;
    f_nsyms: Cardinal;
    f_opthdr: Word;
    f_flags: Word;
  end;
  PTfilehdr_t = ^Tfilehdr_t;
  Topthdr_t = record
    magic: Word;
    vstamp: Cardinal;
    proc_type: Cardinal;
    rom_width_bits: Cardinal;
    ram_width_bits: Cardinal;
  end;
  PTopthdr_t = ^Topthdr_t;
  Tscnhdr_t = record
    _s: TUnionRecord;
    s_paddr: Cardinal;
    s_vaddr: Cardinal;
    s_size: Cardinal;
    s_scnptr: Cardinal;
    s_relptr: Cardinal;
    s_lnnoptr: Cardinal;
    s_nreloc: Word;
    s_nlnno: Word;
    s_flags: Cardinal;
  end;
  PTscnhdr_t = ^Tscnhdr_t;
  Treloc_t = record
    r_vaddr: Cardinal;
    r_symndx: Cardinal;
    r_offset: SmallInt;
    r_type: Word;
  end;
  PTreloc_t = ^Treloc_t;
  Tsyment_t = record
    _n: TUnionRecord;
    n_value: Cardinal;
    n_scnum: SmallInt;
    n_type: Cardinal;
    n_sclass: Char;
    n_numaux: Byte;
  end;
  PTsyment_t = ^Tsyment_t;
  Tcoff_lineno_t = record
    l_srcndx: Cardinal;
    l_lnno: Word;
    l_paddr: Cardinal;
    l_flags: Word;
    l_fcnndx: Cardinal;
  end;
  PTcoff_lineno_t = ^Tcoff_lineno_t;
  Taux_file_t = record
    x_offset: Cardinal;
    x_incline: Cardinal;
    x_flags: Byte;
    _unused: array[0..11-1] of Char;
  end;
  PTaux_file_t = ^Taux_file_t;
  Taux_scn_t = record
    x_scnlen: Cardinal;
    x_nreloc: Word;
    x_nlinno: Word;
    _unused: array[0..12-1] of Char;
  end;
  PTaux_scn_t = ^Taux_scn_t;
  Taux_tag_t = record
    _unused: array[0..6-1] of Char;
    x_size: Word;
    _unused2: array[0..4-1] of Char;
    x_endndx: Cardinal;
    _unused3: array[0..4-1] of Char;
  end;
  PTaux_tag_t = ^Taux_tag_t;
  Taux_eos_t = record
    x_tagndx: Cardinal;
    _unused: array[0..2-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_eos_t = ^Taux_eos_t;
  Taux_fcn_t = record
    x_tagndx: Cardinal;
    x_size: Cardinal;
    x_lnnoptr: Cardinal;
    x_endndx: Cardinal;
    x_actscnum: SmallInt;
    _unused: array[0..2-1] of Char;
  end;
  PTaux_fcn_t = ^Taux_fcn_t;
  Taux_fcn_calls_t = record
    x_calleendx: Cardinal;
    x_is_interrupt: Cardinal;
    _unused: array[0..12-1] of Char;
  end;
  PTaux_fcn_calls_t = ^Taux_fcn_calls_t;
  Taux_arr_t = record
    x_tagndx: Cardinal;
    x_lnno: Word;
    x_size: Word;
    x_dimen: array[0..4-1] of Word;
    _unused: array[0..4-1] of Char;
  end;
  PTaux_arr_t = ^Taux_arr_t;
  Taux_eobf_t = record
    _unused: array[0..4-1] of Char;
    x_lnno: Word;
    _unused2: array[0..14-1] of Char;
  end;
  PTaux_eobf_t = ^Taux_eobf_t;
  Taux_bobf_t = record
    _unused: array[0..4-1] of Char;
    x_lnno: Word;
    _unused2: array[0..6-1] of Char;
    x_endndx: Cardinal;
    _unused3: array[0..4-1] of Char;
  end;
  PTaux_bobf_t = ^Taux_bobf_t;
  Taux_var_t = record
    x_tagndx: Cardinal;
    _unused: array[0..2-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_var_t = ^Taux_var_t;
  Taux_field_t = record
    _unused: array[0..6-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_field_t = ^Taux_field_t;

var
  strings_it: array[0..DIM-1] of PChar;
  strings_en: array[0..DIM-1] of PChar;
  STR_ID: array[0..DIM-1] of PChar;
  bufferU0: array[0..128-1] of Byte;
  bufferI0: array[0..128-1] of Byte;
  bufferU: PByte;
  bufferI: PByte;
  NumberOfBytesRead: TDWORD;
  BytesWritten: TDWORD;
  Result_: TULONG;
  WriteHandle: THANDLE;
  ReadHandle: THANDLE;
  HIDOverlapped: TOVERLAPPED;
  hEventObject: THANDLE;
  statusID: Integer;
  status_bar: PControl;
  str: array[0..4096-1] of Char;
  saveLog: Integer;
  strings: PChar;
  fd: Integer;
  programID: Integer;
  MinDly: Integer;
  load_osccal: Integer;
  load_BKosccal: Integer;
  use_osccal: Integer;
  use_BKosccal: Integer;
  load_calibword: Integer;
  max_err: Integer;
  AVRlock: Integer;
  AVRfuse: Integer;
  AVRfuse_h: Integer;
  AVRfuse_x: Integer;
  ICDenable: Integer;
  ICDaddr: Integer;
  FWVersion: Integer;
  HwID: Integer;
  logfile: ^TextFile;
  LogFileName: array[0..512-1] of Char;
  loadfile: array[0..512-1] of Char;
  savefile: array[0..512-1] of Char;
  memCODE_W: PWORD;
  size: Integer;
  sizeW: Integer;
  sizeEE: Integer;
  sizeCONFIG: Integer;
  sizeUSERID: Integer;
  memCODE: PByte;
  memEE: PByte;
  memID: array[0..512-1] of Byte;
  memCONFIG: array[0..48-1] of Byte;
  memUSERID: array[0..8-1] of Byte;
  hvreg: Double;
  RWstop: Integer;
  useSAFLOCK_flag: Integer;
  variables: array[0..0x200-1] of Tvar;
  statusTxt: PControl;
  sourceTxt: PControl;
  sourceBuf: PMemo;
  icdVbox1: PControl;
  icdMenuPC: PControl;
  icdMenuSTAT: PControl;
  icdMenuBank0: PControl;
  icdMenuBank1: PControl;
  icdMenuBank2: PControl;
  icdMenuBank3: PControl;
  icdMenuEE: PControl;
  icdCommand: PControl;
  statusBuf: PMemo;
  icdTimer: Integer;
  devices: array of PChar;
  Ndevices: Integer;
  NDEVLIST: Integer;
  DEVLIST: array of TDEVICES;
  cmdline: Integer;
  loadfileEE: array[0..512-1] of Char = ();
  savefileEE: array[0..512-1] of Char = ();
  CoffFileName: array[0..512-1] of Char = ();
  vid: Integer;
  pid: Integer;
  new_vid: Integer;
  new_pid: Integer;
  old_vid: Integer;
  old_pid: Integer;
  DeviceDetected: Integer;
  IOTimer: Integer;
  skipV33check: Integer;
  waitS1: Integer;
  waitingS1: Integer;
  progress: Integer;
  forceConfig: Integer;
  dataBuf: PMemo;
  data: PControl;
  data_scroll: PControl;
  window: PControl;
  toolbar: PControl;
  button: PControl;
  b_open: PControl;
  b_save: PControl;
  b_read: PControl;
  b_write: PControl;
  notebook: PControl;
  label_: PControl;
  img: PControl;
  devTree: PControl;
  devTypeCombo: PControl;
  devFramePIC: PControl;
  ICD_check: PControl;
  ICD_addr_entry: PControl;
  EEPROM_RW: PControl;
  ReadReserved: PControl;
  Write_ID_BKCal: PControl;
  WriteCalib12: PControl;
  UseSaflock: PControl;
  UseOSCCAL: PControl;
  UseBKOSCCAL: PControl;
  UseFileCal: PControl;
  devFrameAVR: PControl;
  AVR_FuseLow: PControl;
  AVR_FuseLowWrite: PControl;
  AVR_FuseHigh: PControl;
  AVR_FuseHighWrite: PControl;
  AVR_FuseExt: PControl;
  AVR_FuseExtWrite: PControl;
  AVR_Lock: PControl;
  AVR_LockWrite: PControl;
  b_WfuseLF: PControl;
  b_connect: PControl;
  b_testhw: PControl;
  b_log: PControl;
  VID_entry: PControl;
  PID_entry: PControl;
  Errors_entry: PControl;
  I2C8bit: PControl;
  I2C16bit: PControl;
  SPI00: PControl;
  SPI01: PControl;
  SPI10: PControl;
  SPI11: PControl;
  I2CDataSend: PControl;
  I2CDataReceive: PControl;
  I2CSendBtn: PControl;
  I2CReceiveBtn: PControl;
  I2CNbyte: PControl;
  I2CSpeed: PControl;
  DCDC_ON: PControl;
  DCDC_voltage: PControl;
  VPP_ON: PControl;
  VDD_ON: PControl;
  b_io_active: PControl;
  commandSend: PControl;
  commandTransfer: PControl;
  b_V33check: PControl;
  Hex_entry: PControl;
  Address_entry: PControl;
  Data_entry: PControl;
  Hex_data: PControl;
  Hex_data2: PControl;
  CW1_entry: PControl;
  CW2_entry: PControl;
  CW3_entry: PControl;
  CW4_entry: PControl;
  CW5_entry: PControl;
  CW6_entry: PControl;
  CW7_entry: PControl;
  ConfigForce: PControl;
  b_WaitS1: PControl;
  devFrameConfigW: PControl;
  devFrameICD: PControl;
  devFrameOsc: PControl;
  devPIC_CW1: PControl;
  devPIC_CW2: PControl;
  devPIC_CW3: PControl;
  devPIC_CW4: PControl;
  devPIC_CW5: PControl;
  devPIC_CW6: PControl;
  devPIC_CW7: PControl;
  devPIC_CW8: PControl;
  devinfo: PControl;
  stopBtn: PControl;
  readBtn: PControl;
  writeBtn: PControl;
  devStore: PGtkListStore;
  devFiltEntry: PControl;
  devFrame: PControl;
  devSel: PObject;
  ioButtons: array[0..13-1] of Tio_btn;
  ee: Integer;
  readRes: Integer;
  dev: array[0..64-1] of Char = ();
  devType: Integer;
  cur_path: PChar;
  cur_pathEE: PChar;
  groupNames: array[0..NUM_GROUPS-1] of PChar = ($50, $49, $43, $31, $30, $2F, $31, $32, $50, $49, $43, $31, $36, $50, $49, $43, $31, $38, $50, $49, $43, $32, $34, $50, $49, $43, $33, $30, $2F, $33, $33, $41, $54, $4D, $45, $4C, $20, $41, $56, $52, $4D, $45, $4D, $4F, $52, $59);
  GROUP_ALL: PChar;

  ioButtons: array[0..13-1] of Tio_btn;

// --- function declarations ---
procedure strinit;
function strfind(langid: PChar; langfile: PChar): Integer;
function GenerateLangFile(langid: PChar; langfile: PChar): Pointer;
function StartHVReg(V: Double): Integer;
function msDelay(delay: Double): Pointer;
procedure DisplayEE;
function PrintMessage(msg: PChar): Pointer;
function PrintMessageI2C(msg: PChar): Pointer;
function CheckV33Regulator: Integer;
procedure OpenLogFile;
procedure WriteLogIO;
procedure CloseLogFile;
function htoi(hex: PChar; length: Integer): Cardinal;
function PacketIO(delay: Double): Pointer;
function I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: PBYTE): Pointer;
function I2CSend(mode: Integer; speed: Integer; N: Integer; buffer: PBYTE): Pointer;
function scanSourceFile(s_files_p: ^Tsrcfile): ^TextFile;
function analyzeCOFF(filename: PChar; label_: array[0..0x2200-1] of PChar; ulabel: array[0..0x400-1] of PChar; source_info: array[0..0x2200-1] of Tsrc_i; s_files_p: ^^Tsrcfile; data: array[0..0x2200-1] of Word; sym_p: ^^Tsymbol; nsym: ^Integer): Integer;
function startICD(Tck: Integer): Pointer;
function isRunning: Integer;
function cont(break_addr: Integer; freeze: Integer): Pointer;
procedure step;
procedure run;
function version: Integer;
procedure Halt_;
function ReadRegister(addr: Integer): Integer;
function ReadRegisterN(addr: Integer; n: Integer; buf: ^Integer): Integer;
function WriteRegister(addr: Integer; data: Integer): Pointer;
function ReadProgMem(addr: Integer): Integer;
function ReadProgMemN(addr: Integer; n: Integer; buf: ^Integer): Integer;
function ReadDataMem(addr: Integer): Integer;
function ReadDataMemN(addr: Integer; n: Integer; buf: PByte): Integer;
function decodeCmd(cmd: Integer; str: PChar; addrH: Integer): PChar;
function getVar(addr: Integer; var_: PChar): PChar;
function scrollToLine(line: Integer): Pointer;
function SourceHilightLine(line: Integer): Pointer;
function SourceRemoveHilightLine(line: Integer): Pointer;
function loadSource(f: ^TextFile): Integer;
function loadCoff(widget: PControl; window: PControl): Pointer;
procedure initVar;
function ICDHelp(widget: PControl; window: PControl): Pointer;
function icdCheck(widget: PControl; window: PControl): Pointer;
function icdRun(widget: PControl; window: PControl): Pointer;
function icdHalt(widget: PControl; window: PControl): Pointer;
function icdStep(widget: PControl; window: PControl): Pointer;
function icdStepOver(widget: PControl; window: PControl): Pointer;
function icdStop(widget: PControl; window: PControl): Pointer;
function icdRefresh(widget: PControl; window: PControl): Pointer;
function ShowBank(bank: Integer; status: PChar): Pointer;
procedure ShowContext;
function addWatch(s: Tsymbol): Integer;
function executeCommand(command: PChar): Integer;
function removeWatch(name_: PChar): Integer;
function source_mouse_event(widget: PControl; event: PGdkEventButton; func_data: Pointer): Integer;
function icdStatus_mouse_event(widget: PControl; event: PGdkEventButton; func_data: Pointer): Integer;
function icdCommand_key_event(widget: PControl; event: PGdkEventButton; func_data: Pointer): Integer;
function icd_key_event(widget: PControl; event: PGdkEventButton; func_data: Pointer): Integer;
function nameToGroup(devName: PChar): Tgroup_t;
function populateDevInfo(info: PDevInfo; devlistEntry: PDEVICES): Pointer;
function GetDevInfo(dev: PChar): TDevInfo;
function ListDevices: PChar;
function GetDevType(device: PChar): Integer;
function GetDevInfo(dev: PChar): TDevInfo;
function Write_(dev: PChar; ee: Integer): Pointer;
function Read_(dev: PChar; ee: Integer; r: Integer): Pointer;
function htoi(hex: PChar; length: Integer): Cardinal;
function Save(devType: Integer; savefile: PChar): Pointer;
function Load(devType: Integer; loadfile: PChar): Integer;
function SaveEE(devType: Integer; savefile: PChar): Pointer;
function LoadEE(devType: Integer; loadfile: PChar): Integer;
procedure OpenLogFile;
procedure WriteLogIO;
procedure CloseLogFile;
function ReadAT(dim: Integer; dim2: Integer; options: Integer): Pointer;
function ReadAT_HV(dim: Integer; dim2: Integer; options: Integer): Pointer;
function WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer): Pointer;
function WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
function WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
function DisplayCODEAVR(dim: Integer): Pointer;
function WriteATfuseSlow(fuse: Integer): Pointer;
function Connect(widget: PControl; window: PControl): Pointer;
procedure I2cspiR;
procedure I2cspiS;
procedure ProgID;
function PrintMessageI2C(msg: PChar): Pointer;
procedure ShowContext;
function FindDevice(vid: Integer; pid: Integer): Integer;
function CheckS1: Integer;
function delete_event(widget: PControl; event: PGdkEvent; data: Pointer): Integer;
function info(widget: PControl; window: PControl): Pointer;
function PrintMessage(msg: PChar): Pointer;
function PrintMessageI2C(msg: PChar): Pointer;
function PrintMessageCMD(msg: PChar): Pointer;
procedure getOptions;
procedure GetSelectedDevice;
function Fopen(widget: PControl; window: PControl): Pointer;
function Fsave(widget: PControl; window: PControl): Pointer;
procedure selectDataTab;
function DevWrite(widget: PControl; window: PControl): Pointer;
function DevRead(widget: PControl; window: PControl): Pointer;
function WriteATfuseLowLF(widget: PControl; window: PControl): Pointer;
function onDevSel_Changed(widget: PControl; window: PControl): Pointer;
function selectDev_ForeachFunc(model: PGtkTreeModel; path: PGtkTreePath; iter: PGtkTreeIter; devNameToSelect: PChar): Boolean;
function sortIterCompareFunc(model: PGtkTreeModel; a: PGtkTreeIter; b: PGtkTreeIter; userdata: Pointer): Integer;
function strupr(s: PChar): PChar;
function AddDevices(groupFilter: Tgroup_t; textFilter: PChar): Pointer;
function FilterDevType(widget: PControl; window: PControl): Pointer;
function IOchanged(widget: PControl; window: PControl): Pointer;
function IOactive(widget: PControl; window: PControl): Pointer;
function VPPVDDactive(widget: PControl; window: PControl): Pointer;
function DCDCactive(widget: PControl; window: PControl): Pointer;
function HexConvert(widget: PControl; window: PControl): Pointer;
function DataToHexConvert(widget: PControl; window: PControl): Pointer;
function HexSave(widget: PControl; window: PControl): Pointer;
function Stop(widget: PControl; window: PControl): Pointer;
procedure Xclose;
function MsgBox(msg: PChar): Pointer;
function Connect(widget: PControl; window: PControl): Pointer;
procedure I2cspiR;
procedure I2cspiS;
procedure CommandIO;
procedure DisplayEE;
function StartHVReg(V: Double): Integer;
procedure ProgID;
function CheckV33Regulator: Integer;
function CheckS1: Integer;
function TestHw(widget: PControl; parent: PForm): Pointer;
function msDelay(delay: Double): Pointer;
function PacketIO(delay: Double): Pointer;
function main(argc: Integer; argv: array of PChar): Integer;
function FindDevice(vid: Integer; pid: Integer): Integer;

implementation

function delete_event(widget: PControl; event: PGdkEvent; data: Pointer): Integer;
var
  // (no local variables detected)
begin
  gtk_main_quit();
  Exit(FALSE_);
end;

function info(widget: PControl; window: PControl): Pointer;
var
  license: PChar;
begin
  license := 'This program is free software; you can redistribute it and/or' + NL + 'modify it under the terms of the GNU Library General Public License as' + NL + 'published by the Free Software Foundation; either version 2 of the' + NL + 'License, or (at your option) any later version.' + NL + '' + NL + 'This program is distributed in the hope that it will be useful,' + NL + 'but WITHOUT ANY WARRANTY; without even the implied warranty of' + NL + 'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU' + NL + 'Library General Public License for more details.' + NL + '' + NL + 'You should have received a copy of the GNU Library General Public' + NL + 'License along with the Gnome Library; see the file COPYING.LIB.  If not,' + NL + 'write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,' + NL + 'Boston, MA 02111-1307, USA.' + NL + '';
  gtk_show_about_dialog(nil, 'comments', 'A graphical interface for the Open Programmer', 'copyright', 'Copyright (C) Alberto Maccioni 2009-2025' + NL + '' + NL + 'This program is free software; you can ' + NL + 'redistribute it and/or modify it under ' + NL + 'the terms of the GNU General Public License ' + NL + 'as published by the Free Software Foundation;' + NL + 'either version 2 of the License, or ' + NL + '(at your option) any later version.', 'license', license, 'logo', gdk_pixbuf_new_from_resource('/res/sys.png', nil), 'program-name', 'OPGUI', 'version', 'unknown', 'website', 'www.openprog.altervista.org', 'wrap-license', TRUE_, 'title', 'Info about OPGUI', nil);
end;

function PrintMessage(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  l: Integer;
begin
  if cmdline then
   Exit;
  gtk_text_buffer_get_end_iter(dataBuf, @iter);
  gtk_text_buffer_insert(dataBuf, @iter, msg, -1);
  gtk_text_buffer_get_start_iter(dataBuf, @iter2);
  gtk_text_buffer_get_end_iter(dataBuf, @iter);
  l := gtk_text_buffer_get_line_count(dataBuf);
  if l > 600 + 10 then
  begin
   gtk_text_iter_set_line(@iter, l - 600);
   gtk_text_buffer_delete(dataBuf, @iter2, @iter);
  end;
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
  gtk_text_buffer_get_end_iter(dataBuf, @iter);
  gtk_text_view_scroll_to_iter(data, @iter, 0.0, FALSE_, 0, 0);
end;

function PrintMessageI2C(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
  dataBuf: PMemo;
begin
  dataBuf := gtk_text_view_get_buffer(I2CDataReceive);
  gtk_text_buffer_set_text(dataBuf, msg, -1);
  gtk_text_buffer_get_end_iter(dataBuf, @iter);
  gtk_text_view_scroll_to_iter(I2CDataReceive, @iter, 0.0, FALSE_, 0, 0);
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
end;

function PrintMessageCMD(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
  dataBuf: PMemo;
begin
  dataBuf := gtk_text_view_get_buffer(commandTransfer);
  gtk_text_buffer_set_text(dataBuf, msg, -1);
  gtk_text_buffer_get_end_iter(dataBuf, @iter);
  gtk_text_view_scroll_to_iter(commandTransfer, @iter, 0.0, FALSE_, 0, 0);
end;

procedure getOptions;
var
  i: Integer;
  str: PChar;
  cw1: Integer;
  cw2: Integer;
  cw3: Integer;
  cw4: Integer;
  cw5: Integer;
  cw6: Integer;
  cw7: Integer;
begin
  vid := htoi(gtk_entry_get_text(VID_entry), 4);
  pid := htoi(gtk_entry_get_text(PID_entry), 4);
  saveLog := gtk_toggle_button_get_active(b_log);
  ee := IfThen(gtk_toggle_button_get_active(EEPROM_RW), $FFFF, 0);
  programID := gtk_toggle_button_get_active(Write_ID_BKCal);
  max_err := atoi(gtk_entry_get_text(Errors_entry));
  load_calibword := gtk_toggle_button_get_active(WriteCalib12);
  useSAFLOCK_flag := gtk_toggle_button_get_active(UseSaflock);
  load_osccal := not (gtk_toggle_button_get_active(UseOSCCAL));
  load_BKosccal := gtk_toggle_button_get_active(UseBKOSCCAL);
  ICDenable := gtk_toggle_button_get_active(ICD_check);
  readRes := gtk_toggle_button_get_active(ReadReserved);
  skipV33check := gtk_toggle_button_get_active(b_V33check);
  waitS1 := gtk_toggle_button_get_active(b_WaitS1);
  i := sscanf(gtk_entry_get_text(ICD_addr_entry), '%x', @ICDaddr);
  if (i <> 1) or (ICDaddr < 0) or (ICDaddr > $FFFF) then
   ICDaddr := $1FF0;
  str := 0;
  if str then
   strncpy(dev, str, SizeOf(dev) - 1);
  g_free(str);
  AVRlock := $100; AVRfuse_x := $100; AVRfuse_h := $100; AVRfuse := $100;
  if gtk_toggle_button_get_active(AVR_FuseLowWrite) then
  begin
   i := sscanf(gtk_entry_get_text(AVR_FuseLow), '%x', @AVRfuse);
   if (i <> 1) or (AVRfuse < 0) or (AVRfuse > $FF) then
    AVRfuse := $100;
  end;
  if gtk_toggle_button_get_active(AVR_FuseHighWrite) then
  begin
   i := sscanf(gtk_entry_get_text(AVR_FuseHigh), '%x', @AVRfuse_h);
   if (i <> 1) or (AVRfuse_h < 0) or (AVRfuse_h > $FF) then
    AVRfuse_h := $100;
  end;
  if gtk_toggle_button_get_active(AVR_FuseExtWrite) then
  begin
   i := sscanf(gtk_entry_get_text(AVR_FuseExt), '%x', @AVRfuse_x);
   if (i <> 1) or (AVRfuse_x < 0) or (AVRfuse_x > $FF) then
    AVRfuse_x := $100;
  end;
  if gtk_toggle_button_get_active(AVR_LockWrite) then
  begin
   i := sscanf(gtk_entry_get_text(AVR_Lock), '%x', @AVRlock);
   if (i <> 1) or (AVRlock < 0) or (AVRlock > $FF) then
    AVRlock := $100;
  end;
  str := malloc(128);
  if gtk_toggle_button_get_active(ConfigForce) then
  begin
   cw7 := $10000; cw6 := $10000; cw5 := $10000; cw4 := $10000; cw3 := $10000; cw2 := $10000; cw1 := $10000;
   i := sscanf(gtk_entry_get_text(CW1_entry), '%x', @cw1);
   i := sscanf(gtk_entry_get_text(CW2_entry), '%x', @cw2);
   i := sscanf(gtk_entry_get_text(CW3_entry), '%x', @cw3);
   i := sscanf(gtk_entry_get_text(CW4_entry), '%x', @cw4);
   i := sscanf(gtk_entry_get_text(CW5_entry), '%x', @cw5);
   i := sscanf(gtk_entry_get_text(CW6_entry), '%x', @cw6);
   i := sscanf(gtk_entry_get_text(CW7_entry), '%x', @cw7);
   if devType = PIC16 then
   begin
    if (not (strncmp(dev, '16F1', 4)) or not (strncmp(dev, '12F1', 4))) and (sizeW > $8008) then
    begin
     if cw1 <= $3FFF then
     begin
      memCODE_W[$8007] := cw1;
      sprintf(str, strings[S_ForceConfigWx], 1, $8007, cw1);
      PrintMessage(str);
     end;
     if cw2 <= $3FFF then
     begin
      memCODE_W[$8008] := cw2;
      sprintf(str, strings[S_ForceConfigWx], 2, $8008, cw2);
      PrintMessage(str);
     end;
    end
    else
    begin
     if (cw1 <= $3FFF) and (sizeW > $2007) then
     begin
      memCODE_W[$2007] := cw1;
      sprintf(str, strings[S_ForceConfigWx], 1, $2007, cw1);
      PrintMessage(str);
     end;
     if (cw2 <= $3FFF) and (sizeW > $2008) then
     begin
      memCODE_W[$2008] := cw2;
      printf('2' + NL + '');
      sprintf(str, strings[S_ForceConfigWx], 2, $2008, cw2);
      PrintMessage(str);
     end;
    end;
   end
   else
    if devType = PIC12 then
    begin
     if (cw1 <= $FFF) and (sizeW > $FFF) then
     begin
      memCODE_W[$FFF] := cw1;
      sprintf(str, strings[S_ForceConfigWx], 1, $FFF, cw1);
      PrintMessage(str);
     end;
    end
    else
     if devType = PIC18 then
     begin
      if cw1 <= $FFFF then
      begin
       memCONFIG[0] := cw1 and $FF;
       memCONFIG[1] := (cw1 shr 8) and $FF;
      end;
      if cw2 <= $FFFF then
      begin
       memCONFIG[2] := cw2 and $FF;
       memCONFIG[3] := (cw2 shr 8) and $FF;
      end;
      if cw3 <= $FFFF then
      begin
       memCONFIG[4] := cw3 and $FF;
       memCONFIG[5] := (cw3 shr 8) and $FF;
      end;
      if cw4 <= $FFFF then
      begin
       memCONFIG[6] := cw4 and $FF;
       memCONFIG[7] := (cw4 shr 8) and $FF;
      end;
      if cw5 <= $FFFF then
      begin
       memCONFIG[8] := cw5 and $FF;
       memCONFIG[9] := (cw5 shr 8) and $FF;
      end;
      if cw6 <= $FFFF then
      begin
       memCONFIG[10] := cw6 and $FF;
       memCONFIG[11] := (cw6 shr 8) and $FF;
      end;
      if cw7 <= $FFFF then
      begin
       memCONFIG[12] := cw7 and $FF;
       memCONFIG[13] := (cw7 shr 8) and $FF;
      end;
      PrintMessage(strings[S_ForceConfigW]);
      for i := 0 to (7) - 1 do
      begin
       sprintf(str, strings[S_ConfigWordH], i + 1, memCONFIG[i * 2 + 1]);
       PrintMessage(str);
       sprintf(str, strings[S_ConfigWordL], i + 1, memCONFIG[i * 2]);
       PrintMessage(str);
      end;
     end;
  end;
  free(str);
end;

procedure GetSelectedDevice;
var
  tmpModel: PGtkTreeModel;
  tmpIter: TGtkTreeIter;
  devName: PChar;
begin
  if not (0(devSel)) then
  begin
   Exit;
  end;
  if gtk_tree_selection_get_selected(devSel, @tmpModel, @tmpIter) then
  begin
   gtk_tree_model_get(tmpModel, @tmpIter, DEVICE_NAME_COLUMN, @devName, -1);
   strcpy(dev, devName);
   gtk_widget_set_sensitive(readBtn, TRUE_);
   gtk_widget_set_sensitive(writeBtn, TRUE_);
   g_free(devName);
  end
  else
  begin
   dev[0] := '\0';
   gtk_widget_set_sensitive(readBtn, FALSE_);
   gtk_widget_set_sensitive(writeBtn, FALSE_);
  end;
end;

function Fopen(widget: PControl; window: PControl): Pointer;
var
  dialog: PGtkFileChooser;
  filename: PChar;
  dialog2: PGtkFileChooser;
  filename2: PChar;
begin
  GetSelectedDevice();
  if progress then
   Exit;
  progress := 1;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fopen], window, 0, strings[I_CANCEL], -6, strings[I_OPEN], -2, nil);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  if gtk_dialog_run(dialog) = -2 then
  begin
   filename := gtk_file_chooser_get_filename(dialog);
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   Load(devType, filename);
   g_free(filename);
   if devType = AVR then
   begin
    dialog2 := gtk_file_chooser_dialog_new(strings[S_openEEfile], window, 0, strings[I_CANCEL], -6, strings[I_OPEN], -2, nil);
    if not (cur_pathEE) then
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog);
    if cur_pathEE then
     gtk_file_chooser_set_current_folder(dialog2, cur_pathEE);
    if gtk_dialog_run(dialog2) = -2 then
    begin
     filename2 := gtk_file_chooser_get_filename(dialog2);
     if cur_pathEE then
      free(cur_pathEE);
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog2);
     LoadEE(devType, filename2);
     g_free(filename2);
    end;
    gtk_widget_destroy(dialog2);
   end;
  end;
  gtk_widget_destroy(dialog);
  progress := 0;
end;

function Fsave(widget: PControl; window: PControl): Pointer;
var
  dialog: PGtkFileChooser;
  filename: PChar;
  dialog2: PGtkFileChooser;
  filename2: PChar;
begin
  if progress then
   Exit;
  progress := 1;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fsave], window, 1, strings[I_CANCEL], -6, strings[I_SAVE], -2, nil);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  gtk_file_chooser_set_do_overwrite_confirmation(dialog, TRUE_);
  if gtk_dialog_run(dialog) = -2 then
  begin
   filename := gtk_file_chooser_get_filename(dialog);
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   Save(devType, filename);
   sprintf(str, strings[S_FileSaved], filename);
   PrintMessage(str);
   g_free(filename);
   if devType = AVR then
   begin
    dialog2 := gtk_file_chooser_dialog_new(strings[S_saveEEfile], window, 1, strings[I_CANCEL], -6, strings[I_SAVE], -2, nil);
    if not (cur_pathEE) then
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog);
    if cur_pathEE then
     gtk_file_chooser_set_current_folder(dialog2, cur_pathEE);
    gtk_file_chooser_set_do_overwrite_confirmation(dialog2, TRUE_);
    if gtk_dialog_run(dialog2) = -2 then
    begin
     filename2 := gtk_file_chooser_get_filename(dialog2);
     if cur_pathEE then
      free(cur_pathEE);
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog2);
     SaveEE(devType, filename2);
     sprintf(str, strings[S_FileSaved], filename2);
     PrintMessage(str);
     g_free(filename2);
    end;
    gtk_widget_destroy(dialog2);
   end;
  end;
  gtk_widget_destroy(dialog);
  progress := 0;
end;

procedure selectDataTab;
var
  // (no local variables detected)
begin
  gtk_notebook_set_current_page(notebook, 0);
end;

function DevWrite(widget: PControl; window: PControl): Pointer;
var
  i: Integer;
  S1: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  selectDataTab();
  gtk_statusbar_push(status_bar, statusID, '');
  RWstop := 0;
  getOptions();
  if not (waitingS1) and waitS1 then
  begin
   waitingS1 := 1;
   S1 := 0;
   PrintMessage(strings[I_PRESSS1]);
   i := 0;
   while not (S1) and waitS1 and waitingS1 do
   begin
    S1 := CheckS1();
    msDelay(50);
    PrintMessage('.');
    if i mod 64 = 63 then
     PrintMessage(strings[S_NL]);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    msDelay(50);
    Inc(i);
   end;
   PrintMessage(strings[S_NL]);
   if not (progress) and S1 then
   begin
    gtk_widget_set_sensitive(stopBtn, TRUE_);
    progress := 1;
    Write_(dev, ee);
    progress := 0;
    gtk_widget_set_sensitive(stopBtn, FALSE_);
   end;
   waitingS1 := 0;
  end
  else
   if waitingS1 then
    waitingS1 := 0
   else
    if not (progress) then
    begin
     gtk_widget_set_sensitive(stopBtn, TRUE_);
     progress := 1;
     Write_(dev, ee);
     progress := 0;
     gtk_widget_set_sensitive(stopBtn, FALSE_);
    end;
end;

function DevRead(widget: PControl; window: PControl): Pointer;
var
  i: Integer;
  S1: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  selectDataTab();
  gtk_statusbar_push(status_bar, statusID, '');
  getOptions();
  RWstop := 0;
  if not (waitingS1) and waitS1 then
  begin
   waitingS1 := 1;
   S1 := 0;
   PrintMessage(strings[I_PRESSS1]);
   i := 0;
   while not (S1) and waitS1 and waitingS1 do
   begin
    S1 := CheckS1();
    msDelay(50);
    PrintMessage('.');
    if i mod 64 = 63 then
     PrintMessage(strings[S_NL]);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    msDelay(50);
    Inc(i);
   end;
   PrintMessage(strings[S_NL]);
   if not (progress) and S1 then
   begin
    gtk_widget_set_sensitive(stopBtn, TRUE_);
    progress := 1;
    Read_(dev, ee, readRes);
    progress := 0;
    gtk_widget_set_sensitive(stopBtn, FALSE_);
   end;
   waitingS1 := 0;
  end
  else
   if waitingS1 then
    waitingS1 := 0
   else
    if not (progress) then
    begin
     gtk_widget_set_sensitive(stopBtn, TRUE_);
     progress := 1;
     Read_(dev, ee, readRes);
     progress := 0;
     gtk_widget_set_sensitive(stopBtn, FALSE_);
    end;
end;

function WriteATfuseLowLF(widget: PControl; window: PControl): Pointer;
var
  // (no local variables detected)
begin
  if DeviceDetected <> 1 then
   Exit;
  if progress then
   Exit;
  getOptions();
  if gtk_toggle_button_get_active(AVR_FuseLowWrite) then
  begin
   progress := 1;
   if AVRfuse < $100 then
    WriteATfuseSlow(AVRfuse);
   progress := 0;
  end;
end;

function onDevSel_Changed(widget: PControl; window: PControl): Pointer;
var
  info: TDevInfo;
begin
  GetSelectedDevice();
  if strlen(dev) = 0 then
   Exit;
  info := GetDevInfo(dev);
  sprintf(str, '<b>%s: %s</b>', strings[I_Dev], dev);
  gtk_label_set_markup(devFrame, str);
  devType := info.family;
  gtk_label_set_text(devinfo, info.features);
  if (devType = PIC12) or (devType = PIC16) or (devType = PIC18) or (devType = PIC24) then
  begin
   gtk_widget_show_all(devFramePIC);
   gtk_widget_hide(devFrameAVR);
   gtk_widget_show_all(EEPROM_RW);
  end
  else
   if devType = AVR then
   begin
    gtk_widget_hide(devFramePIC);
    gtk_widget_show_all(devFrameAVR);
    gtk_widget_show_all(EEPROM_RW);
   end
   else
   begin
    gtk_widget_hide(devFramePIC);
    gtk_widget_hide(devFrameAVR);
    gtk_widget_hide(EEPROM_RW);
   end;
  if devType = PIC16 then
   gtk_widget_show_all(devFrameICD)
  else
   gtk_widget_hide(devFrameICD);
  if (devType = PIC12) or (devType = PIC16) then
   gtk_widget_show_all(devFrameOsc)
  else
   gtk_widget_hide(devFrameOsc);
  if (devType = PIC12) or (devType = PIC16) or (devType = PIC18) then
   gtk_widget_show_all(Write_ID_BKCal)
  else
   gtk_widget_hide(Write_ID_BKCal);
  if devType = PIC16 then
   gtk_widget_show_all(WriteCalib12)
  else
   gtk_widget_hide(WriteCalib12);
  if (devType = PIC12) or (devType = PIC16) or (devType = PIC18) then
  begin
   gtk_widget_show_all(devFrameConfigW);
   gtk_widget_hide(devPIC_CW2);
   gtk_widget_hide(devPIC_CW3);
   gtk_widget_hide(devPIC_CW4);
   gtk_widget_hide(devPIC_CW5);
   gtk_widget_hide(devPIC_CW6);
   gtk_widget_hide(devPIC_CW7);
   gtk_widget_hide(devPIC_CW8);
   if devType = PIC16 then
   begin
    gtk_widget_show_all(devPIC_CW2);
   end
   else
    if devType = PIC18 then
    begin
     gtk_widget_show_all(devPIC_CW2);
     gtk_widget_show_all(devPIC_CW3);
     gtk_widget_show_all(devPIC_CW4);
     gtk_widget_show_all(devPIC_CW5);
     gtk_widget_show_all(devPIC_CW6);
     gtk_widget_show_all(devPIC_CW7);
     gtk_widget_show_all(devPIC_CW8);
     gtk_widget_show_all(devPIC_CW8);
    end;
  end
  else
  begin
   gtk_widget_hide(devFrameConfigW);
   gtk_toggle_button_set_active(ConfigForce, FALSE_);
  end;
  gtk_statusbar_push(status_bar, statusID, dev);
end;

function selectDev_ForeachFunc(model: PGtkTreeModel; path: PGtkTreePath; iter: PGtkTreeIter; devNameToSelect: PChar): Boolean;
var
  thisEntryDevName: PChar;
  matched: Integer;
begin
  gtk_tree_model_get(model, iter, DEVICE_NAME_COLUMN, @thisEntryDevName, -1);
  matched := strcmp(thisEntryDevName, devNameToSelect) = 0;
  if matched then
   gtk_tree_selection_select_iter(devSel, iter);
  g_free(thisEntryDevName);
  Exit(matched);
end;

function sortIterCompareFunc(model: PGtkTreeModel; a: PGtkTreeIter; b: PGtkTreeIter; userdata: Pointer): Integer;
var
  sortcol: Tsort_type_t;
  ret: Integer;
  sortDataType: Tsort_data_type_t;
  dataCol: Integer;
  nameA: PChar;
  nameB: PChar;
begin
  sortcol := GPOINTER_TO_INT(userdata);
  ret := 0;
  case sortcol of
   SORT_STRING_NAME:
   begin
    sortDataType := SDT_STRING;
    dataCol := DEVICE_NAME_COLUMN;
   end;
   SORT_STRING_GROUP:
   begin
    sortDataType := SDT_STRING;
    dataCol := DEVICE_GROUP_COLUMN;
   end;
   else
   begin
    Exit(0);
   end;
  end;
  case sortDataType of
   SDT_STRING:
   begin
    gtk_tree_model_get(model, a, dataCol, @nameA, -1);
    gtk_tree_model_get(model, b, dataCol, @nameB, -1);
    if (nameA = nil) or (nameB = nil) then
    begin
     if (nameA = nil) and (nameB = nil) then
      Break;
     ret := IfThen(nameA = nil, -1, 1);
    end
    else
    begin
     ret := g_utf8_collate(nameA, nameB);
    end;
    g_free(nameA);
    g_free(nameB);
    Break;
   end;
   else
   begin
    g_return_val_if_reached(0);
   end;
  end;
  Exit(ret);
end;

function strupr(s: PChar): PChar;
var
  p: PChar;
begin
  p := s;
  p^ := toupper(p^);
  while p^ do
  begin
   Inc(p);
  end;
  Exit(s);
end;

function AddDevices(groupFilter: Tgroup_t; textFilter: PChar): Pointer;
var
  i: Integer;
  j: Integer;
  devices: PChar;
  tok: PChar;
  textFilterU: array[0..32-1] of Char;
  info: TDevInfo;
begin
  if 0(devSel) then
   g_signal_handlers_disconnect_by_func(G_OBJECT(devSel), G___GTK2LAZ_CALLCONV_stdcall(onDevSel_Changed), nil);
  if not (0(devStore)) then
  begin
   devStore := gtk_list_store_new(DEVICE_N_COLUMNS, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING);
   gtk_tree_view_set_model(devTree, devStore);
   gtk_tree_sortable_set_sort_func(devStore, SORT_STRING_NAME, sortIterCompareFunc, GINT_TO_POINTER(SORT_STRING_NAME), nil);
   gtk_tree_sortable_set_sort_func(devStore, SORT_STRING_GROUP, sortIterCompareFunc, GINT_TO_POINTER(SORT_STRING_GROUP), nil);
   gtk_tree_view_column_set_sort_column_id(gtk_tree_view_get_column(devTree, 0), SORT_STRING_NAME);
   gtk_tree_view_column_set_sort_column_id(gtk_tree_view_get_column(devTree, 1), SORT_STRING_GROUP);
   g_object_unref(G_OBJECT(devStore));
  end
  else
   gtk_list_store_clear(devStore);
  j := 0;
  devices := 0;
  strupr(strncpy(textFilterU, textFilter, 32));
  for i := 0 to (NDEVLIST) - 1 do
  begin
   if devices then
    free(devices);
   devices := malloc(strlen(DEVLIST[i].device) + 1);
   strcpy(devices, DEVLIST[i].device);
   populateDevInfo(@info, @(DEVLIST[i]));
   tok := strtok(devices, ', ' + #9 + '');
   while tok do
   begin
    info.group := nameToGroup(tok);
    if (info.group <> -1) and (not (textFilter) or (strlen(textFilter) = 0) or strstr(strupr(tok), textFilterU)) and ((groupFilter = -1) or (info.group = groupFilter)) then
    begin
     gtk_list_store_insert_with_values(devStore, nil, -1, DEVICE_ID_COLUMN, j, DEVICE_NAME_COLUMN, tok, DEVICE_GROUP_COLUMN, groupNames[info.group], -1);
     Inc(j);
    end;
    tok := strtok(nil, ', ' + #9 + '');
   end;
  end;
  free(devices);
  if 0(devSel) then
  begin
   gtk_tree_selection_unselect_all(devSel);
  end
  else
  begin
   devSel := gtk_tree_view_get_selection(devTree);
   gtk_tree_selection_set_mode(devSel, 0);
  end;
  g_signal_connect(G_OBJECT(devSel), 'changed', G___GTK2LAZ_CALLCONV_stdcall(onDevSel_Changed), nil);
  gtk_tree_model_foreach(devStore, selectDev_ForeachFunc, dev);
end;

function FilterDevType(widget: PControl; window: PControl): Pointer;
var
  selGroupName: PChar;
  filtText: PChar;
  selGroup: Tgroup_t;
begin
  selGroupName := gtk_combo_box_text_get_active_text(0(devTypeCombo));
  filtText := gtk_entry_get_text(devFiltEntry);
  selGroup := -1;
  for i := 0 to (NUM_GROUPS) - 1 do
  begin
   if strcmp(selGroupName, groupNames[i]) = 0 then
   begin
    selGroup := i;
    i := NUM_GROUPS;
   end;
  end;
  if (selGroup = -1) and strcmp(GROUP_ALL, selGroupName) then
  begin
   sprintf(str, 'ERR: group name '%s' invalid', selGroupName);
   PrintMessage(str);
   Exit;
  end;
  AddDevices(selGroup, filtText);
  g_free(selGroupName);
  onDevSel_Changed(nil, nil);
end;

function IOchanged(widget: PControl; window: PControl): Pointer;
var
  i: Integer;
  j: Integer;
  trisa: Integer;
  trisb: Integer;
  trisc: Integer;
  latac: Integer;
  latb: Integer;
  port: Integer;
  z: Integer;
  vpp: Double;
begin
  if progress then
   Exit;
  if DeviceDetected <> 1 then
   Exit;
  if not (gtk_toggle_button_get_active(b_io_active)) then
   Exit;
  j := 0;
  trisa := 1;
  trisb := 0;
  trisc := $30;
  latac := 0;
  latb := 0;
  port := 0;
  str[0] := 0;
  for i := 0 to (SizeOf(ioButtons) div SizeOf(ioButtons[0])) - 1 do
  begin
   if gtk_toggle_button_get_active(ioButtons[i].r_0) then
   begin
   end
   else
    if gtk_toggle_button_get_active(ioButtons[i].r_1) then
    begin
     if i < 8 then
      latb := latb or 1 shl i
     else
      if i = 8 then
       latac := latac or $80
      else
       if i = 9 then
        latac := latac or $40
       else
        if i = 10 then
         latac := latac or $20
        else
         if i = 11 then
          latac := latac or $10
         else
          if i = 12 then
           latac := latac or $08;
    end
    else
     if gtk_toggle_button_get_active(ioButtons[i].r_I) then
     begin
      if i < 8 then
       trisb := trisb or 1 shl i
      else
       if i = 8 then
        trisc := trisc or $80
       else
        if i = 9 then
         trisc := trisc or $40
        else
         if i = 10 then
          trisa := trisa or $20
         else
          if i = 11 then
           trisa := trisa or $10
          else
           if i = 12 then
            trisa := trisa or $8;
     end;
  end;
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $80;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $81;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $82;
  Inc(j);
  bufferU[j] := $F1;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $92;
  Inc(j);
  bufferU[j] := trisa;
  Inc(j);
  bufferU[j] := $F1;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $93;
  Inc(j);
  bufferU[j] := trisb;
  Inc(j);
  bufferU[j] := $F1;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $94;
  Inc(j);
  bufferU[j] := trisc;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := latb;
  Inc(j);
  bufferU[j] := latac;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  z := 0;
  while (z < 64 - 3) and (bufferI[z] <> $F0) do
  begin
   Inc(z);
  end;
  port := bufferI[z + 3];
  gtk_label_set_text(ioButtons[10].e_I, IfThen(port and $20, '1', '0'));
  gtk_label_set_text(ioButtons[11].e_I, IfThen(port and $10, '1', '0'));
  gtk_label_set_text(ioButtons[12].e_I, IfThen(port and $8, '1', '0'));
  z := 4;
  while (z < 64 - 3) and (bufferI[z] <> $F0) do
  begin
   Inc(z);
  end;
  port := bufferI[z + 3];
  for i := 0 to (8) - 1 do
  begin
   gtk_label_set_text(ioButtons[i].e_I, IfThen(port and (1 shl i), '1', '0'));
  end;
  z := 4;
  while (z < 64 - 3) and (bufferI[z] <> $F0) do
  begin
   Inc(z);
  end;
  port := bufferI[z + 3];
  gtk_label_set_text(ioButtons[8].e_I, IfThen(port and $80, '1', '0'));
  gtk_label_set_text(ioButtons[9].e_I, IfThen(port and $40, '1', '0'));
  z := 4;
  while (z < 64 - 2) and (bufferI[z] <> $0C) do
  begin
   Inc(z);
  end;
  vpp := ((((bufferI[z + 1] shl 8) + bufferI[z + 2]) div 1024.0) * 5 * 34) div 12;
  sprintf(str, 'VPP=%.2fV', vpp);
  gtk_statusbar_push(status_bar, statusID, str);
  Exit;
end;

function IOactive(widget: PControl; window: PControl): Pointer;
var
  // (no local variables detected)
begin
  if gtk_toggle_button_get_active(b_io_active) and not (icdTimer) then
  begin
   IOTimer := g_timeout_add(100, IOchanged, nil);
  end
  else
   if IOTimer then
   begin
    g_source_remove(IOTimer);
   end;
end;

function VPPVDDactive(widget: PControl; window: PControl): Pointer;
var
  j: Integer;
  vdd_vpp: Integer;
  str: array[0..16-1] of Char;
begin
  if DeviceDetected <> 1 then
   Exit;
  j := 0;
  vdd_vpp := 0;
  str := '';
  if gtk_toggle_button_get_active(VPP_ON) then
  begin
   vdd_vpp := vdd_vpp + 4;
   strcat(str, 'VPP ');
  end;
  if gtk_toggle_button_get_active(VDD_ON) then
  begin
   vdd_vpp := vdd_vpp + 1;
   strcat(str, 'VDD ');
  end;
  gtk_statusbar_push(status_bar, statusID, str);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := vdd_vpp;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
end;

function DCDCactive(widget: PControl; window: PControl): Pointer;
var
  j: Integer;
  vreg: Integer;
  str: array[0..16-1] of Char;
  voltage: Double;
begin
  if DeviceDetected <> 1 then
   Exit;
  if gtk_toggle_button_get_active(DCDC_ON) then
  begin
   j := 0;
   vreg := 0;
   voltage := gtk_range_get_value(0(DCDC_voltage));
   vreg := voltage * 10.0;
   sprintf(str, 'DCDC %.1fV', voltage);
   gtk_statusbar_push(status_bar, statusID, str);
   bufferU[j] := $05;
   Inc(j);
   bufferU[j] := $0D;
   Inc(j);
   bufferU[j] := vreg;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end
  else
  begin
   j := 0;
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   while j < 64 do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end;
end;

function HexConvert(widget: PControl; window: PControl): Pointer;
var
  hex: array[0..256-1] of Char;
  str: array[0..256-1] of Char;
  s2: array[0..32-1] of Char;
  i: Integer;
  address: Integer;
  length: Integer;
  sum: Integer;
begin
  sum := 0;
  strncpy(hex, gtk_entry_get_text(Hex_entry), SizeOf(hex));
  if strlen(hex) > 0 then
  begin
   if (hex[0] = #58) and (strlen(hex) > 8) then
   begin
    length := htoi(hex + 1, 2);
    address := htoi(hex + 3, 4);
    if strlen(hex) < 11 + length * 2 then
     gtk_entry_set_text(Hex_data, '__line too short')
    else
    begin
     i := 1;
     while i <= length * 2 + 9 do
     begin
      sum := sum + htoi(hex + i, 2);
      Inc(i, 2);
     end;
     if sum and $ff <> 0 then
     begin
      sprintf(str, '__checksum error, expected 0x%02X', (-sum + htoi(hex + 9 + length * 2, 2)) and $FF);
      gtk_entry_set_text(Hex_data, str);
     end
     else
     begin
      case htoi(hex + 7, 2) of
       0:
       begin
        sprintf(str, 'address: 0x%04X ', address);
        if i and length then
         strcat(str, 'data: 0x');
        for i := 0 to (length) - 1 do
        begin
         sprintf(s2, '%02X', htoi(hex + 9 + i * 2, 2));
         strcat(str, s2);
        end;
        gtk_entry_set_text(Hex_data, str);
       end;
       4:
       begin
        if strlen(hex) > 14 then
        begin
         sprintf(str, 'extended linear address = %04X', htoi(hex + 9, 4));
         gtk_entry_set_text(Hex_data, str);
        end;
       end;
       else
       begin
        gtk_entry_set_text(Hex_data, '__unknown record type');
       end;
      end;
     end;
    end;
   end
   else
    gtk_entry_set_text(Hex_data, '__invalid line');
  end
  else
   gtk_entry_set_text(Hex_entry, '');
end;

function DataToHexConvert(widget: PControl; window: PControl): Pointer;
var
  hex: array[0..256-1] of Char;
  str: array[0..256-1] of Char;
  s2: array[0..32-1] of Char;
  i: Integer;
  address: Integer;
  length: Integer;
  sum: Integer;
  x: Integer;
begin
  sum := 0;
  i := sscanf(gtk_entry_get_text(Address_entry), '%x', @address);
  if i <> 1 then
   address := 0;
  strncpy(hex, gtk_entry_get_text(Data_entry), SizeOf(hex));
  length := strlen(hex);
  length := length and $FF;
  if length > 0 then
  begin
   sprintf(str, ':--%04X00', address and $FFFF);
   i := 0;
   while i + 1 < length do
   begin
    x := htoi(hex + i, 2);
    sum := sum + x;
    sprintf(s2, '%02X', x);
    strcat(str, s2);
    Inc(i, 2);
   end;
   sprintf(s2, '%02X', i div 2);
   str[1] := s2[0];
   str[2] := s2[1];
   x := sum;
   sum := sum + i div 2 + address and $ff + (address shr 8) and $ff;
   sprintf(s2, '%02X', -sum and $FF);
   strcat(str, s2);
   gtk_entry_set_text(Hex_data2, str);
  end;
end;

function HexSave(widget: PControl; window: PControl): Pointer;
var
  dialog: PGtkFileChooser;
  filename: PChar;
  f: ^TextFile;
begin
  if strlen(gtk_entry_get_text(Hex_data2)) < 11 then
   Exit;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fsave], window, 1, strings[I_CANCEL], -6, strings[I_SAVE], -2, nil);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  gtk_file_chooser_set_do_overwrite_confirmation(dialog, TRUE_);
  if gtk_dialog_run(dialog) = -2 then
  begin
   filename := gtk_file_chooser_get_filename(dialog);
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   f := fopen(filename, 'w');
   if f then
   begin
    fprintf(f, gtk_entry_get_text(Hex_data2));
    fclose(f);
   end;
   g_free(filename);
  end;
  gtk_widget_destroy(dialog);
end;

function Stop(widget: PControl; window: PControl): Pointer;
var
  // (no local variables detected)
begin
  if DeviceDetected <> 1 then
   Exit;
  if (progress = 1) and (RWstop = 0) then
  begin
   RWstop := 1;
   PrintMessage(strings[I_STOP]);
  end;
end;

procedure Xclose;
var
  // (no local variables detected)
begin
  gtk_main_quit();
end;

function MsgBox(msg: PChar): Pointer;
var
  dialog: PControl;
begin
  dialog := gtk_message_dialog_new(window, 0, 0, 0, msg);
  gtk_window_set_title(dialog, ' ');
  gtk_dialog_run(dialog);
  gtk_widget_destroy(dialog);
end;

function Connect(widget: PControl; window: PControl): Pointer;
var
  // (no local variables detected)
begin
  vid := htoi(gtk_entry_get_text(VID_entry), 4);
  pid := htoi(gtk_entry_get_text(PID_entry), 4);
  DeviceDetected := FindDevice(vid, pid);
  if not (DeviceDetected) then
  begin
   DeviceDetected := FindDevice(new_vid, new_pid);
   if DeviceDetected then
   begin
    vid := new_vid;
    pid := new_pid;
   end;
  end;
  if not (DeviceDetected) then
   DeviceDetected := FindDevice(old_vid, old_pid);
  hvreg := 0;
  ProgID();
end;

procedure I2cspiR;
var
  nbyte: Integer;
  mode: Integer;
  tok: PChar;
  tokbuf: array[0..512-1] of Char;
  tmpbuf: array[0..128-1] of TBYTE;
  i: Integer;
  x: Integer;
begin
  gtk_statusbar_push(status_bar, statusID, '');
  saveLog := gtk_toggle_button_get_active(b_log);
  nbyte := gtk_spin_button_get_value_as_int(I2CNbyte);
  if nbyte < 0 then
   nbyte := 0;
  if nbyte > 60 then
   nbyte := 60;
  mode := 0;
  if gtk_toggle_button_get_active(I2C16bit) then
   mode := 1;
  if gtk_toggle_button_get_active(SPI00) then
   mode := 2;
  if gtk_toggle_button_get_active(SPI01) then
   mode := 3;
  if gtk_toggle_button_get_active(SPI10) then
   mode := 4;
  if gtk_toggle_button_get_active(SPI11) then
   mode := 5;
  i := 0;
  strncpy(tokbuf, gtk_entry_get_text(I2CDataSend), SizeOf(tokbuf));
  tok := strtok(tokbuf, ' ');
  while tok and (i < 128) do
  begin
   if sscanf(tok, '%x', @x) then
   begin
    tmpbuf[i] := x;
    Inc(i);
   end;
   tok := strtok(nil, ' ');
  end;
  while i < 128 do
  begin
   tmpbuf[i] := 0;
   Inc(i);
  end;
  I2CReceive(mode, gtk_combo_box_get_active(I2CSpeed), nbyte, tmpbuf);
end;

procedure I2cspiS;
var
  nbyte: Integer;
  mode: Integer;
  tok: PChar;
  tokbuf: array[0..512-1] of Char;
  tmpbuf: array[0..128-1] of TBYTE;
  i: Integer;
  x: Integer;
begin
  gtk_statusbar_push(status_bar, statusID, '');
  saveLog := gtk_toggle_button_get_active(b_log);
  nbyte := gtk_spin_button_get_value_as_int(I2CNbyte);
  if nbyte < 0 then
   nbyte := 0;
  if nbyte > 57 then
   nbyte := 57;
  mode := 0;
  if gtk_toggle_button_get_active(I2C16bit) then
   mode := 1;
  if gtk_toggle_button_get_active(SPI00) then
   mode := 2;
  if gtk_toggle_button_get_active(SPI01) then
   mode := 3;
  if gtk_toggle_button_get_active(SPI10) then
   mode := 4;
  if gtk_toggle_button_get_active(SPI11) then
   mode := 5;
  i := 0;
  strncpy(tokbuf, gtk_entry_get_text(I2CDataSend), SizeOf(tokbuf));
  tok := strtok(tokbuf, ' ');
  while tok and (i < 128) do
  begin
   if sscanf(tok, '%x', @x) then
   begin
    tmpbuf[i] := x;
    Inc(i);
   end;
   tok := strtok(nil, ' ');
  end;
  while i < 128 do
  begin
   tmpbuf[i] := 0;
   Inc(i);
  end;
  I2CSend(mode, gtk_combo_box_get_active(I2CSpeed), nbyte, tmpbuf);
end;

procedure CommandIO;
var
  tok: PChar;
  tokbuf: array[0..512-1] of Char;
  str: array[0..16-1] of Char;
  i: Integer;
  x: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  gtk_statusbar_push(status_bar, statusID, '');
  saveLog := gtk_toggle_button_get_active(b_log);
  i := 0;
  strncpy(tokbuf, gtk_entry_get_text(commandSend), SizeOf(tokbuf));
  tok := strtok(tokbuf, ' ');
  while tok and (i < 64) do
  begin
   if sscanf(tok, '%x', @x) then
   begin
    bufferU[i] := x;
    Inc(i);
   end;
   tok := strtok(nil, ' ');
  end;
  while i < 64 do
  begin
   bufferU[i] := $0;
   Inc(i);
  end;
  PacketIO(150);
  sprintf(tokbuf, '>[');
  for i := 0 to (64) - 1 do
  begin
   sprintf(str, ' %02X', bufferU[i]);
   strcat(tokbuf, str);
   if (i mod 32 = 31) and (i <> 64 - 1) then
    strcat(tokbuf, '' + NL + '    ');
  end;
  strcat(tokbuf, ' ]' + NL + '<[');
  for i := 0 to (64) - 1 do
  begin
   sprintf(str, ' %02X', bufferI[i]);
   strcat(tokbuf, str);
   if (i mod 32 = 31) and (i <> 64 - 1) then
    strcat(tokbuf, '' + NL + '     ');
  end;
  strcat(tokbuf, ' ]');
  PrintMessageCMD(tokbuf);
end;

procedure DisplayEE;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  v: array[0..256-1] of Char;
  aux: PChar;
  g: PChar;
  valid: Integer;
  empty: Integer;
  lines: Integer;
  i: Integer;
  j: Integer;
  max: Integer;
begin
  valid := 0;
  empty := 1;
  lines := 0;
  s[0] := 0;
  v[0] := 0;
  aux := malloc((sizeEE div 16 + 1) * (16 + 16 * 5));
  aux[0] := 0;
  PrintMessage(strings[S_EEMem]);
  max := IfThen(sizeEE > 7000, 7000, sizeEE);
  i := 0;
  while i < max do
  begin
   valid := 0;
   j := i;
   while (j < i + 16) and (j < sizeEE) do
   begin
    sprintf(t, '%02X ', memEE[j]);
    strcat(s, t);
    sprintf(t, '%c', IfThen(isprint(memEE[j]) and (memEE[j] < $FF), memEE[j], #46));
    g := g_locale_to_utf8(t, -1, nil, nil, nil);
    if g then
     strcat(v, g);
    g_free(g);
    if memEE[j] < $ff then
     valid := 1;
    Inc(j);
   end;
   if valid then
   begin
    sprintf(t, '%04X: %s %s' + #13 + '' + NL + '', i, s, v);
    strcat(aux, t);
    empty := 0;
    Inc(lines);
    if lines > 500 then
    begin
     strcat(aux, '(...)' + #13 + '' + NL + '');
     i := max - 16 * 2;
     lines := 490;
    end;
   end;
   s[0] := 0;
   v[0] := 0;
   Inc(i, 16);
  end;
  if empty then
   PrintMessage(strings[S_Empty])
  else
  begin
   PrintMessage(aux);
   if sizeEE > max then
    PrintMessage('(...)' + #13 + '' + NL + '');
  end;
  free(aux);
end;

function StartHVReg(V: Double): Integer;
var
  j: Integer;
  z: Integer;
  vreg: Integer;
  t0: TDWORD;
  t: TDWORD;
  v: Integer;
begin
  j := 0;
  vreg := V * 10.0;
  if saveLog and logfile then
   fprintf(logfile, 'StartHVReg(%.2f)' + NL + '', V);
  if V = -1 then
  begin
   bufferU[j] := $06;
   Inc(j);
   bufferU[j] := $04;
   Inc(j);
   PacketIO(5);
   msDelay(40);
   Exit(-1);
  end;
  t0 := GetTickCount(); t := GetTickCount();
  bufferU[j] := $05;
  Inc(j);
  bufferU[j] := $0D;
  Inc(j);
  bufferU[j] := vreg;
  Inc(j);
  bufferU[j] := $07;
  Inc(j);
  bufferU[j] := 1;
  Inc(j);
  bufferU[j] := 2000 shr 8;
  Inc(j);
  bufferU[j] := 2000 and $ff;
  Inc(j);
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  msDelay(20);
  z := 0;
  while (z < 64 - 2) and (bufferI[z] <> $0C) do
  begin
   Inc(z);
  end;
  v := (bufferI[z + 1] shl 8) + bufferI[z + 2];
  if v = 0 then
  begin
   PrintMessage(strings[S_lowUsbV]);
   Exit(0);
  end;
  j := 0;
  bufferU[j] := $0A;
  Inc(j);
  bufferU[j] := $0C;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  while ((v < (vreg div 10.0 - 1) * (((12.0 div 34) * 1024) div 5)) or (v > (vreg div 10.0 + 1) * (((12.0 div 34) * 1024) div 5))) and (t < t0 + 1500) do
  begin
   PacketIO(5);
   msDelay(20);
   z := 0;
   while (z < 64 - 2) and (bufferI[z] <> $0C) do
   begin
    Inc(z);
   end;
   v := (bufferI[z + 1] shl 8) + bufferI[z + 2];
   if HwID = 3 then
    v := v shr 2;
   t := GetTickCount();
  end;
  if v > (vreg div 10.0 + 1) * (((12.0 div 34) * 1024) div 5) then
  begin
   PrintMessage(strings[S_HiVPP]);
   Exit(0);
  end
  else
   if v < (vreg div 10.0 - 1) * (((12.0 div 34) * 1024) div 5) then
   begin
    PrintMessage(strings[S_LowVPP]);
    Exit(0);
   end
   else
    if v = 0 then
    begin
     PrintMessage(strings[S_lowUsbV]);
     Exit(0);
    end
    else
    begin
     sprintf(str, strings[S_reg], t - t0, v div ((12.0 div 34) * 1024) div 5);
     PrintMessage(str);
     if saveLog and logfile then
      fprintf(logfile, strings[S_reg], t - t0, v div ((12.0 div 34) * 1024) div 5);
     Exit(vreg);
    end;
end;

procedure ProgID;
var
  j: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  j := 0;
  bufferU[j] := $01;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  while (j < 64 - 7) and (bufferI[j] <> $01) do
  begin
   Inc(j);
  end;
  sprintf(str, strings[S_progver], bufferI[j + 1], bufferI[j + 2], bufferI[j + 3]);
  PrintMessage(str);
  FWVersion := (bufferI[j + 1] shl 16) + (bufferI[j + 2] shl 8) + bufferI[j + 3];
  sprintf(str, strings[S_progid], bufferI[j + 4], bufferI[j + 5], bufferI[j + 6]);
  PrintMessage(str);
  HwID := bufferI[j + 6];
  if HwID = 1 then
   PrintMessage(' (18F2550)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else
   if HwID = 2 then
    PrintMessage(' (18F2450)' + #13 + '' + NL + '' + #13 + '' + NL + '')
   else
    if HwID = 3 then
     PrintMessage(' (18F2458/2553)' + #13 + '' + NL + '' + #13 + '' + NL + '')
    else
     if HwID = 4 then
      PrintMessage(' (18F25K50)' + #13 + '' + NL + '' + #13 + '' + NL + '')
     else
      if HwID = 5 then
       PrintMessage(' (18F25K50 all-in-one variant)' + #13 + '' + NL + '' + #13 + '' + NL + '')
      else
       PrintMessage(' (?)' + #13 + '' + NL + '' + #13 + '' + NL + '');
  gtk_toggle_button_set_active(b_V33check, IfThen(HwID = 5, TRUE_, FALSE_));
  gtk_widget_set_visible(b_V33check, IfThen(HwID = 5, FALSE_, TRUE_));
end;

function CheckV33Regulator: Integer;
var
  i: Integer;
  j: Integer;
begin
  j := 0;
  if skipV33check then
   Exit(1);
  bufferU[j] := $F1;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $93;
  Inc(j);
  bufferU[j] := $FE;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $01;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $81;
  Inc(j);
  bufferU[j] := $32;
  Inc(j);
  bufferU[j] := $00;
  Inc(j);
  bufferU[j] := 0;
  Inc(j);
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $81;
  Inc(j);
  bufferU[j] := $F1;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $93;
  Inc(j);
  bufferU[j] := $FF;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  while (j < 64 - 3) and (bufferI[j] <> $F0) do
  begin
   Inc(j);
  end;
  i := bufferI[j + 3] and $2;
  j := 3;
  while (j < 64 - 3) and (bufferI[j] <> $F0) do
  begin
   Inc(j);
  end;
  Exit(IfThen(i + bufferI[j + 3] and $2 = 2, 1, 0));
end;

function CheckS1: Integer;
var
  i: Integer;
  j: Integer;
begin
  j := 0;
  bufferU[j] := $F0;
  Inc(j);
  bufferU[j] := $0F;
  Inc(j);
  if HwID = 5 then
  begin
   bufferU[j] := $80;
   Inc(j);
  end
  else
  begin
   bufferU[j] := $84;
   Inc(j);
  end;
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  while (j < 64 - 3) and (bufferI[j] <> $F0) do
  begin
   Inc(j);
  end;
  if HwID = 5 then
  begin
   i := bufferI[j + 3] and $80;
   Exit(IfThen(i, 1, 0));
  end
  else
  begin
   i := bufferI[j + 3] and $8;
   Exit(IfThen(i, 0, 1));
  end;
end;

function TestHw(widget: PControl; parent: PForm): Pointer;
var
  str: array[0..256-1] of Char;
  j: Integer;
  i: Integer;
  x: Integer;
  r: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  StartHVReg(13);
  j := 0;
  MsgBox(strings[I_TestHW]);
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $5;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=5V' + NL + ' VPPU=13V' + NL + ' PGD(RB5)=0V' + NL + ' PGC(RB6)=0V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $15;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=5V' + NL + ' VPPU=0V' + NL + ' PGD(RB5)=5V' + NL + ' PGC(RB6)=5V' + NL + ' PGM(RB7)=5V');
  MsgBox(str);
  j := 0;
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $1;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=0V' + NL + ' VPPU=13V' + NL + ' PGD(RB5)=5V' + NL + ' PGC(RB6)=0V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $4;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=0V' + NL + ' VPPU=0V' + NL + ' PGD(RB5)=0V' + NL + ' PGC(RB6)=5V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[j] := $0F;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $0E;
  Inc(j);
  bufferU[j] := $0;
  Inc(j);
  bufferU[j] := $04;
  Inc(j);
  while j < 64 do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  if FWVersion >= $900 then
  begin
   j := 0;
   strcpy(str, '0000000000000');
   PrintMessage('IO test' + NL + 'RC|RA|--RB--|' + NL + '');
   for i := 0 to (13) - 1 do
   begin
    x := 1 shl i;
    j := 0;
    bufferU[j] := $0E;
    Inc(j);
    bufferU[j] := $0;
    Inc(j);
    bufferU[j] := $45;
    Inc(j);
    bufferU[j] := $0;
    Inc(j);
    bufferU[j] := $0;
    Inc(j);
    bufferU[j] := $32;
    Inc(j);
    bufferU[j] := x and $FF;
    Inc(j);
    bufferU[j] := (x shr 5) and $FF;
    Inc(j);
    bufferU[j] := $46;
    Inc(j);
    bufferU[j] := $47;
    Inc(j);
    bufferU[j] := $04;
    Inc(j);
    while j < 64 do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    j := 0;
    while (j < 64 - 1) and (bufferI[j] <> $46) do
    begin
     Inc(j);
    end;
    r := bufferI[j + 1];
    j := 2;
    while (j < 64 - 1) and (bufferI[j] <> $47) do
    begin
     Inc(j);
    end;
    r := r + (bufferI[j + 1] and $F8) shl 5;
    for j := 0 to (13) - 1 do
    begin
     str[12 - j] := IfThen(x and (1 shl j), #49, #48);
    end;
    PrintMessage(str);
    sprintf(str, ' (%s)' + NL + '', IfThen(r = x, 'OK', strings[S_ErrSing]));
    PrintMessage(str);
   end;
  end;
end;

function msDelay(delay: Double): Pointer;
var
  stop: T__int64;
  freq: T__int64;
  timeout: T__int64;
begin
  QueryPerformanceCounter(@stop);
  QueryPerformanceFrequency(@freq);
  timeout := stop + (delay * freq) div 1000.0;
  while stop < timeout do
  begin
   QueryPerformanceCounter(@stop);
  end;
end;

function PacketIO(delay: Double): Pointer;
var
  delay0: Integer;
  start: T__int64;
  stop: T__int64;
  freq: T__int64;
  timeout: T__int64;
begin
  if saveLog and logfile then
   fprintf(logfile, 'PacketIO(%.2f)' + NL + '', delay);
  delay0 := delay;
  QueryPerformanceCounter(@start);
  QueryPerformanceFrequency(@freq);
  delay := delay - 50 - 10;
  if delay < 0 then
   delay := 0;
  Result_ := WriteFile(WriteHandle, bufferU0, 64 + 1, @BytesWritten, nil);
  QueryPerformanceCounter(@stop);
  timeout := stop + (delay * freq) div 1000.0;
  while stop < timeout do
  begin
   QueryPerformanceCounter(@stop);
  end;
  Result_ := ReadFile(ReadHandle, bufferI0, 64 + 1, @NumberOfBytesRead, @HIDOverlapped);
  Result_ := WaitForSingleObject(hEventObject, 50);
  if saveLog and logfile then
   WriteLogIO();
  ResetEvent(hEventObject);
  if Result_ <> WAIT_OBJECT_0 then
  begin
   PrintMessage(strings[S_comTimeout]);
   if saveLog and logfile then
    fprintf(logfile, strings[S_comTimeout]);
  end;
  QueryPerformanceCounter(@stop);
  if saveLog and logfile then
   fprintf(logfile, 'T=%.2f ms (%+.2f ms)' + NL + '', ((stop - start) * 1000.0) div freq, ((stop - start) * 1000.0) div freq - delay0);
end;

function main(argc: Integer; argv: array of PChar): Integer;
var
  f: ^TextFile;
  homedir: PChar;
  config_dir: PChar;
  fname: PChar;
  lang: array[0..32-1] of Char;
  langfile: Integer;
  temp: array[0..256-1] of Char;
  line: array[0..256-1] of Char;
  X: Integer;
  dev_ini: array[0..64-1] of Char;
  vid_ini: Integer;
  pid_ini: Integer;
  max_err_ini: Integer;
  tmpbuf: array[0..128-1] of Cardinal;
  option_index: Integer;
  help: Integer;
  command: Integer;
  i: Integer;
  j: Integer;
  long_options: array of Toption;
  langid: PChar;
  n: Integer;
  p: PChar;
  builder: PObject;
  cssProvider: PObject;
  w: PControl;
  loadCoffBtn: PControl;
  text: array[0..16-1] of Char;
  info: TDevInfo;
begin
  fname := 0;
  lang := '';
  langfile := 0;
  homedir := g_get_home_dir();
  if homedir then
  begin
   config_dir := g_build_path(G_DIR_SEPARATOR_S, homedir, '.opgui', nil);
   if not (g_file_test(config_dir, G_FILE_TEST_IS_DIR)) then
    mkdir(config_dir);
   fname := g_build_path(G_DIR_SEPARATOR_S, config_dir, 'opgui.ini', nil);
   f := fopen(fname, 'r');
   if f then
   begin
    while fgets(line, 256, f) do
    begin
     if sscanf(line, 'device %s', temp) > 0 then
      strcpy(dev, temp)
     else
      if sscanf(line, 'vid %X', @X) > 0 then
       vid := X
      else
       if sscanf(line, 'pid %X', @X) > 0 then
        pid := X
       else
        sscanf(line, 'maxerr %d', @max_err);
    end;
    fclose(f);
   end;
  end;
  strncpy(dev_ini, dev, SizeOf(dev_ini));
  vid_ini := vid;
  pid_ini := pid;
  max_err_ini := max_err;
  vid_ini := vid;
  pid_ini := pid;
  max_err_ini := max_err;
  bufferI := bufferI0 + 1;
  bufferU := bufferU0 + 1;
  bufferI0[0] := 0;
  bufferU0[0] := 0;
  gtk_init(@argc, @argv);
  opterr := 0;
  option_index := 0;
  help := 0;
  command := 0;
  long_options := [['?', no_argument, @help, 1], ['h', no_argument, @help, 1], ['help', no_argument, @help, 1], ['c', no_argument, @command, 1], ['command', no_argument, @command, 1], ['lang', required_argument, 0, #108], ['langfile', no_argument, @langfile, 1], [0, 0, 0, 0]];
  j := getopt_long_only(argc, argv, '', long_options, @option_index);
  while j <> -1 do
  begin
   if j = #108 then
   begin
    strncpy(lang, optarg, SizeOf(lang) - 1);
   end;
  end;
  j := 0;
  i := optind;
  while (i < argc) and (i < 128) do
  begin
   sscanf(argv[i], '%x', @(tmpbuf[j]));
   Inc(i);
   Inc(j);
  end;
  while j < 128 do
  begin
   tmpbuf[j] := 0;
   Inc(j);
  end;
  strinit();
  langid := 0;
  i := 0;
  if lang[0] then
  begin
   if (lang[0] = #105) and (lang[1] = #116) then
   begin
    strings := strings_it;
    i := 1;
   end
   else
    if (lang[0] = #101) and (lang[1] = #110) then
    begin
     strings := strings_en;
     i := 1;
    end
    else
     i := strfind(lang, 'languages.rc');
  end;
  if i = 0 then
  begin
   langid := malloc(19);
   n := GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SISO639LANGNAME, langid, 9);
   langid[n - 1] := #45;
   GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SISO3166CTRYNAME, langid + n, 9);
   if langid then
   begin
    if (langid[0] = #105) and (langid[1] = #116) then
     strings := strings_it
    else
     if (langid[0] = #101) and (langid[1] = #110) then
      strings := strings_en
     else
      if strfind(langid, 'languages.rc') then
      else
      begin
       p := strchr(langid, #45);
       if p then
        p^ := 0;
       if not (strfind(langid, 'languages.rc')) then
        strings := strings_en;
      end;
   end
   else
    strings := strings_en;
  end;
  if langfile then
   GenerateLangFile(langid, 'languages.rc');
  if help then
  begin
   printf(strings[I_GUI_CMD_HELP]);
   exit_(0);
  end;
  if command then
  begin
   cmdline := 1;
   DeviceDetected := FindDevice(vid, pid);
   if not (DeviceDetected) then
   begin
    DeviceDetected := FindDevice(new_vid, new_pid);
    if DeviceDetected then
    begin
     vid := new_vid;
     pid := new_pid;
    end;
   end;
   if not (DeviceDetected) then
    DeviceDetected := FindDevice(old_vid, old_pid);
   if DeviceDetected then
   begin
    bufferU[0] := 0;
    for i := 1 to (64) - 1 do
    begin
     bufferU[i] := tmpbuf[i - 1];
    end;
    PacketIO(100);
    printf('> ');
    for i := 1 to (64) - 1 do
    begin
     printf('%02X ', bufferU[i]);
    end;
    printf('' + NL + '< ');
    for i := 1 to (64) - 1 do
    begin
     printf('%02X ', bufferI[i]);
    end;
    printf(NL);
   end
   else
    printf(strings[S_noprog]);
   exit_(0);
  end;
  builder := nil;
  builder := gtk_builder_new_from_resource('/res/opgui.glade');
  window := gtk_builder_get_object(builder, 'window');
  g_signal_connect(window, 'destroy', G___GTK2LAZ_CALLCONV_stdcall(Xclose), nil);
  gtk_window_set_icon(window, gdk_pixbuf_new_from_resource('/res/sys.png', nil));
  cssProvider := gtk_css_provider_new();
  gtk_css_provider_load_from_resource(cssProvider, '/res/style.css');
  gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), 0(cssProvider), 0);
  w := nil;
  sprintf(str, 'opgui v%s', 'unknown');
  gtk_window_set_title(window, str);
  notebook := gtk_builder_get_object(builder, 'NOTEBOOK');
  w := gtk_builder_get_object(builder, 'OPEN_T');
  gtk_widget_set_tooltip_text(w, strings[I_Fopen]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(Fopen), nil);
  w := gtk_builder_get_object(builder, 'SAVE_T');
  gtk_widget_set_tooltip_text(w, strings[I_Fsave]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(Fsave), nil);
  readBtn := gtk_builder_get_object(builder, 'READ_T');
  gtk_widget_set_tooltip_text(readBtn, strings[I_DevR]);
  g_signal_connect(readBtn, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(DevRead), nil);
  writeBtn := gtk_builder_get_object(builder, 'WRITE_T');
  gtk_widget_set_tooltip_text(writeBtn, strings[I_DevW]);
  g_signal_connect(writeBtn, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(DevWrite), nil);
  stopBtn := gtk_builder_get_object(builder, 'STOP_T');
  gtk_widget_set_tooltip_text(stopBtn, strings[I_ICD_STOP]);
  g_signal_connect(stopBtn, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(Stop), nil);
  w := gtk_builder_get_object(builder, 'CONNECT_T');
  gtk_widget_set_tooltip_text(w, strings[I_CONN]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(Connect), nil);
  w := gtk_builder_get_object(builder, 'INFO_T');
  gtk_widget_set_tooltip_text(w, strings[I_Info]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(info), nil);
  gtk_label_set_text(gtk_builder_get_object(builder, 'DATA_T_L'), strings[I_Data]);
  data := gtk_builder_get_object(builder, 'DATA');
  dataBuf := gtk_text_view_get_buffer(data);
  gtk_label_set_text(gtk_builder_get_object(builder, 'DEVICE_L'), strings[I_Dev]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'TYPE_L'), strings[I_TypeFilt]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'DEV_SRC_L'), strings[I_Filt]);
  devTypeCombo := gtk_builder_get_object(builder, 'TYPE_C');
  g_signal_connect(G_OBJECT(devTypeCombo), 'changed', G___GTK2LAZ_CALLCONV_stdcall(FilterDevType), nil);
  devFiltEntry := gtk_builder_get_object(builder, 'DEV_SRC_E');
  g_signal_connect(G_OBJECT(devFiltEntry), 'changed', G___GTK2LAZ_CALLCONV_stdcall(FilterDevType), nil);
  devTree := gtk_builder_get_object(builder, 'DEV_TREE');
  gtk_tree_view_insert_column_with_attributes(devTree, -1, strings[I_Dev], gtk_cell_renderer_text_new(), 'text', DEVICE_NAME_COLUMN, nil);
  gtk_tree_view_insert_column_with_attributes(devTree, -1, strings[I_Type], gtk_cell_renderer_text_new(), 'text', DEVICE_GROUP_COLUMN, nil);
  gtk_tree_view_column_set_fixed_width(gtk_tree_view_get_column(devTree, 0), 125);
  gtk_tree_view_column_set_fixed_width(gtk_tree_view_get_column(devTree, 1), 125);
  devFrame := gtk_builder_get_object(builder, 'DEVICE_NAME');
  devinfo := gtk_builder_get_object(builder, 'DEV_INFO');
  EEPROM_RW := gtk_builder_get_object(builder, 'EE_RW');
  gtk_button_set_label(EEPROM_RW, strings[I_EE]);
  ReadReserved := gtk_builder_get_object(builder, 'RES_READ');
  gtk_button_set_label(ReadReserved, strings[I_ReadRes]);
  Write_ID_BKCal := gtk_builder_get_object(builder, 'PROG_ID');
  gtk_button_set_label(Write_ID_BKCal, strings[I_ID_BKo_W]);
  WriteCalib12 := gtk_builder_get_object(builder, 'PROG_CAL12');
  gtk_button_set_label(WriteCalib12, strings[I_CalW]);
  UseSaflock := gtk_builder_get_object(builder, 'USE_SAFLOCK');
  gtk_button_set_label(UseSaflock, strings[I_Saflock]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'OSCCAL_L'), strings[I_OSCW]);
  UseOSCCAL := gtk_builder_get_object(builder, 'OSCCAL');
  gtk_button_set_label(UseOSCCAL, strings[I_OSC]);
  UseBKOSCCAL := gtk_builder_get_object(builder, 'BKOSCCAL');
  gtk_button_set_label(UseBKOSCCAL, strings[I_BKOSC]);
  UseFileCal := gtk_builder_get_object(builder, 'FILECAL');
  gtk_button_set_label(UseFileCal, strings[I_OSCF]);
  ICD_check := gtk_builder_get_object(builder, 'ICD');
  gtk_button_set_label(ICD_check, strings[I_ICD_ENABLE]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'ICD_ADDR_L'), strings[I_ICD_ADDRESS]);
  ICD_addr_entry := gtk_builder_get_object(builder, 'ICD_ADDR');
  ConfigForce := gtk_builder_get_object(builder, 'FORCE_CW');
  gtk_button_set_label(ConfigForce, strings[I_PIC_FORCECW]);
  CW1_entry := gtk_builder_get_object(builder, 'CW1');
  CW2_entry := gtk_builder_get_object(builder, 'CW2');
  CW3_entry := gtk_builder_get_object(builder, 'CW3');
  CW4_entry := gtk_builder_get_object(builder, 'CW4');
  CW5_entry := gtk_builder_get_object(builder, 'CW5');
  CW6_entry := gtk_builder_get_object(builder, 'CW6');
  CW7_entry := gtk_builder_get_object(builder, 'CW7');
  AVR_FuseLow := gtk_builder_get_object(builder, 'FUSEL');
  AVR_FuseLowWrite := gtk_builder_get_object(builder, 'FUSEL_C');
  gtk_button_set_label(AVR_FuseLowWrite, strings[I_AT_FUSE]);
  AVR_FuseHigh := gtk_builder_get_object(builder, 'FUSEH');
  AVR_FuseHighWrite := gtk_builder_get_object(builder, 'FUSEH_C');
  gtk_button_set_label(AVR_FuseHighWrite, strings[I_AT_FUSEH]);
  AVR_FuseExt := gtk_builder_get_object(builder, 'FUSEX');
  AVR_FuseExtWrite := gtk_builder_get_object(builder, 'FUSEX_C');
  gtk_button_set_label(AVR_FuseExtWrite, strings[I_AT_FUSEX]);
  AVR_Lock := gtk_builder_get_object(builder, 'FUSELCK');
  AVR_LockWrite := gtk_builder_get_object(builder, 'FUSELCK_C');
  gtk_button_set_label(AVR_LockWrite, strings[I_AT_LOCK]);
  b_WfuseLF := gtk_builder_get_object(builder, 'FUSEL_W3K');
  gtk_button_set_label(b_WfuseLF, strings[I_AT_FUSELF]);
  g_signal_connect(G_OBJECT(b_WfuseLF), 'clicked', G___GTK2LAZ_CALLCONV_stdcall(WriteATfuseLowLF), window);
  devFramePIC := gtk_builder_get_object(builder, 'PIC_OPT');
  devFrameAVR := gtk_builder_get_object(builder, 'AVR_OPT');
  devFrameConfigW := gtk_builder_get_object(builder, 'CW_OPT');
  devFrameICD := gtk_builder_get_object(builder, 'ICD_OPT');
  devFrameOsc := gtk_builder_get_object(builder, 'OSC_OPT');
  devPIC_CW1 := gtk_builder_get_object(builder, 'CW1_OPT');
  devPIC_CW2 := gtk_builder_get_object(builder, 'CW2_OPT');
  devPIC_CW3 := gtk_builder_get_object(builder, 'CW3_OPT');
  devPIC_CW4 := gtk_builder_get_object(builder, 'CW4_OPT');
  devPIC_CW5 := gtk_builder_get_object(builder, 'CW5_OPT');
  devPIC_CW6 := gtk_builder_get_object(builder, 'CW6_OPT');
  devPIC_CW7 := gtk_builder_get_object(builder, 'CW7_OPT');
  devPIC_CW8 := gtk_builder_get_object(builder, 'CW8_OPT');
  gtk_widget_hide(devFrameAVR);
  gtk_widget_hide(devFramePIC);
  gtk_label_set_text(gtk_builder_get_object(builder, 'OPTIONS_L'), strings[I_Opt]);
  VID_entry := gtk_builder_get_object(builder, 'VID');
  PID_entry := gtk_builder_get_object(builder, 'PID');
  Errors_entry := gtk_builder_get_object(builder, 'MAXERR');
  b_connect := gtk_builder_get_object(builder, 'CONNECT');
  gtk_button_set_label(b_connect, strings[I_CONN]);
  g_signal_connect(G_OBJECT(b_connect), 'clicked', G___GTK2LAZ_CALLCONV_stdcall(Connect), window);
  b_testhw := gtk_builder_get_object(builder, 'TEST');
  gtk_button_set_label(b_testhw, strings[I_TestHWB]);
  g_signal_connect(G_OBJECT(b_testhw), 'clicked', G___GTK2LAZ_CALLCONV_stdcall(TestHw), window);
  b_log := gtk_builder_get_object(builder, 'LOG');
  gtk_button_set_label(b_log, strings[I_LOG]);
  b_V33check := gtk_builder_get_object(builder, '3VCHECK');
  gtk_button_set_label(b_V33check, strings[I_CK_V33]);
  b_WaitS1 := gtk_builder_get_object(builder, 'S1');
  gtk_button_set_label(b_WaitS1, strings[I_WAITS1]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'MAXERR_L'), strings[I_MAXERR]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'I2CMODE'), strings[I_I2CMode]);
  I2C8bit := gtk_builder_get_object(builder, 'I2C8BIT');
  I2C16bit := gtk_builder_get_object(builder, 'I2C16BIT');
  SPI00 := gtk_builder_get_object(builder, 'SPI00');
  SPI01 := gtk_builder_get_object(builder, 'SPI01');
  SPI10 := gtk_builder_get_object(builder, 'SPI10');
  SPI11 := gtk_builder_get_object(builder, 'SPI11');
  gtk_label_set_text(gtk_builder_get_object(builder, 'DATASEND_L'), strings[I_I2CDATAOUT]);
  I2CDataSend := gtk_builder_get_object(builder, 'DATASEND');
  gtk_label_set_text(gtk_builder_get_object(builder, 'DATATR_L'), strings[I_I2CDATATR]);
  I2CDataReceive := gtk_builder_get_object(builder, 'DATATR');
  gtk_label_set_text(gtk_builder_get_object(builder, 'NBYTE_L'), strings[I_I2C_NB]);
  I2CNbyte := gtk_builder_get_object(builder, 'NBYTE_S');
  gtk_label_set_text(gtk_builder_get_object(builder, 'SPEED_L'), strings[I_Speed]);
  I2CSpeed := gtk_builder_get_object(builder, 'SPEED_C');
  I2CSendBtn := gtk_builder_get_object(builder, 'SEND_B');
  gtk_button_set_label(I2CSendBtn, strings[I_I2CSend]);
  g_signal_connect(G_OBJECT(I2CSendBtn), 'clicked', G___GTK2LAZ_CALLCONV_stdcall(I2cspiS), window);
  I2CReceiveBtn := gtk_builder_get_object(builder, 'RECEIVE_B');
  gtk_button_set_label(I2CReceiveBtn, strings[I_I2CReceive]);
  g_signal_connect(G_OBJECT(I2CReceiveBtn), 'clicked', G___GTK2LAZ_CALLCONV_stdcall(I2cspiR), window);
  loadCoffBtn := gtk_builder_get_object(builder, 'LOADCOFF_B');
  gtk_tool_button_set_label(loadCoffBtn, strings[I_LOAD_COFF]);
  g_signal_connect(G_OBJECT(loadCoffBtn), 'clicked', G___GTK2LAZ_CALLCONV_stdcall(loadCoff), window);
  g_signal_connect(gtk_builder_get_object(builder, 'ICD_TAB'), 'key_press_event', G___GTK2LAZ_CALLCONV_stdcall(icd_key_event), nil);
  gtk_menu_item_set_label(gtk_builder_get_object(builder, 'OPTIONS_M'), strings[I_Opt]);
  icdMenuPC := gtk_builder_get_object(builder, 'PCOUNT_M');
  gtk_menu_item_set_label(icdMenuPC, strings[I_SHOW_PC]);
  icdMenuSTAT := gtk_builder_get_object(builder, 'STATUS_M');
  gtk_menu_item_set_label(icdMenuSTAT, strings[I_SHOW_STATUS]);
  icdMenuBank0 := gtk_builder_get_object(builder, 'BANK0_M');
  gtk_menu_item_set_label(icdMenuBank0, strings[I_SHOW_BANK0]);
  icdMenuBank1 := gtk_builder_get_object(builder, 'BANK1_M');
  gtk_menu_item_set_label(icdMenuBank1, strings[I_SHOW_BANK1]);
  icdMenuBank2 := gtk_builder_get_object(builder, 'BANK2_M');
  gtk_menu_item_set_label(icdMenuBank2, strings[I_SHOW_BANK2]);
  icdMenuBank3 := gtk_builder_get_object(builder, 'BANK3_M');
  gtk_menu_item_set_label(icdMenuBank3, strings[I_SHOW_BANK3]);
  icdMenuEE := gtk_builder_get_object(builder, 'EE_M');
  gtk_menu_item_set_label(icdMenuEE, strings[I_SHOW_EE]);
  w := gtk_builder_get_object(builder, 'ICD_RUN');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_RUN]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(icdRun), nil);
  w := gtk_builder_get_object(builder, 'ICD_HALT');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_HALT]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(icdHalt), nil);
  w := gtk_builder_get_object(builder, 'ICD_STEP');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_STEP]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(icdStep), nil);
  w := gtk_builder_get_object(builder, 'ICD_STEPOVER');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_STEPOVER]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(icdStepOver), nil);
  w := gtk_builder_get_object(builder, 'ICD_STOP');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_STOP]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(icdStop), nil);
  w := gtk_builder_get_object(builder, 'ICD_REFRESH');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_REFRESH]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(icdRefresh), nil);
  icdCommand := gtk_builder_get_object(builder, 'ICD_CMD_E');
  gtk_widget_set_tooltip_text(icdCommand, strings[I_ICD_CMD]);
  g_signal_connect(G_OBJECT(icdCommand), 'key_press_event', G___GTK2LAZ_CALLCONV_stdcall(icdCommand_key_event), nil);
  w := gtk_builder_get_object(builder, 'ICD_HELP');
  gtk_widget_set_tooltip_text(w, strings[I_ICD_HELP]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(ICDHelp), nil);
  gtk_label_set_text(gtk_builder_get_object(builder, 'ICD_SOURCE_L'), strings[I_ICD_SOURCE]);
  sourceTxt := gtk_builder_get_object(builder, 'ICD_SOURCE');
  sourceBuf := gtk_text_view_get_buffer(sourceTxt);
  g_signal_connect(G_OBJECT(sourceTxt), 'button_press_event', G___GTK2LAZ_CALLCONV_stdcall(source_mouse_event), nil);
  gtk_label_set_text(gtk_builder_get_object(builder, 'ICD_STAT_L'), strings[I_ICD_STATUS]);
  statusTxt := gtk_builder_get_object(builder, 'ICD_STATUS');
  statusBuf := gtk_text_view_get_buffer(statusTxt);
  g_signal_connect(G_OBJECT(statusTxt), 'button_press_event', G___GTK2LAZ_CALLCONV_stdcall(icdStatus_mouse_event), nil);
  b_io_active := gtk_builder_get_object(builder, 'IOEN');
  gtk_button_set_label(b_io_active, strings[I_IO_Enable]);
  g_signal_connect(G_OBJECT(b_io_active), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(IOactive), nil);
  ioButtons[0].r_0 := gtk_builder_get_object(builder, 'RB0_0');
  ioButtons[0].r_1 := gtk_builder_get_object(builder, 'RB0_1');
  ioButtons[0].r_I := gtk_builder_get_object(builder, 'RB0_I');
  ioButtons[0].e_I := gtk_builder_get_object(builder, 'RB0_L');
  ioButtons[1].r_0 := gtk_builder_get_object(builder, 'RB1_0');
  ioButtons[1].r_1 := gtk_builder_get_object(builder, 'RB1_1');
  ioButtons[1].r_I := gtk_builder_get_object(builder, 'RB1_I');
  ioButtons[1].e_I := gtk_builder_get_object(builder, 'RB1_L');
  ioButtons[2].r_0 := gtk_builder_get_object(builder, 'RB2_0');
  ioButtons[2].r_1 := gtk_builder_get_object(builder, 'RB2_1');
  ioButtons[2].r_I := gtk_builder_get_object(builder, 'RB2_I');
  ioButtons[2].e_I := gtk_builder_get_object(builder, 'RB2_L');
  ioButtons[3].r_0 := gtk_builder_get_object(builder, 'RB3_0');
  ioButtons[3].r_1 := gtk_builder_get_object(builder, 'RB3_1');
  ioButtons[3].r_I := gtk_builder_get_object(builder, 'RB3_I');
  ioButtons[3].e_I := gtk_builder_get_object(builder, 'RB3_L');
  ioButtons[4].r_0 := gtk_builder_get_object(builder, 'RB4_0');
  ioButtons[4].r_1 := gtk_builder_get_object(builder, 'RB4_1');
  ioButtons[4].r_I := gtk_builder_get_object(builder, 'RB4_I');
  ioButtons[4].e_I := gtk_builder_get_object(builder, 'RB4_L');
  ioButtons[5].r_0 := gtk_builder_get_object(builder, 'RB5_0');
  ioButtons[5].r_1 := gtk_builder_get_object(builder, 'RB5_1');
  ioButtons[5].r_I := gtk_builder_get_object(builder, 'RB5_I');
  ioButtons[5].e_I := gtk_builder_get_object(builder, 'RB5_L');
  ioButtons[6].r_0 := gtk_builder_get_object(builder, 'RB6_0');
  ioButtons[6].r_1 := gtk_builder_get_object(builder, 'RB6_1');
  ioButtons[6].r_I := gtk_builder_get_object(builder, 'RB6_I');
  ioButtons[6].e_I := gtk_builder_get_object(builder, 'RB6_L');
  ioButtons[7].r_0 := gtk_builder_get_object(builder, 'RB7_0');
  ioButtons[7].r_1 := gtk_builder_get_object(builder, 'RB7_1');
  ioButtons[7].r_I := gtk_builder_get_object(builder, 'RB7_I');
  ioButtons[7].e_I := gtk_builder_get_object(builder, 'RB7_L');
  ioButtons[8].r_0 := gtk_builder_get_object(builder, 'RC7_0');
  ioButtons[8].r_1 := gtk_builder_get_object(builder, 'RC7_1');
  ioButtons[8].r_I := gtk_builder_get_object(builder, 'RC7_I');
  ioButtons[8].e_I := gtk_builder_get_object(builder, 'RC7_L');
  ioButtons[9].r_0 := gtk_builder_get_object(builder, 'RC6_0');
  ioButtons[9].r_1 := gtk_builder_get_object(builder, 'RC6_1');
  ioButtons[9].r_I := gtk_builder_get_object(builder, 'RC6_I');
  ioButtons[9].e_I := gtk_builder_get_object(builder, 'RC6_L');
  ioButtons[10].r_0 := gtk_builder_get_object(builder, 'RA5_0');
  ioButtons[10].r_1 := gtk_builder_get_object(builder, 'RA5_1');
  ioButtons[10].r_I := gtk_builder_get_object(builder, 'RA5_I');
  ioButtons[10].e_I := gtk_builder_get_object(builder, 'RA5_L');
  ioButtons[11].r_0 := gtk_builder_get_object(builder, 'RA4_0');
  ioButtons[11].r_1 := gtk_builder_get_object(builder, 'RA4_1');
  ioButtons[11].r_I := gtk_builder_get_object(builder, 'RA4_I');
  ioButtons[11].e_I := gtk_builder_get_object(builder, 'RA4_L');
  ioButtons[12].r_0 := gtk_builder_get_object(builder, 'RA3_0');
  ioButtons[12].r_1 := gtk_builder_get_object(builder, 'RA3_1');
  ioButtons[12].r_I := gtk_builder_get_object(builder, 'RA3_I');
  ioButtons[12].e_I := gtk_builder_get_object(builder, 'RA3_L');
  for ii := 0 to (SizeOf(ioButtons) div SizeOf(ioButtons[0])) - 1 do
  begin
   gtk_toggle_button_set_active(ioButtons[ii].r_I, TRUE_);
   g_signal_connect(G_OBJECT(ioButtons[ii].r_0), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(IOchanged), nil);
   g_signal_connect(G_OBJECT(ioButtons[ii].r_1), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(IOchanged), nil);
   g_signal_connect(G_OBJECT(ioButtons[ii].r_I), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(IOchanged), nil);
  end;
  VDD_ON := gtk_builder_get_object(builder, 'VDDUEN');
  VPP_ON := gtk_builder_get_object(builder, 'VPPUEN');
  DCDC_ON := gtk_builder_get_object(builder, 'DCDCEN');
  DCDC_voltage := gtk_builder_get_object(builder, 'DCDC_S');
  gtk_label_set_text(gtk_builder_get_object(builder, 'CMD_L'), strings[I_IO_Commands]);
  gtk_label_set_text(gtk_builder_get_object(builder, 'CMDSEND_L'), strings[I_I2CDATAOUT]);
  commandSend := gtk_builder_get_object(builder, 'CMDSEND');
  gtk_label_set_text(gtk_builder_get_object(builder, 'CMDTR_L'), strings[I_I2CDATATR]);
  commandTransfer := gtk_builder_get_object(builder, 'CMDTR');
  w := gtk_builder_get_object(builder, 'CMDTR_B');
  gtk_button_set_label(w, strings[I_I2CSend]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(CommandIO), window);
  g_signal_connect(G_OBJECT(VDD_ON), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(VPPVDDactive), nil);
  g_signal_connect(G_OBJECT(VPP_ON), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(VPPVDDactive), nil);
  g_signal_connect(G_OBJECT(DCDC_ON), 'toggled', G___GTK2LAZ_CALLCONV_stdcall(DCDCactive), nil);
  g_signal_connect(G_OBJECT(DCDC_voltage), 'value_changed', G___GTK2LAZ_CALLCONV_stdcall(DCDCactive), nil);
  Hex_entry := gtk_builder_get_object(builder, 'HEXIN');
  Hex_data := gtk_builder_get_object(builder, 'DATAOUT');
  Address_entry := gtk_builder_get_object(builder, 'ADDRIN');
  Data_entry := gtk_builder_get_object(builder, 'DATAIN');
  Hex_data2 := gtk_builder_get_object(builder, 'HEXOUT');
  w := gtk_builder_get_object(builder, 'HEXSAVE');
  gtk_button_set_label(w, strings[I_Fsave]);
  g_signal_connect(w, 'clicked', G___GTK2LAZ_CALLCONV_stdcall(HexSave), window);
  g_signal_connect(G_OBJECT(Hex_entry), 'changed', G___GTK2LAZ_CALLCONV_stdcall(HexConvert), nil);
  g_signal_connect(G_OBJECT(Address_entry), 'changed', G___GTK2LAZ_CALLCONV_stdcall(DataToHexConvert), nil);
  g_signal_connect(G_OBJECT(Data_entry), 'changed', G___GTK2LAZ_CALLCONV_stdcall(DataToHexConvert), nil);
  status_bar := gtk_builder_get_object(builder, 'STATUS_B');
  statusID := gtk_statusbar_get_context_id(status_bar, 'ID');
  gtk_widget_show_all(window);
  sprintf(text, '%04X', vid);
  gtk_entry_set_text(VID_entry, text);
  sprintf(text, '%04X', pid);
  gtk_entry_set_text(PID_entry, text);
  sprintf(text, '%d', max_err);
  gtk_entry_set_text(Errors_entry, text);
  sizeW := $8400;
  memCODE_W := malloc(sizeW * SizeOf(WORD));
  initVar();
  for i := 0 to ($8400) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  strncpy(LogFileName, strings[S_LogFile], SizeOf(LogFileName));
  gtk_combo_box_text_append(0(devTypeCombo), GROUP_ALL, GROUP_ALL);
  for i := 0 to (NUM_GROUPS) - 1 do
  begin
   gtk_combo_box_text_append(0(devTypeCombo), groupNames[i], groupNames[i]);
  end;
  if strlen(dev) > 0 then
  begin
   info := GetDevInfo(dev);
   gtk_combo_box_set_active_id(devTypeCombo, groupNames[info.group]);
  end
  else
  begin
   gtk_combo_box_set_active_id(devTypeCombo, GROUP_ALL);
  end;
  DeviceDetected := FindDevice(vid, pid);
  if not (DeviceDetected) then
  begin
   DeviceDetected := FindDevice(new_vid, new_pid);
   if DeviceDetected then
   begin
    vid := new_vid;
    pid := new_pid;
   end;
  end;
  if not (DeviceDetected) then
   DeviceDetected := FindDevice(old_vid, old_pid);
  ProgID();
  gtk_main();
  if strcmp(dev_ini, dev) or (vid_ini <> vid) or (pid_ini <> pid) or (max_err_ini <> max_err) then
  begin
   if homedir then
   begin
    f := fopen(fname, 'w');
    if f then
    begin
     fprintf(f, 'device %s' + NL + '', dev);
     fprintf(f, 'maxerr %d' + NL + '', max_err);
     fprintf(f, 'vid %X' + NL + '', vid);
     fprintf(f, 'pid %X' + NL + '', pid);
    end;
    fclose(f);
   end;
  end;
  Exit(0);
end;

function FindDevice(vid: Integer; pid: Integer): Integer;
var
  MyDeviceDetected: Integer;
  detailData: TPSP_DEVICE_INTERFACE_DETAIL_DATA;
  DeviceHandle: THANDLE;
  hDevInfo: THANDLE;
  HidGuid: TGUID;
  MyDevicePathName: array[0..1024-1] of Char;
  Length: TULONG;
  Required: TULONG;
  Attributes: THIDD_ATTRIBUTES;
  devInfoData: TSP_DEVICE_INTERFACE_DATA;
  LastDevice: Integer;
  MemberIndex: Integer;
  Result_: TLONG;
  hHID: THMODULE;
  HidD_GetHidGuid: TGETHIDGUID;
  HidD_GetAttributes: TGETATTRIBUTES;
  HidD_SetNumInputBuffers: TSETNUMINPUTBUFFERS;
  HidD_GetNumInputBuffers: TGETNUMINPUTBUFFERS;
  HidD_GetFeature: TGETFEATURE;
  HidD_SetFeature: TSETFEATURE;
  HidD_GetInputReport: TGETREPORT;
  HidD_SetOutputReport: TSETREPORT;
  HidD_GetManufacturerString: TGETMANUFACTURERSTRING;
  HidD_GetProductString: TGETPRODUCTSTRING;
  hSAPI: THMODULE;
  SetupDiGetClassDevsA: TSETUPDIGETCLASSDEVS;
  SetupDiEnumDeviceInterfaces: TSETUPDIENUMDEVICEINTERFACES;
  SetupDiGetDeviceInterfaceDetailA: TSETUPDIGETDEVICEINTERFACEDETAIL;
  SetupDiDestroyDeviceInfoList: TSETUPDIDESTROYDEVICEINFOLIST;
begin
  MyDeviceDetected := FALSE_;
  // local typedef: HIDD_ATTRIBUTES
  // local typedef: PHIDD_ATTRIBUTES
  // local typedef: GETHIDGUID
  // local typedef: GETATTRIBUTES
  // local typedef: SETNUMINPUTBUFFERS
  // local typedef: GETNUMINPUTBUFFERS
  // local typedef: GETFEATURE
  // local typedef: SETFEATURE
  // local typedef: GETREPORT
  // local typedef: SETREPORT
  // local typedef: GETMANUFACTURERSTRING
  // local typedef: GETPRODUCTSTRING
  LastDevice := FALSE_;
  MemberIndex := 0;
  Length := 0;
  detailData := nil;
  DeviceHandle := nil;
  hHID := 0;
  HidD_GetHidGuid := 0;
  HidD_GetAttributes := 0;
  HidD_SetNumInputBuffers := 0;
  HidD_GetNumInputBuffers := 0;
  HidD_GetFeature := 0;
  HidD_SetFeature := 0;
  HidD_GetInputReport := 0;
  HidD_SetOutputReport := 0;
  HidD_GetManufacturerString := 0;
  HidD_GetProductString := 0;
  hHID := LoadLibrary('hid.dll');
  if not (hHID) then
  begin
   PrintMessage('Can't find hid.dll');
   Exit(0);
  end;
  HidD_GetHidGuid := GetProcAddress(hHID, 'HidD_GetHidGuid');
  HidD_GetAttributes := GetProcAddress(hHID, 'HidD_GetAttributes');
  HidD_SetNumInputBuffers := GetProcAddress(hHID, 'HidD_SetNumInputBuffers');
  HidD_GetNumInputBuffers := GetProcAddress(hHID, 'HidD_GetNumInputBuffers');
  HidD_GetFeature := GetProcAddress(hHID, 'HidD_GetFeature');
  HidD_SetFeature := GetProcAddress(hHID, 'HidD_SetFeature');
  HidD_GetInputReport := GetProcAddress(hHID, 'HidD_GetInputReport');
  HidD_SetOutputReport := GetProcAddress(hHID, 'HidD_SetOutputReport');
  HidD_GetManufacturerString := GetProcAddress(hHID, 'HidD_GetManufacturerString');
  HidD_GetProductString := GetProcAddress(hHID, 'HidD_GetProductString');
  if (HidD_GetHidGuid = nil) or (HidD_GetAttributes = nil) or (HidD_GetFeature = nil) or (HidD_SetFeature = nil) or (HidD_GetInputReport = nil) or (HidD_SetOutputReport = nil) or (HidD_GetManufacturerString = nil) or (HidD_GetProductString = nil) or (HidD_SetNumInputBuffers = nil) or (HidD_GetNumInputBuffers = nil) then
   Exit(0);
  hSAPI := 0;
  hSAPI := LoadLibrary('setupapi.dll');
  if not (hSAPI) then
  begin
   PrintMessage('Can't find setupapi.dll');
   Exit(0);
  end;
  // local typedef: SETUPDIGETCLASSDEVS
  // local typedef: SETUPDIENUMDEVICEINTERFACES
  // local typedef: SETUPDIGETDEVICEINTERFACEDETAIL
  // local typedef: SETUPDIDESTROYDEVICEINFOLIST
  SetupDiGetClassDevsA := 0;
  SetupDiEnumDeviceInterfaces := 0;
  SetupDiGetDeviceInterfaceDetailA := 0;
  SetupDiDestroyDeviceInfoList := 0;
  SetupDiGetClassDevsA := GetProcAddress(hSAPI, 'SetupDiGetClassDevsA');
  SetupDiEnumDeviceInterfaces := GetProcAddress(hSAPI, 'SetupDiEnumDeviceInterfaces');
  SetupDiGetDeviceInterfaceDetailA := GetProcAddress(hSAPI, 'SetupDiGetDeviceInterfaceDetailA');
  SetupDiDestroyDeviceInfoList := GetProcAddress(hSAPI, 'SetupDiDestroyDeviceInfoList');
  if (SetupDiGetClassDevsA = nil) or (SetupDiEnumDeviceInterfaces = nil) or (SetupDiDestroyDeviceInfoList = nil) or (SetupDiGetDeviceInterfaceDetailA = nil) then
   Exit(0);
  HidD_GetHidGuid(@HidGuid);
  hDevInfo := SetupDiGetClassDevs(@HidGuid, nil, nil, DIGCF_PRESENT or DIGCF_INTERFACEDEVICE);
  devInfoData.cbSize := SizeOf(devInfoData);
  MemberIndex := 0;
  LastDevice := FALSE_;
  repeat
   Result_ := SetupDiEnumDeviceInterfaces(hDevInfo, 0, @HidGuid, MemberIndex, @devInfoData);
   if Result_ <> 0 then
   begin
    Result_ := SetupDiGetDeviceInterfaceDetail(hDevInfo, @devInfoData, nil, 0, @Length, nil);
    detailData := malloc(Length);
    detailData^.cbSize := SizeOf(SP_DEVICE_INTERFACE_DETAIL_DATA);
    Result_ := SetupDiGetDeviceInterfaceDetail(hDevInfo, @devInfoData, detailData, Length, @Required, nil);
    DeviceHandle := CreateFile(detailData^.DevicePath, 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, nil);
    Attributes.Size := SizeOf(Attributes);
    Result_ := HidD_GetAttributes(DeviceHandle, @Attributes);
    MyDeviceDetected := FALSE_;
    if Attributes.VendorID = vid then
    begin
     if Attributes.ProductID = pid then
     begin
      MyDeviceDetected := TRUE_;
      strcpy(MyDevicePathName, detailData^.DevicePath);
      WriteHandle := CreateFile(detailData^.DevicePath, GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, nil);
      ReadHandle := CreateFile(detailData^.DevicePath, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nil);
      if hEventObject then
       CloseHandle(hEventObject);
      hEventObject := CreateEvent(nil, TRUE_, TRUE_, '');
      HIDOverlapped.hEvent := hEventObject;
      HIDOverlapped.Offset := 0;
      HIDOverlapped.OffsetHigh := 0;
      Result_ := HidD_SetNumInputBuffers(DeviceHandle, 64);
     end
     else
      CloseHandle(DeviceHandle);
    end
    else
     CloseHandle(DeviceHandle);
    free(detailData);
   end
   else
    LastDevice := TRUE_;
   MemberIndex := MemberIndex + 1;
  until not ((LastDevice = FALSE_) and (MyDeviceDetected = FALSE_));
  SetupDiDestroyDeviceInfoList(hDevInfo);
  if MyDeviceDetected = FALSE_ then
  begin
   PrintMessage(strings[S_noprog]);
  end
  else
  begin
   PrintMessage(strings[S_prog]);
   sprintf(str, 'VID=0x%04X PID=0x%04X' + #13 + '' + NL + '', vid, pid);
   PrintMessage(str);
  end;
  Exit(MyDeviceDetected);
end;

end.
