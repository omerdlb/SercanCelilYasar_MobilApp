import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BMICalculator extends StatefulWidget {
  final String memberId;

  const BMICalculator({super.key, required this.memberId});

  @override
  _BMICalculatorState createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = "Erkek";
  double? _bmi;
  String _bmiResult = "";

  void _calculateBMI() {
    double height = double.tryParse(_heightController.text) ?? 0;
    double weight = double.tryParse(_weightController.text) ?? 0;

    if (height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen geçerli değerler giriniz!"))
      );
      return;
    }

    double heightInMeters = height / 100;
    double bmi = weight / (heightInMeters * heightInMeters);

    String result;
    if (bmi < 18.5) {
      result = "Zayıf";
    } else if (bmi >= 18.5 && bmi < 24.9) {
      result = "Normal";
    } else if (bmi >= 25 && bmi < 29.9) {
      result = "Fazla Kilolu";
    } else {
      result = "Obez";
    }

    setState(() {
      _bmi = bmi;
      _bmiResult = result;
    });

    _saveToFirestore(bmi, result);
  }

  void _saveToFirestore(double bmi, String result) async {
    try {
      await FirebaseFirestore.instance
          .collection('uyelerim')
          .doc(widget.memberId)
          .collection('olcumlerim')
          .add({
        'test': 'Vücut Kitle İndeksi (BMI)',
        'yas': int.tryParse(_ageController.text) ?? 0,
        'cinsiyet': _gender,
        'boy': double.tryParse(_heightController.text) ?? 0,
        'kilo': double.tryParse(_weightController.text) ?? 0,
        'bmi': bmi.toStringAsFixed(1),
        'sonuc': result,
        'tarih': _getCurrentDateTime(), // Tarih ve saat
      });

      // Başarılı işlem mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BMI başarıyla kaydedildi!')),
      );
    } catch (e) {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BMI kaydedilirken hata oluştu!')),
      );
    }
  }

 // Tarih ve saati formatlama fonksiyonu
  String _getCurrentDateTime() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy, HH:mm');
    return formatter.format(DateTime.now());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Vücut Kitle İndeksi Hesaplama",
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Yaş", labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                  ),
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white,
              ),
              DropdownButton<String>(
                dropdownColor: Colors.black,
                value: _gender,
                items: ["Erkek", "Kadın"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(color: Colors.white),),

                  );

                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
              ),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                    labelText: "Boy (cm)",labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                    labelText: "Kilo (kg)",
                  labelStyle:  TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: _calculateBMI,
                child: const Text("BMI Hesapla ve Kaydet",style: TextStyle(color: Colors.white),),
              ),
              const SizedBox(height: 20),
              if (_bmi != null)
                Text(
                  "BMI: ${_bmi!.toStringAsFixed(1)} - $_bmiResult",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}