import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personaltrainer/AboutCoach/TrainerPermissionsPage.dart';

class TrainerListPage extends StatefulWidget {
  const TrainerListPage({super.key});

  @override
  _TrainerListPageState createState() => _TrainerListPageState();
}

class _TrainerListPageState extends State<TrainerListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showDeleteConfirmationDialog(BuildContext context, String trainerId, String trainerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Antrenörü Sil',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '$trainerName adlı antrenörü silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _deleteTrainer(trainerId, trainerName);
              },
              child: Text(
                'Sil',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTrainer(String trainerId, String trainerName) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Antrenör siliniyor...'),
              ],
            ),
          );
        },
      );

      // Antrenörü sil
      await _firestore.collection('admins').doc(trainerId).delete();

      // Loading dialog'unu kapat
      Navigator.of(context).pop();

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('$trainerName başarıyla silindi!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Loading dialog'unu kapat
      Navigator.of(context).pop();

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Antrenör silinirken hata oluştu: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Antrenör Listesi', style: TextStyle(color: Colors.white)),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('admins').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Henüz antrenör bulunmuyor.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            var trainers = snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['helpercoach'] == true;
            }).toList();

            if (trainers.isEmpty) {
              return Center(
                child: Text(
                  'Henüz antrenör bulunmuyor.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: trainers.length,
              itemBuilder: (context, index) {
                var trainer = trainers[index].data() as Map<String, dynamic>;
                String trainerId = trainers[index].id;
                String name = trainer['name'] ?? 'İsimsiz Antrenör';
                String email = trainer['email'] ?? 'Email Yok';
                bool isActive = trainer['helpercoach'] ?? false;

                return Card(
                  color: Colors.white.withOpacity(0.9),
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(color: Colors.black87),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrainerPermissionsPage(
                                  trainerId: trainerId,
                                  trainerName: name,
                                  currentPermissions: trainer,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, trainerId, name);
                          },
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
} 