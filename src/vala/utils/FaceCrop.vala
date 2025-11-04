public class FaceCrop {
    // C++ で作った関数を extern で宣言
    [CCode (cname = "detect_face_and_crop")]
    public extern static bool detect_face_and_crop(string input_path, string output_path);
}

public static int main(string[] args) {
    if (args.length < 3) {
        print("Usage: FaceCrop <input> <output>\n");
        return 1;
    }

    bool ok = FaceCrop.detect_face_and_crop(args[1], args[2]);
    if (ok) {
        print("Face cropped successfully!\n");
    } else {
        print("No face detected.\n");
    }

    return 0;
}
