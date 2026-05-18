{
  progP12.pas - PIC12 (12비트 워드) 마이크로컨트롤러 프로그래밍 알고리즘
  원본 C 소스: progP12.c
  Copyright (C) 2009-2016 Alberto Maccioni
  Free Pascal 변환

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
}

unit progP12;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, common;

procedure Read12F5xx(dim: Integer; dim2: Integer);
procedure Write12F5xx(dim: Integer; OscAddr: Integer);
procedure Write12C5xx(dim: Integer; dummy: Integer);

implementation

{ ============================================================
  Read12F5xx
  - 12비트 PIC 읽기
  - dim  = 프로그램 크기
  - dim2 = 설정(config) 크기
  - VDD → VPP 순서
  - CONFIG @ 0x7FF (프로그램 모드 진입 시)
  - OSCCAL = 마지막 메모리 위치
  - 코드 메모리 너머에 4개의 ID + 예약 영역
  ============================================================ }
procedure Read12F5xx(dim: Integer; dim2: Integer);
var
  k, z, i, j: Integer;
  s, t: string;
  start, stop: LongWord;
  valid, empty: Integer;
  aux: string;
begin
  k := 0;
  z := 0;

  if dim2 < 4 then dim2 := 4;
  sizeW := $1000;

  if Assigned(memCODE_W) then
    FreeMem(memCODE_W);
  GetMem(memCODE_W, SizeOf(Word) * sizeW);

  if saveLog then
  begin
    OpenLogFile();
    fprintf(logfile, 'Read12F5xx(%d,%d)' + LineEnding, [dim, dim2]);
  end;

  start := GetTickCount();

  j := 0;
  bufferU[j] := SET_PARAMETER;   Inc(j);
  bufferU[j] := SET_T1T2;        Inc(j);
  bufferU[j] := 1;               Inc(j);   // T1=1µs
  bufferU[j] := 100;             Inc(j);   // T2=100µs
  bufferU[j] := SET_PARAMETER;   Inc(j);
  bufferU[j] := SET_T3;          Inc(j);
  bufferU[j] := 2000 shr 8;      Inc(j);
  bufferU[j] := 2000 and $FF;    Inc(j);
  bufferU[j] := EN_VPP_VCC;      Inc(j);   // 프로그램 모드 진입
  bufferU[j] := $00;             Inc(j);
  bufferU[j] := SET_CK_D;        Inc(j);
  bufferU[j] := $00;             Inc(j);
  bufferU[j] := EN_VPP_VCC;      Inc(j);   // VDD
  bufferU[j] := $01;             Inc(j);
  bufferU[j] := EN_VPP_VCC;      Inc(j);   // VDD+VPP
  bufferU[j] := $05;             Inc(j);
  bufferU[j] := NOP;             Inc(j);
  bufferU[j] := READ_DATA_PROG;  Inc(j);   // 설정 워드 읽기
  bufferU[j] := INC_ADDR;        Inc(j);   // 7FF->000
  bufferU[j] := FLUSH;           Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(2);

  // READ_DATA_PROG 응답 위치 탐색
  z := 0;
  while (z < DIMBUF - 2) and (bufferI[z] <> READ_DATA_PROG) do
    Inc(z);

  if z < DIMBUF - 2 then
  begin
    memCODE_W[$FFF] := (bufferI[z + 1] shl 8) + bufferI[z + 2];
    PrintMessage(LineEnding);
    PrintMessage1(strings[S_ConfigWord], memCODE_W[$FFF]);  // '\r\nConfiguration word: 0x%03X\r\n'

    case memCODE_W[$FFF] and $03 of
      0: PrintMessage(strings[S_LPOsc]);   // 'LP oscillator\r\n'
      1: PrintMessage(strings[S_XTOsc]);   // 'XT oscillator\r\n'
      2: PrintMessage(strings[S_IntOsc]);  // 'Internal osc.\r\n'
      3: PrintMessage(strings[S_RCOsc]);   // 'RC oscillator\r\n'
    end;

    if (memCODE_W[$FFF] and $04) <> 0 then
      PrintMessage(strings[S_WDTON])    // 'WDT ON\r\n'
    else
      PrintMessage(strings[S_WDTOFF]);  // 'WDT OFF\r\n'

    if (memCODE_W[$FFF] and $08) <> 0 then
      PrintMessage(strings[S_CPOFF])   // 'Code protection OFF\r\n'
    else
      PrintMessage(strings[S_CPON]);   // 'Code protection ON\r\n'

    if (memCODE_W[$FFF] and $10) <> 0 then
      PrintMessage(strings[S_MCLRON])   // 'Master clear ON\r\n'
    else
      PrintMessage(strings[S_MCLROFF]); // 'Master clear OFF\r\n'
  end
  else
    PrintMessage(strings[S_NoConfigW]); // 'Impossible to read config word\r\n'

  // ================== 코드 읽기 ==================
  PrintMessage(strings[S_CodeReading1]); // 'reading code ...'
  PrintStatusSetup();

  i := 0;
  j := 0;
  while i < dim + dim2 do
  begin
    bufferU[j] := READ_DATA_PROG; Inc(j);
    bufferU[j] := INC_ADDR;       Inc(j);

    if (j > DIMBUF * 2 div 4 - 3) or (i = dim + dim2 - 1) then
    begin
      bufferU[j] := FLUSH; Inc(j);
      while j < DIMBUF do
      begin
        bufferU[j] := $00;
        Inc(j);
      end;
      PacketIO(5);

      for z := 0 to DIMBUF - 3 do
      begin
        if bufferI[z] = READ_DATA_PROG then
        begin
          memCODE_W[k] := (bufferI[z + 1] shl 8) + bufferI[z + 2];
          Inc(k);
          Inc(z, 2);
        end;
      end;

      PrintStatus(strings[S_CodeReading], i * 100 div (dim + dim2), i);
      // 'Read: %d%%, addr. %03X'
      j := 0;

      if saveLog then
        fprintf(logfile, strings[S_Log7], [i, i, k, k]);
        // 'i=%d(0x%X), k=%d(0x%X)\n'
    end;

    Inc(i);
  end;
  PrintStatusEnd();

  // ================== 프로그램 모드 종료 ==================
  bufferU[j] := NOP;       Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $01;       Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $00;       Inc(j);
  bufferU[j] := SET_CK_D;  Inc(j);
  bufferU[j] := $00;       Inc(j);
  bufferU[j] := FLUSH;     Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(1);

  stop := GetTickCount();

  for i := k to $FFE do
    memCODE_W[i] := $FFF;

  if k <> dim + dim2 then
  begin
    PrintMessage(LineEnding);
    PrintMessage2(strings[S_ReadErr], dim + dim2, k);
    // 'Error reading, requested %d words, read %d\r\n'
  end
  else
    PrintMessage(strings[S_Compl]);

  // ================== 시각화 ==================
  i := 0;
  while i < 4 do
  begin
    PrintMessage4(strings[S_ChipID],
      i, memCODE_W[dim + i],
      i + 1, memCODE_W[dim + i + 1]);
    // 'ID%d: 0x%03X   ID%d: 0x%03X\r\n'
    Inc(i, 2);
  end;

  if dim2 > 4 then
    PrintMessage1(strings[S_BKOsccal], memCODE_W[dim + 4]);
    // 'Backup OSCCAL: 0x%03X\r\n'

  PrintMessage(strings[S_CodeMem]); // '\r\nCode memory\r\n'
  s := '';
  valid := 0;
  empty := 1;
  aux := '';

  i := 0;
  while i < dim do
  begin
    valid := 0;
    j := i;
    while (j < i + COL) and (j < dim) do
    begin
      t := Format('%03X ', [memCODE_W[j]]);
      s := s + t;
      if memCODE_W[j] < $FFF then valid := 1;
      Inc(j);
    end;
    if valid <> 0 then
    begin
      t := Format('%04X: %s' + LineEnding, [i, s]);
      empty := 0;
      aux := aux + t;
    end;
    s := '';
    Inc(i, COL);
  end;

  if empty <> 0 then
    PrintMessage(strings[S_Empty])
  else
    PrintMessage(aux);

  if dim2 > 5 then
  begin
    aux := '';
    s := '';
    PrintMessage(strings[S_ConfigResMem]); // '\r\nConfig and reserved memory:\r\n'
    empty := 1;

    i := dim;
    while i < dim + dim2 do
    begin
      valid := 0;
      j := i;
      while (j < i + COL) and (j < dim + 64) do
      begin
        t := Format('%03X ', [memCODE_W[j]]);
        s := s + t;
        if memCODE_W[j] < $FFF then valid := 1;
        Inc(j);
      end;
      if valid <> 0 then
      begin
        t := Format('%04X: %s' + LineEnding, [i, s]);
        empty := 0;
        aux := aux + t;
      end;
      s := '';
      Inc(i, COL);
    end;

    if empty <> 0 then
      PrintMessage(strings[S_Empty])
    else
      PrintMessage(aux);
  end;

  str_ := Format(strings[S_End], [(stop - start) / 1000.0]);
  // '\r\nEnd (%.2f s)\r\n'
  PrintMessage(str_);

  if saveLog then
  begin
    fprintf(logfile, str_, []);
    CloseLogFile();
  end;

  PrintStatusClear();
