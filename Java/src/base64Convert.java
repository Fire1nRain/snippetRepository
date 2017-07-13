import java.util.ArrayList;

/**
 * Created by gjx-T460p on 2017/7/13.
 * 10进制数字与64进制之间的转换
 * 适用于自制短连接生成器
 */
public class base64Convert {

    /**
     * 64进制使用的符号的列表
     */
    private static final char[] base64Map = "abcdefghijklmnopqrstuvwxyz-0123456789+ABCDEFGHIJKLMNOPQRSTUVWXYZ".toCharArray();

    /**
     * 转换回10进制时使用的映射，根据base64Map生成，用于去除额外的循环
     */
    private static final long[] base10Map = {
            0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L,
            0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L,
            0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 37L, 0L, 26L, 0L, 0L,
            27L, 28L, 29L, 30L, 31L, 32L, 33L, 34L, 35L, 36L, 0L, 0L, 0L, 0L, 0L,
            0L, 0L, 38L, 39L, 40L, 41L, 42L, 43L, 44L, 45L, 46L, 47L, 48L, 49L, 50L,
            51L, 52L, 53L, 54L, 55L, 56L, 57L, 58L, 59L, 60L, 61L, 62L, 63L, 0L,
            0L, 0L, 0L, 0L, 0L, 0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L,
            12L, 13L, 14L, 15L, 16L, 17L, 18L, 19L, 20L, 21L, 22L, 23L, 24L, 25L,
    };

    /**
     * 从十进制转换为64进制的方法
     * 使用了对位的操作来加快运算速度
     * TODO 是否有比StringBuilder.reverse().toString()更快的方法来产生目标字符串？
     *
     * @param l 待转换的10进制数
     * @return 转换后的64进制字符串
     */
    public static String toBase64(long l) {
        StringBuilder base64 = new StringBuilder();
        int n;
        while (l > 0) {
            n = (int) (l & 63L); //取低6位
            base64.append(base64Map[n]);//取出对应位置的字符并加入StringBuilder中
            l = l >> 6;//向右位移6位
        }
        return base64.reverse().toString();
    }

    /**
     * 从64进制转换回10进制的方法
     * 同样使用了对位的操作
     * TODO 同样的，toCharArray()是否有更快的替代方法？
     * TODO 更改为Java 1.8的Stream模式是否能加快速度？
     *
     * @param b64 待转换的64进制字符串
     * @return 转换后的10进制数
     */
    public static long toBase10(String b64) {
        long l = 0L;
        for (char c : b64.toCharArray())
            l = (l << 6) | base10Map[c];
        return l;
    }


    public static void main(String[] args) {
        long l = 1234567890123L;
        String b = toBase64(l);
        long l2 = toBase10(b);
        System.out.println("base10:" + l);
        System.out.println("Convert to base64:" + b);
        System.out.println("Back to base10:" + l2);
//        generateBase10Map();
    }


    private static String generateBase10Map() {
        StringBuilder map = new StringBuilder();
        ArrayList<Long> longs = new ArrayList<>();
        for (int i = 0; i < 123; i++)
            longs.add(0L);
        for (int i = 0; i < base64Map.length; i++) {
            longs.set(base64Map[i], (long) i);
            System.out.println("letter " + base64Map[i] + " is mapped to " + i + " at " + (int) base64Map[i]);
        }
        for (Long l : longs)
            map.append(l).append("L,");
        return map.substring(0, map.length() - 1);
    }
}
