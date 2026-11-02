unit icons;

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
  LCLType;

const
  NL = #10;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  write_icon: array of Byte;
  read_icon: array of Byte;
  system_icon: array of Byte;
  go_icon: array of Byte;
  halt_icon: array of Byte;
  step_icon: array of Byte;
  stepover_icon: array of Byte;
  stop_icon: array of Byte;

// --- function declarations ---

implementation

end.
