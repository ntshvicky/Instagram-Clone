const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
      console.log("Follower Created", snapshot.id);
      const userId = context.params.userId;
      const followerId = context.params.followerId;

      // 1) Create followed users posts ref
      const followedUserPostsRef = admin
          .firestore()
          .collection("posts")
          .doc(userId)
          .collection("userPosts");

      // 2) Create following user's timeline ref
      const timelinePostsRef = admin
          .firestore()
          .collection("timeline")
          .doc(followerId)
          .collection("timelinePosts");

      // 3) Get followed users posts
      const querySnapshot = await followedUserPostsRef.get();

      // 4) Add each user post to following user's timeline
      querySnapshot.forEach((doc) => {
        if (doc.exists) {
          const postId = doc.id;
          const postData = doc.data();
          timelinePostsRef.doc(postId).set(postData);
        }
      });
    });

exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
      console.log("Follower Deleted", snapshot.id);

      const userId = context.params.userId;
      const followerId = context.params.followerId;

      const timelinePostsRef = admin
          .firestore()
          .collection("timeline")
          .doc(followerId)
          .collection("timelinePosts")
          .where("ownerId", "==", userId);

      const querySnapshot = await timelinePostsRef.get();
      querySnapshot.forEach((doc) => {
        if (doc.exists) {
          doc.ref.delete();
        }
      });
    });

// when a post is created, add post to timeline of each follower (of post owner)
exports.onCreatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onCreate(async (snapshot, context) => {
      const postCreated = snapshot.data();
      const userId = context.params.userId;
      const postId = context.params.postId;

      // 1) Get all the followers of the user who made the post
      const userFollowersRef = admin
          .firestore()
          .collection("followers")
          .doc(userId)
          .collection("userFollowers");

      const querySnapshot = await userFollowersRef.get();
      // 2) Add new post to each follower's timeline
      querySnapshot.forEach((doc) => {
        const followerId = doc.id;

        admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .doc(postId)
            .set(postCreated);
      });
    });

exports.onUpdatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {
      const postUpdated = change.after.data();
      const userId = context.params.userId;
      const postId = context.params.postId;

      // 1) Get all the followers of the user who made the post
      const userFollowersRef = admin
          .firestore()
          .collection("followers")
          .doc(userId)
          .collection("userFollowers");

      const querySnapshot = await userFollowersRef.get();
      // 2) Update each post in each follower's timeline
      querySnapshot.forEach((doc) => {
        const followerId = doc.id;

        admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .doc(postId)
            .get()
            .then((doc) => {
              if (doc.exists) {
                doc.ref.update(postUpdated);
              }
            });
      });
    });

exports.onDeletePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onDelete(async (snapshot, context) => {
      const userId = context.params.userId;
      const postId = context.params.postId;

      // 1) Get all the followers of the user who made the post
      const userFollowersRef = admin
          .firestore()
          .collection("followers")
          .doc(userId)
          .collection("userFollowers");

      const querySnapshot = await userFollowersRef.get();
      // 2) Delete each post in each follower's timeline
      querySnapshot.forEach((doc) => {
        const followerId = doc.id;

        admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .doc(postId)
            .get()
            .then((doc) => {
              if (doc.exists) {
                doc.ref.delete();
              }
            });
      });
    });

exports.onCreateActivityFeedItem = functions.firestore
    .document("/feed/{userId}/feedItems/{activityFeedItem}")
    .onCreate(async (snapshot, context) => {
      console.log("Activity Feed Item Created", snapshot.data());

      // 1) Get user connected to the feed
      const userId = context.params.userId;

      const userRef = admin.firestore().doc(`users/${userId}`);
      const doc = await userRef.get();

      // 2) send notification, if they have a token
      const androidNotificationToken = doc.data().androidNotificationToken;
      const createdActivityFeedItem = snapshot.data();
      if (androidNotificationToken) {
        sendNotification(androidNotificationToken, createdActivityFeedItem);
      } else {
        console.log("No token for user, cannot send notification");
      }

      /**
       * Adds two numbers together.
       * @param {string} androidNotificationToken The first number.
       * @param {string} activityFeedItem The second number.
       */
      function sendNotification(androidNotificationToken, activityFeedItem) {
        let body;

        // 3) switch body value based off of notification type
        switch (activityFeedItem.type) {
          case "comment":
            body = `${activityFeedItem.username} replied: ${
              activityFeedItem.commentData
            }`;
            break;
          case "like":
            body = `${activityFeedItem.username} liked your post`;
            break;
          case "follow":
            body = `${activityFeedItem.username} started following you`;
            break;
          default:
            break;
        }

        // 4) Create message for push notification
        const message = {
          notification: {body},
          token: androidNotificationToken,
          data: {recipient: userId, type: "feed"},
        };

        // 5) Send message with admin.messaging()
        admin
            .messaging()
            .send(message)
            .then((response) => {
              // Response is a message ID string
              console.log("Successfully sent message", response);
            })
            .catch((error) => {
              console.log("Error sending message", error);
            });
      }
    });


exports.onCreateChatItem = functions.firestore
    .document("/chatmessage/{stage1}/{stage2}/{timeline}")
    .onCreate(async (snapshot, context) => {
      console.log("Chat Item Created", snapshot.data());

      // Read chat user data
      const chatItem = snapshot.data();

      // 1) Get user connected to the chat
      const senderId = chatItem.idFrom;
      const recipientId = chatItem.idTo;

      const sndRef = admin.firestore().doc(`users/${senderId}`);
      const sndDoc = await sndRef.get();

      const rcvRef = admin.firestore().doc(`users/${recipientId}`);
      const rcvDoc = await rcvRef.get();

      // 2) send notification, if they have a token
      const ntfSender = sndDoc.data();
      const ntfReceiver = rcvDoc.data();
      if (ntfReceiver.androidNotificationToken) {
        sendNotification(ntfSender, ntfReceiver, chatItem);
      } else {
        console.log("No token for user, cannot send notification");
      }

      /**
       * Adds two numbers together.
       * @param {string} ntfSender The Sender.
       * @param {string} ntfReceiver The Receiver
       * @param {string} chatItem The second Item.
       */
      function sendNotification(ntfSender, ntfReceiver, chatItem) {
        let body;

        // 3) switch body value based off of notification type
        switch (chatItem.type) {
          case 0:
            body = `${ntfSender.displayName} has sent a message`;
            break;
          case 1:
            body = `${ntfSender.displayName} has sent an image`;
            break;
          case 2:
            body = `${ntfSender.displayName} has sent an emoji`;
            break;
          default:
            body = `${ntfSender.displayName} has messaged you`;
        }

        // 4) Create message for push notification
        const message = {
          notification: {body},
          token: ntfReceiver.androidNotificationToken,
          data: {recipient: recipientId, sender: senderId, type: "chat"},
        };

        // 5) Send message with admin.messaging()
        admin
            .messaging()
            .send(message)
            .then((response) => {
              // Response is a message ID string
              console.log("Successfully sent message", response);
            })
            .catch((error) => {
              console.log("Error sending message", error);
            });
      }
    });
