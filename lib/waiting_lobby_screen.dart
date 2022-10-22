import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WaitingLobbyScreen extends StatefulWidget {
  final int occupancy;
  final int noOfPlayers;
  final String lobbyName;
  final players;
  const WaitingLobbyScreen(
      {Key? key,
      required this.occupancy,
      required this.noOfPlayers,
      required this.lobbyName,
      this.players})
      : super(key: key);

  @override
  State<WaitingLobbyScreen> createState() => _WaitingLobbyScreenState();
}

class _WaitingLobbyScreenState extends State<WaitingLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.03,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Waiting for ${widget.occupancy - widget.noOfPlayers} players to join',
            style: TextStyle(fontSize: 30),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.06,
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            readOnly: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.lobbyName));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Copied!')));
            },
            decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Color(0xffF5F5FA),
                hintText: 'Tap to copy room name!',
                hintStyle:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
        ),
        Text(
          'Players:',
          style: TextStyle(fontSize: 80),
        ),
        ListView.builder(
            primary: true,
            shrinkWrap: true,
            itemCount: widget.noOfPlayers,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Text(
                  '${index + 1}.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(
                  widget.players[index]['nickname'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            })
      ],
    ));
  }
}
