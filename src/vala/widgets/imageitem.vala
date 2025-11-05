using Gtk;
using GLib;


public class ImageItem : Gtk.EventBox {
    // クリック時に通知するシグナル（外から接続して動作を差し替え可能）
    public signal void clicked(ImageItem item);
    public new string path;
    public Gdk.Pixbuf pixbuf;
    public Gtk.Image image;
    public int width;
    public int height;
    public double aspect_ratio;
    public Gtk.Label label;
    private Gtk.Box box; // 画像とラベルを縦に積む
    private Gdk.Pixbuf? original_pixbuf;

    // 既存のコンストラクタを修正：path が空ならファイル読み込みをスキップ
    public ImageItem(string path, string view_type) {
        // クリック取得のためにボタンイベントを受け付ける
        this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        this.button_press_event.connect((e) => {
            stderr.printf("ImageItem clicked: %s\n", path);
            clicked(this);
            return true;
        });

    // 初期値
    this.path = "";
    this.pixbuf = null;
    this.image = new Gtk.Image();
    this.width = 0;
    this.height = 0;
    this.aspect_ratio = 1.0; // avoid division by zero in thumbnailer

        if (path != null && path.length > 0) {
            try {
                this.pixbuf = new Gdk.Pixbuf.from_file(path);
                this.path = path;
                this.width = this.pixbuf.get_width();
                this.height = this.pixbuf.get_height();
                if (this.height > 0) this.aspect_ratio = (double)this.width / (double)this.height;
                else this.aspect_ratio = 1.0;
                this.image = new Gtk.Image.from_pixbuf(this.pixbuf);
                this.original_pixbuf = this.pixbuf;
            } catch (Error e) {
                stderr.printf("ImageItem: failed to load %s: %s\n", path, e.message);
                // 失敗時は透明プレースホルダを使う
                this.pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 128, 128);
                this.pixbuf.fill(0x00000000);
                this.image = new Gtk.Image.from_pixbuf(this.pixbuf);
                this.width = this.pixbuf.get_width();
                this.height = this.pixbuf.get_height();
                if (this.height > 0) this.aspect_ratio = (double)this.width / (double)this.height;
                else this.aspect_ratio = 1.0;
                this.original_pixbuf = this.pixbuf;
            }
        } else {
            // 空パスは後で set_pixbuf_and_label 等で上書きされる想定
            this.pixbuf = null;
            this.image = new Gtk.Image();
            this.original_pixbuf = null;
        }
        // Create label and box container so other methods can safely pack children
        this.label = new Gtk.Label("");
        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
        // ensure label and image are present
        this.box.pack_start(this.label, false, false, 0);
        this.box.pack_start(this.image, false, false, 0);
        this.add(this.box);
    }



    public void set_item(int width, int height) {
        if (original_pixbuf == null && pixbuf != null) {
            original_pixbuf = pixbuf;
        }

        if (original_pixbuf == null) {
            return;
        }

        int src_width = original_pixbuf.get_width();
        int src_height = original_pixbuf.get_height();
        if (src_width <= 0 || src_height <= 0) {
            return;
        }

        double scale_w = (double) width / (double) src_width;
        double scale_h = (double) height / (double) src_height;
        double scale = scale_w < scale_h ? scale_w : scale_h;
        if (scale <= 0.0) {
            scale = 1.0;
        }

    int scaled_width = (int) ((double) src_width * scale + 0.5);
    int scaled_height = (int) ((double) src_height * scale + 0.5);
        if (scaled_width < 1) scaled_width = 1;
        if (scaled_height < 1) scaled_height = 1;

        var scaled = original_pixbuf.scale_simple(scaled_width, scaled_height, Gdk.InterpType.BILINEAR);
        var canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, width, height);
        canvas.fill(0x00000000);

        int offset_x = (width - scaled_width) / 2;
        int offset_y = (height - scaled_height) / 2;
        scaled.copy_area(0, 0, scaled_width, scaled_height, canvas, offset_x, offset_y);

        this.pixbuf = canvas;
        this.image = new Gtk.Image.from_pixbuf(this.pixbuf);
        this.width = width;
        this.height = height;
        if (scaled_height > 0) this.aspect_ratio = (double) scaled_width / (double) scaled_height;
        else this.aspect_ratio = 1.0;

        this.set_size_request(width, height);
 
        // 先に既存の image を取り除く（初回は存在しない）
        foreach (Gtk.Widget child in box.get_children()) {
            if (child is Gtk.Image) {
                box.remove(child);
                break;
            }
        }
        
        // ラベルが未追加なら追加（重複追加しない）
        bool has_label = false;
        foreach (Gtk.Widget child in box.get_children()) {
            if (child == label) { has_label = true; break; }
        }
        if (!has_label) box.pack_start(label, false, false, 0);
        box.pack_start(image, false, false, 0);
    }

    // 外部で既に合成済みの Pixbuf を与えて表示するユーティリティ
    public void set_pixbuf_and_label(Gdk.Pixbuf pb, string label_text, int width, int height) {
        this.width = width;
        this.height = height;
        this.pixbuf = pb;
        this.image = new Gtk.Image.from_pixbuf(pb);
        this.label.set_text(label_text);
    this.original_pixbuf = pb;
    this.width = width;
    this.height = height;
    if (height > 0) this.aspect_ratio = (double) width / (double) height;
    else this.aspect_ratio = 1.0;

        // 既存の画像ウィジェットを除去
        foreach (Gtk.Widget child in box.get_children()) {
            if (child is Gtk.Image) {
                box.remove(child);
                break;
            }
        }
        bool has_label = false;
        foreach (Gtk.Widget child in box.get_children()) {
            if (child == label) { has_label = true; break; }
        }
        if (!has_label) box.pack_start(label, false, false, 0);
        box.pack_start(image, false, false, 0);
    }

    // 新規追加: Pixbuf から直接生成するファクトリ
    public static ImageItem create_from_pixbuf(Gdk.Pixbuf pb, string label_text, string view_type) {
        var it = new ImageItem("", view_type);
        if (pb != null) {
            it.pixbuf = pb;
            it.width = pb.get_width();
            it.height = pb.get_height();
            it.image = new Gtk.Image.from_pixbuf(pb);
            it.original_pixbuf = pb;
            // ラベルやその他があれば set_pixbuf_and_label を呼ぶ（既存実装に合わせる）
            try {
                it.set_pixbuf_and_label(pb, label_text, it.width, it.height);
            } catch (Error e) {
                // set_pixbuf_and_label が無ければ安全に無視
            }
        } else {
            it.image = new Gtk.Image();
        }
        return it;
    }
}