unit strings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common;

const
  NL = '\n';

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

// --- function declarations ---
function strfind(langid: PChar; langfile: PChar): Integer;
procedure GenerateLangFile(langid: PChar; langfile: PChar);

implementation

function strfind(langid: PChar; langfile: PChar): Integer;
var
  f: ^TextFile;
  line: array[0..4096-1] of Char;
  id: Char;
  string: Char;
  p: Char;
  temp: array[0..32-1] of Char;
  i: Integer;
begin
  f := fopen(langfile, 'r');
  i := 0;
  if f then
  begin
   temp[0] := 0;
   (* TODO gtk2laz: complex for loop: for(;fgets(line,sizeof(line),f);){ 			if(sscanf(line,"[%[^]]",temp)&&!strncmp(langid,temp,sizeof(temp))){ 				strings=malloc(DIM*sizeof(char*)); 				for(i=0;i<DIM;i++) strings[i]=0; 				for(;fgets(lin *)
  end;
end;

procedure GenerateLangFile(langid: PChar; langfile: PChar);
var
  f: ^TextFile;
  i: Integer;
  j: Integer;
  if(strings_en[i][j]=='\r') fprintf(f,"%s","\\r"): Telse;
  fprintf(f,"%c",strings_en[i][j]): Telse;
begin
  f := fopen(langfile, 'a');
  if f then
  begin
   fprintf(f, '' + LineEnding + '' + LineEnding + '[%s]' + LineEnding + '', IfThen(langid, langid, 'x'));
   for i := 1 to (DIM) - 1 do
   begin
    fprintf(f, '%s' + #9 + '' + #9 + '', STR_ID[i]);
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while: for(j=0;strings_en[i][j];j++){ 				if(strings_en[i][j]=='\n') fprintf(f,"%s","\\n"); 				else if(strings_en[i][j]=='\r') fprintf(f,"%s","\\r"); 				else fprintf(f,"%c",strings_en[i][j]); 			} 			fprin *)
    // init: j=0
    while strings_en[i][j] do
    begin
     if strings_en[i][j] = '\n' then
      fprintf(f, '%s', ''' + LineEnding + '');
     (* TODO gtk2laz: unrecognised statement: j++; *)
    end;
   end;
  end;
end;

end.
