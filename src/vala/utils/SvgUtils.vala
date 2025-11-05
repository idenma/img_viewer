using Cairo;
using Gdk;
using Rsvg;


namespace img_viewer.utils {

    public class SvgUtils {

        // 画像をSVGの形でマスクして返す
        public static Gdk.Pixbuf? render_svg(string svg_path, int width, int height) {
            try {
                var handle = new Rsvg.Handle.from_file(svg_path);

                double svg_width = width;
                double svg_height = height;
                handle.get_intrinsic_size_in_pixels(out svg_width, out svg_height);

                if (svg_width <= 0 || svg_height <= 0) {
                    svg_width = width;
                    svg_height = height;
                }

                var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
                var cr = new Cairo.Context(surface);
                CairoUtils.clear_surface(cr);

                double scale_x = (double) width / svg_width;
                double scale_y = (double) height / svg_height;
                cr.save();
                cr.scale(scale_x, scale_y);
                handle.render_document(cr, CairoUtils.make_viewport((int) svg_width, (int) svg_height));
                cr.restore();

                return CairoUtils.surface_to_pixbuf(surface, width, height);
            } catch (GLib.Error e) {
                stderr.printf("SvgUtils.render_svg failed: %s\n", e.message);
                return null;
            }
        }
    }
}
