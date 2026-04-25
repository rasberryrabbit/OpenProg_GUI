unit I2CSPI;

(*
 * I2CSPI.pas - algorithms to interface generic I2C/SPI devices
 * Copyright (C) 2010-2022 Alberto Maccioni
 * Object Pascal conversion
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *)

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Common, Instructions;

// ── 내부 상수 ─────────────────────────────────────────────────────────────
const
  CS_PIN  = 8;    // C: #define CS  8
  HLD_PIN = 16;   // C: #define HLD 16

// ── 공개 프로시저 ──────────────────────────────────────────────────────────
(*
  I2CReceive : I2C/SPI 수신
    mode  : 0=I2C 8bit, 1=I2C 16bit, 2=SPI_00, 3=SPI_01, 4=SPI_10, 5=SPI_11
    speed : 0=100kbps, 1=200kbps, 2=300/400kbps, 3=500/800kbps
    N     : 수신 바이트 수
    buffer: 입력 파라미터 버퍼 (Control byte, Address 등)
*)
procedure I2CReceive(mode, speed, N: Integer; buffer: PByte);

(*
  I2CSend : I2C/SPI 송신
    mode  : 0=I2C 8bit, 1=I2C 16bit, 2=SPI_00, 3=SPI_01, 4=SPI_10, 5=SPI_11
    speed : 0=100kbps, 1=200kbps, 2=300/400kbps, 3=500/800kbps
    N     : 송신 바이트 수
    buffer: 송신 데이터 버퍼 (Control byte, Address, Data 순)
*)
procedure I2CSend(mode, speed, N: Integer; buffer: PByte);

implementation

// ── printM 헬퍼 ───────────────────────────────────────────────────────────
// C: #ifdef _GTKGUI → PrintMessageI2C(id)  else → printf(id)
// Qt GUI 버전: PrintMessageI2C 를 항상 사용
procedure printM(const id: AnsiString); inline;
begin
  PrintMessageI2C(id);    // Common 유닛의 Qt 버전 PrintMessageI2C 호출
end;

// ─────────────────────────────────────────────────────────────────────────────
// I2CReceive
// ─────────────────────────────────────────────────────────────────────────────
procedure I2CReceive(mode, speed, N: Integer; buffer: PByte);
var
  j, i  : Integer;
  s, t  : AnsiString;
