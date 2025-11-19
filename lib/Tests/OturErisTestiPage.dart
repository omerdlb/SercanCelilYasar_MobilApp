import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OturErisTestiPage extends StatefulWidget {
  final String memberId;
  const OturErisTestiPage({super.key, required this.memberId});

  @override
  _OturErisTestiPageState createState() => _OturErisTestiPageState();
}

class _OturErisTestiPageState extends State<OturErisTestiPage> {
  final TextEditingController _measurement1Controller = TextEditingController();
  final TextEditingController _measurement2Controller = TextEditingController();
  String? _selectedGender;
  int? _userAge;
  String? _evaluationResult;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('uyelerim').doc(widget.memberId).get();
      setState(() {
        _userAge = userDoc['age'];
      });
    } catch (e) {
      print("Yaş verisi çekilirken hata oluştu: $e");
    }
  }

  String _getCurrentDateTime() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy, HH:mm');
    return formatter.format(DateTime.now());
  }

  void _evaluateFlexibility(int bestScore) {
    if (_userAge == null || _selectedGender == null) {
      setState(() {
        _evaluationResult = "Yaş veya cinsiyet bilgisi eksik!";
      });
      return;
    }

    // Yaşa ve cinsiyete göre normal aralıklar
    Map<int, List<int>> normalRanges = {
      5: [18, 28, 16, 26], 6: [19, 30, 17, 27], 7: [20, 31, 18, 28],
      8: [21, 33, 19, 29], 9: [22, 34, 20, 30], 10: [23, 35, 21, 31],
      11: [24, 36, 22, 32], 12: [25, 37, 23, 33], 13: [26, 38, 24, 34],
      14: [27, 39, 25, 35], 15: [28, 40, 26, 36], 16: [29, 41, 27, 37]
    };

    List<int>? range = normalRanges[_userAge];
    if (range == null) {
      setState(() {
        _evaluationResult = "Bu yaş için değerlendirme mevcut değil.";
      });
      return;
    }

    int minNormal = _selectedGender == "Kadın" ? range[0] : range[2];
    int maxNormal = _selectedGender == "Kadın" ? range[1] : range[3];

    if (bestScore < minNormal) {
      setState(() {
        _evaluationResult = "Esnekliğiniz ortalamanın altında. Esnekliği artırmak için bireysel derslerimize göz atabilirsiniz! Düzenli çalışma ile başarıya ulaşabilirsiniz.";
      });
    } else if (bestScore > maxNormal) {
      setState(() {
        _evaluationResult = "Esnekliğiniz ortalamanın üzerinde. Çok iyi! Devam edin, esnekliğinizi daha da geliştirebilirsiniz. Bireysel derslerimizle yeni seviyelere ulaşabilirsiniz!";
      });
    } else {
      setState(() {
        _evaluationResult = "Esnekliğiniz normal seviyede. Sürekli gelişim için bireysel derslerimize göz atabilirsiniz. Daha fazlası için çalışmaya devam edin!";
      });
    }
  }

  void _saveMeasurements() async {
    int olcum1 = int.tryParse(_measurement1Controller.text) ?? 0;
    int olcum2 = int.tryParse(_measurement2Controller.text) ?? 0;
    int eniyiolcum = olcum1 > olcum2 ? olcum1 : olcum2;

    _evaluateFlexibility(eniyiolcum);

    try {
      await FirebaseFirestore.instance.collection('uyelerim').doc(widget.memberId).collection('olcumlerim').add({
        'test': 'Otur Eriş Testi',
        'olcum1': olcum1,
        'olcum2': olcum2,
        'bestscore': eniyiolcum,
        'sonuc': _evaluationResult,
        'tarih': _getCurrentDateTime(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler başarıyla kaydedildi!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler kaydedilirken hata oluştu!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Otur Eriş Testi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.black),
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.black54,
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Test Açıklaması:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 16)),
                      Text(
                        "Bu test, esneklik ve vücut kontrolü becerilerini ölçmek için yapılır. Testin amacı, kişinin oturur pozisyonda bacaklarını düz tutarak ne kadar ileriye uzanabileceğini görmek ve vücut kontrolünü ve esnekliğini test etmektir.\n\n"
                            "1. Yere oturun ve ayak tabanlarınızı düz bir şekilde test sehpasına dayayın.\n"
                            "2. Kalçanızı ve belinizi ileri doğru eğin, dizlerinizi bükmeden ellerinizi vücudunuzun önünde uzatın.\n"
                            "3. En uzak noktaya kadar uzanmaya çalışın ve bu noktada 2 saniye bekleyin.\n"
                            "4. En son noktada ölçüm yapılır. Bu testi 2 kez yaparak en yüksek ölçüm kaydedilir.",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: Colors.black54,
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Cinsiyet Seçiniz:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Checkbox(
                            value: _selectedGender == "Kadın",
                            onChanged: (bool? value) {
                              setState(() {
                                _selectedGender = value == true ? "Kadın" : null;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Text("Kadın", style: TextStyle(color: Colors.white)),
                          Checkbox(
                            value: _selectedGender == "Erkek",
                            onChanged: (bool? value) {
                              setState(() {
                                _selectedGender = value == true ? "Erkek" : null;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Text("Erkek", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              inputField(_measurement1Controller, '1. Ölçüm (cm):'),
              SizedBox(height: 10),
              inputField(_measurement2Controller, '2. Ölçüm (cm):'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMeasurements,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Siyah arka plan
                  foregroundColor: Colors.white, // Beyaz metin
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Verileri Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              if (_evaluationResult != null)
                Card(
                  color: Colors.black54,
                  elevation: 8.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _evaluationResult!,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField(TextEditingController controller, String labelText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        TextField(
          cursorColor: Colors.black,
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            labelText: labelText,
            labelStyle: TextStyle(color: Colors.black),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}