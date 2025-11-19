import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ManualTestAdd extends StatefulWidget {
  final String memberId;

  const ManualTestAdd({super.key, required this.memberId});

  @override
  _ManualTestAddState createState() => _ManualTestAddState();
}

class _ManualTestAddState extends State<ManualTestAdd> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _testTitleController = TextEditingController();
  final TextEditingController _testDescriptionController = TextEditingController();
  final TextEditingController _evaluationController = TextEditingController();
  List<TextEditingController> _resultControllers = [TextEditingController()];
  String _selectedEvaluation = 'Orta';
  bool _isManualEvaluation = false;

  final List<String> _evaluationOptions = [
    'Çok Kötü',
    'Kötü',
    'Orta',
    'İyi',
    'Çok İyi',
    'Geliştirilmeli'
  ];

  @override
  void dispose() {
    _testTitleController.dispose();
    _testDescriptionController.dispose();
    _evaluationController.dispose();
    for (var controller in _resultControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addResultField() {
    setState(() {
      _resultControllers.add(TextEditingController());
    });
  }

  void _removeResultField(int index) {
    if (_resultControllers.length > 1) {
      setState(() {
        _resultControllers[index].dispose();
        _resultControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveTest() async {
    if (_formKey.currentState!.validate()) {
      try {
        List<String> results = _resultControllers
            .map((controller) => controller.text)
            .where((text) => text.isNotEmpty)
            .toList();

        await FirebaseFirestore.instance
            .collection('uyelerim')
            .doc(widget.memberId)
            .collection('olcumlerim')
            .add({
          'test': _testTitleController.text,
          'aciklama': _testDescriptionController.text,
          'sonuclar': results,
          'degerlendirme': _isManualEvaluation ? _evaluationController.text : _selectedEvaluation,
          'tarih': DateTime.now().toString(),
          'test_tipi': 'manuel'
        });

        Fluttertoast.showToast(
          msg: "Test başarıyla kaydedildi",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Navigator.pop(context);
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Hata oluştu: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manuel Test Ekle", style: TextStyle(color: Colors.white)),
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _testTitleController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Test Başlığı',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen test başlığını girin';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _testDescriptionController,
                          style: TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Test Açıklaması',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen test açıklamasını girin';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sonuçlar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            ...List.generate(_resultControllers.length, (index) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _resultControllers[index],
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Sonuç ${index + 1}',
                                          labelStyle: TextStyle(color: Colors.white70),
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.red, width: 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_resultControllers.length > 1)
                                      Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: IconButton(
                                          icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                                          onPressed: () => _removeResultField(index),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            TextButton.icon(
                              onPressed: _addResultField,
                              icon: Icon(Icons.add_circle, color: Colors.white),
                              label: Text('Sonuç Ekle', style: TextStyle(color: Colors.white)),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Değerlendirme',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: Text(
                                      'Hazır Değerlendirme',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    value: false,
                                    groupValue: _isManualEvaluation,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isManualEvaluation = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: Text(
                                      'Manuel Değerlendirme',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    value: true,
                                    groupValue: _isManualEvaluation,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isManualEvaluation = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (!_isManualEvaluation)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedEvaluation,
                                  dropdownColor: Colors.grey[900],
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  items: _evaluationOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value, style: TextStyle(color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedEvaluation = newValue;
                                      });
                                    }
                                  },
                                ),
                              )
                            else
                              TextFormField(
                                controller: _evaluationController,
                                style: TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Değerlendirmenizi Yazın',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.red, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (_isManualEvaluation && (value == null || value.isEmpty)) {
                                    return 'Lütfen değerlendirme yazın';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Testi Kaydet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 