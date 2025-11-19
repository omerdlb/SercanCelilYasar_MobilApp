import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';


class UserMembershipDetails extends StatefulWidget {
  const UserMembershipDetails({super.key});

  @override
  State<UserMembershipDetails> createState() => _UserMembershipDetailsState();
}

class _UserMembershipDetailsState extends State<UserMembershipDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isIndividualLesson = false;

  @override
  void initState() {
    super.initState();
    _checkIndividualLesson();
  }

  Future<void> _checkIndividualLesson() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot snapshot = await _firestore
            .collection('bireysel_dersler')
            .where('uid', isEqualTo: user.uid)
            .get();

        setState(() {
          _isIndividualLesson = snapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print("Bireysel ders kontrolünde hata: $e");
    }
  }

  void _showLicenseInfo() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '‼️İLK DEFA LİSANS ÇIKARMAK İÇİN GEREKLİ ADIMLAR‼️',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('📌 Gençlik ve Spor Müdürlüğüne götürülmesi gereken evraklar:'),
                Text('- Sporcunun kimlik fotokopisi'),
                Text('- Lisans başvurusu yapacak ebeveynin kimlik fotokopisi'),
                Text('- 3 adet vesikalık fotoğraf'),
                Text('- Sağlık raporu (Aile hekimi veya devlet hastanesinden, "Spor içindir" ibaresi seçilmeli)'),

                SizedBox(height: 10),
                Text('📌 e-Devlet Üzerinden Yapılacak İşlemler:'),
                Text('> e-Devlet > Spor Bilgi Sistemi > Velayetim Altındaki Kişi Seçilir >'),
                Text('1️⃣ Beyan izin işlemleri > Beyan işlemleri > Beyan türü: Sağlık/Sporcu Lisans Başvuru'),
                Text('2️⃣ Veli İzni İşlemi'),

                SizedBox(height: 10),
                Text(
                  '‼️DAHA ÖNCE LİSANSI OLANLARIN YAPMASI GEREKENLER‼️',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('📌 e-Devlet Üzerinden Yapılacak İşlemler:'),
                Text('> e-Devlet > Spor Bilgi Sistemi > Velayetim Altındaki Kişi Seçilir >'),
                Text('1️⃣ Beyan izin işlemleri > Beyan işlemleri > Beyan türü: Sağlık/Sporcu Lisans Başvuru'),
                Text('2️⃣ Veli İzni İşlemi'),

                SizedBox(height: 10),
                Text('📌 Götürülmesi Gereken Evraklar:'),
                Text('- Velinin ve sporcunun kimlik fotokopisi'),
                Text('- Sporcunun 2 vesikalık fotoğrafı'),
                Text('- Lisans vize ücreti dekontu (300 TL, aşağıdaki IBAN\'a yatırılmalı)'),

                SizedBox(height: 10),
                Text(
                  '📍 Hazırladığınız evrakları aşağıdaki konuma götürerek 2025 lisansınızı çıkarabilirsiniz:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () => _launchURL('https://g.co/kgs/vD4UDws'),
                  child: Text(
                    '📍 Bornova Kapalı Spor Salonu Konumu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                SizedBox(height: 10),
                Text(
                  '💳 Lisans Ücreti IBAN Bilgisi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('TEB Bankası TL Hesabı'),
                Text('IBAN: TR32 0003 2000 0000 0135 5652 84'),
                Text('Açıklama: "Sporcu Adı Soyadı - Vize Ücreti"'),

                SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () => _copyToClipboard('TR32 0003 2000 0000 0135 5652 84'),
                  child: Text(
                    '📋 IBAN\'i Kopyala',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyToClipboard(String iban) {
    Clipboard.setData(ClipboardData(text: iban)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IBAN kopyalandı!')),
      );
    });
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Bu link açılamadı: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Üyelik Bilgileri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('uyelerim').doc(_auth.currentUser?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Üye bilgileri bulunamadı"));
          }

          var member = snapshot.data!;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0xFF9A0202),
                  Color(0xFFC80101),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 12, // Toplam kart sayısı
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _buildInfoCard(
                      icon: Icons.person,
                      label: 'Ad Soyad',
                      value: member['name']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 1:
                    return _buildInfoCard(
                      icon: Icons.cake,
                      label: 'Doğum Tarihi',
                      value: member['birthDate']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 2:
                    return _buildInfoCard(
                      icon: Icons.book,
                      label: 'Paket Bilgisi',
                      value: member['paket']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 3:
                    return _isIndividualLesson
                        ? _buildInfoCard(
                      icon: Icons.format_list_numbered,
                      label: 'Kalan Ders Sayısı',
                      value: member['lessonCount']?.toString() ?? '0',
                    )
                        : SizedBox.shrink();
                  case 4:
                    return _buildInfoCard(
                      icon: Icons.groups,
                      label: 'Ders Bilgisi',
                      value: member['group']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 5:
                    return _buildInfoCard(
                      icon: Icons.sports_martial_arts,
                      label: 'Kuşak',
                      value: member['belt']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 6:
                    return _buildInfoCard(
                      icon: Icons.badge,
                      label: 'Lisans Durumu',
                      value: member['lisans']?.toString() ?? 'Veri Yüklenemedi',
                      onInfoTap: _showLicenseInfo,
                    );
                  case 7:
                    return _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: member['email']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 8:
                    return _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Telefon Numarası',
                      value: member['phoneNumber']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 9:
                    return _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: 'Başlangıç Tarihi',
                      value: member['start_date']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 10:
                    return _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: 'Bitiş Tarihi',
                      value: member['end_date']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  default:
                    return SizedBox.shrink();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onInfoTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (onInfoTap != null)
              IconButton(
                icon: Icon(Icons.help_outline),
                onPressed: onInfoTap,
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }
}