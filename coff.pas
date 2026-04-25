unit coff;

{
  COFF file parser
  COFF file structure:
    file header
    optional header
    sections (name, address, size, raw data pointer, reloc entry, ptr to first line, number of lines)
    relocation entries
    symbols (name, value, section, type, class) + optional info
    lines (source file symbol, line number, address of code)
    symbol table
    string table
}

{$IFDEF FPC}
  {$MODE DELPHI}
  {$PACKENUM 1}
{$ENDIF}

interface

uses
  SysUtils, Classes;

const
  LMAX     = $2200;
  DATA_MAX = $2200;
  ULMAX    = $400;
  SYMNMLEN = 8;
  X_DIMNUM = 4;

// ---------------------------------------------------------------------------
// COFF on-disk structures  (all packed to match C layout)
// ---------------------------------------------------------------------------

type
  TFileHdr = packed record
    f_magic  : Word;
    f_nscns  : Word;
    f_timdat : LongWord;
    f_symptr : LongWord;
    f_nsyms  : LongWord;
    f_opthdr : Word;
    f_flags  : Word;
  end;

  TOptHdr = packed record
    magic          : Word;
    _pad           : Word;          // explicit padding so vstamp aligns to 4
    vstamp         : LongWord;
    proc_type      : LongWord;
    rom_width_bits : LongWord;
    ram_width_bits : LongWord;
  end;

  TScnHdrName = packed record
    case Byte of
      0: (_s_name   : array[0..7] of AnsiChar);
      1: (_s_zeroes : LongWord;
          _s_offset : LongWord);
  end;

  TScnHdr = packed record
    _s       : TScnHdrName;
    s_paddr  : LongWord;
    s_vaddr  : LongWord;
    s_size   : LongWord;
    s_scnptr : LongWord;
    s_relptr : LongWord;
    s_lnnoptr: LongWord;
    s_nreloc : Word;
    s_nlnno  : Word;
    s_flags  : LongWord;
  end;

  TReloc = packed record
    r_vaddr  : LongWord;
    r_symndx : LongWord;
    r_offset : SmallInt;
    r_type   : Word;
  end;

  TSymEntName = packed record
    case Byte of
      0: (_n_name   : array[0..SYMNMLEN-1] of AnsiChar);
      1: (_n_zeroes : LongWord;
          _n_offset : LongWord);
  end;

  TSymEnt = packed record
    _n       : TSymEntName;
    n_value  : LongWord;
    n_scnum  : SmallInt;
    n_type   : LongWord;
    n_sclass : ShortInt;
    n_numaux : Byte;
  end;

  TCoffLineno = packed record
    l_srcndx : LongWord;
    l_lnno   : Word;
    l_paddr  : LongWord;
    l_flags  : Word;
    l_fcnndx : LongWord;
  end;

  TAuxFile = packed record
    x_offset  : LongWord;
    x_incline : LongWord;
    x_flags   : Byte;
    _unused   : array[0..10] of Byte;
  end;

  TAuxScn = packed record
    x_scnlen  : LongWord;
    x_nreloc  : Word;
    x_nlinno  : Word;
    _unused   : array[0..11] of Byte;
  end;

  TAuxTag = packed record
    _unused  : array[0..5] of Byte;
    x_size   : Word;
    _unused2 : array[0..3] of Byte;
    x_endndx : LongWord;
    _unused3 : array[0..3] of Byte;
  end;

  TAuxEos = packed record
    x_tagndx : LongWord;
    _unused  : array[0..1] of Byte;
    x_size   : Word;
    _unused2 : array[0..11] of Byte;
  end;

  TAuxFcn = packed record
    x_tagndx  : LongWord;
    x_size    : LongWord;
    x_lnnoptr : LongWord;
    x_endndx  : LongWord;
    x_actscnum: SmallInt;
    _unused   : array[0..1] of Byte;
  end;

  TAuxFcnCalls = packed record
    x_calleendx    : LongWord;
    x_is_interrupt : LongWord;
    _unused        : array[0..11] of Byte;
  end;

  TAuxArr = packed record
    x_tagndx : LongWord;
    x_lnno   : Word;
    x_size   : Word;
    x_dimen  : array[0..X_DIMNUM-1] of Word;
    _unused  : array[0..3] of Byte;
  end;

  TAuxEobf = packed record
    _unused  : array[0..3] of Byte;
    x_lnno   : Word;
    _unused2 : array[0..13] of Byte;
  end;

  TAuxBobf = packed record
    _unused  : array[0..3] of Byte;
    x_lnno   : Word;
    _unused2 : array[0..5] of Byte;
    x_endndx : LongWord;
    _unused3 : array[0..3] of Byte;
  end;

  TAuxVar = packed record
    x_tagndx : LongWord;
    _unused  : array[0..1] of Byte;
    x_size   : Word;
    _unused2 : array[0..11] of Byte;
  end;

  TAuxField = packed record
    _unused : array[0..5] of Byte;
    x_size  : Word;
    _unused2: array[0..11] of Byte;
  end;

