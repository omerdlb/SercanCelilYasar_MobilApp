import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _lessonCountController = TextEditingController();

  bool _isIndividualLesson = false; // Bireysel ders seçeneği için checkbox durumu

  String? _selectedBelt;
  String? _selectedPaket;

  final List<String> _beltOptions = [
    "Beyaz",
    "Sarı",
    "Sarı-Yeşil",
    "Yeşil",
    "Yeşil-Mavi",
    "Mavi",
    "Mavi-Kırmızı",
    "Kırmızı",
    "Kırmızı-Siyah",
    "Siyah"
  ];

  final List<String> _paketOptions = [
    "1 Aylık",
    "3 Aylık",
    "6 Aylık",
  ];

  List<String> _groupOptions = [];
  Map<String, bool> _selectedGroups = {}; // Seçilen grupları tutacak map
  bool _isLoadingGroups = true;

  // Tarih seçimi için eklenen değişkenler
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _birthDate;

  // Tarih formatlama fonksiyonu
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd-MM-yyyy').format(date); // gün-Ay-yıl formatı
  }

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('group_lessons').get();

      List<String> groupNames =
      snapshot.docs.map((doc) => doc['group_name'].toString()).toList();

      setState(() {
        _groupOptions = groupNames;
        _selectedGroups = {for (var group in groupNames) group: false};
        _isLoadingGroups = false;
      });
    } catch (e) {
      print('Error fetching groups: $e');
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  String _generateEmail(String name) {
    String normalizedName = name
        .replaceAll(RegExp(r"[ğĞ]"), "g")
        .replaceAll(RegExp(r"[üÜ]"), "u")
        .replaceAll(RegExp(r"[şŞ]"), "s")
        .replaceAll(RegExp(r"[ıİ]"), "i")
        .replaceAll(RegExp(r"[çÇ]"), "c")
        .replaceAll(RegExp(r"[öÖ]"), "o")
        .toLowerCase()
        .replaceAll(' ', '.');
    return '$normalizedName@dlbstudio.com';
  }

  // Tarih seçme fonksiyonu
  Future<void> _selectDate(BuildContext context, String dateType) async {
    DateTime? initialDate;
    DateTime firstDate;
    DateTime lastDate;
    
    switch (dateType) {
      case 'start':
        initialDate = _startDate;
        firstDate = DateTime(1900);
        lastDate = DateTime(2100);
        break;
      case 'end':
        initialDate = _endDate;
        firstDate = DateTime(1900);
        lastDate = DateTime(2100);
        break;
      case 'birth':
        initialDate = _birthDate;
        firstDate = DateTime(1900);
        lastDate = DateTime.now();
        break;
      default:
        initialDate = DateTime.now();
        firstDate = DateTime(1900);
        lastDate = DateTime(2100);
    }
    
    DateTime selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black,
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
            ),
            primaryColorDark: Colors.black,
          ),
          child: child!,
        );
      },
    ) ?? DateTime.now();
    
    setState(() {
      switch (dateType) {
        case 'start':
          _startDate = selectedDate;
          break;
        case 'end':
          _endDate = selectedDate;
          break;
        case 'birth':
          _birthDate = selectedDate;
          break;
      }
    });
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;


    // Yeni kullanıcı bilgilerini al
    String name = _nameController.text;
    String password = _passwordController.text;
    String baseEmail = _generateEmail(name);
    String email = baseEmail;
    String phoneNumber = _phoneController.text.trim();
    int paymentAmount = int.parse(_paymentController.text);

    if (phoneNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen 10 haneli bir telefon numarası girin.")),
      );
      return;
    }

    String formattedPhoneNumber = "+90$phoneNumber";
    String startDateFormatted = _formatDate(_startDate);
    String endDateFormatted = _formatDate(_endDate);
    String birthDateFormatted = _formatDate(_birthDate);
    int? lessonCount = _lessonCountController.text.isNotEmpty
        ? int.parse(_lessonCountController.text)
        : null;

    try {
      int emailSuffix = 1;
      bool emailExists = true;

      while (emailExists) {
        try {
          // Mevcut admin oturumunu koru
          User? currentAdmin = FirebaseAuth.instance.currentUser;
          if (currentAdmin == null) {
            throw Exception('Admin oturumu bulunamadı');
          }

          // Firebase Authentication ile yeni kullanıcı oluştur
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          emailExists = false;
          String uid = userCredential.user!.uid;

          // Seçilen grupların adlarını string olarak oluştur
          String selectedGroupsString = _selectedGroups.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .join(', ');

          // Firestore'a yeni kullanıcıyı kaydet
          await FirebaseFirestore.instance.collection('uyelerim').doc(uid).set({
            'name': name,
            'birthDate': birthDateFormatted.isNotEmpty ? birthDateFormatted : null,
            'email': email,
            'group': selectedGroupsString,
            'belt': _selectedBelt,
            'paket': _selectedPaket,
            'lessonCount': lessonCount,
            'lisans': "yok",
            'phoneNumber': formattedPhoneNumber,
            'paymentAmount': paymentAmount,
            'start_date': startDateFormatted.isNotEmpty ? startDateFormatted : null,
            'end_date': endDateFormatted.isNotEmpty ? endDateFormatted : null,
            'uid': uid,
            'isFirstTime': true,
          });

          // Seçilen gruplara üye ekleme işlemi
          for (var group in _selectedGroups.keys) {
            if (_selectedGroups[group] == true) {
              await FirebaseFirestore.instance
                  .collection('group_lessons')
                  .where('group_name', isEqualTo: group)
                  .get()
                  .then((querySnapshot) {
                if (querySnapshot.docs.isNotEmpty) {
                  querySnapshot.docs.first.reference
                      .collection('grup_uyeleri')
                      .doc(uid)
                      .set({
                    'name': name,
                    'birthDate': birthDateFormatted.isNotEmpty ? birthDateFormatted : null,
                    'belt': _selectedBelt,
                    'uid': uid,
                    'phoneNumber': formattedPhoneNumber,
                  });
                }
              });
            }
          }

          // Bireysel ders ekleme işlemi
          if (_isIndividualLesson) {
            await FirebaseFirestore.instance.collection('bireysel_dersler').add({
              'bireyselders_name': 'Özel Ders: $name',
              'uid': uid,
              'name': name,
              'birthDate': birthDateFormatted.isNotEmpty ? birthDateFormatted : null,
              'belt': _selectedBelt,
              'phoneNumber': formattedPhoneNumber,
            });
          }

          // Kazanc koleksiyonuna ekleme işlemi
          String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
          await FirebaseFirestore.instance.collection('kazanc').add({
            'name': name,
            'uid': uid,
            'group' : selectedGroupsString,
            'paymentAmount': paymentAmount,
            'date': formattedDate,
          });

          // Formu temizle
          _nameController.clear();
          _passwordController.clear();
          _phoneController.clear();
          _paymentController.clear();
          _lessonCountController.clear();
          setState(() {
            _selectedBelt = null;
            _selectedGroups = {for (var group in _groupOptions) group: false};
            _startDate = null;
            _endDate = null;
            _birthDate = null;
            _isIndividualLesson = false;
          });

          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Üye başarıyla oluşturuldu. Lütfen tekrar giriş yapın.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Oturumu kapat ve login sayfasına yönlendir
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          }

        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            email = baseEmail.replaceFirst(RegExp(r'@'), '${emailSuffix++}@');
          } else {
            print('Error saving member: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Üye eklenirken bir hata oluştu: ${e.message}')),
            );
            return;
          }
        }
      }
    } catch (e) {
      print('Error saving member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Üye eklenirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Üye Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000),
              Color(0xFF4A0000),
              Color(0xFF9A0202),
              Color(0xFFB00000),
              Color(0xFF9A0202),
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'İsim Soyisim',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen isim soyisim girin.';
                      }
                      return null;
                    },
                    cursorColor: Colors.white,
                  ),
                  // Doğum Tarihi Seçici
                  TextFormField(
                    controller: TextEditingController(text: _formatDate(_birthDate)),
                    decoration: InputDecoration(
                      labelText: 'Doğum Tarihi',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.white),
                        onPressed: () => _selectDate(context, 'birth'),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    readOnly: true,
                    validator: (value) {
                      if (_birthDate == null) {
                        return 'Lütfen bir doğum tarihi seçin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    cursorColor: Colors.white,
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifre girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Kuşak',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    value: _selectedBelt,
                    items: _beltOptions
                        .map((belt) => DropdownMenuItem(
                      value: belt,
                      child: Text(belt, style: TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBelt = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Lütfen bir kuşak seçin.';
                      }
                      return null;
                    },
                    dropdownColor: Colors.black,
                  ),
                  const SizedBox(height: 20),
                  _isLoadingGroups
                      ? Center(child: CircularProgressIndicator())
                      : Container(
                    height: 150, // Grup listesi için sabit bir yükseklik
                    child: ListView(
                      children: _groupOptions.map((group) {
                        return CheckboxListTile(
                          title: Text(group, style: TextStyle(color: Colors.white)),
                          value: _selectedGroups[group],
                          onChanged: (value) {
                            setState(() {
                              _selectedGroups[group] = value ?? false;
                            });
                          },
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ),
                  // Bireysel Ders Checkbox'u
                  CheckboxListTile(
                    title: Text(
                      'Bireysel Ders',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _isIndividualLesson,
                    onChanged: (value) {
                      setState(() {
                        _isIndividualLesson = value ?? false;
                      });
                    },
                    activeColor: Colors.black,
                    checkColor: Colors.white,
                  ),
                  SizedBox(height: 20,),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Paket Bilgisi',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                      ),
                    ),
                    value: _selectedPaket,
                    items: _paketOptions
                        .map((paket) => DropdownMenuItem(
                      value: paket,
                      child: Text(paket , style: TextStyle(color: Colors.white),),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaket = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Lütfen bir paket seçin.';
                      }
                      return null;
                    },
                    dropdownColor: Colors.black, // Listenin arka planını mavi yapmak (örneğin)
                  ),
                  TextFormField(
                    cursorColor: Colors.white,
                    controller: _lessonCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ders Sayısı (Opsiyonel)',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                        return 'Lütfen geçerli bir sayı girin.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    maxLength: 10,
                    cursorColor: Colors.white,
                    controller: _phoneController,
                    decoration: InputDecoration( labelText: "Telefon Numarası (Başında 0 olmadan)",
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifre girin.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20,),
                  TextFormField(
                    cursorColor: Colors.white,
                    controller: _paymentController,
                    decoration: InputDecoration( labelText: "Ödeme Miktarını Gir",
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen ödeme bilgisi girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Başlangıç Tarihi Seçici
                  TextFormField(
                    controller: TextEditingController(text: _formatDate(_startDate)),
                    decoration: InputDecoration(
                      labelText: 'Başlangıç Tarihi',
                      labelStyle: TextStyle(color: Colors.white), // Label'ı siyah yapar
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Alt çizgiyi siyah yapar
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapar
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.white), // Icon rengini siyah yapar
                        onPressed: () => _selectDate(context, 'start'),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    readOnly: true,
                    validator: (value) {
                      if (_startDate == null) {
                        return 'Lütfen bir başlangıç tarihi seçin.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
                  // Bitiş Tarihi Seçici
                  TextFormField(
                    controller: TextEditingController(text: _formatDate(_endDate)),
                    decoration: InputDecoration(
                      labelText: 'Bitiş Tarihi',
                      labelStyle: TextStyle(color: Colors.white), // Etiketi siyah yapar
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Alt çizgiyi siyah yapar
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapar
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.white), // İkonu siyah yapar
                        onPressed: () => _selectDate(context, 'end'),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    readOnly: true,
                    validator: (value) {
                      if (_endDate == null) {
                        return 'Lütfen bir bitiş tarihi seçin.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: _saveMember,
                      child: Text('Kaydet',style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}