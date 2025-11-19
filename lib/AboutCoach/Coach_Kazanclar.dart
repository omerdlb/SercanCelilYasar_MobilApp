import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CoachKazanclarimPage extends StatefulWidget {
  const CoachKazanclarimPage({super.key});

  @override
  _CoachKazanclarimPageState createState() => _CoachKazanclarimPageState();
}

class _CoachKazanclarimPageState extends State<CoachKazanclarimPage> {
  String _selectedFilter = "Tüm Zamanlar";
  String? _selectedMonth;
  String? _selectedGroup;
  String _searchQuery = ""; // Arama sorgusu için değişken
  TextEditingController _searchController = TextEditingController(); // Arama çubuğu için controller
  bool _isSearching = false; // Arama çubuğunun görünürlüğünü kontrol etmek için

  // Ayların isimlerini Türkçe olarak tanımla
  final List<String> ayIsimleri = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
  ];

  @override
  void initState() {
    super.initState();
  }

  // Parse date string in dd-MM-yyyy format
  DateTime parseDate(String dateString) {
    List<String> parts = dateString.split('-');
    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  // Filtre menüsünü açan fonksiyon
  void _openFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              title: Text("Tüm Zamanlar"),
              onTap: () {
                setState(() {
                  _selectedFilter = "Tüm Zamanlar";
                  _selectedMonth = null;
                  _selectedGroup = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Aylara Göre Listele"),
              onTap: () {
                setState(() {
                  _selectedFilter = "Aylara Göre Listele";
                  _selectedMonth = null;
                  _selectedGroup = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Grupları Karşılaştır"),
              onTap: () {
                setState(() {
                  _selectedFilter = "Grupları Karşılaştır";
                  _selectedMonth = null;
                  _selectedGroup = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Ödeme silme işlemi
  Future<void> _deletePayment(String paymentId) async {
    try {
      await FirebaseFirestore.instance.collection('kazanc').doc(paymentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödeme başarıyla silindi.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ödeme silinirken hata oluştu: $e")),
      );
    }
  }

  // Ödeme düzenleme sayfasına yönlendirme
  void _editPayment(Map<String, dynamic> payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPaymentPage(payment: payment),
      ),
    );
  }

  // Arama çubuğunu göster veya gizle
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching; // Arama çubuğunun görünürlüğünü değiştir
      if (!_isSearching) {
        _searchController.clear(); // Arama çubuğu gizlendiğinde temizle
        _searchQuery = ""; // Arama sorgusunu sıfırla
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Kazançlarım', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearch, // Arama ikonuna tıklandığında arama çubuğunu göster/gizle
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _openFilterMenu, // Filtre ikonuna tıklandığında menü açılır
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah
              Color(0xFF9A0202), // Kırmızı
              Color(0xFFC80101), // Koyu Kırmızı
            ],
            begin: Alignment.topCenter, // Üstten başlasın
            end: Alignment.bottomCenter, // Alta doğru gitsin
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                'Filtre: $_selectedFilter ${_selectedMonth != null ? "- ${ayIsimleri[int.parse(_selectedMonth!) - 1]}" : ""} ${_selectedGroup != null ? "- $_selectedGroup" : ""}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10),
              // Arama çubuğu
              if (_isSearching) // Arama çubuğu yalnızca arama aktifse gösterilir
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value; // Arama sorgusunu güncelle
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "İsimle Ara",
                    hintStyle: TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('kazanc')
                      .snapshots(), // Firestore'dan veri akışını başlatıyoruz
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator()); // Yükleme sırasında gösterilecek
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Veri yok.", style: TextStyle(color: Colors.white))); // Veri yoksa gösterilecek
                    }

                    // Verileri aldıktan sonra listeyi oluşturuyoruz
                    List<dynamic> payments = snapshot.data!.docs.map((doc) {
                      return {
                        'id': doc.id, // Firestore'dan gelen ID'yi ekleyin
                        'paymentAmount': doc['paymentAmount'] ?? 0, // Null kontrolü
                        'date': doc['date'] ?? 'No Date', // Tarih
                        'name': doc['name'] ?? 'No Name', // İsim
                        'group': doc['group'] ?? 'No Group', // Grup
                      };
                    }).toList();

                    // Eğer bir ay seçildiyse, ödemeleri o aya göre filtrele
                    if (_selectedMonth != null) {
                      payments = payments.where((payment) {
                        DateTime date = parseDate(payment['date']); // Tarihi parse et
                        return date.month.toString() == _selectedMonth;
                      }).toList();
                    }

                    // Eğer bir grup seçildiyse, ödemeleri o gruba göre filtrele
                    if (_selectedGroup != null) {
                      payments = payments.where((payment) {
                        return payment['group'] == _selectedGroup;
                      }).toList();
                    }

                    // Arama sorgusuna göre filtrele
                    if (_searchQuery.isNotEmpty) {
                      payments = payments.where((payment) {
                        return payment['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    // Toplam Geliri Hesapla
                    double totalIncome = payments.fold(0, (sum, payment) => sum + payment['paymentAmount']);

                    if (_selectedFilter == "Aylara Göre Listele" && _selectedMonth == null) {
                      return _buildMonthlySummary(payments); // Aylara göre özet göster
                    } else if (_selectedFilter == "Grupları Karşılaştır" && _selectedGroup == null) {
                      return _buildGroupComparison(payments); // Grupları karşılaştır
                    } else {
                      return _buildPaymentList(payments, totalIncome); // Ödeme listesini göster
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Aylara göre özet gösteren widget
  Widget _buildMonthlySummary(List<dynamic> payments) {
    Map<String, double> monthlyIncome = {};

    // Her bir ödeme için ayı ve kazancı hesapla
    for (var payment in payments) {
      DateTime date = parseDate(payment['date']); // Tarihi parse et
      String month = date.month.toString(); // Ayı al
      monthlyIncome[month] = (monthlyIncome[month] ?? 0) + payment['paymentAmount']; // Kazancı ekle
    }

    return ListView.builder(
      itemCount: 12, // 12 ay için
      itemBuilder: (context, index) {
        String month = (index + 1).toString(); // Ay numarası (1-12)
        double income = monthlyIncome[month] ?? 0; // Ayın kazancı (eğer yoksa 0)

        return ListTile(
          title: Text(ayIsimleri[index], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Ay ismi (Ocak, Şubat, ...)
          trailing: Text(
            "₺${income.toStringAsFixed(2)}", // Sağ tarafta ayın kazancı
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green, // Kazancı yeşil renkte göster
            ),
          ),
          onTap: () {
            setState(() {
              _selectedMonth = month; // Ay seçildiğinde _selectedMonth güncellenir
            });
          },
        );
      },
    );
  }

  // Grupları karşılaştıran widget
  Widget _buildGroupComparison(List<dynamic> payments) {
    Map<String, double> groupIncome = {};

    // Her bir ödeme için grubu ve kazancı hesapla
    for (var payment in payments) {
      String group = payment['group']; // Grubu al
      groupIncome[group] = (groupIncome[group] ?? 0) + payment['paymentAmount']; // Kazancı ekle
    }

    return ListView.builder(
      itemCount: groupIncome.length,
      itemBuilder: (context, index) {
        String group = groupIncome.keys.elementAt(index); // Grup ismi
        double income = groupIncome[group] ?? 0; // Grubun kazancı

        return ListTile(
          title: Text(group, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Grup ismi
          trailing: Text(
            "₺${income.toStringAsFixed(2)}", // Sağ tarafta grubun kazancı
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green, // Kazancı yeşil renkte göster
            ),
          ),
          onTap: () {
            setState(() {
              _selectedGroup = group; // Grup seçildiğinde _selectedGroup güncellenir
            });
          },
        );
      },
    );
  }

  // Ödeme listesini gösteren widget
  Widget _buildPaymentList(List<dynamic> payments, double totalIncome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Toplam Gelir kısmı
        Container(
          width: 150, // Çemberin çapı
          height: 150, // Çemberin çapı
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // Çemberin rengi
            shape: BoxShape.circle, // Çember şekli
          ),
          child: Center(
            child: Text(
              "₺${totalIncome.toStringAsFixed(2)}", // Geliri Türk Lirası simgesi ile göster
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Metin rengi
              ),
            ),
          ),
        ),
        SizedBox(height: 10), // Çember ile "Toplam Gelir" arasına boşluk
        Text(
          'Toplam Gelir',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Metin rengi
          ),
        ),
        SizedBox(height: 20), // "Toplam Gelir" metni ile liste arasına boşluk
        Expanded(
          child: ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 3, // Gölgelendirme
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Kenarlardan boşluk
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Kartın köşelerini yuvarla
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Kartın iç boşluğu
                  child: ListTile(
                    title: Text(
                      "Ödeme Miktarı: ₺${payments[index]['paymentAmount']}",
                      style: const TextStyle(fontWeight: FontWeight.bold), // Kalın başlık
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                          "Tarih: ${payments[index]['date']}", // Tarih bilgisi
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        Text(
                          "İsim: ${payments[index]['name']}", // İsim bilgisi
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        Text(
                          "Grup: ${payments[index]['group']}", // Grup bilgisi
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editPayment(payments[index]); // Düzenleme işlemi
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deletePayment(payments[index]['id']); // Silme işlemi
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
// Düzenleme sayfası
class EditPaymentPage extends StatefulWidget {
  final Map<String, dynamic> payment;

  const EditPaymentPage({super.key, required this.payment});

  @override
  _EditPaymentPageState createState() => _EditPaymentPageState();
}

class _EditPaymentPageState extends State<EditPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _nameController;
  late String _selectedGroup;


  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.payment['paymentAmount'].toString());
    _dateController = TextEditingController(text: widget.payment['date']);
    _nameController = TextEditingController(text: widget.payment['name']);
    _selectedGroup = widget.payment['group'] ?? 'No Group'; // Varsayılan grup

  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _nameController.dispose();
    super.dispose();
  }


  // Tarih seçiciyi aç
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.black,
            colorScheme: ColorScheme.dark(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }
  // Ödemeyi güncelle
  Future<void> _updatePayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('kazanc')
            .doc(widget.payment['id'])
            .update({
          'paymentAmount': double.parse(_amountController.text),
          'date': _dateController.text,
          'name': _nameController.text,
          'group': _selectedGroup,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ödeme başarıyla güncellendi.")),
        );
        Navigator.pop(context); // Düzenleme sayfasını kapat
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ödeme güncellenirken hata oluştu: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Ödeme Düzenle" , style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: Icon(Icons.save,color: Colors.white,),
            onPressed: _updatePayment,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah
              Color(0xFF9A0202), // Kırmızı
              Color(0xFFC80101), // Koyu Kırmızı
            ],
            begin: Alignment.topCenter, // Üstten başlasın
            end: Alignment.bottomCenter, // Alta doğru gitsin
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Ödeme Miktarı',
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
                      return 'Lütfen ödeme miktarını girin';
                    }
                    return null;
                  },

                  cursorColor: Colors.white,
                ),
                TextFormField(
                  controller: _dateController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: "Tarih",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today,color: Colors.white,),
                      onPressed: () => _selectDate(context),
                    ),
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  readOnly: true, // Tarih seçiciyi açmak için
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Lütfen tarihi girin";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "İsim",
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // Normal durumda alt çizgiyi siyah yapmak
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // Focus olduğunda alt çizgiyi siyah yapmak
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Lütfen ismi girin";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: _updatePayment,
                  child: Text("Güncelle",style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}