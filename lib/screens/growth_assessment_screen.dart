import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/persentil_data.dart';
import 'growth_chart_screen.dart';

class GrowthAssessmentScreen extends StatefulWidget {
  final PatientRecord patient;

  const GrowthAssessmentScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<GrowthAssessmentScreen> createState() => _GrowthAssessmentScreenState();
}

class _GrowthAssessmentScreenState extends State<GrowthAssessmentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ageInMonths = widget.patient.chronologicalAgeInMonths;
    final chronoAgeYears = widget.patient.chronologicalAgeYears;
    final chronoAgeRemainingMonths = widget.patient.chronologicalAgeMonths;
    final weight = widget.patient.weight;
    final height = widget.patient.height;
    final gender = widget.patient.selectedGender;
    
    // Cinsiyet bazlı renk
    final isMale = gender.toLowerCase() == 'erkek';
    final genderColor = isMale ? Colors.blue : Colors.pink;
    
    // BMI hesapla
    double bmi = 0;
    if (height > 0 && weight > 0) {
      double heightInMeters = height / 100.0;
      bmi = weight / (heightInMeters * heightInMeters);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Büyüme Gelişme Değerlendirmesi'),
        backgroundColor: genderColor.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hasta bilgileri kartı (Büyüme grafiği ile aynı stil)
            Card(
              elevation: 4,
              color: genderColor.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.patientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoBox('Yaş', '$chronoAgeYears yıl $chronoAgeRemainingMonths ay\n($ageInMonths ay)', Icons.cake),
                        _buildInfoBox('Cinsiyet', gender, Icons.person),
                        _buildInfoBox('Boy', height > 0 ? '${height.toStringAsFixed(1)} cm' : '-', Icons.height),
                        _buildInfoBox('Ağırlık', weight > 0 ? '${weight.toStringAsFixed(1)} kg' : '-', Icons.monitor_weight),
                        _buildInfoBox('BKİ', bmi > 0 ? bmi.toStringAsFixed(1) : '-', Icons.analytics),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Büyüme ve Gelişme Değerlendirmesi Başlığı
          
            // Ağırlık Persentili
            Row(
              children: [
                Expanded(
                  child: _buildPercentileBox(
                    'Ağırlık Persentili\nNEYZİ',
                    widget.patient.neyziWeightPercentile,
                    Colors.orange,
                    chartType: 'neyzi_weight',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPercentileBox(
                    'Ağırlık Persentili\nWHO',
                    widget.patient.chronologicalAgeInMonths > 120
                        ? '10 yaşından büyük çocuklar\niçin BKİ kullanınız'
                        : widget.patient.whoWeightPercentile,
                    Colors.blue,
                    chartType: 'who_weight',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Boy Persentili
            Row(
              children: [
                Expanded(
                  child: _buildPercentileBox(
                    'Boy Persentili\nNEYZİ',
                    widget.patient.neyziHeightPercentile,
                    Colors.orange,
                    chartType: 'neyzi_height',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPercentileBox(
                    'Boy Persentili\nWHO',
                    widget.patient.whoHeightPercentile,
                    Colors.blue,
                    chartType: 'who_height',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // BMI Persentili
            Row(
              children: [
                Expanded(
                  child: _buildPercentileBox(
                    'BKİ Persentili\nNEYZİ',
                    widget.patient.neyziBmiPercentile,
                    Colors.orange,
                    chartType: 'neyzi_bmi',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPercentileBox(
                    'BKİ Persentili\nWHO',
                    widget.patient.whoBmiPercentile,
                    Colors.blue,
                    chartType: 'who_bmi',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Boy Yaşı Durumu
            Row(
              children: [
                Expanded(
                  child: _buildPercentileBox(
                    'Boy Yaşı Durumu\nNEYZİ',
                    widget.patient.neyziHeightAgeStatus,
                    Colors.orange,
                    chartType: 'neyzi_height',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPercentileBox(
                    'Boy Yaşı Durumu\nWHO',
                    widget.patient.whoHeightAgeStatus,
                    Colors.blue,
                    chartType: 'who_height',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentileBox(String title, String value, Color borderColor, {String? chartType}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: borderColor, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              if (chartType != null)
                Tooltip(
                  message: 'Grafiği açmak için tıklayın',
                  waitDuration: const Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GrowthChartScreen(
                            patient: widget.patient,
                            initialChartType: chartType,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.show_chart,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildPercentileValues(title, borderColor, value),
        ],
      ),
    );
  }

  Widget _buildPercentileValues(String title, Color borderColor, String value) {
    // Hangi tip persentil olduğunu belirle
    late final String dataType;
    late final String source;
    
    if (title.contains('Ağırlık Persentili')) {
      dataType = 'weight';
      source = title.contains('Neyzi') ? 'neyzi' : 'who';
    } else if (title.contains('Boy Persentili')) {
      dataType = 'height';
      source = title.contains('Neyzi') ? 'neyzi' : 'who';
    } else if (title.contains('Boy Yaşı Durumu')) {
      dataType = 'height';
      source = title.contains('Neyzi') ? 'neyzi' : 'who';
    } else if (title.contains('BKİ Persentili')) {
      dataType = 'bmi';
      source = title.contains('Neyzi') ? 'neyzi' : 'who';
    } else {
      return const SizedBox.shrink();
    }

    final ageInMonths = widget.patient.chronologicalAgeInMonths;
    final gender = widget.patient.selectedGender;
    
    if (gender.isEmpty || ageInMonths < 0) {
      return const SizedBox.shrink();
    }

    int referenceAgeInMonths = ageInMonths;
    String? heightAgeLabel;
    if (title.contains('Boy Yaşı Durumu')) {
      final bool useNeyzi = title.contains('NEYZİ');
      final int heightAgeMonths = useNeyzi
          ? widget.patient.neyziHeightAgeInMonths
          : widget.patient.whoHeightAgeInMonths;
      if (heightAgeMonths > -1) {
        referenceAgeInMonths = heightAgeMonths;
        heightAgeLabel = 'Boy Yaşı: ${heightAgeMonths} Ay';
      }
    }

    return FutureBuilder<Map<String, double>>(
      future: _getPercentileValuesFromCSV(source, dataType, gender, referenceAgeInMonths),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final values = snapshot.data!;
        
        // Birimi belirle
        String unit = '';
        if (dataType == 'weight') {
          unit = 'kg';
        } else if (dataType == 'height') {
          unit = 'cm';
        } else if (dataType == 'bmi') {
          unit = 'kg/m²';
        }
        
        return Column(
          children: [
            if (value.isNotEmpty && value != '-') ...[
              const SizedBox(height: 8),
              // Topuz + İğne birlikte (Stack ile konumlandırılmış)
              _buildScalePointer(value),
              const SizedBox(height: 4),
            ],
            if (heightAgeLabel != null) ...[
              Text(
                heightAgeLabel,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            // Kantar skalası (persentil değerleri)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Persentil etiketleri satırı (% ile başlayan)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Text(
                          '%',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _buildPercentileLabel('P3'),
                      _buildPercentileLabel('P10'),
                      _buildPercentileLabel('P25'),
                      _buildPercentileLabel('P50'),
                      _buildPercentileLabel('P75'),
                      _buildPercentileLabel('P90'),
                      _buildPercentileLabel('P97'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Persentil değerleri satırı (birim ile başlayan)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Text(
                          unit,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _buildPercentileValue(values['p3'] ?? 0),
                      _buildPercentileValue(values['p10'] ?? 0),
                      _buildPercentileValue(values['p25'] ?? 0),
                      _buildPercentileValue(values['p50'] ?? 0),
                      _buildPercentileValue(values['p75'] ?? 0),
                      _buildPercentileValue(values['p90'] ?? 0),
                      _buildPercentileValue(values['p97'] ?? 0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPercentileLabel(String label) {
    return Expanded(
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPercentileValue(double value) {
    return Expanded(
      child: Text(
        value > 0 ? value.toStringAsFixed(1) : '-',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildScalePointer(String value) {
    // Cetvel pozisyonları: [%, P3, P10, P25, P50, P75, P90, P97]
    // Pozisyon (0-1):      0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875
    
    double position = 0.5; // Varsayılan: ortada
    
    // P<3 veya P3'ün Altında - gösterge P3'ün solunda (% ile P3 arasında)
    if (value.contains('P<3') || value.contains('< P3') || 
        (value.contains('P3') && (value.contains('Altında') || value.contains('altında')))) {
      position = 0.0625; // % ile P3 arasının ortası (0 + 0.125) / 2
    } 
    // P>97 veya P97'nin Üzerinde - gösterge P97'nin sağında
    else if (value.contains('P>97') || value.contains('> P97') || 
             (value.contains('P97') && (value.contains('Üzerinde') || value.contains('üzerinde')))) {
      position = 0.9375; // P97'nin sağında (0.875 + 1.0) / 2
    } 
    // "P25-P50 Arası" gibi iki persentil arası durumlar
    else if (value.contains('P') && value.contains('Arası')) {
      final matches = RegExp(r'P(\d+)').allMatches(value).toList();
      if (matches.length >= 2) {
        final lower = int.parse(matches[0].group(1)!);
        final upper = int.parse(matches[1].group(1)!);
        
        // Cetvel üzerinde persentillerin pozisyonlarını bul
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
          position = (lowerPos + upperPos) / 2; // İki persentil arasının tam ortası
        }
      }
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Topuz ve iğnenin birlikte hareket etmesi için pozisyon hesapla
        final pointerLeft = constraints.maxWidth * (0.125 + position * 0.875);
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: 40, // Topuz + iğne için yeterli alan
            ),
            // Topuz ve iğne birlikte konumlandırılmış
            Positioned(
              left: pointerLeft - 30, // Topuz merkezi için ayarlama (yaklaşık yarı genişlik)
              top: 0,
              child: SizedBox(
                width: 60, // Topuz genişliği
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Topuz (kantarın üst kısmı - persentil aralığı yazısı)
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    // İğne (▼)
                    const Text(
                      '▼',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> _getPercentileValuesFromCSV(String source, String dataType, String gender, int ageInMonths) async {
    try {
      List<dynamic> sourceData;
      if (source == 'who') {
        if (dataType == 'weight') {
          sourceData = gender == 'Erkek' ? PersentilData.whoErkekAgirlik : PersentilData.whoKadinAgirlik;
        } else if (dataType == 'height') {
          sourceData = gender == 'Erkek' ? PersentilData.whoErkekBoy : PersentilData.whoKadinBoy;
        } else {
          sourceData = gender == 'Erkek' ? PersentilData.whoErkekBmi : PersentilData.whoKadinBmi;
        }
      } else {
        if (dataType == 'weight') {
          sourceData = gender == 'Erkek' ? PersentilData.neyziErkekAgirlik : PersentilData.neyziKadinAgirlik;
        } else if (dataType == 'height') {
          sourceData = gender == 'Erkek' ? PersentilData.neyziErkekBoy : PersentilData.neyziKadinBoy;
        } else {
          sourceData = gender == 'Erkek' ? PersentilData.neyziErkekBmi : PersentilData.neyziKadinBmi;
        }
      }

      if (sourceData.isEmpty) return {};

      for (final item in sourceData) {
        if (item.ageInMonths == ageInMonths) {
          return {
            'p3': item.percentile3 as double,
            'p10': item.percentile10 as double,
            'p25': item.percentile25 as double,
            'p50': item.percentile50 as double,
            'p75': item.percentile75 as double,
            'p90': item.percentile90 as double,
            'p97': item.percentile97 as double,
          };
        }
      }

      int minDifference = 999999;
      dynamic closestData;

      for (final item in sourceData) {
        final difference = (item.ageInMonths - ageInMonths).abs();
        if (difference < minDifference) {
          minDifference = difference;
          closestData = item;
        } else if (difference == minDifference && item.ageInMonths > ageInMonths) {
          closestData = item;
        }
      }

      if (closestData != null) {
        return {
          'p3': closestData.percentile3 as double,
          'p10': closestData.percentile10 as double,
          'p25': closestData.percentile25 as double,
          'p50': closestData.percentile50 as double,
          'p75': closestData.percentile75 as double,
          'p90': closestData.percentile90 as double,
          'p97': closestData.percentile97 as double,
        };
      }
    } catch (e) {
      print('Error loading percentile values: $e');
    }
    return {};
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    );
  }
}
