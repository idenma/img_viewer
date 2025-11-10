using Gtk;
using GLib;
using Gee;

// フォルダ列挙と選択を担当
class FolderLoader {
    public static string[] get_image_names(string folder_name) {
        var list = new Gee.ArrayList<string>();
        try {
            var dir = Dir.open(folder_name, 0);
            string? entry;
            while ((entry = dir.read_name()) != null) {
                if (entry == "." || entry == "..") continue;
                list.add(entry);
            }
        } catch (Error e) {
            stderr.printf("FolderLoader: failed to list '%s': %s\n", folder_name, e.message);
            return new string[0];
        }
        return list.to_array();
    }

    public static string? choose_folder(Gtk.Window parent, string initial) {
        Gtk.FileChooserNative? native = null;
        Gtk.FileChooserDialog? dialog = null;
        Gtk.FileChooser chooser;

        try {
            native = new Gtk.FileChooserNative(
                "フォルダを選択してください",
                parent,
                Gtk.FileChooserAction.SELECT_FOLDER,
                "Open",
                "Cancel"
            );
            chooser = native;
        } catch (Error e) {
            stderr.printf("FileChooserNative unavailable: %s\n", e.message);
            dialog = new Gtk.FileChooserDialog(
                "フォルダを選択してください",
                parent,
                Gtk.FileChooserAction.SELECT_FOLDER,
                "Open", Gtk.ResponseType.OK,
                "Cancel", Gtk.ResponseType.CANCEL
            );
            chooser = dialog;
        }

        try {
            chooser.set_current_folder(initial);
        } catch (Error e) {
            stderr.printf("Failed to open '%s': %s\n", initial, e.message);
        }

        string? result = null;
        try {
            int resp = (native != null) ? native.run() : dialog.run();
            if (resp == (int) Gtk.ResponseType.OK) {
                string? sel = chooser.get_filename();
                if (sel != null && sel.length > 0) result = sel;
            }
        } catch (GLib.Error e) {
            stderr.printf("File chooser failed: %s\n", e.message);
        }

        try {
            if (native != null) {
                native.destroy();
            } else if (dialog != null) {
                dialog.destroy();
            }
        } catch (Error e) {
        }

        return result;
    }
}