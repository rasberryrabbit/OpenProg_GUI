unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  ComCtrls,
  Controls,
  Dialogs,
  ExtCtrls,
  Forms,
  Graphics,
  Menus,
  Spin,
  StdCtrls,
  SysUtils;

type
  TMainForm = class(TForm)
    Tpanel1: TPanel;
    StatusB: TStatusBar;
    Ttoolbar2: TToolBar;
    OpenT: TToolButton;
    SaveT: TToolButton;
    Ttoolbutton3: TToolButton;
    ReadT: TToolButton;
    WriteT: TToolButton;
    Ttoolbutton4: TToolButton;
    StopT: TToolButton;
    ConnectT: TToolButton;
    InfoT: TToolButton;
    Notebook: TPageControl;
    Tscrollbox5: TScrollBox;
    Data: TMemo;
    DeviceTab: TPanel;
    Tpanel6: TPanel;
    Tpanel7: TPanel;
    TypeL: TLabel;
    TypeC: TComboBox;
    Tpanel8: TPanel;
    DevSrcL: TLabel;
    DevSrcE: TEdit;
    Tscrollbox9: TScrollBox;
    DevTree: TListView;
    Tgroupbox10: TGroupBox;
    Tpanel11: TPanel;
    DevInfo: TLabel;
    EeRw: TCheckBox;
    PicOpt: TPanel;
    Tpanel12: TPanel;
    Tpanel13: TPanel;
    ResRead: TCheckBox;
    ProgId: TCheckBox;
    ProgCal12: TCheckBox;
    UseSaflock: TCheckBox;
    OscOpt: TGroupBox;
    Tpanel14: TPanel;
    Osccal: TRadioButton;
    Bkosccal: TRadioButton;
    Filecal: TRadioButton;
    OsccalL: TLabel;
    CwOpt: TGroupBox;
    Tpanel15: TPanel;
    ForceCw: TCheckBox;
    Tpanel16: TPanel;
    Cw1Opt: TPanel;
    Tlabel17: TLabel;
    Cw1: TEdit;
    Cw2Opt: TPanel;
    Tlabel18: TLabel;
    Cw2: TEdit;
    Cw3Opt: TPanel;
    Tlabel19: TLabel;
    Cw3: TEdit;
    Cw4Opt: TPanel;
    Tlabel20: TLabel;
    Cw4: TEdit;
    Tpanel21: TPanel;
    Cw5Opt: TPanel;
    Tlabel22: TLabel;
    Cw5: TEdit;
    Cw6Opt: TPanel;
    Tlabel23: TLabel;
    Cw6: TEdit;
    Cw7Opt: TPanel;
    Tlabel24: TLabel;
    Cw7: TEdit;
    Cw8Opt: TPanel;
    Tlabel25: TLabel;
    Cw8: TEdit;
    Tlabel26: TLabel;
    IcdOpt: TGroupBox;
    Tpanel27: TPanel;
    Icd: TCheckBox;
    Tpanel28: TPanel;
    IcdAddrL: TLabel;
    IcdAddr: TEdit;
    Tlabel29: TLabel;
    AvrOpt: TPanel;
    Tpanel30: TPanel;
    Fusel: TEdit;
    FuselC: TCheckBox;
    Tpanel31: TPanel;
    Fuseh: TEdit;
    FusehC: TCheckBox;
    Tpanel32: TPanel;
    Fusex: TEdit;
    FusexC: TCheckBox;
    Tpanel33: TPanel;
    Fuselck: TEdit;
    FuselckC: TCheckBox;
    FuselW3k: TButton;
    DeviceName: TLabel;
    OptionsTab: TPanel;
    Connect: TButton;
    Tpanel34: TPanel;
    Tpanel35: TPanel;
    Tlabel36: TLabel;
    Vid: TEdit;
    Tpanel37: TPanel;
    Tlabel38: TLabel;
    Pid: TEdit;
    Test: TButton;
    Log: TCheckBox;
    W3vcheck: TCheckBox;
    S1: TCheckBox;
    Tpanel39: TPanel;
    MaxerrL: TLabel;
    Maxerr: TEdit;
    I2cspiTab: TPanel;
    Tgroupbox40: TGroupBox;
    Tpanel41: TPanel;
    I2c8bit: TRadioButton;
    I2c16bit: TRadioButton;
    Tbevel42: TBevel;
    Spi00: TRadioButton;
    Spi01: TRadioButton;
    Spi10: TRadioButton;
    Spi11: TRadioButton;
    I2cmode: TLabel;
    Tpanel43: TPanel;
    Tpanel44: TPanel;
    NbyteL: TLabel;
    NbyteS: TSpinEdit;
    Tpanel45: TPanel;
    SpeedL: TLabel;
    SpeedC: TComboBox;
    Tpanel46: TPanel;
    SendB: TButton;
    ReceiveB: TButton;
    DatasendL: TLabel;
    Datasend: TEdit;
    DatatrL: TLabel;
    Tgroupbox47: TGroupBox;
    Datatr: TMemo;
    Tlabel48: TLabel;
    IcdTab: TPanel;
    Ttoolbar50: TToolBar;
    IcdRun: TToolButton;
    IcdHalt: TToolButton;
    IcdStep: TToolButton;
    IcdStepover: TToolButton;
    Ttoolbutton51: TToolButton;
    IcdStop: TToolButton;
    Ttoolbutton52: TToolButton;
    IcdRefresh: TToolButton;
    Ttoolbutton53: TToolButton;
    LoadcoffB: TToolButton;
    Ttoolbutton54: TToolButton;
    Ttoolbutton55: TToolButton;
    IcdCmdE: TEdit;
    Ttoolbutton56: TToolButton;
    IcdHelp: TToolButton;
    Tpanel57: TPanel;
    Tpanel58: TPanel;
    IcdSourceL: TLabel;
    Tscrollbox59: TScrollBox;
    IcdSource: TMemo;
    Tpanel60: TPanel;
    Tpanel61: TPanel;
    IcdStatL: TLabel;
    Tmainmenu62: TMainMenu;
    OptionsM: TMenuItem;
    Tpopupmenu63: TPopupMenu;
    PcountM: TMenuItem;
    StatusM: TMenuItem;
    Bank0M: TMenuItem;
    Bank1M: TMenuItem;
    Bank2M: TMenuItem;
    Bank3M: TMenuItem;
    EeM: TMenuItem;
    Tscrollbox64: TScrollBox;
    IcdStatus: TMemo;
    IoTab: TPanel;
    Tgroupbox66: TGroupBox;
    Tpanel67: TPanel;
    Ioen: TCheckBox;
    Tpanel68: TPanel;
    Tpanel69: TPanel;
    Tpanel70: TPanel;
    Tlabel71: TLabel;
    Rb70: TRadioButton;
    Rb71: TRadioButton;
    Rb7I: TRadioButton;
    Rb7L: TLabel;
    Tpanel72: TPanel;
    Tlabel73: TLabel;
    Rb60: TRadioButton;
    Rb61: TRadioButton;
    Rb6I: TRadioButton;
    Rb6L: TLabel;
    Tpanel74: TPanel;
    Tlabel75: TLabel;
    Rb50: TRadioButton;
    Rb51: TRadioButton;
    Rb5I: TRadioButton;
    Rb5L: TLabel;
    Tpanel76: TPanel;
    Tlabel77: TLabel;
    Rb40: TRadioButton;
    Rb41: TRadioButton;
    Rb4I: TRadioButton;
    Rb4L: TLabel;
    Tpanel78: TPanel;
    Tlabel79: TLabel;
    Rb30: TRadioButton;
    Rb31: TRadioButton;
    Rb3I: TRadioButton;
    Rb3L: TLabel;
    Tpanel80: TPanel;
    Tlabel81: TLabel;
    Rb20: TRadioButton;
    Rb21: TRadioButton;
    Rb2I: TRadioButton;
    Rb2L: TLabel;
    Tpanel82: TPanel;
    Tlabel83: TLabel;
    Rb10: TRadioButton;
    Rb11: TRadioButton;
    Rb1I: TRadioButton;
    Rb1L: TLabel;
    Tpanel84: TPanel;
    Tlabel85: TLabel;
    Rb00: TRadioButton;
    Rb01: TRadioButton;
    Rb0I: TRadioButton;
    Rb0L: TLabel;
    Tpanel86: TPanel;
    Tpanel87: TPanel;
    Tlabel88: TLabel;
    Rc70: TRadioButton;
    Rc71: TRadioButton;
    Rc7I: TRadioButton;
    Rc7L: TLabel;
    Tpanel89: TPanel;
    Tlabel90: TLabel;
    Rc60: TRadioButton;
    Rc61: TRadioButton;
    Rc6I: TRadioButton;
    Rc6L: TLabel;
    Tpanel91: TPanel;
    Tlabel92: TLabel;
    Ra50: TRadioButton;
    Ra51: TRadioButton;
    Ra5I: TRadioButton;
    Ra5L: TLabel;
    Tpanel93: TPanel;
    Tlabel94: TLabel;
    Ra40: TRadioButton;
    Ra41: TRadioButton;
    Ra4I: TRadioButton;
    Ra4L: TLabel;
    Tpanel95: TPanel;
    Tlabel96: TLabel;
    Ra30: TRadioButton;
    Ra31: TRadioButton;
    Ra3I: TRadioButton;
    Ra3L: TLabel;
    Tlabel97: TLabel;
    Tpanel98: TPanel;
    Vdduen: TCheckBox;
    Vppuen: TCheckBox;
    Dcdcen: TCheckBox;
    DcdcS: TTrackBar;
    Tgroupbox99: TGroupBox;
    Tpanel100: TPanel;
    Tpanel101: TPanel;
    Tpanel102: TPanel;
    CmdsendL: TLabel;
    Cmdsend: TEdit;
    Tpanel103: TPanel;
    CmdtrL: TLabel;
    Tgroupbox104: TGroupBox;
    Cmdtr: TMemo;
    Tlabel105: TLabel;
    CmdtrB: TButton;
    CmdL: TLabel;
    UtilityTab: TPanel;
    Tgroupbox107: TGroupBox;
    Tpanel108: TPanel;
    Tpanel109: TPanel;
    Tlabel110: TLabel;
    Hexin: TEdit;
    Dataout: TEdit;
    Tlabel111: TLabel;
    Tgroupbox112: TGroupBox;
    Tpanel113: TPanel;
    Tpanel114: TPanel;
    Tlabel115: TLabel;
    Addrin: TEdit;
    Tpanel116: TPanel;
    Tlabel117: TLabel;
    Datain: TEdit;
    Tpanel118: TPanel;
    Tlabel119: TLabel;
    Hexout: TEdit;
    Hexsave: TButton;
    Tlabel120: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.Xclose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // TODO: port original C handler 'Xclose'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.gtk_widget_destroy(Sender: TObject);
