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
    private Gee.ArrayList<uint32> history;
    private int history_index = -1;
    private uint32 current_instance_id = 0;

    public MainWindow(string start_folder) {
        Object(title: "Image Viewer", default_width: 1920, default_height: 1150);
        this.folder_name = start_folder;
        this.instance_map = new Gee.HashMap<uint32, BaseWindow>();
        this.history = new Gee.ArrayList<uint32>();

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
        folder_img_display(folder_name);
        footer.update_state(view_type);
    }

    // === Footerイベントハンドラ ===
    private void on_footer_action(string id) {
        switch (id) {
        case "back":
            navigate_history(-1);
            return;
        case "forward":
            navigate_history(1);
            return;
        case "grid":
            grid_display(folder_name);
            break;
        case "folder_img":
            folder_img_display(folder_name);
            break;
        case "choose_folder":
            choose_folder_and_reload();
            break;
        case "exit":
            this.destroy();
            return;
        }
    }

    // === フォルダ選択 ===
    private void choose_folder_and_reload() {
        string? sel = FolderLoader.choose_folder(this, folder_name);
        if (sel == null) return;
        folder_name = sel;
        reset_history();
        folder_img_display(folder_name);
    }

    // === Grid表示 ===
    private void grid_display(string folder) {
        names = FolderLoader.get_image_names(folder);
        if (names.length == 0) {
            show_message("No images found in folder.", folder, "grid");
            return;
        }

    var gview = new ImageGridView(folder, names, thumb_width);
    instance_map.set(gview.instance_id, gview);
    show_view(gview, true);
    }

    // === FolderGrid表示 ===
    private void folder_img_display(string folder) {
        var fgview = new FolderGridView(folder, names, thumb_width);
        instance_map.set(fgview.instance_id, fgview);

        // サブフォルダクリック時のイベント
        fgview.folder_selected.connect((subfolder_path) => {
            string[] flow_names = FolderLoader.get_image_names(subfolder_path);
            if (flow_names.length == 0) {
                show_message("No images found in folder.", subfolder_path, "grid");
                return;
            }

            var flow = new ImageFlowView(subfolder_path, flow_names, thumb_width);
            instance_map.set(flow.instance_id, flow);
            show_view(flow, true);
        });
        show_view(fgview, true);
    }

    private void show_view(BaseWindow view, bool record_history) {
        detach_current_view();

        Gtk.Widget widget = view.get_widget();
        main_view = widget;
        content_box.pack_start(main_view, true, true, 0);
        main_view.show_all();

        folder_name = view.folder_path;
        names = view.image_names;
        view_type = view.view_type;
        current_instance_id = view.instance_id;

        if (record_history) {
            if (history_index < history.size - 1) {
                for (int i = history.size - 1; i > history_index; i--) {
                    history.remove_at(i);
                }
            }

            if (history_index < 0 || history.get(history_index) != view.instance_id) {
                history.add(view.instance_id);
                history_index = history.size - 1;
            }
        } else {
            history_index = history.index_of(view.instance_id);
        }

        footer.update_state(view_type);
        footer.set_navigation_state(can_go_back(), can_go_forward());
    }

    private void detach_current_view() {
        if (main_view != null) {
            bool destroy_view = (current_instance_id == 0);
            Gtk.Widget old_view = main_view;
            content_box.remove(old_view);
            if (destroy_view) {
                old_view.destroy();
            }
        }
        main_view = null;
        current_instance_id = 0;
    }

    private void navigate_history(int delta) {
        if (history.size == 0) return;
        int target_index = history_index + delta;
        if (target_index < 0 || target_index >= history.size) return;

        uint32 target_id = history.get(target_index);
        BaseWindow? view = instance_map.get(target_id);
        if (view == null) return;

        history_index = target_index;
        show_view(view, false);
    }

    private void show_message(string text, string folder, string next_view_type) {
        detach_current_view();
        var lbl = new Gtk.Label(text);
        main_view = lbl;
        content_box.pack_start(main_view, true, true, 0);
        main_view.show();

        folder_name = folder;
        names = {};
        view_type = next_view_type;
        current_instance_id = 0;
        footer.update_state(view_type);
        footer.set_navigation_state(can_go_back(), can_go_forward());
    }

    private bool can_go_back() {
        return history.size > 0 && history_index > 0;
    }

    private bool can_go_forward() {
        return history.size > 0 && history_index >= 0 && history_index < history.size - 1;
    }

    private void reset_history() {
        history.clear();
        history_index = -1;
        instance_map.clear();
        footer.set_navigation_state(false, false);
    }
}
