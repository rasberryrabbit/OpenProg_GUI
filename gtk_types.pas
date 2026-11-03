unit gtk_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TGtkWidget = record
    (* empty struct *)
  end;
  TGtkWindow = record
    (* empty struct *)
  end;
  TGtkButton = record
    (* empty struct *)
  end;
  TGtkLabel = record
    (* empty struct *)
  end;
  TGtkEntry = record
    (* empty struct *)
  end;
  TGtkBox = record
    (* empty struct *)
  end;
  TGtkNotebook = record
    (* empty struct *)
  end;
  TGtkComboBox = record
    (* empty struct *)
  end;
  TGtkComboBoxText = record
    (* empty struct *)
  end;
  TGtkSpinButton = record
    (* empty struct *)
  end;
  TGtkTextView = record
    (* empty struct *)
  end;
  TGtkTextBuffer = record
    (* empty struct *)
  end;
  TGtkTextIter = record
    (* empty struct *)
  end;
  TGtkStatusbar = record
    (* empty struct *)
  end;
  TGtkTreeView = record
    (* empty struct *)
  end;
  TGtkTreeSelection = record
    (* empty struct *)
  end;
  TGtkListStore = record
    (* empty struct *)
  end;
  TGtkTreeStore = record
    (* empty struct *)
  end;
  TGtkTreeIter = record
    (* empty struct *)
  end;
  TGtkTreePath = record
    (* empty struct *)
  end;
  TGtkTreeModel = record
    (* empty struct *)
  end;
  TGtkCellRenderer = record
    (* empty struct *)
  end;
  TGtkCellRendererText = record
    (* empty struct *)
  end;
  TGtkCellRendererPixbuf = record
    (* empty struct *)
  end;
  TGtkTreeViewColumn = record
    (* empty struct *)
  end;
  TGtkFileChooser = record
    (* empty struct *)
  end;
  TGtkFileChooserDialog = record
    (* empty struct *)
  end;
  TGtkDialog = record
    (* empty struct *)
  end;
  TGtkMessageDialog = record
    (* empty struct *)
  end;
  TGtkScale = record
    (* empty struct *)
  end;
  TGtkHScale = record
    (* empty struct *)
  end;
  TGtkVScale = record
    (* empty struct *)
  end;
  TGtkScrollbar = record
    (* empty struct *)
  end;
  TGtkHScrollbar = record
    (* empty struct *)
  end;
  TGtkVScrollbar = record
    (* empty struct *)
  end;
  TGtkPaned = record
    (* empty struct *)
  end;
  TGtkHPaned = record
    (* empty struct *)
  end;
  TGtkVPaned = record
    (* empty struct *)
  end;
  TGtkSeparator = record
    (* empty struct *)
  end;
  TGtkFrame = record
    (* empty struct *)
  end;
  TGtkAspectFrame = record
    (* empty struct *)
  end;
  TGtkScrolledWindow = record
    (* empty struct *)
  end;
  TGtkDrawingArea = record
    (* empty struct *)
  end;
  TGtkToggleToolButton = record
    (* empty struct *)
  end;
  TGtkToggleButton = record
    (* empty struct *)
  end;
  TGtkCheckButton = record
    (* empty struct *)
  end;
  TGtkRadioButton = record
    (* empty struct *)
  end;
  TGtkToolButton = record
    (* empty struct *)
  end;
  TGtkToolbar = record
    (* empty struct *)
  end;
  TGtkMenuBar = record
    (* empty struct *)
  end;
  TGtkMenu = record
    (* empty struct *)
  end;
  TGtkMenuItem = record
    (* empty struct *)
  end;
  TGtkCheckMenuItem = record
    (* empty struct *)
  end;
  TGtkImage = record
    (* empty struct *)
  end;
  TGtkAdjustment = record
    (* empty struct *)
  end;
  TGtkBuilder = record
    (* empty struct *)
  end;
  TGdkPixbuf = record
    (* empty struct *)
  end;
  TGdkScreen = record
    (* empty struct *)
  end;
  TGdkEventButton = record
    (* empty struct *)
  end;
  TGdkEventKey = record
    (* empty struct *)
  end;
  TGdkEvent = record
    (* empty struct *)
  end;
  TGdkDrawable = record
    (* empty struct *)
  end;
  TGdkGC = record
    (* empty struct *)
  end;
  TGdkPixmap = record
    (* empty struct *)
  end;
  TGdkColor = record
    (* empty struct *)
  end;
  TGdkRectangle = record
    (* empty struct *)
  end;
  TGdkWindow = record
    (* empty struct *)
  end;
  TGdkCursor = record
    (* empty struct *)
  end;
  TGdkDevice = record
    (* empty struct *)
  end;
  TGdkDisplay = record
    (* empty struct *)
  end;
  TGtkCssProvider = record
    (* empty struct *)
  end;
  Tgboolean = Integer;
  Tgint = Integer;
  Tguint = Cardinal;
  Tglong = LongInt;
  Tgulong = Cardinal;
  Tgdouble = Double;
  Tgchar = Char;
  Tguchar = Byte;
  Tgpointer = ^Pointer;
  Tgconstpointer = ^Pointer;
  Tgsize = Cardinal;
  Tgssize = LongInt;
  Tguint32 = Cardinal;
  Tguint16 = Word;
  Tguint8 = Byte;
  Tgint32 = Integer;
  Tgint16 = SmallInt;
  Tgint8 = ShortInt;
  Tgint64 = Int64;
  Tguint64 = QWord;
  TGCallback = Integer;
  TGObject = ^Pointer;

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
