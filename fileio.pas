unit fileio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform,
  common,
  progp12,
  progp16,
  progp18,
  progp24,
  progavr,
  devicerw;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

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
  word: Integer;

// --- function declarations ---
function htoi(hex: PChar; length: Integer): Cardinal;
procedure SaveEE(devType: Integer; savefile: PChar);
function Load(devType: Integer; loadfile: PChar): Integer;
procedure LoadEE(devType: Integer; loadfile: PChar);
procedure OpenLogFile;
procedure CloseLogFile;
procedure WriteLogParsedIO;
procedure WriteLogIO;

implementation

function htoi(hex: PChar; length: Integer): Cardinal;
var
  i: Integer;
  = 0: Tunsigned int v;
  (i = 0; i < length; i++) { 		v <<= 4; 		if (hex[i] >= '0' && hex[i] <= '9') v += hex[i] - '0'; 		else if (hex[i] >= 'a' && hex[i] <= 'f') v += hex[i] - 'a' + 10; 		else if (hex[i] >= 'A' && hex[i] <= 'F') v += hex[i] - 'A' + 10; 		else PrintMessage1(strings[S_Inohex],hex);	 	} 	return v: Tfor;
begin
  // empty body
end;

procedure SaveEE(devType: Integer; savefile: PChar);
var
  f: ^TextFile;
  if(devType==AVR){ 		char str[512],str1[512]=""; 		int i,base; 		fprintf(f,":020000040000FA\n");			 		int sum=0,count=0,s; 		for(i=0,count=sum=0;i<sizeEE;i++){ 			sum+=memEE[i]; 			sprintf(str,"%02X",memEE[i]&0xff); 			strcat(str1,str); 			count++; 			if(count==16||i==sizeEE-1){ 				base=i-count+1; 				for(s=i;s>i-count&&memEE[s]>=0xff;s--){	 					sum-=memEE[s]&0xff; 					str1[strlen(str1)-2]=0; 				} 				count-=i-s; 				sum+=count+(base&0xff)+((base>>8)&0xff); 				if(count){ 					fprintf(f,":%02X%04X00%s%02X\n",count,base&0xFFFF,str1,(-sum)&0xff); 				} 				str1[0]=0; 				count=sum=0; 			} 		} 		fprintf(f,":00000001FF\n"); 	} 	if(f) fclose(f): Telse;
begin
  f := fopen(savefile, 'w');
  if  not f then
   Exit;
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
   (* TODO gtk2laz: complex for loop: for(;fgets(line,256,f);){ 			if(strlen(line)>9&&line[0]==':'){ 				int hex_count = htoi(line+1, 2); 					if((int)strlen(line)-11<hex_count*2) { 						PrintMessage1(strings[S_IhexShort],line);	 				} 	 *)
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
   (* TODO gtk2laz: complex for loop: for(;fgets(line,256,f);){ 			if(strlen(line)>9&&line[0]==':'){ 				int hex_count = htoi(line+1, 2); 				if((int)strlen(line) - 11 < hex_count * 2) { 					PrintMessage1(strings[S_IhexShort],line);	 			 *)
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
   (* TODO gtk2laz: complex for loop: for(;fgets(line,256,f);){ 			if(strlen(line)>9&&line[0]==':'){ 				int hex_count = htoi(line+1, 2); 				if((int)strlen(line) - 11 < hex_count * 2) { 						PrintMessage1(strings[S_IhexShort],line);	 		 *)
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
   (* TODO gtk2laz: complex for loop: for(;fgets(line,256,f);){ 			if(strlen(line)>9&&line[0]==':'){ 				int hex_count = htoi(line+1, 2); 				if((int)strlen(line) - 11 < hex_count * 2) { 					PrintMessage1(strings[S_IhexShort],line);	 			 *)
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
    (* TODO gtk2laz: complex for loop: for(;fgets(line,256,f);){ 				if(strlen(line)>9&&line[0]==':'){ 					int hex_count = htoi(line+1, 2); 					if((int)strlen(line) - 11 < hex_count * 2) { 							PrintMessage1(strings[S_IhexShort],line); *)
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

procedure LoadEE(devType: Integer; loadfile: PChar);
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
   (* TODO gtk2laz: complex for loop: for(;fgets(line,256,f);){ 			if(strlen(line)>9&&line[0]==':'){ 				int hex_count = htoi(line+1, 2); 				if((int)strlen(line) - 11 < hex_count * 2) { 					PrintMessage1(strings[S_IhexShort],line);	 			 *)
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
  timeinfo: ^Tstruct tm;
  rawtime: Ttime_t;
  = localtime( &rawtime ): Ttimeinfo;
begin
  logfile := fopen(LogFileName, 'w');
  if  not logfile then
   Exit;
  fprintf(logfile, _APPNAME " version %s (%s)\n", VERSION, SYSNAME);
  fprintf(logfile, 'Firmware version %d.%d.%d' + LineEnding + '', FWVersion shr 16, (FWVersion shr 8)&0xFF, FWVersion&0xFF);
  time(&rawtime);
  fprintf(logfile, '%s' + LineEnding + '', asctime(timeinfo));
end;

procedure CloseLogFile;
var
  // (no local variables detected)
begin
  if logfile then
   CloseFile(logfile);
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
       (* TODO gtk2laz: unrecognised statement: u++ *)
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
       (* TODO gtk2laz: unrecognised statement: u++ *)
       fprintf(logfile, ' %02X', bufferU[u]);
      end;
     end;
     (* TODO gtk2laz: unrecognised statement: break *)
    end;
   end;
  end;
end;

procedure WriteLogIO;
var
  i: Integer;
begin
  fprintf(logfile, 'bufferU=[');
  for i := 0 to (DIMBUF) - 1 do
  begin
   if i%32 = 0 then
    fprintf(logfile, '' + LineEnding + '');
   fprintf(logfile, '%02X ', bufferU[i]);
  end;
  fprintf(logfile, 'bufferI=[');
  for i := 0 to (DIMBUF) - 1 do
  begin
   if i%32 = 0 then
    fprintf(logfile, '' + LineEnding + '');
   fprintf(logfile, '%02X ', bufferI[i]);
  end;
  WriteLogParsedIO();
end;

end.
