import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BirthdayTrackingPage extends StatefulWidget {
  const BirthdayTrackingPage({super.key});

  @override
  State<BirthdayTrackingPage> createState() => _BirthdayTrackingPageState();
}

class _BirthdayTrackingPageState extends State<BirthdayTrackingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Doğum günü takip için değişkenler
  List<Map<String, dynamic>> todayBirthdays = [];
  List<Map<String, dynamic>> upcomingBirthdays = [];
  bool isLoadingBirthdays = true;

  @override
  void initState() {
    super.initState();
    _loadBirthdays();
  }

  // Doğum günlerini yükle
  Future<void> _loadBirthdays() async {
    setState(() {
      isLoadingBirthdays = true;
    });

    try {
      QuerySnapshot membersSnapshot = await _firestore.collection('uyelerim').get();
      
      List<Map<String, dynamic>> todayBirthdaysList = [];
      List<Map<String, dynamic>> upcomingBirthdaysList = [];
      
      DateTime today = DateTime.now();
      String todayFormatted = DateFormat('dd-MM').format(today);
      
      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        String? birthDate = memberData['birthDate'];
        
        if (birthDate != null && birthDate.isNotEmpty) {
          try {
            // Doğum tarihini parse et
            DateTime birthDateTime = DateFormat('dd-MM-yyyy').parse(birthDate);
            String birthDayMonth = DateFormat('dd-MM').format(birthDateTime);
            
            // Bugün doğum günü olanlar
            if (birthDayMonth == todayFormatted) {
              todayBirthdaysList.add({
                'name': memberData['name'] ?? 'Bilinmeyen',
                'birthDate': birthDate,
                'age': today.year - birthDateTime.year,
                'phoneNumber': memberData['phoneNumber'] ?? '',
                'belt': memberData['belt'] ?? '',
              });
            } else {
              // Yaklaşan doğum günleri (önümüzdeki 30 gün içinde)
              DateTime nextBirthday = DateTime(today.year, birthDateTime.month, birthDateTime.day);
              if (nextBirthday.isBefore(today)) {
                nextBirthday = DateTime(today.year + 1, birthDateTime.month, birthDateTime.day);
              }
              
              int daysUntilBirthday = nextBirthday.difference(today).inDays;
              if (daysUntilBirthday <= 30 && daysUntilBirthday > 0) {
                upcomingBirthdaysList.add({
                  'name': memberData['name'] ?? 'Bilinmeyen',
                  'birthDate': birthDate,
                  'age': nextBirthday.year - birthDateTime.year,
                  'phoneNumber': memberData['phoneNumber'] ?? '',
                  'belt': memberData['belt'] ?? '',
                  'daysUntil': daysUntilBirthday,
                });
              }
            }
          } catch (e) {
            print('Doğum tarihi parse hatası: $e');
          }
        }
      }
      
      // Yaklaşan doğum günlerini güne göre sırala
      upcomingBirthdaysList.sort((a, b) => a['daysUntil'].compareTo(b['daysUntil']));
      
      setState(() {
        todayBirthdays = todayBirthdaysList;
        upcomingBirthdays = upcomingBirthdaysList;
        isLoadingBirthdays = false;
      });
    } catch (e) {
      print('Doğum günleri yüklenirken hata: $e');
      setState(() {
        isLoadingBirthdays = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        title: Text(
          '🎂 Doğum Günü Takip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBirthdays,
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
        child: isLoadingBirthdays
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
                      'Doğum günleri yükleniyor...',
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
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bugün doğum günü olanlar
                    if (todayBirthdays.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cake, color: Colors.green, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Bugün Doğum Günü Olanlar',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ...todayBirthdays.map((member) => _buildBirthdayCard(member, true)),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    
                    // Yaklaşan doğum günleri
                    if (upcomingBirthdays.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.orange, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Yaklaşan Doğum Günleri (30 gün)',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ...upcomingBirthdays.map((member) => _buildBirthdayCard(member, false)),
                          ],
                        ),
                      ),
                    ],
                    
                    // Doğum günü yoksa
                    if (todayBirthdays.isEmpty && upcomingBirthdays.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF000000).withOpacity(0.8),
                              Color(0xFF9A0202).withOpacity(0.8),
                              Color(0xFFC80101).withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Color(0xFFC80101).withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.cake_outlined, color: Colors.white, size: 70),
                            SizedBox(height: 20),
                            Text(
                              'Yaklaşan doğum günü yok',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Önümüzdeki 30 gün içinde doğum günü olan sporcu bulunmuyor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                          
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  // Doğum günü kartı oluştur
  Widget _buildBirthdayCard(Map<String, dynamic> member, bool isToday) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.green : Colors.orange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: (isToday ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // İsim ve yaş
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${member['age']} yaş',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: member['belt'] != null && member['belt'].isNotEmpty
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member['belt'] ?? 'Kuşak Yok',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (member['phoneNumber'] != null && member['phoneNumber'].isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    '📞 ${member['phoneNumber']}',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Tarih bilgisi
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isToday)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'BUGÜN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  '${member['daysUntil']} gün kaldı',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              SizedBox(height: 4),
              Text(
                member['birthDate'],
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
