import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerPermissionsPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final Map<String, dynamic> currentPermissions;

  const TrainerPermissionsPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    required this.currentPermissions,
  });

  @override
  _TrainerPermissionsPageState createState() => _TrainerPermissionsPageState();
}

class _TrainerPermissionsPageState extends State<TrainerPermissionsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, bool> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = {
      'canEditLicense': widget.currentPermissions['canEditLicense'] ?? false,
      'canAddMember': widget.currentPermissions['canAddMember'] ?? false,
      'canDeleteMember': widget.currentPermissions['canDeleteMember'] ?? false,
      'canAddMeasurement': widget.currentPermissions['canAddMeasurement'] ?? false,
      'canUpdateMembership': widget.currentPermissions['canUpdateMembership'] ?? false,
      'canCreateAnnouncement': widget.currentPermissions['canCreateAnnouncement'] ?? false,
      'canEditBeltExam': widget.currentPermissions['canEditBeltExam'] ?? false,
      'canCreateLesson': widget.currentPermissions['canCreateLesson'] ?? false,
      'canDeleteLesson': widget.currentPermissions['canDeleteLesson'] ?? false,
      'canViewLessonMembers': widget.currentPermissions['canViewLessonMembers'] ?? false,
      'canRemoveLessonMembers': widget.currentPermissions['canRemoveLessonMembers'] ?? false,
      'canEditLesson': widget.currentPermissions['canEditLesson'] ?? false,
      // Üye görme yetkileri
      'canViewAllMembers': widget.currentPermissions['canViewAllMembers'] ?? false,
      'canViewActiveMembers': widget.currentPermissions['canViewActiveMembers'] ?? false,
      'canViewExpiredMembers': widget.currentPermissions['canViewExpiredMembers'] ?? false,
      'canViewPendingMembers': widget.currentPermissions['canViewPendingMembers'] ?? false,
      'canViewExcusedMembers': widget.currentPermissions['canViewExcusedMembers'] ?? false,
      'canViewMemberStats': widget.currentPermissions['canViewMemberStats'] ?? false,
    };
  }

  Future<void> _savePermissions() async {
    try {
      await _firestore.collection('admins').doc(widget.trainerId).update({
        ..._permissions,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetkiler başarıyla güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetkiler güncellenirken bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPermissionSwitch(String title, String key) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        value: _permissions[key] ?? false,
        onChanged: (bool value) {
          setState(() {
            _permissions[key] = value;
          });
        },
        activeColor: Colors.green,
        activeTrackColor: Colors.green.withOpacity(0.4),
        inactiveThumbColor: Colors.red,
        inactiveTrackColor: Colors.red.withOpacity(0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.trainerName} - Yetkiler',
          style: TextStyle(color: Colors.white),
        ),
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Genel Yetkiler
                  _buildSectionHeader('Genel Yetkiler'),
                  _buildPermissionSwitch('Lisans Düzenleme', 'canEditLicense'),
                  _buildPermissionSwitch('Üye Ekleme', 'canAddMember'),
                  _buildPermissionSwitch('Üye Silme', 'canDeleteMember'),
                  _buildPermissionSwitch('Ölçüm Ekleme', 'canAddMeasurement'),
                  _buildPermissionSwitch('Üyelik Bilgilerini Güncelleme', 'canUpdateMembership'),
                  _buildPermissionSwitch('Duyuru Oluşturma', 'canCreateAnnouncement'),
                  _buildPermissionSwitch('Kuşak Sınavı Düzenleme', 'canEditBeltExam'),
                  
                  // Ders Yetkileri
                  _buildSectionHeader('Ders Yetkileri'),
                  _buildPermissionSwitch('Ders Oluşturma', 'canCreateLesson'),
                  _buildPermissionSwitch('Ders Silme', 'canDeleteLesson'),
                  _buildPermissionSwitch('Ders Üyelerini Görme', 'canViewLessonMembers'),
                  _buildPermissionSwitch('Ders Üyelerini Kaldırma', 'canRemoveLessonMembers'),
                  _buildPermissionSwitch('Dersi Düzenleme', 'canEditLesson'),
                  
                  // Üye Görme Yetkileri
                  _buildSectionHeader('Üye Görme Yetkileri'),
                  _buildPermissionSwitch('Tüm Üyeleri Görme', 'canViewAllMembers'),
                  _buildPermissionSwitch('Aktif Üyeleri Görme', 'canViewActiveMembers'),
                  _buildPermissionSwitch('Süresi Bitmiş Üyeleri Görme', 'canViewExpiredMembers'),
                  _buildPermissionSwitch('Bekleyen Üyeleri Görme', 'canViewPendingMembers'),
                  _buildPermissionSwitch('İzinli Üyeleri Görme', 'canViewExcusedMembers'),
                  _buildPermissionSwitch('Üye İstatistiklerini Görme', 'canViewMemberStats'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _savePermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Yetkileri Kaydet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 