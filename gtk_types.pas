unit gtk_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TGtkWidget = record
    (* empty struct *)
  end;
  PGtkWidget = ^TGtkWidget;
  TGtkWindow = record
    (* empty struct *)
  end;
  PGtkWindow = ^TGtkWindow;
  TGtkButton = record
    (* empty struct *)
  end;
  PGtkButton = ^TGtkButton;
  TGtkLabel = record
    (* empty struct *)
  end;
  PGtkLabel = ^TGtkLabel;
  TGtkEntry = record
    (* empty struct *)
  end;
  PGtkEntry = ^TGtkEntry;
  TGtkBox = record
    (* empty struct *)
  end;
  PGtkBox = ^TGtkBox;
  TGtkNotebook = record
    (* empty struct *)
  end;
  PGtkNotebook = ^TGtkNotebook;
  TGtkComboBox = record
    (* empty struct *)
  end;
  PGtkComboBox = ^TGtkComboBox;
  TGtkComboBoxText = record
    (* empty struct *)
  end;
  PGtkComboBoxText = ^TGtkComboBoxText;
  TGtkSpinButton = record
    (* empty struct *)
  end;
  PGtkSpinButton = ^TGtkSpinButton;
  TGtkTextView = record
    (* empty struct *)
  end;
  PGtkTextView = ^TGtkTextView;
  TGtkTextBuffer = record
    (* empty struct *)
  end;
  PGtkTextBuffer = ^TGtkTextBuffer;
  TGtkTextIter = record
    (* empty struct *)
  end;
  PGtkTextIter = ^TGtkTextIter;
  TGtkStatusbar = record
    (* empty struct *)
  end;
  PGtkStatusbar = ^TGtkStatusbar;
  TGtkTreeView = record
    (* empty struct *)
  end;
  PGtkTreeView = ^TGtkTreeView;
  TGtkTreeSelection = record
    (* empty struct *)
  end;
  PGtkTreeSelection = ^TGtkTreeSelection;
  TGtkListStore = record
    (* empty struct *)
  end;
  PGtkListStore = ^TGtkListStore;
  TGtkTreeStore = record
    (* empty struct *)
  end;
  PGtkTreeStore = ^TGtkTreeStore;
  TGtkTreeIter = record
    (* empty struct *)
  end;
  PGtkTreeIter = ^TGtkTreeIter;
  TGtkTreePath = record
    (* empty struct *)
  end;
  PGtkTreePath = ^TGtkTreePath;
  TGtkTreeModel = record
    (* empty struct *)
  end;
  PGtkTreeModel = ^TGtkTreeModel;
  TGtkCellRenderer = record
    (* empty struct *)
  end;
  PGtkCellRenderer = ^TGtkCellRenderer;
  TGtkCellRendererText = record
    (* empty struct *)
  end;
  PGtkCellRendererText = ^TGtkCellRendererText;
  TGtkCellRendererPixbuf = record
    (* empty struct *)
  end;
  PGtkCellRendererPixbuf = ^TGtkCellRendererPixbuf;
  TGtkTreeViewColumn = record
    (* empty struct *)
  end;
  PGtkTreeViewColumn = ^TGtkTreeViewColumn;
  TGtkFileChooser = record
    (* empty struct *)
  end;
  PGtkFileChooser = ^TGtkFileChooser;
  TGtkFileChooserDialog = record
    (* empty struct *)
  end;
  PGtkFileChooserDialog = ^TGtkFileChooserDialog;
  TGtkDialog = record
    (* empty struct *)
  end;
  PGtkDialog = ^TGtkDialog;
  TGtkMessageDialog = record
    (* empty struct *)
  end;
  PGtkMessageDialog = ^TGtkMessageDialog;
  TGtkScale = record
    (* empty struct *)
  end;
  PGtkScale = ^TGtkScale;
  TGtkHScale = record
    (* empty struct *)
  end;
  PGtkHScale = ^TGtkHScale;
  TGtkVScale = record
    (* empty struct *)
  end;
  PGtkVScale = ^TGtkVScale;
  TGtkScrollbar = record
    (* empty struct *)
  end;
  PGtkScrollbar = ^TGtkScrollbar;
  TGtkHScrollbar = record
    (* empty struct *)
  end;
  PGtkHScrollbar = ^TGtkHScrollbar;
  TGtkVScrollbar = record
    (* empty struct *)
  end;
  PGtkVScrollbar = ^TGtkVScrollbar;
  TGtkPaned = record
    (* empty struct *)
  end;
  PGtkPaned = ^TGtkPaned;
  TGtkHPaned = record
    (* empty struct *)
  end;
  PGtkHPaned = ^TGtkHPaned;
  TGtkVPaned = record
    (* empty struct *)
  end;
  PGtkVPaned = ^TGtkVPaned;
  TGtkSeparator = record
    (* empty struct *)
  end;
  PGtkSeparator = ^TGtkSeparator;
  TGtkFrame = record
    (* empty struct *)
  end;
  PGtkFrame = ^TGtkFrame;
  TGtkAspectFrame = record
    (* empty struct *)
  end;
  PGtkAspectFrame = ^TGtkAspectFrame;
  TGtkScrolledWindow = record
    (* empty struct *)
  end;
  PGtkScrolledWindow = ^TGtkScrolledWindow;
  TGtkDrawingArea = record
    (* empty struct *)
  end;
  PGtkDrawingArea = ^TGtkDrawingArea;
  TGtkToggleToolButton = record
    (* empty struct *)
  end;
  PGtkToggleToolButton = ^TGtkToggleToolButton;
  TGtkToggleButton = record
    (* empty struct *)
  end;
  PGtkToggleButton = ^TGtkToggleButton;
  TGtkCheckButton = record
    (* empty struct *)
  end;
  PGtkCheckButton = ^TGtkCheckButton;
  TGtkRadioButton = record
    (* empty struct *)
  end;
  PGtkRadioButton = ^TGtkRadioButton;
  TGtkToolButton = record
    (* empty struct *)
  end;
  PGtkToolButton = ^TGtkToolButton;
  TGtkToolbar = record
    (* empty struct *)
  end;
  PGtkToolbar = ^TGtkToolbar;
  TGtkMenuBar = record
    (* empty struct *)
  end;
  PGtkMenuBar = ^TGtkMenuBar;
  TGtkMenu = record
    (* empty struct *)
  end;
  PGtkMenu = ^TGtkMenu;
  TGtkMenuItem = record
    (* empty struct *)
  end;
  PGtkMenuItem = ^TGtkMenuItem;
  TGtkCheckMenuItem = record
    (* empty struct *)
  end;
  PGtkCheckMenuItem = ^TGtkCheckMenuItem;
  TGtkImage = record
    (* empty struct *)
  end;
  PGtkImage = ^TGtkImage;
  TGtkAdjustment = record
    (* empty struct *)
  end;
  PGtkAdjustment = ^TGtkAdjustment;
  TGtkBuilder = record
    (* empty struct *)
  end;
  PGtkBuilder = ^TGtkBuilder;
  TGdkPixbuf = record
    (* empty struct *)
  end;
  PGdkPixbuf = ^TGdkPixbuf;
  TGdkScreen = record
    (* empty struct *)
  end;
  PGdkScreen = ^TGdkScreen;
  TGdkEventButton = record
    (* empty struct *)
  end;
  PGdkEventButton = ^TGdkEventButton;
  TGdkEventKey = record
    (* empty struct *)
  end;
  PGdkEventKey = ^TGdkEventKey;
  TGdkEvent = record
    (* empty struct *)
  end;
  PGdkEvent = ^TGdkEvent;
  TGdkDrawable = record
    (* empty struct *)
  end;
  PGdkDrawable = ^TGdkDrawable;
  TGdkGC = record
    (* empty struct *)
  end;
  PGdkGC = ^TGdkGC;
  TGdkPixmap = record
    (* empty struct *)
  end;
  PGdkPixmap = ^TGdkPixmap;
  TGdkColor = record
    (* empty struct *)
  end;
  PGdkColor = ^TGdkColor;
  TGdkRectangle = record
    (* empty struct *)
  end;
  PGdkRectangle = ^TGdkRectangle;
  TGdkWindow = record
    (* empty struct *)
  end;
  PGdkWindow = ^TGdkWindow;
  TGdkCursor = record
    (* empty struct *)
  end;
  PGdkCursor = ^TGdkCursor;
  TGdkDevice = record
    (* empty struct *)
  end;
  PGdkDevice = ^TGdkDevice;
  TGdkDisplay = record
    (* empty struct *)
  end;
  PGdkDisplay = ^TGdkDisplay;
  TGtkCssProvider = record
    (* empty struct *)
  end;
  PGtkCssProvider = ^TGtkCssProvider;
  Tgboolean = Integer;
  Tgint = Integer;
  Tguint = Cardinal;
  Tglong = LongInt;
  Tgulong = Cardinal;
  Tgdouble = Double;
  Tgchar = Char;
  Tguchar = Byte;
  Tgpointer = Pointer;
  Tgconstpointer = Pointer;
  Tgsize = Cardinal;
  Tgssize = LongInt;
  Tguint32 = Cardinal;
  Tguint16 = Word;
  Tguint8 = Byte;
  Tgint32 = Integer;
  Tgint16 = SmallInt;
  Tgint8 = ShortInt;
  Tgint64 = LongInt;
  Tguint64 = Cardinal;
  TGCallback = Integer;
  TGObject = Pointer;
  TGResource = record
    (* empty struct *)
  end;
  PGResource = ^TGResource;
  TGStaticResource = record
    (* empty struct *)
  end;
  PGStaticResource = ^TGStaticResource;

