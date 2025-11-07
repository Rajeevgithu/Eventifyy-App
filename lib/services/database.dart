import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = "users";
  static const String _eventsCollection = "Event";
  static const String _ticketsCollection = "Tickets";

  // Subcollections
  static const String _userBookingsSubcollection = "Booking";

  // ===========================================================================
  // USER PROFILE
  // ===========================================================================

  /// Add or update user on first sign-in
  Future<void> addUserDetail(
    Map<String, dynamic> userInfoMap,
    String userId,
  ) async {
    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .set(userInfoMap, SetOptions(merge: true));
  }

  /// Update specific fields in user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(_usersCollection).doc(userId).update(data);
  }

  /// Get user data by ID
  Future<Map<String, dynamic>?> getUserDetail(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      return snapshot.exists ? snapshot.data() : null;
    } catch (e) {
      debugPrint("Error fetching user: $e");
      return null;
    }
  }

  /// Delete user + all their bookings
  Future<void> deleteUser(String userId) async {
    final batch = _firestore.batch();

    try {
      // Delete all bookings in user's subcollection
      final bookingsSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_userBookingsSubcollection)
          .get();

      for (final doc in bookingsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user document
      batch.delete(_firestore.collection(_usersCollection).doc(userId));

      await batch.commit();
    } catch (e) {
      debugPrint("Error deleting user: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // EVENTS
  // ===========================================================================

  /// Add or update event
  Future<void> addEvent(
    Map<String, dynamic> eventInfoMap,
    String eventId,
  ) async {
    await _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .set(eventInfoMap, SetOptions(merge: true));
  }

  /// Stream all events
  Stream<QuerySnapshot> getAllEvents() {
    return _firestore.collection(_eventsCollection).snapshots();
  }

  /// Stream events by category
  Stream<QuerySnapshot> getEventsByCategory(String category) {
    return _firestore
        .collection(_eventsCollection)
        .where("Category", isEqualTo: category)
        .snapshots();
  }

  // ===========================================================================
  // BOOKINGS (User Side)
  // ===========================================================================

  /// Book an event (saved under user)
  Future<String> addUserBooking(
    Map<String, dynamic> bookingInfo,
    String userId,
  ) async {
    final docRef = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_userBookingsSubcollection)
        .add({...bookingInfo, "BookingDate": FieldValue.serverTimestamp()});
    return docRef.id;
  }

  /// Stream user's bookings
  Stream<QuerySnapshot> getUserBookings(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_userBookingsSubcollection)
        .orderBy("BookingDate", descending: true)
        .snapshots();
  }

  // ===========================================================================
  // ADMIN PANEL (Global Tickets)
  // ===========================================================================

  /// Add booking to global Tickets (admin view)
  Future<String> addAdminBooking(Map<String, dynamic> bookingInfo) async {
    final docRef = await _firestore.collection(_ticketsCollection).add({
      ...bookingInfo,
      "BookingDate": FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Stream all bookings (admin)
  Stream<QuerySnapshot> getAllUserBookings() {
    return _firestore
        .collection(_ticketsCollection)
        .orderBy("BookingDate", descending: true)
        .snapshots();
  }

  /// Stream all tickets
  Stream<QuerySnapshot> getAllTickets() {
    return _firestore.collection(_ticketsCollection).snapshots();
  }

  // ===========================================================================
  // UTILITIES
  // ===========================================================================

  /// Search events by name (partial match)
  Stream<QuerySnapshot> searchEvents(String query) {
    final lower = query.toLowerCase();
    final upper = '$lower\uf8ff';

    return _firestore
        .collection(_eventsCollection)
        .where("SearchName", isGreaterThanOrEqualTo: lower)
        .where("SearchName", isLessThanOrEqualTo: upper)
        .snapshots();
  }

  /// Get event by ID
  Future<DocumentSnapshot?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();
      return doc.exists ? doc : null;
    } catch (e) {
      debugPrint("Error fetching event: $e");
      return null;
    }
  }
}
