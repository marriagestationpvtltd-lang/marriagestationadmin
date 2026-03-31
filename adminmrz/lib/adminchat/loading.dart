import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'chatprovider.dart';
import 'chatscreen.dart';

class Loading extends StatefulWidget {
  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      provider.fetchChatList();
      provider.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    Provider.of<ChatProvider>(context, listen: false).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen();
  }
}