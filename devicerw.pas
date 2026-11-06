unit devicerw;

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
  progp12,
  progp16,
  progp18,
  progp24,
  progeeprom,
  progavr,
  glib_types,
  gtk_types,
  libc_types,
  sys_types,
  mainform;

const
  NL = #10;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;
  TDEVICES = record
    family: Tfamily_t;
    HV: Double;
    V33: Integer;
    ReadPtr: procedure();
    ReadParam: array[0..4-1] of Integer;
    ResArea: Integer;
    WritePtr: procedure();
    WriteParam: array[0..6-1] of Integer;
    WriteParamD: Double;
  end;
  PDEVICES = ^TDEVICES;
  TDevInfo = record
    group: Tgroup_t;
    family: Tfamily_t;
    HV: Double;
    V33: Integer;
    size: Integer;
    sizeEE: Integer;
  end;
  PDevInfo = ^TDevInfo;
  Tfamily_t = (PIC12, PIC16, PIC18, PIC24, PIC32, AVR, I2CEE, SPIEE, UWEE, OWEE, UNIOEE, NUM_FAMILIES);
  Tgroup_t = (G_PIC_10_12, G_PIC_16, G_PIC_18, G_PIC_24, G_PIC_30_33, G_ATMEL, G_EEPROM, NUM_GROUPS);

type
  TDWORD = Cardinal;
  TWORD = Word;
  TBYTE = Byte;
  Tfp = PProcedure;

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
  devices: array of PChar;
  Ndevices: Integer;
  NDEVLIST: Integer;
  DEVLIST: array of TDEVICES;

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
function Read12F5xx(dim: Integer; dim2: Integer): Pointer;
function Write12F5xx(dim: Integer; OscAddr: Integer): Pointer;
function Write12C5xx(dim: Integer; dummy: Integer): Pointer;
function Read16Fxxx(dim: Integer; dim2: Integer; dim3: Integer; vdd: Integer): Pointer;
function Write12F6xx(dim: Integer; dim2: Integer): Pointer;
function Write12F61x(dim: Integer; d: Integer; d2: Integer): Pointer;
function Write12F62x(dim: Integer; dim2: Integer): Pointer;
function Write16F7x(dim: Integer; vdd: Integer): Pointer;
function Write16F71x(dim: Integer; vdd: Integer): Pointer;
function Write16F72x(dim: Integer; d: Integer; d2: Integer): Pointer;
function Write16F62x(dim: Integer; dim2: Integer): Pointer;
function Write16F8x(dim: Integer; dim2: Integer): Pointer;
function Write16F81x(dim: Integer; dim2: Integer): Pointer;
function Write16F87x(dim: Integer; dim2: Integer): Pointer;
function Write16F87xA(dim: Integer; dim2: Integer; seq: Integer): Pointer;
function Write16F88x(dim: Integer; dim2: Integer): Pointer;
function Read16F1xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer): Pointer;
function Write16F1xxx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Read16F18xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer): Pointer;
function Write16F18xxx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function DisplayCODE16F(size: Integer): Pointer;
function DisplayEE16F(size: Integer): Pointer;
function Read18Fx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Read18FKx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer): Pointer;
function Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer): Pointer;
function DisplayCODE18F(dim: Integer): Pointer;
function Read24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
function Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
function DisplayCODE24F(dim: Integer): Pointer;
procedure DisplayEE24F;
function Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
function Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
function ReadI2C(dim: Integer; addr: Integer): Pointer;
function WriteI2C(dim: Integer; addr: Integer; page: Integer): Pointer;
function Read93x(dim: Integer; na: Integer; options: Integer): Pointer;
function Write93Sx(dim: Integer; na: Integer; page: Integer): Pointer;
function Write93Cx(dim: Integer; na: Integer; options: Integer): Pointer;
function Read25xx(dim: Integer): Pointer;
function Write25xx(dim: Integer; options: Integer): Pointer;
function ReadOneWireMem(dim: Integer; options: Integer): Pointer;
function WriteOneWireMem(dim: Integer; options: Integer): Pointer;
procedure ReadDS1820;
function Read11xx(dim: Integer): Pointer;
function Write11xx(dim: Integer; page: Integer): Pointer;
function ReadAT(dim: Integer; dim2: Integer; options: Integer): Pointer;
function ReadAT_HV(dim: Integer; dim2: Integer; options: Integer): Pointer;
function WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer): Pointer;
function WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
function WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
function DisplayCODEAVR(dim: Integer): Pointer;
function WriteATfuseSlow(fuse: Integer): Pointer;
function nameToGroup(devName: PChar): Tgroup_t;
function populateDevInfo(info: PDevInfo; devlistEntry: PDEVICES): Pointer;
function GetDevInfo(dev: PChar): TDevInfo;
function ListDevices: PChar;
function GetDevType(device: PChar): Integer;
function GetDevInfo(dev: PChar): TDevInfo;
function Write_(dev: PChar; ee: Integer): Pointer;
function Read_(dev: PChar; ee: Integer; r: Integer): Pointer;
function ListDevices: PChar;
procedure CheckDevices;
function Read_(dev: PChar; ee: Integer; r: Integer): Pointer;
function Write_(dev: PChar; ee: Integer): Pointer;
function GetDevType(dev: PChar): Integer;
function nameToGroup(devName: PChar): Tgroup_t;
function populateDevInfo(info: PDevInfo; devlistEntry: PDEVICES): Pointer;
function GetDevInfo(dev: PChar): TDevInfo;

