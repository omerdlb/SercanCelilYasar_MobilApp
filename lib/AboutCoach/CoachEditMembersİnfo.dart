import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CoachEditMembersInfo extends StatefulWidget {
  final String memberId;

  const CoachEditMembersInfo({Key? key, required this.memberId})
      : super(key: key);

  @override
  _CoachEditMembersInfoState createState() => _CoachEditMembersInfoState();
}

class _CoachEditMembersInfoState extends State<CoachEditMembersInfo> {
  late TextEditingController nameController;
  late TextEditingController birthDateController;
  late TextEditingController phonenumberController;
  late TextEditingController startDateController;
  late TextEditingController endDateController;
  late TextEditingController paymentController;
  late TextEditingController lessonCountController;

  String selectedBelt = '';
  String selectedPaket = '';
  Map<String, bool> selectedGroups = {};
  bool _isLoading = true;
  bool _isIndividualLesson = false;
  List<String> _groupOptions = []; // Firebase'den çekilecek gruplar

  final List<String> _beltOptions = [
    "Beyaz",
    "Sarı",
    "Sarı-Yeşil",
    "Yeşil",
    "Yeşil-Mavi",
    "Mavi",
    "Mavi-Kırmızı",
    "Kırmızı",
    "Kırmızı-Siyah",
    "Siyah"
  ];

