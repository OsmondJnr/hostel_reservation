import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hostel_reservation/app_theme.dart';

import 'review_service.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _service = ReviewService();
  final _commentController = TextEditingController();
  double _rating = 3.0;
  bool _loadingExisting = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    if (_user == null) return;
    final data = await _service.getUserReview(_user!.uid);
    if (data != null) {
      setState(() {
        _rating = (data['rating'] as num?)?.toDouble() ?? 3.0;
        _commentController.text = data['comment'] ?? '';
      });
    }
    setState(() => _loadingExisting = false);
  }

  Future<void> _submit() async {
    if (_user == null) return;
    await _service.submitReview(
      userId: _user!.uid,
      rating: _rating,
      comment: _commentController.text.trim(),
      userName: _user!.displayName ?? '',
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thank You!'),
          content: const Text('Your review has been submitted.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate & Review Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // rating and comment form
            Text('Rate the Room:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              maxRating: 5,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your review here...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit Review'),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.allReviewsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reviews = snap.data ?? [];
                  if (reviews.isEmpty) {
                    return const Center(child: Text('No reviews yet')); 
                  }
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final rev = reviews[index];
                      final name = rev['name'] as String? ?? 'User';
                      final rating = (rev['rating'] as num?)?.toDouble() ?? 0;
                      final comment = rev['comment'] as String? ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text('$name — ${rating.toStringAsFixed(1)} ⭐'),
                          subtitle: Text(comment),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
