using Gtk;
using GLib;
using Gdk;
using img_viewer.utils;


// 画面下部に配置するフッターバー。ImageItem をボタンとして利用
public class FooterBar : Gtk.Box {
    public signal void action(string id);

    private ImageItem btn_grid;
    private ImageItem btn_folder_img;
    private ImageItem btn_choose;
    private ImageItem btn_exit;
    private ImageItem btn_back;
    private ImageItem btn_forward;
    private bool back_enabled = false;
    private bool forward_enabled = false;
    private string current_view = "folder_img";

    public FooterBar() {
        Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 8);
        set_halign(Gtk.Align.FILL);
        set_valign(Gtk.Align.END);
        margin = 6;

        // 戻る
        btn_back = create_icon_button("icon/back.svg", "Back");
        btn_back.clicked.connect((item) => {
            if (!back_enabled) {
                return;
            }
            action("back");
        });

        // Grid 画像グリッド表示
        // 指定のSVGアイコンを使用（100x100）
        string grid_icon = "icon/file-image.svg";
        btn_grid = create_icon_button(grid_icon, "Switch");
    btn_grid.clicked.connect((item) => { action("grid"); });

        // folder_img フォルダグリッド表示
        btn_folder_img = create_icon_button("icon/folder-img.svg", "folder_img");
    btn_folder_img.clicked.connect((item) => { action("folder_img"); });

        // フォルダ選択
        btn_choose = create_icon_button("icon/folder.svg", "Choose Folder");
        btn_choose.clicked.connect((item) => { action("choose_folder"); });

        // 進む
        btn_forward = create_icon_button("icon/foward.svg", "Forward");
        btn_forward.clicked.connect((item) => {
            if (!forward_enabled) {
                return;
            }
            action("forward");
        });

        pack_start(btn_back, false, false, 0);
        pack_start(btn_grid, false, false, 0);
        pack_start(btn_folder_img, false, false, 0);
        pack_start(btn_choose, false, false, 0);
        pack_start(btn_forward, false, false, 0);

        // 終了ボタン
        btn_exit = create_icon_button("icon/power.svg", "終了");
        btn_exit.clicked.connect((item) => { action("exit"); });
        pack_end(btn_exit, false, false, 0);

        set_navigation_state(false, false);
    }

    // MainWindow 側の状態に応じてトグル表記を更新
    public void update_state(string view_type) {
        current_view = view_type;
        switch (view_type) {
            case "grid":
                btn_grid.label.set_text("Image Grid");
                break;
            case "folder_img":
                btn_folder_img.label.set_text("Folder image");
                break;
            case "choose_folder":
                btn_folder_img.label.set_text("Choose Folder");
                break;
            default:
                btn_grid.label.set_text("image");
                break;
        }
    }

    public void set_navigation_state(bool can_back, bool can_forward) {
        back_enabled = can_back;
        forward_enabled = can_forward;
        btn_back.set_dimmed(!can_back);
        btn_forward.set_dimmed(!can_forward);
    }

    private ImageItem create_icon_button(string svg_path, string label_text) {
        int icon_size = 100;
        Gdk.Pixbuf? pixbuf = SvgUtils.render_svg(svg_path, icon_size, icon_size);
        if (pixbuf == null) {
            pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, icon_size, icon_size);
            pixbuf.fill(0x4c4c4cff);
        }

        var item = ImageItem.create_from_pixbuf(pixbuf, label_text, "footer");
        item.set_item(icon_size, icon_size);
        item.label.set_text(label_text);
        return item;
    }
}
