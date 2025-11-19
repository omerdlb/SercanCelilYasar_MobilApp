import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:personaltrainer/AboutCoach/AttendanceAnalysisPage.dart';
import 'package:personaltrainer/About_User/User_Attandance_Table.dart';
import 'package:personaltrainer/About_User/User_Membership_Details.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';

import '../Tests/PerformanceTestList.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Map<String, dynamic> userDocument = {};
  String? memberId;
  String? groupName;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot document = await FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(user.uid)
            .get();

        if (document.exists) {
          setState(() {
            userDocument = document.data() as Map<String, dynamic>;
            memberId = user.uid;
            groupName = userDocument['group'];
          });
        }
      }
    } catch (e) {
      print("Hata: $e");
    }
  }



  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } catch (e) {
      print("Çıkış yaparken hata oluştu: $e");
    }
  }

  // String olarak gelen tarihi DateTime'a dönüştürme fonksiyonu
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat("dd-MM-yyyy").parse(dateString);
    } catch (e) {
      return DateTime.now(); // Hata durumunda şu anki tarihi döndür
    }
  }

  String _getMembershipStatus(Map<String, dynamic> userDocument) {
    try {
      DateTime endDate = _parseDate(userDocument['end_date']);
      DateTime now = DateTime.now();
      return endDate.isBefore(now) ? 'Sonlanmış' : 'Devam Ediyor';
    } catch (e) {
      return 'Tarih Hatası';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Üyelik Detaylarım',style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app,color: Colors.white,), onPressed: _signOut),
        ],
      ),
      body: userDocument.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
        width: double.infinity, // Tüm ekranı kaplasın
        height: double.infinity, // Tüm ekranı kaplasın
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah
              Color(0xFF9A0202), // Kırmızı
              Color(0xFFC80101), // Koyu Kırmızı
            ],
            begin: Alignment.topCenter, // Üstten başlasın
            end: Alignment.bottomCenter, // Alta doğru gitsin
          ),
        ),
            child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  userDocument['name']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 30, color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                userDocument['name'] ?? 'Ad Soyad Bulunamadı',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Üyelik Durumunuz\n',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Başlık siyah ve bold
                          ),
                        ),
                        TextSpan(
                          text: _getMembershipStatus(userDocument),
                          style: TextStyle(
                            fontSize: 16,
                            color: _getMembershipStatus(userDocument) == 'Sonlanmış' ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4, // Satırda 4 buton olacak
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1, // Kare butonlar
                  children: [
                    _buildGridButton(
                      icon: Icons.edit,
                      label: 'Üyelik Bilgilerim',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserMembershipDetails()),
                      ),
                    ),
                    _buildGridButton(
                      icon: Icons.bar_chart,
                      label: 'Ölçümlerim',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PerformanceTestList(memberId: memberId!)),
                        );
                      },
                    ),
                    _buildGridButton(
                      icon: Icons.calendar_today,
                      label: 'Yoklama Çizelgem',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserAttendanceTable()),
                      ),
                    ),
                    _buildGridButton(
                      icon: Icons.pie_chart,
                      label: 'Yoklama Analiz',
                      onTap: () {
                        if (memberId != null && groupName != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AttendanceAnalysisPage(memberId: memberId!, groupName: groupName!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grup bilgisi bulunamadı!')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
                    ),
                  ),
          ),
    );
  }

  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}