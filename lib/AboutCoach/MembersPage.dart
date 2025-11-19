import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personaltrainer/AboutCoach/MemberAddPage.dart';
import 'package:personaltrainer/User_Admin_Profile/MemberDetailsPage.dart';
import 'package:url_launcher/url_launcher.dart'; // WhatsApp mesajı göndermek için
import 'package:firebase_auth/firebase_auth.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // String _searchQuery = ''; // Arama sorgusu - şu an kullanılmıyor
  String _filterOption = 'Genel'; // Varsayılan filtre: Genel
  List<String> _selectedGroups = []; // Seçilen gruplar
  bool _canAddMember = false; // Üye ekleme yetkisi
  bool _isAdmin = false; // Admin kontrolü
  bool _isHelperCoach = false; // Helper Coach kontrolü
  bool isLoading = true; // Yükleme durumu
  
  // Üye görme yetkileri
  bool _canViewAllMembers = false;
  bool _canViewActiveMembers = false;
  bool _canViewExpiredMembers = false;
  bool _canViewPendingMembers = false;
  bool _canViewExcusedMembers = false;
  bool _canViewMemberStats = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // Kullanıcı rolünü kontrol et
  }

  // Kullanıcı rolünü ve yetkisini kontrol et
  Future<void> _checkUserRole() async {
    setState(() {
      isLoading = true;
    });
    
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        setState(() {
          // Admin kontrolü
          _isAdmin = adminDoc.exists && adminDoc.data() != null
              ? (adminDoc.data() as Map<String, dynamic>)['admin'] == true
              : false;

          if (_isAdmin) {
            // Admin ise tüm yetkileri ver
            _isHelperCoach = false;
            _canAddMember = true;
            _canViewAllMembers = true;
            _canViewActiveMembers = true;
            _canViewExpiredMembers = true;
            _canViewPendingMembers = true;
            _canViewExcusedMembers = true;
            _canViewMemberStats = true;
          } else {
            // Admin değilse helper coach ve yetkilerini kontrol et
            _isHelperCoach = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['helpercoach'] == true
                : false;
            _canAddMember = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canAddMember'] == true
                : false;
            
            // Üye görme yetkilerini kontrol et
            _canViewAllMembers = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewAllMembers'] == true
                : false;
            _canViewActiveMembers = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewActiveMembers'] == true
                : false;
            _canViewExpiredMembers = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewExpiredMembers'] == true
                : false;
            _canViewPendingMembers = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewPendingMembers'] == true
                : false;
            _canViewExcusedMembers = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewExcusedMembers'] == true
                : false;
            _canViewMemberStats = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewMemberStats'] == true
                : false;
          }
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isAdmin = false;
          _isHelperCoach = false;
          _canAddMember = false;
          _canViewAllMembers = false;
          _canViewActiveMembers = false;
          _canViewExpiredMembers = false;
          _canViewPendingMembers = false;
          _canViewExcusedMembers = false;
          _canViewMemberStats = false;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        _isAdmin = false;
        _isHelperCoach = false;
        _canAddMember = false;
        _canViewAllMembers = false;
        _canViewActiveMembers = false;
        _canViewExpiredMembers = false;
        _canViewPendingMembers = false;
        _canViewExcusedMembers = false;
        _canViewMemberStats = false;
        isLoading = false;
      });
    }
  }

  // String olarak gelen tarihi DateTime'a dönüştürme fonksiyonu
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat("dd-MM-yyyy").parse(dateString);
    } catch (e) {
      return DateTime.now(); // Hata durumunda şu anki tarihi döndür
    }
  }

  // Arama sorgusunu güncelleme fonksiyonu - şu an kullanılmıyor
  // void _updateSearchQuery(String query) {
  //   setState(() {
  //     _searchQuery = query;
  //   });
  // }

  // Üyelik durumunu kontrol etme fonksiyonu
  String _getMembershipStatus(QueryDocumentSnapshot member) {
    try {
      DateTime endDate = _parseDate(member['end_date']);
      DateTime now = DateTime.now();
      return endDate.isBefore(now) ? 'Sonlanmış' : 'Devam Ediyor';
    } catch (e) {
      return 'Tarih Hatası';
    }
  }

  // Filtreleme işlemi
  List<QueryDocumentSnapshot> _filterMembers(List<QueryDocumentSnapshot> members) {
    // Önce yetki kontrolü yap
    List<QueryDocumentSnapshot> filteredByPermission = _filterMembersByPermission(members);
    
    // Sonra kullanıcının seçtiği filtreyi uygula
    switch (_filterOption) {
      case 'Üyeliği Biten':
        return filteredByPermission.where((member) => _getMembershipStatus(member) == 'Sonlanmış').toList();
      case 'Devam Eden':
        return filteredByPermission.where((member) => _getMembershipStatus(member) == 'Devam Ediyor').toList();
      case 'İzinli':
        return filteredByPermission.where((member) {
          Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
          return data?.containsKey('excused') == true && data?['excused'] == true;
        }).toList();
      case 'Genel':
      default:
        return filteredByPermission;
    }
  }

  // Yetkilere göre üye filtreleme
  List<QueryDocumentSnapshot> _filterMembersByPermission(List<QueryDocumentSnapshot> members) {
    if (_canViewAllMembers) {
      return members; // Tüm üyeleri görebilir
    }
    
    List<QueryDocumentSnapshot> filteredMembers = [];
    
    for (var member in members) {
      Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
      bool isPending = data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
      bool isExcused = data?.containsKey('excused') == true && data?['excused'] == true;
      String membershipStatus = _getMembershipStatus(member);
      
      // Yetki kontrolü
      if (isPending && _canViewPendingMembers) {
        filteredMembers.add(member);
      } else if (isExcused && _canViewExcusedMembers) {
        filteredMembers.add(member);
      } else if (membershipStatus == 'Devam Ediyor' && _canViewActiveMembers) {
        filteredMembers.add(member);
      } else if (membershipStatus == 'Sonlanmış' && _canViewExpiredMembers) {
        filteredMembers.add(member);
      }
    }
    
    return filteredMembers;
  }

  // WhatsApp mesajı gönderme fonksiyonu
  void _sendWhatsAppMessage(String userId) async {
    try {
      DocumentSnapshot memberDoc = await _firestore.collection('uyelerim').doc(userId).get();
      String phoneNumber = memberDoc['phoneNumber'];
      String name = memberDoc['name'];
      // String endDate = memberDoc['end_date']; // Şu an kullanılmıyor

      // DateTime endDateTime = DateFormat("dd-MM-yyyy").parse(endDate); // Şu an kullanılmıyor
      // String formattedEndDate = DateFormat("d MMMM yyyy", "tr_TR").format(endDateTime); // Şu an kullanılmıyor

      final String message = "Merhabalar \nSporcumuz $name, Yeni Ay Aidat Ödemesi Gelmiştir.\nNot: Ödeme Yapıldığı Zaman Lütfen Dekont Göndermeyi Unutmayınız!\nBANKA \nİBAN : TR98 0001 5001 5800 7313 6581 10\nALICI: Sercan Celil YAŞAR ";

      final String url = "https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}";

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'WhatsApp açılamadı.';
      }
    } catch (e) {
      // print('Hata: $e');
    }
  }

  // Bilgilendirme mesajı göster
  void _showNotificationDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Bilgilendirme Mesajı Gönder"),
          content: Text("Üyeliği biten kişiye WhatsApp üzerinden bilgilendirme mesajı göndermek istiyor musunuz?"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
              },
              child: Text("Vazgeç", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                _sendWhatsAppMessage(userId); // Mesaj gönder
                Navigator.pop(context); // Dialog'u kapat
              },
              child: Text("Gönder", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Grup filtreleme sayfasını aç
  void _openGroupFilterPage() async {
    final selectedGroups = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => GroupFilterPage(
          onFilterApplied: (groups) {
            setState(() {
              _selectedGroups = groups; // Seçilen grupları güncelle
            });
          },
        ),
      ),
    );

    if (selectedGroups != null) {
      setState(() {
        _selectedGroups = selectedGroups;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text(
          'Üyeler',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(_firestore, (query) {}), // Boş fonksiyon
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              if (value == 'group_filter') {
                _openGroupFilterPage();
              } else {
                setState(() {
                  _filterOption = value;
                });
              }
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuItem<String>> items = [
                PopupMenuItem<String>(
                  value: 'Genel',
                  child: Text('Genel'),
                ),
              ];
              
              // Yetkilere göre filtre seçeneklerini ekle
              if (_canViewActiveMembers) {
                items.add(PopupMenuItem<String>(
                  value: 'Devam Eden',
                  child: Text('Devam Eden'),
                ));
              }
              
              if (_canViewExpiredMembers) {
                items.add(PopupMenuItem<String>(
                  value: 'Üyeliği Biten',
                  child: Text('Üyeliği Biten'),
                ));
              }
              
              if (_canViewExcusedMembers) {
                items.add(PopupMenuItem<String>(
                  value: 'İzinli',
                  child: Text('İzinli'),
                ));
              }
              
              items.add(PopupMenuItem<String>(
                value: 'group_filter',
                child: Text('Grupları Filtrele'),
              ));
              
              return items;
            },
          ),
          if (_isAdmin || (_isHelperCoach && _canAddMember)) // Admin veya yetkili helper coach için göster
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: Colors.white),
              onSelected: (value) {
                if (value == 'add_member') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddMemberPage()),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'add_member',
                  child: Text('Üye Ekle'),
                ),
              ],
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah (En koyu nokta)
              Color(0xFF4A0000), // Koyu kırmızımsı siyah
              Color(0xFF9A0202), // Orta kırmızı
              Color(0xFFB00000), // Daha açık kırmızı
              Color(0xFF9A0202), // En açık kırmızı
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0], // Geçiş oranları
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Üye bilgileri yükleniyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lütfen bekleyiniz',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Toplam üye sayısı ve diğer bilgiler (sadece yetkisi olanlar için)
                if (_canViewMemberStats)
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('uyelerim').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var members = snapshot.data!.docs;

                      // Kategorilere göre üye sayılarını hesapla
                      int totalMembers = members.length;
                      int activeMembers = members.where((member) => _getMembershipStatus(member) == 'Devam Ediyor').length;
                      int expiredMembers = members.where((member) => _getMembershipStatus(member) == 'Sonlanmış').length;
                      int pendingMembers = members.where((member) {
                          Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                          return data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
                      }).length;
                      int excusedMembers = members.where((member) {
                          Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                          return data?.containsKey('excused') == true && data?['excused'] == true;
                      }).length;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toplam Üyeler (sadece canViewAllMembers yetkisi varsa göster)
                            if (_canViewAllMembers)
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.blue, // Mavi daire (Toplam için)
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Toplam: $totalMembers",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            if (_canViewAllMembers) SizedBox(height: 5),
                            
                            // Devam Eden Üyeler
                            if (_canViewActiveMembers)
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green, // Yeşil daire
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Devam Eden: $activeMembers",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            if (_canViewActiveMembers) SizedBox(height: 5),
                            
                            // Üyeliği Sonlananlar
                            if (_canViewExpiredMembers)
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.red, // Kırmızı daire
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Üyeliği Sonlanan: $expiredMembers",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            if (_canViewExpiredMembers) SizedBox(height: 5),
                            
                            // Onay Bekleyen Üyeler
                            if (_canViewPendingMembers)
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.orange, // Turuncu daire
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Onay Bekleyen: $pendingMembers",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            if (_canViewPendingMembers) SizedBox(height: 5),
                            
                            // İzinli Üyeler
                            if (_canViewExcusedMembers && excusedMembers > 0)
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.purple, // Mor daire (İzinli için)
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "İzinli: $excusedMembers",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: _canViewAllMembers || _canViewActiveMembers || _canViewExpiredMembers || _canViewPendingMembers || _canViewExcusedMembers
                    ? StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('uyelerim').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 3,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Üye listesi yükleniyor...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Lütfen bekleyiniz',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          var members = snapshot.data!.docs;
                          var filteredMembers = _filterMembers(members); // Filtrelenmiş üyeler

                          // Grup filtreleme uygula
                          if (_selectedGroups.isNotEmpty) {
                            filteredMembers = filteredMembers.where((member) {
                              String group = member['group'] ?? '';
                              return _selectedGroups.contains(group);
                            }).toList();
                          }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Her satırda 3 kart
                          crossAxisSpacing: 5, // Yatay boşluk
                          mainAxisSpacing: 5, // Dikey boşluk
                          childAspectRatio: 0.6, // Kartları kare yap
                        ),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          var member = filteredMembers[index];
                          bool isMembershipEnded = _getMembershipStatus(member) == 'Sonlanmış';

                          return Card(
                            color: (() {
                                Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                                return data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
                            })()
                                ? Colors.orange.withOpacity(0.9) // Onay bekleyenler için turuncu
                                : Colors.white.withOpacity(0.9),
                            shadowColor: Colors.black,
                            margin: EdgeInsets.all(5),
                            child: InkWell(
                              onTap: () {
                                _showMemberDetails(context, member);
                              },
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Profil Resmi (veya baş harf)
                                        CircleAvatar(
                                          backgroundColor: Colors.black,
                                          radius: 30,
                                          child: Text(
                                            member['name'][0],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        // İsim
                                        Text(
                                          member['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: 14, // Yazı boyutunu küçült
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1, // Tek satırda göster
                                          overflow: TextOverflow.ellipsis, // Taşan metni ... ile göster
                                        ),
                                        SizedBox(height: 5),
                                        // Üyelik Durumu
                                        Text(
                                          (() {
                                              Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                                              return data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
                                          })()
                                              ? 'Onay Bekliyor'
                                              : (() {
                                                  Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                                                  return data?.containsKey('excused') == true && data?['excused'] == true;
                                              })()
                                              ? 'İzinli'
                                              : _getMembershipStatus(member),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: (() {
                                                Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                                                return data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
                                            })()
                                                ? Colors.white 
                                               : (() {
                                                   Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                                                   return data?.containsKey('excused') == true && data?['excused'] == true;
                                               })()
                                               ? Colors.purple
                                                : (isMembershipEnded ? Colors.red : Colors.green),
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        // Detaylı Bilgi Butonu
                                        ElevatedButton(
                                          onPressed: () {
                                            _showMemberDetails(context, member);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            minimumSize: Size(80, 30), // Buton boyutunu küçült
                                          ),
                                          child: Text(
                                            'Detaylı Bilgi',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12, // Yazı boyutunu küçült
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Üyeliği bitenler için nokta
                                  if (isMembershipEnded)
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.circle,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          _showNotificationDialog(context, member.id); // UserId'yi geçiriyoruz
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 64,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Üye Görme Yetkiniz Bulunmuyor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Üyeleri görüntülemek için yetki almanız gerekiyor.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                ),
              ],
            ),
      ),
    );
  }

  void _showMemberDetails(BuildContext context, QueryDocumentSnapshot member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDetailsPage(member: member),
      ),
    );
  }
}
class CustomSearchDelegate extends SearchDelegate<String> {
  final FirebaseFirestore _firestore;
  final Function(String) _updateSearchQuery;

