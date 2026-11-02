unit i2cspi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

const
  CS = 8;
  HLD = 16;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  i: Integer;
  j: Integer;
  str: array[0..1024-1] of Char;
  t: array[0..16-1] of Char;
  n: Integer;

// --- function declarations ---
procedure I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: PByte);

implementation

procedure I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: PByte);
var
  j: Integer;
begin
  j := 0;
  if N<0 then
   N := 0;
  if N>60 then
   N := 60;
  if mode<0 then
   mode := 0;
  if mode>5 then
   mode := 5;
  if speed<0 then
   speed := 0;
  if speed>3 then
   speed := 3;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'I2C-SPI receive' + #9 + 'mode=%d' + #9 + 'speed=%d' + LineEnding + '', mode, speed);
  end;
  bufferU[Inc(j)] := EN_VPP_VCC;
  bufferU[Inc(j)] := $1;
  if mode<2 then
  begin
   bufferU[Inc(j)] := I2C_INIT;
   bufferU[Inc(j)] := IfThen((speed shl 3)+(speed>0, $40, 0));
  end
  else
  begin
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := SPI_INIT;
   bufferU[Inc(j)] := speed+((mode-2) shl 2);
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(2);
  j := 0;
  if mode = 0 then
  begin
   bufferU[Inc(j)] := I2C_READ;
   bufferU[Inc(j)] := IfThen(N>(DIMBUF-4), DIMBUF-4, N);
   bufferU[Inc(j)] := buffer[0];
   bufferU[Inc(j)] := buffer[1];
  end
  else if mode = 1 then
  begin
   bufferU[Inc(j)] := I2C_READ2;
   bufferU[Inc(j)] := IfThen(N>(DIMBUF-4), DIMBUF-4, N);
   bufferU[Inc(j)] := buffer[0];
   bufferU[Inc(j)] := buffer[1];
   bufferU[Inc(j)] := buffer[2];
  end
  else if mode>=2 then
  begin
   bufferU[Inc(j)] := SPI_READ;
   bufferU[Inc(j)] := IfThen(N>(DIMBUF-5), DIMBUF-5, N);
   bufferU[Inc(j)] := EXT_PORT;
   bufferU[Inc(j)] := CS;
   bufferU[Inc(j)] := 0;
  end;
  (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(;j<DIMBUF;j++) bufferU[j]=0x0 *)
  // init: 
  while j<DIMBUF do
  begin
   (* TODO gtk2laz: unrecognised statement: j++; *)
  end;
  PacketIO(10);
  if saveLog then
  begin
   CloseLogFile();
  end;
end;

end.
