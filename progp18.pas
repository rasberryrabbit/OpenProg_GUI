unit progp18;

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
  LOAD_PC_ADDR = $80;
  BULK_ERASE = $18;
  ROW_ERASE_PROGRAM_MEM = $F0;
  LOAD_NVM = $00;
  LOAD_NVM_INC = $02;
  READ_NVM = $FC;
  READ_NVM_INC = $FE;
  INC_ADDR8 = $F8;
  BEGIN_INT_PROG = $E0;
  BEGIN_EXT_PROG = $C0;
  PROGRAM_DATA = $C0;
  PROGRAM_DATA_INC = $E0;
  END_EXT_PROG = $82;
  PROGRAM_ACCESS_EN = $4C;
  IDaddr = $200000;
  CONFIGaddr = $300000;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  PIC18LIST: array of TID18;

// --- function declarations ---
function PIC18_ID(id: Integer): Pointer;
function DisplayCODE18F(dim: Integer): Pointer;
function Read18Fx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer): Pointer;
function Read18FKx(dim: Integer; dim2: Integer; options: Integer): Pointer;
function Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer): Pointer;

implementation

function PIC18_ID(id: Integer): Pointer;
var
  s: array[0..128-1] of Char;
  i: Integer;
  MJrev: Integer;
  MNrev: Integer;
begin
  for i := 0 to (sizeof(PIC18LIST)/sizeof(PIC18LIST[0])) - 1 do
  begin
   if PIC18LIST[i].revmask not =0xFFFF and PIC18LIST[i].id = (id&~PIC18LIST[i].revmask) then
   begin
    sprintf(s, PIC18LIST[i].device, id&PIC18LIST[i].revmask);
    PrintMessage(s);
    Exit;
   end
   else if PIC18LIST[i].revmask = 0xFFFF and PIC18LIST[i].id = (id&0xFFFF) then
   begin
    MJrev := (id shr 22)&0x3F;
    MNrev := (id shr 16)&0x3F;
    sprintf(s, PIC18LIST[i].device, MJrev+'A', MNrev);
    PrintMessage(s);
    Exit;
   end;
  end;
  PrintMessage(s);
end;

function DisplayCODE18F(dim: Integer): Pointer;
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
  s := "";
  t := "";
  aux := malloc((((dim) div (16)) + (1)) * ((16) + ((16) * (6))));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:386
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
     Source: /tmp/opgui-0.12.4/progP18.c:388
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

function Read18Fx(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  entry: Integer;
  newAddr: Integer;
  vpp: Double;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  entry := (options) and ($F);
  newAddr := ((options) shr (4)) and ($F);
  if ((dim) > ($1FFFFF)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if ((entry) > (0)) and (not (CheckV33Regulator())) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := -(1);
  if (entry) = (0) then
   vpp := 12;
  else
   if ((entry) = (1)) or ((entry) = (3)) then
    vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Read18F(%d,%d,%d)    (0x%X,0x%X,0x%X)\n", dim, dim2, options, dim, dim2, options);
  end;
  size := dim;
  sizeEE := dim2;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  if memEE then
   free(memEE);
  memEE := malloc(sizeEE);
  for j := 0 to (8) - 1 do
  begin
   memID[j] := $FF;
  end;
  for j := 0 to (14) - 1 do
  begin
   memCONFIG[j] := $FF;
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
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  if (entry) = (2) then
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
  end;
  if ((entry) = (2)) or ((entry) = (3)) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $4D;
   bufferU[Inc(j)] := $43;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen((entry) = (2), 11, 4));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:527
    Original C:
      for (z = 0; (bufferI[z] != 0x24) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($24)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (3)) then
  begin
   sprintf(str, strings[S_DevID2], bufferI[(z) + (3)], bufferI[(z) + (2)]);
   PrintMessage(str);
   PIC18_ID((bufferI[(z) + (2)]) + ((bufferI[(z) + (3)]) shl (8)));
  end;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, "Read code\n");
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:536
    Original C:
      for (i = 0, j = 0; i < dim; i += 64 - 4)
      {
        bufferU[j++] = 0x24;
        bufferU[j++] = (i < (dim - (64 - 4))) ? (64 - 4) : (dim - i);
        bufferU[j++] = 0x04;
        for (; j < 64; j++)
          bufferU[j] = 0x0;
      
        PacketIO(2);
        for (z = 0; (bufferI[z] != 0x24) && (z < 64); z++)
          ;
      
        for (j = z + 2; (j < ((z + 2) + bufferI[z + 1])) && (j < 64); j++)
          memCODE[k++] = bufferI[j];
      
        {
          sprintf(str, strings[S_CodeReading2], (i * 100) / (dim + dim2), i);
          gtk_statusbar_push((GtkStatusbar * ) status_bar, statusID, str);
          while (gtk_events_pending())
            gtk_main_iteration();
      
        }
        ;
        if (RWstop...
  *)
  // init: i = 0, j = 0
  while (i) < (dim) do
  begin
   bufferU[Inc(j)] := $24;
   bufferU[Inc(j)] := IfThen((i) < ((dim) - ((64) - (4))), (64) - (4), (dim) - (i));
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:542
     Original C:
       for (z = 0; (bufferI[z] != 0x24) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($24)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:543
     Original C:
       for (j = z + 2; (j < ((z + 2) + bufferI[z + 1])) && (j < 64); j++)
         memCODE[k++] = bufferI[j];
   *)
   // init: j = z + 2
   while ((j) < (((z) + (2)) + (bufferI[(z) + (1)]))) and ((j) < (64)) do
   begin
    memCODE[Inc(k)] := bufferI[j];
     // step: j++
   end;
   sprintf(str, strings[S_CodeReading2], ((i) * (100)) div ((dim) + (dim2)), i);
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
    // step: i += 64 - 4
  end;
  if (k) <> (dim) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if saveLog then
   fprintf(logfile, "Read config\n");
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $20;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := 8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $30;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := 14;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(8);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:590
    Original C:
      for (z = 0; (bufferI[z] != 0x24) && (z < (64 - 28)); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($24)) and ((z) < ((64) - (28))) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (28)) then
  begin
   for i := 0 to (8) - 1 do
   begin
    memID[Inc(k2)] := bufferI[((z) + (i)) + (2)];
   end;
   while (i) < ((14) + (8)) do
   begin
    memCONFIG[(-(8)) + (Inc(k2))] := bufferI[((z) + (i)) + (8)];
    Inc(i);
   end;
  end;
  j := 0;
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log7], i, i, k2, k2);
  end;
  if (k2) <> (22) then
  begin
   sprintf(str, strings[S_ReadConfigErr], 22, k2);
   PrintMessage(str);
  end;
  if dim2 then
  begin
   PrintMessage(strings[S_ReadEE]);
   if saveLog then
    fprintf(logfile, "Read EEPROM\n");
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $9E;
   bufferU[Inc(j)] := IfThen((newAddr) = (0), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $9C;
   bufferU[Inc(j)] := IfThen((newAddr) = (0), $A6, $7F);
   while (i) < (dim2) do
   begin
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := (i) and ($FF);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := IfThen((newAddr) = (0), $A9, $74);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := ((i) shr (8)) and ($FF);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := IfThen((newAddr) = (0), $AA, $75);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := IfThen((newAddr) = (0), $A6, $7F);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $50;
    bufferU[Inc(j)] := IfThen((newAddr) = (0), $A8, $73);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F5;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $22;
    if ((j) > ((64) - (26))) or ((i) = ((dim2) - (1))) then
    begin
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(10);
     for z := 0 to ((64) - (1)) - 1 do
     begin
      if (bufferI[z]) = ($22) then
      begin
       memEE[Inc(k2)] := bufferI[(z) + (1)];
       z := z + 8;
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
  PrintMessage("\r\n");
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
  PacketIO(1);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, "");
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:678
    Original C:
      for (i = 0; i < 8; i += 2)
      {
        {
          sprintf(str, strings[S_ChipID2], i, memID[i], i + 1, memID[i + 1]);
          PrintMessage(str);
        }
        ;
      }
  *)
  // init: i = 0
  while (i) < (8) do
  begin
   sprintf(str, strings[S_ChipID2], i, memID[i], (i) + (1), memID[(i) + (1)]);
   PrintMessage(str);
    // step: i += 2
  end;
  for i := 0 to (7) - 1 do
  begin
   sprintf(str, strings[S_ConfigWordH], (i) + (1), memCONFIG[((i) * (2)) + (1)]);
   PrintMessage(str);
   sprintf(str, strings[S_ConfigWordL], (i) + (1), memCONFIG[(i) * (2)]);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE18F(dim);
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

function Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  EEalgo: Integer;
  entry: Integer;
  optWrite: Integer;
  vpp: Double;
  start: Cardinal;
  ww: Integer;
  wdly: Double;
  valid: Integer;
  i0: Integer;
  errEE: Integer;
  errID: Integer;
  errC: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  EEalgo := ((options) shr (4)) and ($F);
  entry := (options) and ($F);
  optWrite := ((options) shr (8)) and ($F);
  if ((dim) > ($1FFFFF)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if (wbuf) > (64) then
  begin
   PrintMessage(strings[S_WbufLim]);
   Exit;
  end;
  if ((entry) > (0)) and (not (CheckV33Regulator())) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := -(1);
  if (entry) = (0) then
   vpp := 12;
  else
   if ((entry) = (1)) or ((entry) = (3)) then
    vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Write18F(%d,%d,%d,%d)    (0x%X,0x%X,0x%X,0x%X)\n", dim, dim2, wbuf, options, dim, dim2, wbuf, options);
  end;
  if (dim) > (size) then
   dim := size;
  if (dim) mod (wbuf) then
  begin
   dim := dim + (wbuf) - ((dim) mod (wbuf));
   j := size;
   if (j) < (dim) then
   begin
    size := dim;
    memCODE := realloc(memCODE, size);
    while (j) < (dim) do
    begin
     memCODE[j] := $FF;
     Inc(j);
    end;
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
  if (entry) = (2) then
  begin
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
  end;
  if ((entry) = (2)) or ((entry) = (3)) then
  begin
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $4D;
   bufferU[Inc(j)] := $43;
   bufferU[Inc(j)] := $48;
   bufferU[Inc(j)] := $50;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $0A;
  end;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $24;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (5100) shr (8);
  bufferU[Inc(j)] := (5100) and ($ff);
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(IfThen((entry) = (2), 10, 3));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:823
    Original C:
      for (z = 0; (bufferI[z] != 0x24) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($24)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (3)) then
  begin
   sprintf(str, strings[S_DevID2], bufferI[(z) + (3)], bufferI[(z) + (2)]);
   PrintMessage(str);
   PIC18_ID((bufferI[(z) + (2)]) + ((bufferI[(z) + (3)]) shl (8)));
  end;
  j := 0;
  PrintMessage(strings[S_StartErase]);
  if (optWrite) <> (3) then
  begin
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $3C;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   if (eraseW1) < ($10000) then
   begin
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $05;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F6;
    bufferU[Inc(j)] := $25;
    bufferU[Inc(j)] := ((eraseW1) shr (8)) and ($FF);
    bufferU[Inc(j)] := (eraseW1) and ($FF);
   end;
   if (eraseW2) < ($10000) then
   begin
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $04;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F6;
    bufferU[Inc(j)] := $25;
    bufferU[Inc(j)] := ((eraseW2) shr (8)) and ($FF);
    bufferU[Inc(j)] := (eraseW2) and ($FF);
   end;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(16);
   if (optWrite) <> (0) then
    msDelay(550);
   j := 0;
  end
  else
  begin
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $3C;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, "ERASE BLOCK0\n");
   end;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, "ERASE BLOCK1\n");
   end;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, "ERASE BLOCK2\n");
   end;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, "ERASE BLOCK3\n");
   end;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, "ERASE BOOT BLOCK\n");
   end;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $25;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, "ERASE CONFIG\n");
   end;
   if programID then
   begin
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $8E;
    bufferU[Inc(j)] := $7F;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $9C;
    bufferU[Inc(j)] := $7F;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $84;
    bufferU[Inc(j)] := $7F;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F8;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6A;
    bufferU[Inc(j)] := $F7;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6A;
    bufferU[Inc(j)] := $F6;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $88;
    bufferU[Inc(j)] := $7F;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $82;
    bufferU[Inc(j)] := $7F;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $00;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(7);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, "ERASE ID\n");
    end;
   end;
  end;
  PrintMessage(strings[S_Compl]);
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $8E;
  bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $9C;
  bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $84;
  bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(1);
  j := 0;
  PrintMessage(strings[S_StartCodeProg]);
  wdly := 1.0;
  if (optWrite) = (1) then
   wdly := 1.2;
  if (optWrite) = (2) then
   wdly := 3.4;
  if saveLog then
  begin
   fprintf(logfile, "WRITE CODE\ndim=%d(0x%X)\n", dim, dim);
  end;
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:1201
    Original C:
      for (i = (k = 0); i < dim;)
      {
        if (k == 0)
        {
          i0 = i;
          for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (wbuf))
          {
            for (k2 = 0; (k2 < wbuf) && (!valid); k2++)
              if (memCODE[i + k2] < 0xFF)
              valid = 1;
      
          }
      
          if (i >= dim)
            break;
          if (i > i0)
          {
            bufferU[j++] = 0x21;
            bufferU[j++] = 0x0E;
            bufferU[j++] = (i >> 16) & 0xFF;
            bufferU[j++] = 0x21;
            bufferU[j++] = 0x6E;
            bufferU[j++] = 0xF8;
            bufferU[j++] = 0x21;
            bufferU[j++] = 0x0E;
            bufferU[j++] = (i >> 8) & 0xFF;
            bufferU[j++] = 0x21;
         ...
  *)
  // init: i = (k = 0)
  while (i) < (dim) do
  begin
   if (k) = (0) then
   begin
    i0 := i;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP18.c:1204
      Original C:
        for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (wbuf))
        {
          for (k2 = 0; (k2 < wbuf) && (!valid); k2++)
            if (memCODE[i + k2] < 0xFF)
            valid = 1;
        
        }
    *)
    // init: valid = 0
    while (not (valid)) and ((i) < (dim)) do
    begin
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progP18.c:1205
       Original C:
         for (k2 = 0; (k2 < wbuf) && (!valid); k2++)
           if (memCODE[i + k2] < 0xFF)
           valid = 1;
     *)
     // init: k2 = 0
     while ((k2) < (wbuf)) and (not (valid)) do
     begin
      if (memCODE[(i) + (k2)]) < ($FF) then
       valid := 1;
       // step: k2++
     end;
      // step: i += (valid) ? (0) : (wbuf)
    end;
    if (i) >= (dim) then
     Break;
    if (i) > (i0) then
    begin
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := ((i) shr (16)) and ($FF);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $6E;
     bufferU[Inc(j)] := $F8;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := ((i) shr (8)) and ($FF);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $6E;
     bufferU[Inc(j)] := $F7;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := (i) and ($FF);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $6E;
     bufferU[Inc(j)] := $F6;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(2);
     j := 0;
    end;
   end;
   if (((64) - (4)) - (j)) < (((wbuf) - (2)) - (k)) then
    ww := (((64) - (4)) - (j)) div (2);
   else
    ww := (((wbuf) - (2)) - (k)) div (2);
   bufferU[Inc(j)] := $26;
   bufferU[Inc(j)] := ww;
   for z := 0 to (ww) - 1 do
   begin
    bufferU[Inc(j)] := memCODE[(i) + (1)];
    bufferU[Inc(j)] := memCODE[i];
    i := i + 2;
   end;
   k := k + (ww) * (2);
   if (k) = ((wbuf) - (2)) then
   begin
    if (j) > ((64) - (8)) then
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
    bufferU[Inc(j)] := $28;
    bufferU[Inc(j)] := memCODE[(i) + (1)];
    bufferU[Inc(j)] := memCODE[i];
    if (optWrite) = (1) then
    begin
     bufferU[Inc(j)] := (1200) shr (8);
     bufferU[Inc(j)] := (1200) and ($FF);
    end
    else
     if (optWrite) = (2) then
     begin
      bufferU[Inc(j)] := (3400) shr (8);
      bufferU[Inc(j)] := (3400) and ($FF);
     end
     else
     begin
      bufferU[Inc(j)] := (1000) shr (8);
      bufferU[Inc(j)] := (1000) and ($FF);
     end;
    i := i + 2;
    k := 0;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(IfThen((k) = (0), wdly, 2));
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
    fprintf(logfile, strings[S_Log7], i, i, k, k);
   end;
  end;
  PrintMessage(strings[S_Compl]);
  if (programID) and (((optWrite) = (0)) or ((optWrite) = (3))) then
  begin
   PrintMessage(strings[S_IDW]);
   if saveLog then
    fprintf(logfile, "Write ID\n");
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $8E;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $9C;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $26;
   bufferU[Inc(j)] := 3;
   for i := 0 to (3) - 1 do
   begin
    bufferU[Inc(j)] := memID[((i) * (2)) + (1)];
    bufferU[Inc(j)] := memID[(i) * (2)];
   end;
   bufferU[Inc(j)] := $27;
   bufferU[Inc(j)] := memID[((i) * (2)) + (1)];
   bufferU[Inc(j)] := memID[(i) * (2)];
   bufferU[Inc(j)] := (1000) shr (8);
   bufferU[Inc(j)] := (1000) and ($FF);
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
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
   PrintMessage(strings[S_Compl]);
  end;
  if (dim2) and (((optWrite) = (0)) or ((optWrite) = (3))) then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
    fprintf(logfile, "Write EEPROM\n");
   errEE := 0;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $9E;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $9C;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $84;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1337
     Original C:
       for (i = 0; (i < dim2) && (err <= max_err); i++)
       {
         if (memEE[i] != 0xFF)
         {
           bufferU[j++] = 0x21;
           bufferU[j++] = 0x0E;
           bufferU[j++] = i & 0xFF;
           bufferU[j++] = 0x21;
           bufferU[j++] = 0x6E;
           bufferU[j++] = (optWrite != 3) ? (0xA9) : (0x74);
           if (EEalgo == 0)
           {
             bufferU[j++] = 0x21;
             bufferU[j++] = 0x0E;
             bufferU[j++] = (i >> 8) & 0xFF;
             bufferU[j++] = 0x21;
             bufferU[j++] = 0x6E;
             bufferU[j++] = (optWrite != 3) ? (0xAA) : (0x75);
           }
           bufferU[j++] = 0x21;
           bufferU[j++] = 0x0E;
           bufferU[j++] = memEE[i];
           bufferU[j++] = 0x21;...
   *)
   // init: i = 0
   while ((i) < (dim2)) and ((err) <= (max_err)) do
   begin
    if (memEE[i]) <> ($FF) then
    begin
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := (i) and ($FF);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $6E;
     bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A9, $74);
     if (EEalgo) = (0) then
     begin
      bufferU[Inc(j)] := $21;
      bufferU[Inc(j)] := $0E;
      bufferU[Inc(j)] := ((i) shr (8)) and ($FF);
      bufferU[Inc(j)] := $21;
      bufferU[Inc(j)] := $6E;
      bufferU[Inc(j)] := IfThen((optWrite) <> (3), $AA, $75);
     end;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $0E;
     bufferU[Inc(j)] := memEE[i];
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $6E;
     bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A8, $73);
     if (EEalgo) = (1) then
     begin
      bufferU[Inc(j)] := $21;
      bufferU[Inc(j)] := $0E;
      bufferU[Inc(j)] := $55;
      bufferU[Inc(j)] := $21;
      bufferU[Inc(j)] := $6E;
      bufferU[Inc(j)] := $A7;
      bufferU[Inc(j)] := $21;
      bufferU[Inc(j)] := $0E;
      bufferU[Inc(j)] := $AA;
      bufferU[Inc(j)] := $21;
      bufferU[Inc(j)] := $6E;
      bufferU[Inc(j)] := $A7;
     end;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $82;
     bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $80;
     bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $50;
     bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A8, $73);
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $6E;
     bufferU[Inc(j)] := $F5;
     bufferU[Inc(j)] := $21;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := $22;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(8);
     sprintf(str, strings[S_CodeWriting], (((i) + (dim)) * (100)) div ((dim) + (dim2)), i);
     gtk_statusbar_push(status_bar, statusID, str);
     while gtk_events_pending() do
     begin
      gtk_main_iteration();
     end;
     if RWstop then
      i := dim2;
     j := 0;
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progP18.c:1402
       Original C:
         for (z = 64 - 1; z && (!((bufferI[z] == 0x22) && (bufferI[z - 1] == 0x21))); z--)
           ;
     *)
     // init: z = 64 - 1
     while (z) and (not (((bufferI[z]) = ($22)) and ((bufferI[(z) - (1)]) = ($21)))) do
     begin
       // step: z--
     end;
     if (z) and ((memEE[i]) <> (bufferI[(z) + (1)])) then
      Inc(errEE);
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
     // step: i++
   end;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
   err := err + errEE;
  end;
  PrintMessage(strings[S_CodeV]);
  if saveLog then
   fprintf(logfile, "VERIFY CODE\n");
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $8E;
  bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $9C;
  bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := $21;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, "\n\n");
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:1438
    Original C:
      for (i = 0, j = 0, k = 0; i < dim; i += 64 - 4)
      {
        i0 = i;
        for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (64 - 4))
        {
          for (k2 = 0; ((k2 < (64 - 4)) && (!valid)) && ((i + k2) < dim); k2++)
            if (memCODE[i + k2] < 0xFF)
            valid = 1;
      
        }
      
        if (i >= dim)
          break;
        if (i > i0)
        {
          bufferU[j++] = 0x21;
          bufferU[j++] = 0x0E;
          bufferU[j++] = (i >> 16) & 0xFF;
          bufferU[j++] = 0x21;
          bufferU[j++] = 0x6E;
          bufferU[j++] = 0xF8;
          bufferU[j++] = 0x21;
          bufferU[j++] = 0x0E;
          bufferU[j++] = (i >> 8) & 0xFF;
          bufferU[j++] = 0x21;
          bufferU[j++...
  *)
  // init: i = 0, j = 0, k = 0
  while (i) < (dim) do
  begin
   i0 := i;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1440
     Original C:
       for (valid = 0; (!valid) && (i < dim); i += (valid) ? (0) : (64 - 4))
       {
         for (k2 = 0; ((k2 < (64 - 4)) && (!valid)) && ((i + k2) < dim); k2++)
           if (memCODE[i + k2] < 0xFF)
           valid = 1;
       
       }
   *)
   // init: valid = 0
   while (not (valid)) and ((i) < (dim)) do
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP18.c:1441
      Original C:
        for (k2 = 0; ((k2 < (64 - 4)) && (!valid)) && ((i + k2) < dim); k2++)
          if (memCODE[i + k2] < 0xFF)
          valid = 1;
    *)
    // init: k2 = 0
    while (((k2) < ((64) - (4))) and (not (valid))) and (((i) + (k2)) < (dim)) do
    begin
     if (memCODE[(i) + (k2)]) < ($FF) then
      valid := 1;
      // step: k2++
    end;
     // step: i += (valid) ? (0) : (64 - 4)
   end;
   if (i) >= (dim) then
    Break;
   if (i) > (i0) then
   begin
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := ((i) shr (16)) and ($FF);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F8;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := ((i) shr (8)) and ($FF);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F7;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := (i) and ($FF);
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F6;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
   end;
   bufferU[Inc(j)] := $24;
   bufferU[Inc(j)] := IfThen((i) < ((dim) - ((64) - (4))), (64) - (4), (dim) - (i));
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   if (bufferI[1]) = ($24) then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP18.c:1474
      Original C:
        for (z = 0; (z < bufferI[2]) && (z < 64); z++)
        {
          if (memCODE[i + z] != bufferI[z + 3])
          {
            {
              sprintf(str, strings[S_CodeVError], i + z, i + z, memCODE[i + z], bufferI[z + 3]);
              PrintMessage(str);
            }
            ;
            err++;
          }
        }
    *)
    // init: z = 0
    while ((z) < (bufferI[2])) and ((z) < (64)) do
    begin
     if (memCODE[(i) + (z)]) <> (bufferI[(z) + (3)]) then
     begin
      sprintf(str, strings[S_CodeVError], (i) + (z), (i) + (z), memCODE[(i) + (z)], bufferI[(z) + (3)]);
      PrintMessage(str);
      Inc(err);
     end;
      // step: z++
    end;
   end;
   sprintf(str, strings[S_CodeV2], ((i) * (100)) div ((dim) + (dim2)), i);
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
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   if (err) >= (max_err) then
    Break;
    // step: i += 64 - 4
  end;
  if (i) < (dim) then
  begin
   sprintf(str, strings[S_CodeVError2], dim, i);
   PrintMessage(str);
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if (err) >= (max_err) then
  begin
   sprintf(str, strings[S_MaxErr], err);
   PrintMessage(str);
  end;
  if ((programID) and ((err) < (max_err))) and ((optWrite) = (0)) then
  begin
   PrintMessage(strings[S_IDV]);
   errID := 0;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $24;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1519
     Original C:
       for (z = 0; (bufferI[z] != 0x24) && (z < 64); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($24)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   for i := 0 to (8) - 1 do
   begin
    if ((memID[i]) <> ($FF)) and ((memID[i]) <> (bufferI[((z) + (i)) + (2)])) then
     Inc(errID);
   end;
   sprintf(str, strings[S_ComplErr], errID);
   PrintMessage(str);
   err := err + errID;
   if (err) >= (max_err) then
   begin
    sprintf(str, strings[S_MaxErr], err);
    PrintMessage(str);
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, 0, 0, err);
   end;
  end;
  if ((err) < (max_err)) and (((optWrite) = (0)) or ((optWrite) = (3))) then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
    fprintf(logfile, "Write CONFIG\n");
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $8E;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $8C;
   bufferU[Inc(j)] := IfThen((optWrite) <> (3), $A6, $7F);
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F6;
   for i := 0 to (14) - 1 do
   begin
    if (memCONFIG[i]) < ($FF) then
    begin
     bufferU[Inc(j)] := $27;
     bufferU[Inc(j)] := 0;
     bufferU[Inc(j)] := memCONFIG[i];
     bufferU[Inc(j)] := (5000) shr (8);
     bufferU[Inc(j)] := (5000) and ($FF);
    end;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $2A;
    bufferU[Inc(j)] := $F6;
    Inc(i);
    if (memCONFIG[i]) < ($FF) then
    begin
     bufferU[Inc(j)] := $27;
     bufferU[Inc(j)] := memCONFIG[i];
     bufferU[Inc(j)] := 0;
     bufferU[Inc(j)] := (5000) shr (8);
     bufferU[Inc(j)] := (5000) and ($FF);
    end;
    bufferU[Inc(j)] := $21;
    bufferU[Inc(j)] := $2A;
    bufferU[Inc(j)] := $F6;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(12);
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, 0, 0);
    end;
   end;
   PrintMessage(strings[S_Compl]);
   PrintMessage(strings[S_ConfigV]);
   errC := 0;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $30;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := $21;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := $24;
   bufferU[Inc(j)] := 14;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1604
     Original C:
       for (z = 0; (bufferI[z] != 0x24) && (z < (64 - 16)); z++)
         ;
   *)
   // init: z = 0
   while ((bufferI[z]) <> ($24)) and ((z) < ((64) - (16))) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (16)) then
   begin
    for i := 0 to (14) - 1 do
    begin
     if (not (memCONFIG[i])) and (bufferI[((z) + (i)) + (2)]) then
      Inc(errC);
    end;
   end;
   sprintf(str, strings[S_ComplErr], errC);
   PrintMessage(str);
   err := err + errC;
   if (err) >= (max_err) then
   begin
    sprintf(str, strings[S_MaxErr], err);
    PrintMessage(str);
   end;
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, 0, 0, err);
   end;
  end;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
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
  PacketIO(1);
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

