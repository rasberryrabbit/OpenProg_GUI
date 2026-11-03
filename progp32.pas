unit progp32;

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
  sys_types,
  mainform;

const
  NL = #10;
  MTAP_COMMAND = $07;
  MTAP_SW_MTAP = $04;
  MTAP_SW_ETAP = $05;
  MTAP_IDCODE = $01;
  MCHP_STATUS = $00;
  MCHP_ASSERT_RST = $D1;
  MCHP_DE_ASSERT_RST = $D0;
  MCHP_ERASE = $FC;
  MCHP_FLASH_ENABLE = $FE;
  MCHP_FLASH_DISABLE = $FD;
  ETAP_ADDRESS = $08;
  ETAP_DATA = $09;
  ETAP_CONTROL = $0A;
  ETAP_EJTAGBOOT = $0C;
  ETAP_FASTDATA = $0E;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  PIC32LIST: array of TID32;

// --- function declarations ---
function PIC32_ID(id: Integer): Pointer;
function XferInstruction(j: ^Integer; instruction: Integer): Pointer;
function Read32x(dim: Integer; options: Integer): Pointer;

implementation

function PIC32_ID(id: Integer): Pointer;
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to ((SizeOf(PIC32LIST)) div (SizeOf(PIC32LIST[0]))) - 1 do
  begin
   if ((id) and ($0FFFFFFF)) = (PIC32LIST[i].id) then
   begin
    strcpy(s, PIC32LIST[i].device);
    strcat(s, '' + #13 + '' + NL + '');
    PrintMessage(s);
    Exit;
   end;
  end;
  PrintMessage(strings[S_nodev]);
end;

function XferInstruction(j: ^Integer; instruction: Integer): Pointer;
var
  i: Integer;
  z: Integer;
  w0: Integer;
  IO: Integer;
begin
  i := 0;
  w0 := 0;
  IO := 0;
  if (j) = (-(1)) then
  begin
   j := @(i);
   IO := 1;
  end;
  if IO then
  begin
   bufferU[Inc(j^)] := $54;
   bufferU[Inc(j^)] := $0A;
   bufferU[Inc(j^)] := $04;
   while (j^) < (64) do
   begin
    bufferU[j^] := $0;
    Inc(j^);
   end;
   PacketIO(5);
   i := 0;
   bufferU[Inc(j^)] := $55;
   bufferU[Inc(j^)] := $00;
   bufferU[Inc(j^)] := $04;
   bufferU[Inc(j^)] := $C0;
   bufferU[Inc(j^)] := $00;
   bufferU[Inc(j^)] := $04;
   while (j^) < (64) do
   begin
    bufferU[j^] := $0;
    Inc(j^);
   end;
   for i := 0 to (20) - 1 do
   begin
    PacketIO(5);
    z := 0;
    while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
    begin
     Inc(z);
    end;
    if (z) < ((64) - (4)) then
     w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
    if (w0) and ($40000) then
     Break;
   end;
   if (i) = (20) then
   begin
    sprintf(str, 'i=20 ECR=0x%08X' + #13 + '' + NL + '', w0);
    PrintMessage(str);
   end;
   i := 0;
  end;
  bufferU[Inc(j^)] := $54;
  bufferU[Inc(j^)] := $09;
  bufferU[Inc(j^)] := $55;
  bufferU[Inc(j^)] := ((instruction) shr (24)) and ($FF);
  bufferU[Inc(j^)] := ((instruction) shr (16)) and ($FF);
  bufferU[Inc(j^)] := ((instruction) shr (8)) and ($FF);
  bufferU[Inc(j^)] := (instruction) and ($FF);
  bufferU[Inc(j^)] := $54;
  bufferU[Inc(j^)] := $0A;
  bufferU[Inc(j^)] := $55;
  bufferU[Inc(j^)] := $00;
  bufferU[Inc(j^)] := $00;
  bufferU[Inc(j^)] := $C0;
  bufferU[Inc(j^)] := $00;
  if IO then
  begin
   bufferU[Inc(j^)] := $04;
   while (j^) < (64) do
   begin
    bufferU[j^] := $0;
    Inc(j^);
   end;
   PacketIO(5);
   i := 0;
  end;
end;

function Read32x(dim: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  start: Cardinal;
  w0: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  if (FWVersion) < ($A00) then
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
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read32x(%d,%d)    (0x%X,0x%X)' + NL + '', dim, options, dim, options);
  end;
  if ((dim) > ($80000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  size := dim;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  memset(memCODE, $FF, dim);
  StartHVReg(-(1));
  start := GetTickCount();
  w0 := 0;
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $27;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $53;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $53;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := $55;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(25);
  j := 0;
  z := 0;
  while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  bufferU[Inc(j)] := $55;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  i := 0;
  while (((w0) and ($C)) <> ($8)) and ((i) < (20)) do
  begin
   PacketIO(5);
   z := 0;
   while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
   begin
    Inc(z);
   end;
   if (z) < ((64) - (4)) then
    w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
   Inc(i);
  end;
  sprintf(str, 'Device status: CFGRDY=%d FCBUSY=%d (0x%02X)' + #13 + '' + NL + '', IfThen((w0) and ($8), 1, 0), IfThen((w0) and ($4), 1, 0), (w0) and ($FF));
  PrintMessage(str);
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $55;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  PacketIO(5);
  j := 0;
  z := 0;
  while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'IDCODE=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  PIC32_ID(w0);
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $53;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := $55;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $53;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $53;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $55;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  for i := 0 to (20) - 1 do
  begin
   PacketIO(5);
   z := 0;
   while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
   begin
    Inc(z);
   end;
   if (z) < ((64) - (4)) then
    w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
   if (w0) and ($40000) then
    Break;
  end;
  sprintf(str, 'ECR=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  i := $bFC00BF0;
  while (i) < ($bFC00C10) do
  begin
   XferInstruction(-(1), $3C13FF20);
   XferInstruction(-(1), ($3C080000) + ((i) shr (16)));
   XferInstruction(-(1), ($35080000) + ((i) and ($FFFF)));
   XferInstruction(-(1), $8d090000);
   XferInstruction(-(1), $ae690000);
   XferInstruction(-(1), 0);
   j := 0;
   bufferU[Inc(j)] := $54;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $56;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   j := 0;
   w0 := -(10);
   z := 0;
   while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
   begin
    Inc(z);
   end;
   if (z) < ((64) - (4)) then
    w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
   sprintf(str, '[0x%08X]=0x%08X' + #13 + '' + NL + '', i, w0);
   PrintMessage(str);
   Inc(i, 4);
  end;
  i := $BF80F230;
  XferInstruction(-(1), $3C13FF20);
  XferInstruction(-(1), ($3C080000) + ((i) shr (16)));
  XferInstruction(-(1), ($35080000) + ((i) and ($FFFF)));
  XferInstruction(-(1), $8d090000);
  XferInstruction(-(1), $ae690000);
  XferInstruction(-(1), 0);
  j := 0;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $56;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  w0 := -(10);
  z := 0;
  while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'DEVID=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  PacketIO(5);
  z := 0;
  while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'DEVID=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  PacketIO(5);
  z := 0;
  while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'DEVID=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  PacketIO(5);
  z := 0;
  while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'DEVID=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  PacketIO(5);
  z := 0;
  while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'DEVID=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  XferInstruction(-(1), $3C13FF20);
  XferInstruction(-(1), ($3C080000) + ((i) shr (16)));
  XferInstruction(-(1), ($35080000) + ((i) and ($FFFF)));
  XferInstruction(-(1), $8d090000);
  XferInstruction(-(1), $ae690000);
  XferInstruction(-(1), 0);
  j := 0;
  bufferU[Inc(j)] := $54;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $56;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  w0 := -(10);
  z := 0;
  while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
  begin
   Inc(z);
  end;
  if (z) < ((64) - (4)) then
   w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
  sprintf(str, 'DEVID=0x%08X' + #13 + '' + NL + '', w0);
  PrintMessage(str);
  i := $1FC00000;
  while ((i) < ($1FC00BF0)) and (0) do
  begin
   XferInstruction(@(j), $3C13FF20);
   XferInstruction(@(j), ($3C080000) + ((i) shr (16)));
   XferInstruction(@(j), ($35080000) + ((i) mod ($FFFF)));
   XferInstruction(@(j), $8d090000);
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   j := 0;
   XferInstruction(@(j), $ae690000);
   bufferU[Inc(j)] := $54;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $56;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(5);
   j := 0;
   z := 0;
   while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
   begin
    Inc(z);
   end;
   z := 4;
   while ((bufferI[z]) <> ($55)) and ((z) < (64)) do
   begin
    Inc(z);
   end;
   z := 4;
   while ((bufferI[z]) <> ($56)) and ((z) < (64)) do
   begin
    Inc(z);
   end;
   if (z) < ((64) - (4)) then
    w0 := ((((bufferI[(z) + (1)]) shl (24)) + ((bufferI[(z) + (2)]) shl (16))) + ((bufferI[(z) + (3)]) shl (8))) + (bufferI[(z) + (4)]);
   sprintf(str, '[0x%08X]=0x%08X' + #13 + '' + NL + '', i, w0);
   PrintMessage(str);
   Inc(i, 4);
  end;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  writeP();
  msDelay(2);
  readP();
  if saveLog then
   WriteLogIO();
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, '');
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
   CloseLogFile();
end;

end.