// ---------------------------------------------------------------------------
// High-level records used by the rest of the application
// ---------------------------------------------------------------------------

  TSrcInfo = record
    label_   : AnsiString;   // renamed from 'label' (reserved word)
    src_file : Integer;
    src_line : Integer;
  end;

  TSrcFile = record
    l_srcndx : LongWord;
    name     : AnsiString;
    ptr      : TFileStream;   // nil when not yet opened
    nlines   : Integer;
    lineptr  : array of Int64; // file-position for each line (1-based index)
  end;

  TSymbol = record
    name  : AnsiString;
    value : Integer;
  end;

// Array types
  TLabelArray   = array[0..LMAX-1]  of AnsiString;
  TULabelArray  = array[0..ULMAX-1] of AnsiString;
  TSrcInfoArray = array[0..LMAX-1]  of TSrcInfo;

// ---------------------------------------------------------------------------
// Public interface
// ---------------------------------------------------------------------------

{ Open and scan a source file, filling lineptr[] with seek positions. }
function ScanSourceFile(var SrcFile: TSrcFile): Boolean;

{
  Parse the COFF file 'Filename'.
  Outputs:
    Labels      – code labels indexed by address
    ULabels     – symbols in non-empty sections, indexed by address
    SourceInfo  – per-address source information
    SrcFiles    – dynamic array of source-file descriptors
    Data        – raw word data (0x2200 words)
    Symbols     – flat list of all class-7 symbols
}
function AnalyzeCOFF(
  const Filename  : string;
  var Labels      : TLabelArray;
  var ULabels     : TULabelArray;
  var SourceInfo  : TSrcInfoArray;
  var SrcFiles    : array of TSrcFile;
  var SrcFileCount: Integer;
  var Data        : array of Word;
  var Symbols     : array of TSymbol;
  var NSymbols    : Integer
): Boolean;

implementation

// ---------------------------------------------------------------------------

function ScanSourceFile(var SrcFile: TSrcFile): Boolean;
var
  F    : TFileStream;
  SR   : TStreamReader;
  Pos  : Int64;
begin
  Result := False;
  try
    F := TFileStream.Create(SrcFile.name, fmOpenRead or fmShareDenyNone);
  except
    SrcFile.ptr := nil;
    Exit;
  end;

  SrcFile.ptr    := F;
  SrcFile.nlines := 1;           // line numbers start at 1
  SetLength(SrcFile.lineptr, 2); // index 0 unused; index 1 = first line

  SR := TStreamReader.Create(F, TEncoding.Default, False, 4096);
  try
    SrcFile.lineptr[1] := F.Position;
    while not SR.EndOfStream do
    begin
      SR.ReadLine;
      Pos := F.Position;
      Inc(SrcFile.nlines);
      SetLength(SrcFile.lineptr, SrcFile.nlines + 1);
      SrcFile.lineptr[SrcFile.nlines] := Pos;
    end;
  finally
    SR.Free;
  end;
  Result := True;
end;

// ---------------------------------------------------------------------------

