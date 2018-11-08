import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:Remind/main.dart';
import 'package:Remind/pages/email_login_page.dart';

typedef LoginCallback = void Function();

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() {
    return new LoginPageState();
  }
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _facebookLogin = FacebookLogin();

  AnimationController animationController;
  Animation<double> curveAnimation;
  Animation<double> paddingAnimation;
  Animation<double> fadeInAnimation;

  @override
  void initState() {
    super.initState();

    _cancelAllNotifications();

    animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    curveAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.decelerate,
    );
    paddingAnimation = Tween(begin: 0.0, end: 128.0).animate(curveAnimation)
      ..addListener(() {
        setState(() {});
      });
    fadeInAnimation = Tween(begin: 0.0, end: 1.0).animate(curveAnimation)
      ..addListener(() {
        setState(() {});
      });
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: paddingAnimation.value),
              child: Text(
                'Remind.',
                style: Theme.of(context).accentTextTheme.display3.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            Opacity(
              child: Container(
                width: 250.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _loginButton(() {
                      _loginWithEmail(context);
                    }, 'Sign in with email', Icon(MdiIcons.email, size: 24.0),
                        Colors.white, Color.fromRGBO(204, 0, 31, 1.0)),
                    _loginButton(
                        _loginWithFacebook,
                        'Sign in with Facebook',
                        Icon(
                          MdiIcons.facebookBox,
                          size: 24.0,
                        ),
                        Colors.white,
                        Color.fromRGBO(59, 89, 152, 1.0)),
                    _loginButton(
                        _loginWithGoogle,
                        'Sign in with Google',
                        Image.asset(
                          'assets/google_logo.png',
                          height: 24.0,
                        ),
                        Colors.grey[800],
                        Colors.white),
                  ],
                ),
              ),
              opacity: fadeInAnimation.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButton(LoginCallback loginCallback, String label, Widget icon,
      Color color, Color backgroundColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: RaisedButton(
        onPressed: loginCallback,
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: icon,
              ),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        color: backgroundColor,
        textColor: color,
      ),
    );
  }

  void _loginWithGoogle() async {
    final googleAccount = await _googleSignIn.signIn();
    final googleAuth = await googleAccount.authentication;
    try {
      await _auth.signInWithGoogle(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: e.message, toastLength: Toast.LENGTH_LONG);
    }
  }

  void _loginWithFacebook() async {
    var result = await _facebookLogin.logInWithReadPermissions(['email']);
    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        try {
          await _auth.signInWithFacebook(accessToken: result.accessToken.token);
        } on PlatformException catch (e) {
          Fluttertoast.showToast(
              msg: e.message, toastLength: Toast.LENGTH_LONG);
        }
        break;
      case FacebookLoginStatus.cancelledByUser:
        break;
      case FacebookLoginStatus.error:
        Fluttertoast.showToast(msg: 'Error: ${result.errorMessage}');
        break;
    }
  }

  void _loginWithEmail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return EmailLoginPage();
      }),
    );
  }

  void _cancelAllNotifications() async {
    await RemindApp.notifications.cancelAll();
  }
}
