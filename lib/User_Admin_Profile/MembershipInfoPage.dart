import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../AboutCoach/CoachEditMembersİnfo.dart';

class MembershipInfoPage extends StatefulWidget {
  final QueryDocumentSnapshot member;

  const MembershipInfoPage({super.key, required this.member});

  @override
  State<MembershipInfoPage> createState() => _MembershipInfoPageState();
}

class _MembershipInfoPageState extends State<MembershipInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isIndividualLesson = false;

  bool isAdmin = false;
  bool isHelperCoach = false;
  bool canUpdateMembership = false;
  bool _isExcused = false; // Yeni eklenen alan


  Future<void> _checkIndividualLesson() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bireysel_dersler')
          .where('uid', isEqualTo: widget.member.id)
          .get();

      setState(() {
        _isIndividualLesson = snapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print("Bireysel ders kontrolünde hata: $e");
    }
  }

  Future<void> checkUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        setState(() {
          // Admin kontrolü
          isAdmin = adminDoc.exists && adminDoc.data() != null
              ? (adminDoc.data() as Map<String, dynamic>)['admin'] == true
              : false;

          if (isAdmin) {
            // Admin ise tüm yetkileri ver
            isHelperCoach = false;
            canUpdateMembership = true;
          } else {
            // Admin değilse helper coach ve yetkilerini kontrol et
            isHelperCoach = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['helpercoach'] == true
                : false;
            canUpdateMembership = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canUpdateMembership'] == true
                : false;
          }
        });
      } catch (e) {
        print("Rol kontrolünde hata: $e");
        setState(() {
          isAdmin = false;
          isHelperCoach = false;
          canUpdateMembership = false;
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        isHelperCoach = false;
        canUpdateMembership = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIndividualLesson();
    checkUserRole().then((_) {
      setState(() {}); // Roller yüklendikten sonra UI'ı güncelle
    });
    _loadExcusedStatus(); // İzinli durumunu yükle
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
        actions: [
          if (isAdmin || (isHelperCoach && canUpdateMembership)) // Admin veya yetkili helper coach ise göster
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoachEditMembersInfo(memberId: widget.member.id),
                    ),
                  );
                } else if (value == 'toggleExcused') {
                  _toggleExcusedStatus();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Text('Verileri Güncelle'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggleExcused',
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Text(_isExcused ? 'İzni Kaldır' : 'İzinli Olarak Ayarla'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Container(
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
        child: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('uyelerim').doc(widget.member.id).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('Veri bulunamadı.'));
            }

            var memberData = snapshot.data!.data() as Map<String, dynamic>;

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 11,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _buildInfoCard(
                      icon: Icons.person,
                      label: 'Ad Soyad',
                      value: memberData['name']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 1:
                    return _buildInfoCard(
                      icon: Icons.cake,
                      label: 'Doğum Tarihi',
                      value: memberData['birthDate']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 2:
                    return _buildInfoCard(
                      icon: Icons.book,
                      label: 'Paket Bilgisi',
                      value: memberData['paket']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 3:
                    return _isIndividualLesson
                        ? _buildInfoCard(
                      icon: Icons.format_list_numbered,
                      label: 'Kalan Ders Sayısı',
                      value: memberData['lessonCount']?.toString() ?? '0',
                    )
                        : SizedBox.shrink();
                  case 4:
                    return _buildInfoCard(
                      icon: Icons.groups,
                      label: 'Grup',
                      value: memberData['group']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 5:
                    return _buildInfoCard(
                      icon: Icons.sports_martial_arts,
                      label: 'Kuşak',
                      value: memberData['belt']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 6:
                    return _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: memberData['email']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 7:
                    return _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Telefon Numarası',
                      value: memberData['phoneNumber']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 8:
                    return _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: 'Başlangıç Tarihi',
                      value: memberData['start_date']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  case 9:
                    return _buildInfoCard(
                      icon: Icons.calendar_today,
                      label: 'Bitiş Tarihi',
                      value: memberData['end_date']?.toString() ?? 'Veri Yüklenemedi',
                    );
                  default:
                    return SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.9),
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
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }


  // Yeni eklenen fonksiyon
  Future<void> _toggleExcusedStatus() async {
    final memberRef = _firestore.collection('uyelerim').doc(widget.member.id);
    final memberDoc = await memberRef.get();

    if (memberDoc.exists) {
      final currentExcused = memberDoc.data()?['excused'] as bool? ?? false;
      final newExcused = !currentExcused;

      await memberRef.update({'excused': newExcused});
      setState(() {
        _isExcused = newExcused;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isExcused ? 'Üye izinli olarak ayarlandı.' : 'Üye izinli olarak kaldırıldı.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // İzinli durumunu yükle
  Future<void> _loadExcusedStatus() async {
    try {
      final memberDoc = await _firestore.collection('uyelerim').doc(widget.member.id).get();
      if (memberDoc.exists) {
        setState(() {
          _isExcused = memberDoc.data()?['excused'] as bool? ?? false;
        });
      }
    } catch (e) {
      print('İzinli durumu yüklenirken hata: $e');
    }
  }
}
