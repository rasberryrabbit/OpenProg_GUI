unit sys_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  Tfd_set = record
    fds_bits: array[0..8-1] of Cardinal;
  end;
  Tssize_t = LongInt;
  Tsize_t = Cardinal;
  Tpid_t = Integer;
  Tuid_t = Integer;
  Tgid_t = Integer;
  Tmode_t = Integer;
  Toff_t = LongInt;
  Ttime_t = LongInt;
  Tuintptr_t = Cardinal;
  Tintptr_t = LongInt;

var
  ioctl: TProcedure;
  FD_ZERO: TProcedure;
  FD_SET: TProcedure;
  FD_CLR: TProcedure;
  FD_ISSET: TProcedure;
  stat: TProcedure;
  fstat: TProcedure;
  ftime: TProcedure;

implementation

end.
