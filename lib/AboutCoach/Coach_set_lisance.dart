import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoachSetLisance extends StatefulWidget {
  @override
  _CoachSetLisanceState createState() => _CoachSetLisanceState();
}

class _CoachSetLisanceState extends State<CoachSetLisance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Map<String, String> selectedLisans = {};
  bool isAdmin = false;
  bool isHelperCoach = false;
  bool canEditLicense = false; // Lisans düzenleme yetkisi
  TextEditingController searchController = TextEditingController();
  bool isLoading = true; // Yükleme durumu için değişken

  @override
  void initState() {
    super.initState();
    checkUserRole();
    fetchUsers();
  }

  Future<void> checkUserRole() async {
    setState(() {
      isLoading = true;
    });
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        if (adminDoc.exists && adminDoc.data() != null) {
          Map<String, dynamic> userData = adminDoc.data() as Map<String, dynamic>;
          
          setState(() {
            isAdmin = userData['admin'] == true;
            isHelperCoach = userData['helpercoach'] == true;
            
            // Admin ise direkt yetki ver, helper coach ise yetkiyi kontrol et
            canEditLicense = isAdmin || (isHelperCoach && userData['canEditLicense'] == true);
            isLoading = false;
          });
        } else {
          setState(() {
            isAdmin = false;
            isHelperCoach = false;
            canEditLicense = false;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          isAdmin = false;
          isHelperCoach = false;
          canEditLicense = false;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        isHelperCoach = false;
        canEditLicense = false;
        isLoading = false;
      });
    }
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('uyelerim').get();
      List<Map<String, dynamic>> userList = querySnapshot.docs.map((doc) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        String lisansDurumu = data?['lisans'] ?? 'yok'; // Varsayılan "yok"

        return {
          'id': doc.id,
          'name': data?['name'] ?? 'Bilinmeyen',
          'lisans': lisansDurumu,
        };
      }).toList();

      setState(() {
        users = userList;
        filteredUsers = userList; // Başlangıçta tüm kullanıcılar filtrelenmiş olarak ayarlanır
        for (var user in users) {
          selectedLisans[user['id']] = user['lisans']; // Seçili değerleri kaydet
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterUsers(String query) {
    setState(() {
      filteredUsers = users
          .where((user) =>
          user['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> saveLisansUpdates() async {
    if (!canEditLicense) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lisans düzenleme yetkiniz bulunmuyor.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      for (var userId in selectedLisans.keys) {
        await _firestore.collection('uyelerim').doc(userId).set(
          {'lisans': selectedLisans[userId]},
          SetOptions(merge: true),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lisans bilgileri başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Üye Listesi",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000),
              Color(0xFF4A0000),
              Color(0xFF9A0202),
              Color(0xFFB00000),
              Color(0xFFC80101),
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0],
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
                    'Üye bilgileri yükleniyor...',
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
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (!canEditLicense)
                    Container(
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lisans düzenleme yetkiniz bulunmuyor.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Üye ara...',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: filterUsers,
                    ),
                  ),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'Üye bulunamadı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 5),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.person,
                                    color: Colors.blueAccent,
                                    size: 50,
                                  ),
                                  title: Text(
                                    filteredUsers[index]['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Lisans Durumu",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          _buildCheckbox(filteredUsers[index]['id'], 'Yok', 'yok'),
                                          _buildCheckbox(filteredUsers[index]['id'], 'Var', 'var'),
                                          _buildCheckbox(filteredUsers[index]['id'], 'Vize', 'vizeletilmeli'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (canEditLicense)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: saveLisansUpdates,
                        child: Text(
                          "Kaydet",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildCheckbox(String userId, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: selectedLisans[userId] == value,
          onChanged: canEditLicense ? (bool? newValue) {
            if (newValue == true) {
              setState(() {
                selectedLisans[userId] = value;
              });
            }
          } : null, // Yetki yoksa checkbox'ı devre dışı bırak
          activeColor: _getCheckboxColor(value),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Color _getCheckboxColor(String value) {
    switch (value) {
      case 'yok':
        return Colors.red;
      case 'var':
        return Colors.green;
      case 'vizeletilmeli':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}