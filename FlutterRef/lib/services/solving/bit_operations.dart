/// 位操作工具类
/// 
/// 提供各种位操作相关的工具方法，用于高效处理候选数掩码
class BitOperations {
  /// 计算位数量
  static int countBits(int bits) {
    bits = bits - ((bits >> 1) & 0x55555555);
    bits = (bits & 0x33333333) + ((bits >> 2) & 0x33333333);
    bits = (bits + (bits >> 4)) & 0x0F0F0F0F;
    bits = bits + (bits >> 8);
    bits = bits + (bits >> 16);
    return bits & 0x3F;
  }

  /// 获取最低位对应的值
  static int getLowestBitValue(int mask) {
    if (mask == 0) return 0;
    return (mask & -mask).bitLength;
  }

  /// 获取最高位对应的值
  static int getHighestBitValue(int mask) {
    if (mask == 0) return 0;
    return mask.bitLength;
  }

  /// 将位掩码转换为 Set< int >
  static Set<int> maskToSet(int mask) {
    final set = <int>{};
    int m = mask;
    int num = 1;
    while (m != 0) {
      if ((m & 1) != 0) {
        set.add(num);
      }
      m >>= 1;
      num++;
    }
    return set;
  }

  /// 获取单个值（如果掩码只有一位）
  static int? getSingleValue(int mask) {
    if (countBits(mask) != 1) return null;
    for (int i = 1; i <= 9; i++) {
      if ((mask & (1 << (i - 1))) != 0) {
        return i;
      }
    }
    return null;
  }

  /// 快速计算最小和
  static int calculateMinSumBitwise(List<int> masks, int usedMask) {
    int sum = 0;
    for (final mask in masks) {
      final available = mask & ~usedMask;
      if (available == 0) return 1000; // 不可能
      sum += getLowestBitValue(available);
    }
    return sum;
  }

  /// 快速计算最大和
  static int calculateMaxSumBitwise(List<int> masks, int usedMask) {
    int sum = 0;
    for (final mask in masks) {
      final available = mask & ~usedMask;
      if (available == 0) return -1; // 不可能
      sum += getHighestBitValue(available);
    }
    return sum;
  }
}
