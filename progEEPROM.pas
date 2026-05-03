unit progEEPROM;
(**
 * progEEPROM.pas
 * 다양한 EEPROM 타입 프로그래밍 알고리즘
 * 원본 C 소스: progEEPROM.c (Copyright (C) 2009-2022 Alberto Maccioni)
 * Free Pascal 변환
 *
 * GNU General Public License v2 이상 적용
 *)

{$MODE OBJFPC}
{$H+}

interface

uses
  SysUtils, common;

{ I2C 메모리 }
procedure ReadI2C(dim: Integer; addr: Integer);
procedure WriteI2C(dim: Integer; addr: Integer; page: Integer);

{ 93x 시리즈 마이크로와이어 메모리 }
procedure Read93x(dim: Integer; na: Integer; options: Integer);
procedure Write93Sx(dim: Integer; na: Integer; page: Integer);
procedure Write93Cx(dim: Integer; na: Integer; options: Integer);

{ 25xx SPI 메모리 }
procedure Read25xx(dim: Integer);
procedure Write25xx(dim: Integer; options: Integer);

{ OneWire 메모리 }
procedure ReadOneWireMem(dim: Integer; options: Integer);
procedure WriteOneWireMem(dim: Integer; options: Integer);
procedure ReadDS1820();

{ 11xx UNIO 메모리 }
procedure Read11xx(dim: Integer);
procedure Write11xx(dim: Integer; page: Integer);

implementation

{ ============================================================
  공용 상수 (instructions.h 에서 가져온 값들이 common 유닛에 있다고 가정)
  실제 프로젝트에서는 common 유닛에 아래 상수들이 정의되어야 합니다.
  ============================================================ }

const
  { 93x 시리즈용 포트 비트 상수 }
  PRE = $08;   { RB3 }
  S   = $10;   { RB4 }
  W_  = $20;   { RB5 - W는 Free Pascal 예약어이므로 W_ 사용 }
  ORG = $20;   { RB5 }

  { 25xx SPI용 포트 비트 상수 }
  CS  = 8;
  HLD = 16;
  WP  = $40;

  { OneWire 명령 }
  READ_ROM             = $33;
  MATCH_ROM            = $55;
  SKIP_ROM             = $CC;
  SEARCH_ROM           = $F0;
  WRITE_SCRATCHPAD_OW  = $0F;
  READ_SCRATCHPAD_OW   = $AA;
  COPY_SCRATCHPAD_OW   = $55;
  READ_MEMORY_OW       = $F0;
  WRITE_APP_REGISTER   = $99;
  READ_STAT_REGISTER   = $66;
  READ_APP_REGISTER    = $C3;
  COPY_LOCK_APP_REGISTER = $5A;
  READ_SCRATCHPAD2     = $BE;
  CONVERT_TEMP         = $44;
  RECALL_EE            = $B8;
  READ_PWSUP           = $B4;

  { UNIO 명령 }
  UNIO_READ  = $03;
  UNIO_CRRD  = $06;
  UNIO_WRITE = $6C;
  UNIO_WREN  = $96;
  UNIO_WRDI  = $91;
  UNIO_RDSR  = $05;
  UNIO_WRSR  = $6E;
  UNIO_ERAL  = $6D;
  UNIO_SETAL = $67;

{ ============================================================
  OneWire 디바이스 ID 테이블
  ============================================================ }
type
  TOW_ID = record
    id: Integer;
    device: string;
  end;

