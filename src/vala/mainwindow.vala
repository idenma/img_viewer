using Gtk;
using GLib;
using Gdk;
using Gee;

// メインウィンドウクラス
public class MainWindow : Gtk.Window {
    private string folder_name;
    private string[] names = {};
    private Gtk.Box content_box;
    private FooterBar footer;
    private string view_type = "folder_img";
    private Gtk.Widget? main_view = null;
    private Gee.HashMap<uint32, BaseWindow> instance_map;
    private int thumb_width = 290;

    public MainWindow(string start_folder) {
        Object(title: "Image Viewer", default_width: 1920, default_height: 1150);
        this.folder_name = start_folder;
        this.instance_map = new Gee.HashMap<uint32, BaseWindow>();

        // メインレイアウト
        var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        add(vbox);

        // コンテンツボックス
        content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vbox.pack_start(content_box, true, true, 0);

        // フッター（イベント制御）
        footer = new FooterBar();
        footer.action.connect(on_footer_action);
        vbox.pack_end(footer, false, false, 6);

        // 初期表示
        grid_display(folder_name);
        footer.update_state(view_type);
    }

    // === Footerイベントハンドラ ===
    private void on_footer_action(string id) {
        if (main_view != null) {
            content_box.remove(main_view);
            main_view.destroy();
            main_view = null;
        }

        switch (id) {
        case "grid":
            view_type = "grid";
            grid_display(folder_name);
            break;
        case "folder_img":
            view_type = "folder_img";
            folder_img_display(folder_name);
            break;
        case "choose_folder":
            choose_folder_and_reload();
            break;
        case "exit":
            this.destroy();
            return;
        }

        footer.update_state(view_type);
    }

    // === フォルダ選択 ===
    private void choose_folder_and_reload() {
        string? sel = FolderLoader.choose_folder(this, folder_name);
        if (sel == null) return;
        folder_name = sel;
        if (main_view != null) {
            content_box.remove(main_view);
            main_view.destroy();
            main_view = null;
        }
        grid_display(folder_name);
    }

    // === Grid表示 ===
    private void grid_display(string folder) {
        names = FolderLoader.get_image_names(folder);
        if (names.length == 0) {
            var lbl = new Gtk.Label("No images found in folder.");
            main_view = lbl;
            content_box.pack_start(lbl, true, true, 0);
            lbl.show();
            return;
        }

        var gview = new ImageGridView(folder, names, thumb_width);
        instance_map.set(gview.instance_id, gview);
        main_view = gview.get_widget();
        content_box.pack_start(main_view, true, true, 0);
        main_view.show_all();
    }

    // === FolderGrid表示 ===
    private void folder_img_display(string folder) {
        var fgview = new FolderGridView(folder, names, thumb_width);
        instance_map.set(fgview.instance_id, fgview);

        // サブフォルダクリック時のイベント
        fgview.folder_selected.connect((subfolder_path) => {
            if (main_view != null) {
                content_box.remove(main_view);
                main_view.destroy();
                main_view = null;
            }
            view_type = "flow";
            folder_name = subfolder_path;
            names = FolderLoader.get_image_names(folder_name);

            var flow = new ImageFlowView(folder_name, names, thumb_width);
            main_view = flow.get_widget();
            content_box.pack_start(main_view, true, true, 0);
            main_view.show_all();
            footer.update_state(view_type);
        });

        main_view = fgview.get_widget();
        content_box.pack_start(main_view, true, true, 0);
        main_view.show_all();
    }
}
