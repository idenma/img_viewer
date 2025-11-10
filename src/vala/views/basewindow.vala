using Gtk;
using GLib;
using Gdk;
using Gee;

// FlowBox 表示クラス
class BaseWindow : Object {
    private Gtk.Widget? current_view = null;
    public Gtk.ScrolledWindow scrolled;
    private uint idle_id = 0;
    private int attached_count = 0;
    public string view_type;
    public int target_size;
    public uint32 instance_id;
    public string folder_path { get; protected set; }
    public string[] image_names { get; protected set; }

    public BaseWindow(string folder_name, string[] names, int target_size) {
        this.view_type = "";
        this.target_size = target_size;
        this.folder_path = folder_name;
        this.image_names = names;
        scrolled = new Gtk.ScrolledWindow(null, null);
       instance_id = RandomGenerator.between(0, 2147483647);
       print("instance ID: %u\n", instance_id);
    }

    public virtual Gtk.Widget get_widget() {
        return scrolled;
    }

}