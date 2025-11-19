import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';

class AddTrainerPage extends StatefulWidget {
  const AddTrainerPage({super.key});

  @override
  _AddTrainerPageState createState() => _AddTrainerPageState();
}

class _AddTrainerPageState extends State<AddTrainerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateEmail(String name) {
    String normalizedName = name
        .replaceAll(RegExp(r"[ğĞ]"), "g")
        .replaceAll(RegExp(r"[üÜ]"), "u")
        .replaceAll(RegExp(r"[şŞ]"), "s")
        .replaceAll(RegExp(r"[ıİ]"), "i")
        .replaceAll(RegExp(r"[çÇ]"), "c")
        .replaceAll(RegExp(r"[öÖ]"), "o")
        .toLowerCase()
        .replaceAll(' ', '.');
    return '$normalizedName@dlbstudio.com';
  }

  Future<void> _saveTrainer() async {
    if (!_formKey.currentState!.validate()) return;

    // Mevcut admin bilgilerini al
    User? currentUser = _auth.currentUser;
    String? currentUserUid = currentUser?.uid;
    String? currentUserEmail;
    String? currentUserPassword;

    if (currentUserUid != null) {
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(currentUserUid).get();
      if (adminDoc.exists) {
        currentUserEmail = adminDoc['email'];
        currentUserPassword = adminDoc['password'];
      }
    }

    // Yeni antrenör bilgilerini al
    String name = _nameController.text;
    String password = _passwordController.text;
    String baseEmail = _generateEmail(name);
    String email = baseEmail;

    try {
      int emailSuffix = 1;
      bool emailExists = true;

      while (emailExists) {
        try {
          // Mevcut admin oturumunu koru
          User? currentAdmin = FirebaseAuth.instance.currentUser;
          if (currentAdmin == null) {
            throw Exception('Admin oturumu bulunamadı');
          }

          // Firebase Authentication ile yeni kullanıcı oluştur
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          emailExists = false;
          String uid = userCredential.user!.uid;

          // Firestore'a yeni antrenörü kaydet
          await _firestore.collection('admins').doc(uid).set({
            'name': name,
            'email': email,
            'helpercoach': true,
            'admin': false,
          });

          // Başarı mesajı
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Antrenör başarıyla eklendi!')),
          );

          // Formu temizle
          _formKey.currentState!.reset();
          _nameController.clear();
          _passwordController.clear();

          // Admin oturumunu koru - artık Firestore'dan şifre alıp tekrar giriş yapmaya gerek yok
          if (currentAdmin.uid != FirebaseAuth.instance.currentUser?.uid) {
            throw Exception('Admin oturumu değişti');
          }

          // Sayfayı kapat
          Navigator.pop(context);

        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            email = baseEmail.replaceFirst(RegExp(r'@'), '${emailSuffix++}@');
          } else {
            print('Error saving trainer: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Antrenör eklenirken bir hata oluştu: ${e.message}')),
            );
            return;
          }
        }
      }
    } catch (e) {
      print('Error saving trainer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Antrenör eklenirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Antrenör Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000),
              Color(0xFF4A0000),
              Color(0xFF9A0202),
              Color(0xFFB00000),
              Color(0xFF9A0202),
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Antrenör Adı Soyadı',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen antrenör adı soyadı girin.';
                    }
                    return null;
                  },
                  cursorColor: Colors.white,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifre girin.';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                  cursorColor: Colors.white,
                ),
                SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: _saveTrainer,
                    child: Text(
                      'Antrenör Ekle',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 