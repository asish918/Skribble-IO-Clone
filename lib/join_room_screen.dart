import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:skribble_clone/widgets/custom_text_field.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({Key? key}) : super(key: key);

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          'Join Room',
          style: TextStyle(color: Colors.black, fontSize: 30),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.08,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: CustomTextField(
            controller: _nameController,
            text: 'Enter your Name',
          ),
        ),
        SizedBox(height: 20),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: CustomTextField(
            controller: _roomNameController,
            text: 'Enter Room Name',
          ),
        ),
        SizedBox(
          height: 40,
        ),
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue),
              minimumSize: MaterialStateProperty.all(
                Size(MediaQuery.of(context).size.width / 2.5, 50),
              ),
              textStyle: MaterialStateProperty.all(
                TextStyle(color: Colors.white),
              )),
          onPressed: () {},
          child: Text(
            'Create',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ]),
    );
  }
}
