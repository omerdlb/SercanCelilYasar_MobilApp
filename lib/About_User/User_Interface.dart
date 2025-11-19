import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:personaltrainer/About_User/AboutUsPage.dart';
import 'package:personaltrainer/About_User/PoomsePage.dart';
import 'package:personaltrainer/About_User/User_BeltExam_Register.dart';
import 'package:personaltrainer/About_User/User_Profile_Page.dart';
import 'package:personaltrainer/About_User/User_Order_Equipment_Page.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({super.key});

  @override
  _UserInterfaceState createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isIndividualLesson = false;
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  StreamSubscription<User?>? _authStateSubscription; // Auth state listener için

  DateTime selectedDate = DateTime.now();
  String? userId;
  Map<DateTime, List<Map<String, dynamic>>> cachedLessons = {};
  List<Map<String, dynamic>> groupLessons = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _fetchGroupLessons();
    _checkIndividualLesson();
    _getGroupLessonsForUser();
    _checkFirstTimeLogin();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkFirstTimeLogin() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('uyelerim').doc(user.uid).get();
        if (userDoc.exists) {
          bool isFirstTime = (userDoc.data() as Map<String, dynamic>?)?['isFirstTime'] ?? false;
          if (isFirstTime) {
            // İlk giriş yapan kullanıcı için dialog göster
            if (mounted) {
              _showFirstTimeLoginDialog();
            }
          }
        }
      }
    } catch (e) {
      print("İlk giriş kontrolünde hata: $e");
    }
  }

  Future<void> _showFirstTimeLoginDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF4A0000), Color(0xFF9A0202)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.security, size: 40, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Güvenlik Güncellemesi',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Güvenliğiniz için lütfen email adresinizi ve şifrenizi değiştirin.',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.all(15),
                      child: Column(
                        children: [
                          TextField(
                            controller: _newEmailController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Yeni Email Adresi',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'ornek@email.com',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.email, color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 15),
                          TextField(
                            controller: _currentPasswordController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Mevcut Şifre',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Şu anki şifrenizi girin',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 15),
                          TextField(
                            controller: _newPasswordController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Yeni Şifre',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'En az 6 karakter',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.lock, color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 15),
                          TextField(
                            controller: _confirmPasswordController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Yeni Şifre (Tekrar)',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: 'Yeni şifrenizi tekrar girin',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.lock, color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    // --- Button Row for Güncelle and İptal ---
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_validateInputs()) {
                                  try {
                                    User? user = _auth.currentUser;
                                    if (user != null) {
                                      print('Mevcut kullanıcı email: ${user.email}');
                                      await _auth.signOut();
                                      print('Mevcut oturum kapatıldı');

                                      try {
                                        print('Yeni oturum açma denemesi başlıyor...');
                                        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                                          email: user.email!,
                                          password: _currentPasswordController.text,
                                        );

                                        user = userCredential.user;
                                        if (user != null) {
                                          print('Kimlik doğrulama başarılı');
                                          await user.updatePassword(_newPasswordController.text);
                                          print('Şifre değiştirme başarılı');
                                          await user.verifyBeforeUpdateEmail(_newEmailController.text);
                                          print('Email doğrulama linki gönderildi');

                                          await _firestore.collection('uyelerim').doc(user.uid).update({
                                            'email': _newEmailController.text,
                                            'isFirstTime': false,
                                            'emailVerified': false,
                                          });
                                          print('Firestore email güncellendi');

                                          if (mounted) {
                                            Navigator.of(context).pop();
                                            _showVerificationLinkDialog(user);
                                          }
                                        }
                                      } on FirebaseAuthException catch (e) {
                                        print('Kimlik doğrulama hatası: ${e.code} - ${e.message}');
                                        String errorMessage;

                                        switch (e.code) {
                                          case 'invalid-credential':
                                          case 'wrong-password':
                                            errorMessage = 'Mevcut şifreniz yanlış. Lütfen tekrar deneyin.';
                                            break;
                                          case 'user-disabled':
                                            errorMessage = 'Hesabınız devre dışı bırakılmış.';
                                            break;
                                          case 'user-not-found':
                                            errorMessage = 'Kullanıcı bulunamadı.';
                                            break;
                                          case 'too-many-requests':
                                            errorMessage = 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
                                            break;
                                          case 'email-already-in-use':
                                            errorMessage = 'Bu email adresi zaten kullanımda.';
                                            break;
                                          case 'invalid-email':
                                            errorMessage = 'Geçersiz email adresi.';
                                            break;
                                          case 'requires-recent-login':
                                            errorMessage = 'Güvenlik nedeniyle tekrar giriş yapmanız gerekiyor.';
                                            break;
                                          default:
                                            errorMessage = 'Kimlik doğrulama hatası: ${e.message}';
                                        }

                                        await _auth.signOut();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(errorMessage),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 5),
                                            ),
                                          );
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (context) => LoginPage()),
                                            (Route<dynamic> route) => false,
                                          );
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    print('Genel hata: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Beklenmeyen bir hata oluştu: $e'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 5,
                              ),
                              child: Text(
                                'Güncelle',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                User? user = _auth.currentUser;
                                if (user != null) {
                                  await _firestore.collection('uyelerim').doc(user.uid).update({'isFirstTime': false});
                                }
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('İptal', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Not: Bu işlem zorunludur ve güvenliğiniz için gereklidir.',
                        style: TextStyle(fontSize: 12, color: Colors.white60, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showVerificationLinkDialog(User user) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF000000), Color(0xFF4A0000), Color(0xFF9A0202)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mark_email_unread, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Email Doğrulama',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Yeni email adresinize bir doğrulama linki gönderdik.',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Lütfen email kutunuzu kontrol edin ve doğrulama linkine tıklayın.',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Not: Eğer email kutunuzda doğrulama linkini göremiyorsanız, spam klasörünü kontrol edin.',
                          style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Doğrulama işlemi tamamlandıktan sonra uygulamaya tekrar giriş yapmanız gerekecektir.',
                    style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _auth.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(
                                  checkEmailVerification: true,
                                  pendingEmail: _newEmailController.text,
                                ),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bir hata oluştu: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                      child: Text(
                        'Tamam',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _validateInputs() {
    if (_newEmailController.text.isEmpty ||
        _currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeni şifreler eşleşmiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şifre en az 6 karakter olmalıdır'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (!_newEmailController.text.contains('@') || !_newEmailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçerli bir email adresi girin'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
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

  void _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = user?.uid;
    });
  }

  Future<void> _fetchGroupLessons() async {
    if (userId == null) return;
    groupLessons = await _getGroupLessonsForUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Derslerim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF9A0202), Color(0xFFC80101)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildDateSelector(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getGroupLessonsForUser(), // selectedDate değiştiğinde otomatik yenilenir
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Veri yüklenirken bir hata oluştu.'));
                  }
                  final groupLessons = snapshot.data ?? [];
                  if (groupLessons.isEmpty) {
                    return Center(
                      child: Text(
                        'Bugün katılabileceğiniz grup dersi bulunmamaktadır.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: groupLessons.length,
                    itemBuilder: (context, index) {
                      final group = groupLessons[index];
                      bool isCurrentDay = selectedDate.day == DateTime.now().day;

                      return Card(
                        color: Colors.white,
                        elevation: 5,
                        margin: EdgeInsets.all(8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    group['group_name'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isCurrentDay)
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'qrscanner') {
                                          scanQRCode(context, group['group_name']);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem<String>(
                                          value: 'qrscanner',
                                          child: Text('Yoklama Al'),
                                        ),
                                      ],
                                      child: Icon(Icons.qr_code_scanner),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'Günler: ${group['days'].join(', ')}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Saat: ${group['time']}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Antrenör: ${group['trainer']}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.black,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('beltexam')
            .doc('examStatus')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Veri alınamadı'));
          }

          // isOpen değerinin Firestore'da olup olmadığını kontrol et
          bool isOpen = snapshot.data?.exists ?? false ? snapshot.data?.get('isOpen') ?? false : false;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('beltexam').snapshots(),
            builder: (context, folderSnapshot) {
              if (folderSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              bool folderExists = folderSnapshot.hasData && folderSnapshot.data!.docs.isNotEmpty;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomBarIcon(
                      context,
                      icon: Icons.announcement,
                      label: 'Hakkımızda',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutUs()),
                      ),
                    ),
                    if (folderExists && isOpen != null) // isOpen değeri null değilse ikonu göster
                      _buildBottomBarIcon(
                        context,
                        icon: Icons.school,
                        label: 'Kuşak Sınavı',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserBeltExamRegister()),
                        ),
                      ),
                    _buildBottomBarIcon(
                      context,
                      icon: Icons.qr_code_scanner,
                      label: 'Yoklamanı Al',
                      onTap: () {
                        if (groupLessons.isNotEmpty) {
                          scanQRCode(context, groupLessons[0]['group_name']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Grup dersi bulunamadı.')),
                          );
                        }
                      },
                    ),
                    if(!_isIndividualLesson)
                    _buildBottomBarIcon(
                      context,
                      icon: Icons.shopping_cart,
                      label: 'Malzeme Siparişi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserOrderEquipmentPage()),
                      ),
                    ),
                    _buildBottomBarIcon(
                      context,
                      icon: Icons.sports_martial_arts,
                      label: 'Poomseler',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PoomsePage()),
                      ),
                    ),
                    _buildBottomBarIcon(
                      context,
                      icon: Icons.account_circle,
                      label: 'Profilim',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfilePage()),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  Widget _buildBottomBarIcon(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getGroupLessonsForUser() async {
    if (userId == null) return [];

    // Kullanıcının grup bilgilerini al
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('uyelerim').doc(userId).get();
    String groupString = userDoc['group'] ?? ''; // Kullanıcının gruplarını al
    List<String> userGroups = groupString.split(',').map((e) => e.trim()).toList(); // Grupları listeye çevir

    if (userGroups.isEmpty) return []; // Kullanıcı hiçbir gruba ait değilse boş döndür

    // Tüm grupları tek bir sorgu ile çek
    QuerySnapshot groupLessonsSnapshot = await FirebaseFirestore.instance.collection('group_lessons').get();

    List<Map<String, dynamic>> groupLessons = [];

    // Seçilen tarihin gün adını al
    String selectedDayName = DateFormat.EEEE('tr_TR').format(selectedDate);

    for (var groupDoc in groupLessonsSnapshot.docs) {
      final groupData = groupDoc.data() as Map<String, dynamic>;
      String groupName = groupData['group_name'];

      // Kullanıcı bu gruba ait mi?
      if (userGroups.contains(groupName)) {
        // Yeni yapı: days_with_time alanı
        final daysWithTime = Map<String, String>.from(groupData['days_with_time'] ?? {});

        // Seçilen gün için ders var mı kontrol et
        bool hasLessonOnSelectedDay = daysWithTime.containsKey(selectedDayName);

        if (hasLessonOnSelectedDay) {
          groupLessons.add({
            'group_name': groupName,
            'days': daysWithTime.keys.toList(), // Tüm günleri listeye ekle
            'time': daysWithTime[selectedDayName] ?? '', // Seçilen günün saatini al
            'trainer': groupData['trainer'],
          });
        }
      }
    }

    return groupLessons;
  }
  void _onDateSelected(int day) {
    setState(() {
      selectedDate = DateTime(DateTime.now().year, DateTime.now().month, day);
    });
  }


  Widget _buildDateSelector() {
    DateTime now = DateTime.now();
    DateTime firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    DateTime lastDayOfCurrentMonth = firstDayOfNextMonth.subtract(Duration(days: 1));
    int daysInMonth = lastDayOfCurrentMonth.day;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(daysInMonth, (index) {
          int day = index + 1;
          bool isToday = day == DateTime.now().day;
          bool isSelected = selectedDate.day == day;

          String dayAbbreviation = DateFormat.E('tr_TR').format(DateTime(now.year, now.month, day));

          return GestureDetector(
            onTap: () => _onDateSelected(day),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  width: isSelected ? 60 : 50,
                  height: isSelected ? 60 : 50,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (isToday ? Colors.green : Colors.white),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: isSelected ? 18 : 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isToday || isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(dayAbbreviation, style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> scanQRCode(BuildContext context, String groupName) async {
    try {
      // Önce QR kodun geçerliliğini kontrol et
      final qrSnapshot = await FirebaseFirestore.instance.collection('qrcode').doc('qrCode').get();
      if (!qrSnapshot.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR kod sistemi şu anda aktif değil.')),
          );
        }
        return;
      }

      // QR kodu tara
      ScanResult scanResult;
      try {
        scanResult = await BarcodeScanner.scan(
          options: ScanOptions(
            strings: {
              'cancel': 'İptal',
              'flash_on': 'Flaş Açık',
              'flash_off': 'Flaş Kapalı',
            },
            restrictFormat: [BarcodeFormat.qr], // Sadece QR kodları tara
            useCamera: -1, // Arka kamerayı kullan
            autoEnableFlash: false,
            android: AndroidOptions(
              useAutoFocus: true, // Android'de otomatik odaklama
            ),
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kamera erişiminde sorun oluştu: ${e.toString()}')),
          );
        }
        return;
      }

      if (scanResult.rawContent.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR kodu tarama iptal edildi.')),
          );
        }
        return;
      }

      String scannedQRCode = scanResult.rawContent.trim();
      final qrData = qrSnapshot.data();

      if (qrData == null || qrData['data'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR kod verisi bulunamadı.')),
          );
        }
        return;
      }

      // SADECE QR KOD EŞLEŞMESİNİ KONTROL ET (ZAMAN KONTROLÜ YOK)
      if (qrData['data'] != scannedQRCode) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR kod eşleşmiyor. Lütfen tekrar deneyin.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Kullanıcının ders hakkını kontrol et
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('uyelerim').doc(userId).get();
      if (!userDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı bilgileri bulunamadı.')),
          );
        }
        return;
      }

      int lessonCount = userDoc['lessonCount'] ?? 0;
      // Sadece bireysel dersler için ders hakkı kontrolü yap
      if (_isIndividualLesson && lessonCount <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ders hakkınız kalmamış.')),
          );
        }
        return;
      }

      // Aynı gün içinde daha önce yoklama alınmış mı kontrol et
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
          .collection('group_lessons')
          .doc(groupName)
          .collection('yoklamalar')
          .doc(currentDate)
          .get();

      if (attendanceDoc.exists) {
        Map<String, dynamic> attendanceData = attendanceDoc.data() as Map<String, dynamic>;
        if (attendanceData['attendance'] != null &&
            attendanceData['attendance'][userId] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bugün için zaten yoklama almışsınız.')),
            );
          }
          return;
        }
      }

      // Yoklama kaydını oluştur
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Grup yoklaması
        DocumentReference groupAttendanceRef = FirebaseFirestore.instance
            .collection('group_lessons')
            .doc(groupName)
            .collection('yoklamalar')
            .doc(currentDate);

        transaction.set(groupAttendanceRef, {
          'date': currentDate,
          'attendance': {userId: true},
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Kullanıcı yoklaması
        DocumentReference userAttendanceRef = FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(userId)
            .collection('yoklamalar')
            .doc(currentDate);

        transaction.set(userAttendanceRef, {
          'date': currentDate,
          'attendance': true,
          'group': groupName,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Ders hakkını güncelle
        DocumentReference userRef = FirebaseFirestore.instance.collection('uyelerim').doc(userId);
        transaction.update(userRef, {
          'lessonCount': FieldValue.increment(-1),
          'lastAttendanceDate': currentDate,
        });
      });

      // QR kod ekranındaki isim ve üyelik durumu güncellensin
      await updateQRCodeInFirestore(scannedQRCode);

      if (context.mounted) {
        if (_isIndividualLesson) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yoklama başarıyla alındı. Kalan ders hakkı: ${lessonCount - 1}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yoklama başarıyla alındı.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('QR kod tarama hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  String generateQRCode() {
    final random = Random.secure(); // Daha güvenli rastgele sayı üreteci
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = List.generate(6, (index) => random.nextInt(10).toString()).join();
    return '$timestamp$randomPart'; // Zaman damgası + rastgele sayı
  }

  Future<void> updateQRCodeInFirestore(String generatedData) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('uyelerim').doc(currentUser.uid).get();
      String userName = userDoc['name'] ?? 'Bilinmeyen Kullanıcı';
      String membershipStatus = _getMembershipStatus(userDoc.data() as Map<String, dynamic>);

      await FirebaseFirestore.instance.collection('qrcode').doc('qrCode').update({
        'data': generatedData,
        'updatedBy': userName,
        'updatedAt': FieldValue.serverTimestamp(), // Sunucu zamanını kullan
        'membershipStatus': membershipStatus,
        'lastUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('QR kodu güncellenirken hata oluştu: $e');
      throw e; // Hatayı yukarı fırlat
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat("dd-MM-yyyy").parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _getMembershipStatus(Map<String, dynamic> userDocument) {
    try {
      DateTime endDate = _parseDate(userDocument['end_date']);
      DateTime now = DateTime.now();
      return endDate.isBefore(now) ? 'Üyeliğiniz Sonlanmıştır' : 'Üyeliğiniz Devam Ediyor';
    } catch (e) {
      return 'Tarih Hatası';
    }
  }
}