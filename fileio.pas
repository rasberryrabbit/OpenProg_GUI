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
    v := v + (hex[i]) - (#48);
   else
    if ((hex[i]) >= (#97)) and ((hex[i]) <= (#102)) then
     v := v + ((hex[i]) - (#97)) + (10);
    else
     if ((hex[i]) >= (#65)) and ((hex[i]) <= (#70)) then
      v := v + ((hex[i]) - (#65)) + (10);
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
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/fileIO.c:56
     Original C:
       for (i = 0; (i < sizeW) && (memCODE_W[i] >= x); i++)
         ;
   *)
   // init: i = 0
   while ((i) < (sizeW)) and ((memCODE_W[i]) >= (x)) do
   begin
     // step: i++
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
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/fileIO.c:64
       Original C:
         for (s = i; (s >= base) && (memCODE_W[s] >= x); s--)
         {
           sum -= (memCODE_W[s] >> 8) + (memCODE_W[s] & 0xff);
           str1[strlen(str1) - 4] = 0;
         }
     *)
     // init: s = i
     while ((s) >= (base)) and ((memCODE_W[s]) >= (x)) do
     begin
      sum := sum - ((memCODE_W[s]) shr (8)) + ((memCODE_W[s]) and ($ff));
      str1[(strlen(str1)) - (4)] := 0;
       // step: s--
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
     count := (sum := 0);
    end;
    Inc(i);
   end;
   if sizeEE then
   begin
    if (ext) <> ($01) then
     fprintf(f, ":020000040001F9\n");
    while (i) < (sizeEE) do
    begin
     sum := sum + memEE[i];
     sprintf(str, "%02X00", (memEE[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if ((count) = (8)) or ((i) = ((sizeEE) - (1))) then
     begin
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:88
        Original C:
          for (s = i; (s > (i - count)) && (memEE[s] >= 0xff); s--)
          {
            sum -= memEE[s] & 0xff;
            str1[strlen(str1) - 4] = 0;
          }
      *)
      // init: s = i
      while ((s) > ((i) - (count))) and ((memEE[s]) >= ($ff)) do
      begin
       sum := sum - (memEE[s]) and ($ff);
       str1[(strlen(str1)) - (4)] := 0;
        // step: s--
      end;
      count := count - (i) - (s);
      addr := ((((s) - (count)) + (1)) * (2)) + ($E000);
      sum := sum + (((count) * (2)) + ((addr) and ($ff))) + ((addr) shr (8));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", (count) * (2), addr, str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      count := (sum := 0);
     end;
     Inc(i);
    end;
   end;
   fprintf(f, ":00000001FF\n");
  end
  else
   if (devType) = (PIC18) then
   begin
    fprintf(f, ":020000040000FA\n");
    (* TODO gtk2laz: for loop with non-standard form; rewritten as while
      Source: /tmp/opgui-0.12.4/fileIO.c:108
      Original C:
        for (i = 0; (i < size) && (memCODE[i] == 0xff); i++)
          ;
    *)
    // init: i = 0
    while ((i) < (size)) and ((memCODE[i]) = ($ff)) do
    begin
      // step: i++
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
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:116
        Original C:
          for (s = i; (s >= base) && (memCODE[s] == 0xff); s--)
          {
            sum -= memCODE[s];
            str1[strlen(str1) - 2] = 0;
          }
      *)
      // init: s = i
      while ((s) >= (base)) and ((memCODE[s]) = ($ff)) do
      begin
       sum := sum - memCODE[s];
       str1[(strlen(str1)) - (2)] := 0;
        // step: s--
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
      count := (sum := 0);
     end;
     Inc(i);
    end;
    while (i) < (8) do
    begin
     sum := sum + memID[i];
     sprintf(str, "%02X", (memID[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if (count) = (8) then
     begin
      fprintf(f, ":020000040020DA\n");
      base := ((i) - (count)) + (1);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:141
        Original C:
          for (s = i; (s > (i - count)) && (memID[s] >= 0xff); s--)
          {
            sum -= memID[s] & 0xff;
            str1[strlen(str1) - 2] = 0;
          }
      *)
      // init: s = i
      while ((s) > ((i) - (count))) and ((memID[s]) >= ($ff)) do
      begin
       sum := sum - (memID[s]) and ($ff);
       str1[(strlen(str1)) - (2)] := 0;
        // step: s--
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      count := (sum := 0);
     end;
     Inc(i);
    end;
    while (i) < (14) do
    begin
     sum := sum + memCONFIG[i];
     sprintf(str, "%02X", (memCONFIG[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if (count) = (14) then
     begin
      fprintf(f, ":020000040030CA\n");
      base := ((i) - (count)) + (1);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:162
        Original C:
          for (s = i; (s > (i - count)) && (memCONFIG[s] >= 0xff); s--)
          {
            sum -= memCONFIG[s] & 0xff;
            str1[strlen(str1) - 2] = 0;
          }
      *)
      // init: s = i
      while ((s) > ((i) - (count))) and ((memCONFIG[s]) >= ($ff)) do
      begin
       sum := sum - (memCONFIG[s]) and ($ff);
       str1[(strlen(str1)) - (2)] := 0;
        // step: s--
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      count := (sum := 0);
     end;
     Inc(i);
    end;
    if sizeEE then
    begin
     fprintf(f, ":0200000400F00A\n");
     while (i) < (sizeEE) do
     begin
      sum := sum + memEE[i];
      sprintf(str, "%02X", (memEE[i]) and ($ff));
      strcat(str1, str);
      Inc(count);
      if ((count) = (16)) or ((i) = ((sizeEE) - (1))) then
      begin
       base := ((i) - (count)) + (1);
       (* TODO gtk2laz: for loop with non-standard form; rewritten as while
         Source: /tmp/opgui-0.12.4/fileIO.c:184
         Original C:
           for (s = i; (s > (i - count)) && (memEE[s] >= 0xff); s--)
           {
             sum -= memEE[s] & 0xff;
             str1[strlen(str1) - 2] = 0;
           }
       *)
       // init: s = i
       while ((s) > ((i) - (count))) and ((memEE[s]) >= ($ff)) do
       begin
        sum := sum - (memEE[s]) and ($ff);
        str1[(strlen(str1)) - (2)] := 0;
         // step: s--
       end;
       count := count - (i) - (s);
       sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
       if count then
       begin
        fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
       end;
       str1[0] := 0;
       count := (sum := 0);
      end;
      Inc(i);
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
     (* TODO gtk2laz: for loop with non-standard form; rewritten as while
       Source: /tmp/opgui-0.12.4/fileIO.c:206
       Original C:
         for (i = 0; (i < size) && (word == 0xffffffff); i += 4)
           word = ((memCODE[i] + (memCODE[i + 1] << 8)) + (memCODE[i + 2] << 16)) + (memCODE[i + 3] << 24);
     *)
     // init: i = 0
     while ((i) < (size)) and ((word) = ($ffffffff)) do
     begin
      word := (((memCODE[i]) + ((memCODE[(i) + (1)]) shl (8))) + ((memCODE[(i) + (2)]) shl (16))) + ((memCODE[(i) + (3)]) shl (24));
       // step: i += 4
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
       (* TODO gtk2laz: for loop with non-standard form; rewritten as while
         Source: /tmp/opgui-0.12.4/fileIO.c:215
         Original C:
           for (s = base, valid = 0; (s <= i) && (!valid); s += 4)
           {
             if (((memCODE[s] < 0xFF) || (memCODE[s + 1] < 0xFF)) || ((+memCODE[s + 2]) < 0xFF))
               valid = 1;
           }
       *)
       // init: s = base, valid = 0
       while ((s) <= (i)) and (not (valid)) do
       begin
        if (((memCODE[s]) < ($FF)) or ((memCODE[(s) + (1)]) < ($FF))) or ((+(memCODE[(s) + (2)])) < ($FF)) then
         valid := 1;
         // step: s += 4
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
       count := (sum := 0);
      end;
      Inc(i);
     end;
     if sizeCONFIG then
     begin
      fprintf(f, ":0200000401F009\n");
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:232
        Original C:
          for (i = 0, count = (sum = 0); (i < sizeCONFIG) && (i < 48); i++)
          {
            sum += memCONFIG[i];
            sprintf(str, "%02X", memCONFIG[i]);
            strcat(str1, str);
            count++;
            if ((count == 4) || (i == (sizeCONFIG - 1)))
            {
              base = (i - count) + 1;
              sum += (count + (base & 0xff)) + ((base >> 8) & 0xff);
              if (count)
              {
                fprintf(f, ":%02X%04X00%s%02X\n", count, base & 0xFFFF, str1, (-sum) & 0xff);
              }
              str1[0] = 0;
              count = (sum = 0);
            }
          }
      *)
      // init: i = 0, count = (sum = 0)
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
        count := (sum := 0);
       end;
        // step: i++
      end;
     end;
     if sizeEE then
     begin
      fprintf(f, ":0200000400FFFB\n");
      str1[0] := 0;
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:251
        Original C:
          for (i = 0, count = (sum = 0); i < sizeEE; i += 2)
          {
            sum += memEE[i] + memEE[i + 1];
            sprintf(str, "%02X%02X0000", memEE[i] & 0xff, memEE[i + 1] & 0xff);
            strcat(str1, str);
            count += 4;
            if ((count == 16) || (i == (sizeEE - 2)))
            {
              base = ((2 * i) - count) + 4;
              for (s = base / 2, valid = 0; (s <= i) && (!valid); s += 2)
              {
                if ((memEE[s] < 0xFF) || (memEE[s + 1] < 0xFF))
                  valid = 1;
              }
          
              sum += ((0xE0 + count) + (base & 0xff)) + (base >> 8);
              if (count && valid)
              {
                fprintf(f, ":%02X%04X00%s%02X\n", count, base + 0xE000, str1, (-sum) & 0xff);
             ...
      *)
      // init: i = 0, count = (sum = 0)
      while (i) < (sizeEE) do
      begin
       sum := sum + (memEE[i]) + (memEE[(i) + (1)]);
       sprintf(str, "%02X%02X0000", (memEE[i]) and ($ff), (memEE[(i) + (1)]) and ($ff));
       strcat(str1, str);
       count := count + 4;
       if ((count) = (16)) or ((i) = ((sizeEE) - (2))) then
       begin
        base := (((2) * (i)) - (count)) + (4);
        (* TODO gtk2laz: for loop with non-standard form; rewritten as while
          Source: /tmp/opgui-0.12.4/fileIO.c:258
          Original C:
            for (s = base / 2, valid = 0; (s <= i) && (!valid); s += 2)
            {
              if ((memEE[s] < 0xFF) || (memEE[s + 1] < 0xFF))
                valid = 1;
            }
        *)
        // init: s = base / 2, valid = 0
        while ((s) <= (i)) and (not (valid)) do
        begin
         if ((memEE[s]) < ($FF)) or ((memEE[(s) + (1)]) < ($FF)) then
          valid := 1;
          // step: s += 2
        end;
        sum := sum + ((($E0) + (count)) + ((base) and ($ff))) + ((base) shr (8));
        if (count) and (valid) then
        begin
         fprintf(f, ":%02X%04X00%s%02X\n", count, (base) + ($E000), str1, (-(sum)) and ($ff));
        end;
        str1[0] := 0;
        count := (sum := 0);
       end;
        // step: i += 2
      end;
     end;
     fprintf(f, ":00000001FF\n");
    end
    else
     if (devType) = (AVR) then
     begin
      fprintf(f, ":020000040000FA\n");
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:275
        Original C:
          for (i = 0; (i < size) && (memCODE[i] == 0xff); i++)
            ;
      *)
      // init: i = 0
      while ((i) < (size)) and ((memCODE[i]) = ($ff)) do
      begin
        // step: i++
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
        (* TODO gtk2laz: for loop with non-standard form; rewritten as while
          Source: /tmp/opgui-0.12.4/fileIO.c:283
          Original C:
            for (s = i; (s >= base) && (memCODE[s] == 0xff); s--)
            {
              sum -= memCODE[s];
              str1[strlen(str1) - 2] = 0;
            }
        *)
        // init: s = i
        while ((s) >= (base)) and ((memCODE[s]) = ($ff)) do
        begin
         sum := sum - memCODE[s];
         str1[(strlen(str1)) - (2)] := 0;
          // step: s--
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
        count := (sum := 0);
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
          (* TODO gtk2laz: for loop with non-standard form; rewritten as while
            Source: /tmp/opgui-0.12.4/fileIO.c:321
            Original C:
              for (s = (valid = 0); str1[s] && (!valid); s++)
                if (str1[s] != 'F')
                valid = 1;
          *)
          // init: s = (valid = 0)
          while (str1[s]) and (not (valid)) do
          begin
           if (str1[s]) <> (#70) then
            valid := 1;
            // step: s++
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
          count := (sum := 0);
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
   Exit;
  else
   if (devType) = (AVR) then
   begin
    str1 := "";
    fprintf(f, ":020000040000FA\n");
    sum := 0;
    count := 0;
    while (i) < (sizeEE) do
    begin
     sum := sum + memEE[i];
     sprintf(str, "%02X", (memEE[i]) and ($ff));
     strcat(str1, str);
     Inc(count);
     if ((count) = (16)) or ((i) = ((sizeEE) - (1))) then
     begin
      base := ((i) - (count)) + (1);
      (* TODO gtk2laz: for loop with non-standard form; rewritten as while
        Source: /tmp/opgui-0.12.4/fileIO.c:359
        Original C:
          for (s = i; (s > (i - count)) && (memEE[s] >= 0xff); s--)
          {
            sum -= memEE[s] & 0xff;
            str1[strlen(str1) - 2] = 0;
          }
      *)
      // init: s = i
      while ((s) > ((i) - (count))) and ((memEE[s]) >= ($ff)) do
      begin
       sum := sum - (memEE[s]) and ($ff);
       str1[(strlen(str1)) - (2)] := 0;
        // step: s--
      end;
      count := count - (i) - (s);
      sum := sum + ((count) + ((base) and ($ff))) + (((base) shr (8)) and ($ff));
      if count then
      begin
       fprintf(f, ":%02X%04X00%s%02X\n", count, (base) and ($FFFF), str1, (-(sum)) and ($ff));
      end;
      str1[0] := 0;
      count := (sum := 0);
     end;
     Inc(i);
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
  imax: Integer;
  buffer: array[0..0x30000-1] of Byte;
  bufferEE: array[0..0x1000-1] of Byte;
  sizeM: Integer;
  buffer: Byte;
  bufferEE: array[0..0x2000-1] of Byte;
  d: Integer;
  buffer: array[0..0x30000-1] of Byte;
  bufSize: Integer;
  bufferEE=(unsigned char*)malloc(bufSize): Byte;
  sum: Integer;
begin
  input_address := 0;
  ext_addr := 0;
  f := fopen(loadfile, 'r');
  if  not f then
   Exit(-1);
  // return value of PrintMessage2() ignored
  PrintMessage2('[%d] %s :\r' + LineEnding + '', devType, loadfile);
  if devType = PIC12 or devType = PIC16 then
  begin
   sizeM := 0;
   FillChar(buffer, sizeof(buffer), $FF);
   FillChar(bufferEE, sizeof(bufferEE), $FF);
   sizeEE := 0;
   (* TODO gtk2laz: complex for loop
     Source: /tmp/opgui-0.12.4/fileIO.c:390
     Original C:
       		for(;fgets(line,256,f);){
       			if(strlen(line)>9&&line[0]==':'){
       				int hex_count = htoi(line+1, 2);
       					if((int)strlen(line)-11<hex_count*2) {
       						PrintMessage1(strings[S_IhexShort],line);	//"Intel hex8 line too short:\r\n%s\r\n"
       				}
       				else{
       					input_address=(ext_addr<<16)+htoi(line+3,4);
       					sum=0;
       					for (i=1;i<=hex_count*2+9;i+=2) sum += htoi(line+i,2);
       					if ((sum & 0xff)!=0) {
       							PrintMessage1(strings[S_IhexChecksum],line);	//"Intel hex8 checksum error in line:\r\n%s\r\n"
       					}
       					else{
       						switch(htoi(line+7,2)){
       							case 0:		//Data record
       								if(input_address<0x1E000){		//Code
       									sizeM=input_address+hex_count;
       									if(sizeM>sizeW) sizeW=sizeM;
       									for (i=0;i<hex_count;i++){
       										buffer[input_address+i]=htoi(line+9+i*2,2);
       									}
       								}
       								else if(input_address>=0x1E000&&input_address<0x1F000){	//EEPROM
       									sizeM=(input_address-0x1E000+hex_count)/2;
       									if(sizeM>sizeEE) sizeEE=sizeM;
       									for (i=0;i<hex_count;i+=2){
       										bufferEE[(input_address-0x1E000)/2+i/2]=htoi(line+9+i*2,2);
       									}
       								}
       								break;
   *)
   if memCODE_W then
    FreeMem(memCODE_W);
   memCODE_W := malloc(sizeof(WORD)*sizeW);
   for i := 0 to (sizeW) - 1 do
   begin
    memCODE_W[i] := (buffer[i*2+1] shl 8)+buffer[i*2];
   end;
   if sizeEE then
   begin
    memEE := malloc(sizeEE);
    Move(bufferEE, memEE, sizeEE);
   end
   else
    memEE := 0;
   // return value of PrintMessage() ignored
   PrintMessage(strings[S_CodeMem]);
   imax := IfThen(sizeW>0x8000, $8500, $2100);
   // return value of DisplayCODE16F() ignored
   DisplayCODE16F(imax);
   if sizeW>=0x2100 and sizeW<0x3000 then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_EEMem]);
    // return value of DisplayEE16F() ignored
    DisplayEE16F($700);
   end
   else if sizeEE then
    // return value of DisplayEE() ignored
    DisplayEE();
   // return value of PrintMessage() ignored
   PrintMessage('\r' + LineEnding + '');
  end
  else if devType = PIC18 then
  begin
   FillChar(buffer, sizeof(buffer), $FF);
   FillChar(bufferEE, sizeof(bufferEE), $FF);
   FillChar(memID, sizeof(memID), $FF);
   FillChar(memCONFIG, sizeof(memCONFIG), $FF);
   (* TODO gtk2laz: complex for loop
     Source: /tmp/opgui-0.12.4/fileIO.c:390
     Original C:
       		for(;fgets(line,256,f);){
       			if(strlen(line)>9&&line[0]==':'){
       				int hex_count = htoi(line+1, 2);
       					if((int)strlen(line)-11<hex_count*2) {
       						PrintMessage1(strings[S_IhexShort],line);	//"Intel hex8 line too short:\r\n%s\r\n"
       				}
       				else{
       					input_address=(ext_addr<<16)+htoi(line+3,4);
       					sum=0;
       					for (i=1;i<=hex_count*2+9;i+=2) sum += htoi(line+i,2);
       					if ((sum & 0xff)!=0) {
       							PrintMessage1(strings[S_IhexChecksum],line);	//"Intel hex8 checksum error in line:\r\n%s\r\n"
       					}
       					else{
       						switch(htoi(line+7,2)){
       							case 0:		//Data record
       								if(input_address<0x1E000){		//Code
       									sizeM=input_address+hex_count;
       									if(sizeM>sizeW) sizeW=sizeM;
       									for (i=0;i<hex_count;i++){
       										buffer[input_address+i]=htoi(line+9+i*2,2);
       									}
       								}
       								else if(input_address>=0x1E000&&input_address<0x1F000){	//EEPROM
       									sizeM=(input_address-0x1E000+hex_count)/2;
       									if(sizeM>sizeEE) sizeEE=sizeM;
       									for (i=0;i<hex_count;i+=2){
       										bufferEE[(input_address-0x1E000)/2+i/2]=htoi(line+9+i*2,2);
       									}
       								}
       								break;
   *)
   memCODE := malloc(size);
   Move(buffer, memCODE, size);
   if memEE then
    FreeMem(memEE);
   memEE := malloc(sizeEE);
   Move(bufferEE, memEE, sizeEE);
   // return value of PrintMessage() ignored
   PrintMessage(strings[S_IDMem]);
   for i := 0 to (8) - 1 do
   begin
    i := i + 2;
   end;
   // return value of PrintMessage() ignored
   PrintMessage(strings[S_ConfigMem]);
   for i := 0 to (12) - 1 do
   begin
    // return value of PrintMessage2() ignored
    PrintMessage2('[0x%06X] 0x%02X\r' + LineEnding + '', 0x300000+i, memCONFIG[i]);
   end;
   // return value of DisplayCODE18F() ignored
   DisplayCODE18F(size);
   if sizeEE then
    // return value of DisplayEE() ignored
    DisplayEE();
   // return value of PrintMessage() ignored
   PrintMessage('\r' + LineEnding + '');
  end
  else if devType = PIC24 then
  begin
   buffer := malloc($100000);
   FillChar(buffer, $100000, $FF);
   FillChar(bufferEE, sizeof(bufferEE), $FF);
   FillChar(memCONFIG, sizeof(memCONFIG), $FF);
   FillChar(memUSERID, sizeof(memUSERID), $FF);
   sizeUSERID := 0;
   (* TODO gtk2laz: complex for loop
     Source: /tmp/opgui-0.12.4/fileIO.c:390
     Original C:
       		for(;fgets(line,256,f);){
       			if(strlen(line)>9&&line[0]==':'){
       				int hex_count = htoi(line+1, 2);
       					if((int)strlen(line)-11<hex_count*2) {
       						PrintMessage1(strings[S_IhexShort],line);	//"Intel hex8 line too short:\r\n%s\r\n"
       				}
       				else{
       					input_address=(ext_addr<<16)+htoi(line+3,4);
       					sum=0;
       					for (i=1;i<=hex_count*2+9;i+=2) sum += htoi(line+i,2);
       					if ((sum & 0xff)!=0) {
       							PrintMessage1(strings[S_IhexChecksum],line);	//"Intel hex8 checksum error in line:\r\n%s\r\n"
       					}
       					else{
       						switch(htoi(line+7,2)){
       							case 0:		//Data record
       								if(input_address<0x1E000){		//Code
       									sizeM=input_address+hex_count;
       									if(sizeM>sizeW) sizeW=sizeM;
       									for (i=0;i<hex_count;i++){
       										buffer[input_address+i]=htoi(line+9+i*2,2);
       									}
       								}
       								else if(input_address>=0x1E000&&input_address<0x1F000){	//EEPROM
       									sizeM=(input_address-0x1E000+hex_count)/2;
       									if(sizeM>sizeEE) sizeEE=sizeM;
       									for (i=0;i<hex_count;i+=2){
       										bufferEE[(input_address-0x1E000)/2+i/2]=htoi(line+9+i*2,2);
       									}
       								}
       								break;
   *)
   memCODE := malloc(size);
   Move(buffer, memCODE, size);
   FreeMem(buffer);
   sizeEE := IfThen(sizeEE, $1000, 0);
   if memEE then
    FreeMem(memEE);
   memEE := malloc(sizeEE);
   for i := 0 to (sizeEE) - 1 do
   begin
    memEE[i] := bufferEE[i*2];
    memEE[i+1] := bufferEE[i*2+1];
    i := i + 2;
   end;
   if valid then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_ConfigMem]);
    for i := 0 to (48) - 1 do
    begin
     d := (memCONFIG[i+1] shl 8)+memCONFIG[i];
     if i<36 or d<0xFFFF then
      // return value of PrintMessage2() ignored
      PrintMessage2('0xF800%02X: 0x%04X\r' + LineEnding + '', i/2, d);
     i := i + 4;
    end;
   end;
   // return value of DisplayCODE24F() ignored
   DisplayCODE24F(size);
   if sizeEE then
   begin
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_EEMem]);
    // return value of DisplayEE24F() ignored
    DisplayEE24F();
   end;
  end
  else if devType = AVR then
  begin
   FillChar(buffer, sizeof(buffer), $FF);
   (* TODO gtk2laz: complex for loop
     Source: /tmp/opgui-0.12.4/fileIO.c:390
     Original C:
       		for(;fgets(line,256,f);){
       			if(strlen(line)>9&&line[0]==':'){
       				int hex_count = htoi(line+1, 2);
       					if((int)strlen(line)-11<hex_count*2) {
       						PrintMessage1(strings[S_IhexShort],line);	//"Intel hex8 line too short:\r\n%s\r\n"
       				}
       				else{
       					input_address=(ext_addr<<16)+htoi(line+3,4);
       					sum=0;
       					for (i=1;i<=hex_count*2+9;i+=2) sum += htoi(line+i,2);
       					if ((sum & 0xff)!=0) {
       							PrintMessage1(strings[S_IhexChecksum],line);	//"Intel hex8 checksum error in line:\r\n%s\r\n"
       					}
       					else{
       						switch(htoi(line+7,2)){
       							case 0:		//Data record
       								if(input_address<0x1E000){		//Code
       									sizeM=input_address+hex_count;
       									if(sizeM>sizeW) sizeW=sizeM;
       									for (i=0;i<hex_count;i++){
       										buffer[input_address+i]=htoi(line+9+i*2,2);
       									}
       								}
       								else if(input_address>=0x1E000&&input_address<0x1F000){	//EEPROM
       									sizeM=(input_address-0x1E000+hex_count)/2;
       									if(sizeM>sizeEE) sizeEE=sizeM;
       									for (i=0;i<hex_count;i+=2){
       										bufferEE[(input_address-0x1E000)/2+i/2]=htoi(line+9+i*2,2);
       									}
       								}
       								break;
   *)
   memCODE := malloc(size);
   Move(buffer, memCODE, size);
   if size then
    // return value of PrintMessage() ignored
    PrintMessage(strings[S_CodeMem]);
   // return value of DisplayCODEAVR() ignored
   DisplayCODEAVR(size);
   // return value of PrintMessage() ignored
   PrintMessage('\r' + LineEnding + '');
  end
  else if devType = I2CEE or devType = SPIEE or devType = UWEE or devType = OWEE or devType = UNIOEE then
  begin
   if Pos(loadfile, loadfile) then
   begin
    f := freopen(loadfile, 'rb', f);
    if  not f then
     Exit(-1);
    Seek(f, 0L);
    sizeEE := FilePos(f);
    Seek(f, 0L);
    if sizeEE>0x1000000 then
     sizeEE := $1000000;
    if memEE then
     FreeMem(memEE);
    memEE := malloc(sizeEE);
    sizeEE := fread(memEE, 1, sizeEE, f);
   end
   else
   begin
    bufSize := $40000;
    FillChar(bufferEE, bufSize, $FF);
    (* TODO gtk2laz: complex for loop
      Source: /tmp/opgui-0.12.4/fileIO.c:390
      Original C:
        		for(;fgets(line,256,f);){
        			if(strlen(line)>9&&line[0]==':'){
        				int hex_count = htoi(line+1, 2);
        					if((int)strlen(line)-11<hex_count*2) {
        						PrintMessage1(strings[S_IhexShort],line);	//"Intel hex8 line too short:\r\n%s\r\n"
        				}
        				else{
        					input_address=(ext_addr<<16)+htoi(line+3,4);
        					sum=0;
        					for (i=1;i<=hex_count*2+9;i+=2) sum += htoi(line+i,2);
        					if ((sum & 0xff)!=0) {
        							PrintMessage1(strings[S_IhexChecksum],line);	//"Intel hex8 checksum error in line:\r\n%s\r\n"
        					}
        					else{
        						switch(htoi(line+7,2)){
        							case 0:		//Data record
        								if(input_address<0x1E000){		//Code
        									sizeM=input_address+hex_count;
        									if(sizeM>sizeW) sizeW=sizeM;
        									for (i=0;i<hex_count;i++){
        										buffer[input_address+i]=htoi(line+9+i*2,2);
        									}
        								}
        								else if(input_address>=0x1E000&&input_address<0x1F000){	//EEPROM
        									sizeM=(input_address-0x1E000+hex_count)/2;
        									if(sizeM>sizeEE) sizeEE=sizeM;
        									for (i=0;i<hex_count;i+=2){
        										bufferEE[(input_address-0x1E000)/2+i/2]=htoi(line+9+i*2,2);
        									}
        								}
        								break;
    *)
    memEE := malloc(sizeEE);
    Move(bufferEE, memEE, sizeEE);
    FreeMem(bufferEE);
   end;
   sum := 0;
   for i := 0 to (sizeEE) - 1 do
   begin
   end;
   // return value of PrintMessage1() ignored
   PrintMessage1('Checksum: 0x%X\r' + LineEnding + '', sum&0xFFFF);
   // return value of PrintMessage() ignored
   PrintMessage('\r' + LineEnding + '');
  end;
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
begin
  f := fopen(loadfile, 'r');
  if  not f then
   Exit;
  if devType = AVR then
  begin
   input_address := 0;
   ext_addr := 0;
   PrintMessage1('%s :\r' + LineEnding + '\r' + LineEnding + '', loadfile);
   FillChar(bufferEE, sizeof(bufferEE), $FF);
   (* TODO gtk2laz: complex for loop
     Source: /tmp/opgui-0.12.4/fileIO.c:758
     Original C:
       		for(;fgets(line,256,f);){
       			if(strlen(line)>9&&line[0]==':'){
       				int hex_count = htoi(line+1, 2);
       				if((int)strlen(line) - 11 < hex_count * 2) {
       					PrintMessage1(strings[S_IhexShort],line);	//"Intel hex8 line too short:\r\n%s\r\n"
       				}
       				else{
       					input_address=htoi(line+3,4);
       					int sum = 0;
       					for (i=1;i<=hex_count*2+9;i+=2)	sum+=htoi(line+i,2);
       					if ((sum & 0xff)!=0) {
       						PrintMessage1(strings[S_IhexChecksum],line);	//"Intel hex8 checksum error in line:\r\n%s\r\n"
       					}
       					else{
       						switch(htoi(line+7,2)){
       							case 0:		//Data record
       								if(ext_addr==0&&input_address<0x1000){	//EEPROM
       									for (i=0;i<hex_count;i++){
       										bufferEE[input_address+i]=htoi(line+9+i*2,2);
       									}
       									sizeEE=input_address+hex_count;
       								}
       								break;
       							case 4:		//extended linear address record
       								if(strlen(line)>14)	ext_addr=htoi(line+9,4);
       								break;
       							default:
       								break;
       						}
       					}
       				}
   *)
   memEE := malloc(sizeEE);
   Move(bufferEE, memEE, sizeEE);
   if sizeEE then
    DisplayEE();
   PrintMessage('\r' + LineEnding + '');
   CloseFile(f);
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
  tot: Telse;
  if(inst[i].retParams<0x100){ 					if(bufferI[r]==inst[i].code){ 						r++; 						fprintf(logfile," ->"); 						if(inst[i].retParams==0) fprintf(logfile," OK");	 						for(p=0;p<inst[i].retParams;p++){ 							if(p>15&&p%22==0) fprintf(logfile,"\n\t\t\t\t"); 							fprintf(logfile," %02X",bufferI[r++]); 						} 					} 					else fprintf(logfile," -> NAK"); 				} 				else{	 					if(bufferI[r]==inst[i].code){ 						fprintf(logfile," ->"); 						int N=bufferI[r+1]; 						int A=inst[i].retParams>>8; 						int x=inst[i].retParams&0xF; 						int bit=inst[i].retParams&0x10?1:0;	 						int tot; 						if(bit==0) tot=A+N*x; 						else tot=A+(((N*x-1)>>3)+1);  						if(N>0xF0) tot=A;	 						for(p=0;p<tot;p++){ 							r++; 							if(p>15&&p%22==0) fprintf(logfile,"\n\t\t\t\t"); 							fprintf(logfile," %02X",bufferI[r]); 						} 						r++; 					} 					else fprintf(logfile," -> NAK"); 				} 				fprintf(logfile,"\n"): Telse;
begin
  for u := 0,r=0 to (DIMBUF) - 1 do
  begin
   for i := 0 to (sizeof(inst)/sizeof(struct INSTRUCTIONS)) - 1 do
   begin
    if bufferU[u] = inst[i].code then
    begin
     fprintf(logfile, '%02X %s', bufferU[u], inst[i].name);
     if inst[i].params<0x100 then
     begin
      for p := 0 to (inst[i].params) - 1 do
      begin
       (* TODO gtk2laz: unrecognised statement
         Source: /tmp/opgui-0.12.4/fileIO.c:920
         Original C:
           
           //Parse input and output buffer and "decompile" instructions
           //Write to log file
           void WriteLogParsedIO()
           {
           	int i,u,r,p;
           	for(u=0,r=0;u<DIMBUF;u++){
           		for(i=0;i<sizeof(inst)/sizeof(struct INSTRUCTIONS);i++){
           			if(bufferU[u]==inst[i].code){
           				fprintf(logfile,"%02X %s",bufferU[u],inst[i].name);
           				if(inst[i].params<0x100){
           					for(p=0;p<inst[i].params;p++){
           						u++;
           						fprintf(logfile," %02X",bufferU[u]);
           					}
           				}
           				else{	//A+N*x
           					int N=bufferU[u+1];
           					int A=inst[i].params>>8;
           					int x=inst[i].params&0xF;
           					int bit=inst[i].params&0x10?1:0;	//bit multiplier
           					int tot;
           					if(bit==0) tot=A+N*x;
           					else tot=A+(((N*x-1)>>3)+1); //convert bit count to byte
           					for(p=0;p<tot;p++){
           						u++;
           						fprintf(logfile," %02X",bufferU[u]);
           					}
           				}
           				if(inst[i].retParams==-1) u=DIMBUF;	//stop parsing after FLUSH
           				else if(inst[i].retParams<0x100){
       *)
       fprintf(logfile, ' %02X', bufferU[u]);
      end;
     end
     else
     begin
      N := bufferU[u+1];
      A := inst[i].params shr 8;
      x := inst[i].params&0xF;
      bit := IfThen(inst[i].params&0x10, 1, 0);
      if bit = 0 then
       tot := A+N*x;
      tot := A+(((N*x-1) shr 3)+1);
      for p := 0 to (tot) - 1 do
      begin
       (* TODO gtk2laz: unrecognised statement
         Source: /tmp/opgui-0.12.4/fileIO.c:920
         Original C:
           
           //Parse input and output buffer and "decompile" instructions
           //Write to log file
           void WriteLogParsedIO()
           {
           	int i,u,r,p;
           	for(u=0,r=0;u<DIMBUF;u++){
           		for(i=0;i<sizeof(inst)/sizeof(struct INSTRUCTIONS);i++){
           			if(bufferU[u]==inst[i].code){
           				fprintf(logfile,"%02X %s",bufferU[u],inst[i].name);
           				if(inst[i].params<0x100){
           					for(p=0;p<inst[i].params;p++){
           						u++;
           						fprintf(logfile," %02X",bufferU[u]);
           					}
           				}
           				else{	//A+N*x
           					int N=bufferU[u+1];
           					int A=inst[i].params>>8;
           					int x=inst[i].params&0xF;
           					int bit=inst[i].params&0x10?1:0;	//bit multiplier
           					int tot;
           					if(bit==0) tot=A+N*x;
           					else tot=A+(((N*x-1)>>3)+1); //convert bit count to byte
           					for(p=0;p<tot;p++){
           						u++;
           						fprintf(logfile," %02X",bufferU[u]);
           					}
           				}
           				if(inst[i].retParams==-1) u=DIMBUF;	//stop parsing after FLUSH
           				else if(inst[i].retParams<0x100){
       *)
       fprintf(logfile, ' %02X', bufferU[u]);
      end;
     end;
     (* TODO gtk2laz: unrecognised statement
       Source: /tmp/opgui-0.12.4/fileIO.c:920
       Original C:
         
         //Parse input and output buffer and "decompile" instructions
         //Write to log file
         void WriteLogParsedIO()
         {
         	int i,u,r,p;
         	for(u=0,r=0;u<DIMBUF;u++){
         		for(i=0;i<sizeof(inst)/sizeof(struct INSTRUCTIONS);i++){
         			if(bufferU[u]==inst[i].code){
         				fprintf(logfile,"%02X %s",bufferU[u],inst[i].name);
         				if(inst[i].params<0x100){
         					for(p=0;p<inst[i].params;p++){
         						u++;
         						fprintf(logfile," %02X",bufferU[u]);
         					}
         				}
         				else{	//A+N*x
         					int N=bufferU[u+1];
         					int A=inst[i].params>>8;
         					int x=inst[i].params&0xF;
         					int bit=inst[i].params&0x10?1:0;	//bit multiplier
         					int tot;
         					if(bit==0) tot=A+N*x;
         					else tot=A+(((N*x-1)>>3)+1); //convert bit count to byte
         					for(p=0;p<tot;p++){
         						u++;
         						fprintf(logfile," %02X",bufferU[u]);
         					}
         				}
         				if(inst[i].retParams==-1) u=DIMBUF;	//stop parsing after FLUSH
         				else if(inst[i].retParams<0x100){
     *)
    end;
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
