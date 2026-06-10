import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. REGISTER USER
  Future<String?> registerDispatcher({
    required String email,
    required String password,
    required String name,
  }) async {
      try{
          UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

          // Create the pending dispatcher document
          await _firestore.collection('dispatchers').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'name': name,
            'email': email,
            'status': 'pending',
            'assigned_city': null,
            'createdAt': FieldValue.serverTimestamp(),
          });

          return "success";
      } on FirebaseAuthException catch (e) {
        return e.message;
      } catch (e) {
        return e.toString();
      }
  }



  //2. LOGIN USER
  Future<String?> loginUser({
    required String email,
    required String password,
    required bool isAdmin,
  }) async {
    try{
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      if (isAdmin){
        //check if the user exists in system_admins
        var adminDoc = await _firestore.collection('admins').doc(cred.user!.uid).get();
        if(adminDoc.exists){
          return "admin_success";
        }
        else{
          await _auth.signOut();
          return "Access Denied: You don't have Admin privilages";
        }
      }
      else{
        //check if user exists in dispatchers
        var dispatcherDoc = await _firestore.collection('dispatchers').doc(cred.user!.uid).get();
        if (dispatcherDoc.exists){
          // if(dispatcherDoc['status'] == 'active'){
            return 'dispatcher_success';
          // }
          // else{
            // await _auth.signOut();
            // return "Account Pending: Your city has not been assigned yet by an Admin";
          // }
        }
        else{
          await _auth.signOut();
          return "Access Denied: No Dispatcher account found with this email";
        }
      }
    } on FirebaseAuthException catch(e){
      return e.message;
    } catch(e){
      return e.toString();
    }
  }


  // 3. LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

}