begin
  // ── 파라미터 범위 클램핑 ──────────────────────────────────────────────────
  if N     < 0 then N     := 0;
  if N     > 60 then N    := 60;
  if mode  < 0 then mode  := 0;
  if mode  > 5 then mode  := 5;
  if speed < 0 then speed := 0;
  if speed > 3 then speed := 3;

  // ── 로그 기록 ────────────────────────────────────────────────────────────
  if saveLog <> 0 then
  begin
    OpenLogFile;
    // fprintf(logfile, "I2C-SPI receive\tmode=%d\tspeed=%d\n", mode, speed)
    WriteLn(TTextRec(logfile^).BufPtr, // 실제 구현에서는 logfile 스트림에 기록
      Format('I2C-SPI receive'#9'mode=%d'#9'speed=%d', [mode, speed]));
    // 주의: logfile이 FILE*이므로 FPC에서는 TextFile 또는 TFileStream으로 래핑 필요
  end;

  // ── 1차 패킷: 전원 및 인터페이스 초기화 ──────────────────────────────────
  j := 0;
  bufferU[j] := VREG_DIS;    Inc(j);   // HV 레귤레이터 비활성화
  bufferU[j] := EN_VPP_VCC;  Inc(j);   // VDD 활성화
  bufferU[j] := $01;         Inc(j);

  if mode < 2 then
  begin
    // I2C 모드 초기화
    // speed>0 이면 슬루 레이트 제어 활성화 (bit 6 = 0x40)
    bufferU[j] := I2C_INIT;  Inc(j);
    bufferU[j] := Byte((speed shl 3) + IfThen(speed > 0, $40, 0));  Inc(j);
  end
  else
  begin
    // SPI 모드 초기화
    bufferU[j] := EXT_PORT;   Inc(j);   // CS=1
    bufferU[j] := CS_PIN;     Inc(j);
    bufferU[j] := 0;          Inc(j);
    bufferU[j] := EXT_PORT;   Inc(j);   // CS=0
    bufferU[j] := 0;          Inc(j);
    bufferU[j] := 0;          Inc(j);
    bufferU[j] := SPI_INIT;   Inc(j);
    // speed 하위 2비트 + (mode-2) << 2
    bufferU[j] := Byte(speed + ((mode - 2) shl 2));  Inc(j);
  end;

  bufferU[j] := FLUSH;  Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00;  Inc(j); end;
  PacketIO(2);

  // ── 2차 패킷: 읽기 명령 ──────────────────────────────────────────────────
  j := 0;
  if mode = 0 then
  begin
    // I2C 8bit 읽기
    bufferU[j] := I2C_READ;   Inc(j);
    bufferU[j] := Byte(IfThen(N > (DIMBUF - 4), DIMBUF - 4, N));  Inc(j);
    bufferU[j] := buffer[0];  Inc(j);   // Control byte
    bufferU[j] := buffer[1];  Inc(j);   // Address
  end
  else if mode = 1 then
  begin
    // I2C 16bit 읽기
    bufferU[j] := I2C_READ2;  Inc(j);
    bufferU[j] := Byte(IfThen(N > (DIMBUF - 4), DIMBUF - 4, N));  Inc(j);
    bufferU[j] := buffer[0];  Inc(j);   // Control byte
    bufferU[j] := buffer[1];  Inc(j);   // Address H
    bufferU[j] := buffer[2];  Inc(j);   // Address L
  end
  else
  begin
    // SPI 읽기 (mode >= 2)
    bufferU[j] := SPI_READ;   Inc(j);
    bufferU[j] := Byte(IfThen(N > (DIMBUF - 5), DIMBUF - 5, N));  Inc(j);
    bufferU[j] := EXT_PORT;   Inc(j);   // CS=1
    bufferU[j] := CS_PIN;     Inc(j);
    bufferU[j] := 0;          Inc(j);
  end;

  bufferU[j] := FLUSH;  Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00;  Inc(j); end;
  PacketIO(10);

  if saveLog <> 0 then
    CloseLogFile;

  // ── 응답 처리 ─────────────────────────────────────────────────────────────
  if (bufferI[0] = I2C_READ) or (bufferI[0] = I2C_READ2) or (bufferI[0] = SPI_READ) then
  begin
    if bufferI[1] = $FD then
      printM(AnsiString(strings_[S_I2CAckErr]))   // "acknowledge error"
    else if bufferI[1] > $FA then
      printM(AnsiString(strings_[S_InsErr]))       // "unknown instruction"
    else
    begin
      // 송신 헤더 출력
      if (mode = 0) or (mode = 1) then
        s := AnsiString(Format('> %02X %02X'#13#10,
               [bufferU[2], bufferU[3]]))
      else
        s := '';
      s := s + '< ';

      // 수신 데이터 16바이트 단위 hex 출력
      for i := 0 to bufferI[1] - 1 do
      begin
        t := AnsiString(Format('%02X ', [bufferI[i + 2]]));
        s := s + t;
        if (i > 0) and ((i mod 16) = 15) then
          s := s + #13#10;
      end;
      s := s + #13#10;
      printM(s);
    end;
  end
  else
    printM(AnsiString(strings_[S_ComErr]));  // "communication error"
end;

// ─────────────────────────────────────────────────────────────────────────────
// I2CSend
// ─────────────────────────────────────────────────────────────────────────────
procedure I2CSend(mode, speed, N: Integer; buffer: PByte);
var
  j, i, n  : Integer;
  s, t      : AnsiString;
begin
  // ── 파라미터 범위 클램핑 ──────────────────────────────────────────────────
  if N     < 0  then N     := 0;
  if N     > 57 then N     := 57;
  if mode  < 0  then mode  := 0;
  if mode  > 5  then mode  := 5;
  if speed < 0  then speed := 0;
  if speed > 3  then speed := 3;

  // ── 로그 기록 ────────────────────────────────────────────────────────────
  if saveLog <> 0 then
  begin
    OpenLogFile;
    WriteLn(TTextRec(logfile^).BufPtr,
      Format('I2C-SPI send'#9'mode=%d'#9'speed=%d', [mode, speed]));
  end;

  // ── 1차 패킷: 전원 및 인터페이스 초기화 ──────────────────────────────────
  j := 0;
  bufferU[j] := VREG_DIS;    Inc(j);
  bufferU[j] := EN_VPP_VCC;  Inc(j);
  bufferU[j] := $01;         Inc(j);

  if mode < 2 then
  begin
    bufferU[j] := I2C_INIT;  Inc(j);
    bufferU[j] := Byte((speed shl 3) + IfThen(speed > 0, $40, 0));  Inc(j);
  end
  else
  begin
    bufferU[j] := EXT_PORT;  Inc(j);   // CS=1
    bufferU[j] := CS_PIN;    Inc(j);
    bufferU[j] := 0;         Inc(j);
    bufferU[j] := EXT_PORT;  Inc(j);   // CS=0
    bufferU[j] := 0;         Inc(j);
    bufferU[j] := 0;         Inc(j);
    bufferU[j] := SPI_INIT;  Inc(j);
    bufferU[j] := Byte(speed + ((mode - 2) shl 2));  Inc(j);
  end;

  bufferU[j] := FLUSH;  Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00;  Inc(j); end;
  PacketIO(2);

  // ── 2차 패킷: 쓰기 명령 ──────────────────────────────────────────────────
  j := 0;
  if mode = 0 then
  begin
    // I2C 8bit 쓰기
    bufferU[j] := I2C_WRITE;  Inc(j);
    bufferU[j] := Byte(IfThen(N > (DIMBUF - 5), DIMBUF - 5, N));  Inc(j);
    bufferU[j] := buffer[0];  Inc(j);   // Control byte
    bufferU[j] := buffer[1];  Inc(j);   // Address
    for i := 0 to bufferU[1] - 1 do
    begin
      bufferU[j] := buffer[i + 2];  Inc(j);
    end;
  end
  else if mode = 1 then
  begin
    // I2C 16bit 쓰기
    bufferU[j] := I2C_WRITE;  Inc(j);
    bufferU[j] := Byte(IfThen(N + 1 > (DIMBUF - 5), DIMBUF - 5, N + 1));  Inc(j);
    bufferU[j] := buffer[0];  Inc(j);   // Control byte
    bufferU[j] := buffer[1];  Inc(j);   // Address H
    bufferU[j] := buffer[2];  Inc(j);   // Address L
    for i := 0 to bufferU[1] - 2 do
    begin
      bufferU[j] := buffer[i + 3];  Inc(j);
    end;
  end;

  if mode >= 2 then
  begin
    // SPI 쓰기
    bufferU[j] := SPI_WRITE;  Inc(j);
    bufferU[j] := Byte(IfThen(N > (DIMBUF - 5), DIMBUF - 5, N));  Inc(j);
    for i := 0 to bufferU[1] - 1 do
    begin
      bufferU[j] := buffer[i];  Inc(j);
    end;
    bufferU[j] := EXT_PORT;  Inc(j);   // CS=1
    bufferU[j] := CS_PIN;    Inc(j);
    bufferU[j] := 0;         Inc(j);
  end;

  bufferU[j] := FLUSH;  Inc(j);
  while j < DIMBUF do begin bufferU[j] := $00;  Inc(j); end;
  PacketIO(20);

  if saveLog <> 0 then
    CloseLogFile;

  // ── 응답 처리 ─────────────────────────────────────────────────────────────
  if (bufferI[0] = I2C_WRITE) or (bufferI[0] = SPI_WRITE) then
  begin
    if bufferI[1] = $FD then
      printM(AnsiString(strings_[S_I2CAckErr]))
    else if bufferI[1] > $FA then
      printM(AnsiString(strings_[S_InsErr]))
    else
    begin
      s := '> ';
      // I2C: 헤더 4바이트(cmd, len, ctrl, addr) 건너뜀 → n=4
      // SPI: 헤더 2바이트(cmd, len) 건너뜀            → n=2
      if mode < 2 then n := 4 else n := 2;

      for i := 0 to bufferU[1] - 1 do
      begin
        t := AnsiString(Format('%02X ', [Byte(bufferU[i + n])]));
        s := s + t;
        if (i > 0) and ((i mod 16) = 15) then
          s := s + #13#10;
      end;
      s := s + #13#10;
      printM(s);
    end;
  end
  else
    printM(AnsiString(strings_[S_ComErr]));   // "communication error"
end;

end.
