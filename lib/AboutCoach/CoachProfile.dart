import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';
import 'package:personaltrainer/AboutCoach/AddTrainerPage.dart';
import 'package:personaltrainer/AboutCoach/TrainerListPage.dart';
import 'package:personaltrainer/AboutCoach/BirthdayTrackingPage.dart';

import 'Uyelik_Talebi_Page.dart';

class CoachProfilePage extends StatefulWidget {
  const CoachProfilePage({super.key});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isAdmin = false;
  bool isHelperCoach = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<QuerySnapshot> _requestsFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _firestore
        .collection('coach')
        .doc('talepler')
        .collection('requests')
        .get(); // Fetch initial list of requests
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        setState(() {
          // Doküman varsa ve alanlar mevcutsa değerleri al, yoksa false olarak ayarla
          isAdmin = adminDoc.exists && adminDoc.data() != null
              ? (adminDoc.data() as Map<String, dynamic>)['admin'] == true
              : false;

          isHelperCoach = adminDoc.exists && adminDoc.data() != null
              ? (adminDoc.data() as Map<String, dynamic>)['helpercoach'] == true
              : false;
        });
      } catch (e) {
        print("Rol kontrolünde hata: $e");
        setState(() {
          isAdmin = false;
          isHelperCoach = false;
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        isHelperCoach = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Profilim', style: TextStyle(color: Colors.white)),
        actions: [
          // Yenileme butonu
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _requestsFuture = _firestore
                    .collection('coach')
                    .doc('talepler')
                    .collection('requests')
                    .get();
              });
            },
          ),
          // Şifre sıfırlama butonu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'reset_password') {
                _showResetPasswordDialog();
              } else if (value == 'add_trainer' && isAdmin) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTrainerPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              if (isAdmin) // Sadece admin ise antrenör ekleme seçeneğini göster
                PopupMenuItem<String>(
                  value: 'add_trainer',
                  child: Text("Antrenör Ekle"),
                ),
              PopupMenuItem<String>(
                value: 'reset_password',
                child: Text("Şifremi Sıfırla"),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah
              Color(0xFF9A0202), // Kırmızı
              Color(0xFFC80101), // Koyu Kırmızı
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Profil bilgileri yükleniyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lütfen bekleyiniz',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Text(
                    _getInitials(),
                    style: TextStyle(fontSize: 40, color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? 'Email Bulunamadı',
                style: TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Divider(
                color: Colors.white,
                thickness: 1,
                height: 10,
              ),
              SizedBox(height: 15),
              
              // Doğum Günü Takip Butonu
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BirthdayTrackingPage()),
                    );
                  },
                  icon: Icon(Icons.cake, color: Colors.black),
                  label: Text(
                    "🎂 Doğum Günü Takip",
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              
              SizedBox(height: 15),
              Divider(
                color: Colors.white,
                thickness: 1,
                height: 10,
              ),
              SizedBox(height: 15),
              
              // Görüşme talepleri başlığı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Görüşme Talepleri',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // Görüşme talepleri listesi
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Görüşme talepleri yükleniyor...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Lütfen bekleyiniz',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                          child: Text(
                            'Talep yok.',
                            style: TextStyle(color: Colors.white),
                          ));
                    }

                    var requests = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        var request = requests[index].data() as Map<String, dynamic>; // Güvenli casting
                        String userName = request.containsKey('userName') ? request['userName'] : 'Bilinmeyen Kullanıcı';
                        String courseTitle = request.containsKey('courseTitle') ? request['courseTitle'] : 'Bilinmeyen Kurs';
                        String coachName = request.containsKey('coachName') ? request['coachName'] : 'Bilinmeyen Eğitmen';

                        var requestDoc = requests[index]; // DocumentSnapshot olarak al
                        String requestId = requestDoc.id; // Belge ID'sini al

                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(
                              userName,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            subtitle: Text(
                              "$courseTitle\n$coachName",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRequest(requestId), // Doğru ID'yi gönder
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              if (isAdmin && !isHelperCoach)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => UyelikTalebiPage()),
                                );
                              },
                              icon: Icon(Icons.group_add, color: Colors.black),
                              label: Text(
                                "Üyelik Talepleri",
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TrainerListPage()),
                                );
                              },
                              icon: Icon(Icons.people, color: Colors.black),
                              label: Text(
                                "Antrenörler",
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Çıkış yap butonu
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: Icon(Icons.logout, color: Colors.black),
                  label: Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    String email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Çıkış yaparken hata oluştu: $e");
    }
  }

  // Silme işlemi
  void _deleteRequest(String requestId) async {
    try {
      await _firestore
          .collection('coach')
          .doc('talepler')
          .collection('requests')
          .doc(requestId)
          .delete();

      // Başarılı silme sonrası SnackBar ile kullanıcıya bilgi veriyoruz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talep silindi!')),
      );

      // Listeyi güncellemek için setState çağırıyoruz
      setState(() {
        // Yine veriyi çekmek için Future'ı tekrar başlatıyoruz
        _requestsFuture = _firestore
            .collection('coach')
            .doc('talepler')
            .collection('requests')
            .get();
      });
    } catch (e) {
      print("Silme işlemi sırasında hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme işlemi başarısız oldu')),
      );
    }
  }

  void _showResetPasswordDialog() {
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Şifre Sıfırlama"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifreyi Doğrula',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
              },
              child: Text("Vazgeç", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () async {
                String newPassword = newPasswordController.text.trim();
                String confirmPassword = confirmPasswordController.text.trim();

                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Şifreler eşleşmiyor.")),
                  );
                  return;
                }

                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.updatePassword(newPassword);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Şifre başarıyla güncellendi. Lütfen tekrar giriş yapın.",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await FirebaseAuth.instance.signOut(); // Oturumu kapat
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  print("Şifre güncelleme hatası: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Şifre güncelleme sırasında bir hata oluştu.",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Kaydet", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

}