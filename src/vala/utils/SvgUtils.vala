using Cairo;
using Gdk;
using Rsvg;


namespace img_viewer.utils {

    public class SvgUtils {

        // 画像をSVGの形でマスクして返す
        public static Gdk.Pixbuf? render_svg(Gdk.Pixbuf img_pixbuf, string svg_path, int width, int height) {
            if (img_pixbuf == null) {
                img_pixbuf = new Gdk.Pixbuf.from_file(svg_path);

            }
            
            // SVGファイル読み込み
            var handle = new Rsvg.Handle.from_file(svg_path);

            // SVGの実寸取得（スケール用）
            double mw = width, mh = height;
            handle.get_intrinsic_size_in_pixels(out mw, out mh);

            // 描画用のサーフェスを作成
            Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
            Cairo.Context cr = new Cairo.Context(surface);

            // 背景を透明で初期化
            CairoUtils.clear_surface(cr);

            // ------------------------------------
            // 1. 元画像を背景に描画
            // ------------------------------------
            var image_surface = CairoUtils.pixbuf_to_surface(img_pixbuf);
            cr.save();
            cr.set_source_surface(image_surface, 0, 0);
            cr.paint();
            cr.restore();

            // ------------------------------------
            // 2. SVGをマスクとして適用
            // ------------------------------------
            // SVGを描画する別サーフェスを作成
            Cairo.ImageSurface mask_surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
            Cairo.Context mask_cr = new Cairo.Context(mask_surface);
            mask_cr.scale(width / mw, height / mh);
            handle.render_document(mask_cr, CairoUtils.make_viewport(width, height));

            // mask_surfaceのアルファを元画像に適用
            cr.save();
            cr.set_operator(Cairo.Operator.DEST_IN);
            cr.set_source_surface(mask_surface, 0, 0);
            cr.paint();
            cr.restore();

            // ------------------------------------
            // 3. Pixbufとして返す
            // ------------------------------------
            var result_pixbuf = CairoUtils.surface_to_pixbuf(surface, width, height);
            return result_pixbuf;
        }
    }
}
