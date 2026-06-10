import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/materi.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int total;
  final MateriModel? materi;

  const ResultPage({
    super.key,
    required this.score,
    required this.total,
    this.materi,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  int earnedPoints = 0;
  bool isUpdating = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _saveQuizResult();
  }

  Future<void> _saveQuizResult() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (widget.total <= 0) {
      setState(() {
        earnedPoints = 0;
        isUpdating = false;
        errorMessage = 'Total soal tidak valid.';
      });
      return;
    }

    final double percentage = (widget.score / widget.total) * 100;
    earnedPoints = percentage.round().clamp(0, 100);

    if (user == null) {
      if (!mounted) return;
      setState(() {
        isUpdating = false;
        errorMessage = 'User belum login. Riwayat tidak tersimpan.';
      });
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference<Map<String, dynamic>> userRef =
          firestore.collection('users').doc(user.uid);

      final CollectionReference<Map<String, dynamic>> historyRef =
          userRef.collection('history');

      final WriteBatch batch = firestore.batch();

      batch.set(
        userRef,
        {
          'points': FieldValue.increment(earnedPoints),
          'lastQuizAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(historyRef.doc(), {
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'quizId': widget.materi?.id ?? '',
        'quizTitle': widget.materi?.title.trim().isNotEmpty == true
            ? widget.materi!.title.trim()
            : 'Kuis',
        'score': earnedPoints,
        'correctAnswers': widget.score,
        'totalQuestions': widget.total,
        'pointsEarned': earnedPoints,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        isUpdating = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isUpdating = false;
        errorMessage = 'Gagal menyimpan riwayat: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String quizTitle = widget.materi?.title.trim().isNotEmpty == true
        ? widget.materi!.title.trim()
        : 'Kuis';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 100,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kuis Selesai!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quizTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Skor Kamu: ${widget.score} / ${widget.total}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Nilai / Poin Diperoleh',
                        style: TextStyle(color: Colors.indigo),
                      ),
                      const SizedBox(height: 8),
                      isUpdating
                          ? const SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '+$earnedPoints',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 45),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A11CB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'KEMBALI KE HOME',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}