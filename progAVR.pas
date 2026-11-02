unit progavr;

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
  mainform;

const
  LOCK = 1;
  FUSE = 2;
  FUSE_H = 4;
  FUSE_X = 8;
  CAL = 16;
  SLOW = 256;
  RST = $40;
  SPEED = 3000;
  SDI = $10;
  SII = $1;
  SDO = $2;
  SCI = $8;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  AVRLIST: array of TAVRID;

// --- function declarations ---
function AtmelID(id: array of TBYTE): Pointer;
function DisplayCODEAVR(dim: Integer): Pointer;
function SWSPI(data: Integer; speed: Integer): Integer;
function WriteATfuseSlow(fuse: Integer): Pointer;
function SyncSPI: Double;
function ReadAT(dim: Integer; dim2: Integer; options: Integer): Pointer;
function ReadAT_HV(dim: Integer; dim2: Integer; options: Integer): Pointer;
function WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer): Pointer;
function WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
function WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;

implementation

function AtmelID(id: array of TBYTE): Pointer;
var
  str: array[0..128-1] of Char;
  i: Integer;
  idw: Integer;
  strcat(str,"\r\n"): Telse;
begin
  (* TODO gtk2laz: array initializer
    Source: /tmp/opgui-0.12.4/progAVR.c:86
    Original C:
      	char str[128]="";
  *)
  idw := (id[1] shl 8)+id[2];
  if id[0] = 0 and id[1] = 1 and id[2] = 2 then
  begin
   PrintMessage(strings[S_Protected]);
   Exit;
  end;
  for i := 0 to (sizeof(AVRLIST)/sizeof(AVRLIST[0])) - 1 do
  begin
   if idw = AVRLIST[i].id then
   begin
    strcat(str, AVRLIST[i].device);
    i := 1000;
   end;
  end;
  PrintMessage(str);
end;

function DisplayCODEAVR(dim: Integer): Pointer;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
  aux: PChar;
begin
  s := "";
  t := "";
  valid := 0;
  empty := 1;
  lines := 0;
  aux := malloc((((dim) div (16)) + (1)) * ((16) + ((16) * (6))));
  aux[0] := 0;
  s[0] := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:137
    Original C:
      for (i = 0; (i < dim) && (i < size); i += 16 * 2)
      {
        valid = 0;
        for (j = i; (j < (i + (16 * 2))) && (j < dim); j++)
        {
          sprintf(t, "%02X ", memCODE[j]);
          strcat(s, t);
          if (memCODE[j] < 0xff)
            valid = 1;
        }
      
        if (valid)
        {
          sprintf(t, "%04X: %s\r\n", i, s);
          strcat(aux, t);
          empty = 0;
          lines++;
          if (lines > 500)
          {
            strcat(aux, "(...)\r\n");
            i = ((dim < size) ? (dim) : (size)) - (16 * 4);
            lines = 490;
          }
        }
        s[0] = 0;
      }
  *)
  // init: i = 0
  while ((i) < (dim)) and ((i) < (size)) do
  begin
   valid := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:139
     Original C:
       for (j = i; (j < (i + (16 * 2))) && (j < dim); j++)
       {
         sprintf(t, "%02X ", memCODE[j]);
         strcat(s, t);
         if (memCODE[j] < 0xff)
           valid = 1;
       }
   *)
   // init: j = i
   while ((j) < ((i) + ((16) * (2)))) and ((j) < (dim)) do
   begin
    sprintf(t, "%02X ", memCODE[j]);
    strcat(s, t);
    if (memCODE[j]) < ($ff) then
     valid := 1;
     // step: j++
   end;
   if valid then
   begin
    sprintf(t, "%04X: %s\r\n", i, s);
    strcat(aux, t);
    empty := 0;
    Inc(lines);
    if (lines) > (500) then
    begin
     strcat(aux, "(...)\r\n");
     i := (IfThen((dim) < (size), dim, size)) - ((16) * (4));
     lines := 490;
    end;
   end;
   s[0] := 0;
    // step: i += 16 * 2
  end;
  if empty then
   PrintMessage(strings[S_Empty]);
  else
   PrintMessage(aux);
  free(aux);
end;

function SWSPI(data: Integer; speed: Integer): Integer;
var
  i: Integer;
  j: Integer;
  din: Integer;
  Tbit: Double;