  final List<String> _paketOptions = [
    "1 Aylık",
    "3 Aylık",
    "6 Aylık",
  ];

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
    _fetchGroups(); // Firebase'den grupları çek
    _checkIndividualLessonStatus(); // Bireysel ders durumunu kontrol et
  }

  Future<void> _fetchMemberData() async {
    DocumentSnapshot member = await FirebaseFirestore.instance
        .collection('uyelerim')
        .doc(widget.memberId)
        .get();

    // Tüm veriyi güvenli şekilde al
    Map<String, dynamic> memberData = member.data() as Map<String, dynamic>? ?? {};

    nameController = TextEditingController(text: memberData['name'] ?? '');
    
    // birthDate alanını güvenli şekilde oku
    String birthDateValue = memberData['birthDate'] ?? '';
    birthDateController = TextEditingController(text: birthDateValue);
    
    phonenumberController = TextEditingController(
        text: (memberData['phoneNumber'] ?? '').toString().replaceAll("+90", ""));
    selectedBelt = memberData['belt'] ?? '';
    selectedPaket = memberData['paket'] ?? '';
    startDateController = TextEditingController(
        text: memberData['start_date'] != null 
            ? DateFormat("dd-MM-yyyy").format(_parseDate(memberData['start_date']))
            : '');
    endDateController = TextEditingController(
        text: memberData['end_date'] != null 
            ? DateFormat("dd-MM-yyyy").format(_parseDate(memberData['end_date']))
            : '');
    paymentController = TextEditingController();
    lessonCountController =
        TextEditingController(text: memberData['lessonCount']?.toString() ?? '');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchGroups() async {
    QuerySnapshot groupSnapshot =
        await FirebaseFirestore.instance.collection('group_lessons').get();
    _groupOptions =
        groupSnapshot.docs.map((doc) => doc['group_name'] as String).toList();

    // Üyenin mevcut gruplarını işaretle
    DocumentSnapshot member = await FirebaseFirestore.instance
        .collection('uyelerim')
        .doc(widget.memberId)
        .get();
    
    // Tüm veriyi güvenli şekilde al
    Map<String, dynamic> memberData = member.data() as Map<String, dynamic>? ?? {};
    
    if (memberData['group'] != null && memberData['group'].toString().isNotEmpty) {
      List<String> currentGroups = memberData['group'].toString().split(', ');
      selectedGroups = {
        for (var group in _groupOptions) group: currentGroups.contains(group)
      };
    } else {
      selectedGroups = {for (var group in _groupOptions) group: false};
    }

    setState(() {});
  }

  Future<void> _checkIndividualLessonStatus() async {
    DocumentSnapshot individualLessonDoc = await FirebaseFirestore.instance
        .collection('bireysel_dersler')
        .doc(widget.memberId)
        .get();

    setState(() {
      _isIndividualLesson = individualLessonDoc
          .exists; // Kullanıcı bireysel derslere kayıtlıysa true, değilse false
    });
  }

  DateTime _parseDate(String date) {
    try {
      return DateFormat("dd-MM-yyyy").parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Bilgileri Güncelle', style: TextStyle(color: Colors.white)),
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInputCard(
                      icon: Icons.person,
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: 'İsim',
                            labelStyle: TextStyle(color: Colors.black)),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.cake,
                      child: TextField(
                        controller: birthDateController,
                        decoration: InputDecoration(
                            labelText: 'Doğum Tarihi',
                            labelStyle: TextStyle(color: Colors.black)),
                        readOnly: true,
                        style: TextStyle(color: Colors.black),
                        onTap: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: birthDateController.text.isNotEmpty ? _parseDate(birthDateController.text) : DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (selectedDate != null) {
                            birthDateController.text = DateFormat("dd-MM-yyyy").format(selectedDate);
                          }
                        },
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.phone,
                      child: TextField(
                        controller: phonenumberController,
                        decoration: InputDecoration(
                            labelText: 'Telefon Numarası',
                            labelStyle: TextStyle(color: Colors.black)),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.sports_martial_arts,
                      child: DropdownButtonFormField<String>(
                        value: selectedBelt,
                        items: _beltOptions.map((belt) {
                          return DropdownMenuItem(
                            value: belt,
                            child: Text(belt,
                                style: TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedBelt = value!;
                          });
                        },
                        decoration: InputDecoration(
                            labelText: 'Kuşak',
                            labelStyle: TextStyle(color: Colors.black)),
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.book,
                      child: DropdownButtonFormField<String>(
                        value: selectedPaket,
                        items: _paketOptions.map((paket) {
                          return DropdownMenuItem(
                            value: paket,
                            child: Text(paket,
                                style: TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPaket = value!;
                          });
                        },
                        decoration: InputDecoration(
                            labelText: 'Paket',
                            labelStyle: TextStyle(color: Colors.black)),
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.groups,
                      child: Column(
                        children: _groupOptions.map((group) {
                          return CheckboxListTile(
                            title: Text(group,
                                style: TextStyle(color: Colors.black)),
                            value: selectedGroups[group],
                            onChanged: (value) {
                              setState(() {
                                selectedGroups[group] = value ?? false;
                              });
                            },
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.calendar_today,
                      child: TextField(
                        controller: startDateController,
                        decoration: InputDecoration(
                            labelText: 'Üyelik Başlama Tarihi',
                            labelStyle: TextStyle(color: Colors.black)),
                        readOnly: true,
                        style: TextStyle(color: Colors.black),
                        onTap: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _parseDate(startDateController.text),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );

                          if (selectedDate != null) {
                            startDateController.text =
                                DateFormat("dd-MM-yyyy").format(selectedDate);
                          }
                        },
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.calendar_today,
                      child: TextField(
                        controller: endDateController,
                        decoration: InputDecoration(
                            labelText: 'Üyelik Sonlanma Tarihi',
                            labelStyle: TextStyle(color: Colors.black)),
                        readOnly: true,
                        style: TextStyle(color: Colors.black),
                        onTap: () async {
                          DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _parseDate(endDateController.text),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );

                          if (selectedDate != null) {
                            endDateController.text =
                                DateFormat("dd-MM-yyyy").format(selectedDate);
                          }
                        },
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.payment,
                      child: TextField(
                        controller: paymentController,
                        decoration: InputDecoration(
                            labelText: 'Ödeme Miktarı',
                            labelStyle: TextStyle(color: Colors.black)),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    _buildInputCard(
                      icon: Icons.school,
                      child: CheckboxListTile(
                        title: Text('Bireysel Derslere Kayıtlı',
                            style: TextStyle(color: Colors.black)),
                        value: _isIndividualLesson,
                        onChanged: (value) {
                          setState(() {
                            _isIndividualLesson = value ?? false;
                          });
                        },
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                      ),
                    ),
                    if (_isIndividualLesson)
                      _buildInputCard(
                        icon: Icons.school,
                        child: TextField(
                          controller: lessonCountController,
                          decoration: InputDecoration(
                              labelText: 'Kalan Ders Sayısı',
                              labelStyle: TextStyle(color: Colors.black)),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateMember,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      child: Text('Güncelle',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInputCard({required IconData icon, required Widget child}) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            SizedBox(width: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Future<void> _updateMember() async {
    // Seçilen grupların listesi
    List<String> selectedGroupNames = selectedGroups.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    // Üyenin mevcut gruplarını al
    DocumentSnapshot member = await FirebaseFirestore.instance
        .collection('uyelerim')
        .doc(widget.memberId)
        .get();
    List<String> oldGroups = member['group']?.split(', ') ?? [];

    // Eski gruplardan üyeyi sil
    for (String oldGroup in oldGroups) {
      if (!selectedGroupNames.contains(oldGroup)) {
        await _removeMemberFromGroup(oldGroup);
      }
    }

    // Yeni gruplara üyeyi ekle
    for (String newGroup in selectedGroupNames) {
      if (!oldGroups.contains(newGroup)) {
        await _addMemberToGroup(newGroup);
      }
    }

    // Üyenin ana bilgilerini güncelle
    await FirebaseFirestore.instance
        .collection('uyelerim')
        .doc(widget.memberId)
        .update({
      'name': nameController.text,
      'birthDate': birthDateController.text,
      'belt': selectedBelt,
      'paket': selectedPaket,
      'group': selectedGroupNames.join(', '),
      'start_date': startDateController.text,
      'end_date': endDateController.text,
      'phoneNumber': "+90${phonenumberController.text}",
      'isIndividualLesson': _isIndividualLesson,
      // Bireysel ders durumunu kaydet
    });

    // Ödeme bilgisi ekle
    if (paymentController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('kazanc').add({
        'paymentAmount': double.parse(paymentController.text),
        'group': selectedGroupNames.join(', '),
        'date': DateFormat("dd-MM-yyyy").format(DateTime.now()),
        'name': nameController.text,
      });
    }

    // Bireysel ders sayısını güncelle
    if (_isIndividualLesson && lessonCountController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('uyelerim')
          .doc(widget.memberId)
          .update({
        'lessonCount': int.parse(lessonCountController.text),
      });

      // Bireysel derslere ekle
      await _addMemberToIndividualLessons();
    } else if (!_isIndividualLesson) {
      // Bireysel derslerden çıkar (güvenli silme)
      try {
        await _removeMemberFromIndividualLessons();
      } catch (e) {
        // Belge yoksa hata verme
      }
    }

    Navigator.of(context).pop();
  }

  Future<void> _removeMemberFromGroup(String groupName) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('group_lessons')
        .where('group_name', isEqualTo: groupName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentReference groupRef = querySnapshot.docs.first.reference;
      await groupRef.collection('grup_uyeleri').doc(widget.memberId).delete();
    }
  }

  Future<void> _addMemberToGroup(String groupName) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('group_lessons')
        .where('group_name', isEqualTo: groupName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentReference groupRef = querySnapshot.docs.first.reference;
      await groupRef.collection('grup_uyeleri').doc(widget.memberId).set({
        'name': nameController.text,
        'birthDate': birthDateController.text,
        'belt': selectedBelt,
        'uid': widget.memberId,
        'phoneNumber': "+90${phonenumberController.text}",
      });
    }
  }

  Future<void> _addMemberToIndividualLessons() async {
    await FirebaseFirestore.instance
        .collection('bireysel_dersler')
        .doc(widget.memberId)
        .set({
      'bireyselders_name': 'Özel Ders: ${nameController.text}',
      'uid': widget.memberId,
      'name': nameController.text,
      'birthDate': birthDateController.text,
      'phoneNumber': "+90${phonenumberController.text}",
      'lessonCount': int.parse(lessonCountController.text),
    });
  }

  Future<void> _removeMemberFromIndividualLessons() async {
    await FirebaseFirestore.instance
        .collection('bireysel_dersler')
        .doc(widget.memberId)
        .delete();
  }
}
