using Gtk;
using GLib;
using Gdk;
using Cairo;
using Rsvg;


// サムネイル作成ユーティリティ
class Thumbnailer {

    public static ImageItem? create_image_thumbnail(string path, int target_size, string view_type) {//コメント内のview_typeは300とする
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
                int folder_size = target_size; // //300*300
                Gdk.Pixbuf? img_pixbuf = null;//Pixbufの箱(まだ空＆サイズなし)
                Gdk.Pixbuf? folder_pixbuf = null;//フォルダアイコン用のPixbufの箱

                try {
                    img_pixbuf = new Gdk.Pixbuf.from_file(path);//Pixbufの箱にpathの画像を読み込む（中身＆サイズがこれで決まる）
                } catch (GLib.Error e) {
                    img_pixbuf = null;
                }
                var img_pixbuf_width = img_pixbuf.get_width();  //元画像のサイズ取得
                var img_pixbuf_height = img_pixbuf.get_height(); //元画像のサイズ取得
                // ソースをターゲットサイズにスケーリング（アスペクト保持）
                if (img_pixbuf != null) {               //img_pixbufに画像が入ってるなら

                    if (img_pixbuf_width != folder_size || img_pixbuf_height != folder_size) {
                        //元画像サイズがターゲットサイズと違うなら、つまり元画像とfolderIconのサイズが違う場合
                        int ratio_width = (int) (folder_size / img_pixbuf_width);
                        int ratio_height = (int) (folder_size / img_pixbuf_height);

                        if (ratio_width < ratio_height) {//もし高さの比率の方が大きければ･･･そうじゃない方、つまり幅をfolder_sizeに合わせたいよね
                            img_pixbuf_width = folder_size;//幅をfolder_sizeに合わせた
                            img_pixbuf_height = (int)(img_pixbuf_height * ratio_width);//で、高さは元画像の比率で決める
                        } else {//もし幅の比率の方が大きければ
                            img_pixbuf_height = folder_size;//高さをfolder_sizeに合わせた
                            img_pixbuf_width = (int)(img_pixbuf_width * ratio_height);//で、幅は元画像の比率で決める
                        }

                        //ここでPixbufとして読み込んだ画像をfolderIconサイズに合わせる
                        var folder_size_img_pixbuf = img_pixbuf.scale_simple(img_pixbuf_width, img_pixbuf_height, Gdk.InterpType.BILINEAR);
                        folder_pixbuf = folder_size_img_pixbuf;
                        try {
                            var cairo_canvas = new Cairo.ImageSurface(Cairo.Format.ARGB32, img_pixbuf_width, img_pixbuf_height);
                            //Cairoを使った描画用cairo_canvas（キャンバス）作成。cario_canvasは透明な状態
                            var cr_paint = new Cairo.Context(cairo_canvas);//cr_paintはcairo_canvasに描画するためのペイント道具だよ
                            cr_paint.save();//現在の状態を保存するよ
                            cr_paint.set_source_rgba(0,0,0,0);//透明色をセットするよ
                            cr_paint.set_operator(Cairo.Operator.SOURCE);//描画モードをSOURCEに設定するよ
                            cr_paint.paint();//キャンバスを透明色で塗りつぶすよ
                            cr_paint.restore();//保存しておいた状態に戻すよ
                            Gdk.cairo_set_source_pixbuf(cr_paint, folder_size_img_pixbuf, img_pixbuf_width, img_pixbuf_height);//描画用ペイント道具にPixbufをセットするよ
                            cr_paint.paint();//Pixbufをキャンバスに描画するよ
                            var canvas_pb = Gdk.pixbuf_get_from_surface(cairo_canvas, 0, 0, img_pixbuf_width, img_pixbuf_height);//キャンバスからPixbufを取得するよ
                            img_pixbuf = (canvas_pb != null) ? canvas_pb : folder_size_img_pixbuf;//取得したPixbufをimg_pixbufにセットするよ
                        } catch (GLib.Error e) {
                            stderr.printf("Thumbnailer: cairo draw failed: %s\n", e.message);
                            img_pixbuf = folder_size_img_pixbuf;
                        }
                    }
                } else {
                    // フォルダ代表アイコンをSVGから生成
                    folder_pixbuf = Thumbnailer.rasterize_svg_to_pixbuf("icon/folder.svg", img_pixbuf_width, img_pixbuf_height);
                }

                if (folder_pixbuf != null) {
                    stderr.printf("Thumbnailer: source pixbuf size = %d x %d\n", folder_pixbuf.get_width(), folder_pixbuf.get_height());
                } else {
                    stderr.printf("Thumbnailer: source pixbuf is NULL\n");
                }

                // マスク適用
                Gdk.Pixbuf? mask_svg = null;//マスク用のPixbufの箱をつくるよ
                if (img_pixbuf != null) { //img_pixbufに画像が入ってるなら
                    mask_svg = Thumbnailer.apply_mask_to_pixbuf(img_pixbuf, "icon/folder.svg", img_pixbuf_width, img_pixbuf_height);//mask_svgはimg_pixbufにマスクを適用したものになるよ
                }
                if (mask_svg != null) {//mask_svgに画像が入ってるなら
                    stderr.printf("Thumbnailer: mask_svg pixbuf size = %d x %d\n", mask_svg.get_width(), mask_svg.get_height());//mask_svgのサイズをターミナルに表示するよ
                    return ImageItem.create_from_pixbuf(mask_svg, GLib.Path.get_basename(path), "foldergrid");//mask_svgを使ってImageItemを作成して返すよ
                } else if (img_pixbuf != null) {//img_pixbufに画像が入ってるなら
                    return ImageItem.create_from_pixbuf(img_pixbuf, GLib.Path.get_basename(path), "foldergrid");//img_pixbufを使ってImageItemを作成して返すよ
                } else {
                    int h3 = (int) (target_size / imageitem.aspect_ratio);//アスペクト比を維持した高さを計算するよ
                    imageitem.set_item(target_size, h3);
                }
                break;

            default:
                break;
            }