implementation

function ListDevices: PChar;
var
  i: Integer;
  len: Integer;
  l: Integer;
  last: array[0..8-1] of Char;
  list: PChar;
begin
  len := 0;
  last := '';
  list := 0;
  for i := 0 to (Ndevices) - 1 do
  begin
   l := strlen(devices[i]);
   if not (last[0]) then
   begin
    list := realloc(list, len + l + 1);
    strcpy(list + len, devices[i]);
    len := len + l;
   end
   else
   begin
    list := realloc(list, len + l + 3);
    if strncmp(devices[i], last, 2) then
     strcpy(list + len, ',' + NL + '')
    else
     strcpy(list + len, ', ');
    strcpy(list + len + 2, devices[i]);
    len := len + l + 2;
   end;
   last[0] := devices[i][0];
   last[1] := devices[i][1];
   last[2] := 0;
  end;
  Exit(list);
end;

procedure CheckDevices;
var
  i: Integer;
begin
  for i := 0 to (Ndevices) - 1 do
  begin
   if GetDevType(devices[i]) < 0 then
   begin
    printf('Can't find %s' + NL + '', devices[i]);
    fflush(stdout);
   end;
  end;
  printf('OK %d devices' + NL + '', Ndevices);
  fflush(stdout);
end;

function Read_(dev: PChar; ee: Integer; r: Integer): Pointer;
var
  i: Integer;
  j: Integer;
  params: array[0..5-1] of Integer;
  str: PChar;
  tok: PChar;
begin
  str := 0;
  for i := 0 to (SizeOf(DEVLIST) div SizeOf(DEVLIST[0])) - 1 do
  begin
   if str then
    free(str);
   str := malloc(strlen(DEVLIST[i].device) + 1);
   strcpy(str, DEVLIST[i].device);
   tok := strtok(str, ',');
   while tok do
   begin
    if not (strcmp(dev, tok)) then
    begin
     for j := 0 to (4) - 1 do
     begin
      params[j] := DEVLIST[i].ReadParam[j];
     end;
     if DEVLIST[i].V33 > 0 then
     begin
      if not (CheckV33Regulator()) then
      begin
       PrintMessage(strings[S_noV33reg]);
       Exit;
      end;
     end;
     if hvreg <> DEVLIST[i].HV then
      hvreg := IfThen(StartHVReg(DEVLIST[i].HV) > 0, DEVLIST[i].HV, 0);
     if DEVLIST[i].ReadPtr = 0 then
     begin
      PrintMessage(strings[S_nodev_r]);
      Exit;
     end;
     case DEVLIST[i].family of
      PIC12:
      begin
       if r then
        params[1] := DEVLIST[i].ResArea;
       DEVLIST[i].ReadPtr(params[0], params[1]);
      end;
      PIC16:
      begin
       if r then
        params[2] := DEVLIST[i].ResArea;
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].ReadPtr(params[0], params[1], params[2], params[3]);
      end;
      PIC18:
      begin
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].ReadPtr(params[0], params[1], params[2]);
      end;
      PIC24:
      begin
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].ReadPtr(params[0], params[1], params[2], params[3], IfThen(r, DEVLIST[i].ResArea, 0));
      end;
      PIC32:
      begin
       DEVLIST[i].ReadPtr(params[0], params[1]);
      end;
      AVR:
      begin
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].ReadPtr(params[0], params[1], params[2]);
      end;
      I2CEE:
      begin
       DEVLIST[i].ReadPtr(params[0], params[1]);
      end;
      UWEE:
      begin
       DEVLIST[i].ReadPtr(params[0], params[1], params[2]);
      end;
      SPIEE:
      begin
       DEVLIST[i].ReadPtr(params[0]);
      end;
      OWEE:
      begin
       if params[0] = -10 then
        DEVLIST[i].ReadPtr^()
       else
        DEVLIST[i].ReadPtr(params[0], params[1]);
      end;
      UNIOEE:
      begin
       DEVLIST[i].ReadPtr(params[0]);
      end;
      else
      begin
       PrintMessage(strings[S_nodev_r]);
      end;
     end;
     Exit;
    end;
    tok := strtok(nil, ',');
   end;
  end;
  PrintMessage(strings[S_nodev_r]);
