import 'package:cloud_firestore/cloud_firestore.dart';

/// A small helper class to encapsulate firestore operations related to reviews.
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all reviews in the system. Documents are mapped to a simple
  /// `Map<String, dynamic>` where the Firestore document id is added under
  /// the `id` key. Reviews are sorted by `createdAt` descending so newest
  /// appear first.
  Stream<List<Map<String, dynamic>>> allReviewsStream() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Fetch the review document for the given user id. Returns `null` if the
  /// document does not exist.
  Future<Map<String, dynamic>?> getUserReview(String userId) async {
    final doc = await _firestore.collection('reviews').doc(userId).get();
    return doc.exists ? Map<String, dynamic>.from(doc.data()!) : null;
  }

  /// Creates or updates a review.  We use the user's uid as the document id so
  /// that a given user has at most one review and can easily update it.  The
  /// data is merged to preserve any additional fields that might already exist
  /// (e.g. if the schema changes later).
  Future<void> submitReview({
    required String userId,
    required double rating,
    required String comment,
    String? userName,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = _firestore.collection('reviews').doc(userId);

    await ref.set({
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'name': userName ?? '',
      'updatedAt': now,
      // only set createdAt the first time; merge ensures we don't overwrite
      'createdAt': now,
    }, SetOptions(merge: true));
  }
}
