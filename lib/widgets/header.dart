import 'package:flutter/material.dart';
import 'package:fluttersocial/pages/chat.dart';
import 'package:fluttersocial/pages/profile.dart';

AppBar header(context,
    {bool isAppTitle = false, String titleText, removeBackButton = false, isChatOpen = false, Profile profile, String userId}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? "FlutterShare" : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? "Signatra" : "",
        fontSize: isAppTitle ? 50.0 : 22.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
    actions: !isChatOpen ? null : <Widget>[
      IconButton(
        icon: Icon(
          Icons.chat,
          color: Colors.white,
        ),
        onPressed: () {
          showChatPage(context, profile: profile, userId: userId);
        },
      )
    ],
  );
}

showChatPage(BuildContext context, {Profile profile, String userId}) {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Chat(
        receiverId: profile.profileId,
        receiverAvatar: profile.profileAvatar,
        receiverName: profile.profileName,
        userId: userId,
      ),
    ),
  );
}
