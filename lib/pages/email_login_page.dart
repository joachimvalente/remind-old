import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:Remind/themes/themes.dart';
import 'package:Remind/util/regex.dart';

class EmailLoginPage extends StatefulWidget {
  @override
  EmailLoginPageState createState() => EmailLoginPageState();
}

class EmailLoginPageState extends State<EmailLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _loggingIn = false;
  String _emailError;
  String _passwordError;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          leading: _loggingIn
              ? Container()
              : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Remind.',
                      style: Theme.of(context)
                          .textTheme
                          .display2
                          .copyWith(color: Colors.white)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Log in or sign up.',
                      style: Theme.of(context)
                          .textTheme
                          .subhead
                          .copyWith(color: Colors.white)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      errorText: _emailError,
                      errorMaxLines: 4,
                    ),
                    onFieldSubmitted: (value) {
                      _emailFocusNode.unfocus();
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    autofocus: true,
                    enabled: !_loggingIn,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      errorText: _passwordError,
                      errorMaxLines: 4,
                    ),
                    onFieldSubmitted: (_) {
                      _passwordFocusNode.unfocus();
                      _login(createUser: false);
                    },
                    enabled: !_loggingIn,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: _loggingIn
                      ? CircularProgressIndicator()
                      : ButtonBar(
                          children: [
                            FlatButton(
                              onPressed: () {
                                _login(createUser: true);
                              },
                              child: Text('Sign up'),
                            ),
                            RaisedButton(
                              onPressed: () {
                                _login(createUser: false);
                              },
                              child: Text('Log in'),
                              color: Theme.of(context).accentColor,
                            ),
                          ],
                        ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: InkWell(
                      child: Text('Forgot password?',
                          style:
                              TextStyle(decoration: TextDecoration.underline)),
                      onTap: _sendPasswordResetEmail,
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendPasswordResetEmail() async {
    setState(() {
      _loggingIn = true;
      _emailError = null;
      _passwordError = null;
    });

    // First check easy things locally.
    final email = _emailController.text;
    if (email.isEmpty) {
      _emailError = 'Enter an email';
      setState(() {
        _loggingIn = false;
      });
      return;
    }
    if (emailRegex.stringMatch(email) != email) {
      _emailError = 'Invalid email';
      setState(() {
        _loggingIn = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on PlatformException catch (e) {
      // iOS uses details, android uses message
      String error = e.details ?? e.message;
      _emailError = error;
      setState(() {
        _loggingIn = false;
      });
      return;
    }

    Fluttertoast.showToast(msg: 'Send passord reset email to $email');
    setState(() {
      _loggingIn = false;
    });
  }

  void _login({@required bool createUser}) async {
    setState(() {
      _loggingIn = true;
      _emailError = null;
      _passwordError = null;
    });

    // First check easy things locally.
    final email = _emailController.text;
    final password = _passwordController.text;
    if (email.isEmpty) {
      _emailError = 'Enter an email';
      setState(() {
        _loggingIn = false;
      });
      return;
    }
    if (emailRegex.stringMatch(email) != email) {
      _emailError = 'Invalid email';
      setState(() {
        _loggingIn = false;
      });
      return;
    }
    if (password.length < 6) {
      _passwordError = 'Enter at least 6 characters';
      setState(() {
        _loggingIn = false;
      });
      return;
    }

    final method = createUser
        ? FirebaseAuth.instance.createUserWithEmailAndPassword
        : FirebaseAuth.instance.signInWithEmailAndPassword;
    try {
      await method(
        email: email,
        password: password,
      );
    } on PlatformException catch (e) {
      // iOS uses details, android uses message
      String error = e.details ?? e.message;
      // Very hacky way to know if the message is about the password.
      if (error.toLowerCase().contains('password')) {
        _passwordError = error;
      } else {
        _emailError = error;
      }
      setState(() {
        _loggingIn = false;
      });
    }
  }
}
