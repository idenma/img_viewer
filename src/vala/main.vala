
using Gtk;
using Gdk;


public static int main(string[] args) {
    Gtk.init(ref args);

    string start_folder = "G:\\家族写真\\家族写真-2014\\1";
    if (args.length > 1) start_folder = args[1];

    var app = new MainWindow(start_folder);
    app.destroy.connect(() => { Gtk.main_quit(); });
    app.show_all();

    Gtk.main();
    return 0;
}

