import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personaltrainer/AboutCoach/BeltExam.dart';
import 'package:personaltrainer/AboutCoach/CoachGroupLessonsPage.dart';
import 'package:personaltrainer/AboutCoach/CoachProfile.dart';
import 'package:personaltrainer/AboutCoach/CoachSeeOrders_Page.dart';
import 'package:personaltrainer/AboutCoach/Coach_Create_Announcement.dart';
import 'package:personaltrainer/AboutCoach/Coach_Kazanclar.dart';
import 'package:personaltrainer/AboutCoach/Coach_set_lisance.dart';
import 'package:personaltrainer/AboutCoach/MembersPage.dart';
import 'package:personaltrainer/AboutCoach/AttendancePage.dart';
import 'package:personaltrainer/AboutCoach/AbsentMembersPage.dart';

class CoachHomePage extends StatefulWidget {
  const CoachHomePage({super.key});

  @override
  _CoachHomePageState createState() => _CoachHomePageState();
}

class _CoachHomePageState extends State<CoachHomePage> {
  final int daysInMonth = DateTime.now().day;
  DateTime selectedDate = DateTime.now();
  String? _selectedTrainerUid; // Seçilen antrenörün UID'sini tutmak için değişken

  // Month and year selection variables
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<int> _years = List.generate(5, (index) => DateTime.now().year - 2 + index);
  List<String> _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedDate();
  }

  void _updateSelectedDate() {
    // Make sure the day doesn't exceed the days in the selected month
    int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    int day = selectedDate.day > daysInMonth ? daysInMonth : selectedDate.day;

    setState(() {
      selectedDate = DateTime(_selectedYear, _selectedMonth, day);
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentMonth = _months[_selectedMonth - 1];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Month dropdown
            DropdownButton<String>(
              value: currentMonth,
              dropdownColor: Colors.black,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              style: TextStyle(color: Colors.white, fontSize: 20),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMonth = _months.indexOf(newValue!) + 1;
                  _updateSelectedDate();
                });
              },
              items: _months.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(width: 10),
            // Year dropdown
            DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: Colors.black,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              style: TextStyle(color: Colors.white, fontSize: 20),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedYear = newValue!;
                  _updateSelectedDate();
                });
              },
              items: _years.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          // Antrenör filtreleme butonu
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              _showTrainerFilterDialog();
            },
          ),
        ],
      ),
      body: Container(
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
            // Tarih kutuları
            _buildDateSelector(),
            // Grup derslerini listele
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('group_lessons').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final lessons = snapshot.data!.docs;
                  final today = DateFormat.EEEE('tr_TR').format(selectedDate);

                  // Seçilen tarihe ve antrenöre göre dersleri filtrele
                  final selectedLessons = lessons.where((lesson) {
                    Map<String, String> daysWithTime = Map<String, String>.from(lesson['days_with_time'] ?? {});
                    bool matchesDay = daysWithTime.containsKey(today);
                    bool matchesTrainer = _selectedTrainerUid == null || lesson['traineruid'] == _selectedTrainerUid;
                    return matchesDay && matchesTrainer;
                  }).toList();

                  if (selectedLessons.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedTrainerUid != null 
                          ? 'Seçilen antrenörün bu tarihte dersi bulunmuyor.'
                          : 'Bu tarihte ders bulunmuyor.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: selectedLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = selectedLessons[index];
                      bool isToday = selectedDate.year == DateTime.now().year &&
                          selectedDate.month == DateTime.now().month &&
                          selectedDate.day == DateTime.now().day;

                      bool isPastDay = selectedDate.isBefore(DateTime.now().subtract(Duration(days: 1)));

                      Map<String, String> daysWithTime = Map<String, String>.from(lesson['days_with_time'] ?? {});
                      String? lessonTime = daysWithTime[today];

                      return Card(
                        color: Colors.white.withOpacity(1),
                        shadowColor: Colors.black,
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(
                            lesson['group_name'],
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 23,
                            ),
                          ),
                          subtitle: Text(
                            'Günler: ${daysWithTime.keys.join(', ')}\nSaat: ${lessonTime ?? "Belirtilmemiş"}\nAntrenör: ${lesson['trainer']}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                          ),
                          trailing: isToday || isPastDay
                              ? PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.black,
                            ),
                            onSelected: (value) {
                              if (value == 'take_attendance') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendancePage(
                                      lessonId: lesson.id,
                                      selectedDate: selectedDate,
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return {'take_attendance'}.map((String choice) {
                                return PopupMenuItem<String>(
                                  value: choice,
                                  child: Text('Yoklama Al', style: TextStyle(color: Colors.black),),
                                );
                              }).toList();
                            },
                            color: Colors.white,
                          )
                              : null,
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

  Widget _buildDateSelector() {
    // Get days in the selected month
    int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Row(
            children: List.generate(daysInMonth, (index) {
              int day = index + 1;
              bool isToday = day == DateTime.now().day &&
                  _selectedMonth == DateTime.now().month &&
                  _selectedYear == DateTime.now().year;
              bool isSelected = selectedDate.day == day;

              // Get day abbreviation
              String dayAbbreviation = DateFormat.E('tr_TR').format(
                DateTime(_selectedYear, _selectedMonth, day),
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = DateTime(_selectedYear, _selectedMonth, day);
                  });
                  print("Seçilen gün: $day");
                },
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      width: isToday ? 50 : 40,
                      height: isToday ? 50 : 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : (isToday ? Colors.green : Colors.white),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: isToday ? 18 : 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      dayAbbreviation,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildBottomBarIcon(
              context,
              icon: Icons.group_add,
              label: 'Ders Oluştur',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GroupLessonsPage()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.people,
              label: 'Üyelerim',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MembersPage()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.person_off,
              label: 'Devamsız Kişiler',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AbsentMembersPage()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.badge,
              label: 'Lisans',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CoachSetLisance()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.announcement,
              label: 'Duyurular',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CoachCreateAnnouncement()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.school,
              label: 'Kuşak Sınavı',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BeltExamPage()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.shopping_cart,
              label: 'Malzeme Siparişi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>  CoachSeeOrders()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.pie_chart,
              label: 'Kazançlarım',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>  CoachKazanclarimPage()),
                );
              },
            ),
            _buildBottomBarIcon(
              context,
              icon: Icons.account_circle,
              label: 'Profilim',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>  CoachProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarIcon(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

  // Antrenör filtreleme dialog'unu göster
  void _showTrainerFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Antrenör Filtrele'),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('admins').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final trainers = snapshot.data!.docs;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Tüm Dersler'),
                      leading: Radio<String?>(
                        value: null,
                        groupValue: _selectedTrainerUid,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedTrainerUid = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    ...trainers.map((trainer) {
                      return ListTile(
                        title: Text(trainer['name']),
                        leading: Radio<String?>(
                          value: trainer.id, // Antrenörün UID'sini kullan
                          groupValue: _selectedTrainerUid,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedTrainerUid = value;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}