import 'dart:io';

import 'package:fluttersocial/pages/home.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttersocial/widgets/progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

/// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.high,
);

class Chat extends StatelessWidget
{
  final String receiverId;
  final String receiverAvatar;
  final String receiverName;
  final String userId;

  Chat({
    Key key,
    @required this.receiverId,
    @required this.receiverAvatar,
    @required this.receiverName,
    @required this.userId,
  });

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).accentColor,
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage: CachedNetworkImageProvider(receiverAvatar),
                ),
            ),
          ],
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          centerTitle: true,
          title: Text(
            receiverName,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ChatScreen(receiverId: receiverId, receiverAvatar: receiverAvatar, receiverName: receiverName, userId: userId),
      );
  }
}

class ChatScreen extends StatefulWidget {

  final String receiverId;
  final String receiverAvatar;
  final String receiverName;
  final String userId;

  ChatScreen({
    Key key,
    @required this.receiverId,
    @required this.receiverAvatar,
    @required this.receiverName,
    @required this.userId,
  }): super(key: key);


  @override
  State createState() => _ChatScreenState(receiverId: receiverId, receiverAvatar: receiverAvatar, receiverName: receiverName, userId: userId);
}

class _ChatScreenState extends State<ChatScreen> {

  final String receiverId;
  final String receiverAvatar;
  final String receiverName;
  final String userId;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  _ChatScreenState({
    Key key,
    @required this.receiverId,
    @required this.receiverAvatar,
    @required this.receiverName,
    @required this.userId,
  });

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  bool isDisplaySticker;
  bool isLoading;

  File imageFile;
  String imageUrl;

  String chatId;
  var listMessage;

  @override
  void initState() {
    super.initState();

    isDisplaySticker = false;
    isLoading = false;

    chatId = "";

    readLocal();
  }

  readLocal() async {

    if(userId.hashCode <= receiverId.hashCode){
      chatId = '$userId-$receiverId';
    } else {
      chatId = '$receiverId-$userId';
    }

    usersRef.doc(userId).update({ "chattingWith": receiverId });
  }

