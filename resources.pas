unit resources;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Buttons, Spin, Menus, LCLType,
  mainform;

const
  G_HAS_CONSTRUCTORS = 1;
  G_MSVC_SYMBOL_PREFIX = '_';
  G_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA = 1;
  G_DEFINE_DESTRUCTOR_NEEDS_PRAGMA = 1;

type
  DWORD = Cardinal;
  WORD  = Word;
  BYTE  = Byte;

var
  resources_resource_data: Tstatic SECTION union;
  static_resource: Tstatic GStaticResource;
  GResource *resources_get_resource (void): TG_MODULE_EXPORT;
  _func(void): Tstatic void;

// --- function declarations ---
procedure _func(void: Tvoid); \
  extern int ( _array ## _func)(void);              \
  int _func ## _ructor(void);              \
  int _func ## _ructor();
procedure _func(void: Tvoid);


  fini(_func)

  static void _func(void);















G_DEFINE_CONSTRUCTOR(resourcesresource_ructor)



G_DEFINE_DESTRUCTOR(resourcesresource_destructor)





static void resourcesresource_ructor ();
procedure resourcesresource_destructor;

implementation

procedure _func(void: Tvoid); \
  extern int ( _array ## _func)(void);              \
  int _func ## _ructor(void);              \
  int _func ## _ructor();
var
  (_func): Tatexit;
  (NULL,  _array ## _func): Tg_slist_find;
begin
  Exit;
end;

procedure _func(void: Tvoid);


  fini(_func)

  static void _func(void);















G_DEFINE_CONSTRUCTOR(resourcesresource_ructor)



G_DEFINE_DESTRUCTOR(resourcesresource_destructor)





static void resourcesresource_ructor ();
var
  (&static_resource): Tg_static_resource_init;
begin
  // empty body
end;

procedure resourcesresource_destructor;
var
  (&static_resource): Tg_static_resource_fini;
begin
  // empty body
end;

end.
