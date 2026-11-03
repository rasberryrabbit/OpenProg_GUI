unit progp16;

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
  glib_types,
  gtk_types,
  libc_types,
  sys_types;

const
  NL = #10;
  LOAD_PC_ADDR = $80;
  BULK_ERASE_PROGRAM_MEM = $18;
  ROW_ERASE_PROGRAM_MEM = $F0;
  LOAD_NVM = $00;
  LOAD_NVM_INC = $02;
  READ_NVM = $FC;
  READ_NVM_INC = $FE;
  INC_ADDR8 = $F8;
  BEGIN_INT_PROG = $E0;
  BEGIN_EXT_PROG = $C0;
  END_EXT_PROG = $82;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  PIC16LIST: array of TID16;

// --- function declarations ---
function PIC16_ID(id: Integer): Pointer;
function DisplayCODE16F(size: Integer): Pointer;
function DisplayEE16F(size: Integer): Pointer;
function Read16Fxxx(dim: Integer; dim2: Integer; dim3: Integer; vdd: Integer): Pointer;
function Read16F1xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer): Pointer;
function Read16F18xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer): Pointer;
function Write12F6xx(dim: Integer; dim2: Integer): Pointer;
function Write16F8x(dim: Integer; dim2: Integer): Pointer;
function Write16F62x(dim: Integer; dim2: Integer): Pointer;
function Write12F62x(dim: Integer; dim2: Integer): Pointer;
function Write16F87x(dim: Integer; dim2: Integer): Pointer;
function Write16F87xA(dim: Integer; dim2: Integer; seq: Integer): Pointer;
function Write16F81x(dim: Integer; dim2: Integer): Pointer;
function Write12F61x(dim: Integer; d: Integer; d2: Integer): Pointer;
function Write16F88x(dim: Integer; dim2: Integer): Pointer;
function Write16F7x(dim: Integer; vdd: Integer): Pointer;
function Write16F71x(dim: Integer; vdd: Integer): Pointer;
function Write16F72x(dim: Integer; d: Integer; d2: Integer): Pointer;
function Write16F1xxx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Write16F18xxx(dim: Integer; dim2: Integer; options: Integer): Pointer;

implementation

function PIC16_ID(id: Integer): Pointer;
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to ((SizeOf(PIC16LIST)) div (SizeOf(PIC16LIST[0]))) - 1 do
  begin
   if (PIC16LIST[i].revmask) and (((id) shr (5)) = (PIC16LIST[i].id)) then
   begin
    sprintf(s, PIC16LIST[i].device, (id) and (PIC16LIST[i].revmask));
    PrintMessage(s);
    Exit;
   end
   else
    if (not (PIC16LIST[i].revmask)) and ((id) = (PIC16LIST[i].id)) then
    begin
     sprintf(s, PIC16LIST[i].device);
     PrintMessage(s);
     Exit;
    end;
  end;
  sprintf(s, '%s', strings[S_nodev]);
  PrintMessage(s);
end;

