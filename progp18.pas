unit progp18;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

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
  k: Integer;
  k2: Integer;
  z: Integer;
  i: Integer;
  j: Integer;
  start: Cardinal;
  stop: Cardinal;

// --- function declarations ---
procedure PIC18_ID(id: Integer);
procedure DisplayCODE18F(dim: Integer);
procedure Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer);
procedure Read18FKx(dim: Integer; dim2: Integer; options: Integer);
procedure Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer);

implementation

procedure PIC18_ID(id: Integer);
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

procedure DisplayCODE18F(dim: Integer);
var
  s: array[0..256-1] of Char;
  t: array[0..256-1] of Char;
  aux: PChar;
  valid: Integer;
  empty: Integer;
  i: Integer;
  j: Integer;
  lines: Integer;
  PrintMessage(aux): Telse;
begin
  (* TODO gtk2laz: array initializer: s[256]=""; *)
  (* TODO gtk2laz: array initializer: t[256]=""; *)
  aux := malloc((dim/COL+1)*(16+COL*6));
  aux[0] := 0;
  valid := 0;
  empty := 1;
  lines := 0;
  for i := 0 to (dim and i<size) - 1 do
  begin
   valid := 0;
   for j := i to (i+COL*2 and j<dim) - 1 do
   begin
    sprintf(t, '%02X ', memCODE[j]);
    strcat(s, t);
    if memCODE[j]<0xff then
     valid := 1;
   end;
   i := i + COL*2;
  end;
  FreeMem(aux);
end;

procedure Write18Fx(dim: Integer; dim2: Integer; wbuf: Integer; eraseW1: Integer; eraseW2: Integer; options: Integer);
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
  if(entry==1||entry==3) vpp=8.5: Telse;
  ww: Integer;
  stop: Cardinal;
