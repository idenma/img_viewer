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
                //Gdk.Pixbuf? img_pixbuf = new Gdk.Pixbuf.from_file(path);
                var face_crop = Thumbnailer.opencv_face_crop(path);
                Gdk.Pixbuf? img_pixbuf = Pixbuf.load_from_file(face_crop);

        //        if (img_pixbuf == null) {
        //            img_pixbuf = SvgUtils.render_svg(null,"icon/folder.svg", folder_size, folder_size);
        //        }

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

    public static Gdk.Pixbuf opencv_face_crop(string image_path) {

        string input = image_path;
        string output = "face_result.png";
        int count = OpenCVWrapper.detect_faces(input, out output, 300, 300);
        print("検出された顔の数: %d\n", count);
        print("結果画像: %s\n", output);
    }

    }
}
