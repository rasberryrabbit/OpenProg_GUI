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
  progavr;

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

var
  hex: array[0..256-1] of Char;
  str: array[0..256-1] of Char;
  s2: array[0..32-1] of Char;
  i: Integer;
  address: Integer;
  length: Integer;
  sum: Integer;
  x: Integer;

  ioButtons: array[0..13-1] of Tio_btn;

// --- function declarations ---
procedure Connect(widget: ^TControl; vid: ^TGtkWidget window);
void I2cspiR();
void I2cspiS();
void ProgID();
void PrintMessageI2C(char msg);
void ShowContext();
int FindDevice(int; widget: ^T"MEMORY"
};
char GROUP_ALL="";


	int fd = -1;

	struct hiddev_report_info rep_info_i,rep_info_u;
	struct hiddev_usage_ref_multi ref_multi_i,ref_multi_u;

	char path[512]="";
	unsigned char bufferU[128],bufferI[128];

	unsigned char bufferU0[128],bufferI0[128];
	unsigned char bufferU,bufferI;
	DWORD NumberOfBytesRead,BytesWritten;
	ULONG Result;
	HANDLE WriteHandle,ReadHandle;
	OVERLAPPED HIDOverlapped;
	HANDLE hEventObject;



gint delete_event( GtkWidget; event: ^TGdkEvent; data: Pointer);
procedure info(widget: ^TControl; window: ^TControl);
procedure PrintMessage(msg: PChar);
procedure PrintMessageI2C(msg: PChar);
procedure PrintMessageCMD(msg: PChar);
procedure getOptions;
procedure GetSelectedDevice;
procedure Fopen(widget: ^TControl; window: ^TControl);
procedure Fsave(widget: ^TControl; window: ^TControl);
procedure selectDataTab;
procedure DevWrite(widget: ^TControl; window: ^TControl);
procedure DevRead(widget: ^TControl; window: ^TControl);
procedure WriteATfuseLowLF(widget: ^TControl; window: ^TControl);
procedure onDevSel_Changed(widget: ^TControl; window: ^TControl);
function selectDev_ForeachFunc(model: ^TGtkTreeModel; path: ^TGtkTreePath; iter: ^TGtkTreeIter; devNameToSelect: PChar): Boolean;
function sortIterCompareFunc(model: ^TGtkTreeModel; a: ^TGtkTreeIter; b: ^TGtkTreeIter; userdata: Pointer): Integer;
function strupr(s: PChar): PChar;
procedure AddDevices(groupFilter: Tenum group_t; textFilter: PChar);
procedure FilterDevType(widget: ^TControl; window: ^TControl);
procedure IOchanged(widget: ^TControl; window: ^TControl);
procedure VPPVDDactive(widget: ^TControl; window: ^TControl);
procedure DCDCactive(widget: ^TControl; window: ^TControl);
procedure HexConvert(widget: ^TControl; window: ^TControl);
procedure HexSave(widget: ^TControl; window: ^TControl);
procedure Stop(widget: ^TControl; window: ^TControl);
procedure Xclose;
procedure MsgBox(msg: PChar);
procedure Connect(widget: ^TControl; window: ^TControl);
procedure I2cspiR;
procedure I2cspiS;
procedure CommandIO;
procedure DisplayEE;
function StartHVReg(V: Double): Integer;
procedure ProgID;
function CheckS1: Integer;
procedure TestHw(widget: ^TControl; parent: ^TForm);
procedure msDelay(delay: Double);
function GetTickCount: DWORD;
procedure PacketIO(delay: Double);
function main(argc: Integer; argv: PChar): Integer;
function FindDevice(vid: Integer; pid: Integer): Integer;

implementation

procedure Connect(widget: ^TControl; vid: ^TGtkWidget window);
void I2cspiR();
void I2cspiS();
void ProgID();
void PrintMessageI2C(char msg);
void ShowContext();
int FindDevice(int; widget: ^T"MEMORY"
};
char GROUP_ALL="";


	int fd = -1;

	struct hiddev_report_info rep_info_i,rep_info_u;
	struct hiddev_usage_ref_multi ref_multi_i,ref_multi_u;

	char path[512]="";
	unsigned char bufferU[128],bufferI[128];

	unsigned char bufferU0[128],bufferI0[128];
	unsigned char bufferU,bufferI;
	DWORD NumberOfBytesRead,BytesWritten;
	ULONG Result;
	HANDLE WriteHandle,ReadHandle;
	OVERLAPPED HIDOverlapped;
	HANDLE hEventObject;



gint delete_event( GtkWidget; event: ^TGdkEvent; data: Pointer);
var
  // (no local variables detected)
begin
  Application.Terminate;
  Exit;
end;

procedure info(widget: ^TControl; window: ^TControl);
var
  license: PChar;
begin
  license := 'This program is free software; you can redistribute it and/or' + NL + '"     "modify it under the terms of the GNU Library General Public License as' + NL + '"     "published by the Free Software Foundation; either version 2 of the' + NL + '"     "License, or (at your option) any later version.' + NL + '"     "' + NL + '"     "This program is distributed in the hope that it will be useful,' + NL + '"     "but WITHOUT ANY WARRANTY; without even the implied warranty of' + NL + '"     "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU' + NL + '"     "Library General Public License for more details.' + NL + '"     "' + NL + '"     "You should have received a copy of the GNU Library General Public' + NL + '"     "License along with the Gnome Library; see the file COPYING.LIB.  If not,' + NL + '"     "write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,' + NL + '"     "Boston, MA 02111-1307, USA.' + NL + '';
  gtk_show_about_dialog(nil, 'comments', 'A graphical interface for the Open Programmer', 'copyright', 'Copyright (C) Alberto Maccioni 2009-2025' + NL + '' + NL + '" 		"This program is free software; you can ' + NL + '" 		"redistribute it and/or modify it under ' + NL + '" 		"the terms of the GNU General Public License ' + NL + '" 		"as published by the Free Software Foundation;' + NL + '" 		"either version 2 of the License, or ' + NL + '" 		"(at your option) any later version.', 'license', license, 'logo', gdk_pixbuf_new_from_resource('/res/sys.png', nil), 'program-name', 'OPGUI', 'version', VERSION, 'website', 'www.openprog.altervista.org', 'wrap-license', True, 'title', 'Info about OPGUI', nil);
end;

procedure PrintMessage(msg: PChar);
var
  iter: TGtkTextIter;
  iter2: TGtkTextIter;
  l: Integer;
begin
  if (cmdline) <> 0 then
   Exit;
  dataBuf.SelEnd := Length(dataBuf.Text);
  dataBuf.SelText := @( iter );
  dataBuf.SelStart := 0;
  dataBuf.SelEnd := Length(dataBuf.Text);
  l := dataBuf.Lines.Count;
  if l > MAXLINES+10 then
  begin
   gtk_text_iter_set_line(@( iter ), l-MAXLINES);
   dataBuf.Clear;
  end;
  while (Application.ProcessMessages; False) <> 0 do
  begin
  end;
  dataBuf.SelEnd := Length(dataBuf.Text);
  GTK_TEXT_VIEW(data).SelStart := Length(GTK_TEXT_VIEW(data).Text);
end;

procedure PrintMessageI2C(msg: PChar);
var
  iter: TGtkTextIter;
  dataBuf: ^TMemo;
begin
  dataBuf := GTK_TEXT_VIEW(I2CDataReceive);
  dataBuf.Lines.Text := msg;
  dataBuf.SelEnd := Length(dataBuf.Text);
  GTK_TEXT_VIEW(I2CDataReceive).SelStart := Length(GTK_TEXT_VIEW(I2CDataReceive).Text);
  while (Application.ProcessMessages; False) <> 0 do
  begin
  end;
end;

procedure PrintMessageCMD(msg: PChar);
var
  iter: TGtkTextIter;
  dataBuf: ^TMemo;
begin
  dataBuf := GTK_TEXT_VIEW(commandTransfer);
  dataBuf.Lines.Text := msg;
  dataBuf.SelEnd := Length(dataBuf.Text);
  GTK_TEXT_VIEW(commandTransfer).SelStart := Length(GTK_TEXT_VIEW(commandTransfer).Text);
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
  vid := htoi(GTK_ENTRY(VID_entry).Text, 4);
  pid := htoi(GTK_ENTRY(PID_entry).Text, 4);
  saveLog := GTK_TOGGLE_BUTTON(b_log).Checked;
  ee := IfThen(GTK_TOGGLE_BUTTON(EEPROM_RW).Checked, $FFFF, 0);
  programID := GTK_TOGGLE_BUTTON(Write_ID_BKCal).Checked;
  max_err := StrToInt(GTK_ENTRY(Errors_entry).Text);
  load_calibword := GTK_TOGGLE_BUTTON(WriteCalib12).Checked;
  useSAFLOCK_flag := GTK_TOGGLE_BUTTON(UseSaflock).Checked;
  load_osccal :=  not (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(UseOSCCAL)));
  load_BKosccal := GTK_TOGGLE_BUTTON(UseBKOSCCAL).Checked;
  ICDenable := GTK_TOGGLE_BUTTON(ICD_check).Checked;
  readRes := GTK_TOGGLE_BUTTON(ReadReserved).Checked;
  skipV33check := GTK_TOGGLE_BUTTON(b_V33check).Checked;
  waitS1 := GTK_TOGGLE_BUTTON(b_WaitS1).Checked;
  i := sscanf(GTK_ENTRY(ICD_addr_entry).Text, '%x', @( ICDaddr ));
  if (i <> 1) or (ICDaddr < 0) or (ICDaddr > $FFFF) then
   ICDaddr := $1FF0;
  str := 0;
  if (str) <> 0 then
   strncpy(dev, str, sizeof(dev)-1);
  g_free(str);
  AVRlock := $100 ; AVRfuse_x := $100 ; AVRfuse_h := $100 ; AVRfuse := $100;
  if (GTK_TOGGLE_BUTTON(AVR_FuseLowWrite).Checked) <> 0 then
  begin
   i := sscanf(GTK_ENTRY(AVR_FuseLow).Text, '%x', @( AVRfuse ));
   if (i <> 1) or (AVRfuse < 0) or (AVRfuse > $FF) then
    AVRfuse := $100;
  end;
  if (GTK_TOGGLE_BUTTON(AVR_FuseHighWrite).Checked) <> 0 then
  begin
   i := sscanf(GTK_ENTRY(AVR_FuseHigh).Text, '%x', @( AVRfuse_h ));
   if (i <> 1) or (AVRfuse_h < 0) or (AVRfuse_h > $FF) then
    AVRfuse_h := $100;
  end;
  if (GTK_TOGGLE_BUTTON(AVR_FuseExtWrite).Checked) <> 0 then
  begin
   i := sscanf(GTK_ENTRY(AVR_FuseExt).Text, '%x', @( AVRfuse_x ));
   if (i <> 1) or (AVRfuse_x < 0) or (AVRfuse_x > $FF) then
    AVRfuse_x := $100;
  end;
  if (GTK_TOGGLE_BUTTON(AVR_LockWrite).Checked) <> 0 then
  begin
   i := sscanf(GTK_ENTRY(AVR_Lock).Text, '%x', @( AVRlock ));
   if (i <> 1) or (AVRlock < 0) or (AVRlock > $FF) then
    AVRlock := $100;
  end;
  str := malloc(128);
  if (GTK_TOGGLE_BUTTON(ConfigForce).Checked) <> 0 then
  begin
   cw7 := $10000 ; cw6 := $10000 ; cw5 := $10000 ; cw4 := $10000 ; cw3 := $10000 ; cw2 := $10000 ; cw1 := $10000;
   i := sscanf(GTK_ENTRY(CW1_entry).Text, '%x', @( cw1 ));
   i := sscanf(GTK_ENTRY(CW2_entry).Text, '%x', @( cw2 ));
   i := sscanf(GTK_ENTRY(CW3_entry).Text, '%x', @( cw3 ));
   i := sscanf(GTK_ENTRY(CW4_entry).Text, '%x', @( cw4 ));
   i := sscanf(GTK_ENTRY(CW5_entry).Text, '%x', @( cw5 ));
   i := sscanf(GTK_ENTRY(CW6_entry).Text, '%x', @( cw6 ));
   i := sscanf(GTK_ENTRY(CW7_entry).Text, '%x', @( cw7 ));
   if devType = PIC16 then
   begin
    if (( not strncmp(dev,'16F1',4) or not strncmp(dev,'12F1',4))) and (sizeW > $8008) then
    begin
     if cw1 <= $3FFF then
     begin
      memCODE_W[$8007] := cw1;
      PrintMessage3(strings[S_ForceConfigWx], 1, $8007, cw1);
     end;
     if cw2 <= $3FFF then
     begin
      memCODE_W[$8008] := cw2;
      PrintMessage3(strings[S_ForceConfigWx], 2, $8008, cw2);
     end;
    end
    else
    begin
     if (cw1 <= $3FFF) and (sizeW > $2007) then
     begin
      memCODE_W[$2007] := cw1;
      PrintMessage3(strings[S_ForceConfigWx], 1, $2007, cw1);
     end;
     if (cw2 <= $3FFF) and (sizeW > $2008) then
     begin
      memCODE_W[$2008] := cw2;
      printf('2' + NL + '');
      PrintMessage3(strings[S_ForceConfigWx], 2, $2008, cw2);
     end;
    end;
   end
   else if devType = PIC12 then
   begin
    if (cw1 <= $FFF) and (sizeW > $FFF) then
    begin
     memCODE_W[$FFF] := cw1;
     PrintMessage3(strings[S_ForceConfigWx], 1, $FFF, cw1);
    end;
   end
   else if devType = PIC18 then
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
     PrintMessage2(strings[S_ConfigWordH], i+1, memCONFIG[i*2+1]);
     PrintMessage2(strings[S_ConfigWordL], i+1, memCONFIG[i*2]);
    end;
   end;
  end;
  FreeMem(str);
