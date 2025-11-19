import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String lessonId;
  final DateTime selectedDate;

  const AttendancePage({super.key, required this.lessonId, required this.selectedDate});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<String> _attendanceStatus = [];
  bool _isLoading = true; // İlk yükleme durumu
  late String formattedDate; // Tarih formatı
  bool _isFirstAttendance = true; // İlk yoklama kontrolü
  bool _isSavingAttendance = false; // Yoklama kaydediliyor mu?

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate); // Seçilen tarihi kullan
    _fetchSavedAttendance(); // Kaydedilmiş yoklama durumlarını getir
  }

  /// Kaydedilmiş yoklama durumlarını Firestore'dan getir
  Future<void> _fetchSavedAttendance() async {
    DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
        .collection('group_lessons')
        .doc(widget.lessonId)
        .collection('yoklamalar')
        .doc(formattedDate)
        .get();

    if (attendanceDoc.exists) {
      final attendanceData = attendanceDoc.data() as Map<String, dynamic>;
      final savedAttendance = attendanceData['attendance'] as Map<String, dynamic>;

      // Tüm grup üyelerini getir
      QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
          .collection('group_lessons')
          .doc(widget.lessonId)
          .collection('grup_uyeleri')
          .get();

      List<String> updatedAttendance = [];

      // Her bir üyenin ID'sine göre yoklama durumunu kontrol et
      for (var member in membersSnapshot.docs) {
        final memberId = member.id;
        final status = savedAttendance[memberId];
        if (status == true) {
          updatedAttendance.add('katıldı');
        } else if (status == false) {
          updatedAttendance.add('katılmadı');
        } else if (status == 'izinli') {
          updatedAttendance.add('izinli');
        } else {
          updatedAttendance.add('katılmadı');
        }
      }

      setState(() {
        _attendanceStatus = updatedAttendance;
        _isLoading = false; // Yükleme tamamlandı
        _isFirstAttendance = false; // Daha önce yoklama yapılmış
      });
    } else {
      setState(() {
        _attendanceStatus = [];
        _isLoading = false; // Yükleme tamamlandı
        _isFirstAttendance = true; // İlk yoklama
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoklama Al', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('group_lessons')
            .doc(widget.lessonId)
            .collection('grup_uyeleri')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final members = snapshot.data!.docs;

          // Güvenlik: attendanceStatus ve members uzunluğu eşit değilse doldur
          if (_attendanceStatus.length != members.length) {
            _attendanceStatus = List.generate(members.length, (index) => 'katılmadı');
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                        Card(
                          color: Colors.black.withOpacity(0.7),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildLegendItem(Colors.green, "Katıldı"),
                                _buildLegendItem(Colors.orange, "İzinli"),
                                _buildLegendItem(Colors.red, "Katılmadı"),
                              ],
                            ),
                          ),
                        ),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      String memberName = member['name'];
                      String memberInitial = memberName.isNotEmpty
                          ? memberName[0].toUpperCase()
                                  : '';

                              Color statusColor = _attendanceStatus[index] == 'katıldı'
                                  ? Colors.green
                                  : _attendanceStatus[index] == 'izinli'
                                      ? Colors.orange
                                      : Colors.red;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 4,
                                color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            child: Text(memberInitial),
                          ),
                          title: Text(
                            memberName,
                                    style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                                      color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                                    _attendanceStatus[index].toUpperCase(),
                            style: TextStyle(
                                      color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                                  trailing: _buildAttendanceButton(_attendanceStatus[index], index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSavingAttendance ? null : () async {
                    setState(() {
                      _isSavingAttendance = true;
                    });
                    await _saveAttendance(members);
                    if (mounted) {
                      setState(() {
                        _isSavingAttendance = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                    ),
                            elevation: 4,
                  ),
                  child: _isSavingAttendance
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Yoklama Kaydediliyor...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Yoklamayı Kaydet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(String currentStatus, int index) {
    return PopupMenuButton<String>(
      icon: Icon(
        currentStatus == 'katıldı'
            ? Icons.check_circle
            : currentStatus == 'izinli'
                ? Icons.event_busy
                : Icons.cancel,
        color: currentStatus == 'katıldı'
            ? Colors.green
            : currentStatus == 'izinli'
                ? Colors.orange
                : Colors.red,
        size: 28,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      onSelected: (String newStatus) {
        setState(() {
          _attendanceStatus[index] = newStatus;
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'katıldı',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Katıldı', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'katılmadı',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Katılmadı', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'izinli',
          child: Row(
            children: [
              Icon(Icons.event_busy, color: Colors.orange),
              SizedBox(width: 8),
              Text('İzinli', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveAttendance(List<QueryDocumentSnapshot> members) async {
    // Güvenlik: attendanceStatus ve members uzunluğu eşit değilse doldur
    if (_attendanceStatus.length != members.length) {
      _attendanceStatus = List.generate(members.length, (index) => 'katılmadı');
    }

    String currentTime = DateFormat('HH:mm').format(DateTime.now()); // Saat bilgisi

    CollectionReference attendanceRef = FirebaseFirestore.instance
        .collection('group_lessons')
        .doc(widget.lessonId)
        .collection('yoklamalar');

    DocumentReference dailyAttendanceDoc = attendanceRef.doc(formattedDate);

    // Yoklama verisi
    Map<String, dynamic> attendanceData = {
      'date': formattedDate,
      'time': currentTime,
      'attendance': {}
    };

    for (int i = 0; i < members.length; i++) {
      String status = _attendanceStatus[i];
      if (status == 'katıldı') {
        attendanceData['attendance'][members[i].id] = true;
      } else if (status == 'katılmadı') {
        attendanceData['attendance'][members[i].id] = false;
      } else if (status == 'izinli') {
        attendanceData['attendance'][members[i].id] = 'izinli';
      }
    }

    // Mevcut belgeyi güncelle veya oluştur
    await dailyAttendanceDoc.set(attendanceData, SetOptions(merge: true));

    // Her üye için yoklama bilgisini kendi belgesine ekle
    for (var member in members) {
      DocumentReference memberRef = FirebaseFirestore.instance
          .collection('uyelerim') // Üyeler koleksiyonu
          .doc(member.id);

      // Üye belgesindeki yoklamalar koleksiyonuna veri ekle
      CollectionReference attendanceSubCollection = memberRef.collection('yoklamalar');

      // Her yoklama için bir belge ekle
      String status = _attendanceStatus[members.indexOf(member)];
      dynamic attendanceValue;
      if (status == 'katıldı') {
        attendanceValue = true;
      } else if (status == 'katılmadı') {
        attendanceValue = false;
      } else if (status == 'izinli') {
        attendanceValue = 'izinli';
      }
      Map<String, dynamic> memberAttendanceData = {
        'date': formattedDate,
        'attendance': attendanceValue, // Doğru tipte kaydet
      };

      await attendanceSubCollection.doc(formattedDate).set(memberAttendanceData, SetOptions(merge: true));

      // Bireysel ders kontrolü ve ders hakkı düşme işlemi
      DocumentSnapshot memberDoc = await memberRef.get();
      bool isIndividualLesson = (memberDoc.data() as Map<String, dynamic>?)?['isIndividualLesson'] ?? false;
      int currentLessonCount = memberDoc['lessonCount'] ?? 0;
      if (
        isIndividualLesson &&
        _isFirstAttendance &&
        (status == 'katıldı' || status == 'katılmadı') &&
        currentLessonCount > 0
      ) {
        await memberRef.update({
          'lessonCount': currentLessonCount - 1,
        });
      }
    }

    if (mounted) {
      setState(() {
        _isFirstAttendance = false;
      });
    }

    // Başarı mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yoklama başarıyla kaydedildi.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}