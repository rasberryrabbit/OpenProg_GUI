unit coff;

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
  mainform;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

// --- function declarations ---
function analyzeCOFF(filename: PChar; label: array[0..0x2200-1] of PChar; ulabel: array[0..0x400-1] of PChar; source_info: array[0..0x2200-1] of Tsrc_i; s_files_p: ^^Tsrcfile; data: array[0..0x2200-1] of Word; sym_p: ^^Tsymbol; nsym: ^Integer): Integer;
function scanSourceFile(s_files_p: ^Tsrcfile): ^TextFile;

implementation

function analyzeCOFF(filename: PChar; label: array[0..0x2200-1] of PChar; ulabel: array[0..0x400-1] of PChar; source_info: array[0..0x2200-1] of Tsrc_i; s_files_p: ^^Tsrcfile; data: array[0..0x2200-1] of Word; sym_p: ^^Tsymbol; nsym: ^Integer): Integer;
var
  i: Integer;
  j: Integer;
  k: Integer;
  sections: ^Tscnhdr_t;
  FileHeader: Tfilehdr_t;
  OptHeader: Topthdr_t;
  strsize: Integer;
  strN: Integer;
  strtable: PChar;
  strings: PChar;
  if(sections[i]._s._s_s._s_zeroes==0) name=&strtable[sections[i]._s._s_s._s_offset]: Telse;
  name: Telse;
  filemax: Integer;
  if(symbol._n._n_n._n_zeroes==0) name=&strtable[symbol._n._n_n._n_offset]: Telse;
  name: Telse;
