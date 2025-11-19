import 'package:flutter/material.dart';
import 'package:personaltrainer/Tests/AltigenKoordinasyonTestiPage.dart';
import 'package:personaltrainer/Tests/BMICalculator.dart';
import 'package:personaltrainer/Tests/FlamingoDengeTestiPage.dart';
import 'package:personaltrainer/Tests/LongJumpTestPage.dart';
import 'package:personaltrainer/Tests/OturErisTestiPage.dart';
import 'package:personaltrainer/Tests/ManualTestAdd.dart';

class ListAllTest extends StatelessWidget {
  final String memberId;

  const ListAllTest({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> testList = [
      {
        "name": "Manuel Test Ekle",
        "category": "Özel Testler",
        "icon": Icons.add_circle_outline,
        "color": Colors.blue,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManualTestAdd(memberId: memberId),
            ),
          );
        },
      },
      {
        "name": "Altıgen Koordinasyon Testi",
        "category": "Koordinasyon Testleri",
        "icon": Icons.speed,
        "color": Colors.red,
        "page": AltigenKoordinasyonTestiPage(memberId: memberId),
      },
      {
        "name": "Durarak Uzun Atlama Testi",
        "category": "Kuvvet Testleri",
        "icon": Icons.directions_run,
        "color": Colors.orange,
        "page": LongJumpTestPage(memberId: memberId),
      },
      {
        "name": "Flamingo Denge Testi",
        "category": "Denge Testleri",
        "icon": Icons.accessibility_new,
        "color": Colors.purple,
        "page": FlamingoDengeTestiPage(memberId: memberId),
      },
      {
        "name": "Otur Eriş Testi",
        "category": "Esneklik Testleri",
        "icon": Icons.fitness_center,
        "color": Colors.green,
        "page": OturErisTestiPage(memberId: memberId),
      },
      {
        "name": "Vücut Kitle İndeksi",
        "category": "Vücut Kitle İndeksi",
        "icon": Icons.monitor_weight,
        "color": Colors.teal,
        "page": BMICalculator(memberId: memberId),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Listesi", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF9A0202), Color(0xFFC80101)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          itemCount: testList.length,
          itemBuilder: (context, index) {
            final test = testList[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: test["color"],
                  child: Icon(test["icon"], color: Colors.white),
                ),
                title: Text(
                  test["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  test["category"],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  if (test["onTap"] != null) {
                    test["onTap"]();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => test["page"],
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}