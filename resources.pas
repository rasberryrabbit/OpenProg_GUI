unit resources;

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
  GResource__resources_get_resource__void_: TG_MODULE_EXPORT;
  _func_void_: Tstatic void;

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
  // (no local variables detected)
begin
  atexit(_func);
  g_slist_find(nil, _array ## _func);
  Exit;
end;

procedure _func(void: Tvoid);


  fini(_func)

  static void _func(void);















G_DEFINE_CONSTRUCTOR(resourcesresource_ructor)



G_DEFINE_DESTRUCTOR(resourcesresource_destructor)





static void resourcesresource_ructor ();
var
  // (no local variables detected)
begin
  g_static_resource_init(@( static_resource ));
end;

procedure resourcesresource_destructor;
var
  // (no local variables detected)
begin
  g_static_resource_fini(@( static_resource ));
end;

end.