begin
  k := 0;
  z := 0;
  err := 0;
  EEalgo := (options shr 4)&0xF;
  entry := options&0xF;
  optWrite := (options shr 8)&0xF;
  if dim>0x1FFFFF or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if entry = 0 then
   vpp := 12;
  if  not StartHVReg(vpp) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if dim%wbuf then
  begin
   dim := dim + wbuf-dim%wbuf;
   j := size;
   if j<dim then
   begin
    size := dim;
    memCODE := realloc(memCODE, size);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<dim;j++) memCODE[j]=0xFF *)
    // init: 
    while j<dim do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
   end;
  end;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := 100;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  if entry = 2 then
  begin
   bufferU[Inc(j)] := EN_VPP_VCC;
   bufferU[Inc(j)] := $1;
  end;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $3F;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $FE;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6E;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := TBLR_INC_N;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 5100 shr 8;
  bufferU[Inc(j)] := 5100&0xff;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(IfThen(entry = 2, 10, 3));
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=TBLR_INC_N&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =TBLR_INC_N and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-3 then
  begin
   PrintMessage2(strings[S_DevID2], bufferI[z+3], bufferI[z+2]);
   PIC18_ID(bufferI[z+2]+(bufferI[z+3] shl 8));
  end;
  PrintMessage(strings[S_StartErase]);
  if optWrite not =3 then
  begin
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $3C;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   if eraseW1<0x10000 then
   begin
    bufferU[Inc(j)] := CORE_INS;
    bufferU[Inc(j)] := $0E;
    bufferU[Inc(j)] := $05;
    bufferU[Inc(j)] := CORE_INS;
    bufferU[Inc(j)] := $6E;
    bufferU[Inc(j)] := $F6;
    bufferU[Inc(j)] := TABLE_WRITE;
    bufferU[Inc(j)] := (eraseW1 shr 8)&0xFF;
    bufferU[Inc(j)] := eraseW1&0xFF;
   end;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(16);
   if optWrite not =0 then
    msDelay(550);
   j := 0;
  end
  else
  begin
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $3C;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := $01;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK0' + LineEnding + '');
   end;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK1' + LineEnding + '');
   end;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK2' + LineEnding + '');
   end;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := $08;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BLOCK3' + LineEnding + '');
   end;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE BOOT BLOCK' + LineEnding + '');
   end;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $04;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := $02;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $05;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $06;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TABLE_WRITE;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(7);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, 'ERASE CONFIG' + LineEnding + '');
   end;
  end;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $8E;
  bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $9C;
  bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $84;
  bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1);
  j := 0;
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  (* TODO gtk2laz: do-while without while: double wdly=1.0 *)
  if optWrite = 1 then
   wdly := 1.2;
  if optWrite = 2 then
   wdly := 3.4;
  if saveLog then
  begin
   fprintf(logfile, 'WRITE CODE' + LineEnding + 'dim=%d(0x%X)' + LineEnding + '', dim, dim);
  end;
  j := 0;
  (* TODO gtk2laz: complex for loop: for(i=k=0;i<dim;){		 		if(k==0){				 			i0=i; 			for(valid=0;!valid&&i<dim;i+=valid?0:wbuf){ 				for(k2=0;k2<wbuf&&!valid;k2++) if(memCODE[i+k2]<0xFF) valid=1; 			} 			if(i>=dim) break; 			if(i>i0){		 *)
  PrintMessage(strings[S_Compl]);
  if programID and (optWrite = 0 or optWrite = 3) then
  begin
   PrintMessage(strings[S_IDW]);
   if saveLog then
    fprintf(logfile, 'Write ID' + LineEnding + '');
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $8E;
   bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $9C;
   bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $0E;
   bufferU[Inc(j)] := $20;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6E;
   bufferU[Inc(j)] := $F8;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F7;
   bufferU[Inc(j)] := CORE_INS;
   bufferU[Inc(j)] := $6A;
   bufferU[Inc(j)] := $F6;
   bufferU[Inc(j)] := TBLW_INC_N;
   bufferU[Inc(j)] := 3;
   for i := 0 to (3) - 1 do
   begin
    bufferU[Inc(j)] := memID[i*2+1];
    bufferU[Inc(j)] := memID[i*2];
   end;
   bufferU[Inc(j)] := memID[i*2+1];
   bufferU[Inc(j)] := memID[i*2];
   bufferU[Inc(j)] := 1000 shr 8;
   bufferU[Inc(j)] := 1000&0xFF;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   if saveLog then
   begin
    fprintf(logfile, strings[S_Log7], i, i, 0, 0);
   end;
  end;
  PrintStatusSetup();
  if saveLog then
   fprintf(logfile, 'VERIFY CODE' + LineEnding + '');
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $8E;
  bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $9C;
  bufferU[Inc(j)] := IfThen(optWrite not =3, $A6, $7F);
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F8;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F7;
  bufferU[Inc(j)] := CORE_INS;
  bufferU[Inc(j)] := $6A;
  bufferU[Inc(j)] := $F6;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  if saveLog then
  begin
   fprintf(logfile, '' + LineEnding + '' + LineEnding + '');
  end;
  if i<dim then
  begin
   PrintMessage2(strings[S_CodeVError2], dim, i);
  end;
  if err>=max_err then
  begin
   PrintMessage1(strings[S_MaxErr], err);
  end;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Read18FKx(dim: Integer; dim2: Integer; options: Integer);
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
  type := (options shr 4)&0xF;
  if type = 0 then
  begin
   EEaddr := $310000;
   DCIaddr := $3FFF00;
   DIAaddr := $3F0000;
   DIAlen := $40;
   UIDlen := $10;
   CONFIGlen := 5;
   CONFIGorg := 0;
  end
  else if type = 1 then
  begin
   EEaddr := $380000;
   DCIaddr := $3C0000;
   DIAaddr := $2C0000;
   DIAlen := $100;
   UIDlen := $40;
   CONFIGlen := 10;
   CONFIGorg := 1;
  end
  else if type = 2 then
  begin
   EEaddr := $380000;
   DCIaddr := $3C0000;
   DIAaddr := $2C0000;
   DIAlen := $100;
   UIDlen := $40;
   CONFIGlen := 35;
   CONFIGorg := 1;
  end
  else if type = 3 then
  begin
   EEaddr := $310000;
   DCIaddr := 0;
   DIAaddr := 0;
   DIAlen := 0;
   UIDlen := 8;
   CONFIGlen := 6;
   CONFIGorg := 0;
  end
  else if type = 4 then
  begin
   EEaddr := $310000;
   DCIaddr := 0;
   DIAaddr := 0;
   DIAlen := 0;
   UIDlen := $100;
   CONFIGlen := 6;
   CONFIGorg := 0;
  end
  else if type = 5 then
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
   PrintMessage('unexpected parameter');
  if dim>0x1FFFFF or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if  not StartHVReg(vpp) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if memCODE then
   FreeMem(memCODE);
  memCODE := malloc(size);
  memDIA := malloc(DIAlen);
  for j := 0 to (sizeof(memID)) - 1 do
  begin
  end;
  for j := 0 to (48) - 1 do
  begin
  end;
  for j := 0 to (DIAlen) - 1 do
  begin
  end;
  start := GetTickCount();
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 2;
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
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := WAIT_T3;
  MemAddr := 0x3FFFFc shl 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := MemAddr shr 16;
  bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
  bufferU[Inc(j)] := MemAddr&0xFF;
  bufferU[Inc(j)] := ICSP8_READ;
  bufferU[Inc(j)] := READ_NVM_INC;
  bufferU[Inc(j)] := ICSP8_READ;
  bufferU[Inc(j)] := READ_NVM_INC;
  if DCIaddr>0 then
  begin
   MemAddr := DCIaddr shl 1;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := $80;
   bufferU[Inc(j)] := MemAddr shr 16;
   bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
   bufferU[Inc(j)] := MemAddr&0xFF;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
  end;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(4);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=ICSP8_READ&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =ICSP8_READ and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
  begin
   devREV := (bufferI[z+1] shl 8)+bufferI[z+2];
  end;
  if z<DIMBUF-2 then
  begin
   devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  end;
  PrintMessage1('RevID: 0x%04X\r' + LineEnding + '', devREV);
  PIC18_ID(devID+(devREV shl 16));
  if DCIaddr>0 then
  begin
   PrintMessage('Device Configuration Information:\r' + LineEnding + '');
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;bufferI[z]!=ICSP8_READ&&z<DIMBUF;z++) *)
   // init: z+=3
   while bufferI[z] not =ICSP8_READ and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('Erase row size: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('Write latches per row: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('User rows: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('EEPROM size: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
    sizeEE := (bufferI[z+1] shl 8)+bufferI[z+2];
   end;
   if z<DIMBUF-3 then
   begin
    PrintMessage1('Pin count: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
  end
  else
   sizeEE := dim2;
  PrintMessage(strings[S_CodeReading1]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_CodeReading1]);
  PrintStatusSetup();
  for i := 0,j=0 to (dim) - 1 do
  begin
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   if (j+1)/2*3+3>DIMBUF or i = dim-2 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = ICSP8_READ then
     begin
      memCODE[Inc(k)] := bufferI[z+2];
      memCODE[Inc(k)] := bufferI[z+1];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k, k);
    end;
   end;
   i := i + 2;
  end;
  if k not =dim then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadCodeErr2], dim, k);
  end
  else
   PrintMessage(strings[S_Compl]);
  PrintMessage(strings[S_Read_CONFIG_A]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, '%s' + LineEnding + '', strings[S_Read_CONFIG_A]);
  MemAddr := 0x300000 shl 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := MemAddr shr 16;
  bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
  bufferU[Inc(j)] := MemAddr&0xFF;
  k2 := 0;
  for i := 0 to (CONFIGlen) - 1 do
  begin
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   if (j+1)/2*3+3>DIMBUF or i = CONFIGlen-1 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = ICSP8_READ then
     begin
      memCONFIG[Inc(k2)] := bufferI[z+2];
      if CONFIGorg = 0 then
       memCONFIG[Inc(k2)] := bufferI[z+1];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
  end;
  if k2 not =CONFIGlen then
  begin
   PrintMessage('\r' + LineEnding + '');
   PrintMessage2(strings[S_ReadConfigErr], CONFIGlen, k2);
  end
  else
   PrintMessage(strings[S_Compl]);
  if saveLog then
   fprintf(logfile, strings[S_sepLine]);
  if saveLog then
   fprintf(logfile, 'Read user ID' + LineEnding + '');
  MemAddr := 0x200000 shl 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := $80;
  bufferU[Inc(j)] := MemAddr shr 16;
  bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
  bufferU[Inc(j)] := MemAddr&0xFF;
  k2 := 0;
  for i := 0 to (UIDlen) - 1 do
  begin
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   if (j+1)/2*3+3>DIMBUF or i = UIDlen-2 then
   begin
    bufferU[Inc(j)] := FLUSH;
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
    // init: 
    while j<DIMBUF do
    begin
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
    PacketIO(5);
    for z := 0 to (DIMBUF-2) - 1 do
    begin
     if bufferI[z] = ICSP8_READ then
     begin
      memID[Inc(k2)] := bufferI[z+2];
      memID[Inc(k2)] := bufferI[z+1];
      z := z + 2;
     end;
    end;
    j := 0;
    if saveLog then
    begin
     fprintf(logfile, strings[S_Log7], i, i, k2, k2);
    end;
   end;
   i := i + 2;
  end;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1);
  stop := GetTickCount();
  PrintStatusClear();
  PrintMessage(strings[S_ConfigMem]);
  for i := 0 to (UIDlen) - 1 do
  begin
   if memID[i]<0xFF or memID[i+1]<0xFF then
    PrintMessage4(strings[S_ChipID2], i, memID[i], i+1, memID[i+1]);
   i := i + 2;
  end;
  DisplayCODE18F(dim);
  if dim2 then
  begin
   DisplayEE();
  end;
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

