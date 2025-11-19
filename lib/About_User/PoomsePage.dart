import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PoomsePage extends StatelessWidget {
  // Poomselerin adları ve YouTube linkleri
  final List<Map<String, String>> poomses = [
    {
      'name': 'Taegeuk Beyaz Kuşak',
      'videoUrl': 'https://www.youtube.com/watch?v=DyNu1iy2GUo&t=62s',
    },
    {
      'name': 'Taegeuk Il Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=vB6QGqFc4Qg',
    },
    {
      'name': 'Taegeuk Ee Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=f3uPbfEPvjg',
    },
    {
      'name': 'Taegeuk Sam Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=gLRwo0wI03g',
    },
    {
      'name': 'Taegeuk Sa Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=h7WOK9sASks',
    },
    {
      'name': 'Taegeuk O Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=y_Y4lMcLpec',
    },
    {
      'name': 'Taegeuk Yuk Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=FkV_Hi2RmF8',
    },
    {
      'name': 'Taegeuk Chil Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=MBANTqA7SOw',
    },
    {
      'name': 'Taegeuk Pal Jang',
      'videoUrl': 'https://www.youtube.com/watch?v=RDfRC28eaa0',
    },
    {
      'name': 'Koryo',
      'videoUrl': 'https://www.youtube.com/watch?v=pd5VGGLDQ2I',
    },
    {
      'name': 'Keumgang',
      'videoUrl': 'https://www.youtube.com/watch?v=61cBiU7xD6o',
    },
    {
      'name': 'Taeback',
      'videoUrl': 'https://www.youtube.com/watch?v=mDrV8LeS5kE',
    },
    {
      'name': 'Pyongwon',
      'videoUrl': 'https://www.youtube.com/watch?v=VUBc7BHhXBo',
    },
    {
      'name': 'Pyongwon',
      'videoUrl': 'https://www.youtube.com/watch?v=VUBc7BHhXBo',
    },
    {
      'name': 'Shipjin',
      'videoUrl': 'https://www.youtube.com/watch?v=95ryemrqmWs',
    },
    {
      'name': 'Jitae',
      'videoUrl': 'https://www.youtube.com/watch?v=ttmy1O-IgQQ',
    },
  ];

   PoomsePage({super.key});

  // YouTube linkini açacak fonksiyon
  void _launchYouTube(String url, BuildContext context) async {
    try {
      final Uri url0 = Uri.parse(url);  // URL'yi Uri'ye çevir
      if (await canLaunchUrl(url0)) {   // canLaunchUrl yerine launchUrl kullanılır
        await launchUrl(url0);          // launchUrl fonksiyonunu kullanıyoruz
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link açılamadı: $url'),
          backgroundColor: Colors.red,
        ),
      );
      print('Hata: $e'); // Hata detayını konsola yazdır
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Taekwondo Poomseleri',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.black,
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
        child: ListView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: poomses.length,
          itemBuilder: (context, index) {
            final poomse = poomses[index];
            return Card(
              elevation: 4.0,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16.0),
                title: Text(
                  poomse['name']!,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(Icons.play_circle_fill, color: Colors.redAccent),
                onTap: () => _launchYouTube(poomse['videoUrl']!, context),
              ),
            );
          },
        ),
      ),
    );
  }
}