// lib/services/patient_service.dart
// import 'dart:io'; // KALDIRILDI
import 'dart:convert'; 
// import 'package:path_provider/path_provider.dart'; // KALDIRILDI
import 'package:collection/collection.dart'; 
import 'package:intl/intl.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // YENİ EKLENDİ
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'auth_service.dart'; 

class PatientService {
  // late Directory _rootDocDir; // KALDIRILDI
  AuthService? _authService;
  final Uuid _uuid = const Uuid(); // YENİ

  Future<void> init([AuthService? authService]) async {
    // _rootDocDir = await getApplicationDocumentsDirectory(); // KALDIRILDI
    _authService = authService;
  }
  
  // YARDIMCI: Geçerli diyetisyenin kayıt anahtarını döner (Key: Diyetisyen_[KullaniciAdi]_Patients)
  String? _getCurrentUserStorageKey() {
    final currentUser = _authService?.currentUser;
    if (currentUser == null) return null;

    final safeFolderName = AuthService.createSafeFolderName(currentUser.username);
    // Verileri SharedPreferences'ta tek bir anahtar altında tutuyoruz
    return '${safeFolderName}_Patients'; 
  }
  
  // YARDIMCI: Belirli bir diyetisyenin tüm kayıtlarını yükler (SharedPreferences'tan okur)
  Future<List<PatientRecord>> _loadAllRecordsForCurrentUser() async {
    print('DEBUG _loadAllRecordsForCurrentUser BAŞLADI');
    
    final storageKey = _getCurrentUserStorageKey();
    print('DEBUG storageKey: $storageKey');
    
    if (storageKey == null) {
      print('DEBUG storageKey null, boş liste dönülüyor');
      return [];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(storageKey);
      
      print('DEBUG contents null mu: ${contents == null}');
      print('DEBUG contents empty mi: ${contents?.isEmpty}');
      
      if (contents == null || contents.isEmpty) {
        print('DEBUG contents boş, boş liste dönülüyor');
        return [];
      }
      
      print('DEBUG JSON decode ediliyor, ilk 100 karakter: ${contents.substring(0, contents.length > 100 ? 100 : contents.length)}');
      
      final List<dynamic> jsonList = jsonDecode(contents);
      print('DEBUG jsonList uzunluğu: ${jsonList.length}');
      
      final records = jsonList.map((json) => PatientRecord.fromJson(json)).toList();
      print('DEBUG PatientRecord listesine dönüştürüldü, kayıt sayısı: ${records.length}');
      
      records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
      print('DEBUG Kayıtlar tarihe göre sıralandı');
      
      return records;
    } catch (e, stackTrace) {
      print("PatientService HATA: Tüm hasta kayıtları yüklenirken hata oluştu: $e");
      print("Stack trace: $stackTrace");
      return [];
    }
  }
  
  // YARDIMCI: Tüm hastaların en son kayıtlarını listeler (PatientListScreen için)
  Future<Map<String, PatientRecord>> _loadLatestRecordsByPatient() async {
    final allRecords = await _loadAllRecordsForCurrentUser();
    final latestRecords = <String, PatientRecord>{};
    
    for (var record in allRecords) {
        if (!latestRecords.containsKey(record.patientName) || record.recordDate.isAfter(latestRecords[record.patientName]!.recordDate)) {
            latestRecords[record.patientName] = record;
        }
    }

    return latestRecords;
  }
  
  // PatientListScreen tarafından kullanılır
  Future<List<PatientRecord>> getRecordsByUserId(String userId) async {
    final latestRecordsMap = await _loadLatestRecordsByPatient();
    return latestRecordsMap.values.toList();
  }
  
  // MetabolizmaScreen'den çağrılır
  Future<List<PatientRecord>> getTrackingRecords(String patientName, String userId) async {
     final allRecords = await _loadAllRecordsForCurrentUser();
     
     // Sadece istenen hastaya ait kayıtları filtrele
     return allRecords.where((r) => r.patientName == patientName).toList();
  }
  
