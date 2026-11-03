unit i2cspi;

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
function I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: ^TBYTE): Pointer;
function I2CSend(mode: Integer; speed: Integer; N: Integer; buffer: ^TBYTE): Pointer;

implementation

function I2CReceive(mode: Integer; speed: Integer; N: Integer; buffer: ^TBYTE): Pointer;
var
  j: Integer;
  str: array[0..1024-1] of Char;
  t: array[0..16-1] of Char;
  i: Integer;
begin
  j := 0;
  if (N) < (0) then
   N := 0;
  if (N) > (60) then
   N := 60;
  if (mode) < (0) then
   mode := 0;
  if (mode) > (5) then
   mode := 5;
  if (speed) < (0) then
   speed := 0;
  if (speed) > (3) then
   speed := 3;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'I2C-SPI receive' + #9 + 'mode=%d' + #9 + 'speed=%d' + NL + '', mode, speed);
  end;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (mode) < (2) then
  begin
   bufferU[Inc(j)] := $2B;
   bufferU[Inc(j)] := ((speed) shl (3)) + (IfThen((speed) > (0), $40, 0));
  end
  else
  begin
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $2F;
   bufferU[Inc(j)] := (speed) + (((mode) - (2)) shl (2));
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  if (mode) = (0) then
  begin
   bufferU[Inc(j)] := $2C;
   bufferU[Inc(j)] := IfThen((N) > ((64) - (4)), (64) - (4), N);
   bufferU[Inc(j)] := buffer[0];
   bufferU[Inc(j)] := buffer[1];
  end
  else
   if (mode) = (1) then
   begin
    bufferU[Inc(j)] := $2E;
    bufferU[Inc(j)] := IfThen((N) > ((64) - (4)), (64) - (4), N);
    bufferU[Inc(j)] := buffer[0];
    bufferU[Inc(j)] := buffer[1];
    bufferU[Inc(j)] := buffer[2];
   end
   else
    if (mode) >= (2) then
    begin
     bufferU[Inc(j)] := $30;
     bufferU[Inc(j)] := IfThen((N) > ((64) - (5)), (64) - (5), N);
     bufferU[Inc(j)] := $32;
     bufferU[Inc(j)] := 8;
     bufferU[Inc(j)] := 0;
    end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(10);
  if saveLog then
  begin
   CloseLogFile();
  end;
  if (((bufferI[0]) = ($2C)) or ((bufferI[0]) = ($2E))) or ((bufferI[0]) = ($30)) then
  begin
   if (bufferI[1]) = ($FD) then
   begin
    PrintMessageI2C(strings[S_I2CAckErr]);
   end
   else
    if (bufferI[1]) > ($FA) then
    begin
     PrintMessageI2C(strings[S_InsErr]);
    end
    else
    begin
     str := '';
     t := '';
     if (mode) = (0) then
      sprintf(str, '> %02X %02X' + #13 + '' + NL + '', bufferU[2], bufferU[3])
     else
      if (mode) = (1) then
       sprintf(str, '> %02X %02X' + #13 + '' + NL + '', bufferU[2], bufferU[3]);
     strcat(str, '< ');
     for i := 0 to (bufferI[1]) - 1 do
     begin
      sprintf(t, '%02X ', bufferI[(i) + (2)]);
      strcat(str, t);
      if (i) and (((i) mod (16)) = (15)) then
      begin
       strcat(str, '' + #13 + '' + NL + '');
      end;
     end;
     strcat(str, '' + #13 + '' + NL + '');
     PrintMessageI2C(str);
     fflush(stdout);
    end;
  end
  else
   PrintMessageI2C(strings[S_ComErr]);
end;

function I2CSend(mode: Integer; speed: Integer; N: Integer; buffer: ^TBYTE): Pointer;
var
  i: Integer;
  j: Integer;
  str: array[0..1024-1] of Char;
  t: array[0..16-1] of Char;
  n: Integer;
  i: Integer;
begin
  j := 0;
  if (N) < (0) then
   N := 0;
  if (N) > (57) then
   N := 57;
  if (mode) < (0) then
   mode := 0;
  if (mode) > (5) then
   mode := 5;
  if (speed) < (0) then
   speed := 0;
  if (speed) > (3) then
   speed := 3;
  if saveLog then
  begin
   OpenLogFile();
   fprintf(logfile, 'I2C-SPI send' + #9 + 'mode=%d' + #9 + 'speed=%d' + NL + '', mode, speed);
  end;
  bufferU[Inc(j)] := $06;
  bufferU[Inc(j)] := $0E;
  bufferU[Inc(j)] := $1;
  if (mode) < (2) then
  begin
   bufferU[Inc(j)] := $2B;
   bufferU[Inc(j)] := ((speed) shl (3)) + (IfThen((speed) > (0), $40, 0));
  end
  else
  begin
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := 0;
   bufferU[Inc(j)] := $2F;
   bufferU[Inc(j)] := (speed) + (((mode) - (2)) shl (2));
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(2);
  j := 0;
  if (mode) = (0) then
  begin
   bufferU[Inc(j)] := $2D;
   bufferU[Inc(j)] := IfThen((N) > ((64) - (5)), (64) - (5), N);
   bufferU[Inc(j)] := buffer[0];
   bufferU[Inc(j)] := buffer[1];
   for i := 0 to (bufferU[1]) - 1 do
   begin
    bufferU[Inc(j)] := buffer[(i) + (2)];
   end;
  end
  else
   if (mode) = (1) then
   begin
    bufferU[Inc(j)] := $2D;
    bufferU[Inc(j)] := IfThen(((N) + (1)) > ((64) - (5)), (64) - (5), (N) + (1));
    bufferU[Inc(j)] := buffer[0];
    bufferU[Inc(j)] := buffer[1];
    bufferU[Inc(j)] := buffer[2];
    for i := 0 to ((bufferU[1]) - (1)) - 1 do
    begin
     bufferU[Inc(j)] := buffer[(i) + (3)];
    end;
   end;
  if (mode) >= (2) then
  begin
   bufferU[Inc(j)] := $31;
   bufferU[Inc(j)] := IfThen((N) > ((64) - (5)), (64) - (5), N);
   for i := 0 to (bufferU[1]) - 1 do
   begin
    bufferU[Inc(j)] := buffer[i];
   end;
   bufferU[Inc(j)] := $32;
   bufferU[Inc(j)] := 8;
   bufferU[Inc(j)] := 0;
  end;
  bufferU[Inc(j)] := $04;
  while (j) < (64) do
  begin
   bufferU[j] := $0;
   Inc(j);
  end;
  PacketIO(20);
  if saveLog then
  begin
   CloseLogFile();
  end;
  if ((bufferI[0]) = ($2D)) or ((bufferI[0]) = ($31)) then
  begin
   if (bufferI[1]) = ($FD) then
   begin
    PrintMessageI2C(strings[S_I2CAckErr]);
   end
   else
    if (bufferI[1]) > ($FA) then
    begin
     PrintMessageI2C(strings[S_InsErr]);
    end
    else
    begin
     n := 2;
     sprintf(str, '> ');
     if (mode) < (2) then
      n := 4;
     for i := 0 to (bufferU[1]) - 1 do
     begin
      sprintf(t, '%02X ', bufferU[(i) + (n)]);
      strcat(str, t);
      if (i) and (((i) mod (16)) = (15)) then
      begin
       strcat(str, '' + #13 + '' + NL + '');
      end;
     end;
     strcat(str, '' + #13 + '' + NL + '');
     PrintMessageI2C(str);
    end;
  end
  else
   PrintMessageI2C(strings[S_ComErr]);
end;

end.
