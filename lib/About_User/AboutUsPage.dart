import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> with TickerProviderStateMixin {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
bool _isIndividualLesson = false;
bool _isLoading = true; // Yükleniyor durumu

int _currentPage = 0;
final PageController _pageController = PageController();
late Timer _timer;

// Doğum günü kayan yazı için
List<Map<String, dynamic>> todayBirthdays = [];
bool isLoadingBirthdays = true;
AnimationController? _animationController;
Animation<double>? _animation;

final List<Map<String, String>> _cards = [
  {
    "image": "assets/coachsercan.jpg",
    "title": "Sercan Celil Yaşar",
    "shortDescription": "Beni Yakından Tanıyın",
    "longDescription": "Sercan Celil Yaşar - Taekwondo Antrenörü Sercan Celil Yaşar, Taekwondo branşına 2009 yılında Kocaeli’nin Gölcük ilçesinde başlamış olup, 16 yıldır aktif olarak sporcu kimliğiyle kariyerine devam etmektedir. 2017 yılından beridir aktif olarak MİLLİ TAKIM SPORCUSU olarak müsabakalarda görev almaktadır. 2019-2023 yılları arasında Türkiye Olimpiyat Hazırlık Merkezi (TOHM) kampında yer almıştır. Kariyeri boyunca 1 Türkiye şampiyonluğu 5 Türkiye 3.lüğü  elde eden Sercan Celil Yaşar, ulusal turnuvalarda 30’dan fazla derece kazanmıştır. Uluslararası arenada ise UKRAYNA OPEN 3.lük TURKİSH OPEN 3.lük olmak üzere toplam  7 önemli dereceye sahiptir. Bu başarıları arasında Balkan Şampiyonası ve Ukrayna Open gibi prestijli organizasyonlarda elde ettiği dereceler de bulunmaktadır. Akademik kariyerine Celal Bayar Üniversitesi Spor Bilimleri Fakültesi Antrenörlük Bölümü’nde devam eden Sercan Celil Yaşar, uzmanlık alanı olarak Taekwondo branşını seçmiştir. Sporcu kimliğini akademik bilgiyle birleştirerek, hem kendi kariyerini geliştirmekte hem de gelecekteki sporculara rehberlik etmeyi hedeflemektedir."
  },
  {
    "image": "assets/huseyin.jpg",
    "title": "Hüseyin Emre Şıvgınkıran",
    "shortDescription": "Beni Yakından Tanıyın",
    "longDescription": "Hüseyin Emre ŞIVGINKIRAN - Taekwondo Antrenörü Hüseyin Emre Şıvgınkıran, Taekwondo branşına 2015 yılında İzmir’in Gaziemir ilçesinde başlamış olup, 10 yıldır aktif olarak sporcu kimliğiyle kariyerine devam etmektedir. 2020 yılından beridir aktif olarak MİLLİ TAKIM SPORCUSU olarak müsabakalarda görev almaktadır. Kariyeri boyunca 1 Türkiye 2.liği 6 Türkiye 3.lüğü  elde eden Hüseyin Emre Şıvgınkıran, ulusal turnuvalarda 10’dan fazla derece kazanmıştır. Uluslararası arenada ise TURKİSH OPEN 3.lük olmak üzere toplam  4 önemli dereceye sahiptir. Akademik kariyerine Celal Bayar Üniversitesi Spor Bilimleri Fakültesi Antrenörlük Bölümü’nde devam eden Hüseyin Emre Şıvgınkıran, uzmanlık alanı olarak Taekwondo branşını seçmiştir. Sporcu kimliğini akademik bilgiyle birleştirerek, hem kendi kariyerini geliştirmekte hem de gelecekteki sporculara rehberlik etmeyi hedeflemektedir"
  },
  {
    "image": "assets/tkdgrup.jpg",
    "title": "Grup Dersleri",
    "shortDescription": "Taekwondo'nun gücünü grup derslerinde keşfedin.",
    "longDescription": "Taekwondo grup dersleri, her seviyeye uygun olarak tasarlanmıştır. Temel tekniklerden gelişmiş dövüş stratejilerine kadar birçok konuyu içeren antrenmanlarla hem fiziksel gücünüzü artırabilir hem de dayanıklılığınızı geliştirebilirsiniz. Grup halinde çalışarak takım ruhunu hissedin ve motivasyonunuzu artırın."
  },
  {
    "image": "assets/tkdbireysel.jpg",
    "title": "Bireysel Dersler",
    "shortDescription": "Özel derslerle yeteneklerinizi geliştirin.",
    "longDescription": "Bireysel Taekwondo derslerinde, eğitmeninizle birebir çalışarak tekniklerinizi en iyi seviyeye taşıyabilirsiniz. Kişiye özel antrenman programları ile hedeflerinize daha hızlı ulaşabilir, kuşak sınavlarına ve müsabakalara daha iyi hazırlanabilirsiniz. Kendi hızınızda öğrenerek hem fiziksel hem de mental gücünüzü en üst seviyeye çıkarın."
  },
  {
    "image": "assets/athletichtest.jpg",
    "title": "Atletik Performans Testleri",
    "shortDescription": "Atletik performans testleri ile eksiklerini kapat.",
    "longDescription": "Atletik performans testleri ile fiziksel kapasiteniz, dayanıklılığınız, hızınız ,esnekliğiniz ve çevikliğiniz ölçülür. Yapılan testler sonucunda, güçlü ve geliştirilmesi gereken alanlarınız belirlenir. Bu veriler ışığında, size özel antrenman programları oluşturulur. Böylece, belirlediğiniz hedeflere daha hızlı ve verimli bir şekilde ulaşabilirsiniz. Hem fiziksel hem de mental gücünüzü artırarak, spor performansınızı zirveye taşıyabilirsiniz."
  }
];


@override
void initState() {
  super.initState();
  _initializeData(); // Verileri başlat
}

Future<void> _initializeData() async {
  await _checkIndividualLesson(); // Bireysel ders kontrolü
  await _loadBirthdays(); // Doğum günlerini yükle
  await Future.delayed(Duration(seconds: 1)); // 2 saniye yükleme simülasyonu
  setState(() {
    _isLoading = false; // Yükleme tamamlandı
  });
  _startAutoScroll(); // Otomatik kaydırma başlat
}

@override
void dispose() {
  _timer.cancel();
  _pageController.dispose();
  _animationController?.dispose();
  super.dispose();
}

Future<void> _checkIndividualLesson() async {
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return;

  try {
    QuerySnapshot snapshot = await _firestore
        .collection('bireysel_dersler')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Kullanıcı bireysel derslerde ise, ilk elemanı (Aidat listesi) kaldır
      setState(() {
        _isIndividualLesson = true;
        _cards.removeAt(0); // İlk elemanı kaldır
      });
    } else {
      setState(() {
        _isIndividualLesson = false;
      });
    }
  } catch (e) {
    print("Bireysel ders kontrolünde hata: $e");
  }
}