end;

function Write_(dev: PChar; ee: Integer): Pointer;
var
  i: Integer;
  j: Integer;
  params: array[0..6-1] of Integer;
  str: PChar;
  tok: PChar;
begin
  str := 0;
  for i := 0 to (SizeOf(DEVLIST) div SizeOf(DEVLIST[0])) - 1 do
  begin
   if str then
    free(str);
   str := malloc(strlen(DEVLIST[i].device) + 1);
   strcpy(str, DEVLIST[i].device);
   tok := strtok(str, ',');
   while tok do
   begin
    if not (strcmp(dev, tok)) then
    begin
     for j := 0 to (6) - 1 do
     begin
      params[j] := DEVLIST[i].WriteParam[j];
     end;
     if DEVLIST[i].V33 > 0 then
     begin
      if not (CheckV33Regulator()) then
      begin
       PrintMessage(strings[S_noV33reg]);
       Exit;
      end;
     end;
     if hvreg <> DEVLIST[i].HV then
      hvreg := IfThen(StartHVReg(DEVLIST[i].HV) > 0, DEVLIST[i].HV, 0);
     if DEVLIST[i].WritePtr = 0 then
     begin
      PrintMessage(strings[S_nodev_w]);
      Exit;
     end;
     case DEVLIST[i].family of
      PIC12:
      begin
       DEVLIST[i].WritePtr(params[0], params[1]);
      end;
      PIC16:
      begin
       if not (ee) then
        params[1] := 0;
       if params[2] = -10 then
        DEVLIST[i].WritePtr(params[0], params[1])
       else
        DEVLIST[i].WritePtr(params[0], params[1], params[2]);
      end;
      PIC18:
      begin
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].WritePtr(params[0], params[1], params[2], params[3], params[4], params[5]);
      end;
      PIC24:
      begin
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].WritePtr(params[0], params[1], params[2], params[3], params[4], DEVLIST[i].WriteParamD);
      end;
      AVR:
      begin
       if not (ee) then
        params[1] := 0;
       DEVLIST[i].WritePtr(params[0], params[1], params[2], params[3]);
      end;
      I2CEE:
      begin
       DEVLIST[i].WritePtr(params[0], params[1], params[2]);
      end;
      UWEE:
      begin
       DEVLIST[i].WritePtr(params[0], params[1], params[2]);
      end;
      SPIEE:
      begin
       DEVLIST[i].WritePtr(params[0], params[1]);
      end;
      OWEE:
      begin
       DEVLIST[i].WritePtr(params[0], params[1]);
      end;
      UNIOEE:
      begin
       DEVLIST[i].WritePtr(params[0], params[1]);
      end;
      else
      begin
       PrintMessage(strings[S_nodev_w]);
      end;
     end;
     Exit;
    end;
    tok := strtok(nil, ',');
   end;
  end;
  PrintMessage(strings[S_nodev_w]);
end;

