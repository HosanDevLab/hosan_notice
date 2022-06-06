import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/pages/edit_assignment.dart';
import 'package:hosan_notice/pages/home.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';

class AssignmentPage extends StatefulWidget {
  final String assignmentId;

  AssignmentPage({Key? key, required this.assignmentId}) : super(key: key);

  @override
  _AssignmentPageState createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');
  final _commentTextFieldController = TextEditingController();

  late Offset _commentOffset;

  bool? assignmentLoadDone;

  late Future<List<Map>> _assignment_comments, _teachers;
  late Future<Map> _me, _assignment;

  Future<Map<dynamic, dynamic>> fetchStudentsMe() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students/me'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchStudentsMe();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> fetchAssignment() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchAssignment();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<Map>> fetchAssignmentComments() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}/comments'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchAssignmentComments();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> deleteAssignment() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.delete(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await deleteAssignment();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> deleteComment(String commentId) async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.delete(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}/comments/${commentId}'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await deleteComment(commentId);
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> patchComment(String commentId,
      {required String content}) async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.patch(
      Uri.parse(
          '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}/comments/${commentId}'),
      headers: {
        'ID-Token': await user.getIdToken(true),
        'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await deleteComment(commentId);
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> postHeart() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.post(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}/heart'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await postHeart();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> deleteHeart() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.delete(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}/heart'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await deleteHeart();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map> postAssignmentComment(String text) async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.post(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments/${widget.assignmentId}/comments'),
        body: json.encode({'content': text}),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await postAssignmentComment(text);
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<Map<dynamic, dynamic>>> fetchTeachers() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/teachers/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchTeachers();
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  void initState() {
    _assignment = fetchAssignment();
    _assignment_comments = fetchAssignmentComments();
    _me = fetchStudentsMe();
    _teachers = fetchTeachers();
    super.initState();
  }

  Widget commentCard(BuildContext context, Map student, Map comment) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (comment['author']?['_id'] == student['_id']) {
              showMenu(
                useRootNavigator: true,
                context: context,
                position: RelativeRect.fromLTRB(
                  _commentOffset.dx,
                  _commentOffset.dy,
                  0,
                  0,
                ),
                items: [
                  PopupMenuItem(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 22,
                        ),
                        Text(
                          ' 삭제',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(Duration(seconds: 0), () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('이 댓글을 삭제할까요?'),
                                  SizedBox(height: 12),
                                  Text(
                                    '다시 되돌릴 수 없어요!',
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: Text('계속하기'),
                                  style: TextButton.styleFrom(
                                    primary: Colors.pink,
                                  ),
                                  onPressed: () async {
                                    await deleteComment(comment['_id']);

                                    Navigator.pop(context);

                                    final fetchFuture =
                                        fetchAssignmentComments();

                                    setState(() {
                                      _assignment_comments = fetchFuture;
                                    });
                                    await fetchFuture;
                                  },
                                ),
                                TextButton(
                                  child: Text('취소'),
                                  style: TextButton.styleFrom(
                                    primary: Colors.black54,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ],
                            );
                          },
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 22,
                        ),
                        Text(
                          ' 수정',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                    onTap: () {
                      final _editFieldController = TextEditingController(
                        text: comment['content'],
                      );

                      bool isPatching = false;

                      Future.delayed(Duration(seconds: 0), () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('댓글 수정하기'),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _editFieldController,
                                    autofocus: true,
                                  )
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: Text('완료'),
                                  onPressed: () async {
                                    if (isPatching) {
                                      return;
                                    }

                                    isPatching = true;

                                    await patchComment(
                                      comment['_id'],
                                      content: _editFieldController.text,
                                    );

                                    Navigator.pop(context);

                                    final fetchFuture =
                                        fetchAssignmentComments();

                                    setState(() {
                                      _assignment_comments = fetchFuture;
                                    });
                                    await fetchFuture;
                                  },
                                ),
                                TextButton(
                                  child: Text('취소'),
                                  style: TextButton.styleFrom(
                                    primary: Colors.black54,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ],
                            );
                          },
                        );
                      });
                    },
                  )
                ],
              );
            }
          },
          onTapDown: (details) {
            _commentOffset = details.globalPosition;
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL!),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${comment['author']?['name']}  '),
                          TextSpan(
                            text: '1분 전',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ]),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      SelectableText(comment['content'])
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: FutureBuilder(
        future:
            Future.wait([_me, _assignment, _assignment_comments, _teachers]),
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
                  ],
                ),
              ),
            );
          }

          final student = snapshot.data[0];
          final assignment = snapshot.data[1];
          final List<Map> comments = snapshot.data[2];
          final List<Map> teachers = snapshot.data[3];

          Duration? timeDiff;
          String? timeDiffStr;
          if (assignment['createdAt'] != null) {
            timeDiff = DateTime.parse(assignment['createdAt'])
                .difference(DateTime.now());
            if (timeDiff.inSeconds <= 0) {
              final timeDiffNegative = DateTime.now()
                  .difference(DateTime.parse(assignment['createdAt']));
              if (timeDiffNegative.inDays > 0)
                timeDiffStr = '${timeDiffNegative.inDays}일 전 등록함';
              else if (timeDiffNegative.inHours > 0)
                timeDiffStr = '${timeDiffNegative.inHours}시간 전 등록함';
              else if (timeDiffNegative.inMinutes > 0)
                timeDiffStr = '${timeDiffNegative.inMinutes}분 전 등록함';
              else
                timeDiffStr = '${timeDiffNegative.inSeconds}초 전 등록함';
            } else {
              timeDiffStr = '방금';
            }
          }

          final liked = (assignment['hearts'] as List)
              .map((e) => e['_id'])
              .contains(student['_id']);

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment['title']),
                  Text(
                    assignment['deadline'] != null
                        ? '기한: ${DateTime.parse(assignment['deadline']).toLocal().toString().split('.')[0]} 까지'
                        : '기한 없음',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .apply(color: Colors.white),
                  )
                ],
              ),
              toolbarHeight: 70,
              backgroundColor: (assignment['deadline'] == null ||
                      DateTime.parse(assignment['deadline'])
                              .difference(DateTime.now())
                              .inSeconds >=
                          0)
                  ? Colors.deepPurple
                  : Colors.pink,
            ),
            body: RefreshIndicator(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 5,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '제목: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: assignment['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Divider(height: 0),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Tooltip(
                              message: '과목: ${assignment['subject']?['name']}',
                              child: Card(
                                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: ListTile(
                                  horizontalTitleGap: 2,
                                  leading: Icon(Icons.subject, size: 28),
                                  title: Text(
                                    assignment['subject']?['name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  onTap: () {},
                                ),
                              ),
                            ),
                          ),
                          (assignment['teacher'] != null
                              ? Expanded(
                                  flex: 3,
                                  child: Card(
                                    margin: EdgeInsets.fromLTRB(6, 10, 0, 0),
                                    child: ListTile(
                                      horizontalTitleGap: 2,
                                      leading: Icon(Icons.person, size: 28),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            teachers.firstWhere(
                                                  (t) =>
                                                      t['_id'] ==
                                                      assignment['teacher'],
                                                  orElse: () => {},
                                                )['name'] ??
                                                '(알 수 없음)',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '선생님',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      onTap: () {},
                                    ),
                                  ),
                                )
                              : SizedBox(width: 0))
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(width: 5),
                          Text(
                            '과제/수행평가 내용',
                            style: Theme.of(context).textTheme.subtitle2!.apply(
                                color: Colors.grey[700], fontSizeDelta: -1),
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      SizedBox(height: 5),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 100,
                        ),
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.only(top: 10, bottom: 5),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 10),
                            child: SelectableText(
                                (assignment['description'] as String).isNotEmpty
                                    ? assignment['description']
                                        .replaceAll(r'\n', '\n')
                                    : '(내용 없음)',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          SizedBox(width: 5),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.caption,
                                children: [
                                  TextSpan(
                                    text: assignment['author']?['name'] ??
                                        '(알 수 없는 사용자)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(
                                    text: '님이 ${timeDiffStr}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          Tooltip(
                            message: liked ? '좋아요! 취소하기' : '좋아요! 달기',
                            child: TextButton.icon(
                              onPressed: () async {
                                final fetchFuture =
                                    liked ? deleteHeart() : postHeart();

                                setState(() {
                                  _assignment = fetchFuture;
                                });
                                await fetchFuture;
                              },
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                size: 22,
                              ),
                              label: Text(
                                ((assignment['hearts']?.length ?? 0))
                                    .toString(),
                              ),
                              style: TextButton.styleFrom(
                                primary: Colors.pink[500],
                                textStyle: TextStyle(fontSize: 12),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                          ...assignment['author']?['_id'] == student['_id']
                              ? [
                                  Tooltip(
                                    message: '이 게시글 수정하기',
                                    child: TextButton.icon(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 20,
                                      ),
                                      label: Text('수정'),
                                      style: TextButton.styleFrom(
                                        textStyle: TextStyle(fontSize: 12),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 5,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                EditAssignmentPage(assignment),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: '이 게시글 삭제하기',
                                    child: TextButton.icon(
                                      icon: Icon(
                                        Icons.close,
                                        size: 22,
                                      ),
                                      label: Text('삭제'),
                                      style: TextButton.styleFrom(
                                        primary: Colors.red[700],
                                        textStyle: TextStyle(fontSize: 12),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 5),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('이 게시글을 삭제할까요?'),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    '다시 되돌릴 수 없어요!',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption,
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text('계속하기'),
                                                  style: TextButton.styleFrom(
                                                    primary: Colors.pink,
                                                  ),
                                                  onPressed: () async {
                                                    await deleteAssignment();

                                                    Navigator.pop(context);
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            HomePage(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('취소'),
                                                  style: TextButton.styleFrom(
                                                    primary: Colors.black54,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  )
                                ]
                              : [],
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          SizedBox(width: 5),
                          Text(
                            '이 과제/수행평가의 댓글',
                            style: Theme.of(context).textTheme.subtitle2!.apply(
                                color: Colors.grey[700], fontSizeDelta: -1),
                          ),
                          SizedBox(width: 10),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.only(top: 5),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(user.photoURL!),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _commentTextFieldController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  labelText: '댓글 추가하기',
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                ),
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            SizedBox(width: 10),
                            Container(
                              padding: EdgeInsets.only(top: 5),
                              child: IconButton(
                                icon: Icon(Icons.send),
                                splashRadius: 24,
                                splashColor: Colors.deepPurple[100],
                                color: Colors.deepPurple[700],
                                padding: EdgeInsets.all(5),
                                constraints: BoxConstraints(),
                                onPressed: () async {
                                  if (_commentTextFieldController
                                      .text.isEmpty) {
                                    return;
                                  }

                                  FocusManager.instance.primaryFocus?.unfocus();

                                  final text = _commentTextFieldController.text;
                                  _commentTextFieldController.clear();

                                  await postAssignmentComment(text);

                                  final fetchAssignmentCommentsFuture =
                                      fetchAssignmentComments();
                                  setState(() {
                                    _assignment_comments =
                                        fetchAssignmentCommentsFuture;
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Divider(height: 0),
                      Container(
                        child: Column(
                          children: [
                            ...comments.map((e) {
                              return commentCard(context, student, e);
                            }),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              onRefresh: () async {
                final fetchStudentsMeFuture = fetchStudentsMe();
                final fetchAssignmentFuture = fetchAssignment();
                final fetchAssignmentCommentsFuture = fetchAssignmentComments();

                setState(() {
                  _me = fetchStudentsMeFuture;
                  _assignment = fetchAssignmentFuture;
                  _assignment_comments = fetchAssignmentCommentsFuture;
                });
                await Future.wait([
                  fetchStudentsMeFuture,
                  fetchAssignmentFuture,
                  fetchAssignmentCommentsFuture
                ]);
              },
            ),
          );
        },
      ),
    );
  }
}
