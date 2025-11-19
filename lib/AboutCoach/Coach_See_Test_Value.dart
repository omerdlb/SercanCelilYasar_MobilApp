import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personaltrainer/Tests/OturErisTestiPage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';


class CoachSeeTestValue extends StatefulWidget {
  final String memberId;

  const CoachSeeTestValue({super.key, required this.memberId});

  @override
  _CoachSeeTestValueState createState() => _CoachSeeTestValueState();
}

class _CoachSeeTestValueState extends State<CoachSeeTestValue> {
  Map<String, bool> expandedStates = {};



  Future<void> _generateAndSavePdf(String testName, Map<String, dynamic> testData) async {
    final pdf = pw.Document();

    // Fontu yükleyin
    final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Başlık
                pw.Container(
                  padding: pw.EdgeInsets.only(bottom: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    testName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Test Detayları
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: _buildPdfDetails(testData, ttf),
                  ),
                ),

                // Alt Bilgi
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: pw.EdgeInsets.only(top: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Oluşturulma Tarihi: ${DateTime.now().toString().split('.')[0]}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                          font: ttf,
                        ),
                      ),
                      pw.Text(
                        'Coach Sercan Celil YAŞAR',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                          font: ttf,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // PDF'i doğrudan yazdırma seçeneği sun
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${testName}_${DateTime.now().toString().split('.')[0]}.pdf',
    );
  }

  List<pw.Widget> _buildPdfDetails(Map<String, dynamic> testData, pw.Font ttf) {
    List<pw.Widget> details = [];

    void addDetail(String label, dynamic value) {
      if (value == null || value.toString().isEmpty) return;

      details.add(
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text(
                  "$label:",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value.toString(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    font: ttf,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Manuel test detayları
    if (testData['test_tipi'] == 'manuel') {
      addDetail("Test", testData['test']);
      if (testData['aciklama'] != null && testData['aciklama'].toString().isNotEmpty) {
        addDetail("Açıklama", testData['aciklama']);
      }
      if (testData['sonuclar'] != null && testData['sonuclar'] is List) {
        List<dynamic> results = testData['sonuclar'];
        if (results.isNotEmpty) {
          for (int i = 0; i < results.length; i++) {
            if (results[i] != null && results[i].toString().isNotEmpty) {
              addDetail("Sonuç ${i + 1}", results[i]);
            }
          }
        }
      }
      if (testData['degerlendirme'] != null && testData['degerlendirme'].toString().isNotEmpty) {
        addDetail("Değerlendirme", testData['degerlendirme']);
      }
    } else {
      // Standart test detayları
      switch (testData['test']) {
        case "Altıgen Koordinasyon Testi":
          addDetail("2 Ölçümün Ortalaması", testData['average']);
          addDetail("Ölçüm 1", testData['olcum1']);
          addDetail("Ölçüm 2", testData['olcum2']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Durarak Uzun Atlama Testi":
          addDetail("En iyi sonuç", testData['best']);
          addDetail("Ölçüm 1", testData['olcum1']);
          addDetail("Ölçüm 2", testData['olcum2']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Flamingo Denge Testi":
          addDetail("1 dakika içerisindeki toplam denge kaybı", testData['balanceLostCount']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Otur Eriş Testi":
          addDetail("Ölçüm 1", testData['olcum1']);
          addDetail("Ölçüm 2", testData['olcum2']);
          addDetail("En İyi Ölçüm", testData['bestscore']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Vücut Kitle İndeksi (BMI)":
          addDetail("Cinsiyet", testData['cinsiyet']);
          addDetail("Yaş", testData['yas']);
          addDetail("Boy", testData['boy']);
          addDetail("Kilo", testData['kilo']);
          addDetail("Vücut Kitle İndeksi", testData['bmi']);
          addDetail("Sonuç", testData['sonuc']);
          break;

        default:
          testData.forEach((key, value) {
            if (key != 'test' && key != 'test_tipi' && key != 'tarih') {
              addDetail(key, value);
            }
          });
          break;
      }
    }

    // Tarih her zaman en sonda gösterilsin
    if (testData['tarih'] != null) {
      try {
        DateTime date = DateTime.parse(testData['tarih']);
        String formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        addDetail("Tarih", formattedDate);
      } catch (e) {
        addDetail("Tarih", testData['tarih']);
      }
    }

    return details;
  }






  Future<List<Map<String, dynamic>>> fetchTests() async {
    List<Map<String, dynamic>> testList = [];
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('uyelerim')
          .doc(widget.memberId)
          .collection('olcumlerim')
          .get();

      for (var doc in snapshot.docs) {
        var testData = doc.data();
        testData['id'] = doc.id; // Firestore'dan gelen ID'yi ekleyin
        testList.add(testData);
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
    }
    return testList;
  }

  Future<void> _deleteTest(String testId) async {
    try {
      await FirebaseFirestore.instance
          .collection('uyelerim')
          .doc(widget.memberId)
          .collection('olcumlerim')
          .doc(testId)
          .delete();
      setState(() {}); // Sayfayı yenile
    } catch (e) {
      print("Silme hatası: $e");
    }
  }


  void _confirmDelete(String testId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Testi Sil"),
        content: const Text("Bu testi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("İptal", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTest(testId);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Performans Test Listesi", style: TextStyle(color: Colors.white)),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('uyelerim')
              .doc(widget.memberId)
              .collection('olcumlerim')
              .orderBy('tarih', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // Yükleme durumu
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Ölçümler yükleniyor...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Hata durumu
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Bir hata oluştu: ${snapshot.error}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Sayfayı yenile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        "Tekrar Dene",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Veri yok durumu
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Henüz ölçüm sonucu bulunmuyor.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            List<Map<String, dynamic>> tests = snapshot.data!.docs
                .map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                })
                .toList();

            List<Map<String, dynamic>> manualTests = tests.where((test) => test['test_tipi'] == 'manuel').toList();
            List<Map<String, dynamic>> standardTests = tests.where((test) => test['test_tipi'] != 'manuel').toList();

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {}); // Sayfayı yenile
              },
              color: Colors.red[700],
              backgroundColor: Colors.white,
              child: ListView(
                children: [
                  if (manualTests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Özel Ölçümler",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...manualTests.map((test) {
                      String currentId = "${widget.memberId}_${tests.indexOf(test)}";
                      return _buildTestCard(test, currentId, expandedStates[currentId] ?? false);
                    }).toList(),
                  ],
                  if (standardTests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Standart Ölçümler",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...standardTests.map((test) {
                      String currentId = "${widget.memberId}_${tests.indexOf(test)}";
                      return _buildTestCard(test, currentId, expandedStates[currentId] ?? false);
                    }).toList(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, String currentId, bool isExpanded) {
    String testName = test['test'] ?? "Bilinmeyen Test";
    String testId = test['id'] ?? "";
    bool isManualTest = test['test_tipi'] == 'manuel';
    Color cardColor = isManualTest ? Colors.grey[800]! : Colors.grey[900]!;

    String formattedDate = "Tarih belirtilmemiş";
    if (test['tarih'] != null) {
      try {
        if (test['tarih'] is Timestamp) {
          DateTime date = (test['tarih'] as Timestamp).toDate();
          formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        } else if (test['tarih'] is String) {
          DateTime date = DateTime.parse(test['tarih']);
          formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        }
      } catch (e) {
        formattedDate = test['tarih'].toString();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      color: cardColor,
      child: Column(
        children: [
          ListTile(
            title: Text(
              testName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              formattedDate,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: () {
                    _generateAndSavePdf(testName, test);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  onPressed: () {
                    if (isManualTest) {
                      _showManualTestInfoDialog(test);
                    } else {
                      _showTestInfoDialog(testName);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      expandedStates[currentId] = !isExpanded;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == "delete") {
                      _confirmDelete(testId);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: "delete",
                        child: Text("Sil"),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: Colors.white, thickness: 1.5),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildDetails(testName, test),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetails(String testName, Map<String, dynamic> testData) {
    List<Widget> details = [];

    void addDetail(String label, dynamic value) {
      if (value == null || value.toString().isEmpty) return;
      
      details.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label: ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            Expanded(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    // Manuel test detayları
    if (testData['test_tipi'] == 'manuel') {
      // Test açıklaması
      if (testData['aciklama'] != null && testData['aciklama'].toString().isNotEmpty) {
        details.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              testData['aciklama'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }

      // Sonuçlar
      if (testData['sonuclar'] != null && testData['sonuclar'] is List) {
        List<dynamic> results = testData['sonuclar'];
        if (results.isNotEmpty) {
          details.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Sonuçlar:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          );
          
          for (int i = 0; i < results.length; i++) {
            if (results[i] != null && results[i].toString().isNotEmpty) {
              details.add(
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    "• ${results[i]}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
          }
          details.add(SizedBox(height: 8));
        }
      }

      // Değerlendirme
      if (testData['degerlendirme'] != null && testData['degerlendirme'].toString().isNotEmpty) {
        details.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Değerlendirme: ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                Expanded(
                  child: Text(
                    testData['degerlendirme'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Standart test detayları
      switch (testName) {
        case "Altıgen Koordinasyon Testi":
          addDetail("2 Ölçümün Ortalaması", testData['average']);
          addDetail("Ölçüm 1", testData['olcum1']);
          addDetail("Ölçüm 2", testData['olcum2']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Durarak Uzun Atlama Testi":
          addDetail("En iyi sonuç", testData['best']);
          addDetail("Ölçüm 1", testData['olcum1']);
          addDetail("Ölçüm 2", testData['olcum2']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Flamingo Denge Testi":
          addDetail("1 dakika içerisindeki toplam denge kaybı", testData['balanceLostCount']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Otur Eriş Testi":
          addDetail("Ölçüm 1", testData['olcum1']);
          addDetail("Ölçüm 2", testData['olcum2']);
          addDetail("En İyi Ölçüm", testData['bestscore']);
          addDetail("Değerlendirme", testData['sonuc']);
          break;

        case "Vücut Kitle İndeksi (BMI)":
          addDetail("Cinsiyet", testData['cinsiyet']);
          addDetail("Yaş", testData['yas']);
          addDetail("Boy", testData['boy']);
          addDetail("Kilo", testData['kilo']);
          addDetail("Vücut Kitle İndeksi", testData['bmi']);
          addDetail("Sonuç", testData['sonuc']);
          break;

        default:
          testData.forEach((key, value) {
            if (key != 'test' && key != 'test_tipi' && key != 'tarih') {
              addDetail(key, value);
            }
          });
          break;
      }
    }

    // Tarih her zaman en sonda gösterilsin
    if (testData['tarih'] != null) {
      String formattedDate;
      try {
        // Timestamp kontrolü
        if (testData['tarih'] is Timestamp) {
          DateTime date = (testData['tarih'] as Timestamp).toDate();
          formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        } else if (testData['tarih'] is String) {
          // String formatındaki tarihi parse etmeyi dene
          DateTime date = DateTime.parse(testData['tarih']);
          formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        } else {
          formattedDate = testData['tarih'].toString();
        }
      } catch (e) {
        formattedDate = testData['tarih'].toString();
      }

      details.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "Tarih: $formattedDate",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return details;
  }

  void _showTestInfoDialog(String testName) {
    String testInfo;

    switch (testName) {
      case "Altıgen Koordinasyon Testi":
        testInfo = "Bu test, koordinasyon ve hız yeteneğini ölçer. Katılımcı, altıgen şeklindeki parkuru belirli bir sürede tamamlamaya çalışır.";
        break;

      case "Durarak Uzun Atlama Testi":
        testInfo = "Bu test, bacak kaslarının gücünü ve sıçrama yeteneğini ölçer. Katılımcı, yerden olabildiğince uzağa sıçramaya çalışır.";
        break;

      case "Flamingo Denge Testi":
        testInfo = "Bu test, denge yeteneğini ölçer. Katılımcı, tek ayak üzerinde belirli bir süre durmaya çalışır.";
        break;

      case "Otur Eriş Testi":
        testInfo = "Bu test, bel ve bacak kaslarının esnekliğini ölçer. Katılımcı, bacaklarını düz tutarak oturur ve ayak parmaklarına ulaşmaya çalışır.";
        break;

      case "Vücut Kitle İndeksi (BMI)":
        testInfo = "Bu test, boy ve kilonuza göre vücut kitle indeksinizi (BMI) hesaplar. BMI, vücut ağırlığınızın sağlıklı bir aralıkta olup olmadığını belirlemeye yardımcı olur.";
        break;

      default:
        testInfo = "Bu test hakkında daha fazla bilgi burada olacak.";
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(testName),
        content: Text(testInfo),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Kapat",style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  void _showManualTestInfoDialog(Map<String, dynamic> test) {
    String testName = test['test'] ?? "Bilinmeyen Test";
    String description = test['aciklama'] ?? "Açıklama bulunmuyor.";
    List<dynamic> results = test['sonuclar'] ?? [];
    String evaluation = test['degerlendirme'] ?? "Değerlendirme bulunmuyor.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          testName,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (description.isNotEmpty) ...[
                Text(
                  "Açıklama:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 16),
              ],
              if (results.isNotEmpty) ...[
                Text(
                  "Sonuçlar:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                ...results.map((result) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    "• $result",
                    style: TextStyle(color: Colors.black87),
                  ),
                )).toList(),
                SizedBox(height: 16),
              ],
              Text(
                "Değerlendirme:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                evaluation,
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "Kapat",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}