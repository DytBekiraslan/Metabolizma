// lib/screens/fa_graph_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/models.dart';
import '../services/patient_service.dart';

class FaGraphScreen extends StatefulWidget {
  final PatientRecord patientRecord;

  const FaGraphScreen({
    super.key, 
    required this.patientRecord,
  });

  @override
  State<FaGraphScreen> createState() => _FaGraphScreenState();
}

class _FaGraphScreenState extends State<FaGraphScreen> {
  Future<List<PhenylalanineRecord>>? _pheRecordsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final patientService = Provider.of<PatientService>(context, listen: false);
    _pheRecordsFuture = patientService.getPheRecordsByPatientName(widget.patientRecord.patientName);
  }

  // Yaşa göre FA referans aralığını hesapla
  Map<String, dynamic> _getAgeAwareRange() {
    final ageInYears = widget.patientRecord.chronologicalAgeYears;

    if (ageInYears < 12) {
      return {'min': 2.0, 'max': 6.0, 'label': '0-12 yaş'};
    } else {
      return {'min': 2.0, 'max': 11.0, 'label': '12+ yaş'};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cinsiyet bazlı renk
    final isMale = widget.patientRecord.selectedGender.toLowerCase() == 'erkek';
    final genderColor = isMale ? Colors.blue : Colors.pink;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientRecord.patientName} - Kan Fenilalanin Düzeyi'),
        backgroundColor: genderColor.shade700,
      ),
      body: FutureBuilder<List<PhenylalanineRecord>>(
        future: _pheRecordsFuture,
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
                'Bu hasta için kayıtlı Fenilalanin (FA) düzeyi bulunmamaktadır.',
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
                // FA ARALIKLARI GÖSTERGE
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Normal Fenilalanin Aralıkları:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 0-12 yaş: 2-6 mg/dL ${widget.patientRecord.chronologicalAgeYears < 12 ? '✓ (Mevcut)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.patientRecord.chronologicalAgeYears < 12 ? FontWeight.bold : FontWeight.normal,
                          color: widget.patientRecord.chronologicalAgeYears < 12 ? Colors.green.shade700 : Colors.black,
                        ),
                      ),
                      Text(
                        '• 12 yaştan sonra: 2-11 mg/dL ${widget.patientRecord.chronologicalAgeYears >= 12 ? '✓ (Mevcut)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.patientRecord.chronologicalAgeYears >= 12 ? FontWeight.bold : FontWeight.normal,
                          color: widget.patientRecord.chronologicalAgeYears >= 12 ? Colors.green.shade700 : Colors.black,
                        ),
                      ),
                      const Text('• Gebeler: 2-4 mg/dL', style: TextStyle(fontSize: 12)),
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

  Widget _buildGraph(List<PhenylalanineRecord> records) {
    final minDate = records.first.visitDate;
    
    final Map<int, List<double>> sameDayValues = {};
    for (var record in records) {
      final daysSinceMin = record.visitDate.difference(minDate).inDays;
      sameDayValues.putIfAbsent(daysSinceMin, () => []);
      sameDayValues[daysSinceMin]!.add(record.pheLevel);
    }
    
    final List<FlSpot> spots = [];
    for (var record in records) {
      final dayIndex = record.visitDate.difference(minDate).inDays.toDouble();
      final dayRecordCount = sameDayValues[(dayIndex.toInt())]!.length;
      
      if (dayRecordCount > 1) {
        final recordIndexInDay = sameDayValues[(dayIndex.toInt())]!.indexOf(record.pheLevel);
        final xValue = dayIndex + (recordIndexInDay * 0.08);
        spots.add(FlSpot(xValue, record.pheLevel));
      } else {
        spots.add(FlSpot(dayIndex, record.pheLevel));
      }
    }

    final maxX = spots.isNotEmpty ? spots.last.x + 1 : 10.0;
    final intervalX = maxX > 0 ? (maxX / 5).round().toDouble() : 1.0;
    
    final maxY = (records.map((r) => r.pheLevel).reduce(max) * 1.2).ceilToDouble().clamp(10.0, double.infinity);
    final intervalY = (maxY / 5).round().toDouble();

    final ageRange = _getAgeAwareRange();
    final double faMin = ageRange['min'] as double;
    final double faMax = ageRange['max'] as double;

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
                child: Text('FA (mg/dL)', textAlign: TextAlign.center),
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
              color: Colors.deepPurple.shade600,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.deepPurple.shade900,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
            // FA İDEAL ARALIĞI - AÇIK YEŞİL ALAN (yaşa duyarlı)
            LineChartBarData(
              spots: [
                FlSpot(0, faMin), FlSpot(maxX, faMin), 
                FlSpot(0, faMax), FlSpot(maxX, faMax),
              ],
              isCurved: false,
              dashArray: [5, 5],
              color: Colors.green.shade400,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.shade200.withOpacity(0.5),
                cutOffY: faMin,
                applyCutOffY: true, 
              ),
              aboveBarData: BarAreaData(
                show: true,
                color: Colors.green.shade200.withOpacity(0.5),
                cutOffY: faMax,
                applyCutOffY: true,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final record = records[spot.spotIndex];
                  final value = record.pheLevel;
                  final diff = value - faMax;
                  final status = value < faMin ? 'DÜŞÜK' : (value > faMax ? 'YÜKSEK' : 'NORMAL');
                  final diffText = diff.abs().toStringAsFixed(2);
                  
                  return LineTooltipItem(
                    'FA: ${value.toStringAsFixed(2)} mg/dL\nAralık: ${faMin.toStringAsFixed(1)}-${faMax.toStringAsFixed(1)} mg/dL\nDurum: $status (${diff > 0 ? '+' : ''}$diffText)\nTarih: ${DateFormat('dd.MM.yyyy').format(record.visitDate)}',
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

  Widget _buildDataTable(List<PhenylalanineRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kan Fenilalanin Düzeyi/ Sonuç Tarihi  (Düzenlemek İçin Tıklayın)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
            columns: const [
              DataColumn(label: Text('Sıra', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Sonuç Tarihi', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kan Fenilalanin Düzeyi (mg/dL)', style: TextStyle(fontWeight: FontWeight.bold))),
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
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text(record.pheLevel.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
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
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _deleteRecord(PhenylalanineRecord record) {
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
                
                await patientService.deletePheRecord(
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
              decoration: const InputDecoration(labelText: 'Kan Fenilalanin Düzeyi (mg/dL)'),
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
                
                final newRecord = PhenylalanineRecord(
                  patientId: widget.patientRecord.patientName,
                  patientName: widget.patientRecord.patientName,
                  visitDate: newDate,
                  pheLevel: newValue,
                );
                
                await patientService.savePheRecord(widget.patientRecord.patientName, newRecord);

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

  void _editRecord(PhenylalanineRecord record, int index, List<PhenylalanineRecord> records) {
    final dateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(record.visitDate));
    final valueController = TextEditingController(text: record.pheLevel.toStringAsFixed(2));

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
              decoration: const InputDecoration(labelText: 'Kan Fenilalanin Düzeyi (mg/dL)'),
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
                
                await patientService.deletePheRecord(
                  widget.patientRecord.patientName,
                  record.patientId,
                  record.visitDate,
                );
                
                final updatedRecord = PhenylalanineRecord(
                  patientId: record.patientId,
                  patientName: record.patientName,
                  visitDate: newDate,
                  pheLevel: newValue,
                );
                
                await patientService.savePheRecord(widget.patientRecord.patientName, updatedRecord);

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

    final onlyDigits = text.replaceAll(RegExp(r'[^\d]'), '');

    if (onlyDigits.isEmpty) {
      return const TextEditingValue(text: '');
    }

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
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
