// 線形合同法(LCG)による簡易乱数ジェネレータ
public class RandomGenerator {
    // 内部状態（0 を避ける）
    private static uint64 state = 88172645463325252;
    private static bool seeded = false;

    // LCG パラメータ（64bit 環境向けの定数）
    private const uint64 A = 6364136223846793005;
    private const uint64 C = 1442695040888963407;

    // アプリ起動時に自動で現在時刻をシードとして設定（マイクロ秒精度）
    static construct {
        seed_now();
    }

    // 現在時刻（real_time, monotonic_time）からシードを作る
    public static void seed_now () {
        // get_real_time / get_monotonic_time はマイクロ秒
        uint64 t1 = (uint64) GLib.get_real_time();
        uint64 t2 = (uint64) GLib.get_monotonic_time();
        // 簡単なミックス
        uint64 s = (t1 << 1) ^ (t2 << 3) ^ (t1 >> 17) ^ (t2 >> 29);
    seed(s);
    }

    // シードを設定（0 は避ける）
    public static void seed (uint64 s) {
        state = (s == 0UL) ? 1UL : s;
    seeded = true;
    }

    // 内部状態を進めて 64bit 乱数を返す
    private static uint64 next_u64 () {
        if (!seeded) {
            // 念のため初回使用時にも自動シード
            seed_now();
        }
        // 演算は uint64 (= 64bit) でオーバーフローを許容（2^64 で剰余）
        state = A * state + C;
        return state;
    }

    // 32bit 値を返す（上位32ビットを採る）
    public static uint next_u32 () {
        return (uint)(next_u64() >> 32);
    }

    // a,b の範囲（inclusive）で乱数を返す
    public static int between (int a, int b) {
        int min = (a < b) ? a : b;
        int max = (a < b) ? b : a;
        if (min == max) return min;

        // 範囲幅（uint64 経由）
        uint64 range = (uint64)max - (uint64)min + 1UL;
        if (range == 0UL) return min;

        // 32bit 乱数を使ってレンジに縮小
        uint64 r = (uint64) next_u32();
        uint64 v = r % range;
        return (int)((uint64)min + v);
    }

    // 0..1 未満の実数を返す（必要なら）
    public static double next_double () {
        // 53bit 精度を得るため上位53ビットを利用
        uint64 v = next_u64() >> 11; // 64-53 = 11
        return (double)v / 9007199254740992.0; // 2^53
    }
}
