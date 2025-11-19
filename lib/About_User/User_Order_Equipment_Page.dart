import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserOrderEquipmentPage extends StatefulWidget {
  const UserOrderEquipmentPage({super.key});

  @override
  _UserOrderEquipmentPageState createState() => _UserOrderEquipmentPageState();
}

class _UserOrderEquipmentPageState extends State<UserOrderEquipmentPage> {
  int _currentPage = 0;
  String? username;
  bool? isApproved;
  bool isOrderPlaced = false;
  double totalPrice = 0.0; // Toplam fiyat

  final List<Map<String, dynamic>> _cards = [
    {"image": "assets/dobok.jpg", "title": "Beyaz Yaka Dobok", "price": 1500.0},
    {"image": "assets/kusak.jpg", "title": "Kuşak", "price": 200.0},
    {"image": "assets/yelek.png", "title": "Yelek", "price": 1150.0},
    {"image": "assets/kolkaval.jpg", "title": "Kol-Kaval Koruyucu", "price": 1100.0},
    {"image": "assets/kask.png", "title": "Kask", "price": 1500.0},
    {"image": "assets/kapalıkask.png", "title": "Kapalı Kask", "price": 1800.0},
    {"image": "assets/prodobokalt.jpg", "title": "Profesyonel Alt Dobok", "price": 1100.0},
    {"image": "assets/ayakkabı.png", "title": "Taekwondo İdman Ayakkabısı", "price": 1600.0},
    {"image": "assets/raketellik.jpg", "title": "Raket Ellik", "price": 1100.0},
    {"image": "assets/yastıkellik.jpg", "title": "Yastık Ellik", "price": 1200.0},
    {"image": "assets/siyahyakadobok.jpg", "title": "Siyah Yaka Dobok", "price": 3500.0},
    {"image": "assets/ayaküstü.png", "title": "Ayak Üstü Koruyucu", "price": 1150.0},
    {"image": "assets/eldiven.png", "title": "El Üstü Koruyucu", "price": 1150.0},
    {"image": "assets/dişlik.png", "title": "Dişlik", "price": 200.0},
    {"image": "assets/erkekkuki.png", "title": "Erkek Kuki", "price": 600.0},
    {"image": "assets/kadınkuki.png", "title": "Kadın Kuki", "price": 600.0},
  ];

  Map<String, List<String>> sizeOptions = {
    "Beyaz Yaka Dobok": ["90 cm", "1.10 cm", "1.20 cm", "1.30 cm", "1.40 cm", "1.50 cm", "1.60 cm", "1.70 cm", "1.80 cm"],
    "Kuşak": ["Beyaz", "Sarı", "Sarı Yeşil", "Yeşil", "Yeşil Mavi", "Mavi", "Mavi Kırmızı", "Kırmızı", "Kırmızı Siyah", "Siyah"],
    "Kol-Kaval Koruyucu": ["XS", "S", "M", "L", "XL"],
    "Kask": ["S", "M", "L"],
    "Yelek": ["0 Numara", "1 Numara", "2 Numara","3 Numara","4 Numara"],
    "Profesyonel Alt Dobok": ["1.30 cm", "1.40 cm", "1.50 cm", "1.60 cm", "1.70 cm", "1.80 cm", "1.90 cm"],
    "Taekwondo İdman Ayakkabısı": ["36", "37", "38", "39", "40", "41", "42", "43", "44"],
    "Siyah Yaka Dobok": ["90 cm", "1.10 cm", "1.20 cm", "1.30 cm", "1.40 cm", "1.50 cm", "1.60 cm", "1.70 cm", "1.80 cm"],
    "Ayak Üstü Koruyucu": ["XS (25-30 numara)", "S (31-36 numara)", "M (37-40 numara)", "L (41-43 numara)"],
    "El Üstü Koruyucu": ["XS", "S", "M", "L"],
    "Erkek Kuki": ["XS", "S", "M", "L"],
    "Kadın Kuki": ["XS", "S", "M", "L"],
    "Kapalı Kask": ["XS", "S", "M", "L"],
  };