procedure Write18FKx(dim: Integer; dim2: Integer; options: Integer; nu1: Integer; nu2: Integer; nu3: Integer);
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
  type := (options shr 4)&0xF;
  if type = 0 then
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
  else if type = 1 then
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
  else if type = 2 then
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
  else if type = 3 then
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
  else if type = 4 then
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
  else if type = 5 then
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
   PrintMessage('unexpected parameter');
  if dim>0x1FFFFF or dim<0 then
  begin
   PrintMessage(strings[S_CodeLim]);
   Exit;
  end;
  if  not StartHVReg(vpp) then
  begin
   PrintMessage(strings[S_HVregErr]);
   Exit;
  end;
  if dim2>sizeEE then
   dim2 := sizeEE;
  if dim<1 then
  begin
   PrintMessage(strings[S_NoCode]);
   Exit;
  end;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T1T2;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := 35;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 11000 shr 8;
  bufferU[Inc(j)] := 11000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $4;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $5;
  bufferU[Inc(j)] := WAIT_T3;
  MemAddr := 0x3FFFFc shl 1;
  bufferU[Inc(j)] := TX16;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := LOAD_PC_ADDR;
  bufferU[Inc(j)] := MemAddr shr 16;
  bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
  bufferU[Inc(j)] := MemAddr&0xFF;
  bufferU[Inc(j)] := ICSP8_READ;
  bufferU[Inc(j)] := READ_NVM_INC;
  bufferU[Inc(j)] := ICSP8_READ;
  bufferU[Inc(j)] := READ_NVM_INC;
  if DCIaddr>0 then
  begin
   MemAddr := DCIaddr shl 1;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := MemAddr shr 16;
   bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
   bufferU[Inc(j)] := MemAddr&0xFF;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
   bufferU[Inc(j)] := ICSP8_READ;
   bufferU[Inc(j)] := READ_NVM_INC;
  end;
  bufferU[Inc(j)] := 2;
  bufferU[Inc(j)] := LOAD_PC_ADDR;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(14);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=ICSP8_READ&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =ICSP8_READ and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-2 then
  begin
   devREV := (bufferI[z+1] shl 8)+bufferI[z+2];
  end;
  if z<DIMBUF-2 then
  begin
   devID := (bufferI[z+1] shl 8)+bufferI[z+2];
  end;
  PrintMessage1('RevID: 0x%04X\r' + LineEnding + '', devREV);
  PIC18_ID(devID+(devREV shl 16));
  if DCIaddr>0 then
  begin
   PrintMessage('Device Configuration Information:\r' + LineEnding + '');
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=3;bufferI[z]!=ICSP8_READ&&z<DIMBUF;z++) *)
   // init: z+=3
   while bufferI[z] not =ICSP8_READ and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('Erase row size: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
   if z<DIMBUF-2 then
   begin
    rowN := (bufferI[z+1] shl 8)+bufferI[z+2];
    PrintMessage1('Write latches per row: %d\r' + LineEnding + '', rowN);
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('User rows: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
   if z<DIMBUF-2 then
   begin
    PrintMessage1('EEPROM size: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
   if z<DIMBUF-3 then
   begin
    PrintMessage1('Pin count: %d\r' + LineEnding + '', (bufferI[z+1] shl 8)+bufferI[z+2]);
   end;
  end;
  PrintMessage(strings[S_StartErase]);
  if saveLog then
  begin
   fprintf(logfile, strings[S_sepLine]);
   fprintf(logfile, strings[S_StartErase]);
   fprintf(logfile, strings[S_NL]);
  end;
  PrintMessage(strings[S_StartCodeProg]);
  PrintStatusSetup();
  if saveLog then
  begin
   fprintf(logfile, strings[S_sepLine]);
   fprintf(logfile, 'WRITE CODE' + LineEnding + 'dim=%d(0x%X)' + LineEnding + '', dim, dim);
  end;
  PrintMessage1(strings[S_ComplErr], err);
  if dim2 then
  begin
   PrintMessage(strings[S_EEAreaW]);
   PrintStatusSetup();
   if saveLog then
   begin
    fprintf(logfile, strings[S_sepLine]);
    fprintf(logfile, 'WRITE EEPROM' + LineEnding + 'dim2=%d(0x%X)' + LineEnding + '', dim2, dim2);
   end;
   j := 0;
   MemAddr := EEaddr shl 1;
   bufferU[Inc(j)] := TX16;
   bufferU[Inc(j)] := 2;
   bufferU[Inc(j)] := LOAD_PC_ADDR;
   bufferU[Inc(j)] := MemAddr shr 16;
   bufferU[Inc(j)] := (MemAddr shr 8)&0xFF;
   bufferU[Inc(j)] := MemAddr&0xFF;
   for i := k=0 to (dim2) - 1 do
   begin
    if memEE[i]<0xFF then
    begin
     if type = 1 or type = 2 or type = 4 or type = 5 then
     begin
      bufferU[Inc(j)] := ICSP8_LOAD;
      bufferU[Inc(j)] := PROGRAM_DATA;
      bufferU[Inc(j)] := 0;
      bufferU[Inc(j)] := memEE[i];
     end
     else if type = 0 or type = 3 then
     begin
      bufferU[Inc(j)] := ICSP8_LOAD;
      bufferU[Inc(j)] := LOAD_NVM;
      bufferU[Inc(j)] := 0;
      bufferU[Inc(j)] := memEE[i];
      bufferU[Inc(j)] := ICSP8_SHORT;
      bufferU[Inc(j)] := BEGIN_INT_PROG;
     end;
     bufferU[Inc(j)] := ICSP8_READ;
     bufferU[Inc(j)] := READ_NVM_INC;
     (* TODO gtk2laz: unrecognised statement: w++ *)
    end
    else
    begin
     bufferU[Inc(j)] := ICSP8_SHORT;
     bufferU[Inc(j)] := INC_ADDR8;
    end;
   end;
   err := err + errEE;
   PrintStatusEnd();
   PrintMessage1(strings[S_ComplErr], errEE);
  end;
  bufferU[Inc(j)] := 1;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := SET_CK_D;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(1);
  stop := GetTickCount();
  sprintf(str, strings[S_EndErr], (stop-start)/1000.0, err, IfThen(err not =1, strings[S_ErrPlur], strings[S_ErrSing]));
  PrintMessage(str);
  if saveLog then
  begin
   fprintf(logfile, str);
   CloseLogFile();
  end;
end;

end.
