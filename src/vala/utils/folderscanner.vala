using GLib;
using Gee;

// === サブフォルダと画像ファイルを列挙するユーティリティ ===
public class FolderScanner {
    public static Gee.ArrayList<string> get_subfolders(string folder_name) {
        var subfolders = new Gee.ArrayList<string>();
        try {
            var dir = Dir.open(folder_name, 0);
            string? nm;
            while ((nm = dir.read_name()) != null) {
                if (nm == "." || nm == "..") continue;
                var full = Path.build_filename(folder_name, nm);
                if (FileUtils.test(full, FileTest.IS_DIR))
                    subfolders.add(full);
            }
        } catch (Error e) {
            stderr.printf("FolderScanner: failed to list subfolders: %s\n", e.message);
        }

        return subfolders;
    }

    public static Gee.ArrayList<string> get_image_files(string folder_name) {
        var files = new Gee.ArrayList<string>();
        try {
            var dir = Dir.open(folder_name, 0);
            string? fn;
            while ((fn = dir.read_name()) != null) {
                if (fn == "." || fn == "..") continue;
                files.add(fn);
            }
        } catch (Error e) {
            stderr.printf("FolderScanner: failed to read images: %s\n", e.message);
        }

        return files;
    }
}
