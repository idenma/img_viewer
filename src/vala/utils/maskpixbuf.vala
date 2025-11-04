using Cairo;
using Gdk;

public static Gdk.Pixbuf mask_pixbuf(Gdk.Pixbuf src, Gdk.Pixbuf mask) {
    // src と mask のサイズは同じであることが前提
    int width = src.get_width();
    int height = src.get_height();

    // Cairo ImageSurface を作成
    var surface = new ImageSurface(Format.ARGB32, width, height);
    var cr = new Context(surface);

    // src を surface に描画
    Gdk.cairo_set_source_pixbuf(cr, src, 0, 0);
    cr.paint();

    // mask を surface にマスクとして適用
    var mask_surface = new ImageSurface(Format.A8, width, height);
    var mask_cr = new Context(mask_surface);

    // mask のアルファチャンネルを mask_surface にコピー
    // Pixbuf の R,G,B は無視して A チャンネルだけをコピー
    int rowstride = mask.get_rowstride();
    uint8[] pixels = mask.get_pixels();
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int offset = y * rowstride + x * 4;
            uint8 alpha = pixels[offset + 3]; // A チャンネル
            mask_surface.get_data()[(y * width + x)] = alpha;
        }
    }

    // surface にマスクを適用
    cr.mask_surface(mask_surface, 0, 0);

    // 最終的に Pixbuf に変換
    return Gdk.pixbuf_get_from_surface(surface, 0, 0, width, height);
}
