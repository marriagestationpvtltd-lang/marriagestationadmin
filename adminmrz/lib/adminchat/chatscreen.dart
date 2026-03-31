import 'package:adminmrz/adminchat/right.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chathome.dart';
import 'chatprovider.dart';
import 'constant.dart';
import 'left.dart';
import 'main.dart';

class ChatScreen extends StatefulWidget {
  // var nama;
  // var onlineok;

  //ChatScreen(this.nama, this.onlineok);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  @override
  void initState() {
    super.initState();

    // Fetch chat list when page loads
    Future.microtask(() =>
        Provider.of<ChatProvider>(context, listen: false).fetchChatList());
  }


  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          ChatSidebar(), // Left Sidebar
          Container(width: 1, color: const Color(0xFFE2E8F0)),
          Expanded(
              child: ChatWindow(name: 'select user to chat', isOnline: true, receiverIdd: 903,)), // Center Chat Window
          Container(width: 1, color: const Color(0xFFE2E8F0)),
          ProfileSidebar(
            selectedTab: selectedTab,
            onTabChange: (index) {
              setState(() {
                selectedTab = index;
              });
            }, id: 903,
          ), // Right Sidebar
        ],
      ),
    );
  }
}