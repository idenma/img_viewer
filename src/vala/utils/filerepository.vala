using GLib;
using Gdk;
using Gee;

// ファイル/フォルダ列挙処理を一元化
public class FileRepository : Object {
    private static string[] IMAGE_EXTS = { ".png", ".jpg", ".jpeg", ".jfif", ".webp", ".bmp", ".gif", ".tiff" };

    public static Gee.ArrayList<string> list_subfolders(string folder_path) {
        var subfolders = new Gee.ArrayList<string>();
        try {
            var dir = Dir.open(folder_path, 0);
            string? entry;
            while ((entry = dir.read_name()) != null) {
                if (entry == "." || entry == "..") {
                    continue;
                }
                var full = Path.build_filename(folder_path, entry);
                if (FileUtils.test(full, FileTest.IS_DIR)) {
                    subfolders.add(full);
                }
            }
        } catch (Error e) {
            stderr.printf("FileRepository: failed to list subfolders in '%s': %s\n", folder_path, e.message);
        }
        return subfolders;
    }

    public static Gee.ArrayList<string> list_image_files(string folder_path) {
        var files = new Gee.ArrayList<string>();
        try {
            var dir = Dir.open(folder_path, 0);
            string? entry;
            while ((entry = dir.read_name()) != null) {
                if (entry == "." || entry == "..") {
                    continue;
                }
                var lower = entry.down();
                if (!has_supported_extension(lower)) {
                    continue;
                }
                string full_path = Path.build_filename(folder_path, entry);
                if (!is_regular_file(full_path)) {
                    continue;
                }
                if (!can_decode_with_gdk(full_path)) {
                    continue;
                }
                files.add(entry);
            }
        } catch (Error e) {
            stderr.printf("FileRepository: failed to list images in '%s': %s\n", folder_path, e.message);
        }
        return files;
    }

    public static string[] get_image_names(string folder_path) {
        return list_image_files(folder_path).to_array();
    }

    private static bool has_supported_extension(string lower_name) {
        foreach (var ext in IMAGE_EXTS) {
            if (lower_name.has_suffix(ext)) {
                return true;
            }
        }
        return false;
    }

    private static bool is_regular_file(string full_path) {
        try {
            if (!FileUtils.test(full_path, FileTest.IS_REGULAR)) {
                return false;
            }
        } catch (Error e) {
            stderr.printf("FileRepository: stat failed for '%s': %s\n", full_path, e.message);
            return false;
        }
        return true;
    }

    private static bool can_decode_with_gdk(string full_path) {
        try {
            int width = 0;
            int height = 0;
            var info = Gdk.Pixbuf.get_file_info(full_path, out width, out height);
            if (info == null || width <= 0 || height <= 0) {
                return false;
            }
        } catch (GLib.Error e) {
            stderr.printf("FileRepository: probe failed for '%s': %s\n", full_path, e.message);
            return false;
        }
        return true;
    }
}
