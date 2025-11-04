[CCode (cheader_filename = "opencv_wrapper.h")]
namespace OpenCVWrapper {
    [CCode (cname = "detect_faces")]
    public int detect_faces(string image_path, string output_dir, int target_width, int target_height);
}