  // YENİDEN YAZILDI: PatientRecord'u SharedPreferences'a kaydeder (Tüm listeyi güncelleyerek)
  Future<PatientRecord> savePatientRecord(PatientRecord record) async {
    print('DEBUG savePatientRecord BAŞLADI');
    print('DEBUG patientName: ${record.patientName}');
    print('DEBUG weight: ${record.weight}');
    print('DEBUG height: ${record.height}');
    print('DEBUG chronologicalAgeInMonths: ${record.chronologicalAgeInMonths}');
    
    final storageKey = _getCurrentUserStorageKey();
    print('DEBUG storageKey: $storageKey');
    
    if (storageKey == null) throw Exception("Kayıtlı diyetisyen bulunamadı. Lütfen giriş yapın.");

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Mevcut tüm kayıtları yükle
    final allRecords = await _loadAllRecordsForCurrentUser();
    print('DEBUG Mevcut kayıt sayısı: ${allRecords.length}');
    
    // 2. Yeni kayda benzersiz ID ver
    record.recordId = _uuid.v4(); 
    print('DEBUG Yeni recordId: ${record.recordId}');
    
    // 3. Mevcut kayıt listesine ekle
    allRecords.add(record);
    print('DEBUG Kayıt eklendi, yeni toplam: ${allRecords.length}');

    // 4. Tüm listeyi JSON dizisi olarak kaydet
    final jsonList = allRecords.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(storageKey, jsonString);
    print('DEBUG SharedPreferences\'a kaydedildi');
    
    // Geri döndürülen kayıtta artık dosya yolu yerine null kalacak,
    // ancak kayıt PatientRecord içinde yerel olarak saklanmış olacak.
    return record;
  }
  
  // YENİ METOT: Belirli bir hastanın TÜM kayıtlarını siler
  Future<void> deleteAllRecordsByPatientName(String patientName) async {
    final storageKey = _getCurrentUserStorageKey();
    if (storageKey == null) throw Exception("Kayıtlı diyetisyen bulunamadı. Lütfen giriş yapın.");

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Mevcut tüm kayıtları yükle
    final allRecords = await _loadAllRecordsForCurrentUser();
    
    // 2. Silinecek hastaya ait olmayan kayıtları filtrele
    final remainingRecords = allRecords.where((r) => r.patientName != patientName).toList();

    // 3. Kalan listeyi JSON dizisi olarak kaydet
    final jsonList = remainingRecords.map((r) => r.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(jsonList));
  }

  // Artık kullanılmıyor.
  Future<void> deleteRecord(String recordId) async {
    throw UnimplementedError("Bu sistemde tekil kayıt silme desteklenmiyor.");
  }
  
  // YARDIMCI: FA Kayıt anahtarını döner (Key: Diyetisyen_[KullaniciAdi]_PheRecords)
  String? _getCurrentUserPheStorageKey() {
    final currentUser = _authService?.currentUser;
    if (currentUser == null) return null;

    final safeFolderName = AuthService.createSafeFolderName(currentUser.username);
    // Verileri SharedPreferences'ta tek bir anahtar altında tutuyoruz
    return '${safeFolderName}_PheRecords'; 
  }

