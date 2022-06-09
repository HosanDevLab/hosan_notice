import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hosan_notice/pages/myclass.dart';

class ClassesPage extends StatefulWidget {
  final BuildContext context;
  final List<Map> classes;

  ClassesPage(this.context, {Key? key, required this.classes})
      : super(key: key);

  @override
  _ClassesPageState createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  @override
  Widget build(BuildContext context) {
    widget.classes.sort((a, b) => a['classNum'] - b['classNum']);

    final firstGrades = widget.classes.where((e) => e['grade'] == 1);
    final secondGrades = widget.classes.where((e) => e['grade'] == 2);
    final thirdGrades = widget.classes.where((e) => e['grade'] == 3);

    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0),
      appBar: AppBar(
        title: Text('다른 학반으로 이동'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 1,
      ),
      body: Container(
        height: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 8),
          duration: Duration(milliseconds: 300),
          builder: (_, value, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: value, sigmaY: value),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                color: Colors.black.withOpacity(value * 0.04375),
                child: ListView(
                  physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.8,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '1학년',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...firstGrades.map(
                      (o) {
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '1학년 ${o['classNum']}반',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(child: Container()),
                                Text(
                                  '${o['teacher']['name']}T 담임',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                widget.context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MyClassPage(classId: o['_id']),
                                ),
                              );
                            },
                            dense: true,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.8,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '2학년',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...secondGrades.map(
                      (o) {
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '2학년 ${o['classNum']}반',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(child: Container()),
                                Text(
                                  '${o['teacher']['name']} 담임',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                widget.context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MyClassPage(classId: o['_id']),
                                ),
                              );
                            },
                            dense: true,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.8,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '3학년',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...thirdGrades.map(
                      (o) {
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '3학년 ${o['classNum']}반',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(child: Container()),
                                Text(
                                  '${o['teacher']['name']} 담임',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                widget.context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MyClassPage(classId: o['_id']),
                                ),
                              );
                            },
                            dense: true,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
