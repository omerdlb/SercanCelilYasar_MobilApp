import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoachCreateAnnouncement extends StatefulWidget {
  const CoachCreateAnnouncement({super.key});

  @override
  _CoachCreateAnnouncementState createState() => _CoachCreateAnnouncementState();
}

class _CoachCreateAnnouncementState extends State<CoachCreateAnnouncement> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isAdmin = false;
  bool isHelperCoach = false;
  bool canCreateAnnouncement = false;
  List<Map<String, dynamic>> todayBirthdays = [];
  bool isLoadingBirthdays = true;

  @override
  void initState() {
    super.initState();
    checkUserRole();
    _loadBirthdays();
  }

  Future<void> checkUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        setState(() {
          // Admin kontrolü
          isAdmin = adminDoc.exists && adminDoc.data() != null
              ? (adminDoc.data() as Map<String, dynamic>)['admin'] == true
              : false;

          if (isAdmin) {
            // Admin ise tüm yetkileri ver
            isHelperCoach = false;
            canCreateAnnouncement = true;
          } else {
            // Admin değilse helper coach ve yetkilerini kontrol et
            isHelperCoach = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['helpercoach'] == true
                : false;
            canCreateAnnouncement = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canCreateAnnouncement'] == true
                : false;
          }
        });
      } catch (e) {
        setState(() {
          isAdmin = false;
          isHelperCoach = false;
          canCreateAnnouncement = false;
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        isHelperCoach = false;
        canCreateAnnouncement = false;
      });
    }
  }

  Stream<QuerySnapshot> _getAnnouncements() {
    return _firestore.collection('announcements').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _loadBirthdays() async {
    try {
      setState(() {
        isLoadingBirthdays = true;
      });

      QuerySnapshot membersSnapshot = await _firestore.collection('uyelerim').get();
      List<Map<String, dynamic>> todayBirthdaysList = [];

      DateTime today = DateTime.now();

      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> member = doc.data() as Map<String, dynamic>;
        
        if (member['birthDate'] != null && member['birthDate'].isNotEmpty) {
          String birthDate = member['birthDate'];
          
          // Doğum tarihini parse et (dd-MM-yyyy formatında)
          try {
            List<String> dateParts = birthDate.split('-');
            if (dateParts.length == 3) {
              int day = int.parse(dateParts[0]);
              int month = int.parse(dateParts[1]);
              int year = int.parse(dateParts[2]);
              
              // Bu yıl için doğum günü tarihini oluştur
              DateTime thisYearBirthday = DateTime(today.year, month, day);
              
              // Bugün doğum günü mü kontrol et
              if (thisYearBirthday.day == today.day && thisYearBirthday.month == today.month) {
                // Yaş hesapla
                int age = today.year - year;
                
                todayBirthdaysList.add({
                  'name': member['name'] ?? 'İsimsiz',
                  'age': age,
                  'birthDate': birthDate,
                });
              }
            }
          } catch (e) {
            // Tarih parse edilemezse atla
            continue;
          }
        }
      }

      setState(() {
        todayBirthdays = todayBirthdaysList;
        isLoadingBirthdays = false;
      });
    } catch (e) {
      setState(() {
        isLoadingBirthdays = false;
      });
    }
  }

  Widget _buildScrollingBirthdayText() {
    if (isLoadingBirthdays || todayBirthdays.isEmpty) {
      return SizedBox.shrink();
    }

    // Tüm doğum günü mesajlarını birleştir
    String allBirthdayMessages = todayBirthdays
        .map((member) => '🎂 Doğum günün kutlu olsun ${member['name']} 🎂')
        .join(' • ');

    return Container(
      height: 45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _createScrollingAnimation(),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-_createScrollingAnimation().value * 800, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    allBirthdayMessages,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(width: 200),
                  Text(
                    allBirthdayMessages,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(width: 200),
                  Text(
                    allBirthdayMessages,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  AnimationController? _animationController;
  Animation<double>? _animation;

  Animation<double> _createScrollingAnimation() {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: Duration(seconds: 15),
        vsync: this,
      );
      _animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.linear,
      ));
      _animationController!.repeat();
    }
    return _animation!;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _showAnnouncementSheet({String? docId, String? existingTitle, String? existingContent}) {
    TextEditingController titleController = TextEditingController(text: existingTitle);
    TextEditingController contentController = TextEditingController(text: existingContent);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            height: 375,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(docId == null ? "Yeni Duyuru Ekle" : "Duyuruyu Düzenle",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.black)),
                SizedBox(height: 10),
                TextField(
                  cursorColor: Colors.black,
                  controller: titleController,
                  decoration: InputDecoration(labelText: "Duyuru Başlığı",
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Normal durumda alt çizgiyi siyah yapmak
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Focus olduğunda alt çizgiyi siyah yapmak
                    ),),

                ),
                SizedBox(height: 10),
                TextField(
                  cursorColor: Colors.black,
                  controller: contentController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: "Duyuru İçeriği",
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Normal durumda alt çizgiyi siyah yapmak
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Focus olduğunda alt çizgiyi siyah yapmak
                    ),),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                        if (docId == null) {
                          await _firestore.collection('announcements').add({
                            'title': titleController.text,
                            'content': contentController.text,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await _firestore.collection('announcements').doc(docId).update({
                            'title': titleController.text,
                            'content': contentController.text,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Text("Kaydet",style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Duyurular",
          style: TextStyle(color: Colors.white),
        ),
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
            _buildScrollingBirthdayText(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAnnouncements(),
                builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  if (!isAdmin && !(isHelperCoach && canCreateAnnouncement))
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Duyuru eklemek için yetkiniz bulunmamaktadır.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Henüz duyuru bulunmamaktadır.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                if (!isAdmin && !(isHelperCoach && canCreateAnnouncement))
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Duyuru eklemek için yetkiniz bulunmamaktadır.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(10),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var announcement = snapshot.data!.docs[index];
                      Timestamp? timestamp = announcement['timestamp'];
                      String formattedDate = timestamp != null
                          ? DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR').format(timestamp.toDate())
                          : "Tarih Yok";

                      return Card(
                        color: Colors.white.withOpacity(0.9),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        elevation: 3,
                        child: ListTile(
                          title: Text(announcement['title'] ?? "Başlık Yok",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(announcement['content'] ?? "İçerik Yok",
                                style: TextStyle(color: Colors.black, fontSize: 19),),
                              SizedBox(height: 5),
                              Text(
                                formattedDate,
                                style: TextStyle(fontSize: 13, color: Colors.black),
                              ),
                            ],
                          ),
                          trailing: (isAdmin || (isHelperCoach && canCreateAnnouncement))
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAnnouncementSheet(
                                        docId: announcement.id,
                                        existingTitle: announcement['title'],
                                        existingContent: announcement['content'],
                                      );
                                    } else if (value == 'delete') {
                                      _firestore.collection('announcements').doc(announcement.id).delete();
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit, color: Colors.blue),
                                        title: Text('Düzenle'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Sil'),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (isAdmin || (isHelperCoach && canCreateAnnouncement))
            ? () => _showAnnouncementSheet()
            : null,
        backgroundColor: (isAdmin || (isHelperCoach && canCreateAnnouncement))
            ? Colors.black
            : Colors.grey,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
