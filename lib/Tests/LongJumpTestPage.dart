import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LongJumpTestPage extends StatefulWidget {
  final String memberId;

  const LongJumpTestPage({super.key, required this.memberId});

  @override
  _LongJumpTestPageState createState() => _LongJumpTestPageState();
}

class _LongJumpTestPageState extends State<LongJumpTestPage> {
  final _formKey = GlobalKey<FormState>();
  double? _jump1, _jump2, _bestJump;
  String? _gender;
  int? _age;
  String? _performanceLevel;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('uyelerim').doc(widget.memberId).get();
      if (userDoc.exists) {
        setState(() {
          _age = userDoc['age'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yaş bilgisi alınamadı!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Durarak Uzun Atlama Testi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF9A0202), Color(0xFFC80101)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTestDescription(),
              SizedBox(height: 20),
              _buildGenderSelection(),
              SizedBox(height: 20),
              _buildJumpForm(),
              SizedBox(height: 20),
              if (_bestJump != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En İyi Atlama Skoru: ${_bestJump!.toStringAsFixed(2)} m',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    if (_performanceLevel != null)
                      Text(
                        'Performans Seviyesi: $_performanceLevel',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: _saveResults,
                child: Text('Sonuçları Kaydet', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Card(
      color: Colors.black54,
      elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cinsiyetinizi Seçin:',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            CheckboxListTile(
              title: Text("Erkek", style: TextStyle(color: Colors.white)),
              value: _gender == "Erkek",
              activeColor: Colors.green, // Seçildiğinde yeşil olacak
              onChanged: (bool? value) {
                setState(() {
                  _gender = value == true ? "Erkek" : null;
                });
              },
            ),
            CheckboxListTile(
              title: Text("Kadın", style: TextStyle(color: Colors.white)),
              value: _gender == "Kadın",
              activeColor: Colors.green, // Seçildiğinde yeşil olacak
              onChanged: (bool? value) {
                setState(() {
                  _gender = value == true ? "Kadın" : null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildJumpForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJumpInputField('1. Deneme Skoru (Cm cinsinden):', (value) {
            _jump1 = double.tryParse(value ?? '');
          }),
          SizedBox(height: 20),
          _buildJumpInputField('2. Deneme Skoru (Cm cinsinden):', (value) {
            _jump2 = double.tryParse(value ?? '');
          }),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: _calculateBestJump,
            child: Text('En İyi Sonucu Hesapla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildJumpInputField(String label, Function(String?) onSaved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
        TextFormField(
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: 'Ölçüm (cm cinsinden)',
            labelStyle: TextStyle(color: Colors.white),
            hintText: 'Örneğin: 150 yazınız (150 cm = 1.50 m)',
            hintStyle: TextStyle(color: Colors.white),
            enabledBorder: UnderlineInputBorder( // Pasifken beyaz çizgi
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder( // Seçildiğinde beyaz çizgi
              borderSide: BorderSide(color: Colors.white, width: 2.0),
            ),
          ),
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // Sadece sayıların girilmesine izin ver
            if (RegExp(r'^[0-9]+$').hasMatch(value)) {
              // Eğer sayı ise bir şey yap
            } else {
              // Eğer sayı değilse inputu temizle veya başka bir işlem yap
              // Burada örnek olarak sadece sayı dışı girişleri engelliyoruz
            }
          },
          onSaved: (value) {
            double? cmValue = double.tryParse(value ?? '');
            if (cmValue != null) {
              onSaved((cmValue / 100).toString());
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Lütfen atlama mesafesini giriniz';
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Sadece sayı girilebilir';
            return null;
          },
        ),
      ],
    );
  }

  void _calculateBestJump() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        _bestJump = (_jump1 != null && _jump2 != null) ? (_jump1! > _jump2! ? _jump1 : _jump2) : null;
        _performanceLevel = _evaluatePerformance(_bestJump ?? 0);
      });
    }
  }

  String _evaluatePerformance(double jump) {
    if (_age == null || _gender == null) return 'Bilinmiyor';

    if (_gender == "Erkek") {
      if (_age! >= 5 && _age! <= 10) {
        if (jump >= 1.5) {
          return 'Harika! Performansın Üstün, mükemmel bir başlangıç! Özel derslerle seviyeni daha da ileriye taşıyabilirsin.';
        } else if (jump >= 1.0) {
          return 'İyi iş! Ancak özel derslerle daha da ileriye gidebilirsin!';
        } else {
          return 'Gelişmeye devam et! Özel derslerle hızla gelişebilirsin.';
        }
      }
      if (_age! >= 11 && _age! <= 18) {
        if (jump >= 2.0) {
          return 'Harika! Performansın Üstün, bu seviyeye çıkmak için harika bir yol aldın! Özel derslerle daha da üst seviyelere çıkabilirsin.';
        } else if (jump >= 1.5) {
          return 'İyi iş! Performansını daha da geliştirmek için özel derslere katılabilirsin.';
        } else {
          return 'Gelişmeye devam et! Özel derslerle atlayışını güçlendirebilirsin.';
        }
      }
    } else {
      if (_age! >= 5 && _age! <= 10) {
        if (jump >= 1.4) {
          return 'Harika! Performansın Üstün, çok iyi bir gelişim gösteriyorsun! Özel derslerle daha da ileriye gidebilirsin.';
        } else if (jump >= 0.9) {
          return 'İyi iş! Daha fazla gelişim için özel derslerle destek alabilirsin.';
        } else {
          return 'Gelişmeye devam et! Özel derslerle gelişimin çok daha hızlı olabilir.';
        }
      }
      if (_age! >= 11 && _age! <= 18) {
        if (jump >= 1.8) {
          return 'Harika! Performansın Üstün, çok iyi bir seviyeye geldin! Özel derslerle daha da üst seviyelere ulaşabilirsin.';
        } else if (jump >= 1.3) {
          return 'İyi iş! Performansını daha da ileriye taşımak için özel derslere katılabilirsin.';
        } else {
          return 'Gelişmeye devam et! Özel derslerle hızlıca gelişebilirsin.';
        }
      }
    }
    return 'Bilinmiyor';
  }
  void _saveResults() async {
    if (_bestJump != null) {
      await FirebaseFirestore.instance.collection('uyelerim').doc(widget.memberId).collection('olcumlerim').add({
        'test': 'Durarak Uzun Atlama Testi',
        'olcum1': _jump1,
        'olcum2': _jump2,
        'best': _bestJump,
        'tarih': DateFormat('dd-MM-yyyy, HH:mm').format(DateTime.now()),
        'cinsiyet': _gender,
        'yas': _age,
        'sonuc': _performanceLevel,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler başarıyla kaydedildi!')));
    }
  }

  Widget _buildTestDescription() {
    return Card(
      color: Colors.black54,
      elevation: 8.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Test Açıklaması:",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold ,fontSize: 16),
            ),
            Text(
              'Bu test, patlayıcı kuvveti ve kas gücünü ölçmek için yapılır. Ayaklar bitişik halde sıçrama çizgisinin gerisinde durulur, '
                  'dizler bükülerek ve kollar geriye sallanarak zıplanır. En iyi atlama skoru kaydedilir.',
              style: TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}