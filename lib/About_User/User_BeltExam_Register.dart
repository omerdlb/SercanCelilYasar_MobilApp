import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class UserBeltExamRegister extends StatefulWidget {
  const UserBeltExamRegister({super.key});

  @override
  _UserBeltExamRegisterState createState() => _UserBeltExamRegisterState();
}


class _UserBeltExamRegisterState extends State<UserBeltExamRegister> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> examDates = [];
  String userBelt = ""; // Kullanıcının kuşak bilgisi
  bool isLoading = true;
  String? selectedExamDate; // Seçilen sınav tarihi
  bool isNakitSelected = false; // Nakit seçildi mi?
  bool isIbanSelected = false; // IBAN seçildi mi?
  bool isLicenseYesSelected = false; // Lisans bilgisi var mı?
  bool isLicenseNoSelected = false; // Lisans bilgisi yok mu?
  String userName = ""; // Kullanıcı adı (örnek)
  bool isUpdateMode = false; //
  @override
  void initState() {
    super.initState();
    _fetchExamDates();
    _fetchUserName();
    _fetchUserBelt(); // Kullanıcının kuşak bilgisini çek
  }


  // Function to fetch user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      // Get the current userId from Firebase Authentication
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid; // Get the user ID

        // Fetch the user document using the userId dynamically
        DocumentSnapshot userDoc = await _firestore.collection('uyelerim').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name']; // Kullanıcının adını al
            isLoading = false;
          });
        }
      } else {
        // Handle the case when the user is not logged in
        setState(() {
          isLoading = false;
        });
        print("User not logged in");
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  // Function to fetch user's belt information from Firestore
  Future<void> _fetchUserBelt() async {
    try {
      // Get the current userId from Firebase Authentication
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid; // Get the user ID

        // Fetch the user document using the userId dynamically
        DocumentSnapshot userDoc = await _firestore.collection('uyelerim').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            userBelt = userDoc['belt']; // Kullanıcının kuşak bilgisini al
            isLoading = false;
          });
        }
      } else {
        // Handle the case when the user is not logged in
        setState(() {
          isLoading = false;
        });
        print("User not logged in");
      }
    } catch (e) {
      print('Error fetching user belt: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to fetch exam dates (no changes needed)
  Future<void> _fetchExamDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('beltexam').get();
      setState(() {
        examDates = snapshot.docs
            .where((doc) {
          String docId = doc.id;
          try {
            DateFormat('dd-MM-yyyy').parseStrict(docId);
            return true;
          } catch (e) {
            return false;
          }
        })
            .map((doc) => doc.id)
            .toList();
      });
    } catch (e) {
      print('Error fetching exam dates: $e');
    }
  }

  Future<void> _saveOrUpdateUserExamRegistration() async {
    if (selectedExamDate == null || selectedExamDate!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen sınav tarihini seçin.')),
      );
      return;
    }

    if (!isNakitSelected && !isIbanSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen ödeme yöntemini seçin.')),
      );
      return;
    }

    if (!isLicenseYesSelected && !isLicenseNoSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen lisans bilgisi seçin.')),
      );
      return;
    }

    if (userBelt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kuşak bilgisi eksik.')),
      );
      return;
    }

    try {
      // Check if the user has already registered for the exam
      var existingRegistration = await _firestore.collection('beltexam')
          .doc(selectedExamDate)
          .collection('sınavKayıt')
          .where('userName', isEqualTo: userName)
          .get();

      if (existingRegistration.docs.isNotEmpty) {
        // User has already registered, so update the existing registration
        var docId = existingRegistration.docs.first.id;
        await _firestore.collection('beltexam')
            .doc(selectedExamDate)
            .collection('sınavKayıt')
            .doc(docId)
            .update({
          'selectedBelt': userBelt,
          'paymentMethod': isNakitSelected ? 'Nakit' : 'IBAN',
          'licenseInfo': isLicenseYesSelected ? 'Var' : 'Yok',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydınız başarıyla güncellendi!')),
        );
        setState(() {
          isUpdateMode = true; // Change the button text to "Bilgileri Güncelle"
        });
      } else {
        // User has not registered yet, so create a new registration
        await _firestore.collection('beltexam')
            .doc(selectedExamDate)
            .collection('sınavKayıt')
            .add({
          'userName': userName,
          'selectedExamDate': selectedExamDate,
          'selectedBelt': userBelt,
          'paymentMethod': isNakitSelected ? 'Nakit' : 'IBAN',
          'licenseInfo': isLicenseYesSelected ? 'Var' : 'Yok',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydınız başarıyla tamamlandı!')),
        );
        setState(() {
          isUpdateMode = true; // Change the button text to "Bilgileri Güncelle"
        });
      }
    } catch (e) {
      print('Error saving or updating user exam registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt sırasında bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kuşak Sınavı Kaydı',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
            child: SingleChildScrollView(
                    child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sınav Tarihi Seçici
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Sınav Tarihi Seçin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownButton<String>(
                          hint: Text('Tarih Seçin'),
                          value: selectedExamDate,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedExamDate = newValue;
                            });
                          },
                          items: examDates.map((examDate) {
                            return DropdownMenuItem<String>(
                              value: examDate,
                              child: Text(examDate),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Kuşak Bilgisi
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Kuşak Bilgisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          userBelt,
                          style: TextStyle(fontSize: 16,color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Ödeme Bilgisi
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ödeme Bilgisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Nakit'),
                                value: isNakitSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isNakitSelected = value ?? false;
                                    if (isNakitSelected) {
                                      isIbanSelected = false;
                                    }
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('IBAN'),
                                value: isIbanSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isIbanSelected = value ?? false;
                                    if (isIbanSelected) {
                                      isNakitSelected = false;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Lisans Bilgisi
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lisans Bilgisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Var'),
                                value: isLicenseYesSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isLicenseYesSelected = value ?? false;
                                    if (isLicenseYesSelected) {
                                      isLicenseNoSelected = false;
                                    }
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: Text('Yok'),
                                value: isLicenseNoSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isLicenseNoSelected = value ?? false;
                                    if (isLicenseNoSelected) {
                                      isLicenseYesSelected = false;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Kaydı Tamamla Butonu
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: _saveOrUpdateUserExamRegistration,
                    child: Text(isUpdateMode ? 'Bilgileri Güncelle' : 'Kaydet' ,style: TextStyle(color: Colors.white),),
                  )
                ),
              ],
            ),
                    ),
                  ),
          ),
    );
  }
}