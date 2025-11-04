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

    public BaseWindow(string folder_name, string[] names, int target_size) {
        this.view_type = "";
        this.target_size = 0;
        scrolled = new Gtk.ScrolledWindow(null, null);
       instance_id = RandomGenerator.between(0, 2147483647);
       print("instance ID: %u\n", instance_id);
    }

}