using Gtk;
using GLib;


// 画面下部に配置するフッターバー。ImageItem をボタンとして利用
public class FooterBar : Gtk.Box {
    public signal void action(string id);

    private ImageItem btn_grid;
    private ImageItem btn_folder_img;
    private ImageItem btn_choose;
    private ImageItem btn_exit;
    private string current_view = "grid";

    public FooterBar() {
        Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 8);
        set_halign(Gtk.Align.FILL);
        set_valign(Gtk.Align.END);
        margin = 6;

        //Grid 画像グリッド表示
        // 指定のSVGアイコンを使用（100x100）
        string grid_icon = "icon/file-image.svg";
        btn_grid = new ImageItem(grid_icon, "footer");
        btn_grid.set_item(100, 100);
        btn_grid.label.set_text("Switch");
        btn_grid.clicked.connect((item) => { action("grid"); });

        //folder_img フォルダグリッド表示
        btn_folder_img = new ImageItem("icon/folder-img.svg", "footer");
        btn_folder_img.set_item(100, 100);
        btn_folder_img.label.set_text("Folder Grid");
        btn_folder_img.clicked.connect((item) => { action("folder_img"); });

        // フォルダ選択
        btn_choose = new ImageItem("icon/folder.svg", "footer");
        btn_choose.set_item(100, 100);
        btn_choose.label.set_text("Choose Folder");
        btn_choose.clicked.connect((item) => { action("choose_folder"); });

        pack_start(btn_grid, false, false, 0);
        pack_start(btn_folder_img, false, false, 0);
        pack_start(btn_choose, false, false, 0);

        // 終了ボタン
        btn_exit = new ImageItem("icon/power.svg", "footer");
        btn_exit.set_item(100, 100);
        btn_exit.label.set_text("終了");
        btn_exit.clicked.connect((item) => { action("exit"); });
        pack_end(btn_exit, false, false, 0);
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
}
