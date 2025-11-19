import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeltExamPage extends StatefulWidget {
  const BeltExamPage({super.key});

  @override
  _BeltExamPageState createState() => _BeltExamPageState();
}

class _BeltExamPageState extends State<BeltExamPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isExamOpen = false;
  String? _activeExamDate;
  bool _isAdmin = false;
  bool _canEditBeltExam = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
    _loadExamStatus();
  }

  // Kullanıcı yetkilerini yükle
  Future<void> _loadUserPermissions() async {
    try {
      await Future.delayed(Duration(milliseconds: 200));
      
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Önce admin koleksiyonunda kontrol et
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(userId).get();
        if (adminDoc.exists) {
          setState(() {
            _isAdmin = adminDoc['admin'] ?? false;
            _canEditBeltExam = adminDoc['canEditBeltExam'] ?? false;
            _isLoading = false;
          });
          return;
        }

        // Admin değilse helpercoach koleksiyonunda kontrol et
        DocumentSnapshot helperCoachDoc = await _firestore.collection('helpercoach').doc(userId).get();
        if (helperCoachDoc.exists) {
          setState(() {
            _isAdmin = false;
            _canEditBeltExam = helperCoachDoc['canEditBeltExam'] ?? false;
            _isLoading = false;
          });
          return;
        }

        // Hiçbir yetki bulunamadıysa
        setState(() {
          _isAdmin = false;
          _canEditBeltExam = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sınav durumunu ve aktif sınav tarihini yükle
  Future<void> _loadExamStatus() async {
    try {
      // Minimum yükleme süresi için Future.delayed ekle
      await Future.delayed(Duration(milliseconds: 200));
      
      DocumentSnapshot examStatusSnapshot =
      await _firestore.collection('beltexam').doc('examStatus').get();

      if (examStatusSnapshot.exists) {
        setState(() {
          _isExamOpen = examStatusSnapshot['isOpen'] ?? false;
        });
      }

      // Aktif sınav tarihini yükle
      QuerySnapshot examDatesSnapshot =
      await _firestore.collection('beltexam').get();
      var examDates = examDatesSnapshot.docs
          .where((doc) => doc.id != 'examStatus')
          .toList();

      if (examDates.isNotEmpty) {
        setState(() {
          _activeExamDate = examDates.last['examDate'];
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // Sadece canEditBeltExam false olan kullanıcılar için görüntüleme modu
    if (!_isAdmin && !_canEditBeltExam) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Kuşak Sınavı', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
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
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kuşak sınavı ile ilgili bir yetkiniz bulunmamaktadır. Bu sayfayı sadece görüntüleyebilirsiniz.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildReadOnlyExamList(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kuşak Sınavı',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: _onMenuOptionSelected,
            itemBuilder: (BuildContext context) {
              return [
                if (_isAdmin) // Sadece admin sınavı açıp kapatabilir
                  PopupMenuItem<String>(
                    value: 'toggleExam',
                    child: Text(_isExamOpen ? 'Sınavı Kapat' : 'Yeni Kuşak Sınavı Oluştur'),
                  ),
                if (_isExamOpen && (_isAdmin || _canEditBeltExam))
                  PopupMenuItem<String>(
                    value: 'selectExamDate',
                    child: Text('Sınav Tarihini Seç'),
                  ),
              ];
            },
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
        child: Column(
          children: [
            SizedBox(height: 20),
            if (_isAdmin || _canEditBeltExam) // Yetkili kullanıcılar için durum bilgisi
              Text(
                _isExamOpen ? 'Kuşak Sınavı Kaydı Açık' : 'Kuşak Sınavı Kaydı Kapalı',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            if (_activeExamDate != null && (_isAdmin || _canEditBeltExam))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Aktif Sınav Tarihi: $_activeExamDate',
                  style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 20),
            Expanded(child: _buildExamList()),
          ],
        ),
      ),
    );
  }

  void _onMenuOptionSelected(String value) async {
    if (value == 'toggleExam') {
      await _toggleExamStatus();
    } else if (value == 'selectExamDate') {
      await _selectExamDate();
    }
  }

  // Sınav durumunu aç/kapat
  Future<void> _toggleExamStatus() async {
    setState(() {
      _isExamOpen = !_isExamOpen;
    });

    try {
      await _firestore.collection('beltexam').doc('examStatus').set({
        'isOpen': _isExamOpen,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kuşak Sınavı Durumu Güncellendi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sınav durumu güncellenirken bir hata oluştu.')),
      );
    }
  }

  // Sınav tarihini seç
  Future<void> _selectExamDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black, // Seçilen tarih kutusunun başlığını siyah yapar
            colorScheme: ColorScheme.light(
              primary: Colors.black, // Butonun rengi
              onPrimary: Colors.white, // Başlık rengi
            ),
            primaryColorDark: Colors.black, // Seçilen tarih kutusundaki okları siyah yapar
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);

      try {
        await _firestore.collection('beltexam').doc(formattedDate).set({
          'examDate': formattedDate,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _activeExamDate = formattedDate;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sınav Tarihi Kaydedildi: $formattedDate')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sınav tarihi kaydedilirken hata oluştu.')),
        );
      }
    }
  }

  // Sadece görüntüleme modu için liste widget'ı
  Widget _buildReadOnlyExamList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('beltexam').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var examDocs = snapshot.data!.docs.where((doc) => doc.id != 'examStatus').toList();

        return ListView.builder(
          itemCount: examDocs.length,
          itemBuilder: (context, index) {
            var examData = examDocs[index];
            String examDate = examData['examDate'];

            return Card(
              color: Colors.white.withOpacity(0.9),
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  examDate,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                subtitle: Text(
                  'Sınav Tarihi',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Icon(Icons.visibility, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  // Orijinal liste widget'ını güncelle
  Widget _buildExamList() {
    if (!_isAdmin && !_canEditBeltExam) {
      return _buildReadOnlyExamList();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('beltexam').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var examDocs = snapshot.data!.docs.where((doc) => doc.id != 'examStatus').toList();

        return ListView.builder(
          itemCount: examDocs.length,
          itemBuilder: (context, index) {
            var examData = examDocs[index];
            String examDate = examData['examDate'];

            return Card(
              color: Colors.white.withOpacity(0.9),
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  examDate,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                trailing: PopupMenuButton<String>(
                  iconColor: Colors.black,
                  onSelected: (value) {
                    if (value == 'edit' && (_isAdmin || _canEditBeltExam)) {
                      _editExamDate(examDate);
                    } else if (value == 'delete' && _isAdmin) { // Sadece admin silebilir
                      _deleteExamDate(examDate);
                    } else if (value == 'viewRegistrations' && (_isAdmin || _canEditBeltExam)) {
                      _viewRegistrations(examDate);
                    }
                  },
                  itemBuilder: (context) => [
                    if (_isAdmin || _canEditBeltExam)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Tarihi Düzenle'),
                      ),
                    if (_isAdmin) // Sadece admin silme seçeneğini görebilir
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Sil'),
                      ),
                    if (_isAdmin || _canEditBeltExam)
                      PopupMenuItem(
                        value: 'viewRegistrations',
                        child: Text('Kayıtları Görüntüle'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Sınav tarihini düzenle
  Future<void> _editExamDate(String oldDate) async {
    if (!_isAdmin && !_canEditBeltExam) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu işlem için yetkiniz bulunmamaktadır.')),
      );
      return;
    }
    DateTime initialDate = DateFormat('dd-MM-yyyy').parse(oldDate);

    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black, // Seçilen tarih kutusunun başlığını siyah yapar
            colorScheme: ColorScheme.light(
              primary: Colors.black, // Butonun rengi
              onPrimary: Colors.white, // Başlık rengi
            ),
            primaryColorDark: Colors.black, // Seçilen tarih kutusundaki okları siyah yapar
          ),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      String newFormattedDate = DateFormat('dd-MM-yyyy').format(newDate);

      try {
        await _firestore.collection('beltexam').doc(newFormattedDate).set({
          'examDate': newFormattedDate,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('beltexam').doc(oldDate).delete();

        setState(() {
          _activeExamDate = newFormattedDate;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sınav Tarihi Güncellendi: $newFormattedDate')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tarih güncellenirken hata oluştu.')),
        );
      }
    }
  }

  // Sınav tarihini sil
  Future<void> _deleteExamDate(String examDate) async {
    if (!_isAdmin && !_canEditBeltExam) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu işlem için yetkiniz bulunmamaktadır.')),
      );
      return;
    }
    try {
      await _firestore.collection('beltexam').doc(examDate).delete();
      setState(() {
        _activeExamDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sınav Tarihi Silindi: $examDate')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarih silinirken hata oluştu.')),
      );
    }
  }

  Future<void> _viewRegistrations(String examDate) async {
    if (!_isAdmin && !_canEditBeltExam) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu işlem için yetkiniz bulunmamaktadır.')),
      );
      return;
    }
    try {
      QuerySnapshot registrationsSnapshot = await _firestore
          .collection('beltexam')
          .doc(examDate)
          .collection('sınavKayıt')
          .get();

      if (registrationsSnapshot.docs.isNotEmpty) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false, // Kullanıcı ekranın dışına basarak kapatamaz
          barrierColor: Colors.black.withOpacity(0.5), // Hafif koyu arkaplan efekti
          transitionDuration: Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
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
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.black,
                        title: Text('Kayıtlı Üyeler ($examDate)' ,style: TextStyle(color: Colors.white),),
                        automaticallyImplyLeading: false, // Geri tuşunu gizler
                        actions: [
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: registrationsSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            var registration = registrationsSnapshot.docs[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _deleteRegistration(examDate, registration.id);
                                    Navigator.pop(context); // Modal'ı kapat
                                    _viewRegistrations(examDate); // Listeyi yenile
                                  },
                                ),
                                title: Text(registration['userName'] ?? 'İsim Yok'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kuşak: ${registration['selectedBelt']}'),
                                    Text('Ödeme: ${registration['paymentMethod']}'),
                                    Text('Lisans: ${registration['licenseInfo']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu tarih için kayıt bulunamadı.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıtlar yüklenirken hata oluştu.')),
      );
    }
  }

// Kaydı silme işlemi
  Future<void> _deleteRegistration(String examDate, String registrationId) async {
    if (!_isAdmin && !_canEditBeltExam) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu işlem için yetkiniz bulunmamaktadır.')),
      );
      return;
    }
    try {
      await _firestore
          .collection('beltexam')
          .doc(examDate)
          .collection('sınavKayıt')
          .doc(registrationId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt başarıyla silindi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt silinirken hata oluştu.')),
      );
    }
  }
}