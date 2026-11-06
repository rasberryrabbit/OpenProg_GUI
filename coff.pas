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
  glib_types,
  gtk_types,
  libc_types,
  sys_types,
  mainform;

const
  NL = #10;

const
  LMAX = $2200;
  DATA_MAX = $2200;
  ULMAX = $400;
  SYMNMLEN = 8;
  X_DIMNUM = 4;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;
  Tfilehdr_t = record
    f_magic: Word;
    f_nscns: Word;
    f_timdat: DWORD;
    f_symptr: DWORD;
    f_nsyms: DWORD;
    f_opthdr: Word;
    f_flags: Word;
  end;
  PTfilehdr_t = ^Tfilehdr_t;
  Topthdr_t = record
    magic: Word;
    vstamp: DWORD;
    proc_type: DWORD;
    rom_width_bits: DWORD;
    ram_width_bits: DWORD;
  end;
  PTopthdr_t = ^Topthdr_t;
  Tscnhdr_t = record
    s_paddr: DWORD;
    s_vaddr: DWORD;
    s_size: DWORD;
    s_scnptr: DWORD;
    s_relptr: DWORD;
    s_lnnoptr: DWORD;
    s_nreloc: Word;
    s_nlnno: Word;
    s_flags: DWORD;
  end;
  PTscnhdr_t = ^Tscnhdr_t;
  Treloc_t = record
    r_vaddr: DWORD;
    r_symndx: DWORD;
    r_offset: SmallInt;
    r_type: Word;
  end;
  PTreloc_t = ^Treloc_t;
  Tsyment_t = record
    n_value: DWORD;
    n_scnum: SmallInt;
    n_type: DWORD;
    n_sclass: Char;
    n_numaux: Byte;
  end;
  PTsyment_t = ^Tsyment_t;
  Tcoff_lineno_t = record
    l_srcndx: DWORD;
    l_lnno: Word;
    l_paddr: DWORD;
    l_flags: Word;
    l_fcnndx: DWORD;
  end;
  PTcoff_lineno_t = ^Tcoff_lineno_t;
  Taux_file_t = record
    x_offset: DWORD;
    x_incline: DWORD;
    x_flags: Byte;
    _unused: array[0..11-1] of Char;
  end;
  PTaux_file_t = ^Taux_file_t;
  Taux_scn_t = record
    x_scnlen: DWORD;
    x_nreloc: Word;
    x_nlinno: Word;
    _unused: array[0..12-1] of Char;
  end;
  PTaux_scn_t = ^Taux_scn_t;
  Taux_tag_t = record
    _unused: array[0..6-1] of Char;
    x_size: Word;
    _unused2: array[0..4-1] of Char;
    x_endndx: DWORD;
    _unused3: array[0..4-1] of Char;
  end;
  PTaux_tag_t = ^Taux_tag_t;
  Taux_eos_t = record
    x_tagndx: DWORD;
    _unused: array[0..2-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_eos_t = ^Taux_eos_t;
  Taux_fcn_t = record
    x_tagndx: DWORD;
    x_size: DWORD;
    x_lnnoptr: DWORD;
    x_endndx: DWORD;
    x_actscnum: SmallInt;
    _unused: array[0..2-1] of Char;
  end;
  PTaux_fcn_t = ^Taux_fcn_t;
  Taux_fcn_calls_t = record
    x_calleendx: DWORD;
    x_is_interrupt: DWORD;
    _unused: array[0..12-1] of Char;
  end;
  PTaux_fcn_calls_t = ^Taux_fcn_calls_t;
  Taux_arr_t = record
    x_tagndx: DWORD;
    x_lnno: Word;
    x_size: Word;
    x_dimen: array[0..X_DIMNUM-1] of Word;
    _unused: array[0..4-1] of Char;
  end;
  PTaux_arr_t = ^Taux_arr_t;
  Taux_eobf_t = record
    _unused: array[0..4-1] of Char;
    x_lnno: Word;
    _unused2: array[0..14-1] of Char;
  end;
  PTaux_eobf_t = ^Taux_eobf_t;
  Taux_bobf_t = record
    _unused: array[0..4-1] of Char;
    x_lnno: Word;
    _unused2: array[0..6-1] of Char;
    x_endndx: DWORD;
    _unused3: array[0..4-1] of Char;
  end;
  PTaux_bobf_t = ^Taux_bobf_t;
  Taux_var_t = record
    x_tagndx: DWORD;
    _unused: array[0..2-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_var_t = ^Taux_var_t;
  Taux_field_t = record
    _unused: array[0..6-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_field_t = ^Taux_field_t;
  Tsrc_i = record
    label_: PChar;
    src_file: Integer;
    src_line: Integer;
  end;
  PTsrc_i = ^Tsrc_i;
  Tsrcfile = record
    l_srcndx: DWORD;
    name_: PChar;
    ptr: ^TextFile;
    nlines: Integer;
  end;
  PTsrcfile = ^Tsrcfile;
  Tsymbol = record
    name_: PChar;
    value: Integer;
  end;
  PTsymbol = ^Tsymbol;

type
  Tfilehdr_t = record
    f_magic: Word;
    f_nscns: Word;
    f_timdat: Cardinal;
    f_symptr: Cardinal;
    f_nsyms: Cardinal;
    f_opthdr: Word;
    f_flags: Word;
  end;
  PTfilehdr_t = ^Tfilehdr_t;
  Topthdr_t = record
    magic: Word;
    vstamp: Cardinal;
    proc_type: Cardinal;
    rom_width_bits: Cardinal;
    ram_width_bits: Cardinal;
  end;
  PTopthdr_t = ^Topthdr_t;
  Tscnhdr_t = record
    _s: TUnionRecord;
    s_paddr: Cardinal;
    s_vaddr: Cardinal;
    s_size: Cardinal;
    s_scnptr: Cardinal;
    s_relptr: Cardinal;
    s_lnnoptr: Cardinal;
    s_nreloc: Word;
    s_nlnno: Word;
    s_flags: Cardinal;
  end;
  PTscnhdr_t = ^Tscnhdr_t;
  Treloc_t = record
    r_vaddr: Cardinal;
    r_symndx: Cardinal;
    r_offset: SmallInt;
    r_type: Word;
  end;
  PTreloc_t = ^Treloc_t;
  Tsyment_t = record
    _n: TUnionRecord;
    n_value: Cardinal;
    n_scnum: SmallInt;
    n_type: Cardinal;
    n_sclass: Char;
    n_numaux: Byte;
  end;
  PTsyment_t = ^Tsyment_t;
  Tcoff_lineno_t = record
    l_srcndx: Cardinal;
    l_lnno: Word;
    l_paddr: Cardinal;
    l_flags: Word;
    l_fcnndx: Cardinal;
  end;
  PTcoff_lineno_t = ^Tcoff_lineno_t;
  Taux_file_t = record
    x_offset: Cardinal;
    x_incline: Cardinal;
    x_flags: Byte;
    _unused: array[0..11-1] of Char;
  end;
  PTaux_file_t = ^Taux_file_t;
  Taux_scn_t = record
    x_scnlen: Cardinal;
    x_nreloc: Word;
    x_nlinno: Word;
    _unused: array[0..12-1] of Char;
  end;
  PTaux_scn_t = ^Taux_scn_t;
  Taux_tag_t = record
    _unused: array[0..6-1] of Char;
    x_size: Word;
    _unused2: array[0..4-1] of Char;
    x_endndx: Cardinal;
    _unused3: array[0..4-1] of Char;
  end;
  PTaux_tag_t = ^Taux_tag_t;
  Taux_eos_t = record
    x_tagndx: Cardinal;
    _unused: array[0..2-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_eos_t = ^Taux_eos_t;
  Taux_fcn_t = record
    x_tagndx: Cardinal;
    x_size: Cardinal;
    x_lnnoptr: Cardinal;
    x_endndx: Cardinal;
    x_actscnum: SmallInt;
    _unused: array[0..2-1] of Char;
  end;
  PTaux_fcn_t = ^Taux_fcn_t;
  Taux_fcn_calls_t = record
    x_calleendx: Cardinal;
    x_is_interrupt: Cardinal;
    _unused: array[0..12-1] of Char;
  end;
  PTaux_fcn_calls_t = ^Taux_fcn_calls_t;
  Taux_arr_t = record
    x_tagndx: Cardinal;
    x_lnno: Word;
    x_size: Word;
    x_dimen: array[0..4-1] of Word;
    _unused: array[0..4-1] of Char;
  end;
  PTaux_arr_t = ^Taux_arr_t;
  Taux_eobf_t = record
    _unused: array[0..4-1] of Char;
    x_lnno: Word;
    _unused2: array[0..14-1] of Char;
  end;
  PTaux_eobf_t = ^Taux_eobf_t;
  Taux_bobf_t = record
    _unused: array[0..4-1] of Char;
    x_lnno: Word;
    _unused2: array[0..6-1] of Char;
    x_endndx: Cardinal;
    _unused3: array[0..4-1] of Char;
  end;
  PTaux_bobf_t = ^Taux_bobf_t;
  Taux_var_t = record
    x_tagndx: Cardinal;
    _unused: array[0..2-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_var_t = ^Taux_var_t;
  Taux_field_t = record
    _unused: array[0..6-1] of Char;
    x_size: Word;
    _unused2: array[0..12-1] of Char;
  end;
  PTaux_field_t = ^Taux_field_t;

// --- function declarations ---
function scanSourceFile(s_files_p: ^Tsrcfile): ^TextFile;
function analyzeCOFF(filename: PChar; label_: array[0..0x2200-1] of PChar; ulabel: array[0..0x400-1] of PChar; source_info: array[0..0x2200-1] of Tsrc_i; s_files_p: ^^Tsrcfile; data: array[0..0x2200-1] of Word; sym_p: ^^Tsymbol; nsym: ^Integer): Integer;
function analyzeCOFF(filename: PChar; label_: array[0..0x2200-1] of PChar; ulabel: array[0..0x400-1] of PChar; source_info: array[0..0x2200-1] of Tsrc_i; s_files_p: ^^Tsrcfile; data: array[0..0x2200-1] of Word; sym_p: ^^Tsymbol; nsym: ^Integer): Integer;
function scanSourceFile(s_files_p: ^Tsrcfile): ^TextFile;

implementation

function analyzeCOFF(filename: PChar; label_: array[0..0x2200-1] of PChar; ulabel: array[0..0x400-1] of PChar; source_info: array[0..0x2200-1] of Tsrc_i; s_files_p: ^^Tsrcfile; data: array[0..0x2200-1] of Word; sym_p: ^^Tsymbol; nsym: ^Integer): Integer;
var
  i: Integer;
  j: Integer;
  k: Integer;
  f: ^TextFile;
  sections: ^Tscnhdr_t;
  FileHeader: Tfilehdr_t;
  OptHeader: Topthdr_t;
  strsize: Integer;
  strN: Integer;
  strtable: PChar;
  strings: PChar;
  name_: PChar;
  null: array of Char;
  symbol: Tsyment_t;
  filemax: Integer;
  aux: Taux_file_t;
  line: Tcoff_lineno;
  raw: PByte;
begin
  f := fopen(filename, 'rb');
  if not (f) then
   Exit(0);
  fread(@FileHeader, SizeOf(filehdr_t), 1, f);
  if FileHeader.f_opthdr = 18 then
  begin
   fread(@OptHeader, 2, 1, f);
   fread(@OptHeader + 4, 16, 1, f);
  end;
  sections := malloc(SizeOf(scnhdr_t) * FileHeader.f_nscns);
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   fread(@(sections[i]), 40, 1, f);
  end;
  if fseek(f, FileHeader.f_symptr + FileHeader.f_nsyms * 20, SEEK_SET) then
   printf('seek error' + NL + '');
  strsize := 0;
  strN := 0;
  fread(@strsize, 4, 1, f);
  strtable := malloc(strsize);
  strtable[3] := 0; strtable[2] := 0; strtable[1] := 0; strtable[0] := 0;
  fread(@(strtable[4]), strsize - 4, 1, f);
  for i := 4 to (strsize) - 1 do
  begin
   if strtable[i] = 0 then
    Inc(strN);
  end;
  strings := malloc(strN * SizeOf(char *));
  if strN then
   strings[0] := @(strtable[4]);
  j := 1;
  i := 4;
  while (i < strsize) and (j < strN) do
  begin
   if strtable[i] = 0 then
   begin
    strings[j] := @(strtable[i + 1]);
    Inc(j);
   end;
   Inc(i);
  end;
  null := '';
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   if sections[i]._s._s_name[0] then
    name_ := sections[i]._s._s_name
   else
    if sections[i]._s._s_s._s_zeroes = 0 then
     name_ := @(strtable[sections[i]._s._s_s._s_offset])
    else
     name_ := null;
  end;
  for i := 0 to ($2200) - 1 do
  begin
   label_[i] := 0;
  end;
  for i := 0 to ($400) - 1 do
  begin
   ulabel[i] := 0;
  end;
  filemax := 0;
  nsym^ := 0;
  if fseek(f, FileHeader.f_symptr, SEEK_SET) then
   printf('seek error' + NL + '');
  for i := 0 to (FileHeader.f_nsyms) - 1 do
  begin
   j := fread(@symbol, 1, 14, f);
   j := fread(@symbol + 16, 1, 6, f);
   if symbol._n._n_name[0] then
    name_ := symbol._n._n_name
   else
    if symbol._n._n_n._n_zeroes = 0 then
     name_ := @(strtable[symbol._n._n_n._n_offset])
    else
     name_ := null;
   if (symbol.n_sclass = 6) and (symbol.n_value < $2200) then
   begin
    if label_[symbol.n_value] = 0 then
    begin
     label_[symbol.n_value] := malloc(strlen(name_) + 1);
     strcpy(label_[symbol.n_value], name_);
    end
    else
    begin
     printf('conflicting labels at address %X: %s vs. %s' + NL + '', symbol.n_value, label_[symbol.n_value], name_);
    end;
   end;
   if (symbol.n_sclass = 7) and (symbol.n_value < $400) and (symbol.n_scnum > 0) and (sections[symbol.n_scnum - 1].s_size > 0) then
   begin
    if ulabel[symbol.n_value] = 0 then
    begin
     ulabel[symbol.n_value] := malloc(strlen(name_) + 1);
     strcpy(ulabel[symbol.n_value], name_);
    end
    else
    begin
     printf('conflicting labels at address %X: %s vs. %s' + NL + '', symbol.n_value, ulabel[symbol.n_value], name_);
    end;
   end;
   if symbol.n_sclass = 7 then
   begin
    Inc(nsym^);
    sym_p^ := realloc(sym_p^, nsym^ * SizeOf(struct symbol));
    sym_p^[nsym^ - 1].name_ := strdup(name_);
    sym_p^[nsym^ - 1].value := symbol.n_value;
   end;
   if symbol.n_sclass = 103 then
   begin
    fread(@aux, 20, 1, f);
    Dec(symbol.n_numaux);
    Inc(filemax);
    s_files_p^ := realloc(s_files_p^, filemax * SizeOf(struct srcfile));
    s_files_p^[filemax - 1].name_ := strdup(@(strtable[aux.x_offset]));
    s_files_p^[filemax - 1].ptr := 0;
    s_files_p^[filemax - 1].l_srcndx := i;
    s_files_p^[filemax - 1].nlines := 0;
    s_files_p^[filemax - 1].lineptr := nil;
    Inc(i);
   end;
   i := i + symbol.n_numaux;
   j := symbol.n_numaux;
   while j do
   begin
    fread(@symbol, 20, 1, f);
    Dec(j);
   end;
  end;
  for i := 0 to ($2200) - 1 do
  begin
   source_info[i].label_ := 0;
   source_info[i].src_file := 0;
   source_info[i].src_line := 0;
  end;
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   if fseek(f, sections[i].s_lnnoptr, SEEK_SET) then
    printf('seek error' + NL + '');
   for j := 0 to (sections[i].s_nlnno) - 1 do
   begin
    fread(@line, 6, 1, f);
    fread(@line + 8, 6, 1, f);
    fread(@line + 16, 4, 1, f);
    if line.l_paddr < $2200 then
    begin
     source_info[line.l_paddr].label_ := 0;
     for k := 0 to (filemax) - 1 do
     begin
      if s_files_p^[k].l_srcndx = line.l_srcndx then
      begin
       source_info[line.l_paddr].src_file := k;
       if s_files_p^[k].ptr = 0 then
       begin
        scanSourceFile(@(s_files_p^[k]));
       end;
       k := filemax + 10;
      end;
     end;
     if k = filemax then
      source_info[line.l_paddr].src_file := -1;
     source_info[line.l_paddr].src_line := line.l_lnno;
    end;
   end;
  end;
  for i := 0 to ($2200) - 1 do
  begin
   data[i] := $FFFF;
  end;
  for i := 0 to (FileHeader.f_nscns) - 1 do
  begin
   if sections[i].s_size > 0 then
   begin
    if fseek(f, sections[i].s_scnptr, SEEK_SET) then
     printf('seek error' + NL + '');
    raw := malloc(sections[i].s_size);
    fread(raw, sections[i].s_size, 1, f);
    if sections[i].s_paddr + sections[i].s_size div 2 < $2200 then
     memcpy(@(data[sections[i].s_paddr]), raw, sections[i].s_size);
    free(raw);
   end;
  end;
  free(strtable);
  free(strings);
  free(raw);
  Exit(1);
end;

function scanSourceFile(s_files_p: ^Tsrcfile): ^TextFile;
var
  f: ^TextFile;
  line: array[0..4096-1] of Char;
  p: LongInt;
  i: PChar;
begin
  f := fopen(s_files_p^.name_, 'rb');
  s_files_p^.ptr := f;
  if not (f) then
   Exit(f);
  s_files_p^.nlines := 1;
  p := ftell(f);
  i := fgets(line, 4096, f);
  while i do
  begin
   s_files_p^.lineptr := realloc(s_files_p^.lineptr, (s_files_p^.nlines + 1) * SizeOf(long int));
   s_files_p^.lineptr[s_files_p^.nlines] := p;
   Inc(s_files_p^.nlines);
   p := ftell(f);
   i := fgets(line, 4096, f);
  end;
  Exit(f);
end;

end.
