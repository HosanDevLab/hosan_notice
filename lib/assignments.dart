import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/drawer.dart';

class AssignmentsPage extends StatefulWidget {
  _AssignmentsPageState createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  @override
  Widget build(BuildContext context) {
    return DoubleBack(
        message: '뒤로가기를 한번 더 누르면 종료합니다.',
        child: Scaffold(
          appBar: AppBar(
            title: Text('과제 및 수행평가'),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            child: ListView(
              physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.all(12),
              children: ['국어', '수학', '영어', '통합과학', '통합사회', '한국사']
                  .map((e) => (Card(
                        child: ListTile(
                          title: Text(e),
                          onTap: () {},
                        ),
                      )))
                  .toList(),
            ),
            onRefresh: () async {},
          ),
          drawer: MainDrawer(parentContext: context),
        ));
  }
}
