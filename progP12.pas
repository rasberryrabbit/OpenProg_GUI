unit progp12;

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

// --- function declarations ---
function Read12F5xx(dim: Integer; dim2: Integer): Pointer;
function Write12F5xx(dim: Integer; OscAddr: Integer): Pointer;
function Write12C5xx(dim: Integer; dummy: Integer): Pointer;

implementation

function Read12F5xx(dim: Integer; dim2: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  PrintMessage(strings[S_WDTOFF]): Telse;
  PrintMessage(strings[S_CPON]): Telse;
  PrintMessage(strings[S_MCLROFF]): Telse;
  stop: Cardinal;
  valid: Integer;
  empty: Integer;
  aux: PChar;
  PrintMessage(aux): Telse;
  PrintMessage(aux): Telse;
begin
  k := 0;
  z := 0;
  if dim2<4 then
   dim2 := 4;
  sizeW := $1000;
  if memCODE_W then
   FreeMem(memCODE_W);
  memCODE_W := malloc(sizeof(WORD)*sizeW);
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'Read12F5xx(%d,%d)' + LineEnding + '', dim, dim2);
  end;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := READ_DATA_PROG;
  bufferU[Inc(j)] := INC_ADDR;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP12.c:63
    Original C:
      	for(;j<DIMBUF;j++) bufferU[j]=0x0;
  *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement
     Source: /tmp/opgui-0.12.4/progP12.c:1
     Original C:
       /**
        * \file progP12.c - algorithms to program the PIC12 (12 bit word) family of microcontrollers
        * Copyright (C) 2009-2016 Alberto Maccioni
        *
        * This program is free software; you can redistribute it and/or modify
   *)
  end;
  PacketIO(2);
  for z := 0 to (DIMBUF-2 and bufferI[z] not =READ_DATA_PROG) - 1 do
  begin
  end;
  if z<DIMBUF-2 then
  begin
   memCODE_W[0xfff] := (bufferI[z+1] shl 8)+bufferI[z+2];
   PrintMessage('\r' + LineEnding + '');
   PrintMessage1(strings[S_ConfigWord], memCODE_W[0xfff]);
   case memCODE_W[0xfff]&0x03 of
    0:
    begin
     PrintMessage(strings[S_LPOsc]);
    end;
    1:
    begin
     PrintMessage(strings[S_XTOsc]);
    end;
    2:
    begin
     PrintMessage(strings[S_IntOsc]);
    end;
    3:
    begin
     PrintMessage(strings[S_RCOsc]);
    end;
   end;
   if memCODE_W[0xfff]&0x08 then
    PrintMessage(strings[S_CPOFF]);
   if memCODE_W[0xfff]&0x10 then
    PrintMessage(strings[S_MCLRON]);
  end
  else
   PrintMessage(strings[S_NoConfigW]);
  PrintMessage(strings[S_CodeReading1]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim+dim2) - 1 do
  begin
   bufferU[Inc(j)] := READ_DATA_PROG;
   bufferU[Inc(j)] := INC_ADDR;
   if j>DIMBUF*2/4-3 or i = dim+dim2-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP12.c:63
      Original C:
        	for(;j<DIMBUF;j++) bufferU[j]=0x0;
    *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement
       Source: /tmp/opgui-0.12.4/progP12.c:1
       Original C:
         /**
          * \file progP12.c - algorithms to program the PIC12 (12 bit word) family of microcontrollers
          * Copyright (C) 2009-2016 Alberto Maccioni
          *
          * This program is free software; you can redistribute it and/or modify
     *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = READ_DATA_PROG then
     begin
      memCODE_W[Inc(k)] := (bufferI[z+1] shl 8)+bufferI[z+2];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
  end;
  bufferU[Inc(j)] := NOP;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP12.c:63
    Original C:
      	for(;j<DIMBUF;j++) bufferU[j]=0x0;
  *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement
     Source: /tmp/opgui-0.12.4/progP12.c:1
     Original C:
       /**
        * \file progP12.c - algorithms to program the PIC12 (12 bit word) family of microcontrollers
        * Copyright (C) 2009-2016 Alberto Maccioni
        *
        * This program is free software; you can redistribute it and/or modify
   *)
  end;
  PacketIO(1);
  stop := GetTickCount();
  for i := k to ($fff) - 1 do
  begin
  end;
  if k not =dim+dim2 then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadErr], dim+dim2, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  for i := 0 to (4) - 1 do
  begin
   PrintMessage4(strings[S_ChipID], i, memCODE_W[dim+i], i+1, memCODE_W[dim+i+1]);
   i := i + 2;
  end;
  s[0] := 0;
  valid := 0;
  empty := 1;
  aux := malloc((dim/COL+1)*(16+COL*5));
  aux[0] := 0;
  for i := 0 to (dim) - 1 do
  begin
   valid := 0;
   for j := i to (i+COL and j<dim) - 1 do
   begin
    sprintf(t, '%03X ', memCODE_W[j]);
    strcat(s, t);
    if memCODE_W[j]<0xfff then
     valid := 1;
   end;
   i := i + COL;
  end;
  FreeMem(aux);
  if dim2>5 then
  begin
   aux := malloc((dim2/COL+1)*(16+COL*5));
   aux[0] := 0;
   s[0] := 0;
   PrintMessage(strings[S_ConfigResMem]);
   empty := 1;
   for i := dim to (dim+dim2) - 1 do
   begin
    valid := 0;
    for j := i to (i+COL and j<dim+64) - 1 do
    begin
     sprintf(t, '%03X ', memCODE_W[j]);
     strcat(s, t);
     if memCODE_W[j]<0xfff then
      valid := 1;
    end;
    i := i + COL;
   end;
   FreeMem(aux);
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

function Write12F5xx(dim: Integer; OscAddr: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  w: Integer;
  err: Integer;
  osccal: TWORD;
  BKosccal: TWORD;
  start: Cardinal;
  dim1: Integer;
  err_c: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  osccal := -(1);
  BKosccal := -(1);
  if (OscAddr) > (dim) then
   OscAddr := (dim) - (1);
  if (OscAddr) = (-(1)) then
   use_BKosccal := (use_osccal := 0);
  if (sizeW) < ($1000) then
  begin
   PrintMessage(strings[S_NoConfigW2]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Write12F5xx(%d,%d)\n", dim, OscAddr);
  end;
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := memCODE_W[i] and $FFF;
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
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  if (OscAddr) <> (-(1)) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP12.c:236
     Original C:
       for (i = -1; i < (OscAddr - 0xff); i += 0xff)
       {
         bufferU[j++] = 0x17;
         bufferU[j++] = 0xff;
       }
   *)
   // init: i = -1
   while (i) < ((OscAddr) - ($ff)) do
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $ff;
     // step: i += 0xff
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := (OscAddr) - (i);
   bufferU[Inc(j)] := $14;
   if (OscAddr) < (dim) then
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := (dim) - (OscAddr);
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $4;
   bufferU[Inc(j)] := $14;
  end;
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
  if (OscAddr) <> (-(1)) then
  begin
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP12.c:267
     Original C:
       for (z = 4; (z < (64 - 2)) && (bufferI[z] != 0x14); z++)
         ;
   *)
   // init: z = 4
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
    osccal := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP12.c:269
     Original C:
       for (z += 3; (z < (64 - 2)) && (bufferI[z] != 0x14); z++)
         ;
   *)
   // init: z += 3
   while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
   begin
     // step: z++
   end;
   if (z) < ((64) - (2)) then
    BKosccal := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
   if ((osccal) = (-(1))) or ((BKosccal) = (-(1))) then
   begin
    PrintMessage(strings[S_ErrOsccal]);
    PrintMessage("\r\n");
    Exit;
   end;
   sprintf(str, strings[S_Osccal], osccal);
   PrintMessage(str);
   sprintf(str, strings[S_BKOsccal], BKosccal);
   PrintMessage(str);
  end;
  PrintMessage(strings[S_StartErase]);
  j := 0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  if (dim) > ((OscAddr) + (1)) then
  begin
   bufferU[Inc(j)] := $19;
   bufferU[Inc(j)] := $0A;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/progP12.c:290
     Original C:
       for (i = -1; i < (dim - 0xff); i += 0xff)
       {
         bufferU[j++] = 0x17;
         bufferU[j++] = 0xff;
       }
   *)
   // init: i = -1
   while (i) < ((dim) - ($ff)) do
   begin
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := $ff;
     // step: i += 0xff
   end;
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := ((dim) - (i)) - (1);
   bufferU[Inc(j)] := $19;
   bufferU[Inc(j)] := $0A;
   if programID then
   begin
    bufferU[Inc(j)] := $16;
    bufferU[Inc(j)] := $19;
    bufferU[Inc(j)] := $0A;
   end;
  end
  else
  begin
   if programID then
   begin
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/progP12.c:306
      Original C:
        for (i = -1; i < (dim - 0xff); i += 0xff)
        {
          bufferU[j++] = 0x17;
          bufferU[j++] = 0xff;
        }
    *)
    // init: i = -1
    while (i) < ((dim) - ($ff)) do
    begin
     bufferU[Inc(j)] := $17;
     bufferU[Inc(j)] := $ff;
      // step: i += 0xff
    end;
    bufferU[Inc(j)] := $17;
    bufferU[Inc(j)] := (dim) - (i);
    bufferU[Inc(j)] := $19;
    bufferU[Inc(j)] := $0A;
   end
   else
   begin
    bufferU[Inc(j)] := $19;
    bufferU[Inc(j)] := $0A;
   end;
  end;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $16;
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
  PacketIO(IfThen((dim) > ((OscAddr) + (1)), 50, 30));
  PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_StartCodeProg]);
  dim1 := dim;
  if programID then
   dim1 := (dim) + (5);
  if (memCODE_W[(dim) + (4)]) >= ($FFF) then
   memCODE_W[(dim) + (4)] := BKosccal;
  if use_BKosccal then
   memCODE_W[OscAddr] := BKosccal;
  else
   if use_osccal then
    memCODE_W[OscAddr] := osccal;
  while (i) < (dim1) do
  begin
   if (memCODE_W[i]) < ($fff) then
   begin
    bufferU[Inc(j)] := $12;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $0A;
    bufferU[Inc(j)] := $1C;
    bufferU[Inc(j)] := $09;
    bufferU[Inc(j)] := $14;
    Inc(w);
   end;
   bufferU[Inc(j)] := $16;
   if ((j) > ((64) - (10))) or ((i) = ((dim1) - (1))) then
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
    PacketIO(((w) * (3)) + (3));
    w := 0;
    for z := 0 to ((64) - (7)) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($fff)) then
      Inc(k);
     else
      if ((bufferI[z]) = ($12)) and ((bufferI[(z) + (5)]) = ($14)) then
      begin
       if (memCODE_W[k]) <> (((bufferI[(z) + (6)]) shl (8)) + (bufferI[(z) + (7)])) then
       begin
        PrintMessage("\r\n");
        sprintf(str, strings[S_CodeWError], k, memCODE_W[k], ((bufferI[(z) + (6)]) shl (8)) + (bufferI[(z) + (7)]));
        PrintMessage(str);
        Inc(err);
        if (max_err) and ((err) > (max_err)) then
        begin
         sprintf(str, strings[S_MaxErr], err);
         PrintMessage(str);
         PrintMessage(strings[S_IntW]);
         i := dim1;
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
  PrintMessage(strings[S_ConfigW]);
  err_c := 0;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $12;
  bufferU[Inc(j)] := (memCODE_W[$fff]) shr (8);
  bufferU[Inc(j)] := (memCODE_W[$fff]) and ($ff);
  bufferU[Inc(j)] := $18;
  bufferU[Inc(j)] := $0A;
  bufferU[Inc(j)] := $1C;
  bufferU[Inc(j)] := $09;
  bufferU[Inc(j)] := $14;
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
  PacketIO(20);
  stop := GetTickCount();
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP12.c:432
    Original C:
      for (z = 0; (z < (64 - 2)) && (bufferI[z] != 0x14); z++)
        ;
  *)
  // init: z = 0
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
    // step: z++
  end;
  if (not (memCODE_W[$fff])) and (((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)])) then
  begin
   PrintMessage("\r\n");
   sprintf(str, strings[S_ConfigWErr], memCODE_W[$fff], ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]));
   PrintMessage(str);
   Inc(err_c);
  end;
  err := err + err_c;
  if (z) > ((64) - (2)) then
  begin
   PrintMessage("\r\n");
   PrintMessage(strings[S_ConfigWErr2]);
  end;
  sprintf(str, strings[S_ComplErr], err_c);
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log8], i, i, k, k, err);
  end;
  sprintf(str, strings[S_EndErr], ((stop) - (start)) div (1000.0), err, IfThen((err) <> (1), strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
  gtk_statusbar_push(status_bar, statusID, "");
end;

function Write12C5xx(dim: Integer; dummy: Integer): Pointer;
var
  k: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  err: Integer;
  osccal: TWORD;
  OscAddr: Integer;
  start: Cardinal;
  N: Integer;
  Nt: Integer;
  Nmin: Integer;
  Nmax: Integer;
  xN: Integer;
  dim1: Integer;
  err_c: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  osccal := -(1);
  OscAddr := (dim) - (1);
  if (FWVersion) < ($800) then
  begin
   sprintf(str, strings[S_FWver2old], "0.8.0");
   PrintMessage(str);
   Exit;
  end;
  if (sizeW) < ($1000) then
  begin
   PrintMessage(strings[S_NoConfigW2]);
   Exit;
  end;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, "Write12C5xx(%d)\n", dim);
  end;
  for i := 0 to (sizeW) - 1 do
  begin
   memCODE_W[i] := memCODE_W[i] and $FFF;
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := $07;
  bufferU[Inc(j)] := 3;
  bufferU[Inc(j)] := 8;
  bufferU[Inc(j)] := 11;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0F;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $00;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP12.c:501
    Original C:
      for (i = -1; i < (OscAddr - 0xff); i += 0xff)
      {
        bufferU[j++] = 0x17;
        bufferU[j++] = 0xff;
      }
  *)
  // init: i = -1
  while (i) < ((OscAddr) - ($ff)) do
  begin
   bufferU[Inc(j)] := $17;
   bufferU[Inc(j)] := $ff;
    // step: i += 0xff
  end;
  bufferU[Inc(j)] := $17;
  bufferU[Inc(j)] := (OscAddr) - (i);
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
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while
    Source: /tmp/opgui-0.12.4/progP12.c:524
    Original C:
      for (z = 4; (z < (64 - 2)) && (bufferI[z] != 0x14); z++)
        ;
  *)
  // init: z = 4
  while ((z) < ((64) - (2))) and ((bufferI[z]) <> ($14)) do
  begin
    // step: z++
  end;
  if (z) < ((64) - (2)) then
   osccal := ((bufferI[(z) + (1)]) shl (8)) + (bufferI[(z) + (2)]);
  if (osccal) = (-(1)) then
  begin
   PrintMessage(strings[S_ErrOsccal]);
   PrintMessage("\r\n");
   Exit;
  end;
  sprintf(str, strings[S_Osccal], osccal);
  PrintMessage(str);
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := $16;
  bufferU[Inc(j)] := $0C;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  PrintMessage(strings[S_StartCodeProg]);
  Nt := 0;
  Nmin := 255;
  Nmax := 0;
  xN := 0;
  dim1 := dim;
  if programID then
   dim1 := (dim) + (5);
  if use_osccal then
   memCODE_W[OscAddr] := osccal;
  while (i) < (dim1) do
  begin
   if (memCODE_W[i]) < ($fff) then
   begin
    bufferU[Inc(j)] := $20;
    bufferU[Inc(j)] := (memCODE_W[i]) shr (8);
    bufferU[Inc(j)] := (memCODE_W[i]) and ($ff);
    bufferU[Inc(j)] := $14;
    bufferU[Inc(j)] := $0C;
    bufferU[Inc(j)] := $16;
   end
   else
   begin
    while (((memCODE_W[i]) >= ($fff)) and ((j) < ((64) - (1)))) and ((i) < (dim1)) do
    begin
     bufferU[Inc(j)] := $16;
     Inc(i);
    end;
    Dec(i);
   end;
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
   PacketIO((10) + (3));
   j := 0;
   if ((bufferI[1]) = ($20)) and ((bufferI[3]) = ($14)) then
   begin
    N := bufferI[2];
    if (N) < ($F0) then
    begin
     Nt := Nt + N;
     Inc(xN);
     if (N) < (Nmin) then
      Nmin := N;
     if (N) > (Nmax) then
      Nmax := N;
    end;
    if (memCODE_W[k]) <> (((bufferI[4]) shl (8)) + (bufferI[5])) then
    begin
     PrintMessage("\r\n");
     sprintf(str, strings[S_CodeWError], k, memCODE_W[k], ((bufferI[4]) shl (8)) + (bufferI[5]));
     PrintMessage(str);
     Inc(err);
     if (max_err) and ((err) > (max_err)) then
     begin
      sprintf(str, strings[S_MaxErr], err);
      PrintMessage(str);
      PrintMessage(strings[S_IntW]);
      i := dim1;
      z := 64;
     end;
    end;
    Inc(k);
   end
   else
    for z := 0 to (64) - 1 do
    begin
     if ((bufferI[z]) = ($16)) and ((memCODE_W[k]) >= ($fff)) then
      Inc(k);
    end;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log8], i, i, k, k, err);
   end;
   Inc(i);
  end;
  err := err + (i) - (k);
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
  if (saveLog) and (xN) then
   fprintf(logfile, "Programming pulses: avg %.1f, min %d, max %d\r\n", (Nt) div (xN), Nmin, Nmax);
  if (memCODE_W[$fff]) < ($fff) then
  begin
   PrintMessage(strings[S_ConfigW]);
   err_c := 0;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $0;
   bufferU[Inc(j)] := $0A;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $1;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $5;
   bufferU[Inc(j)] := $12;
   bufferU[Inc(j)] := (memCODE_W[$fff]) shr (8);
   bufferU[Inc(j)] := (memCODE_W[$fff]) and ($ff);
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(12);
   j := 0;
   for i := 0 to (20) - 1 do
   begin
    bufferU[Inc(j)] := $18;
    bufferU[Inc(j)] := $09;
    bufferU[Inc(j)] := $1C;
   end;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   j := 0;
   for i := 0 to (5) - 1 do
   begin
    PacketIO(3);
   end;
   bufferU[Inc(j)] := $14;
   bufferU[Inc(j)] := $04;
   while (j) < (64) do
   begin
    bufferU[j] := $0;
    Inc(j);
   end;
   PacketIO(2);
   j := 0;
   if (not (memCODE_W[$fff])) and (((bufferI[2]) shl (8)) + (bufferI[3])) then
   begin
    PrintMessage("\r\n");
    sprintf(str, strings[S_ConfigWErr], memCODE_W[$fff], ((bufferI[2]) shl (8)) + (bufferI[3]));
    PrintMessage(str);
    Inc(err_c);
   end;
   err := err + err_c;
  end;
  sprintf(str, strings[S_ComplErr], err);
  PrintMessage(str);
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
  j := 0;
  stop := GetTickCount();
  if saveLog then
  begin
   fprintf(logfile, strings[S_Log8], i, i, k, k, err);
  end;
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