begin
  // TODO: port original C handler 'gtk_widget_destroy'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.onDevSel_Changed(Sender: TObject; User: boolean);
begin
  // TODO: port original C handler 'onDevSel_Changed'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.Fopen(Sender: TObject);
begin
  // TODO: port original C handler 'Fopen'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.Fsave(Sender: TObject);
begin
  // TODO: port original C handler 'Fsave'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.DevRead(Sender: TObject);
begin
  // TODO: port original C handler 'DevRead'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.DevWrite(Sender: TObject);
begin
  // TODO: port original C handler 'DevWrite'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.Stop(Sender: TObject);
begin
  // TODO: port original C handler 'Stop'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.Connect(Sender: TObject);
begin
  // TODO: port original C handler 'Connect'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.info(Sender: TObject);
begin
  // TODO: port original C handler 'info'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.FilterDevType(Sender: TObject; User: boolean);
begin
  // TODO: port original C handler 'FilterDevType'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.WriteATfuseLowLF(Sender: TObject);
begin
  // TODO: port original C handler 'WriteATfuseLowLF'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.TestHw(Sender: TObject);
begin
  // TODO: port original C handler 'TestHw'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.I2cspiS(Sender: TObject);
begin
  // TODO: port original C handler 'I2cspiS'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.I2cspiR(Sender: TObject);
