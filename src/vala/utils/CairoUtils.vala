using Cairo;
using Gdk;
using Rsvg;

namespace img_viewer.utils {

    public class CairoUtils {

        public static void clear_surface(Cairo.Context cr) {
            cr.save();
            cr.set_operator(Cairo.Operator.CLEAR);
            cr.paint();
            cr.restore();
        }

        // 🔽 修正：Rsvg.Rectangle を返すようにする
        public static Rsvg.Rectangle make_viewport(int width, int height) {
            Rsvg.Rectangle rect = { 0, 0, width, height };
            return rect;
        }

        public static Gdk.Pixbuf scale_pixbuf(Gdk.Pixbuf src, int target_width, int target_height) {//Pixbufを指定サイズにスケーリングする
            return src.scale_simple(target_width, target_height, Gdk.InterpType.BILINEAR);
        }

        public static Cairo.ImageSurface pixbuf_to_surface(Gdk.Pixbuf pixbuf) {//PixbufをCairoのImageSurfaceに変換する
            var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.width, pixbuf.height);
            var cr = new Cairo.Context(surface);
            Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
            cr.paint();
            return surface;
        }

        public static Gdk.Pixbuf surface_to_pixbuf(Cairo.ImageSurface surface, int width, int height) {//このメソッドの機能: CairoのImageSurfaceをGdkのPixbufに変換する
            surface.flush();
            return Gdk.pixbuf_get_from_surface(surface, 0, 0, width, height);
        }
    }
}
