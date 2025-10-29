using Gtk;
using GLib;
using Gdk;
using Gee;
//using folderloader.vala;

// Grid 表示クラス
public class MainWindow : Gtk.Window {
    private string folder_name;
    private string[] names = {};
    private Gtk.Box content_box;
    private Gtk.Button toggle_button;
    private Gtk.Button folder_button;
    private bool showing_grid = true;
    private Gtk.Widget? current_view = null;
    private FolderLoader folder_loader;
    private int thumb_width = 290;

    public MainWindow(string start_folder) {
        Object();
        set_default_size(1200, 800);

        this.folder_name = start_folder;

        var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        add(vbox);

        var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        vbox.pack_start(hbox, false, false, 6);

        toggle_button = new Gtk.Button.with_label("Switch to Flow");
        toggle_button.clicked.connect(() => {
            showing_grid = !showing_grid;
            if (showing_grid) toggle_button.set_label("Switch to Flow"); else toggle_button.set_label("Switch to Grid");
            if (current_view != null) {
                try { current_view.destroy(); } catch (Error e) { }
                content_box.remove(current_view);
                current_view = null;
            }
            load_folder(folder_name);
        });
        hbox.pack_start(toggle_button, false, false, 6);

        folder_button = new Gtk.Button.with_label("Choose Folder");
        folder_button.clicked.connect(() => {
            choose_folder_and_reload();
        });
        hbox.pack_start(folder_button, false, false, 6);

        content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vbox.pack_start(content_box, true, true, 0);

        // 初期ロード
        load_folder(folder_name);

        show_all();
    }

    public void choose_folder_and_reload() {
        string? sel = FolderLoader.choose_folder(this, folder_name);
        if (sel != null) {
            folder_name = sel;
            if (current_view != null) {
                content_box.remove(current_view);
                current_view = null;
            }
            load_folder(folder_name);
        }
    }

    public void load_folder(string folder) {
        names = FolderLoader.get_image_names(folder);
        if (names.length == 0) {
            var lbl = new Gtk.Label("No images found in folder.");
            content_box.pack_start(lbl, true, true, 0);
            current_view = lbl;
            lbl.show();
            return;
        }

        if (showing_grid) {
            var gview = new ImageGridView(folder, names, thumb_width, 8 * 1024 * 1024);
            current_view = gview.get_widget();
            content_box.pack_start(current_view, true, true, 0);
            current_view.show_all();
        } else {
            var fview = new ImageFlowView(folder, names, thumb_width, 8 * 1024 * 1024);
            current_view = fview.get_widget();
            content_box.pack_start(current_view, true, true, 0);
            current_view.show_all();
        }
    }
}
    public static int main(string[] args) {
    Gtk.init(ref args);

    string start_folder = "F:\\GTK3\\old\\minimal\\flowbox\\img\\freng";
    if (args.length > 1) start_folder = args[1];
    var app = new MainWindow(start_folder);
    app.destroy.connect(() => { Gtk.main_quit(); });
    app.show_all();

    Gtk.main();
    return 0;
}





