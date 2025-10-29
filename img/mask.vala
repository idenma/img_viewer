using Gtk;
using GLib;
using Gdk;
using Cairo;
using Rsvg;

// Mask: ImageItem とマスク用 Pixbuf を受け取り、合成後の ImageItem を返すユーティリティ
public class Mask {
    private ImageItem prev_item;
    private Gdk.Pixbuf? mask_pb;
    private string? mask_svg;

    // Construct with an already-rasterized mask pixbuf
    public Mask(ImageItem prev_imageitem, Gdk.Pixbuf masking_image) {
        this.prev_item = prev_imageitem;
        this.mask_pb = masking_image;
        this.mask_svg = null;
    }

    // SVG マスクパスで構築する。マスクは apply() 時にレンダリングされる
    public Mask.with_svg(ImageItem prev_imageitem, string svg_path) {
        this.prev_item = prev_imageitem;
        this.mask_pb = null;
        this.mask_svg = svg_path;
    }

    // マスクを適用して新しい ImageItem を返す。失敗したら元の ImageItem を返す。
    public ImageItem apply() {
        try {
            if (prev_item == null || prev_item.pixbuf == null) {
                stderr.printf("Mask.apply: source pixbuf is null, returning original\n");
                return prev_item;
            }

            int w;
            int h;
            // ターゲットサイズの決定：マスクpixbufサイズがあればそれを使用し、なければソースpixbufサイズを使用する。
            if (mask_pb != null) {
                w = mask_pb.get_width();
                h = mask_pb.get_height();
            } else {
                w = prev_item.pixbuf.get_width();
                h = prev_item.pixbuf.get_height();
            }

            // gdk_pixbuf_scale_simple を失敗させる無効なサイズをガードする。
            if (w <= 0 || h <= 0) {
                stderr.printf("Mask.apply: invalid target size %d x %d, returning original\n", w, h);
                return prev_item;
            }

            // 元画像をマスクサイズに合わせてリサイズ
            Gdk.Pixbuf src_pb = prev_item.pixbuf;
            if (src_pb == null) {
                stderr.printf("Mask.apply: source pixbuf became null, returning original\n");
                return prev_item;
            }
            Gdk.Pixbuf scaled_src = src_pb.scale_simple(w, h, Gdk.InterpType.BILINEAR);

            // Cairo サーフェスを作成して合成
            var img_surf = Gdk.cairo_surface_create_from_pixbuf(scaled_src, 1, null);
            Cairo.Surface mask_surf;
            if (mask_pb != null) {
                mask_surf = Gdk.cairo_surface_create_from_pixbuf(mask_pb, 1, null);
            } else if (mask_svg != null) {
                // Render SVG to a surface of size w x h
                try {
                    var handle = new Rsvg.Handle.from_file(mask_svg);
                    var svg_surf = new Cairo.ImageSurface(Cairo.Format.ARGB32, w, h);
                    var svg_cr = new Cairo.Context(svg_surf);
                    // clear
                    svg_cr.save();
                    svg_cr.set_source_rgba(0,0,0,0);
                    svg_cr.set_operator(Cairo.Operator.SOURCE);
                    svg_cr.paint();
                    svg_cr.restore();

                    double mw = 0; double mh = 0;
                    try { handle.get_intrinsic_size_in_pixels(out mw, out mh); } catch (GLib.Error e) { mw = w; mh = h; }
                    if (mw <= 0 || mh <= 0) { mw = w; mh = h; }
                    double sx = (double) w / mw;
                    double sy = (double) h / mh;
                    double s = (sx < sy) ? sx : sy;
                    double dx = (w - s * mw) / 2.0;
                    double dy = (h - s * mh) / 2.0;
                    svg_cr.translate(dx, dy);
                    svg_cr.scale(s, s);
                    handle.render_cairo(svg_cr);
                    mask_surf = svg_surf;
                } catch (GLib.Error e) {
                    stderr.printf("Mask: failed to render SVG %s: %s\n", mask_svg, e.message);
                    return prev_item;
                }
            } else {
                stderr.printf("Mask.apply: no mask available\n");
                return prev_item;
            }

            var result_surf = new Cairo.ImageSurface(Cairo.Format.ARGB32, w, h);
            var cr = new Cairo.Context(result_surf);
            // 透明でクリア
            cr.save();
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.restore();

            // 画像をマスクで描画する（マスクのアルファを使って切り抜く）
            cr.set_source_surface(img_surf, 0, 0);
            cr.mask_surface(mask_surf, 0, 0);

            // 結果を Pixbuf に変換
            var result_pb = Gdk.pixbuf_get_from_surface(result_surf, 0, 0, w, h);
            if (result_pb == null) {
                stderr.printf("Mask.apply: failed to convert result surface to pixbuf, returning original\n");
                return prev_item;
            }

            // determine a safe label text
            string label_text = "";
            try {
                if (prev_item.label != null) label_text = prev_item.label.get_text();
            } catch (GLib.Error e) {
                label_text = prev_item.path != null ? prev_item.path : "";
            }

            // create_from_pixbuf を使って直接 ImageItem を生成
            var out_item = ImageItem.create_from_pixbuf(result_pb, label_text, "mask");

            if (h > 0) out_item.aspect_ratio = (double) w / (double) h;

            return out_item;
        } catch (GLib.Error e) {
            stderr.printf("Mask.apply failed: %s\n", e.message);
            return prev_item;
        }
    }
}
