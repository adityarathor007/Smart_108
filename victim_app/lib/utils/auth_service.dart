import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_108/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

  //1. LOGIN USER
  String? get currentUserUid => _auth.currentUser?.uid;

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try{

      //1. Sign in with Firebase Auth
      UserCredential result=await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null;
    } on FirebaseAuthException catch (e){
      return e.message;
    } catch (e) {
      return "An unexpected error occurred. ";
    }
  }


 //2.SIGN IN WITH GOOGLE
  Future<String?> signInWithGoogle() async {

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    try{
        // Trigger google account picker
        final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
        final GoogleSignInAuthentication googleAuth=googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
        logger.d("User authenticated with UID: ${user.uid}");
        // 5. FIRESTORE SYNC: Check if the user is new
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
            // Create the profile document only if it doesn't exist
            await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'full_name': user.displayName ?? "-",
            'phone_number': user.phoneNumber ?? "-", // Google doesn't always provide this
            'email': user.email,
            'role': 'victim',
            'created_at': FieldValue.serverTimestamp(),
            'profile_completed': false,
            });
            return "new_user"; // Special flag to tell UI to go to Onboarding
        }}
        return null;

    } on FirebaseAuthException catch (e){
        return e.message;
    } catch (e) {
        return "An unknown error occured during google Sign In";
    }
    }





  //3. REGISTER USER
  Future<String?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber
  })async{
    try{
      //1. Create User in Auth
      UserCredential result= await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      User ? user = result.user;

      //2. Create User Profile in Firestore
      if(user!=null){
        // 1. Send the verification email immediately
        await user.sendEmailVerification();

        //2. Create the Firestore documentj
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'email':email,
          'role': 'victim',
          'created_at': FieldValue.serverTimestamp(),
          'profile_completed': false, //Track if medical info is added
        });

        
        await _auth.signOut(); // 2. SIGN OUT IMMEDIATELY
        // This prevents the StreamBuilder from jumping to the "Home" screen
        // before the profile is fully ready.
      }


      return null; //Success
    } on FirebaseAuthException catch(e){
      return e.message;
    }
  }



  //4. FORGOT PASSWORD
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }




  //5. SIGN OUT
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will automatically redirect to LoginPage
  }


  //6. Convert image to Base64 and save to Firestore
  Future<String?> uploadProfilePictureBase64() async{
    try{
      final String? uid = _auth.currentUser?.uid;
      if(uid==null) return "User not logged in";

      //a. Pick the image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 400,
      );

      if (image == null) return "No image selected";

      //b. Convert image to Bytes
      File file=File(image.path);
      List<int> imageBytes=await file.readAsBytes();


      //c. Encode Bytes to Base64 String
      String base64String = base64Encode(imageBytes);


      //d. Update Firestore document directly
      await _firestore.collection('users').doc(uid).update({
        'profile_base64': base64String
      });

      return null;
    } catch(e){
      return "Error: ${e.toString()}";
    }


  }


}


  // UPDATE MEDICAL PROFILE
//   Future<void> updateMedicalProfile({
//     required String bloodGroup,
//     required String emergencyContact,
//   }) async {
//     String uid = _auth.currentUser!.uid;
//     await _firestore.collection('users').doc(uid).update({
//       'blood_group': bloodGroup,
//       'emergency_contact': emergencyContact,
//       'profile_completed': true,
//     });
//   }
// }
