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
  sys_types;

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
    r_0: ^TControl;
    r_1: ^TControl;
    r_I: ^TControl;
    e_I: ^TControl;
  end;

type
  TGtkTreeModelForeachFunc = ^TProcedure;
  TGSourceFunc = ^TProcedure;

var
  strings: PChar;
  cmdline: Integer;
  saveLog: Integer;
  programID: Integer;
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
  loadfileEE: array[0..512-1] of Char;
  savefileEE: array[0..512-1] of Char;
  CoffFileName: array[0..512-1] of Char;
  vid: Integer;
  pid: Integer;
  new_vid: Integer;
  new_pid: Integer;
  old_vid: Integer;
  old_pid: Integer;
  memCODE_W: ^TWORD;
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
  DeviceDetected: Integer;
  IOTimer: Integer;
  skipV33check: Integer;
  waitS1: Integer;
  waitingS1: Integer;
  progress: Integer;
  RWstop: Integer;
  forceConfig: Integer;
  useSAFLOCK_flag: Integer;
  dataBuf: ^TMemo;
  data: ^TControl;
  data_scroll: ^TControl;
  window: ^TControl;
  toolbar: ^TControl;
  button: ^TControl;
  b_open: ^TControl;
  b_save: ^TControl;
  b_read: ^TControl;
  b_write: ^TControl;
  notebook: ^TControl;
  label_: ^TControl;
  status_bar: ^TControl;
  img: ^TControl;
  devTree: ^TControl;
  devTypeCombo: ^TControl;
  devFramePIC: ^TControl;
  ICD_check: ^TControl;
  ICD_addr_entry: ^TControl;
  EEPROM_RW: ^TControl;
  ReadReserved: ^TControl;
  Write_ID_BKCal: ^TControl;
  WriteCalib12: ^TControl;
  UseSaflock: ^TControl;
  UseOSCCAL: ^TControl;
  UseBKOSCCAL: ^TControl;
  UseFileCal: ^TControl;
  devFrameAVR: ^TControl;
  AVR_FuseLow: ^TControl;
  AVR_FuseLowWrite: ^TControl;
  AVR_FuseHigh: ^TControl;
  AVR_FuseHighWrite: ^TControl;
  AVR_FuseExt: ^TControl;
  AVR_FuseExtWrite: ^TControl;
  AVR_Lock: ^TControl;
  AVR_LockWrite: ^TControl;
  b_WfuseLF: ^TControl;
  b_connect: ^TControl;
  b_testhw: ^TControl;
  b_log: ^TControl;
  VID_entry: ^TControl;
  PID_entry: ^TControl;
  Errors_entry: ^TControl;
  I2C8bit: ^TControl;
  I2C16bit: ^TControl;
  SPI00: ^TControl;
  SPI01: ^TControl;
  SPI10: ^TControl;
  SPI11: ^TControl;
  I2CDataSend: ^TControl;
  I2CDataReceive: ^TControl;
  I2CSendBtn: ^TControl;
  I2CReceiveBtn: ^TControl;
  I2CNbyte: ^TControl;
  I2CSpeed: ^TControl;
  DCDC_ON: ^TControl;
  DCDC_voltage: ^TControl;
  VPP_ON: ^TControl;
  VDD_ON: ^TControl;
  b_io_active: ^TControl;
  commandSend: ^TControl;
  commandTransfer: ^TControl;
  b_V33check: ^TControl;
  Hex_entry: ^TControl;
  Address_entry: ^TControl;
  Data_entry: ^TControl;
  Hex_data: ^TControl;
  Hex_data2: ^TControl;
  CW1_entry: ^TControl;
  CW2_entry: ^TControl;
  CW3_entry: ^TControl;
  CW4_entry: ^TControl;
  CW5_entry: ^TControl;
  CW6_entry: ^TControl;
  CW7_entry: ^TControl;
  ConfigForce: ^TControl;
  b_WaitS1: ^TControl;
  devFrameConfigW: ^TControl;
  devFrameICD: ^TControl;
  devFrameOsc: ^TControl;
  devPIC_CW1: ^TControl;
  devPIC_CW2: ^TControl;
  devPIC_CW3: ^TControl;
  devPIC_CW4: ^TControl;
  devPIC_CW5: ^TControl;
  devPIC_CW6: ^TControl;
  devPIC_CW7: ^TControl;
  devPIC_CW8: ^TControl;
  devinfo: ^TControl;
  stopBtn: ^TControl;
  readBtn: ^TControl;
  writeBtn: ^TControl;
  devStore: ^TGtkListStore;
  devFiltEntry: ^TControl;
  devFrame: ^TControl;
  devSel: ^TObject;
  ioButtons: array[0..13-1] of Tio_btn;
  statusID: Integer;
  ee: Integer;
  readRes: Integer;
  dev: array[0..64-1] of Char;
  devType: Integer;
  str: array[0..4096-1] of Char;
  cur_path: PChar;
  cur_pathEE: PChar;
  groupNames: array[0..NUM_GROUPS-1] of PChar;
  GROUP_ALL: PChar;
  fd: Integer;
  path: array[0..512-1] of Char;
  bufferU: array[0..128-1] of Byte;
  bufferI: array[0..128-1] of Byte;

  ioButtons: array[0..13-1] of Tio_btn;

// --- function declarations ---
function Connect(widget: ^TControl; window: ^TControl): Pointer;
procedure I2cspiR;
procedure I2cspiS;
procedure ProgID;
function PrintMessageI2C(msg: PChar): Pointer;
procedure ShowContext;
function FindDevice(vid: Integer; pid: Integer): Integer;
function CheckS1: Integer;
function delete_event(widget: ^TControl; event: ^TGdkEvent; data: Pointer): Integer;
function info(widget: ^TControl; window: ^TControl): Pointer;
function PrintMessage(msg: PChar): Pointer;
function PrintMessageI2C(msg: PChar): Pointer;
function PrintMessageCMD(msg: PChar): Pointer;
procedure getOptions;
procedure GetSelectedDevice;
function Fopen(widget: ^TControl; window: ^TControl): Pointer;
function Fsave(widget: ^TControl; window: ^TControl): Pointer;
procedure selectDataTab;
function DevWrite(widget: ^TControl; window: ^TControl): Pointer;
function DevRead(widget: ^TControl; window: ^TControl): Pointer;
function WriteATfuseLowLF(widget: ^TControl; window: ^TControl): Pointer;
function onDevSel_Changed(widget: ^TControl; window: ^TControl): Pointer;
function selectDev_ForeachFunc(model: ^TGtkTreeModel; path: ^TGtkTreePath; iter: ^TGtkTreeIter; devNameToSelect: PChar): Boolean;
function sortIterCompareFunc(model: ^TGtkTreeModel; a: ^TGtkTreeIter; b: ^TGtkTreeIter; userdata: Pointer): Integer;
function strupr(s: PChar): PChar;
function AddDevices(groupFilter: Tgroup_t; textFilter: PChar): Pointer;
function FilterDevType(widget: ^TControl; window: ^TControl): Pointer;
function IOchanged(widget: ^TControl; window: ^TControl): Pointer;
function IOactive(widget: ^TControl; window: ^TControl): Pointer;
function VPPVDDactive(widget: ^TControl; window: ^TControl): Pointer;
function DCDCactive(widget: ^TControl; window: ^TControl): Pointer;
function HexConvert(widget: ^TControl; window: ^TControl): Pointer;
function DataToHexConvert(widget: ^TControl; window: ^TControl): Pointer;
function HexSave(widget: ^TControl; window: ^TControl): Pointer;
function Stop(widget: ^TControl; window: ^TControl): Pointer;
procedure Xclose;
function MsgBox(msg: PChar): Pointer;
function Connect(widget: ^TControl; window: ^TControl): Pointer;
procedure I2cspiR;
procedure I2cspiS;
procedure CommandIO;
procedure DisplayEE;
function StartHVReg(V: Double): Integer;
procedure ProgID;
function CheckV33Regulator: Integer;
function CheckS1: Integer;
function TestHw(widget: ^TControl; parent: ^TForm): Pointer;
function msDelay(delay: Double): Pointer;
function GetTickCount: TDWORD;
function PacketIO(delay: Double): Pointer;
function main(argc: Integer; argv: array of PChar): Integer;
function FindDevice(vid: Integer; pid: Integer): Integer;

implementation

function delete_event(widget: ^TControl; event: ^TGdkEvent; data: Pointer): Integer;
var
  // (no local variables detected)
begin
  gtk_main_quit();
  Exit(FALSE_);
end;

function info(widget: ^TControl; window: ^TControl): Pointer;
var
  license: PChar;
begin
  license := 'This program is free software; you can redistribute it and/or' + NL + 'modify it under the terms of the GNU Library General Public License as' + NL + 'published by the Free Software Foundation; either version 2 of the' + NL + 'License, or (at your option) any later version.' + NL + '' + NL + 'This program is distributed in the hope that it will be useful,' + NL + 'but WITHOUT ANY WARRANTY; without even the implied warranty of' + NL + 'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU' + NL + 'Library General Public License for more details.' + NL + '' + NL + 'You should have received a copy of the GNU Library General Public' + NL + 'License along with the Gnome Library; see the file COPYING.LIB.  If not,' + NL + 'write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,' + NL + 'Boston, MA 02111-1307, USA.' + NL + '';
  gtk_show_about_dialog(NULL, 'comments', 'A graphical interface for the Open Programmer', 'copyright', 'Copyright (C) Alberto Maccioni 2009-2025' + NL + '' + NL + 'This program is free software; you can ' + NL + 'redistribute it and/or modify it under ' + NL + 'the terms of the GNU General Public License ' + NL + 'as published by the Free Software Foundation;' + NL + 'either version 2 of the License, or ' + NL + '(at your option) any later version.', 'license', license, 'logo', gdk_pixbuf_new_from_resource('/res/sys.png', NULL), 'program-name', 'OPGUI', 'version', 'unknown', 'website', 'www.openprog.altervista.org', 'wrap-license', TRUE_, 'title', 'Info about OPGUI', NULL);
end;

