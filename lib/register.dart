import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosan_notice/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool isLoggingIn = false;
  bool isDisposed = false;
  late WebViewController _controller;

  late int grade;
  late int classNum;
  late int numberInClass;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('학생 등록'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
              child: Container(
            padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('학생 정보를 입력합니다',
                    style: Theme.of(context).textTheme.subtitle1),
                SizedBox(height: 18),
                DropdownButtonFormField(
                  validator: (value) => value == null ? "학년을 선택하세요." : null,
                  decoration: InputDecoration(
                      hintText: '학년',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
                  onChanged: (value) {},
                  onSaved: (value) {
                    grade = value as int;
                  },
                  items: List.generate(3, (index) => index + 1)
                      .map((e) =>
                          DropdownMenuItem(child: Text('$e학년'), value: e))
                      .toList(),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField(
                  validator: (value) => value == null ? "반을 선택하세요." : null,
                  decoration: InputDecoration(
                      hintText: '반',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
                  onChanged: (value) {},
                  onSaved: (value) {
                    classNum = value as int;
                  },
                  items: List.generate(10, (index) => index + 1)
                      .map(
                          (e) => DropdownMenuItem(child: Text('$e반'), value: e))
                      .toList(),
                ),
                SizedBox(height: 16),
                TextFormField(
                  validator: (text) => text!.isEmpty ? "번호를 입력하세요." : null,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  onChanged: (text) {},
                  onSaved: (text) {
                    numberInClass = int.parse(text!);
                  },
                  decoration: InputDecoration(
                      labelText: '번호',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 18, horizontal: 12)),
                ),
                SizedBox(height: 16),
                RichText(
                    text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: [
                      TextSpan(text: '등록하면 '),
                      TextSpan(
                        text: '<호산고 알리미> 개인정보 처리방침',
                        style: TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('개인정보 처리방침'),
                                    content: WebView(
                                      initialUrl: 'about:blank',
                                      onWebViewCreated: (WebViewController
                                          webViewController) async {
                                        _controller = webViewController;
                                        String fileText = await rootBundle
                                            .loadString('assets/privacy.html');
                                        _controller.loadUrl(Uri.dataFromString(
                                                fileText,
                                                mimeType: 'text/html',
                                                encoding:
                                                    Encoding.getByName('utf-8'))
                                            .toString());
                                      },
                                    ),
                                  );
                                });
                          },
                      ),
                      TextSpan(text: '에 동의하는 것으로 간주됩니다.')
                    ])),
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _formKey.currentState!.save();
                            });
                            firestore
                                .collection('students')
                                .doc(user!.uid)
                                .set({
                              'grade': grade,
                              'classNum': classNum,
                              'numberInClass': numberInClass,
                              'isPending': false,
                            });
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()));
                          }
                        },
                        label: Text('등록하기', style: TextStyle(fontSize: 16)),
                      ),
                    )),
              ],
            ),
          )),
        ));
  }
}
