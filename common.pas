unit Common;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

// {$DEFINE DEBUG}

const
  _APPNAME   = 'OPGUI';
  _QTGUI     = True;              // GTK → Qt 로 변경

  COL        = 16;
  VERSION    = 'unknown';         // Makefile 또는 프로젝트 옵션에서 정의
  G          = (12.0 / 34 * 1024 / 5);  // ≈ 72.2823529412

  // 플래그 상수
  LOCK       = 1;
  FUSE       = 2;
  FUSE_H     = 4;
  FUSE_X     = 8;
  CAL        = 16;
  SLOW       = 256;

{$IF Defined(LINUX) or Defined(UNIX)}
  SYSNAME    = 'Linux';
  DIMBUF     = 64;
{$ELSE}
  SYSNAME    = 'Windows';
  DIMBUF     = 64;
{$ENDIF}

type
  DWORD  = LongWord;       // unsigned long  (32-bit)
  WORD   = Word;           // unsigned short (16-bit)
  BYTE   = Byte;           // unsigned char  (8-bit)
  PDWORD = ^DWORD;
  PWORD  = ^WORD;
  PBYTE  = ^Byte;

// ── 매크로 → 인라인 헬퍼 프로시저 ──────────────────────────────────────────
// C 매크로를 Object Pascal 인라인 프로시저로 대체합니다.
// Qt 위젯 포인터(QStatusBar, QTextEdit 등)는 별도 폼 유닛에서 주입합니다.

procedure PrintMessage1(const Fmt: string; const P: array of const); inline;
procedure PrintMessage2(const Fmt: string; const P1, P2: Variant);   inline;
procedure PrintMessage3(const Fmt: string; const P1, P2, P3: Variant); inline;
procedure PrintMessage4(const Fmt: string; const P1, P2, P3, P4: Variant); inline;

// StatusBar 출력 — Qt: QStatusBar.showMessage()
// ※ GTK: gtk_statusbar_push() + gtk_events_pending() 루프
//    Qt:  status_bar.showMessage(text) + QCoreApplication.processEvents()
procedure PrintStatus(const Fmt: string; const P1, P2: Variant); inline;
procedure PrintStatusSetup(); inline;   // 콘솔 버전 전용 — GUI에서는 빈 구현
procedure PrintStatusEnd();   inline;   // 콘솔 버전 전용 — GUI에서는 빈 구현
procedure PrintStatusClear(); inline;

// ── 플랫폼별 전역 변수 ────────────────────────────────────────────────────
{$IF Defined(LINUX) or Defined(UNIX)}
var
  bufferU : array[0..127] of Byte;
  bufferI : array[0..127] of Byte;

function GetTickCount(): DWORD;
{$ELSE}
// Windows 전용 핸들/버퍼 — Windows API/HID 헤더 임포트 필요
var
  bufferU0          : array[0..127] of Byte;
  bufferI0          : array[0..127] of Byte;
  bufferU           : PByte;
  bufferI           : PByte;
  NumberOfBytesRead : DWORD;
  BytesWritten      : DWORD;
  Result_           : LongWord;  // 'Result'는 Pascal 예약어 → Result_ 사용
  WriteHandle       : THandle;
  ReadHandle        : THandle;
  // OVERLAPPED, HANDLE 등은 Windows 유닛 또는 별도 HID 유닛에서 선언
{$ENDIF}

// ── Qt UI 위젯 포인터 (외부 폼 유닛에서 할당) ──────────────────────────────
// GTK 버전의 GtkWidget* status_bar 를 대체합니다.
// 실제 타입은 Qt 바인딩(Qt5Pas 등)에 맞게 조정하세요.
var
  // Qt StatusBar — (구)GTK: GtkStatusbar*
  // Qt5Pas 직접 바인딩: QStatusBarH
  // LCL + Qt 백엔드:    TStatusBar
  status_bar_handle : Pointer;

  // Qt TextEdit 메시지 출력용 — (구)GTK: GtkTextView*
  // Qt5Pas 직접 바인딩: QTextEditH
  // LCL + Qt 백엔드:    TMemo
  msg_view_handle   : Pointer;

