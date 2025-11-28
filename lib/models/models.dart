// lib/models/models.dart
import 'package:flutter/material.dart'; // Sadece UniqueKey için tutuluyor, kaldırılabilir
import 'package:intl/intl.dart'; 
import 'dart:convert'; 
// import 'package:hive/hive.dart'; // KALDIRILDI
// import 'package:uuid/uuid.dart'; // AuthService ve PatientService kullanıyor

// --- KULLANICI VE HASTA TAKİP MODELLERİ (Dosya Tabanlı -> Web/SharedPreferences Uyumlu) ---

class User { 
  String username;
  String passwordHash; 
  String userId; 

  // GÜNCELLENDİ: userId artık kurucudan alınıyor veya atanıyor
  User({required this.username, required this.passwordHash, required this.userId});
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'] as String,
    passwordHash: json['passwordHash'] as String,
    userId: json['userId'] as String, // ID'yi JSON'dan al
  );
}
//// GÜNCELLENMİŞ PatientRecord sınıfı
class PatientRecord {
  String? recordId;
  final String ownerUserId;
  final String patientName;
  final DateTime recordDate;
  String recordDataJson;
  String? pdfFilePath;
  String? jsonFilePath;

  // YENİ EKLENEN ALANLAR: Grafikler ve Listeleme İçin Temel Veriler
  final double weight;
  final String selectedGender;
  final int chronologicalAgeInMonths;
  final int chronologicalAgeYears;
  final int chronologicalAgeMonths;
  final int neyziHeightAgeInMonths;
  final int whoHeightAgeInMonths;
  
  // Büyüme Gelişme Değerlendirmesi Verileri
  final String neyziWeightPercentile;
  final String whoWeightPercentile;
  final String neyziHeightPercentile;
  final String whoHeightPercentile;
  final String neyziBmiPercentile;
  final String whoBmiPercentile;
  final String neyziHeightAgeStatus;
  final String whoHeightAgeStatus;
  final double height;

  PatientRecord({
    this.recordId,
    required this.ownerUserId,
    required this.patientName,
    required this.recordDate,
    required this.recordDataJson,
    this.pdfFilePath,
    this.jsonFilePath,
    // YENİ ZORUNLU PARAMETRELER
    required this.weight,
    required this.selectedGender,
    required this.chronologicalAgeInMonths,
    required this.chronologicalAgeYears,
    required this.chronologicalAgeMonths,
    this.neyziHeightAgeInMonths = -1,
    this.whoHeightAgeInMonths = -1,
    // Büyüme Gelişme Verileri
    this.neyziWeightPercentile = '-',
    this.whoWeightPercentile = '-',
    this.neyziHeightPercentile = '-',
    this.whoHeightPercentile = '-',
    this.neyziBmiPercentile = '-',
    this.whoBmiPercentile = '-',
    this.neyziHeightAgeStatus = '-',
    this.whoHeightAgeStatus = '-',
    this.height = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'ownerUserId': ownerUserId,
        'patientName': patientName,
        'recordDate': recordDate.toIso8601String(),
        'recordDataJson': recordDataJson,
        'pdfFilePath': pdfFilePath,
        'jsonFilePath': jsonFilePath,
        // YENİ SERİLEŞTİRME
        'weight': weight,
        'selectedGender': selectedGender,
        'chronologicalAgeInMonths': chronologicalAgeInMonths,
        'chronologicalAgeYears': chronologicalAgeYears,
        'chronologicalAgeMonths': chronologicalAgeMonths,
        // Büyüme Gelişme Verileri
        'neyziWeightPercentile': neyziWeightPercentile,
        'whoWeightPercentile': whoWeightPercentile,
        'neyziHeightPercentile': neyziHeightPercentile,
        'whoHeightPercentile': whoHeightPercentile,
        'neyziBmiPercentile': neyziBmiPercentile,
        'whoBmiPercentile': whoBmiPercentile,
        'neyziHeightAgeStatus': neyziHeightAgeStatus,
        'whoHeightAgeStatus': whoHeightAgeStatus,
        'height': height,
        'neyziHeightAgeInMonths': neyziHeightAgeInMonths,
        'whoHeightAgeInMonths': whoHeightAgeInMonths,
      };

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    // Güvenli okuma
    final weight = (json['weight'] as num?)?.toDouble() ?? 0.0;
    final selectedGender = json['selectedGender'] as String? ?? 'Erkek';
    final chronoAgeInMonths = json['chronologicalAgeInMonths'] as int? ?? 0;
    final chronoAgeYears = json['chronologicalAgeYears'] as int? ?? 0;
    final chronoAgeMonths = json['chronologicalAgeMonths'] as int? ?? 0;
    
    // Büyüme Gelişme Verileri
    final neyziWeightPercentile = json['neyziWeightPercentile'] as String? ?? '-';
    final whoWeightPercentile = json['whoWeightPercentile'] as String? ?? '-';
    final neyziHeightPercentile = json['neyziHeightPercentile'] as String? ?? '-';
    final whoHeightPercentile = json['whoHeightPercentile'] as String? ?? '-';
    final neyziBmiPercentile = json['neyziBmiPercentile'] as String? ?? '-';
    final whoBmiPercentile = json['whoBmiPercentile'] as String? ?? '-';
    final neyziHeightAgeStatus = json['neyziHeightAgeStatus'] as String? ?? '-';
    final whoHeightAgeStatus = json['whoHeightAgeStatus'] as String? ?? '-';
    final height = (json['height'] as num?)?.toDouble() ?? 0.0;
    final neyziHeightAgeInMonths = json['neyziHeightAgeInMonths'] as int? ?? -1;
    final whoHeightAgeInMonths = json['whoHeightAgeInMonths'] as int? ?? -1;

    return PatientRecord(
      recordId: json['recordId'] as String?,
      ownerUserId: json['ownerUserId'] as String,
      patientName: json['patientName'] as String,
      recordDate: DateTime.parse(json['recordDate']),
      recordDataJson: json['recordDataJson'] as String,
      pdfFilePath: json['pdfFilePath'] as String?,
      jsonFilePath: json['jsonFilePath'] as String?,
      // YENİ PARAMETRELERİN ATANMASI
      weight: weight,
      selectedGender: selectedGender,
      chronologicalAgeInMonths: chronoAgeInMonths,
      chronologicalAgeYears: chronoAgeYears,
      chronologicalAgeMonths: chronoAgeMonths,
      // Büyüme Gelişme Verileri
      neyziWeightPercentile: neyziWeightPercentile,
      whoWeightPercentile: whoWeightPercentile,
      neyziHeightPercentile: neyziHeightPercentile,
      whoHeightPercentile: whoHeightPercentile,
      neyziBmiPercentile: neyziBmiPercentile,
      whoBmiPercentile: whoBmiPercentile,
      neyziHeightAgeStatus: neyziHeightAgeStatus,
      whoHeightAgeStatus: whoHeightAgeStatus,
      height: height,
      neyziHeightAgeInMonths: neyziHeightAgeInMonths,
      whoHeightAgeInMonths: whoHeightAgeInMonths,
    );
  }
}
class BesinVerisi {
  final double fenilalaninDegeri;
  final double proteinDegeri;
  final double enerjiDegeri;