function DisplayCODE16F(size: Integer): Pointer;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
begin
  s := '';
  t := '';
  aux := malloc((((size) div (16)) + (1)) * ((16) + ((16) * (5))));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  i := 0;
  while ((i) < (size)) and ((i) < (sizeW)) do
  begin
   valid := 0;
   j := i;
   while (((j) < ((i) + (16))) and ((j) < (sizeW))) and ((i) < (size)) do
   begin
    sprintf(t, '%04X ', memCODE_W[j]);
    strcat(s, t);
    if ((memCODE_W[j]) and ($3fff)) < ($3fff) then
     valid := 1;
    Inc(j);
   end;
   if valid then
   begin
    sprintf(t, '%04X: %s' + #13 + '' + NL + '', i, s);
    empty := 0;
    strcat(aux, t);
    Inc(lines);
    if (lines) > (500) then
    begin
     strcat(aux, '(...)' + #13 + '' + NL + '');
     i := (IfThen((sizeW) < (size), sizeW, size)) - ((16) * (2));
     lines := 490;
    end;
   end;
   s[0] := 0;
   Inc(i, 16);
  end;
  if empty then
   PrintMessage(strings[S_Empty])
  else
   PrintMessage(aux);
  free(aux);
end;

function DisplayEE16F(size: Integer): Pointer;
var
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  v: array[0..256-1] of Char;
  aux: PChar;
  g: PChar;
begin
  valid := 0;
  empty := 1;
  s := '';
  t := '';
  v := '';
  aux := malloc((((size) div (16)) + (1)) * ((16) + ((16) * (5))));
  aux[0] := 0;
  empty := 1;
  v[0] := 0;
  i := $2100;
  while ((i) < (($2100) + (size))) and ((i) < (sizeW)) do
  begin
   valid := 0;
   j := i;
   while (((j) < ((i) + (16))) and ((j) < (($2100) + (size)))) and ((j) < (sizeW)) do
   begin
    sprintf(t, '%02X ', (memCODE_W[j]) and ($ff));
    strcat(s, t);
    sprintf(t, '%c', IfThen((isprint((memCODE_W[j]) and ($FF))) and (((memCODE_W[j]) and ($FF)) < ($FF)), (memCODE_W[j]) and ($FF), #46));
    g := g_locale_to_utf8(t, -(1), NULL, NULL, NULL);
    if g then
     strcat(v, g);
    g_free(g);
    if ((memCODE_W[j]) and ($FF)) < ($ff) then
     valid := 1;
    Inc(j);
   end;
   if valid then
   begin
    sprintf(t, '%04X: %s %s' + #13 + '' + NL + '', i, s, v);
    empty := 0;
    strcat(aux, t);
   end;
   s[0] := 0;
   v[0] := 0;
   Inc(i, 16);
  end;
  if empty then
   PrintMessage(strings[S_Empty])
  else
   PrintMessage(aux);
  free(aux);
end;

function Read16Fxxx(dim: Integer; dim2: Integer; dim3: Integer; vdd: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  ee2200: Integer;
  s: array[0..512-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  start: Cardinal;
  stop: Cardinal;
  valid: Integer;
  empty: Integer;
begin
  k := 0;
  k2 := 0;
  z := 0;
  ee2200 := 0;
  if (dim2) < (0) then
  begin
   dim2 := -(dim2);
   ee2200 := 1;
  end;
  if ((dim) > ($2000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($400)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if ((dim3) > ($100)) or ((dim3) < (0)) then
  begin
   PrintMessage(strings[S_ConfigLim]);
   Exit;
  end;
  if (dim3) < (8) then
   dim3 := 8;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read16Fxxx(%d,%d,%d,%d)' + NL + '', dim, dim2, dim3, vdd);
  end;
  sizeW := ($2100) + (dim2);
  if memCODE_W then
   free(memCODE_W);
  memCODE_W := malloc((SizeOf(WORD)) * (sizeW));
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
  end
  else
   if (vdd) = (1) then
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := (25000) shr (8);
    bufferU[Inc(j)] := (25000) and ($ff);
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := (2000) shr (8);
    bufferU[Inc(j)] := (2000) and ($ff);
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end
   else
    if (vdd) = (2) then
    begin
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := $5;
    end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(vdd, 55, 5));
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeReading1]);
  j := 0;
  for i := 0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   if ((j) > ((((64) * (2)) div (4)) - (3))) or ((i) = ((dim) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($14) then
     begin
      memCODE_W[Inc(k)] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((i) * (100)) div (((dim) + (dim2)) + (dim3)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  if (k) <> (dim) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  for i := k to ($2000) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_Read_CONFIG_A]);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  for i := $2000 to (($2000) + (dim3)) - 1 do
  begin
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   if ((j) > ((((64) * (2)) div (4)) - (3))) or ((i) = ((($2000) + (dim3)) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($14) then
     begin
      memCODE_W[($2000) + (Inc(k2))] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((((i) - ($2000)) + (dim)) * (100)) div (((dim) + (dim2)) + (dim3)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if (k2) <> (dim3) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigErr], dim3, k2);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  for i := ($2000) + (k2) to (($2000) + (dim3)) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  if dim2 then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ReadEE]);
   if ee2200 then
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $FF;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := ($100) - (dim3);
   k2 := 0;
   i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    bufferU[Inc(j)] := $15;
    bufferU[Inc(j)] := $16;
    if ((j) > ((((64) * (2)) div (3)) - (3))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(8);
     for z := 0 to ((64) - (1)) - 1 do
     begin
      if (bufferI[z]) = ($15) then
      begin
       memCODE_W[($2100) + (Inc(k2))] := bufferI[(z) + (1)];
       Inc(z);
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((((i) - ($2100)) + (dim)) * (100)) div (((dim) + (dim2)) + (dim3)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
    Inc(i);
   end;
   if (k2) <> (dim2) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadEEErr], dim2, k2);
    PrintMessage(str);
    for i := ($2100) + (k2) to (($2100) + (dim2)) - 1 do
    begin
     memCODE_W[i] := $3fff;
    end;
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  i := 0;
  while (i) < (4) do
  begin
   sprintf(str, 'ID%d: 0x%04X' + #9 + 'ID%d: 0x%04X' + #13 + '' + NL + '', i, memCODE_W[($2000) + (i)], (i) + (1), memCODE_W[(($2000) + (i)) + (1)]);
   PrintMessage(str);
   Inc(i, 2);
  end;
  sprintf(str, strings[S_DevID], memCODE_W[$2006]);
  PrintMessage(str);
  if (memCODE_W[$2005]) < ($3FFF) then
  begin
   sprintf(str, strings[S_DevREV], memCODE_W[$2005]);
   PrintMessage(str);
  end;
  PIC16_ID(memCODE_W[$2006]);
  sprintf(str, strings[S_ConfigWord], memCODE_W[$2007]);
  PrintMessage(str);
  if (dim3) > (8) then
  begin
   sprintf(str, strings[S_Config2Cal1], memCODE_W[$2008]);
   PrintMessage(str);
  end;
  if (dim3) > (9) then
  begin
   sprintf(str, strings[S_Calib1_2], memCODE_W[$2009]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeMem2]);
  DisplayCODE16F(dim);
  s[0] := 0;
  valid := 0;
  empty := 1;
  if (dim3) > (8) then
  begin
   aux := malloc((((dim3) div (16)) + (1)) * ((16) + ((16) * (5))));
   aux[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ConfigResMem]);
   i := $2000;
   while (i) < (($2000) + (dim3)) do
   begin
    valid := 0;
    j := i;
    while ((j) < ((i) + (16))) and ((j) < (($2000) + (dim3))) do
    begin
     sprintf(t, '%04X ', memCODE_W[j]);
     strcat(s, t);
     if (memCODE_W[j]) < ($3fff) then
      valid := 1;
     Inc(j);
    end;
    if valid then
    begin
     snprintf(t, SizeOf(t), '%04X: %s' + #13 + '' + NL + '', i, s);
     empty := 0;
     strcat(aux, t);
    end;
    s[0] := 0;
    Inc(i, 16);
   end;
   if empty then
    PrintMessage(strings[S_Empty])
   else
    PrintMessage(aux);
   free(aux);
  end;
  if dim2 then
  begin
   PrintMessage(strings[S_EEMem]);
   DisplayEE16F(dim2);
  end;
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Read16F1xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  F18x: Integer;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  start: Cardinal;
  stop: Cardinal;
  valid: Integer;
  empty: Integer;
begin
  k := 0;
  k2 := 0;
  z := 0;
  F18x := (options) and (16);
  if (F18x) and ((FWVersion) < ($A00)) then
  begin
   sprintf(str, strings[S_FWver2old], '0.10.0');
   PrintMessage(str);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if ((dim) > ($8000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($400)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if ((dim3) > ($200)) or ((dim3) < (0)) then
  begin
   PrintMessage(strings[S_ConfigLim]);
   Exit;
  end;
  if (dim3) < (11) then
   dim3 := 11;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read16F1xxx(%d,%d,%d,%d)' + NL + '', dim, dim2, dim3, options);
  end;
  if ((options) and (2)) = (0) then
  begin
   if not (StartHVReg(8.5)) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end
   else
    hvreg := 8.5;
  end
  else
   StartHVReg(-(1));
  sizeW := $8200;
  if F18x then
   sizeW := $E004;
  sizeEE := dim2;
  if memCODE_W then
   free(memCODE_W);
  memCODE_W := malloc((SizeOf(WORD)) * (sizeW));
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  if memEE then
   free(memEE);
  memEE := malloc(sizeEE);
  for i := 0 to (sizeEE) - 1 do
  begin
   memEE[i] := $FF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  if ((options) and (2)) = (0) then
  begin
   if ((options) and (1)) = (0) then
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeReading1]);
  j := 0;
  for i := 0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   if ((j) > ((((64) * (2)) div (4)) - (3))) or ((i) = ((dim) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($14) then
     begin
      memCODE_W[Inc(k)] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((i) * (100)) div (((dim) + (dim2)) + (dim3)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  if (k) <> (dim) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_Read_CONFIG_A]);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  for i := $8000 to (($8000) + (dim3)) - 1 do
  begin
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   if ((j) > ((((64) * (2)) div (4)) - (3))) or ((i) = ((($8000) + (dim3)) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($14) then
     begin
      memCODE_W[($8000) + (Inc(k2))] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((((i) - ($8000)) + (dim)) * (100)) div (((dim) + (dim2)) + (dim3)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if (k2) <> (dim3) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigErr], dim3, k2);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if F18x then
  begin
   k2 := 0;
   PrintMessage(strings[S_Read_CONFIG_A]);
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $E0;
   bufferU[Inc(j)] := $00;
   for i := 0 to (4) - 1 do
   begin
    bufferU[Inc(j)] := $52;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   for z := 0 to ((64) - (2)) - 1 do
   begin
    if (bufferI[z]) = ($52) then
    begin
     memCODE_W[($E000) + (Inc(k2))] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
     z := z + 2;
    end;
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'Calibration area @0xE000' + NL + '');
   end;
   if (k2) <> (4) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigErr], dim3, k2);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  if (dim2) and (not (F18x)) then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ReadEE]);
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $16;
   for i := (k := 0) to (dim2) - 1 do
   begin
    bufferU[Inc(j)] := $15;
    bufferU[Inc(j)] := $16;
    if ((j) > ((((64) * (2)) div (3)) - (3))) or ((i) = ((dim2) - (1))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to ((64) - (1)) - 1 do
     begin
      if (bufferI[z]) = ($15) then
      begin
       memEE[Inc(k)] := bufferI[(z) + (1)];
       Inc(z);
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((i) * (100)) div (((dim) + (dim2)) + (dim3)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
    end;
   end;
   if (i) <> (dim2) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadEEErr], dim2, i);
    PrintMessage(str);
    while (i) < (dim2) do
    begin
     memEE[i] := $ff;
     Inc(i);
    end;
   end
   else
    PrintMessage(strings[S_Compl]);
  end
  else
   if (dim2) and (F18x) then
   begin
    PrintMessage(strings[S_ReadEE]);
    if saveLog then
     fprintf(logfile, strings[S_sepLine]);
    if saveLog then
     fprintf(logfile, '%s' + NL + '', strings[S_ReadEE]);
    bufferU[Inc(j)] := $50;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := $00;
    for i := (k := 0) to (dim2) - 1 do
    begin
     bufferU[Inc(j)] := $52;
     if ((j) > (((64) div (3)) - (3))) or ((i) = ((dim2) - (1))) then
     begin
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(5);
      for z := 0 to ((64) - (1)) - 1 do
      begin
       if (bufferI[z]) = ($52) then
       begin
        memEE[Inc(k)] := bufferI[(z) + (2)];
        z := z + 2;
       end;
      end;
      sprintf(str, strings[S_CodeReading], ((i) * (100)) div (((dim) + (dim2)) + (dim3)), i);
      gtk_statusbar_push(status_bar, statusID, str);
      while gtk_events_pending() do
      begin
       gtk_main_iteration();
      end;
      j := 0;
      if saveLog then
      begin
       fprintf(logfile, strings[S_Log7], i, i, k, k);
      end;
     end;
    end;
    if (i) <> (dim2) then
    begin
     PrintMessage('' + #13 + '' + NL + '');
     sprintf(str, strings[S_ReadEEErr], dim2, i);
     PrintMessage(str);
     while (i) < (dim2) do
     begin
      memEE[i] := $ff;
      Inc(i);
     end;
    end
    else
     PrintMessage(strings[S_Compl]);
   end;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  i := 0;
  while (i) < (4) do
  begin
   sprintf(str, 'ID%d: 0x%04X' + #9 + 'ID%d: 0x%04X' + #13 + '' + NL + '', i, memCODE_W[($8000) + (i)], (i) + (1), memCODE_W[(($8000) + (i)) + (1)]);
   PrintMessage(str);
   Inc(i, 2);
  end;
  sprintf(str, strings[S_DevID], memCODE_W[$8006]);
  PrintMessage(str);
  if (memCODE_W[$8005]) < ($3FFF) then
  begin
   sprintf(str, strings[S_DevREV], memCODE_W[$8005]);
   PrintMessage(str);
  end;
  PIC16_ID(memCODE_W[$8006]);
  sprintf(str, strings[S_ConfigWordX], 1, memCODE_W[$8007]);
  PrintMessage(str);
  sprintf(str, strings[S_ConfigWordX], 2, memCODE_W[$8008]);
  PrintMessage(str);
  if (((options) and ($C)) = (0)) and ((F18x) = (0)) then
  begin
   sprintf(str, strings[S_CalibWordX], 1, memCODE_W[$8009]);
   PrintMessage(str);
   sprintf(str, strings[S_CalibWordX], 2, memCODE_W[$800A]);
   PrintMessage(str);
   if (memCODE_W[$800B]) < ($3FFF) then
   begin
    sprintf(str, strings[S_CalibWordX], 3, memCODE_W[$800B]);
    PrintMessage(str);
   end;
  end
  else
   if (((options) and ($C)) = (4)) and ((F18x) = (0)) then
   begin
    sprintf(str, strings[S_ConfigWordX], 3, memCODE_W[$8009]);
    PrintMessage(str);
    sprintf(str, strings[S_CalibWordX], 1, memCODE_W[$800A]);
    PrintMessage(str);
    sprintf(str, strings[S_CalibWordX], 2, memCODE_W[$800B]);
    PrintMessage(str);
    sprintf(str, strings[S_CalibWordX], 3, memCODE_W[$800C]);
    PrintMessage(str);
   end
   else
    if ((options) and ($C)) = (8) then
    begin
     sprintf(str, strings[S_ConfigWordX], 3, memCODE_W[$8009]);
     PrintMessage(str);
     sprintf(str, strings[S_ConfigWordX], 4, memCODE_W[$800A]);
     PrintMessage(str);
    end;
  if F18x then
  begin
   sprintf(str, strings[S_CalibWordX], 1, memCODE_W[$E000]);
   PrintMessage(str);
   sprintf(str, strings[S_CalibWordX], 2, memCODE_W[$E001]);
   PrintMessage(str);
   sprintf(str, strings[S_CalibWordX], 3, memCODE_W[$E002]);
   PrintMessage(str);
   sprintf(str, strings[S_CalibWordX], 4, memCODE_W[$E003]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeMem2]);
  DisplayCODE16F(dim);
  if (dim3) > (15) then
  begin
   valid := 0;
   empty := 1;
   s[0] := 0;
   aux := malloc(((dim3) div (16)) * ((16) + ((16) * (5))));
   aux[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ConfigResMem]);
   i := $8000;
   while (i) < (($8000) + (dim3)) do
   begin
    valid := 0;
    j := i;
    while ((j) < ((i) + (16))) and ((j) < (($8000) + (dim3))) do
    begin
     sprintf(t, '%04X ', memCODE_W[j]);
     strcat(s, t);
     if (memCODE_W[j]) < ($3fff) then
      valid := 1;
     Inc(j);
    end;
    if valid then
    begin
     sprintf(t, '%04X: %s' + #13 + '' + NL + '', i, s);
     empty := 0;
     strcat(aux, t);
    end;
    s[0] := 0;
    Inc(i, 16);
   end;
   if empty then
    PrintMessage(strings[S_Empty])
   else
    PrintMessage(aux);
   free(aux);
  end;
  if dim2 then
   DisplayEE();
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Read16F18xxx(dim: Integer; dim2: Integer; dim3: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  useDCI: Integer;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  useDCI := IfThen(((options) and ($10)) = (0), 1, 0);
  if (FWVersion) < ($B00) then
  begin
   sprintf(str, strings[S_FWver2old], '0.11.0');
   PrintMessage(str);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if ((dim) > ($8000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read16F18xxx(%d,%d,%d,%d)' + NL + '', dim, dim2, dim3, options);
  end;
  if ((options) and (2)) = (0) then
  begin
   if not (StartHVReg(8.5)) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end
   else
    hvreg := 8.5;
  end
  else
   StartHVReg(-(1));
  sizeW := $8220;
  if memCODE_W then
   free(memCODE_W);
  memCODE_W := malloc((SizeOf(WORD)) * (sizeW));
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := $3fff;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  if ((options) and (2)) = (0) then
  begin
   if ((options) and (1)) = (0) then
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeReading1]);
  j := 0;
  for i := 0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((dim) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($58) then
     begin
      memCODE_W[Inc(k)] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((i) * (100)) div (((dim) + (dim2)) + ($60)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  if (k) <> (dim) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ReadCodeErr], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_Read_CONFIG_A]);
  bufferU[Inc(j)] := $59;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $00;
  k2 := 0;
  for i := $8000 to ($8010) - 1 do
  begin
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ($800F)) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($58) then
     begin
      memCODE_W[($8000) + (Inc(k2))] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((((i) - ($8000)) + (dim)) * (100)) div (((dim) + (dim2)) + ($60)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if (k2) <> ($10) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigErr], $10, k2);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if useDCI then
  begin
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, 'Read device info area @0x8100' + NL + '');
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := $00;
   k2 := 0;
   for i := $8100 to ($8120) - 1 do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ($811F)) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($58) then
      begin
       memCODE_W[($8100) + (Inc(k2))] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
       z := z + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (((((i) - ($8100)) + (dim)) + ($20)) * (100)) div (((dim) + (dim2)) + ($60)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
   end;
   if (k2) <> ($20) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigErr], $20, k2);
    PrintMessage(str);
   end;
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, 'Read Device Configuration Information @0x8200' + NL + '');
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $82;
   bufferU[Inc(j)] := $00;
   k2 := 0;
   for i := $8200 to ($8220) - 1 do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ($821F)) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($58) then
      begin
       memCODE_W[($8200) + (Inc(k2))] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
       z := z + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (((((i) - ($8200)) + (dim)) + ($40)) * (100)) div (((dim) + (dim2)) + ($60)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
   end;
   if (k2) <> ($20) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigErr], $20, k2);
    PrintMessage(str);
   end;
  end;
  if dim2 then
  begin
   if useDCI then
    dim2 := memCODE_W[$8203];
   if ((dim2) > ($1000)) or ((dim2) < (0)) then
   begin
    PrintMessage(strings[S_EELim]);
    Exit;
   end;
   sizeEE := dim2;
   if memEE then
    free(memEE);
   memEE := malloc(sizeEE);
   for i := 0 to (sizeEE) - 1 do
   begin
    memEE[i] := $FF;
   end;
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ReadEE]);
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $F0;
   bufferU[Inc(j)] := $00;
   for i := (k := 0) to (dim2) - 1 do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((dim2) - (1))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($58) then
      begin
       memEE[Inc(k)] := bufferI[(z) + (2)];
       z := z + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (((i) * (100)) + (dim)) + (($60) div (((dim) + (dim2)) + ($60))), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
    end;
   end;
   if (i) <> (dim2) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ReadEEErr], dim2, i);
    PrintMessage(str);
    while (i) < (dim2) do
    begin
     memEE[i] := $ff;
     Inc(i);
    end;
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  i := 0;
  while (i) < (4) do
  begin
   sprintf(str, 'ID%d: 0x%04X' + #9 + 'ID%d: 0x%04X' + #13 + '' + NL + '', i, memCODE_W[($8000) + (i)], (i) + (1), memCODE_W[(($8000) + (i)) + (1)]);
   PrintMessage(str);
   Inc(i, 2);
  end;
  sprintf(str, strings[S_DevID], memCODE_W[$8006]);
  PrintMessage(str);
  if (memCODE_W[$8005]) < ($3FFF) then
  begin
   sprintf(str, strings[S_DevREV], memCODE_W[$8005]);
   PrintMessage(str);
  end;
  PIC16_ID(memCODE_W[$8006]);
  for i := 0 to (5) - 1 do
  begin
   sprintf(str, strings[S_ConfigWordX], (i) + (1), memCODE_W[($8007) + (i)]);
   PrintMessage(str);
  end;
  if useDCI then
  begin
   PrintMessage('Device Information Area @0x8100' + #13 + '' + NL + '');
   s[0] := 0;
   i := 0;
   while (i) < ($20) do
   begin
    sprintf(t, '%04X: ', ($8100) + (i));
    strcat(s, t);
    j := i;
    while ((j) < ((i) + (16))) and ((j) < ($20)) do
    begin
     sprintf(t, '%04X ', memCODE_W[($8100) + (j)]);
     strcat(s, t);
     Inc(j);
    end;
    strcat(s, '' + #13 + '' + NL + '');
    Inc(i, 16);
   end;
   PrintMessage(s);
   PrintMessage('Device Configuration Information @0x8200' + #13 + '' + NL + '');
   s[0] := 0;
   i := 0;
   while (i) < ($20) do
   begin
    sprintf(t, '%04X: ', ($8200) + (i));
    strcat(s, t);
    j := i;
    while ((j) < ((i) + (16))) and ((j) < ($20)) do
    begin
     sprintf(t, '%04X ', memCODE_W[($8200) + (j)]);
     strcat(s, t);
     Inc(j);
    end;
    strcat(s, '' + #13 + '' + NL + '');
    Inc(i, 16);
   end;
   PrintMessage(s);
   sprintf(str, 'Erase row size: %d words' + #13 + '' + NL + '', memCODE_W[$8200]);
   PrintMessage(str);
   sprintf(str, 'Write latches: %d' + #13 + '' + NL + '', memCODE_W[$8201]);
   PrintMessage(str);
   sprintf(str, 'User rows: %d' + #13 + '' + NL + '', memCODE_W[$8202]);
   PrintMessage(str);
   sprintf(str, '->%d Flash words' + #13 + '' + NL + '', (memCODE_W[$8200]) * (memCODE_W[$8202]));
   PrintMessage(str);
   sprintf(str, 'EE data memory size: %d' + #13 + '' + NL + '', memCODE_W[$8203]);
   PrintMessage(str);
   sprintf(str, 'Pin count: %d' + #13 + '' + NL + '', memCODE_W[$8204]);
   PrintMessage(str);
   if (dim) <> ((memCODE_W[$8200]) * (memCODE_W[$8202])) then
    PrintMessage(strings[S_WarnFlashSize]);
  end;
  PrintMessage(strings[S_CodeMem2]);
  DisplayCODE16F(dim);
  if dim2 then
   DisplayEE();
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write12F6xx(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  calib1: TWORD;
  calib2: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_e: Integer;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  calib1 := $3fff;
  calib2 := $3fff;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if load_calibword then
  begin
   if (sizeW) > ($2009) then
    load_calibword := 2
   else
    if (sizeW) > ($2008) then
     load_calibword := 1
    else
    begin
     PrintMessage(strings[S_NoCalibW]);
     load_calibword := 0;
    end;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write12F6xx(%d,%d)' + NL + '', dim, dim2);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  calib1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  if (calib1) < ($3fff) then
  begin
   sprintf(str, strings[S_CalibWord1], calib1);
   PrintMessage(str);
  end;
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  calib2 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  if (calib2) < ($3fff) then
  begin
   sprintf(str, strings[S_CalibWord2], calib2);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $0A;
  if ((programID) or (load_calibword)) or (ICDenable) then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if load_calibword then
   begin
    bufferU[Inc(j)] := $17;
    if (load_calibword) = (2) then
     bufferU[Inc(j)] := $09
    else
     bufferU[Inc(j)] := $08;
   end;
  end;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  if dim2 then
  begin
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (4000) shr (8);
  bufferU[Inc(j)] := (4000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(50);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (12))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (5)) + (2));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (8000) shr (8);
   bufferU[Inc(j)] := (8000) and ($ff);
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := ($2100) - ($2001);
   w := 2;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (12))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (9)) + (2));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err_e);
         if (max_err) and (((err) + (err_e)) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], (err) + (err_e));
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err_e := err_e + (i) - (k);
   err := err + err_e;
   sprintf(str, strings[S_ComplErr], err_e);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := ($2800) + ((ICDaddr) and ($7FF));
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (4000) shr (8);
  bufferU[Inc(j)] := (4000) and ($ff);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 4;
  end;
  if ICDenable then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (ICDgoto) shr (8);
   bufferU[Inc(j)] := (ICDgoto) and ($FF);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if load_calibword then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2009]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2009]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(35);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  if ICDenable then
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (ICDgoto) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ICDErr], $2004, i, ICDgoto, ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if load_calibword then
  begin
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[$2008]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_Calib1Err], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   if (load_calibword) = (2) then
   begin
    z := 6;
    while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
    begin
     Inc(z);
    end;
    if (memCODE_W[$2009]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
    begin
     PrintMessage('' + #13 + '' + NL + '');
     sprintf(str, strings[S_Calib2Err], memCODE_W[$2009], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
     PrintMessage(str);
     Inc(err_c);
    end;
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F8x(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  config: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  r: Integer;
  start: Cardinal;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F8x(%d,%d)' + NL + '', dim, dim2);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (25000) shr (8);
  bufferU[Inc(j)] := (25000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(140);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  config := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_ConfigWord], config);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  if (config) < ($3FF0) then
  begin
   PrintMessage(strings[S_ProtErase]);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
  end
  else
   if ((devID) shr (5)) = ($2B) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := $3f;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := $19;
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    if dim2 then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := $ff;
     bufferU[Inc(j)] := $1B;
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
    end;
   end
   else
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := $3f;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $07;
    if dim2 then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := $ff;
     bufferU[Inc(j)] := $1F;
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $1F;
     bufferU[Inc(j)] := $07;
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $1F;
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $1F;
     bufferU[Inc(j)] := $07;
    end;
   end;
  if not (programID) then
  begin
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
  end;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  r := IfThen(((devID) shr (5)) = ($2B), 8000, 20000);
  bufferU[Inc(j)] := (r) shr (8);
  bufferU[Inc(j)] := (r) and ($ff);
  bufferU[Inc(j)] := $04;
  r := r div 1000;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(not (programID), 140, 60));
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (10))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (r)) + (4));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 1;
   w := 0;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (10))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (r)) + (5));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err);
         if (max_err) and ((err) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], err);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err := err + (i) - (k);
   sprintf(str, strings[S_ComplErr], (i) - (k));
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(programID, 125, 35));
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F62x(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  config: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F62x(%d,%d)' + NL + '', dim, dim2);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(12);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  config := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_ConfigWord], config);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (5000) shr (8);
  bufferU[Inc(j)] := (5000) and ($ff);
  if (config) < ($3C00) then
  begin
   PrintMessage(strings[S_ProtErase]);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
  end
  else
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $3f;
   bufferU[Inc(j)] := $ff;
   bufferU[Inc(j)] := $19;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   if dim2 then
   begin
    bufferU[Inc(j)] := $13;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := $1B;
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
   end;
  end;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (8000) shr (8);
  bufferU[Inc(j)] := (8000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(60);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (10))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (9)) + (2));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $2;
   w := 0;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $1E;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (10))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (14)) + (1));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err);
         if (max_err) and ((err) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], err);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err := err + (i) - (k);
   sprintf(str, strings[S_ComplErr], (i) - (k));
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $1E;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(programID, 125, 35));
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write12F62x(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  config: TWORD;
  osccal: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write12F62x(%d,%d)' + NL + '', dim, dim2);
  end;
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  i := 0;
  while (i) < ((dim) - ($ff)) do
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $ff;
   Inc(i, $ff);
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := ((dim) - (1)) - (i);
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  osccal := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  config := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (1)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  if programID then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (3000) shr (8);
  bufferU[Inc(j)] := (3000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(40);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  if not (load_osccal) then
   memCODE_W[(dim) - (1)] := osccal;
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (10))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (6.5)) + ((j) * (0.1)));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (6000) shr (8);
   bufferU[Inc(j)] := (6000) and ($ff);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   w := 3;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (10))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (7)) + (2));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err);
         if (max_err) and ((err) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], err);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err := err + (i) - (k);
   sprintf(str, strings[S_ComplErr], (i) - (k));
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 7;
  end;
  if not (load_calibword) then
   memCODE_W[$2007] := ((memCODE_W[$2007]) and ($fff)) + ((config) and ($3000));
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(35);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F87x(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  config: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  ee2200: Integer;
  start: Cardinal;
  err_e: Integer;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  ee2200 := 0;
  if (dim2) < (0) then
  begin
   dim2 := -(dim2);
   ee2200 := 1;
  end;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F87x(%d,%d)' + NL + '', dim, dim2);
  end;
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(60);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  config := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_ConfigWord], config);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (8000) shr (8);
  bufferU[Inc(j)] := (8000) and ($ff);
  if ((config) and ($3130)) <> ($3130) then
  begin
   PrintMessage(strings[S_ProtErase]);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
  end
  else
  begin
   if (ICDenable) or (programID) then
   begin
    bufferU[Inc(j)] := $11;
    bufferU[Inc(j)] := $3F;
    bufferU[Inc(j)] := $FF;
   end;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $3f;
   bufferU[Inc(j)] := $ff;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $07;
   if dim2 then
   begin
    bufferU[Inc(j)] := $13;
    bufferU[Inc(j)] := $ff;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $07;
   end;
   if (ICDenable) or (programID) then
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $1;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $0F;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $1;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end;
  end;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (4000) shr (8);
  bufferU[Inc(j)] := (4000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(60);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (10))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (5)) + (2));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 1;
   if ee2200 then
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $FF;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := 1;
   end;
   w := 0;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $1E;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (10))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (8)) + (5));
     w := 0;
     for z := 0 to (64) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err_e);
         if (max_err) and (((err) + (err_e)) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], (err) + (err_e));
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err_e := err_e + (i) - (k);
   err := err + err_e;
   sprintf(str, strings[S_ComplErr], err_e);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := ($2800) + ((ICDaddr) and ($7FF));
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (8000) shr (8);
  bufferU[Inc(j)] := (8000) and ($ff);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 4;
  end;
  if ICDenable then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (ICDgoto) shr (8);
   bufferU[Inc(j)] := (ICDgoto) and ($FF);
   bufferU[Inc(j)] := $1E;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $1E;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(programID, 125, 35));
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  if ICDenable then
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (ICDgoto) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ICDErr], $2004, i, ICDgoto, ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F87xA(dim: Integer; dim2: Integer; seq: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  config: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_e: Integer;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F87xA(%d,%d,%d)' + NL + '', dim, dim2, seq);
  end;
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
  end;
  start := GetTickCount();
  bufferU[0] := 0;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (25000) shr (8);
  bufferU[Inc(j)] := (25000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (seq) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen((seq) = (0), 90, 40));
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  config := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_ConfigWord], config);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (15000) shr (8);
  bufferU[Inc(j)] := (15000) and ($ff);
  if (ICDenable) or (programID) then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := $1F;
  bufferU[Inc(j)] := $1F;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (1200) shr (8);
  bufferU[Inc(j)] := (1200) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(60);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (11))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO((((w) * (1.5)) + (((6) - (w)) * (0.2))) + (2));
    w := 0;
    for z := 0 to ((64) - (6)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (4)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (5)]) shl (8)) + (bufferI[(z) + (6)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (5)]) shl (8)) + (bufferI[(z) + (6)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 7;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (12000) shr (8);
   bufferU[Inc(j)] := (12000) and ($ff);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 1;
   w := 0;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (10))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (12.5)) + (5));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err_e);
         if (max_err) and ((err) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], err);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err_e := err_e + (i) - (k);
   err := err + err_e;
   sprintf(str, strings[S_ComplErr], err_e);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := ($2800) + ((ICDaddr) and ($7FF));
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (12000) shr (8);
  bufferU[Inc(j)] := (12000) and ($ff);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 4;
  end;
  if ICDenable then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (ICDgoto) shr (8);
   bufferU[Inc(j)] := (ICDgoto) and ($FF);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) <> ($3fff)) then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  i := 28;
  if programID then
   i := i + 50;
  if ICDenable then
   i := i + 13;
  PacketIO(i);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  if ICDenable then
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (ICDgoto) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ICDErr], $2004, i, ICDgoto, ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) <> ($3fff)) then
  begin
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$2008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F81x(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  config: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_e: Integer;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F81x(%d,%d)' + NL + '', dim, dim2);
  end;
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (25000) shr (8);
  bufferU[Inc(j)] := (25000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(40);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  config := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_ConfigWord], config);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  if (programID) or (ICDenable) then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $FF;
  end;
  if ((config) and ($2100)) <> ($2100) then
  begin
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end
  else
  begin
   bufferU[Inc(j)] := $19;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $17;
  end;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (11))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (2.5)) + (3));
    w := 0;
    for z := 0 to ((64) - (6)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (4)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (5)]) shl (8)) + (bufferI[(z) + (6)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (5)]) shl (8)) + (bufferI[(z) + (6)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 7;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   err_e := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $13;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   j := 0;
   w := 0;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $1E;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $1F;
     bufferU[Inc(j)] := $17;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (10))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (2.5)) + (5));
     w := 0;
     for z := 0 to ((64) - (5)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (4)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (5)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (5)]);
         PrintMessage(str);
         Inc(err_e);
         if (max_err) and ((err) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], err);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 6;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err_e := err_e + (i) - (k);
   err := err + err_e;
   sprintf(str, strings[S_ComplErr], err_e);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := ($2800) + ((ICDaddr) and ($7FF));
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 4;
  end;
  if ICDenable then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (ICDgoto) shr (8);
   bufferU[Inc(j)] := (ICDgoto) and ($FF);
   bufferU[Inc(j)] := $1E;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $1E;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $1F;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) <> ($3fff)) then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $1E;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 7;
   Inc(i);
  end;
  if ICDenable then
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (ICDgoto) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ICDErr], $2004, i, ICDgoto, ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 7;
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) <> ($3fff)) then
  begin
   z := 7;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$2008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write12F61x(dim: Integer; d: Integer; d2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  devREV: TWORD;
  calib1: TWORD;
  calib2: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  devREV := $3fff;
  calib1 := $3fff;
  calib2 := $3fff;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if load_calibword then
  begin
   if (sizeW) > ($2008) then
    load_calibword := 1
   else
   begin
    PrintMessage(strings[S_NoCalibW]);
    load_calibword := 0;
   end;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write12F61x(%d)' + NL + '', dim);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devREV := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  if (devREV) < ($3FFF) then
  begin
   sprintf(str, strings[S_DevREV], devREV);
   PrintMessage(str);
  end;
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  calib1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  calib2 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  if (calib1) < ($3fff) then
  begin
   sprintf(str, strings[S_CalibWord1], calib1);
   PrintMessage(str);
  end;
  if (calib2) < ($3fff) then
  begin
   sprintf(str, strings[S_CalibWord2], calib2);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  if (programID) or (load_calibword) then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if load_calibword then
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $08;
   end;
  end;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (4000) shr (8);
  bufferU[Inc(j)] := (4000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(40);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1A;
    bufferU[Inc(j)] := $09;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (12))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (5)) + (2.5));
    w := 0;
    for z := 0 to ((64) - (7)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (5)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (6)]) shl (8)) + (bufferI[(z) + (7)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 8;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1A;
    bufferU[Inc(j)] := $09;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $1E;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $1A;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if load_calibword then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $1E;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1A;
   bufferU[Inc(j)] := $09;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(35);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 8;
   Inc(i);
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if load_calibword then
  begin
   z := 8;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[$2008]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_Calib1Err], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F88x(dim: Integer; dim2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  calib1: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  calib1 := $3fff;
  k := 0;
  z := 0;
  if (sizeW) < ($2009) then
  begin
   PrintMessage(strings[S_NoConfigW4]);
   Exit;
  end;
  if load_calibword then
  begin
   if (sizeW) > ($200A) then
    load_calibword := 1
   else
   begin
    PrintMessage(strings[S_NoCalibW]);
    load_calibword := 0;
   end;
  end;
  if dim2 then
  begin
   if (sizeW) < ($2100) then
   begin
    dim2 := 0;
    PrintMessage(strings[S_NoEEMem]);
   end
   else
    if (dim2) > ((sizeW) - ($2100)) then
     dim2 := (sizeW) - ($2100);
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F88x(%d,%d)' + NL + '', dim, dim2);
  end;
  i := 0;
  while ((i) < ($200A)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (6000) shr (8);
  bufferU[Inc(j)] := (6000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  calib1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  if (calib1) < ($3fff) then
  begin
   sprintf(str, strings[S_CalibWord1], calib1);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  if ((programID) or (load_calibword)) or (ICDenable) then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if load_calibword then
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := 9;
   end;
  end;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (3000) shr (8);
  bufferU[Inc(j)] := (3000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(40);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (12))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (3)) + (2));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (6000) shr (8);
   bufferU[Inc(j)] := (6000) and ($ff);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 1;
   w := 2;
   k := $2100; i := $2100;
   while (i) < (($2100) + (dim2)) do
   begin
    if (memCODE_W[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (12))) or ((i) = ((($2100) + (dim2)) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((((i) - ($2100)) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (6.5)) + (2));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memCODE_W[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memCODE_W[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(err);
         if (max_err) and ((err) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], err);
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := $2200;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
    Inc(i);
   end;
   err := err + (i) - (k);
   sprintf(str, strings[S_ComplErr], (i) - (k));
   PrintMessage(str);
  end;
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := ($2800) + ((ICDaddr) and ($7FF));
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (3000) shr (8);
  bufferU[Inc(j)] := (3000) and ($ff);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 4;
  end;
  if ICDenable then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (ICDgoto) shr (8);
   bufferU[Inc(j)] := (ICDgoto) and ($FF);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if load_calibword then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2009]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2009]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(35);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  if ICDenable then
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (ICDgoto) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ICDErr], $2004, i, ICDgoto, ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  z := 6;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if load_calibword then
  begin
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[$2009]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_Calib1Err], memCODE_W[$2009], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F7x(dim: Integer; vdd: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F7x(%d,%d)' + NL + '', dim, vdd);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(vdd, 20, 70));
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(vdd, 50, 100));
  PrintMessage(strings[S_Compl]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (1000) shr (8);
  bufferU[Inc(j)] := (1000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(vdd, 2, 52));
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1C;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (10))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (1.5)) + (2));
    w := 0;
    for z := 0 to ((64) - (6)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (4)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (5)]) shl (8)) + (bufferI[(z) + (6)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (5)]) shl (8)) + (bufferI[(z) + (6)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 7;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1C;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $1C;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) < ($3fff)) then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1C;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) < ($3fff)) then
  begin
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$2008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F71x(dim: Integer; vdd: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  k := 0;
  z := 0;
  if (sizeW) < ($2007) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F71x(%d,%d)' + NL + '', dim, vdd);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(vdd, 20, 70));
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  if programID then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (vdd) = (0) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen(vdd, 30, 130));
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1C;
    bufferU[Inc(j)] := $09;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (11))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (2.5)) + (2));
    w := 0;
    for z := 0 to ((64) - (7)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (5)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (6)]) shl (8)) + (bufferI[(z) + (7)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (6)]) shl (8)) + (bufferI[(z) + (7)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 8;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $1E;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1C;
    bufferU[Inc(j)] := $09;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 3;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 7;
  end;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $1E;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $1C;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) < ($3fff)) then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $1E;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1C;
   bufferU[Inc(j)] := $09;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(15);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if ((sizeW) > ($2008)) and ((memCODE_W[$2008]) < ($3fff)) then
  begin
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$2008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F72x(dim: Integer; d: Integer; d2: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  start: Cardinal;
  err_c: Integer;
  ICDgoto: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  k := 0;
  z := 0;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if not (StartHVReg(8.5)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if (sizeW) < ($2008) then
  begin
   PrintMessage(strings[S_NoConfigW3]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F72x(%d)' + NL + '', dim);
  end;
  i := 0;
  while ((i) < ($2009)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $1F;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (6000) shr (8);
  bufferU[Inc(j)] := (6000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(3);
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  PIC16_ID(devID);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  if (programID) or (ICDenable) then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $1F;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2500) shr (8);
  bufferU[Inc(j)] := (2500) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(18);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  k := 0; i := 0; w := 0;
  j := 0;
  while (i) < (dim) do
  begin
   if (memCODE_W[i]) < ($3fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (12))) or ((i) = ((dim) - (1))) then
   begin
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(((w) * (2.5)) + (2));
    w := 0;
    for z := 0 to ((64) - (5)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($3fff)) then
      Inc(k)
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)])) then
       begin
        PrintMessage('' + #13 + '' + NL + '');
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim;
         z := 64;
        end;
       end;
       Inc(k);
       z := z + 6;
      end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  PrintMessage(strings[S_ConfigAreaW]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
  err_c := 0;
  ICDgoto := ($2800) + ((ICDaddr) and ($7FF));
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (6000) shr (8);
  bufferU[Inc(j)] := (6000) and ($ff);
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  if programID then
  begin
   for i := $2000 to ($2004) - 1 do
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := 4;
  end;
  if ICDenable then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (ICDgoto) shr (8);
   bufferU[Inc(j)] := (ICDgoto) and ($FF);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$2007]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$2007]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  if (sizeW) > ($2008) then
  begin
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$2008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$2008]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $04;
  end;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(45);
  i := 0;
  z := 0;
  while (programID) and ((i) < (4)) do
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (memCODE_W[($2000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_IDErr], i, memCODE_W[($2000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
   Inc(i);
  end;
  if ICDenable then
  begin
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (ICDgoto) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    sprintf(str, strings[S_ICDErr], $2004, i, ICDgoto, ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := z + 6;
  end;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  if (not (memCODE_W[$2007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage('' + #13 + '' + NL + '');
   sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  if (sizeW) > ($2008) then
  begin
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$2008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$2008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
  end;
  err := err + err_c;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log9], err);
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F1xxx(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  devREV: TWORD;
  calib1: TWORD;
  calib2: TWORD;
  calib3: TWORD;
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  F18x: Integer;
  start: Cardinal;
  calib: array[0..4-1] of TWORD;
  dly: Integer;
  valid: Integer;
  inc: Integer;
  errEE: Integer;
  errEE: Integer;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  devREV := $3fff;
  calib1 := $3fff;
  calib2 := $3fff;
  calib3 := $3fff;
  k := 0;
  k2 := 0;
  z := 0;
  F18x := (options) and (16);
  if (F18x) and ((FWVersion) < ($A00)) then
  begin
   sprintf(str, strings[S_FWver2old], '0.10.0');
   PrintMessage(str);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if (sizeW) < ($8009) then
  begin
   PrintMessage(strings[S_NoConfigW5]);
   PrintMessage(strings[S_End]);
   Exit;
  end;
  if ((options) and (4)) and ((sizeW) < ($800A)) then
  begin
   sizeW := $800A;
   memCODE_W := realloc(memCODE_W, (SizeOf(WORD)) * (sizeW));
   memCODE_W[$8009] := $3FFF;
  end;
  if ((options) and (8)) and ((sizeW) < ($800B)) then
  begin
   sizeW := $800B;
   memCODE_W := realloc(memCODE_W, (SizeOf(WORD)) * (sizeW));
   memCODE_W[$800A] := $3FFF;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F1xxx(%d,%d,%d)' + NL + '', dim, dim2, options);
  end;
  if (dim2) > (sizeEE) then
   dim2 := sizeEE;
  if ((options) and (2)) = (0) then
  begin
   if not (StartHVReg(8.5)) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-(1));
  i := 0;
  while ((i) < ($800C)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  if ((options) and (2)) = (0) then
  begin
   if ((options) and (1)) = (0) then
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $11;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $16;
  if (options) and (4) then
   bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $14;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2500) shr (8);
  bufferU[Inc(j)] := (2500) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devREV := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  if (devREV) < ($3FFF) then
  begin
   sprintf(str, strings[S_DevREV], devREV);
   PrintMessage(str);
  end;
  PIC16_ID(devID);
  if ((memCODE_W[$8006]) < ($3FFF)) and ((devID) <> (memCODE_W[$8006])) then
   PrintMessage(strings[S_DevMismatch]);
  if not (F18x) then
  begin
   z := 3;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   calib1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   if (calib1) < ($3fff) then
   begin
    sprintf(str, strings[S_CalibWordX], 1, calib1);
    PrintMessage(str);
   end;
   z := 3;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   calib2 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   if (calib2) < ($3fff) then
   begin
    sprintf(str, strings[S_CalibWordX], 2, calib2);
    PrintMessage(str);
   end;
   z := 3;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   calib3 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   if (calib3) < ($3fff) then
   begin
    sprintf(str, strings[S_CalibWordX], 3, calib3);
    PrintMessage(str);
   end;
  end
  else
  begin
   calib := [$3FFF, $3FFF, $3FFF, $3FFF];
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $E0;
   bufferU[Inc(j)] := $00;
   for i := 0 to (4) - 1 do
   begin
    bufferU[Inc(j)] := $52;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'Calibration area @0xE000' + NL + '');
   end;
   z := 0;
   i := 0;
   while ((z) < ((64) - (2))) and ((i) < (4)) do
   begin
    if (bufferI[z]) = ($52) then
    begin
     calib[Inc(i)] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
     z := z + 2;
    end;
    Inc(z);
   end;
   if (i) <> (4) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigErr], 4, i);
    PrintMessage(str);
   end
   else
   begin
    for i := 0 to (4) - 1 do
    begin
     sprintf(str, strings[S_CalibWordX], (i) + (1), calib[i]);
     PrintMessage(str);
    end;
   end;
  end;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  dly := 8;
  j := 0;
  if programID then
  begin
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
  end
  else
   if not (F18x) then
   begin
    bufferU[Inc(j)] := $1F;
    bufferU[Inc(j)] := $16;
   end
   else
   begin
    bufferU[Inc(j)] := $50;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $00;
   end;
  bufferU[Inc(j)] := $19;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  if F18x then
  begin
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $F0;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $19;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   dly := dly + 6;
  end;
  if not (F18x) then
  begin
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $16;
  end
  else
  begin
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(dly);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  fflush(logfile);
  while ((dim) > (0)) and ((memCODE_W[dim]) >= ($3fff)) do
  begin
   Dec(dim);
  end;
  if not (F18x) then
  begin
   if (dim) mod (8) then
    dim := dim + (8) - ((dim) mod (8));
   j := 0;
   i := (k := 0);
   while (i) < (dim) do
   begin
    inc := 0; valid := 0;
    while ((i) < (dim)) and (not (valid)) do
    begin
     valid := 0;
     for k := 0 to (8) - 1 do
     begin
      if (memCODE_W[(i) + (k)]) < ($3fff) then
       valid := 1;
     end;
     if not (valid) then
     begin
      inc := inc + 8;
      i := i + 8;
     end;
     if (inc) and ((valid) or ((inc) = (248))) then
     begin
      bufferU[Inc(j)] := $17;
      k := inc; bufferU[Inc(j)] := inc;
      inc := 0;
     end;
     if ((j) > ((64) - (4))) or ((valid) and ((j) > (1))) then
     begin
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO((3) + ((k) div (2)));
      j := 0;
     end;
    end;
    if valid then
    begin
     k := 0;
     bufferU[Inc(j)] := $12;
     bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) shr (8);
     bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) and ($ff);
     for k := 1 to (8) - 1 do
     begin
      bufferU[Inc(j)] := $16;
      bufferU[Inc(j)] := $12;
      bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) shr (8);
      bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) and ($ff);
     end;
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $16;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, 0, 0);
     end;
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
    end;
    Inc(i, 8);
   end;
  end
  else
  begin
   if (dim) mod (32) then
    dim := dim + (32) - ((dim) mod (32));
   j := 0;
   i := (k := 0);
   while (i) < (dim) do
   begin
    valid := 0;
    while ((i) < (dim)) and (not (valid)) do
    begin
     valid := 0;
     for k := 0 to (32) - 1 do
     begin
      if (memCODE_W[(i) + (k)]) < ($3fff) then
       valid := 1;
     end;
     Inc(i, IfThen(valid, 0, 32));
    end;
    bufferU[Inc(j)] := $50;
    bufferU[Inc(j)] := (i) shr (8);
    bufferU[Inc(j)] := (i) and ($FF);
    k := 0;
    while ((k) < (32)) and ((i) < (dim)) do
    begin
     bufferU[Inc(j)] := IfThen((k) < (31), $51, $12);
     bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) shr (8);
     bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) and ($ff);
     if (j) > ((64) - (4)) then
     begin
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(3);
      j := 0;
     end;
     Inc(k);
    end;
    if (i) < (dim) then
    begin
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, 0, 0);
     end;
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
    end;
    Inc(i, 32);
   end;
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeV]);
  j := 0;
  if not (F18x) then
  begin
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $16;
  end
  else
  begin
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  for i := (k := 0) to (dim) - 1 do
  begin
   if (j) = (0) then
   begin
    valid := 0;
    while ((i) < (dim)) and (not (valid)) do
    begin
     k2 := 0;
     while ((k2) < (255)) and (not (valid)) do
     begin
      if (memCODE_W[(i) + (k2)]) < ($3fff) then
       valid := 1;
      Inc(k2);
     end;
     if (k2) > (16) then
     begin
      bufferU[Inc(j)] := $17;
      bufferU[Inc(j)] := k2;
      i := i + k2;
      k := k + k2;
     end;
     if ((j) > ((64) - (4))) or ((valid) and ((j) > (1))) then
     begin
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO((3) + (((j) div (2)) * (0.1)));
      j := 0;
     end;
    end;
   end;
   if (memCODE_W[i]) < ($3FFF) then
    bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   if ((j) > ((((64) * (2)) div (4)) - (3))) or ((i) = ((dim) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($16) then
      Inc(k)
     else
      if (bufferI[z]) = ($14) then
      begin
       if ((memCODE_W[k]) < ($3FFF)) and ((memCODE_W[k]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]))) then
       begin
        sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
        PrintMessage(str);
        Inc(err);
       end;
       z := z + 2;
      end;
    end;
    sprintf(str, strings[S_CodeV2], ((i) * (100)) div ((dim) + (dim2)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
    if (err) >= (max_err) then
     i := dim;
   end;
  end;
  if (k) < (dim) then
  begin
   sprintf(str, strings[S_CodeVError3], dim, k);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if (err) >= (max_err) then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  if ((dim2) and ((err) < (max_err))) and (not (F18x)) then
  begin
   errEE := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
   j := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (5000) shr (8);
   bufferU[Inc(j)] := (5000) and ($ff);
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $1F;
   bufferU[Inc(j)] := $16;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   k := 0; i := 0; w := 0;
   while (i) < (dim2) do
   begin
    if (memEE[i]) < ($ff) then
    begin
     bufferU[Inc(j)] := $13;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $15;
     Inc(w);
    end;
    bufferU[Inc(j)] := $16;
    if ((j) > ((64) - (12))) or ((i) = ((dim2) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], (((i) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((w) * (5)) + (2));
     w := 0;
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($16)) and ((memEE[k]) >= ($ff)) then
       Inc(k)
      else
       if ((bufferI[z]) = ($13)) and ((bufferI[(z) + (3)]) = ($15)) then
       begin
        if (memEE[k]) <> (bufferI[(z) + (4)]) then
        begin
         PrintMessage('' + #13 + '' + NL + '');
         sprintf(str, strings[S_CodeWError3], k, memEE[k], bufferI[(z) + (4)]);
         PrintMessage(str);
         Inc(errEE);
         if (max_err) and (((err) + (errEE)) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], (err) + (errEE));
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := dim2;
          z := 64;
         end;
        end;
        Inc(k);
        z := z + 5;
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
    Inc(i);
   end;
   errEE := errEE + (i) - (k);
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end
  else
   if ((dim2) and ((err) < (max_err))) and (F18x) then
   begin
    errEE := 0;
    PrintMessage(strings[S_EEAreaW]);
    if saveLog then
     fprintf(logfile, strings[S_sepLine]);
    if saveLog then
     fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
    j := 0;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := (5000) shr (8);
    bufferU[Inc(j)] := (5000) and ($ff);
    bufferU[Inc(j)] := $50;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(7);
    j := 0;
    k := 0; i := 0; w := 0;
    while (i) < (dim2) do
    begin
     if (memEE[i]) < ($ff) then
     begin
      bufferU[Inc(j)] := $12;
      bufferU[Inc(j)] := 0;
      bufferU[Inc(j)] := memEE[i];
      bufferU[Inc(j)] := $18;
      bufferU[Inc(j)] := $0A;
      bufferU[Inc(j)] := $14;
      Inc(w);
     end;
     bufferU[Inc(j)] := $16;
     if ((j) > ((64) - (12))) or ((i) = ((dim2) - (1))) then
     begin
      sprintf(str, strings[S_CodeWriting], (((i) + (dim)) * (100)) div ((dim) + (dim2)), i);
      gtk_statusbar_push(status_bar, statusID, str);
      while gtk_events_pending() do
      begin
       gtk_main_iteration();
      end;
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(((w) * (5)) + (2));
      w := 0;
      for z := 0 to ((64) - (4)) - 1 do
      begin
       if ((bufferI[z]) = ($16)) and ((memEE[k]) >= ($ff)) then
        Inc(k)
       else
        if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (3)]) = ($14)) then
        begin
         if (memEE[k]) <> (bufferI[(z) + (5)]) then
         begin
          PrintMessage('' + #13 + '' + NL + '');
          sprintf(str, strings[S_CodeWError3], k, memEE[k], bufferI[(z) + (5)]);
          PrintMessage(str);
          Inc(errEE);
          if (max_err) and (((err) + (errEE)) > (max_err)) then
          begin
           sprintf(str, strings[S_MaxErr], (err) + (errEE));
           PrintMessage(str);
           PrintMessage(strings[S_IntW]);
           i := dim2;
           z := 64;
          end;
         end;
         Inc(k);
         z := z + 6;
        end;
      end;
      j := 0;
      if saveLog then
      begin
       fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
      end;
     end;
     Inc(i);
    end;
    errEE := errEE + (i) - (k);
    sprintf(str, strings[S_ComplErr], errEE);
    PrintMessage(str);
    err := err + errEE;
   end;
  if (err) >= (max_err) then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  if (max_err) and ((err) < (max_err)) then
  begin
   PrintMessage(strings[S_ConfigAreaW]);
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
   err_c := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (5000) shr (8);
   bufferU[Inc(j)] := (5000) and ($ff);
   bufferU[Inc(j)] := $11;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $FF;
   if programID then
   begin
    for i := $8000 to ($8004) - 1 do
    begin
     bufferU[Inc(j)] := $12;
     bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $18;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $14;
     bufferU[Inc(j)] := $16;
    end;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := 3;
   end
   else
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := 7;
   end;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$8007]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$8007]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$8008]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$8008]) and ($ff);
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $16;
   if (options) and ($C) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[$8009]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[$8009]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   if (options) and (8) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[$800A]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[$800A]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $16;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := (IfThen(programID, 22, 0)) + (IfThen((options) and ($C), 10, 0));
   PacketIO((18) + (j));
   i := 0;
   z := 0;
   while (programID) and ((i) < (4)) do
   begin
    while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
    begin
     Inc(z);
    end;
    if (memCODE_W[($8000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
    begin
     PrintMessage('' + #13 + '' + NL + '');
     sprintf(str, strings[S_IDErr], i, memCODE_W[($8000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
     PrintMessage(str);
     Inc(err_c);
    end;
    z := z + 6;
    Inc(i);
   end;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$8007])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$8007], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   z := 6;
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
    Inc(z);
   end;
   if (not (memCODE_W[$8008])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
   begin
    PrintMessage('' + #13 + '' + NL + '');
    sprintf(str, strings[S_ConfigWErr3], memCODE_W[$8008], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    Inc(err_c);
   end;
   if (options) and ($C) then
   begin
    z := 6;
    while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
    begin
     Inc(z);
    end;
    if (not (memCODE_W[$8009])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
    begin
     PrintMessage('' + #13 + '' + NL + '');
     sprintf(str, strings[S_ConfigWErr3], memCODE_W[$8009], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
     PrintMessage(str);
     Inc(err_c);
    end;
   end;
   if (options) and (8) then
   begin
    z := 6;
    while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
    begin
     Inc(z);
    end;
    if (not (memCODE_W[$800A])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
    begin
     PrintMessage('' + #13 + '' + NL + '');
     sprintf(str, strings[S_ConfigWErr3], memCODE_W[$800A], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
     PrintMessage(str);
     Inc(err_c);
    end;
   end;
   err := err + err_c;
   sprintf(str, strings[S_ComplErr], err_c);
   PrintMessage(str);
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log9], err);
   end;
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

function Write16F18xxx(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  err: Integer;
  devID: TWORD;
  devREV: TWORD;
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  useDCI: Integer;
  bulkEraseField: Integer;
  reboot: Integer;
  rowN: Integer;
  start: Cardinal;
  DIA: array[0..0x20-1] of TWORD;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  DCI: array[0..0x20-1] of TWORD;
  valid: Integer;
  errEE: Integer;
  t: array[0..256-1] of Char;
  err_c: Integer;
  stop: Cardinal;
begin
  err := 0;
  devID := $3fff;
  devREV := $3fff;
  k := 0;
  k2 := 0;
  z := 0;
  useDCI := IfThen(((options) and ($10)) = (0), 1, 0);
  bulkEraseField := IfThen((options) and ($20), 1, 0);
  reboot := IfThen((options) and ($40), 1, 0);
  rowN := 32;
  if (FWVersion) < ($B00) then
  begin
   sprintf(str, strings[S_FWver2old], '0.11.0');
   PrintMessage(str);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if (sizeW) < ($800C) then
  begin
   PrintMessage(strings[S_NoConfigW6]);
   sprintf(str, strings[S_End], 0);
   PrintMessage(str);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Write16F18xxx(%d,%d,%d)' + NL + '', dim, dim2, options);
  end;
  if (dim2) > (0) then
   dim2 := sizeEE;
  if (dim2) > ($1000) then
   dim2 := $100;
  if ((options) and (2)) = (0) then
  begin
   if not (StartHVReg(8.5)) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-(1));
  i := 0;
  while ((i) < ($800C)) and ((i) < (sizeW)) do
  begin
   memCODE_W[i] := memCODE_W[i] and $3FFF;
   Inc(i);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  if ((options) and (2)) = (0) then
  begin
   if ((options) and (1)) = (0) then
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end
   else
   begin
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $5;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := $C2;
   bufferU[Inc(j)] := $B2;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $59;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $58;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $58;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  if not (bulkEraseField) then
  begin
   bufferU[Inc(j)] := (2800) shr (8);
   bufferU[Inc(j)] := (2800) and ($ff);
  end
  else
  begin
   bufferU[Inc(j)] := (7000) shr (8);
   bufferU[Inc(j)] := (7000) and ($ff);
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  z := 0;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($58)) do
  begin
   Inc(z);
  end;
  devREV := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  z := 3;
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($58)) do
  begin
   Inc(z);
  end;
  devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, strings[S_DevID], devID);
  PrintMessage(str);
  if (devREV) < ($3FFF) then
  begin
   sprintf(str, strings[S_DevREV], devREV);
   PrintMessage(str);
  end;
  PIC16_ID(devID);
  if ((memCODE_W[$8006]) < ($3FFF)) and ((devID) <> (memCODE_W[$8006])) then
   PrintMessage(strings[S_DevMismatch]);
  if useDCI then
  begin
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, 'Device Information Area @0x8100' + NL + '');
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $81;
   bufferU[Inc(j)] := $00;
   k := 0;
   for i := 0 to ($20) - 1 do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ($1F)) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($58) then
      begin
       DIA[Inc(k)] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
       z := z + 2;
      end;
     end;
     j := 0;
    end;
   end;
   PrintMessage('Device Information Area @0x8100' + #13 + '' + NL + '');
   s[0] := 0;
   i := 0;
   while (i) < ($20) do
   begin
    sprintf(t, '%04X: ', ($8100) + (i));
    strcat(s, t);
    j := i;
    while ((j) < ((i) + (16))) and ((j) < ($20)) do
    begin
     sprintf(t, '%04X ', DIA[j]);
     strcat(s, t);
     Inc(j);
    end;
    strcat(s, '' + #13 + '' + NL + '');
    Inc(i, 16);
   end;
   PrintMessage(s);
   if saveLog then
    fprintf(logfile, 'Device Configuration Information @0x8200' + NL + '');
   j := 0;
   k := 0;
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $82;
   bufferU[Inc(j)] := $00;
   for i := 0 to ($20) - 1 do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ($1F)) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(5);
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($58) then
      begin
       DCI[Inc(k)] := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
       z := z + 2;
      end;
     end;
     j := 0;
    end;
   end;
   PrintMessage('Device Configuration Information @0x8200' + #13 + '' + NL + '');
   s[0] := 0;
   i := 0;
   while (i) < ($20) do
   begin
    sprintf(t, '%04X: ', ($8200) + (i));
    strcat(s, t);
    j := i;
    while ((j) < ((i) + (16))) and ((j) < ($20)) do
    begin
     sprintf(t, '%04X ', DCI[j]);
     strcat(s, t);
     Inc(j);
    end;
    strcat(s, '' + #13 + '' + NL + '');
    Inc(i, 16);
   end;
   PrintMessage(s);
   sprintf(str, 'Erase row size: %d words' + #13 + '' + NL + '', DCI[0]);
   PrintMessage(str);
   sprintf(str, 'Write latches: %d' + #13 + '' + NL + '', DCI[1]);
   PrintMessage(str);
   sprintf(str, 'User rows: %d' + #13 + '' + NL + '', DCI[2]);
   PrintMessage(str);
   sprintf(str, '->%d Flash words' + #13 + '' + NL + '', (DCI[0]) * (DCI[2]));
   PrintMessage(str);
   sprintf(str, 'EE data memory size: %d' + #13 + '' + NL + '', DCI[3]);
   PrintMessage(str);
   sprintf(str, 'Pin count: %d' + #13 + '' + NL + '', DCI[4]);
   PrintMessage(str);
   if ((DCI[0]) * (DCI[2])) <> (dim) then
    PrintMessage(strings[S_WarnFlashSize]);
   if (dim2) > (DCI[3]) then
    dim2 := DCI[3];
  end;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartErase]);
  j := 0;
  if not (bulkEraseField) then
  begin
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   if programID then
   begin
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $00;
   end
   else
   begin
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $00;
   end;
   bufferU[Inc(j)] := $57;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   if dim2 then
   begin
    bufferU[Inc(j)] := $59;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $57;
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
   end;
  end
  else
  begin
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := IfThen(programID, $0F, $0B);
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(30);
  PrintMessage(strings[S_Compl]);
  if reboot then
  begin
   j := 0;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
  end;
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_StartCodeProg]);
  fflush(logfile);
  while ((dim) > (0)) and ((memCODE_W[(dim) - (1)]) >= ($3fff)) do
  begin
   Dec(dim);
  end;
  if (dim) mod (rowN) then
   dim := dim + (rowN) - ((dim) mod (rowN));
  j := 0;
  i := (k := 0);
  while (i) < (dim) do
  begin
   valid := 0;
   while ((i) < (dim)) and (not (valid)) do
   begin
    valid := 0;
    for k := 0 to (rowN) - 1 do
    begin
     if (memCODE_W[(i) + (k)]) < ($3fff) then
      valid := 1;
    end;
    Inc(i, IfThen(valid, 0, rowN));
   end;
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (i) shr (8);
   bufferU[Inc(j)] := (i) and ($FF);
   k := 0;
   while ((k) < (rowN)) and ((i) < (dim)) do
   begin
    bufferU[Inc(j)] := $59;
    bufferU[Inc(j)] := IfThen((k) < ((rowN) - (1)), $02, $00);
    bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[(i) + (k)]) and ($ff);
    if (j) > ((64) - (5)) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
    end;
    Inc(k);
   end;
   if (i) < (dim) then
   begin
    bufferU[Inc(j)] := $57;
    bufferU[Inc(j)] := $E0;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(3);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
   end;
   Inc(i, rowN);
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + NL + '', strings[S_CodeV]);
  j := 0;
  bufferU[Inc(j)] := $59;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  for i := (k := 0) to (dim) - 1 do
  begin
   if (j) = (0) then
   begin
    k2 := i;
    while ((k2) < (dim)) and ((memCODE_W[k2]) >= ($3fff)) do
    begin
     Inc(k2);
    end;
    if (k2) > ((i) + (10)) then
    begin
     i := k2;
     k := i;
     bufferU[Inc(j)] := $59;
     bufferU[Inc(j)] := $80;
     bufferU[Inc(j)] := ((i) shr (8)) and ($FF);
     bufferU[Inc(j)] := (i) and ($FF);
    end;
   end;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((dim) - (1))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    for z := 0 to ((64) - (2)) - 1 do
    begin
     if (bufferI[z]) = ($58) then
     begin
      if (memCODE_W[k]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
      begin
       sprintf(str, strings[S_CodeWError2], k, memCODE_W[k], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
       PrintMessage(str);
       Inc(err);
      end;
      z := z + 2;
      Inc(k);
     end;
    end;
    sprintf(str, strings[S_CodeV2], ((i) * (100)) div ((dim) + (dim2)), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
    if (err) >= (max_err) then
     i := dim;
   end;
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if (err) >= (max_err) then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end
  else
   if (dim2) and ((err) < (max_err)) then
   begin
    errEE := 0;
    PrintMessage(strings[S_EEAreaW]);
    if saveLog then
     fprintf(logfile, strings[S_sepLine]);
    if saveLog then
     fprintf(logfile, '%s' + NL + '', strings[S_EEAreaW]);
    j := 0;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := (5600) shr (8);
    bufferU[Inc(j)] := (5600) and ($ff);
    bufferU[Inc(j)] := $59;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := $00;
    k := 0; i := 0; w := 0;
    while (i) < (dim2) do
    begin
     if (memEE[i]) < ($ff) then
     begin
      bufferU[Inc(j)] := $59;
      bufferU[Inc(j)] := $00;
      bufferU[Inc(j)] := 0;
      bufferU[Inc(j)] := (memEE[i]) and ($ff);
      bufferU[Inc(j)] := $57;
      bufferU[Inc(j)] := $E0;
      bufferU[Inc(j)] := $0A;
      bufferU[Inc(j)] := $58;
      bufferU[Inc(j)] := $FE;
      Inc(w);
     end
     else
     begin
      bufferU[Inc(j)] := $57;
      bufferU[Inc(j)] := $F8;
     end;
     if ((j) > ((64) - (10))) or ((i) = ((dim2) - (1))) then
     begin
      sprintf(str, strings[S_CodeWriting], (((i) + (dim)) * (100)) div ((dim) + (dim2)), i);
      gtk_statusbar_push(status_bar, statusID, str);
      while gtk_events_pending() do
      begin
       gtk_main_iteration();
      end;
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(((w) * (6)) + (2));
      j := 0;
      w := 0;
      for z := 0 to ((64) - (5)) - 1 do
      begin
       if ((bufferI[z]) = ($57)) and ((memEE[k]) >= ($ff)) then
        Inc(k)
       else
        if ((bufferI[z]) = ($59)) and ((bufferI[(z) + (3)]) = ($58)) then
        begin
         if (memEE[k]) <> (bufferI[(z) + (5)]) then
         begin
          PrintMessage('' + #13 + '' + NL + '');
          sprintf(str, strings[S_CodeWError3], k, memEE[k], bufferI[(z) + (5)]);
          PrintMessage(str);
          Inc(errEE);
          if (max_err) and (((err) + (errEE)) > (max_err)) then
          begin
           sprintf(str, strings[S_MaxErr], (err) + (errEE));
           PrintMessage(str);
           PrintMessage(strings[S_IntW]);
           i := dim2;
           z := 64;
          end;
         end;
         Inc(k);
         z := z + 5;
        end;
      end;
      if saveLog then
      begin
       fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
      end;
     end;
     Inc(i);
    end;
    errEE := errEE + (i) - (k);
    sprintf(str, strings[S_ComplErr], errEE);
    PrintMessage(str);
    if (max_err) and (((err) + (errEE)) > (max_err)) then
    begin
     sprintf(str, strings[S_MaxErr], (err) + (errEE));
     PrintMessage(str);
    end;
    err := err + errEE;
   end;
  if (max_err) and ((err) < (max_err)) then
  begin
   PrintMessage(strings[S_ConfigAreaW]);
   PrintMessage('' + #13 + '' + NL + '');
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, '%s' + NL + '', strings[S_ConfigAreaW]);
   err_c := 0;
   j := 0;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (12000) shr (8);
   bufferU[Inc(j)] := (12000) and ($ff);
   if programID then
   begin
    bufferU[Inc(j)] := $59;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $00;
    for i := $8000 to ($8004) - 1 do
    begin
     bufferU[Inc(j)] := $59;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
     bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
     bufferU[Inc(j)] := $57;
     bufferU[Inc(j)] := $E0;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $FE;
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(50);
    z := 0;
    for i := 0 to (4) - 1 do
    begin
     while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($58)) do
     begin
      Inc(z);
     end;
     if (memCODE_W[($8000) + (i)]) <> (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
     begin
      sprintf(str, strings[S_IDErr], i, memCODE_W[($8000) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
      PrintMessage(str);
      Inc(err_c);
     end;
     z := z + 6;
    end;
    j := 0;
   end;
   bufferU[Inc(j)] := $59;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $07;
   for i := $8007 to ($800C) - 1 do
   begin
    bufferU[Inc(j)] := $59;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $57;
    bufferU[Inc(j)] := $E0;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(60);
   z := 0;
   for i := 0 to (5) - 1 do
   begin
    while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($58)) do
    begin
     Inc(z);
    end;
    if (not (memCODE_W[($8007) + (i)])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
    begin
     sprintf(t, 'config%d', (i) + (1));
     sprintf(str, strings[S_WErr2], t, memCODE_W[($8007) + (i)], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
     PrintMessage(str);
     Inc(err_c);
    end;
    z := z + 6;
   end;
   err := err + err_c;
   sprintf(str, strings[S_ComplErr], err_c);
   PrintMessage(str);
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log9], err_c);
   end;
  end;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, '');
end;

end.
