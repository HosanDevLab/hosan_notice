import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/pages/assignment.dart';
import 'package:intl/intl.dart';

class NewAssignmentPage extends StatefulWidget {
  final String subjectId;

  NewAssignmentPage({Key? key, required this.subjectId}) : super(key: key);

  @override
  _NewAssignmentPageState createState() => _NewAssignmentPageState();
}

class _NewAssignmentPageState extends State<NewAssignmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  DateTime? deadline;
  String? teacher;
  bool isBeingAdded = false;
  late String title;
  late String description;
  String type = 'assignment';

  late Future<DocumentSnapshot<Map<String, dynamic>>> _subjects;

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchSubjects() async {
    DocumentSnapshot<Map<String, dynamic>> data =
        await firestore.collection('subjects').doc(widget.subjectId).get();
    return data;
  }

  @override
  void initState() {
    _subjects = fetchSubjects();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _subjects,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text('과제 불러오는 중...'),
                ),
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('불러오는 중', textAlign: TextAlign.center),
                      )
                    ])));
          }

          final data = snapshot.data.data();

          return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('새 과제 등록'),
                    Text(data['name'],
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2!
                            .apply(color: Colors.white))
                  ],
                ),
                toolbarHeight: 70,
              ),
              body: RefreshIndicator(
                  child: Container(
                    height: double.infinity,
                    child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            Card(
                                margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: ListTile(
                                  horizontalTitleGap: 2,
                                  leading: Icon(Icons.subject, size: 28),
                                  title: Text(data['name'],
                                      overflow: TextOverflow.ellipsis),
                                  onTap: () {},
                                )),
                            Card(
                                margin: EdgeInsets.fromLTRB(20, 10, 20, 0),
                                child: ListTile(
                                  horizontalTitleGap: 2,
                                  leading: Icon(Icons.person, size: 28),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DropdownButton(
                                        value: teacher,
                                        isExpanded: true,
                                        hint: Text('선생님',
                                            overflow: TextOverflow.ellipsis),
                                        items: [
                                          DropdownMenuItem(
                                              child: Text('선택 안 함',
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              value: 0),
                                          ...(data['teachers'] as List).map(
                                              (e) => DropdownMenuItem(
                                                  child: Text(e,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  value: e))
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            teacher =
                                                value is String ? value : null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {},
                                )),
                            Card(
                                margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: RadioListTile(
                                            title: Text('과제'),
                                            value: 'assignment',
                                            groupValue: type,
                                            onChanged: (value) {
                                              setState(() {
                                                type = value as String;
                                              });
                                            })),
                                    Expanded(
                                        child: RadioListTile(
                                            title: Text('수행평가'),
                                            value: 'assessment',
                                            groupValue: type,
                                            onChanged: (value) {
                                              setState(() {
                                                type = value as String;
                                              });
                                            })),
                                  ],
                                )),
                            Card(
                                margin: EdgeInsets.fromLTRB(20, 10, 20, 0),
                                child: ListTile(
                                  leading: Icon(Icons.timer, size: 28),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(deadline == null
                                          ? '기한 없음'
                                          : DateFormat('yyyy-MM-dd a hh:mm')
                                                  .format(deadline!)
                                                  .replaceAll('AM', '오전')
                                                  .replaceAll('PM', '오후') +
                                              ' 까지'),
                                      deadline == null
                                          ? Text('이곳을 클릭해 기한 설정',
                                              style: TextStyle(fontSize: 12))
                                          : Container()
                                    ],
                                  ),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2050),
                                    );
                                    if (date == null) return;

                                    final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now());
                                    if (time == null) return;

                                    setState(() {
                                      deadline = DateTime(date.year, date.month,
                                          date.day, time.hour, time.minute);
                                    });
                                  },
                                )),
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                  margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
                                  child: Container(
                                      padding:
                                          EdgeInsets.fromLTRB(20, 0, 20, 0),
                                      child: TextFormField(
                                        validator: (value) =>
                                            value == null ? "제목을 입력하세요." : null,
                                        onSaved: (text) {
                                          title = text!;
                                        },
                                        decoration: InputDecoration(
                                            border: UnderlineInputBorder(
                                                borderSide: BorderSide.none),
                                            label: Text('과제 제목')),
                                        keyboardType: TextInputType.text,
                                      ))),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                  margin: EdgeInsets.fromLTRB(20, 12, 20, 8),
                                  child: Container(
                                      padding:
                                          EdgeInsets.fromLTRB(20, 5, 20, 15),
                                      child: TextFormField(
                                        validator: (value) =>
                                            value == null ? "내용을 입력하세요." : null,
                                        onSaved: (text) {
                                          description = text!;
                                        },
                                        decoration: InputDecoration(
                                            label: Text('과제 내용')),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                      ))),
                            ),
                            Divider(indent: 20, endIndent: 20),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.done),
                                label: Text('등록하기'),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();

                                    setState(() {
                                      isBeingAdded = true;
                                    });

                                    final DocumentReference<
                                            Map<String, dynamic>> data =
                                        await firestore
                                            .collection('assignments')
                                            .add({
                                      'title': title,
                                      'description': description,
                                      'subject': firestore
                                          .collection('subjects')
                                          .doc(widget.subjectId),
                                      'createdAt': DateTime.now(),
                                      'teacher': teacher,
                                      'deadline': deadline
                                    });

                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AssignmentPage(
                                                    assignmentId: data.id)));
                                  }
                                },
                              ),
                            )
                          ]),
                        )),
                  ),
                  onRefresh: () async {
                    final fetchFuture = fetchSubjects();
                    setState(() {
                      _subjects = fetchFuture;
                    });
                    await Future.wait([fetchFuture]);
                  }));
        });
  }
}
