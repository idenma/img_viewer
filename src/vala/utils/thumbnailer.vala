using Gtk;
using GLib;
using Gdk;
using Cairo;
using Rsvg;
using img_viewer.utils;
#if HAVE_OPENCV_FACE
using OpenCVWrapper;
#endif

class Thumbnailer {

    public static ImageItem? create_image_thumbnail(string path, int target_size, string view_type) {
        if (path != null && path.length > 0 && !FileUtils.test(path, FileTest.EXISTS)) {
            stderr.printf("Thumbnailer: missing file %s\n", path);
        }

        var item = new ImageItem("", view_type);
        item.set_placeholder(target_size, target_size, "(No Image)");
        return item;
    }

    public static Gdk.Pixbuf? apply_mask_to_pixbuf(Gdk.Pixbuf img, Gdk.Pixbuf mask, int width, int height) {
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
        var cr = new Cairo.Context(surface);

        CairoUtils.clear_surface(cr);
        Gdk.cairo_set_source_pixbuf(cr, img, 0, 0);
        cr.paint();
        cr.set_operator(Cairo.Operator.DEST_IN);
        Gdk.cairo_set_source_pixbuf(cr, mask, 0, 0);
        cr.paint();
        cr.set_operator(Cairo.Operator.OVER);

        return CairoUtils.surface_to_pixbuf(surface, width, height);
    }

    private static Gdk.Pixbuf fit_pixbuf_to_square(Gdk.Pixbuf src, int size) {
        int src_width = src.get_width();
        int src_height = src.get_height();
        if (src_width <= 0 || src_height <= 0) {
            return CairoUtils.scale_pixbuf(src, size, size);
        }

        double scale_x = (double) size / src_width;
        double scale_y = (double) size / src_height;
        double scale = scale_x < scale_y ? scale_x : scale_y;
        int scaled_width = (int) Math.round(src_width * scale);
        int scaled_height = (int) Math.round(src_height * scale);
        if (scaled_width <= 0) scaled_width = 1;
        if (scaled_height <= 0) scaled_height = 1;

        var scaled = src.scale_simple(scaled_width, scaled_height, Gdk.InterpType.BILINEAR);
        var result = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, size, size);
        result.fill(0x00000000);

        int offset_x = (size - scaled_width) / 2;
        int offset_y = (size - scaled_height) / 2;
        scaled.copy_area(0, 0, scaled_width, scaled_height, result, offset_x, offset_y);
        return result;
    }

#if HAVE_OPENCV_FACE
    public static string opencv_face_crop(string image_path) {
        // OpenCV 側は第2引数を「出力ディレクトリ」として扱う実装
        // ここではリポジトリ直下の output_faces/ を用いる（.gitignore 済み）
        string out_dir = "output_faces";
        try {
            var out_folder = File.new_for_path(out_dir);
            if (!out_folder.query_exists()) {
                out_folder.make_directory_with_parents();
            }
        } catch (GLib.Error e) {
            stderr.printf("Failed to ensure output dir '%s': %s\n", out_dir, e.message);
            // ディレクトリが用意できない場合は元画像を返す
            return image_path;
        }

        int count = OpenCVWrapper.detect_faces(image_path, out_dir, 300, 300);

        if (count > 0) {
            string first = GLib.Path.build_filename(out_dir, "face_0.png");
            if (FileUtils.test(first, FileTest.EXISTS)) {
                return first;
            }
            for (int i = 1; i < count; i++) {
                string alternative = GLib.Path.build_filename(out_dir, "face_%d.png".printf(i));
                if (FileUtils.test(alternative, FileTest.EXISTS)) {
                    return alternative;
                }
            }
        }

        return image_path;
    }
#endif
}