begin
  din := 0;
  Tbit := ((1.0) div (speed)) * (1e6);
  if saveLog then
   fprintf(logfile, "SWSPI(0x%X,%d)\n", data, speed);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := ((Tbit) div (2)) shr (8);
  bufferU[Inc(j)] := ((Tbit) div (2)) and ($ff);
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $F5;
  bufferU[Inc(j)] := $3F;
  for i := 0 to (4) - 1 do
  begin
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := (data) and ($80);
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := (data) and ($80);
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $0A;
   data := data shl 1;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((4) * (((Tbit) div (1000.0)) + (0.5))));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:192
    Original C:
      for (j = 0; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j = 0
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:195
    Original C:
      for (j += 2; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j += 2
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:198
    Original C:
      for (j += 2; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j += 2
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:201
    Original C:
      for (j += 2; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j += 2
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  j := 0;
  for i := 0 to (4) - 1 do
  begin
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := (data) and ($80);
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := (data) and ($80);
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $0A;
   data := data shl 1;
  end;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((4) * (((Tbit) div (1000.0)) + (0.5))));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:223
    Original C:
      for (j = 0; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j = 0
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:226
    Original C:
      for (j += 2; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j += 2
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:229
    Original C:
      for (j += 2; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j += 2
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  din := din shl 1;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:232
    Original C:
      for (j += 2; (j < (64 - 1)) && (bufferI[j] != 0x46); j++)
        ;
  *)
  // init: j += 2
  while ((j) < ((64) - (1))) and ((bufferI[j]) <> ($46)) do
  begin
    // step: j++
  end;
  din := din + (bufferI[(j) + (1)]) and (1);
  if saveLog then
   fprintf(logfile, "Read 0x%X\n", din);
  Exit(din);
end;

function WriteATfuseSlow(fuse: Integer): Pointer;
var
  j: Integer;
  d: Integer;
begin
  fuse := fuse and $FF;
  if (FWVersion) < ($900) then
  begin
   sprintf(str, strings[S_FWver2old], "0.9.0");
   PrintMessage(str);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "WriteATfuseSlow(0x%X)\n", fuse);
  end;
  PrintMessage(strings[S_FuseAreaW]);
  j := 0;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $F5;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $35;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  msDelay(20);
  SWSPI($AC, 3000);
  SWSPI($53, 3000);
  d := SWSPI(0, 3000);
  SWSPI(0, 3000);
  if (d) <> ($53) then
  begin
   j := 0;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   PrintMessage(strings[S_SyncErr]);
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  SWSPI($AC, 3000);
  SWSPI($A0, 3000);
  SWSPI($00, 3000);
  SWSPI(fuse, 3000);
  msDelay(9);
  SWSPI($50, 3000);
  SWSPI($00, 3000);
  SWSPI($00, 3000);
  d := SWSPI(0, 3000);
  if (d) <> (fuse) then
  begin
   sprintf(str, strings[S_WErr1], "fuse", fuse, d);
   PrintMessage(str);
  end;
  j := 0;
  bufferU[Inc(j)] := $35;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  PrintMessage(strings[S_Compl]);
end;

function SyncSPI: Double;
var
  z: Integer;
  i: Integer;
  j: Integer;
  Tbyte: Double;
  d0: Integer;
  d1: Integer;
  d2: Integer;
  d3: Integer;
  d4: Integer;
  d5: Integer;
  d6: Integer;
  d7: Integer;
begin
  z := 0;
  j := 0;
  bufferU[Inc(j)] := $2F;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  for i := 1 to (256) - 1 do
  begin
   if (i) > (10) then
    Inc(i);
   if (i) > (20) then
    i := i + 2;
   if (i) > (40) then
    i := i + 4;
   if (i) > (80) then
    i := i + 4;
   if (i) > (160) then
    i := i + 8;
   Tbyte := ((20) + ((i) * (4))) div (1000.0);
   j := 0;
   bufferU[Inc(j)] := $35;
   bufferU[Inc(j)] := $FF;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := i;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $40;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $35;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(9);
   msDelay(20);
   j := 0;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $53;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 11;
   bufferU[Inc(j)] := $55;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $AA;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $55;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $AA;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $53;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO((1.5) + (((32) * (Tbyte)) * (1.1)));
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:428
     Original C:
       for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d0 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:431
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d1 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:433
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d2 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:435
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d3 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:437
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d4 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:439
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d5 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:441
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d6 := bufferI[(z) + (2)];
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:443
     Original C:
       for (z += bufferI[z + 1] + 1; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += bufferI[z + 1] + 1
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   d7 := bufferI[(z) + (2)];
   if (((((((d0) = ($53)) and ((d6) = ($53))) and ((d1) = (d2))) and ((d1) = (d3))) and ((d1) = (d4))) and ((d1) = (d5))) and ((d1) = (d7)) then
    Break;
  end;
  if (i) > (256) then
  begin
   PrintMessage(strings[S_SyncErr]);
   if saveLog then
    fprintf(logfile, strings[S_SyncErr]);
   Exit(0);
  end;
  Inc(i);
  i := i + (i) div (10);
  if (i) > (255) then
   i := 255;
  Tbyte := ((20) + ((i) * (4))) div (1000.0);
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := i;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  sprintf(str, strings_it[I_AT_COMM], (8) div (Tbyte));
  PrintMessage(str);
  if saveLog then
   fprintf(logfile, str);
  Exit(Tbyte);
end;

function ReadAT(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  Tbyte: Double;
  signature: array of TBYTE;
  start: Cardinal;
  c: Integer;
  n: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  signature := [0, 0, 0];
  if ((dim) > ($20000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($1000)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "ReadAT(0x%X,0x%X,0x%X)\n", dim, dim2, options);
  end;
  size := dim;
  sizeEE := dim2;
  if memCODE then
   free(memCODE);
  memCODE := malloc(dim);
  if memEE then
   free(memEE);
  memEE := malloc(dim2);
  for j := 0 to (size) - 1 do
  begin
   memCODE[j] := $FF;
  end;
  for j := 0 to (sizeEE) - 1 do
  begin
   memEE[j] := $FF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  Tbyte := SyncSPI();
  if (Tbyte) = (0) then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  if (options) and (1) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
  end;
  if (options) and (2) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
  end;
  if (options) and (4) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
  end;
  if (options) and (8) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1.5) + (((7) * (4.5)) * (Tbyte)));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:578
    Original C:
      for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z = 0
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[0] := bufferI[(z) + (2)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:580
    Original C:
      for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z += 3
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[1] := bufferI[(z) + (2)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:582
    Original C:
      for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z += 3
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[2] := bufferI[(z) + (2)];
  sprintf(str, "CHIP ID:%02X%02X%02X\r\n", signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  if (options) and (1) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:587
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, "LOCK bits:\t  0x%02X\r\n", bufferI[(z) + (2)]);
   PrintMessage(str);
  end;
  if (options) and (2) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:591
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, "FUSE bits:\t  0x%02X\r\n", bufferI[(z) + (2)]);
   PrintMessage(str);
  end;
  if (options) and (4) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:595
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, "FUSE HIGH bits:\t  0x%02X\r\n", bufferI[(z) + (2)]);
   PrintMessage(str);
  end;
  if (options) and (8) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:599
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, "Extended FUSE bits: 0x%02X\r\n", bufferI[(z) + (2)]);
   PrintMessage(str);
  end;
  if (options) and (16) then
  begin
   j := 0;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO((1.5) + (((4.5) * (4)) * (Tbyte)));
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:635
     Original C:
       for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, "Calibration bits:\t  0x%02X", bufferI[(z) + (2)]);
   PrintMessage(str);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:637
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, ",0x%02X", bufferI[(z) + (2)]);
   PrintMessage(str);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:639
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, ",0x%02X", bufferI[(z) + (2)]);
   PrintMessage(str);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:641
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   sprintf(str, ",0x%02X\r\n", bufferI[(z) + (2)]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_CodeReading1]);
  c := ((64) - (5)) div (2);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:649
    Original C:
      for (i = 0, j = 0; i < dim; i += c * 2)
      {
        bufferU[j++] = 0x33;
        bufferU[j++] = (i < (dim - (2 * c))) ? (c) : ((dim - i) / 2);
        bufferU[j++] = i >> 9;
        bufferU[j++] = i >> 1;
        bufferU[j++] = 0x04;
        for (; j < 64; j++)
          bufferU[j] = 0x0;
      
        PacketIO(1.5 + (240 * Tbyte));
        if (bufferI[0] == 0x33)
        {
          for (z = 2; (z < ((bufferI[1] * 2) + 2)) && (z < 64); z++)
            memCODE[k++] = bufferI[z];
      
        }
        {
          sprintf(str, strings[S_CodeReading], (i * 100) / (dim + dim2), i);
          gtk_statusbar_push((GtkStatusbar * ) status_bar, statusID, str);
          while (gtk_events_pending())
            gtk_mai...
  *)
  // init: i = 0, j = 0
  while (i) < (dim) do
  begin
   bufferU[Inc(j)] := $33;
   bufferU[Inc(j)] := IfThen((i) < ((dim) - ((2) * (c))), c, ((dim) - (i)) div (2));
   bufferU[Inc(j)] := (i) shr (9);
   bufferU[Inc(j)] := (i) shr (1);
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO((1.5) + ((240) * (Tbyte)));
   if (bufferI[0]) = ($33) then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:658
      Original C:
        for (z = 2; (z < ((bufferI[1] * 2) + 2)) && (z < 64); z++)
          memCODE[k++] = bufferI[z];
    *)
    // init: z = 2
    while ((z) < (((bufferI[1]) * (2)) + (2))) and ((z) < (64)) do
    begin
     memCODE[Inc(k)] := bufferI[z];
      // step: z++
    end;
   end;
   sprintf(str, strings[S_CodeReading], ((i) * (100)) div ((dim) + (dim2)), i);
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
    fprintf(logfile, strings[S_Log7], i, i, k, k);
    // step: i += c * 2
  end;
  if (k) <> (dim) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if dim2 then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, "%s\n", strings[S_ReadEE]);
   n := 0;
   while (i) < (dim2) do
   begin
    bufferU[Inc(j)] := $31;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := (i) shr (8);
    bufferU[Inc(j)] := i;
    bufferU[Inc(j)] := $30;
    bufferU[Inc(j)] := 1;
    Inc(n);
    if ((j) > ((64) - (9))) or ((i) = ((dim) - (1))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO((1.5) + ((((4) * (n)) * (Tbyte)) * (1.3)));
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if ((bufferI[z]) = ($30)) and ((bufferI[(z) + (1)]) = (1)) then
      begin
       memEE[Inc(k2)] := bufferI[(z) + (2)];
       z := z + 3;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (((i) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := dim2;
     j := 0;
     n := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
    Inc(i);
   end;
   if (k2) <> (dim2) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ReadEEErr], dim2, k2);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := $35;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, "");
  PrintMessage(strings[S_CodeMem]);
  DisplayCODEAVR(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function ReadAT_HV(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  signature: array of TBYTE;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  signature := [0, 0, 0];
  if (FWVersion) < ($900) then
  begin
   sprintf(str, strings[S_FWver2old], "0.9.0");
   PrintMessage(str);
   Exit;
  end;
  if ((dim) > ($20000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "ReadAT_HV(0x%X,0x%X,0x%X)\n", dim, dim2, options);
  end;
  size := dim;
  sizeEE := dim2;
  if memCODE then
   free(memCODE);
  memCODE := malloc(dim);
  if memEE then
   free(memEE);
  memEE := malloc(dim2);
  for j := 0 to (size) - 1 do
  begin
   memCODE[j] := $FF;
  end;
  for j := 0 to (sizeEE) - 1 do
  begin
   memEE[j] := $FF;
  end;
  if not (StartHVReg(12)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $FC;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  if (options) and (1) then
  begin
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $00;
  end;
  if (options) and (2) then
  begin
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $68;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
   bufferU[Inc(j)] := $00;
  end;
  if (options) and (4) then
  begin
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $7A;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7E;
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
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:904
    Original C:
      for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
        ;
  *)
  // init: z = 0
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
  begin
    // step: z++
  end;
  signature[0] := bufferI[(z) + (1)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:906
    Original C:
      for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
        ;
  *)
  // init: z += 2
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
  begin
    // step: z++
  end;
  signature[1] := bufferI[(z) + (1)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:908
    Original C:
      for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
        ;
  *)
  // init: z += 2
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
  begin
    // step: z++
  end;
  signature[2] := bufferI[(z) + (1)];
  sprintf(str, "CHIP ID:%02X%02X%02X\r\n", signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  if (options) and (1) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:913
     Original C:
       for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z += 2
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   sprintf(str, "LOCK byte:\t  0x%02X\r\n", bufferI[(z) + (1)]);
   PrintMessage(str);
  end;
  if (options) and (2) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:917
     Original C:
       for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z += 2
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   sprintf(str, "FUSE byte:\t  0x%02X\r\n", bufferI[(z) + (1)]);
   PrintMessage(str);
  end;
  if (options) and (4) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:921
     Original C:
       for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z += 2
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   sprintf(str, "FUSE HIGH byte:\t  0x%02X\r\n", bufferI[(z) + (1)]);
   PrintMessage(str);
  end;
  if (options) and (8) then
  begin
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $00;
  end;
  if (options) and (16) then
  begin
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $0C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $00;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  PacketIO(2);
  z := 0;
  if (options) and (8) then
  begin
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
    Inc(z);
   end;
   sprintf(str, "Extended FUSE byte: 0x%02X\r\n", bufferI[(z) + (1)]);
   PrintMessage(str);
   z := z + 2;
  end;
  if (options) and (16) then
  begin
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
    Inc(z);
   end;
   sprintf(str, "Calibration byte: 0x%02X\r\n", bufferI[(z) + (1)]);
   PrintMessage(str);
  end;
  if saveLog then
   fprintf(logfile, "READ CODE\n");
  PrintMessage(strings[S_CodeReading1]);
  j := 0;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:973
    Original C:
      for (i = 0; i < dim;)
      {
        if ((i & 511) == 0)
        {
          bufferU[j++] = 0x48;
          bufferU[j++] = 1;
          bufferU[j++] = 0x1C;
          bufferU[j++] = i >> 9;
          bufferU[j++] = 0x04;
          for (; j < 64; j++)
            bufferU[j] = 0x0;
      
          PacketIO(2);
          j = 0;
        }
        bufferU[j++] = 0x48;
        bufferU[j++] = 3;
        bufferU[j++] = 0x0C;
        bufferU[j++] = (i >> 1) & 0xFF;
        bufferU[j++] = 0x68;
        bufferU[j++] = 0x00;
        bufferU[j++] = 0x6C;
        bufferU[j++] = 0x00;
        bufferU[j++] = 0x48;
        bufferU[j++] = 2;
        bufferU[j++] = 0x78;
        bufferU[j++] = 0x00;
        bufferU[j++] = 0x7C;
        bufferU[j++] = 0x00;
        i += 2;
      ... (tru...
  *)
  // init: i = 0
  while (i) < (dim) do
  begin
   if ((i) and (511)) = (0) then
   begin
    bufferU[Inc(j)] := $48;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $1C;
    bufferU[Inc(j)] := (i) shr (9);
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
   end;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $0C;
   bufferU[Inc(j)] := ((i) shr (1)) and ($FF);
   bufferU[Inc(j)] := $68;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $00;
   i := i + 2;
   if ((j) > ((64) - (14))) or ((i) >= ((dim) - (2))) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    for z := 0 to ((64) - (1)) - 1 do
    begin
     if (bufferI[z]) = ($48) then
     begin
      memCODE[Inc(k)] := bufferI[(z) + (1)];
      z := z + 1;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((i) * (100)) div ((dim) + (dim2)), i);
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
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadCodeErr], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if dim2 then
  begin
   if saveLog then
    fprintf(logfile, "READ EEPROM\n");
   PrintMessage(strings[S_ReadEE]);
   j := 0;
   k := 0;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if ((i) and (255)) = (0) then
    begin
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     j := 0;
    end;
    bufferU[Inc(j)] := $48;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := $0C;
    bufferU[Inc(j)] := (i) and ($FF);
    bufferU[Inc(j)] := $68;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $6C;
    bufferU[Inc(j)] := $00;
    if ((j) > ((64) - (8))) or ((i) >= ((dim2) - (2))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     for z := 0 to ((64) - (1)) - 1 do
     begin
      if (bufferI[z]) = ($48) then
      begin
       memEE[Inc(k)] := bufferI[(z) + (1)];
       z := z + 1;
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((i) * (100)) div ((dim) + (dim2)), i);
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
   if (k) <> (dim2) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ReadEEErr], dim2, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, "");
  PrintMessage(strings[S_CodeMem]);
  DisplayCODEAVR(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function WriteAT(dim: Integer; dim2: Integer; dummy1: Integer; dummy2: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  Tbyte: Double;
  signature: array of TBYTE;
  start: Cardinal;
  errEE: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  signature := [0, 0, 0];
  if ((dim) > ($8000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "WriteAT(0x%X,0x%X)\n", dim, dim2);
  end;
  if (dim) > (size) then
   dim := size;
  if (dim2) > (sizeEE) then
   dim2 := sizeEE;
  if (dim) < (1) then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  Tbyte := SyncSPI();
  if (Tbyte) = (0) then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + (((3) * (4)) * (Tbyte)));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1254
    Original C:
      for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z = 0
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[0] := bufferI[(z) + (2)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1256
    Original C:
      for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z += 3
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[1] := bufferI[(z) + (2)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1258
    Original C:
      for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z += 3
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[2] := bufferI[(z) + (2)];
  sprintf(str, "CHIP ID:%02X%02X%02X\r\n", signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
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
  PacketIO((1) + ((4) * (Tbyte)));
  msDelay(25);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_StartCodeProg]);
  while (i) < (dim) do
  begin
   if (memCODE[i]) <> ($FF) then
   begin
    bufferU[Inc(j)] := $31;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := ($40) + (IfThen((i) and (1), 8, 0));
    bufferU[Inc(j)] := (i) shr (9);
    bufferU[Inc(j)] := (i) shr (1);
    bufferU[Inc(j)] := memCODE[i];
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $31;
    bufferU[Inc(j)] := 3;
    bufferU[Inc(j)] := ($20) + (IfThen((i) and (1), 8, 0));
    bufferU[Inc(j)] := (i) shr (9);
    bufferU[Inc(j)] := (i) shr (1);
    bufferU[Inc(j)] := $30;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    j := 0;
    PacketIO((7) + (((2) * (4)) * (Tbyte)));
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:1308
      Original C:
        for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
          ;
    *)
    // init: z = 0
    while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
    begin
      // step: z++
    end;
    if ((z) = ((64) - (2))) or ((memCODE[i]) <> (bufferI[(z) + (2)])) then
    begin
     Inc(err);
    end;
    if (max_err) and ((err) > (max_err)) then
    begin
     sprintf(str, strings[S_MaxErr], err);
     PrintMessage(str);
     PrintMessage(strings[S_IntW]);
     i := dim;
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, k, k, err);
    end;
   end;
   Inc(i);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, "%s\n", strings[S_EEAreaW]);
   errEE := 0;
   while (i) < (dim2) do
   begin
    if (memEE[i]) <> ($FF) then
    begin
     bufferU[Inc(j)] := $31;
     bufferU[Inc(j)] := 4;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $31;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $A0;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := $30;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     PacketIO((7) + (((2) * (4)) * (Tbyte)));
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:1353
       Original C:
         for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
           ;
     *)
     // init: z = 0
     while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
     begin
       // step: z++
     end;
     if ((z) = ((64) - (2))) or ((memEE[i]) <> (bufferI[(z) + (2)])) then
     begin
      Inc(errEE);
     end;
     if (max_err) and (((err) + (errEE)) > (max_err)) then
     begin
      sprintf(str, strings[S_MaxErr], (err) + (errEE));
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim2;
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
    Inc(i);
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end;
  if (AVRlock) < ($100) then
  begin
   PrintMessage(strings[S_FuseAreaW]);
   if saveLog then
    fprintf(logfile, "%s\n", strings[S_FuseAreaW]);
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := ($F9) + ((AVRlock) and ($06));
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO((3) + ((4) * (Tbyte)));
   msDelay(15);
   PrintMessage(strings[S_Compl]);
  end;
  bufferU[Inc(j)] := $35;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 0;
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
  gtk_statusbar_push(status_bar, statusID, "");
