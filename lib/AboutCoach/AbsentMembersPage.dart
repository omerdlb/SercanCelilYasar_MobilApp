import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class AbsentMembersPage extends StatefulWidget {
  const AbsentMembersPage({super.key});

  @override
  _AbsentMembersPageState createState() => _AbsentMembersPageState();
}

class _AbsentMembersPageState extends State<AbsentMembersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isAdmin = false;
  // bool _isHelperCoach = false; // Şu an kullanılmıyor
  bool _canViewAbsentMembers = false;
  bool isLoading = true;
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];
  
  // Peş peşe devamsızlık ayarları
  int _consecutiveAbsenceLimit = 3; // Varsayılan 3 gün
  List<Map<String, dynamic>> _consecutiveAbsentMembers = [];
  bool _isLoadingConsecutiveAbsences = false;
  
  // Cache mekanizması
  DateTime? _lastDataLoad;
  static const Duration _cacheExpiry = Duration(minutes: 5); // 5 dakika cache

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadGroups();
    _loadConsecutiveAbsentMembers();
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
            _canViewAbsentMembers = true;
          } else {
            // Admin değilse helper coach ve yetkilerini kontrol et
            _canViewAbsentMembers = adminDoc.exists && adminDoc.data() != null
                ? (adminDoc.data() as Map<String, dynamic>)['canViewAbsentMembers'] == true
                : false;
          }
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isAdmin = false;
          _canViewAbsentMembers = false;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        _isAdmin = false;
        _canViewAbsentMembers = false;
        isLoading = false;
      });
    }
  }

  // Grupları yükle
  Future<void> _loadGroups() async {
    try {
      QuerySnapshot groupsSnapshot = await _firestore.collection('group_lessons').get();
      List<Map<String, dynamic>> groupsList = [];
      
      for (var doc in groupsSnapshot.docs) {
        groupsList.add({
          'id': doc.id,
          'name': doc['group_name'] ?? 'İsimsiz Grup',
        });
      }
      
      setState(() {
        _groups = groupsList;
      });
    } catch (e) {
      print('Gruplar yüklenirken hata: $e');
    }
  }

  // Peş peşe devamsızlık yapan kişileri yükle (Optimized)
  Future<void> _loadConsecutiveAbsentMembers({bool forceRefresh = false}) async {
    // Cache kontrolü
    if (!forceRefresh && 
        _lastDataLoad != null && 
        DateTime.now().difference(_lastDataLoad!) < _cacheExpiry &&
        _consecutiveAbsentMembers.isNotEmpty) {
      return; // Cache'den kullan
    }

    setState(() {
      _isLoadingConsecutiveAbsences = true;
    });

    try {
      List<Map<String, dynamic>> consecutiveAbsentList = [];
      
      // Son 30 günün tarih aralığını hesapla
      DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      String startDate = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
      String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Tüm üyeleri getir
      QuerySnapshot membersSnapshot = await _firestore
          .collection('uyelerim')
          .get();
      
      // Paralel olarak tüm üyelerin yoklama verilerini getir
      List<Future<Map<String, dynamic>>> memberFutures = [];
      
      for (var memberDoc in membersSnapshot.docs) {
        String memberId = memberDoc.id;
        String memberName = memberDoc['name'] ?? 'İsimsiz';
        
        // Her üye için yoklama verilerini getir
        Future<Map<String, dynamic>> memberFuture = _getMemberAttendanceData(
          memberId, 
          memberName, 
          startDate, 
          endDate
        );
        memberFutures.add(memberFuture);
      }
      
      // Tüm üyelerin verilerini paralel olarak bekle
      List<Map<String, dynamic>> memberResults = await Future.wait(memberFutures);
      
      // Sonuçları filtrele ve sırala
      for (var result in memberResults) {
        if (result['consecutiveAbsences'] >= _consecutiveAbsenceLimit) {
          consecutiveAbsentList.add(result);
        }
      }
      
      // Peş peşe devamsızlık sayısına göre sırala (en yüksek önce)
      consecutiveAbsentList.sort((a, b) => b['consecutiveAbsences'].compareTo(a['consecutiveAbsences']));
      
      setState(() {
        _consecutiveAbsentMembers = consecutiveAbsentList;
        _isLoadingConsecutiveAbsences = false;
        _lastDataLoad = DateTime.now(); // Cache zamanını güncelle
      });
    } catch (e) {
      print('Peş peşe devamsızlık verileri yüklenirken hata: $e');
      setState(() {
        _isLoadingConsecutiveAbsences = false;
      });
    }
  }

  // Tek bir üyenin yoklama verilerini getir (doğru peş peşe devamsızlık hesaplama)
  Future<Map<String, dynamic>> _getMemberAttendanceData(
    String memberId, 
    String memberName, 
    String startDate, 
    String endDate
  ) async {
    try {
      // Tüm yoklama kayıtlarını getir (katılım, devamsızlık, izinli)
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('uyelerim')
          .doc(memberId)
          .collection('yoklamalar')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .limit(50) // Maksimum 50 kayıt (30 gün için yeterli)
          .get();
      
      // Tüm yoklama kayıtlarını map'e çevir
      Map<String, dynamic> attendanceMap = {};
      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        attendanceMap[data['date']] = data['attendance'];
      }
      
      // Tarih aralığındaki tüm günleri oluştur
      List<String> allDates = [];
      DateTime start = DateTime.parse(startDate);
      DateTime end = DateTime.parse(endDate);
      
      for (DateTime date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
        allDates.add(DateFormat('yyyy-MM-dd').format(date));
      }
      
      // Devamsızlık serisini kontrol et
      int consecutiveAbsences = 0;
      int maxConsecutiveAbsences = 0;
      List<Map<String, dynamic>> absenceDetails = [];
      
      // Tarihleri ters sırada işle (en yeni önce)
      for (String date in allDates.reversed) {
        dynamic attendanceValue = attendanceMap[date];
        
        // Devamsızlık kontrolü:
        // 1. Yoklama kaydı yoksa (null) -> devamsızlık sayılmaz
        // 2. attendance = false veya 'katılmadı' -> devamsızlık
        // 3. attendance = true -> katılım (seri biter)
        // 4. attendance = 'izinli' -> izinli (seri biter)
        bool isAbsent = attendanceValue == false || attendanceValue == 'katılmadı';
        
        if (isAbsent) {
          consecutiveAbsences++;
          absenceDetails.add({
            'date': date,
            'attendance': attendanceValue,
          });
        } else if (attendanceValue == true || attendanceValue == 'izinli') {
          // Katılım veya izinli - devamsızlık serisi biter
          if (consecutiveAbsences > maxConsecutiveAbsences) {
            maxConsecutiveAbsences = consecutiveAbsences;
          }
          consecutiveAbsences = 0;
        }
        // attendanceValue == null ise (yoklama kaydı yok) hiçbir şey yapma
      }
      
      // Son seriyi de kontrol et
      if (consecutiveAbsences > maxConsecutiveAbsences) {
        maxConsecutiveAbsences = consecutiveAbsences;
      }
      
      return {
        'memberId': memberId,
        'memberName': memberName,
        'consecutiveAbsences': maxConsecutiveAbsences,
        'absenceDetails': absenceDetails,
      };
    } catch (e) {
      print('Üye $memberId yoklama verileri alınırken hata: $e');
      return {
        'memberId': memberId,
        'memberName': memberName,
        'consecutiveAbsences': 0,
        'absenceDetails': [],
      };
    }
  }

  // Tarih seçici
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Devamsız Kişiler',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // PDF dışa aktarma butonu
          if (_consecutiveAbsentMembers.isNotEmpty)
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _exportToPDF,
            ),
          // Yenileme butonu
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadConsecutiveAbsentMembers(forceRefresh: true),
          ),
          // Peş peşe devamsızlık limiti ayarlama butonu
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _showConsecutiveAbsenceSettings,
          ),
          // Tarih seçici butonu
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDate,
          ),
          // Grup seçici butonu
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showGroupFilterDialog,
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
                    'Yetki bilgileri yükleniyor...',
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
          : _canViewAbsentMembers
            ? Column(
                children: [
                  // Peş peşe devamsızlık limiti bilgisi
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Peş Peşe Devamsızlık Limiti: $_consecutiveAbsenceLimit gün',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Son 30 gün içinde $_consecutiveAbsenceLimit veya daha fazla peş peşe devamsızlık yapan kişiler listeleniyor.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Peş peşe devamsızlık yapan kişiler listesi
                  Expanded(
                    child: _isLoadingConsecutiveAbsences
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
                                'Peş peşe devamsızlık verileri yükleniyor...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _consecutiveAbsentMembers.isEmpty
                        ? Center(
                            child: Container(
                              margin: EdgeInsets.all(32),
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 50,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'HARIKA!',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Peş peşe devamsızlık yapan kimse yok',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Tüm üyeler düzenli olarak derslere katılıyor',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _consecutiveAbsentMembers.length,
                            itemBuilder: (context, index) {
                              var member = _consecutiveAbsentMembers[index];
                              
                              return Card(
                                color: Colors.white.withOpacity(0.9),
                                margin: EdgeInsets.symmetric(vertical: 8),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      member['memberName'][0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    member['memberName'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      Text(
                                        'Peş peşe devamsızlık: ${member['consecutiveAbsences']} gün',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Son devamsızlık: ${member['absenceDetails'].isNotEmpty ? DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.parse(member['absenceDetails'][0]['date'])) : 'Bilinmiyor'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.black54,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    _showMemberAbsenceDetails(member);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
                      'Devamsızlık Görme Yetkiniz Bulunmuyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Devamsızlık bilgilerini görüntülemek için yetki almanız gerekiyor.',
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
    );
  }

  // Peş peşe devamsızlık limiti ayarlama dialog'u
  void _showConsecutiveAbsenceSettings() {
    TextEditingController limitController = TextEditingController(text: _consecutiveAbsenceLimit.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.black, size: 24),
              SizedBox(width: 8),
              Text(
                'Peş Peşe Devamsızlık Limiti',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kaç gün peş peşe devamsızlık yapan kişiler listelensin?',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Gün Sayısı',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                int? newLimit = int.tryParse(limitController.text);
                if (newLimit != null && newLimit > 0) {
                  setState(() {
                    _consecutiveAbsenceLimit = newLimit;
                  });
                  _loadConsecutiveAbsentMembers(forceRefresh: true);
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Kaydet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Üye devamsızlık detaylarını göster
  void _showMemberAbsenceDetails(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red,
                radius: 16,
                child: Text(
                  member['memberName'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['memberName'],
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Devamsızlık Detayları',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _exportMemberToPDF(member);
                },
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 24,
                ),
                tooltip: 'PDF Oluştur',
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peş peşe devamsızlık: ${member['consecutiveAbsences']} gün',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Devamsızlık Tarihleri:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: member['absenceDetails'].isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Devamsızlık kaydı bulunamadı',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: member['absenceDetails'].length,
                        itemBuilder: (context, index) {
                          var absence = member['absenceDetails'][index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 2),
                            color: Colors.red.withOpacity(0.1),
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.cancel, color: Colors.red, size: 16),
                              title: Text(
                                DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.parse(absence['date'])),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Devamsız',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Kapat',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Font yükleme - Türkçe karakterler için güvenli
  Future<pw.Font> _loadBebasNeueFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('BebasNeue font yüklenemedi, varsayılan font kullanılıyor: $e');
      return pw.Font.helvetica();
    }
  }


  // PDF dışa aktarma fonksiyonu
  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      final ttf = await _loadBebasNeueFont();
      
      // PDF başlığı ve içeriği
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Başlık
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                      pw.Text(
                        'PES PESE DEVAMSIZLIK RAPORU',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          font: ttf,
                        ),
                      ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'TARIH: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()).toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                        font: ttf,
                      ),
                    ),
                    pw.Text(
                      'Limit: $_consecutiveAbsenceLimit gün',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Bilgilendirme metni
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'BU RAPORDA, SON 30 GUN ICINDE $_consecutiveAbsenceLimit VEYA DAHA FAZLA PES PESE DEVAMSIZLIK YAPAN SPORCULAR LISTELENMEKTEDIR.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.black,
                    font: ttf,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Sporcu listesi
              ..._consecutiveAbsentMembers.map((member) {
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 20),
                  padding: pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Sporcu başlığı
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 40,
                            height: 40,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                member['memberName'][0].toUpperCase(),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 15),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'SAYIN SPORUMUZ ${member['memberName'].toString().toUpperCase()}',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                    font: ttf,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'PES PESE ${member['consecutiveAbsences']} GUN DERSLERE KATILMADI',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    color: PdfColors.red,
                                    fontWeight: pw.FontWeight.bold,
                                    font: ttf,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      pw.SizedBox(height: 15),
                      
                      // Devamsızlık tarihleri
                      pw.Text(
                        'KATILMADIGI TARIHLER:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                          font: ttf,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      
                      if (member['absenceDetails'].isNotEmpty)
                        pw.Column(
                          children: member['absenceDetails'].map<pw.Widget>((absence) {
                            return pw.Container(
                              margin: pw.EdgeInsets.only(bottom: 5),
                              padding: pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.red50,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Row(
                                children: [
                                  pw.Text(
                                    '-',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.red,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(width: 8),
                                  pw.Text(
                                    DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.parse(absence['date'])).toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.black,
                                      font: ttf,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        pw.Text(
                          'DEVAMSIZLIK KAYDI BULUNAMADI',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                            font: ttf,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: 30),
              
              // Alt bilgi
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BU RAPOR OTOMATIK OLARAK OLUSTURULMUSTUR.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                        font: ttf,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'OLUSTURULMA TARIHI: ${DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(DateTime.now()).toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                        font: ttf,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );
      
      // PDF'i yazdır ve paylaş
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Peş_Peşe_Devamsızlık_Raporu_${DateFormat('yyyy-MM-dd', 'tr_TR').format(DateTime.now())}.pdf',
      );
      
    } catch (e) {
      print('PDF oluşturulurken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulurken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Tek sporcu için PDF oluşturma fonksiyonu
  Future<void> _exportMemberToPDF(Map<String, dynamic> member) async {
    try {
      final pdf = pw.Document();
      final ttf = await _loadBebasNeueFont();
      
      // PDF başlığı ve içeriği
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık kutusu
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'SPORCU DEVAMSIZLIK RAPORU',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        font: ttf,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'TARIH: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()).toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                        font: ttf,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Sporcu bilgileri
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Sporcu avatar ve ismi
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 60,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              member['memberName'][0].toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                font: ttf,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'SAYIN SPORUMUZ ${member['memberName'].toString().toUpperCase()}',
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                  font: ttf,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'PES PESE ${member['consecutiveAbsences']} GUN DERSLERE KATILMADI',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  color: PdfColors.red,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    
                    // Devamsızlık tarihleri
                    pw.Text(
                      'KATILMADIGI TARIHLER:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                        font: ttf,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    
                    if (member['absenceDetails'].isNotEmpty)
                      pw.Column(
                        children: member['absenceDetails'].map<pw.Widget>((absence) {
                          return pw.Container(
                            margin: pw.EdgeInsets.only(bottom: 8),
                            padding: pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red50,
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(color: PdfColors.red100),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Text(
                                  '-',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    color: PdfColors.red,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(width: 10),
                                pw.Text(
                                  DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.parse(absence['date'])).toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    color: PdfColors.black,
                                    fontWeight: pw.FontWeight.normal,
                                    font: ttf,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      pw.Container(
                        padding: pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          'DEVAMSIZLIK KAYDI BULUNAMADI',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                            font: ttf,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Alt bilgi
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'BU RAPOR OTOMATIK OLARAK OLUSTURULMUSTUR.\nOLUSTURULMA TARIHI: ${DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(DateTime.now()).toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                    font: ttf,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ];
          },
        ),
      );
      
      // PDF'i yazdır ve paylaş
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Sporcu_Devamsızlık_Raporu_${member['memberName'].replaceAll(' ', '_')}_${DateFormat('yyyy-MM-dd', 'tr_TR').format(DateTime.now())}.pdf',
      );
      
    } catch (e) {
      print('Sporcu PDF oluşturulurken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF oluşturulurken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Grup filtreleme dialog'unu göster
  void _showGroupFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.black, size: 24),
              SizedBox(width: 8),
              Text(
                'Grup Filtresi',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hangi grubun devamsızlıklarını görmek istiyorsunuz?',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Tüm Gruplar seçeneği
                  Card(
                    color: _selectedGroupId == null ? Colors.black.withOpacity(0.1) : Colors.white,
                    child: ListTile(
                      leading: Radio<String?>(
                        value: null,
                        groupValue: _selectedGroupId,
                        activeColor: Colors.black,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedGroupId = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      title: Text(
                        'Tüm Gruplar',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: _selectedGroupId == null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Tüm grupların devamsızlıklarını göster',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: _selectedGroupId == null 
                        ? Icon(Icons.check_circle, color: Colors.black, size: 20)
                        : null,
                    ),
                  ),
                  // Grup seçenekleri
                  ..._groups.map((group) {
                    bool isSelected = _selectedGroupId == group['id'];
                    return Card(
                      color: isSelected ? Colors.black.withOpacity(0.1) : Colors.white,
                      child: ListTile(
                        leading: Radio<String?>(
                          value: group['id'],
                          groupValue: _selectedGroupId,
                          activeColor: Colors.black,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedGroupId = value;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        title: Text(
                          group['name'],
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'Bu grubun devamsızlıklarını göster',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check_circle, color: Colors.black, size: 20)
                          : null,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}
