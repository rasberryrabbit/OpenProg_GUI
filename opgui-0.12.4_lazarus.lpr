program opgui-0.12.4_lazarus;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widget set
  Forms
  , mainform
  , i2cspi
  , coff
  , strings
  , instructions
  , common
  , devicerw
  , fileio
  , icd
  , progavr
  , progeeprom
  , progp12
  , progp16
  , progp18
  , progp24
  , progp32
  , opgui
  , i2cspi
  , coff
  , devicerw
  , fileio
  , icd
  , icons
  , progavr
  , progeeprom
  , progp12
  , progp16
  , progp18
  , progp24
  , progp32
  , resources
  , strings;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