end;

procedure GetSelectedDevice;
var
  tmpModel: ^TGtkTreeModel;
  tmpIter: TGtkTreeIter;
  devName: PChar;
begin
  if  not GTK_IS_TREE_SELECTION(devSel) then
  begin
   Exit;
  end;
  if (devSel.Selected <> nil) <> 0 then
  begin
   gtk_tree_model_get(tmpModel, @( tmpIter ), DEVICE_NAME_COLUMN, @( devName ), -1);
   strcpy(dev, devName);
   GTK_WIDGET(readBtn).Enabled := True;
   GTK_WIDGET(writeBtn).Enabled := True;
   g_free(devName);
  end
  else
  begin
   dev[0] := '\0';
   GTK_WIDGET(readBtn).Enabled := False;
   GTK_WIDGET(writeBtn).Enabled := False;
  end;
end;

procedure Fopen(widget: ^TControl; window: ^TControl);
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
  dialog2: ^TGtkFileChooser;
  filename2: PChar;
begin
  GetSelectedDevice();
  if (progress) <> 0 then
   Exit;
  progress := 1;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fopen], GTK_WINDOW(window), GTK_FILE_CHOOSER_ACTION_OPEN, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_OPEN], GTK_RESPONSE_ACCEPT, nil);
  if (cur_path) <> 0 then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  if gtk_dialog_run(GTK_DIALOG(dialog)) = GTK_RESPONSE_ACCEPT then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if (cur_path) <> 0 then
    FreeMem(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   Load(devType, filename);
   g_free(filename);
   if devType = AVR then
   begin
    dialog2 := gtk_file_chooser_dialog_new(strings[S_openEEfile], GTK_WINDOW(window), GTK_FILE_CHOOSER_ACTION_OPEN, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_OPEN], GTK_RESPONSE_ACCEPT, nil);
    if  not cur_pathEE then
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog);
    if (cur_pathEE) <> 0 then
     gtk_file_chooser_set_current_folder(dialog2, cur_pathEE);
    if gtk_dialog_run(GTK_DIALOG(dialog2)) = GTK_RESPONSE_ACCEPT then
    begin
     filename2 := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog2));
     if (cur_pathEE) <> 0 then
      FreeMem(cur_pathEE);
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog2);
     LoadEE(devType, filename2);
     g_free(filename2);
    end;
    GTK_WIDGET(dialog2).Free;
   end;
  end;
  GTK_WIDGET(dialog).Free;
  progress := 0;
end;

procedure Fsave(widget: ^TControl; window: ^TControl);
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
  dialog2: ^TGtkFileChooser;
  filename2: PChar;
begin
  if (progress) <> 0 then
   Exit;
  progress := 1;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fsave], GTK_WINDOW(window), GTK_FILE_CHOOSER_ACTION_SAVE, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_SAVE], GTK_RESPONSE_ACCEPT, nil);
  if (cur_path) <> 0 then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  gtk_file_chooser_set_do_overwrite_confirmation(dialog, True);
  if gtk_dialog_run(GTK_DIALOG(dialog)) = GTK_RESPONSE_ACCEPT then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if (cur_path) <> 0 then
    FreeMem(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   Save(devType, filename);
   PrintMessage1(strings[S_FileSaved], filename);
   g_free(filename);
   if devType = AVR then
   begin
    dialog2 := gtk_file_chooser_dialog_new(strings[S_saveEEfile], GTK_WINDOW(window), GTK_FILE_CHOOSER_ACTION_SAVE, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_SAVE], GTK_RESPONSE_ACCEPT, nil);
    if  not cur_pathEE then
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog);
    if (cur_pathEE) <> 0 then
     gtk_file_chooser_set_current_folder(dialog2, cur_pathEE);
    gtk_file_chooser_set_do_overwrite_confirmation(dialog2, True);
    if gtk_dialog_run(GTK_DIALOG(dialog2)) = GTK_RESPONSE_ACCEPT then
    begin
     filename2 := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog2));
     if (cur_pathEE) <> 0 then
      FreeMem(cur_pathEE);
     cur_pathEE := gtk_file_chooser_get_current_folder(dialog2);
     SaveEE(devType, filename2);
     PrintMessage1(strings[S_FileSaved], filename2);
     g_free(filename2);
    end;
    GTK_WIDGET(dialog2).Free;
   end;
  end;
  GTK_WIDGET(dialog).Free;
  progress := 0;
end;

procedure selectDataTab;
var
  // (no local variables detected)
begin
  GTK_NOTEBOOK(notebook).PageIndex := 0;
end;

procedure DevWrite(widget: ^TControl; window: ^TControl);
var
  i: Integer;
  S1: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  selectDataTab();
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  RWstop := 0;
  getOptions();
  if (not waitingS1) and (waitS1) then
  begin
   waitingS1 := 1;
   S1 := 0;
   PrintMessage(strings[I_PRESSS1]);
   i := 0;
   while (not S1) and (waitS1) and (waitingS1) do
   begin
    S1 := CheckS1();
    msDelay(50);
    PrintMessage('.');
    if i mod 64 = 63 then
     PrintMessage(strings[S_NL]);
    while (Application.ProcessMessages; False) <> 0 do
    begin
    end;
    msDelay(50);
    Inc(i);
   end;
   if (not progress) and (S1) then
   begin
    stopBtn.Enabled := True;
    progress := 1;
    Write(dev, ee);
    progress := 0;
    stopBtn.Enabled := False;
   end;
   waitingS1 := 0;
  end
  else if (waitingS1) <> 0 then
   waitingS1 := 0
  else if  not progress then
  begin
   stopBtn.Enabled := True;
   progress := 1;
   Write(dev, ee);
   progress := 0;
   stopBtn.Enabled := False;
  end;
end;

procedure DevRead(widget: ^TControl; window: ^TControl);
var
  i: Integer;
  S1: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  selectDataTab();
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  getOptions();
  RWstop := 0;
  if (not waitingS1) and (waitS1) then
  begin
   waitingS1 := 1;
   S1 := 0;
   PrintMessage(strings[I_PRESSS1]);
   i := 0;
   while (not S1) and (waitS1) and (waitingS1) do
   begin
    S1 := CheckS1();
    msDelay(50);
    PrintMessage('.');
    if i mod 64 = 63 then
     PrintMessage(strings[S_NL]);
    while (Application.ProcessMessages; False) <> 0 do
    begin
    end;
    msDelay(50);
    Inc(i);
   end;
   if (not progress) and (S1) then
   begin
    stopBtn.Enabled := True;
    progress := 1;
    Read(dev, ee, readRes);
    progress := 0;
    stopBtn.Enabled := False;
   end;
   waitingS1 := 0;
  end
  else if (waitingS1) <> 0 then
   waitingS1 := 0
  else if  not progress then
  begin
   stopBtn.Enabled := True;
   progress := 1;
   Read(dev, ee, readRes);
   progress := 0;
   stopBtn.Enabled := False;
  end;
end;