function GetDevType(dev: PChar): Integer;
var
  i: Integer;
  type_: Integer;
  str: PChar;
  tok: PChar;
begin
  type_ := -1;
  str := 0;
  for i := 0 to (SizeOf(DEVLIST) div SizeOf(DEVLIST[0])) - 1 do
  begin
   if str then
    free(str);
   str := malloc(strlen(DEVLIST[i].device) + 1);
   strcpy(str, DEVLIST[i].device);
   tok := strtok(str, ',');
   while tok do
   begin
    if not (strcmp(dev, tok)) then
    begin
     type_ := DEVLIST[i].family;
     tok := 0;
     i := SizeOf(DEVLIST) div SizeOf(DEVLIST[0]);
    end;
    tok := strtok(nil, ',');
   end;
  end;
  free(str);
  Exit(type_);
end;

function nameToGroup(devName: PChar): Tgroup_t;
var
  // (no local variables detected)
begin
  if not (strncmp(devName, '10F', 3)) or not (strncmp(devName, '12F', 3)) or not (strncmp(devName, '12C', 3)) or not (strncmp(devName, '12LF', 4)) then
   Exit(G_PIC_10_12);
  if not (strncmp(devName, '16F', 3)) or not (strncmp(devName, '16LF', 4)) or not (strncmp(devName, '16C', 3)) then
   Exit(G_PIC_16);
  if not (strncmp(devName, '18F', 3)) then
   Exit(G_PIC_18);
  if not (strncmp(devName, '24F', 3)) or not (strncmp(devName, '24H', 3)) or not (strncmp(devName, '24E', 3)) then
   Exit(G_PIC_24);
  if not (strncmp(devName, '30F', 3)) or not (strncmp(devName, '33F', 3)) or not (strncmp(devName, '33E', 3)) then
   Exit(G_PIC_30_33);
  if not (strncmp(devName, 'AT', 2)) then
   Exit(G_ATMEL);
  if not (strncmp(devName, '24', 2)) or not (strncmp(devName, '25', 2)) or not (strncmp(devName, '93', 2)) or not (strncmp(devName, '95', 2)) or not (strncmp(devName, '11', 2)) or not (strncmp(devName, 'DS', 2)) then
   Exit(G_EEPROM);
  sprintf(str, 'can't determine group of device '%s'' + NL + '', devName);
  PrintMessage(str);
  Exit(-1);
end;

function populateDevInfo(info: PDevInfo; devlistEntry: PDEVICES): Pointer;
var
  str2: array[0..256-1] of Char;
  str3: array[0..64-1] of Char;
  strF: array[0..32-1] of Char;
  x: Double;
  ee: Integer;
begin
  info^.family := devlistEntry^.family;
  info^.HV := devlistEntry^.HV;
  info^.V33 := devlistEntry^.V33;
  info^.size := devlistEntry^.ReadParam[0];
  info^.sizeEE := devlistEntry^.WriteParam[1];
  str2[0] := 0;
  x := info^.size div 1024.0;
  if x - x then
   sprintf(strF, '%.1f', x)
  else
   sprintf(strF, '%d', x);
  case info^.family of
   PIC12:
   begin
    sprintf(str2, 'PIC12, ');
    if info^.size < 1024 then
     sprintf(str3, '%dW FLASH', info^.size)
    else
     sprintf(str3, '%sKW FLASH', strF);
    strcat(str2, str3);
   end;
   PIC16:
   begin
    sprintf(str2, 'PIC16, ');
    if info^.size < 1024 then
     sprintf(str3, '%dW FLASH', info^.size)
    else
     sprintf(str3, '%sKW FLASH', strF);
    strcat(str2, str3);
    if info^.sizeEE then
    begin
     ee := info^.sizeEE;
     if ee < 0 then
      ee := -ee;
     sprintf(str3, ' + %dB EEPROM', ee);
     strcat(str2, str3);
    end;
   end;
   PIC18:
   begin
    sprintf(str2, 'PIC18, ');
    if info^.size < 1024 then
     sprintf(str3, '%dB FLASH ', info^.size)
    else
     sprintf(str3, '%sKB FLASH ', strF);
    strcat(str2, str3);
    if info^.sizeEE then
    begin
     sprintf(str3, '+ %dB EEPROM ', info^.sizeEE);
     strcat(str2, str3);
    end;
   end;
   PIC24:
   begin
    sprintf(str2, 'PIC24, ');
    if info^.size < 1024 then
     sprintf(str3, '%dW FLASH', info^.size)
    else
     sprintf(str3, '%sKW FLASH', strF);
    strcat(str2, str3);
    if info^.sizeEE then
    begin
     sprintf(str3, ' + %dB EEPROM', info^.sizeEE);
     strcat(str2, str3);
    end;
   end;
   PIC32:
   begin
    sprintf(str2, 'PIC32, ');
    if info^.size < 1024 then
     sprintf(str3, '%dW FLASH', info^.size)
    else
     sprintf(str3, '%sKW FLASH', strF);
    strcat(str2, str3);
    if info^.sizeEE then
    begin
     sprintf(str3, ' + %dB EEPROM', info^.sizeEE);
     strcat(str2, str3);
    end;
   end;
   AVR:
   begin
    sprintf(str2, 'AVR, ');
    if info^.size < 1024 then
     sprintf(str3, '%dB FLASH', info^.size)
    else
     sprintf(str3, '%sKB FLASH', strF);
    strcat(str2, str3);
    if info^.sizeEE then
    begin
     sprintf(str3, ' + %dB EEPROM', info^.sizeEE);
     strcat(str2, str3);
    end;
   end;
   I2CEE:
   begin
    if info^.size < 1024 then
     sprintf(str2, '%s, %dB', strings[I_I2CMEM], info^.size)
    else
     sprintf(str2, '%s, %sKB', strings[I_I2CMEM], strF);
   end;
   SPIEE:
   begin
    if info^.size < 1024 then
     sprintf(str2, '%s, %dB', strings[I_SPIMEM], info^.size)
    else
     sprintf(str2, '%s, %sKB', strings[I_SPIMEM], strF);
   end;
   UWEE:
   begin
    if info^.size < 1024 then
     sprintf(str2, '%s, %dB', strings[I_UWMEM], info^.size)
    else
     sprintf(str2, '%s,%sKB', strings[I_UWMEM], strF);
   end;
   OWEE:
   begin
    if info^.size < 0 then
     sprintf(str2, strings[I_OWDEV])
    else
     if info^.size < 1024 then
      sprintf(str2, '%s, %dB', strings[I_OWMEM], info^.size)
     else
      sprintf(str2, '%s, %sKB', strings[I_OWMEM], strF);
   end;
   UNIOEE:
   begin
    if info^.size < 1024 then
     sprintf(str2, '%s, %dB', strings[I_UNIOMEM], info^.size)
    else
     sprintf(str2, '%s, %sKB', strings[I_UNIOMEM], strF);
   end;
   else
   begin
    sprintf(str2, '!!unknown family!!');
   end;
  end;
  if info^.HV > 0 then
  begin
   sprintf(str3, ', %.1fV', info^.HV);
   strcat(str2, str3);
  end;
  if info^.V33 then
  begin
   strcat(str2, ', ');
   strcat(str2, strings[I_3V3REQUIRED]);
  end;
  info^.features := malloc(strlen(str2) + 1);
  strcpy(info^.features, str2);
end;

function GetDevInfo(dev: PChar): TDevInfo;
var
  i: Integer;
  str: PChar;
  tok: PChar;
  info: TDevInfo;
begin
  str := 0;
  info.device := 0;
  info.family := -1;
  info.HV := -1;
  info.V33 := -1;
  info.size := -1;
  info.sizeEE := -1;
  info.features := 0;
  for i := 0 to (NDEVLIST) - 1 do
  begin
   str := malloc(strlen(DEVLIST[i].device) + 1);
   strcpy(str, DEVLIST[i].device);
   tok := strtok(str, ',');
   while tok do
   begin
    if not (strcmp(dev, tok)) then
    begin
     info.device := malloc(strlen(tok) + 1);
     strcpy(info.device, tok);
     info.group := nameToGroup(info.device);
     populateDevInfo(@info, @(DEVLIST[i]));
     free(str);
     Exit(info);
    end;
    tok := strtok(nil, ',');
   end;
   free(str);
  end;
  Exit(info);
end;

end.
