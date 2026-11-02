unit progp32;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

const
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

// --- function declarations ---
procedure PIC32_ID(id: Integer);
procedure XferInstruction(j: ^Integer; instruction: Integer);
procedure Read32x(dim: Integer; options: Integer);

implementation

procedure PIC32_ID(id: Integer);
var
  s: array[0..64-1] of Char;
  i: Integer;
begin
  for i := 0 to (sizeof(PIC32LIST)/sizeof(PIC32LIST[0])) - 1 do
  begin
   if (id&0x0FFFFFFF) = PIC32LIST[i].id then
   begin
    strcpy(s, PIC32LIST[i].device);
    strcat(s, '\r' + LineEnding + '');
    PrintMessage(s);
    Exit;
   end;
  end;
end;

procedure XferInstruction(j: ^Integer; instruction: Integer);
var
  i: Integer;
  z: Integer;
  w0: Integer;
  IO: Integer;
begin
  i := 0;
  w0 := 0;
  IO := 0;
  if j = -1 then
  begin
   j := &i;
   IO := 1;
  end;
  bufferU[(*j)++] := ETAP_DATA;
  bufferU[(*j)++] := JTAG_XFER_DATA;
  bufferU[(*j)++] := (instruction shr 24)&0xFF;
  bufferU[(*j)++] := (instruction shr 16)&0xFF;
  bufferU[(*j)++] := (instruction shr 8)&0xFF;
  bufferU[(*j)++] := instruction&0xFF;
  bufferU[(*j)++] := JTAG_SEND_CMD;
  bufferU[(*j)++] := ETAP_CONTROL;
  bufferU[(*j)++] := JTAG_XFER_DATA;
  bufferU[(*j)++] := $00;
  bufferU[(*j)++] := $00;
  bufferU[(*j)++] := $C0;
  bufferU[(*j)++] := $00;
  if IO then
  begin
   bufferU[(*j)++] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;(*j)<DIMBUF;(*j)++) bufferU[(*j)]=0x0 *)
   // init: 
   while <DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: (*j)++; *)
   end;
   PacketIO(5);
   i := 0;
  end;
end;

