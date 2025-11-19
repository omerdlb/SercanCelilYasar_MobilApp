import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class AttendanceAnalysisPage extends StatefulWidget {
  final String memberId;
  final String groupName;

  const AttendanceAnalysisPage({
    super.key,
    required this.memberId,
    required this.groupName,
  });

  @override
  State<AttendanceAnalysisPage> createState() => _AttendanceAnalysisPageState();
}

class _AttendanceAnalysisPageState extends State<AttendanceAnalysisPage> {
  String _selectedFilter = 'Tümü'; // 'Tümü', 'Bu Ay', 'Geçen Ay', 'Özel Tarih'
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedMonth = '';
  String _selectedYear = DateTime.now().year.toString();


  // Tarih filtreleme fonksiyonları
  String _getFilterTitle() {
    switch (_selectedFilter) {
      case 'Bu Ay':
        return 'Bu Ay (${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now())})';
      case 'Geçen Ay':
        final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
        return 'Geçen Ay (${DateFormat('MMMM yyyy', 'tr_TR').format(lastMonth)})';
      case 'Özel Tarih':
        if (_startDate != null && _endDate != null) {
          return '${DateFormat('dd MMMM', 'tr_TR').format(_startDate!)} - ${DateFormat('dd MMMM yyyy', 'tr_TR').format(_endDate!)}';
        }
        return 'Özel Tarih';
      case 'Aylık':
        if (_selectedMonth.isNotEmpty) {
          return '${_selectedMonth} ${_selectedYear}';
        }
        return 'Aylık';
      default:
        return 'Tüm Zamanlar';
    }
  }

