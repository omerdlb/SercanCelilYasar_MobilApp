import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için

class OldAttendancePage extends StatefulWidget {
  final String groupId;

  const OldAttendancePage({super.key, required this.groupId});

  @override
  _OldAttendancePageState createState() => _OldAttendancePageState();
}

class _OldAttendancePageState extends State<OldAttendancePage> {

  // Tarihi formatlayarak gün ismiyle birlikte döndür
  String _formatDateWithDay(String date) {
    try {
      // Tarihi 'yyyy-MM-dd' formatında parse ediyoruz
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(date);
      String dayName = DateFormat('EEEE', 'tr_TR').format(parsedDate); // Türkçe gün ismi
      // Formatlanmış tarihi ve gün ismini döndürüyoruz
      return '${DateFormat('dd-MM-yyyy').format(parsedDate)} ($dayName)';
    } catch (e) {
      return date; // Hata durumunda orijinal tarihi döndür
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eski Yoklamalar',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('group_lessons')
            .doc(widget.groupId)
            .collection('yoklamalar')
            .orderBy('date', descending: true) // Tarihe göre sırala
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceRecords = snapshot.data!.docs;

          if (attendanceRecords.isEmpty) {
            return const Center(
              child: Text(
                'Henüz yoklama kaydı bulunmamaktadır.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              final date = record['date'] ?? 'Tarih Yok';
              final time = record['time'] ?? 'Saat Yok';

              // Tarihi gün ismiyle birlikte formatla
              String formattedDate = _formatDateWithDay(date);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(
                    formattedDate, // Formatlanmış tarih ve gün ismi
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Saat: $time',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceDetailPage(
                          groupId: widget.groupId,
                          date: record.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AttendanceDetailPage extends StatelessWidget {
  final String groupId;
  final String date;

  const AttendanceDetailPage({super.key, required this.groupId, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yoklama Detayları - $date'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('group_lessons')
            .doc(groupId)
            .collection('yoklamalar')
            .doc(date)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata oluştu: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceData = snapshot.data!.data() as Map<String, dynamic>?;

          if (attendanceData == null || !attendanceData.containsKey('attendance')) {
            return const Center(
              child: Text(
                'Katılım bilgisi bulunamadı.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final attendance = attendanceData['attendance'] as Map<String, dynamic>;

          if (attendance.isEmpty) {
            return const Center(
              child: Text(
                'Katılım bilgisi yok.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: attendance.length,
            itemBuilder: (context, index) {
              String memberId = attendance.keys.elementAt(index);
              bool isPresent = attendance[memberId] ?? false;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('uyelerim') // Kullanıcıların koleksiyon adı
                    .doc(memberId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata oluştu: ${userSnapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const ListTile(
                      title: Text('Kullanıcı bilgisi yüklenemedi.'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  String memberName = userData?['name'] ?? 'Bilinmeyen Kullanıcı';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      leading: CircleAvatar(
                        backgroundColor: isPresent ? Colors.green : Colors.red,
                        child: Icon(
                          isPresent ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        isPresent ? 'Dersteydi' : 'Derste değildi',
                        style: TextStyle(
                          color: isPresent ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}