  onFocusChange() {
    if(focusNode.hasFocus){

      //hide sticker when keypad appear
      setState(() {
        isDisplaySticker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              //create list of msgs
              createListMessage(),

              //showStciker
              (isDisplaySticker ? createSticker() : Container()),

              //Input Controllers
              createInput(),
            ],
          ),
          createLoading(),
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  createLoading() {
    return Positioned(child: isLoading ? circularProgress() : Container(),);
  }
  Future<bool> onBackPress() {
    if(isDisplaySticker) {
      setState(() {
        isDisplaySticker = false;
      });
    } else {
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  onSendMessage(String contentMsg, int type) {
    //type 0: text msg
    //type 1: image
    //type 2: emoji
    if(contentMsg != ""){
      textEditingController.clear();
      var docRef = chatMsgRef.doc(chatId).collection(chatId).doc(DateTime.now().microsecondsSinceEpoch.toString());
      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.set(docRef, {
          "idFrom": userId,
          "idTo": receiverId,
          "timestamp": DateTime.now().microsecondsSinceEpoch.toString(),
          "content": contentMsg,
          "type": type,
        },);
      });
      listScrollController.animateTo(0.0, duration: Duration(microseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: "Empty message can not be send");
    }
  }

  createSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage("mimi1", 2),
                child: Image.asset(
                  "images/mimi1.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: () => onSendMessage("mimi2", 2),
                child: Image.asset(
                  "images/mimi2.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: () => onSendMessage("mimi3", 2),
                child: Image.asset(
                  "images/mimi3.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),

          //Second row
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage("mimi4", 2),
                child: Image.asset(
                  "images/mimi4.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: () => onSendMessage("mimi5", 2),
                child: Image.asset(
                  "images/mimi5.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: () => onSendMessage("mimi6", 2),
                child: Image.asset(
                  "images/mimi6.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),

          //Third row
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage("mimi7", 2),
                child: Image.asset(
                  "images/mimi7.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: () => onSendMessage("mimi8", 2),
                child: Image.asset(
                  "images/mimi8.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: () => onSendMessage("mimi9", 2),
                child: Image.asset(
                  "images/mimi9.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),

        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 0.5)), color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isDisplaySticker = !isDisplaySticker;
    });
  }

  createListMessage() {
    return Flexible(
      child: chatId == "" ? Container(child: Center(child: circularProgress()))
          :
      Container(
        child: StreamBuilder(
          stream: chatMsgRef.doc(chatId).collection(chatId).orderBy("timestamp", descending: true).limit(20).snapshots(),
          builder: (context, snapshot){
            if(!snapshot.hasData){
              circularProgress();
            } else {
              listMessage = snapshot.data.docs;
              return ListView.builder(padding: EdgeInsets.all(10.0),
                  itemBuilder: (context, index) => createItem(index, snapshot.data.docs[index]),
                itemCount: snapshot.data.docs.length,
                reverse: true,
                controller: listScrollController,
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget createItem(int index, DocumentSnapshot documentSnapshot) {
    //sender side
    if(documentSnapshot["idFrom"] == userId)
      {
        return Row(
          children: <Widget>[
            documentSnapshot["type"] == 0
            //Textmsg
            ? Container(
              child: Text(
                documentSnapshot["content"],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              width: 200.0,
              decoration: BoxDecoration(color: Colors.lightBlueAccent, borderRadius: BorderRadius.circular(8.0)),
              margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0: 10.0, right: 10.0),
            )
                //Image msg
            : documentSnapshot["type"] == 1
            ? Container(
              child: FlatButton(
                child: Material(
                  child: CachedNetworkImage(
                    placeholder: (context, url) => Container(
                      child: circularProgress(),
                      width: 200.0,
                      height: 200.0,
                      padding: EdgeInsets.all(70.0),
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(8.0)),),
                    ),
                    errorWidget: (context, url, error) => Material(
                      child: Image.asset("image/img_not_available.jepg", width: 200.0, height: 200.0, fit: BoxFit.cover,),
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    imageUrl: documentSnapshot["content"],
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: (BuildContext context, int index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(documentSnapshot["content"]),
                        heroAttributes: PhotoViewHeroAttributes(tag: documentSnapshot["timestamp"]),
                      );
                    },
                    itemCount: 1,
                    loadingBuilder: (context, event) => Center(
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          value: event == null
                              ? 0
                              : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                        ),
                      ),
                    ),
                  )));
                },
              ),
              margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0: 10.0, right: 10.0),
            )
            //Sticker
                : Container(
              child: Image.asset("images/${documentSnapshot['content']}.gif",
                width: 100.0,
                height: 100.0,
                fit: BoxFit.cover,
              ),
              margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0: 10.0, right: 10.0),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        );
      }
    //receiver side
    else {
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMsgLeft(index)?Material(
                  //display reciver profile image
                  child: CachedNetworkImage(
                    placeholder: (context, url) => Container(
                      child: circularProgress(),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(70.0),
                    ),
                    imageUrl: receiverAvatar,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(18.0),),
                  clipBehavior: Clip.hardEdge,
                ):Container(width: 35.0,),
                //display msgs
                documentSnapshot["type"] == 0
                //Textmsg
                    ? Container(
                  child: Text(
                    documentSnapshot["content"],
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(left: 10.0),
                )
                //Image msg
                    : documentSnapshot["type"] == 1
                    ? Container(
                  child: FlatButton(
                    child: Material(
                      child: CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: circularProgress(),
                          width: 200.0,
                          height: 200.0,
                          padding: EdgeInsets.all(70.0),
                          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(8.0)),),
                        ),
                        errorWidget: (context, url, error) => Material(
                          child: Image.asset("image/img_not_available.jepg", width: 200.0, height: 200.0, fit: BoxFit.cover,),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        imageUrl: documentSnapshot["content"],
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> PhotoView(
                        imageProvider: AssetImage(documentSnapshot["content"]),
                      )));
                    },
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                )
                //Sticker
                    : Container(
                  child: Image.asset("images/${documentSnapshot['content']}.gif",
                    width: 100.0,
                    height: 100.0,
                    fit: BoxFit.cover,
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                ),
              ],
            ),
            //msg time
            isLastMsgLeft(index)? Container(
              child: Text(DateFormat("dd MMMM, yyyy - hh:mm:aa").format(DateTime.fromMicrosecondsSinceEpoch(int.parse(documentSnapshot["timestamp"]))),
              style: TextStyle(color: Colors.grey, fontSize: 12.0, fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 50.0, bottom: 5.0),
            ): Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMsgLeft(int index) {
    if((index>0 && listMessage!=null && listMessage[index-1]["idFrom"]==userId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMsgRight(int index) {
    if((index>0 && listMessage!=null && listMessage[index-1]["idFrom"]!=userId) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  createInput() {
    return Container(
      child: Row(
        children: <Widget>[

          //Pick image
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                color: Colors.lightBlueAccent,
                onPressed: () => selectImage(context),
              ),
            ),
            color: Colors.white,
          ),

          //Pick emoji
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.face),
                color: Colors.lightBlueAccent,
                onPressed: () => getSticker(),
              ),
            ),
            color: Colors.white,
          ),

          //Text input for chattext
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(
                  color: Colors.black, fontSize: 15.0,
                ),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: "Write here...",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          //send Message icon button
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                color: Colors.lightBlueAccent,
                onPressed: () => onSendMessage(textEditingController.text,0),
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        color: Colors.white,
      ),
    );
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Create Post"),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    final pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.imageFile = File(pickedFile.path);
      if(this.imageFile != null){
        isLoading = true;
      }
      uploadImageFile();
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      this.imageFile = File(pickedFile.path);
      if(this.imageFile != null){
        isLoading = true;
      }
      uploadImageFile();
    });
  }

  uploadImageFile() async {
    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("chat_$fileName.jpg");
    UploadTask uploadTask = ref.putFile(imageFile);

    imageUrl = await uploadTask.then((res) async {
      return res.ref.getDownloadURL();
    }, onError: (err) {
      setState(() {
        isLoading = false;
        Fluttertoast.showToast(msg: "Err: ${err.toString()}");
      });
    });

    await uploadTask.whenComplete(() async {
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    });
  }

}