  Query _getAttendanceQuery() {
    Query query = FirebaseFirestore.instance
        .collection('group_lessons')
        .doc(widget.groupName)
        .collection('yoklamalar')
        .where('attendance.${widget.memberId}', isNotEqualTo: null);

    switch (_selectedFilter) {
      case 'Bu Ay':
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        query = query
            .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfMonth))
            .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endOfMonth));
        break;
      case 'Geçen Ay':
        final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
        final startOfLastMonth = DateTime(lastMonth.year, lastMonth.month, 1);
        final endOfLastMonth = DateTime(lastMonth.year, lastMonth.month + 1, 0);
        query = query
            .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfLastMonth))
            .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endOfLastMonth));
        break;
      case 'Özel Tarih':
        if (_startDate != null && _endDate != null) {
          query = query
              .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_startDate!))
              .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_endDate!));
        }
        break;
      case 'Aylık':
        if (_selectedMonth.isNotEmpty) {
          final monthNumber = _getMonthNumber(_selectedMonth);
          final startOfMonth = DateTime(int.parse(_selectedYear), monthNumber, 1);
          final endOfMonth = DateTime(int.parse(_selectedYear), monthNumber + 1, 0);
          query = query
              .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfMonth))
              .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endOfMonth));
        }
        break;
    }
    return query;
  }

  int _getMonthNumber(String monthName) {
    final months = {
      'Ocak': 1, 'Şubat': 2, 'Mart': 3, 'Nisan': 4, 'Mayıs': 5, 'Haziran': 6,
      'Temmuz': 7, 'Ağustos': 8, 'Eylül': 9, 'Ekim': 10, 'Kasım': 11, 'Aralık': 12
    };
    return months[monthName] ?? 1;
  }

  // PDF oluşturma fonksiyonu
  Future<void> _generatePdf(BuildContext context, int attended, int missed, int excused, int total, List<PieChartSectionData> sections) async {
    final pdf = pw.Document();

    // Fontu yükleyin
    final fontData = await rootBundle.load('assets/fonts/BebasNeue-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

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
                // Başlık Bölümü
                pw.Container(
                  padding: pw.EdgeInsets.only(bottom: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Katılım Analizi Raporu',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Grup: ${widget.groupName}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          font: ttf,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dönem: ${_getFilterTitle()}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          font: ttf,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Özet Bilgiler
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Özet Bilgiler',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      _buildPdfDetail("Toplam Ders Sayısı", "$total gün", ttf),
                      _buildPdfDetail("Katılım", "$attended gün", ttf, PdfColors.green),
                      _buildPdfDetail("İzinli", "$excused gün", ttf, PdfColors.orange),
                      _buildPdfDetail("Devamsızlık", "$missed gün", ttf, PdfColors.red),
                      _buildPdfDetail("Katılım Oranı", "%${((attended / total) * 100).toStringAsFixed(1)}", ttf, PdfColors.green),
                      _buildPdfDetail("İzinli Oranı", "%${((excused / total) * 100).toStringAsFixed(1)}", ttf, PdfColors.orange),
                      _buildPdfDetail("Devamsızlık Oranı", "%${((missed / total) * 100).toStringAsFixed(1)}", ttf, PdfColors.red),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Katılım Durumu Grafiği
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Katılım Durumu',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        children: [
                          // Katılım Göstergesi
                          pw.Container(
                            width: 120,
                            padding: pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green100,
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(color: PdfColors.green),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'Katılım',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 16,
                                    color: PdfColors.green900,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '%${((attended / total) * 100).toStringAsFixed(1)}',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 24,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // İzinli Göstergesi
                          pw.Container(
                            width: 120,
                            padding: pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.orange100,
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(color: PdfColors.orange),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'İzinli',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 16,
                                    color: PdfColors.orange900,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '%${((excused / total) * 100).toStringAsFixed(1)}',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 24,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.orange900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Devamsızlık Göstergesi
                          pw.Container(
                            width: 120,
                            padding: pw.EdgeInsets.all(12),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red100,
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(color: PdfColors.red),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'Devamsızlık',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 16,
                                    color: PdfColors.red900,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '%${((missed / total) * 100).toStringAsFixed(1)}',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 24,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

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

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Katılım_Analizi_${widget.groupName}_${_getFilterTitle().replaceAll(' ', '_')}_${DateTime.now().toString().split('.')[0]}.pdf',
    );
  }

  pw.Widget _buildPdfDetail(String label, String value, pw.Font ttf, [PdfColor? valueColor]) {
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
              value,
              style: pw.TextStyle(
                fontSize: 14,
                font: ttf,
                color: valueColor ?? PdfColors.black,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filtre seçim dialogu
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Tarih Filtresi Seç',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seçili filtre önizlemesi
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.filter_list, color: Colors.red, size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Seçili Filtre:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getFilterDisplayName(_selectedFilter),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              _buildFilterOption('Tümü', 'Tüm zamanlar', setDialogState),
              _buildFilterOption('Bu Ay', 'Bu ay', setDialogState),
              _buildFilterOption('Geçen Ay', 'Geçen ay', setDialogState),
              _buildFilterOption('Aylık', 'Belirli bir ay', setDialogState),
              _buildFilterOption('Özel Tarih', 'Tarih aralığı', setDialogState),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'Tümü';
                  _startDate = null;
                  _endDate = null;
                  _selectedMonth = '';
                  _selectedYear = DateTime.now().year.toString();
                });
                Navigator.pop(context);
              },
              child: Text('Sıfırla', style: TextStyle(color: Colors.orange)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_selectedFilter == 'Aylık') {
                  _showMonthYearDialog();
                } else if (_selectedFilter == 'Özel Tarih') {
                  _showDateRangeDialog();
                } else {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Uygula', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String value, String title, StateSetter setDialogState) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: Colors.black)),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (String? newValue) {
        setState(() {
          _selectedFilter = newValue!;
        });
        setDialogState(() {}); // Dialog'u anlık güncelle
      },
      activeColor: Colors.red,
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'Tümü':
        return 'Tüm Zamanlar';
      case 'Bu Ay':
        return 'Bu Ay (${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now())})';
      case 'Geçen Ay':
        final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
        return 'Geçen Ay (${DateFormat('MMMM yyyy', 'tr_TR').format(lastMonth)})';
      case 'Aylık':
        if (_selectedMonth.isNotEmpty) {
          return '${_selectedMonth} ${_selectedYear}';
        }
        return 'Belirli Bir Ay';
      case 'Özel Tarih':
        if (_startDate != null && _endDate != null) {
          return '${DateFormat('dd MMMM', 'tr_TR').format(_startDate!)} - ${DateFormat('dd MMMM yyyy', 'tr_TR').format(_endDate!)}';
        }
        return 'Tarih Aralığı';
      default:
        return 'Tüm Zamanlar';
    }
  }

  void _showMonthYearDialog() {
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                   'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final years = List.generate(5, (index) => (DateTime.now().year - 2 + index).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Ay ve Yıl Seç',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ay:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedMonth.isEmpty ? months[DateTime.now().month - 1] : _selectedMonth,
              isExpanded: true,
              items: months.map((month) => DropdownMenuItem(
                value: month,
                child: Text(month, style: TextStyle(color: Colors.black)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedMonth = value!),
            ),
            SizedBox(height: 16),
            Text('Yıl:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedYear,
              isExpanded: true,
              items: years.map((year) => DropdownMenuItem(
                value: year,
                child: Text(year, style: TextStyle(color: Colors.black)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedYear = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Uygula', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Tarih Aralığı Seç',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seçilen tarih aralığı önizlemesi
              if (_startDate != null && _endDate != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.red, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Seçilen Tarih Aralığı:',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMMM yyyy', 'tr_TR').format(_startDate!)} - ${DateFormat('dd MMMM yyyy', 'tr_TR').format(_endDate!)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ListTile(
                title: Text('Başlangıç Tarihi:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  _startDate != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_startDate!) : 'Seçiniz',
                  style: TextStyle(
                    color: _startDate != null ? Colors.red : Colors.grey,
                    fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: _startDate != null ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                    setDialogState(() {}); // Dialog'u güncelle
                  }
                },
              ),
              ListTile(
                title: Text('Bitiş Tarihi:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  _endDate != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_endDate!) : 'Seçiniz',
                  style: TextStyle(
                    color: _endDate != null ? Colors.red : Colors.grey,
                    fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: _endDate != null ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                    setDialogState(() {}); // Dialog'u güncelle
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                Navigator.pop(context);
              },
              child: Text('Temizle', style: TextStyle(color: Colors.orange)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_startDate != null && _endDate != null) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: (_startDate != null && _endDate != null) ? Colors.red : Colors.grey,
              ),
              child: Text('Uygula', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katılım Analizi', style: TextStyle(fontWeight: FontWeight.bold , color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf ,color: Colors.white,),
            onPressed: () async {
              // StreamBuilder verilerinden dinamik verileri alalım
              final snapshot = await _getAttendanceQuery().get();

              final attendanceRecords = snapshot.docs;

              if (attendanceRecords.isEmpty) {
                return; // Eğer veri yoksa işlem yapma
              }

              int total = attendanceRecords.length;
              int attended = attendanceRecords
                  .where((doc) => doc['attendance'][widget.memberId] == true)
                  .length;
              int excused = attendanceRecords
                  .where((doc) => doc['attendance'][widget.memberId] == 'izinli')
                  .length;
              int missed = attendanceRecords
                  .where((doc) => doc['attendance'][widget.memberId] == false)
                  .length;

              // Pasta grafiği için veri
              List<PieChartSectionData> sections = [
                PieChartSectionData(
                  color: Colors.green,
                  value: attended.toDouble(),
                  title: '${((attended / total) * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: excused.toDouble(),
                  title: '${((excused / total) * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: missed.toDouble(),
                  title: '${((missed / total) * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ];

              // PDF oluşturma fonksiyonunu çağırıyoruz
              await _generatePdf(context, attended, missed, excused, total, sections);
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity, // Tüm ekranı kaplasın
        height: double.infinity, // Tüm ekranı kaplasın
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
        child: Column(
          children: [
            // Filtre bilgisi
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtre: ${_getFilterTitle()}',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showFilterDialog,
                    child: Text(
                      'Değiştir',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Ana içerik
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getAttendanceQuery().snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final attendanceRecords = snapshot.data!.docs;
            if (attendanceRecords.isEmpty) {
              return const Center(
                child: Text('Bu kullanıcıya ait katılım verisi bulunamadı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white)),
              );
            }

            int total = attendanceRecords.length;
            int attended = attendanceRecords.where((doc) => doc['attendance'][widget.memberId] == true).length;
            int excused = attendanceRecords.where((doc) => doc['attendance'][widget.memberId] == 'izinli').length;
            int missed = attendanceRecords.where((doc) => doc['attendance'][widget.memberId] == false).length;

            List<PieChartSectionData> sections = [
              PieChartSectionData(
                color: Colors.green,
                value: attended.toDouble(),
                title: '${((attended / total) * 100).toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              PieChartSectionData(
                color: Colors.orange,
                value: excused.toDouble(),
                title: '${((excused / total) * 100).toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              PieChartSectionData(
                color: Colors.red,
                value: missed.toDouble(),
                title: '${((missed / total) * 100).toStringAsFixed(1)}%',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.white.withOpacity(0.9),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                            borderData: FlBorderData(show: false),
                            startDegreeOffset: -90,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 150, // Kartın yüksekliğini artır
                    child: Card(
                      color: Colors.white.withOpacity(0.9),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Katılım:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
                                Text('$attended gün', style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('İzinli:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
                                Text('$excused gün', style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Devamsızlık:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
                                Text('$missed gün', style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }
}
