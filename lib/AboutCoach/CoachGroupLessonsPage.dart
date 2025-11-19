import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


import 'OldAttendancePage.dart';

class GroupLessonsPage extends StatefulWidget {
  const GroupLessonsPage({super.key});

  @override
  _GroupLessonsPageState createState() => _GroupLessonsPageState();
}

class _GroupLessonsPageState extends State<GroupLessonsPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isListExpanded = false;
  bool isAdmin = false;
  bool isHelperCoach = false;
  bool isLoading = true; // Yükleme durumu için yeni değişken
  String? _selectedTrainer;
  String? _selectedTrainerUid;
  
  // Yetki değişkenleri
  bool canAddGroup = false;
  bool canEditGroup = false;
  bool canDeleteGroup = false;
  bool canViewMembers = false;
  bool canViewAttendance = false;

  @override
  void initState() {
    super.initState();
    checkUserRole();
  }

  Future<int> _getGroupMemberCount(String groupId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('group_lessons')
        .doc(groupId)
        .collection('grup_uyeleri')
        .get();
    return snapshot.docs.length;
  }

  Future<void> checkUserRole() async {
    setState(() {
      isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await Future.delayed(Duration(milliseconds: 200));
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        if (adminDoc.exists && adminDoc.data() != null) {
          Map<String, dynamic> userData = adminDoc.data() as Map<String, dynamic>;
          
          setState(() {
            isAdmin = userData['admin'] == true;
            isHelperCoach = userData['helpercoach'] == true;
            
            // Admin ise tüm yetkileri ver
            if (isAdmin) {
              canAddGroup = true;
              canEditGroup = true;
              canDeleteGroup = true;
              canViewMembers = true;
              canViewAttendance = true;
            } 
            // Helper coach ise yetkileri kontrol et
            else if (isHelperCoach) {
              canAddGroup = userData['canCreateLesson'] == true;
              canEditGroup = userData['canEditLesson'] == true;
              canDeleteGroup = userData['canDeleteLesson'] == true;
              canViewMembers = userData['canViewLessonMembers'] == true;
              canViewAttendance = userData['canViewLessonMembers'] == true;
            }
            isLoading = false; // Yükleme bitti
          });
        } else {
          setState(() {
            isAdmin = false;
            isHelperCoach = false;
            canAddGroup = false;
            canEditGroup = false;
            canDeleteGroup = false;
            canViewMembers = false;
            canViewAttendance = false;
            isLoading = false; // Yükleme bitti
          });
        }
      } catch (e) {
        setState(() {
          isAdmin = false;
          isHelperCoach = false;
          canAddGroup = false;
          canEditGroup = false;
          canDeleteGroup = false;
          canViewMembers = false;
          canViewAttendance = false;
          isLoading = false; // Yükleme bitti
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        isHelperCoach = false;
        canAddGroup = false;
        canEditGroup = false;
        canDeleteGroup = false;
        canViewMembers = false;
        canViewAttendance = false;
        isLoading = false; // Yükleme bitti
      });
    }
  }

  final List<String> _daysOfWeek = [
    'Pazar',
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi'
  ];

  Map<String, String?> _selectedDaysWithTime = {
    'Pazar': null,
    'Pazartesi': null,
    'Salı': null,
    'Çarşamba': null,
    'Perşembe': null,
    'Cuma': null,
    'Cumartesi': null,
  };

  String? _editingGroupId;

  Future<void> _pickTime(String day) async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF000000),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.normal),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(backgroundColor: Colors.white)),
            dialogBackgroundColor: Colors.white,
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Color(0xFF000000)),
              headlineMedium: TextStyle(color: Color(0xFF000000)),
            ),
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: TextStyle(color: Color(0xFF000000)),
              backgroundColor: Colors.white,
              dialHandColor: Color(0xFF000000),
              dialBackgroundColor: Colors.white,
            ), colorScheme: ColorScheme.light().copyWith(
            primary: Color(0xFF000000),
            onPrimary: Colors.white,
            surface: Colors.white,
          ).copyWith(secondary: Color(0xFF000000)),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedDaysWithTime[day] = time.format(context);
      });
    }
  }

  Future<void> _saveGroupLesson() async {
    String groupName = _groupNameController.text.trim();


    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen grup dersi ismini giriniz.')),
      );
      return;
    }


    // Seçilen günleri ve saatleri filtrele
    Map<String, String?> selectedDaysWithTime = {};
    _selectedDaysWithTime.forEach((day, time) {
      if (time != null) {
        selectedDaysWithTime[day] = time;
      }
    });

    if (selectedDaysWithTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haftanın günlerini ve saatlerini seçiniz.')),
      );
      return;
    }

    if (_selectedTrainer == null || _selectedTrainerUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir antrenör seçiniz.')),
      );
      return;
    }

    try {
      final lessonRef = FirebaseFirestore.instance.collection('group_lessons');

      if (_editingGroupId == null) {
        await lessonRef.doc(groupName).set({
          'group_name': groupName,
          'days_with_time': selectedDaysWithTime,
          'trainer': _selectedTrainer,
          'traineruid': _selectedTrainerUid,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup dersi başarıyla kaydedildi.')),
        );
      } else {
        await lessonRef.doc(_editingGroupId).update({
          'group_name': groupName,
          'days_with_time': selectedDaysWithTime,
          'trainer': _selectedTrainer,
          'traineruid': _selectedTrainerUid,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup dersi başarıyla güncellendi.')),
        );
      }

      _clearInputs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  void _clearInputs() {
    _groupNameController.clear();
    setState(() {
      _selectedDaysWithTime = {
        'Pazar': null,
        'Pazartesi': null,
        'Salı': null,
        'Çarşamba': null,
        'Perşembe': null,
        'Cuma': null,
        'Cumartesi': null,
      };
      _selectedTrainer = null;
      _selectedTrainerUid = null;
      _editingGroupId = null;
    });
  }

  void _deleteGroupLesson(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grup Dersini Sil'),
          content: const Text('Bu grup dersini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('group_lessons')
            .doc(id)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup dersi başarıyla silindi.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    }
  }


  void _toggleListExpansion() {
    setState(() {
      _isListExpanded = !_isListExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Yönetimi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_list') {
                _toggleListExpansion();
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_list',
                child: Text(_isListExpanded ? 'Grup Dersi Oluştur' : 'Tüm Dersleri Görüntüle'),
              ),
            ],
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
        child: isLoading 
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('group_lessons').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Grup dersleri yükleniyor...',
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
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Bir hata oluştu: ${snapshot.error}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz grup dersi bulunmuyor.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yeni bir grup dersi oluşturmak için yukarıdaki formu kullanabilirsiniz.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final lessons = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (!_isListExpanded) ...[
                        TextField(
                          controller: _groupNameController,
                          cursorColor: Colors.white, // İmleç rengi beyaz
                          style: TextStyle(color: Colors.white), // Metin rengi beyaz
                          decoration: InputDecoration(
                            labelText: 'Grup Dersi',
                            labelStyle: TextStyle(color: Colors.white), // Label rengi beyaz
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white), // Normal durumda kenarlık rengi beyaz
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white), // Odaklandığında kenarlık rengi beyaz
                            ),
                            hintStyle: TextStyle(color: Colors.white), // Hint metni rengi beyaz (isteğe bağlı)
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Haftanın Günlerini Seçin:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _daysOfWeek.map((day) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  side: BorderSide(color: Colors.white, width: 2),
                                  checkColor: Colors.black,
                                  value: _selectedDaysWithTime[day] != null,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedDaysWithTime[day] = null; // Gün seçildiğinde saat bilgisini sıfırla
                                      } else {
                                        _selectedDaysWithTime.remove(day); // Gün seçimi kaldırıldığında saat bilgisini sil
                                      }
                                    });
                                  },
                                  activeColor: Colors.white,
                                ),
                                Text(day, style: TextStyle(color: Colors.white)),
                                if (_selectedDaysWithTime[day] != null) // Eğer gün seçiliyse saat bilgisini göster
                                  Text(
                                    ' (${_selectedDaysWithTime[day]})',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.access_time, color: Colors.white),
                                  onPressed: () {
                                    _pickTime(day); // Gün için saat seçimi yap
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Antrenör Seçin:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('admins')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final trainers = snapshot.data!.docs;

                            if (trainers.isEmpty) {
                              return Column(
                                children: [
                                  const Text('Antrenör bulunamadı.', style: TextStyle(color: Colors.white)),
                                ],
                              );
                            }
                            return Expanded(
                              child: ListView(
                                children: trainers.map((trainer) {
                                  return ListTile(
                                    title: Text(trainer['name'], style: TextStyle(color: Colors.white)),
                                    leading: Radio<String>(
                                      value: trainer['name'],
                                      groupValue: _selectedTrainer,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedTrainer = value;
                                          _selectedTrainerUid = trainer.id;
                                        });
                                      },
                                      activeColor: Colors.white,
                                      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.white;
                                        }
                                        return Colors.white;
                                      }),
                                      overlayColor: WidgetStateProperty.all(Colors.white),
                                      focusColor: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        if (!canAddGroup && !isAdmin)
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Grup dersi oluşturma yetkiniz bulunmuyor.',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: (canAddGroup || isAdmin) ? _saveGroupLesson : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (canAddGroup || isAdmin) ? Color(0xFF333333) : Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              child: Text(
                                _editingGroupId == null ? 'Kaydet' : 'Güncelle',
                                style: TextStyle(
                                  color: (canAddGroup || isAdmin) ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_editingGroupId != null)
                              ElevatedButton(
                                onPressed: _clearInputs,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                child: const Text('Vazgeç'),
                              ),
                          ],
                        ),
                      ],
                      if (_isListExpanded) ...[
                        Expanded(
                          child: ListView.builder(
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              return Card(
                                color: Colors.white.withOpacity(1),
                                shadowColor: Colors.black,
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text(
                                    lesson['group_name'],
                                    style: const TextStyle(
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 23,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Günler: ${lesson['days_with_time'].keys.join(', ')}\nSaatler: ${lesson['days_with_time'].values.join(', ')}\nAntrenör: ${lesson['trainer']}',
                                    style: const TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 18,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FutureBuilder<int>(
                                        future: _getGroupMemberCount(lesson.id),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return const Icon(Icons.error, color: Colors.red);
                                          } else {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.people, color: Colors.black),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${snapshot.data}',
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      if (isAdmin || canEditGroup || canDeleteGroup || canViewMembers || canViewAttendance)
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.black),
                                          onSelected: (value) {
                                            if (value == 'delete' && (canDeleteGroup || isAdmin)) {
                                              _deleteGroupLesson(lesson.id);
                                            } else if (value == 'view_members' && (canViewMembers || isAdmin)) {
                                              _viewMembers(lesson.id);
                                            } else if (value == 'view_attendance' && (canViewAttendance || isAdmin)) {
                                              _viewAttendance(lesson.id);
                                            } else if (value == 'edit' && (canEditGroup || isAdmin)) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditGroupLessonPage(
                                                    groupId: lesson.id,
                                                    groupName: lesson['group_name'],
                                                    daysWithTime: lesson['days_with_time'],
                                                    trainer: lesson['trainer'],
                                                    traineruid: lesson['traineruid'],
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (BuildContext context) {
                                            List<PopupMenuItem<String>> items = [];
                                            
                                            if (canDeleteGroup || isAdmin) {
                                              items.add(const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Text('Grup Dersini Sil', style: TextStyle(color: Colors.black)),
                                              ));
                                            }
                                            
                                            if (canViewMembers || isAdmin) {
                                              items.add(const PopupMenuItem<String>(
                                                value: 'view_members',
                                                child: Text('Üyeleri Gör', style: TextStyle(color: Colors.black)),
                                              ));
                                            }
                                            
                                            if (canViewAttendance || isAdmin) {
                                              items.add(const PopupMenuItem<String>(
                                                value: 'view_attendance',
                                                child: Text('Yoklamaları Gör', style: TextStyle(color: Colors.black)),
                                              ));
                                            }
                                            
                                            if (canEditGroup || isAdmin) {
                                              items.add(const PopupMenuItem<String>(
                                                value: 'edit',
                                                child: Text('Grubu Düzenle', style: TextStyle(color: Colors.black)),
                                              ));
                                            }
                                            
                                            return items;
                                          },
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  void _viewMembers(String groupId) async {
    // Önce yetki kontrolü yap
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (adminDoc.exists && adminDoc.data() != null) {
          Map<String, dynamic> userData = adminDoc.data() as Map<String, dynamic>;
          bool canView = userData['admin'] == true || 
                        (userData['helpercoach'] == true && userData['canViewLessonMembers'] == true);
          
          if (canView) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MembersListPage(groupId: groupId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Grup üyelerini görüntüleme yetkiniz bulunmuyor.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print("Yetki kontrolünde hata: $e");
      }
    }
  }

  void _viewAttendance(String groupId) async {
    // Önce yetki kontrolü yap
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (adminDoc.exists && adminDoc.data() != null) {
          Map<String, dynamic> userData = adminDoc.data() as Map<String, dynamic>;
          bool canView = userData['admin'] == true || 
                        (userData['helpercoach'] == true && userData['canViewLessonMembers'] == true);
          
          if (canView) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OldAttendancePage(groupId: groupId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yoklamaları görüntüleme yetkiniz bulunmuyor.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print("Yetki kontrolünde hata: $e");
      }
    }
  }
}

class MembersListPage extends StatefulWidget {
  final String groupId;

  const MembersListPage({super.key, required this.groupId});

  @override
  _MembersListPageState createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isAdmin = false;
  bool canViewMembers = false;
  bool canRemoveMembers = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkUserRole();
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
            canViewMembers = isAdmin || (userData['helpercoach'] == true && userData['canViewLessonMembers'] == true);
            canRemoveMembers = isAdmin || (userData['helpercoach'] == true && userData['canRemoveLessonMembers'] == true);
            isLoading = false;
          });
        } else {
          setState(() {
            isAdmin = false;
            canViewMembers = false;
            canRemoveMembers = false;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          isAdmin = false;
          canViewMembers = false;
          canRemoveMembers = false;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        canViewMembers = false;
        canRemoveMembers = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!canViewMembers && !isAdmin) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
          title: const Text('Grup Üyeleri', style: TextStyle(color: Colors.white)),
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
          child: Center(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Grup üyelerini görüntüleme yetkiniz bulunmuyor.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: const Text('Grup Üyeleri', style: TextStyle(color: Colors.white)),
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
        child: isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Yetkiler kontrol ediliyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_lessons')
                  .doc(widget.groupId)
                  .collection('grup_uyeleri')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Grup üyeleri yükleniyor...',
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
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Üyeler yüklenirken bir hata oluştu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Lütfen daha sonra tekrar deneyiniz',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final members = snapshot.data!.docs;

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Grupta henüz üye bulunmuyor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yeni üyeler eklemek için ana sayfaya dönebilirsiniz',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          member['name'],
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF000000),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        trailing: canRemoveMembers || isAdmin
                          ? IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                _showRemoveMemberDialog(context, widget.groupId, member.id);
                              },
                            )
                          : null,
                      ),
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, String groupId, String memberId) async {
    if (!canRemoveMembers && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üye kaldırma yetkiniz bulunmuyor.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Üyeyi Gruptan Çıkar"),
          content: Text("Bu üyeyi gruptan çıkarmak istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text("Hayır", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("Evet", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('group_lessons')
            .doc(groupId)
            .collection('grup_uyeleri')
            .doc(memberId)
            .delete();

        // Üyenin profilindeki grup bilgisini güncelle
        DocumentSnapshot memberDoc = await FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(memberId)
            .get();

        if (memberDoc.exists) {
          String currentGroups = memberDoc['group'] ?? '';
          List<String> groupsList = currentGroups.split(', ');
          groupsList.removeWhere((group) => group == widget.groupId);
          String updatedGroupsString = groupsList.join(', ');

          await FirebaseFirestore.instance
              .collection('uyelerim')
              .doc(memberId)
              .update({
            'group': updatedGroupsString,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üye gruptan başarıyla çıkarıldı.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    }
  }
}

class OldAttendancePage extends StatelessWidget {
  final String groupId;

  const OldAttendancePage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, // Geri git ikonu ve diğer ikonların rengi beyaz
        ),
        backgroundColor:  Colors.black,
        title: const Text('Eski Yoklamalar',style: TextStyle(color: Colors.white),),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('group_lessons')
              .doc(groupId)
              .collection('yoklamalar')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final attendanceRecords = snapshot.data!.docs;

            return ListView.builder(
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = attendanceRecords[index];
                return ListTile(
                  title: Text(record.id, style: TextStyle(color: Colors.white ,fontWeight: FontWeight.bold),),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceDetailPage(
                          groupId: groupId,
                          date: record.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
class EditGroupLessonPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final Map<String, dynamic> daysWithTime;
  final String trainer;
  final String traineruid;

  const EditGroupLessonPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.daysWithTime,
    required this.trainer,
    required this.traineruid,
  });

  @override
  _EditGroupLessonPageState createState() => _EditGroupLessonPageState();
}

class _EditGroupLessonPageState extends State<EditGroupLessonPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String?> _selectedDaysWithTime = {};
  String? _selectedTrainer;
  String? _selectedTrainerUid;
  bool isAdmin = false;
  bool canEditGroup = false;
  bool isLoading = true; // Yükleme durumu için yeni değişken
  final List<String> _daysOfWeek = [
    'Pazar',
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi'
  ];

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.groupName;
    _selectedDaysWithTime = widget.daysWithTime.map<String, String?>(
      (key, value) => MapEntry(key, value.toString()),
    );
    _selectedTrainer = widget.trainer;
    _selectedTrainerUid = widget.traineruid;
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    setState(() {
      isLoading = true; // Yükleme başladı
    });
    
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await Future.delayed(Duration(milliseconds: 200));
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        if (adminDoc.exists && adminDoc.data() != null) {
          Map<String, dynamic> userData = adminDoc.data() as Map<String, dynamic>;
          
          setState(() {
            isAdmin = userData['admin'] == true;
            canEditGroup = isAdmin || (userData['helpercoach'] == true && userData['canEditLesson'] == true);
            isLoading = false; // Yükleme bitti
          });
        } else {
          setState(() {
            isAdmin = false;
            canEditGroup = false;
            isLoading = false; // Yükleme bitti
          });
        }
      } catch (e) {
        setState(() {
          isAdmin = false;
          canEditGroup = false;
          isLoading = false; // Yükleme bitti
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        canEditGroup = false;
        isLoading = false; // Yükleme bitti
      });
    }
  }

  Future<void> _pickTime(String day) async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF333333),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.normal),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(backgroundColor: Colors.white)),
            dialogBackgroundColor: Colors.white,
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Color(0xFF333333)),
              headlineMedium: TextStyle(color: Color(0xFF333333)),
            ),
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: TextStyle(color: Color(0xFF333333)),
              backgroundColor: Colors.white,
              dialHandColor: Color(0xFF333333),
              dialBackgroundColor: Colors.white,
            ), colorScheme: ColorScheme.light().copyWith(
            primary: Color(0xFF333333),
            onPrimary: Colors.white,
            surface: Colors.white,
          ).copyWith(secondary: Color(0xFF333333)),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedDaysWithTime[day] = time.format(context);
      });
    }
  }

  Future<void> _saveGroupLesson() async {
    if (!canEditGroup && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grup düzenleme yetkiniz bulunmuyor.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen grup dersi ismini giriniz.')),
      );
      return;
    }

    Map<String, String?> selectedDaysWithTime = {};
    _selectedDaysWithTime.forEach((day, time) {
      if (time != null) {
        selectedDaysWithTime[day] = time;
      }
    });

    if (selectedDaysWithTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haftanın günlerini ve saatlerini seçiniz.')),
      );
      return;
    }

    if (_selectedTrainer == null || _selectedTrainerUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir antrenör seçiniz.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('group_lessons')
          .doc(widget.groupId)
          .update({
        'group_name': groupName,
        'days_with_time': selectedDaysWithTime,
        'trainer': _selectedTrainer,
        'traineruid': _selectedTrainerUid,
      });

      // Grup üyelerini al
      QuerySnapshot groupMembersSnapshot = await FirebaseFirestore.instance
          .collection('group_lessons')
          .doc(widget.groupId)
          .collection('grup_uyeleri')
          .get();

      // Her bir üyenin profilindeki grup adını güncelle
      for (var memberDoc in groupMembersSnapshot.docs) {
        String userId = memberDoc.id;

        // Kullanıcının uyelerim koleksiyonundaki grup adını güncelle
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          String currentGroups = userDoc['group'] ?? '';
          List<String> groupsList = currentGroups.split(', ');

          // Eski grup adını yeni grup adıyla değiştir
          groupsList = groupsList.map((group) {
            return group == widget.groupName ? groupName : group;
          }).toList();

          // Güncellenmiş grupları string olarak birleştir
          String updatedGroupsString = groupsList.join(', ');

          // Kullanıcının grup bilgisini güncelle
          await FirebaseFirestore.instance
              .collection('uyelerim')
              .doc(userId)
              .update({
            'group': updatedGroupsString,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grup dersi başarıyla güncellendi.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  void _addDay(String day) {
    setState(() {
      _selectedDaysWithTime[day] = null; // Yeni gün ekle, saat null olarak başlat
    });
  }

  void _removeDay(String day) {
    setState(() {
      _selectedDaysWithTime.remove(day); // Günü kaldır
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black,
        title: const Text('Grubu Düzenle', style: TextStyle(color: Colors.white)),
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
        child: isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Yetkiler kontrol ediliyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!canEditGroup && !isAdmin)
                    Container(
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Grup düzenleme yetkiniz bulunmuyor.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (canEditGroup || isAdmin) ...[
                    TextField(
                      cursorColor: Colors.white,
                      controller: _groupNameController,
                      style: TextStyle(color: Colors.white), // Metin rengi beyaz
                      decoration: InputDecoration(
                        labelText: 'Grup Dersi İsmi',
                        labelStyle: TextStyle(color: Colors.white), // Label rengi beyaz
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white), // Kenarlık rengi beyaz
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white), // Odaklandığında kenarlık rengi beyaz
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Haftanın Günlerini Seçin:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _selectedDaysWithTime.keys.map((day) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _selectedDaysWithTime[day] != null,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedDaysWithTime[day] = null;
                                  } else {
                                    _selectedDaysWithTime.remove(day);
                                  }
                                });
                              },

                              activeColor: Colors.white, // Checkbox rengi beyaz
                              checkColor: Colors.black, // Check işareti rengi siyah
                            ),
                            Text(day, style: TextStyle(color: Colors.white)),
                            if (_selectedDaysWithTime[day] != null)
                              Text(
                                ' (${_selectedDaysWithTime[day]})',
                                style: TextStyle(color: Colors.white),
                              ),
                            IconButton(
                              icon: Icon(Icons.access_time, color: Colors.white),
                              onPressed: () => _pickTime(day),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _removeDay(day),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: null, // Yeni gün seçimi için null
                      hint: Text(
                        'Yeni Gün Ekle',
                        style: TextStyle(color: Colors.white), // Hint metin rengi beyaz
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _addDay(newValue); // Yeni gün ekle
                        }
                      },
                      items: _daysOfWeek.map<DropdownMenuItem<String>>((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(
                            day,
                            style: TextStyle(color: Colors.black), // Açılır menüdeki metin rengi siyah
                          ),
                        );
                      }).toList(),
                      dropdownColor: Colors.white, // Açılır menü arka plan rengi beyaz
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white), // Dropdown ikon rengi beyaz
                      style: TextStyle(color: Colors.white), // Seçili öğe metin rengi beyaz
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Antrenör Seçin:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('admins')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final trainers = snapshot.data!.docs;

                        return Expanded(
                          child: ListView(
                            children: trainers.map((trainer) {
                              return ListTile(
                                title: Text(trainer['name'], style: TextStyle(color: Colors.white)),
                                leading: Radio<String>(
                                  value: trainer['name'],
                                  groupValue: _selectedTrainer,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedTrainer = value;
                                      _selectedTrainerUid = trainer.id;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return Colors.white;
                                  }),
                                  overlayColor: WidgetStateProperty.all(Colors.white),
                                  focusColor: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveGroupLesson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Buton arka plan rengi beyaz
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(color: Colors.black), // Buton metin rengi siyah
                      ),
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}