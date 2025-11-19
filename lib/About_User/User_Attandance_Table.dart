import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class UserAttendanceTable extends StatefulWidget {
  const UserAttendanceTable({super.key});

  @override
  _UserAttendanceTableState createState() => _UserAttendanceTableState();
}

class _UserAttendanceTableState extends State<UserAttendanceTable> {
  int selectedYear = DateTime.now().year;
  final Map<String, int> months = {
    'Ocak': 1,
    'Şubat': 2,
    'Mart': 3,
    'Nisan': 4,
    'Mayıs': 5,
    'Haziran': 6,
    'Temmuz': 7,
    'Ağustos': 8,
    'Eylül': 9,
    'Ekim': 10,
    'Kasım': 11,
    'Aralık': 12,
  };

  Map<String, Map<int, dynamic>> attendanceMap = {};
  Map<String, Set<int>> membershipDatesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  void _fetchAllData() {
    for (String month in months.keys) {
      _fetchAttendanceData(month, selectedYear);
      _fetchMembershipDates(month, selectedYear);
    }
  }

  Future<void> _fetchMembershipDates(String month, int year) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var membershipSnapshot = await FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(user.uid)
            .collection('üyelik_tarihleri')
            .get();

        Set<int> dates = {};
        int monthNumber = months[month]!;

        for (var doc in membershipSnapshot.docs) {
          DateTime startDate = DateFormat('dd-MM-yyyy').parse(doc['start_date']);
          DateTime endDate = DateFormat('dd-MM-yyyy').parse(doc['end_date']);

          if (startDate.year == year && startDate.month == monthNumber) {
            dates.add(startDate.day);
          }
          if (endDate.year == year && endDate.month == monthNumber) {
            dates.add(endDate.day);
          }
        }

        setState(() {
          membershipDatesMap[month] = dates;
        });
      }
    } catch (e) {
      print('Üyelik tarihleri alınırken hata: $e');
    }
  }

  Future<void> _fetchAttendanceData(String month, int year) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        int monthNumber = months[month]!;
        String startDate = DateFormat('yyyy-MM-dd').format(DateTime(year, monthNumber, 1));
        String endDate = DateFormat('yyyy-MM-dd').format(DateTime(year, monthNumber + 1, 0));

        var querySnapshot = await FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(user.uid)
            .collection('yoklamalar')
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .get();

        Map<int, dynamic> data = {};
        for (var doc in querySnapshot.docs) {
          DateTime date = DateTime.parse(doc['date']);
          data[date.day] = doc['attendance'];
        }

        setState(() {
          attendanceMap[month] = data;
        });
      }
    } catch (e) {
      print('Yoklama verisi alınırken hata: $e');
    }
  }

  List<int> _generateDaysForMonth(String month, int year) {
    int monthNumber = months[month]!;
    DateTime lastDay = DateTime(year, monthNumber + 1, 0);
    return List.generate(lastDay.day, (index) => index + 1);
  }

  Color _getDayColor(String month, int day) {
    dynamic status = attendanceMap[month]?[day];
    if (status == null) return Colors.white;
    if (status == true || status == 'katıldı') return Colors.green;
    if (status == 'izinli') return Colors.orange;
    return Colors.red;
  }

  bool _isMembershipDate(String month, int day) {
    return membershipDatesMap[month]?.contains(day) ?? false;
  }

  String _getDayName(int year, String month, int day) {
    DateTime date = DateTime(year, months[month]!, day);
    return DateFormat('E', 'tr_TR').format(date).substring(0, 3);
  }

  String _getAttendanceStatus(String month, int day) {
    dynamic status = attendanceMap[month]?[day];
    if (status == null) return '';
    if (status == true || status == 'katıldı') return 'Katıldı';
    if (status == 'izinli') return 'İzinli';
    return 'Katılmadı';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yoklama Çizelgem', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildLegendItem(Colors.green, "Devamlılık"),
                      _buildLegendItem(Colors.orange, "İzinli"),
                      _buildLegendItem(Colors.red, "Devamsızlık"),
                    ],
                  ),
                ),
              ),
              DropdownButton<int>(
                dropdownColor:  Colors.black,
                value: selectedYear,
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedYear = newValue;
                      attendanceMap.clear();
                      membershipDatesMap.clear();
                      _fetchAllData();
                    });
                  }
                },
                items: List.generate(21, (index) => DateTime.now().year - 10 + index)
                    .map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString(),style: TextStyle(color: Colors.white),),
                  );
                }).toList(),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: months.length,
                  separatorBuilder: (context, index) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    String month = months.keys.elementAt(index);
                    List<int> days = _generateDaysForMonth(month, selectedYear);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            month,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: days.length,
                          itemBuilder: (context, dayIndex) {
                            int day = days[dayIndex];
                            return Card(
                              margin: const EdgeInsets.all(2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              color: _getDayColor(month, day),
                              child: Tooltip(
                                message: _getAttendanceStatus(month, day),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      day.toString(),
                                        style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                          color: _getDayColor(month, day) == Colors.white ? Colors.black : Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _getDayName(selectedYear, month, day),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getDayColor(month, day) == Colors.white ? Colors.black : Colors.white,
                                        ),
                                    ),
                                  ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}