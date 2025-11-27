void main() {
  final testValues = [
    'P25-P50 Arası',
    'P3-P10 Arası',
    'P50-P75 Arası',
    'P10-P25 Arası',
  ];
  
  for (final value in testValues) {
    print('\nTest: "$value"');
    final matches = RegExp(r'P(\d+)').allMatches(value).toList();
    print('  Matches bulundu: ${matches.length}');
    
    if (matches.length >= 2) {
      final lower = int.parse(matches[0].group(1)!);
      final upper = int.parse(matches[1].group(1)!);
      print('  İlk persentil (lower): P$lower');
      print('  İkinci persentil (upper): P$upper');
      
      final percentilePositions = {
        3: 0.125,
        10: 0.25,
        25: 0.375,
        50: 0.5,
        75: 0.625,
        90: 0.75,
        97: 0.875,
      };
      
      final lowerPos = percentilePositions[lower];
      final upperPos = percentilePositions[upper];
      
      if (lowerPos != null && upperPos != null) {
        final position = (lowerPos + upperPos) / 2;
        print('  lowerPos: $lowerPos');
        print('  upperPos: $upperPos');
        print('  Hesaplanan pozisyon: $position');
      }
    }
  }
}
