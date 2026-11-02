unit progp24;

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

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  PIC24LIST: array of TID24;

// --- function declarations ---
function CheckData(a: Integer; b: Integer; addr: Integer; err: ^Integer): Pointer;
function PIC24_ID(id: Integer): Pointer;
function DisplayCODE24F(dim: Integer): Pointer;
procedure DisplayEE24F;
function Read24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
function Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
function Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
function Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;

implementation

function CheckData(a: Integer; b: Integer; addr: Integer; err: ^Integer): Pointer;
var
  // (no local variables detected)
begin
  if (a) <> (b) then
  begin
   PrintMessage(strings[S_NL]);
   sprintf(str, strings[S_CodeVError], addr, addr, a, b);
   PrintMessage(str);
   Inc(err^);
  end;
end;

function PIC24_ID(id: Integer): Pointer;
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (sizeof(PIC24LIST)/sizeof(PIC24LIST[0])) - 1 do
  begin
   if id = PIC24LIST[i].id then
   begin
    strcpy(s, PIC24LIST[i].device);
    strcat(s, '\r' + LineEnding + '');
    PrintMessage(s);
    Exit;
   end;
  end;
end;

function DisplayCODE24F(dim: Integer): Pointer;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  d: Integer;
  lines: Integer;
begin
  s := "";
  t := "";
  aux := malloc(((((dim) div (16)) + (1)) * (2)) * ((16) + ((16) * (9))));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:370
    Original C:
      for (i = 0; (i < dim) && (i < size); i += 16 * 2)
      {
        valid = 0;
        for (j = i; (j < (i + (16 * 2))) && (j < dim); j += 4)
        {
          d = (((memCODE[j + 3] << 24) + (memCODE[j + 2] << 16)) + (memCODE[j + 1] << 8)) + memCODE[j];
          sprintf(t, "%08X ", d);
          strcat(s, t);
          if (d != 0xffffffff)
            valid = 1;
        }
      
        if (valid)
        {
          sprintf(t, "%06X: %s\r\n", i / 2, s);
          empty = 0;
          strcat(aux, t);
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
     Source: /tmp/opgui-0.12.4/progP24.c:372
     Original C:
       for (j = i; (j < (i + (16 * 2))) && (j < dim); j += 4)
       {
         d = (((memCODE[j + 3] << 24) + (memCODE[j + 2] << 16)) + (memCODE[j + 1] << 8)) + memCODE[j];
         sprintf(t, "%08X ", d);
         strcat(s, t);
         if (d != 0xffffffff)
           valid = 1;
       }
   *)
   // init: j = i
   while ((j) < ((i) + ((16) * (2)))) and ((j) < (dim)) do
   begin
    d := ((((memCODE[(j) + (3)]) shl (24)) + ((memCODE[(j) + (2)]) shl (16))) + ((memCODE[(j) + (1)]) shl (8))) + (memCODE[j]);
    sprintf(t, "%08X ", d);
    strcat(s, t);
    if (d) <> ($ffffffff) then
     valid := 1;
     // step: j += 4
   end;
   if valid then
   begin
    sprintf(t, "%06X: %s\r\n", (i) div (2), s);
    empty := 0;
    strcat(aux, t);
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

procedure DisplayEE24F;
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  v: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  g: PChar;
begin
  valid := 0;
  empty := 1;
  s[0] := 0;
  v[0] := 0;
  aux := malloc((($1000) div (16)) * ((16) + ((16) * (5))));
  aux[0] := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:408
    Original C:
      for (i = 0; (i < 0x1000) && (i < sizeEE); i += 16)
      {
        valid = 0;
        for (j = i; ((j < (i + 16)) && (j < 0x1000)) && (i < sizeEE); j += 2)
        {
          sprintf(t, "%02X %02X ", memEE[j], memEE[j + 1]);
          strcat(s, t);
          sprintf(t, "%c", (isprint(memEE[j]) && (memEE[j] < 0xFF)) ? (memEE[j]) : ('.'));
          g = g_locale_to_utf8(t, -1, NULL, NULL, NULL);
          if (g)
            strcat(v, g);
          g_free(g);
          if (memEE[j] < 0xff)
            valid = 1;
          sprintf(t, "%c", (isprint(memEE[j + 1]) && (memEE[j + 1] < 0xFF)) ? (memEE[j + 1]) : ('.'));
          g = g_locale_to_utf8(t, -1, NULL, NULL, NULL);
          if (g)
         ...
  *)
  // init: i = 0
  while ((i) < ($1000)) and ((i) < (sizeEE)) do
  begin
   valid := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:410
     Original C:
       for (j = i; ((j < (i + 16)) && (j < 0x1000)) && (i < sizeEE); j += 2)
       {
         sprintf(t, "%02X %02X ", memEE[j], memEE[j + 1]);
         strcat(s, t);
         sprintf(t, "%c", (isprint(memEE[j]) && (memEE[j] < 0xFF)) ? (memEE[j]) : ('.'));
         g = g_locale_to_utf8(t, -1, NULL, NULL, NULL);
         if (g)
           strcat(v, g);
         g_free(g);
         if (memEE[j] < 0xff)
           valid = 1;
         sprintf(t, "%c", (isprint(memEE[j + 1]) && (memEE[j + 1] < 0xFF)) ? (memEE[j + 1]) : ('.'));
         g = g_locale_to_utf8(t, -1, NULL, NULL, NULL);
         if (g)
           strcat(v, g);
         g_free(g);
         if (memEE[j + 1] < 0xff)
           valid = 1;
       }
   *)
   // init: j = i
   while (((j) < ((i) + (16))) and ((j) < ($1000))) and ((i) < (sizeEE)) do
   begin
    sprintf(t, "%02X %02X ", memEE[j], memEE[(j) + (1)]);
    strcat(s, t);
    sprintf(t, "%c", IfThen((isprint(memEE[j])) and ((memEE[j]) < ($FF)), memEE[j], #46));
    g := g_locale_to_utf8(t, -(1), NULL, NULL, NULL);
    if g then
     strcat(v, g);
    g_free(g);
    if (memEE[j]) < ($ff) then
     valid := 1;
    sprintf(t, "%c", IfThen((isprint(memEE[(j) + (1)])) and ((memEE[(j) + (1)]) < ($FF)), memEE[(j) + (1)], #46));
    g := g_locale_to_utf8(t, -(1), NULL, NULL, NULL);
    if g then
     strcat(v, g);
    g_free(g);
    if (memEE[(j) + (1)]) < ($ff) then
     valid := 1;
     // step: j += 2
   end;
   if valid then
   begin
    sprintf(t, "%04X: %s %s\r\n", (i) + ($F000), s, v);
    strcat(aux, t);
    empty := 0;
   end;
   s[0] := 0;
   v[0] := 0;
    // step: i += 16
  end;
  if empty then
   PrintMessage(strings[S_Empty]);
  else
   PrintMessage(aux);
  free(aux);
end;

function Read24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  entry: Integer;
  config: Integer;
  EEbaseAddr: Integer;
  newTABLPAG: Integer;
  memExec: PByte;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  High: Integer;
  stop: Cardinal;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  d: Integer;
  valid: Integer;
  empty: Integer;
  aux: PChar;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := (options) and ($F);
  config := ((options) shr (4)) and ($F);
  EEbaseAddr := ($1000) - (dim2);
  newTABLPAG := IfThen((options) and ($100), 1, 0);
  if (FWVersion) < ($700) then
  begin
   sprintf(str, strings[S_FWver2old], "0.7.0");
   PrintMessage(str);
   Exit;
  end;
  if ((entry) < (2)) and (not (CheckV33Regulator())) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Read24Fx(%d,%d,%d,%d,%d)    (0x%X,0x%X,0x%X,0x%X,0x%X)\n", dim, dim2, options, appIDaddr, executiveArea, dim, dim2, options, appIDaddr, executiveArea);
  end;
  dim := dim * 2;
  if ((dim) > ($80000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($4000)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  memExec := 0;
  executiveArea := executiveArea * 2;
  if executiveArea then
   memExec := malloc(executiveArea);
  for i := 0 to (executiveArea) - 1 do
  begin
   memExec[i] := $FF;
  end;
  size := dim;
  sizeEE := $1000;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  if memEE then
   free(memEE);
  memEE := malloc($1000);
  memset(memCODE, $FF, dim);
  memset(memEE, $FF, $1000);
  if (config) > (2) then
  begin
   sizeCONFIG := 48;
   for i := 0 to (48) - 1 do
   begin
    memCONFIG[i] := $FF;
   end;
  end;
  if ((entry) = (1)) or ((entry) = (2)) then
  begin
   if not (StartHVReg(IfThen((entry) = (2), 12, 6))) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-(1));
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (10000) shr (8);
  bufferU[Inc(j)] := (10000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  if ((entry) = (0)) or ((entry) = (3)) then
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
  end
  else
   PrintMessage(strings[S_HVICSP]);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (30000) shr (8);
  bufferU[Inc(j)] := (30000) and ($ff);
  bufferU[Inc(j)] := $0A;
  if (entry) = (2) then
  begin
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $38;
  end
  else
  begin
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(55);
  j := 0;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:642
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:644
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "DevID: 0x%04X\r\nDevRev: 0x%04X\r\n", w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $44;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := ($20) + (((appIDaddr) shr (12)) and ($F));
  bufferU[Inc(j)] := ((appIDaddr) shr (4)) and ($FF);
  bufferU[Inc(j)] := (((appIDaddr) shl (4)) and ($F0)) + (6);
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:703
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "ApplicationID @ 0x80%04X:  0x%04X\r\n", appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_CodeReading1]);
  High := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:712
    Original C:
      for (i = 0; i < dim; i += 24)
      {
        if ((i >> 17) != High)
        {
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x20;
          bufferU[j++] = (i >> 21) & 0xFF;
          bufferU[j++] = (i >> 13) & 0xF0;
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x88;
          if (newTABLPAG)
          {
            bufferU[j++] = 0x02;
            bufferU[j++] = 0xA0;
          }
          else
          {
            bufferU[j++] = 0x01;
            bufferU[j++] = 0x90;
          }
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x04;
          bufferU[j++] = 0x02;
          bufferU[j++] = 0x00;
          bufferU[j++] = 0x38;
          bufferU[j++] = 0x04;
          for (; j < 64; j++)
            bufferU[j] = 0x0;
      
          P...
  *)
  // init: i = 0
  while (i) < (dim) do
  begin
   if ((i) shr (17)) <> (High) then
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := ((i) shr (21)) and ($FF);
    bufferU[Inc(j)] := ((i) shr (13)) and ($F0);
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    if newTABLPAG then
    begin
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $A0;
    end
    else
    begin
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $90;
    end;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
    High := (i) shr (17);
   end;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   if (i) < ((dim) - (16)) then
   begin
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
   end;
   if (i) < ((dim) - (8)) then
   begin
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:808
     Original C:
       for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (1)] := bufferI[(z) + (1)];
    memCODE[k] := bufferI[(z) + (2)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:813
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (2)] := bufferI[(z) + (2)];
    memCODE[(k) + (6)] := bufferI[(z) + (1)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:818
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (5)] := bufferI[(z) + (1)];
    memCODE[(k) + (4)] := bufferI[(z) + (2)];
    k := k + 8;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:824
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (1)] := bufferI[(z) + (1)];
    memCODE[(k) + (0)] := bufferI[(z) + (2)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:829
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (2)] := bufferI[(z) + (2)];
    memCODE[(k) + (6)] := bufferI[(z) + (1)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:834
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (5)] := bufferI[(z) + (1)];
    memCODE[(k) + (4)] := bufferI[(z) + (2)];
    k := k + 8;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:840
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (1)] := bufferI[(z) + (1)];
    memCODE[(k) + (0)] := bufferI[(z) + (2)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:845
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (2)] := bufferI[(z) + (2)];
    memCODE[(k) + (6)] := bufferI[(z) + (1)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:850
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (5)] := bufferI[(z) + (1)];
    memCODE[(k) + (4)] := bufferI[(z) + (2)];
    k := k + 8;
   end;
   sprintf(str, strings[S_CodeReading2], ((i) * (100)) div (dim), (i) div (2));
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
    // step: i += 24
  end;
  if (k) <> (dim) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if (config) > (2) then
  begin
   if saveLog then
    fprintf(logfile, "\nCONFIG:\n");
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $88;
   if newTABLPAG then
   begin
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
   end
   else
   begin
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $90;
   end;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
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
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   while (i) < (9) do
   begin
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
     Inc(z);
    end;
    memCONFIG[(i) * (4)] := bufferI[(z) + (2)];
    memCONFIG[((i) * (4)) + (1)] := bufferI[(z) + (1)];
    z := z + 3;
    Inc(i);
   end;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
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
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   while (i) < (12) do
   begin
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
     Inc(z);
    end;
    memCONFIG[(i) * (4)] := bufferI[(z) + (2)];
    memCONFIG[((i) * (4)) + (1)] := bufferI[(z) + (1)];
    z := z + 3;
    Inc(i);
   end;
   gtk_statusbar_push(status_bar, statusID, "");
  end;
  if dim2 then
  begin
   if saveLog then
    fprintf(logfile, "\nEEPROM:\n");
   PrintMessage(strings[S_ReadEE]);
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $45;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $F0;
   bufferU[Inc(j)] := $88;
   if newTABLPAG then
   begin
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
   end
   else
   begin
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $90;
   end;
   bufferU[Inc(j)] := $2F;
   bufferU[Inc(j)] := ((EEbaseAddr) shr (4)) and ($FF);
   bufferU[Inc(j)] := ((EEbaseAddr) and ($F0)) + (6);
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1010
     Original C:
       for (k2 = 0, i = 0; i < dim2; i += 2)
       {
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0xB6;
         bufferU[j++] = 0x37;
         if ((j > (64 - 6)) || (i == (dim2 - 2)))
         {
           bufferU[j++] = 0x04;
           for (; j < 64; j++)
             bufferU[j] = 0x0;
       
           PacketIO(3);
           j = 0;
           for (z = 0; z < (64 - 2); z++)
           {
             if (bufferI[z] == 0x37)
             {
               memEE[EEbaseAddr + (k2++)] = bufferI[z + 2];
               memEE[EEbaseAddr + (k2++)] = bufferI[z + 1];
               z += 3;
             }
           }
       
           {
             sprintf(str, strings[S_CodeReading], ((i + dim) * 100) / (dim + dim2...
   *)
   // init: k2 = 0, i = 0
   while (i) < (dim2) do
   begin
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    if ((j) > ((64) - (6))) or ((i) = ((dim2) - (2))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     j := 0;
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($37) then
      begin
       memEE[(EEbaseAddr) + (Inc(k2))] := bufferI[(z) + (2)];
       memEE[(EEbaseAddr) + (Inc(k2))] := bufferI[(z) + (1)];
       z := z + 3;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (((i) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
     // step: i += 2
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
  if executiveArea then
  begin
   j := 0;
   PrintMessage(strings[S_Read_EXE_A]);
   if saveLog then
    fprintf(logfile, "\nExecutive area:\n");
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $45;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $88;
   if newTABLPAG then
   begin
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
   end
   else
   begin
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $90;
   end;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
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
     Source: /tmp/opgui-0.12.4/progP24.c:1075
     Original C:
       for (i = 0, k = 0; i < executiveArea; i += 16)
       {
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0x96;
         bufferU[j++] = 0x37;
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0xDB;
         bufferU[j++] = 0xB6;
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0xD3;
         bufferU[j++] = 0xD6;
         bufferU[j++] = 0x37;
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0xB6;
         bufferU[j++] = 0x37;
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0x96;
         bufferU[j++] = 0x37;...
   *)
   // init: i = 0, k = 0
   while (i) < (executiveArea) do
   begin
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(3);
    j := 0;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1122
      Original C:
        for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z = 0
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (1)] := bufferI[(z) + (1)];
     memExec[k] := bufferI[(z) + (2)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1127
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (2)] := bufferI[(z) + (2)];
     memExec[(k) + (6)] := bufferI[(z) + (1)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1132
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (5)] := bufferI[(z) + (1)];
     memExec[(k) + (4)] := bufferI[(z) + (2)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1137
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (9)] := bufferI[(z) + (1)];
     memExec[(k) + (8)] := bufferI[(z) + (2)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1142
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (10)] := bufferI[(z) + (2)];
     memExec[(k) + (14)] := bufferI[(z) + (1)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1147
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (13)] := bufferI[(z) + (1)];
     memExec[(k) + (12)] := bufferI[(z) + (2)];
    end;
    k := k + 16;
    sprintf(str, strings[S_CodeReading2], ((i) * (100)) div (executiveArea), ($800000) + ((i) div (2)));
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
     // step: i += 16
   end;
   if (k) <> (executiveArea) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ReadCodeErr2], executiveArea, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  PrintMessage("\r\n");
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
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
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, "");
  if (config) > (2) then
  begin
   PrintMessage(strings[S_ConfigMem]);
   if (((config) = (3)) or ((config) = (4))) or ((config) = (6)) then
   begin
    sprintf(str, "0xF80000: FBS = 0x%02X\r\n", memCONFIG[0]);
    PrintMessage(str);
    if (config) = (4) then
    begin
     sprintf(str, "0xF80002: FSS = 0x%02X\r\n", memCONFIG[4]);
     PrintMessage(str);
    end;
    sprintf(str, "0xF80004: FGS = 0x%02X\r\n", memCONFIG[8]);
    PrintMessage(str);
    sprintf(str, "0xF80006: FOSCSEL = 0x%02X\r\n", memCONFIG[12]);
    PrintMessage(str);
    sprintf(str, "0xF80008: FOSC = 0x%02X\r\n", memCONFIG[16]);
    PrintMessage(str);
    sprintf(str, "0xF8000A: FWDT = 0x%02X\r\n", memCONFIG[20]);
    PrintMessage(str);
    sprintf(str, "0xF8000C: FPOR = 0x%02X\r\n", memCONFIG[24]);
    PrintMessage(str);
    sprintf(str, "0xF8000E: FICD = 0x%02X\r\n", memCONFIG[28]);
    PrintMessage(str);
    if (config) = (3) then
    begin
     sprintf(str, "0xF80010: FDS = 0x%02X\r\n", memCONFIG[32]);
     PrintMessage(str);
    end
    else
     if (config) = (4) then
     begin
      sprintf(str, "0xF80010: UID0 = 0x%02X\r\n", memCONFIG[32]);
      PrintMessage(str);
      sprintf(str, "0xF80012: UID1 = 0x%02X\r\n", memCONFIG[36]);
      PrintMessage(str);
      sprintf(str, "0xF80014: UID2 = 0x%02X\r\n", memCONFIG[40]);
      PrintMessage(str);
      sprintf(str, "0xF80016: UID3 = 0x%02X\r\n", memCONFIG[44]);
      PrintMessage(str);
     end;
   end
   else
    if (config) = (5) then
    begin
     sprintf(str, "0xF80000: FOSC = 0x%02X%02X\r\n", memCONFIG[1], memCONFIG[0]);
     PrintMessage(str);
     sprintf(str, "0xF80002: FWDT = 0x%02X%02X\r\n", memCONFIG[5], memCONFIG[4]);
     PrintMessage(str);
     sprintf(str, "0xF80004: FBORPOR = 0x%02X%02X\r\n", memCONFIG[9], memCONFIG[8]);
     PrintMessage(str);
     sprintf(str, "0xF80006: FBS = 0x%02X%02X\r\n", memCONFIG[13], memCONFIG[12]);
     PrintMessage(str);
     sprintf(str, "0xF80008: FSS = 0x%02X%02X\r\n", memCONFIG[17], memCONFIG[16]);
     PrintMessage(str);
     sprintf(str, "0xF8000A: FGS = 0x%02X%02X\r\n", memCONFIG[21], memCONFIG[20]);
     PrintMessage(str);
     sprintf(str, "0xF8000C: FICD = 0x%02X%02X\r\n", memCONFIG[25], memCONFIG[24]);
     PrintMessage(str);
    end;
  end
  else
  begin
   sprintf(str, "CONFIG1: 0x%04X\r\nCONFIG2: 0x%04X\r\n", ((memCODE[(dim) - (3)]) shl (8)) + (memCODE[(dim) - (4)]), ((memCODE[(dim) - (7)]) shl (8)) + (memCODE[(dim) - (8)]));
   PrintMessage(str);
   if (config) = (1) then
   begin
    sprintf(str, "CONFIG3: 0x%04X\r\n", ((memCODE[(dim) - (11)]) shl (8)) + (memCODE[(dim) - (12)]));
    PrintMessage(str);
   end;
   if (config) = (2) then
   begin
    sprintf(str, "CONFIG4: 0x%04X\r\n", ((memCODE[(dim) - (15)]) shl (8)) + (memCODE[(dim) - (16)]));
    PrintMessage(str);
   end;
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE24F(dim);
  if dim2 then
  begin
   PrintMessage(strings[S_EEMem]);
   DisplayEE24F();
  end;
  if executiveArea then
  begin
   empty := 1;
   aux := malloc(((((dim) div (16)) + (1)) * (2)) * ((16) + ((16) * (9))));
   aux[0] := 0;
   s[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ExeMem]);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1239
     Original C:
       for (i = 0; i < executiveArea; i += 16 * 2)
       {
         valid = 0;
         for (j = i; (j < (i + (16 * 2))) && (j < executiveArea); j += 4)
         {
           d = (((memExec[j + 3] << 24) + (memExec[j + 2] << 16)) + (memExec[j + 1] << 8)) + memExec[j];
           sprintf(t, "%08X ", d);
           strcat(s, t);
           if (d != 0xffffffff)
             valid = 1;
         }
       
         if (valid)
         {
           sprintf(t, "%06X: %s\r\n", i / 2, s);
           empty = 0;
           strcat(aux, t);
         }
         s[0] = 0;
       }
   *)
   // init: i = 0
   while (i) < (executiveArea) do
   begin
    valid := 0;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1241
      Original C:
        for (j = i; (j < (i + (16 * 2))) && (j < executiveArea); j += 4)
        {
          d = (((memExec[j + 3] << 24) + (memExec[j + 2] << 16)) + (memExec[j + 1] << 8)) + memExec[j];
          sprintf(t, "%08X ", d);
          strcat(s, t);
          if (d != 0xffffffff)
            valid = 1;
        }
    *)
    // init: j = i
    while ((j) < ((i) + ((16) * (2)))) and ((j) < (executiveArea)) do
    begin
     d := ((((memExec[(j) + (3)]) shl (24)) + ((memExec[(j) + (2)]) shl (16))) + ((memExec[(j) + (1)]) shl (8))) + (memExec[j]);
     sprintf(t, "%08X ", d);
     strcat(s, t);
     if (d) <> ($ffffffff) then
      valid := 1;
      // step: j += 4
    end;
    if valid then
    begin
     sprintf(t, "%06X: %s\r\n", (i) div (2), s);
     empty := 0;
     strcat(aux, t);
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
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Read24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; executiveArea: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  UID: array[0..16-1] of Byte;
  memExec: PByte;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  High: Integer;
  stop: Cardinal;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  d: Integer;
  valid: Integer;
  empty: Integer;
  aux: PChar;
begin
  k := 0;
  z := 0;
  for i := 0 to (16) - 1 do
  begin
   UID[i] := $FF;
  end;
  if (FWVersion) < ($900) then
  begin
   sprintf(str, strings[S_FWver2old], "0.9.0");
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
   fprintf(logfile, "Read24Ex(%d,%d,%d,%d,%d)    (0x%X,0x%X,0x%X,0x%X,0x%X)\n", dim, dim2, options, appIDaddr, executiveArea, dim, dim2, options, appIDaddr, executiveArea);
  end;
  dim := dim * 2;
  if ((dim) > ($100000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  memExec := 0;
  executiveArea := executiveArea * 2;
  if executiveArea then
   memExec := malloc(executiveArea);
  for i := 0 to (executiveArea) - 1 do
  begin
   memExec[i] := $FF;
  end;
  size := dim;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  memset(memCODE, $FF, dim);
  StartHVReg(-(1));
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (55000) shr (8);
  bufferU[Inc(j)] := (55000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(65);
  j := 0;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1407
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1409
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "DevID: 0x%04X\r\nDevRev: 0x%04X\r\n", w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := ($20) + (((appIDaddr) shr (12)) and ($F));
  bufferU[Inc(j)] := ((appIDaddr) shr (4)) and ($FF);
  bufferU[Inc(j)] := (((appIDaddr) shl (4)) and ($F0)) + (6);
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1457
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "ApplicationID @ 0x80%04X:  0x%04X\r\n", appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_CodeReading1]);
  High := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1466
    Original C:
      for (i = 0; i < dim; i += 24)
      {
        if ((i >> 17) != High)
        {
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x20;
          bufferU[j++] = (i >> 21) & 0xFF;
          bufferU[j++] = (i >> 13) & 0xF0;
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x88;
          bufferU[j++] = 0x02;
          bufferU[j++] = 0xA0;
          bufferU[j++] = 0x3E;
          bufferU[j++] = 0x04;
          bufferU[j++] = 0x02;
          bufferU[j++] = 0x00;
          bufferU[j++] = 0x38;
          bufferU[j++] = 0x38;
          bufferU[j++] = 0x04;
          for (; j < 64; j++)
            bufferU[j] = 0x0;
      
          PacketIO(2);
          j = 0;
          High = i >> 17;
        }
        bufferU[j++] = 0x49;
        bufferU[j++] =...
  *)
  // init: i = 0
  while (i) < (dim) do
  begin
   if ((i) shr (17)) <> (High) then
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := ((i) shr (21)) and ($FF);
    bufferU[Inc(j)] := ((i) shr (13)) and ($F0);
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
    High := (i) shr (17);
   end;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   if (i) < ((dim) - (16)) then
   begin
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
   end;
   if (i) < ((dim) - (8)) then
   begin
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(4);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1556
     Original C:
       for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (1)] := bufferI[(z) + (1)];
    memCODE[k] := bufferI[(z) + (2)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1561
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (2)] := bufferI[(z) + (2)];
    memCODE[(k) + (6)] := bufferI[(z) + (1)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1566
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (5)] := bufferI[(z) + (1)];
    memCODE[(k) + (4)] := bufferI[(z) + (2)];
    k := k + 8;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1572
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (1)] := bufferI[(z) + (1)];
    memCODE[(k) + (0)] := bufferI[(z) + (2)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1577
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (2)] := bufferI[(z) + (2)];
    memCODE[(k) + (6)] := bufferI[(z) + (1)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1582
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (5)] := bufferI[(z) + (1)];
    memCODE[(k) + (4)] := bufferI[(z) + (2)];
    k := k + 8;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1588
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (1)] := bufferI[(z) + (1)];
    memCODE[(k) + (0)] := bufferI[(z) + (2)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1593
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (2)] := bufferI[(z) + (2)];
    memCODE[(k) + (6)] := bufferI[(z) + (1)];
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1598
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    memCODE[(k) + (5)] := bufferI[(z) + (1)];
    memCODE[(k) + (4)] := bufferI[(z) + (2)];
    k := k + 8;
   end;
   sprintf(str, strings[S_CodeReading2], ((i) * (100)) div (dim), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
    // step: i += 24
  end;
  if (k) <> (dim) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if executiveArea then
  begin
   j := 0;
   PrintMessage(strings[S_Read_EXE_A]);
   if saveLog then
    fprintf(logfile, "\nExecutive area:\n");
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $45;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $87;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1647
     Original C:
       for (i = 0, k = 0; i < executiveArea; i += 16)
       {
         bufferU[j++] = 0x49;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0x96;
         bufferU[j++] = 0x37;
         bufferU[j++] = 0x49;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0xDB;
         bufferU[j++] = 0xB6;
         bufferU[j++] = 0x49;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0xD3;
         bufferU[j++] = 0xD6;
         bufferU[j++] = 0x37;
         bufferU[j++] = 0x49;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0xB6;
         bufferU[j++] = 0x37;
         bufferU[j++] = 0x49;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0x96;
         bufferU[j++] = 0x37;...
   *)
   // init: i = 0, k = 0
   while (i) < (executiveArea) do
   begin
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $96;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $DB;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $D3;
    bufferU[Inc(j)] := $D6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $49;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(3);
    j := 0;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1695
      Original C:
        for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z = 0
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (1)] := bufferI[(z) + (1)];
     memExec[k] := bufferI[(z) + (2)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1700
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (2)] := bufferI[(z) + (2)];
     memExec[(k) + (6)] := bufferI[(z) + (1)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1705
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (5)] := bufferI[(z) + (1)];
     memExec[(k) + (4)] := bufferI[(z) + (2)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1710
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (9)] := bufferI[(z) + (1)];
     memExec[(k) + (8)] := bufferI[(z) + (2)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1715
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (10)] := bufferI[(z) + (2)];
     memExec[(k) + (14)] := bufferI[(z) + (1)];
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1720
      Original C:
        for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
    *)
    // init: z += 3
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
      // step: z++
    end;
    if (z) < ((64) - (2)) then
    begin
     memExec[(k) + (13)] := bufferI[(z) + (1)];
     memExec[(k) + (12)] := bufferI[(z) + (2)];
    end;
    k := k + 16;
    sprintf(str, strings[S_CodeReading2], ((i) * (100)) div (executiveArea), ($800000) + ((i) div (2)));
    gtk_statusbar_push(status_bar, statusID, str);
    while gtk_events_pending() do
    begin
     gtk_main_iteration();
    end;
    if RWstop then
     i := dim;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
     // step: i += 16
   end;
   if (k) <> (executiveArea) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ReadCodeErr2], executiveArea, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
  PrintMessage("\r\n");
  j := 0;
  if saveLog then
   fprintf(logfile, "\nUser ID:\n");
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $45;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $86;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $DB;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $D3;
  bufferU[Inc(j)] := $D6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $DB;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $D3;
  bufferU[Inc(j)] := $D6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(3);
  j := 0;
  k := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1814
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   UID[(k) + (1)] := bufferI[(z) + (1)];
   UID[k] := bufferI[(z) + (2)];
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1819
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   UID[(k) + (2)] := bufferI[(z) + (2)];
   UID[(k) + (6)] := bufferI[(z) + (1)];
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1824
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   UID[(k) + (5)] := bufferI[(z) + (1)];
   UID[(k) + (4)] := bufferI[(z) + (2)];
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1829
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   UID[(k) + (9)] := bufferI[(z) + (1)];
   UID[(k) + (8)] := bufferI[(z) + (2)];
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1834
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   UID[(k) + (10)] := bufferI[(z) + (2)];
   UID[(k) + (14)] := bufferI[(z) + (1)];
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:1839
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   UID[(k) + (13)] := bufferI[(z) + (1)];
   UID[(k) + (12)] := bufferI[(z) + (2)];
  end;
  PrintMessage("\r\n");
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
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
  PacketIO(2);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, "");
  for i := 0 to (10) - 1 do
  begin
   sprintf(str, "CONFIG%d(0x%05X): 0x%02X\r\n", i, (((dim) - (40)) + ((i) * (4))) div (2), memCODE[((dim) - (40)) + ((i) * (4))]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE24F(dim);
  if executiveArea then
  begin
   empty := 1;
   aux := malloc(((((executiveArea) div (16)) + (1)) * (2)) * ((16) + ((16) * (9))));
   aux[0] := 0;
   s[0] := 0;
   empty := 1;
   PrintMessage(strings[S_ExeMem]);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:1871
     Original C:
       for (i = 0; i < executiveArea; i += 16 * 2)
       {
         valid = 0;
         for (j = i; (j < (i + (16 * 2))) && (j < executiveArea); j += 4)
         {
           d = (((memExec[j + 3] << 24) + (memExec[j + 2] << 16)) + (memExec[j + 1] << 8)) + memExec[j];
           sprintf(t, "%08X ", d);
           strcat(s, t);
           if (d != 0xffffffff)
             valid = 1;
         }
       
         if (valid)
         {
           sprintf(t, "%06X: %s\r\n", i / 2, s);
           empty = 0;
           strcat(aux, t);
         }
         s[0] = 0;
       }
   *)
   // init: i = 0
   while (i) < (executiveArea) do
   begin
    valid := 0;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:1873
      Original C:
        for (j = i; (j < (i + (16 * 2))) && (j < executiveArea); j += 4)
        {
          d = (((memExec[j + 3] << 24) + (memExec[j + 2] << 16)) + (memExec[j + 1] << 8)) + memExec[j];
          sprintf(t, "%08X ", d);
          strcat(s, t);
          if (d != 0xffffffff)
            valid = 1;
        }
    *)
    // init: j = i
    while ((j) < ((i) + ((16) * (2)))) and ((j) < (executiveArea)) do
    begin
     d := ((((memExec[(j) + (3)]) shl (24)) + ((memExec[(j) + (2)]) shl (16))) + ((memExec[(j) + (1)]) shl (8))) + (memExec[j]);
     sprintf(t, "%08X ", d);
     strcat(s, t);
     if (d) <> ($ffffffff) then
      valid := 1;
      // step: j += 4
    end;
    if valid then
    begin
     sprintf(t, "%06X: %s\r\n", (i) div (2), s);
     empty := 0;
     strcat(aux, t);
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
  for i := 0 to (4) - 1 do
  begin
   if ((UID[(i) * (4)]) <> ($FF)) or ((UID[((i) * (4)) + (1)]) <> ($FF)) then
   begin
    sprintf(str, "UserID%d=%04X", i, ((UID[(i) * (4)]) shl (8)) + (UID[((i) * (4)) + (1)]));
    PrintMessage(str);
   end;
  end;
  sprintf(str, strings[S_End], ((stop) - (start)) div (1000.0));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write24Fx(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  entry: Integer;
  config: Integer;
  EEbaseAddr: Integer;
  newTABLPAG: Integer;
  err: Integer;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  erase: Integer;
  valid: Integer;
  High: Integer;
  r0: Integer;
  r1: Integer;
  r2: Integer;
  r3: Integer;
  w3: Integer;
  w2: Integer;
  eewrite: Integer;
  errE: Integer;
  written: Integer;
  read: Integer;
  confword: Integer;
  errC: Integer;
  Nconf: Integer;
  value: Integer;
  errC: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := (options) and ($F);
  config := ((options) shr (4)) and ($F);
  EEbaseAddr := ($1000) - (dim2);
  newTABLPAG := IfThen((options) and ($100000), 1, 0);
  err := 0;
  if (FWVersion) < ($700) then
  begin
   sprintf(str, strings[S_FWver2old], "0.7.0");
   PrintMessage(str);
   Exit;
  end;
  if ((entry) < (2)) and (not (CheckV33Regulator())) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Write24Fx(%d,%d,%d,%d,%d,%.1f)    (0x%X,0x%X,0x%X,0x%X,0x%X,%.3f)\n", dim, dim2, options, appIDaddr, rowSize, wait, dim, dim2, options, appIDaddr, rowSize, wait);
  end;
  dim := dim * 2;
  if ((dim) > ($80000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($1000)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  j := size;
  if (j) mod ((rowSize) * (4)) then
  begin
   size := ((((j) div ((rowSize) * (4))) + (1)) * (rowSize)) * (4);
   memCODE := realloc(memCODE, size);
   while (j) < (size) do
   begin
    memCODE[j] := $FF;
    Inc(j);
   end;
  end;
  if (dim) > (size) then
   dim := size;
  if (sizeEE) < ($1000) then
   dim2 := 0;
  if (dim) < (1) then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  if ((entry) = (1)) or ((entry) = (2)) then
  begin
   if not (StartHVReg(IfThen((entry) = (2), 12, 6))) then
   begin
    PrintMessage(strings[S_HVregErr]);
    Exit;
   end;
  end
  else
   StartHVReg(-(1));
  if (config) > (2) then
  begin
   PrintMessage(strings[S_ConfigMem]);
   if (((config) = (3)) or ((config) = (4))) or ((config) = (6)) then
   begin
    sprintf(str, "0xF80000: FBS = 0x%02X\r\n", memCONFIG[0]);
    PrintMessage(str);
    if (config) = (4) then
    begin
     sprintf(str, "0xF80002: FSS = 0x%02X\r\n", memCONFIG[4]);
     PrintMessage(str);
    end;
    sprintf(str, "0xF80004: FGS = 0x%02X\r\n", memCONFIG[8]);
    PrintMessage(str);
    sprintf(str, "0xF80006: FOSCSEL = 0x%02X\r\n", memCONFIG[12]);
    PrintMessage(str);
    sprintf(str, "0xF80008: FOSC = 0x%02X\r\n", memCONFIG[16]);
    PrintMessage(str);
    sprintf(str, "0xF8000A: FWDT = 0x%02X\r\n", memCONFIG[20]);
    PrintMessage(str);
    sprintf(str, "0xF8000C: FPOR = 0x%02X\r\n", memCONFIG[24]);
    PrintMessage(str);
    sprintf(str, "0xF8000E: FICD = 0x%02X\r\n", memCONFIG[28]);
    PrintMessage(str);
    if (config) = (3) then
    begin
     sprintf(str, "0xF80010: FDS = 0x%02X\r\n", memCONFIG[32]);
     PrintMessage(str);
    end
    else
     if (config) = (4) then
     begin
      sprintf(str, "0xF80010: UID0 = 0x%02X\r\n", memCONFIG[32]);
      PrintMessage(str);
      sprintf(str, "0xF80012: UID1 = 0x%02X\r\n", memCONFIG[36]);
      PrintMessage(str);
      sprintf(str, "0xF80014: UID2 = 0x%02X\r\n", memCONFIG[40]);
      PrintMessage(str);
      sprintf(str, "0xF80016: UID3 = 0x%02X\r\n", memCONFIG[44]);
      PrintMessage(str);
     end;
   end
   else
    if (config) = (5) then
    begin
     sprintf(str, "0xF80000: FOSC = 0x%02X%02X\r\n", memCONFIG[1], memCONFIG[0]);
     PrintMessage(str);
     sprintf(str, "0xF80002: FWDT = 0x%02X%02X\r\n", memCONFIG[5], memCONFIG[4]);
     PrintMessage(str);
     sprintf(str, "0xF80004: FBORPOR = 0x%02X%02X\r\n", memCONFIG[9], memCONFIG[8]);
     PrintMessage(str);
     sprintf(str, "0xF80006: FBS = 0x%02X%02X\r\n", memCONFIG[13], memCONFIG[12]);
     PrintMessage(str);
     sprintf(str, "0xF80008: FSS = 0x%02X%02X\r\n", memCONFIG[17], memCONFIG[16]);
     PrintMessage(str);
     sprintf(str, "0xF8000A: FGS = 0x%02X%02X\r\n", memCONFIG[21], memCONFIG[20]);
     PrintMessage(str);
     sprintf(str, "0xF8000C: FICD = 0x%02X%02X\r\n", memCONFIG[25], memCONFIG[24]);
     PrintMessage(str);
    end;
  end
  else
  begin
   sprintf(str, "CONFIG1: 0x%04X\r\nCONFIG2: 0x%04X\r\n", ((memCODE[(dim) - (3)]) shl (8)) + (memCODE[(dim) - (4)]), ((memCODE[(dim) - (7)]) shl (8)) + (memCODE[(dim) - (8)]));
   PrintMessage(str);
   if (config) = (1) then
   begin
    sprintf(str, "CONFIG3: 0x%04X\r\n", ((memCODE[(dim) - (11)]) shl (8)) + (memCODE[(dim) - (12)]));
    PrintMessage(str);
   end;
   if (config) = (2) then
   begin
    sprintf(str, "CONFIG4: 0x%04X\r\n", ((memCODE[(dim) - (15)]) shl (8)) + (memCODE[(dim) - (16)]));
    PrintMessage(str);
   end;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  if ((entry) = (0)) or ((entry) = (3)) then
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
  end
  else
   PrintMessage(strings[S_HVICSP]);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (30000) shr (8);
  bufferU[Inc(j)] := (30000) and ($ff);
  bufferU[Inc(j)] := $0A;
  if (entry) = (2) then
  begin
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $38;
  end
  else
  begin
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $0;
  end;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(37);
  j := 0;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2155
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2157
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "DevID: 0x%04X\r\nDevRev: 0x%04X\r\n", w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $44;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := ($20) + (((appIDaddr) shr (12)) and ($F));
  bufferU[Inc(j)] := ((appIDaddr) shr (4)) and ($FF);
  bufferU[Inc(j)] := (((appIDaddr) shl (4)) and ($F0)) + (6);
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $78;
  bufferU[Inc(j)] := $47;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
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
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2199
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "ApplicationID @ 0x80%04X:  0x%04X\r\n", appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, "\nERASE:\n");
  erase := ((options) and ($F00)) shr (8);
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $24;
  if (erase) = (0) then
  begin
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $4A;
  end
  else
   if (erase) = (1) then
   begin
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $FA;
   end
   else
    if (erase) >= (2) then
    begin
     bufferU[Inc(j)] := $07;
     bufferU[Inc(j)] := $FA;
    end;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $3B;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := $BB;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  if (erase) >= (2) then
  begin
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := 4;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $61;
   bufferU[Inc(j)] := $0A;
   if (erase) = (3) then
   begin
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(20);
    msDelay(200);
    j := 0;
   end;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $A9;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $61;
  end
  else
  begin
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $61;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3C;
   bufferU[Inc(j)] := $22;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $37;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(7);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2302
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  w0 := (bufferI[(z) + (1)]) and ($80);
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $3B;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $3C;
  bufferU[Inc(j)] := $22;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2318
    Original C:
      for (i = 0; ((erase < 2) && (i < 100)) && w0; i++)
      {
        PacketIO(5);
        for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
      
        w0 = bufferI[z + 1] & 0x80;
        msDelay(10);
      }
  *)
  // init: i = 0
  while (((erase) < (2)) and ((i) < (100))) and (w0) do
  begin
   PacketIO(5);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2320
     Original C:
       for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   w0 := (bufferI[(z) + (1)]) and ($80);
   msDelay(10);
    // step: i++
  end;
  if saveLog then
   fprintf(logfile, "\nErase time: %dms\n", (i) * (12));
  msDelay(10);
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 5;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := IfThen((erase) > (0), $1A, $4A);
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $3B;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  if newTABLPAG then
  begin
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $A0;
  end
  else
  begin
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $90;
  end;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(5);
  j := 0;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, "\nWRITE CODE:\n");
  High := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2363
    Original C:
      for (i = 0, k = 0; i < dim; i += 4 * 4)
      {
        if (k == 0)
        {
          for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (rowSize * 4))
          {
            for (k2 = 0; (k2 < (rowSize * 4)) && (!valid); k2++)
              if (memCODE[i + k2] < 0xFF)
              valid = 1;
      
          }
      
          if (i >= dim)
            break;
        }
        if ((i >> 17) != High)
        {
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x20;
          bufferU[j++] = (i >> 21) & 0xFF;
          bufferU[j++] = (i >> 13) & 0xF0;
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x88;
          if (newTABLPAG)
          {
            bufferU[j++] = 0x02;
            bufferU[j++] = 0xA0;
          }
          else
      ...
  *)
  // init: i = 0, k = 0
  while (i) < (dim) do
  begin
   if (k) = (0) then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:2365
      Original C:
        for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (rowSize * 4))
        {
          for (k2 = 0; (k2 < (rowSize * 4)) && (!valid); k2++)
            if (memCODE[i + k2] < 0xFF)
            valid = 1;
        
        }
    *)
    // init: valid = 0
    while (not (valid)) and ((i) < (dim)) do
    begin
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progP24.c:2366
       Original C:
         for (k2 = 0; (k2 < (rowSize * 4)) && (!valid); k2++)
           if (memCODE[i + k2] < 0xFF)
           valid = 1;
     *)
     // init: k2 = 0
     while ((k2) < ((rowSize) * (4))) and (not (valid)) do
     begin
      if (memCODE[(i) + (k2)]) < ($FF) then
       valid := 1;
       // step: k2++
     end;
      // step: i += (valid) ? (0) : (rowSize * 4)
    end;
    if (i) >= (dim) then
     Break;
   end;
   if ((i) shr (17)) <> (High) then
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := ((i) shr (21)) and ($FF);
    bufferU[Inc(j)] := ((i) shr (13)) and ($F0);
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    if newTABLPAG then
    begin
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $A0;
    end
    else
    begin
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $90;
    end;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
    High := (i) shr (17);
   end;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := ($20) + (((i) shr (13)) and ($F));
   bufferU[Inc(j)] := ((i) shr (5)) and ($FF);
   bufferU[Inc(j)] := (((i) shl (3)) and ($F0)) + (7);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (1)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (1)]) shl (4)) and ($F0)) + (((memCODE[i]) shr (4)) and ($F));
   bufferU[Inc(j)] := ((memCODE[i]) shl (4)) and ($F0);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (6)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (6)]) shl (4)) and ($F0)) + (((memCODE[(i) + (2)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (2)]) shl (4)) and ($F0)) + (1);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (5)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (5)]) shl (4)) and ($F0)) + (((memCODE[(i) + (4)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (4)]) shl (4)) and ($F0)) + (2);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (9)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (9)]) shl (4)) and ($F0)) + (((memCODE[(i) + (8)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (8)]) shl (4)) and ($F0)) + (3);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (14)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (14)]) shl (4)) and ($F0)) + (((memCODE[(i) + (10)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (10)]) shl (4)) and ($F0)) + (4);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (13)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (13)]) shl (4)) and ($F0)) + (((memCODE[(i) + (12)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (12)]) shl (4)) and ($F0)) + (5);
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $B6;
   Inc(k);
   if (k) = ((rowSize) div (4)) then
   begin
    if (erase) > (1) then
    begin
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
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
     bufferU[Inc(j)] := $3F;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := IfThen((erase) > (0), $1A, $4A);
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $04;
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $00;
    end
    else
    begin
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $04;
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
    end;
    k := 0;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   j := 0;
   sprintf(str, strings[S_CodeWriting2], ((i) * (100)) div ((dim) + (dim2)), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], (i) div (2), (i) div (2), k, k);
   end;
    // step: i += 4 * 4
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, "\nVERIFY CODE:\n");
  High := $E0000000;
  r0 := 0;
  r1 := 0;
  r2 := 0;
  r3 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:2530
    Original C:
      for (i = 0; i < dim; i += 16)
      {
        for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (16))
        {
          for (k2 = 0; (k2 < 16) && (!valid); k2++)
            if (memCODE[i + k2] < 0xFF)
            valid = 1;
      
        }
      
        if (i >= dim)
          break;
        if ((i >> 17) != High)
        {
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x20;
          bufferU[j++] = (i >> 21) & 0xFF;
          bufferU[j++] = (i >> 13) & 0xF0;
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x88;
          if (newTABLPAG)
          {
            bufferU[j++] = 0x02;
            bufferU[j++] = 0xA0;
          }
          else
          {
            bufferU[j++] = 0x01;
            bufferU[j++] = 0x90;
          }
      .....
  *)
  // init: i = 0
  while (i) < (dim) do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2532
     Original C:
       for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (16))
       {
         for (k2 = 0; (k2 < 16) && (!valid); k2++)
           if (memCODE[i + k2] < 0xFF)
           valid = 1;
       
       }
   *)
   // init: valid = 0
   while (not (valid)) and ((i) < (dim)) do
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:2533
      Original C:
        for (k2 = 0; (k2 < 16) && (!valid); k2++)
          if (memCODE[i + k2] < 0xFF)
          valid = 1;
    *)
    // init: k2 = 0
    while ((k2) < (16)) and (not (valid)) do
    begin
     if (memCODE[(i) + (k2)]) < ($FF) then
      valid := 1;
      // step: k2++
    end;
     // step: i += (valid) ? (0) : (16)
   end;
   if (i) >= (dim) then
    Break;
   if ((i) shr (17)) <> (High) then
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := ((i) shr (21)) and ($FF);
    bufferU[Inc(j)] := ((i) shr (13)) and ($F0);
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    if newTABLPAG then
    begin
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $A0;
    end
    else
    begin
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $90;
    end;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
    High := (i) shr (17);
   end;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := ($20) + (((i) shr (13)) and ($F));
   bufferU[Inc(j)] := ((i) shr (5)) and ($FF);
   bufferU[Inc(j)] := (((i) shl (3)) and ($F0)) + (6);
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(3);
   sprintf(str, strings[S_CodeV2], ((i) * (100)) div ((dim) + (dim2)), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2618
     Original C:
       for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2622
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r0 := r0 + (bufferI[(z) + (2)]) shl (16);
    r1 := (bufferI[(z) + (1)]) shl (16);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2627
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r1 := r1 + ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2631
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r2 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2635
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r2 := r2 + (bufferI[(z) + (2)]) shl (16);
    r3 := (bufferI[(z) + (1)]) shl (16);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2640
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r3 := r3 + ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   w0 := (((memCODE[(i) + (2)]) shl (16)) + ((memCODE[(i) + (1)]) shl (8))) + (memCODE[i]);
   w1 := (((memCODE[(i) + (6)]) shl (16)) + ((memCODE[(i) + (5)]) shl (8))) + (memCODE[(i) + (4)]);
   w2 := (((memCODE[(i) + (10)]) shl (16)) + ((memCODE[(i) + (9)]) shl (8))) + (memCODE[(i) + (8)]);
   w3 := (((memCODE[(i) + (14)]) shl (16)) + ((memCODE[(i) + (13)]) shl (8))) + (memCODE[(i) + (12)]);
   CheckData(w0, r0, (i) div (2), @(err));
   CheckData(w1, r1, ((i) div (2)) + (2), @(err));
   CheckData(w2, r2, ((i) div (2)) + (4), @(err));
   CheckData(w3, r3, ((i) div (2)) + (6), @(err));
   sprintf(str, strings[S_CodeV2], ((i) * (100)) div (dim), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], (i) div (2), (i) div (2), k, k, err);
   end;
   if (err) >= (max_err) then
    Break;
    // step: i += 16
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if (err) >= (max_err) then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  if (dim2) and ((err) < (max_err)) then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, "\nWRITE EEPROM:\n");
   eewrite := ((options) and ($f000)) shr (12);
   if (eewrite) = (0) then
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $24;
    bufferU[Inc(j)] := $05;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $3B;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := $F0;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    if newTABLPAG then
    begin
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $A0;
    end
    else
    begin
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $90;
    end;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $2F;
    bufferU[Inc(j)] := (EEbaseAddr) shr (4);
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $BB;
    bufferU[Inc(j)] := $08;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $A8;
    bufferU[Inc(j)] := $E7;
    bufferU[Inc(j)] := $61;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $24;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $4A;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $3B;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(9);
    j := 0;
   end
   else
    if (eewrite) = (2) then
    begin
     bufferU[Inc(j)] := $3F;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $04;
     bufferU[Inc(j)] := $6A;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $3F;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $6A;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(6);
     j := 0;
     bufferU[Inc(j)] := $3F;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $06;
     bufferU[Inc(j)] := $6A;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(4);
     j := 0;
    end
    else
     if (eewrite) = (1) then
     begin
      bufferU[Inc(j)] := $36;
      bufferU[Inc(j)] := $20;
      bufferU[Inc(j)] := $07;
      bufferU[Inc(j)] := $F0;
      bufferU[Inc(j)] := $36;
      bufferU[Inc(j)] := $88;
      if newTABLPAG then
      begin
       bufferU[Inc(j)] := $02;
       bufferU[Inc(j)] := $A0;
      end
      else
      begin
       bufferU[Inc(j)] := $01;
       bufferU[Inc(j)] := $90;
      end;
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(1);
      j := 0;
     end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2857
     Original C:
       for (k2 = 0, i = 0x1000 - dim2; i < 0x1000; i += 2)
       {
         if ((memEE[i] < 0xFF) || (memEE[i + 1] < 0xFF))
         {
           bufferU[j++] = 0x36;
           bufferU[j++] = 0x2F;
           bufferU[j++] = i >> 4;
           bufferU[j++] = ((i << 4) & 0xF0) + 7;
           bufferU[j++] = 0x36;
           bufferU[j++] = 0x20 + ((memEE[i + 1] >> 4) & 0xF);
           bufferU[j++] = ((memEE[i + 1] << 4) & 0xF0) + ((memEE[i] >> 4) & 0xF);
           bufferU[j++] = (memEE[i] << 4) & 0xF0;
           bufferU[j++] = 0x38;
           bufferU[j++] = 0x3E;
           bufferU[j++] = 0xBB;
           bufferU[j++] = 0x1B;
           bufferU[j++] = 0x80;
           if (eewrite == 0)
           {
             bufferU[j++] = 0...
   *)
   // init: k2 = 0, i = 0x1000 - dim2
   while (i) < ($1000) do
   begin
    if ((memEE[i]) < ($FF)) or ((memEE[(i) + (1)]) < ($FF)) then
    begin
     bufferU[Inc(j)] := $36;
     bufferU[Inc(j)] := $2F;
     bufferU[Inc(j)] := (i) shr (4);
     bufferU[Inc(j)] := (((i) shl (4)) and ($F0)) + (7);
     bufferU[Inc(j)] := $36;
     bufferU[Inc(j)] := ($20) + (((memEE[(i) + (1)]) shr (4)) and ($F));
     bufferU[Inc(j)] := (((memEE[(i) + (1)]) shl (4)) and ($F0)) + (((memEE[i]) shr (4)) and ($F));
     bufferU[Inc(j)] := ((memEE[i]) shl (4)) and ($F0);
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $BB;
     bufferU[Inc(j)] := $1B;
     bufferU[Inc(j)] := $80;
     if (eewrite) = (0) then
     begin
      bufferU[Inc(j)] := $3E;
      bufferU[Inc(j)] := $A8;
      bufferU[Inc(j)] := $E7;
      bufferU[Inc(j)] := $61;
     end
     else
      if (eewrite) = (1) then
      begin
       bufferU[Inc(j)] := $3F;
       bufferU[Inc(j)] := 6;
       bufferU[Inc(j)] := $24;
       bufferU[Inc(j)] := $00;
       bufferU[Inc(j)] := $4A;
       bufferU[Inc(j)] := $88;
       bufferU[Inc(j)] := $3B;
       bufferU[Inc(j)] := $0A;
       bufferU[Inc(j)] := $20;
       bufferU[Inc(j)] := $05;
       bufferU[Inc(j)] := $58;
       bufferU[Inc(j)] := $88;
       bufferU[Inc(j)] := $3B;
       bufferU[Inc(j)] := $38;
       bufferU[Inc(j)] := $20;
       bufferU[Inc(j)] := $0A;
       bufferU[Inc(j)] := $A8;
       bufferU[Inc(j)] := $88;
       bufferU[Inc(j)] := $3B;
       bufferU[Inc(j)] := $38;
       bufferU[Inc(j)] := $3E;
       bufferU[Inc(j)] := $A8;
       bufferU[Inc(j)] := $E7;
       bufferU[Inc(j)] := $61;
       bufferU[Inc(j)] := $0A;
       bufferU[Inc(j)] := $38;
       bufferU[Inc(j)] := $38;
       bufferU[Inc(j)] := $3E;
       bufferU[Inc(j)] := $A9;
       bufferU[Inc(j)] := $E7;
       bufferU[Inc(j)] := $61;
      end;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO((wait) + (2));
     j := 0;
     sprintf(str, strings[S_CodeWriting], ((((i) - ($1000)) + (dim2)) * (100)) div (dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := dim;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k, k);
     end;
    end;
     // step: i += 2
   end;
   if saveLog then
    fprintf(logfile, "\nVERIFY EEPROM:\n");
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $2F;
   bufferU[Inc(j)] := (EEbaseAddr) shr (4);
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $38;
   errE := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:2938
     Original C:
       for (i = (k2 = EEbaseAddr); i < (EEbaseAddr + dim2); i += 2)
       {
         bufferU[j++] = 0x3E;
         bufferU[j++] = 0xBA;
         bufferU[j++] = 0x0B;
         bufferU[j++] = 0xB6;
         bufferU[j++] = 0x37;
         if ((j > (64 - 7)) || (i == (dim2 - 4)))
         {
           bufferU[j++] = 0x04;
           for (; j < 64; j++)
             bufferU[j] = 0x0;
       
           PacketIO(3);
           for (z = 0; z < (64 - 2); z++)
           {
             if (bufferI[z] == 0x37)
             {
               CheckData(memEE[k2], bufferI[z + 2], i, &errE);
               CheckData(memEE[k2 + 1], bufferI[z + 1], i + 1, &errE);
               z += 3;
               k2 += 2;
             }
           }
       
           {
             sprintf(str, strings[S_Co...
   *)
   // init: i = (k2 = EEbaseAddr)
   while (i) < ((EEbaseAddr) + (dim2)) do
   begin
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    if ((j) > ((64) - (7))) or ((i) = ((dim2) - (4))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(3);
     for z := 0 to ((64) - (2)) - 1 do
     begin
      if (bufferI[z]) = ($37) then
      begin
       CheckData(memEE[k2], bufferI[(z) + (2)], i, @(errE));
       CheckData(memEE[(k2) + (1)], bufferI[(z) + (1)], (i) + (1), @(errE));
       z := z + 3;
       k2 := k2 + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], (((i) - (EEbaseAddr)) * (100)) div (dim2), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := (EEbaseAddr) + (dim2);
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log7], i, i, k2, k2);
     end;
    end;
     // step: i += 2
   end;
   sprintf(str, strings[S_ComplErr], errE);
   PrintMessage(str);
   err := err + errE;
   gtk_statusbar_push(status_bar, statusID, "");
  end;
  j := 0;
  if (((config) > (2)) and ((config) < (5))) and ((err) < (max_err)) then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
    fprintf(logfile, "\nWRITE CONFIG:\n");
   confword := ((options) and ($F0000)) shr (16);
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := 6;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0F;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $88;
   if newTABLPAG then
   begin
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
   end
   else
   begin
    bufferU[Inc(j)] := $01;
    bufferU[Inc(j)] := $90;
   end;
   bufferU[Inc(j)] := $24;
   bufferU[Inc(j)] := $00;
   if (confword) = (0) then
    bufferU[Inc(j)] := $0A;
   else
    if (confword) = (1) then
     bufferU[Inc(j)] := $3A;
    else
     if (confword) = (2) then
      bufferU[Inc(j)] := $4A;
     else
      if (confword) = (3) then
       bufferU[Inc(j)] := $8A;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $3B;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $38;
   for i := 0 to (12) - 1 do
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := ((memCONFIG[(i) * (4)]) shr (4)) and ($F);
    bufferU[Inc(j)] := ((memCONFIG[(i) * (4)]) shl (4)) and ($F0);
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BB;
    bufferU[Inc(j)] := $1B;
    bufferU[Inc(j)] := $80;
    if (memCONFIG[(i) * (4)]) < ($FF) then
    begin
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
    end;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(5);
    msDelay(27);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   errC := 0;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $78;
   bufferU[Inc(j)] := $47;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
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
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   while (i) < (9) do
   begin
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
     Inc(z);
    end;
    written := memCONFIG[(i) * (4)];
    read := bufferI[(z) + (2)];
    if (not (written)) and (read) then
     CheckData(written, read, ($F80000) + ((i) * (2)), @(errC));
    z := z + 3;
    Inc(i);
   end;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $3E;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
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
    fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3126
     Original C:
       for (z = 0; i < 12; i++)
       {
         for (; (bufferI[z] != 0x37) && (z < 64); z++)
           ;
       
         written = memCONFIG[i * 4];
         read = bufferI[z + 2];
         if ((~written) & read)
           CheckData(written, read, 0xF80000 + (i * 2), &errC);
         z += 3;
       }
   *)
   // init: z = 0
   while (i) < (12) do
   begin
    while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
    begin
     Inc(z);
    end;
    written := memCONFIG[(i) * (4)];
    read := bufferI[(z) + (2)];
    if (not (written)) and (read) then
     CheckData(written, read, ($F80000) + ((i) * (2)), @(errC));
    z := z + 3;
     // step: i++
   end;
   sprintf(str, strings[S_ComplErr], errC);
   PrintMessage(str);
   gtk_statusbar_push(status_bar, statusID, "");
   err := err + errC;
  end
  else
   if ((config) >= (5)) and ((err) < (max_err)) then
   begin
    PrintMessage(strings[S_ConfigW]);
    if saveLog then
     fprintf(logfile, "\nWRITE CONFIG:\n");
    Nconf := IfThen((config) = (5), 7, 8);
    bufferU[Inc(j)] := $3F;
    bufferU[Inc(j)] := 4;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $0F;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $88;
    if newTABLPAG then
    begin
     bufferU[Inc(j)] := $02;
     bufferU[Inc(j)] := $A0;
    end
    else
    begin
     bufferU[Inc(j)] := $01;
     bufferU[Inc(j)] := $90;
    end;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    for i := 0 to (Nconf) - 1 do
    begin
     bufferU[Inc(j)] := $36;
     bufferU[Inc(j)] := $2F;
     bufferU[Inc(j)] := $FF;
     bufferU[Inc(j)] := $F0;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $BB;
     bufferU[Inc(j)] := $1B;
     bufferU[Inc(j)] := $80;
     bufferU[Inc(j)] := $3F;
     bufferU[Inc(j)] := 6;
     bufferU[Inc(j)] := $24;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $8A;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $05;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $20;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $88;
     bufferU[Inc(j)] := $3B;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A8;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $A9;
     bufferU[Inc(j)] := $E7;
     bufferU[Inc(j)] := $61;
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
    end;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $07;
    for i := 0 to (Nconf) - 1 do
    begin
     value := (memCONFIG[(i) * (4)]) + ((memCONFIG[((i) * (4)) + (1)]) shl (8));
     bufferU[Inc(j)] := $36;
     bufferU[Inc(j)] := ($20) + ((value) shr (12));
     bufferU[Inc(j)] := (value) shr (4);
     bufferU[Inc(j)] := (value) shl (4);
     bufferU[Inc(j)] := $38;
     bufferU[Inc(j)] := $3E;
     bufferU[Inc(j)] := $BB;
     bufferU[Inc(j)] := $1B;
     bufferU[Inc(j)] := $80;
     if (value) < ($FFFF) then
     begin
      bufferU[Inc(j)] := $3F;
      bufferU[Inc(j)] := 6;
      bufferU[Inc(j)] := $24;
      bufferU[Inc(j)] := $00;
      bufferU[Inc(j)] := $8A;
      bufferU[Inc(j)] := $88;
      bufferU[Inc(j)] := $3B;
      bufferU[Inc(j)] := $0A;
      bufferU[Inc(j)] := $20;
      bufferU[Inc(j)] := $05;
      bufferU[Inc(j)] := $58;
      bufferU[Inc(j)] := $88;
      bufferU[Inc(j)] := $3B;
      bufferU[Inc(j)] := $38;
      bufferU[Inc(j)] := $20;
      bufferU[Inc(j)] := $0A;
      bufferU[Inc(j)] := $A8;
      bufferU[Inc(j)] := $88;
      bufferU[Inc(j)] := $3B;
      bufferU[Inc(j)] := $38;
      bufferU[Inc(j)] := $3E;
      bufferU[Inc(j)] := $A8;
      bufferU[Inc(j)] := $E7;
      bufferU[Inc(j)] := $61;
      bufferU[Inc(j)] := $0A;
      bufferU[Inc(j)] := $38;
      bufferU[Inc(j)] := $38;
      bufferU[Inc(j)] := $3E;
      bufferU[Inc(j)] := $A9;
      bufferU[Inc(j)] := $E7;
      bufferU[Inc(j)] := $61;
     end;
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
    end;
    errC := 0;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $06;
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $78;
    bufferU[Inc(j)] := $47;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $BA;
    bufferU[Inc(j)] := $0B;
    bufferU[Inc(j)] := $B6;
    bufferU[Inc(j)] := $37;
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
     fprintf(logfile, strings[S_Log7], $F80000, $F80000, 0, 0);
    end;
    while (i) < (7) do
    begin
     while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
     begin
      Inc(z);
     end;
     written := (memCONFIG[((i) * (4)) + (1)]) + ((memCONFIG[(i) * (4)]) shl (8));
     read := (bufferI[(z) + (1)]) + ((bufferI[(z) + (2)]) shl (8));
     if (not (written)) and (read) then
      CheckData(written, read, ($F80000) + ((i) * (2)), @(errC));
     z := z + 3;
     Inc(i);
    end;
    sprintf(str, strings[S_ComplErr], errC);
    PrintMessage(str);
    gtk_statusbar_push(status_bar, statusID, "");
    err := err + errC;
   end;
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
  PacketIO(2);
  j := 0;
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

function Write24Ex(dim: Integer; dim2: Integer; options: Integer; appIDaddr: Integer; rowSize: Integer; wait: Double): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  start: Cardinal;
  w0: Integer;
  w1: Integer;
  valid: Integer;
  High: Integer;
  r0: Integer;
  r1: Integer;
  r2: Integer;
  r3: Integer;
  w3: Integer;
  w2: Integer;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  err := 0;
  if (FWVersion) < ($900) then
  begin
   sprintf(str, strings[S_FWver2old], "0.9.0");
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
   fprintf(logfile, "Write24Ex(%d,%d,%d,%d,%d,%.1f)    (0x%X,0x%X,0x%X,0x%X,0x%X,%.3f)\n", dim, dim2, options, appIDaddr, rowSize, wait, dim, dim2, options, appIDaddr, rowSize, wait);
  end;
  dim := dim * 2;
  if ((dim) > ($100000)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if (dim) > (size) then
   for i := size to (dim) - 1 do
   begin
    memCODE[i] := $FF;
   end;
  if (dim) < (1) then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  StartHVReg(-(1));
  for i := 0 to (10) - 1 do
  begin
   sprintf(str, "CONFIG%d(0x%05X): 0x%02X\r\n", i, (((dim) - (40)) + ((i) * (4))) div (2), memCODE[((dim) - (40)) + ((i) * (4))]);
   PrintMessage(str);
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $4D;
  bufferU[Inc(j)] := $43;
  bufferU[Inc(j)] := $48;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (55000) shr (8);
  bufferU[Inc(j)] := (55000) and ($ff);
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(65);
  j := 0;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $F0;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $B6;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  w0 := 0;
  w1 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3493
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3495
    Original C:
      for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w1 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "DevID: 0x%04X\r\nDevRev: 0x%04X\r\n", w0, w1);
  PrintMessage(str);
  PIC24_ID(w0);
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $44;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $A0;
  bufferU[Inc(j)] := ($20) + (((appIDaddr) shr (12)) and ($F));
  bufferU[Inc(j)] := ((appIDaddr) shr (4)) and ($FF);
  bufferU[Inc(j)] := (((appIDaddr) shl (4)) and ($F0)) + (6);
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $87;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $BA;
  bufferU[Inc(j)] := $0B;
  bufferU[Inc(j)] := $96;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
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
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3532
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   w0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  sprintf(str, "ApplicationID @ 0x80%04X:  0x%04X\r\n", appIDaddr, w0);
  PrintMessage(str);
  PrintMessage(strings[S_StartErase]);
  if saveLog then
   fprintf(logfile, "\nERASE:\n");
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $DA;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $4A;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $7C;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $05;
  bufferU[Inc(j)] := $51;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $71;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $A1;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $71;
  bufferU[Inc(j)] := $49;
  bufferU[Inc(j)] := $A8;
  bufferU[Inc(j)] := $E7;
  bufferU[Inc(j)] := $29;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $7C;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(4);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3594
    Original C:
      for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  w0 := (bufferI[(z) + (1)]) and ($80);
  w0 := 1;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $7C;
  bufferU[Inc(j)] := $40;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $37;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3612
    Original C:
      for (i = 0; (i < 50) && w0; i++)
      {
        PacketIO(5);
        for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
          ;
      
        w0 = bufferI[z + 1] & 0x80;
        msDelay(10);
      }
  *)
  // init: i = 0
  while ((i) < (50)) and (w0) do
  begin
   PacketIO(5);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3614
     Original C:
       for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   w0 := (bufferI[(z) + (1)]) and ($80);
   msDelay(10);
    // step: i++
  end;
  if saveLog then
   fprintf(logfile, "ERASE TIME: %d ms\n", (i) * (10));
  msDelay(70);
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $36;
  bufferU[Inc(j)] := $04;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $38;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := 4;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $02;
  bufferU[Inc(j)] := $AC;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $1A;
  bufferU[Inc(j)] := $88;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := $4A;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
   fprintf(logfile, "\nWRITE CODE:\n");
  High := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3658
    Original C:
      for (i = 0, k = 0; i < dim; i += 2 * 4)
      {
        for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (2 * 4))
        {
          for (k2 = 0; (k2 < (2 * 4)) && (!valid); k2++)
            if (memCODE[i + k2] < 0xFF)
            valid = 1;
      
        }
      
        if (i >= dim)
          break;
        bufferU[j++] = 0x3F;
        bufferU[j++] = 5;
        bufferU[j++] = 0xEB;
        bufferU[j++] = 0x03;
        bufferU[j++] = 0x00;
        bufferU[j++] = 0xEB;
        bufferU[j++] = 0x03;
        bufferU[j++] = 0x80;
        bufferU[j++] = 0x20 + ((memCODE[i + 1] >> 4) & 0xF);
        bufferU[j++] = ((memCODE[i + 1] << 4) & 0xF0) + ((memCODE[i] >> 4) & 0xF);
        bufferU[j++] = (memCODE[i] << 4) ...
  *)
  // init: i = 0, k = 0
  while (i) < (dim) do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3660
     Original C:
       for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (2 * 4))
       {
         for (k2 = 0; (k2 < (2 * 4)) && (!valid); k2++)
           if (memCODE[i + k2] < 0xFF)
           valid = 1;
       
       }
   *)
   // init: valid = 0
   while (not (valid)) and ((i) < (dim)) do
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:3661
      Original C:
        for (k2 = 0; (k2 < (2 * 4)) && (!valid); k2++)
          if (memCODE[i + k2] < 0xFF)
          valid = 1;
    *)
    // init: k2 = 0
    while ((k2) < ((2) * (4))) and (not (valid)) do
    begin
     if (memCODE[(i) + (k2)]) < ($FF) then
      valid := 1;
      // step: k2++
    end;
     // step: i += (valid) ? (0) : (2 * 4)
   end;
   if (i) >= (dim) then
    Break;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := 5;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $03;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (1)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (1)]) shl (4)) and ($F0)) + (((memCODE[i]) shr (4)) and ($F));
   bufferU[Inc(j)] := ((memCODE[i]) shl (4)) and ($F0);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (6)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (6)]) shl (4)) and ($F0)) + (((memCODE[(i) + (2)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (2)]) shl (4)) and ($F0)) + (1);
   bufferU[Inc(j)] := ($20) + (((memCODE[(i) + (5)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (5)]) shl (4)) and ($F0)) + (((memCODE[(i) + (4)]) shr (4)) and ($F));
   bufferU[Inc(j)] := (((memCODE[(i) + (4)]) shl (4)) and ($F0)) + (2);
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := $84;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $EB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $BB;
   bufferU[Inc(j)] := $1B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $3F;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := ($20) + (((i) shr (13)) and ($F));
   bufferU[Inc(j)] := ((i) shr (5)) and ($FF);
   bufferU[Inc(j)] := (((i) shl (3)) and ($F0)) + (3);
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := ((i) shr (21)) and ($FF);
   bufferU[Inc(j)] := (((i) shr (13)) and ($F0)) + (4);
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $53;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $64;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $51;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $71;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $A1;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $71;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $A8;
   bufferU[Inc(j)] := $E7;
   bufferU[Inc(j)] := $29;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   sprintf(str, strings[S_CodeWriting2], ((i) * (100)) div ((dim) + (dim2)), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], (i) div (2), (i) div (2), k, k);
   end;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := $42;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $88;
   bufferU[Inc(j)] := $7C;
   bufferU[Inc(j)] := $42;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   PacketIO(2);
    // step: i += 2 * 4
  end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, "\nVERIFY CODE:\n");
  High := $E0000000;
  r0 := 0;
  r1 := 0;
  r2 := 0;
  r3 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP24.c:3771
    Original C:
      for (i = 0; i < dim; i += 16)
      {
        for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (16))
        {
          for (k2 = 0; (k2 < 16) && (!valid); k2++)
            if (memCODE[i + k2] < 0xFF)
            valid = 1;
      
        }
      
        if (i >= dim)
          break;
        if ((i >> 17) != High)
        {
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x20;
          bufferU[j++] = (i >> 21) & 0xFF;
          bufferU[j++] = (i >> 13) & 0xF0;
          bufferU[j++] = 0x36;
          bufferU[j++] = 0x88;
          bufferU[j++] = 0x02;
          bufferU[j++] = 0xA0;
          bufferU[j++] = 0x3E;
          bufferU[j++] = 0x04;
          bufferU[j++] = 0x02;
          bufferU[j++] = 0x00;
          bufferU[j...
  *)
  // init: i = 0
  while (i) < (dim) do
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3773
     Original C:
       for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (16))
       {
         for (k2 = 0; (k2 < 16) && (!valid); k2++)
           if (memCODE[i + k2] < 0xFF)
           valid = 1;
       
       }
   *)
   // init: valid = 0
   while (not (valid)) and ((i) < (dim)) do
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP24.c:3774
      Original C:
        for (k2 = 0; (k2 < 16) && (!valid); k2++)
          if (memCODE[i + k2] < 0xFF)
          valid = 1;
    *)
    // init: k2 = 0
    while ((k2) < (16)) and (not (valid)) do
    begin
     if (memCODE[(i) + (k2)]) < ($FF) then
      valid := 1;
      // step: k2++
    end;
     // step: i += (valid) ? (0) : (16)
   end;
   if (i) >= (dim) then
    Break;
   if ((i) shr (17)) <> (High) then
   begin
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := ((i) shr (21)) and ($FF);
    bufferU[Inc(j)] := ((i) shr (13)) and ($F0);
    bufferU[Inc(j)] := $36;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $A0;
    bufferU[Inc(j)] := $3E;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $02;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $38;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
    High := (i) shr (17);
   end;
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := ($20) + (((i) shr (13)) and ($F));
   bufferU[Inc(j)] := ((i) shr (5)) and ($FF);
   bufferU[Inc(j)] := (((i) shl (3)) and ($F0)) + (6);
   bufferU[Inc(j)] := $36;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $87;
   bufferU[Inc(j)] := $38;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $96;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $DB;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $D3;
   bufferU[Inc(j)] := $D6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $BA;
   bufferU[Inc(j)] := $0B;
   bufferU[Inc(j)] := $B6;
   bufferU[Inc(j)] := $37;
   bufferU[Inc(j)] := $49;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(4);
   sprintf(str, strings[S_CodeV2], ((i) * (100)) div ((dim) + (dim2)), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   if RWstop then
    i := dim;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3854
     Original C:
       for (z = 0; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r0 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3858
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r0 := r0 + (bufferI[(z) + (2)]) shl (16);
    r1 := (bufferI[(z) + (1)]) shl (16);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3863
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r1 := r1 + ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3867
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r2 := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3871
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r2 := r2 + (bufferI[(z) + (2)]) shl (16);
    r3 := (bufferI[(z) + (1)]) shl (16);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP24.c:3876
     Original C:
       for (z += 3; (bufferI[z] != 0x37) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($37)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    r3 := r3 + ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   w0 := (((memCODE[(i) + (2)]) shl (16)) + ((memCODE[(i) + (1)]) shl (8))) + (memCODE[i]);
   w1 := (((memCODE[(i) + (6)]) shl (16)) + ((memCODE[(i) + (5)]) shl (8))) + (memCODE[(i) + (4)]);
   w2 := (((memCODE[(i) + (10)]) shl (16)) + ((memCODE[(i) + (9)]) shl (8))) + (memCODE[(i) + (8)]);
   w3 := (((memCODE[(i) + (14)]) shl (16)) + ((memCODE[(i) + (13)]) shl (8))) + (memCODE[(i) + (12)]);
   CheckData(w0, r0, (i) div (2), @(err));
   CheckData(w1, r1, ((i) div (2)) + (2), @(err));
   CheckData(w2, r2, ((i) div (2)) + (4), @(err));
   CheckData(w3, r3, ((i) div (2)) + (6), @(err));
   sprintf(str, strings[S_CodeV2], ((i) * (100)) div (dim), (i) div (2));
   gtk_statusbar_push(status_bar, statusID, str);
   while gtk_events_pending() do
   begin
    gtk_main_iteration();
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], (i) div (2), (i) div (2), k, k, err);
   end;
   if (err) >= (max_err) then
    Break;
    // step: i += 16
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if (err) >= (max_err) then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
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
  PacketIO(2);
  j := 0;
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
