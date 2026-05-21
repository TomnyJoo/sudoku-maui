import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sudoku/services/generation/progress_utils.dart';
import 'package:sudoku/services/statistics/statistics.dart';

/// 图表工具类
class ChartUtils {
  /// 创建时间分布图表
  static BarChart createTimeDistributionChart(
    Map<String, int> timeDistribution,
  ) {
    final data = timeDistribution.entries.map((entry) => BarChartGroupData(
        x: timeDistribution.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      )).toList();

    return BarChart(
      BarChartData(
        barGroups: data,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < timeDistribution.keys.length) {
                  final label = timeDistribution.keys.toList()[index];
                  // 提取数字部分，如从 "0-1分钟" 提取 "0"
                  final numericPart = label.replaceAll(RegExp('[^0-9-+]'), '');
                  final parts = numericPart.split('-'); // 提取起始值
                  final startValue = parts.isNotEmpty ? parts[0] : '';
                  // 只显示起始值
                  return Text(
                    startValue,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
            axisNameWidget: const Text('m', style: TextStyle(fontSize: 10)),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(),
      ),
    );
  }

  /// 创建技能曲线图表
  static LineChart createSkillCurveChart(
    List<GameRecord> games,
  ) {
    if (games.isEmpty) {
      return LineChart(LineChartData());
    }

    // 按时间排序
    final sortedGames = [...games]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final spots = sortedGames.asMap().entries.map((entry) {
      final index = entry.key;
      final game = entry.value;
      return FlSpot(index.toDouble(), game.time.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Colors.red,
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            axisNameWidget: const Text('s', style: TextStyle(fontSize: 10)),
          ),
        ),
      ),
    );
  }

  /// 创建错误模式图表
  static PieChart createErrorPatternChart(
    Map<int, int> errorPatterns,
  ) {
    final data = errorPatterns.entries.map((entry) => PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.key.toString(),
        color: Colors.primaries[entry.key % Colors.primaries.length],
      )).toList();

    return PieChart(
      PieChartData(
        sections: data,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  /// 创建难度分布图表
  static BarChart createDifficultyDistributionChart(
    BuildContext context,
    Map<String, DifficultyStats> difficultyStats,
  ) {
    final data = difficultyStats.entries.map((entry) => BarChartGroupData(
        x: difficultyStats.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value.completedGames.toDouble(),
            color: Colors.green,
            width: 20,
            borderRadius: BorderRadius.zero,
          ),
        ],
      )).toList();

    return BarChart(
      BarChartData(
        barGroups: data,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < difficultyStats.keys.length) {
                  final difficulty = difficultyStats.keys.toList()[index];
                  return Text(
                    GameUtils.getLocalizedDifficultyName(context, difficulty),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(),
      ),
    );
  }
}