end;

{ ============================================================
  Write12F5xx
  - 12비트 PIC 쓰기
  - dim     = 프로그램 크기 (최대 ~4300 = 0x10CC)
  - OscAddr = OSCCAL 주소 (시작 시 저장됨), -1이면 사용 안 함
  - VDD → VPP 순서
  - CONFIG @ 0x7FF (프로그램 모드 진입 시)
  - BACKUP OSCCAL @ dim+5
  - 소거: BULK_ERASE_PROG (1001) + 10ms
  - 쓰기: BEGIN_PROG (1000) + Tprogram 2ms + END_PROG2 (1110)
  ============================================================ }
procedure Write12F5xx(dim: Integer; OscAddr: Integer);
var
  k, z, i, j, w: Integer;
  err, err_c: Integer;
  osccal, BKosccal: Word;
  start, stop: LongWord;
  dim1: Integer;
begin
  k := 0; z := 0; err := 0;
  osccal  := Word(-1);
  BKosccal := Word(-1);

  if OscAddr > dim then OscAddr := dim - 1;
  if OscAddr = -1 then
  begin
    use_BKosccal := 0;
    use_osccal   := 0;
  end;

  if sizeW < $1000 then
  begin
    PrintMessage(strings[S_NoConfigW2]); // 'Can''t find CONFIG (0xFFF)\r\n'
    Exit;
  end;

  if saveLog then
  begin
    OpenLogFile();
    fprintf(logfile, 'Write12F5xx(%d,%d)' + LineEnding, [dim, OscAddr]);
  end;

  for i := 0 to sizeW - 1 do
    memCODE_W[i] := memCODE_W[i] and $FFF;

  start := GetTickCount();
  j := 0;

  bufferU[j] := SET_PARAMETER; Inc(j);
  bufferU[j] := SET_T1T2;      Inc(j);
  bufferU[j] := 1;             Inc(j);   // T1=1µs
  bufferU[j] := 100;           Inc(j);   // T2=100µs
  bufferU[j] := EN_VPP_VCC;   Inc(j);   // 프로그램 모드 진입
  bufferU[j] := $00;           Inc(j);
  bufferU[j] := SET_CK_D;      Inc(j);
  bufferU[j] := $00;           Inc(j);
  bufferU[j] := EN_VPP_VCC;   Inc(j);   // VDD
  bufferU[j] := $01;           Inc(j);
  bufferU[j] := NOP;           Inc(j);
  bufferU[j] := EN_VPP_VCC;   Inc(j);   // VDD+VPP
  bufferU[j] := $05;           Inc(j);
  bufferU[j] := NOP;           Inc(j);

  // OSCCAL 및 BKosccal 읽기
  if OscAddr <> -1 then
  begin
    i := -1;
    while i < OscAddr - $FF do
    begin
      bufferU[j] := INC_ADDR_N; Inc(j);
      bufferU[j] := $FF;        Inc(j);
      Inc(i, $FF);
    end;
    bufferU[j] := INC_ADDR_N;       Inc(j);
    bufferU[j] := OscAddr - i;      Inc(j);
    bufferU[j] := READ_DATA_PROG;   Inc(j);   // OSCCAL
    if OscAddr < dim then
    begin
      bufferU[j] := INC_ADDR_N;    Inc(j);
      bufferU[j] := dim - OscAddr; Inc(j);
    end;
    bufferU[j] := INC_ADDR_N; Inc(j);
    bufferU[j] := $04;         Inc(j);   // 400->404
    bufferU[j] := READ_DATA_PROG; Inc(j); // 백업 OSCCAL
  end;

  bufferU[j] := NOP;       Inc(j);   // 프로그램 모드 종료
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $01;        Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $00;        Inc(j);
  bufferU[j] := SET_CK_D;   Inc(j);
  bufferU[j] := $00;        Inc(j);
  bufferU[j] := SET_PARAMETER; Inc(j);
  bufferU[j] := SET_T3;     Inc(j);
  bufferU[j] := 10000 shr 8;   Inc(j);
  bufferU[j] := 10000 and $FF; Inc(j);
  bufferU[j] := WAIT_T3;    Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(15);

  if OscAddr <> -1 then
  begin
    z := 4;
    while (z < DIMBUF - 2) and (bufferI[z] <> READ_DATA_PROG) do Inc(z);
    if z < DIMBUF - 2 then
      osccal := (bufferI[z + 1] shl 8) + bufferI[z + 2];
    Inc(z, 3);
    while (z < DIMBUF - 2) and (bufferI[z] <> READ_DATA_PROG) do Inc(z);
    if z < DIMBUF - 2 then
      BKosccal := (bufferI[z + 1] shl 8) + bufferI[z + 2];

    if (osccal = Word(-1)) or (BKosccal = Word(-1)) then
    begin
      PrintMessage(strings[S_ErrOsccal]); // 'Error reading OSCCAL and BKOSCCAL'
      PrintMessage(LineEnding);
      Exit;
    end;
    PrintMessage1(strings[S_Osccal],   osccal);   // 'OSCCAL: 0x%03X\r\n'
    PrintMessage1(strings[S_BKOsccal], BKosccal); // 'Backup OSCCAL: 0x%03X\r\n'
  end;

  // ================== 메모리 소거 ==================
  PrintMessage(strings[S_StartErase]); // 'Erase ... '
  j := 0;
  bufferU[j] := EN_VPP_VCC; Inc(j);   // 프로그램 모드 진입
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := NOP;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $05;         Inc(j);

  if dim > OscAddr + 1 then   // 12F519 (Flash+EEPROM)
  begin
    bufferU[j] := BULK_ERASE_PROG; Inc(j);
    bufferU[j] := WAIT_T3;         Inc(j);
    i := -1;
    while i < dim - $FF do
    begin
      bufferU[j] := INC_ADDR_N; Inc(j);
      bufferU[j] := $FF;        Inc(j);
      Inc(i, $FF);
    end;
    bufferU[j] := INC_ADDR_N;    Inc(j);
    bufferU[j] := dim - i - 1;   Inc(j);
    bufferU[j] := BULK_ERASE_PROG; Inc(j); // EEPROM 소거
    bufferU[j] := WAIT_T3;         Inc(j);
    if programID <> 0 then
    begin
      bufferU[j] := INC_ADDR;        Inc(j);
      bufferU[j] := BULK_ERASE_PROG; Inc(j);
      bufferU[j] := WAIT_T3;         Inc(j);
    end;
  end
  else   // 12Fxxx
  begin
    if programID <> 0 then
    begin
      i := -1;
      while i < dim - $FF do
      begin
        bufferU[j] := INC_ADDR_N; Inc(j);
        bufferU[j] := $FF;        Inc(j);
        Inc(i, $FF);
      end;
      bufferU[j] := INC_ADDR_N;    Inc(j);
      bufferU[j] := dim - i;       Inc(j);
      bufferU[j] := BULK_ERASE_PROG; Inc(j);
      bufferU[j] := WAIT_T3;         Inc(j);
    end
    else
    begin
      bufferU[j] := BULK_ERASE_PROG; Inc(j);
      bufferU[j] := WAIT_T3;         Inc(j);
    end;
  end;

  bufferU[j] := EN_VPP_VCC; Inc(j);  // 프로그램 모드 종료
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $00;         Inc(j);
  bufferU[j] := WAIT_T3;    Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);  // 프로그램 모드 재진입
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := NOP;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $05;         Inc(j);
  bufferU[j] := INC_ADDR;   Inc(j);  // 7FF->000
  bufferU[j] := SET_PARAMETER; Inc(j);
  bufferU[j] := SET_T3;     Inc(j);
  bufferU[j] := 2000 shr 8; Inc(j);  // T3=2ms
  bufferU[j] := 2000 and $FF; Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;

  if dim > OscAddr + 1 then
    PacketIO(50)
  else
    PacketIO(30);

  PrintMessage(strings[S_Compl]); // 'completed\r\n'

  // ================== 코드 쓰기 ==================
  PrintMessage(strings[S_StartCodeProg]); // 'Write code ... '
  PrintStatusSetup();

  dim1 := dim;
  if programID <> 0 then dim1 := dim + 5;
  if memCODE_W[dim + 4] >= $FFF then
    memCODE_W[dim + 4] := BKosccal;
  if use_BKosccal <> 0 then
    memCODE_W[OscAddr] := BKosccal
  else if use_osccal <> 0 then
    memCODE_W[OscAddr] := osccal;

  i := 0; k := 0; w := 0; j := 0;
  while i < dim1 do
  begin
    if memCODE_W[i] < $FFF then
    begin
      bufferU[j] := LOAD_DATA_PROG;        Inc(j);
      bufferU[j] := memCODE_W[i] shr 8;   Inc(j);  // MSB
      bufferU[j] := memCODE_W[i] and $FF; Inc(j);  // LSB
      bufferU[j] := BEGIN_PROG;            Inc(j);
      bufferU[j] := WAIT_T3;              Inc(j);   // Tprogram 2ms
      bufferU[j] := END_PROG2;            Inc(j);
      bufferU[j] := WAIT_T2;             Inc(j);   // Tdischarge
      bufferU[j] := READ_DATA_PROG;      Inc(j);
      Inc(w);
    end;
    bufferU[j] := INC_ADDR; Inc(j);

    if (j > DIMBUF - 10) or (i = dim1 - 1) then
    begin
      PrintStatus(strings[S_CodeWriting], i * 100 div dim, i);
      bufferU[j] := FLUSH; Inc(j);
      while j < DIMBUF do
      begin
        bufferU[j] := $00;
        Inc(j);
      end;
      PacketIO(w * 3 + 3);
      w := 0;

      z := 0;
      while z < DIMBUF - 7 do
      begin
        if (bufferI[z] = INC_ADDR) and (memCODE_W[k] >= $FFF) then
          Inc(k)
        else if (bufferI[z] = LOAD_DATA_PROG) and (bufferI[z + 5] = READ_DATA_PROG) then
        begin
          if memCODE_W[k] <> (bufferI[z + 6] shl 8) + bufferI[z + 7] then
          begin
            PrintMessage(LineEnding);
            PrintMessage3(strings[S_CodeWError], k, memCODE_W[k],
              (bufferI[z + 6] shl 8) + bufferI[z + 7]);
            Inc(err);
            if (max_err <> 0) and (err > max_err) then
            begin
              PrintMessage1(strings[S_MaxErr], err);
              PrintMessage(strings[S_IntW]);
              i := dim1;
              z := DIMBUF;
            end;
          end;
          Inc(k);
          Inc(z, 8);
        end;
        Inc(z);
      end;

      j := 0;
      if saveLog then
        fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);
    end;

    Inc(i);
  end;
  PrintStatusEnd();
  Inc(err, i - k);
  PrintMessage1(strings[S_ComplErr], err);

  // ================== CONFIG 쓰기 ==================
  PrintMessage(strings[S_ConfigW]); // 'Write CONFIG ... '
  err_c := 0;

  bufferU[j] := NOP;        Inc(j);   // 프로그램 모드 종료
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $00;         Inc(j);
  bufferU[j] := SET_CK_D;   Inc(j);
  bufferU[j] := $00;         Inc(j);
  // 5 × WAIT_T3 (프로그램 모드 재진입 전 10ms 이상 대기)
  bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := WAIT_T3; Inc(j);
  bufferU[j] := EN_VPP_VCC;     Inc(j);  // 프로그램 모드 진입
  bufferU[j] := $01;             Inc(j);
  bufferU[j] := NOP;             Inc(j);
  bufferU[j] := EN_VPP_VCC;     Inc(j);
  bufferU[j] := $05;             Inc(j);
  bufferU[j] := LOAD_DATA_PROG; Inc(j);  // 설정 워드
  bufferU[j] := memCODE_W[$FFF] shr 8;   Inc(j);  // MSB
  bufferU[j] := memCODE_W[$FFF] and $FF; Inc(j);  // LSB
  bufferU[j] := BEGIN_PROG;     Inc(j);
  bufferU[j] := WAIT_T3;        Inc(j);  // Tprogram 2ms
  bufferU[j] := END_PROG2;      Inc(j);
  bufferU[j] := WAIT_T2;        Inc(j);  // Tdischarge
  bufferU[j] := READ_DATA_PROG; Inc(j);
  bufferU[j] := NOP;            Inc(j);  // 프로그램 모드 종료
  bufferU[j] := EN_VPP_VCC;    Inc(j);
  bufferU[j] := $01;            Inc(j);
  bufferU[j] := EN_VPP_VCC;    Inc(j);
  bufferU[j] := $00;            Inc(j);
  bufferU[j] := SET_CK_D;      Inc(j);
  bufferU[j] := $00;            Inc(j);
  bufferU[j] := FLUSH;          Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(20);

  stop := GetTickCount();

  z := 0;
  while (z < DIMBUF - 2) and (bufferI[z] <> READ_DATA_PROG) do Inc(z);
  // 0을 썼는데 1이 읽히면 오류 (~W & R)
  if (not memCODE_W[$FFF]) and ((bufferI[z + 1] shl 8) + bufferI[z + 2]) <> 0 then
  begin
    PrintMessage(LineEnding);
    PrintMessage2(strings[S_ConfigWErr],
      memCODE_W[$FFF],
      (bufferI[z + 1] shl 8) + bufferI[z + 2]);
    Inc(err_c);
  end;
  if z > DIMBUF - 2 then
  begin
    PrintMessage(LineEnding);
    PrintMessage(strings[S_ConfigWErr2]); // 'Error writing CONFIG'
  end;
  Inc(err, err_c);
  PrintMessage1(strings[S_ComplErr], err_c);

  if saveLog then
    fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

  if err <> 1 then
    str_ := Format(strings[S_EndErr], [(stop - start) / 1000.0, err, strings[S_ErrPlur]])
  else
    str_ := Format(strings[S_EndErr], [(stop - start) / 1000.0, err, strings[S_ErrSing]]);
  PrintMessage(str_);

  if saveLog then
  begin
    fprintf(logfile, str_, []);
    CloseLogFile();
  end;

  PrintStatusClear();
