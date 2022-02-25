import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hosan_notice/pages/myclass.dart';

class ClassesPage extends StatefulWidget {
  final BuildContext context;

  ClassesPage({Key? key, required this.context}) : super(key: key);

  @override
  _ClassesPageState createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0),
      appBar: AppBar(
        title: Text('전체 학반'),
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
                    ...List.generate(
                      8,
                      (i) {
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '1학년 ${i + 1}반',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(child: Container()),
                                Text(
                                  '국어 OOO 담임',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                widget.context,
                                MaterialPageRoute(
                                  builder: (context) => MyClassPage(),
                                ),
                              );
                            },
                            dense: true,
                          ),
                        );
                      },
                      growable: true,
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
                    ...List.generate(
                      9,
                      (i) {
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '2학년 ${i + 1}반',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Expanded(child: Container()),
                                Text(
                                  '국어 OOO 담임',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ],
                            ),
                            onTap: () {},
                            dense: true,
                          ),
                        );
                      },
                      growable: true,
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