function PrintMessage(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  l: Integer;
begin
  if cmdline then
   Exit;
  gtk_text_buffer_get_end_iter(dataBuf, @(iter));
  gtk_text_buffer_insert(dataBuf, @(iter), msg, -(1));
  gtk_text_buffer_get_start_iter(dataBuf, @(iter2));
  gtk_text_buffer_get_end_iter(dataBuf, @(iter));
  l := gtk_text_buffer_get_line_count(dataBuf);
  if (l) > ((600) + (10)) then
  begin
   gtk_text_iter_set_line(@(iter), (l) - (600));
   gtk_text_buffer_delete(dataBuf, @(iter2), @(iter));
  end;
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
  gtk_text_buffer_get_end_iter(dataBuf, @(iter));
  gtk_text_view_scroll_to_iter(data, @(iter), 0.0, FALSE_, 0, 0);
end;

function PrintMessageI2C(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
  dataBuf: ^TMemo;
begin
  dataBuf := gtk_text_view_get_buffer(I2CDataReceive);
  gtk_text_buffer_set_text(dataBuf, msg, -(1));
  gtk_text_buffer_get_end_iter(dataBuf, @(iter));
  gtk_text_view_scroll_to_iter(I2CDataReceive, @(iter), 0.0, FALSE_, 0, 0);
  while gtk_events_pending() do
  begin
   gtk_main_iteration();
  end;
end;

function PrintMessageCMD(msg: PChar): Pointer;
var
  iter: TGtkTextIter;
  dataBuf: ^TMemo;
begin
  dataBuf := gtk_text_view_get_buffer(commandTransfer);
  gtk_text_buffer_set_text(dataBuf, msg, -(1));
  gtk_text_buffer_get_end_iter(dataBuf, @(iter));
  gtk_text_view_scroll_to_iter(commandTransfer, @(iter), 0.0, FALSE_, 0, 0);
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
  vid := htoi(gtk_entry_get_text(GTK_ENTRY(VID_entry)), 4);
  pid := htoi(gtk_entry_get_text(GTK_ENTRY(PID_entry)), 4);
  saveLog := gtk_toggle_button_get_active(b_log);
  ee := IfThen(gtk_toggle_button_get_active(EEPROM_RW), $FFFF, 0);
  programID := gtk_toggle_button_get_active(Write_ID_BKCal);
  max_err := atoi(gtk_entry_get_text(GTK_ENTRY(Errors_entry)));
  load_calibword := gtk_toggle_button_get_active(WriteCalib12);
  useSAFLOCK_flag := gtk_toggle_button_get_active(UseSaflock);
  load_osccal := not (gtk_toggle_button_get_active(UseOSCCAL));
  load_BKosccal := gtk_toggle_button_get_active(UseBKOSCCAL);
  ICDenable := gtk_toggle_button_get_active(ICD_check);
  readRes := gtk_toggle_button_get_active(ReadReserved);
  skipV33check := gtk_toggle_button_get_active(b_V33check);
  waitS1 := gtk_toggle_button_get_active(b_WaitS1);
  i := sscanf(gtk_entry_get_text(GTK_ENTRY(ICD_addr_entry)), '%x', @(ICDaddr));
  if (((i) <> (1)) or ((ICDaddr) < (0))) or ((ICDaddr) > ($FFFF)) then
   ICDaddr := $1FF0;
  str := 0;
  if str then
   strncpy(dev, str, (SizeOf(dev)) - (1));
  g_free(str);
  AVRlock := $100; AVRfuse_x := $100; AVRfuse_h := $100; AVRfuse := $100;
  if gtk_toggle_button_get_active(AVR_FuseLowWrite) then
  begin
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(AVR_FuseLow)), '%x', @(AVRfuse));
   if (((i) <> (1)) or ((AVRfuse) < (0))) or ((AVRfuse) > ($FF)) then
    AVRfuse := $100;
  end;
  if gtk_toggle_button_get_active(AVR_FuseHighWrite) then
  begin
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(AVR_FuseHigh)), '%x', @(AVRfuse_h));
   if (((i) <> (1)) or ((AVRfuse_h) < (0))) or ((AVRfuse_h) > ($FF)) then
    AVRfuse_h := $100;
  end;
  if gtk_toggle_button_get_active(AVR_FuseExtWrite) then
  begin
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(AVR_FuseExt)), '%x', @(AVRfuse_x));
   if (((i) <> (1)) or ((AVRfuse_x) < (0))) or ((AVRfuse_x) > ($FF)) then
    AVRfuse_x := $100;
  end;
  if gtk_toggle_button_get_active(AVR_LockWrite) then
  begin
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(AVR_Lock)), '%x', @(AVRlock));
   if (((i) <> (1)) or ((AVRlock) < (0))) or ((AVRlock) > ($FF)) then
    AVRlock := $100;
  end;
  str := malloc(128);
  if gtk_toggle_button_get_active(ConfigForce) then
  begin
   cw7 := $10000; cw6 := $10000; cw5 := $10000; cw4 := $10000; cw3 := $10000; cw2 := $10000; cw1 := $10000;
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW1_entry)), '%x', @(cw1));
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW2_entry)), '%x', @(cw2));
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW3_entry)), '%x', @(cw3));
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW4_entry)), '%x', @(cw4));
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW5_entry)), '%x', @(cw5));
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW6_entry)), '%x', @(cw6));
   i := sscanf(gtk_entry_get_text(GTK_ENTRY(CW7_entry)), '%x', @(cw7));
   if (devType) = (PIC16) then
   begin
    if ((not (strncmp(dev, '16F1', 4))) or (not (strncmp(dev, '12F1', 4)))) and ((sizeW) > ($8008)) then
    begin
     if (cw1) <= ($3FFF) then
     begin
      memCODE_W[$8007] := cw1;
      sprintf(str, strings[S_ForceConfigWx], 1, $8007, cw1);
      PrintMessage(str);
     end;
     if (cw2) <= ($3FFF) then
     begin
      memCODE_W[$8008] := cw2;
      sprintf(str, strings[S_ForceConfigWx], 2, $8008, cw2);
      PrintMessage(str);
     end;
    end
    else
    begin
     if ((cw1) <= ($3FFF)) and ((sizeW) > ($2007)) then
     begin
      memCODE_W[$2007] := cw1;
      sprintf(str, strings[S_ForceConfigWx], 1, $2007, cw1);
      PrintMessage(str);
     end;
     if ((cw2) <= ($3FFF)) and ((sizeW) > ($2008)) then
     begin
      memCODE_W[$2008] := cw2;
      printf('2' + NL + '');
      sprintf(str, strings[S_ForceConfigWx], 2, $2008, cw2);
      PrintMessage(str);
     end;
    end;
   end
   else
    if (devType) = (PIC12) then
    begin
     if ((cw1) <= ($FFF)) and ((sizeW) > ($FFF)) then
     begin
      memCODE_W[$FFF] := cw1;
      sprintf(str, strings[S_ForceConfigWx], 1, $FFF, cw1);
      PrintMessage(str);
     end;
    end
    else
     if (devType) = (PIC18) then
     begin
      if (cw1) <= ($FFFF) then
      begin
       memCONFIG[0] := (cw1) and ($FF);
       memCONFIG[1] := ((cw1) shr (8)) and ($FF);
      end;
      if (cw2) <= ($FFFF) then
      begin
       memCONFIG[2] := (cw2) and ($FF);
       memCONFIG[3] := ((cw2) shr (8)) and ($FF);
      end;
      if (cw3) <= ($FFFF) then
      begin
       memCONFIG[4] := (cw3) and ($FF);
       memCONFIG[5] := ((cw3) shr (8)) and ($FF);
      end;
      if (cw4) <= ($FFFF) then
      begin
       memCONFIG[6] := (cw4) and ($FF);
       memCONFIG[7] := ((cw4) shr (8)) and ($FF);
      end;
      if (cw5) <= ($FFFF) then
      begin
       memCONFIG[8] := (cw5) and ($FF);
       memCONFIG[9] := ((cw5) shr (8)) and ($FF);
      end;
      if (cw6) <= ($FFFF) then
      begin
       memCONFIG[10] := (cw6) and ($FF);
       memCONFIG[11] := ((cw6) shr (8)) and ($FF);
      end;
      if (cw7) <= ($FFFF) then
      begin
       memCONFIG[12] := (cw7) and ($FF);
       memCONFIG[13] := ((cw7) shr (8)) and ($FF);
      end;
      PrintMessage(strings[S_ForceConfigW]);
      for i := 0 to (7) - 1 do
      begin
       sprintf(str, strings[S_ConfigWordH], (i) + (1), memCONFIG[((i) * (2)) + (1)]);
       PrintMessage(str);
       sprintf(str, strings[S_ConfigWordL], (i) + (1), memCONFIG[(i) * (2)]);
       PrintMessage(str);
      end;
     end;
  end;
  free(str);
end;

procedure GetSelectedDevice;
var
  tmpModel: ^TGtkTreeModel;
  tmpIter: TGtkTreeIter;
  devName: PChar;
begin
  if not (GTK_IS_TREE_SELECTION(devSel)) then
  begin
   Exit;
  end;
  if gtk_tree_selection_get_selected(devSel, @(tmpModel), @(tmpIter)) then
  begin
   gtk_tree_model_get(tmpModel, @(tmpIter), DEVICE_NAME_COLUMN, @(devName), -(1));
   strcpy(dev, devName);
   gtk_widget_set_sensitive(GTK_WIDGET(readBtn), TRUE_);
   gtk_widget_set_sensitive(GTK_WIDGET(writeBtn), TRUE_);
   g_free(devName);
  end
  else
  begin
   dev[0] := '\0';
   gtk_widget_set_sensitive(GTK_WIDGET(readBtn), FALSE_);
   gtk_widget_set_sensitive(GTK_WIDGET(writeBtn), FALSE_);
  end;
end;

function Fopen(widget: ^TControl; window: ^TControl): Pointer;
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
  dialog2: ^TGtkFileChooser;
  filename2: PChar;
