// lib/screens/tyrosine_graph_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/models.dart';
import '../services/patient_service.dart';

class TyrosineGraphScreen extends StatefulWidget {
  final PatientRecord patientRecord;

  const TyrosineGraphScreen({
    super.key, 
    required this.patientRecord,
  });

  @override
  State<TyrosineGraphScreen> createState() => _TyrosineGraphScreenState();
}

class _TyrosineGraphScreenState extends State<TyrosineGraphScreen> {
  Future<List<TyrosineRecord>>? _tyrosineRecordsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final patientService = Provider.of<PatientService>(context, listen: false);
    _tyrosineRecordsFuture = patientService.getTyrosineRecordsByPatientName(widget.patientRecord.patientName);
  }

  // Yaşa göre Tirozin referans aralığını hesapla
  Map<String, dynamic> _getAgeAwareRange() {
    final ageInYears = widget.patientRecord.chronologicalAgeYears;

    // Yaşa göre aralık
    if (ageInYears < 12) {
      return {'min': 80.0, 'max': 210.0, 'label': '0-12 yaş'};
    } else {
      return {'min': 60.0, 'max': 170.0, 'label': '12+ yaş'};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cinsiyet bazlı renk
    final isMale = widget.patientRecord.selectedGender.toLowerCase() == 'erkek';
    final genderColor = isMale ? Colors.blue : Colors.pink;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientRecord.patientName} - Kan Tirozin Düzeyi'),
        backgroundColor: genderColor.shade700,
      ),
      body: FutureBuilder<List<TyrosineRecord>>(
        future: _tyrosineRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Veri yüklenirken hata oluştu: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'Bu hasta için kayıtlı Tirozin düzeyi bulunmamaktadır.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Hasta bilgilerini hesapla
          final chronoAgeMonths = widget.patientRecord.chronologicalAgeInMonths;
          final chronoAgeYears = widget.patientRecord.chronologicalAgeYears;
          final chronoAgeRemainingMonths = widget.patientRecord.chronologicalAgeMonths;
          final weight = widget.patientRecord.weight;
          final height = widget.patientRecord.height;
          final gender = widget.patientRecord.selectedGender;
          
          // BMI hesapla
          double bmi = 0;
          if (height > 0 && weight > 0) {
            double heightInMeters = height / 100.0;
            bmi = weight / (heightInMeters * heightInMeters);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hasta bilgileri kartı
                Card(
                  elevation: 4,
                  color: genderColor.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientRecord.patientName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoBox('Yaş', '$chronoAgeYears yıl $chronoAgeRemainingMonths ay\n($chronoAgeMonths ay)', Icons.cake),
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
                // TİROZİN ARALIKLARI GÖSTERGE
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Normal Tirozin Aralıkları:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 0-12 yaş: 80-210 µmol/L ${widget.patientRecord.chronologicalAgeYears < 12 ? '✓ (Mevcut)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.patientRecord.chronologicalAgeYears < 12 ? FontWeight.bold : FontWeight.normal,
                          color: widget.patientRecord.chronologicalAgeYears < 12 ? Colors.blue.shade700 : Colors.black,
                        ),
                      ),
                      Text(
                        '• 12 yaştan sonra: 60-170 µmol/L ${widget.patientRecord.chronologicalAgeYears >= 12 ? '✓ (Mevcut)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.patientRecord.chronologicalAgeYears >= 12 ? FontWeight.bold : FontWeight.normal,
                          color: widget.patientRecord.chronologicalAgeYears >= 12 ? Colors.blue.shade700 : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildGraph(records),
                const SizedBox(height: 30),
                _buildDataTable(records),
              ],
            ),
          );
        },
      ),
    );
  }

  // Grafik Oluşturma Metodu
  Widget _buildGraph(List<TyrosineRecord> records) {
    final minDate = records.first.visitDate;
    
    // Aynı gün içindeki ölçümleri gruplayıp dikey çizgi olarak düzenle
    final Map<int, List<double>> sameDayValues = {};
    for (var record in records) {
      final daysSinceMin = record.visitDate.difference(minDate).inDays;
      sameDayValues.putIfAbsent(daysSinceMin, () => []);
      sameDayValues[daysSinceMin]!.add(record.tyrosineLevel);
    }
    
    // Aynı günde birden fazla ölçüm varsa x ekseninde biraz kaydır (dikey çizgi efekti için)
    final List<FlSpot> spots = [];
    for (var record in records) {
      final dayIndex = record.visitDate.difference(minDate).inDays.toDouble();
      final dayRecordCount = sameDayValues[(dayIndex.toInt())]!.length;
      
      if (dayRecordCount > 1) {
        // Aynı günde birden fazla var - küçük x offset ekle
        final recordIndexInDay = sameDayValues[(dayIndex.toInt())]!.indexOf(record.tyrosineLevel);
        final xValue = dayIndex + (recordIndexInDay * 0.08);
        spots.add(FlSpot(xValue, record.tyrosineLevel));
      } else {
        // Tek ölçüm
        spots.add(FlSpot(dayIndex, record.tyrosineLevel));
      }
    }

    final maxX = spots.isNotEmpty ? spots.last.x + 1 : 10.0;
    final intervalX = maxX > 0 ? (maxX / 5).round().toDouble() : 1.0;
    
    final maxY = (records.map((r) => r.tyrosineLevel).reduce(max) * 1.2).ceilToDouble().clamp(10.0, double.infinity);
    final intervalY = (maxY / 5).round().toDouble();

    // TİROZİN ARALIKLARI (yaşa göre)
    final ageRange = _getAgeAwareRange();
    final double tyrosineMin = ageRange['min'] as double;
    final double tyrosineMax = ageRange['max'] as double;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: intervalX > 0 ? intervalX : 1,
                getTitlesWidget: (value, meta) {
                  final date = minDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat('dd.MM.yy').format(date), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Tirozin (mg/dL)', textAlign: TextAlign.center),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: intervalY > 0 ? intervalY : 1,
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.blue.shade600,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.blue.shade900,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
            // TİROZİN İDEAL ARALIĞI (dinamik yaşa göre hesaplanan) - AÇIK YEŞİL ALAN
            LineChartBarData(
              spots: [
                FlSpot(0, tyrosineMin), FlSpot(maxX, tyrosineMin), 
                FlSpot(0, tyrosineMax), FlSpot(maxX, tyrosineMax),
              ],
              isCurved: false,
              dashArray: [5, 5],
              color: Colors.green.shade400,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.shade200.withOpacity(0.5),
                cutOffY: tyrosineMin,
                applyCutOffY: true, 
              ),
              aboveBarData: BarAreaData(
                show: true,
                color: Colors.green.shade200.withOpacity(0.5),
                cutOffY: tyrosineMax,
                applyCutOffY: true,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final record = records[spot.spotIndex];
                  final value = record.tyrosineLevel;
                  final diff = value - tyrosineMax;
                  final status = value < tyrosineMin ? 'DÜŞÜK' : (value > tyrosineMax ? 'YÜKSEK' : 'NORMAL');
                  final diffText = diff.abs().toStringAsFixed(2);
                  
                  return LineTooltipItem(
                    'Tirozin: ${value.toStringAsFixed(2)} µmol/L\nAralık: ${tyrosineMin.toStringAsFixed(1)}-${tyrosineMax.toStringAsFixed(1)} µmol/L\nDurum: $status (${diff > 0 ? '+' : ''}$diffText)\nTarih: ${DateFormat('dd.MM.yyyy').format(record.visitDate)}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Veri Tablosu Oluşturma Metodu
  Widget _buildDataTable(List<TyrosineRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kan Tirozin Düzeyi/ Sonuç Tarihi  (Düzenlemek İçin Tıklayın)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
            columns: const [
              DataColumn(label: Text('Sıra', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Sonuç Tarihi', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kan Tirozin Düzeyi (mg/dL)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('İşlem', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: records.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text((index + 1).toString())),
                  DataCell(
                    GestureDetector(
                      onTap: () => _editRecord(record, index, records),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(DateFormat('dd.MM.yyyy').format(record.visitDate), style: TextStyle(color: Colors.blue.shade700)),
                      ),
                    ),
                  ),
                  DataCell(
                    GestureDetector(
                      onTap: () => _editRecord(record, index, records),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.cyan.shade200),
                        ),
                        child: Text(record.tyrosineLevel.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan.shade700)),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Sil',
                      onPressed: () => _deleteRecord(record),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _addNewRecord(),
            icon: const Icon(Icons.add),
            label: const Text('Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _deleteRecord(TyrosineRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu kaydı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final patientService = Provider.of<PatientService>(context, listen: false);
                
                await patientService.deleteTyrosineRecord(
                  widget.patientRecord.patientName,
                  record.patientId,
                  record.visitDate,
                );

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _loadData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt silindi'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewRecord() {
    final dateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(DateTime.now()));
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Vizit Verisi Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              inputFormatters: [
                _DateInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Tarihi (gg.aa.yyyy)',
                hintText: 'Geçmiş tarihleri de ekleyebilirsiniz',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kan Tirozin Düzeyi (µmol/L)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (dateController.text.isEmpty || valueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurunuz'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                final newDate = DateFormat('dd.MM.yyyy').parse(dateController.text);
                final newValue = double.parse(valueController.text.replaceAll(',', '.'));

                final patientService = Provider.of<PatientService>(context, listen: false);
                
                final newRecord = TyrosineRecord(
                  patientId: widget.patientRecord.patientName,
                  patientName: widget.patientRecord.patientName,
                  visitDate: newDate,
                  tyrosineLevel: newValue,
                );
                
                await patientService.saveTyrosineRecord(widget.patientRecord.patientName, newRecord);

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _loadData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt eklendi'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _editRecord(TyrosineRecord record, int index, List<TyrosineRecord> records) {
    final dateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(record.visitDate));
    final valueController = TextEditingController(text: record.tyrosineLevel.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vizit Verisini Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              inputFormatters: [
                _DateInputFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Tarihi (gg.aa.yyyy)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kan Tirozin Düzeyi (mg/dL)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newDate = DateFormat('dd.MM.yyyy').parse(dateController.text);
                final newValue = double.parse(valueController.text.replaceAll(',', '.'));

                final patientService = Provider.of<PatientService>(context, listen: false);
                
                // 1. Eski kaydı sil (eski tarih ile)
                await patientService.deleteTyrosineRecord(
                  widget.patientRecord.patientName,
                  record.patientId,
                  record.visitDate,
                );
                
                // 2. Yeni kaydı ekle (yeni tarih ile)
                final updatedRecord = TyrosineRecord(
                  patientId: record.patientId,
                  patientName: record.patientName,
                  visitDate: newDate,
                  tyrosineLevel: newValue,
                );
                
                await patientService.saveTyrosineRecord(widget.patientRecord.patientName, updatedRecord);

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _loadData();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veriler kaydedildi'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
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

// Otomatik nokta ekleyen date formatter
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Sadece rakam ve noktaları tut
    final onlyDigits = text.replaceAll(RegExp(r'[^\d]'), '');

    if (onlyDigits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Formatla: gg.aa.yyyy
    String formatted = '';
    if (onlyDigits.length >= 1) {
      formatted += onlyDigits.substring(0, 1);
    }
    if (onlyDigits.length >= 2) {
      formatted += onlyDigits.substring(1, 2);
    }
    if (onlyDigits.length >= 3) {
      formatted += '.' + onlyDigits.substring(2, 3);
    }
    if (onlyDigits.length >= 4) {
      formatted += onlyDigits.substring(3, 4);
    }
    if (onlyDigits.length >= 5) {
      formatted += '.' + onlyDigits.substring(4);
    } else if (onlyDigits.length >= 5) {
      formatted += onlyDigits.substring(4);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