function AnalyzeCOFF(
  const Filename  : string;
  var Labels      : TLabelArray;
  var ULabels     : TULabelArray;
  var SourceInfo  : TSrcInfoArray;
  var SrcFiles    : array of TSrcFile;
  var SrcFileCount: Integer;
  var Data        : array of Word;
  var Symbols     : array of TSymbol;
  var NSymbols    : Integer
): Boolean;

  // Read a Pascal shortstring-style name from a syment / scnhdr name union.
  function ResolveName(const NameBytes: array of Byte;
                       Zeroes, Offset: LongWord;
                       const StrTable: TBytes): AnsiString;
  var
    I: Integer;
    S: AnsiString;
  begin
    // If the first byte is non-zero the name fits in 8 bytes
    if NameBytes[0] <> 0 then
    begin
      SetLength(S, SYMNMLEN);
      Move(NameBytes[0], S[1], SYMNMLEN);
      // strip trailing nulls
      I := SYMNMLEN;
      while (I > 0) and (S[I] = #0) do Dec(I);
      SetLength(S, I);
      Result := S;
    end
    else if Zeroes = 0 then
    begin
      // name is in the string table
      I := Offset;
      S := '';
      while (I < Length(StrTable)) and (StrTable[I] <> 0) do
      begin
        S := S + AnsiChar(StrTable[I]);
        Inc(I);
      end;
      Result := S;
    end
    else
      Result := '';
  end;

var
  F         : TFileStream;
  FileHdr   : TFileHdr;
  OptHdr    : TOptHdr;
  Sections  : array of TScnHdr;
  Symbol    : TSymEnt;
  Line      : TCoffLineno;
  AuxFile   : TAuxFile;
  AuxDummy  : array[0..19] of Byte;
  StrTable  : TBytes;
  StrSize   : LongWord;
  NameBytes : array[0..SYMNMLEN-1] of Byte;
  Name      : AnsiString;
  RawBuf    : TBytes;
  I, J, K   : Integer;
  FileMax   : Integer;
begin
  Result := False;

  try
    F := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
  except
    Exit;
  end;

  try
    // ----------------------------------------------------------------
    // File header
    // ----------------------------------------------------------------
    F.ReadBuffer(FileHdr, SizeOf(TFileHdr));

    // Optional header (18 bytes on-disk but struct is larger due to padding)
    if FileHdr.f_opthdr = 18 then
    begin
      F.ReadBuffer(OptHdr.magic,  2);
      F.ReadBuffer(OptHdr.vstamp, 16); // remaining 16 bytes
    end;

    // ----------------------------------------------------------------
    // Section headers
    // ----------------------------------------------------------------
    SetLength(Sections, FileHdr.f_nscns);
    for I := 0 to FileHdr.f_nscns - 1 do
      F.ReadBuffer(Sections[I], 40);

    // ----------------------------------------------------------------
    // String table  (located immediately after symbol table)
    // ----------------------------------------------------------------
    F.Seek(Int64(FileHdr.f_symptr) + Int64(FileHdr.f_nsyms) * 20, soBeginning);
    F.ReadBuffer(StrSize, 4);
    SetLength(StrTable, StrSize);
    StrTable[0] := 0; StrTable[1] := 0; StrTable[2] := 0; StrTable[3] := 0;
    if StrSize > 4 then
      F.ReadBuffer(StrTable[4], StrSize - 4);

    // ----------------------------------------------------------------
    // Initialise output arrays
    // ----------------------------------------------------------------
    for I := 0 to LMAX - 1 do
    begin
      Labels[I]           := '';
      SourceInfo[I].label_ := '';
      SourceInfo[I].src_file := 0;
      SourceInfo[I].src_line := 0;
    end;
    for I := 0 to ULMAX - 1 do
      ULabels[I] := '';

    for I := 0 to $21FF do
      Data[I] := $FFFF;

    FileMax  := 0;
    NSymbols := 0;

    // ----------------------------------------------------------------
    // Symbol table
    // ----------------------------------------------------------------
    F.Seek(FileHdr.f_symptr, soBeginning);

    I := 0;
    while I < Integer(FileHdr.f_nsyms) do
    begin
      // The on-disk symbol entry is 18 bytes but the C struct has a 2-byte
      // hole between the name union (14 bytes) and n_value (offset 16).
      // Read as the C code does: first 14 bytes, skip 2, then 6 bytes.
      F.ReadBuffer(Symbol, 14);
      F.Seek(2, soCurrent);
      F.ReadBuffer(PByte(@Symbol)[16], 6);

      // Resolve name
      Move(Symbol._n._n_name[0], NameBytes[0], SYMNMLEN);
      Name := ResolveName(NameBytes, Symbol._n._n_zeroes, Symbol._n._n_offset, StrTable);

      // n_sclass = 6  → code label
      if (Symbol.n_sclass = 6) and (Symbol.n_value < LMAX) then
      begin
        if Labels[Symbol.n_value] = '' then
          Labels[Symbol.n_value] := Name
        else
          WriteLn(Format('conflicting labels at address %X: %s vs. %s',
            [Symbol.n_value, Labels[Symbol.n_value], Name]));
      end;

      // n_sclass = 7  → symbol in a section
      if (Symbol.n_sclass = 7) and (Symbol.n_value < ULMAX)
        and (Symbol.n_scnum > 0)
        and (Sections[Symbol.n_scnum - 1].s_size > 0) then
      begin
        if ULabels[Symbol.n_value] = '' then
          ULabels[Symbol.n_value] := Name
        else
          WriteLn(Format('conflicting labels at address %X: %s vs. %s',
            [Symbol.n_value, ULabels[Symbol.n_value], Name]));
      end;

      if Symbol.n_sclass = 7 then
      begin
        Inc(NSymbols);
        SetLength(Symbols, NSymbols);
        Symbols[NSymbols - 1].name  := Name;
        Symbols[NSymbols - 1].value := Symbol.n_value;
      end;

      // n_sclass = 103  → C_FILE auxiliary record
      if Symbol.n_sclass = 103 then
      begin
        F.ReadBuffer(AuxFile, 20);
        Dec(Symbol.n_numaux);
        Inc(I);

        Inc(FileMax);
        SetLength(SrcFiles, FileMax);
        // Resolve the filename from the string table
        J := AuxFile.x_offset;
        Name := '';
        while (J < Integer(StrSize)) and (StrTable[J] <> 0) do
        begin
          Name := Name + AnsiChar(StrTable[J]);
          Inc(J);
        end;
        SrcFiles[FileMax - 1].name     := Name;
        SrcFiles[FileMax - 1].ptr      := nil;
        SrcFiles[FileMax - 1].l_srcndx := I - 1; // index of the .file symbol
        SrcFiles[FileMax - 1].nlines   := 0;
        SetLength(SrcFiles[FileMax - 1].lineptr, 0);
      end;

      // Skip any remaining auxiliary records
      for J := 1 to Symbol.n_numaux do
        F.ReadBuffer(AuxDummy, 20);

      Inc(I, Symbol.n_numaux + 1);
    end;

    SrcFileCount := FileMax;

    // ----------------------------------------------------------------
    // Line-number entries for all sections
    // ----------------------------------------------------------------
    for I := 0 to FileHdr.f_nscns - 1 do
    begin
      if Sections[I].s_lnnoptr = 0 then Continue;
      F.Seek(Sections[I].s_lnnoptr, soBeginning);

      for J := 0 to Integer(Sections[I].s_nlnno) - 1 do
      begin
        // On-disk: 4 + 2 + 4 + 2 + 4 = 16 bytes, but struct has padding
        F.ReadBuffer(Line.l_srcndx, 4);
        F.ReadBuffer(Line.l_lnno,   2);
        F.ReadBuffer(Line.l_paddr,  4);
        F.ReadBuffer(Line.l_flags,  2);
        F.ReadBuffer(Line.l_fcnndx, 4);

        if Line.l_paddr < DATA_MAX then
        begin
          SourceInfo[Line.l_paddr].label_ := '';
          SourceInfo[Line.l_paddr].src_file := -1;

          for K := 0 to FileMax - 1 do
          begin
            if SrcFiles[K].l_srcndx = Line.l_srcndx then
            begin
              SourceInfo[Line.l_paddr].src_file := K;
              if SrcFiles[K].ptr = nil then
                ScanSourceFile(SrcFiles[K]);
              Break;
            end;
          end;
          SourceInfo[Line.l_paddr].src_line := Line.l_lnno;
        end;
      end;
    end;

    // ----------------------------------------------------------------
    // Raw section data  → Data[]
    // ----------------------------------------------------------------
    for I := 0 to FileHdr.f_nscns - 1 do
    begin
      if Sections[I].s_size = 0 then Continue;
      F.Seek(Sections[I].s_scnptr, soBeginning);
      SetLength(RawBuf, Sections[I].s_size);
      F.ReadBuffer(RawBuf[0], Sections[I].s_size);

      if (Sections[I].s_paddr + Sections[I].s_size div 2) < $2200 then
        Move(RawBuf[0], Data[Sections[I].s_paddr], Sections[I].s_size);
    end;

    Result := True;

  finally
    F.Free;
  end;
end;

end.
