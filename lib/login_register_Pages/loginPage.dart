import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personaltrainer/AboutCoach/CoachHomePage.dart';
import 'package:personaltrainer/About_User/User_Interface.dart';
import 'package:personaltrainer/AboutCoach/SecondCoachScreen.dart';
import 'package:personaltrainer/login_register_Pages/forgot_password_page.dart';
import 'package:personaltrainer/login_register_Pages/register_page.dart';
import 'package:personaltrainer/qrcode/qr_code.dart';


class LoginPage extends StatefulWidget {
  final bool checkEmailVerification;
  final String? pendingEmail;

  const LoginPage({
    Key? key,
    this.checkEmailVerification = false,
    this.pendingEmail,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (widget.pendingEmail != null) {
      _emailOrUsernameController.text = widget.pendingEmail!;
    }
    if (widget.checkEmailVerification) {
      _checkEmailVerification();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => checkUserLogin());
  }

  void checkUserLogin() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      navigateUser(user.email!);
    }
  }

  Future<void> _checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Email doğrulama durumunu kontrol et
        await user.reload(); // Kullanıcı bilgilerini yenile
        user = _auth.currentUser; // Güncel kullanıcı bilgisini al

        if (user?.emailVerified == true) {
          // Email doğrulanmış, Firestore'u güncelle
          await _firestore.collection('uyelerim').doc(user!.uid).update({
            'emailVerified': true,
          });
          
          // Kullanıcıyı yönlendir
          if (mounted) {
            navigateUser(user.email!);
          }
        } else {
          // Email doğrulanmamış, kullanıcıyı bilgilendir
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lütfen email adresinizi doğrulayın.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Email doğrulama kontrolü hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email doğrulama kontrolü sırasında bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> navigateUser(String email) async {
    try {
      // Önce admins koleksiyonunda kullanıcıyı ara
      var adminQuerySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

      if (adminQuerySnapshot.docs.isNotEmpty && mounted) {
        // Admin kullanıcısı bulundu
        var adminData = adminQuerySnapshot.docs.first.data();
        bool isAdmin = adminData['admin'] ?? false;
        bool isHelperCoach = adminData['helpercoach'] ?? false;

        if (isAdmin) {
          // Admin ise CoachHomePage'e yönlendir
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const CoachHomePage()));
        } else if (isHelperCoach) {
          // Helper coach ise Secondcoachscreen'e yönlendir
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Secondcoachscreen()));
        }
        return;
      }

      // Eğer admins koleksiyonunda bulunamazsa, uyelerim koleksiyonunda ara
      var userQuerySnapshot = await _firestore
          .collection('uyelerim')
          .where('email', isEqualTo: email)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty && mounted) {
        // Normal kullanıcı bulundu
        var userData = userQuerySnapshot.docs.first.data();

        // isAccepted kontrolü
        if (userData.containsKey('isAccepted')) {
          // Yeni sistem kullanıcısı (isAccepted alanı var)
          bool isAccepted = userData['isAccepted'] ?? false;
          if (!isAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hesabınız henüz onaylanmamış. Lütfen antrenörünüzle iletişime geçin.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // Email doğrulama kontrolü
        if (widget.checkEmailVerification) {
          User? user = _auth.currentUser;
          if (user != null && !user.emailVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lütfen email adresinizi doğrulayın.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
            return;
          }
        }

        // Kullanıcıyı UserInterface'e yönlendir
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const UserInterface()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı bulunamadı!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Kullanıcı yönlendirme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı yönlendirme sırasında bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF9A0202), Color(0xFFC80101)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeText(),
              const SizedBox(height: 40),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 30),
              _buildLoginButton(),
              const SizedBox(height: 20),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Center(
      child: Column(
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 200,
                height: 200,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hoşgeldin!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hesabınıza Giriş Yapınız',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      cursorColor: Colors.white,
      controller: _emailOrUsernameController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Email veya Kullanıcı Adı',
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        prefixIcon: Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  Widget _buildPasswordField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          cursorColor: Colors.white,
          controller: _passwordController,
          obscureText: _obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Şifre',
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            prefixIcon: const Icon(Icons.lock, color: Colors.white),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
        onPressed: _login,
        child: const Text('Giriş Yap', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            child: const Text('Üyelik Oluştur'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
              );
            },
            child: const Text('Şifremi Unuttum'),
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {

      // Özel kontrol: Kullanıcı adı ve şifre "1" ise QR kod sayfasına git
      if (_emailOrUsernameController.text.trim() == 'qrcode' &&
          _passwordController.text.trim() == 'qrcode') {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const QrCodeGenerator())
        );
        return;
      }

    if (_emailOrUsernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen kullanıcı adı/email ve şifrenizi girin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String input = _emailOrUsernameController.text.trim();
      String password = _passwordController.text;

      // Önce admins koleksiyonunda ara
      QuerySnapshot adminQuerySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: input)
          .get();

      if (adminQuerySnapshot.docs.isEmpty) {
        // Email ile bulunamazsa, kullanıcı adı ile ara
        adminQuerySnapshot = await _firestore
            .collection('admins')
            .where('name', isEqualTo: input)
            .get();
      }

      if (adminQuerySnapshot.docs.isNotEmpty) {
        // Admin kullanıcısı bulundu
        var adminData = adminQuerySnapshot.docs.first.data() as Map<String, dynamic>;
        String email = adminData['email'];
        bool isAdmin = adminData['admin'] ?? false;
        bool isHelperCoach = adminData['helpercoach'] ?? false;

        // Firebase Authentication ile giriş yap
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          if (isAdmin) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const CoachHomePage()));
          } else if (isHelperCoach) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const Secondcoachscreen()));
          }
        }
        return;
      }

      // Admin bulunamazsa, normal kullanıcıları ara
      QuerySnapshot userQuerySnapshot = await _firestore
          .collection('uyelerim')
          .where('email', isEqualTo: input)
          .get();

      if (userQuerySnapshot.docs.isEmpty) {
        // Email ile bulunamazsa, kullanıcı adı ile ara
        userQuerySnapshot = await _firestore
            .collection('uyelerim')
            .where('name', isEqualTo: input)
            .get();
      }

      if (userQuerySnapshot.docs.isNotEmpty) {
        // Normal kullanıcı bulundu
        var userData = userQuerySnapshot.docs.first.data() as Map<String, dynamic>;
        String email = userData['email'];

        // isAccepted kontrolü
        if (userData.containsKey('isAccepted')) {
          bool isAccepted = userData['isAccepted'] ?? false;
          if (!isAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hesabınız henüz onaylanmamış. Lütfen antrenörünüzle iletişime geçin.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // Firebase Authentication ile giriş yap
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;
        if (user != null) {
          // Email doğrulama kontrolü
          if (widget.checkEmailVerification && !user.emailVerified) {
            await _checkEmailVerification();
            return;
          }

          // Normal kullanıcı girişi
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const UserInterface()));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı bulunamadı!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu kullanıcı adı/email ile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          errorMessage = 'Hatalı şifre.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email adresi.';
          break;
        case 'user-disabled':
          errorMessage = 'Bu hesap devre dışı bırakılmış.';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
          break;
        default:
          errorMessage = 'Giriş yapılırken bir hata oluştu: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beklenmeyen bir hata oluştu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardıma mı ihtiyacın var?'),
        content: const Text('Giriş yapabilmek için antrenörünüzden şifre ve email adresi talep etmelisiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}