end;

{ ============================================================
  Write12C5xx
  - 12비트 OTP PIC 쓰기
  - dim = 프로그램 크기 (최대 ~4300 = 0x10CC)
  - VDD → VPP 순서
  - CONFIG @ 0x7FF (프로그램 모드 진입 시)
  - 쓰기: BEGIN_PROG (1000) + Tprogram 100µs + END_PROG2 (1110)
  - 8 펄스 + 11N 오버펄스
  ============================================================ }
procedure Write12C5xx(dim: Integer; dummy: Integer);
var
  k, z, i, j: Integer;
  err, err_c: Integer;
  osccal: Word;
  OscAddr: Integer;
  start, stop: LongWord;
  N, Nt, Nmin, Nmax, xN: Integer;
  dim1: Integer;
begin
  k := 0; z := 0; err := 0;
  osccal := Word(-1);
  OscAddr := dim - 1;

  if FWVersion < $800 then
  begin
    PrintMessage1(strings[S_FWver2old], '0.8.0');
    // 'This firmware is too old. Version %s is required\r\n'
    Exit;
  end;

  if sizeW < $1000 then
  begin
    PrintMessage(strings[S_NoConfigW2]); // 'Can''t find CONFIG (0xFFF)\r\n'
    Exit;
  end;

  if saveLog then
  begin
    OpenLogFile();
    fprintf(logfile, 'Write12C5xx(%d)' + LineEnding, [dim]);
  end;

  for i := 0 to sizeW - 1 do
    memCODE_W[i] := memCODE_W[i] and $FFF;

  start := GetTickCount();
  j := 0;

  bufferU[j] := SET_PARAMETER; Inc(j);
  bufferU[j] := SET_T1T2;      Inc(j);
  bufferU[j] := 1;             Inc(j);  // T1=1µs
  bufferU[j] := 100;           Inc(j);  // T2=100µs
  bufferU[j] := SET_PARAMETER; Inc(j);
  bufferU[j] := SET_MN;        Inc(j);
  bufferU[j] := 8;             Inc(j);  // M=8 펄스
  bufferU[j] := 11;            Inc(j);  // N=11 오버펄스
  bufferU[j] := EN_VPP_VCC;   Inc(j);  // 프로그램 모드 진입
  bufferU[j] := $00;           Inc(j);
  bufferU[j] := SET_CK_D;      Inc(j);
  bufferU[j] := $00;           Inc(j);
  bufferU[j] := EN_VPP_VCC;   Inc(j);  // VDD
  bufferU[j] := $01;           Inc(j);
  bufferU[j] := NOP;           Inc(j);
  bufferU[j] := EN_VPP_VCC;   Inc(j);  // VDD+VPP
  bufferU[j] := $05;           Inc(j);
  bufferU[j] := NOP;           Inc(j);

  // OSCCAL 주소로 이동
  i := -1;
  while i < OscAddr - $FF do
  begin
    bufferU[j] := INC_ADDR_N; Inc(j);
    bufferU[j] := $FF;        Inc(j);
    Inc(i, $FF);
  end;
  bufferU[j] := INC_ADDR_N;    Inc(j);
  bufferU[j] := OscAddr - i;   Inc(j);
  bufferU[j] := READ_DATA_PROG; Inc(j);  // OSCCAL

  bufferU[j] := NOP;        Inc(j);  // 프로그램 모드 종료
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $00;         Inc(j);
  bufferU[j] := SET_CK_D;   Inc(j);
  bufferU[j] := $00;         Inc(j);
  bufferU[j] := SET_PARAMETER; Inc(j);
  bufferU[j] := SET_T3;     Inc(j);
  bufferU[j] := 10000 shr 8;   Inc(j);
  bufferU[j] := 10000 and $FF; Inc(j);
  bufferU[j] := WAIT_T3;    Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(15);

  j := 0;
  z := 4;
  while (z < DIMBUF - 2) and (bufferI[z] <> READ_DATA_PROG) do Inc(z);
  if z < DIMBUF - 2 then
    osccal := (bufferI[z + 1] shl 8) + bufferI[z + 2];

  if osccal = Word(-1) then
  begin
    PrintMessage(strings[S_ErrOsccal]); // 'Error reading OSCCAL and BKOSCCAL'
    PrintMessage(LineEnding);
    Exit;
  end;
  PrintMessage1(strings[S_Osccal], osccal); // 'OSCCAL: 0x%03X\r\n'

  bufferU[j] := EN_VPP_VCC; Inc(j);  // 프로그램 모드 진입
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := NOP;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $05;         Inc(j);
  bufferU[j] := INC_ADDR;   Inc(j);  // 7FF->000
  bufferU[j] := READ_ADC;   Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(2);
  j := 0;

  // ================== 코드 쓰기 ==================
  PrintMessage(strings[S_StartCodeProg]); // 'Write code ... '
  PrintStatusSetup();

  N := 0; Nt := 0; Nmin := 255; Nmax := 0; xN := 0;
  dim1 := dim;
  if programID <> 0 then dim1 := dim + 5;
  if use_osccal <> 0 then memCODE_W[OscAddr] := osccal;

  i := 0; k := 0; j := 0;
  while i < dim1 do
  begin
    if memCODE_W[i] < $FFF then
    begin
      bufferU[j] := PROG_C;                Inc(j);  // 8 펄스 + 11N 오버펄스 프로그램&검증
      bufferU[j] := memCODE_W[i] shr 8;   Inc(j);  // MSB
      bufferU[j] := memCODE_W[i] and $FF; Inc(j);  // LSB
      bufferU[j] := READ_DATA_PROG;        Inc(j);
      bufferU[j] := READ_ADC;              Inc(j);
      bufferU[j] := INC_ADDR;              Inc(j);
    end
    else
    begin
      // 연속된 0xFFF 건너뛰기
      while (memCODE_W[i] >= $FFF) and (j < DIMBUF - 1) and (i < dim1) do
      begin
        bufferU[j] := INC_ADDR;
        Inc(j);
        Inc(i);
      end;
      Dec(i);
    end;

    PrintStatus(strings[S_CodeWriting], i * 100 div dim, i);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do
    begin
      bufferU[j] := $00;
      Inc(j);
    end;
    PacketIO(10 + 3);  // Tprogram 최대 100µs × 96 ≈ 10ms
    j := 0;

    if (bufferI[1] = PROG_C) and (bufferI[3] = READ_DATA_PROG) then
    begin
      N := bufferI[2];
      if N < $F0 then
      begin
        Inc(Nt, N);
        Inc(xN);
        if N < Nmin then Nmin := N;
        if N > Nmax then Nmax := N;
      end;
      if memCODE_W[k] <> (bufferI[4] shl 8) + bufferI[5] then
      begin
        PrintMessage(LineEnding);
        PrintMessage3(strings[S_CodeWError], k, memCODE_W[k],
          (bufferI[4] shl 8) + bufferI[5]);
        Inc(err);
        if (max_err <> 0) and (err > max_err) then
        begin
          PrintMessage1(strings[S_MaxErr], err);
          PrintMessage(strings[S_IntW]);
          i := dim1;
          z := DIMBUF;
        end;
      end;
      Inc(k);
    end
    else
    begin
      for z := 0 to DIMBUF - 1 do
      begin
        if (bufferI[z] = INC_ADDR) and (memCODE_W[k] >= $FFF) then
          Inc(k);
      end;
    end;

    if saveLog then
      fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

    Inc(i);
  end;

  PrintStatusEnd();
  Inc(err, i - k);
  PrintMessage1(strings[S_ComplErr], err);

  if saveLog and (xN <> 0) then
    fprintf(logfile, 'Programming pulses: avg %.1f, min %d, max %d' + LineEnding,
      [(Nt / xN), Nmin, Nmax]);

  // ================== CONFIG 쓰기 ==================
  if memCODE_W[$FFF] < $FFF then
  begin
    PrintMessage(strings[S_ConfigW]); // 'Write CONFIG ... '
    err_c := 0;

    bufferU[j] := EN_VPP_VCC; Inc(j);  // 프로그램 모드 종료
    bufferU[j] := $01;         Inc(j);
    bufferU[j] := EN_VPP_VCC; Inc(j);
    bufferU[j] := $00;         Inc(j);
    bufferU[j] := WAIT_T3;    Inc(j);   // 10ms
    bufferU[j] := EN_VPP_VCC; Inc(j);  // 프로그램 모드 진입
    bufferU[j] := $01;         Inc(j);
    bufferU[j] := EN_VPP_VCC; Inc(j);
    bufferU[j] := $05;         Inc(j);
    bufferU[j] := LOAD_DATA_PROG;        Inc(j);  // 설정 워드
    bufferU[j] := memCODE_W[$FFF] shr 8;   Inc(j);
    bufferU[j] := memCODE_W[$FFF] and $FF; Inc(j);
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do
    begin
      bufferU[j] := $00;
      Inc(j);
    end;
    PacketIO(12);
    j := 0;

    // 20 펄스씩 5회 = 100 펄스
    for i := 0 to 19 do
    begin
      bufferU[j] := BEGIN_PROG; Inc(j);
      bufferU[j] := WAIT_T2;    Inc(j);   // Tprogram 100µs
      bufferU[j] := END_PROG2;  Inc(j);
    end;
    bufferU[j] := FLUSH; Inc(j);
    while j < DIMBUF do
    begin
      bufferU[j] := $00;
      Inc(j);
    end;
    j := 0;
    for i := 0 to 4 do
      PacketIO(3);

    bufferU[j] := READ_DATA_PROG; Inc(j);
    bufferU[j] := FLUSH;          Inc(j);
    while j < DIMBUF do
    begin
      bufferU[j] := $00;
      Inc(j);
    end;
    PacketIO(2);
    j := 0;

    if (not memCODE_W[$FFF]) and ((bufferI[2] shl 8) + bufferI[3]) <> 0 then
    begin
      PrintMessage(LineEnding);
      PrintMessage2(strings[S_ConfigWErr],
        memCODE_W[$FFF],
        (bufferI[2] shl 8) + bufferI[3]);
      Inc(err_c);
    end;
    Inc(err, err_c);
  end;

  PrintMessage1(strings[S_ComplErr], err);

  // ================== 종료 ==================
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $01;         Inc(j);
  bufferU[j] := EN_VPP_VCC; Inc(j);
  bufferU[j] := $00;         Inc(j);
  bufferU[j] := SET_CK_D;   Inc(j);
  bufferU[j] := $00;         Inc(j);
  bufferU[j] := FLUSH;      Inc(j);
  while j < DIMBUF do
  begin
    bufferU[j] := $00;
    Inc(j);
  end;
  PacketIO(2);
  j := 0;

  stop := GetTickCount();

  if saveLog then
    fprintf(logfile, strings[S_Log8], [i, i, k, k, err]);

  if err <> 1 then
    str_ := Format(strings[S_EndErr], [(stop - start) / 1000.0, err, strings[S_ErrPlur]])
  else
    str_ := Format(strings[S_EndErr], [(stop - start) / 1000.0, err, strings[S_ErrSing]]);
  PrintMessage(str_);

  if saveLog then
  begin
    fprintf(logfile, str_, []);
    CloseLogFile();
  end;

  PrintStatusClear();
end;

end.
