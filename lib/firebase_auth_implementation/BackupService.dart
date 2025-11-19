import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart'; // Platform kontrolü için


class BackupService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Tüm koleksiyonları ve alt koleksiyonları rekürsif olarak al
  Future<Map<String, dynamic>> fetchAllCollectionsAndSubcollections() async {
    Map<String, dynamic> allData = {};

    // Ana koleksiyonları al
    var collections = await _getTopLevelCollections();
    for (var collection in collections) {
      allData[collection] = await _fetchCollectionData(collection);
    }

    return allData;
  }

  // Firestore'daki üst düzey koleksiyonları al
  Future<List<String>> _getTopLevelCollections() async {
    return [
      'admins',
      'announcements',
      'beltexam',
      'bireysel_dersler',
      'coach',
      'equipmentOrders',
      'group_lessons',
      'kazanc',
      'qrcode',
      'uyelerim',
    ];
  }

  // Bir koleksiyonun verilerini ve alt koleksiyonlarını al
  Future<Map<String, dynamic>> _fetchCollectionData(String collectionPath) async {
    Map<String, dynamic> collectionData = {};

    // Koleksiyonun belgelerini al
    var snapshot = await firestore.collection(collectionPath).get();
    for (var doc in snapshot.docs) {
      // Belge verilerini JSON'a uygun hale getir
      collectionData[doc.id] = _convertDataToJsonCompatible(doc.data());

      // Alt koleksiyonları kontrol et
      var subcollections = await _getSubcollections(collectionPath, doc.id);
      if (subcollections.isNotEmpty) {
        Map<String, dynamic> subcollectionData = {};
        for (var subcollection in subcollections) {
          subcollectionData[subcollection] =
          await _fetchCollectionData('$collectionPath/${doc.id}/$subcollection');
        }
        collectionData[doc.id]['subcollections'] = subcollectionData;
      }
    }

    return collectionData;
  }

  // Bir belgenin alt koleksiyonlarını al
  Future<List<String>> _getSubcollections(String collectionPath, String docId) async {
    return [
      'comments', // Örnek alt koleksiyon
      'logs', // Örnek alt koleksiyon
    ];
  }

  // Veriyi JSON formatında kaydet
  Future<void> backupData() async {
    var data = await fetchAllCollectionsAndSubcollections();

    // Veriyi JSON formatına dönüştür
    String jsonString = jsonEncode(data);

    // Şu anki tarihi ve saati al
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd_MM_yyyy').format(now); // gg/aa/yyyy formatı
    String formattedTime = DateFormat('HH_mm').format(now); // Saatin formatı: ss_dd

    // Dosya adını oluştur
    String fileName = 'firebase_backup_sercan_${formattedDate}_${formattedTime}.json';

    // Dosyayı kaydetme işlemi
    Directory directory;

    if (kIsWeb) {
      // Web için farklı bir işleme gerek olabilir
      print("Web ortamında yedekleme yapılmıyor.");
      return;
    } else if (Platform.isIOS) {
      // iOS cihazlarda uygulama belgeleri klasörüne kaydet
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      // Android cihazlarda indirilenler klasörüne kaydet
      directory = (await getExternalStorageDirectory())!;
    } else {
      print("Desteklenmeyen platform");
      return;
    }

    if (directory == null) {
      print("Geçici dizine erişilemiyor.");
      return;
    }

    // Dosya yolu ayarlama
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);
    print("Veri başarıyla yedeklendi: ${file.path}");

    // Dosyayı kullanıcıya paylaş
    await _shareFile(file);
  }

// Dosyayı kullanıcıya paylaş
  Future<void> _shareFile(File file) async {
    if (await file.exists()) {
      // Güncel share_plus paketi ile dosya paylaşımı
      await Share.shareXFiles([XFile(file.path)], text: 'Firestore Yedek Dosyası');
    } else {
      print("Dosya bulunamadı: ${file.path}");
    }
  }
  // Veriyi JSON'a uygun hale getir
  Map<String, dynamic> _convertDataToJsonCompatible(Map<String, dynamic> data) {
    Map<String, dynamic> convertedData = {};

    data.forEach((key, value) {
      if (value is Timestamp) {
        // Timestamp türündeki verileri string'e çevir
        convertedData[key] = value.toDate().toString();
      } else if (value is Map<String, dynamic>) {
        // İç içe map'leri rekürsif olarak işle
        convertedData[key] = _convertDataToJsonCompatible(value);
      } else if (value is List) {
        // Listeleri işle
        convertedData[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertDataToJsonCompatible(item);
          } else if (item is Timestamp) {
            return item.toDate().toString();
          } else {
            return item;
          }
        }).toList();
      } else {
        // Diğer türleri olduğu gibi ekle
        convertedData[key] = value;
      }
    });

    return convertedData;
  }
}