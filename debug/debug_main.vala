using Gtk;
using GLib;
// Mask クラスを利用

public static int main(string[] args) {
    Gtk.init(ref args);

    string start_folder = "F:\\iCloud\\iCloudDrive\\Artist_art\\sooon"; // main.vala と同じ既定パスを使う
    if (args.length > 1) start_folder = args[1];

    var win = new Gtk.Window();
    // 小さいウィンドウにして中央にフォルダアイコンだけ表示するデバッグ用
    win.set_default_size(800, 600);
    win.set_title("Debug: Centered Folder Icon");

    // 1 ウィジェットだけを中央に配置するためのコンテナ
    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
    win.add(hbox);

    // 単体テスト: start_folder を表す「フォルダアイコン」を中央に一つだけ表示する
    try {
        // start_folder 内の最初の画像ファイルを探す
        string? rep_path = null;
        try {
            Dir dir = Dir.open(start_folder, 0);
            string name;
            while ((name = dir.read_name()) != null) {
                // 各エントリを candidate パスとして試し、サムネイル生成に成功したら代表画像とする
                string candidate = start_folder + "\\" + name;
                try {
                    var tmp = Thumbnailer.create_image_thumbnail(candidate, 300, "foldergrid");
                    if (tmp != null) {
                        rep_path = candidate;
                        break;
                    }
                } catch (Error e) {
                    // 無視して次へ
                }
            }
            // Dir の明示的クローズは省略（GLib.Dir を明示的に閉じる必要があればここで行う）
        } catch (Error e) {
            rep_path = null;
        }

        ImageItem? base_item = null;
        if (rep_path != null) {
            // 見つかった画像ファイルから foldergrid 用サムネイルを作る
            try {
                base_item = Thumbnailer.create_image_thumbnail(rep_path, 300, "foldergrid");
            } catch (Error e) {
                base_item = null;
            }
        }

        if (base_item == null) {
            // フォールバック: フォルダアイコン自体をラスタライズして元画像にする（常に有効な pixbuf を得るため）
            try {
                var pb = Thumbnailer.rasterize_svg_to_pixbuf("icon/folder.svg", 300, 300);
                if (pb != null) {
                    base_item = ImageItem.create_from_pixbuf(pb, "folder", "foldergrid");
                } else {
                    // 最終手段: ファイルパス版（ImageItem の内部で失敗すれば透明プレースホルダになる）
                    base_item = new ImageItem("icon/folder.svg", "foldergrid");
                }
            } catch (Error e) {
                base_item = new ImageItem("icon/folder.svg", "foldergrid");
            }
        }

        // Mask を使ってフォルダ形に切り抜く（icon/folder.svg をマスクに使う）
        ImageItem final_item;
        if (base_item != null) final_item = base_item;
        else final_item = new ImageItem("icon/folder.svg", "foldergrid");

        // Only attempt masking when we have a valid pixbuf and non-zero size
        bool did_mask = false;
        try {
            if (final_item != null && final_item.pixbuf != null) {
                int pw = final_item.pixbuf.get_width();
                int ph = final_item.pixbuf.get_height();
                if (pw > 0 && ph > 0) {
                    // debug: save the source pixbuf before masking
                    try {
                        final_item.pixbuf.savev("debug_before_mask.png", "png", null, null);
                        stderr.printf("debug_main: saved debug_before_mask.png (%d x %d)\n", pw, ph);
                    } catch (GLib.Error e) {
                        stderr.printf("debug_main: could not save debug_before_mask.png: %s\n", e.message);
                    }

                    var m = new Mask.with_svg(final_item, "icon/folder.svg");
                    var masked = m.apply();
                    if (masked != null) {
                        // debug: save masked pixbuf as well
                        try {
                            if (masked.pixbuf != null) masked.pixbuf.savev("debug_after_mask.png", "png", null, null);
                            stderr.printf("debug_main: saved debug_after_mask.png\n");
                        } catch (GLib.Error e) {
                            stderr.printf("debug_main: could not save debug_after_mask.png: %s\n", e.message);
                        }
                        final_item = masked; did_mask = true;
                    }
                } else {
                    stderr.printf("debug_main: skipping mask because source size is %d x %d\n", pw, ph);
                }
            } else {
                stderr.printf("debug_main: skipping mask because source pixbuf is null\n");
            }
        } catch (Error e) {
            stderr.printf("debug_main: mask creation failed: %s\n", e.message);
            // 失敗したらそのまま final_item を使う
        }

        // 表示設定: 中央寄せで適度なサイズ要求
        final_item.set_size_request(300, 300);
        final_item.set_halign(Gtk.Align.CENTER);
        final_item.set_valign(Gtk.Align.CENTER);
        hbox.pack_start(final_item, true, true, 0);
        // Force a redraw/show in case children changed after packing
        try {
            final_item.show_all();
            final_item.queue_draw();
            stderr.printf("debug_main: forced show_all and queue_draw on final_item\n");
        } catch (Error e) {
            stderr.printf("debug_main: show_all/queue_draw failed: %s\n", e.message);
        }

        // Add a control image (known-good PNG) to the right so we can compare
        try {
            // Create a solid opaque magenta pixbuf as a control to verify rendering
            var control_pb = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 300, 300);
            control_pb.fill((uint)0xffff00ff); // AARRGGBB -> opaque magenta
            var control = ImageItem.create_from_pixbuf(control_pb, "control", "foldergrid");
            try {
                control_pb.savev("debug_control.png", "png", null, null);
                stderr.printf("debug_main: saved debug_control.png\n");
            } catch (GLib.Error e) {
                stderr.printf("debug_main: failed to save debug_control.png: %s\n", e.message);
            }
            control.set_size_request(300, 300);
            control.set_halign(Gtk.Align.CENTER);
            control.set_valign(Gtk.Align.CENTER);
            hbox.pack_start(control, true, true, 0);
            control.show_all();
            control.queue_draw();
            stderr.printf("debug_main: added solid-color control ImageItem (magenta)\n");
        } catch (Error e) {
            stderr.printf("debug_main: failed to add control image: %s\n", e.message);
        }

        // デバッグ用: 表示している pixbuf の情報を出力してファイルに保存（小さすぎる等の判定用）
        try {
            if (final_item.pixbuf != null) {
                int pw = final_item.pixbuf.get_width();
                int ph = final_item.pixbuf.get_height();
                stderr.printf("debug_main: final pixbuf size = %d x %d, did_mask=%b\n", pw, ph, did_mask);
                try {
                    final_item.pixbuf.savev("debug_capture.png", "png", null, null);
                    // also save a scaled-up copy for human inspection if small
                    if (pw > 0 && ph > 0 && (pw < 100 || ph < 100)) {
                        var scaled = final_item.pixbuf.scale_simple(300, 300, Gdk.InterpType.NEAREST);
                        if (scaled != null) scaled.savev("debug_capture_lg.png", "png", null, null);
                    }
                    stderr.printf("debug_main: saved debug_capture.png (and debug_capture_lg.png if tiny)\n");
                } catch (GLib.Error e) {
                    stderr.printf("debug_main: failed to save debug_capture.png: %s\n", e.message);
                }
            } else {
                stderr.printf("debug_main: no pixbuf to save\n");
            }
        } catch (GLib.Error e) {
            stderr.printf("debug_main: debug save failed: %s\n", e.message);
        }
    } catch (Error e) {
        stderr.printf("test ImageItem failed: %s\n", e.message);
    }

    win.destroy.connect(() => { Gtk.main_quit(); });
    win.show_all();
    Gtk.main();
    return 0;
}
