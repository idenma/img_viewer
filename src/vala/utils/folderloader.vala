using Gtk;
using GLib;
using Gdk;
using Gee;

// フォルダ列挙と選択を担当
class FolderLoader {
    public static string[] get_image_names(string folder_name) {
        var list = new Gee.ArrayList<string>();
        var exts = new Gee.ArrayList<string>();
        exts.add(".png");
        exts.add(".jpg");
        exts.add(".jpeg");
        exts.add(".bmp");
        exts.add(".gif");
        exts.add(".tiff");
        exts.add(".webp");
        Dir dir = null;
        try {
            dir = Dir.open(folder_name, 0);
        } catch (Error e) {
            stderr.printf("Failed to open '%s': %s\n", folder_name, e.message);
            return new string[0];
        }

        if (dir != null) {
            string? nopt;
            while ((nopt = dir.read_name()) != null) {
                string name = nopt;
                if (name == "." || name == "..") continue;
                string lname = name.down();

                bool matched = false;
                foreach (string ext in exts) {
                    if (lname.has_suffix(ext)) {
                        matched = true;
                        break;
                    }
                }
            
                if (matched) {
                    list.add(name);
                }
            }
        }
        return list.to_array();
    }

    public static string? choose_folder(Gtk.Window parent, string initial) {
        var chooser = new Gtk.FileChooserDialog(
            "フォルダを選択してください", parent,
            Gtk.FileChooserAction.SELECT_FOLDER,
            "Open", Gtk.ResponseType.OK,
            "Cancel", Gtk.ResponseType.CANCEL
        );

        try {
            chooser.set_current_folder(initial);
        } catch (Error e) {
            stderr.printf("Failed to open '%s': %s\n", initial, e.message);
        }

        string? result = null;
        int resp = chooser.run();
        if (resp == (int) Gtk.ResponseType.OK) {
            string? sel = chooser.get_filename();
            if (sel != null && sel.length > 0) result = sel;
        }
        chooser.destroy();
        return result;
    }
}