var
  gtk_button_new: TProcedure;
  gtk_button_new_with_label: TProcedure;
  gtk_button_set_label: TProcedure;
  gtk_button_get_label: TProcedure;
  gtk_label_new: TProcedure;
  gtk_label_set_text: TProcedure;
  gtk_label_set_markup: TProcedure;
  gtk_label_get_text: TProcedure;
  gtk_entry_new: TProcedure;
  gtk_entry_get_text: TProcedure;
  gtk_entry_set_text: TProcedure;
  gtk_entry_set_max_length: TProcedure;
  gtk_widget_show: TProcedure;
  gtk_widget_show_all: TProcedure;
  gtk_widget_hide: TProcedure;
  gtk_widget_set_sensitive: TProcedure;
  gtk_widget_set_visible: TProcedure;
  gtk_widget_destroy: TProcedure;
  gtk_widget_grab_focus: TProcedure;
  gtk_widget_queue_draw: TProcedure;
  gtk_widget_set_tooltip_text: TProcedure;
  gtk_main: TProcedure;
  gtk_main_quit: TProcedure;
  gtk_events_pending: TProcedure;
  gtk_main_iteration: TProcedure;
  gtk_main_iteration_do: TProcedure;
  gtk_init: TProcedure;
  gtk_statusbar_push: TProcedure;
  gtk_statusbar_pop: TProcedure;
  gtk_statusbar_remove_all: TProcedure;
  gtk_spin_button_get_value: TProcedure;
  gtk_spin_button_get_value_as_int: TProcedure;
  gtk_spin_button_set_value: TProcedure;
  gtk_spin_button_set_range: TProcedure;
  gtk_spin_button_set_increments: TProcedure;
  gtk_toggle_button_get_active: TProcedure;
  gtk_toggle_button_set_active: TProcedure;
  gtk_toggle_tool_button_get_active: TProcedure;
  gtk_toggle_tool_button_set_active: TProcedure;
  gtk_combo_box_get_active: TProcedure;
  gtk_combo_box_set_active: TProcedure;
  gtk_combo_box_text_get_active_text: TProcedure;
  gtk_combo_box_text_append: TProcedure;
  gtk_combo_box_text_remove: TProcedure;
  gtk_combo_box_text_remove_all: TProcedure;
  gtk_text_view_get_buffer: TProcedure;
  gtk_text_buffer_set_text: TProcedure;
  gtk_text_buffer_get_text: TProcedure;
  gtk_text_buffer_get_start_iter: TProcedure;
  gtk_text_buffer_get_end_iter: TProcedure;
  gtk_text_buffer_insert: TProcedure;
  gtk_text_buffer_delete: TProcedure;
  gtk_text_buffer_get_line_count: TProcedure;
  gtk_text_view_scroll_to_iter: TProcedure;
  gtk_builder_new: TProcedure;
  gtk_builder_new_from_file: TProcedure;
  gtk_builder_new_from_resource: TProcedure;
  gtk_builder_get_object: TProcedure;
  gtk_builder_connect_signals: TProcedure;
  gtk_window_set_title: TProcedure;
  gtk_window_set_default_size: TProcedure;
  gtk_window_set_modal: TProcedure;
  gtk_window_close: TProcedure;
  gtk_window_present: TProcedure;
  gtk_window_resize: TProcedure;
  g_signal_connect: TProcedure;
  g_signal_connect_swapped: TProcedure;
  g_signal_handlers_disconnect_by_func: TProcedure;
  g_object_unref: TProcedure;
  g_object_get_data: TProcedure;
  g_object_set_data: TProcedure;
  g_timeout_add: TProcedure;
  g_idle_add: TProcedure;
  gdk_pixbuf_new_from_resource: TProcedure;
  gtk_css_provider_new: TProcedure;
  gtk_css_provider_load_from_resource: TProcedure;
  gtk_style_context_add_provider_for_screen: TProcedure;
  gdk_screen_get_default: TProcedure;
  gtk_tree_view_get_selection: TProcedure;
  gtk_tree_selection_get_selected: TProcedure;
  gtk_tree_selection_select_iter: TProcedure;
  gtk_tree_selection_unselect_all: TProcedure;
  gtk_tree_selection_set_mode: TProcedure;
  gtk_tree_view_insert_column_with_attributes: TProcedure;
  gtk_notebook_get_current_page: TProcedure;
  gtk_notebook_set_current_page: TProcedure;
  gtk_notebook_append_page: TProcedure;
  gtk_notebook_remove_page: TProcedure;
  gtk_range_get_value: TProcedure;
  gtk_range_set_value: TProcedure;
  gtk_progress_bar_set_fraction: TProcedure;
  gtk_progress_bar_pulse: TProcedure;
  gtk_window_set_icon: TProcedure;

implementation

end.