// ── 공통 전역 변수 ────────────────────────────────────────────────────────
var
  statusID        : Integer;
  str             : array[0..4095] of AnsiChar;  // char str[4096]
  saveLog         : Integer;
  strings_        : PPAnsiChar;   // char** strings  ('strings'는 Pascal 예약어)
  fd              : Integer;
  programID       : Integer;
  MinDly          : Integer;
  load_osccal     : Integer;
  load_BKosccal   : Integer;
  use_osccal      : Integer;
  use_BKosccal    : Integer;
  load_calibword  : Integer;
  max_err         : Integer;
  AVRlock         : Integer;
  AVRfuse         : Integer;
  AVRfuse_h       : Integer;
  AVRfuse_x       : Integer;
  ICDenable       : Integer;
  ICDaddr         : Integer;
  FWVersion       : Integer;
  HwID            : Integer;
  logfile         : Pointer;      // FILE*
  LogFileName     : array[0..511] of AnsiChar;
  loadfile        : array[0..511] of AnsiChar;
  savefile        : array[0..511] of AnsiChar;
  memCODE_W       : PWORD;
  size_           : Integer;      // 'size' 는 일부 컴파일러와 충돌 → size_
  sizeW           : Integer;
  sizeEE          : Integer;
  sizeCONFIG      : Integer;
  sizeUSERID      : Integer;
  memCODE         : PByte;
  memEE           : PByte;
  memID           : array[0..511] of Byte;
  memCONFIG_      : array[0..47]  of Byte;   // memCONFIG[48]
  memUSERID       : array[0..7]   of Byte;
  hvreg           : Double;
  RWstop          : Integer;
  useSAFLOCK_flag : Integer;

// ── 함수/프로시저 선언 ────────────────────────────────────────────────────
function  StartHVReg(V: Double): Integer;
procedure msDelay(Delay: Double);
procedure DisplayEE();
procedure PrintMessage(const Msg: AnsiString);
procedure PrintMessageI2C(const Msg: AnsiString);
function  CheckV33Regulator(): Integer;
procedure OpenLogFile();
procedure WriteLogIO();
procedure CloseLogFile();
function  htoi(const Hex: AnsiString; Length: Integer): LongWord;
procedure PacketIO(Delay: Double);

implementation

uses
  SysUtils, Variants, Math
  {$IFDEF LCL}
  , Forms, Controls    // LCL: Application.ProcessMessages
  {$ENDIF}
  ;

// ============================================================================
// 매크로 → 인라인 프로시저 구현
// ============================================================================

procedure PrintMessage1(const Fmt: string; const P: array of const);
begin
  PrintMessage(AnsiString(Format(Fmt, P)));
end;

procedure PrintMessage2(const Fmt: string; const P1, P2: Variant);
begin
  PrintMessage(AnsiString(Format(Fmt, [P1, P2])));
end;

procedure PrintMessage3(const Fmt: string; const P1, P2, P3: Variant);
begin
  PrintMessage(AnsiString(Format(Fmt, [P1, P2, P3])));
end;

procedure PrintMessage4(const Fmt: string; const P1, P2, P3, P4: Variant);
begin
  PrintMessage(AnsiString(Format(Fmt, [P1, P2, P3, P4])));
end;

