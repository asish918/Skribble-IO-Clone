import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:skribble_clone/final_leaderboard.dart';
import 'package:skribble_clone/home_screen.dart';
import 'package:skribble_clone/models/my_custom_painter.dart';
import 'package:skribble_clone/models/touch_points.dart';
import 'package:skribble_clone/sidebar/player_drawer.dart';
import 'package:skribble_clone/waiting_lobby_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PaintScreen extends StatefulWidget {
  final Map<String, String> data;
  final String screenFrom;
  const PaintScreen({Key? key, required this.data, required this.screenFrom})
      : super(key: key);

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late IO.Socket _socket;
  List<TouchPoints> points = [];
  Map dataOfRoom = {};
  StrokeCap strokeType = StrokeCap.round;
  Color selectedColor = Colors.black;
  double opacity = 1;
  double strokeWidth = 2;
  List<Widget> textBlankWidget = [];
  ScrollController _scrollController = new ScrollController();
  TextEditingController controller = TextEditingController();
  List<Map> messages = [];
  late Timer _timer;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map> scoreboard = [];
  bool isTextInputReadOnly = false;
  int maxPoints = 0;
  String winner = '';
  bool isShowFinalLeaderBoard = false;

  int guessedUserCtr = 0;
  int _start = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connect();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _socket.dispose();
    _timer.cancel();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(oneSec, (Timer time) {
      if (_start == 0) {
        _socket.emit('change-turn', dataOfRoom['name']);
        setState(() {
          _timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void renderTextBlank(String text) {
    textBlankWidget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWidget.add(
        Text(
          '_',
          style: TextStyle(fontSize: 30),
        ),
      );
    }
  }

  void connect() {
    _socket = IO.io('http://10.5.111.148:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();

    if (widget.screenFrom == 'createRoom') {
      _socket.emit('create-game', widget.data);
    } else {
      _socket.emit('join-game', widget.data);
    }

    _socket.onConnect((data) {
      debugPrint("Connected...");
      _socket.on('updateRoom', (roomData) {
        setState(() {
          renderTextBlank(roomData['word']);
          dataOfRoom = roomData;
        });
        if (!roomData['isJoin'] != true) {
          startTimer();
        }
        scoreboard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on('points', (point) {
        if (point['details'] != null) {
          setState(() {
            points.add(
              TouchPoints(
                  points: Offset((point['details']['dx']).toDouble(),
                      (point['details']['dy']).toDouble()),
                  paint: Paint()
                    ..strokeCap = strokeType
                    ..isAntiAlias = true
                    ..color = selectedColor.withOpacity(opacity)
                    ..strokeWidth = strokeWidth),
            );
          });
        }
      });

      _socket.on('show-leaderboard', (roomPlayers) {
        scoreboard.clear();
        for (int i = 0; i < roomPlayers.length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomPlayers[i]['nickname'],
              'points': roomPlayers[i]['points'].toString(),
            });
          });

          if (maxPoints < int.parse(scoreboard[i]['points'])) {
            winner = scoreboard[i]['username'];
            maxPoints = int.parse(scoreboard[i]['points']);
          }
        }

        setState(() {
          _timer.cancel();
          isShowFinalLeaderBoard = true;
        });
      });

      _socket.on('change-turn', (data) {
        String oldWord = dataOfRoom['word'];
        showDialog(
            context: context,
            builder: (context) {
              Future.delayed(Duration(seconds: 3), () {
                setState(() {
                  dataOfRoom = data;
                  renderTextBlank(data['word']);
                  guessedUserCtr = 0;
                  _start = 60;
                  points.clear();
                  isTextInputReadOnly = false;
                });
                Navigator.of(context).pop();
                _timer.cancel();
                startTimer();
              });
              return AlertDialog(
                  title: Center(
                child: Text('Word was $oldWord'),
              ));
            });
      });

      _socket.on('color-change', (colorString) {
        int value = int.parse(colorString, radix: 16);
        Color newColor = Color(value);
        setState(() {
          selectedColor = newColor;
        });
      });

      _socket.on('stroke-width', (value) {
        setState(() {
          strokeWidth = value.toDouble();
        });
      });

      _socket.on('msg', (msgData) {
        setState(() {
          messages.add(msgData);
          guessedUserCtr = msgData['guessedUserCtr'];
        });

        if (guessedUserCtr == dataOfRoom['players'].length - 1) {
          _socket.emit('change-turn', dataOfRoom['name']);
        }

        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 40,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut);
      });

      _socket.on('clean-screen', (data) {
        setState(() {
          points.clear();
        });
      });

      _socket.on('updateScore', (roomData) {
        scoreboard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on('closeInput', (_) {
        _socket.emit('updateScore', widget.data['name']);
        setState(() {
          isTextInputReadOnly = true;
        });
      });

      _socket.on('user-disconnected', (data) {
        scoreboard.clear();
        for (int i = 0; i < data['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': data['players'][i]['nickname'],
              'points': data['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on(
          'notCorrectGame',
          (data) => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    void selectColor() {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Choose Color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        String colorString = color.toString();
                        String valueString =
                            colorString.split('(0x')[1].split(')')[0];
                        Map map = {
                          'color': valueString,
                          'roomName': dataOfRoom
                        };
                        _socket.emit('color-change', map);
                      }),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              ));
    }

    return Scaffold(
      key: scaffoldKey,
      drawer: PlayerDrawer(userData: scoreboard),
      backgroundColor: Colors.white,
      body: dataOfRoom != null
          ? dataOfRoom['isJoin'] != true
              ? !isShowFinalLeaderBoard != true
                  ? Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: width,
                              height: height * 0.55,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  _socket.emit('paint', {
                                    'details': {
                                      'dx': details.localPosition.dx,
                                      'dy': details.localPosition.dy
                                    },
                                    'roomName': widget.data['name'],
                                  });
                                },
                                onPanStart: (details) {
                                  _socket.emit('paint', {
                                    'details': {
                                      'dx': details.localPosition.dx,
                                      'dy': details.localPosition.dy
                                    },
                                    'roomName': widget.data['name'],
                                  });
                                },
                                onPanEnd: (details) {
                                  _socket.emit('paint', {
                                    'details': null,
                                    'roomName': widget.data['name']
                                  });
                                },
                                child: SizedBox.expand(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter:
                                            MyCustomPainter(pointsList: points),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    selectColor();
                                  },
                                  icon: Icon(Icons.color_lens,
                                      color: selectedColor),
                                ),
                                Expanded(
                                  child: Slider(
                                      min: 1.0,
                                      max: 10.0,
                                      label: "Strokewidth $strokeWidth",
                                      activeColor: selectedColor,
                                      value: strokeWidth,
                                      onChanged: (double value) {
                                        Map map = {
                                          'value': value,
                                          'roomName': widget.data
                                        };
                                        _socket.emit('stroke-width', map);
                                      }),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _socket.emit(
                                        'clean-screen', dataOfRoom['name']);
                                  },
                                  icon: Icon(Icons.layers_clear,
                                      color: selectedColor),
                                ),
                              ],
                            ),
                            dataOfRoom['turn']['nickname'] !=
                                    widget.data['nickname']
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: textBlankWidget,
                                  )
                                : Center(
                                    child: Text(
                                      dataOfRoom['word'],
                                      style: TextStyle(fontSize: 30),
                                    ),
                                  ),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  var msg = messages[index].values;
                                  return ListTile(
                                    title: Text(
                                      msg.elementAt(0),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      msg.elementAt(1),
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                        dataOfRoom['turn']['nickname'] !=
                                widget.data['nickname']
                            ? Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  child: TextField(
                                    readOnly: isTextInputReadOnly,
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        Map map = {
                                          'username': widget.data['nickname'],
                                          'msg': value.trim(),
                                          'word': dataOfRoom['word'],
                                          'roomName': widget.data['name'],
                                          'guessedUserCtr': guessedUserCtr,
                                          'totalTime': 60,
                                          'timeTaken': 60 - _start,
                                        };
                                        _socket.emit('msg', map);
                                        controller.clear();
                                      }
                                    },
                                    controller: controller,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      filled: true,
                                      fillColor: Color(0xffF5F5FA),
                                      hintText: 'Your Guess',
                                      hintStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              )
                            : Container(),
                        SafeArea(
                          child: IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: Colors.black,
                            ),
                            onPressed: () =>
                                scaffoldKey.currentState!.openDrawer(),
                          ),
                        )
                      ],
                    )
                  : FinalLeaderboard(
                      scoreboard: scoreboard,
                      winner: winner,
                    )
              : WaitingLobbyScreen(
                  lobbyName: dataOfRoom['name'],
                  noOfPlayers: dataOfRoom['players'].length,
                  occupancy: dataOfRoom['occupancy'],
                )
          : Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 7,
          backgroundColor: Colors.white,
          child: Text(
            '$_start',
            style: TextStyle(color: Colors.black, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
