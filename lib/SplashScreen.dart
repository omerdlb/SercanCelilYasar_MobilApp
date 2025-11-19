import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:personaltrainer/login_register_Pages/loginPage.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded( // Ekran alanını daha iyi kullanmasını sağlıyoruz
            child: Center(
              child: Lottie.asset(
                "assets/Lottie/coachsercan.json",
                repeat: true,
                reverse: true,
                width: MediaQuery.of(context).size.width * 0.8, // Animasyon genişliği
                height: MediaQuery.of(context).size.height * 0.4, // Animasyon yüksekliği
                fit: BoxFit.contain, // Animasyonu uygun şekilde sığdır
              ),
            ),
          ),
        ],
      ),
      nextScreen: const LoginPage(),
      backgroundColor: Colors.white,
      splashIconSize: 250,
    );
  }
}