            return imageitem;
        }catch (GLib.Error e) {
            stderr.printf("Thumbnailer: create_image_thumbnail failed for %s: %s\n", path, e.message);
            return null;
        }

    }

    // SVGファイルをGdk.Pixbufとしてラスタライズ
    public static Gdk.Pixbuf? rasterize_svg_to_pixbuf(string svg_path, int width, int height) {
        try {
            var handle = new Rsvg.Handle.from_file(svg_path);//SVGファイルを読み込むよ
            var svg_cairo_canvas = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);//Cairoを使った描画用cairo_canvas（キャンバス）をつくるよ　cario_canvasはまだ透明だよ
            var svg_paint = new Cairo.Context(svg_cairo_canvas);//svg_paintはcario_canvasに描画するためのペイント道具だよ

            // 描画領域をクリア
            svg_paint.save();//現在の状態を保存するよ
            svg_paint.set_source_rgba(0,0,0,0);//透明色をセットするよ
            svg_paint.set_operator(Cairo.Operator.SOURCE);//描画モードをSOURCEに設定するよ
            svg_paint.paint();//キャンバスを透明色で塗りつぶすよ
            svg_paint.restore();//保存しておいた状態に戻すよ

            // SVGサイズを取得
            double mw = width, mh = height;
            handle.get_intrinsic_size_in_pixels(out mw, out mh);//SVGの元サイズを取得するよ

            // ⭐ 修正: アスペクト比を維持せずに全面フィット
            double ratio_width = (double) width / mw;//幅の比率を計算するよ
            double ratio_height = (double) height / mh;//高さの比率を計算するよ
            svg_paint.scale(ratio_width, ratio_height);//描画用ペイント道具にスケーリングを設定するよ、svg_paintをアイコンサイズに合わせるよ

            // ⭐ viewport (描画範囲)を正しく指定するよ
            var viewport = Rsvg.Rectangle();//viewport（描画範囲）をつくるよ
            viewport.x = 0;
            viewport.y = 0;
            viewport.width = width;
            viewport.height = height;

            handle.render_document(svg_paint, viewport);

            return Gdk.pixbuf_get_from_surface(svg_cairo_canvas, 0, 0, width, height);
        } catch (GLib.Error e) {
            stderr.printf("Thumbnailer.rasterize_svg_to_pixbuf failed for %s: %s\n", svg_path, e.message);
            return null;
        }
    }

    // マスク適用
    public static Gdk.Pixbuf? apply_mask_to_pixbuf(Gdk.Pixbuf src, string mask_svg_path, int width, int height) {
        try {
            if (src == null) return null;//srcがnullならnullを返すよ

            Gdk.Pixbuf src_pb = src;//src_pbはsrcと同じものになるよ　なんで作るかというと、サイズ変更の可能性があるからだよ
            if (src.get_width() != width || src.get_height() != height) {//srcのサイズが指定された幅と高さと違うなら
                var folder_size_img_pixbuf = src.scale_simple(width, height, Gdk.InterpType.BILINEAR);//folder_size_img_pixbufはsrcを指定された幅と高さにスケーリングしたものになるよ
                if (folder_size_img_pixbuf != null) src_pb = folder_size_img_pixbuf;//src_pbはfolder_size_img_pixbufになるよ
            }

            var handle = new Rsvg.Handle.from_file(mask_svg_path);//SVGファイルを読み込むよ
            var mask_cairo_canvas = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);//Cairoを使った描画用cairo_canvas（キャンバス）をつくるよ　cario_canvasはまだ透明だよ
            var mask_cr_paint = new Cairo.Context(mask_cairo_canvas);//mask_cr_paintはcario_canvasに描画するためのペイント道具だよ

            // クリア
            mask_cr_paint.save();//現在の状態を保存するよ
            mask_cr_paint.set_source_rgba(0,0,0,0);//透明色をセットするよ
            mask_cr_paint.set_operator(Cairo.Operator.SOURCE);//描画モードをSOURCEに設定するよ
            mask_cr_paint.paint();//キャンバスを透明色で塗りつぶすよ
            mask_cr_paint.restore();//保存しておいた状態に戻すよ

            // ⭐ 修正版スケーリング（全面フィット）
            double mw = width, mh = height;//mwとmhは指定された幅と高さになるよ
            handle.get_intrinsic_size_in_pixels(out mw, out mh);//SVGの元サイズを取得するよ　mwとmhをhandleに入れてあげるよ
            double ratio_width = (double) width / mw;//幅の比率を計算するよ
            double ratio_height = (double) height / mh;//高さの比率を計算するよ
            mask_cr_paint.scale(ratio_width, ratio_height);//描画用ペイント道具にスケーリングを設定するよ、mask_cr_paintをアイコンサイズに合わせるよ

            // 正しい viewport 指定
            var mask_rect = Rsvg.Rectangle();//viewport（描画範囲）をつくるよ、この四角はmaskの描画範囲になるよ
            mask_rect.x = 0;
            mask_rect.y = 0;
            mask_rect.width = width;
            mask_rect.height = height;

            handle.render_document(mask_cr_paint, mask_rect);

            // srcをcairo_canvas化
            var src_cairo_canvas = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);//Cairoを使った描画用cairo_canvas（キャンバス）をつくるよ　cario_canvasは何のために作るかというと、maskと合成するためだよ
            var src_cr_paint = new Cairo.Context(src_cairo_canvas);//src_cr_paintはcario_canvasに描画するためのペイント道具だよ
            Gdk.cairo_set_source_pixbuf(src_cr_paint, src_pb, 0, 0);//描画用ペイント道具にPixbufをセットするよ
            src_cr_paint.paint();//Pixbufをキャンバスに描画するよ

            // 合成
            var result_cairo_canvas = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);//Cairoを使った描画用result_cairo_canvas（キャンバス）をつくるよ　result_cairo_canvasは最終結果を入れるためのものだよ
            var res_cr_paint = new Cairo.Context(result_cairo_canvas);//res_cr_paintはresult_cairo_canvasに描画するためのペイント道具だよ
            res_cr_paint.set_source_surface(src_cairo_canvas, 0, 0);//src_cairo_canvasを描画用ペイント道具にセットするよ
            res_cr_paint.mask_surface(mask_cairo_canvas, 0, 0);//mask_cairo_canvasを使ってマスク描画するよ

            return Gdk.pixbuf_get_from_surface(result_cairo_canvas, 0, 0, width, height);
        } catch (GLib.Error e) {
            stderr.printf("Thumbnailer.apply_mask_to_pixbuf failed: %s\n", e.message);
            return null;
        }
    }
}