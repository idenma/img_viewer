using Gtk;
using GLib;
using Gdk;
using Gee;

// FlowBox 表示クラス
class ImageFlowView : BaseWindow {
    private Gtk.FlowBox flow;
    private uint idle_id = 0;
    private int attached_count = 0;
    // サムネイル生成は Thumbnailer の static を利用

    public ImageFlowView(string folder_name, string[] file_name, int target_size) {
        base(folder_name, file_name, target_size);
        this.view_type = "flow";
        this.target_size = 400;
        flow = new Gtk.FlowBox();
        flow.set_valign(Gtk.Align.START);
        flow.set_max_children_per_line(10);
        flow.set_row_spacing(0);
        flow.set_column_spacing(0);

        scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        flow.set_hexpand(true);
        flow.set_vexpand(true);
        scrolled.add(flow);


        int count = file_name.length;
        int k = 0;
        idle_id = GLib.Idle.add(() => {
            if (k >= count) return false;

            string image_path = folder_name + "\\" + file_name[k];
            //stderr.printf("loading(flow): %s\n", image_path);

            ImageItem? thumb = Thumbnailer.create_image_thumbnail(image_path, target_size, view_type);

            if (thumb != null) {
                var image = new Gtk.Image.from_pixbuf(thumb.pixbuf);
                var child = new Gtk.FlowBoxChild();
                child.add(image);
                flow.add(child);
                child.show_all();
                attached_count++;
                stderr.printf("flow attached_count=%d for %s\n", attached_count, image_path);
                flow.show_all();
            } else {
                stderr.printf("skip image (cannot scale flow): %s\n", image_path);
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