end;

function WriteATmega(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  Tbyte: Double;
  err: Integer;
  Rtry: Integer;
  maxTry: Integer;
  signature: array of TBYTE;
  start: Cardinal;
  w: Integer;
  v: Integer;
  c: Integer;
  errEE: Integer;
  err_f: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  Rtry := 0;
  maxTry := 0;
  signature := [0, 0, 0];
  if ((dim) > ($20000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($1000)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "WriteATmega(0x%X,0x%X,0x%X,0x%X)\n", dim, dim2, page, options);
  end;
  if (dim) > (size) then
   dim := size;
  else
  begin
   size := dim;
   memCODE := realloc(memCODE, dim);
  end;
  if (size) mod ((page) * (2)) then
  begin
   j := size;
   dim := ((((j) div ((page) * (2))) + (1)) * (page)) * (2);
   memCODE := realloc(memCODE, dim);
   while (j) < (dim) do
   begin
    memCODE[j] := $FF;
    Inc(j);
   end;
  end;
  if (dim2) > (sizeEE) then
   dim2 := sizeEE;
  if (dim) < (1) then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  Tbyte := SyncSPI();
  if (Tbyte) = (0) then
  begin
   if saveLog then
    CloseLogFile();
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1.5) + (((3) * (4.5)) * (Tbyte)));
  if saveLog then
   WriteLogIO();
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1488
    Original C:
      for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z = 0
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[0] := bufferI[(z) + (2)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1490
    Original C:
      for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z += 3
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[1] := bufferI[(z) + (2)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1492
    Original C:
      for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
        ;
  *)
  // init: z += 3
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
  begin
    // step: z++
  end;
  signature[2] := bufferI[(z) + (2)];
  sprintf(str, "CHIP ID:%02X%02X%02X\r\n", signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (5000) shr (8);
  bufferU[Inc(j)] := (5000) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO((1) + ((4) * (Tbyte)));
  msDelay(15);
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_StartCodeProg]);
  w := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1520
    Original C:
      for (i = 0; i < dim; i += page * 2)
      {
        for (z = i, v = 0; z < (i + (page * 2)); z++)
          if (memCODE[z] < 0xFF)
          v = 1;
      
        if (v)
        {
          for (k = 0, j = 0, v = 0; k < page; k += w)
          {
            w = ((page - k) < ((64 - 6) / 2)) ? (page - k) : ((64 - 6) / 2);
            bufferU[j++] = 0x34;
            bufferU[j++] = w;
            bufferU[j++] = k >> 8;
            bufferU[j++] = k;
            for (z = 0; z < (w * 2); z++)
              bufferU[j++] = memCODE[(i + (k * 2)) + z];
      
            bufferU[j++] = 0x04;
            for (; j < 64; j++)
              bufferU[j] = 0x0;
      
            j = 0;
            PacketIO(1.5 + ((w * 9) * Tbyte));
          }
      
          ...
  *)
  // init: i = 0
  while (i) < (dim) do
  begin
   while (z) < ((i) + ((page) * (2))) do
   begin
    if (memCODE[z]) < ($FF) then
     v := 1;
    Inc(z);
   end;
   if v then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:1523
      Original C:
        for (k = 0, j = 0, v = 0; k < page; k += w)
        {
          w = ((page - k) < ((64 - 6) / 2)) ? (page - k) : ((64 - 6) / 2);
          bufferU[j++] = 0x34;
          bufferU[j++] = w;
          bufferU[j++] = k >> 8;
          bufferU[j++] = k;
          for (z = 0; z < (w * 2); z++)
            bufferU[j++] = memCODE[(i + (k * 2)) + z];
        
          bufferU[j++] = 0x04;
          for (; j < 64; j++)
            bufferU[j] = 0x0;
        
          j = 0;
          PacketIO(1.5 + ((w * 9) * Tbyte));
        }
    *)
    // init: k = 0, j = 0, v = 0
    while (k) < (page) do
    begin
     w := IfThen(((page) - (k)) < (((64) - (6)) div (2)), (page) - (k), ((64) - (6)) div (2));
     bufferU[Inc(j)] := $34;
     bufferU[Inc(j)] := w;
     bufferU[Inc(j)] := (k) shr (8);
     bufferU[Inc(j)] := k;
     for z := 0 to ((w) * (2)) - 1 do
     begin
      bufferU[Inc(j)] := memCODE[((i) + ((k) * (2))) + (z)];
     end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     PacketIO((1.5) + (((w) * (9)) * (Tbyte)));
      // step: k += w
    end;
    bufferU[Inc(j)] := $31;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $4C;
    bufferU[Inc(j)] := (i) shr (9);
    bufferU[Inc(j)] := (i) shr (1);
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    j := 0;
    PacketIO((6) + ((4) * (Tbyte)));
    sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    if RWstop then
     i := dim;
    c := ((64) - (5)) div (2);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:1551
      Original C:
        for (k = 0, j = 0; k < page; k += c)
        {
          for (Rtry = 0; Rtry < 5; Rtry++)
          {
            bufferU[j++] = 0x33;
            bufferU[j++] = (k < (page - c)) ? (c) : (page - k);
            bufferU[j++] = (i + (k * 2)) >> 9;
            bufferU[j++] = (i + (k * 2)) >> 1;
            bufferU[j++] = 0x04;
            for (; j < 64; j++)
              bufferU[j] = 0x0;
        
            PacketIO(1.5 + (240 * Tbyte));
            if (bufferI[0] == 0x33)
            {
              for (w = 0, z = 2; (z < ((bufferI[1] * 2) + 2)) && (z < 64); z++)
              {
                if (memCODE[(i + (k * 2)) + w] != bufferI[z])
                {
                  if (Rtry < 4)
                    z = 64;
                  else
                    err++...
    *)
    // init: k = 0, j = 0
    while (k) < (page) do
    begin
     for Rtry := 0 to (5) - 1 do
     begin
      bufferU[Inc(j)] := $33;
      bufferU[Inc(j)] := IfThen((k) < ((page) - (c)), c, (page) - (k));
      bufferU[Inc(j)] := ((i) + ((k) * (2))) shr (9);
      bufferU[Inc(j)] := ((i) + ((k) * (2))) shr (1);
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO((1.5) + ((240) * (Tbyte)));
      if (bufferI[0]) = ($33) then
      begin
       (* TODO gtk2laz: for loop with non-standard form; rewritten as while
         Source: /tmp/opgui-0.12.4/progAVR.c:1561
         Original C:
           for (w = 0, z = 2; (z < ((bufferI[1] * 2) + 2)) && (z < 64); z++)
           {
             if (memCODE[(i + (k * 2)) + w] != bufferI[z])
             {
               if (Rtry < 4)
                 z = 64;
               else
                 err++;
             }
             w++;
           }
       *)
       // init: w = 0, z = 2
       while ((z) < (((bufferI[1]) * (2)) + (2))) and ((z) < (64)) do
       begin
        if (memCODE[((i) + ((k) * (2))) + (w)]) <> (bufferI[z]) then
        begin
         if (Rtry) < (4) then
          z := 64;
         else
          Inc(err);
        end;
        Inc(w);
         // step: z++
       end;
       if (z) < (64) then
        Rtry := 100;
      end;
      j := 0;
     end;
      // step: k += c
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log8], i, i, w, w, err);
    end;
    if (max_err) and ((err) > (max_err)) then
    begin
     sprintf(str, strings[S_MaxErr], err);
     PrintMessage(str);
     PrintMessage(strings[S_IntW]);
     i := dim;
    end;
   end;
    // step: i += page * 2
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, "%s\n", strings[S_EEAreaW]);
   errEE := 0;
   while (i) < (dim2) do
   begin
    if (memEE[i]) <> ($FF) then
    begin
     bufferU[Inc(j)] := $31;
     bufferU[Inc(j)] := 4;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $31;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $A0;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := i;
     bufferU[Inc(j)] := $30;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     PacketIO((11) + ((8.5) * (Tbyte)));
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:1613
       Original C:
         for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
           ;
     *)
     // init: z = 0
     while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
     begin
       // step: z++
     end;
     if ((z) = ((64) - (2))) or ((memEE[i]) <> (bufferI[(z) + (2)])) then
     begin
      if (Rtry) < (4) then
      begin
       Inc(Rtry);
       if (Rtry) > (maxTry) then
        maxTry := Rtry;
       Dec(i);
      end
      else
      begin
       Inc(errEE);
       Rtry := 0;
      end;
     end;
     if (max_err) and (((err) + (errEE)) > (max_err)) then
     begin
      sprintf(str, strings[S_MaxErr], (err) + (errEE));
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim2;
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
    Inc(i);
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end;
  err_f := 0;
  if ((((AVRlock) < ($100)) or ((AVRfuse) < ($100))) or ((AVRfuse_h) < ($100))) or ((AVRfuse_x) < ($100)) then
  begin
   PrintMessage(strings[S_FuseAreaW]);
   if saveLog then
    fprintf(logfile, "%s\n", strings[S_FuseAreaW]);
  end;
  if (AVRfuse) < ($100) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := AVRfuse;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO((6) + ((8.5) * (Tbyte)));
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:1664
     Original C:
       for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (2))) or ((AVRfuse) <> (bufferI[(z) + (2)])) then
    Inc(err_f);
  end;
  if (AVRfuse_h) < ($100) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := AVRfuse_h;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO((6) + ((8.5) * (Tbyte)));
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:1686
     Original C:
       for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (2))) or ((AVRfuse_h) <> (bufferI[(z) + (2)])) then
    Inc(err_f);
  end;
  if (AVRfuse_x) < ($100) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $A4;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := AVRfuse_x;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO((6) + ((8.5) * (Tbyte)));
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:1708
     Original C:
       for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (2))) or ((AVRfuse_x) <> (bufferI[(z) + (2)])) then
    Inc(err_f);
  end;
  if (AVRlock) < ($100) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $AC;
   bufferU[Inc(j)] := $E0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := AVRlock;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO((6) + ((8.5) * (Tbyte)));
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:1730
     Original C:
       for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x30); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($30)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (2))) or ((AVRlock) <> (bufferI[(z) + (2)])) then
    Inc(err_f);
  end;
  err := err + err_f;
  if ((((AVRlock) < ($100)) or ((AVRfuse) < ($100))) or ((AVRfuse_h) < ($100))) or ((AVRfuse_x) < ($100)) then
  begin
   sprintf(str, strings[S_ComplErr], err_f);
   PrintMessage(str);
  end;
  bufferU[Inc(j)] := $35;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $31;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 0;
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
  gtk_statusbar_push(status_bar, statusID, "");
