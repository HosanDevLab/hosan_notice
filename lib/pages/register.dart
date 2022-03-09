import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosan_notice/widgets/animated_indexed_stack.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import '../modules/refresh_token.dart';
import '../modules/update_timetable_widget.dart';
import 'home.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scrollController1 = ScrollController();
  final _scrollController2 = ScrollController();
  final remoteConfig = RemoteConfig.instance;
  final user = FirebaseAuth.instance.currentUser!;
  final storage = new LocalStorage('auth.json');

  bool isLoggingIn = false;
  bool isDisposed = false;
  late WebViewController _controller;

  int grade = 0;
  late int classNum;
  late int numberInClass;
  late String name;
  late int _index = 0;

  final _selectedSubjects = [{}, {}];

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  late Future<List<Map<dynamic, dynamic>>> _subjects;

  Future<List<Map<dynamic, dynamic>>> fetchSubjects() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/subjects/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      data.sort((a, b) => a['order'] - b['order']);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchSubjects();
    } else {
      throw Exception('Failed to load post');
    }
  }

  void resetScroll() {
    _scrollController1.jumpTo(_scrollController1.position.maxScrollExtent);
    _scrollController2.jumpTo(_scrollController2.position.maxScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    _subjects = fetchSubjects();
  }

  Widget studentInfoPage(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
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
                      .map((e) =>
                          DropdownMenuItem(child: Text('$e학년'), value: e))
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
                      .map(
                          (e) => DropdownMenuItem(child: Text('$e반'), value: e))
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
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        _index = 1;
                      });
                    }
                  },
                ),
              )),
        ],
      ),
    ));
  }

  Future doRegister(AsyncSnapshot<List<Map<dynamic, dynamic>>> snapshot) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _formKey.currentState!.save();
      });
      final requiredSubjects = (snapshot.data as List)
          .where((e) => e['isRequired'] == true && e['grade'] == grade);

      requiredSubjects.forEach((e) {
        switch (e['termType']) {
          case 1:
            _selectedSubjects[0][e['_id']] = true;
            break;
          case 2:
            _selectedSubjects[1][e['_id']] = true;
            break;
          default:
            _selectedSubjects[0][e['_id']] = true;
            _selectedSubjects[1][e['_id']] = true;
        }
      });

      Future<Map<dynamic, dynamic>> postData() async {
        var rawData = remoteConfig.getAll()['BACKEND_HOST'];
        var cfgs = jsonDecode(rawData!.asString());

        final response = await http.post(
            Uri.parse(
                '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students'),
            body: jsonEncode({
              'name': name,
              'grade': grade,
              'classNum': classNum,
              'numberInClass': numberInClass,
              'subjects': {
                '1st': _selectedSubjects[0]
                    .entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList(),
                '2nd': _selectedSubjects[1]
                    .entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList()
              }
            }),
            headers: {
              'ID-Token': await user.getIdToken(true),
              'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
              'Content-Type': 'application/json'
            });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data;
        } else if (response.statusCode == 401 &&
            jsonDecode(response.body)['code'] == 40100) {
          await refreshToken();
          return await postData();
        } else {
          throw Exception('Failed to load post');
        }
      }

      BuildContext? ctx;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          ctx = context;
          return AlertDialog(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(),
                ),
                Container(
                  margin: EdgeInsets.only(left: 16),
                  child: Text("처리하는 중입니다..."),
                ),
              ],
            ),
          );
        },
      );

      fetchAndUpdateTimetableWidget(
        storage.getItem('AUTH_TOKEN'),
        storage.getItem('REFRESH_TOKEN'),
      );

      await Workmanager().registerPeriodicTask(
        '1',
        'widgetBackgroundUpdate',
        inputData: {
          'authToken': storage.getItem('AUTH_TOKEN') ?? '',
          'refreshToken': storage.getItem('REFRESH_TOKEN') ?? '',
        },
        frequency: Duration(minutes: 15),
      );

      await postData();
      Navigator.pop(ctx!);

      setState(() {
        _index++;
      });
    }
  }

  Widget selectSubjectPage(BuildContext context, {int? term}) {
    return Container(
      height: double.infinity,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              term == null
                  ? Text(
                      '수강 과목을 선택합니다',
                      style: Theme.of(context).textTheme.subtitle1,
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$term학기',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' 수강 과목을 선택합니다'),
                        ],
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ),
              SizedBox(height: 7),
              Text(
                '주의! 올해($grade학년${term == null ? '' : ' $term학기'}) 수강 과목만 선택하세요.\n'
                '나중에 언제든 변경할 수 있어요.',
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .apply(fontSizeDelta: -1),
              ),
              SizedBox(height: 14),
              FutureBuilder(
                  future: _subjects,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<dynamic, dynamic>>> snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();

                    return Column(
                      children: [
                        ListView(
                          physics: NeverScrollableScrollPhysics(),
                          controller: term == 1
                              ? _scrollController1
                              : _scrollController2,
                          itemExtent: 40,
                          shrinkWrap: true,
                          children: (snapshot.data as List)
                              .where((e) =>
                                  e['hidden'] != true &&
                                  e['grade'] == grade &&
                                  [0, term].contains(e['termType']))
                              .map((e) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  switch (term) {
                                    case 1:
                                      _selectedSubjects[0][e['_id']] =
                                          _selectedSubjects[0][e['_id']] == true
                                              ? false
                                              : true;
                                      break;
                                    case 2:
                                      _selectedSubjects[1][e['_id']] =
                                          _selectedSubjects[1][e['_id']] == true
                                              ? false
                                              : true;
                                      break;
                                    default:
                                      _selectedSubjects[0][e['_id']] =
                                          _selectedSubjects[0][e['_id']] == true
                                              ? false
                                              : true;
                                      _selectedSubjects[1][e['_id']] =
                                          _selectedSubjects[1][e['_id']] == true
                                              ? false
                                              : true;
                                  }
                                });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Transform.scale(
                                    scale: 1.05,
                                    child: Checkbox(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      value: e['isRequired'] == true ||
                                          _selectedSubjects[term == null
                                                  ? 0
                                                  : term - 1][e['_id']] ==
                                              true,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSubjects[term == null
                                              ? 0
                                              : term - 1][e['_id']] = value;
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                      (e['isRequired'] ? '[필수] ' : '') +
                                          e['name'],
                                      style:
                                          Theme.of(context).textTheme.subtitle2)
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
                                    label: Text('이전',
                                        style: TextStyle(fontSize: 16)),
                                    onPressed: () {
                                      setState(() {
                                        _index = term == 1 ? 0 : 1;
                                      });

                                      resetScroll();
                                    },
                                  ),
                                )),
                                SizedBox(width: 10),
                                Expanded(
                                    child: Container(
                                  height: 45,
                                  child: term == 1
                                      ? ElevatedButton(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('다음',
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                              SizedBox(width: 5),
                                              Icon(Icons.arrow_forward),
                                            ],
                                          ),
                                          onPressed: () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              _formKey.currentState!.save();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              setState(() {
                                                _index = term == 1 ? 2 : 3;
                                              });

                                              resetScroll();
                                            }
                                          },
                                        )
                                      : ElevatedButton.icon(
                                          icon: Icon(Icons.check),
                                          label: Text('등록하기',
                                              style: TextStyle(fontSize: 16)),
                                          onPressed: () => doRegister(snapshot),
                                        ),
                                )),
                              ],
                            )),
                      ],
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget permissionsAlertPage(BuildContext context) {
    return Container(
      height: double.infinity,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('앱 사용을 위한 권한을 허용해주세요.',
                  style: Theme.of(context).textTheme.subtitle1),
              SizedBox(height: 10),
              Divider(),
              ListTile(
                leading: Icon(Icons.bluetooth),
                title: Text('블루투스'),
                subtitle: Text('자동 출결, 교내 네비게이션'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('위치'),
                subtitle: Text('자동 출결, 교내 네비게이션'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
              ),
              Divider(),
              SizedBox(height: 5),
              Text(
                '[호산고 알리미] 는 앱을 닫거나 직접 사용하지 않는 경우에도 자동 출결, 교내 내비게이션 기능을 사용하기 위해 위치 데이터에 접근합니다. 계속하면 이에 동의하는 것으로 간주합니다.',
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .apply(fontSizeDelta: -1),
              ),
              SizedBox(height: 18),
              SizedBox(
                height: 45,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await [
                      Permission.location,
                      Permission.bluetooth,
                    ].request();
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  },
                  child: Text('계속하기', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      studentInfoPage(context),
      ...(grade == 1
          ? [selectSubjectPage(context)]
          : [
              selectSubjectPage(context, term: 1),
              selectSubjectPage(context, term: 2),
            ]),
      permissionsAlertPage(context)
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == pages.length - 1 ? "앱 권한 허용" : '학생 등록'),
      ),
      body: Form(
        key: _formKey,
        child: Container(
            child: Column(
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / pages.length,
              backgroundColor: Colors.transparent,
              minHeight: 6,
              color: Colors.deepPurple,
            ),
            Container(
              padding: EdgeInsets.only(top: 7, bottom: 7),
              child: Text(
                '${_index + 1} / ${pages.length} 단계',
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            Divider(height: 0),
            Expanded(
              child: AnimatedIndexedStack(
                duration: Duration(milliseconds: 250),
                index: _index,
                children: pages,
              ),
            )
          ],
        )),
      ),
    );
  }
}