  // YARDIMCI: Belirli bir diyetisyene ait tüm FA kayıtlarını yükler (SharedPreferences'tan okur)
  Future<List<PhenylalanineRecord>> _loadAllPheRecordsForCurrentUser() async {
    final storageKey = _getCurrentUserPheStorageKey();
    if (storageKey == null) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(storageKey);
      
      if (contents == null || contents.isEmpty) return [];
      
      final List<dynamic> jsonList = jsonDecode(contents);
      
      // YENİ MODELİ KULLANARAK DESERİLEŞTİRME
      final records = jsonList.map((json) => PhenylalanineRecord.fromJson(json)).toList();
      
      records.sort((a, b) => a.visitDate.compareTo(b.visitDate)); // Tarihe göre sıralı tut
      return records;
    } catch (e) {
      print("PatientService HATA: Tüm FA kayıtları yüklenirken hata oluştu: $e");
      return [];
    }
  }

  // YENİ METOT: Yeni bir FA kaydını (kan düzeyi ve vizit tarihi) kaydeder.
  Future<void> savePheRecord(String patientName, PhenylalanineRecord record) async {
    final storageKey = _getCurrentUserPheStorageKey();
    if (storageKey == null) throw Exception("Kayıtlı diyetisyen bulunamadı. Lütfen giriş yapın.");

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Mevcut tüm FA kayıtlarını yükle
    final allRecords = await _loadAllPheRecordsForCurrentUser();
    
    // 2. Aynı patientId/patientName/visitDate var mı diye kontrol et
    // Varsa güncelle, yoksa ekle
    int existingIndex = allRecords.indexWhere((r) => 
      r.patientId == record.patientId && 
      r.patientName == record.patientName && 
      r.visitDate.day == record.visitDate.day &&
      r.visitDate.month == record.visitDate.month &&
      r.visitDate.year == record.visitDate.year
    );

    if (existingIndex >= 0) {
      // Güncelle
      allRecords[existingIndex] = record;
    } else {
      // Yeni ekle
      allRecords.add(record);
    }

    // 3. Listeyi JSON dizisi olarak kaydet
    final jsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(jsonList));
  }

  // YENİ METOT: Belirli bir hastanın tüm FA kayıtlarını döner (patientId veya patientName).
  Future<List<PhenylalanineRecord>> getPheRecordsByPatientName(String patientName) async {
     final allRecords = await _loadAllPheRecordsForCurrentUser();
     
     // Önce patientId'ye göre ara, yoksa patientName'e göre ara (backward compatibility)
     var result = allRecords.where((r) => r.patientId == patientName).toList();
     if (result.isEmpty) {
       result = allRecords.where((r) => r.patientName == patientName).toList();
     }
     return result;
  }

  // YENİ METOT: FA kaydını sil (patientId, patientName, visitDate ile)
  Future<void> deletePheRecord(String patientName, String patientId, DateTime visitDate) async {
    final storageKey = _getCurrentUserPheStorageKey();
    if (storageKey == null) throw Exception("Kayıtlı diyetisyen bulunamadı. Lütfen giriş yapın.");

    final prefs = await SharedPreferences.getInstance();
    final allRecords = await _loadAllPheRecordsForCurrentUser();
    
    // Kaydı bul ve sil
    allRecords.removeWhere((r) => 
      r.patientId == patientId && 
      r.patientName == patientName && 
      r.visitDate.day == visitDate.day &&
      r.visitDate.month == visitDate.month &&
      r.visitDate.year == visitDate.year
    );

    final jsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(jsonList));
  }

  // YARDIMCI: Tirozin Kayıt anahtarını döner (Key: Diyetisyen_[KullaniciAdi]_TyrosineRecords)
  String? _getCurrentUserTyrosineStorageKey() {
    final currentUser = _authService?.currentUser;
    if (currentUser == null) return null;

    final safeFolderName = AuthService.createSafeFolderName(currentUser.username);
    return '${safeFolderName}_TyrosineRecords'; 
  }

  // YARDIMCI: Belirli bir diyetisyene ait tüm Tirozin kayıtlarını yükler
  Future<List<TyrosineRecord>> _loadAllTyrosineRecordsForCurrentUser() async {
    final storageKey = _getCurrentUserTyrosineStorageKey();
    if (storageKey == null) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(storageKey);
      
      if (contents == null || contents.isEmpty) return [];
      
      final List<dynamic> jsonList = jsonDecode(contents);
      final records = jsonList.map((json) => TyrosineRecord.fromJson(json)).toList();
      
      records.sort((a, b) => a.visitDate.compareTo(b.visitDate));
      return records;
    } catch (e) {
      print("PatientService HATA: Tüm Tirozin kayıtları yüklenirken hata oluştu: $e");
      return [];
    }
  }

  // YENİ METOT: Yeni bir Tirozin kaydını kaydeder veya günceller.
  Future<void> saveTyrosineRecord(String patientName, TyrosineRecord record) async {
    final storageKey = _getCurrentUserTyrosineStorageKey();
    if (storageKey == null) throw Exception("Kayıtlı diyetisyen bulunamadı. Lütfen giriş yapın.");

    final prefs = await SharedPreferences.getInstance();
    final allRecords = await _loadAllTyrosineRecordsForCurrentUser();
    
    // Aynı patientId/patientName/visitDate var mı diye kontrol et
    // Varsa güncelle, yoksa ekle
    int existingIndex = allRecords.indexWhere((r) => 
      r.patientId == record.patientId && 
      r.patientName == record.patientName && 
      r.visitDate.day == record.visitDate.day &&
      r.visitDate.month == record.visitDate.month &&
      r.visitDate.year == record.visitDate.year
    );

    if (existingIndex >= 0) {
      // Güncelle
      allRecords[existingIndex] = record;
    } else {
      // Yeni ekle
      allRecords.add(record);
    }

    final jsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(jsonList));
  }

  // YENİ METOT: Belirli bir hastanın tüm Tirozin kayıtlarını döner.
  Future<List<TyrosineRecord>> getTyrosineRecordsByPatientName(String patientName) async {
     final allRecords = await _loadAllTyrosineRecordsForCurrentUser();
     // Önce patientId'ye göre ara, yoksa patientName'e göre ara (backward compatibility)
     var result = allRecords.where((r) => r.patientId == patientName).toList();
     if (result.isEmpty) {
       result = allRecords.where((r) => r.patientName == patientName).toList();
     }
     return result;
  }

  // YENİ METOT: Tirozin kaydını sil (patientId, patientName, visitDate ile)
  Future<void> deleteTyrosineRecord(String patientName, String patientId, DateTime visitDate) async {
    final storageKey = _getCurrentUserTyrosineStorageKey();
    if (storageKey == null) throw Exception("Kayıtlı diyetisyen bulunamadı. Lütfen giriş yapın.");

    final prefs = await SharedPreferences.getInstance();
    final allRecords = await _loadAllTyrosineRecordsForCurrentUser();
    
    // Kaydı bul ve sil
    allRecords.removeWhere((r) => 
      r.patientId == patientId && 
      r.patientName == patientName && 
      r.visitDate.day == visitDate.day &&
      r.visitDate.month == visitDate.month &&
      r.visitDate.year == visitDate.year
    );

    final jsonList = allRecords.map((r) => r.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(jsonList));
  }

  // YENİ METOT: Belirli bir hastanın tüm PatientRecord'larını döner.
Future<List<PatientRecord>> getAllPatientRecords(String patientName) async {
   print('DEBUG getAllPatientRecords ÇAĞRILDI, patientName: $patientName');
   
   final allRecords = await _loadAllRecordsForCurrentUser();
   print('DEBUG Toplam yüklenen kayıt: ${allRecords.length}');
   
   // Sadece istenen hastaya ait kayıtları filtrele
   // NOT: PatientRecord'lar zaten en yeniden eskiye sıralanmıştı (_loadAllRecordsForCurrentUser içinde)
   final filtered = allRecords.where((r) => r.patientName == patientName).toList();
   print('DEBUG $patientName için bulunan kayıt: ${filtered.length}');
   
   for (var record in filtered) {
     print('DEBUG - RecordId: ${record.recordId}, Boy: ${record.height}, Ağırlık: ${record.weight}, Yaş(ay): ${record.chronologicalAgeInMonths}');
   }
   
   return filtered;
}
}