import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../firebase_auth_implementation/BackupService.dart';

class QrCodeGenerator extends StatefulWidget {
  const QrCodeGenerator({super.key});

  @override
  _QrCodeGeneratorState createState() => _QrCodeGeneratorState();
}

class _QrCodeGeneratorState extends State<QrCodeGenerator> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final BackupService backupService = BackupService(); // BackupService örneği

  @override
  void initState() {
    super.initState();
   // _scheduleDailyBackup(); // Zamanlayıcıyı başlat
  }

  // Her gün saat 16:55'te yedek almak için zamanlayıcı kur
  void _scheduleDailyBackup() {
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(now.year, now.month, now.day, 17, 58);

    // Eğer şu anki saat 16:55'i geçmişse, bir sonraki güne ayarla
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    // Zamanlayıcıyı kur
    Duration durationUntilScheduled = scheduledTime.difference(now);
    Future.delayed(durationUntilScheduled, () async {
      try {
        await backupService.backupData(); // Yedekleme işlemini başlat
        // Yedekleme başarılı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Veri yedekleme işlemi başarıyla tamamlandı.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Hata durumunda mesaj göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Veri yedekleme işlemi sırasında bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      _scheduleDailyBackup(); // Her gün tekrar et
    });
  }

  // Rastgele QR kodu oluşturma ve Firestore'a kaydetme fonksiyonu
  Future<void> generateRandomQrCode() async {
    final random = Random();
    String generatedData = List.generate(10, (index) => random.nextInt(10).toString()).join();

    await firestore.collection('qrcode').doc('qrCode').set({
      'data': generatedData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedBy': null, // İlk başta updatedBy boş bırakılabilir
      'membershipStatus': 'Bilinmiyor',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah (En koyu nokta)
              Color(0xFF4A0000), // Koyu kırmızımsı siyah
              Color(0xFF9A0202), // Orta kırmızı
              Color(0xFFB00000), // Daha açık kırmızı
              Color(0xFFC80101), // En açık kırmızı
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0], // Geçiş oranları
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: firestore.collection('qrcode').doc('qrCode').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('QR kod alınırken bir hata oluştu', style: TextStyle(color: Colors.white));
              } else if (snapshot.hasData && snapshot.data != null) {
                if (!snapshot.data!.exists || snapshot.data!.data() == null || snapshot.data!['data'] == null) {
                  // QR kodu yoksa yeni bir tane oluştur
                  generateRandomQrCode();
                  return const Text('QR kod oluşturuluyor...', style: TextStyle(color: Colors.white));
                }

                String qrData = snapshot.data!['data'];
                String? updatedBy = snapshot.data!.data()?['updatedBy'];
                String? endDateString = snapshot.data!.data()?['end_date'];
                String? membershipStatus = snapshot.data!.data()?['membershipStatus'];

                // Kullanıcı ismi mesajı
                String userNameMessage = updatedBy != null && updatedBy.isNotEmpty
                    ? 'Hoşgeldin, $updatedBy'
                    : 'Hoşgeldiniz';

                // Üyelik durumu rengi
                Color membershipStatusColor = (membershipStatus == 'Üyeliğiniz Devam Ediyor')
                    ? Colors.green
                    : (membershipStatus == 'Üyeliğiniz Sonlanmıştır' ? Colors.red : Colors.grey);

                String userInitial = updatedBy != null && updatedBy.isNotEmpty
                    ? updatedBy[0].toUpperCase()
                    : '?'; // Eğer kullanıcı adı yoksa varsayılan 'H' harfi

                // Tarihi formatla
                String formattedEndDate = _formatDate(endDateString);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Text(
                        userInitial,
                        style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      userNameMessage,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    // Üyelik Durumu ve Card
                    Card(
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Text(
                              'Üyelik Durumu',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              membershipStatus ?? 'Bilinmiyor',
                              style: TextStyle(fontSize: 16, color: membershipStatusColor , fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onLongPress: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: MediaQuery.of(context).size.width * 0.6,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.L,
                        errorStateBuilder: (context, error) => const Text('QR kodu görüntülenemedi'),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                );
              } else {
                return const Text('QR kod alınamadı', style: TextStyle(color: Colors.white));
              }
            },
          ),
        ),
      ),
    );
  }

  // 📌 Tarihi okunabilir bir formata çeviren fonksiyon
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'Bilinmiyor') {
      return 'Bilinmiyor';
    }
    try {
      DateTime parsedDate = DateFormat("dd-MM-yyyy").parse(dateString);
      return DateFormat("dd MMMM yyyy").format(parsedDate);
    } catch (e) {
      return 'Geçersiz Tarih';
    }
  }
}