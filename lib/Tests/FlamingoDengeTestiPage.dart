import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class FlamingoDengeTestiPage extends StatefulWidget {
  final String memberId;

  const FlamingoDengeTestiPage({super.key, required this.memberId});

  @override
  _FlamingoDengeTestiPageState createState() => _FlamingoDengeTestiPageState();
}

class _FlamingoDengeTestiPageState extends State<FlamingoDengeTestiPage> {
  int _balanceLostCount = 0; // Denge kaybı sayacı
  bool _isTestStarted = false; // Testin başlatılıp başlatılmadığını kontrol eder
  late Stopwatch _stopwatch; // Kronometre
  late Timer _timer; // Anlık süreyi güncellemek için
  bool _isTestFinished = false; // Testin bitip bitmediğini kontrol eder
  bool _showSaveOption = false; // Kaydetme seçeneğini gösterir
  bool _isMale = true; // Cinsiyet bilgisi (varsayılan: erkek)
  int _age = 0; // Firestore'dan çekilen yaş bilgisi
  String _performanceResult = ''; // Performans sonucu (üstünde/altında)

  // Beklenen performans değerleri
  final Map<String, Map<String, List<int>>> _expectedValues = {
    'male': {
      '5-6': [5, 10],
      '7-8': [4, 8],
      '9-10': [3, 7],
      '11-12': [2, 6],
      '13-14': [1, 5],
      '15-16': [1, 4],
      '17-18': [0, 3],
    },
    'female': {
      '5-6': [6, 11],
      '7-8': [5, 9],
      '9-10': [4, 8],
      '11-12': [3, 7],
      '13-14': [2, 6],
      '15-16': [1, 5],
      '17-18': [0, 4],
    },
  };

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
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

  void _startTest() {
    setState(() {
      _isTestStarted = true;
      _isTestFinished = false;
      _showSaveOption = false;
    });
    _stopwatch.start();

    // Timer ile her saniye ekrana süreyi güncelleyebiliriz.
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_stopwatch.elapsed.inSeconds >= 60) {
        // Testin süresi 1 dakika olunca otomatik olarak durdurulur
        _stopTest();
        _timer.cancel(); // Timer'ı durdur
      }
      setState(() {});
    });
  }

  void _resetTest() {
    setState(() {
      _balanceLostCount = 0;
      _isTestStarted = false;
      _isTestFinished = false;
      _showSaveOption = false;
      _performanceResult = '';
    });
    _stopwatch.reset();
    _timer.cancel(); // Timer'ı sıfırlıyoruz
  }

  void _stopTest() {
    setState(() {
      _isTestStarted = false;
      _isTestFinished = true;
      _showSaveOption = true; // Kaydetme seçeneğini göster
    });
    _stopwatch.stop();
    _checkPerformance(_age, _isMale); // Performans kontrolü yap
  }

  // Denge kaybı ekleme fonksiyonu, kronometreyi durdurur
  void _loseBalance() {
    setState(() {
      _balanceLostCount++;
    });
    _stopwatch.stop(); // Denge kaybı eklendiğinde kronometre durdurulur
    _isTestStarted = false; // Test durdurulur
  }

  String _getElapsedTime() {
    final int milliseconds = _stopwatch.elapsedMilliseconds;
    final int seconds = (milliseconds / 1000).floor();
    final int minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Tarih ve saati formatlama fonksiyonu
  String _getCurrentDateTime() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy, HH:mm');
    return formatter.format(DateTime.now());
  }

  // Performans kontrolü
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

    if (_balanceLostCount >= expectedRange[0] && _balanceLostCount <= expectedRange[1]) {
      setState(() {
        _performanceResult = 'Denge yetiniz ortalama seviyede! Mevcut seviyenizi daha da geliştirmek için bireysel denge antrenmanlarımıza katılabilirsiniz.';
      });
    } else if (_balanceLostCount < expectedRange[0]) {
      setState(() {
        _performanceResult = 'Denge yetiniz ortalamanın üzerinde! Daha ileri seviyeye ulaşmak ve gelişiminizi sürdürmek için bireysel derslerimizle kendinizi zorlamaya ne dersiniz?';
      });
    } else {
      setState(() {
        _performanceResult = 'Denge yetiniz ortalamanın altında. Denge yetinizi geliştirmek için bireysel derslerimiz hakkında bilgi alabilirsiniz!';
      });
    }
  }

  void _saveResults() async {
    try {
      await FirebaseFirestore.instance.collection('uyelerim').doc(widget.memberId).collection('olcumlerim').add({
        'test': 'Flamingo Denge Testi',
        'balanceLostCount': _balanceLostCount,
        'sonuc': _performanceResult, // Performans sonucunu kaydet
        'tarih': _getCurrentDateTime(),
        'cinsiyet': _isMale ? 'Erkek' : 'Kadın', // Cinsiyet bilgisini kaydet
        'age': _age, // yas bilgisini kaydet
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler başarıyla kaydedildi!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler kaydedilirken bir hata oluştu!')));
    }
    _resetTest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flamingo Denge Testi", style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cinsiyet Seçimi Checkbox
                // Cinsiyet Seçimi Card içinde
              Card(
                color: Colors.black54, // Kartın arka plan rengini ayarlayabilirsiniz
                elevation: 0.8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Flamingo Denge Testi, sporcuların statik denge kabiliyetlerini tespit etmek amacıyla yapılan bir testtir. Sporcu seçili ayağı ile denge materyali üzerine çıkar ve 60 saniye boyunca dengeyi korumaya çalışır. Testin amacı, denge kaybı sayısını ve zamanını kaydetmektir.',
                  style: TextStyle(fontSize: 15,color: Colors.white,fontWeight: FontWeight.bold),
                ),
              ),
            ),
              Card(
                  color: Colors.black54, // Kartın arka plan rengini ayarlayabilirsiniz
                  elevation: 0.8, // Kartın gölgesini ekleyebilirsiniz
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
                // Geçen süre ve denge kaybı
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geçen Süre: ${_getElapsedTime()}',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Denge Kaybı: $_balanceLostCount',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Başlatma butonu
                ElevatedButton(
                  onPressed: _isTestStarted ? null : _startTest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Testi Başlat', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),

                // Durdurma butonu
                ElevatedButton(
                  onPressed: _isTestStarted ? _stopTest : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Testi Durdur', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),

                // Yeniden başlatma butonu
                ElevatedButton(
                  onPressed: _isTestStarted ? null : _resetTest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Testi Sıfırla', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 20),

                // Denge kaybı ekleme butonu
                ElevatedButton(
                  onPressed: _isTestStarted ? _loseBalance : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('Denge Kaybı Ekle', style: TextStyle(color: Colors.white)),
                ),

                // Test bitince verileri kaydetme seçeneği
                if (_showSaveOption)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: _saveResults,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: Text('Verileri Kaydet', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                SizedBox(height: 15,),
                // Performans sonucu
                if (_performanceResult.isNotEmpty)
                  Text(
                    'Performans Sonucu: $_performanceResult',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}