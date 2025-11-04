using Gtk;
using GLib;
using Gdk;
using Cairo;
using Rsvg;
using img_viewer.utils;
using OpenCVWrapper;

class Thumbnailer {

    public static ImageItem? create_image_thumbnail(string path, int target_size, string view_type) {
        try {
            var imageitem = new ImageItem(path, view_type);

            switch (view_type) {
            case "grid":
                imageitem.set_item(target_size, target_size);
                break;

            case "flow":
                int width = (int)(target_size * imageitem.aspect_ratio);
                imageitem.set_item(width, target_size);
                break;

            case "foldergrid":
                int folder_size = target_size;
                // 顔クロップ試行 → 失敗時はフォルダアイコンでマスク合成にフォールバック
                string face_crop = Thumbnailer.opencv_face_crop(path);
                Gdk.Pixbuf? img_pixbuf = null;
                try {
                    img_pixbuf = new Pixbuf.from_file(face_crop);
                } catch (GLib.Error e) {
                    img_pixbuf = null;
                }

                if (img_pixbuf == null) {
                    // 画像が確保できない場合は、フォルダSVGでプレースホルダを生成
                    try {
                        img_pixbuf = SvgUtils.render_svg(null, "icon/folder.svg", folder_size, folder_size);
                    } catch (Error e) {
                        img_pixbuf = null;
                    }
                }

                if (img_pixbuf != null) {
                    img_pixbuf = CairoUtils.scale_pixbuf(img_pixbuf, folder_size, folder_size);
                    var mask = SvgUtils.render_svg(img_pixbuf, "icon/folder.svg", folder_size, folder_size);

                    if (mask != null) {
                        var result = apply_mask_to_pixbuf(img_pixbuf, mask, folder_size, folder_size);
                        return ImageItem.create_from_pixbuf(result, GLib.Path.get_basename(path), "foldergrid");
                    }
                }
                break;

            default:
                break;
            }

            return imageitem;
        } catch (GLib.Error e) {
            stderr.printf("Thumbnailer: %s\n", e.message);
            return null;
        }
    }

    public static Gdk.Pixbuf? apply_mask_to_pixbuf(Gdk.Pixbuf img, Gdk.Pixbuf mask, int width, int height) {
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
        var cr = new Cairo.Context(surface);

        Gdk.cairo_set_source_pixbuf(cr, img, 0, 0);
        cr.paint();
        Gdk.cairo_set_source_pixbuf(cr, mask, 0, 0);
        cr.mask(cr.get_source());

        return CairoUtils.surface_to_pixbuf(surface, width, height);
    }

    public static string opencv_face_crop(string image_path) {
        // OpenCV 側は第2引数を「出力ディレクトリ」として扱う実装
        // ここではリポジトリ直下の output_faces/ を用いる（.gitignore 済み）
        string out_dir = "output_faces";
        try {
            var out_folder = File.new_for_path(out_dir);
            if (!out_folder.query_exists()) {
                out_folder.make_directory_with_parents();
            }
        } catch (Error e) {
            stderr.printf("Failed to ensure output dir '%s': %s\n", out_dir, e.message);
            // ディレクトリが用意できない場合は元画像を返す
            return image_path;
        }

        int count = OpenCVWrapper.detect_faces(image_path, out_dir, 300, 300);

        // 1枚以上検出できたら、face_0.png を代表として返す
        if (count > 0) {
            string first = Path.build_filename(out_dir, "face_0.png");
            if (FileUtils.test(first, FileTest.EXISTS)) {
                return first;
            }
            // 念のため face_1.png ... の存在も探す
            for (int i = 1; i < count; i++) {
                string alt = Path.build_filename(out_dir, "face_%d.png".printf(i));
                if (FileUtils.test(alt, FileTest.EXISTS)) return alt;
            }
        }

        // 検出できない/見つからない場合は元画像を返す
        return image_path;
    }

}