begin
  GetSelectedDevice();
  if progress then
   Exit;
  progress := 1;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fopen], window, GTK_FILE_CHOOSER_ACTION_OPEN, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_OPEN], GTK_RESPONSE_ACCEPT, NULL);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  if (gtk_dialog_run(GTK_DIALOG(dialog))) = (GTK_RESPONSE_ACCEPT) then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   Load(devType, filename);
   g_free(filename);
   if (devType) = (AVR) then
   begin
    dialog2 := gtk_file_chooser_dialog_new(strings[S_openEEfile], window, GTK_FILE_CHOOSER_ACTION_OPEN, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_OPEN], GTK_RESPONSE_ACCEPT, NULL);
    if not (cur_pathEE) then
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog);
    if cur_pathEE then
     gtk_file_chooser_set_current_folder(dialog2, cur_pathEE);
    if (gtk_dialog_run(GTK_DIALOG(dialog2))) = (GTK_RESPONSE_ACCEPT) then
    begin
     filename2 := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog2));
     if cur_pathEE then
      free(cur_pathEE);
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog2);
     LoadEE(devType, filename2);
     g_free(filename2);
    end;
    gtk_widget_destroy(GTK_WIDGET(dialog2));
   end;
  end;
  gtk_widget_destroy(GTK_WIDGET(dialog));
  progress := 0;
end;

function Fsave(widget: ^TControl; window: ^TControl): Pointer;
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
  dialog2: ^TGtkFileChooser;
  filename2: PChar;
begin
  if progress then
   Exit;
  progress := 1;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fsave], window, GTK_FILE_CHOOSER_ACTION_SAVE, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_SAVE], GTK_RESPONSE_ACCEPT, NULL);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  gtk_file_chooser_set_do_overwrite_confirmation(dialog, TRUE_);
  if (gtk_dialog_run(GTK_DIALOG(dialog))) = (GTK_RESPONSE_ACCEPT) then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   Save(devType, filename);
   sprintf(str, strings[S_FileSaved], filename);
   PrintMessage(str);
   g_free(filename);
   if (devType) = (AVR) then
   begin
    dialog2 := gtk_file_chooser_dialog_new(strings[S_saveEEfile], window, GTK_FILE_CHOOSER_ACTION_SAVE, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_SAVE], GTK_RESPONSE_ACCEPT, NULL);
    if not (cur_pathEE) then
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog);
    if cur_pathEE then
     gtk_file_chooser_set_current_folder(dialog2, cur_pathEE);
    gtk_file_chooser_set_do_overwrite_confirmation(dialog2, TRUE_);
    if (gtk_dialog_run(GTK_DIALOG(dialog2))) = (GTK_RESPONSE_ACCEPT) then
    begin
     filename2 := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog2));
     if cur_pathEE then
      free(cur_pathEE);
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog2);
     SaveEE(devType, filename2);
     sprintf(str, strings[S_FileSaved], filename2);
     PrintMessage(str);
     g_free(filename2);
    end;
    gtk_widget_destroy(GTK_WIDGET(dialog2));
   end;
  end;
  gtk_widget_destroy(GTK_WIDGET(dialog));
  progress := 0;
end;

procedure selectDataTab;
var
  // (no local variables detected)
begin
  gtk_notebook_set_current_page(notebook, 0);
end;

function DevWrite(widget: ^TControl; window: ^TControl): Pointer;
var
  i: Integer;
  S1: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  selectDataTab();
  gtk_statusbar_push(status_bar, statusID, '');
  RWstop := 0;
  getOptions();
  if (not (waitingS1)) and (waitS1) then
  begin
   waitingS1 := 1;
   S1 := 0;
   PrintMessage(strings[I_PRESSS1]);
   i := 0;
   while ((not (S1)) and (waitS1)) and (waitingS1) do
   begin
    S1 := CheckS1();
    msDelay(50);
    PrintMessage('.');
    if ((i) mod (64)) = (63) then
     PrintMessage(strings[S_NL]);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    msDelay(50);
    Inc(i);
   end;
   PrintMessage(strings[S_NL]);
   if (not (progress)) and (S1) then
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

function DevRead(widget: ^TControl; window: ^TControl): Pointer;
var
  i: Integer;
  S1: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  selectDataTab();
  gtk_statusbar_push(status_bar, statusID, '');
  getOptions();
  RWstop := 0;
  if (not (waitingS1)) and (waitS1) then
  begin
   waitingS1 := 1;
   S1 := 0;
   PrintMessage(strings[I_PRESSS1]);
   i := 0;
   while ((not (S1)) and (waitS1)) and (waitingS1) do
   begin
    S1 := CheckS1();
    msDelay(50);
    PrintMessage('.');
    if ((i) mod (64)) = (63) then
     PrintMessage(strings[S_NL]);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    msDelay(50);
    Inc(i);
   end;
   PrintMessage(strings[S_NL]);
   if (not (progress)) and (S1) then
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

function WriteATfuseLowLF(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if progress then
   Exit;
  getOptions();
  if gtk_toggle_button_get_active(AVR_FuseLowWrite) then
  begin
   progress := 1;
   if (AVRfuse) < ($100) then
    WriteATfuseSlow(AVRfuse);
   progress := 0;
  end;
end;

function onDevSel_Changed(widget: ^TControl; window: ^TControl): Pointer;
var
  info: TDevInfo;
begin
  GetSelectedDevice();
  if (strlen(dev)) = (0) then
   Exit;
  info := GetDevInfo(dev);
  sprintf(str, '<b>%s: %s</b>', strings[I_Dev], dev);
  gtk_label_set_markup(devFrame, str);
  devType := info.family;
  gtk_label_set_text(devinfo, info.features);
  if ((((devType) = (PIC12)) or ((devType) = (PIC16))) or ((devType) = (PIC18))) or ((devType) = (PIC24)) then
  begin
   gtk_widget_show_all(GTK_WIDGET(devFramePIC));
   gtk_widget_hide(GTK_WIDGET(devFrameAVR));
   gtk_widget_show_all(GTK_WIDGET(EEPROM_RW));
  end
  else
   if (devType) = (AVR) then
   begin
    gtk_widget_hide(GTK_WIDGET(devFramePIC));
    gtk_widget_show_all(GTK_WIDGET(devFrameAVR));
    gtk_widget_show_all(GTK_WIDGET(EEPROM_RW));
   end
   else
   begin
    gtk_widget_hide(GTK_WIDGET(devFramePIC));
    gtk_widget_hide(GTK_WIDGET(devFrameAVR));
    gtk_widget_hide(GTK_WIDGET(EEPROM_RW));
   end;
  if (devType) = (PIC16) then
   gtk_widget_show_all(GTK_WIDGET(devFrameICD))
  else
   gtk_widget_hide(GTK_WIDGET(devFrameICD));
  if ((devType) = (PIC12)) or ((devType) = (PIC16)) then
   gtk_widget_show_all(GTK_WIDGET(devFrameOsc))
  else
   gtk_widget_hide(GTK_WIDGET(devFrameOsc));
  if (((devType) = (PIC12)) or ((devType) = (PIC16))) or ((devType) = (PIC18)) then
   gtk_widget_show_all(GTK_WIDGET(Write_ID_BKCal))
  else
   gtk_widget_hide(GTK_WIDGET(Write_ID_BKCal));
  if (devType) = (PIC16) then
   gtk_widget_show_all(GTK_WIDGET(WriteCalib12))
  else
   gtk_widget_hide(GTK_WIDGET(WriteCalib12));
  if (((devType) = (PIC12)) or ((devType) = (PIC16))) or ((devType) = (PIC18)) then
  begin
   gtk_widget_show_all(GTK_WIDGET(devFrameConfigW));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW2));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW3));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW4));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW5));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW6));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW7));
   gtk_widget_hide(GTK_WIDGET(devPIC_CW8));
   if (devType) = (PIC16) then
   begin
    gtk_widget_show_all(GTK_WIDGET(devPIC_CW2));
   end
   else
    if (devType) = (PIC18) then
    begin
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW2));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW3));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW4));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW5));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW6));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW7));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW8));
     gtk_widget_show_all(GTK_WIDGET(devPIC_CW8));
    end;
  end
  else
  begin
   gtk_widget_hide(GTK_WIDGET(devFrameConfigW));
   gtk_toggle_button_set_active(ConfigForce, FALSE_);
  end;
  gtk_statusbar_push(status_bar, statusID, dev);
end;

function selectDev_ForeachFunc(model: ^TGtkTreeModel; path: ^TGtkTreePath; iter: ^TGtkTreeIter; devNameToSelect: PChar): Boolean;
var
  thisEntryDevName: PChar;
  matched: Integer;
begin
  gtk_tree_model_get(model, iter, DEVICE_NAME_COLUMN, @(thisEntryDevName), -(1));
  matched := (strcmp(thisEntryDevName, devNameToSelect)) = (0);
  if matched then
   gtk_tree_selection_select_iter(devSel, iter);
  g_free(thisEntryDevName);
  Exit(matched);
end;

