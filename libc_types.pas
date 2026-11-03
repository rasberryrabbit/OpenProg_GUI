unit libc_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  Tint8_t = Integer;
  Tint16_t = Integer;
  Tint32_t = Integer;
  Tint64_t = Int64;
  Tuint8_t = Cardinal;
  Tuint16_t = Cardinal;
  Tuint32_t = Cardinal;
  Tuint64_t = QWord;
  Tuintptr_t = Cardinal;
  Tintptr_t = LongInt;
  TFILE = record
    (* empty struct *)
  end;
  Tsize_t = Cardinal;
  Ttime_t = LongInt;
  Twchar_t = Integer;
  Twint_t = Cardinal;

var
  isdigit: TProcedure;
  isalpha: TProcedure;
  isalnum: TProcedure;
  isspace: TProcedure;
  isupper: TProcedure;
  islower: TProcedure;
  tolower: TProcedure;
  toupper: TProcedure;
  errno: Integer;
  open: TProcedure;
  getopt_long: TProcedure;
  getopt: TProcedure;
  sqrt: TProcedure;
  pow: TProcedure;
  floor: TProcedure;
  ceil: TProcedure;
  round: TProcedure;
  printf: TProcedure;
  fprintf: TProcedure;
  sprintf: TProcedure;
  snprintf: TProcedure;
  fopen: TProcedure;
  fclose: TProcedure;
  fread: TProcedure;
  fwrite: TProcedure;
  fseek: TProcedure;
  ftell: TProcedure;
  feof: TProcedure;
  fgets: TProcedure;
  fputs: TProcedure;
  fgetc: TProcedure;
  fputc: TProcedure;
  malloc: TProcedure;
  calloc: TProcedure;
  realloc: TProcedure;
  free: TProcedure;
  exit: TProcedure;
  atoi: TProcedure;
  strtol: TProcedure;
  atof: TProcedure;
  strcpy: TProcedure;
  strncpy: TProcedure;
  strcat: TProcedure;
  strncat: TProcedure;
  strcmp: TProcedure;
  strncmp: TProcedure;
  strcasecmp: TProcedure;
  strncasecmp: TProcedure;
  strlen: TProcedure;
  strchr: TProcedure;
  strrchr: TProcedure;
  strstr: TProcedure;
  strdup: TProcedure;
  memcpy: TProcedure;
  memmove: TProcedure;
  memset: TProcedure;
  memcmp: TProcedure;
  time: TProcedure;
  localtime: TProcedure;
  clock_gettime: TProcedure;
  gettimeofday: TProcedure;
  close: TProcedure;
  read: TProcedure;
  write: TProcedure;
  access: TProcedure;
  unlink: TProcedure;
  sleep: TProcedure;
  usleep: TProcedure;

implementation

end.
