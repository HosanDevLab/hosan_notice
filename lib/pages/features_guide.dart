import 'package:flutter/material.dart';

class FeaturesGuidePage extends StatefulWidget {
  @override
  _FeaturesGuidePageState createState() => _FeaturesGuidePageState();
}

class _FeaturesGuidePageState extends State<FeaturesGuidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('앱 기능 및 사용법'),
      ),
      body: Container(
        height: double.infinity,
        child: SingleChildScrollView(
          physics:
              BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이 앱에는 이런 기능들이 있어요!',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          SizedBox(height: 6),
                          Text(
                            '나중에 메뉴에서 언제든 다시 확인할 수 있어요.',
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .apply(fontSizeDelta: -1),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('설명 건너뛰기'),
                    )
                  ],
                ),
                Divider(height: 28),
                SizedBox(height: 4),
                Text(
                  '1. 바탕화면 시간표 위젯',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '바탕화면에 시간표 위젯을 추가해 빠르게 확인할 수 있습니다!',
                  style: TextStyle(fontSize: 14, height: 1.45),
                ),
                Image.asset('assets/timetable_widget.png'),
                Divider(),
                SizedBox(height: 12),
                Text(
                  '2. 과목별 과제/수행평가 관리',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '과제나 수행평가가 있으면 누구나 등록하세요! '
                  '반 친구들에게도 공유되어 누구나 확인할 수 있고, 잊지 않도록 알림도 보내드려요.',
                  style: TextStyle(fontSize: 14, height: 1.45),
                ),
                SizedBox(height: 18),
                Center(
                    child: Image.asset(
                  'assets/assignments_page.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                )),
                SizedBox(height: 18),
                Divider(),
                SizedBox(height: 12),
                Text(
                  '3. 한눈에 과제 일정 관리',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '복잡한 과제/수행평가 일정, 정리해서 보여드려요! '
                  '과제를 등록하기만 하면 캘린더에 표시됩니다. ',
                  style: TextStyle(fontSize: 14, height: 1.45),
                ),
                SizedBox(height: 18),
                Center(
                    child: Image.asset(
                  'assets/calendar_page.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                )),
                SizedBox(height: 18),
                Divider(),
                SizedBox(height: 12),
                Text(
                  '4. 급식 메뉴 확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '급식표를 찾지 않아도 빠르게 확인할 수 있습니다!',
                  style: TextStyle(fontSize: 14, height: 1.45),
                ),
                SizedBox(height: 18),
                Center(
                    child: Image.asset(
                  'assets/mealinfo_page.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                )),
                Divider(height: 24),
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    child: Text('닫기', style: TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
