import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class AltigenKoordinasyonTestiPage extends StatefulWidget {
  final String memberId;

  const AltigenKoordinasyonTestiPage({super.key, required this.memberId});

  @override
  _AltigenKoordinasyonTestiPageState createState() =>
      _AltigenKoordinasyonTestiPageState();
}

class _AltigenKoordinasyonTestiPageState
    extends State<AltigenKoordinasyonTestiPage> {
  final _firstTrialController = TextEditingController();
  final _secondTrialController = TextEditingController();
  String _averageScore = '';
  String _performanceResult = ''; // Performans sonucu (üstünde/altında)

  late Timer _timer;
  int _elapsedTime = 0;
  bool _isRunning = false;
  bool _isFirstTrialCompleted = false;
  bool _isSecondTrialCompleted = false;
  bool _isMale = true; // Cinsiyet bilgisi için varsayılan değer (erkek)
  int _age = 0; // Firestore'dan çekilen yaş bilgisi

  // Beklenen performans değerleri
  final Map<String, Map<String, List<int>>> _expectedValues = {
    'male': {
      '5-6': [20, 25],
      '7-8': [18, 22],
      '9-10': [16, 20],
      '11-12': [14, 18],
      '13-14': [12, 16],
      '15-16': [10, 14],
      '17-18': [8, 12],
    },
    'female': {
      '5-6': [22, 27],
      '7-8': [20, 24],
      '9-10': [18, 22],
      '11-12': [16, 20],
      '13-14': [14, 18],
      '15-16': [12, 16],
      '17-18': [10, 14],
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Kullanıcının yaş bilgisini Firestore'dan çek
  }

  // Firestore'dan kullanıcının yaş bilgisini çek
  void _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('uyelerim')
          .doc(widget.memberId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _age = userDoc['age'] ?? 0; // Firestore'dan yaş bilgisini al
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yaş bilgisi alınırken hata oluştu: $e')));
    }
  }

  void _startTimer() {
    setState(() {
      _elapsedTime = 0;
      _isRunning = true;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      if (!_isFirstTrialCompleted) {
        _firstTrialController.text = _elapsedTime.toString();
        _isFirstTrialCompleted = true;
      } else {
        _secondTrialController.text = _elapsedTime.toString();
        _isSecondTrialCompleted = true;
        _calculateAverage();
        _checkPerformance(_age, _isMale); // Performans kontrolü yap
      }
      _timer.cancel();
    });
  }

  void _resetAll() {
    setState(() {
      _firstTrialController.clear();
      _secondTrialController.clear();
      _elapsedTime = 0;
      _isRunning = false;
      _isFirstTrialCompleted = false;
      _isSecondTrialCompleted = false;
      _averageScore = '';
      _performanceResult = '';
    });
  }

  void _calculateAverage() {
    final double firstTrial = double.tryParse(_firstTrialController.text) ?? 0;
    final double secondTrial = double.tryParse(_secondTrialController.text) ?? 0;

    if (firstTrial > 0 && secondTrial > 0) {
      final double average = (firstTrial + secondTrial) / 2;
      setState(() {
        _averageScore = average.toStringAsFixed(2);
      });
    }
  }

  void _checkPerformance(int age, bool isMale) {
    String ageGroup;
    if (age >= 5 && age <= 6) {
      ageGroup = '5-6';
    } else if (age >= 7 && age <= 8) {
      ageGroup = '7-8';
    } else if (age >= 9 && age <= 10) {
      ageGroup = '9-10';
    } else if (age >= 11 && age <= 12) {
      ageGroup = '11-12';
    } else if (age >= 13 && age <= 14) {
      ageGroup = '13-14';
    } else if (age >= 15 && age <= 16) {
      ageGroup = '15-16';
    } else if (age >= 17 && age <= 18) {
      ageGroup = '17-18';
    } else {
      ageGroup = '5-6'; // Varsayılan değer
    }

    final gender = isMale ? 'male' : 'female';
    final expectedRange = _expectedValues[gender]![ageGroup]!;
    final averageScore = double.tryParse(_averageScore) ?? 0;

    if (averageScore >= expectedRange[0] && averageScore <= expectedRange[1]) {
      setState(() {
        _performanceResult = 'Harika iş çıkardınız! Koordinasyon seviyeniz ortalamanın içinde. Devam edin! Koordinasyonunuzu geliştirmek isterseniz, bireysel derslerimize göz atabilirsiniz!';
      });
    } else if (averageScore < expectedRange[0]) {
      setState(() {
        _performanceResult = 'Harika bir başlangıç! Koordinasyonunuzu geliştirmek için biraz daha çalışmaya devam edin. Bireysel derslerimizle hızlıca ilerleyebilirsiniz!';
      });
    } else {
      setState(() {
        _performanceResult = 'Koordinasyon değeriniz ortalamanın altında. Ancak endişelenmeyin, daha fazla pratik ve bireysel derslerle çok daha iyi olabilirsiniz! Bizimle birlikte gelişmeye devam edin!';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Altıgen Koordinasyon Testi', style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                      Text(
                        "Test Açıklaması:",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 16),
                      ),
                      Text(
                        "Altıgen Koordinasyon Testi, bir oyuncunun çevikliğini, yön değiştirme hızını ve dengeyi ölçmeye yönelik bir testtir.",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold ,fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Cinsiyet Seçimi Checkbox
              // Cinsiyet Seçimi Checkbox'ları Card içinde
              Card(
                color: Colors.black54,
                elevation: 8.0, // Kartın gölgesini ekleyebilirsiniz
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Kart köşelerini yuvarlayabilirsiniz
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Kartın iç kenar boşluklarını ayarladık
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Cinsiyet:',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _isMale,
                              onChanged: (value) {
                                setState(() {
                                  _isMale = value ?? true; // Varsayılan olarak erkek seçili
                                });
                              },
                              activeColor: Colors.green,
                            ),
                            Text(
                              'Erkek',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            SizedBox(width: 20),
                            Checkbox(
                              value: !_isMale,
                              onChanged: (value) {
                                setState(() {
                                  _isMale = !(value ?? false); // Kadın seçiliyse erkek değil
                                });
                              },
                              activeColor: Colors.green,
                            ),
                            Text(
                              'Kadın',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Geçen Süre: $_elapsedTime sn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 20),

              Text('İlk Deneme Süresi (sn):', style: TextStyle(fontSize: 18, color: Colors.white)),
              TextField(
                controller: _firstTrialController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'İlk denemenin süresini girin',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: !_isRunning && !_isFirstTrialCompleted
                    ? _startTimer
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text('Birinci Denemeyi Başlat', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
              if (_isRunning && !_isFirstTrialCompleted)
                ElevatedButton(
                  onPressed: _stopTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text('Birinci Denemeyi Durdur'),
                ),
              if (_isFirstTrialCompleted && !_isSecondTrialCompleted)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _firstTrialController.clear();
                      _elapsedTime = 0;
                      _isFirstTrialCompleted = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text('Birinci Denemeyi Sıfırla'),
                ),
              SizedBox(height: 20),

              Text('İkinci Deneme Süresi (sn):', style: TextStyle(fontSize: 18, color: Colors.white)),
              TextField(
                controller: _secondTrialController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'İkinci denemenin süresini girin',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isFirstTrialCompleted && !_isSecondTrialCompleted && !_isRunning
                    ? _startTimer
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text('İkinci Denemeyi Başlat'),
              ),
              if (_isRunning && _isFirstTrialCompleted && !_isSecondTrialCompleted)
                ElevatedButton(
                  onPressed: _stopTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text('İkinci Denemeyi Durdur'),
                ),
              if (_isSecondTrialCompleted)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _secondTrialController.clear();
                      _elapsedTime = 0;
                      _isSecondTrialCompleted = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('İkinci Denemeyi Sıfırla'),
                ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isSecondTrialCompleted
                    ? () {
                  _saveResults();
                  _resetAll();
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Kaydet'),
              ),
              SizedBox(height: 20),

              if (_averageScore.isNotEmpty)
                Text(
                  'Ortalama Skor: $_averageScore sn',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              if (_performanceResult.isNotEmpty)
                Text(
                  'Performans Sonucu: $_performanceResult',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentDateTime() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy, HH:mm');
    return formatter.format(DateTime.now());
  }

  void _saveResults() async {
    try {
      await FirebaseFirestore.instance.collection('uyelerim').doc(widget.memberId).collection('olcumlerim').add({
        'test': 'Altıgen Koordinasyon Testi',
        'olcum1': "${_firstTrialController.text} saniye",
        'olcum2': "${_secondTrialController.text} saniye",
        'average': _averageScore,
        'sonuc': _performanceResult, // Performans sonucunu kaydet
        'tarih': _getCurrentDateTime(),
        'cinsiyet': _isMale ? 'Erkek' : 'Kadın', // Cinsiyet bilgisini kaydet
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler başarıyla kaydedildi!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler kaydedilirken bir hata oluştu: $e')));
    }
  }
}