end;

function WriteAT_HV(dim: Integer; dim2: Integer; page: Integer; options: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  t: Integer;
  sdo: Integer;
  err: Integer;
  signature: array of TBYTE;
  start: Cardinal;
  currPage: Integer;
  m: Integer;
  errEE: Integer;
  err_f: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  signature := [0, 0, 0];
  if (FWVersion) < ($900) then
  begin
   sprintf(str, strings[S_FWver2old], "0.9.0");
   PrintMessage(str);
   Exit;
  end;
  if ((dim) > ($10000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "WriteAT_HV(0x%X,0x%X,0x%X,0x%X)\n", dim, dim2, page, options);
  end;
  if (dim) > (size) then
   dim := size;
  else
  begin
   size := dim;
   memCODE := realloc(memCODE, dim);
  end;
  if (page) and ((size) mod ((page) * (2))) then
  begin
   j := size;
   dim := ((((j) div ((page) * (2))) + (1)) * (page)) * (2);
   memCODE := realloc(memCODE, dim);
   while (j) < (dim) do
   begin
    memCODE[j] := $FF;
    Inc(j);
   end;
  end;
  if (dim2) > (sizeEE) then
   dim2 := sizeEE;
  if (dim) < (1) then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  if not (StartHVReg(12)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $FC;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $7;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $01;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $68;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(8);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1892
    Original C:
      for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
        ;
  *)
  // init: z = 0
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
  begin
    // step: z++
  end;
  signature[0] := bufferI[(z) + (1)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1894
    Original C:
      for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
        ;
  *)
  // init: z += 2
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
  begin
    // step: z++
  end;
  signature[1] := bufferI[(z) + (1)];
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1896
    Original C:
      for (z += 2; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
        ;
  *)
  // init: z += 2
  while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
  begin
    // step: z++
  end;
  signature[2] := bufferI[(z) + (1)];
  sprintf(str, "CHIP ID:%02X%02X%02X\r\n", signature[0], signature[1], signature[2]);
  PrintMessage(str);
  AtmelID(signature);
  if saveLog then
   fprintf(logfile, "CHIP ERASE\n");
  j := 0;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := $4C;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $64;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $6C;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $46;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  bufferU[Inc(j)] := $46;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progAVR.c:1919
    Original C:
      for (t = 0, sdo = 0; (t < 20) && (sdo == 0); t++)
      {
        PacketIO(2);
        for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
          ;
      
        sdo = bufferI[z + 1] & 2;
      }
  *)
  // init: t = 0, sdo = 0
  while ((t) < (20)) and ((sdo) = (0)) do
  begin
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:1921
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
   begin
     // step: z++
   end;
   sdo := (bufferI[(z) + (1)]) and (2);
    // step: t++
  end;
  if ((sdo) = (0)) and (saveLog) then
   fprintf(logfile, "SDO=0\r\n");
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, "WRITE CODE\n");
  currPage := -(1);
  j := 0;
  if (page) = (0) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:1933
     Original C:
       for (i = 0, k = 0; i < dim; i += 2)
       {
         if ((memCODE[i] != 0xFF) || (memCODE[i + 1] != 0xFF))
         {
           bufferU[j++] = 0x48;
           bufferU[j++] = 6;
           bufferU[j++] = 0x4C;
           bufferU[j++] = 0x10;
           bufferU[j++] = 0x1C;
           bufferU[j++] = i >> 9;
           bufferU[j++] = 0x0C;
           bufferU[j++] = (i / 2) & 0xFF;
           bufferU[j++] = 0x2C;
           bufferU[j++] = memCODE[i];
           bufferU[j++] = 0x64;
           bufferU[j++] = 0x00;
           bufferU[j++] = 0x6C;
           bufferU[j++] = 0x00;
           bufferU[j++] = 0x46;
           bufferU[j++] = 0x04;
           for (; j < 64; j++)
             bufferU[j] = 0x0;
       
           PacketIO(2);
           j = 0;
           if (sa...
   *)
   // init: i = 0, k = 0
   while (i) < (dim) do
   begin
    if ((memCODE[i]) <> ($FF)) or ((memCODE[(i) + (1)]) <> ($FF)) then
    begin
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $10;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := (i) shr (9);
     bufferU[Inc(j)] := $0C;
     bufferU[Inc(j)] := ((i) div (2)) and ($FF);
     bufferU[Inc(j)] := $2C;
     bufferU[Inc(j)] := memCODE[i];
     bufferU[Inc(j)] := $64;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:1961
       Original C:
         for (t = 0, sdo = 0; (t < 20) && (sdo == 0); t++)
         {
           PacketIO(2);
           for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
             ;
         
           sdo = bufferI[z + 1] & 2;
         }
     *)
     // init: t = 0, sdo = 0
     while ((t) < (20)) and ((sdo) = (0)) do
     begin
      PacketIO(2);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/progAVR.c:1963
        Original C:
          for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
            ;
      *)
      // init: z = 0
      while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
      begin
        // step: z++
      end;
      sdo := (bufferI[(z) + (1)]) and (2);
       // step: t++
     end;
     if (saveLog) and ((sdo) = (0)) then
      fprintf(logfile, "SDO=0\r\n");
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $3C;
     bufferU[Inc(j)] := memCODE[(i) + (1)];
     bufferU[Inc(j)] := $74;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $7C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:1987
       Original C:
         for (t = 0, sdo = 0; (t < 20) && (sdo == 0); t++)
         {
           PacketIO(2);
           for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
             ;
         
           sdo = bufferI[z + 1] & 2;
         }
     *)
     // init: t = 0, sdo = 0
     while ((t) < (20)) and ((sdo) = (0)) do
     begin
      PacketIO(2);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/progAVR.c:1989
        Original C:
          for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
            ;
      *)
      // init: z = 0
      while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
      begin
        // step: z++
      end;
      sdo := (bufferI[(z) + (1)]) and (2);
       // step: t++
     end;
     if (saveLog) and ((sdo) = (0)) then
      fprintf(logfile, "SDO=0\r\n");
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 3;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $68;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $78;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $7C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     j := 0;
     k := i;
     for z := 0 to ((64) - (1)) - 1 do
     begin
      if (bufferI[z]) = ($48) then
      begin
       if (memCODE[k]) <> (bufferI[(z) + (1)]) then
       begin
        sprintf(str, strings[S_CodeVError], k, k, memCODE[k], bufferI[(z) + (1)]);
        PrintMessage(str);
        Inc(err);
       end;
       Inc(k);
       Inc(z);
      end;
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
     if (max_err) and ((err) > (max_err)) then
     begin
      sprintf(str, strings[S_MaxErr], err);
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim;
     end;
    end;
     // step: i += 2
   end;
  end
  else
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2036
     Original C:
       for (i = 0; i < dim; i += page * 2)
       {
         for (k = 0; k < page; k++)
         {
           if ((memCODE[i + (k * 2)] != 0xFF) || (memCODE[(i + (k * 2)) + 1] != 0xFF))
             k = page;
         }
       
         if (k > page)
         {
           bufferU[j++] = 0x48;
           bufferU[j++] = 1;
           bufferU[j++] = 0x4C;
           bufferU[j++] = 0x10;
           for (k = 0; k < page; k++)
           {
             bufferU[j++] = 0x48;
             bufferU[j++] = 5;
             bufferU[j++] = 0x0C;
             bufferU[j++] = ((i / 2) + k) & 0xFF;
             bufferU[j++] = 0x2C;
             bufferU[j++] = memCODE[i + (k * 2)];
             bufferU[j++] = 0x3C;
             bufferU[j++] = memCODE[(i + (k * 2)) + 1];
             b...
   *)
   // init: i = 0
   while (i) < (dim) do
   begin
    for k := 0 to (page) - 1 do
    begin
     if ((memCODE[(i) + ((k) * (2))]) <> ($FF)) or ((memCODE[((i) + ((k) * (2))) + (1)]) <> ($FF)) then
      k := page;
    end;
    if (k) > (page) then
    begin
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 1;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $10;
     for k := 0 to (page) - 1 do
     begin
      bufferU[Inc(j)] := $48;
      bufferU[Inc(j)] := 5;
      bufferU[Inc(j)] := $0C;
      bufferU[Inc(j)] := (((i) div (2)) + (k)) and ($FF);
      bufferU[Inc(j)] := $2C;
      bufferU[Inc(j)] := memCODE[(i) + ((k) * (2))];
      bufferU[Inc(j)] := $3C;
      bufferU[Inc(j)] := memCODE[((i) + ((k) * (2))) + (1)];
      bufferU[Inc(j)] := $7D;
      bufferU[Inc(j)] := $00;
      bufferU[Inc(j)] := $7C;
      bufferU[Inc(j)] := $00;
      if (((j) > ((64) - (13))) or ((k) >= (page))) or ((i) >= ((dim) - (2))) then
      begin
       bufferU[Inc(j)] := $04;
       while (j) < (64) do
       begin
        bufferU[j] := $0;
        Inc(j);
       end;
       PacketIO(2);
       j := 0;
       if saveLog then
       begin
        fprintf(logfile, strings[S_Log7], i, i, k, k);
       end;
      end;
     end;
     if ((i) shr (9)) <> (currPage) then
     begin
      bufferU[Inc(j)] := $48;
      bufferU[Inc(j)] := 1;
      bufferU[Inc(j)] := $1C;
      bufferU[Inc(j)] := (i) shr (9);
      currPage := (i) shr (9);
     end;
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $64;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:2092
       Original C:
         for (t = 0, sdo = 0; (t < 20) && (sdo == 0); t++)
         {
           PacketIO(2);
           for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
             ;
         
           sdo = bufferI[z + 1] & 2;
         }
     *)
     // init: t = 0, sdo = 0
     while ((t) < (20)) and ((sdo) = (0)) do
     begin
      PacketIO(2);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/progAVR.c:2094
        Original C:
          for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
            ;
      *)
      // init: z = 0
      while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
      begin
        // step: z++
      end;
      sdo := (bufferI[(z) + (1)]) and (2);
       // step: t++
     end;
     if ((sdo) = (0)) and (saveLog) then
      fprintf(logfile, "SDO=0\r\n");
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     j := 0;
     m := 0;
     for k := 0 to (page) - 1 do
     begin
      if (k) = (0) then
      begin
       bufferU[Inc(j)] := $48;
       bufferU[Inc(j)] := 4;
       bufferU[Inc(j)] := $4C;
       bufferU[Inc(j)] := $02;
      end
      else
      begin
       bufferU[Inc(j)] := $48;
       bufferU[Inc(j)] := 3;
      end;
      bufferU[Inc(j)] := $0C;
      bufferU[Inc(j)] := (((i) div (2)) + (k)) and ($FF);
      bufferU[Inc(j)] := $68;
      bufferU[Inc(j)] := $00;
      bufferU[Inc(j)] := $6C;
      bufferU[Inc(j)] := $00;
      bufferU[Inc(j)] := $48;
      bufferU[Inc(j)] := 2;
      bufferU[Inc(j)] := $78;
      bufferU[Inc(j)] := $00;
      bufferU[Inc(j)] := $7C;
      bufferU[Inc(j)] := $00;
      if (((j) > ((64) - (14))) or ((k) >= (page))) or ((i) >= ((dim) - (2))) then
      begin
       bufferU[Inc(j)] := $04;
       while (j) < (64) do
       begin
        bufferU[j] := $0;
        Inc(j);
       end;
       PacketIO(2);
       j := 0;
       for z := 0 to ((64) - (1)) - 1 do
       begin
        if (bufferI[z]) = ($48) then
        begin
         if (memCODE[(i) + (m)]) <> (bufferI[(z) + (1)]) then
         begin
          sprintf(str, strings[S_CodeVError], (i) + (m), (i) + (m), memCODE[(i) + (m)], bufferI[(z) + (1)]);
          PrintMessage(str);
          Inc(err);
         end;
         Inc(m);
         Inc(z);
        end;
       end;
       if saveLog then
       begin
        fprintf(logfile, strings[S_Log8], i, i, m, m, err);
       end;
       if (max_err) and ((err) > (max_err)) then
       begin
        sprintf(str, strings[S_MaxErr], err);
        PrintMessage(str);
        PrintMessage(strings[S_IntW]);
        i := dim;
       end;
      end;
     end;
    end;
     // step: i += page * 2
   end;
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   errEE := 0;
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, "WRITE EEPROM\n");
   j := 0;
   for i := 0 to (dim2) - 1 do
   begin
    if (memEE[i]) <> ($FF) then
    begin
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 7;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $11;
     bufferU[Inc(j)] := $0C;
     bufferU[Inc(j)] := (i) and ($FF);
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := $2C;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := $6D;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $64;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     PacketIO(2);
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := $46;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     j := 0;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:2193
       Original C:
         for (t = 0, sdo = 0; (t < 20) && (sdo == 0); t++)
         {
           PacketIO(2);
           for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
             ;
         
           sdo = bufferI[z + 1] & 2;
         }
     *)
     // init: t = 0, sdo = 0
     while ((t) < (20)) and ((sdo) = (0)) do
     begin
      PacketIO(2);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/progAVR.c:2195
        Original C:
          for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
            ;
      *)
      // init: z = 0
      while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
      begin
        // step: z++
      end;
      sdo := (bufferI[(z) + (1)]) and (2);
       // step: t++
     end;
     if ((sdo) = (0)) and (saveLog) then
      fprintf(logfile, "SDO=0\r\n");
     bufferU[Inc(j)] := $48;
     bufferU[Inc(j)] := 5;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $03;
     bufferU[Inc(j)] := $1C;
     bufferU[Inc(j)] := (i) shr (8);
     bufferU[Inc(j)] := $0C;
     bufferU[Inc(j)] := (i) and ($FF);
     bufferU[Inc(j)] := $68;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $6C;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progAVR.c:2215
       Original C:
         for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
           ;
     *)
     // init: z = 0
     while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
     begin
       // step: z++
     end;
     if (memEE[i]) <> (bufferI[(z) + (1)]) then
     begin
      sprintf(str, strings[S_CodeVError], i, i, memEE[i], bufferI[(z) + (1)]);
      PrintMessage(str);
      Inc(errEE);
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
     if ((err) + (errEE)) >= (max_err) then
      Break;
    end;
   end;
   err := err + errEE;
   if (err) >= (max_err) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_MaxErr], err);
    PrintMessage(str);
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
  end;
  err_f := 0;
  if ((((AVRlock) < ($100)) or ((AVRfuse) < ($100))) or ((AVRfuse_h) < ($100))) or ((AVRfuse_x) < ($100)) then
   PrintMessage(strings[S_FuseAreaW]);
  if (AVRfuse) < ($100) then
  begin
   if saveLog then
    fprintf(logfile, "WRITE FUSE\n");
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $40;
   bufferU[Inc(j)] := $2C;
   bufferU[Inc(j)] := AVRfuse;
   bufferU[Inc(j)] := $64;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2255
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
   begin
     // step: z++
   end;
   sdo := (bufferI[(z) + (1)]) and (2);
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2260
     Original C:
       for (i = 0; (i < 20) && (sdo == 0); i++)
       {
         PacketIO(2);
         for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
           ;
       
         sdo = bufferI[z + 1] & 2;
       }
   *)
   // init: i = 0
   while ((i) < (20)) and ((sdo) = (0)) do
   begin
    PacketIO(2);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:2262
      Original C:
        for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
          ;
    *)
    // init: z = 0
    while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
    begin
      // step: z++
    end;
    sdo := (bufferI[(z) + (1)]) and (2);
     // step: i++
   end;
   if ((sdo) = (0)) and (saveLog) then
    fprintf(logfile, "SDO=0\r\n");
   j := 0;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $68;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2279
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (1))) or ((AVRfuse) <> (bufferI[(z) + (1)])) then
   begin
    sprintf(str, strings[S_WErr1], "fuse", AVRfuse, bufferI[(z) + (1)]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  if (AVRfuse_h) < ($100) then
  begin
   if saveLog then
    fprintf(logfile, "WRITE FUSEH\n");
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $40;
   bufferU[Inc(j)] := $2C;
   bufferU[Inc(j)] := AVRfuse_h;
   bufferU[Inc(j)] := $74;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2302
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
   begin
     // step: z++
   end;
   sdo := (bufferI[(z) + (1)]) and (2);
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2307
     Original C:
       for (i = 0; (i < 20) && (sdo == 0); i++)
       {
         PacketIO(2);
         for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
           ;
       
         sdo = bufferI[z + 1] & 2;
       }
   *)
   // init: i = 0
   while ((i) < (20)) and ((sdo) = (0)) do
   begin
    PacketIO(2);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:2309
      Original C:
        for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
          ;
    *)
    // init: z = 0
    while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
    begin
      // step: z++
    end;
    sdo := (bufferI[(z) + (1)]) and (2);
     // step: i++
   end;
   if ((sdo) = (0)) and (saveLog) then
    fprintf(logfile, "SDO=0\r\n");
   j := 0;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $7A;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7E;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2326
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (1))) or ((AVRfuse_h) <> (bufferI[(z) + (1)])) then
   begin
    sprintf(str, strings[S_WErr1], "fuseH", AVRfuse_h, bufferI[(z) + (1)]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  if (AVRfuse_x) < ($100) then
  begin
   if saveLog then
    fprintf(logfile, "WRITE FUSEX\n");
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $40;
   bufferU[Inc(j)] := $2C;
   bufferU[Inc(j)] := AVRfuse_x;
   bufferU[Inc(j)] := $66;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2349
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
   begin
     // step: z++
   end;
   sdo := (bufferI[(z) + (1)]) and (2);
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2354
     Original C:
       for (i = 0; (i < 20) && (sdo == 0); i++)
       {
         PacketIO(2);
         for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
           ;
       
         sdo = bufferI[z + 1] & 2;
       }
   *)
   // init: i = 0
   while ((i) < (20)) and ((sdo) = (0)) do
   begin
    PacketIO(2);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:2356
      Original C:
        for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
          ;
    *)
    // init: z = 0
    while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
    begin
      // step: z++
    end;
    sdo := (bufferI[(z) + (1)]) and (2);
     // step: i++
   end;
   if ((sdo) = (0)) and (saveLog) then
    fprintf(logfile, "SDO=0\r\n");
   j := 0;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2373
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (1))) or ((AVRfuse_x) <> (bufferI[(z) + (1)])) then
   begin
    sprintf(str, strings[S_WErr1], "fuseX", AVRfuse_x, bufferI[(z) + (1)]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  if (AVRlock) < ($100) then
  begin
   if saveLog then
    fprintf(logfile, "WRITE LOCK\n");
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $2C;
   bufferU[Inc(j)] := AVRlock;
   bufferU[Inc(j)] := $64;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $6C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2396
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
   begin
     // step: z++
   end;
   sdo := (bufferI[(z) + (1)]) and (2);
   bufferU[Inc(j)] := $46;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2401
     Original C:
       for (i = 0; (i < 20) && (sdo == 0); i++)
       {
         PacketIO(2);
         for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
           ;
       
         sdo = bufferI[z + 1] & 2;
       }
   *)
   // init: i = 0
   while ((i) < (20)) and ((sdo) = (0)) do
   begin
    PacketIO(2);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progAVR.c:2403
      Original C:
        for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x46); z++)
          ;
    *)
    // init: z = 0
    while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($46)) do
    begin
      // step: z++
    end;
    sdo := (bufferI[(z) + (1)]) and (2);
     // step: i++
   end;
   if ((sdo) = (0)) and (saveLog) then
    fprintf(logfile, "SDO=0\r\n");
   j := 0;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := 3;
   bufferU[Inc(j)] := $4C;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progAVR.c:2420
     Original C:
       for (z = 0; (z < (64 - 1)) && (bufferI[z] != 0x48); z++)
         ;
   *)
   // init: z = 0
   while ((z) < ((64) - (1))) and ((bufferI[z]) <> ($48)) do
   begin
     // step: z++
   end;
   if ((z) = ((64) - (1))) or ((AVRlock) <> (bufferI[(z) + (1)])) then
   begin
    sprintf(str, strings[S_WErr1], "lock", AVRlock, bufferI[(z) + (1)]);
    PrintMessage(str);
    Inc(err_f);
   end;
  end;
  err := err + err_f;
  if ((((AVRlock) < ($100)) or ((AVRfuse) < ($100))) or ((AVRfuse_h) < ($100))) or ((AVRfuse_x) < ($100)) then
  begin
   sprintf(str, strings[S_ComplErr], err_f);
   PrintMessage(str);
  end;
  bufferU[Inc(j)] := $32;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := 0;
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
  gtk_statusbar_push(status_bar, statusID, "");
end;

end.
