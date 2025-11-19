import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class CoachSeeOrders extends StatefulWidget {
  const CoachSeeOrders({super.key});

  @override
  _CoachSeeOrdersState createState() => _CoachSeeOrdersState();
}

class _CoachSeeOrdersState extends State<CoachSeeOrders> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Siparişler", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("equipmentOrders")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "Henüz sipariş bulunmamaktadır.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            }

            var orders = snapshot.data!.docs;

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var order = orders[index];
                var username = order["username"] ?? "Bilinmeyen Kullanıcı";
                var orderDate = order["orderDate"] ?? "Tarih Yok";
                var isApproved = order["isApproved"] ?? false;
                var totalPrice = order["totalPrice"] ?? 0.0;
                var items = order["items"] as List<dynamic>? ?? [];

                return Card(
                  color: Colors.white.withOpacity(0.9),
                  margin: EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// 📌 **Sipariş Başlığı ve Kullanıcı Bilgisi**
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Sipariş Sahibi:\n$username",
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.picture_as_pdf,
                                      color: Colors.black),
                                  onPressed: () => _exportOrderToPDF(order),
                                ),
                                PopupMenuButton<String>(
                                  iconColor: Colors.black,
                                  onSelected: (value) {
                                    if (value == "Sil") {
                                      _showDeleteDialog(context, order.id);
                                    }
                                  },
                                  itemBuilder: (context) =>
                                  [
                                    PopupMenuItem(
                                      value: "Sil",
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 10),
                                          Text("Sil", style: TextStyle(
                                              color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 5),
                        Text("Sipariş Tarihi: $orderDate", style: TextStyle(
                            fontSize: 14, color: Colors.black54)),

                        Divider(color: Colors.grey),

                        /// 📌 **Ürün Listesi**
                        ...items.map((item) {
                          var title = item["title"] ?? "Bilinmeyen Ürün";
                          var size = item.containsKey("size")
                              ? "Beden: ${item["size"]}"
                              : "";
                          var quantity = item.containsKey("quantity")
                              ? "Adet: ${item["quantity"]}"
                              : "";
                          var price = item["price"] ?? 0.0;

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              "• $title $size $quantity - ${price
                                  .toStringAsFixed(2)}TL",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black),
                            ),
                          );
                        }).toList(),

                        SizedBox(height: 10),
                        Text(
                          "Toplam Fiyat: ${totalPrice.toStringAsFixed(2)}₺",
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),

                        SizedBox(height: 10),

                        /// 📌 **Onay Durumu**
                        if (isApproved)
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              "Talep Onaylandı ✅",
                              style: TextStyle(fontSize: 18,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            onPressed: () => _approveOrder(order.id),
                            child: Text(
                              "Onayla",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _approveOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection("equipmentOrders").doc(
          orderId).update({
        "isApproved": true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Talep onaylandı ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String orderId) async {
    return showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("Siparişi Sil"),
            content: Text("Bu siparişi silmek istediğinize emin misiniz?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal", style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("equipmentOrders")
                      .doc(orderId)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Sipariş silindi 🗑️"),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: Text("Sil", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _exportOrderToPDF(DocumentSnapshot order) async {
    try {
      // Fontu yükle
      final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      // PDF oluştur
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Başlık
                  pw.Container(
                    padding: pw.EdgeInsets.only(bottom: 20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      "Sipariş Detayları",
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Sipariş Bilgileri
                  pw.Container(
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfDetail("Sipariş Sahibi", order["username"], ttf),
                        _buildPdfDetail("Sipariş Tarihi", order["orderDate"], ttf),
                        _buildPdfDetail("Toplam Tutar", "${order["totalPrice"].toStringAsFixed(2)}TL", ttf),
                        _buildPdfDetail("Onay Durumu", order["isApproved"] ? "Onaylandı ✅" : "Beklemede ⏳", ttf),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Ürün Listesi Başlığı
                  pw.Container(
                    padding: pw.EdgeInsets.only(bottom: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      "Sipariş Edilen Ürünler",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                        color: PdfColors.black,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Ürün Listesi
                  ...(order["items"] as List<dynamic>).map((item) {
                    String title = item["title"] ?? "Bilinmeyen Ürün";
                    String size = item.containsKey("size") ? "Beden: ${item["size"]}" : "";
                    String quantity = item.containsKey("quantity") ? "Adet: ${item["quantity"]}" : "";
                    double price = item["price"] ?? 0.0;

                    return pw.Container(
                      margin: pw.EdgeInsets.only(bottom: 8),
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  title,
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (size.isNotEmpty || quantity.isNotEmpty)
                                  pw.Text(
                                    "$size $quantity",
                                    style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 12,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          pw.Text(
                            "${price.toStringAsFixed(2)}TL",
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Alt Bilgi
                  pw.SizedBox(height: 30),
                  pw.Container(
                    padding: pw.EdgeInsets.only(top: 20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Oluşturulma Tarihi: ${DateTime.now().toString().split('.')[0]}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                            font: ttf,
                          ),
                        ),
                        pw.Text(
                          'Coach Sercan Celil YAŞAR',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                            font: ttf,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // PDF'i doğrudan yazdırma seçeneği sun
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Sipariş_${order["username"]}_${DateTime.now().toString().split('.')[0]}.pdf',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF oluşturulurken bir hata oluştu: $e")),
      );
    }
  }

  pw.Widget _buildPdfDetail(String label, dynamic value, pw.Font ttf) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 150,
            child: pw.Text(
              "$label:",
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                font: ttf,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.toString(),
              style: pw.TextStyle(
                fontSize: 14,
                font: ttf,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}