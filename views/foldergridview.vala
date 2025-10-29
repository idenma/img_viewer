using Gtk;
using GLib;
using Gdk;
using Gee;

// === FolderGridView ===
// サブフォルダごとにフォルダアイコンを並べて表示するビュー
class FolderGridView : BaseWindow {
    public signal void folder_selected(string folder_path);
    private Gtk.Grid grid;
    private uint idle_id = 0;
    private Thumbnailer thumbnailer;
    public int folder_number;

    public FolderGridView(string folder_name, string[] file_name, int target_size) {
        base(folder_name, file_name, target_size);
        this.target_size = 300;
        this.view_type = "foldergrid";

        // --- UI初期化 ---
        grid = new Gtk.Grid();
        grid.set_row_spacing(5);
        grid.set_column_spacing(5);
        grid.set_hexpand(true);
        grid.set_vexpand(true);

        scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled.add(grid);

        thumbnailer = new Thumbnailer();

        // --- サブフォルダ取得 ---
        var subfolders = FolderScanner.get_subfolders(folder_name);
        folder_number = subfolders.size;

        if (folder_number == 0) {
            var lbl = new Gtk.Label("No subfolders found.");
            grid.attach(lbl, 0, 0, 1, 1);
            lbl.show();
            return;
        }

        int cols = 10;
        int k = 0;

        // --- Idleでフォルダアイコン生成 ---
        idle_id = Idle.add(() => {
            if (k >= subfolders.size) {
                idle_id = 0;
                return false; // 停止
            }

            int col = k % cols;
            int row = k / cols;
            string subfolder = subfolders.get(k);

            var imgs = FolderScanner.get_image_files(subfolder);
            if (imgs.size == 0) {
                var lbl = new Gtk.Label("No images");
                grid.attach(lbl, col, row, 1, 1);
                lbl.show();
                k++;
                return (k < subfolders.size);
            }

            int idx = RandomGenerator.between(0, imgs.size - 1);// ランダムに画像を1枚選択
            string random_file = Path.build_filename(subfolder, imgs.get(idx));
            // サムネイル生成
            ImageItem? thumb_item = Thumbnailer.create_image_thumbnail(random_file, target_size, view_type);

            if (thumb_item != null) {
                thumb_item.label.set_text(Path.get_basename(subfolder));
                thumb_item.clicked.connect((item) => {
                    folder_selected(subfolder);
                });

                Gtk.Widget widget = (Gtk.Widget) thumb_item;
                grid.attach(widget, col, row, 1, 1);
                widget.show_all();
            }

            k++;
            return (k < subfolders.size);
        });

        // --- 後片付け ---
        scrolled.destroy.connect(() => {
            if (idle_id != 0) {
                Source.remove(idle_id);
                idle_id = 0;
            }
        });
    }

    public Gtk.Widget get_widget() {
        return scrolled;
    }
}
