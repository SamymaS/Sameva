import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gestion des quêtes
  static Future<void> saveQuest(Map<String, dynamic> quest) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quests')
          .add(quest);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la quête: $e');
    }
  }

  // Récupération des quêtes
  static Stream<QuerySnapshot> getQuests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('quests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mise à jour du profil joueur
  static Future<void> updatePlayerStats(Map<String, dynamic> stats) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .set({'stats': stats}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des stats: $e');
    }
  }
} 