const
  OW_LIST_COUNT = 6;
  OW_LIST: array[0..OW_LIST_COUNT - 1] of TOW_ID = (
    (id: $10; device: 'DS1820'#13#10),
    (id: $14; device: 'DS2430'#13#10),
    (id: $23; device: 'DS2433'#13#10),
    (id: $28; device: 'DS18B20'#13#10),
    (id: $2D; device: 'DS2431'#13#10),
    (id: $43; device: 'DS28EC20'#13#10)
  );

{ ============================================================
  내부 헬퍼 프로시저
  ============================================================ }

procedure OW_ID(id: Integer);
var
  i: Integer;
  s: string;
begin
  for i := 0 to OW_LIST_COUNT - 1 do
  begin
    if id = OW_LIST[i].id then
    begin
      PrintMessage(PChar(OW_LIST[i].device));
      Exit;
    end;
  end;
  s := strings[S_nodev]; { "Unknown device" }
  PrintMessage(PChar(s));
end;

{ ============================================================
  ReadI2C - I2C 메모리 읽기
  dim  = 크기(바이트)
  addr [3:0]  = 0: 1바이트 주소, 1: 2바이트 주소
       [7:4]  = A2:A0 값
       [11:8] = 17번째 주소 비트 위치(컨트롤 바이트에 추가)
  ============================================================ }
procedure ReadI2C(dim: Integer; addr: Integer);
var
  k, z, i, j, inc_: Integer;
  AX, addr17: Integer;
  start_, stop_: LongWord;
  sum: Integer;
begin
  k := 0;
  z := 0;
  AX     := (addr shr 4) and 7;
  addr17 := (addr shr 8) and $F;
  addr   := addr and 1;

  if (dim > $30000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]); { "EEPROM size out of limits" }
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'ReadI2C(%d,%d)    (0x%X,0x%X)'#10, [dim, addr, dim, addr]);
  end;

  sizeEE := dim;
  if memEE <> nil then FreeMem(memEE);
  memEE := GetMem(dim);

  start_ := GetTickCount();
  hvreg  := 0;

  j := 0;
  bufferU[j] := VREG_DIS;    Inc(j);
  bufferU[j] := I2C_INIT;    Inc(j);
  bufferU[j] := AX;          Inc(j);  { 100k }
  bufferU[j] := EN_VPP_VCC;  Inc(j);  { VDD }
  bufferU[j] := $1;          Inc(j);
  bufferU[j] := FLUSH;       Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  { ---- 읽기 ---- }
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();

  i := 0;
  while i < dim do
  begin
    { 64KB 경계 넘지 않도록 처리 }
    if (i < $10000) and (i > $10000 - (DIMBUF - 4)) then
      inc_ := $10000 - i
    else if i < dim - (DIMBUF - 4) then
      inc_ := DIMBUF - 4
    else
      inc_ := dim - i;

    j := 0;
    if addr = 0 then
    begin
      { 1바이트 주소 }
      bufferU[j] := I2C_READ;               Inc(j);
      bufferU[j] := inc_;                   Inc(j);
      bufferU[j] := $A0 + ((i shr 7) and $0E); Inc(j);
      bufferU[j] := i and $FF;              Inc(j);
    end
    else
    begin
      { 2바이트 주소 }
      bufferU[j] := I2C_READ2; Inc(j);
      bufferU[j] := inc_;      Inc(j);
      if i > $FFFF then
        bufferU[j] := $A0 + addr17   { 17번째 비트(64K 초과 시) }
      else
        bufferU[j] := $A0;
      Inc(j);
      bufferU[j] := (i shr 8) and $FF; Inc(j);
      bufferU[j] := i and $FF;         Inc(j);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(8);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> I2C_READ) and (bufferI[j] <> I2C_READ2) do
      Inc(j);
    if (j < DIMBUF - 1) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        memEE[k] := bufferI[z];
        Inc(k); Inc(z);
      end;
    end;

    PrintStatus(strings[S_CodeReading2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    Inc(i, inc_);
  end;

  PrintStatusEnd();

  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
    sizeEE := k;
  end
  else
    PrintMessage(strings[S_Compl]);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $0;         Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  DisplayEE();

  sum := 0;
  for i := 0 to sizeEE - 1 do
    Inc(sum, memEE[i]);
  PrintMessage1('Checksum: 0x%X'#13#10, sum and $FFFF);

  sprintf(str, strings[S_End], [(stop_ - start_) / 1000.0]);
  PrintMessage(str);

  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  WriteI2C - I2C 메모리 쓰기
  dim  = 크기(바이트)
  addr = ReadI2C와 동일한 형식
  page = 페이지 크기
  ============================================================ }
procedure WriteI2C(dim: Integer; addr: Integer; page: Integer);
var
  k, z, i, j, inc_: Integer;
  err: Integer;
  AX, addr17: Integer;
  start_, stop_: LongWord;
  ack: Integer;
begin
  k := 0; z := 0; err := 0;
  AX     := (addr shr 4) and 7;
  addr17 := (addr shr 8) and $F;
  addr   := addr and 1;
  hvreg  := 0;

  if (dim > $30000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'WriteI2C(%d,%d,%d)    (0x%X,0x%X)'#10,
            [dim, addr, page, dim, addr]);
  end;

  if dim > sizeEE then
  begin
    i := sizeEE;
    ReallocMem(memEE, dim);
    while i < dim do begin memEE[i] := $FF; Inc(i); end;
    sizeEE := dim;
  end;

  if dim < 1 then
  begin
    PrintMessage(strings[S_NoCode]);
    Exit;
  end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;   Inc(j);
  bufferU[j] := I2C_INIT;   Inc(j);
  bufferU[j] := AX;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $1;         Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  { ---- 쓰기 ---- }
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();

  while page >= DIMBUF - 6 do page := page shr 1;

  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := I2C_WRITE; Inc(j);
    if addr = 0 then
    begin
      bufferU[j] := page;                        Inc(j);
      bufferU[j] := $A0 + ((i shr 7) and $0E);  Inc(j);
      bufferU[j] := i and $FF;                   Inc(j);
    end
    else
    begin
      bufferU[j] := page + 1; Inc(j);
      if i > $FFFF then bufferU[j] := $A0 + addr17
      else              bufferU[j] := $A0;
      Inc(j);
      bufferU[j] := (i shr 8) and $FF; Inc(j);
      bufferU[j] := i and $FF;         Inc(j);
    end;

    for k := 0 to page - 1 do
    begin
      bufferU[j] := memEE[i + k]; Inc(j);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(3);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> I2C_WRITE) do Inc(j);
    if (bufferI[j] <> I2C_WRITE) or (bufferI[j + 1] >= $FA) then
      i := dim + 10;

    PrintStatus(strings[S_CodeWriting2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    { ACK 폴링 }
    j := 0;
    bufferU[j] := I2C_WRITE; Inc(j);
    bufferU[j] := 0;         Inc(j);
    bufferU[j] := $A0;       Inc(j);
    bufferU[j] := 0;         Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

    ack := $FD;
    j   := 0;
    while (ack = $FD) and (j < 20) do
    begin
      PacketIO(2);
      k := 0;
      while (k < DIMBUF - 1) and (bufferI[k] <> I2C_WRITE) do Inc(k);
      if (bufferI[k] <> I2C_WRITE) or (bufferI[k + 1] >= $FA) then
        ack := $FD
      else
        ack := bufferI[k + 1];
      Inc(j);
    end;
    j := 0;

    Inc(i, page);
  end;

  PrintStatusEnd();
  PrintMessage(strings[S_Compl]);

  { ---- 검증 ---- }
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  k := 0;

  i := 0;
  while i < dim do
  begin
    if (i < $10000) and (i > $10000 - (DIMBUF - 4)) then
      inc_ := $10000 - i
    else if i < dim - (DIMBUF - 4) then
      inc_ := DIMBUF - 4
    else
      inc_ := dim - i;

    j := 0;
    if addr = 0 then
    begin
      bufferU[j] := I2C_READ;                    Inc(j);
      bufferU[j] := inc_;                        Inc(j);
      bufferU[j] := $A0 + ((i shr 7) and $0E);  Inc(j);
      bufferU[j] := i and $FF;                   Inc(j);
    end
    else
    begin
      bufferU[j] := I2C_READ2; Inc(j);
      bufferU[j] := inc_;      Inc(j);
      if i > $FFFF then bufferU[j] := $A0 + addr17
      else              bufferU[j] := $A0;
      Inc(j);
      bufferU[j] := (i shr 8) and $FF; Inc(j);
      bufferU[j] := i and $FF;         Inc(j);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(8);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> I2C_READ) and (bufferI[j] <> I2C_READ2) do
      Inc(j);
    if ((bufferI[j] = I2C_READ) or (bufferI[j] = I2C_READ2)) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        if memEE[k] <> bufferI[z] then
        begin
          PrintMessage(#13#10);
          PrintMessage4(strings[S_CodeVError],
                        i + z - 3, i + z - 3, memEE[k], bufferI[z]);
          Inc(err);
        end;
        Inc(k); Inc(z);
      end;
    end;

    PrintStatus(strings[S_CodeV2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

    if err >= max_err then Break;
    Inc(i, inc_);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
  PrintMessage1(strings[S_ComplErr], err);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $0;         Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  sprintf(str, strings[S_EndErr],
          [(stop_ - start_) / 1000.0, err,
           IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing])]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Read93x - 93Sx6 마이크로와이어 메모리 읽기
  dim     = 크기(바이트)
  na      = 주소 비트 수
  options = 0: x16 구성, 1: x8 구성
  ============================================================ }
procedure Read93x(dim: Integer; na: Integer; options: Integer);
var
  k, z, i, j, x8: Integer;
  dim2: Integer;
  start_, stop_: LongWord;
  sum: Integer;
begin
  k := 0; z := 0;
  hvreg := 0;

  if (dim > $3000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;
  if na > 13 then na := 13;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Read93x(%d,%d,%d)    (0x%X,0x%X)'#10,
            [dim, na, options, dim, na]);
  end;

  x8 := options and 1;
  sizeEE := dim;
  if memEE <> nil then FreeMem(memEE);
  memEE := GetMem(dim);

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := uW_INIT;   Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $1;        Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);
  if x8 <> 0 then bufferU[j] := S
  else             bufferU[j] := S + ORG;
  Inc(j);
  bufferU[j] := 0;   Inc(j);
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  { ---- 읽기 ---- }
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();

  if x8 <> 0 then dim2 := dim
  else             dim2 := dim div 2;

  i := 0;
  while i < dim2 do
  begin
    j := 0;
    while (j < DIMBUF - 14) and (i < dim2) do
    begin
      bufferU[j] := uWTX;            Inc(j);
      bufferU[j] := na + 3;          Inc(j);  { READ }
      bufferU[j] := $C0 + ((i shr (na - 5)) and $1F); Inc(j); { 110aaaaa aaax0000 }
      bufferU[j] := (i shl (13 - na)) and $FF;        Inc(j);
      bufferU[j] := uWRX;            Inc(j);
      if x8 <> 0 then bufferU[j] := 8
      else             bufferU[j] := 16;
      Inc(j);
      bufferU[j] := EXT_PORT;        Inc(j);
      if x8 <> 0 then bufferU[j] := 0
      else             bufferU[j] := ORG;
      Inc(j);
      bufferU[j] := 0; Inc(j);
      bufferU[j] := EXT_PORT; Inc(j);
      if x8 <> 0 then bufferU[j] := S
      else             bufferU[j] := S + ORG;
      Inc(j);
      bufferU[j] := 0; Inc(j);
      Inc(i);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);

    z := 0;
    while z < DIMBUF - 3 do
    begin
      while (bufferI[z] <> uWRX) and (z < DIMBUF - 3) do Inc(z);
      if bufferI[z] = uWRX then
      begin
        if x8 <> 0 then
        begin
          memEE[k] := bufferI[z + 2];
          Inc(k);
        end
        else
        begin
          memEE[k + 1] := bufferI[z + 2];
          memEE[k]     := bufferI[z + 3];
          Inc(k, 2);
        end;
        Inc(z, 3);
      end;
    end;

    PrintStatus(strings[S_CodeReading2], i * 100 div dim2, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
    sizeEE := k;
  end
  else
    PrintMessage(strings[S_Compl]);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EXT_PORT;  Inc(j);
  bufferU[j] := 0;         Inc(j);
  bufferU[j] := 0;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $0;        Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  DisplayEE();

  sum := 0;
  for i := 0 to sizeEE - 1 do Inc(sum, memEE[i]);
  PrintMessage1('Checksum: 0x%X'#13#10, sum and $FFFF);
  sprintf(str, strings[S_End], [(stop_ - start_) / 1000.0]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Write93Sx - 93Sx6 마이크로와이어 메모리 쓰기 (자동 지연)
  dim  = 크기(바이트)
  na   = 주소 비트 수
  page = 페이지 크기(바이트)
  ============================================================ }
procedure Write93Sx(dim: Integer; na: Integer; page: Integer);
var
  k, z, i, j: Integer;
  err: Integer;
  addr: Integer;
  n: Integer;
  start_, stop_: LongWord;
  dim2: Integer;
begin
  k := 0; z := 0; err := 0;
  hvreg := 0;

  if (dim > $1000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;
  if na > 13 then na := 13;
  if page > 48 then page := 48;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Write93Sx(%d,%d,%d)    (0x%X,0x%X)'#10,
            [dim, na, page, dim, na]);
  end;

  if dim > sizeEE then
  begin
    i := sizeEE;
    ReallocMem(memEE, dim);
    while i < dim do begin memEE[i] := $FF; Inc(i); end;
    sizeEE := dim;
  end;

  if dim < 1 then
  begin
    PrintMessage(strings[S_NoCode]);
    Exit;
  end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := 0; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := uW_INIT;   Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := S + W_; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;      Inc(j);  bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $98;        Inc(j);  bufferU[j] := 0; Inc(j);   { EWEN }
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := W_; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := S + W_ + PRE; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;      Inc(j);  bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $98;        Inc(j);  bufferU[j] := 0; Inc(j);   { Prot.reg.enable }
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := W_ + PRE; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := S + W_ + PRE; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;      Inc(j);  bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $FF;        Inc(j);  bufferU[j] := $F0; Inc(j);  { Prot.reg.clear }
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := W_ + PRE; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := S + W_; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;      Inc(j);  bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $98;        Inc(j);  bufferU[j] := 0; Inc(j);   { EWEN }
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := W_; Inc(j);  bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := S + W_ + PRE; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;      Inc(j);  bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $C0;        Inc(j);  bufferU[j] := 0; Inc(j);   { Prot.reg.read }
  bufferU[j] := uWRX;      Inc(j);  bufferU[j] := 10; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := W_ + PRE; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  { ---- 쓰기 ---- }
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();
  addr := 0;
  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := EXT_PORT; Inc(j);
    bufferU[j] := W_;       Inc(j);  { S=0 으로 시작 }
    bufferU[j] := 0;        Inc(j);
    bufferU[j] := EXT_PORT; Inc(j);
    bufferU[j] := S + W_;  Inc(j);
    bufferU[j] := 0;        Inc(j);
    bufferU[j] := uWTX;     Inc(j);
    bufferU[j] := 3;        Inc(j);
    bufferU[j] := $E0;      Inc(j);  { 111aaaaa aaa(a) D 페이지 쓰기 }
    bufferU[j] := uWTX;     Inc(j);
    bufferU[j] := na;       Inc(j);
    bufferU[j] := addr shr 8; Inc(j);
    if na > 8 then
    begin
      bufferU[j] := addr and $FF; Inc(j);
    end;
    bufferU[j] := uWTX;       Inc(j);
    bufferU[j] := 8 * page;   Inc(j);
    k := 0;
    while k < page do
    begin
      bufferU[j] := memEE[i + k + 1]; Inc(j);
      bufferU[j] := memEE[i + k];     Inc(j);
      Inc(k, 2);
    end;
    bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := W_;      Inc(j);  bufferU[j] := 0; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j);  bufferU[j] := S + W_;  Inc(j);  bufferU[j] := 0; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> uWTX) do Inc(j);
    if (bufferI[j] <> uWTX) or (bufferI[j + 1] >= $FA) then i := dim + 10;

    { 준비 완료 대기 }
    bufferU[j] := uWRX;  Inc(j);
    bufferU[j] := 1;     Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

    z := 0; k := 0;
    while (z < 30) and (k = 0) do
    begin
      PacketIO(2);
      j := 0;
      while (j < DIMBUF - 1) and (bufferI[j] <> uWRX) do Inc(j);
      if bufferI[j] = uWRX then k := bufferI[j + 2];
      Inc(z);
    end;

    j := 0;
    PrintStatus(strings[S_CodeWriting2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    Inc(i, page);
    Inc(addr, ($10000 shr na) * page div 2);
  end;

  PrintStatusEnd();
  PrintMessage(strings[S_Compl]);

  { ---- 검증 ---- }
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  j := 0;
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := S; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;     Inc(j); bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $C0;       Inc(j); bufferU[j] := 0; Inc(j);  { READ 16bit }
  bufferU[j] := FLUSH;    Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  k := 0;
  n := DIMBUF - 2;
  if n > 30 then n := 30;  { 최대 240비트 = 30바이트 }
  dim2 := dim;

  i := 0;
  while i < dim2 do
  begin
    j := 0;
    if i < dim2 - n then bufferU[j] := n * 8
    else                 bufferU[j] := (dim2 - i) * 8;
    { Note: C 원본에서 버퍼 앞에 uWRX 명령을 먼저 넣음 }
    bufferU[0] := uWRX;
    bufferU[1] := bufferU[j];
    j := 2;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);

    j := 0;
    while (bufferI[j] <> uWRX) and (j < DIMBUF - 1) do Inc(j);
    if bufferI[j] = uWRX then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1] div 8) and (z < DIMBUF) do
      begin
        if memEE[k + 1] <> bufferI[z] then
        begin
          PrintMessage(#13#10);
          PrintMessage4(strings[S_CodeVError], i + z - 3, i + z - 3, memEE[k + 1], bufferI[z]);
          Inc(err);
        end;
        if memEE[k] <> bufferI[z + 1] then
        begin
          PrintMessage(#13#10);
          PrintMessage4(strings[S_CodeVError], i + z - 3, i + z - 3, memEE[k], bufferI[z + 1]);
          Inc(err);
        end;
        Inc(z, 2); Inc(k, 2);
      end;
    end;

    PrintStatus(strings[S_CodeV2], i * 100 div dim2, i);
    if RWstop <> 0 then i := dim2;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

    if err >= max_err then Break;
    Inc(i, n);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
  PrintMessage1(strings[S_ComplErr], err);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  sprintf(str, strings[S_EndErr],
          [(stop_ - start_) / 1000.0, err,
           IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing])]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Write93Cx - 93Cx6 마이크로와이어 메모리 쓰기
  dim     = 크기(바이트)
  na      = 주소 비트 수
  options = 0: x16 구성, 1: x8 구성
  ============================================================ }
procedure Write93Cx(dim: Integer; na: Integer; options: Integer);
var
  k, z, i, j: Integer;
  err: Integer;
  addr: Integer;
  start_, stop_: LongWord;
  dim2: Integer;
  org_bit, s_org_bit: Byte;
begin
  k := 0; z := 0; err := 0;
  hvreg := 0;

  if (dim > $1000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;
  if na > 13 then na := 13;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Write93Cx(%d,%d,%d)    (0x%X,0x%X)'#10,
            [dim, na, options, dim, na]);
  end;

  if dim > sizeEE then
  begin
    i := sizeEE;
    ReallocMem(memEE, dim);
    while i < dim do begin memEE[i] := $FF; Inc(i); end;
    sizeEE := dim;
  end;
  if dim < 1 then
  begin
    PrintMessage(strings[S_NoCode]);
    Exit;
  end;

  { x16이면 ORG 비트 포함, x8이면 미포함 }
  if options = 0 then begin org_bit := ORG + PRE;   s_org_bit := S + ORG + PRE; end
  else                begin org_bit := PRE;          s_org_bit := S + PRE;       end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;   Inc(j);
  bufferU[j] := EXT_PORT;   Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uW_INIT;    Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;    Inc(j);
  { EWEN }
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := s_org_bit; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;     Inc(j); bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $98;       Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := org_bit; Inc(j); bufferU[j] := 0; Inc(j);
  { ERAL }
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := s_org_bit; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uWTX;     Inc(j); bufferU[j] := na + 3; Inc(j);
  bufferU[j] := $90;       Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := org_bit; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := s_org_bit; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := uWRX;     Inc(j); bufferU[j] := 1; Inc(j);
  bufferU[j] := FLUSH;    Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  j := 0;
  bufferU[j] := uWRX;  Inc(j); bufferU[j] := 1; Inc(j);
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

  i := 0; k := 0;
  while (i < 30) and (k = 0) do
  begin
    PacketIO(2);
    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> uWRX) do Inc(j);
    if bufferI[j] = uWRX then k := bufferI[j + 2];
    Inc(i);
  end;

  { ---- 쓰기 ---- }
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();
  addr := 0;
  j    := 0;

  if options = 0 then i := 0
  else                i := 0;

  while i < dim do
  begin
    if (memEE[i] < $FF) or ((options = 0) and (memEE[i + 1] < $FF)) then
    begin
      bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := org_bit; Inc(j); bufferU[j] := 0; Inc(j);
      bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := s_org_bit; Inc(j); bufferU[j] := 0; Inc(j);
      bufferU[j] := uWTX;     Inc(j); bufferU[j] := 3; Inc(j);
      bufferU[j] := $A0;       Inc(j);  { 101aaaaa 쓰기 }
      bufferU[j] := uWTX;     Inc(j); bufferU[j] := na; Inc(j);
      bufferU[j] := addr shr 8; Inc(j);
      if na > 8 then begin bufferU[j] := addr and $FF; Inc(j); end;
      bufferU[j] := uWTX; Inc(j);
      if options = 0 then
      begin  { x16 }
        bufferU[j] := 16;         Inc(j);
        bufferU[j] := memEE[i+1]; Inc(j);
        bufferU[j] := memEE[i];   Inc(j);
      end
      else
      begin  { x8 }
        bufferU[j] := 8;       Inc(j);
        bufferU[j] := memEE[i]; Inc(j);
      end;
      bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := org_bit; Inc(j); bufferU[j] := 0; Inc(j);
      bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := s_org_bit; Inc(j); bufferU[j] := 0; Inc(j);
      bufferU[j] := uWRX;     Inc(j); bufferU[j] := 1; Inc(j);
      bufferU[j] := FLUSH;    Inc(j);
      while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
      PacketIO(2);

      PrintStatus(strings[S_CodeWriting2], i * 100 div dim, i);
      if RWstop <> 0 then i := dim;

      if saveLog <> 0 then
        fprintf(logfile, strings[S_Log7], [i, i, k, k]);

      { 준비 완료 대기 }
      j := 0;
      bufferU[j] := uWRX;  Inc(j); bufferU[j] := 1; Inc(j);
      bufferU[j] := FLUSH; Inc(j);
      while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

      z := 0; k := 0;
      while (z < 30) and (k = 0) do
      begin
        PacketIO(2);
        j := 0;
        while (j < DIMBUF - 1) and (bufferI[j] <> uWRX) do Inc(j);
        if bufferI[j] = uWRX then k := bufferI[j + 2];
        Inc(z);
      end;
      j := 0;
    end;

    if options = 0 then Inc(i, 2)
    else                Inc(i, 1);
    Inc(addr, $10000 shr na);
  end;

  msDelay(2);
  PrintStatusEnd();
  if i <> dim then
    PrintMessage2(strings[S_CodeWError4], i, dim)
  else
    PrintMessage(strings[S_Compl]);

  { ---- 검증 ---- }
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  j := 0;
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := org_bit;   Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT; Inc(j); bufferU[j] := s_org_bit; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := FLUSH;    Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  k := 0;
  if options = 0 then dim2 := dim div 2
  else                dim2 := dim;

  i := 0;
  while i < dim2 do
  begin
    j := 0;
    while (j < DIMBUF - 14) and (i < dim2) do
    begin
      bufferU[j] := uWTX;   Inc(j); bufferU[j] := na + 3; Inc(j);
      bufferU[j] := $C0 + ((i shr (na - 5)) and $1F); Inc(j);
      bufferU[j] := (i shl (13 - na)) and $FF;        Inc(j);
      bufferU[j] := uWRX;   Inc(j);
      if options = 0 then bufferU[j] := 16
      else                bufferU[j] := 8;
      Inc(j);
      bufferU[j] := EXT_PORT; Inc(j);
      if options = 0 then bufferU[j] := ORG
      else                bufferU[j] := 0;
      Inc(j);
      bufferU[j] := 0; Inc(j);
      bufferU[j] := EXT_PORT; Inc(j);
      if options = 0 then bufferU[j] := S + ORG
      else                bufferU[j] := S;
      Inc(j);
      bufferU[j] := 0; Inc(j);
      Inc(i);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);

    z := 0;
    while z < DIMBUF - 3 do
    begin
      while (bufferI[z] <> uWRX) and (z < DIMBUF - 3) do Inc(z);
      if bufferI[z] = uWRX then
      begin
        if options = 1 then
        begin  { x8 }
          if memEE[k] <> bufferI[z + 2] then
          begin
            PrintMessage(#13#10);
            PrintMessage4(strings[S_CodeVError], k, k, memEE[k], bufferI[z + 2]);
            Inc(err);
          end;
          Inc(k);
        end
        else
        begin  { x16 }
          if memEE[k] <> bufferI[z + 3] then
          begin
            PrintMessage(#13#10);
            PrintMessage4(strings[S_CodeVError], k, k, memEE[k], bufferI[z + 3]);
            Inc(err);
          end;
          if memEE[k + 1] <> bufferI[z + 2] then
          begin
            PrintMessage(#13#10);
            PrintMessage4(strings[S_CodeVError], k + 1, k + 1, memEE[k + 1], bufferI[z + 2]);
            Inc(err);
          end;
          Inc(k, 2);
        end;
        Inc(z, 3);
      end;
    end;

    PrintStatus(strings[S_CodeV2], i * 100 div dim2, i);
    if RWstop <> 0 then i := dim2;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

    if err >= max_err then Break;
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
  PrintMessage1(strings[S_ComplErr], err);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  sprintf(str, strings[S_EndErr],
          [(stop_ - start_) / 1000.0, err,
           IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing])]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Read25xx - 25xx SPI 메모리 읽기
  dim = 크기(바이트)
  ============================================================ }
procedure Read25xx(dim: Integer);
var
  k, z, i, j: Integer;
  ID: Integer;
  start_, stop_: LongWord;
  sum: Integer;
begin
  k := 0; z := 0;
  hvreg := 0;

  if (dim > $1000000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Read25xx(%d)    (0x%X)'#10, [dim, dim]);
  end;

  sizeEE := dim;
  if memEE <> nil then FreeMem(memEE);
  memEE := GetMem(dim);

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := SPI_INIT;  Inc(j);
  bufferU[j] := 3;         Inc(j);  { 0=100k, 1=200k, 2=300k, 3=500k }
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := 0; Inc(j); { CS=1,HLD=1,WP=0 }
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := 0; Inc(j); { CS=0 }
  bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := $9F; Inc(j); { READ ID }
  bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 3; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := SPI_WRITE; Inc(j);
  if dim > $10000 then
  begin  { 24비트 주소 }
    bufferU[j] := 4; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else if dim > $200 then
  begin  { 16비트 주소 }
    bufferU[j] := 3; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else
  begin  { 8비트 주소 }
    bufferU[j] := 2; Inc(j); bufferU[j] := 3; Inc(j); bufferU[j] := 0; Inc(j);
  end;
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  z := 0;
  while (z < DIMBUF - 4) and (bufferI[z] <> SPI_READ) do Inc(z);
  ID := (bufferI[z + 2] shl 16) + (bufferI[z + 3] shl 8) + bufferI[z + 4];
  if (ID > 0) and (ID <> $FFFFFF) then
    PrintMessage1('DEVICE ID=0x%06X'#13#10, ID);

  { ---- 읽기 ---- }
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();

  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := SPI_READ; Inc(j);
    if i < dim - (DIMBUF - 4) then bufferU[j] := DIMBUF - 4
    else                           bufferU[j] := dim - i;
    Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(4);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> SPI_READ) do Inc(j);
    if (bufferI[j] = SPI_READ) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        memEE[k] := bufferI[z]; Inc(k); Inc(z);
      end;
    end;

    PrintStatus(strings[S_CodeReading2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    Inc(i, DIMBUF - 4);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
    sizeEE := k;
  end
  else
    PrintMessage(strings[S_Compl]);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  DisplayEE();

  sum := 0;
  for i := 0 to sizeEE - 1 do Inc(sum, memEE[i]);
  PrintMessage1('Checksum: 0x%X'#13#10, sum and $FFFF);
  sprintf(str, strings[S_End], [(stop_ - start_) / 1000.0]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Write25xx - SPI 메모리 쓰기
  dim     = 크기(바이트)
  options [11:0] = 페이지 크기
          [12]   = 쓰기 전 지우기
          [13]   = 상태 레지스터 2 사용
  ============================================================ }
procedure Write25xx(dim: Integer; options: Integer);
var
  k, z, i, j: Integer;
  err: Integer;
  page: Integer;
  ID: Integer;
  pp: Integer;
  i0, k2, valid: Integer;
  start_, stop_: LongWord;
begin
  k := 0; z := 0; err := 0;
  hvreg := 0;
  page  := options and $FFF;

  if (dim > $1000000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Write25xx(%d,%d)    (0x%X,0x%X)'#10, [dim, options, dim, options]);
  end;

  if dim > sizeEE then
  begin
    i := sizeEE;
    ReallocMem(memEE, dim);
    while i < dim do begin memEE[i] := $FF; Inc(i); end;
    sizeEE := dim;
  end;
  if dim < 1 then
  begin
    PrintMessage(strings[S_NoCode]);
    Exit;
  end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := SPI_INIT;  Inc(j); bufferU[j] := 3; Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := $9F; Inc(j); { READ ID }
  bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 3; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 5; Inc(j); { READ STATUS }
  bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
  if (options and $2000) <> 0 then
  begin
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := $35; Inc(j); { READ STATUS2 }
    bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
  end;
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  j := 0;
  z := 0;
  while (z < DIMBUF - 4) and (bufferI[z] <> SPI_READ) do Inc(z);
  ID := (bufferI[z + 2] shl 16) + (bufferI[z + 3] shl 8) + bufferI[z + 4];
  if (ID > 0) and (ID <> $FFFFFF) then
  begin
    PrintMessage1('DEVICE ID=0x%06X'#13#10, ID);
    if saveLog <> 0 then fprintf(logfile, 'DEVICE ID=0x%06X'#10, [ID]);
  end;

  msDelay(10);

  { WRITE ENABLE + WRITE STATUS(해제) }
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD; Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 6; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD; Inc(j); bufferU[j] := WP; Inc(j);
  if (options and $2000) <> 0 then
  begin
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := 1; Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else
  begin
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 2; Inc(j);
    bufferU[j] := 1; Inc(j); bufferU[j] := 0; Inc(j);
  end;
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 5; Inc(j);
  bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);
  j := 0;

  { 칩 지우기 (옵션) }
  if (options and $1000) <> 0 then
  begin
    PrintMessage(strings[S_StartErase]);
    if saveLog <> 0 then fprintf(logfile, '%s'#10, [strings[S_StartErase]]);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 5; Inc(j);
    bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    if (options and $2000) <> 0 then
    begin
      bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
      bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := $35; Inc(j);
      bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
      bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    end;
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 6; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := $C7; Inc(j); { CHIP ERASE }
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(5);
    j := 0;

    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 5; Inc(j);
    bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

    pp := 1; j := 0;
    while (pp <> 0) and (j < 400) do  { 최대 40초 대기 }
    begin
      PacketIO(2);
      msDelay(100);
      z := 0;
      while (z < DIMBUF - 1) and (bufferI[z] <> SPI_READ) do Inc(z);
      pp := bufferI[z + 2] and 1;  { WIP 비트 }
      PrintStatus(strings[S_StartErase], 0, 0);
      Inc(j);
    end;
    if saveLog <> 0 then fprintf(logfile, 'Erase time %d ms'#10, [j * 100]);
    PrintMessage(strings[S_Compl]);
    PrintStatus(strings[S_Compl], 0, 0);
  end;

  { ---- 쓰기 ---- }
  PrintMessage(strings[S_EEAreaW]);
  if saveLog <> 0 then fprintf(logfile, '%s'#10, [strings[S_EEAreaW]]);

  i := 0;
  while i < dim do
  begin
    j := 0;
    if (options and $1000) <> 0 then
    begin  { 칩 지우기 후: 빈 페이지 건너뜀 }
      while i < dim - page do
      begin
        k := page;
        while k = page do
        begin
          k := 0;
          while k < page do
          begin
            if memEE[i + k] < $FF then k := page;  { 비어있지 않음 }
            Inc(k);
          end;
          if k = page then Inc(i, page);
        end;
        Break;  { 내부 루프 종료 }
      end;
    end;

    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 6; Inc(j); { WRITE ENABLE }
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j);
    if dim > $10000 then
    begin
      bufferU[j] := 4; Inc(j); bufferU[j] := 2; Inc(j);
      bufferU[j] := i shr 16;        Inc(j);
      bufferU[j] := (i shr 8) and $FF; Inc(j);
      bufferU[j] := i and $FF;       Inc(j);
    end
    else if dim > $200 then
    begin
      bufferU[j] := 3; Inc(j); bufferU[j] := 2; Inc(j);
      bufferU[j] := i shr 8;  Inc(j);
      bufferU[j] := i and $FF; Inc(j);
    end
    else
    begin
      bufferU[j] := 2; Inc(j);
      bufferU[j] := 2 + IfThen((i and $100) <> 0, 8, 0); Inc(j);
      bufferU[j] := i and $FF; Inc(j);
    end;

    pp := IfThen(page < DIMBUF - j - 4, page, DIMBUF - j - 4);
    k := 0;
    while k < page do
    begin
      bufferU[j] := SPI_WRITE; Inc(j);
      bufferU[j] := pp;        Inc(j);
      while (k < page) and (pp > 0) do
      begin
        bufferU[j] := memEE[i + k]; Inc(j);
        Inc(k); Dec(pp);
      end;
      bufferU[j] := FLUSH; Inc(j);
      while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
      PacketIO(2);
      z := 0;
      while (z < DIMBUF - 1) and (bufferI[z] <> SPI_WRITE) do Inc(z);
      if bufferI[z + 1] >= $FA then
      begin
        k := i; i := dim + 10;
        k := page;  { 루프 종료 }
      end;
      pp := IfThen((page - k) < DIMBUF - 4, page - k, DIMBUF - 4);
      j := 0;
    end;

    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 5; Inc(j);
    bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);
    j := 0;

    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := SPI_WRITE; Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := 5; Inc(j);
    bufferU[j] := SPI_READ;  Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

    pp := 1; j := 0;
    while (pp <> 0) and (j < 50) do  { 쓰기 완료 대기 }
    begin
      PacketIO(2);
      z := 0;
      while (z < DIMBUF - 1) and (bufferI[z] <> SPI_READ) do Inc(z);
      pp := bufferI[z + 2] and 1;
      Inc(j);
    end;

    PrintStatus(strings[S_CodeWriting2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, 0, 0]);

    j := 0;
    Inc(i, page);
  end;

  PrintStatusEnd();
  PrintMessage(strings[S_Compl]);

  { ---- 검증 ---- }
  PrintMessage(strings[S_EEV]);
  if saveLog <> 0 then fprintf(logfile, '%s'#10, [strings[S_EEV]]);
  PrintStatusSetup();

  j := 0;
  bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := SPI_WRITE; Inc(j);
  if dim > $10000 then
  begin
    bufferU[j] := 4; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else if dim > $200 then
  begin
    bufferU[j] := 3; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else
  begin
    bufferU[j] := 2; Inc(j); bufferU[j] := 3; Inc(j); bufferU[j] := 0; Inc(j);
  end;
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  k := 0;
  i := 0;
  while i < dim do
  begin
    j := 0;
    if (options and $1000) <> 0 then
    begin
      i0 := i;
      valid := 0;
      while (valid = 0) and (i < dim) do
      begin
        k2 := 0;
        while (k2 < DIMBUF - 4) and (valid = 0) and (i + k2 < dim) do
        begin
          if memEE[i + k2] < $FF then valid := 1;
          Inc(k2);
        end;
        if valid = 0 then Inc(i, DIMBUF - 4);
      end;
      if i >= dim then Break;
      if i > i0 then
      begin
        j := 0;
        bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := CS + HLD; Inc(j); bufferU[j] := WP; Inc(j);
        bufferU[j] := EXT_PORT;  Inc(j); bufferU[j] := HLD;      Inc(j); bufferU[j] := 0;  Inc(j);
        bufferU[j] := SPI_WRITE; Inc(j);
        if dim > $10000 then
        begin
          bufferU[j] := 4; Inc(j); bufferU[j] := 3; Inc(j);
          bufferU[j] := i shr 16;          Inc(j);
          bufferU[j] := (i shr 8) and $FF; Inc(j);
          bufferU[j] := i and $FF;         Inc(j);
        end
        else if dim > $200 then
        begin
          bufferU[j] := 3; Inc(j); bufferU[j] := 3; Inc(j);
          bufferU[j] := i shr 8;  Inc(j);
          bufferU[j] := i and $FF; Inc(j);
        end
        else
        begin
          bufferU[j] := 2; Inc(j);
          bufferU[j] := 3 + IfThen((i and $100) <> 0, 8, 0); Inc(j);
          bufferU[j] := i and $FF; Inc(j);
        end;
        bufferU[j] := FLUSH; Inc(j);
        while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
        PacketIO(2);
        j := 0;
      end;
    end;

    bufferU[j] := SPI_READ; Inc(j);
    if i < dim - (DIMBUF - 4) then bufferU[j] := DIMBUF - 4
    else                           bufferU[j] := dim - i;
    Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(4);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> SPI_READ) do Inc(j);
    if (bufferI[j] = SPI_READ) and (bufferI[j + 1] < $FA) then
    begin
      z := 0;
      while (z < bufferI[j + 1]) and (z < DIMBUF) do
      begin
        if memEE[i + z] <> bufferI[z + j + 2] then
        begin
          PrintMessage4(strings[S_CodeVError], i + z, i + z, memEE[i + z], bufferI[z + 3]);
          Inc(err);
        end;
        Inc(z);
      end;
    end;

    PrintStatus(strings[S_CodeV2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;

    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

    if err >= max_err then Break;
    Inc(i, DIMBUF - 4);
    j := 0;
  end;

  PrintStatusEnd();
  if i < dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, i);
  end;
  PrintMessage1(strings[S_ComplErr], err);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  sprintf(str, strings[S_EndErr],
          [(stop_ - start_) / 1000.0, err,
           IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing])]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  ReadOneWireMem - OneWire 메모리 읽기
  dim     = 크기(바이트)
  options = 1: 상태 레지스터 + 앱 레지스터
            2: 보호 바이트 + ID
  ============================================================ }
procedure ReadOneWireMem(dim: Integer; options: Integer);
var
  k, z, i, j: Integer;
  start_, stop_: LongWord;
  sum: Integer;
begin
  k := 0; z := 0;
  hvreg := 0;

  if FWVersion < $800 then
  begin
    PrintMessage1(strings[S_FWver2old], '0.8.0');
    Exit;
  end;
  if (dim > $10000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'ReadOneWireMem(%d)    (0x%X)'#10, [dim, dim]);
  end;

  sizeEE := dim;
  if memEE <> nil then FreeMem(memEE);
  memEE := GetMem(dim);

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := uW_INIT;   Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := OW_RESET;  Inc(j);
  bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := READ_ROM; Inc(j);
  bufferU[j] := OW_READ;   Inc(j); bufferU[j] := 8; Inc(j);
  if dim <= 32 then
  begin  { 1바이트 주소 }
    bufferU[j] := OW_WRITE; Inc(j); bufferU[j] := 2; Inc(j);
    bufferU[j] := READ_MEMORY_OW; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else
  begin  { 2바이트 주소 }
    bufferU[j] := OW_WRITE; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := READ_MEMORY_OW; Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end;
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(12);
  j := 0;

  z := 0;
  while (bufferI[z] <> OW_RESET) and (z < DIMBUF) do Inc(z);
  if (bufferI[z] = OW_RESET) and (bufferI[z + 1] = 0) then
  begin
    PrintMessage(strings[S_ComErr]);
    bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
    bufferU[j] := FLUSH;      Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);
    Exit;
  end;

  while (bufferI[z] <> OW_READ) and (z < DIMBUF) do Inc(z);
  if (bufferI[z] = OW_READ) and (z < DIMBUF - 9) then
  begin
    PrintMessage1('Family code: 0x%02X ', bufferI[z + 2]);
    OW_ID(bufferI[z + 2]);
    PrintMessage3('Serial ID: 0x%02X%02X%02X', bufferI[z+3], bufferI[z+4], bufferI[z+5]);
    PrintMessage3('%02X%02X%02X', bufferI[z+6], bufferI[z+7], bufferI[z+8]);
    PrintMessage1(#13#10'CRC: 0x%02X'#13#10, bufferI[z + 9]);
  end;

  { ---- 읽기 ---- }
  PrintStatusSetup();
  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := OW_READ; Inc(j);
    if i < dim - (DIMBUF - 4) then bufferU[j] := DIMBUF - 4
    else                           bufferU[j] := dim - i;
    Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(37);

    j := 0;
    while (bufferI[j] <> OW_READ) and (j < DIMBUF) do Inc(j);
    if (bufferI[j] = OW_READ) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        memEE[k] := bufferI[z]; Inc(k); Inc(z);
      end;
    end;
    PrintStatus(strings[S_CodeReading2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;
    j := 0;
    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    Inc(i, DIMBUF - 4);
  end;

  { 상태/앱 레지스터 읽기 (options=1) }
  if options = 1 then
  begin
    j := 0;
    bufferU[j] := OW_RESET;  Inc(j);
    bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := SKIP_ROM;  Inc(j); bufferU[j] := READ_STAT_REGISTER; Inc(j); bufferU[j] := 0; Inc(j);
    bufferU[j] := OW_READ;   Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := OW_RESET;  Inc(j);
    bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := SKIP_ROM;  Inc(j); bufferU[j] := READ_APP_REGISTER; Inc(j); bufferU[j] := 0; Inc(j);
    bufferU[j] := OW_READ;   Inc(j); bufferU[j] := 8; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(15);
    j := 0;

    z := 0;
    while (bufferI[z] <> OW_READ) and (z < DIMBUF - 2) do Inc(z);
    if z < DIMBUF - 2 then
      PrintMessage1('Status register: 0x%02X'#13#10, bufferI[z + 2]);
    Inc(z, 2);
    while (bufferI[z] <> OW_READ) and (z < DIMBUF - 10) do Inc(z);
    PrintMessage('Application register: 0x');
    i := z + 2;
    while i < z + 10 do
    begin
      PrintMessage1('%02X', bufferI[i]);
      Inc(i);
    end;
    PrintMessage(#13#10);
  end
  else if options = 2 then
  begin
    j := 0;
    bufferU[j] := OW_READ; Inc(j);
    if dim = $A00 then bufferU[j] := $24
    else               bufferU[j] := 8;
    Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(25);
    j := 0;

    z := 0;
    while (bufferI[z] <> OW_READ) and (z < DIMBUF - 2) do Inc(z);
    if (bufferI[z] = OW_READ) and (bufferI[z + 1] < $FA) then
    begin
      if dim = $A00 then
      begin
        for i := 0 to 9 do
          PrintMessage2('Protection Control Byte Block %d: 0x%02X'#13#10, i, bufferI[z+2+i]);
        PrintMessage('User EEPROM:'#13#10);
        for i := 0 to 9 do PrintMessage1('%02X', bufferI[z+2+i+10]);
        PrintMessage(#13#10);
        for i := 0 to 9 do PrintMessage1('%02X', bufferI[z+2+i+20]);
        PrintMessage1(#13#10'Memory Block Lock: 0x%02X'#13#10, bufferI[z+2+30]);
        PrintMessage1('Register Page Lock: 0x%02X'#13#10, bufferI[z+2+31]);
        PrintMessage1('Factory Byte: 0x%02X'#13#10, bufferI[z+2+32]);
        PrintMessage2('Factory Trim Bytes: 0x%02X%02X'#13#10, bufferI[z+2+33], bufferI[z+2+34]);
        PrintMessage2('Manufacturer ID: 0x%02X%02X'#13#10, bufferI[z+2+35], bufferI[z+2+36]);
      end
      else
      begin
        PrintMessage1('Protection Control Byte Page 0: 0x%02X'#13#10, bufferI[z+2]);
        PrintMessage1('Protection Control Byte Page 1: 0x%02X'#13#10, bufferI[z+3]);
        PrintMessage1('Protection Control Byte Page 2: 0x%02X'#13#10, bufferI[z+4]);
        PrintMessage1('Protection Control Byte Page 3: 0x%02X'#13#10, bufferI[z+5]);
        PrintMessage1('Copy Protection Byte: 0x%02X'#13#10, bufferI[z+6]);
        PrintMessage1('Factory Byte: 0x%02X'#13#10, bufferI[z+7]);
        PrintMessage2('User Bytes/Manufacturer ID: 0x%02X%02X'#13#10, bufferI[z+8], bufferI[z+9]);
      end;
    end;
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
    sizeEE := k;
  end;

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  DisplayEE();

  sum := 0;
  for i := 0 to sizeEE - 1 do Inc(sum, memEE[i]);
  PrintMessage1('Checksum: 0x%X'#13#10, sum and $FFFF);
  sprintf(str, strings[S_End], [(stop_ - start_) / 1000.0]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  WriteOneWireMem - OneWire 메모리 쓰기
  dim     = 크기(바이트)
  options = 0: 8바이트 스크래치패드
            1: 32바이트 스크래치패드
  ============================================================ }
procedure WriteOneWireMem(dim: Integer; options: Integer);
var
  k, z, i, j: Integer;
  err: Integer;
  page_: Integer;
  start_, stop_: LongWord;
begin
  k := 0; z := 0; err := 0;
  hvreg := 0;

  if FWVersion < $800 then
  begin
    PrintMessage1(strings[S_FWver2old], '0.8.0');
    Exit;
  end;
  if (dim > $10000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'WriteOneWireMem(%d,%d)    (0x%X,0x%X)'#10, [dim, options, dim, options]);
  end;

  if dim > sizeEE then
  begin
    i := sizeEE;
    ReallocMem(memEE, dim);
    while i < dim do begin memEE[i] := $FF; Inc(i); end;
    sizeEE := dim;
  end;
  if dim < 1 then
  begin
    PrintMessage(strings[S_NoCode]);
    Exit;
  end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := uW_INIT;   Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := OW_RESET;  Inc(j);
  bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := READ_ROM; Inc(j);
  bufferU[j] := OW_READ;   Inc(j); bufferU[j] := 8; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(12);
  j := 0;

  z := 0;
  while (bufferI[z] <> OW_RESET) and (z < DIMBUF) do Inc(z);
  if (bufferI[z] = OW_RESET) and (bufferI[z + 1] = 0) then
  begin
    PrintMessage(strings[S_ComErr]);
    bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
    bufferU[j] := FLUSH;      Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);
    j := 0;
    if saveLog <> 0 then CloseLogFile();
    Exit;
  end;

  z := 0;
  while (bufferI[z] <> OW_READ) and (z < DIMBUF) do Inc(z);
  if bufferI[z] = OW_READ then
  begin
    PrintMessage1('Family code: 0x%02X ', bufferI[z + 2]);
    OW_ID(bufferI[z + 2]);
    PrintMessage3('Serial ID: 0x%02X%02X%02X', bufferI[z+3], bufferI[z+4], bufferI[z+5]);
    PrintMessage3('%02X%02X%02X', bufferI[z+6], bufferI[z+7], bufferI[z+8]);
    PrintMessage1(#13#10'CRC: 0x%02X'#13#10, bufferI[z + 9]);
  end;

  { ---- 쓰기 ---- }
  PrintMessage(strings[S_EEAreaW]);
  if options = 0 then page_ := 8
  else                page_ := 32;

  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := OW_RESET;  Inc(j);
    bufferU[j] := OW_WRITE;  Inc(j);
    if dim <= 32 then bufferU[j] := page_ + 3
    else              bufferU[j] := page_ + 4;
    Inc(j);
    bufferU[j] := SKIP_ROM;         Inc(j);
    bufferU[j] := WRITE_SCRATCHPAD_OW; Inc(j);
    bufferU[j] := i and $FF;        Inc(j);
    if dim > 32 then begin bufferU[j] := i shr 8; Inc(j); end;
    for k := 0 to page_ - 1 do begin bufferU[j] := memEE[i + k]; Inc(j); end;
    bufferU[j] := OW_RESET;  Inc(j);
    bufferU[j] := OW_WRITE;  Inc(j);
    if dim <= 32 then bufferU[j] := 3
    else              bufferU[j] := 5;
    Inc(j);
    bufferU[j] := SKIP_ROM;        Inc(j);
    bufferU[j] := COPY_SCRATCHPAD_OW; Inc(j);
    if dim <= 32 then
    begin
      bufferU[j] := $A5; Inc(j);
    end
    else
    begin
      bufferU[j] := i and $FF;  Inc(j);
      bufferU[j] := i shr 8;   Inc(j);
      bufferU[j] := page_ - 1; Inc(j);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(Round(6 + 0.8 * page_));
    msDelay(10);
    j := 0;

    PrintStatus(strings[S_CodeWriting2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;
    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, 0, 0]);

    Inc(i, page_);
  end;

  PrintStatusEnd();
  PrintMessage(strings[S_Compl]);

  { ---- 검증 ---- }
  PrintMessage(strings[S_EEV]);
  if saveLog <> 0 then fprintf(logfile, '%s'#10, [strings[S_EEV]]);
  PrintStatusSetup();
  k := 0;

  bufferU[j] := OW_RESET;  Inc(j);
  bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := SKIP_ROM; Inc(j);
  if dim <= 32 then
  begin
    bufferU[j] := OW_WRITE; Inc(j); bufferU[j] := 2; Inc(j);
    bufferU[j] := READ_MEMORY_OW; Inc(j); bufferU[j] := 0; Inc(j);
  end
  else
  begin
    bufferU[j] := OW_WRITE; Inc(j); bufferU[j] := 3; Inc(j);
    bufferU[j] := READ_MEMORY_OW; Inc(j); bufferU[j] := 0; Inc(j); bufferU[j] := 0; Inc(j);
  end;
  bufferU[j] := FLUSH; Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(10);
  j := 0;

  i := 0;
  while i < dim do
  begin
    bufferU[j] := OW_READ; Inc(j);
    if i < dim - (DIMBUF - 4) then bufferU[j] := DIMBUF - 4
    else                           bufferU[j] := dim - i;
    Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(37);

    j := 0;
    while (bufferI[j] <> OW_READ) and (j < DIMBUF) do Inc(j);
    if (bufferI[j] = OW_READ) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        if memEE[k] <> bufferI[z] then
        begin
          PrintMessage(#13#10);
          PrintMessage4(strings[S_CodeVError],
                        i + z - (j + 2), i + z - (j + 2), memEE[k], bufferI[z]);
          Inc(err);
        end;
        Inc(k); Inc(z);
      end;
    end;
    PrintStatus(strings[S_CodeV2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;
    j := 0;
    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);
    if err >= max_err then Break;

    Inc(i, DIMBUF - 4);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
    sizeEE := k;
  end;
  PrintMessage1(strings[S_ComplErr], err);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  sprintf(str, strings[S_EndErr],
          [(stop_ - start_) / 1000.0, err,
           IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing])]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  ReadDS1820 - DS1820 OneWire 온도 센서 읽기
  ============================================================ }
procedure ReadDS1820();
var
  z, j: Integer;
  TLSB: Double;
  T: Integer;
  start_, stop_: LongWord;
begin
  z := 0;
  TLSB := 0.5;
  hvreg := 0;

  if FWVersion < $800 then
  begin
    PrintMessage1(strings[S_FWver2old], '0.8.0');
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'ReadDS1820()'#10);
  end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := uW_INIT;   Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := OW_RESET;  Inc(j);
  bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 1; Inc(j); bufferU[j] := READ_ROM; Inc(j);
  bufferU[j] := OW_READ;   Inc(j); bufferU[j] := 8; Inc(j);
  bufferU[j] := OW_RESET;  Inc(j);
  bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 2; Inc(j);
  bufferU[j] := SKIP_ROM;  Inc(j); bufferU[j] := CONVERT_TEMP; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(16);
  j := 0;

  z := 0;
  while (bufferI[z] <> OW_RESET) and (z < DIMBUF) do Inc(z);
  if (bufferI[z] = OW_RESET) and (bufferI[z + 1] = 0) then
  begin
    PrintMessage(strings[S_ComErr]);
    bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
    bufferU[j] := FLUSH;      Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(2);
    if saveLog <> 0 then CloseLogFile();
    Exit;
  end;

  z := 0;
  while (bufferI[z] <> OW_READ) and (z < DIMBUF) do Inc(z);
  if z < DIMBUF - 9 then
  begin
    PrintMessage1('Family code: 0x%02X ', bufferI[z + 2]);
    OW_ID(bufferI[z + 2]);
    if bufferI[z + 2] = $10 then TLSB := 0.5      { DS1820 }
    else if bufferI[z + 2] = $28 then TLSB := 0.0625; { DS18B20 }
    PrintMessage3('Serial ID: 0x%02X%02X%02X', bufferI[z+3], bufferI[z+4], bufferI[z+5]);
    PrintMessage3('%02X%02X%02X', bufferI[z+6], bufferI[z+7], bufferI[z+8]);
    PrintMessage1(#13#10'CRC: 0x%02X'#13#10, bufferI[z + 9]);
  end;

  { ---- 읽기 ---- }
  msDelay(800);
  bufferU[j] := OW_RESET;  Inc(j);
  bufferU[j] := OW_WRITE;  Inc(j); bufferU[j] := 2; Inc(j);
  bufferU[j] := SKIP_ROM;  Inc(j); bufferU[j] := READ_SCRATCHPAD2; Inc(j);
  bufferU[j] := OW_READ;   Inc(j); bufferU[j] := 8; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(10);
  j := 0;

  z := 0;
  while (bufferI[z] <> OW_READ) and (z < DIMBUF - 2) do Inc(z);
  T := bufferI[z + 2] + (bufferI[z + 3] shl 8);
  if T > $F000 then T := T or Integer($FFFF0000);  { 음수 보정 }

  PrintMessage2('T=%.4f°C  (0x%04X)'#13#10, T * TLSB, T);

  { ---- 종료 ---- }
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  sprintf(str, strings[S_End], [(stop_ - start_) / 1000.0]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Read11xx - 11xx UNIO 메모리 읽기
  dim = 크기(바이트)
  ============================================================ }
procedure Read11xx(dim: Integer);
var
  k, z, i, j: Integer;
  start_, stop_: LongWord;
  sum: Integer;
begin
  k := 0; z := 0;
  hvreg := 0;

  if FWVersion < $800 then
  begin
    PrintMessage1(strings[S_FWver2old], '0.8.0');
    Exit;
  end;
  if (dim >= $10000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Read11xx(%d)    (0x%X)'#10, [dim, dim]);
  end;

  sizeEE := dim;
  if memEE <> nil then FreeMem(memEE);
  memEE := GetMem(dim);

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;  Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;   Inc(j);
  bufferU[j] := UNIO_COM;  Inc(j);
  bufferU[j] := 2;         Inc(j);  { 쓰기 x 바이트 }
  bufferU[j] := 1;         Inc(j);  { 읽기 x 바이트 }
  bufferU[j] := $A0;       Inc(j);
  bufferU[j] := UNIO_RDSR; Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(5);

  { ---- 읽기 ---- }
  PrintMessage(strings[S_ReadEE]);
  PrintStatusSetup();

  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := UNIO_COM; Inc(j);
    bufferU[j] := 4;        Inc(j);  { 쓰기 4바이트 }
    if i < dim - (DIMBUF - 5) then bufferU[j] := DIMBUF - 5
    else                           bufferU[j] := dim - i;
    Inc(j);
    bufferU[j] := $A0;       Inc(j);
    bufferU[j] := UNIO_READ; Inc(j);
    bufferU[j] := i shr 8;   Inc(j);
    bufferU[j] := i and $FF; Inc(j);
    bufferU[j] := FLUSH;     Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(14);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> UNIO_COM) do Inc(j);
    if (bufferI[j] = UNIO_COM) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        memEE[k] := bufferI[z]; Inc(k); Inc(z);
      end;
    end;

    PrintStatus(strings[S_CodeReading2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;
    j := 0;
    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    Inc(i, DIMBUF - 5);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
    sizeEE := k;
  end
  else
    PrintMessage(strings[S_Compl]);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  DisplayEE();

  sum := 0;
  for i := 0 to sizeEE - 1 do Inc(sum, memEE[i]);
  PrintMessage1('Checksum: 0x%X'#13#10, sum and $FFFF);
  sprintf(str, strings[S_End], [(stop_ - start_) / 1000.0]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

{ ============================================================
  Write11xx - 11xx UNIO 메모리 쓰기
  dim  = 크기(바이트)
  page = 페이지 크기
  ============================================================ }
procedure Write11xx(dim: Integer; page: Integer);
var
  k, z, i, j: Integer;
  err: Integer;
  status_: Integer;
  start_, stop_: LongWord;
begin
  k := 0; z := 0; err := 0;

  if FWVersion < $800 then
  begin
    PrintMessage1(strings[S_FWver2old], '0.8.0');
    Exit;
  end;
  hvreg := 0;
  if (dim >= $10000) or (dim < 0) then
  begin
    PrintMessage(strings[S_EELim]);
    Exit;
  end;

  if saveLog <> 0 then
  begin
    OpenLogFile();
    fprintf(logfile, 'Write11xx(%d,%d)    (0x%X,0x%X)'#10, [dim, page, dim, page]);
  end;

  if dim > sizeEE then
  begin
    i := sizeEE;
    ReallocMem(memEE, dim);
    while i < dim do begin memEE[i] := $FF; Inc(i); end;
    sizeEE := dim;
  end;
  if dim < 1 then
  begin
    PrintMessage(strings[S_NoCode]);
    Exit;
  end;

  start_ := GetTickCount();
  j := 0;
  bufferU[j] := VREG_DIS;   Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $1; Inc(j);
  bufferU[j] := WAIT_T3;    Inc(j);
  bufferU[j] := UNIO_STBY;  Inc(j);
  { WREN }
  bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 2; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_WREN; Inc(j);
  { RDSR }
  bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 2; Inc(j); bufferU[j] := 1; Inc(j);
  bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_RDSR; Inc(j);
  { WRSR }
  bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 3; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_WRSR; Inc(j); bufferU[j] := 0; Inc(j);
  { WAIT x5 }
  bufferU[j] := WAIT_T3; Inc(j); bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := WAIT_T3; Inc(j); bufferU[j] := WAIT_T3; Inc(j); bufferU[j] := WAIT_T3; Inc(j);
  { RDSR }
  bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 2; Inc(j); bufferU[j] := 1; Inc(j);
  bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_RDSR; Inc(j);
  { WREN }
  bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 2; Inc(j); bufferU[j] := 0; Inc(j);
  bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_WREN; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(25);

  { ---- 쓰기 ---- }
  PrintMessage(strings[S_EEAreaW]);
  PrintStatusSetup();
  while page >= DIMBUF - 8 do page := page shr 1;

  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := UNIO_COM;   Inc(j);
    bufferU[j] := 4 + page;   Inc(j);  { 쓰기 바이트 수 }
    bufferU[j] := 0;           Inc(j);  { 읽기 없음 }
    bufferU[j] := $A0;         Inc(j);
    bufferU[j] := UNIO_WRITE;  Inc(j);
    bufferU[j] := i shr 8;     Inc(j);
    bufferU[j] := i and $FF;   Inc(j);
    for k := 0 to page - 1 do begin bufferU[j] := memEE[i + k]; Inc(j); end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(Round((5 + page) * 0.2 + 2));

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> UNIO_COM) do Inc(j);
    if (bufferI[j] <> UNIO_COM) or (bufferI[j + 1] >= $FA) then i := dim + 10;

    PrintStatus(strings[S_CodeWriting2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;
    j := 0;
    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log7], [i, i, k, k]);

    { 상태 폴링 }
    bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 2; Inc(j); bufferU[j] := 1; Inc(j);
    bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_RDSR; Inc(j);
    bufferU[j] := UNIO_COM;   Inc(j); bufferU[j] := 2; Inc(j); bufferU[j] := 0; Inc(j);
    bufferU[j] := $A0;        Inc(j); bufferU[j] := UNIO_WREN; Inc(j);
    bufferU[j] := FLUSH;      Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;

    status_ := 1; k := 0;
    while (status_ <> 0) and (k < 20) do
    begin
      PacketIO(2);
      j := 0;
      while (j < DIMBUF - 1) and (bufferI[j] <> UNIO_COM) do Inc(j);
      if bufferI[j] = UNIO_COM then status_ := bufferI[j + 2] and 1;
      Inc(k);
    end;
    j := 0;

    Inc(i, page);
  end;

  PrintStatusEnd();
  PrintMessage(strings[S_Compl]);

  { ---- 검증 ---- }
  PrintMessage(strings[S_EEV]);
  PrintStatusSetup();
  k := 0;

  i := 0;
  while i < dim do
  begin
    j := 0;
    bufferU[j] := UNIO_COM;  Inc(j);
    bufferU[j] := 4;         Inc(j);
    if i < dim - (DIMBUF - 4) then bufferU[j] := DIMBUF - 4
    else                           bufferU[j] := dim - i;
    Inc(j);
    bufferU[j] := $A0;        Inc(j);
    bufferU[j] := UNIO_READ;  Inc(j);
    bufferU[j] := i shr 8;    Inc(j);
    bufferU[j] := i and $FF;  Inc(j);
    bufferU[j] := FLUSH;      Inc(j);
    while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
    PacketIO(14);

    j := 0;
    while (j < DIMBUF - 1) and (bufferI[j] <> UNIO_COM) do Inc(j);
    if (bufferI[j] = UNIO_COM) and (bufferI[j + 1] < $FA) then
    begin
      z := j + 2;
      while (z < j + 2 + bufferI[j + 1]) and (z < DIMBUF) do
      begin
        if memEE[k] <> bufferI[z] then
        begin
          PrintMessage(#13#10);
          PrintMessage4(strings[S_CodeVError], i + z - 3, i + z - 3, memEE[k], bufferI[z]);
          Inc(err);
        end;
        Inc(k); Inc(z);
      end;
    end;

    PrintStatus(strings[S_CodeV2], i * 100 div dim, i);
    if RWstop <> 0 then i := dim;
    j := 0;
    if saveLog <> 0 then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);
    if err >= max_err then Break;

    Inc(i, DIMBUF - 4);
  end;

  PrintStatusEnd();
  if k <> dim then
  begin
    PrintMessage(#13#10);
    PrintMessage2(strings[S_ReadEEErr], dim, k);
  end;
  PrintMessage1(strings[S_ComplErr], err);

  { ---- 종료 ---- }
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j); bufferU[j] := $0; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00; Inc(j); end;
  PacketIO(2);

  stop_ := GetTickCount();
  PrintStatusClear();
  sprintf(str, strings[S_EndErr],
          [(stop_ - start_) / 1000.0, err,
           IfThen(err <> 1, strings[S_ErrPlur], strings[S_ErrSing])]);
  PrintMessage(str);
  if saveLog <> 0 then
  begin
    fprintf(logfile, str);
    CloseLogFile();
  end;
end;

end.
