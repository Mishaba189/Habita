import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserEmail = 'remember_user_email';
  static const String keyUserPassword = 'remember_user_password';
  static const String keyIsRememberMe = 'remember_me_status';


  Future<void> _setLoading(bool value) async {
    _isLoading = value;
    notifyListeners();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final ValueNotifier<bool> rememberMeNotifier = ValueNotifier<bool>(false);

  String _userName = '';
  String get userName => _userName;
  String get userEmail => _auth.currentUser?.email ?? '';


  Future<void> fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _userName = '';
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        _userName = doc.data()?['name'] ?? user.displayName ?? 'User';
      } else {
        _userName = user.displayName ?? 'User';
      }
    } catch (e) {
      _userName = user.displayName ?? 'User';
    }
    notifyListeners();
  }
  Future<void> loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool(keyIsRememberMe) ?? false;

    rememberMeNotifier.value = isRemembered;
    if (isRemembered) {
      emailController.text = prefs.getString(keyUserEmail) ?? '';
      passwordController.text = prefs.getString(keyUserPassword) ?? '';
    }
  }

  Future<void> _saveSession({required bool rememberMe, String? email, String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setBool(keyIsRememberMe, rememberMe);

    if (rememberMe && email != null && password != null) {
      await prefs.setString(keyUserEmail, email);
      await prefs.setString(keyUserPassword, password);
    } else {
      await prefs.remove(keyUserEmail);
      await prefs.remove(keyUserPassword);
    }
  }

  Future<void> _saveUserToFirestore({
    required String uid,
    required String email,
    required String name,
  }) async {
    final userDocRef = _firestore.collection('users').doc(uid);
    final UserModel userModel = UserModel(
      uid: uid,
      email: email,
      name: name,
    );
    final docSnapshot = await userDocRef.get();
    if (!docSnapshot.exists) {
      await userDocRef.set(userModel.toMap());
    } else {
      await userDocRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Register User
  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _saveUserToFirestore(
          uid: userCredential.user!.uid,
          email: email,
          name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'User',
        );
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } finally {
      _setLoading(false);
    }
  }

  // Log In
  Future<void> logIn(String email, String password) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        String existingName = doc.exists ? (doc.data()?['name'] ?? 'User') : 'User';

        _userName = existingName;

        await _saveUserToFirestore(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          name: existingName,
        );

        await _saveSession(
          rememberMe: rememberMeNotifier.value,
          email: email,
          password: password,
        );
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } finally {
      _setLoading(false);
    }
  }

  // Forgot Password
  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } finally {
      _setLoading(false);
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: '428106498244-3ma7ipq51sflk8gdc9bp6oa78f711os6.apps.googleusercontent.com',
      );

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? 'Google User',
        );
        await _saveSession(rememberMe: false);
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    } catch (e) {
      throw 'An error occurred during Google Sign-In: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, false);
    // Optionally clear remembered credentials on explicit sign out if desired:
    // await prefs.remove(keyUserEmail);
    // await prefs.remove(keyUserPassword);
    // await prefs.setBool(keyIsRememberMe, false);
    notifyListeners();
  }


  Future<void> updateUserName(String newName) async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in.';

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': newName,
      });

      // Update local state variable
      _userName = newName;
      notifyListeners();
    } catch (e) {
      throw 'Failed to update name: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  void clearAll() {
    nameController.clear();
    passwordController.clear();
    emailController.clear();
    confirmPasswordController.clear();
  }

  String getReadableMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'The supplied auth credential is incorrect, malformed or has expired.':
        return 'Incorrect email or password';
      case 'The email address is already in use by another account.':
        return 'The email address is already in use by another account.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}