begin
  FILE*f := fopen(filename, 'rb');
  if  not f then
   Exit(0);
  BlockRead(&FileHeader, sizeof(filehdr_t), 1);
  if FileHeader.f_opthdr = 18 then
  begin
   BlockRead(&OptHeader, 2, 1);
   BlockRead(&OptHeader+4, 16, 1);
  end;
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   BlockRead(&sections[i], 40, 1);
  end;
  strsize := 0;
  strN := 0;
  BlockRead(&strsize, 4, 1);
  strtable := malloc(strsize);
  strtable[0] := strtable[1]=strtable[2]=strtable[3]=0;
  BlockRead(&strtable[4], strsize-4, 1);
  for i := 4 to (strsize) - 1 do
  begin
  end;
  strings := malloc(strN*sizeof(char*));
  if strN then
   strings[0] := &strtable[4];
  j := 1;
  for i := 4 to (strsize and j<strN) - 1 do
  begin
   if strtable[i] = 0 then
   begin
    strings[j] := &strtable[i+1];
    (* TODO gtk2laz: unrecognised statement
      Source: /tmp/opgui-0.12.4/coff.c:1
      Original C:
        // COFF file parser
        // COFF file structure:
        // file header
        // optional header
        // sections(name, address, size, raw data pointer, reloc entry, ptr to first line, number of lines)
        // relocation entries
        // symbols (name, value, section, type, class) + optional info
        // lines (source file symbol, line number, address of code)
        // symbol table
        // string table
        
        #include <stdlib.h>
        #include <stdio.h>
        #include <string.h>
        #include "coff.h"
        
        // Analyze COFF file named filename, extract code labels in label[address], undefined labels in ulabel[address],
        // info about each symbol (name, source line, source file index) in source_info,
        // list of source files (index, name, file pointer) in s_files, raw data in data[0x2200]
        int analyzeCOFF(char *filename,char* label[LMAX],char* ulabel[ULMAX],struct src_i source_info[LMAX],struct srcfile **s_files_p,unsigned short data[0x2200],struct symbol **sym_p, int* nsym)
        {
        	int i,j,k;
        	FILE*f=fopen(filename,"rb");
        	if(!f) return 0;
        	scnhdr_t* sections;
        	filehdr_t FileHeader;
        	opthdr_t OptHeader;
        	fread((char* )&FileHeader,sizeof(filehdr_t),1,f); //file header
        /*	printf("File header:\nmagic %X, sections %d, time %d, symbol ptr %d, nsymbol %d, opt size %d, flags %X\n",\
        	FileHeader.f_magic,FileHeader.f_nscns,FileHeader.f_timdat,FileHeader.f_symptr,FileHeader.f_nsyms,FileHeader.f_opthdr,FileHeader.f_flags);*/
        	if(FileHeader.f_opthdr==18){	//optional header
    *)
   end;
  end;
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   if sections[i]._s._s_name[0] then
    name := sections[i]._s._s_name;
   name := null;
  end;
  for i := 0 to (LMAX) - 1 do
  begin
  end;
  for i := 0 to (ULMAX) - 1 do
  begin
  end;
  filemax := 0;
  *nsym := 0;
  if fseek(f, FileHeader.f_symptr, SEEK_SET) then
   // return value of printf() ignored
   printf('seek error' + LineEnding + '');
  for i := 0 to (FileHeader.f_nsyms) - 1 do
  begin
   j := fread(&symbol, 1, 14, f);
   j := fread(&symbol+16, 1, 6, f);
   if symbol._n._n_name[0] then
    name := symbol._n._n_name;
   name := null;
   if symbol.n_sclass = 6 and symbol.n_value<LMAX then
   begin
    if label[symbol.n_value] = 0 then
    begin
     label[symbol.n_value] := malloc(strlen(name)+1);
     // return value of strcpy() ignored
     strcpy(label[symbol.n_value], name);
    end
    else
    begin
     // return value of printf() ignored
     printf('conflicting labels at address %X: %s vs. %s' + LineEnding + '', symbol.n_value, label[symbol.n_value], name);
    end;
   end;
   (* TODO gtk2laz: for loop with non-standard form; rewritten as while
     Source: /tmp/opgui-0.12.4/coff.c:134
     Original C:
       		for(j=symbol.n_numaux;j;j--)fread(&symbol,20,1,f);
   *)
   // init: j=symbol.n_numaux
   while j do
   begin
    (* TODO gtk2laz: unrecognised statement
      Source: /tmp/opgui-0.12.4/coff.c:1
      Original C:
        // COFF file parser
        // COFF file structure:
        // file header
        // optional header
        // sections(name, address, size, raw data pointer, reloc entry, ptr to first line, number of lines)
        // relocation entries
        // symbols (name, value, section, type, class) + optional info
        // lines (source file symbol, line number, address of code)
        // symbol table
        // string table
        
        #include <stdlib.h>
        #include <stdio.h>
        #include <string.h>
        #include "coff.h"
        
        // Analyze COFF file named filename, extract code labels in label[address], undefined labels in ulabel[address],
        // info about each symbol (name, source line, source file index) in source_info,
        // list of source files (index, name, file pointer) in s_files, raw data in data[0x2200]
        int analyzeCOFF(char *filename,char* label[LMAX],char* ulabel[ULMAX],struct src_i source_info[LMAX],struct srcfile **s_files_p,unsigned short data[0x2200],struct symbol **sym_p, int* nsym)
        {
        	int i,j,k;
        	FILE*f=fopen(filename,"rb");
        	if(!f) return 0;
        	scnhdr_t* sections;
        	filehdr_t FileHeader;
        	opthdr_t OptHeader;
        	fread((char* )&FileHeader,sizeof(filehdr_t),1,f); //file header
        /*	printf("File header:\nmagic %X, sections %d, time %d, symbol ptr %d, nsymbol %d, opt size %d, flags %X\n",\
        	FileHeader.f_magic,FileHeader.f_nscns,FileHeader.f_timdat,FileHeader.f_symptr,FileHeader.f_nsyms,FileHeader.f_opthdr,FileHeader.f_flags);*/
        	if(FileHeader.f_opthdr==18){	//optional header
    *)
   end;
  end;
  for i := 0 to (LMAX) - 1 do
  begin
   source_info[i].label := 0;
   source_info[i].src_file := 0;
   source_info[i].src_line := 0;
  end;
  for i := 0 to ($2200) - 1 do
  begin
  end;
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   if sections[i].s_size>0 then
   begin
    if fseek(f, sections[i].s_scnptr, SEEK_SET) then
     // return value of printf() ignored
     printf('seek error' + LineEnding + '');
    raw := malloc(sections[i].s_size);
    BlockRead(raw, sections[i].s_size, 1);
    if (sections[i].s_paddr+sections[i].s_size/2)<0x2200 then
     Move(raw, &data[sections[i].s_paddr], sections[i].s_size);
    FreeMem(raw);
   end;
  end;
  FreeMem(strings);
  FreeMem(raw);
  Exit(1);
end;

function scanSourceFile(s_files_p: ^Tsrcfile): ^TextFile;
var
  f: ^TextFile;
  line: array[0..4096-1] of Char;
  p: LongInt;
  i: PChar;
begin
  f := fopen(.name, 'rb');
  .ptr := f;
  if  not f then
   Exit(f);
  .nlines := 1;
  p := FilePos(f);
  (* TODO gtk2laz: complex for loop
    Source: /tmp/opgui-0.12.4/coff.c:197
    Original C:
      	for(i=fgets(line,4096,f);i;){
      		(*s_files_p).lineptr=realloc((*s_files_p).lineptr,((*s_files_p).nlines+1)*sizeof(long int));
      		(*s_files_p).lineptr[(*s_files_p).nlines]=p;
      		//printf("nlines%d ptr%d %s",(*s_files_p).nlines,p,line);
      		(*s_files_p).nlines++;
      		p=ftell(f);
      		i=fgets(line,4096,f);
      	}
  *)
end;

end.
