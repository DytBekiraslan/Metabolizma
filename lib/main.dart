// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart'; 
// import 'package:path_provider/path_provider.dart'; // KALDIRILDI
// import 'dart:io'; // KALDIRILDI

import 'models/models.dart'; 
import 'services/auth_service.dart';
import 'services/patient_service.dart'; 
// import 'screens/login_screen.dart'; // DEVRE DIŞI - Hızlı test için
// Diğer ekran importları aynı kalır...
import 'screens/patient_list_screen.dart';
import 'screens/metabolizma_screen.dart'; 
import 'viewmodels/metabolizma_viewmodel.dart'; 
import 'services/persentil_service.dart'; // YENİ EKLENDİ


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Servisleri başlat
    final authService = AuthService();
    await authService.init();
    final persentilService = PersentilService(); // YENİ EKLENDİ
    final patientService = PatientService(); 
    // ÖNEMLİ: PatientService'e AuthService'i parametre olarak geçiyoruz
    await patientService.init(authService); 

    runApp(MyApp(
      authService: authService,
      patientService: patientService, 
      persentilService: persentilService,
    ));
  } catch (e) {
    print('Başlatma hatası: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Başlatma hatası: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final PatientService patientService; 
  final PersentilService persentilService;
  
  const MyApp({
    super.key, 
    required this.authService, 
    required this.patientService,
    required this.persentilService, // YENİ EKLENDİ
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<PatientService>.value(value: patientService), 
        ChangeNotifierProvider(create: (context) => MetabolizmaViewModel()), 
        Provider.value(value: persentilService),
      ],
      child: MaterialApp(
        title: 'Metabolizma Hesaplayıcı',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.teal.shade700, 
            foregroundColor: Colors.white, 
            centerTitle: true,
            elevation: 2,
          ),
          
          inputDecorationTheme: const InputDecorationTheme(
             border: OutlineInputBorder(),
             isDense: true,
             contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.teal.shade600, 
               foregroundColor: Colors.white,
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )
          )
        ),
        
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'), 
          Locale('en', 'US'), 
        ],
        
        // Login devre dışı - hızlı test için direkt hasta listesi
        // home: const LoginScreen(), 
        home: const PatientListScreen(), 
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}