  BesinVerisi({
    required this.fenilalaninDegeri,
    required this.proteinDegeri,
    required this.enerjiDegeri,
  });
}

class DraggableFoodData {
  final String labelName;
  final String displayName;
  final BesinVerisi baseValues;
  final int customFoodIndex;

  DraggableFoodData({
    required this.labelName,
    required this.displayName,
    required this.baseValues,
    required this.customFoodIndex,
  });
}

class DraggableInputRowData {
  final int sourceRowIndex;
  final String foodName;
  final String currentAmountText;

  DraggableInputRowData({
    required this.sourceRowIndex,
    required this.foodName,
    required this.currentAmountText,
  });
}

class MealEntry {
  final int sourceRowIndex;
  final String foodName;
  final double assignedAmount;
  final UniqueKey id = UniqueKey();

  MealEntry({
    required this.sourceRowIndex,
    required this.foodName,
    required this.assignedAmount,
  });

  @override
  String toString() {
    final format = NumberFormat("0.##", "tr_TR"); 
    return "$foodName (${format.format(assignedAmount)})";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class FoodRowState {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController(text: "0");
  final TextEditingController energyController = TextEditingController(text: "0.00");
  final TextEditingController proteinController = TextEditingController(text: "0.00");
  final TextEditingController pheController = TextEditingController(text: "0.00");

  BesinVerisi? originalValues;
  String? originalLabelName;
  
  double initialAmount = 0.0;
  double initialEnergy = 0.0;
  double initialProtein = 0.0;
  double initialPhe = 0.0;

  void dispose() {
    amountController.dispose();
    nameController.dispose();
    energyController.dispose();
    proteinController.dispose();
    pheController.dispose();
  }

  void clear() {
    nameController.text = "";
    amountController.text = "0";
    originalValues = null;
    originalLabelName = null;
    clearCalculatedValues();
    clearInitialValues();
  }

  void clearCalculatedValues() {
    energyController.text = "0.00";
    proteinController.text = "0.00";
    pheController.text = "0.00";
  }

  void clearInitialValues() {
    initialAmount = 0.0;
    initialEnergy = 0.0;
    initialProtein = 0.0;
    initialPhe = 0.0;
  }
}

class CustomFood {
  String name;
  double protein;
  double fa; 
  double enerji;
  final bool isDefault;

  CustomFood({
    required this.name,
    required this.protein,
    required this.fa,
    required this.enerji,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name, 'protein': protein, 'fa': fa, 'enerji': enerji, 'isDefault': isDefault,
      };

  factory CustomFood.fromJson(Map<String, dynamic> json) => CustomFood(
        name: json['name'] as String,
        protein: (json['protein'] as num).toDouble(),
        fa: (json['fa'] as num).toDouble(),
        enerji: (json['enerji'] as num).toDouble(),
        isDefault: json['isDefault'] ?? false,
      );

  static String encode(List<CustomFood> foods) => json.encode(
        foods.map<Map<String, dynamic>>((food) => food.toJson()).toList(),
      );

  static List<CustomFood> decode(String foodsString) {
    if (foodsString.isEmpty) return [];
    try {
      return (json.decode(foodsString) as List<dynamic>)
          .map<CustomFood>((item) => CustomFood.fromJson(item))
          .toList();
    } catch (e) {
      print("CustomFood decode hatasi: $e");
      return [];
    }
  }
}

class ReferenceRequirementFKU {
  final String ageGroup;
  final String pheRange;
  final String tyrosineRange;
  final String proteinRange;
  final String energyRange;
  final String fluidRange;
  final int index;

  const ReferenceRequirementFKU({
    required this.ageGroup,
    required this.pheRange,
    required this.tyrosineRange,
    required this.proteinRange,
    required this.energyRange,
    required this.fluidRange,
    required this.index,
  });
}

class CustomMealSection {
  final String name;
  List<MealEntry> entries = [];
  final UniqueKey id = UniqueKey();

  CustomMealSection(this.name);

   @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomMealSection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MealPlanItem {
  final String name;
  final dynamic reference; 
  final bool isCustom;

  MealPlanItem({required this.name, required this.reference, required this.isCustom});
}

enum PercentileSource { current, who, neyzi,manual }

enum WeightSource {
  manual, 
  whoPercentile, 
  neyziPercentile, 
  current,
}

enum EnergySource {
  doctor,
  fku,
  practical,
  bmhFafBge, 
}

class PercentileData {
  final int ageInMonths; 
  final String gender;
  final double percentile3;
  final double percentile10;
  final double percentile25;
  final double percentile50;
  final double percentile75;
  final double percentile90;
  final double percentile97;
  final double percentile5; 
  final double percentile95; 

  const PercentileData({
    required this.ageInMonths,
    required this.gender,
    required this.percentile3,
    required this.percentile10,
    required this.percentile25,
    required this.percentile50,
    required this.percentile75,
    required this.percentile90,
    required this.percentile97,
    this.percentile5 = 0.0, 
    this.percentile95 = 0.0,
  });

  List<double> get neyziPercentiles => [
    percentile3, percentile10, percentile25, percentile50, percentile75, percentile90, percentile97
  ];

  double getWeightByPercentile(double percentile) {
    if (percentile == 3) return percentile3;
    if (percentile == 5) return percentile5;
    if (percentile == 10) return percentile10;
    if (percentile == 25) return percentile25;
    if (percentile == 50) return percentile50;
    if (percentile == 75) return percentile75;
    if (percentile == 90) return percentile90;
    if (percentile == 95) return percentile95;
    if (percentile == 97) return percentile97;
    return percentile50; 
  }
}


class LengthPercentileData {
  final int ageInMonths;
  final String gender;
  final double percentile3;
  final double percentile10;
  final double percentile25;
  final double percentile50;
  final double percentile75;
  final double percentile90;
  final double percentile97;

  const LengthPercentileData({
    required this.ageInMonths,
    required this.gender,
    required this.percentile3,
    required this.percentile10,
    required this.percentile25,
    required this.percentile50,
    required this.percentile75,
    required this.percentile90,
    required this.percentile97,
  });

  List<double> get percentiles => [
    percentile3, percentile10, percentile25, percentile50, percentile75, percentile90, percentile97
  ];
  
  double getHeightByPercentile(double percentile) {
    if (percentile == 3) return percentile3;
    if (percentile == 10) return percentile10;
    if (percentile == 25) return percentile25;
    if (percentile == 50) return percentile50;
    if (percentile == 75) return percentile75;
    if (percentile == 90) return percentile90;
    if (percentile == 97) return percentile97;
    return 0.0;
  }
}

class BMIPercentileData {
  final int ageInMonths;
  final String gender;
  final double percentile3;
  final double percentile10;
  final double percentile25;
  final double percentile50;
  final double percentile75;
  final double percentile90;
  final double percentile97;

  const BMIPercentileData({
    required this.ageInMonths,
    required this.gender,
    required this.percentile3,
    required this.percentile10,
    required this.percentile25,
    required this.percentile50,
    required this.percentile75,
    required this.percentile90,
    required this.percentile97,
  });

  List<double> get percentiles => [
    percentile3, percentile10, percentile25, percentile50, percentile75, percentile90, percentile97
  ];
  
  double getBMIByPercentile(double percentile) {
    if (percentile == 3) return percentile3;
    if (percentile == 10) return percentile10;
    if (percentile == 25) return percentile25;
    if (percentile == 50) return percentile50;
    if (percentile == 75) return percentile75;
    if (percentile == 90) return percentile90;
    if (percentile == 97) return percentile97;
    return 0.0;
  }
}


class CalculatedPercentiles {
  final String weightPercentile;
  final String heightPercentile;
  final String bmiPercentile;
  
  // CSV-based: Neyzi and WHO separate
  final String neyziWeightPercentile;
  final String whoWeightPercentile;
  final String neyziHeightPercentile;
  final String whoHeightPercentile;
  final String neyziBmiPercentile;
  final String whoBmiPercentile;
  
  // Boy yaşı durumu (Neyzi ve WHO ayrı ayrı)
  final String neyziHeightAgeStatus;
  final String whoHeightAgeStatus;

  CalculatedPercentiles({
    this.weightPercentile = '-',
    this.heightPercentile = '-',
    this.bmiPercentile = '-',
    this.neyziWeightPercentile = '-',
    this.whoWeightPercentile = '-',
    this.neyziHeightPercentile = '-',
    this.whoHeightPercentile = '-',
    this.neyziBmiPercentile = '-',
    this.whoBmiPercentile = '-',
    this.neyziHeightAgeStatus = 'Kronolojik Yaş Kullanıldı',
    this.whoHeightAgeStatus = 'Kronolojik Yaş Kullanıldı',
  });
}
class PhenylalanineRecord {
  final String patientId; // Yeni: Hasta ID'si (patientName'den bağımsız)
  final String patientName;
  final DateTime visitDate;
  final double pheLevel; // mg/dL

  PhenylalanineRecord({required this.patientId, required this.patientName, required this.visitDate, required this.pheLevel});

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'patientName': patientName,
        'visitDate': visitDate.toIso8601String(),
        'pheLevel': pheLevel,
      };

  factory PhenylalanineRecord.fromJson(Map<String, dynamic> json) {
      // YENİ: Alanlar null ise varsayılan/güvenli bir değer atayarak type cast hatasını önlüyoruz.
      final String safePatientId = (json['patientId'] as String?) ?? 'unknown';
      final String safePatientName = (json['patientName'] as String?) ?? 'Bilinmeyen Hasta';
      final double safePheLevel = (json['pheLevel'] as num?)?.toDouble() ?? 0.0;
      
      // Tarihi parse etmeden önce null kontrolü yapıyoruz.
      final String? dateString = json['visitDate'] as String?;
      final DateTime safeVisitDate = (dateString != null && dateString.isNotEmpty) 
                                     ? DateTime.tryParse(dateString) ?? DateTime(2000)
                                     : DateTime(2000); // Varsayılan güvenli tarih

      return PhenylalanineRecord(
        patientId: safePatientId,
        patientName: safePatientName,
        visitDate: safeVisitDate,
        pheLevel: safePheLevel,
      );
  }
}

class TyrosineRecord {
  final String patientId; // Yeni: Hasta ID'si (patientName'den bağımsız)
  final String patientName;
  final DateTime visitDate;
  final double tyrosineLevel; // mg/dL

  TyrosineRecord({required this.patientId, required this.patientName, required this.visitDate, required this.tyrosineLevel});

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'patientName': patientName,
        'visitDate': visitDate.toIso8601String(),
        'tyrosineLevel': tyrosineLevel,
      };

  factory TyrosineRecord.fromJson(Map<String, dynamic> json) {
      final String safePatientId = (json['patientId'] as String?) ?? 'unknown';
      final String safePatientName = (json['patientName'] as String?) ?? 'Bilinmeyen Hasta';
      final double safeTyrosineLevel = (json['tyrosineLevel'] as num?)?.toDouble() ?? 0.0;
      
      final String? dateString = json['visitDate'] as String?;
      final DateTime safeVisitDate = (dateString != null && dateString.isNotEmpty) 
                                     ? DateTime.tryParse(dateString) ?? DateTime(2000)
                                     : DateTime(2000);

      return TyrosineRecord(
        patientId: safePatientId,
        patientName: safePatientName,
        visitDate: safeVisitDate,
        tyrosineLevel: safeTyrosineLevel,
      );
  }
}