function sortIterCompareFunc(model: ^TGtkTreeModel; a: ^TGtkTreeIter; b: ^TGtkTreeIter; userdata: Pointer): Integer;
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
    gtk_tree_model_get(model, a, dataCol, @(nameA), -(1));
    gtk_tree_model_get(model, b, dataCol, @(nameB), -(1));
    if ((nameA) = (NULL)) or ((nameB) = (NULL)) then
    begin
     if ((nameA) = (NULL)) and ((nameB) = (NULL)) then
      Break;
     ret := IfThen((nameA) = (NULL), -(1), 1);
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
  while (p^ := toupper(p^)) do
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
  if GTK_IS_TREE_SELECTION(devSel) then
   g_signal_handlers_disconnect_by_func(devSel, onDevSel_Changed, NULL);
  if not (GTK_IS_LIST_STORE(devStore)) then
  begin
   devStore := gtk_list_store_new(DEVICE_N_COLUMNS, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING);
   gtk_tree_view_set_model(devTree, GTK_TREE_MODEL(devStore));
   gtk_tree_sortable_set_sort_func(GTK_TREE_SORTABLE(devStore), SORT_STRING_NAME, sortIterCompareFunc, GINT_TO_POINTER(SORT_STRING_NAME), NULL);
   gtk_tree_sortable_set_sort_func(GTK_TREE_SORTABLE(devStore), SORT_STRING_GROUP, sortIterCompareFunc, GINT_TO_POINTER(SORT_STRING_GROUP), NULL);
   gtk_tree_view_column_set_sort_column_id(gtk_tree_view_get_column(devTree, 0), SORT_STRING_NAME);
   gtk_tree_view_column_set_sort_column_id(gtk_tree_view_get_column(devTree, 1), SORT_STRING_GROUP);
   g_object_unref(devStore);
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
   devices := malloc((strlen(DEVLIST[i].device)) + (1));
   strcpy(devices, DEVLIST[i].device);
   populateDevInfo(@(info), @(DEVLIST[i]));
   tok := strtok(devices, ', ' + #9 + '');
   while tok do
   begin
    info.group := nameToGroup(tok);
    if (((info.group) <> (-(1))) and (((not (textFilter)) or ((strlen(textFilter)) = (0))) or (strstr(strupr(tok), textFilterU)))) and (((groupFilter) = (-(1))) or ((info.group) = (groupFilter))) then
    begin
     gtk_list_store_insert_with_values(devStore, NULL, -(1), DEVICE_ID_COLUMN, Inc(j), DEVICE_NAME_COLUMN, tok, DEVICE_GROUP_COLUMN, groupNames[info.group], -(1));
    end;
    tok := strtok(NULL, ', ' + #9 + '');
   end;
  end;
  free(devices);
  if GTK_IS_TREE_SELECTION(devSel) then
  begin
   gtk_tree_selection_unselect_all(devSel);
  end
  else
  begin
   devSel := gtk_tree_view_get_selection(devTree);
   gtk_tree_selection_set_mode(devSel, GTK_SELECTION_SINGLE);
  end;
  g_signal_connect(devSel, 'changed', onDevSel_Changed, NULL);
  gtk_tree_model_foreach(GTK_TREE_MODEL(devStore), selectDev_ForeachFunc, dev);
end;

function FilterDevType(widget: ^TControl; window: ^TControl): Pointer;
var
  selGroupName: PChar;
  filtText: PChar;
  selGroup: Tgroup_t;
begin
  selGroupName := gtk_combo_box_text_get_active_text(GTK_COMBO_BOX_TEXT(devTypeCombo));
  filtText := gtk_entry_get_text(GTK_ENTRY(devFiltEntry));
  selGroup := -(1);
  for i := 0 to (NUM_GROUPS) - 1 do
  begin
   if (strcmp(selGroupName, groupNames[i])) = (0) then
   begin
    selGroup := i;
    i := NUM_GROUPS;
   end;
  end;
  if ((selGroup) = (-(1))) and (strcmp(GROUP_ALL, selGroupName)) then
  begin
   sprintf(str, 'ERR: group name '%s' invalid', selGroupName);
   PrintMessage(str);
   Exit;
  end;
  AddDevices(selGroup, filtText);
  g_free(selGroupName);
  onDevSel_Changed(NULL, NULL);
end;

function IOchanged(widget: ^TControl; window: ^TControl): Pointer;
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
  if (DeviceDetected) <> (1) then
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
  for i := 0 to ((SizeOf(ioButtons)) div (SizeOf(ioButtons[0]))) - 1 do
  begin
   if gtk_toggle_button_get_active(ioButtons[i].r_0) then
   begin
   end
   else
    if gtk_toggle_button_get_active(ioButtons[i].r_1) then
    begin
     if (i) < (8) then
      latb := latb or (1) shl (i)
     else
      if (i) = (8) then
       latac := latac or $80
      else
       if (i) = (9) then
        latac := latac or $40
       else
        if (i) = (10) then
         latac := latac or $20
        else
         if (i) = (11) then
          latac := latac or $10
         else
          if (i) = (12) then
           latac := latac or $08;
    end
    else
     if gtk_toggle_button_get_active(ioButtons[i].r_I) then
     begin
      if (i) < (8) then
       trisb := trisb or (1) shl (i)
      else
       if (i) = (8) then
        trisc := trisc or $80
       else
        if (i) = (9) then
         trisc := trisc or $40
        else
         if (i) = (10) then
          trisa := trisa or $20
         else
          if (i) = (11) then
           trisa := trisa or $10
          else
           if (i) = (12) then
            trisa := trisa or $8;
     end;
  end;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $81;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $82;
  bufferU[Inc(j)] := $F1;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $92;
  bufferU[Inc(j)] := trisa;
  bufferU[Inc(j)] := $F1;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $93;
  bufferU[Inc(j)] := trisb;
  bufferU[Inc(j)] := $F1;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $94;
  bufferU[Inc(j)] := trisc;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := latb;
  bufferU[Inc(j)] := latac;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  z := 0;
  while ((z) < ((64) - (3))) and ((bufferI[z]) <> ($F0)) do
  begin
   Inc(z);
  end;
  port := bufferI[(z) + (3)];
  gtk_label_set_text(ioButtons[10].e_I, IfThen((port) and ($20), '1', '0'));
  gtk_label_set_text(ioButtons[11].e_I, IfThen((port) and ($10), '1', '0'));
  gtk_label_set_text(ioButtons[12].e_I, IfThen((port) and ($8), '1', '0'));
  z := 4;
  while ((z) < ((64) - (3))) and ((bufferI[z]) <> ($F0)) do
  begin
   Inc(z);
  end;
  port := bufferI[(z) + (3)];
  for i := 0 to (8) - 1 do
  begin
   gtk_label_set_text(ioButtons[i].e_I, IfThen((port) and ((1) shl (i)), '1', '0'));
  end;
  z := 4;
  while ((z) < ((64) - (3))) and ((bufferI[z]) <> ($F0)) do
  begin
   Inc(z);
  end;
  port := bufferI[(z) + (3)];
  gtk_label_set_text(ioButtons[8].e_I, IfThen((port) and ($80), '1', '0'));
  gtk_label_set_text(ioButtons[9].e_I, IfThen((port) and ($40), '1', '0'));
  z := 4;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($0C)) do
  begin
   Inc(z);
  end;
  vpp := ((((((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) div (1024.0)) * (5)) * (34)) div (12);
  sprintf(str, 'VPP=%.2fV', vpp);
  gtk_statusbar_push(status_bar, statusID, str);
  Exit;
end;

function IOactive(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (gtk_toggle_button_get_active(b_io_active)) and (not (icdTimer)) then
  begin
   IOTimer := g_timeout_add(100, IOchanged, NULL);
  end
  else
   if IOTimer then
   begin
    g_source_remove(IOTimer);
   end;
end;

function VPPVDDactive(widget: ^TControl; window: ^TControl): Pointer;
var
  j: Integer;
  vdd_vpp: Integer;
  str: array[0..16-1] of Char;
begin
  if (DeviceDetected) <> (1) then
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
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := vdd_vpp;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
end;

function DCDCactive(widget: ^TControl; window: ^TControl): Pointer;
var
  j: Integer;
  vreg: Integer;
  str: array[0..16-1] of Char;
  voltage: Double;
  j: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if gtk_toggle_button_get_active(DCDC_ON) then
  begin
   j := 0;
   vreg := 0;
   voltage := gtk_range_get_value(GTK_RANGE(DCDC_voltage));
   vreg := (voltage) * (10.0);
   sprintf(str, 'DCDC %.1fV', voltage);
   gtk_statusbar_push(status_bar, statusID, str);
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $0D;
   bufferU[Inc(j)] := vreg;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end
  else
  begin
   j := 0;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end;
end;

function HexConvert(widget: ^TControl; window: ^TControl): Pointer;
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
  strncpy(hex, gtk_entry_get_text(GTK_ENTRY(Hex_entry)), SizeOf(hex));
  if (strlen(hex)) > (0) then
  begin
   if ((hex[0]) = (#58)) and ((strlen(hex)) > (8)) then
   begin
    length := htoi((hex) + (1), 2);
    address := htoi((hex) + (3), 4);
    if (strlen(hex)) < ((11) + ((length) * (2))) then
     gtk_entry_set_text(GTK_ENTRY(Hex_data), '__line too short')
    else
    begin
     i := 1;
     while (i) <= (((length) * (2)) + (9)) do
     begin
      sum := sum + htoi((hex) + (i), 2);
      Inc(i, 2);
     end;
     if ((sum) and ($ff)) <> (0) then
     begin
      sprintf(str, '__checksum error, expected 0x%02X', ((-(sum)) + (htoi(((hex) + (9)) + ((length) * (2)), 2))) and ($FF));
      gtk_entry_set_text(GTK_ENTRY(Hex_data), str);
     end
     else
     begin
      case htoi((hex) + (7), 2) of
       0:
       begin
        sprintf(str, 'address: 0x%04X ', address);
        if (i) and (length) then
         strcat(str, 'data: 0x');
        for i := 0 to (length) - 1 do
        begin
         sprintf(s2, '%02X', htoi(((hex) + (9)) + ((i) * (2)), 2));
         strcat(str, s2);
        end;
        gtk_entry_set_text(GTK_ENTRY(Hex_data), str);
       end;
       4:
       begin
        if (strlen(hex)) > (14) then
        begin
         sprintf(str, 'extended linear address = %04X', htoi((hex) + (9), 4));
         gtk_entry_set_text(GTK_ENTRY(Hex_data), str);
        end;
       end;
       else
       begin
        gtk_entry_set_text(GTK_ENTRY(Hex_data), '__unknown record type');
       end;
      end;
     end;
    end;
   end
   else
    gtk_entry_set_text(GTK_ENTRY(Hex_data), '__invalid line');
  end
  else
   gtk_entry_set_text(GTK_ENTRY(Hex_entry), '');
end;

function DataToHexConvert(widget: ^TControl; window: ^TControl): Pointer;
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
  i := sscanf(gtk_entry_get_text(GTK_ENTRY(Address_entry)), '%x', @(address));
  if (i) <> (1) then
   address := 0;
  strncpy(hex, gtk_entry_get_text(GTK_ENTRY(Data_entry)), SizeOf(hex));
  length := strlen(hex);
  length := length and $FF;
  if (length) > (0) then
  begin
   sprintf(str, ':--%04X00', (address) and ($FFFF));
   i := 0;
   while ((i) + (1)) < (length) do
   begin
    x := htoi((hex) + (i), 2);
    sum := sum + x;
    sprintf(s2, '%02X', x);
    strcat(str, s2);
    Inc(i, 2);
   end;
   sprintf(s2, '%02X', (i) div (2));
   str[1] := s2[0];
   str[2] := s2[1];
   x := sum;
   sum := sum + (((i) div (2)) + ((address) and ($ff))) + (((address) shr (8)) and ($ff));
   sprintf(s2, '%02X', (-(sum)) and ($FF));
   strcat(str, s2);
   gtk_entry_set_text(GTK_ENTRY(Hex_data2), str);
  end;
end;

function HexSave(widget: ^TControl; window: ^TControl): Pointer;
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
  f: ^TextFile;
begin
  if (strlen(gtk_entry_get_text(GTK_ENTRY(Hex_data2)))) < (11) then
   Exit;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fsave], window, GTK_FILE_CHOOSER_ACTION_SAVE, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_SAVE], GTK_RESPONSE_ACCEPT, NULL);
  if cur_path then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  gtk_file_chooser_set_do_overwrite_confirmation(dialog, TRUE_);
  if (gtk_dialog_run(GTK_DIALOG(dialog))) = (GTK_RESPONSE_ACCEPT) then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if cur_path then
    free(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   f := fopen(filename, 'w');
   if f then
   begin
    fprintf(f, gtk_entry_get_text(GTK_ENTRY(Hex_data2)));
    fclose(f);
   end;
   g_free(filename);
  end;
  gtk_widget_destroy(GTK_WIDGET(dialog));
end;

function Stop(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  if (DeviceDetected) <> (1) then
   Exit;
  if ((progress) = (1)) and ((RWstop) = (0)) then
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
  dialog: ^TControl;
begin
  dialog := gtk_message_dialog_new(window, GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_INFO, GTK_BUTTONS_OK, msg);
  gtk_window_set_title(dialog, ' ');
  gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
end;

function Connect(widget: ^TControl; window: ^TControl): Pointer;
var
  // (no local variables detected)
begin
  vid := htoi(gtk_entry_get_text(GTK_ENTRY(VID_entry)), 4);
  pid := htoi(gtk_entry_get_text(GTK_ENTRY(PID_entry)), 4);
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
  if (nbyte) < (0) then
   nbyte := 0;
  if (nbyte) > (60) then
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
  strncpy(tokbuf, gtk_entry_get_text(GTK_ENTRY(I2CDataSend)), SizeOf(tokbuf));
  tok := strtok(tokbuf, ' ');
  while (tok) and ((i) < (128)) do
  begin
   if sscanf(tok, '%x', @(x)) then
   begin
    tmpbuf[i] := x;
    Inc(i);
   end;
   tok := strtok(NULL, ' ');
  end;
  while (i) < (128) do
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
  if (nbyte) < (0) then
   nbyte := 0;
  if (nbyte) > (57) then
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
  strncpy(tokbuf, gtk_entry_get_text(GTK_ENTRY(I2CDataSend)), SizeOf(tokbuf));
  tok := strtok(tokbuf, ' ');
  while (tok) and ((i) < (128)) do
  begin
   if sscanf(tok, '%x', @(x)) then
   begin
    tmpbuf[i] := x;
    Inc(i);
   end;
   tok := strtok(NULL, ' ');
  end;
  while (i) < (128) do
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
  if (DeviceDetected) <> (1) then
   Exit;
  gtk_statusbar_push(status_bar, statusID, '');
  saveLog := gtk_toggle_button_get_active(b_log);
  i := 0;
  strncpy(tokbuf, gtk_entry_get_text(GTK_ENTRY(commandSend)), SizeOf(tokbuf));
  tok := strtok(tokbuf, ' ');
  while (tok) and ((i) < (64)) do
  begin
   if sscanf(tok, '%x', @(x)) then
   begin
    bufferU[i] := x;
    Inc(i);
   end;
   tok := strtok(NULL, ' ');
  end;
  while (i) < (64) do
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
   if (((i) mod (32)) = (31)) and ((i) <> ((64) - (1))) then
    strcat(tokbuf, '' + NL + '    ');
  end;
  strcat(tokbuf, ' ]' + NL + '<[');
  for i := 0 to (64) - 1 do
  begin
   sprintf(str, ' %02X', bufferI[i]);
   strcat(tokbuf, str);
   if (((i) mod (32)) = (31)) and ((i) <> ((64) - (1))) then
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
  aux := malloc((((sizeEE) div (16)) + (1)) * ((16) + ((16) * (5))));
  aux[0] := 0;
  PrintMessage(strings[S_EEMem]);
  max := IfThen((sizeEE) > (7000), 7000, sizeEE);
  i := 0;
  while (i) < (max) do
  begin
   valid := 0;
   j := i;
   while ((j) < ((i) + (16))) and ((j) < (sizeEE)) do
   begin
    sprintf(t, '%02X ', memEE[j]);
    strcat(s, t);
    sprintf(t, '%c', IfThen((isprint(memEE[j])) and ((memEE[j]) < ($FF)), memEE[j], #46));
    g := g_locale_to_utf8(t, -(1), NULL, NULL, NULL);
    if g then
     strcat(v, g);
    g_free(g);
    if (memEE[j]) < ($ff) then
     valid := 1;
    Inc(j);
   end;
   if valid then
   begin
    sprintf(t, '%04X: %s %s' + #13 + '' + NL + '', i, s, v);
    strcat(aux, t);
    empty := 0;
    Inc(lines);
    if (lines) > (500) then
    begin
     strcat(aux, '(...)' + #13 + '' + NL + '');
     i := (max) - ((16) * (2));
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
   if (sizeEE) > (max) then
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
  vreg := (V) * (10.0);
  if (saveLog) and (logfile) then
   fprintf(logfile, 'StartHVReg(%.2f)' + NL + '', V);
  if (V) = (-(1)) then
  begin
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $04;
   PacketIO(5);
   msDelay(40);
   Exit(-(1));
  end;
  t0 := GetTickCount(); t := GetTickCount();
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $0D;
  bufferU[Inc(j)] := vreg;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  msDelay(20);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($0C)) do
  begin
   Inc(z);
  end;
  v := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  if (v) = (0) then
  begin
   PrintMessage(strings[S_lowUsbV]);
   Exit(0);
  end;
  j := 0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  while (((v) < ((((vreg) div (10.0)) - (1)) * ((((12.0) div (34)) * (1024)) div (5)))) or ((v) > ((((vreg) div (10.0)) + (1)) * ((((12.0) div (34)) * (1024)) div (5))))) and ((t) < ((t0) + (1500))) do
  begin
   PacketIO(5);
   msDelay(20);
   z := 0;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($0C)) do
   begin
    Inc(z);
   end;
   v := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   if (HwID) = (3) then
    v := v shr 2;
   t := GetTickCount();
  end;
  if (v) > ((((vreg) div (10.0)) + (1)) * ((((12.0) div (34)) * (1024)) div (5))) then
  begin
   PrintMessage(strings[S_HiVPP]);
   Exit(0);
  end
  else
   if (v) < ((((vreg) div (10.0)) - (1)) * ((((12.0) div (34)) * (1024)) div (5))) then
   begin
    PrintMessage(strings[S_LowVPP]);
    Exit(0);
   end
   else
    if (v) = (0) then
    begin
     PrintMessage(strings[S_lowUsbV]);
     Exit(0);
    end
    else
    begin
     sprintf(str, strings[S_reg], (t) - (t0), (v) div ((((12.0) div (34)) * (1024)) div (5)));
     PrintMessage(str);
     if (saveLog) and (logfile) then
      fprintf(logfile, strings[S_reg], (t) - (t0), (v) div ((((12.0) div (34)) * (1024)) div (5)));
     Exit(vreg);
    end;
end;

procedure ProgID;
var
  j: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  j := 0;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  while ((j) < ((64) - (7))) and ((bufferI[j]) <> ($01)) do
  begin
   Inc(j);
  end;
  sprintf(str, strings[S_progver], bufferI[(j) + (1)], bufferI[(j) + (2)], bufferI[(j) + (3)]);
  PrintMessage(str);
  FWVersion := (((bufferI[(j) + (1)]) shl (16)) + ((bufferI[(j) + (2)]) shl (8))) + (bufferI[(j) + (3)]);
  sprintf(str, strings[S_progid], bufferI[(j) + (4)], bufferI[(j) + (5)], bufferI[(j) + (6)]);
  PrintMessage(str);
  HwID := bufferI[(j) + (6)];
  if (HwID) = (1) then
   PrintMessage(' (18F2550)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else
   if (HwID) = (2) then
    PrintMessage(' (18F2450)' + #13 + '' + NL + '' + #13 + '' + NL + '')
   else
    if (HwID) = (3) then
     PrintMessage(' (18F2458/2553)' + #13 + '' + NL + '' + #13 + '' + NL + '')
    else
     if (HwID) = (4) then
      PrintMessage(' (18F25K50)' + #13 + '' + NL + '' + #13 + '' + NL + '')
     else
      if (HwID) = (5) then
       PrintMessage(' (18F25K50 all-in-one variant)' + #13 + '' + NL + '' + #13 + '' + NL + '')
      else
       PrintMessage(' (?)' + #13 + '' + NL + '' + #13 + '' + NL + '');
  gtk_toggle_button_set_active(b_V33check, IfThen((HwID) = (5), TRUE_, FALSE_));
  gtk_widget_set_visible(GTK_WIDGET(b_V33check), IfThen((HwID) = (5), FALSE_, TRUE_));
end;

function CheckV33Regulator: Integer;
var
  i: Integer;
  j: Integer;
begin
  j := 0;
  if skipV33check then
   Exit(1);
  bufferU[Inc(j)] := $F1;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $93;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $81;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $81;
  bufferU[Inc(j)] := $F1;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $93;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  while ((j) < ((64) - (3))) and ((bufferI[j]) <> ($F0)) do
  begin
   Inc(j);
  end;
  i := (bufferI[(j) + (3)]) and ($2);
  j := 3;
  while ((j) < ((64) - (3))) and ((bufferI[j]) <> ($F0)) do
  begin
   Inc(j);
  end;
  Exit(IfThen(((i) + ((bufferI[(j) + (3)]) and ($2))) = (2), 1, 0));
end;

function CheckS1: Integer;
var
  i: Integer;
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $0F;
  if (HwID) = (5) then
  begin
   bufferU[Inc(j)] := $80;
  end
  else
  begin
   bufferU[Inc(j)] := $84;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  while ((j) < ((64) - (3))) and ((bufferI[j]) <> ($F0)) do
  begin
   Inc(j);
  end;
  if (HwID) = (5) then
  begin
   i := (bufferI[(j) + (3)]) and ($80);
   Exit(IfThen(i, 1, 0));
  end
  else
  begin
   i := (bufferI[(j) + (3)]) and ($8);
   Exit(IfThen(i, 0, 1));
  end;
end;

function TestHw(widget: ^TControl; parent: ^TForm): Pointer;
var
  str: array[0..256-1] of Char;
  j: Integer;
  j: Integer;
  i: Integer;
  x: Integer;
  r: Integer;
begin
  if (DeviceDetected) <> (1) then
   Exit;
  StartHVReg(13);
  j := 0;
  MsgBox(strings[I_TestHW]);
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=5V' + NL + ' VPPU=13V' + NL + ' PGD(RB5)=0V' + NL + ' PGC(RB6)=0V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $15;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=5V' + NL + ' VPPU=0V' + NL + ' PGD(RB5)=5V' + NL + ' PGC(RB6)=5V' + NL + ' PGM(RB7)=5V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=0V' + NL + ' VPPU=13V' + NL + ' PGD(RB5)=5V' + NL + ' PGC(RB6)=0V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=0V' + NL + ' VPPU=0V' + NL + ' PGD(RB5)=0V' + NL + ' PGC(RB6)=5V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  if (FWVersion) >= ($900) then
  begin
   j := 0;
   strcpy(str, '0000000000000');
   PrintMessage('IO test' + NL + 'RC|RA|--RB--|' + NL + '');
   for i := 0 to (13) - 1 do
   begin
    x := (1) shl (i);
    j := 0;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $45;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $32;
    bufferU[Inc(j)] := (x) and ($FF);
    bufferU[Inc(j)] := ((x) shr (5)) and ($FF);
    bufferU[Inc(j)] := $46;
    bufferU[Inc(j)] := $47;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    j := 0;
    while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
    begin
     Inc(j);
    end;
    r := bufferI[(j) + (1)];
    j := 2;
    while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($47)) do
    begin
     Inc(j);
    end;
    r := r + ((bufferI[(j) + (1)]) and ($F8)) shl (5);
    for j := 0 to (13) - 1 do
    begin
     str[(12) - (j)] := IfThen((x) and ((1) shl (j)), #49, #48);
    end;
    PrintMessage(str);
    sprintf(str, ' (%s)' + NL + '', IfThen((r) = (x), 'OK', strings[S_ErrSing]));
    PrintMessage(str);
   end;
  end;
end;

function msDelay(delay: Double): Pointer;
var
  x: LongInt;
begin
  x := (delay) * (1000.0);
  usleep(IfThen((x) > (0), x, 0));
end;

function GetTickCount: TDWORD;
var
  now: Ttimeb;
begin
  ftime(@(now));
  Exit(((now.time) * (1000)) + (now.millitm));
end;

function PacketIO(delay: Double): Pointer;
var
  delay0: Integer;
  ts: Ttimespec;
  start: Tuint64_t;
  stop: Tuint64_t;
  set_: Tfd_set;
  timeout: Ttimeval;
  rv: Integer;
  i: Integer;
  res: Integer;
begin
  if (saveLog) and (logfile) then
   fprintf(logfile, 'PacketIO(%.2f)' + NL + '', delay);
  delay0 := delay;
  FD_ZERO(@(set_));
  FD_SET(fd, @(set_));
  timeout.tv_sec := 0;
  timeout.tv_usec := (50) * (1000);
  clock_gettime(0, @(ts));
  start := (ts.tv_nsec) div (1000);
  delay := delay - (50) - (10);
  if (delay) < (0) then
   delay := 0;
  res := write_(fd, bufferU, 64);
  if (res) < (0) then
  begin
   printf('Error: %d' + NL + '', errno);
   perror('write');
  end;
  usleep((delay) * (1000.0));
  rv := select((fd) + (1), @(set_), NULL, NULL, @(timeout));
  if (rv) = (-(1)) then
  begin
   PrintMessage(strings[S_ErrSing]);
   if (saveLog) and (logfile) then
    fprintf(logfile, strings[S_ErrSing]);
   Exit;
  end
  else
   if (rv) = (0) then
   begin
    PrintMessage(strings[S_comTimeout]);
    if (saveLog) and (logfile) then
     fprintf(logfile, strings[S_comTimeout]);
    Exit;
   end;
  res := read_(fd, bufferI, 64);
  if (res) < (0) then
  begin
   perror('read');
  end;
  clock_gettime(0, @(ts));
  stop := (ts.tv_nsec) div (1000);
  if (saveLog) and (logfile) then
  begin
   WriteLogIO();
   fprintf(logfile, 'T=%.2f ms (%+.2f ms)' + NL + '', ((stop) - (start)) div (1000.0), (((stop) - (start)) div (1000.0)) - (delay0));
   if (bufferU[0]) <> (bufferI[0]) then
    fprintf(logfile, 'Cannot read correct packet!!' + NL + '');
  end;
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
  p: PChar;
  builder: ^TObject;
  cssProvider: ^TObject;
  w: ^TControl;
  loadCoffBtn: ^TControl;
  text: array[0..16-1] of Char;
  info: TDevInfo;
begin
  fname := 0;
  lang := '';
  langfile := 0;
  homedir := g_get_home_dir();
  if homedir then
  begin
   config_dir := g_build_path(G_DIR_SEPARATOR_S, homedir, '.opgui', NULL);
   if not (g_file_test(config_dir, G_FILE_TEST_IS_DIR)) then
    mkdir(config_dir, 0755);
   fname := g_build_path(G_DIR_SEPARATOR_S, config_dir, 'opgui.ini', NULL);
   f := fopen(fname, 'r');
   if f then
   begin
    while fgets(line, 256, f) do
    begin
     if (sscanf(line, 'device %s', temp)) > (0) then
      strcpy(dev, temp)
     else
      if (sscanf(line, 'vid %X', @(X))) > (0) then
       vid := X
      else
       if (sscanf(line, 'pid %X', @(X))) > (0) then
        pid := X
       else
        sscanf(line, 'maxerr %d', @(max_err));
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
  gtk_init(@(argc), @(argv));
  opterr := 0;
  option_index := 0;
  help := 0;
  command := 0;
  long_options := [['?', no_argument, @(help), 1], ['h', no_argument, @(help), 1], ['help', no_argument, @(help), 1], ['c', no_argument, @(command), 1], ['command', no_argument, @(command), 1], ['lang', required_argument, 0, #108], ['langfile', no_argument, @(langfile), 1], [0, 0, 0, 0]];
  while ((j := getopt_long_only(argc, argv, '', long_options, @(option_index)))) <> (-(1)) do
  begin
   if (j) = (#108) then
   begin
    strncpy(lang, optarg, (SizeOf(lang)) - (1));
   end;
  end;
  j := 0;
  i := optind;
  while ((i) < (argc)) and ((i) < (128)) do
  begin
   sscanf(argv[i], '%x', @(tmpbuf[j]));
   Inc(i);
   Inc(j);
  end;
  while (j) < (128) do
  begin
   tmpbuf[j] := 0;
   Inc(j);
  end;
  strinit();
  langid := 0;
  i := 0;
  if lang[0] then
  begin
   if ((lang[0]) = (#105)) and ((lang[1]) = (#116)) then
   begin
    strings := strings_it;
    i := 1;
   end
   else
    if ((lang[0]) = (#101)) and ((lang[1]) = (#110)) then
    begin
     strings := strings_en;
     i := 1;
    end
    else
     i := strfind(lang, 'languages.rc');
  end;
  if (i) = (0) then
  begin
   langid := getenv('LANG');
   if langid then
   begin
    if ((langid[0]) = (#105)) and ((langid[1]) = (#116)) then
     strings := strings_it
    else
     if ((langid[0]) = (#101)) and ((langid[1]) = (#110)) then
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
     bufferU[i] := tmpbuf[(i) - (1)];
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
  builder := NULL;
  builder := gtk_builder_new_from_resource('/res/opgui.glade');
  window := GTK_WIDGET(gtk_builder_get_object(builder, 'window'));
  g_signal_connect(window, 'destroy', Xclose, NULL);
  gtk_window_set_icon(window, gdk_pixbuf_new_from_resource('/res/sys.png', NULL));
  cssProvider := gtk_css_provider_new();
  gtk_css_provider_load_from_resource(cssProvider, '/res/style.css');
  gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(cssProvider), GTK_STYLE_PROVIDER_PRIORITY_USER);
  w := NULL;
  sprintf(str, 'opgui v%s', 'unknown');
  gtk_window_set_title(window, str);
  notebook := GTK_WIDGET(gtk_builder_get_object(builder, 'NOTEBOOK'));
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'OPEN_T'));
  gtk_widget_set_tooltip_text(w, strings[I_Fopen]);
  g_signal_connect(w, 'clicked', Fopen, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'SAVE_T'));
  gtk_widget_set_tooltip_text(w, strings[I_Fsave]);
  g_signal_connect(w, 'clicked', Fsave, NULL);
  readBtn := GTK_WIDGET(gtk_builder_get_object(builder, 'READ_T'));
  gtk_widget_set_tooltip_text(readBtn, strings[I_DevR]);
  g_signal_connect(readBtn, 'clicked', DevRead, NULL);
  writeBtn := GTK_WIDGET(gtk_builder_get_object(builder, 'WRITE_T'));
  gtk_widget_set_tooltip_text(writeBtn, strings[I_DevW]);
  g_signal_connect(writeBtn, 'clicked', DevWrite, NULL);
  stopBtn := GTK_WIDGET(gtk_builder_get_object(builder, 'STOP_T'));
  gtk_widget_set_tooltip_text(stopBtn, strings[I_ICD_STOP]);
  g_signal_connect(stopBtn, 'clicked', Stop, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'CONNECT_T'));
  gtk_widget_set_tooltip_text(w, strings[I_CONN]);
  g_signal_connect(w, 'clicked', Connect, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'INFO_T'));
  gtk_widget_set_tooltip_text(w, strings[I_Info]);
  g_signal_connect(w, 'clicked', info, NULL);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'DATA_T_L')), strings[I_Data]);
  data := GTK_WIDGET(gtk_builder_get_object(builder, 'DATA'));
  dataBuf := gtk_text_view_get_buffer(data);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'DEVICE_L')), strings[I_Dev]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'TYPE_L')), strings[I_TypeFilt]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'DEV_SRC_L')), strings[I_Filt]);
  devTypeCombo := GTK_WIDGET(gtk_builder_get_object(builder, 'TYPE_C'));
  g_signal_connect(devTypeCombo, 'changed', FilterDevType, NULL);
  devFiltEntry := GTK_WIDGET(gtk_builder_get_object(builder, 'DEV_SRC_E'));
  g_signal_connect(devFiltEntry, 'changed', FilterDevType, NULL);
  devTree := GTK_WIDGET(gtk_builder_get_object(builder, 'DEV_TREE'));
  gtk_tree_view_insert_column_with_attributes(devTree, -(1), strings[I_Dev], gtk_cell_renderer_text_new(), 'text', DEVICE_NAME_COLUMN, NULL);
  gtk_tree_view_insert_column_with_attributes(devTree, -(1), strings[I_Type], gtk_cell_renderer_text_new(), 'text', DEVICE_GROUP_COLUMN, NULL);
  gtk_tree_view_column_set_fixed_width(gtk_tree_view_get_column(devTree, 0), 125);
  gtk_tree_view_column_set_fixed_width(gtk_tree_view_get_column(devTree, 1), 125);
  devFrame := GTK_WIDGET(gtk_builder_get_object(builder, 'DEVICE_NAME'));
  devinfo := GTK_WIDGET(gtk_builder_get_object(builder, 'DEV_INFO'));
  EEPROM_RW := GTK_WIDGET(gtk_builder_get_object(builder, 'EE_RW'));
  gtk_button_set_label(EEPROM_RW, strings[I_EE]);
  ReadReserved := GTK_WIDGET(gtk_builder_get_object(builder, 'RES_READ'));
  gtk_button_set_label(ReadReserved, strings[I_ReadRes]);
  Write_ID_BKCal := GTK_WIDGET(gtk_builder_get_object(builder, 'PROG_ID'));
  gtk_button_set_label(Write_ID_BKCal, strings[I_ID_BKo_W]);
  WriteCalib12 := GTK_WIDGET(gtk_builder_get_object(builder, 'PROG_CAL12'));
  gtk_button_set_label(WriteCalib12, strings[I_CalW]);
  UseSaflock := GTK_WIDGET(gtk_builder_get_object(builder, 'USE_SAFLOCK'));
  gtk_button_set_label(UseSaflock, strings[I_Saflock]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'OSCCAL_L')), strings[I_OSCW]);
  UseOSCCAL := GTK_WIDGET(gtk_builder_get_object(builder, 'OSCCAL'));
  gtk_button_set_label(UseOSCCAL, strings[I_OSC]);
  UseBKOSCCAL := GTK_WIDGET(gtk_builder_get_object(builder, 'BKOSCCAL'));
  gtk_button_set_label(UseBKOSCCAL, strings[I_BKOSC]);
  UseFileCal := GTK_WIDGET(gtk_builder_get_object(builder, 'FILECAL'));
  gtk_button_set_label(UseFileCal, strings[I_OSCF]);
  ICD_check := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD'));
  gtk_button_set_label(ICD_check, strings[I_ICD_ENABLE]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_ADDR_L')), strings[I_ICD_ADDRESS]);
  ICD_addr_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_ADDR'));
  ConfigForce := GTK_WIDGET(gtk_builder_get_object(builder, 'FORCE_CW'));
  gtk_button_set_label(ConfigForce, strings[I_PIC_FORCECW]);
  CW1_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW1'));
  CW2_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW2'));
  CW3_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW3'));
  CW4_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW4'));
  CW5_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW5'));
  CW6_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW6'));
  CW7_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'CW7'));
  AVR_FuseLow := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEL'));
  AVR_FuseLowWrite := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEL_C'));
  gtk_button_set_label(AVR_FuseLowWrite, strings[I_AT_FUSE]);
  AVR_FuseHigh := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEH'));
  AVR_FuseHighWrite := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEH_C'));
  gtk_button_set_label(AVR_FuseHighWrite, strings[I_AT_FUSEH]);
  AVR_FuseExt := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEX'));
  AVR_FuseExtWrite := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEX_C'));
  gtk_button_set_label(AVR_FuseExtWrite, strings[I_AT_FUSEX]);
  AVR_Lock := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSELCK'));
  AVR_LockWrite := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSELCK_C'));
  gtk_button_set_label(AVR_LockWrite, strings[I_AT_LOCK]);
  b_WfuseLF := GTK_WIDGET(gtk_builder_get_object(builder, 'FUSEL_W3K'));
  gtk_button_set_label(b_WfuseLF, strings[I_AT_FUSELF]);
  g_signal_connect(b_WfuseLF, 'clicked', WriteATfuseLowLF, window);
  devFramePIC := GTK_WIDGET(gtk_builder_get_object(builder, 'PIC_OPT'));
  devFrameAVR := GTK_WIDGET(gtk_builder_get_object(builder, 'AVR_OPT'));
  devFrameConfigW := GTK_WIDGET(gtk_builder_get_object(builder, 'CW_OPT'));
  devFrameICD := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_OPT'));
  devFrameOsc := GTK_WIDGET(gtk_builder_get_object(builder, 'OSC_OPT'));
  devPIC_CW1 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW1_OPT'));
  devPIC_CW2 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW2_OPT'));
  devPIC_CW3 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW3_OPT'));
  devPIC_CW4 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW4_OPT'));
  devPIC_CW5 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW5_OPT'));
  devPIC_CW6 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW6_OPT'));
  devPIC_CW7 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW7_OPT'));
  devPIC_CW8 := GTK_WIDGET(gtk_builder_get_object(builder, 'CW8_OPT'));
  gtk_widget_hide(GTK_WIDGET(devFrameAVR));
  gtk_widget_hide(GTK_WIDGET(devFramePIC));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'OPTIONS_L')), strings[I_Opt]);
  VID_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'VID'));
  PID_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'PID'));
  Errors_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'MAXERR'));
  b_connect := GTK_WIDGET(gtk_builder_get_object(builder, 'CONNECT'));
  gtk_button_set_label(b_connect, strings[I_CONN]);
  g_signal_connect(b_connect, 'clicked', Connect, window);
  b_testhw := GTK_WIDGET(gtk_builder_get_object(builder, 'TEST'));
  gtk_button_set_label(b_testhw, strings[I_TestHWB]);
  g_signal_connect(b_testhw, 'clicked', TestHw, window);
  b_log := GTK_WIDGET(gtk_builder_get_object(builder, 'LOG'));
  gtk_button_set_label(b_log, strings[I_LOG]);
  b_V33check := GTK_WIDGET(gtk_builder_get_object(builder, '3VCHECK'));
  gtk_button_set_label(b_V33check, strings[I_CK_V33]);
  b_WaitS1 := GTK_WIDGET(gtk_builder_get_object(builder, 'S1'));
  gtk_button_set_label(b_WaitS1, strings[I_WAITS1]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'MAXERR_L')), strings[I_MAXERR]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'I2CMODE')), strings[I_I2CMode]);
  I2C8bit := GTK_WIDGET(gtk_builder_get_object(builder, 'I2C8BIT'));
  I2C16bit := GTK_WIDGET(gtk_builder_get_object(builder, 'I2C16BIT'));
  SPI00 := GTK_WIDGET(gtk_builder_get_object(builder, 'SPI00'));
  SPI01 := GTK_WIDGET(gtk_builder_get_object(builder, 'SPI01'));
  SPI10 := GTK_WIDGET(gtk_builder_get_object(builder, 'SPI10'));
  SPI11 := GTK_WIDGET(gtk_builder_get_object(builder, 'SPI11'));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'DATASEND_L')), strings[I_I2CDATAOUT]);
  I2CDataSend := GTK_WIDGET(gtk_builder_get_object(builder, 'DATASEND'));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'DATATR_L')), strings[I_I2CDATATR]);
  I2CDataReceive := GTK_WIDGET(gtk_builder_get_object(builder, 'DATATR'));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'NBYTE_L')), strings[I_I2C_NB]);
  I2CNbyte := GTK_WIDGET(gtk_builder_get_object(builder, 'NBYTE_S'));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'SPEED_L')), strings[I_Speed]);
  I2CSpeed := GTK_WIDGET(gtk_builder_get_object(builder, 'SPEED_C'));
  I2CSendBtn := GTK_WIDGET(gtk_builder_get_object(builder, 'SEND_B'));
  gtk_button_set_label(I2CSendBtn, strings[I_I2CSend]);
  g_signal_connect(I2CSendBtn, 'clicked', I2cspiS, window);
  I2CReceiveBtn := GTK_WIDGET(gtk_builder_get_object(builder, 'RECEIVE_B'));
  gtk_button_set_label(I2CReceiveBtn, strings[I_I2CReceive]);
  g_signal_connect(I2CReceiveBtn, 'clicked', I2cspiR, window);
  loadCoffBtn := GTK_WIDGET(gtk_builder_get_object(builder, 'LOADCOFF_B'));
  gtk_tool_button_set_label(loadCoffBtn, strings[I_LOAD_COFF]);
  g_signal_connect(loadCoffBtn, 'clicked', loadCoff, window);
  g_signal_connect(GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_TAB')), 'key_press_event', icd_key_event, NULL);
  gtk_menu_item_set_label(GTK_MENU_ITEM(gtk_builder_get_object(builder, 'OPTIONS_M')), strings[I_Opt]);
  icdMenuPC := GTK_WIDGET(gtk_builder_get_object(builder, 'PCOUNT_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuPC), strings[I_SHOW_PC]);
  icdMenuSTAT := GTK_WIDGET(gtk_builder_get_object(builder, 'STATUS_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuSTAT), strings[I_SHOW_STATUS]);
  icdMenuBank0 := GTK_WIDGET(gtk_builder_get_object(builder, 'BANK0_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank0), strings[I_SHOW_BANK0]);
  icdMenuBank1 := GTK_WIDGET(gtk_builder_get_object(builder, 'BANK1_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank1), strings[I_SHOW_BANK1]);
  icdMenuBank2 := GTK_WIDGET(gtk_builder_get_object(builder, 'BANK2_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank2), strings[I_SHOW_BANK2]);
  icdMenuBank3 := GTK_WIDGET(gtk_builder_get_object(builder, 'BANK3_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank3), strings[I_SHOW_BANK3]);
  icdMenuEE := GTK_WIDGET(gtk_builder_get_object(builder, 'EE_M'));
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuEE), strings[I_SHOW_EE]);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_RUN'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_RUN]);
  g_signal_connect(w, 'clicked', icdRun, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_HALT'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_HALT]);
  g_signal_connect(w, 'clicked', icdHalt, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_STEP'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_STEP]);
  g_signal_connect(w, 'clicked', icdStep, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_STEPOVER'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_STEPOVER]);
  g_signal_connect(w, 'clicked', icdStepOver, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_STOP'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_STOP]);
  g_signal_connect(w, 'clicked', icdStop, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_REFRESH'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_REFRESH]);
  g_signal_connect(w, 'clicked', icdRefresh, NULL);
  icdCommand := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_CMD_E'));
  gtk_widget_set_tooltip_text(icdCommand, strings[I_ICD_CMD]);
  g_signal_connect(icdCommand, 'key_press_event', icdCommand_key_event, NULL);
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_HELP'));
  gtk_widget_set_tooltip_text(w, strings[I_ICD_HELP]);
  g_signal_connect(w, 'clicked', ICDHelp, NULL);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_SOURCE_L')), strings[I_ICD_SOURCE]);
  sourceTxt := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_SOURCE'));
  sourceBuf := gtk_text_view_get_buffer(sourceTxt);
  g_signal_connect(sourceTxt, 'button_press_event', source_mouse_event, NULL);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_STAT_L')), strings[I_ICD_STATUS]);
  statusTxt := GTK_WIDGET(gtk_builder_get_object(builder, 'ICD_STATUS'));
  statusBuf := gtk_text_view_get_buffer(statusTxt);
  g_signal_connect(statusTxt, 'button_press_event', icdStatus_mouse_event, NULL);
  b_io_active := GTK_WIDGET(gtk_builder_get_object(builder, 'IOEN'));
  gtk_button_set_label(b_io_active, strings[I_IO_Enable]);
  g_signal_connect(b_io_active, 'toggled', IOactive, NULL);
  ioButtons[0].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB0_0'));
  ioButtons[0].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB0_1'));
  ioButtons[0].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB0_I'));
  ioButtons[0].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB0_L'));
  ioButtons[1].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB1_0'));
  ioButtons[1].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB1_1'));
  ioButtons[1].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB1_I'));
  ioButtons[1].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB1_L'));
  ioButtons[2].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB2_0'));
  ioButtons[2].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB2_1'));
  ioButtons[2].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB2_I'));
  ioButtons[2].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB2_L'));
  ioButtons[3].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB3_0'));
  ioButtons[3].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB3_1'));
  ioButtons[3].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB3_I'));
  ioButtons[3].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB3_L'));
  ioButtons[4].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB4_0'));
  ioButtons[4].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB4_1'));
  ioButtons[4].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB4_I'));
  ioButtons[4].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB4_L'));
  ioButtons[5].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB5_0'));
  ioButtons[5].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB5_1'));
  ioButtons[5].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB5_I'));
  ioButtons[5].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB5_L'));
  ioButtons[6].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB6_0'));
  ioButtons[6].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB6_1'));
  ioButtons[6].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB6_I'));
  ioButtons[6].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB6_L'));
  ioButtons[7].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB7_0'));
  ioButtons[7].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RB7_1'));
  ioButtons[7].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB7_I'));
  ioButtons[7].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RB7_L'));
  ioButtons[8].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RC7_0'));
  ioButtons[8].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RC7_1'));
  ioButtons[8].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RC7_I'));
  ioButtons[8].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RC7_L'));
  ioButtons[9].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RC6_0'));
  ioButtons[9].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RC6_1'));
  ioButtons[9].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RC6_I'));
  ioButtons[9].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RC6_L'));
  ioButtons[10].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RA5_0'));
  ioButtons[10].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RA5_1'));
  ioButtons[10].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RA5_I'));
  ioButtons[10].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RA5_L'));
  ioButtons[11].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RA4_0'));
  ioButtons[11].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RA4_1'));
  ioButtons[11].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RA4_I'));
  ioButtons[11].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RA4_L'));
  ioButtons[12].r_0 := GTK_WIDGET(gtk_builder_get_object(builder, 'RA3_0'));
  ioButtons[12].r_1 := GTK_WIDGET(gtk_builder_get_object(builder, 'RA3_1'));
  ioButtons[12].r_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RA3_I'));
  ioButtons[12].e_I := GTK_WIDGET(gtk_builder_get_object(builder, 'RA3_L'));
  for ii := 0 to ((SizeOf(ioButtons)) div (SizeOf(ioButtons[0]))) - 1 do
  begin
   gtk_toggle_button_set_active(ioButtons[ii].r_I, TRUE_);
   g_signal_connect(ioButtons[ii].r_0, 'toggled', IOchanged, NULL);
   g_signal_connect(ioButtons[ii].r_1, 'toggled', IOchanged, NULL);
   g_signal_connect(ioButtons[ii].r_I, 'toggled', IOchanged, NULL);
  end;
  VDD_ON := GTK_WIDGET(gtk_builder_get_object(builder, 'VDDUEN'));
  VPP_ON := GTK_WIDGET(gtk_builder_get_object(builder, 'VPPUEN'));
  DCDC_ON := GTK_WIDGET(gtk_builder_get_object(builder, 'DCDCEN'));
  DCDC_voltage := GTK_WIDGET(gtk_builder_get_object(builder, 'DCDC_S'));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'CMD_L')), strings[I_IO_Commands]);
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'CMDSEND_L')), strings[I_I2CDATAOUT]);
  commandSend := GTK_WIDGET(gtk_builder_get_object(builder, 'CMDSEND'));
  gtk_label_set_text(GTK_WIDGET(gtk_builder_get_object(builder, 'CMDTR_L')), strings[I_I2CDATATR]);
  commandTransfer := GTK_WIDGET(gtk_builder_get_object(builder, 'CMDTR'));
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'CMDTR_B'));
  gtk_button_set_label(w, strings[I_I2CSend]);
  g_signal_connect(w, 'clicked', CommandIO, window);
  g_signal_connect(VDD_ON, 'toggled', VPPVDDactive, NULL);
  g_signal_connect(VPP_ON, 'toggled', VPPVDDactive, NULL);
  g_signal_connect(DCDC_ON, 'toggled', DCDCactive, NULL);
  g_signal_connect(DCDC_voltage, 'value_changed', DCDCactive, NULL);
  Hex_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'HEXIN'));
  Hex_data := GTK_WIDGET(gtk_builder_get_object(builder, 'DATAOUT'));
  Address_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'ADDRIN'));
  Data_entry := GTK_WIDGET(gtk_builder_get_object(builder, 'DATAIN'));
  Hex_data2 := GTK_WIDGET(gtk_builder_get_object(builder, 'HEXOUT'));
  w := GTK_WIDGET(gtk_builder_get_object(builder, 'HEXSAVE'));
  gtk_button_set_label(w, strings[I_Fsave]);
  g_signal_connect(w, 'clicked', HexSave, window);
  g_signal_connect(Hex_entry, 'changed', HexConvert, NULL);
  g_signal_connect(Address_entry, 'changed', DataToHexConvert, NULL);
  g_signal_connect(Data_entry, 'changed', DataToHexConvert, NULL);
  status_bar := GTK_WIDGET(gtk_builder_get_object(builder, 'STATUS_B'));
  statusID := gtk_statusbar_get_context_id(status_bar, 'ID');
  gtk_widget_show_all(window);
  sprintf(text, '%04X', vid);
  gtk_entry_set_text(GTK_ENTRY(VID_entry), text);
  sprintf(text, '%04X', pid);
  gtk_entry_set_text(GTK_ENTRY(PID_entry), text);
  sprintf(text, '%d', max_err);
  gtk_entry_set_text(GTK_ENTRY(Errors_entry), text);
  sizeW := $8400;
  memCODE_W := malloc((sizeW) * (SizeOf(WORD)));
  initVar();
  for i := 0 to ($8400) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  strncpy(LogFileName, strings[S_LogFile], SizeOf(LogFileName));
  gtk_combo_box_text_append(GTK_COMBO_BOX_TEXT(devTypeCombo), GROUP_ALL, GROUP_ALL);
  for i := 0 to (NUM_GROUPS) - 1 do
  begin
   gtk_combo_box_text_append(GTK_COMBO_BOX_TEXT(devTypeCombo), groupNames[i], groupNames[i]);
  end;
  if (strlen(dev)) > (0) then
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
  if (((strcmp(dev_ini, dev)) or ((vid_ini) <> (vid))) or ((pid_ini) <> (pid))) or ((max_err_ini) <> (max_err)) then
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
  device_info: Thidraw_devinfo;
  i: Integer;
begin
  MyDeviceDetected := FALSE_;
  i := -(1);
  if (path[0]) = (0) then
  begin
   if ((fd := open('/dev/openprogrammer', (2) or (O_NONBLOCK)))) > (0) then
   begin
    sprintf(path, '/dev/openprogrammer');
    ioctl(fd, $80084803, @(device_info));
    if ((device_info.vendor) = (vid)) and ((device_info.product) = (pid)) then
     i := 0
    else
    begin
     close(fd);
     i := -(1);
    end;
   end;
   if i then
   begin
    for i := 0 to (16) - 1 do
    begin
     sprintf(path, '/dev/hidraw%d', i);
     if ((fd := open(path, (2) or (O_NONBLOCK)))) > (0) then
     begin
      ioctl(fd, $80084803, @(device_info));
      if ((device_info.vendor) = (vid)) and ((device_info.product) = (pid)) then
       Break
      else
       close(fd);
     end;
    end;
   end;
   if (i) = (16) then
   begin
    PrintMessage(strings[S_noprog]);
    path[0] := 0;
    Exit(0);
   end;
  end
  else
  begin
   if ((fd := open(path, (2) or (O_NONBLOCK)))) < (0) then
   begin
    sprintf(str, strings[S_DevPermission], path);
    PrintMessage(str);
    Exit(0);
   end;
   ioctl(fd, $80084803, @(device_info));
   if ((device_info.vendor) <> (vid)) or ((device_info.product) <> (pid)) then
   begin
    PrintMessage(strings[S_noprog]);
    Exit(0);
   end;
  end;
  printf(strings[S_progDev], path);
  Exit(1);
  if (MyDeviceDetected) = (FALSE_) then
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
