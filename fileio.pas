unit fileio;

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
  progp12,
  progp16,
  progp18,
  progp24,
  progavr,
  devicerw,
  mainform;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  inst: array of TINSTRUCTIONS;

// --- function declarations ---
function htoi(hex: PChar; length: Integer): Cardinal;
function Save(devType: Integer; savefile: PChar): Pointer;
function SaveEE(devType: Integer; savefile: PChar): Pointer;
function Load(devType: Integer; loadfile: PChar): Integer;
function LoadEE(devType: Integer; loadfile: PChar): Pointer;
procedure OpenLogFile;
procedure CloseLogFile;
procedure WriteLogParsedIO;
procedure WriteLogIO;

implementation

function htoi(hex: PChar; length: Integer): Cardinal;
var
  i: Integer;
  v: Cardinal;
begin
  v := 0;
  for i := 0 to (length) - 1 do
  begin
   v := v shl 4;
   if ((hex[i]) >= (#48)) and ((hex[i]) <= (#57)) then
    v := v + (hex[i]) - (#48)
   else
    if ((hex[i]) >= (#97)) and ((hex[i]) <= (#102)) then
     v := v + ((hex[i]) - (#97)) + (10)
    else
     if ((hex[i]) >= (#65)) and ((hex[i]) <= (#70)) then
      v := v + ((hex[i]) - (#65)) + (10)
     else
     begin
      sprintf(str, strings[S_Inohex], hex);
      PrintMessage(str);
     end;
  end;
  Exit(v);
end;

function Save(devType: Integer; savefile: PChar): Pointer;
var
  f: ^TextFile;
  str: array[0..512-1] of Char;
  str1: array[0..512-1] of Char;
  i: Integer;
  sum: Integer;
  count: Integer;
  ext: Integer;
  s: Integer;
  base: Integer;
  x: Integer;
  addr: Integer;
  valid: Integer;
  sum: Integer;
  count: Integer;
  s: Integer;
  word: Integer;
  valid: Integer;
begin
  f := fopen(savefile, "w");
  if not (f) then
   Exit;
  str1 := "";
  sum := 0;
  count := 0;
  ext := 0;
  if ((devType) = (PIC12)) or ((devType) = (PIC16)) then
  begin
   x := $3fff;
   fprintf(f, ":020000040000FA\n");
   for i := 0 to (sizeW) - 1 do
   begin
    memCODE_W[i] := memCODE_W[i] and x;
   end;
   i := 0;
   while ((i) < (sizeW)) and ((memCODE_W[i]) >= (x)) do
   begin
    Inc(i);
   end;
   while (i) < (sizeW) do
   begin
    sum := sum + ((memCODE_W[i]) shr (8)) + ((memCODE_W[i]) and ($ff));
    sprintf(str, "%02X%02X", (memCODE_W[i]) and ($ff), (memCODE_W[i]) shr (8));
    strcat(str1, str);
    Inc(count);
    if ((count) = (8)) or ((i) = ((sizeW) - (1))) then
    begin
     base := ((i) - (count)) + (1);
     s := i;
     while ((s) >= (base)) and ((memCODE_W[s]) >= (x)) do
     begin
      sum := sum - ((memCODE_W[s]) shr (8)) + ((memCODE_W[s]) and ($ff));
      str1[(strlen(str1)) - (4)] := 0;
      Dec(s);
     end;
     count := count - (i) - (s);
     addr := (((s) - (count)) + (1)) * (2);
     sum := sum + (((count) * (2)) + ((addr) and ($ff))) + ((addr) shr (8));
     if ((base) shr (15)) > (ext) then
     begin
      ext := (base) shr (15);
      fprintf(f, ":02000004%04X%02X\n", ext, ((-(6)) - (ext)) and ($ff));
     end;
     if count then
      fprintf(f, ":%02X%04X00%s%02X\n", (count) * (2), (addr) and ($FFFF), str1, (-(sum)) and ($ff));
     str1[0] := 0;
     sum := 0; count := 0;
    end;
    Inc(i);
   end;
   if sizeEE then
   begin
    if (ext) <> ($01) then
     fprintf(f, ":020000040001F9\n");
    sum := 0; count := 0;
    for i := 0 to (sizeEE) - 1 do
    begin
     sum := sum + memEE[i];
     sprintf(str, "%02X00", (memEE[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if ((count) = (8)) or ((i) = ((sizeEE) - (1))) then
     begin
      s := i;
      while ((s) > ((i) - (count))) and ((memEE[s]) >= ($ff)) do
      begin
       sum := sum - (memEE[s]) and ($ff);
       str1[(strlen(str1)) - (4)] := 0;
       Dec(s);
      end;
      count := count - (i) - (s);
      addr := ((((s) - (count)) + (1)) * (2)) + ($E000);
      sum := sum + (((count) * (2)) + ((addr) and ($ff))) + ((addr) shr (8));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", (count) * (2), addr, str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      sum := 0; count := 0;
     end;
    end;
   end;
   fprintf(f, ":00000001FF\n");
  end
  else
   if (devType) = (PIC18) then
   begin
    fprintf(f, ":020000040000FA\n");
    i := 0;
    while ((i) < (size)) and ((memCODE[i]) = ($ff)) do
    begin
     Inc(i);
    end;
    while (i) < (size) do
    begin
     sum := sum + memCODE[i];
     sprintf(str, "%02X", memCODE[i]);
     strcat(str1, str);
     Inc(count);
     if ((count) = (16)) or ((i) = ((size) - (1))) then
     begin
      base := ((i) - (count)) + (1);
      s := i;
      while ((s) >= (base)) and ((memCODE[s]) = ($ff)) do
      begin
       sum := sum - memCODE[s];
       str1[(strlen(str1)) - (2)] := 0;
       Dec(s);
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if ((base) shr (16)) > (ext) then
      begin
       ext := (base) shr (16);
       fprintf(f, ":02000004%04X%02X\n", ext, ((-(6)) - (ext)) and ($ff));
      end;
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      sum := 0; count := 0;
     end;
     Inc(i);
    end;
    sum := 0; count := 0;
    for i := 0 to (8) - 1 do
    begin
     sum := sum + memID[i];
     sprintf(str, "%02X", (memID[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if (count) = (8) then
     begin
      fprintf(f, ":020000040020DA\n");
      base := ((i) - (count)) + (1);
      s := i;
      while ((s) > ((i) - (count))) and ((memID[s]) >= ($ff)) do
      begin
       sum := sum - (memID[s]) and ($ff);
       str1[(strlen(str1)) - (2)] := 0;
       Dec(s);
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      sum := 0; count := 0;
     end;
    end;
    sum := 0; count := 0;
    for i := 0 to (14) - 1 do
    begin
     sum := sum + memCONFIG[i];
     sprintf(str, "%02X", (memCONFIG[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if (count) = (14) then
     begin
      fprintf(f, ":020000040030CA\n");
      base := ((i) - (count)) + (1);
      s := i;
      while ((s) > ((i) - (count))) and ((memCONFIG[s]) >= ($ff)) do
      begin
       sum := sum - (memCONFIG[s]) and ($ff);
       str1[(strlen(str1)) - (2)] := 0;
       Dec(s);
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      sum := 0; count := 0;
     end;
    end;
    if sizeEE then
    begin
     fprintf(f, ":0200000400F00A\n");
     sum := 0; count := 0;
     for i := 0 to (sizeEE) - 1 do
     begin
      sum := sum + memEE[i];
      sprintf(str, "%02X", (memEE[i]) and ($ff));
      strcat(str1, str);
      Inc(count);
      if ((count) = (16)) or ((i) = ((sizeEE) - (1))) then
      begin
       base := ((i) - (count)) + (1);
       s := i;
       while ((s) > ((i) - (count))) and ((memEE[s]) >= ($ff)) do
       begin
        sum := sum - (memEE[s]) and ($ff);
        str1[(strlen(str1)) - (2)] := 0;
        Dec(s);
       end;
       count := count - (i) - (s);
       sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
       if count then
       begin
        fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
       end;
       str1[0] := 0;
       sum := 0; count := 0;
      end;
     end;
    end;
    fprintf(f, ":00000001FF\n");
   end
   else
    if (devType) = (PIC24) then
    begin
     fprintf(f, ":020000040000FA\n");
     sum := 0;
     count := 0;
     word := (((memCODE[0]) + ((memCODE[1]) shl (8))) + ((memCODE[2]) shl (16))) + ((memCODE[3]) shl (24));
     i := 0;
     while ((i) < (size)) and ((word) = ($ffffffff)) do
     begin
      word := (((memCODE[i]) + ((memCODE[(i) + (1)]) shl (8))) + ((memCODE[(i) + (2)]) shl (16))) + ((memCODE[(i) + (3)]) shl (24));
      Inc(i, 4);
     end;
     while (i) < (size) do
     begin
      sum := sum + memCODE[i];
      sprintf(str, "%02X", memCODE[i]);
      strcat(str1, str);
      Inc(count);
      if ((count) = (16)) or ((i) = ((size) - (1))) then
      begin
       base := ((i) - (count)) + (1);
       s := base;
       valid := 0;
       while ((s) <= (i)) and (not (valid)) do
       begin
        if (((memCODE[s]) < ($FF)) or ((memCODE[(s) + (1)]) < ($FF))) or ((+(memCODE[(s) + (2)])) < ($FF)) then
         valid := 1;
        Inc(s, 4);
       end;
       sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
       if ((base) shr (16)) > (ext) then
       begin
        ext := (base) shr (16);
        fprintf(f, ":02000004%04X%02X\n", ext, ((-(6)) - (ext)) and ($ff));
       end;
       if (count) and (valid) then
       begin
        fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
       end;
       str1[0] := 0;
       sum := 0; count := 0;
      end;
      Inc(i);
     end;
     if sizeCONFIG then
     begin
      fprintf(f, ":0200000401F009\n");
      i := 0;
      sum := 0; count := 0;
      while ((i) < (sizeCONFIG)) and ((i) < (48)) do
      begin
       sum := sum + memCONFIG[i];
       sprintf(str, "%02X", memCONFIG[i]);
       strcat(str1, str);
       Inc(count);
       if ((count) = (4)) or ((i) = ((sizeCONFIG) - (1))) then
       begin
        base := ((i) - (count)) + (1);
        sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
        if count then
        begin
         fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
        end;
        str1[0] := 0;
        sum := 0; count := 0;
       end;
       Inc(i);
      end;
     end;
     if sizeEE then
     begin
      fprintf(f, ":0200000400FFFB\n");
      str1[0] := 0;
      sum := 0; count := 0;
      i := 0;
      while (i) < (sizeEE) do
      begin
       sum := sum + (memEE[i]) + (memEE[(i) + (1)]);
       sprintf(str, "%02X%02X0000", (memEE[i]) and ($ff), (memEE[(i) + (1)]) and ($ff));
       strcat(str1, str);
       count := count + 4;
       if ((count) = (16)) or ((i) = ((sizeEE) - (2))) then
       begin
        base := (((2) * (i)) - (count)) + (4);
        s := (base) div (2);
        valid := 0;
        while ((s) <= (i)) and (not (valid)) do
        begin
         if ((memEE[s]) < ($FF)) or ((memEE[(s) + (1)]) < ($FF)) then
          valid := 1;
         Inc(s, 2);
        end;
        sum := sum + ((($E0) + (count)) + ((base) and ($ff))) + ((base) shr (8));
        if (count) and (valid) then
        begin
         fprintf(f, ":%02X%04X00%s%02X\n", count, (base) + ($E000), str1, (-(sum)) and ($ff));
        end;
        str1[0] := 0;
        sum := 0; count := 0;
       end;
       Inc(i, 2);
      end;
     end;
     fprintf(f, ":00000001FF\n");
    end
    else
     if (devType) = (AVR) then
     begin
      fprintf(f, ":020000040000FA\n");
      i := 0;
      while ((i) < (size)) and ((memCODE[i]) = ($ff)) do
      begin
       Inc(i);
      end;
      while (i) < (size) do
      begin
       sum := sum + memCODE[i];
       sprintf(str, "%02X", memCODE[i]);
       strcat(str1, str);
       Inc(count);
       if ((count) = (16)) or ((i) = ((size) - (1))) then
       begin
        base := ((i) - (count)) + (1);
        s := i;
        while ((s) >= (base)) and ((memCODE[s]) = ($ff)) do
        begin
         sum := sum - memCODE[s];
         str1[(strlen(str1)) - (2)] := 0;
         Dec(s);
        end;
        count := count - (i) - (s);
        sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
        if ((base) shr (16)) > (ext) then
        begin
         ext := (base) shr (16);
         fprintf(f, ":02000004%04X%02X\n", ext, ((-(6)) - (ext)) and ($ff));
        end;
        if count then
        begin
         fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
        end;
        str1[0] := 0;
        sum := 0; count := 0;
       end;
       Inc(i);
      end;
      fprintf(f, ":00000001FF\n");
     end
     else
      if (((((devType) = (I2CEE)) or ((devType) = (SPIEE))) or ((devType) = (UWEE))) or ((devType) = (OWEE))) or ((devType) = (UNIOEE)) then
      begin
       if (strstr(savefile, ".bin")) or (strstr(savefile, ".BIN")) then
       begin
        fwrite(memEE, 1, sizeEE, f);
       end
       else
       begin
        fprintf(f, ":020000040000FA\n");
        for i := 0 to (sizeEE) - 1 do
        begin
         sum := sum + memEE[i];
         sprintf(str, "%02X", memEE[i]);
         strcat(str1, str);
         Inc(count);
         if ((count) = (16)) or ((i) = ((sizeEE) - (1))) then
         begin
          valid := 0; s := 0;
          while (str1[s]) and (not (valid)) do
          begin
           if (str1[s]) <> (#70) then
            valid := 1;
           Inc(s);
          end;
          if valid then
          begin
           base := ((i) - (count)) + (1);
           sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
           if ((base) shr (16)) > (ext) then
           begin
            ext := (base) shr (16);
            fprintf(f, ":02000004%04X%02X\n", ext, ((-(6)) - (ext)) and ($ff));
           end;
           if count then
           begin
            fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
           end;
          end;
          str1[0] := 0;
          sum := 0; count := 0;
         end;
        end;
        fprintf(f, ":00000001FF\n");
       end;
      end;
  if f then
   fclose(f);
end;

function SaveEE(devType: Integer; savefile: PChar): Pointer;
var
  f: ^TextFile;
  str: array[0..512-1] of Char;
  str1: array[0..512-1] of Char;
  i: Integer;
  base: Integer;
  sum: Integer;
  count: Integer;
  s: Integer;
begin
  f := fopen(savefile, "w");
  if not (f) then
   Exit
  else
   if (devType) = (AVR) then
   begin
    str1 := "";
    fprintf(f, ":020000040000FA\n");
    sum := 0;
    count := 0;
    sum := 0; count := 0;
    for i := 0 to (sizeEE) - 1 do
    begin
     sum := sum + memEE[i];
     sprintf(str, "%02X", (memEE[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if ((count) = (16)) or ((i) = ((sizeEE) - (1))) then
     begin
      base := ((i) - (count)) + (1);
      s := i;
      while ((s) > ((i) - (count))) and ((memEE[s]) >= ($ff)) do
      begin
       sum := sum - (memEE[s]) and ($ff);
       str1[(strlen(str1)) - (2)] := 0;
       Dec(s);
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      sum := 0; count := 0;
     end;
    end;
    fprintf(f, ":00000001FF\n");
   end;
  if f then
   fclose(f);
end;

function Load(devType: Integer; loadfile: PChar): Integer;
var
  i: Integer;
  input_address: Integer;
  ext_addr: Integer;
  sum: Integer;
  valid: Integer;
  line: array[0..256-1] of Char;
  f: ^TextFile;
  buffer: array[0..0x20000-1] of Byte;
  bufferEE: array[0..0x1000-1] of Byte;
  sizeM: Integer;
  hex_count: Integer;
  imax: Integer;
  buffer: array[0..0x30000-1] of Byte;
  bufferEE: array[0..0x1000-1] of Byte;
  sizeM: Integer;
  hex_count: Integer;
  buffer: PByte;
  bufferEE: array[0..0x2000-1] of Byte;
  d: Integer;
  hex_count: Integer;
  end1: Integer;
  buffer: array[0..0x30000-1] of Byte;
  hex_count: Integer;
  bufSize: Integer;
  bufferEE: PByte;
  hex_count: Integer;
  end1: Integer;
  newsize: Integer;
  sum: Integer;
begin
  input_address := 0;
  ext_addr := 0;
  f := fopen(loadfile, "r");
  if not (f) then
   Exit(-(1));
  sprintf(str, "[%d] %s :\r\n", devType, loadfile);
  PrintMessage(str);
  if ((devType) = (PIC12)) or ((devType) = (PIC16)) then
  begin
   sizeM := 0;
   memset(buffer, $FF, SizeOf(buffer));
   memset(bufferEE, $FF, SizeOf(bufferEE));
   sizeEE := 0;
   while fgets(line, 256, f) do
   begin
    if ((strlen(line)) > (9)) and ((line[0]) = (#58)) then
    begin
     hex_count := htoi((line) + (1), 2);
     if ((strlen(line)) - (11)) < ((hex_count) * (2)) then
     begin
      sprintf(str, strings[S_IhexShort], line);
      PrintMessage(str);
     end
     else
     begin
      input_address := ((ext_addr) shl (16)) + (htoi((line) + (3), 4));
      sum := 0;
      i := 1;
      while (i) <= (((hex_count) * (2)) + (9)) do
      begin
       sum := sum + htoi((line) + (i), 2);
       Inc(i, 2);
      end;
      if ((sum) and ($ff)) <> (0) then
      begin
       sprintf(str, strings[S_IhexChecksum], line);
       PrintMessage(str);
      end
      else
      begin
       case htoi((line) + (7), 2) of
        0:
        begin
         if (input_address) < ($1E000) then
         begin
          sizeM := (input_address) + (hex_count);
          if (sizeM) > (sizeW) then
           sizeW := sizeM;
          for i := 0 to (hex_count) - 1 do
          begin
           buffer[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
          end;
         end
         else
          if ((input_address) >= ($1E000)) and ((input_address) < ($1F000)) then
          begin
           sizeM := (((input_address) - ($1E000)) + (hex_count)) div (2);
           if (sizeM) > (sizeEE) then
            sizeEE := sizeM;
           i := 0;
           while (i) < (hex_count) do
           begin
            bufferEE[(((input_address) - ($1E000)) div (2)) + ((i) div (2))] := htoi(((line) + (9)) + ((i) * (2)), 2);
            Inc(i, 2);
           end;
          end;
        end;
        4:
        begin
         if (strlen(line)) > (14) then
          ext_addr := htoi((line) + (9), 4);
        end;
        else
        begin
        end;
       end;
      end;
     end;
    end;
   end;
   sizeW := sizeW div 2;
   if memCODE_W then
    free(memCODE_W);
   memCODE_W := malloc((SizeOf(WORD)) * (sizeW));
   for i := 0 to (sizeW) - 1 do
   begin
    memCODE_W[i] := ((buffer[((i) * (2)) + (1)]) shl (8)) + (buffer[(i) * (2)]);
   end;
   if memEE then
    free(memEE);
   if sizeEE then
   begin
    memEE := malloc(sizeEE);
    memcpy(memEE, bufferEE, sizeEE);
   end
   else
    memEE := 0;
   PrintMessage(strings[S_CodeMem]);
   imax := IfThen((sizeW) > ($8000), $8500, $2100);
   DisplayCODE16F(imax);
   if ((sizeW) >= ($2100)) and ((sizeW) < ($3000)) then
   begin
    PrintMessage(strings[S_EEMem]);
    DisplayEE16F($700);
   end
   else
    if sizeEE then
     DisplayEE();
   PrintMessage("\r\n");
  end
  else
   if (devType) = (PIC18) then
   begin
    memset(buffer, $FF, SizeOf(buffer));
    memset(bufferEE, $FF, SizeOf(bufferEE));
    memset(memID, $FF, SizeOf(memID));
    memset(memCONFIG, $FF, SizeOf(memCONFIG));
    while fgets(line, 256, f) do
    begin
     if ((strlen(line)) > (9)) and ((line[0]) = (#58)) then
     begin
      hex_count := htoi((line) + (1), 2);
      if ((strlen(line)) - (11)) < ((hex_count) * (2)) then
      begin
       sprintf(str, strings[S_IhexShort], line);
       PrintMessage(str);
      end
      else
      begin
       input_address := htoi((line) + (3), 4);
       sum := 0;
       i := 1;
       while (i) <= (((hex_count) * (2)) + (9)) do
       begin
        sum := sum + htoi((line) + (i), 2);
        Inc(i, 2);
       end;
       if ((sum) and ($ff)) <> (0) then
       begin
        sprintf(str, strings[S_IhexChecksum], line);
        PrintMessage(str);
       end
       else
       begin
        case htoi((line) + (7), 2) of
         0:
         begin
          if (ext_addr) < ($20) then
          begin
           sizeM := (((ext_addr) shl (16)) + (input_address)) + (hex_count);
           if (sizeM) > (size) then
            size := sizeM;
           for i := 0 to (hex_count) - 1 do
           begin
            buffer[(((ext_addr) shl (16)) + (input_address)) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
           end;
          end
          else
           if ((ext_addr) = ($20)) and ((input_address) < (64)) then
           begin
            for i := 0 to (hex_count) - 1 do
            begin
             memID[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
            end;
           end
           else
            if ((ext_addr) = ($30)) and ((input_address) < (32)) then
            begin
             for i := 0 to (hex_count) - 1 do
             begin
              memCONFIG[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
             end;
            end
            else
             if ((((ext_addr) = ($F0)) or ((ext_addr) = ($31))) or ((ext_addr) = ($38))) and ((input_address) < ($1000)) then
             begin
              for i := 0 to (hex_count) - 1 do
              begin
               bufferEE[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
              end;
              sizeM := (input_address) + (hex_count);
              if (sizeM) > (sizeEE) then
               sizeEE := sizeM;
             end;
         end;
         4:
         begin
          if (strlen(line)) > (14) then
           ext_addr := htoi((line) + (9), 4);
         end;
         else
         begin
         end;
        end;
       end;
      end;
     end;
    end;
    if memCODE then
     free(memCODE);
    memCODE := malloc(size);
    memcpy(memCODE, buffer, size);
    if memEE then
     free(memEE);
    memEE := malloc(sizeEE);
    memcpy(memEE, bufferEE, sizeEE);
    PrintMessage(strings[S_IDMem]);
    i := 0;
    while (i) < (8) do
    begin
     sprintf(str, "ID%d: 0x%02X   ID%d: 0x%02X\r\n", i, memID[i], (i) + (1), memID[(i) + (1)]);
     PrintMessage(str);
     Inc(i, 2);
    end;
    PrintMessage(strings[S_ConfigMem]);
    for i := 0 to (12) - 1 do
    begin
     sprintf(str, "[0x%06X] 0x%02X\r\n", ($300000) + (i), memCONFIG[i]);
     PrintMessage(str);
    end;
    while (i) < (32) do
    begin
     if (memCONFIG[i]) <> ($FF) then
     begin
      sprintf(str, "[0x%06X] 0x%02X\r\n", ($300000) + (i), memCONFIG[i]);
      PrintMessage(str);
     end;
     Inc(i);
    end;
    PrintMessage(strings[S_CodeMem]);
    DisplayCODE18F(size);
    if sizeEE then
     DisplayEE();
    PrintMessage("\r\n");
   end
   else
    if (devType) = (PIC24) then
    begin
     buffer := malloc($100000);
     memset(buffer, $FF, $100000);
     memset(bufferEE, $FF, SizeOf(bufferEE));
     memset(memCONFIG, $FF, SizeOf(memCONFIG));
     memset(memUSERID, $FF, SizeOf(memUSERID));
     sizeUSERID := 0;
     while fgets(line, 256, f) do
     begin
      if ((strlen(line)) > (9)) and ((line[0]) = (#58)) then
      begin
       hex_count := htoi((line) + (1), 2);
       if ((strlen(line)) - (11)) < ((hex_count) * (2)) then
       begin
        sprintf(str, strings[S_IhexShort], line);
        PrintMessage(str);
       end
       else
       begin
        input_address := htoi((line) + (3), 4);
        sum := 0;
        i := 1;
        while (i) <= (((hex_count) * (2)) + (9)) do
        begin
         sum := sum + htoi((line) + (i), 2);
         Inc(i, 2);
        end;
        if ((sum) and ($ff)) <> (0) then
        begin
         sprintf(str, strings[S_IhexChecksum], line);
         PrintMessage(str);
        end
        else
        begin
         case htoi((line) + (7), 2) of
          0:
          begin
           if (ext_addr) < ($20) then
           begin
            end1 := (((ext_addr) shl (16)) + (input_address)) + (hex_count);
            if (size) < (end1) then
             size := end1;
            for i := 0 to (hex_count) - 1 do
            begin
             buffer[(((ext_addr) shl (16)) + (input_address)) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
            end;
           end
           else
            if ((ext_addr) = ($1F0)) and ((input_address) < (48)) then
            begin
             sizeCONFIG := (input_address) + (hex_count);
             for i := 0 to (hex_count) - 1 do
             begin
              memCONFIG[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
             end;
            end
            else
             if ((ext_addr) = ($FF)) and ((input_address) >= ($E000)) then
             begin
              for i := 0 to (hex_count) - 1 do
              begin
               bufferEE[((input_address) - ($E000)) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
              end;
              sizeEE := ((input_address) - ($E000)) + (hex_count);
             end
             else
              if ((ext_addr) = ($100)) and ((input_address) < (8)) then
              begin
               sizeUSERID := (input_address) + (hex_count);
               i := 0;
               while ((i) < (hex_count)) and (((i) + (input_address)) < (8)) do
               begin
                memUSERID[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
                Inc(i);
               end;
              end;
          end;
          4:
          begin
           if (strlen(line)) > (14) then
            ext_addr := htoi((line) + (9), 4);
          end;
          else
          begin
          end;
         end;
        end;
       end;
      end;
     end;
     if memCODE then
      free(memCODE);
     memCODE := malloc(size);
     memcpy(memCODE, buffer, size);
     free(buffer);
     sizeEE := IfThen(sizeEE, $1000, 0);
     if memEE then
      free(memEE);
     memEE := malloc(sizeEE);
     i := 0;
     while (i) < (sizeEE) do
     begin
      memEE[i] := bufferEE[(i) * (2)];
      memEE[(i) + (1)] := bufferEE[((i) * (2)) + (1)];
      Inc(i, 2);
     end;
     for i := (valid := 0) to (48) - 1 do
     begin
      if (memCONFIG[i]) < ($FF) then
       valid := 1;
     end;
     if valid then
     begin
      PrintMessage(strings[S_ConfigMem]);
      i := 0;
      while (i) < (48) do
      begin
       d := ((memCONFIG[(i) + (1)]) shl (8)) + (memCONFIG[i]);
       if ((i) < (36)) or ((d) < ($FFFF)) then
       begin
        sprintf(str, "0xF800%02X: 0x%04X\r\n", (i) div (2), d);
        PrintMessage(str);
       end;
       Inc(i, 4);
      end;
     end;
     if size then
      PrintMessage(strings[S_CodeMem]);
     DisplayCODE24F(size);
     if sizeEE then
     begin
      PrintMessage(strings[S_EEMem]);
      DisplayEE24F();
     end;
     PrintMessage("\r\n");
    end
    else
     if (devType) = (AVR) then
     begin
      memset(buffer, $FF, SizeOf(buffer));
      while fgets(line, 256, f) do
      begin
       if ((strlen(line)) > (9)) and ((line[0]) = (#58)) then
       begin
        hex_count := htoi((line) + (1), 2);
        if ((strlen(line)) - (11)) < ((hex_count) * (2)) then
        begin
         sprintf(str, strings[S_IhexShort], line);
         PrintMessage(str);
        end
        else
        begin
         input_address := htoi((line) + (3), 4);
         sum := 0;
         i := 1;
         while (i) <= (((hex_count) * (2)) + (9)) do
         begin
          sum := sum + htoi((line) + (i), 2);
          Inc(i, 2);
         end;
         if ((sum) and ($ff)) <> (0) then
         begin
          sprintf(str, strings[S_IhexChecksum], line);
          PrintMessage(str);
         end
         else
         begin
          case htoi((line) + (7), 2) of
           0:
           begin
            if (ext_addr) < ($20) then
            begin
             size := (input_address) + (hex_count);
             for i := 0 to (hex_count) - 1 do
             begin
              buffer[(((ext_addr) shl (16)) + (input_address)) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
             end;
            end;
           end;
           4:
           begin
            if (strlen(line)) > (14) then
             ext_addr := htoi((line) + (9), 4);
           end;
           else
           begin
           end;
          end;
         end;
        end;
       end;
      end;
      if memCODE then
       free(memCODE);
      memCODE := malloc(size);
      memcpy(memCODE, buffer, size);
      if size then
       PrintMessage(strings[S_CodeMem]);
      DisplayCODEAVR(size);
      PrintMessage("\r\n");
     end
     else
      if (((((devType) = (I2CEE)) or ((devType) = (SPIEE))) or ((devType) = (UWEE))) or ((devType) = (OWEE))) or ((devType) = (UNIOEE)) then
      begin
       if (strstr(loadfile, ".bin")) or (strstr(loadfile, ".BIN")) then
       begin
        fseek(f, 0, SEEK_END);
        sizeEE := ftell(f);
        fseek(f, 0, SEEK_SET);
        if (sizeEE) > ($1000000) then
         sizeEE := $1000000;
        if memEE then
         free(memEE);
        memEE := malloc(sizeEE);
        sizeEE := fread(memEE, 1, sizeEE, f);
       end
       else
       begin
        bufSize := $40000;
        bufferEE := malloc(bufSize);
        memset(bufferEE, $FF, bufSize);
        while fgets(line, 256, f) do
        begin
         if ((strlen(line)) > (9)) and ((line[0]) = (#58)) then
         begin
          hex_count := htoi((line) + (1), 2);
          if ((strlen(line)) - (11)) < ((hex_count) * (2)) then
          begin
           sprintf(str, strings[S_IhexShort], line);
           PrintMessage(str);
          end
          else
          begin
           input_address := htoi((line) + (3), 4);
           sum := 0;
           i := 1;
           while (i) <= (((hex_count) * (2)) + (9)) do
           begin
            sum := sum + htoi((line) + (i), 2);
            Inc(i, 2);
           end;
           if ((sum) and ($ff)) <> (0) then
           begin
            sprintf(str, strings[S_IhexChecksum], line);
            PrintMessage(str);
           end
           else
           begin
            case htoi((line) + (7), 2) of
             0:
             begin
              end1 := (((ext_addr) shl (16)) + (input_address)) + (hex_count);
              if (end1) >= ($1000000) then
               Break;
              if (sizeEE) < (end1) then
              begin
               sizeEE := end1;
              end;
              if (bufSize) <= (end1) then
              begin
               newsize := ((end1) and ($FFFC0000)) + ($40000);
               bufferEE := realloc(bufferEE, newsize);
               memset((bufferEE) + (bufSize), $FF, (newsize) - (bufSize));
               bufSize := newsize;
              end;
              for i := 0 to (hex_count) - 1 do
              begin
               bufferEE[(((ext_addr) shl (16)) + (input_address)) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
              end;
             end;
             4:
             begin
              if (strlen(line)) > (14) then
               ext_addr := htoi((line) + (9), 4);
             end;
             else
             begin
             end;
            end;
           end;
          end;
         end;
        end;
        if memEE then
         free(memEE);
        memEE := malloc(sizeEE);
        memcpy(memEE, bufferEE, sizeEE);
        free(bufferEE);
       end;
       DisplayEE();
       sum := 0;
       for i := 0 to (sizeEE) - 1 do
       begin
        sum := sum + memEE[i];
       end;
       sprintf(str, "Checksum: 0x%X\r\n", (sum) and ($FFFF));
       PrintMessage(str);
       PrintMessage("\r\n");
      end;
  fclose(f);
  Exit(0);
end;

function LoadEE(devType: Integer; loadfile: PChar): Pointer;
var
  f: ^TextFile;
  i: Integer;
  line: array[0..256-1] of Char;
  input_address: Integer;
  ext_addr: Integer;
  bufferEE: array[0..0x1000-1] of Byte;
  hex_count: Integer;
  sum: Integer;
begin
  f := fopen(loadfile, "r");
  if not (f) then
   Exit;
  if (devType) = (AVR) then
  begin
   input_address := 0;
   ext_addr := 0;
   sprintf(str, "%s :\r\n\r\n", loadfile);
   PrintMessage(str);
   memset(bufferEE, $FF, SizeOf(bufferEE));
   while fgets(line, 256, f) do
   begin
    if ((strlen(line)) > (9)) and ((line[0]) = (#58)) then
    begin
     hex_count := htoi((line) + (1), 2);
     if ((strlen(line)) - (11)) < ((hex_count) * (2)) then
     begin
      sprintf(str, strings[S_IhexShort], line);
      PrintMessage(str);
     end
     else
     begin
      input_address := htoi((line) + (3), 4);
      sum := 0;
      i := 1;
      while (i) <= (((hex_count) * (2)) + (9)) do
      begin
       sum := sum + htoi((line) + (i), 2);
       Inc(i, 2);
      end;
      if ((sum) and ($ff)) <> (0) then
      begin
       sprintf(str, strings[S_IhexChecksum], line);
       PrintMessage(str);
      end
      else
      begin
       case htoi((line) + (7), 2) of
        0:
        begin
         if ((ext_addr) = (0)) and ((input_address) < ($1000)) then
         begin
          for i := 0 to (hex_count) - 1 do
          begin
           bufferEE[(input_address) + (i)] := htoi(((line) + (9)) + ((i) * (2)), 2);
          end;
          sizeEE := (input_address) + (hex_count);
         end;
        end;
        4:
        begin
         if (strlen(line)) > (14) then
          ext_addr := htoi((line) + (9), 4);
        end;
        else
        begin
        end;
       end;
      end;
     end;
    end;
   end;
   if memEE then
    free(memEE);
   memEE := malloc(sizeEE);
   memcpy(memEE, bufferEE, sizeEE);
   if sizeEE then
    DisplayEE();
   PrintMessage("\r\n");
   fclose(f);
  end;
end;

procedure OpenLogFile;
var
  timeinfo: ^Ttm;
  rawtime: Ttime_t;
begin
  logfile := fopen(LogFileName, "w");
  if not (logfile) then
   Exit;
  fprintf(logfile, "OPGUI version %s (%s)\n", "unknown", "Linux");
  fprintf(logfile, "Firmware version %d.%d.%d\n", (FWVersion) shr (16), ((FWVersion) shr (8)) and ($FF), (FWVersion) and ($FF));
  time(@(rawtime));
  timeinfo := localtime(@(rawtime));
  fprintf(logfile, "%s\n", asctime(timeinfo));
end;

procedure CloseLogFile;
var
  // (no local variables detected)
begin
  if logfile then
   fclose(logfile);
  logfile := 0;
end;

procedure WriteLogParsedIO;
var
  i: Integer;
  u: Integer;
  r: Integer;
  p: Integer;
  N: Integer;
  A: Integer;
  x: Integer;
  bit: Integer;
  tot: Integer;
  N: Integer;
  A: Integer;
  x: Integer;
  bit: Integer;
  tot: Integer;
begin
  r := 0;
  for u := 0 to (64) - 1 do
  begin
   for i := 0 to ((SizeOf(inst)) div (SizeOf(struct INSTRUCTIONS))) - 1 do
   begin
    if (bufferU[u]) = (inst[i].code) then
    begin
     fprintf(logfile, "%02X %s", bufferU[u], inst[i].name_);
     if (inst[i].params) < ($100) then
     begin
      for p := 0 to (inst[i].params) - 1 do
      begin
       Inc(u);
       fprintf(logfile, " %02X", bufferU[u]);
      end;
     end
     else
     begin
      N := bufferU[(u) + (1)];
      A := (inst[i].params) shr (8);
      x := (inst[i].params) and ($F);
      bit := IfThen((inst[i].params) and ($10), 1, 0);
      if (bit) = (0) then
       tot := (A) + ((N) * (x))
      else
       tot := (A) + (((((N) * (x)) - (1)) shr (3)) + (1));
      for p := 0 to (tot) - 1 do
      begin
       Inc(u);
       fprintf(logfile, " %02X", bufferU[u]);
      end;
     end;
     if (inst[i].retParams) = (-(1)) then
      u := 64
     else
      if (inst[i].retParams) < ($100) then
      begin
       if (bufferI[r]) = (inst[i].code) then
       begin
        Inc(r);
        fprintf(logfile, " ->");
        if (inst[i].retParams) = (0) then
         fprintf(logfile, " OK");
        for p := 0 to (inst[i].retParams) - 1 do
        begin
         if ((p) > (15)) and (((p) mod (22)) = (0)) then
          fprintf(logfile, "\n\t\t\t\t");
         fprintf(logfile, " %02X", bufferI[Inc(r)]);
        end;
       end
       else
        fprintf(logfile, " -> NAK");
      end
      else
      begin
       if (bufferI[r]) = (inst[i].code) then
       begin
        fprintf(logfile, " ->");
        N := bufferI[(r) + (1)];
        A := (inst[i].retParams) shr (8);
        x := (inst[i].retParams) and ($F);
        bit := IfThen((inst[i].retParams) and ($10), 1, 0);
        if (bit) = (0) then
         tot := (A) + ((N) * (x))
        else
         tot := (A) + (((((N) * (x)) - (1)) shr (3)) + (1));
        if (N) > ($F0) then
         tot := A;
        for p := 0 to (tot) - 1 do
        begin
         Inc(r);
         if ((p) > (15)) and (((p) mod (22)) = (0)) then
          fprintf(logfile, "\n\t\t\t\t");
         fprintf(logfile, " %02X", bufferI[r]);
        end;
        Inc(r);
       end
       else
        fprintf(logfile, " -> NAK");
      end;
     fprintf(logfile, "\n");
     Break;
    end;
   end;
   if (i) >= ((SizeOf(inst)) div (SizeOf(struct INSTRUCTIONS))) then
   begin
    fprintf(logfile, "%02X ??\n", bufferU[u]);
   end;
  end;
end;

procedure WriteLogIO;
var
  i: Integer;
begin
  fprintf(logfile, "bufferU=[");
  for i := 0 to (64) - 1 do
  begin
   if ((i) mod (32)) = (0) then
    fprintf(logfile, "\n");
   fprintf(logfile, "%02X ", bufferU[i]);
  end;
  fprintf(logfile, "]\n");
  fprintf(logfile, "bufferI=[");
  for i := 0 to (64) - 1 do
  begin
   if ((i) mod (32)) = (0) then
    fprintf(logfile, "\n");
   fprintf(logfile, "%02X ", bufferI[i]);
  end;
  fprintf(logfile, "]\n");
  WriteLogParsedIO();
end;

end.
