using Gtk;
using GLib;
using Gdk;
using Gee;

// Grid 表示クラス
class ImageGridView : BaseWindow {
    private Gtk.Grid grid;
    private uint idle_id = 0;
    private int attached_count = 0;
    // サムネイル生成は Thumbnailer の static を利用

    public ImageGridView(string folder_name, string[] file_name, int target_size) {
        base(folder_name, file_name, target_size);
        this.target_size = 290;
        this.view_type = "grid";
        grid = new Gtk.Grid();
        int cols = 6;
        int spacing = 10;
        grid.set_row_spacing(spacing);
        grid.set_column_spacing(spacing);

        scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        grid.set_hexpand(true);
        grid.set_vexpand(true);
        scrolled.add(grid);

        int count = file_name.length;
        int k = 0;
        idle_id = GLib.Idle.add(() => {
            if (k >= count) return false;

            int i = k / cols;
            int j = k % cols;
            string file_path = folder_name + "\\" + file_name[k];
            stderr.printf("loading: %s\n", file_path);

            ImageItem? thumb = Thumbnailer.create_image_thumbnail(file_path, target_size, view_type);

            if (thumb != null) {
                grid.attach(thumb, j, i, 1, 1);
                // ImageItem 内の VBox に画像+ラベルが入っているので show_all
                thumb.show_all();
                attached_count++;
                stderr.printf("grid attached_count=%d at %d,%d\n", attached_count, i, j);
                grid.show_all();
            } else {
                stderr.printf("skip image (cannot scale): %s\n", file_path);
            }

            k++;
            return (k < count);
        });

    scrolled.destroy.connect(() => { try { Source.remove(idle_id); } catch (Error e) { } });
    }

    public Gtk.Widget get_widget() {
        return scrolled;
    }
}