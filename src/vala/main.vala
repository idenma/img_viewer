
using Gtk;
using Gdk;


public static int main(string[] args) {
    Gtk.init(ref args);

    string start_folder = "F:\\iCloud\\iCloudDrive\\Artist_art";
    if (args.length > 1) start_folder = args[1];

    var app = new MainWindow(start_folder);
    app.destroy.connect(() => { Gtk.main_quit(); });
    app.show_all();

    Gtk.main();
    return 0;
}