  CustomSearchDelegate(this._firestore, this._updateSearchQuery);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.black, // Arka plan rengi
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black, // AppBar rengi
        iconTheme: IconThemeData(color: Colors.white), // İkon rengi
        titleTextStyle: TextStyle(
          color: Colors.white, // Başlık rengi
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70), // Arama metni rengi
        border: InputBorder.none, // Kenarlık kaldırıldı
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.white), // Temizleme ikonu rengi
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white), // Geri ikonu rengi
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF000000), // Siyah (En koyu nokta)
            Color(0xFF4A0000), // Koyu kırmızımsı siyah
            Color(0xFF9A0202), // Orta kırmızı
            Color(0xFFB00000), // Daha açık kırmızı
            Color(0xFF9A0202), // En açık kırmızı
          ],
          stops: [0.0, 0.3, 0.6, 0.8, 1.0], // Geçiş oranları
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('uyelerim').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.white, // Yükleniyor çubuğu rengi
              ),
            );
          }

          var members = snapshot.data!.docs;
          var filteredMembers = members.where((member) {
            String name = member['name'].toString().toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();

          return ListView.builder(
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              var member = filteredMembers[index];
              bool isMembershipEnded = _getMembershipStatus(member) == 'Sonlanmış';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 3,
                color: Colors.white.withOpacity(0.9), // Kart rengi
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Text(
                      member['name'][0],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    member['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black, // Metin rengi
                    ),
                  ),
                  subtitle: Text(
                    (() {
                        Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                        return data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
                    })()
                        ? 'Onay Bekliyor'
                        : (() {
                            Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                            return data?.containsKey('excused') == true && data?['excused'] == true;
                        })()
                        ? 'İzinli'
                        : _getMembershipStatus(member),
                    style: TextStyle(
                      color: (() {
                          Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                          return data?.containsKey('isAccepted') == true && data?['isAccepted'] == false;
                      })()
                          ? Colors.orange
                          : (() {
                              Map<String, dynamic>? data = member.data() as Map<String, dynamic>?;
                              return data?.containsKey('excused') == true && data?['excused'] == true;
                          })()
                          ? Colors.purple
                          : (isMembershipEnded ? Colors.red : Colors.green),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
                  onTap: () {
                    _updateSearchQuery(member['name']);
                    close(context, member['name']);
                    _showMemberDetails(context, member); // Detay sayfasına yönlendir
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Üyelik durumunu kontrol etme fonksiyonu
  String _getMembershipStatus(QueryDocumentSnapshot member) {
    try {
      DateTime endDate = DateFormat("dd-MM-yyyy").parse(member['end_date']);
      DateTime now = DateTime.now();
      return endDate.isBefore(now) ? 'Sonlanmış' : 'Devam Ediyor';
    } catch (e) {
      return 'Tarih Hatası';
    }
  }

  // Detay sayfasına yönlendirme fonksiyonu
  void _showMemberDetails(BuildContext context, QueryDocumentSnapshot member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDetailsPage(member: member),
      ),
    );
  }
}



class GroupFilterPage extends StatefulWidget {
  final Function(List<String>) onFilterApplied;

  const GroupFilterPage({super.key, required this.onFilterApplied});

  @override
  _GroupFilterPageState createState() => _GroupFilterPageState();
}

class _GroupFilterPageState extends State<GroupFilterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _selectedGroups = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text("Grupları Filtrele",style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              widget.onFilterApplied(_selectedGroups); // Seçilen grupları geri gönder
              Navigator.pop(context); // Sayfayı kapat
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000000), // Siyah (En koyu nokta)
              Color(0xFF4A0000), // Koyu kırmızımsı siyah
              Color(0xFF9A0202), // Orta kırmızı
              Color(0xFFB00000), // Daha açık kırmızı
              Color(0xFF9A0202), // En açık kırmızı
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0], // Geçiş oranları
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('group_lessons').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var groups = snapshot.data!.docs;

            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                var group = groups[index];
                String groupName = group['group_name'];

                return CheckboxListTile(
                  title: Text(
                    groupName,
                    style: TextStyle(color: Colors.white), // Metin rengi beyaz
                  ),
                  value: _selectedGroups.contains(groupName),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedGroups.add(groupName);
                      } else {
                        _selectedGroups.remove(groupName);
                      }
                    });
                  },
                  tileColor: Colors.transparent, // Arka plan rengi şeffaf
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.white), // Dış çerçeve beyaz
                    borderRadius: BorderRadius.circular(5), // Köşeleri yuvarlak
                  ),
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // Checkbox köşeleri yuvarlak
                  ),
                  checkColor: Colors.black, // İkon rengi siyah
                  activeColor: Colors.white, // İşaretli durumda arka plan beyaz
                  selected: _selectedGroups.contains(groupName),
                  selectedTileColor: Colors.white.withOpacity(0.1), // Seçili durumda arka plan rengi
                );
              },
            );
          },
        ),
      ),
    );
  }
}