  Map<String, bool> isExpanded = {
    "Dobok": false,
    "Kuşak": false,
    "Yelek": false,
    "Kol-Kaval Koruyucu": false,
    "Kask": false,
    "Profesyonel Alt Dobok": false,
    "Taekwondo İdman Ayakkabısı": false,
    "Raket Ellik": false,
    "Yastık Ellik": false,
    "Siyah Yaka Dobok": false,
    "Ayak Üstü Koruyucu": false,
    "El Üstü Koruyucu": false,
  };

  Map<String, int> selectedQuantities = {
    "Raket Ellik": 0,
    "Yastık Ellik": 0,
    "Dişlik": 0,
  };

  Map<String, String?> selectedSizes = {
    "Dobok": null,
    "Kuşak": null,
    "Yelek": null,
    "Kol-Kaval Koruyucu": null,
    "Kask": null,
    "Profesyonel Alt Dobok": null,
    "Taekwondo İdman Ayakkabısı": null,
    "Siyah Yaka Dobok": null,
    "El Üstü Koruyucu": null,
  };

  @override
  void initState() {
    super.initState();
    _fetchUsername(); // _fetchOrderStatus() burada çağrılmayacak
  }

  Future<void> _fetchUsername() async {
    try {
      // Kullanıcı hazır değilse authStateChanges ile bekle
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null);
      }
      final String uid = user?.uid ?? '';
      if (uid.isEmpty) {
        print('No UID found for current user.');
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('uyelerim')
          .doc(uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        final String? fetchedName = (data == null) ? null : data['name'] as String?;

        if (!mounted) return;
        setState(() {
          username = (fetchedName == null || fetchedName.isEmpty)
              ? 'Bilinmeyen Kullanıcı'
              : fetchedName;
        });

        print('Username set to: ' + (username ?? 'null'));
        await _fetchOrderStatus();
      } else {
        print('uyelerim/$uid belgesi bulunamadı.');
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  Future<void> _fetchOrderStatus() async {
    if (username == null || (username?.isEmpty ?? true)) {
      print("Username is null or empty. Cannot fetch order status.");
      return;
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection("equipmentOrders").doc(username).get();

      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          isApproved = snapshot.data()?["isApproved"] ?? false;
          isOrderPlaced = true;
        });
      } else {
        setState(() {
          isOrderPlaced = false;
        });
      }
    } catch (e) {
      print("Sipariş durumu alınırken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Malzeme Sipariş', style: TextStyle(color: Colors.white)),
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
          child: Column(
            children: [
              _buildCardCarousel(),
              const SizedBox(height: 20),
              _buildPageIndicators(),
              const SizedBox(height: 20),
              _buildSizeDropdown(title: "Beyaz Yaka Dobok"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Kuşak"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Yelek"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Kol-Kaval Koruyucu"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Ayak Üstü Koruyucu"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "El Üstü Koruyucu"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Kask"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Kapalı Kask"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Erkek Kuki"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Kadın Kuki"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Profesyonel Alt Dobok"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Taekwondo İdman Ayakkabısı"),
              const SizedBox(height: 10),
              _buildSizeDropdown(title: "Siyah Yaka Dobok"),
              const SizedBox(height: 10),
              _buildQuantityDropdown(title: "Dişlik", price: 200.0),
              const SizedBox(height: 10),
              _buildQuantityDropdown(title: "Raket Ellik", price: 1100.0),
              const SizedBox(height: 10),
              _buildQuantityDropdown(title: "Yastık Ellik", price: 1200.0),
              const SizedBox(height: 20),
              Text("Toplam Fiyat: ${totalPrice.toStringAsFixed(2)} TL", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _submitOrder,
                child: Text(isOrderPlaced ? "Talebi Düzenle" : "Talepte Bulun", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 20),
              _buildOrderStatus(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeDropdown({required String title}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            subtitle: Text(
              "Fiyat: ${_cards.firstWhere(
                    (element) => element["title"] == title,
                orElse: () => {"price": 0.0}, // Eğer eleman bulunamazsa varsayılan değer
              )["price"]} TL",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: Icon(isExpanded[title] ?? false ? Icons.expand_less : Icons.expand_more, color: Colors.black),
            onTap: () {
              setState(() {
                isExpanded[title] = !(isExpanded[title] ?? false);
              });
            },
          ),
          if (isExpanded[title] ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: DropdownButton<String>(
                value: selectedSizes[title],
                hint: Text("Seçiniz", style: TextStyle(color: Colors.black)),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSizes[title] = newValue;
                    _calculateTotalPrice();
                  });
                },
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text("Seçiniz", style: TextStyle(color: Colors.black)),
                  ),
                  ...sizeOptions[title]!.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityDropdown({required String title, required double price}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            subtitle: Text("Fiyat: $price TL", style: TextStyle(fontSize: 14, color: Colors.grey)),
            trailing: Icon(isExpanded[title] ?? false ? Icons.expand_less : Icons.expand_more, color: Colors.black),
            onTap: () {
              setState(() {
                isExpanded[title] = !(isExpanded[title] ?? false);
              });
            },
          ),
          if (isExpanded[title] ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: DropdownButton<int>(
                value: selectedQuantities[title],
                onChanged: (int? newValue) {
                  setState(() {
                    selectedQuantities[title] = newValue ?? 0;
                    _calculateTotalPrice();
                  });
                },
                items: List.generate(10, (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text("$index adet", style: TextStyle(color: Colors.black)),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _calculateTotalPrice() {
    double newTotal = 0.0;

    // Seçilen boyutlu ürünlerin fiyatlarını ekle
    selectedSizes.forEach((key, value) {
      if (value != null) {
        newTotal += _cards.firstWhere(
              (element) => element["title"] == key,
          orElse: () => {"price": 0.0},
        )["price"] as double;
      }
    });

    // Seçilen miktarlı ürünlerin fiyatlarını ekle
    selectedQuantities.forEach((key, value) {
      if (value > 0) {
        newTotal += (_cards.firstWhere(
              (element) => element["title"] == key,
          orElse: () => {"price": 0.0},
        )["price"] as double) * value;
      }
    });

    setState(() {
      totalPrice = newTotal;
    });
  }

  Widget _buildOrderStatus() {
    if (!isOrderPlaced) {
      return SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("equipmentOrders").doc(username).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Text("Sipariş durumu yükleniyor...", style: TextStyle(fontSize: 16));
        }

        bool? isApproved = snapshot.data!["isApproved"];

        if (isApproved == null || isApproved == false) {
          return Text("Siparişiniz beklemede.",
              style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold));
        } else {
          return Text("Talebiniz onaylandı!", style: TextStyle(fontSize: 16, color: Colors.green));
        }
      },
    );
  }

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: _cards.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final card = _cards[index];
          final image = card['image'];
          final title = card['title'];

          if (image == null || title == null) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text("Invalid card data", style: TextStyle(color: Colors.black)),
                ),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Card(
              color: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Image.asset(
                    image,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_cards.length, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 5),
          width: _currentPage == index ? 12.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  String _getCurrentDateTime() {
    final DateFormat formatter = DateFormat('dd-MM-yyyy, HH:mm');
    return formatter.format(DateTime.now());
  }
  Future<void> _submitOrder() async {
    if (username == null) {
      print("Username is null. Cannot submit order.");
      return;
    }

    Map<String, dynamic> orderData = {
      "username": username,
      "orderDate": _getCurrentDateTime(),
      "isApproved": false,
      "totalPrice": totalPrice,
      "items": []
    };

    // Boyutlu ürünleri ekle
    selectedSizes.forEach((key, value) {
      if (value != null) {
        orderData["items"].add({"title": key, "size": value, "price": _cards.firstWhere(
              (element) => element["title"] == key,
          orElse: () => {"price": 0.0},
        )["price"]});
      }
    });

    // Miktarlı ürünleri ekle
    selectedQuantities.forEach((key, value) {
      if (value > 0) {
        orderData["items"].add({"title": key, "quantity": value, "price": _cards.firstWhere(
              (element) => element["title"] == key,
          orElse: () => {"price": 0.0},
        )["price"] * value});
      }
    });

    try {
      await FirebaseFirestore.instance.collection("equipmentOrders").doc(username).set(orderData);
      setState(() {
        isOrderPlaced = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Siparişiniz başarıyla kaydedildi!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Sipariş kaydedilirken hata oluştu: $e");
    }
  }
}