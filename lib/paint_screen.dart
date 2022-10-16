import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:skribble_clone/models/my_custom_painter.dart';
import 'package:skribble_clone/models/touch_points.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connect();
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
          dataOfRoom = roomData;
        });
        if (!roomData['isJoin'] != true) {}
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

      _socket.on('clean-screen', (data) {
        setState(() {
          points.clear();
        });
      });
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
      backgroundColor: Colors.white,
      body: Stack(
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
                    _socket.emit('paint',
                        {'details': null, 'roomName': widget.data['name']});
                  },
                  child: SizedBox.expand(
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: MyCustomPainter(pointsList: points),
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
                    icon: Icon(Icons.color_lens, color: selectedColor),
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
                      _socket.emit('clean-screen', dataOfRoom['name']);
                    },
                    icon: Icon(Icons.layers_clear, color: selectedColor),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
