import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosan_notice/main.dart';
import 'package:hosan_notice/widgets/animated_indexed_stack.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool isLoggingIn = false;
  bool isDisposed = false;
  late WebViewController _controller;

  int grade = 0;
  late int classNum;
  late int numberInClass;
  late String name;
  late int _index = 0;

  final _selectedSubjects = {};

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _subjects;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchSubjects() async {
    QuerySnapshot<Map<String, dynamic>> data = await firestore
        .collection('subjects')
        .orderBy('order')
        .get();
    final ls = data.docs.toList();
    return ls;
  }

  @override
  void initState() {
    super.initState();
    _subjects = fetchSubjects();
  }

  Widget firstPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('학생 정보를 입력합니다', style: Theme.of(context).textTheme.subtitle1),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: DropdownButtonFormField(
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
                    .map((e) => DropdownMenuItem(child: Text('$e학년'), value: e))
                    .toList(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField(
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
                    .map((e) => DropdownMenuItem(child: Text('$e반'), value: e))
                    .toList(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
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
            )
          ],
        ),
        SizedBox(height: 16),
        TextFormField(
          validator: (text) => text!.isEmpty ? "이름를 입력하세요." : null,
          keyboardType: TextInputType.text,
          onChanged: (text) {},
          onSaved: (text) {
            name = text!;
          },
          decoration: InputDecoration(
              labelText: '이름',
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
            text: TextSpan(style: TextStyle(color: Colors.black), children: [
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
                          onWebViewCreated:
                              (WebViewController webViewController) async {
                            _controller = webViewController;
                            String fileText = await rootBundle
                                .loadString('assets/privacy.html');
                            _controller.loadUrl(Uri.dataFromString(fileText,
                                    mimeType: 'text/html',
                                    encoding: Encoding.getByName('utf-8'))
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
              child: ElevatedButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('다음', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward),
                  ],
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    setState(() {
                      _index = 1;
                    });
                  }
                },
              ),
            )),
      ],
    );
  }

  Widget secondPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('수강 과목을 선택합니다', style: Theme.of(context).textTheme.subtitle1),
        SizedBox(height: 18),
        FutureBuilder(
            future: _subjects,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();

              return Column(
                children: [
                  ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: (snapshot.data as List)
                        .where((e) => e.data()['grade'] == grade)
                        .map((e) {
                      final data = e.data();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSubjects[e.id] =
                                _selectedSubjects[e.id] == true ? false : true;
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Transform.scale(
                              scale: 1.08,
                              child: Checkbox(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                value: data['isRequired'] == true ||
                                    _selectedSubjects[e.id] == true,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSubjects[e.id] = value;
                                  });
                                },
                              ),
                            ),
                            Text(
                                (data['isRequired'] ? '[필수] ' : '') +
                                    data['name'],
                                style: Theme.of(context).textTheme.subtitle1)
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                            height: 45,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.arrow_back),
                              label: Text('이전', style: TextStyle(fontSize: 16)),
                              onPressed: () {
                                setState(() {
                                  _index = 0;
                                });
                              },
                            ),
                          )),
                          SizedBox(width: 10),
                          Expanded(
                              child: Container(
                            height: 45,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.check),
                              label:
                                  Text('등록하기', style: TextStyle(fontSize: 16)),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _formKey.currentState!.save();
                                  });
                                  final requiredSubjectKeys =
                                      (snapshot.data as List)
                                          .where((e) =>
                                              e.data()['isRequired'] == true &&
                                              e.data()['grade'] == grade)
                                          .map((e) => e.id);
                                  requiredSubjectKeys.forEach((e) {
                                    _selectedSubjects[e] = true;
                                  });

                                  firestore
                                      .collection('students')
                                      .doc(user!.uid)
                                      .set({
                                    'name': name,
                                    'grade': grade,
                                    'classNum': classNum,
                                    'numberInClass': numberInClass,
                                    'isPending': false,
                                    'subjects': _selectedSubjects.entries
                                        .map((e) => firestore
                                            .collection('subjects')
                                            .doc(e.key))
                                        .toList()
                                  });
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => HomePage()));
                                }
                              },
                            ),
                          )),
                        ],
                      )),
                ],
              );
            }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('학생 등록'),
        ),
        body: Form(
            key: _formKey,
            child: RefreshIndicator(
              child: Container(
                height: double.infinity,
                child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                        child: AnimatedIndexedStack(
                          duration: Duration(milliseconds: 250),
                          index: _index,
                          children: [firstPage(context), secondPage(context)],
                        ))),
              ),
              onRefresh: () async {
                final fetchFuture = fetchSubjects();
                setState(() {
                  _subjects = fetchFuture;
                });
                await Future.wait([fetchFuture]);
              },
            )));
  }
}