procedure Read32x(dim: Integer; options: Integer);
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
  if FWVersion<0xA00 then
  begin
   PrintMessage1(strings[S_FWver2old], '0.10.0');
   Exit;
  end;
  if memCODE then
   FreeMem(memCODE);
  memCODE := malloc(size);
  FillChar(memCODE, dim, $FF);
  StartHVReg(-1);
  start := GetTickCount();
  w0 := 0;
  j := 0;
  bufferU[Inc(j)] := SET_PARAMETER;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 10000 shr 8;
  bufferU[Inc(j)] := 10000&0xff;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := WAIT_T2;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  bufferU[Inc(j)] := WAIT_T3;
  bufferU[Inc(j)] := SET_PORT_DIR;
  bufferU[Inc(j)] := $27;
  bufferU[Inc(j)] := $FF;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := $08;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := JTAG_SET_MODE;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_SW_MTAP;
  bufferU[Inc(j)] := JTAG_SET_MODE;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_COMMAND;
  bufferU[Inc(j)] := JTAG_XFER_DATA;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := MCHP_STATUS;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(25);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  bufferU[Inc(j)] := JTAG_XFER_DATA;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := MCHP_STATUS;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(i=0;(w0&0xC)!=0x8&&i<20;i++){ 		PacketIO(5); 		for(z=0;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++); 		if(z<DIMBUF-4) w0=(bufferI[z+1]<<24)+(bufferI[z+2]<<16)+(bufferI[z+3]<<8)+bufferI[z+4];  	} 	Pri *)
  // init: i=0
  while (w0&0xC) not =0x8 and i<20 do
  begin
   PacketIO(5);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =JTAG_XFER_DATA and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-4 then
    w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
   (* TODO gtk2laz: unrecognised statement: i++; *)
  end;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_IDCODE;
  bufferU[Inc(j)] := JTAG_XFER_DATA;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  PacketIO(5);
  j := 0;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('IDCODE=0x%08X\r' + LineEnding + '', w0);
  PIC32_ID(w0);
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_SW_MTAP;
  bufferU[Inc(j)] := JTAG_SET_MODE;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_COMMAND;
  bufferU[Inc(j)] := JTAG_XFER_DATA;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := MCHP_STATUS;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_SW_ETAP;
  bufferU[Inc(j)] := JTAG_SET_MODE;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := ETAP_EJTAGBOOT;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := $8;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := MTAP_SW_ETAP;
  bufferU[Inc(j)] := JTAG_SET_MODE;
  bufferU[Inc(j)] := $3E;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := ETAP_CONTROL;
  bufferU[Inc(j)] := JTAG_XFER_DATA;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  j := 0;
  for i := 0 to (20) - 1 do
  begin
   PacketIO(5);
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =JTAG_XFER_DATA and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-4 then
    w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
   if w0&0x40000 then
    (* TODO gtk2laz: unrecognised statement: break *)
  end;
  for i := $bFC00BF0 to ($bFC00C10) - 1 do
  begin
   XferInstruction(-1, $3C13FF20);
   XferInstruction(-1, 0x3C080000+(i shr 16));
   XferInstruction(-1, 0x35080000+(i&0xFFFF));
   XferInstruction(-1, $8d090000);
   XferInstruction(-1, $ae690000);
   XferInstruction(-1, 0);
   j := 0;
   bufferU[Inc(j)] := JTAG_SEND_CMD;
   bufferU[Inc(j)] := ETAP_FASTDATA;
   bufferU[Inc(j)] := JTAG_XFER_F_DATA;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   w0 := -10;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-4 then
    w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
   PrintMessage2('[0x%08X]=0x%08X\r' + LineEnding + '', i, w0);
   i := i + 4;
  end;
  XferInstruction(-1, $3C13FF20);
  XferInstruction(-1, 0x3C080000+(i shr 16));
  XferInstruction(-1, 0x35080000+(i&0xFFFF));
  XferInstruction(-1, $8d090000);
  XferInstruction(-1, $ae690000);
  XferInstruction(-1, 0);
  j := 0;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := ETAP_FASTDATA;
  bufferU[Inc(j)] := JTAG_XFER_F_DATA;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  w0 := -10;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('DEVID=0x%08X\r' + LineEnding + '', w0);
  PacketIO(5);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('DEVID=0x%08X\r' + LineEnding + '', w0);
  PacketIO(5);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('DEVID=0x%08X\r' + LineEnding + '', w0);
  PacketIO(5);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('DEVID=0x%08X\r' + LineEnding + '', w0);
  PacketIO(5);
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('DEVID=0x%08X\r' + LineEnding + '', w0);
  XferInstruction(-1, $3C13FF20);
  XferInstruction(-1, 0x3C080000+(i shr 16));
  XferInstruction(-1, 0x35080000+(i&0xFFFF));
  XferInstruction(-1, $8d090000);
  XferInstruction(-1, $ae690000);
  XferInstruction(-1, 0);
  j := 0;
  bufferU[Inc(j)] := JTAG_SEND_CMD;
  bufferU[Inc(j)] := ETAP_FASTDATA;
  bufferU[Inc(j)] := JTAG_XFER_F_DATA;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := $00;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(5);
  j := 0;
  w0 := -10;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
  // init: z=0
  while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: z++; *)
  end;
  if z<DIMBUF-4 then
   w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
  PrintMessage1('DEVID=0x%08X\r' + LineEnding + '', w0);
  for i := $1FC00000 to (0x1FC00BF0 and 0) - 1 do
  begin
   XferInstruction(&j, $3C13FF20);
   XferInstruction(&j, 0x3C080000+(i shr 16));
   XferInstruction(&j, 0x35080000+(i%0xFFFF));
   XferInstruction(&j, $8d090000);
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   XferInstruction(&j, $ae690000);
   bufferU[Inc(j)] := JTAG_SEND_CMD;
   bufferU[Inc(j)] := ETAP_FASTDATA;
   bufferU[Inc(j)] := JTAG_XFER_F_DATA;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := $00;
   bufferU[Inc(j)] := FLUSH;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
   // init: 
   while j<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: j++; *)
   end;
   PacketIO(5);
   j := 0;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z=0;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++) *)
   // init: z=0
   while bufferI[z] not =JTAG_XFER_DATA and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=4;bufferI[z]!=JTAG_XFER_DATA&&z<DIMBUF;z++) *)
   // init: z+=4
   while bufferI[z] not =JTAG_XFER_DATA and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(z+=4;bufferI[z]!=JTAG_XFER_F_DATA&&z<DIMBUF;z++) *)
   // init: z+=4
   while bufferI[z] not =JTAG_XFER_F_DATA and z<DIMBUF do
   begin
    (* TODO gtk2laz: unrecognised statement: z++; *)
   end;
   if z<DIMBUF-4 then
    w0 := (bufferI[z+1] shl 24)+(bufferI[z+2] shl 16)+(bufferI[z+3] shl 8)+bufferI[z+4];
   PrintMessage2('[0x%08X]=0x%08X\r' + LineEnding + '', i, w0);
   i := i + 4;
  end;
  bufferU[Inc(j)] := SET_T3;
  bufferU[Inc(j)] := 2000 shr 8;
  bufferU[Inc(j)] := 2000&0xff;
  bufferU[Inc(j)] := EXT_PORT;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := 0;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $0;
  bufferU[Inc(j)] := FLUSH;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  writeP();
  msDelay(2);
  readP();
  if saveLog then
   WriteLogIO();
  stop := GetTickCount();
  PrintStatusClear();
  PrintMessage1(strings[S_End], (stop-start)/1000.0);
  if saveLog then
   CloseLogFile();
end;

end.