begin
  // TODO: port original C handler 'I2cspiR'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.loadCoff(Sender: TObject);
begin
  // TODO: port original C handler 'loadCoff'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdRun(Sender: TObject);
begin
  // TODO: port original C handler 'icdRun'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdHalt(Sender: TObject);
begin
  // TODO: port original C handler 'icdHalt'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdStep(Sender: TObject);
begin
  // TODO: port original C handler 'icdStep'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdStepOver(Sender: TObject);
begin
  // TODO: port original C handler 'icdStepOver'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdStop(Sender: TObject);
begin
  // TODO: port original C handler 'icdStop'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdRefresh(Sender: TObject);
begin
  // TODO: port original C handler 'icdRefresh'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdCommand_key_event(Sender: TObject);
begin
  // TODO: port original C handler 'icdCommand_key_event'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.ICDHelp(Sender: TObject);
begin
  // TODO: port original C handler 'ICDHelp'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.source_mouse_event(Sender: TObject);
begin
  // TODO: port original C handler 'source_mouse_event'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.icdStatus_mouse_event(Sender: TObject);
begin
  // TODO: port original C handler 'icdStatus_mouse_event'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.IOactive(Sender: TObject);
begin
  // TODO: port original C handler 'IOactive'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.IOchanged(Sender: TObject);
begin
  // TODO: port original C handler 'IOchanged'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.CommandIO(Sender: TObject);
begin
  // TODO: port original C handler 'CommandIO'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.VPPVDDactive(Sender: TObject);
begin
  // TODO: port original C handler 'VPPVDDactive'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.DCDCactive(Sender: TObject);
begin
  // TODO: port original C handler 'DCDCactive'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.HexSave(Sender: TObject);
begin
  // TODO: port original C handler 'HexSave'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.HexConvert(Sender: TObject; User: boolean);
begin
  // TODO: port original C handler 'HexConvert'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.DataToHexConvert(Sender: TObject; User: boolean);
begin
  // TODO: port original C handler 'DataToHexConvert'. Body left empty by gtk2laz converter.
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Initialize form - hook up runtime state here.
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

end.