// ----------------------------------------------------------------------------
// PrintStatus
// ┌──────────────┬────────────────────────────────────────────────────────┐
// │  GTK (구)    │ gtk_statusbar_push(GTK_STATUSBAR(status_bar),          │
// │              │   statusID, PAnsiChar(S));                             │
// │              │ while (gtk_events_pending()) gtk_main_iteration();     │
// ├──────────────┼────────────────────────────────────────────────────────┤
// │  Qt5Pas (신) │ QStatusBar_showMessage(QStatusBarH(status_bar_handle), │
// │              │   @QStr(S), 0);                                        │
// │              │ QCoreApplication_processEvents(AllEvents, 100);        │
// ├──────────────┼────────────────────────────────────────────────────────┤
// │  LCL/Qt (신) │ TStatusBar(status_bar_handle).SimpleText := S;         │
// │              │ Application.ProcessMessages;                           │
// └──────────────┴────────────────────────────────────────────────────────┘
// ----------------------------------------------------------------------------
procedure PrintStatus(const Fmt: string; const P1, P2: Variant);
var
  S: string;
begin
  S := Format(Fmt, [P1, P2]);

  if status_bar_handle <> nil then
  begin
    {$IFDEF QT5PAS}
    // Qt5Pas 직접 바인딩:
    // QStatusBar_showMessage(QStatusBarH(status_bar_handle), @QStr(S), 0);
    // QCoreApplication_processEvents(QEventLoop_AllEvents, 100);
    {$ELSE}
    // LCL + Qt 백엔드:
    // TStatusBar(status_bar_handle).SimpleText := S;
    // Application.ProcessMessages;
    {$ENDIF}
  end;

  WriteLn('[STATUS] ', S);   // 위젯 미연결 시 콘솔 폴백
end;

procedure PrintStatusSetup();
begin
  // 콘솔 버전 전용 — Qt GUI 버전에서는 아무것도 하지 않음
end;

procedure PrintStatusEnd();
begin
  // 콘솔 버전 전용 — Qt GUI 버전에서는 아무것도 하지 않음
end;

// ----------------------------------------------------------------------------
// PrintStatusClear
// ┌──────────────┬────────────────────────────────────────────────┐
// │  GTK (구)    │ gtk_statusbar_push(..., statusID, "");          │
// ├──────────────┼────────────────────────────────────────────────┤
// │  Qt5Pas (신) │ QStatusBar_clearMessage(QStatusBarH(...));      │
// ├──────────────┼────────────────────────────────────────────────┤
// │  LCL/Qt (신) │ TStatusBar(status_bar_handle).SimpleText := ''; │
// └──────────────┴────────────────────────────────────────────────┘
// ----------------------------------------------------------------------------
procedure PrintStatusClear();
begin
  if status_bar_handle <> nil then
  begin
    {$IFDEF QT5PAS}
    // QStatusBar_clearMessage(QStatusBarH(status_bar_handle));
    {$ELSE}
    // TStatusBar(status_bar_handle).SimpleText := '';
    {$ENDIF}
  end;
end;

// ============================================================================
// 플랫폼별 구현
// ============================================================================

{$IF Defined(LINUX) or Defined(UNIX)}
function GetTickCount(): DWORD;
{$IFDEF FPC}
var
  TS: TTimeSpec;
begin
  // Qt 버전에서도 내부적으로 동일하게 POSIX clock_gettime 사용
  clock_gettime(CLOCK_MONOTONIC, @TS);
  Result := DWORD(TS.tv_sec * 1000 + TS.tv_nsec div 1000000);
end;
{$ELSE}
begin
  Result := 0; // TODO: 플랫폼별 구현 필요
end;
{$ENDIF}
{$ENDIF}

// ============================================================================
// 함수 구현
// ============================================================================

function StartHVReg(V: Double): Integer;
begin
  Result := 0; // TODO
end;

