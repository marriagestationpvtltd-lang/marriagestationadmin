import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'chatprovider.dart';
import 'chatscreen.dart';

class Loading extends StatefulWidget {
  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    Future.microtask(() {
      _chatProvider.fetchChatList();
      _chatProvider.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _chatProvider.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen();
  }
}