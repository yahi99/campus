import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus/services/snackbarService.dart';

enum AuthStatus {
  NotAutheticated,
  Authenticating,
  Authenticated,
  UserNotFound,
  Error
}

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();
final Firestore _firestore = Firestore.instance;
String error;
String bio = "Hi, I'm new here";
AuthStatus status;
// FirebaseUser user1;

// FireStoreService _fireStoreService;

Map<String, String> exposeUser({@required kUsername, @required kUID}) {
  print(kUID);
  return {kUsername: kUsername, kUID: kUID};
}

Future<Map<String, String>> getCurrentUser() async {
  final FirebaseUser user = await _auth.currentUser();
  if (user != null) {
    return exposeUser(kUsername: user.displayName, kUID: user.uid);
    // print(user.getIdToken());
    // return user.uid;
  }
  return null;
}

Future getUser() async {
  final FirebaseUser user = await _auth.currentUser();
  if(user != null){
    return user;
  }
    return null;
}

Future<bool> isUserSignedIn() async {
  final FirebaseUser currentUser = await _auth.currentUser();
  return currentUser != null;
}

signOut() {
  try {
    _auth.signOut();
  } catch (error) {
    print(error);
  }
}

void onAuthenticationChange(Function isLogin) {
  _auth.onAuthStateChanged.listen((FirebaseUser user) {
    if (user != null) {
      isLogin(exposeUser(kUsername: user.displayName, kUID: user.uid));
    } else {
      isLogin(null);
    }
  });
}

Future<Map<String, String>> signUp(
  String email,
  String password,
  String name,
  String phone,
) async {
  status = AuthStatus.Authenticating;
  try {
    AuthResult result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final FirebaseUser user = result.user;
    // user1 = result.user;
    status = AuthStatus.Authenticated;
    SnackBarService.instance.showSnackBarSuccess('Account Created for ${user.email}');
    assert(user != null);
    assert(await user.getIdToken() != null);

    var userUpdateInfo = UserUpdateInfo();
    userUpdateInfo.displayName = name;
    
    userUpdateInfo.photoUrl =
        'https://www.kindpng.com/picc/b/78-785827_avatar-png-icon.png';
    await user.updateProfile(userUpdateInfo).then((user) {
      _auth.currentUser().then((user) {
        final DocumentReference _documentReference = _firestore
            .collection('userData')
            .document(user.uid);
        _documentReference.setData({
          'email': user.email,
          'username': user.displayName,
          'photoUrl': user.photoUrl,
          'initials': user.displayName[0].toUpperCase(),
          'bio': bio,
          'posts': 0,
          'phone': phone,
          'uid': user.uid,
          'followers': 0,
          'followersList': [],
          'following': 0,
          'followingList': [],
          'createdAt': Timestamp.now(),
          'documentId': _documentReference.documentID,
        }).catchError((e) {
          print(e);
        });
      }).catchError((e) {
        print(e);
      });
    }).catchError((e) {
      print(e);
    });
    await user.reload();
    // await _fireStoreService.createUser(user);

    print('Account created');
    print('$user.uid');
    return exposeUser(kUsername: user.displayName, kUID: user.uid);
  } catch (e) {
    error = e.message;
    SnackBarService.instance.showSnackBarError(error);
  }
}

Future<Map<String, String>> signIn(
  String email,
  String password,
) async {
  status = AuthStatus.Authenticating;
  try {
    AuthResult result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final FirebaseUser user = result.user;
    // user1 = result.user;
    status = AuthStatus.Authenticated;
    SnackBarService.instance.showSnackBarSuccess('Welcome, ${user.email}');
    assert(user != null);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    print('signIn succeeded : $user');
    print('User signed in');
    return exposeUser(kUsername: user.displayName, kUID: user.uid);
  } catch (e) {
    status = AuthStatus.Error;
    error = e.message;
    SnackBarService.instance.showSnackBarError(error);
    
    print(error);
  }
}

//  handleError(PlatformException error) {
//   print(error);
//   switch (error.code) {
//     case 'ERROR_EMAIL_ALREADY_IN_USE':
//       setState(() {
//         errorMessage = 'Email Id already Exist!!!';
//       });
//       break;
//     default:
//   }
// }

Future sendPasswordResetEmail(String email) async {
  SnackBarService.instance.showSnackBarSuccess(
    'A link to reset your password has been sent to ${email}'
    );
  return _auth.sendPasswordResetEmail(email: email.trim());
  
}

Future<String> getUserId() async {
  final FirebaseUser user = await _auth.currentUser();
  if (user != null) {
    return user.uid;
  }
  return null;
}