Future<void> _loadBirthdays() async {
  try {
    setState(() {
      isLoadingBirthdays = true;
    });

    QuerySnapshot membersSnapshot = await _firestore.collection('uyelerim').get();
    List<Map<String, dynamic>> todayBirthdaysList = [];

    DateTime today = DateTime.now();

    for (var doc in membersSnapshot.docs) {
      Map<String, dynamic> member = doc.data() as Map<String, dynamic>;
      
      if (member['birthDate'] != null && member['birthDate'].isNotEmpty) {
        String birthDate = member['birthDate'];
        
        // Doğum tarihini parse et (dd-MM-yyyy formatında)
        try {
          List<String> dateParts = birthDate.split('-');
          if (dateParts.length == 3) {
            int day = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int year = int.parse(dateParts[2]);
            
            // Bu yıl için doğum günü tarihini oluştur
            DateTime thisYearBirthday = DateTime(today.year, month, day);
            
            // Bugün doğum günü mü kontrol et
            if (thisYearBirthday.day == today.day && thisYearBirthday.month == today.month) {
              // Yaş hesapla
              int age = today.year - year;
              
              todayBirthdaysList.add({
                'name': member['name'] ?? 'İsimsiz',
                'age': age,
                'birthDate': birthDate,
              });
            }
          }
        } catch (e) {
          // Tarih parse edilemezse atla
          continue;
        }
      }
    }

    setState(() {
      todayBirthdays = todayBirthdaysList;
      isLoadingBirthdays = false;
    });
  } catch (e) {
    setState(() {
      isLoadingBirthdays = false;
    });
  }
}