function Read18FKx(dim: Integer; dim2: Integer; options: Integer): Pointer;
var
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  devID: Integer;
  devREV: Integer;
  MemAddr: Integer;
  EEaddr: Integer;
  DCIaddr: Integer;
  DIAaddr: Integer;
  DIAlen: Integer;
  UIDlen: Integer;
  CONFIGlen: Integer;
  CONFIGorg: Integer;
  type: Integer;
  vpp: Double;
  memDIA: PByte;
  start: Cardinal;
  stop: Cardinal;
begin
  k := 0;
  k2 := 0;
  z := 0;
  devID := 0;
  devREV := 0;
  EEaddr := 0;
  DCIaddr := 0;
  DIAaddr := 0;
  DIAlen := 0;
  UIDlen := 0;
  CONFIGlen := 0;
  CONFIGorg := 0;
  type := ((options) shr (4)) and ($F);
  if (type) = (0) then
  begin
   EEaddr := $310000;
   DCIaddr := $3FFF00;
   DIAaddr := $3F0000;
   DIAlen := $40;
   UIDlen := $10;
   CONFIGlen := 5;
   CONFIGorg := 0;
  end
  else
   if (type) = (1) then
   begin
    EEaddr := $380000;
    DCIaddr := $3C0000;
    DIAaddr := $2C0000;
    DIAlen := $100;
    UIDlen := $40;
    CONFIGlen := 10;
    CONFIGorg := 1;
   end
   else
    if (type) = (2) then
    begin
     EEaddr := $380000;
     DCIaddr := $3C0000;
     DIAaddr := $2C0000;
     DIAlen := $100;
     UIDlen := $40;
     CONFIGlen := 35;
     CONFIGorg := 1;
    end
    else
     if (type) = (3) then
     begin
      EEaddr := $310000;
      DCIaddr := 0;
      DIAaddr := 0;
      DIAlen := 0;
      UIDlen := 8;
      CONFIGlen := 6;
      CONFIGorg := 0;
     end
     else
      if (type) = (4) then
      begin
       EEaddr := $310000;
       DCIaddr := 0;
       DIAaddr := 0;
       DIAlen := 0;
       UIDlen := $100;
       CONFIGlen := 6;
       CONFIGorg := 0;
      end
      else
       if (type) = (5) then
       begin
        EEaddr := $380000;
        DCIaddr := $3C0000;
        DIAaddr := $2C0000;
        DIAlen := $100;
        UIDlen := $40;
        CONFIGlen := 26;
        CONFIGorg := 1;
       end
       else
        PrintMessage("unexpected parameter");
  if ((dim) > ($1FFFFF)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Read18FKx(%d,%d,%d)    (0x%X,0x%X,0x%X)\n", dim, dim2, options, dim, dim2, options);
  end;
  size := dim;
  if memCODE then
   free(memCODE);
  memCODE := malloc(size);
  memDIA := malloc(DIAlen);
  for j := 0 to (SizeOf(memID)) - 1 do
  begin
   memID[j] := $FF;
  end;
  for j := 0 to (48) - 1 do
  begin
   memCONFIG[j] := $FF;
  end;
  for j := 0 to (DIAlen) - 1 do
  begin
   memDIA[j] := $FF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (2000) shr (8);
  bufferU[Inc(j)] := (2000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $0A;
  MemAddr := ($3FFFFc) shl (1);
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (MemAddr) shr (16);
  bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
  bufferU[Inc(j)] := (MemAddr) and ($FF);
  bufferU[Inc(j)] := $58;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $58;
  bufferU[Inc(j)] := $FE;
  if (DCIaddr) > (0) then
  begin
   MemAddr := (DCIaddr) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
  end;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(4);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:1820
    Original C:
      for (z = 0; (bufferI[z] != 0x58) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   devREV := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:1824
    Original C:
      for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  end;
  sprintf(str, "DevID: 0x%04X\r\n", devID);
  PrintMessage(str);
  sprintf(str, "RevID: 0x%04X\r\n", devREV);
  PrintMessage(str);
  PIC18_ID((devID) + ((devREV) shl (16)));
  if (DCIaddr) > (0) then
  begin
   PrintMessage("Device Configuration Information:\r\n");
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1833
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "Erase row size: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1837
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "Write latches per row: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1841
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "User rows: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1845
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "EEPROM size: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
    sizeEE := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1850
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (3)) then
   begin
    sprintf(str, "Pin count: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
  end
  else
   sizeEE := dim2;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_CodeReading1]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:1861
    Original C:
      for (i = 0, j = 0; i < dim; i += 2)
      {
        bufferU[j++] = 0x58;
        bufferU[j++] = 0xFE;
        if ((((((j + 1) / 2) * 3) + 3) > 64) || (i == (dim - 2)))
        {
          bufferU[j++] = 0x04;
          for (; j < 64; j++)
            bufferU[j] = 0x0;
      
          PacketIO(5);
          for (z = 0; z < (64 - 2); z++)
          {
            if (bufferI[z] == 0x58)
            {
              memCODE[k++] = bufferI[z + 2];
              memCODE[k++] = bufferI[z + 1];
              z += 2;
            }
          }
      
          {
            sprintf(str, strings[S_CodeReading], (((((i + sizeEE) + 10) + UIDlen) + DIAlen) * 100) / ((((dim + sizeEE) + 10) + UIDlen) + DIAlen), i);
            gtk_statusbar_pus...
  *)
  // init: i = 0, j = 0
  while (i) < (dim) do
  begin
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((dim) - (2))) then
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
      memCODE[Inc(k)] := bufferI[(z) + (2)];
      memCODE[Inc(k)] := bufferI[(z) + (1)];
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((((((i) + (sizeEE)) + (10)) + (UIDlen)) + (DIAlen)) * (100)) div (((((dim) + (sizeEE)) + (10)) + (UIDlen)) + (DIAlen)), i);
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
    // step: i += 2
  end;
  if (k) <> (dim) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadCodeErr2], dim, k);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, "%s\n", strings[S_Read_CONFIG_A]);
  MemAddr := ($300000) shl (1);
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (MemAddr) shr (16);
  bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
  bufferU[Inc(j)] := (MemAddr) and ($FF);
  k2 := 0;
  for i := 0 to (CONFIGlen) - 1 do
  begin
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((CONFIGlen) - (1))) then
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
      memCONFIG[Inc(k2)] := bufferI[(z) + (2)];
      if (CONFIGorg) = (0) then
       memCONFIG[Inc(k2)] := bufferI[(z) + (1)];
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((((((dim) + (sizeEE)) + (i)) + (UIDlen)) + (DIAlen)) * (100)) div (((((dim) + (sizeEE)) + (CONFIGlen)) + (UIDlen)) + (DIAlen)), i);
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
  if (CONFIGorg) = (0) then
   CONFIGlen := CONFIGlen * 2;
  if (k2) <> (CONFIGlen) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadConfigErr], CONFIGlen, k2);
   PrintMessage(str);
  end
  else
   PrintMessage(strings[S_Compl]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, "Read user ID\n");
  MemAddr := ($200000) shl (1);
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (MemAddr) shr (16);
  bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
  bufferU[Inc(j)] := (MemAddr) and ($FF);
  k2 := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:1938
    Original C:
      for (i = 0; i < UIDlen; i += 2)
      {
        bufferU[j++] = 0x58;
        bufferU[j++] = 0xFE;
        if ((((((j + 1) / 2) * 3) + 3) > 64) || (i == (UIDlen - 2)))
        {
          bufferU[j++] = 0x04;
          for (; j < 64; j++)
            bufferU[j] = 0x0;
      
          PacketIO(5);
          for (z = 0; z < (64 - 2); z++)
          {
            if (bufferI[z] == 0x58)
            {
              memID[k2++] = bufferI[z + 2];
              memID[k2++] = bufferI[z + 1];
              z += 2;
            }
          }
      
          {
            sprintf(str, strings[S_CodeReading], (((((dim + sizeEE) + 10) + i) + DIAlen) * 100) / ((((dim + sizeEE) + 10) + UIDlen) + DIAlen), i);
            gtk_statusbar_push((Gtk...
  *)
  // init: i = 0
  while (i) < (UIDlen) do
  begin
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((UIDlen) - (2))) then
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
      memID[Inc(k2)] := bufferI[(z) + (2)];
      memID[Inc(k2)] := bufferI[(z) + (1)];
      z := z + 2;
     end;
    end;
    sprintf(str, strings[S_CodeReading], ((((((dim) + (sizeEE)) + (10)) + (i)) + (DIAlen)) * (100)) div (((((dim) + (sizeEE)) + (10)) + (UIDlen)) + (DIAlen)), i);
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
    // step: i += 2
  end;
  if (k2) <> (UIDlen) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ReadConfigErr], UIDlen, k2);
   PrintMessage(str);
  end;
  if (DIAaddr) > (0) then
  begin
   if saveLog then
    fprintf(logfile, strings[S_sepLine]);
   if saveLog then
    fprintf(logfile, "Read device info area\n");
   MemAddr := (DIAaddr) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   k2 := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:1975
     Original C:
       for (i = 0; i < DIAlen; i += 2)
       {
         bufferU[j++] = 0x58;
         bufferU[j++] = 0xFE;
         if ((((((j + 1) / 2) * 3) + 3) > 64) || (i == (DIAlen - 2)))
         {
           bufferU[j++] = 0x04;
           for (; j < 64; j++)
             bufferU[j] = 0x0;
       
           PacketIO(5);
           for (z = 0; z < (64 - 2); z++)
           {
             if (bufferI[z] == 0x58)
             {
               memDIA[k2++] = bufferI[z + 2];
               memDIA[k2++] = bufferI[z + 1];
               z += 2;
             }
           }
       
           {
             sprintf(str, strings[S_CodeReading], (((((dim + sizeEE) + 10) + UIDlen) + i) * 100) / ((((dim + sizeEE) + 10) + UIDlen) + DIAlen), i);
             gtk_statusbar_push((G...
   *)
   // init: i = 0
   while (i) < (DIAlen) do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((DIAlen) - (2))) then
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
       memDIA[Inc(k2)] := bufferI[(z) + (2)];
       memDIA[Inc(k2)] := bufferI[(z) + (1)];
       z := z + 2;
      end;
     end;
     sprintf(str, strings[S_CodeReading], ((((((dim) + (sizeEE)) + (10)) + (UIDlen)) + (i)) * (100)) div (((((dim) + (sizeEE)) + (10)) + (UIDlen)) + (DIAlen)), i);
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
     // step: i += 2
   end;
   if (k2) <> (DIAlen) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ReadConfigErr], DIAlen, k2);
    PrintMessage(str);
   end;
  end;
  if dim2 then
  begin
   if ((sizeEE) > ($1000)) or ((sizeEE) < (0)) then
   begin
    PrintMessage(strings[S_EELim]);
    Exit;
   end;
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
    fprintf(logfile, "%s\n", strings[S_ReadEE]);
   MemAddr := (EEaddr) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   for i := (k := 0) to (sizeEE) - 1 do
   begin
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((sizeEE) - (1))) then
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
     sprintf(str, strings[S_CodeReading], ((((((dim) + (i)) + (10)) + (UIDlen)) + (DIAlen)) * (100)) div (((((dim) + (sizeEE)) + (10)) + (UIDlen)) + (DIAlen)), i);
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
   if (k) <> (sizeEE) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ReadEEErr], sizeEE, k);
    PrintMessage(str);
   end
   else
    PrintMessage(strings[S_Compl]);
  end;
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
  PacketIO(1);
  stop := GetTickCount();
  gtk_statusbar_push(status_bar, statusID, "");
  PrintMessage(strings[S_ConfigMem]);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:2061
    Original C:
      for (i = 0; i < UIDlen; i += 2)
      {
        if ((memID[i] < 0xFF) || (memID[i + 1] < 0xFF))
        {
          sprintf(str, strings[S_ChipID2], i, memID[i], i + 1, memID[i + 1]);
          PrintMessage(str);
        }
        ;
      }
  *)
  // init: i = 0
  while (i) < (UIDlen) do
  begin
   if ((memID[i]) < ($FF)) or ((memID[(i) + (1)]) < ($FF)) then
   begin
    sprintf(str, strings[S_ChipID2], i, memID[i], (i) + (1), memID[(i) + (1)]);
    PrintMessage(str);
   end;
    // step: i += 2
  end;
  if (CONFIGorg) = (0) then
  begin
   for i := 0 to (CONFIGlen) - 1 do
   begin
    sprintf(str, strings[S_ConfigWordH], (i) + (1), memCONFIG[((i) * (2)) + (1)]);
    PrintMessage(str);
    sprintf(str, strings[S_ConfigWordL], (i) + (1), memCONFIG[(i) * (2)]);
    PrintMessage(str);
   end;
  end
  else
  begin
   for i := 0 to (CONFIGlen) - 1 do
   begin
    if ((type) = (5)) and (((i) >= ($B)) and ((i) <= ($17))) then
    else
    begin
     sprintf(str, "CONFIG%d: 0x%02X\r\n", (i) + (1), memCONFIG[i]);
     PrintMessage(str);
    end;
   end;
  end;
  PrintMessage(strings[S_CodeMem]);
  DisplayCODE18F(dim);
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

function Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  x: Integer;
  w: Integer;
  err: Integer;
  devID: Integer;
  devREV: Integer;
  MemAddr: Integer;
  rowN: Integer;
  EEaddr: Integer;
  DCIaddr: Integer;
  DIAaddr: Integer;
  DIAlen: Integer;
  UIDlen: Integer;
  CONFIGlen: Integer;
  CONFIGorg: Integer;
  delayErase: Integer;
  delayWrite: Integer;
  delayWriteConfig: Integer;
  type: Integer;
  vpp: Double;
  start: Cardinal;
  valid: Integer;
  errEE: Integer;
  errID: Integer;
  errC: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  x := 0;
  w := 0;
  err := 0;
  devID := 0;
  devREV := 0;
  rowN := 0;
  EEaddr := 0;
  DCIaddr := 0;
  DIAaddr := 0;
  DIAlen := 0;
  UIDlen := 0;
  CONFIGlen := 0;
  CONFIGorg := 0;
  delayErase := 0;
  delayWrite := 0;
  delayWriteConfig := 0;
  type := ((options) shr (4)) and ($F);
  if (type) = (0) then
  begin
   EEaddr := $310000;
   DCIaddr := $3FFF00;
   DIAaddr := $3F0000;
   DIAlen := $40;
   UIDlen := $10;
   CONFIGlen := 5;
   CONFIGorg := 0;
   delayErase := 25500;
   delayWrite := 2800;
   delayWriteConfig := 5600;
  end
  else
   if (type) = (1) then
   begin
    EEaddr := $380000;
    DCIaddr := $3C0000;
    DIAaddr := $2C0000;
    DIAlen := $100;
    UIDlen := $40;
    CONFIGlen := 10;
    CONFIGorg := 1;
    delayErase := 11500;
    delayWriteConfig := 11000;
   end
   else
    if (type) = (2) then
    begin
     EEaddr := $380000;
     DCIaddr := $3C0000;
     DIAaddr := $2C0000;
     DIAlen := $100;
     UIDlen := $40;
     CONFIGlen := 35;
     CONFIGorg := 1;
     delayErase := 11500;
     delayWriteConfig := 11000;
    end
    else
     if (type) = (3) then
     begin
      EEaddr := $310000;
      DCIaddr := 0;
      DIAaddr := 0;
      DIAlen := 0;
      UIDlen := 8;
      CONFIGlen := 6;
      CONFIGorg := 0;
      rowN := 32;
      delayErase := 25500;
      delayWrite := 2800;
      delayWriteConfig := 5600;
     end
     else
      if (type) = (4) then
      begin
       EEaddr := $310000;
       DCIaddr := 0;
       DIAaddr := 0;
       DIAlen := 0;
       UIDlen := $100;
       CONFIGlen := 6;
       CONFIGorg := 2;
       delayErase := 75500;
       delayWrite := 11000;
       delayWriteConfig := 11000;
      end
      else
       if (type) = (5) then
       begin
        EEaddr := $380000;
        DCIaddr := $3C0000;
        DIAaddr := $2C0000;
        DIAlen := $100;
        UIDlen := $40;
        CONFIGlen := 11;
        CONFIGorg := 1;
        delayErase := 11500;
        delayWriteConfig := 11000;
       end
       else
        PrintMessage("unexpected parameter");
  if ((dim) > ($1FFFFF)) or ((dim) < (0)) then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if ((dim2) > ($800)) or ((dim2) < (0)) then
  begin
   PrintMessage(strings[S_EELim]);
   Exit;
  end;
  if not (CheckV33Regulator()) then
  begin
   PrintMessage(strings[S_noV33reg]);
   Exit;
  end;
  vpp := 8.5;
  if not (StartHVReg(vpp)) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Write18FKx(%d,%d,%d)    (0x%X,0x%X,0x%X)\n", dim, dim2, options, dim, dim2, options);
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
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 35;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := (11000) shr (8);
  bufferU[Inc(j)] := (11000) and ($ff);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $0A;
  MemAddr := ($3FFFFc) shl (1);
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := (MemAddr) shr (16);
  bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
  bufferU[Inc(j)] := (MemAddr) and ($FF);
  bufferU[Inc(j)] := $58;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := $58;
  bufferU[Inc(j)] := $FE;
  if (DCIaddr) > (0) then
  begin
   MemAddr := (DCIaddr) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
   bufferU[Inc(j)] := $58;
   bufferU[Inc(j)] := $FE;
  end;
  bufferU[Inc(j)] := $39;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(14);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:2267
    Original C:
      for (z = 0; (bufferI[z] != 0x58) && (z < 64); z++)
        ;
  *)
  // init: z = 0
  while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   devREV := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP18.c:2271
    Original C:
      for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
        ;
  *)
  // init: z += 3
  while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
  begin
   devID := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  end;
  sprintf(str, "DevID: 0x%04X\r\n", devID);
  PrintMessage(str);
  sprintf(str, "RevID: 0x%04X\r\n", devREV);
  PrintMessage(str);
  PIC18_ID((devID) + ((devREV) shl (16)));
  if (DCIaddr) > (0) then
  begin
   PrintMessage("Device Configuration Information:\r\n");
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2280
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "Erase row size: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2284
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    rowN := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
    sprintf(str, "Write latches per row: %d\r\n", rowN);
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2289
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "User rows: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2293
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
   begin
    sprintf(str, "EEPROM size: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2298
     Original C:
       for (z += 3; (bufferI[z] != 0x58) && (z < 64); z++)
         ;
   *)
   // init: z += 3
   while ((bufferI[z]) <> ($58)) and ((z) < (64)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (3)) then
   begin
    sprintf(str, "Pin count: %d\r\n", ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
    PrintMessage(str);
   end;
  end;
  j := 0;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
  begin
   fprintf(logfile, strings[S_sepLine]);
   fprintf(logfile, strings[S_StartErase]);
   fprintf(logfile, strings[S_NL]);
  end;
  if (((type) = (0)) or ((type) = (3))) or ((type) = (4)) then
  begin
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (delayErase) shr (8);
   bufferU[Inc(j)] := (delayErase) and ($ff);
   MemAddr := ($300000) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   bufferU[Inc(j)] := $57;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   MemAddr := ($310000) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   bufferU[Inc(j)] := $57;
   bufferU[Inc(j)] := $18;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $07;
   bufferU[Inc(j)] := 1;
   bufferU[Inc(j)] := (delayWrite) shr (8);
   bufferU[Inc(j)] := (delayWrite) and ($ff);
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(((delayErase) div (1000)) * (2));
  end
  else
   if (((type) = (1)) or ((type) = (2))) or ((type) = (5)) then
   begin
    bufferU[Inc(j)] := $59;
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := 0;
    bufferU[Inc(j)] := $F;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := (delayWriteConfig) shr (8);
    bufferU[Inc(j)] := (delayWriteConfig) and ($ff);
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(1);
    msDelay((delayErase) div (1000));
   end;
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  if saveLog then
  begin
   fprintf(logfile, strings[S_sepLine]);
   fprintf(logfile, "WRITE CODE\ndim=%d(0x%X)\n", dim, dim);
  end;
  if ((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)) then
  begin
   j := 0;
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2378
     Original C:
       for (i = (k = 0); i < dim; i += 2)
       {
         if ((memCODE[i] < 0xFF) || (memCODE[i + 1] < 0xFF))
         {
           bufferU[j++] = 0x59;
           bufferU[j++] = 0xC0;
           bufferU[j++] = memCODE[i + 1];
           bufferU[j++] = memCODE[i];
           bufferU[j++] = 0x09;
           bufferU[j++] = 0x58;
           bufferU[j++] = 0xFE;
         }
         else
         {
           for (x = 0; (((i + x) < dim) && (memCODE[i + x] == 0xFF)) && (memCODE[(i + x) + 1] == 0xFF); x += 2)
             ;
       
           if (x > 9)
           {
             i += x;
             MemAddr = i << 1;
             bufferU[j++] = 0x39;
             bufferU[j++] = 2;
             bufferU[j++] = 0x80;
             bufferU[j++] = MemAddr >> 16;
             buffer...
   *)
   // init: i = (k = 0)
   while (i) < (dim) do
   begin
    if ((memCODE[i]) < ($FF)) or ((memCODE[(i) + (1)]) < ($FF)) then
    begin
     bufferU[Inc(j)] := $59;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := memCODE[(i) + (1)];
     bufferU[Inc(j)] := memCODE[i];
     bufferU[Inc(j)] := $09;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $FE;
    end
    else
    begin
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progP18.c:2389
       Original C:
         for (x = 0; (((i + x) < dim) && (memCODE[i + x] == 0xFF)) && (memCODE[(i + x) + 1] == 0xFF); x += 2)
           ;
     *)
     // init: x = 0
     while ((((i) + (x)) < (dim)) and ((memCODE[(i) + (x)]) = ($FF))) and ((memCODE[((i) + (x)) + (1)]) = ($FF)) do
     begin
       // step: x += 2
     end;
     if (x) > (9) then
     begin
      i := i + x;
      MemAddr := (i) shl (1);
      bufferU[Inc(j)] := $39;
      bufferU[Inc(j)] := 2;
      bufferU[Inc(j)] := $80;
      bufferU[Inc(j)] := (MemAddr) shr (16);
      bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
      bufferU[Inc(j)] := (MemAddr) and ($FF);
      i := i - 2;
     end
     else
     begin
      bufferU[Inc(j)] := $57;
      bufferU[Inc(j)] := $F8;
     end;
    end;
    if ((j) > ((64) - (8))) or ((i) = ((dim) - (2))) then
    begin
     sprintf(str, strings[S_CodeWriting], ((i) * (100)) div ((dim) + (dim2)), i);
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
     PacketIO(2);
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if (((bufferI[z]) = ($57)) and ((memCODE[k]) = ($ff))) and ((memCODE[(k) + (1)]) = ($ff)) then
       k := k + 2;
      else
       if (bufferI[z]) = ($39) then
       begin
        while (((k) < (dim)) and ((memCODE[k]) = ($FF))) and ((memCODE[(k) + (1)]) = ($FF)) do
        begin
         (k := 2);
        end;
       end
       else
        if ((bufferI[z]) = ($59)) and ((bufferI[(z) + (2)]) = ($58)) then
        begin
         if ((memCODE[k]) <> (bufferI[(z) + (4)])) or ((memCODE[(k) + (1)]) <> (bufferI[(z) + (3)])) then
         begin
          PrintMessage("\r\n");
          sprintf(str, strings[S_CodeWError2], k, ((memCODE[(k) + (1)]) shl (8)) + (memCODE[k]), ((bufferI[(z) + (3)]) shl (8)) + (bufferI[(z) + (4)]));
          PrintMessage(str);
          Inc(err);
          if (max_err) and ((err) > (max_err)) then
          begin
           sprintf(str, strings[S_MaxErr], err);
           PrintMessage(str);
           i := dim;
           z := 64;
          end;
         end;
         k := k + 2;
         z := z + 4;
        end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, err);
     end;
    end;
     // step: i += 2
   end;
   err := err + (i) - (k);
  end
  else
   if ((type) = (0)) or ((type) = (3)) then
   begin
    while (((dim) > (0)) and ((memCODE[(dim) - (1)]) = ($ff))) and ((memCODE[(dim) - (2)]) = ($ff)) do
    begin
     (dim := 2);
    end;
    if (dim) mod (rowN) then
     dim := dim + (rowN) - ((dim) mod (rowN));
    if (dim) > (size) then
    begin
     memCODE := realloc(memCODE, dim);
     while (size) < (dim) do
     begin
      memCODE[size] := $FF;
      Inc(size);
     end;
    end;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP18.c:2447
      Original C:
        for (i = (k = 0), j = 0; i < dim; i += rowN)
        {
          for (valid = 0; (i < dim) && (!valid); i += (valid) ? (0) : (rowN))
          {
            valid = 0;
            for (k = 0; k < rowN; k++)
            {
              if (memCODE[i + k] < 0xff)
              {
                valid = 1;
                k = rowN;
              }
            }
        
          }
        
          MemAddr = i << 1;
          bufferU[j++] = 0x39;
          bufferU[j++] = 2;
          bufferU[j++] = 0x80;
          bufferU[j++] = MemAddr >> 16;
          bufferU[j++] = (MemAddr >> 8) & 0xFF;
          bufferU[j++] = MemAddr & 0xFF;
          for (k = 0; k < rowN; k += 2)
          {
            bufferU[j++] = 0x59;
            bufferU[j++] = (k < (rowN - 2)) ? (0x02) : (0x00);
            bufferU[j++] = mem...
    *)
    // init: i = (k = 0), j = 0
    while (i) < (dim) do
    begin
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progP18.c:2448
       Original C:
         for (valid = 0; (i < dim) && (!valid); i += (valid) ? (0) : (rowN))
         {
           valid = 0;
           for (k = 0; k < rowN; k++)
           {
             if (memCODE[i + k] < 0xff)
             {
               valid = 1;
               k = rowN;
             }
           }
         
         }
     *)
     // init: valid = 0
     while ((i) < (dim)) and (not (valid)) do
     begin
      valid := 0;
      for k := 0 to (rowN) - 1 do
      begin
       if (memCODE[(i) + (k)]) < ($ff) then
       begin
        valid := 1;
        k := rowN;
       end;
      end;
       // step: i += (valid) ? (0) : (rowN)
     end;
     MemAddr := (i) shl (1);
     bufferU[Inc(j)] := $39;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $80;
     bufferU[Inc(j)] := (MemAddr) shr (16);
     bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
     bufferU[Inc(j)] := (MemAddr) and ($FF);
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/progP18.c:2464
       Original C:
         for (k = 0; k < rowN; k += 2)
         {
           bufferU[j++] = 0x59;
           bufferU[j++] = (k < (rowN - 2)) ? (0x02) : (0x00);
           bufferU[j++] = memCODE[(i + k) + 1];
           bufferU[j++] = memCODE[i + k];
           if (j > (64 - 5))
           {
             bufferU[j++] = 0x04;
             for (; j < 64; j++)
               bufferU[j] = 0x0;
         
             PacketIO(2);
             j = 0;
           }
         }
     *)
     // init: k = 0
     while (k) < (rowN) do
     begin
      bufferU[Inc(j)] := $59;
      bufferU[Inc(j)] := IfThen((k) < ((rowN) - (2)), $02, $00);
      bufferU[Inc(j)] := memCODE[((i) + (k)) + (1)];
      bufferU[Inc(j)] := memCODE[(i) + (k)];
      if (j) > ((64) - (5)) then
      begin
       bufferU[Inc(j)] := $04;
       while (j) < (64) do
       begin
        bufferU[j] := $0;
        Inc(j);
       end;
       PacketIO(2);
       j := 0;
      end;
       // step: k += 2
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
      PacketIO(6);
      j := 0;
      if saveLog then
      begin
       fprintf(logfile, strings[S_Log7], i, i, 0, 0);
      end;
      sprintf(str, strings[S_CodeWriting], ((i) * (100)) div (((dim) * (2)) + (dim2)), i);
      gtk_statusbar_push(status_bar, statusID, str);
      while gtk_events_pending() do
      begin
       gtk_main_iteration();
      end;
     end;
      // step: i += rowN
    end;
    PrintMessage(strings[S_Compl]);
    PrintMessage(strings[S_CodeV]);
    if saveLog then
    begin
     fprintf(logfile, strings[S_sepLine]);
     fprintf(logfile, "%s\n", strings[S_CodeV]);
    end;
    j := 0;
    bufferU[Inc(j)] := $39;
    bufferU[Inc(j)] := 2;
    bufferU[Inc(j)] := $80;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $0;
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(2);
    j := 0;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP18.c:2510
      Original C:
        for (i = (k = 0); i < dim; i += 2)
        {
          if (j == 0)
          {
            for (x = 0; (((i + x) < dim) && (memCODE[i + x] == 0xFF)) && (memCODE[(i + x) + 1] == 0xFF); x += 2)
              ;
        
            if (x > 9)
            {
              i += x;
              k = i;
              MemAddr = i << 1;
              bufferU[j++] = 0x39;
              bufferU[j++] = 2;
              bufferU[j++] = 0x80;
              bufferU[j++] = MemAddr >> 16;
              bufferU[j++] = (MemAddr >> 8) & 0xFF;
              bufferU[j++] = MemAddr & 0xFF;
            }
          }
          bufferU[j++] = 0x58;
          bufferU[j++] = 0xFE;
          if ((((((j + 1) / 2) * 3) + 3) > 64) || (i == (dim - 2)))
          {
            bufferU[j++] = 0x04;
            for (; j < 64; ...
    *)
    // init: i = (k = 0)
    while (i) < (dim) do
    begin
     if (j) = (0) then
     begin
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/progP18.c:2512
        Original C:
          for (x = 0; (((i + x) < dim) && (memCODE[i + x] == 0xFF)) && (memCODE[(i + x) + 1] == 0xFF); x += 2)
            ;
      *)
      // init: x = 0
      while ((((i) + (x)) < (dim)) and ((memCODE[(i) + (x)]) = ($FF))) and ((memCODE[((i) + (x)) + (1)]) = ($FF)) do
      begin
        // step: x += 2
      end;
      if (x) > (9) then
      begin
       i := i + x;
       k := i;
       MemAddr := (i) shl (1);
       bufferU[Inc(j)] := $39;
       bufferU[Inc(j)] := 2;
       bufferU[Inc(j)] := $80;
       bufferU[Inc(j)] := (MemAddr) shr (16);
       bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
       bufferU[Inc(j)] := (MemAddr) and ($FF);
      end;
     end;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $FE;
     if ((((((j) + (1)) div (2)) * (3)) + (3)) > (64)) or ((i) = ((dim) - (2))) then
     begin
      bufferU[Inc(j)] := $04;
      while (j) < (64) do
      begin
       bufferU[j] := $0;
       Inc(j);
      end;
      PacketIO(2);
      for z := 0 to ((64) - (2)) - 1 do
      begin
       if (bufferI[z]) = ($58) then
       begin
        if ((memCODE[k]) <> (bufferI[(z) + (2)])) or ((memCODE[(k) + (1)]) <> (bufferI[(z) + (1)])) then
        begin
         sprintf(str, strings[S_CodeWError2], k, (memCODE[k]) + ((memCODE[(k) + (1)]) shl (8)), ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
         PrintMessage(str);
         Inc(err);
        end;
        z := z + 2;
        k := k + 2;
       end;
      end;
      sprintf(str, strings[S_CodeV2], (((i) + (dim)) div (((dim) * (2)) + (dim2))) * (100), i);
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
      begin
       sprintf(str, strings[S_MaxErr], err);
       PrintMessage(str);
       i := dim;
      end;
     end;
      // step: i += 2
    end;
    bufferU[Inc(j)] := $07;
    bufferU[Inc(j)] := 1;
    bufferU[Inc(j)] := (delayWriteConfig) shr (8);
    bufferU[Inc(j)] := (delayWriteConfig) and ($ff);
    bufferU[Inc(j)] := $04;
    while (j) < (64) do
    begin
     bufferU[j] := $0;
     Inc(j);
    end;
    PacketIO(1);
    j := 0;
   end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, "WRITE EEPROM\ndim2=%d(0x%X)\n", dim2, dim2);
   end;
   errEE := 0;
   j := 0;
   MemAddr := (EEaddr) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   for i := (k := 0) to (dim2) - 1 do
   begin
    if (memEE[i]) < ($FF) then
    begin
     if ((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)) then
     begin
      bufferU[Inc(j)] := $59;
      bufferU[Inc(j)] := $C0;
      bufferU[Inc(j)] := 0;
      bufferU[Inc(j)] := memEE[i];
     end
     else
      if ((type) = (0)) or ((type) = (3)) then
      begin
       bufferU[Inc(j)] := $59;
       bufferU[Inc(j)] := $00;
       bufferU[Inc(j)] := 0;
       bufferU[Inc(j)] := memEE[i];
       bufferU[Inc(j)] := $57;
       bufferU[Inc(j)] := $E0;
      end;
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
    if ((j) > ((64) - (8))) or ((i) = ((dim2) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], (((i) + (dim)) * (100)) div ((dim) + (dim2)), (i) + (EEaddr));
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
     w := (w) * ((delayWriteConfig) div (1000.0));
     PacketIO((w) + (10));
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if ((bufferI[z]) = ($57)) and ((memEE[k]) = ($ff)) then
       Inc(k);
      else
       if (bufferI[z]) = ($59) then
       begin
        w := IfThen(((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)), bufferI[(z) + (4)], bufferI[(z) + (5)]);
        if (memEE[k]) <> (w) then
        begin
         PrintMessage("\r\n");
         sprintf(str, strings[S_CodeWError2], k, memEE[k], w);
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
        z := z + IfThen(((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)), 4, 5);
       end;
     end;
     j := 0;
     w := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errEE);
     end;
    end;
   end;
   errEE := errEE + (i) - (k);
   err := err + errEE;
   sprintf(str, strings[S_ComplErr], errEE);
   PrintMessage(str);
  end;
  if programID then
  begin
   PrintMessage(strings[S_IDW]);
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, "Write ID\n");
   end;
   errID := 0;
   j := 0;
   MemAddr := ($200000) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP18.c:2659
     Original C:
       for (i = (k = 0); i < UIDlen; i += 2)
       {
         if ((memID[i] < 0xFF) || (memID[i + 1] < 0xFF))
         {
           if ((((type == 1) || (type == 2)) || (type == 4)) || (type == 5))
           {
             bufferU[j++] = 0x59;
             bufferU[j++] = 0xC0;
             bufferU[j++] = memID[i + 1];
             bufferU[j++] = memID[i];
           }
           else
             if ((type == 0) || (type == 3))
           {
             bufferU[j++] = 0x59;
             bufferU[j++] = 0x00;
             bufferU[j++] = memID[i + 1];
             bufferU[j++] = memID[i];
             bufferU[j++] = 0x57;
             bufferU[j++] = 0xE0;
           }
           bufferU[j++] = 0x0A;
           bufferU[j++] = 0x58;
           bufferU[j++] = 0x...
   *)
   // init: i = (k = 0)
   while (i) < (UIDlen) do
   begin
    if ((memID[i]) < ($FF)) or ((memID[(i) + (1)]) < ($FF)) then
    begin
     if ((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)) then
     begin
      bufferU[Inc(j)] := $59;
      bufferU[Inc(j)] := $C0;
      bufferU[Inc(j)] := memID[(i) + (1)];
      bufferU[Inc(j)] := memID[i];
     end
     else
      if ((type) = (0)) or ((type) = (3)) then
      begin
       bufferU[Inc(j)] := $59;
       bufferU[Inc(j)] := $00;
       bufferU[Inc(j)] := memID[(i) + (1)];
       bufferU[Inc(j)] := memID[i];
       bufferU[Inc(j)] := $57;
       bufferU[Inc(j)] := $E0;
      end;
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $FE;
    end
    else
    begin
     bufferU[Inc(j)] := $57;
     bufferU[Inc(j)] := $F8;
    end;
    if ((j) > ((64) - (8))) or ((i) = ((UIDlen) - (2))) then
    begin
     sprintf(str, strings[S_CodeWriting], 99, ($200000) + (i));
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
     PacketIO((((9) * (delayWriteConfig)) div (1000)) + (2));
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if (((bufferI[z]) = ($57)) and ((memID[k]) = ($ff))) and ((memID[(k) + (1)]) = ($ff)) then
       k := k + 2;
      else
       if (bufferI[z]) = ($59) then
       begin
        if ((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)) then
         w := ((bufferI[(z) + (3)]) shl (8)) + (bufferI[(z) + (4)]);
        else
         if ((type) = (0)) or ((type) = (3)) then
          w := ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]);
        x := ((memID[(k) + (1)]) shl (8)) + (memID[k]);
        if (x) <> (w) then
        begin
         PrintMessage("\r\n");
         sprintf(str, strings[S_CodeWError2], k, x, w);
         PrintMessage(str);
         Inc(errID);
         if (max_err) and (((err) + (errID)) > (max_err)) then
         begin
          sprintf(str, strings[S_MaxErr], (err) + (errID));
          PrintMessage(str);
          PrintMessage(strings[S_IntW]);
          i := UIDlen;
          z := 64;
         end;
        end;
        k := k + 2;
        z := z + IfThen(((((type) = (1)) or ((type) = (2))) or ((type) = (4))) or ((type) = (5)), 4, 5);
       end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errID);
     end;
    end;
     // step: i += 2
   end;
   errID := errID + (i) - (k);
   err := err + errID;
   sprintf(str, strings[S_ComplErr], errID);
   PrintMessage(str);
  end;
  if (err) < (max_err) then
  begin
   PrintMessage(strings[S_ConfigW]);
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, "Write CONFIG\n");
   end;
   errC := 0;
   j := 0;
   MemAddr := ($300000) shl (1);
   bufferU[Inc(j)] := $39;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := (MemAddr) shr (16);
   bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
   bufferU[Inc(j)] := (MemAddr) and ($FF);
   for i := (k := 0) to (CONFIGlen) - 1 do
   begin
    if (CONFIGorg) = (0) then
    begin
     bufferU[Inc(j)] := $59;
     bufferU[Inc(j)] := $00;
     bufferU[Inc(j)] := memCONFIG[((i) * (2)) + (1)];
     bufferU[Inc(j)] := memCONFIG[(i) * (2)];
     bufferU[Inc(j)] := $57;
     bufferU[Inc(j)] := $E0;
    end
    else
     if (CONFIGorg) = (1) then
     begin
      bufferU[Inc(j)] := $59;
      bufferU[Inc(j)] := $C0;
      bufferU[Inc(j)] := 0;
      bufferU[Inc(j)] := memCONFIG[i];
     end
     else
      if (CONFIGorg) = (2) then
      begin
       bufferU[Inc(j)] := $59;
       bufferU[Inc(j)] := $C0;
       bufferU[Inc(j)] := memCONFIG[((i) * (2)) + (1)];
       bufferU[Inc(j)] := memCONFIG[(i) * (2)];
      end;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $58;
    bufferU[Inc(j)] := $FE;
    if ((j) > ((64) - (8))) or ((i) = ((CONFIGlen) - (1))) then
    begin
     sprintf(str, strings[S_CodeWriting], 99, (i) + ($300000));
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
     PacketIO((((9) * (delayWriteConfig)) div (1000.0)) + (2));
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if (bufferI[z]) = ($59) then
      begin
       if (CONFIGorg) = (1) then
       begin
        w := bufferI[(z) + (4)];
        x := memCONFIG[k];
       end
       else
        if (CONFIGorg) = (2) then
        begin
         w := ((bufferI[(z) + (3)]) shl (8)) + (bufferI[(z) + (4)]);
         x := ((memCONFIG[(k) + (1)]) shl (8)) + (memCONFIG[k]);
        end
        else
         if (CONFIGorg) = (0) then
         begin
          w := ((bufferI[(z) + (4)]) shl (8)) + (bufferI[(z) + (5)]);
          x := ((memCONFIG[(k) + (1)]) shl (8)) + (memCONFIG[k]);
         end;
       if (not (x)) and (w) then
       begin
        PrintMessage("\r\n");
        sprintf(str, strings[S_CodeWError2], (k) + ($300000), x, w);
        PrintMessage(str);
        Inc(errC);
        if (max_err) and (((err) + (errC)) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], (err) + (errC));
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim2;
         z := 64;
        end;
       end;
       if (CONFIGorg) = (1) then
       begin
        Inc(k);
        z := z + 4;
       end
       else
        if (CONFIGorg) = (2) then
        begin
         k := k + 2;
         z := z + 4;
        end
        else
         if (CONFIGorg) = (0) then
         begin
          k := k + 2;
          z := z + 5;
         end;
      end;
     end;
     j := 0;
     if saveLog then
     begin
      fprintf(logfile, strings[S_Log8], i, i, k, k, errC);
     end;
    end;
   end;
   if (CONFIGorg) = (1) then
    errC := errC + (CONFIGlen) - (k);
   else
    errC := errC + ((CONFIGlen) * (2)) - (k);
   err := err + errC;
   if (((useSAFLOCK_flag) and ((type) = (5))) and ((memCONFIG[$18]) <> ($FF))) and ((err) > (0)) then
    PrintMessage(strings[S_SkipSaflock]);
   if (((useSAFLOCK_flag) and ((type) = (5))) and ((memCONFIG[$18]) <> ($FF))) and ((err) = (0)) then
   begin
    PrintMessage("\r\nWrite SAFLOCK");
    if saveLog then
    begin
     fprintf(logfile, strings[S_sepLine]);
     fprintf(logfile, "Write SAFLOCK\n");
    end;
    errC := 0;
    if (memCONFIG[$19]) <> ($FF) then
    begin
     errC := 1;
     j := 0;
     MemAddr := ($300019) shl (1);
     bufferU[Inc(j)] := $39;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $80;
     bufferU[Inc(j)] := (MemAddr) shr (16);
     bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
     bufferU[Inc(j)] := (MemAddr) and ($FF);
     bufferU[Inc(j)] := $59;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := 0;
     bufferU[Inc(j)] := memCONFIG[$19];
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $FE;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((delayWriteConfig) div (1000.0)) + (2));
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if (bufferI[z]) = ($59) then
      begin
       w := bufferI[(z) + (4)];
       x := memCONFIG[$19];
       if (not (x)) and (w) then
       begin
        PrintMessage("\r\n");
        sprintf(str, strings[S_CodeWError2], $300019, x, w);
        PrintMessage(str);
        PrintMessage(strings[S_IntW]);
       end
       else
        errC := 0;
       z := (64) * (2);
      end;
     end;
     err := err + errC;
    end;
    if (errC) > (0) then
     PrintMessage(strings[S_SkipSaflock]);
    else
    begin
     errC := 1;
     j := 0;
     MemAddr := ($300018) shl (1);
     bufferU[Inc(j)] := $39;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $80;
     bufferU[Inc(j)] := (MemAddr) shr (16);
     bufferU[Inc(j)] := ((MemAddr) shr (8)) and ($FF);
     bufferU[Inc(j)] := (MemAddr) and ($FF);
     bufferU[Inc(j)] := $39;
     bufferU[Inc(j)] := 2;
     bufferU[Inc(j)] := $4C;
     bufferU[Inc(j)] := $4F;
     bufferU[Inc(j)] := $43;
     bufferU[Inc(j)] := $4B;
     bufferU[Inc(j)] := $59;
     bufferU[Inc(j)] := $C0;
     bufferU[Inc(j)] := 0;
     bufferU[Inc(j)] := memCONFIG[$18];
     bufferU[Inc(j)] := $0A;
     bufferU[Inc(j)] := $58;
     bufferU[Inc(j)] := $FE;
     bufferU[Inc(j)] := $04;
     while (j) < (64) do
     begin
      bufferU[j] := $0;
      Inc(j);
     end;
     PacketIO(((delayWriteConfig) div (1000.0)) + (2));
     for z := 0 to ((64) - (4)) - 1 do
     begin
      if (bufferI[z]) = ($58) then
      begin
       w := bufferI[(z) + (2)];
       x := memCONFIG[$18];
       if (not (x)) and (w) then
       begin
        PrintMessage("\r\n");
        sprintf(str, strings[S_CodeWError2], $300018, x, w);
        PrintMessage(str);
        PrintMessage(strings[S_IntW]);
       end
       else
        errC := 0;
       z := (64) * (2);
      end;
     end;
     err := err + errC;
    end;
   end;
   sprintf(str, strings[S_ComplErr], errC);
   PrintMessage(str);
  end;
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
  PacketIO(1);
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