procedure WriteATfuseLowLF(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  if DeviceDetected <> 1 then
   Exit;
  if (progress) <> 0 then
   Exit;
  getOptions();
  if (GTK_TOGGLE_BUTTON(AVR_FuseLowWrite).Checked) <> 0 then
  begin
   progress := 1;
   if AVRfuse < $100 then
    WriteATfuseSlow(AVRfuse);
   progress := 0;
  end;
end;

procedure onDevSel_Changed(widget: ^TControl; window: ^TControl);
var
  info: Tstruct DevInfo;
begin
  GetSelectedDevice();
  if Length(dev) = 0 then
   Exit;
  info := GetDevInfo(dev);
  sprintf(str, '<b>%s: %s</b>', strings[I_Dev], dev);
  GTK_LABEL(devFrame).Caption := str;
  devType := info.family;
  GTK_LABEL(devinfo).Caption := info.features;
  if (devType = PIC12) or (devType = PIC16) or (devType = PIC18) or (devType = PIC24) then
  begin
   GTK_WIDGET(devFramePIC).Visible := True;
   GTK_WIDGET(devFrameAVR).Visible := False;
   GTK_WIDGET(EEPROM_RW).Visible := True;
  end
  else if devType = AVR then
  begin
   GTK_WIDGET(devFramePIC).Visible := False;
   GTK_WIDGET(devFrameAVR).Visible := True;
   GTK_WIDGET(EEPROM_RW).Visible := True;
  end
  else
  begin
   GTK_WIDGET(devFramePIC).Visible := False;
   GTK_WIDGET(devFrameAVR).Visible := False;
   GTK_WIDGET(EEPROM_RW).Visible := False;
  end;
  if devType = PIC16 then
   GTK_WIDGET(devFrameICD).Visible := True
  else
   GTK_WIDGET(devFrameICD).Visible := False;
  if (devType = PIC12) or (devType = PIC16) then
   GTK_WIDGET(devFrameOsc).Visible := True
  else
   GTK_WIDGET(devFrameOsc).Visible := False;
  if (devType = PIC12) or (devType = PIC16) or (devType = PIC18) then
   GTK_WIDGET(Write_ID_BKCal).Visible := True
  else
   GTK_WIDGET(Write_ID_BKCal).Visible := False;
  if devType = PIC16 then
   GTK_WIDGET(WriteCalib12).Visible := True
  else
   GTK_WIDGET(WriteCalib12).Visible := False;
  if (devType = PIC12) or (devType = PIC16) or (devType = PIC18) then
  begin
   GTK_WIDGET(devFrameConfigW).Visible := True;
   GTK_WIDGET(devPIC_CW2).Visible := False;
   GTK_WIDGET(devPIC_CW3).Visible := False;
   GTK_WIDGET(devPIC_CW4).Visible := False;
   GTK_WIDGET(devPIC_CW5).Visible := False;
   GTK_WIDGET(devPIC_CW6).Visible := False;
   GTK_WIDGET(devPIC_CW7).Visible := False;
   GTK_WIDGET(devPIC_CW8).Visible := False;
   if devType = PIC16 then
   begin
    GTK_WIDGET(devPIC_CW2).Visible := True;
   end
   else if devType = PIC18 then
   begin
    GTK_WIDGET(devPIC_CW2).Visible := True;
    GTK_WIDGET(devPIC_CW3).Visible := True;
    GTK_WIDGET(devPIC_CW4).Visible := True;
    GTK_WIDGET(devPIC_CW5).Visible := True;
    GTK_WIDGET(devPIC_CW6).Visible := True;
    GTK_WIDGET(devPIC_CW7).Visible := True;
    GTK_WIDGET(devPIC_CW8).Visible := True;
    GTK_WIDGET(devPIC_CW8).Visible := True;
   end;
  end
  else
  begin
   GTK_WIDGET(devFrameConfigW).Visible := False;
   GTK_TOGGLE_BUTTON(ConfigForce).Checked := False;
  end;
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
end;

function selectDev_ForeachFunc(model: ^TGtkTreeModel; path: ^TGtkTreePath; iter: ^TGtkTreeIter; devNameToSelect: PChar): Boolean;
var
  thisEntryDevName: PChar;
  matched: Integer;
begin
  // return value of gtk_tree_model_get() ignored
  gtk_tree_model_get(model, iter, DEVICE_NAME_COLUMN, @( thisEntryDevName ), -1);
  matched := (strcmp(thisEntryDevName, devNameToSelect) = 0);
  if (matched) <> 0 then
   if iter < devSel.Items.Count then devSel.Items[iter].Selected := True;
  // return value of g_free() ignored
  g_free(thisEntryDevName);
  Exit(matched);
end;

function sortIterCompareFunc(model: ^TGtkTreeModel; a: ^TGtkTreeIter; b: ^TGtkTreeIter; userdata: Pointer): Integer;
var
  sortcol: Tenum sort_type_t;
  ret: Integer;
  sortDataType: Tenum sort_data_type_t;
  dataCol: Integer;
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
end;

function strupr(s: PChar): PChar;
var
  p: PChar;
begin
  p := s;
  while (p^) = toupper( *p ) <> 0 do
  begin
  end;
  Exit(s);
end;

procedure AddDevices(groupFilter: Tenum group_t; textFilter: PChar);
var
  i: Integer;
  j: Integer;
  devices: PChar;
  tok: PChar;
  textFilterU: array[0..32-1] of Char;
  info: Tstruct DevInfo;
begin
  if GTK_IS_TREE_SELECTION(devSel) then
   // g_signal_handlers_disconnect_by_func() -> no-op in LCL
  if  not GTK_IS_LIST_STORE(devStore) then
  begin
   devStore := gtk_list_store_new(DEVICE_N_COLUMNS, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING);
   gtk_tree_view_set_model(GTK_TREE_VIEW(devTree), GTK_TREE_MODEL(devStore));
   gtk_tree_sortable_set_sort_func(GTK_TREE_SORTABLE(devStore), SORT_STRING_NAME, sortIterCompareFunc, GINT_TO_POINTER(SORT_STRING_NAME), nil);
   gtk_tree_sortable_set_sort_func(GTK_TREE_SORTABLE(devStore), SORT_STRING_GROUP, sortIterCompareFunc, GINT_TO_POINTER(SORT_STRING_GROUP), nil);
   gtk_tree_view_column_set_sort_column_id(gtk_tree_view_get_column(GTK_TREE_VIEW(devTree), 0), SORT_STRING_NAME);
   gtk_tree_view_column_set_sort_column_id(gtk_tree_view_get_column(GTK_TREE_VIEW(devTree), 1), SORT_STRING_GROUP);
   // g_object_unref() -> no-op in LCL
  end
  else
   gtk_list_store_clear(devStore);
  j := 0;
  devices := 0;
  strupr(strncpy(textFilterU, textFilter, 32));
  for i := 0 to (NDEVLIST) - 1 do
  begin
   if (devices) <> 0 then
    FreeMem(devices);
   devices := malloc(strlen(DEVLIST[i].device)+1);
   strcpy(devices, DEVLIST[i].device);
   populateDevInfo(@( info ), @( (DEVLIST[i]) ));
   while tok do
   begin
    info.group := nameToGroup(tok);
    if (info.group <> -1) and (( not textFilter or strlen(textFilter) = 0 or strstr(strupr(tok), textFilterU))) and (groupFilter = -1 or info.group = groupFilter) then
    begin
     gtk_list_store_insert_with_values(devStore, nil, -1, DEVICE_ID_COLUMN, Inc(j), DEVICE_NAME_COLUMN, tok, DEVICE_GROUP_COLUMN, groupNames[info.group], -1);
    end;
    tok := strtok(nil, ', ' + #9 + '');
   end;
  end;
  if GTK_IS_TREE_SELECTION(devSel) then
  begin
   devSel.ClearSelection;
  end
  else
  begin
   devSel := GTK_TREE_VIEW(devTree).Selected;
   devSel.MultiSelect := (GTK_SELECTION_SINGLE = 2);
  end;
  // g_signal_connect() -> no-op in LCL
  gtk_tree_model_foreach(GTK_TREE_MODEL(devStore), selectDev_ForeachFunc, dev);
end;

procedure FilterDevType(widget: ^TControl; window: ^TControl);
var
  selGroupName: PChar;
  filtText: PChar;
  selGroup: Tenum group_t;
begin
  selGroupName := GTK_COMBO_BOX_TEXT(devTypeCombo).Text;
  filtText := GTK_ENTRY(devFiltEntry).Text;
  selGroup := -1;
  for i := 0 to (NUM_GROUPS) - 1 do
  begin
   if AnsiCompareStr(selGroupName, groupNames[i]) = 0 then
   begin
    selGroup := i;
    i := NUM_GROUPS;
   end;
  end;
  if (selGroup = -1) and (AnsiCompareStr(GROUP_ALL, selGroupName)) then
  begin
   PrintMessage1('ERR: group name '%s' invalid', selGroupName);
   Exit;
  end;
  AddDevices(selGroup, filtText);
  g_free(selGroupName);
  onDevSel_Changed(nil, nil);
end;

procedure IOchanged(widget: ^TControl; window: ^TControl);
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
  if (progress) <> 0 then
   Exit;
  if DeviceDetected <> 1 then
   Exit;
  if  not gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(b_io_active)) then
   Exit;
  j := 0;
  trisa := 1;
  trisb := 0;
  trisc := $30;
  latac := 0;
  latb := 0;
  port := 0;
  str[0] := 0;
  for i := 0 to (sizeof(ioButtons)/sizeof(ioButtons[0])) - 1 do
  begin
   if (GTK_TOGGLE_BUTTON(ioButtons[i].r_0).Checked) <> 0 then
   begin
   end
   else if (GTK_TOGGLE_BUTTON(ioButtons[i].r_1).Checked) <> 0 then
   begin
    if i < 8 then
     latb := latb or 1 shl i
    else if i = 8 then
     latac := latac or $80
    else if i = 9 then
     latac := latac or $40
    else if i = 10 then
     latac := latac or $20
    else if i = 11 then
     latac := latac or $10
    else if i = 12 then
     latac := latac or $08;
   end
   else if (GTK_TOGGLE_BUTTON(ioButtons[i].r_I).Checked) <> 0 then
   begin
    if i < 8 then
     trisb := trisb or 1 shl i
    else if i = 8 then
     trisc := trisc or $80
    else if i = 9 then
     trisc := trisc or $40
    else if i = 10 then
     trisa := trisa or $20
    else if i = 11 then
     trisa := trisa or $10
    else if i = 12 then
     trisa := trisa or $8;
   end;
  end;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := READ_RAM;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $81;
  bufferU[Inc(j)] := READ_RAM;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $82;
  bufferU[Inc(j)] := WRITE_RAM;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $92;
  bufferU[Inc(j)] := trisa;
  bufferU[Inc(j)] := WRITE_RAM;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $93;
  bufferU[Inc(j)] := trisb;
  bufferU[Inc(j)] := WRITE_RAM;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $94;
  bufferU[Inc(j)] := trisc;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := latb;
  bufferU[Inc(j)] := latac;
  bufferU[Inc(j)] := READ_ADC;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  z := 0;
  while (z < DIMBUF-3) and (bufferI[z] <> READ_RAM) do
  begin
   Inc(z);
  end;
  port := bufferI[z+3];
  GTK_LABEL(ioButtons[10].e_I).Caption := IfThen((port and $20), '1', '0');
  GTK_LABEL(ioButtons[11].e_I).Caption := IfThen((port and $10), '1', '0');
  GTK_LABEL(ioButtons[12].e_I).Caption := IfThen((port and $8), '1', '0');
  Inc(z, 4);
  while (z < DIMBUF-3) and (bufferI[z] <> READ_RAM) do
  begin
   Inc(z);
  end;
  port := bufferI[z+3];
  for i := 0 to (8) - 1 do
  begin
   GTK_LABEL(ioButtons[i].e_I).Caption := IfThen((port and (1 shl i)), '1', '0');
  end;
  Inc(z, 4);
  while (z < DIMBUF-3) and (bufferI[z] <> READ_RAM) do
  begin
   Inc(z);
  end;
  port := bufferI[z+3];
  GTK_LABEL(ioButtons[8].e_I).Caption := IfThen((port and $80), '1', '0');
  GTK_LABEL(ioButtons[9].e_I).Caption := IfThen((port and $40), '1', '0');
  Inc(z, 4);
  while (z < DIMBUF-2) and (bufferI[z] <> READ_ADC) do
  begin
   Inc(z);
  end;
  vpp := ((bufferI[z+1] shl 8)+bufferI[z+2])/1024.0*5*34/12;
  sprintf(str, 'VPP=%.2fV', vpp);
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  Exit;
end;

procedure VPPVDDactive(widget: ^TControl; window: ^TControl);
var
  j: Integer;
  vdd_vpp: Integer;
  str: array[0..16-1] of Char;
begin
  if DeviceDetected <> 1 then
   Exit;
  j := 0;
  vdd_vpp := 0;
  str[0] := #0;
  if (GTK_TOGGLE_BUTTON(VPP_ON).Checked) <> 0 then
  begin
   Inc(vdd_vpp, 4);
   strcat(str, 'VPP ');
  end;
  if (GTK_TOGGLE_BUTTON(VDD_ON).Checked) <> 0 then
  begin
   Inc(vdd_vpp, 1);
   strcat(str, 'VDD ');
  end;
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := vdd_vpp;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
end;

procedure DCDCactive(widget: ^TControl; window: ^TControl);
var
  j: Integer;
  vreg: Integer;
  str: array[0..16-1] of Char;
  voltage: Double;
  j: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  if (GTK_TOGGLE_BUTTON(DCDC_ON).Checked) <> 0 then
  begin
   j := 0;
   vreg := 0;
   voltage := GTK_RANGE(DCDC_voltage).Position;
   vreg := voltage*10.0;
   sprintf(str, 'DCDC %.1fV', voltage);
   GTK_STATUSBAR(status_bar).SimpleText := statusID;
   bufferU[Inc(j)] := VREG_EN;
   bufferU[Inc(j)] := SET_VPP;
   bufferU[Inc(j)] := vreg;
   bufferU[Inc(j)] := FLUSH;
   while j < DIMBUF do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end
  else
  begin
   j := 0;
   bufferU[Inc(j)] := VREG_DIS;
   bufferU[Inc(j)] := FLUSH;
   while j < DIMBUF do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end;
end;

procedure HexConvert(widget: ^TControl; window: ^TControl);
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
  strncpy(hex, GTK_ENTRY(Hex_entry).Text, sizeof(hex));
  if Length(hex) > 0 then
  begin
   if (hex[0] = #58) and (Length(hex) > 8) then
   begin
    length := htoi(hex+1, 2);
    address := htoi(hex+3, 4);
    if Length(hex) < 11+length*2 then
     GTK_ENTRY(Hex_data).Text := '__line too short'
    else
    begin
     i := 1;
     while i <= length*2+9 do
     begin
      Inc(sum, htoi(hex+i, 2));
      Inc(i, 2);
     end;
     if (sum and $ff) <> 0 then
     begin
      sprintf(str, '__checksum error, expected 0x%02X', (-sum+htoi(hex+9+length*2,2)) and $FF);
      GTK_ENTRY(Hex_data).Text := str;
     end
     else
     begin
      case htoi(hex+7, 2) of
       0:
       begin
        sprintf(str, 'address: 0x%04X ', address);
        if (i) and (length) then
         strcat(str, 'data: 0x');
        for i := 0 to (length) - 1 do
        begin
         sprintf(s2, '%02X', htoi(hex+9+i*2, 2));
         strcat(str, s2);
        end;
       end;
       4:
       begin
        if Length(hex) > 14 then
        begin
         sprintf(str, 'extended linear address = %04X', htoi(hex+9, 4));
         GTK_ENTRY(Hex_data).Text := str;
        end;
        Break;
       end;
       else
       begin
        GTK_ENTRY(Hex_data).Text := '__unknown record type';
       end;
      end;
     end;
    end;
   end
   else
    GTK_ENTRY(Hex_data).Text := '__invalid line';
  end
  else
   GTK_ENTRY(Hex_entry).Text := '';
end;

procedure HexSave(widget: ^TControl; window: ^TControl);
var
  dialog: ^TGtkFileChooser;
  filename: PChar;
  f: ^TextFile;
begin
  if Length(GTK_ENTRY(Hex_data2).Text) < 11 then
   Exit;
  dialog := gtk_file_chooser_dialog_new(strings[I_Fsave], GTK_WINDOW(window), GTK_FILE_CHOOSER_ACTION_SAVE, strings[I_CANCEL], GTK_RESPONSE_CANCEL, strings[I_SAVE], GTK_RESPONSE_ACCEPT, nil);
  if (cur_path) <> 0 then
   gtk_file_chooser_set_current_folder(dialog, cur_path);
  gtk_file_chooser_set_do_overwrite_confirmation(dialog, True);
  if gtk_dialog_run(GTK_DIALOG(dialog)) = GTK_RESPONSE_ACCEPT then
  begin
   filename := gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
   if (cur_path) <> 0 then
    FreeMem(cur_path);
   cur_path := gtk_file_chooser_get_current_folder(dialog);
   f := fopen(filename, 'w');
   if (f) <> 0 then
   begin
    fprintf(f, GTK_ENTRY(Hex_data2).Text);
    CloseFile(f);
   end;
   g_free(filename);
  end;
  GTK_WIDGET(dialog).Free;
end;

procedure Stop(widget: ^TControl; window: ^TControl);
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
  Application.Terminate;
end;

procedure MsgBox(msg: PChar);
var
  dialog: ^TControl;
begin
  dialog := gtk_message_dialog_new(GTK_WINDOW(window), GTK_DIALOG_DESTROY_WITH_PARENT, GTK_MESSAGE_INFO, GTK_BUTTONS_OK, msg);
  GTK_WINDOW(dialog).Caption := ' ';
  gtk_dialog_run(GTK_DIALOG(dialog));
  dialog.Free;
end;

procedure Connect(widget: ^TControl; window: ^TControl);
var
  // (no local variables detected)
begin
  vid := htoi(GTK_ENTRY(VID_entry).Text, 4);
  pid := htoi(GTK_ENTRY(PID_entry).Text, 4);
  DeviceDetected := FindDevice(vid, pid);
  if  not DeviceDetected then
  begin
   DeviceDetected := FindDevice(new_vid, new_pid);
   if (DeviceDetected) <> 0 then
   begin
    vid := new_vid;
    pid := new_pid;
   end;
  end;
  if  not DeviceDetected then
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
  tmpbuf: array[0..128-1] of Byte;
  i: Integer;
  x: Integer;
begin
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  saveLog := GTK_TOGGLE_BUTTON(b_log).Checked;
  nbyte := GTK_SPIN_BUTTON(I2CNbyte).Value;
  if nbyte < 0 then
   nbyte := 0;
  if nbyte > 60 then
   nbyte := 60;
  mode := 0;
  if (GTK_TOGGLE_BUTTON(I2C16bit).Checked) <> 0 then
   mode := 1;
  if (GTK_TOGGLE_BUTTON(SPI00).Checked) <> 0 then
   mode := 2;
  if (GTK_TOGGLE_BUTTON(SPI01).Checked) <> 0 then
   mode := 3;
  if (GTK_TOGGLE_BUTTON(SPI10).Checked) <> 0 then
   mode := 4;
  if (GTK_TOGGLE_BUTTON(SPI11).Checked) <> 0 then
   mode := 5;
  i := 0;
  strncpy(tokbuf, GTK_ENTRY(I2CDataSend).Text, sizeof(tokbuf));
  while (tok) and (i < 128) do
  begin
   if sscanf(tok, '%x', @( x )) then
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
  I2CReceive(mode, GTK_COMBO_BOX(I2CSpeed).ItemIndex, nbyte, tmpbuf);
end;

procedure I2cspiS;
var
  nbyte: Integer;
  mode: Integer;
  tok: PChar;
  tokbuf: array[0..512-1] of Char;
  tmpbuf: array[0..128-1] of Byte;
  i: Integer;
  x: Integer;
begin
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  saveLog := GTK_TOGGLE_BUTTON(b_log).Checked;
  nbyte := GTK_SPIN_BUTTON(I2CNbyte).Value;
  if nbyte < 0 then
   nbyte := 0;
  if nbyte > 57 then
   nbyte := 57;
  mode := 0;
  if (GTK_TOGGLE_BUTTON(I2C16bit).Checked) <> 0 then
   mode := 1;
  if (GTK_TOGGLE_BUTTON(SPI00).Checked) <> 0 then
   mode := 2;
  if (GTK_TOGGLE_BUTTON(SPI01).Checked) <> 0 then
   mode := 3;
  if (GTK_TOGGLE_BUTTON(SPI10).Checked) <> 0 then
   mode := 4;
  if (GTK_TOGGLE_BUTTON(SPI11).Checked) <> 0 then
   mode := 5;
  i := 0;
  strncpy(tokbuf, GTK_ENTRY(I2CDataSend).Text, sizeof(tokbuf));
  while (tok) and (i < 128) do
  begin
   if sscanf(tok, '%x', @( x )) then
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
  I2CSend(mode, GTK_COMBO_BOX(I2CSpeed).ItemIndex, nbyte, tmpbuf);
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
  GTK_STATUSBAR(status_bar).SimpleText := statusID;
  saveLog := GTK_TOGGLE_BUTTON(b_log).Checked;
  i := 0;
  strncpy(tokbuf, GTK_ENTRY(commandSend).Text, sizeof(tokbuf));
  while (tok) and (i < DIMBUF) do
  begin
   if sscanf(tok, '%x', @( x )) then
   begin
    bufferU[i] := x;
    Inc(i);
   end;
   tok := strtok(nil, ' ');
  end;
  while i < DIMBUF do
  begin
   bufferU[i] := $0;
   Inc(i);
  end;
  PacketIO(150);
  sprintf(tokbuf, '>[');
  for i := 0 to (DIMBUF) - 1 do
  begin
   sprintf(str, ' %02X', bufferU[i]);
   strcat(tokbuf, str);
   if (i mod 32 = 31) and (i <> DIMBUF-1) then
    strcat(tokbuf, '' + NL + '    ');
  end;
  for i := 0 to (DIMBUF) - 1 do
  begin
   sprintf(str, ' %02X', bufferI[i]);
   strcat(tokbuf, str);
   if (i mod 32 = 31) and (i <> DIMBUF-1) then
    strcat(tokbuf, '' + NL + '     ');
  end;
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
  aux := malloc((sizeEE/COL+1)*(16+COL*5));
  aux[0] := 0;
  PrintMessage(strings[S_EEMem]);
  max := IfThen(sizeEE > 7000, 7000, sizeEE);
  i := 0;
  while i < max do
  begin
   valid := 0;
   j := i;
   while (j < i+COL) and (j < sizeEE) do
   begin
    sprintf(t, '%02X ', memEE[j]);
    strcat(s, t);
    sprintf(t, '%c', IfThen((isprint(memEE[j])) and ((memEE[j]<$FF)), memEE[j], #46));
    g := g_locale_to_utf8(t, -1, nil, nil, nil);
    if (g) <> 0 then
     strcat(v, g);
    g_free(g);
    if memEE[j] < $ff then
     valid := 1;
    Inc(j);
   end;
   if (valid) <> 0 then
   begin
    sprintf(t, '%04X: %s %s' + #13 + '' + NL + '', i, s, v);
    strcat(aux, t);
    empty := 0;
    Inc(lines);
    if lines > 500 then
    begin
     strcat(aux, '(...)' + #13 + '' + NL + '');
     i := max-COL*2;
     lines := 490;
    end;
   end;
   s[0] := 0;
   v[0] := 0;
   Inc(i, COL);
  end;
  if (empty) <> 0 then
   PrintMessage(strings[S_Empty])
  else
  begin
   PrintMessage(aux);
   if sizeEE > max then
    PrintMessage('(...)' + #13 + '' + NL + '');
  end;
  FreeMem(aux);
end;

function StartHVReg(V: Double): Integer;
var
  j: Integer;
  z: Integer;
  vreg: Integer;
  t0: DWORD;
  t: DWORD;
  v: Integer;
begin
  j := 0;
  vreg := (V*10.0);
  if (saveLog) and (logfile) then
   // return value of fprintf() ignored
   fprintf(logfile, 'StartHVReg(%.2f)' + NL + '', V);
  if V = -1 then
  begin
   bufferU[Inc(j)] := VREG_DIS;
   bufferU[Inc(j)] := FLUSH;
   // return value of PacketIO() ignored
   PacketIO(5);
   // return value of msDelay() ignored
   msDelay(40);
   Exit(-1);
  end;
  t0 := GetTickCount() ; t := GetTickCount();
  bufferU[Inc(j)] := VREG_EN;
  bufferU[Inc(j)] := SET_VPP;
  bufferU[Inc(j)] := vreg;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000 and $ff;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_ADC;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(5);
  // return value of msDelay() ignored
  msDelay(20);
  z := 0;
  while (z < DIMBUF-2) and (bufferI[z] <> READ_ADC) do
  begin
   Inc(z);
  end;
  v := (bufferI[z+1] shl 8)+bufferI[z+2];
  if v = 0 then
  begin
   // return value of PrintMessage() ignored
   PrintMessage(strings[S_lowUsbV]);
   Exit(0);
  end;
  j := 0;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := READ_ADC;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /home/z/my-project/opgui_src/opgui.c:1345
    Original C:
      	for(;(v<(vreg/10.0-1)*G||v>(vreg/10.0+1)*G)&&t<t0+1500;t=GetTickCount()){
      		PacketIO(5);
      		msDelay(20);
      		for(z=0;z<DIMBUF-2&&bufferI[z]!=READ_ADC;z++);
      		v=(bufferI[z+1]<<8)+bufferI[z+2];
      		if(HwID==3) v>>=2;		//if 12 bit ADC
      //		PrintMessage2("v=%d=%fV\n",v,v/G);
      	}
  *)
  // init: 
  while ((v<(vreg/10.0-1)*G or v>(vreg/10.0+1)*G)) and (t < t0+1500) do
  begin
   // return value of PacketIO() ignored
   PacketIO(5);
   // return value of msDelay() ignored
   msDelay(20);
   z := 0;
   while (z < DIMBUF-2) and (bufferI[z] <> READ_ADC) do
   begin
    Inc(z);
   end;
   v := (bufferI[z+1] shl 8)+bufferI[z+2];
   if HwID = 3 then
    v := v shr 2;
   t := GetTickCount();
  end;
end;

procedure ProgID;
var
  j: Integer;
begin
  if DeviceDetected <> 1 then
   Exit;
  j := 0;
  bufferU[Inc(j)] := PROG_RST;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  while (j < DIMBUF-7) and (bufferI[j] <> PROG_RST) do
  begin
   Inc(j);
  end;
  PrintMessage3(strings[S_progver], bufferI[j+1], bufferI[j+2], bufferI[j+3]);
  FWVersion := (bufferI[j+1] shl 16)+(bufferI[j+2] shl 8)+bufferI[j+3];
  PrintMessage3(strings[S_progid], bufferI[j+4], bufferI[j+5], bufferI[j+6]);
  HwID := bufferI[j+6];
  if HwID = 1 then
   PrintMessage(' (18F2550)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else if HwID = 2 then
   PrintMessage(' (18F2450)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else if HwID = 3 then
   PrintMessage(' (18F2458/2553)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else if HwID = 4 then
   PrintMessage(' (18F25K50)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else if HwID = 5 then
   PrintMessage(' (18F25K50 all-in-one variant)' + #13 + '' + NL + '' + #13 + '' + NL + '')
  else
   PrintMessage(' (?)' + #13 + '' + NL + '' + #13 + '' + NL + '');
  GTK_TOGGLE_BUTTON(b_V33check).Checked := IfThen(HwID = 5, True, False);
  GTK_WIDGET(b_V33check).Visible := IfThen(HwID = 5, False, True);
end;

function CheckS1: Integer;
var
  i: Integer;
  j: Integer;
begin
  j := 0;
  bufferU[Inc(j)] := READ_RAM;
  bufferU[Inc(j)] := $0F;
  if HwID = 5 then
  begin
   bufferU[Inc(j)] := $80;
  end
  else
  begin
   bufferU[Inc(j)] := $84;
  end;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  // return value of PacketIO() ignored
  PacketIO(5);
  j := 0;
  while (j < DIMBUF-3) and (bufferI[j] <> READ_RAM) do
  begin
   Inc(j);
  end;
  if HwID = 5 then
  begin
   i := bufferI[j+3] and $80;
   Exit(IfThen(i, 1, 0));
  end
  else
  begin
   i := bufferI[j+3] and $8;
   Exit(IfThen(i, 0, 1));
  end;
end;

procedure TestHw(widget: ^TControl; parent: ^TForm);
var
  str: array[0..256-1] of Char;
  j: Integer;
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
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=5V' + NL + ' VPPU=13V' + NL + ' PGD(RB5)=0V' + NL + ' PGC(RB6)=0V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $15;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=5V' + NL + ' VPPU=0V' + NL + ' PGD(RB5)=5V' + NL + ' PGC(RB6)=5V' + NL + ' PGM(RB7)=5V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=0V' + NL + ' VPPU=13V' + NL + ' PGD(RB5)=5V' + NL + ' PGC(RB6)=0V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  strcpy(str, strings[I_TestMSG]);
  strcat(str, '' + NL + ' VDDU=0V' + NL + ' VPPU=0V' + NL + ' PGD(RB5)=0V' + NL + ' PGC(RB6)=5V' + NL + ' PGM(RB7)=0V');
  MsgBox(str);
  j := 0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  while j < DIMBUF do
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
    bufferU[Inc(j)] := EN_VPP_VCC;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := SET_PORT_DIR;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := EXT_PORT;
    bufferU[Inc(j)] := x and $FF;
    bufferU[Inc(j)] := (x shr 5) and $FF;
    bufferU[Inc(j)] := READ_B;
    bufferU[Inc(j)] := READ_AC;
    bufferU[Inc(j)] := FLUSH;
    while j < DIMBUF do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    j := 0;
    while (j < DIMBUF-1) and (bufferI[j] <> READ_B) do
    begin
     Inc(j);
    end;
    r := bufferI[j+1];
    Inc(j, 2);
    while (j < DIMBUF-1) and (bufferI[j] <> READ_AC) do
    begin
     Inc(j);
    end;
    Inc(r, (bufferI[j+1] and $F8) shl 5);
    for j := 0 to (13) - 1 do
    begin
     str[12-j] := IfThen(x and (1 shl j), #49, #48);
    end;
    PrintMessage(str);
    PrintMessage1(' (%s)' + NL + '', IfThen(r = x, 'OK', strings[S_ErrSing]));
   end;
  end;
end;

procedure msDelay(delay: Double);
var
  x: LongInt;
  stop: T__int64;
  freq: T__int64;
  timeout: T__int64;
begin
  x := (delay*1000.0);
  usleep(IfThen(x > MinDly, x, MinDly));
  QueryPerformanceCounter(@( stop ));
  QueryPerformanceFrequency(@( freq ));
  timeout := stop+delay*freq/1000.0;
  while stop < timeout do
  begin
  end;
end;

function GetTickCount: DWORD;
var
  now: Tstruct timeb;
begin
  // return value of ftime() ignored
  ftime(@( now ));
  Exit(now.time*1000+now.millitm);
end;

procedure PacketIO(delay: Double);
var
  delay0: Integer;
  ts: Tstruct timespec;
  start: Tuint64_t;
  stop: Tuint64_t;
  set_: Tfd_set;
  timeout: Tstruct timeval;
  rv: Integer;
  i: Integer;
  res: Integer;
  ev: array[0..80-1] of Tstruct hiddev_event;
  n: Integer;
  start: T__int64;
  stop: T__int64;
  freq: T__int64;
  timeout: T__int64;
begin
  if (saveLog) and (logfile) then
   fprintf(logfile, 'PacketIO(%.2f)' + NL + '', delay);
  delay0 := delay;
  FD_ZERO(@( set_ ));
  FD_SET(fd, @( set_ ));
  timeout.tv_sec := 0;
  timeout.tv_usec := TIMEOUT*1000;
  clock_gettime(CLOCK_REALTIME, @( ts ));
  start := ts.tv_nsec/1000;
  Dec(delay, TIMEOUT-10);
  if delay < MinDly then
   delay := MinDly;
  res := write(fd, bufferU, DIMBUF);
  if res < 0 then
  begin
   printf('Error: %d' + NL + '', errno);
   perror('write');
  end;
  usleep((delay*1000.0));
  rv := select(fd + 1, @( set_ ), nil, nil, @( timeout ));
  if rv = -1 then
  begin
   PrintMessage(strings[S_ErrSing]);
   if (saveLog) and (logfile) then
    fprintf(logfile, strings[S_ErrSing]);
   Exit;
  end
  else if rv = 0 then
  begin
   PrintMessage(strings[S_comTimeout]);
   if (saveLog) and (logfile) then
    fprintf(logfile, strings[S_comTimeout]);
   Exit;
  end;
  res := read(fd, bufferI, DIMBUF);
  if res < 0 then
  begin
   perror('read');
  end;
  n := DIMBUF;
  for i := 0 to (DIMBUF) - 1 do
  begin
   ref_multi_u.values[i] := bufferU[i];
  end;
  ioctl(fd, HIDIOCSUSAGES, @( ref_multi_u ));
  ioctl(fd, HIDIOCSREPORT, @( rep_info_u ));
  usleep((delay*1000.0));
  rv := select(fd + 1, @( set_ ), nil, nil, @( timeout ));
  if rv = -1 then
  begin
   PrintMessage(strings[S_ErrSing]);
   if (saveLog) and (logfile) then
    fprintf(logfile, strings[S_ErrSing]);
  end
  else if rv = 0 then
  begin
   PrintMessage(strings[S_comTimeout]);
   if (saveLog) and (logfile) then
    fprintf(logfile, strings[S_comTimeout]);
  end
  else
  begin
   rv := read(fd, ev, sizeof(struct hiddev_event) *n);
   i := 0;
   while ((ev[0].value<>bufferU[0])) and (i < 40) do
   begin
    msDelay(5);
    rv := read(fd, ev, sizeof(struct hiddev_event) *n);
    if (saveLog) and (logfile) then
     fprintf(logfile, 'Packet not ready, wait extra time' + NL + '');
    Inc(i);
   end;
   if i = 40 then
    fprintf(logfile, 'Cannot read correct packet!!' + NL + '');
   for i := 0 to (n) - 1 do
   begin
    bufferI[i] := ev[i].value and $FF;
   end;
  end;
  clock_gettime(CLOCK_REALTIME, @( ts ));
  stop := ts.tv_nsec / 1000;
  if (saveLog) and (logfile) then
  begin
   WriteLogIO();
   fprintf(logfile, 'T=%.2f ms (%+.2f ms)' + NL + '', (stop-start)/1000.0, (stop-start)/1000.0-delay0);
   if bufferU[0] <> bufferI[0] then
    fprintf(logfile, 'Cannot read correct packet!!' + NL + '');
  end;
  QueryPerformanceCounter(@( start ));
  QueryPerformanceFrequency(@( freq ));
  Dec(delay, TIMEOUT-10);
  if delay < MinDly then
   delay := MinDly;
  Result := WriteFile(WriteHandle, bufferU0, DIMBUF+1, @( BytesWritten ), nil);
  QueryPerformanceCounter(@( stop ));
  timeout := stop+delay*freq/1000.0;
  while stop < timeout do
  begin
  end;
  Result := ReadFile(ReadHandle, bufferI0, DIMBUF+1, @( NumberOfBytesRead ), @( HIDOverlapped ));
  Result := WaitForSingleObject(hEventObject, TIMEOUT);
  if (saveLog) and (logfile) then
   WriteLogIO();
  ResetEvent(hEventObject);
  if Result <> WAIT_OBJECT_0 then
  begin
   PrintMessage(strings[S_comTimeout]);
   if (saveLog) and (logfile) then
    fprintf(logfile, strings[S_comTimeout]);
  end;
  QueryPerformanceCounter(@( stop ));
  if (saveLog) and (logfile) then
   fprintf(logfile, 'T=%.2f ms (%+.2f ms)' + NL + '', (stop-start)*1000.0/freq, (stop-start)*1000.0/freq-delay0);
end;

function main(argc: Integer; argv: PChar): Integer;
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
  long_options: array of Tstruct option;
  langid: PChar;
  n: Integer;
  p: PChar;
  builder: ^TObject;
  cssProvider: ^TObject;
  w: ^TControl;
  loadCoffBtn: ^TControl;
  text: array[0..16-1] of Char;
  info: Tstruct DevInfo;
begin
  fname := 0;
  lang[0] := #0;
  langfile := 0;
  homedir := g_get_home_dir();
  if (homedir) <> 0 then
  begin
   config_dir := g_build_path(G_DIR_SEPARATOR_S, homedir, CONFIG_DIR, nil);
   if  not g_file_test(config_dir,G_FILE_TEST_IS_DIR) then
    // return value of mkdir() ignored
    mkdir(config_dir);
   // return value of mkdir() ignored
   mkdir(config_dir, 0755);
   fname := g_build_path(G_DIR_SEPARATOR_S, config_dir, CONFIG_FILE, nil);
   f := fopen(fname, 'r');
   if (f) <> 0 then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /home/z/my-project/opgui_src/opgui.c:1723
      Original C:
        			for(;fgets(line,256,f);){
        				if(sscanf(line,"device %s",temp)>0) strcpy(dev,temp);
        				else if(sscanf(line,"vid %X",&X)>0) vid=X;
        				else if(sscanf(line,"pid %X",&X)>0) pid=X;
        				else sscanf(line,"maxerr %d",&max_err);
        			}
    *)
    // init: 
    while fgets(line, 256, f) do
    begin
     if sscanf(line, 'device %s', temp) > 0 then
      // return value of strcpy() ignored
      strcpy(dev, temp)
     else if sscanf(line, 'vid %X', @( X )) > 0 then
      vid := X
     else if sscanf(line, 'pid %X', @( X )) > 0 then
      pid := X
     else
      // return value of sscanf() ignored
      sscanf(line, 'maxerr %d', @( max_err ));
    end;
   end;
  end;
  // return value of strncpy() ignored
  strncpy(dev_ini, dev, sizeof(dev_ini));
  vid_ini := vid;
  pid_ini := pid;
  max_err_ini := max_err;
  vid_ini := vid;
  pid_ini := pid;
  max_err_ini := max_err;
  bufferI := bufferI0+1;
  bufferU := bufferU0+1;
  bufferI0[0] := 0;
  bufferU0[0] := 0;
  // gtk_init() -> no-op in LCL
  opterr := 0;
  option_index := 0;
  help := 0;
  command := 0;
  long_options[0] := {'?', no_argument, and help, 1};
  long_options[1] := {'h', no_argument, and help, 1};
  long_options[2] := {'help', no_argument, and help, 1};
  long_options[3] := {'c', no_argument, and command, 1};
  long_options[4] := {'command', no_argument, and command, 1};
  long_options[5] := {'lang', required_argument, 0, 'l'};
  long_options[6] := {'langfile', no_argument, and langfile, 1};
  long_options[7] := {0, 0, 0, 0};
  while (j = getopt_long_only (argc, argv, '',long_options, and option_index)) <> -1 do
  begin
   if j = #108 then
   begin
    // return value of strncpy() ignored
    strncpy(lang, optarg, sizeof(lang)-1);
   end;
  end;
  while j < 128 do
  begin
   tmpbuf[j] := 0;
   Inc(j);
  end;
  // return value of strinit() ignored
  strinit();
  langid := 0;
  i := 0;
  if (lang[0]) <> 0 then
  begin
   if (lang[0] = #105) and (lang[1] = #116) then
   begin
    strings := strings_it;
    i := 1;
   end
   else if (lang[0] = #101) and (lang[1] = #110) then
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
   langid[n-1] := #45;
   // return value of GetLocaleInfo() ignored
   GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SISO3166CTRYNAME, langid+n, 9);
   langid := getenv('LANG');
   if (langid) <> 0 then
   begin
    if (langid[0] = #105) and (langid[1] = #116) then
     strings := strings_it
    else if (langid[0] = #101) and (langid[1] = #110) then
     strings := strings_en
    else if strfind(langid, 'languages.rc') then
    begin
    end
    else
    begin
     p := Pos(langid, langid);
     if (p) <> 0 then
      (p^) := 0;
     if  not strfind(langid,'languages.rc') then
      strings := strings_en;
    end;
   end
   else
    strings := strings_en;
  end;
  if (langfile) <> 0 then
   // return value of GenerateLangFile() ignored
   GenerateLangFile(langid, 'languages.rc');
  if (help) <> 0 then
  begin
   // return value of printf() ignored
   printf(strings[I_GUI_CMD_HELP]);
   Halt;
  end;
  if (command) <> 0 then
  begin
   cmdline := 1;
   DeviceDetected := FindDevice(vid, pid);
   if  not DeviceDetected then
   begin
    DeviceDetected := FindDevice(new_vid, new_pid);
    if (DeviceDetected) <> 0 then
    begin
     vid := new_vid;
     pid := new_pid;
    end;
   end;
   if  not DeviceDetected then
    DeviceDetected := FindDevice(old_vid, old_pid);
   if (DeviceDetected) <> 0 then
   begin
    bufferU[0] := 0;
    for i := 1 to (DIMBUF) - 1 do
    begin
     bufferU[i] := tmpbuf[i-1];
    end;
    // return value of PacketIO() ignored
    PacketIO(100);
    // return value of printf() ignored
    printf('> ');
    for i := 1 to (DIMBUF) - 1 do
    begin
     // return value of printf() ignored
     printf('%02X ', bufferU[i]);
    end;
    // return value of printf() ignored
    printf('' + NL + '< ');
    for i := 1 to (DIMBUF) - 1 do
    begin
     // return value of printf() ignored
     printf('%02X ', bufferI[i]);
    end;
    // return value of printf() ignored
    printf(NL);
   end
   else
    // return value of printf() ignored
    printf(strings[S_noprog]);
   Halt;
  end;
  builder := nil;
  builder := nil;
  window := GTK_WIDGET(window);
  // g_signal_connect() -> no-op in LCL
  // return value of gtk_window_set_icon() ignored
  gtk_window_set_icon(GTK_WINDOW(window), gdk_pixbuf_new_from_resource('/res/sys.png', nil));
  cssProvider := gtk_css_provider_new();
  // return value of gtk_css_provider_load_from_resource() ignored
  gtk_css_provider_load_from_resource(cssProvider, '/res/style.css');
  // return value of gtk_style_context_add_provider_for_screen() ignored
  gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(cssProvider), GTK_STYLE_PROVIDER_PRIORITY_USER);
  w := nil;
  // return value of sprintf() ignored
  sprintf(str, 'opgui v%s', VERSION);
  GTK_WINDOW(window).Caption := str;
  notebook := GTK_WIDGET(NOTEBOOK);
  w := GTK_WIDGET(OPEN_T);
  w.Hint := strings[I_Fopen]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(SAVE_T);
  w.Hint := strings[I_Fsave]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  readBtn := GTK_WIDGET(READ_T);
  readBtn.Hint := strings[I_DevR]; readBtn.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  writeBtn := GTK_WIDGET(WRITE_T);
  writeBtn.Hint := strings[I_DevW]; writeBtn.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  stopBtn := GTK_WIDGET(STOP_T);
  stopBtn.Hint := strings[I_ICD_STOP]; stopBtn.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(CONNECT_T);
  w.Hint := strings[I_CONN]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(INFO_T);
  w.Hint := strings[I_Info]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  GTK_LABEL(GTK_WIDGET(DATA_T_L)).Caption := strings[I_Data];
  data := GTK_WIDGET(DATA);
  dataBuf := GTK_TEXT_VIEW(data);
  GTK_LABEL(GTK_WIDGET(DEVICE_L)).Caption := strings[I_Dev];
  GTK_LABEL(GTK_WIDGET(TYPE_L)).Caption := strings[I_TypeFilt];
  GTK_LABEL(GTK_WIDGET(DEV_SRC_L)).Caption := strings[I_Filt];
  devTypeCombo := GTK_WIDGET(TYPE_C);
  // g_signal_connect() -> no-op in LCL
  devFiltEntry := GTK_WIDGET(DEV_SRC_E);
  // g_signal_connect() -> no-op in LCL
  devTree := GTK_WIDGET(DEV_TREE);
  // return value of gtk_tree_view_insert_column_with_attributes() ignored
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(devTree), -1, strings[I_Dev], gtk_cell_renderer_text_new(), 'text', DEVICE_NAME_COLUMN, nil);
  // return value of gtk_tree_view_insert_column_with_attributes() ignored
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(devTree), -1, strings[I_Type], gtk_cell_renderer_text_new(), 'text', DEVICE_GROUP_COLUMN, nil);
  // return value of gtk_tree_view_column_set_fixed_width() ignored
  gtk_tree_view_column_set_fixed_width(gtk_tree_view_get_column(GTK_TREE_VIEW(devTree), 0), 125);
  // return value of gtk_tree_view_column_set_fixed_width() ignored
  gtk_tree_view_column_set_fixed_width(gtk_tree_view_get_column(GTK_TREE_VIEW(devTree), 1), 125);
  devFrame := GTK_WIDGET(DEVICE_NAME);
  devinfo := GTK_WIDGET(DEV_INFO);
  EEPROM_RW := GTK_WIDGET(EE_RW);
  GTK_BUTTON(EEPROM_RW).Caption := strings[I_EE];
  ReadReserved := GTK_WIDGET(RES_READ);
  GTK_BUTTON(ReadReserved).Caption := strings[I_ReadRes];
  Write_ID_BKCal := GTK_WIDGET(PROG_ID);
  GTK_BUTTON(Write_ID_BKCal).Caption := strings[I_ID_BKo_W];
  WriteCalib12 := GTK_WIDGET(PROG_CAL12);
  GTK_BUTTON(WriteCalib12).Caption := strings[I_CalW];
  UseSaflock := GTK_WIDGET(USE_SAFLOCK);
  GTK_BUTTON(UseSaflock).Caption := strings[I_Saflock];
  GTK_LABEL(GTK_WIDGET(OSCCAL_L)).Caption := strings[I_OSCW];
  UseOSCCAL := GTK_WIDGET(OSCCAL);
  GTK_BUTTON(UseOSCCAL).Caption := strings[I_OSC];
  UseBKOSCCAL := GTK_WIDGET(BKOSCCAL);
  GTK_BUTTON(UseBKOSCCAL).Caption := strings[I_BKOSC];
  UseFileCal := GTK_WIDGET(FILECAL);
  GTK_BUTTON(UseFileCal).Caption := strings[I_OSCF];
  ICD_check := GTK_WIDGET(ICD);
  GTK_BUTTON(ICD_check).Caption := strings[I_ICD_ENABLE];
  GTK_LABEL(GTK_WIDGET(ICD_ADDR_L)).Caption := strings[I_ICD_ADDRESS];
  ICD_addr_entry := GTK_WIDGET(ICD_ADDR);
  ConfigForce := GTK_WIDGET(FORCE_CW);
  GTK_BUTTON(ConfigForce).Caption := strings[I_PIC_FORCECW];
  CW1_entry := GTK_WIDGET(CW1);
  CW2_entry := GTK_WIDGET(CW2);
  CW3_entry := GTK_WIDGET(CW3);
  CW4_entry := GTK_WIDGET(CW4);
  CW5_entry := GTK_WIDGET(CW5);
  CW6_entry := GTK_WIDGET(CW6);
  CW7_entry := GTK_WIDGET(CW7);
  AVR_FuseLow := GTK_WIDGET(FUSEL);
  AVR_FuseLowWrite := GTK_WIDGET(FUSEL_C);
  GTK_BUTTON(AVR_FuseLowWrite).Caption := strings[I_AT_FUSE];
  AVR_FuseHigh := GTK_WIDGET(FUSEH);
  AVR_FuseHighWrite := GTK_WIDGET(FUSEH_C);
  GTK_BUTTON(AVR_FuseHighWrite).Caption := strings[I_AT_FUSEH];
  AVR_FuseExt := GTK_WIDGET(FUSEX);
  AVR_FuseExtWrite := GTK_WIDGET(FUSEX_C);
  GTK_BUTTON(AVR_FuseExtWrite).Caption := strings[I_AT_FUSEX];
  AVR_Lock := GTK_WIDGET(FUSELCK);
  AVR_LockWrite := GTK_WIDGET(FUSELCK_C);
  GTK_BUTTON(AVR_LockWrite).Caption := strings[I_AT_LOCK];
  b_WfuseLF := GTK_WIDGET(FUSEL_W3K);
  GTK_BUTTON(b_WfuseLF).Caption := strings[I_AT_FUSELF];
  // g_signal_connect() -> no-op in LCL
  devFramePIC := GTK_WIDGET(PIC_OPT);
  devFrameAVR := GTK_WIDGET(AVR_OPT);
  devFrameConfigW := GTK_WIDGET(CW_OPT);
  devFrameICD := GTK_WIDGET(ICD_OPT);
  devFrameOsc := GTK_WIDGET(OSC_OPT);
  devPIC_CW1 := GTK_WIDGET(CW1_OPT);
  devPIC_CW2 := GTK_WIDGET(CW2_OPT);
  devPIC_CW3 := GTK_WIDGET(CW3_OPT);
  devPIC_CW4 := GTK_WIDGET(CW4_OPT);
  devPIC_CW5 := GTK_WIDGET(CW5_OPT);
  devPIC_CW6 := GTK_WIDGET(CW6_OPT);
  devPIC_CW7 := GTK_WIDGET(CW7_OPT);
  devPIC_CW8 := GTK_WIDGET(CW8_OPT);
  GTK_WIDGET(devFrameAVR).Visible := False;
  GTK_WIDGET(devFramePIC).Visible := False;
  GTK_LABEL(GTK_WIDGET(OPTIONS_L)).Caption := strings[I_Opt];
  VID_entry := GTK_WIDGET(VID);
  PID_entry := GTK_WIDGET(PID);
  Errors_entry := GTK_WIDGET(MAXERR);
  b_connect := GTK_WIDGET(CONNECT);
  GTK_BUTTON(b_connect).Caption := strings[I_CONN];
  // g_signal_connect() -> no-op in LCL
  b_testhw := GTK_WIDGET(TEST);
  GTK_BUTTON(b_testhw).Caption := strings[I_TestHWB];
  // g_signal_connect() -> no-op in LCL
  b_log := GTK_WIDGET(LOG);
  GTK_BUTTON(b_log).Caption := strings[I_LOG];
  b_V33check := GTK_WIDGET(3VCHECK);
  GTK_BUTTON(b_V33check).Caption := strings[I_CK_V33];
  b_WaitS1 := GTK_WIDGET(S1);
  GTK_BUTTON(b_WaitS1).Caption := strings[I_WAITS1];
  GTK_LABEL(GTK_WIDGET(MAXERR_L)).Caption := strings[I_MAXERR];
  GTK_LABEL(GTK_WIDGET(I2CMODE)).Caption := strings[I_I2CMode];
  I2C8bit := GTK_WIDGET(I2C8BIT);
  I2C16bit := GTK_WIDGET(I2C16BIT);
  SPI00 := GTK_WIDGET(SPI00);
  SPI01 := GTK_WIDGET(SPI01);
  SPI10 := GTK_WIDGET(SPI10);
  SPI11 := GTK_WIDGET(SPI11);
  GTK_LABEL(GTK_WIDGET(DATASEND_L)).Caption := strings[I_I2CDATAOUT];
  I2CDataSend := GTK_WIDGET(DATASEND);
  GTK_LABEL(GTK_WIDGET(DATATR_L)).Caption := strings[I_I2CDATATR];
  I2CDataReceive := GTK_WIDGET(DATATR);
  GTK_LABEL(GTK_WIDGET(NBYTE_L)).Caption := strings[I_I2C_NB];
  I2CNbyte := GTK_WIDGET(NBYTE_S);
  GTK_LABEL(GTK_WIDGET(SPEED_L)).Caption := strings[I_Speed];
  I2CSpeed := GTK_WIDGET(SPEED_C);
  I2CSendBtn := GTK_WIDGET(SEND_B);
  GTK_BUTTON(I2CSendBtn).Caption := strings[I_I2CSend];
  // g_signal_connect() -> no-op in LCL
  I2CReceiveBtn := GTK_WIDGET(RECEIVE_B);
  GTK_BUTTON(I2CReceiveBtn).Caption := strings[I_I2CReceive];
  // g_signal_connect() -> no-op in LCL
  loadCoffBtn := GTK_WIDGET(LOADCOFF_B);
  // return value of gtk_tool_button_set_label() ignored
  gtk_tool_button_set_label(GTK_TOOL_BUTTON(loadCoffBtn), strings[I_LOAD_COFF]);
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(OPTIONS_M), strings[I_Opt]);
  icdMenuPC := GTK_WIDGET(PCOUNT_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuPC), strings[I_SHOW_PC]);
  icdMenuSTAT := GTK_WIDGET(STATUS_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuSTAT), strings[I_SHOW_STATUS]);
  icdMenuBank0 := GTK_WIDGET(BANK0_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank0), strings[I_SHOW_BANK0]);
  icdMenuBank1 := GTK_WIDGET(BANK1_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank1), strings[I_SHOW_BANK1]);
  icdMenuBank2 := GTK_WIDGET(BANK2_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank2), strings[I_SHOW_BANK2]);
  icdMenuBank3 := GTK_WIDGET(BANK3_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuBank3), strings[I_SHOW_BANK3]);
  icdMenuEE := GTK_WIDGET(EE_M);
  // return value of gtk_menu_item_set_label() ignored
  gtk_menu_item_set_label(GTK_MENU_ITEM(icdMenuEE), strings[I_SHOW_EE]);
  w := GTK_WIDGET(ICD_RUN);
  w.Hint := strings[I_ICD_RUN]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(ICD_HALT);
  w.Hint := strings[I_ICD_HALT]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(ICD_STEP);
  w.Hint := strings[I_ICD_STEP]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(ICD_STEPOVER);
  w.Hint := strings[I_ICD_STEPOVER]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(ICD_STOP);
  w.Hint := strings[I_ICD_STOP]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(ICD_REFRESH);
  w.Hint := strings[I_ICD_REFRESH]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  icdCommand := GTK_WIDGET(ICD_CMD_E);
  icdCommand.Hint := strings[I_ICD_CMD]; icdCommand.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  w := GTK_WIDGET(ICD_HELP);
  w.Hint := strings[I_ICD_HELP]; w.ShowHint := True;
  // g_signal_connect() -> no-op in LCL
  GTK_LABEL(GTK_WIDGET(ICD_SOURCE_L)).Caption := strings[I_ICD_SOURCE];
  sourceTxt := GTK_WIDGET(ICD_SOURCE);
  sourceBuf := GTK_TEXT_VIEW(sourceTxt);
  // g_signal_connect() -> no-op in LCL
  GTK_LABEL(GTK_WIDGET(ICD_STAT_L)).Caption := strings[I_ICD_STATUS];
  statusTxt := GTK_WIDGET(ICD_STATUS);
  statusBuf := GTK_TEXT_VIEW(statusTxt);
  // g_signal_connect() -> no-op in LCL
  b_io_active := GTK_WIDGET(IOEN);
  GTK_BUTTON(b_io_active).Caption := strings[I_IO_Enable];
  // g_signal_connect() -> no-op in LCL
  ioButtons[0].r_0 := GTK_WIDGET(RB0_0);
  ioButtons[0].r_1 := GTK_WIDGET(RB0_1);
  ioButtons[0].r_I := GTK_WIDGET(RB0_I);
  ioButtons[0].e_I := GTK_WIDGET(RB0_L);
  ioButtons[1].r_0 := GTK_WIDGET(RB1_0);
  ioButtons[1].r_1 := GTK_WIDGET(RB1_1);
  ioButtons[1].r_I := GTK_WIDGET(RB1_I);
  ioButtons[1].e_I := GTK_WIDGET(RB1_L);
  ioButtons[2].r_0 := GTK_WIDGET(RB2_0);
  ioButtons[2].r_1 := GTK_WIDGET(RB2_1);
  ioButtons[2].r_I := GTK_WIDGET(RB2_I);
  ioButtons[2].e_I := GTK_WIDGET(RB2_L);
  ioButtons[3].r_0 := GTK_WIDGET(RB3_0);
  ioButtons[3].r_1 := GTK_WIDGET(RB3_1);
  ioButtons[3].r_I := GTK_WIDGET(RB3_I);
  ioButtons[3].e_I := GTK_WIDGET(RB3_L);
  ioButtons[4].r_0 := GTK_WIDGET(RB4_0);
  ioButtons[4].r_1 := GTK_WIDGET(RB4_1);
  ioButtons[4].r_I := GTK_WIDGET(RB4_I);
  ioButtons[4].e_I := GTK_WIDGET(RB4_L);
  ioButtons[5].r_0 := GTK_WIDGET(RB5_0);
  ioButtons[5].r_1 := GTK_WIDGET(RB5_1);
  ioButtons[5].r_I := GTK_WIDGET(RB5_I);
  ioButtons[5].e_I := GTK_WIDGET(RB5_L);
  ioButtons[6].r_0 := GTK_WIDGET(RB6_0);
  ioButtons[6].r_1 := GTK_WIDGET(RB6_1);
  ioButtons[6].r_I := GTK_WIDGET(RB6_I);
  ioButtons[6].e_I := GTK_WIDGET(RB6_L);
  ioButtons[7].r_0 := GTK_WIDGET(RB7_0);
  ioButtons[7].r_1 := GTK_WIDGET(RB7_1);
  ioButtons[7].r_I := GTK_WIDGET(RB7_I);
  ioButtons[7].e_I := GTK_WIDGET(RB7_L);
  ioButtons[8].r_0 := GTK_WIDGET(RC7_0);
  ioButtons[8].r_1 := GTK_WIDGET(RC7_1);
  ioButtons[8].r_I := GTK_WIDGET(RC7_I);
  ioButtons[8].e_I := GTK_WIDGET(RC7_L);
  ioButtons[9].r_0 := GTK_WIDGET(RC6_0);
  ioButtons[9].r_1 := GTK_WIDGET(RC6_1);
  ioButtons[9].r_I := GTK_WIDGET(RC6_I);
  ioButtons[9].e_I := GTK_WIDGET(RC6_L);
  ioButtons[10].r_0 := GTK_WIDGET(RA5_0);
  ioButtons[10].r_1 := GTK_WIDGET(RA5_1);
  ioButtons[10].r_I := GTK_WIDGET(RA5_I);
  ioButtons[10].e_I := GTK_WIDGET(RA5_L);
  ioButtons[11].r_0 := GTK_WIDGET(RA4_0);
  ioButtons[11].r_1 := GTK_WIDGET(RA4_1);
  ioButtons[11].r_I := GTK_WIDGET(RA4_I);
  ioButtons[11].e_I := GTK_WIDGET(RA4_L);
  ioButtons[12].r_0 := GTK_WIDGET(RA3_0);
  ioButtons[12].r_1 := GTK_WIDGET(RA3_1);
  ioButtons[12].r_I := GTK_WIDGET(RA3_I);
  ioButtons[12].e_I := GTK_WIDGET(RA3_L);
  for ii := 0 to (sizeof(ioButtons)/sizeof(ioButtons[0])) - 1 do
  begin
   GTK_TOGGLE_BUTTON(ioButtons[ii].r_I).Checked := True;
   // g_signal_connect() -> no-op in LCL
   // g_signal_connect() -> no-op in LCL
   // g_signal_connect() -> no-op in LCL
  end;
  VPP_ON := GTK_WIDGET(VPPUEN);
  DCDC_ON := GTK_WIDGET(DCDCEN);
  DCDC_voltage := GTK_WIDGET(DCDC_S);
  GTK_LABEL(GTK_WIDGET(CMD_L)).Caption := strings[I_IO_Commands];
  GTK_LABEL(GTK_WIDGET(CMDSEND_L)).Caption := strings[I_I2CDATAOUT];
  commandSend := GTK_WIDGET(CMDSEND);
  GTK_LABEL(GTK_WIDGET(CMDTR_L)).Caption := strings[I_I2CDATATR];
  commandTransfer := GTK_WIDGET(CMDTR);
  w := GTK_WIDGET(CMDTR_B);
  GTK_BUTTON(w).Caption := strings[I_I2CSend];
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  Hex_entry := GTK_WIDGET(HEXIN);
  Hex_data := GTK_WIDGET(DATAOUT);
  Address_entry := GTK_WIDGET(ADDRIN);
  Data_entry := GTK_WIDGET(DATAIN);
  Hex_data2 := GTK_WIDGET(HEXOUT);
  w := GTK_WIDGET(HEXSAVE);
  GTK_BUTTON(w).Caption := strings[I_Fsave];
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  // g_signal_connect() -> no-op in LCL
  status_bar := GTK_WIDGET(STATUS_B);
  statusID := gtk_statusbar_get_context_id(GTK_STATUSBAR(status_bar), 'ID');
  window.Visible := True;
  // return value of sprintf() ignored
  sprintf(text, '%04X', vid);
  GTK_ENTRY(VID_entry).Text := text;
  // return value of sprintf() ignored
  sprintf(text, '%04X', pid);
  GTK_ENTRY(PID_entry).Text := text;
  // return value of sprintf() ignored
  sprintf(text, '%d', max_err);
  GTK_ENTRY(Errors_entry).Text := text;
  sizeW := $8400;
  memCODE_W := malloc(sizeW*sizeof(WORD));
  // return value of initVar() ignored
  initVar();
  for i := 0 to ($8400) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  // return value of strncpy() ignored
  strncpy(LogFileName, strings[S_LogFile], sizeof(LogFileName));
  GTK_COMBO_BOX_TEXT(devTypeCombo).Items.Add(GROUP_ALL);
  for i := 0 to (NUM_GROUPS) - 1 do
  begin
   GTK_COMBO_BOX_TEXT(devTypeCombo).Items.Add(groupNames[i]);
  end;
  if Length(dev) > 0 then
  begin
   info := GetDevInfo(dev);
   // return value of gtk_combo_box_set_active_id() ignored
   gtk_combo_box_set_active_id(GTK_COMBO_BOX(devTypeCombo), groupNames[info.group]);
  end
  else
  begin
   // return value of gtk_combo_box_set_active_id() ignored
   gtk_combo_box_set_active_id(GTK_COMBO_BOX(devTypeCombo), GROUP_ALL);
  end;
  DeviceDetected := FindDevice(vid, pid);
  if  not DeviceDetected then
  begin
   DeviceDetected := FindDevice(new_vid, new_pid);
   if (DeviceDetected) <> 0 then
   begin
    vid := new_vid;
    pid := new_pid;
   end;
  end;
  if  not DeviceDetected then
   DeviceDetected := FindDevice(old_vid, old_pid);
  // return value of ProgID() ignored
  ProgID();
  Application.Run;
  if (AnsiCompareStr(dev_ini, dev)) or (vid_ini <> vid) or (pid_ini <> pid) or (max_err_ini <> max_err) then
  begin
   if (homedir) <> 0 then
   begin
    f := fopen(fname, 'w');
    if (f) <> 0 then
    begin
     // return value of fprintf() ignored
     fprintf(f, 'device %s' + NL + '', dev);
     // return value of fprintf() ignored
     fprintf(f, 'maxerr %d' + NL + '', max_err);
     // return value of fprintf() ignored
     fprintf(f, 'vid %X' + NL + '', vid);
     // return value of fprintf() ignored
     fprintf(f, 'pid %X' + NL + '', pid);
    end;
    CloseFile(f);
   end;
  end;
  Exit(0);
end;

function FindDevice(vid: Integer; pid: Integer): Integer;
var
  MyDeviceDetected: Integer;
  device_info: Tstruct hidraw_devinfo;
  i: Integer;
  device_info: Tstruct hiddev_devinfo;
  i: Integer;
  detailData: TPSP_DEVICE_INTERFACE_DETAIL_DATA;
  DeviceHandle: THandle;
  hDevInfo: THandle;
  HidGuid: TGUID;
  MyDevicePathName: array[0..1024-1] of Char;
  Length: DWORD;
  Required: DWORD;
  Attributes: THIDD_ATTRIBUTES;
  devInfoData: TSP_DEVICE_INTERFACE_DATA;
  LastDevice: Integer;
  MemberIndex: Integer;
  Result_: LongInt;
  hHID: THandle;
  hSAPI: THandle;
begin
  MyDeviceDetected := False;
  i := -1;
  if path[0] = 0 then
  begin
   if (fd = open('/dev/openprogrammer', O_RDWR or O_NONBLOCK)) > 0 then
   begin
    // return value of sprintf() ignored
    sprintf(path, '/dev/openprogrammer');
    // return value of ioctl() ignored
    ioctl(fd, HIDIOCGRAWINFO, @( device_info ));
    if (device_info.vendor = vid) and (device_info.product = pid) then
     i := 0
    else
    begin
     // return value of close() ignored
     close(fd);
     i := -1;
    end;
   end;
   if (i) <> 0 then
   begin
    for i := 0 to (16) - 1 do
    begin
     // return value of sprintf() ignored
     sprintf(path, '/dev/hidraw%d', i);
     if (fd = open(path, O_RDWR or O_NONBLOCK)) > 0 then
     begin
      // return value of ioctl() ignored
      ioctl(fd, HIDIOCGRAWINFO, @( device_info ));
      if (device_info.vendor = vid) and (device_info.product = pid) then
       Break
      else
       // return value of close() ignored
       close(fd);
     end;
    end;
   end;
   if i = 16 then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_noprog]);
    path[0] := 0;
    Exit(0);
   end;
  end
  else
  begin
   if (fd = open(path, O_RDWR or O_NONBLOCK)) < 0 then
   begin
    // return value of PrintMessage1() ignored
    PrintMessage1(strings[S_DevPermission], path);
    Exit(0);
   end;
   // return value of ioctl() ignored
   ioctl(fd, HIDIOCGRAWINFO, @( device_info ));
   if (device_info.vendor <> vid) or (device_info.product <> pid) then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_noprog]);
    Exit(0);
   end;
  end;
  // return value of printf() ignored
  printf(strings[S_progDev], path);
  Exit(1);
  i := -1;
  if path[0] = 0 then
  begin
   if (fd = open('/dev/openprogrammer', O_RDONLY )) > 0 then
   begin
    // return value of ioctl() ignored
    ioctl(fd, HIDIOCGDEVINFO, @( device_info ));
    if (device_info.vendor = vid) and (device_info.product = pid) then
     i := 0
    else
    begin
     // return value of close() ignored
     close(fd);
     i := -1;
    end;
   end;
   if (i) <> 0 then
   begin
    for i := 0 to (16) - 1 do
    begin
     // return value of sprintf() ignored
     sprintf(path, '/dev/usb/hiddev%d', i);
     if (fd = open(path, O_RDONLY )) > 0 then
     begin
      // return value of ioctl() ignored
      ioctl(fd, HIDIOCGDEVINFO, @( device_info ));
      if (device_info.vendor = vid) and (device_info.product = pid) then
       Break
      else
       // return value of close() ignored
       close(fd);
     end;
    end;
   end;
   if i = 16 then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_noprog]);
    path[0] := 0;
    Exit(0);
   end;
  end
  else
  begin
   if (fd = open(path, O_RDONLY )) < 0 then
   begin
    // return value of PrintMessage1() ignored
    PrintMessage1(strings[S_DevPermission], path);
    Exit(0);
   end;
   // return value of ioctl() ignored
   ioctl(fd, HIDIOCGDEVINFO, @( device_info ));
   if (device_info.vendor <> vid) or (device_info.product <> pid) then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_noprog]);
    Exit(0);
   end;
  end;
  MyDeviceDetected := True;
  rep_info_u.report_type := HID_REPORT_TYPE_OUTPUT;
  rep_info_i.report_type := HID_REPORT_TYPE_INPUT;
  rep_info_i.report_id := HID_REPORT_ID_FIRST ; rep_info_u.report_id := HID_REPORT_ID_FIRST;
  rep_info_i.num_fields := 1 ; rep_info_u.num_fields := 1;
  ref_multi_u.uref.report_type := HID_REPORT_TYPE_OUTPUT;
  ref_multi_i.uref.report_type := HID_REPORT_TYPE_INPUT;
  ref_multi_i.uref.report_id := HID_REPORT_ID_FIRST ; ref_multi_u.uref.report_id := HID_REPORT_ID_FIRST;
  ref_multi_i.uref.field_index := 0 ; ref_multi_u.uref.field_index := 0;
  ref_multi_i.uref.usage_index := 0 ; ref_multi_u.uref.usage_index := 0;
  ref_multi_i.num_values := DIMBUF ; ref_multi_u.num_values := DIMBUF;
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2301
    Original C:
      	typedef struct _HIDD_ATTRIBUTES {
      	    ULONG   Size;
      	    USHORT  VendorID;
      	    USHORT  ProductID;
      	    USHORT  VersionNumber;
      	} HIDD_ATTRIBUTES, *PHIDD_ATTRIBUTES;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2307
    Original C:
      	typedef void (__stdcall*GETHIDGUID) (OUT LPGUID HidGuid);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2308
    Original C:
      	typedef BOOLEAN (__stdcall*GETATTRIBUTES)(IN HANDLE HidDeviceObject,OUT PHIDD_ATTRIBUTES Attributes);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2309
    Original C:
      	typedef BOOLEAN (__stdcall*SETNUMINPUTBUFFERS)(IN  HANDLE HidDeviceObject,OUT ULONG  NumberBuffers);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2310
    Original C:
      	typedef BOOLEAN (__stdcall*GETNUMINPUTBUFFERS)(IN  HANDLE HidDeviceObject,OUT PULONG  NumberBuffers);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2311
    Original C:
      	typedef BOOLEAN (__stdcall*GETFEATURE) (IN  HANDLE HidDeviceObject, OUT PVOID ReportBuffer, IN ULONG ReportBufferLength);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2312
    Original C:
      	typedef BOOLEAN (__stdcall*SETFEATURE) (IN  HANDLE HidDeviceObject, IN PVOID ReportBuffer, IN ULONG ReportBufferLength);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2313
    Original C:
      	typedef BOOLEAN (__stdcall*GETREPORT) (IN  HANDLE HidDeviceObject, OUT PVOID ReportBuffer, IN ULONG ReportBufferLength);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2314
    Original C:
      	typedef BOOLEAN (__stdcall*SETREPORT) (IN  HANDLE HidDeviceObject, IN PVOID ReportBuffer, IN ULONG ReportBufferLength);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2315
    Original C:
      	typedef BOOLEAN (__stdcall*GETMANUFACTURERSTRING) (IN  HANDLE HidDeviceObject, OUT PVOID ReportBuffer, IN ULONG ReportBufferLength);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2316
    Original C:
      	typedef BOOLEAN (__stdcall*GETPRODUCTSTRING) (IN  HANDLE HidDeviceObject, OUT PVOID ReportBuffer, IN ULONG ReportBufferLength);
  *)
  LastDevice := False;
  MemberIndex := 0;
  Length := 0;
  detailData := nil;
  DeviceHandle := nil;
  hHID := 0;
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2327
    Original C:
      	GETHIDGUID HidD_GetHidGuid=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2328
    Original C:
      	GETATTRIBUTES HidD_GetAttributes=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2329
    Original C:
      	SETNUMINPUTBUFFERS HidD_SetNumInputBuffers=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2330
    Original C:
      	GETNUMINPUTBUFFERS HidD_GetNumInputBuffers=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2331
    Original C:
      	GETFEATURE HidD_GetFeature=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2332
    Original C:
      	SETFEATURE HidD_SetFeature=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2333
    Original C:
      	GETREPORT HidD_GetInputReport=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2334
    Original C:
      	SETREPORT HidD_SetOutputReport=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2335
    Original C:
      	GETMANUFACTURERSTRING HidD_GetManufacturerString=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2336
    Original C:
      	GETPRODUCTSTRING HidD_GetProductString=0;
  *)
  hHID := LoadLibrary('hid.dll');
  if  not hHID then
  begin
   // return value of PrintMessage() ignored
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
  if (HidD_GetHidGuid = NULL\) or (HidD_GetAttributes = NULL\) or (HidD_GetFeature = NULL\) or (HidD_SetFeature = NULL\) or (HidD_GetInputReport = NULL\) or (HidD_SetOutputReport = NULL\) or (HidD_GetManufacturerString = NULL\) or (HidD_GetProductString = NULL\) or (HidD_SetNumInputBuffers = NULL\) or (HidD_GetNumInputBuffers = nil) then
   Exit(0);
  hSAPI := 0;
  hSAPI := LoadLibrary('setupapi.dll');
  if  not hSAPI then
  begin
   // return value of PrintMessage() ignored
   PrintMessage('Can't find setupapi.dll');
   Exit(0);
  end;
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2368
    Original C:
      	typedef HDEVINFO (WINAPI* SETUPDIGETCLASSDEVS) (CONST GUID*,PCSTR,HWND,DWORD);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2369
    Original C:
      	typedef BOOL (WINAPI* SETUPDIENUMDEVICEINTERFACES) (HDEVINFO,PSP_DEVINFO_DATA,CONST GUID*,DWORD,PSP_DEVICE_INTERFACE_DATA);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2370
    Original C:
      	typedef BOOL (WINAPI* SETUPDIGETDEVICEINTERFACEDETAIL) (HDEVINFO,PSP_DEVICE_INTERFACE_DATA,PSP_DEVICE_INTERFACE_DETAIL_DATA_A,DWORD,PDWORD,PSP_DEVINFO_DATA);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2371
    Original C:
      	typedef BOOL (WINAPI* SETUPDIDESTROYDEVICEINFOLIST) (HDEVINFO);
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2372
    Original C:
      	SETUPDIGETCLASSDEVS SetupDiGetClassDevsA=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2373
    Original C:
      	SETUPDIENUMDEVICEINTERFACES SetupDiEnumDeviceInterfaces=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2374
    Original C:
      	SETUPDIGETDEVICEINTERFACEDETAIL SetupDiGetDeviceInterfaceDetailA=0;
  *)
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2375
    Original C:
      	SETUPDIDESTROYDEVICEINFOLIST SetupDiDestroyDeviceInfoList=0;
  *)
  SetupDiGetClassDevsA := GetProcAddress(hSAPI, 'SetupDiGetClassDevsA');
  SetupDiEnumDeviceInterfaces := GetProcAddress(hSAPI, 'SetupDiEnumDeviceInterfaces');
  SetupDiGetDeviceInterfaceDetailA := GetProcAddress(hSAPI, 'SetupDiGetDeviceInterfaceDetailA');
  SetupDiDestroyDeviceInfoList := GetProcAddress(hSAPI, 'SetupDiDestroyDeviceInfoList');
  if (SetupDiGetClassDevsA = NULL\) or (SetupDiEnumDeviceInterfaces = NULL\) or (SetupDiDestroyDeviceInfoList = NULL\) or (SetupDiGetDeviceInterfaceDetailA = nil) then
   Exit(0);
  // return value of HidD_GetHidGuid() ignored
  HidD_GetHidGuid(@( HidGuid ));
  hDevInfo := SetupDiGetClassDevs(@( HidGuid ), nil, nil, DIGCF_PRESENT or DIGCF_INTERFACEDEVICE);
  devInfoData.cbSize := sizeof(devInfoData);
  MemberIndex := 0;
  LastDevice := False;
  (* TODO gtk2laz: unrecognised statement
    Source: /home/z/my-project/opgui_src/opgui.c:2185
    Original C:
      				fprintf(f,"vid %X\n",vid);
      				fprintf(f,"pid %X\n",pid);
      			}
      			fclose(f);
      		}
      	}
      	return 0;
      }
      
      ///
      ///Find the USB peripheral with proper vid&pid code
      /// return 0 if not found
      int FindDevice(int vid,int pid){
      	int MyDeviceDetected = FALSE;
      #if !defined _WIN32 && !defined __CYGWIN__	//Linux
      	#ifndef hiddevIO	//use raw USB device
      	struct hidraw_devinfo device_info;
      	int i=-1;
      	if(path[0]==0){	//search all devices
      		if((fd = open("/dev/openprogrammer", O_RDWR|O_NONBLOCK))>0){ //try with this first
      			sprintf(path,"/dev/openprogrammer");
      			ioctl(fd, HIDIOCGRAWINFO, &device_info);
      			if(device_info.vendor==vid&&device_info.product==pid) i=0;
      			else{
      				close(fd);
      				i=-1;
      			}
      		}
      		if(i){
      			for(i=0;i<16;i++){
      				sprintf(path,"/dev/hidraw%d",i);
      				if((fd = open(path, O_RDWR|O_NONBLOCK))>0){
      					ioctl(fd, HIDIOCGRAWINFO, &device_info);
      					if(device_info.vendor==vid&&device_info.product==pid) break;
      					else close(fd);
      				}
      			}
      		}
      		if(i==16){
      			PrintMessage(strings[S_noprog]);
      			path[0]=0;
      			return 0;
      		}
      	}
      	else{	//user supplied path
      		if((fd = open(path, O_RDWR|O_NONBLOCK)) < 0) {
      			PrintMessage1(strings[S_DevPermission],path); //"cannot open %s, make sure you have read permission on it",path);
      			return 0;
      		}
      		ioctl(fd, HIDIOCGRAWINFO, &device_info);
      		if(device_info.vendor!=vid||device_info.product!=pid){
      			PrintMessage(strings[S_noprog]);
      			return 0;
      		}
      	}
      	printf(strings[S_progDev],path);
      	return 1;
      	#else		//use hiddev device (old method)
      	struct hiddev_devinfo device_info;
      	int i=-1;
      	if(path[0]==0){	//search all devices
      		if((fd = open("/dev/openprogrammer", O_RDONLY ))>0){ //try with this first
      			ioctl(fd, HIDIOCGDEVINFO, &device_info);
      			if(device_info.vendor==vid&&device_info.product==pid) i=0;
      			else{
      				close(fd);
      				i=-1;
      			}
      		}
      		if(i){
      		for(i=0;i<16;i++){
      			sprintf(path,"/dev/usb/hiddev%d",i);
      			if((fd = open(path, O_RDONLY ))>0){
      				ioctl(fd, HIDIOCGDEVINFO, &device_info);
      				if(device_info.vendor==vid&&device_info.product==pid) break;
      				else close(fd);
      				}
      			}
      		}
      		if(i==16){
      			PrintMessage(strings[S_noprog]);
      			path[0]=0;
      			return 0;
      		}
      	}
      	else{	//user supplied path
      		if ((fd = open(path, O_RDONLY )) < 0) {
      			PrintMessage1(strings[S_DevPermission],path); //"cannot open %s, make sure you have read permission on it",path);
      			return 0;
      		}
      		ioctl(fd, HIDIOCGDEVINFO, &device_info);
      		if(device_info.vendor!=vid||device_info.product!=pid){
      			PrintMessage(strings[S_noprog]);
      			return 0;
      		}
      	}
      	MyDeviceDetected = TRUE;
      	rep_info_u.report_type=HID_REPORT_TYPE_OUTPUT;
      	rep_info_i.report_type=HID_REPORT_TYPE_INPUT;
      	rep_info_u.report_id=rep_info_i.report_id=HID_REPORT_ID_FIRST;
      	rep_info_u.num_fields=rep_info_i.num_fields=1;
      	ref_multi_u.uref.report_type=HID_REPORT_TYPE_OUTPUT;
      	ref_multi_i.uref.report_type=HID_REPORT_TYPE_INPUT;
      	ref_multi_u.uref.report_id=ref_multi_i.uref.report_id=HID_REPORT_ID_FIRST;
      	ref_multi_u.uref.field_index=ref_multi_i.uref.field_index=0;
      	ref_multi_u.uref.usage_index=ref_multi_i.uref.usage_index=0;
      	ref_multi_u.num_values=ref_multi_i.num_values=DIMBUF;
      	#endif
  *)
  // return value of SetupDiDestroyDeviceInfoList() ignored
  SetupDiDestroyDeviceInfoList(hDevInfo);
  if MyDeviceDetected = False then
  begin
   // return value of PrintMessage() ignored
   PrintMessage(strings[S_noprog]);
  end
  else
  begin
   // return value of PrintMessage() ignored
   PrintMessage(strings[S_prog]);
   // return value of PrintMessage2() ignored
   PrintMessage2('VID=0x%04X PID=0x%04X' + #13 + '' + NL + '', vid, pid);
  end;
  Exit(MyDeviceDetected);
end;

end.