Widget _buildScrollingBirthdayText() {
  if (isLoadingBirthdays || todayBirthdays.isEmpty) {
    return SizedBox.shrink();
  }

  // Tüm doğum günü mesajlarını birleştir
  String allBirthdayMessages = todayBirthdays
      .map((member) => '🎂 Doğum günün kutlu olsun ${member['name']} 🎂')
      .join(' • ');

  return Container(
    height: 45,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipRect(
      child: AnimatedBuilder(
        animation: _createScrollingAnimation(),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(-_createScrollingAnimation().value * 800, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  allBirthdayMessages,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                ),
                SizedBox(width: 200),
                Text(
                  allBirthdayMessages,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                ),
                SizedBox(width: 200),
                Text(
                  allBirthdayMessages,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Animation<double> _createScrollingAnimation() {
  if (_animationController == null) {
    _animationController = AnimationController(
      duration: Duration(seconds: 15),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.linear,
    ));
    _animationController!.repeat();
  }
  return _animation!;
}

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_currentPage < _cards.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; // Başa dön
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _showCoachSelectionDialog(BuildContext context, String courseTitle) async {
    // Firestore'dan antrenörleri çek
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('coach')
        .doc('trainers')
        .collection('trainers')
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıtlı antrenör bulunamadı.")),
      );
      return;
    }

    // Antrenörleri listele
    List<String> coaches = snapshot.docs.map((doc) => doc['name'] as String).toList();

    // Dialog aç
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Antrenör Seçin"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: coaches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(coaches[index]),
                  onTap: () {
                    Navigator.pop(context); // Dialog'u kapat
                    _saveInquiry(context, courseTitle, coaches[index]); // Seçilen antrenörü kaydet
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveInquiry(BuildContext context, String courseTitle, String coachName) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Kullanıcı bilgilerini alıyoruz
    var userRef = FirebaseFirestore.instance.collection('uyelerim').doc(uid);
    var userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      String userName = userSnapshot['name'];

      try {
        // Coach koleksiyonuna veri kaydediyoruz
        await FirebaseFirestore.instance
            .collection('coach')
            .doc('talepler')
            .collection('requests')
            .add({
          'userName': userName,
          'courseTitle': courseTitle,
          'coachName': coachName, // Seçilen antrenörün adını kaydet
          'timestamp': FieldValue.serverTimestamp(), // İsteğin zamanını kaydet
        });

        // Başarılı kayıt sonrası kullanıcıya bilgi vermek için SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Görüşme talebiniz başarıyla antrenöre iletildi!'),
            duration: Duration(seconds: 3),
          ),
        );

        // Pop-up menüsünü kapatıyoruz
        Navigator.pop(context); // Pop-up menüsünü kapat
      } catch (e) {
        print("Kayıt işlemi sırasında hata oluştu: $e");
      }
    } else {
      print("Kullanıcı verisi bulunamadı");
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text('Hakkımızda', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator()) // Yükleme ekranı
        : Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF000000), // Siyah
            Color(0xFF9A0202), // Kırmızı
            Color(0xFFC80101), // Koyu Kırmızı
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          _buildCardCarousel(),
          SizedBox(height: 5),
          _buildPageIndicators(),
          SizedBox(height: 20),
          _buildScrollingBirthdayText(),
          _buildAnnouncements(),
        ],
      ),
    ),
  );
}

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController, // PageController'ı ekledik
        itemCount: _cards.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final card = _cards[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                _showBottomSheet(context, index);
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        card['image'] ?? '',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        card['title'] ?? 'Başlık Yok',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        card['shortDescription'] ?? 'Açıklama Yok',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  void _showBottomSheet(BuildContext context, int index) {
    final card = _cards[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Üstteki boşluğu görünmez yapar
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75, // Başlangıçta %75 ekranı kaplasın
          maxChildSize: 0.9,     // En fazla %90 açılabilsin (daha fazla içerik görünmesi için)
          minChildSize: 0.5,     // Minimum %50 boyutunda sabit kalsın
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Kenarları yuvarlak yap
              child: Container(
                color: Colors.white, // İçeriğin arka planını beyaz yap
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: BouncingScrollPhysics(), // Kaydırma daha akıcı olur
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                card['image'] ?? '',
                                width: 350,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            card['title'] ?? 'Başlık Yok',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Ayrıntılı Bilgi:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Text(
                            card['longDescription'] ?? 'Ayrıntılı bilgi yok',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.6,
                            ),
                          ),
                        ),
                        childCount: 1, // Sadece uzun açıklamayı ekle
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                          onPressed: () {
                            _showCoachSelectionDialog(context, card['title']!); // Antrenör seçim dialogunu aç
                          },
                          child: Text(
                            "Antrenör ile görüşme talebi oluştur",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 20), // Alt boşluk
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildAnnouncements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              title: Text(
                "Duyurular",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              subtitle: Text(
                "Şu an duyuru yok",
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Duyurular",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      title: Text(doc['title'], style: TextStyle(fontSize: 18)),
                      subtitle: Text(doc['content'], style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _cards.length,
            (index) => Container(
          margin: const EdgeInsets.all(5.0),
          height: 10.0,
          width: 10.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}