// ----------------------------------------------------------------------------
// msDelay
// ┌──────────────┬──────────────────────────────────────────────────┐
// │  GTK (구)    │ g_usleep(delay * 1000)  또는  usleep()           │
// ├──────────────┼──────────────────────────────────────────────────┤
// │  Qt5Pas (신) │ QThread_msleep(Round(Delay));                     │
// ├──────────────┼──────────────────────────────────────────────────┤
// │  LCL/Qt (신) │ Sleep(Round(Delay));                              │
// │              │ Application.ProcessMessages; (UI 응답 유지 시)    │
// └──────────────┴──────────────────────────────────────────────────┘
// ----------------------------------------------------------------------------
procedure msDelay(Delay: Double);
begin
  {$IFDEF QT5PAS}
  // QThread_msleep(Round(Delay));
  {$ELSE}
  Sleep(Round(Delay));
  {$IFDEF LCL}
  // Application.ProcessMessages;   // 필요 시 주석 해제
  {$ENDIF}
  {$ENDIF}
end;

procedure DisplayEE();
begin
  // TODO
end;

// ----------------------------------------------------------------------------
// PrintMessage
// ┌──────────────┬───────────────────────────────────────────────────────┐
// │  GTK (구)    │ gtk_text_buffer_insert_at_cursor(buffer, msg, -1);    │
// │              │ gtk_text_view_scroll_to_mark(...)                     │
// ├──────────────┼───────────────────────────────────────────────────────┤
// │  Qt5Pas (신) │ QTextEdit_append(QTextEditH(msg_view_handle),         │
// │              │   @QStr(string(Msg)));                                │
// │              │ QCoreApplication_processEvents(AllEvents, 0);         │
// ├──────────────┼───────────────────────────────────────────────────────┤
// │  LCL/Qt (신) │ TMemo(msg_view_handle).Lines.Add(string(Msg));        │
// │              │ Application.ProcessMessages;                          │
// └──────────────┴───────────────────────────────────────────────────────┘
// ----------------------------------------------------------------------------
procedure PrintMessage(const Msg: AnsiString);
begin
  if msg_view_handle <> nil then
  begin
    {$IFDEF QT5PAS}
    // QTextEdit_append(QTextEditH(msg_view_handle), @QStr(string(Msg)));
    // QCoreApplication_processEvents(QEventLoop_AllEvents, 0);
    {$ELSE}
    // LCL + Qt 백엔드:
    // TMemo(msg_view_handle).Lines.Add(string(Msg));
    // Application.ProcessMessages;
    {$ENDIF}
  end
  else
    WriteLn(Msg);   // 위젯 미연결 시 콘솔 폴백
end;

// ----------------------------------------------------------------------------
// PrintMessageI2C
//   I2C 전용 메시지 채널 — 별도 위젯 없으면 PrintMessage 와 동일 처리
// ----------------------------------------------------------------------------
procedure PrintMessageI2C(const Msg: AnsiString);
begin
  PrintMessage(Msg);
end;

function CheckV33Regulator(): Integer;
begin
  Result := 0; // TODO
end;

procedure OpenLogFile();
begin
  // TODO
end;

procedure WriteLogIO();
begin
  // TODO
end;

procedure CloseLogFile();
begin
  // TODO
end;

// ----------------------------------------------------------------------------
// htoi — 16진수 문자열을 정수로 변환
// ----------------------------------------------------------------------------
function htoi(const Hex: AnsiString; Length: Integer): LongWord;
var
  I : Integer;
  C : AnsiChar;
begin
  Result := 0;
  for I := 1 to Min(Length, System.Length(Hex)) do
  begin
    C := Hex[I];
    case C of
      '0'..'9': Result := Result * 16 + LongWord(Ord(C) - Ord('0'));
      'a'..'f': Result := Result * 16 + LongWord(Ord(C) - Ord('a') + 10);
      'A'..'F': Result := Result * 16 + LongWord(Ord(C) - Ord('A') + 10);
    else
      Break;
    end;
  end;
end;

procedure PacketIO(Delay: Double);
begin
  // TODO
end;

// ============================================================================
// 초기화 — 전역 Qt 위젯 포인터를 nil 로 초기화
// ============================================================================
initialization
  status_bar_handle := nil;
  msg_view_handle   := nil;

end.
