import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:personaltrainer/AboutCoach/Coach_See_Test_Value.dart';
import 'package:personaltrainer/AboutCoach/ListAllTest.dart';
import 'package:personaltrainer/User_Admin_Profile/Coach_see_User_Attandance_Table.dart';
import '../AboutCoach/AttendanceAnalysisPage.dart';
import 'MembershipInfoPage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MemberDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot member;

  const MemberDetailsPage({super.key, required this.member});

  @override
  _MemberDetailsPageState createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isAdmin = false;
  bool isHelperCoach = false;
  bool canDeleteMember = false;
  bool canAddMeasurement = false;

  @override
  void initState() {
    super.initState();
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        if (adminDoc.exists && adminDoc.data() != null) {
          bool isAdmin = (adminDoc.data() as Map<String, dynamic>)['admin'] == true;
          
          setState(() {
            if (isAdmin) {
              // Admin ise tüm yetkileri ver
              this.isAdmin = true;
              isHelperCoach = false;
              canDeleteMember = true;
              canAddMeasurement = true;
            } else {
              // Admin değilse helper coach ve yetkilerini kontrol et
              this.isAdmin = false;
              isHelperCoach = (adminDoc.data() as Map<String, dynamic>)['helpercoach'] == true;
              canDeleteMember = (adminDoc.data() as Map<String, dynamic>)['canDeleteMember'] == true;
              canAddMeasurement = (adminDoc.data() as Map<String, dynamic>)['canAddMeasurement'] == true;
            }
          });
        }
      } catch (e) {
        print("Rol kontrolünde hata: $e");
        setState(() {
          isAdmin = false;
          isHelperCoach = false;
          canDeleteMember = false;
          canAddMeasurement = false;
        });
      }
    } else {
      setState(() {
        isAdmin = false;
        isHelperCoach = false;
        canDeleteMember = false;
        canAddMeasurement = false;
      });
    }
  }

  Future<void> _generateAndSavePaymentPdf(String memberName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );

      // Önce sadece isme göre filtrele
      QuerySnapshot paymentSnapshot = await _firestore
          .collection('kazanc')
          .where('name', isEqualTo: memberName)
          .get();

      // Sonra uygulama tarafında tarihe göre sırala
      var sortedPayments = paymentSnapshot.docs.toList()
        ..sort((a, b) {
          String dateA = (a.data() as Map<String, dynamic>)['date'] ?? '';
          String dateB = (b.data() as Map<String, dynamic>)['date'] ?? '';
          return dateB.compareTo(dateA); // Tarihe göre azalan sıralama
        });

      Navigator.pop(context);

      if (sortedPayments.isEmpty) {
        _showErrorDialog("Bu üyeye ait ödeme bilgisi bulunamadı.");
        return;
      }

      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            List<List<String>> tableData = [
              ['Tarih', 'Grup', 'Ödeme Tutarı', 'Açıklama'],
            ];

            for (var doc in sortedPayments) {
              var data = doc.data() as Map<String, dynamic>;
              tableData.add([
                data['date']?.toString() ?? '-',
                data['group']?.toString() ?? '-',
                '${data['paymentAmount']?.toString() ?? '-'} TL',
                data['description']?.toString() ?? '-',
              ]);
            }

            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Ödeme Bilgileri - $memberName',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                  ),
                ),
              ),
              pw.Table.fromTextArray(
                context: context,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: ttf,
                ),
                cellStyle: pw.TextStyle(font: ttf),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerLeft,
                },
              ),
            ];
          },
        ),
      );

      // PDF'i yazdırma/paylaşma seçeneği sun
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: '${memberName}_Odeme_Bilgileri.pdf',
      );

    } catch (e) {
      print("PDF oluşturma hatası: $e");
      _showErrorDialog("PDF oluşturulurken bir hata oluştu: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showFileNameDialog(BuildContext context, String defaultName) async {
    String fileName = defaultName;
    return showDialog<String>(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        child: AlertDialog(
          title: const Text(
            "Dosya Adını Girin",
            style: TextStyle(color: Colors.black),
          ),
          content: TextField(
            decoration: InputDecoration(
              hintText: "Dosya adı",
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            onChanged: (value) {
              fileName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(fileName),
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter = widget.member['name'].isNotEmpty
        ? widget.member['name'][0].toUpperCase()
        : "?";

    String memberId = widget.member.id;
    String groupName = widget.member['group'] ?? '';

    // Kullanıcının herhangi bir yetkisi var mı kontrol et
    bool hasAnyPermission = isAdmin || canDeleteMember || canAddMeasurement;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Üye Detayları', style: TextStyle(color: Colors.white),),
        actions: [
          if (hasAnyPermission) // Sadece yetkisi olan kullanıcılar için menüyü göster
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (value) {
                if (value == 'delete' && (isAdmin || canDeleteMember)) {
                  _confirmDeleteMember(widget.member.id);
                }
                else if (value == 'olcum' && (isAdmin || canAddMeasurement)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ListAllTest(memberId: widget.member.id)),
                  );
                }
                else if (value == 'dekont' && isAdmin) {
                  _generateAndSavePaymentPdf(widget.member['name']);
                }
              },
              itemBuilder: (context) => [
                if (isAdmin || canAddMeasurement)
                  PopupMenuItem(
                    value: 'olcum',
                    child: Row(
                      children: [
                        Icon(Icons.monitor_weight_outlined, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Ölçüm Ekle'),
                      ],
                    ),
                  ),
                if (isAdmin)
                  PopupMenuItem(
                    value: 'dekont',
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Dekont Bilgisi'),
                      ],
                    ),
                  ),
                if (isAdmin || canDeleteMember)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Üyeyi Sil'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),body: Container(
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
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor:  Colors.white.withOpacity(0.9),
              child: Text(
                firstLetter,
                style: TextStyle(fontSize: 40, color: Colors.black,fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            Text(
              widget.member['name'],
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Colors.white),
            ),
            SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildCardButton(
                  icon: Icons.edit,
                  label: 'Üyelik Bilgileri',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MembershipInfoPage(member: widget.member)),
                    );
                  },
                ),
                _buildCardButton(
                  icon: Icons.bar_chart,
                  label: 'Ölçümler',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CoachSeeTestValue(memberId: widget.member.id)),
                    );
                  },
                ),
                _buildCardButton(
                  icon: Icons.calendar_today,
                  label: 'Yoklama Çizelgesi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CoachSeeUserAttandanceTable(
                            member: widget.member,
                          )),
                    );
                  },
                ),
                _buildCardButton(
                  icon: Icons.pie_chart,
                  label: 'Yoklama Analiz',
                  onTap: () {
                    if (groupName.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AttendanceAnalysisPage(memberId: memberId, groupName: groupName),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Grup bilgisi bulunamadı!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,color: Colors.black)),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMember(String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Üyeyi Sil'),
        content: Text('Bu üyeyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMember(memberId);
            },
            child: Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMember(String memberId) async {
    try {
      var memberDoc = await _firestore.collection('uyelerim').doc(memberId).get();

      if (memberDoc.exists) {
        String? groupString = memberDoc['group'];
        String memberEmail = memberDoc['email'];

        List<String> groups = groupString?.split(',').map((e) => e.trim()).toList() ?? [];

        await _firestore.collection('uyelerim').doc(memberId).delete();

        for (String group in groups) {
          var groupQuery = await _firestore
              .collection('group_lessons')
              .where('group_name', isEqualTo: group)
              .get();

          if (groupQuery.docs.isNotEmpty) {
            await groupQuery.docs.first.reference
                .collection('grup_uyeleri')
                .doc(memberId)
                .delete();
          }
        }

        try {
          User? user = FirebaseAuth.instance.currentUser;

          if (user != null && user.uid == memberId) {
            await user.delete();
            print("Kullanıcı Firebase Authentication'dan silindi.");
          }
        } catch (e) {
          print('Firebase Authentication silme hatası: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Üye başarıyla silindi.')),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Üye bulunamadı.')),
        );
      }
    } catch (e) {
      print('Hata: Üye silinirken bir sorun oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Üye silinirken bir hata oluştu.')),
      );
    }
  }
}