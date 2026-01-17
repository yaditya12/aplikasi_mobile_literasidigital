import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../data/materi.dart'; // Import Model Data

class AddMateriPage extends StatefulWidget {
  // Tambahkan parameter opsional ini
  final MateriModel? materi; // Data materi (jika edit)
  final String? docId;       // ID Dokumen (jika edit)
  final bool isQuizOnly;     // Parameter Baru (jika kuis saja)

  const AddMateriPage({
    super.key, 
    this.materi, 
    this.docId,
    this.isQuizOnly = false, // Default false
  });

  @override
  State<AddMateriPage> createState() => _AddMateriPageState();
}

class _AddMateriPageState extends State<AddMateriPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  List<Map<String, dynamic>> tempQuiz = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // LOGIKA PENENTUAN MODE (EDIT atau BARU)
    if (widget.materi != null) {
      _titleController = TextEditingController(text: widget.materi!.title);
      _contentController = TextEditingController(text: widget.materi!.content);
      
      // PERBAIKAN PENTING: Salin list quiz agar bisa diedit tanpa merusak data asli
      // Kita harus membuat 'Deep Copy' agar referensi tidak nyangkut
      tempQuiz = widget.materi!.quiz.map((q) {
        return {
          "question": q["question"],
          "options": List<String>.from(q["options"]),
          "answer": q["answer"]
        };
      }).toList();
      
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      tempQuiz = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      tempQuiz.add({
        "question": "",
        "options": ["", "", "", ""],
        "answer": 0,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      tempQuiz.removeAt(index);
    });
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Hilangkan O, 0, I, 1
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Dialog Kode Unik (Hanya muncul saat buat Kuis Baru)
  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text("Berhasil Dibuat!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Bagikan kode ini kepada siswa:", textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400)
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB)),
                onPressed: () {
                  Navigator.pop(context); // Tutup Dialog
                  Navigator.pop(context, true); // Kembali ke Home
                },
                child: const Text("SELESAI", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveAll() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Judul wajib diisi!")));
      return;
    }
    // Cek konten hanya jika bukan Quiz Only
    if (!widget.isQuizOnly && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi materi wajib diisi!")));
      return;
    }
    if (tempQuiz.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimal buat 1 pertanyaan kuis!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> dataToSave = {
        'title': _titleController.text.trim(),
        'content': widget.isQuizOnly ? "" : _contentController.text.trim(),
        'quiz': tempQuiz,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        // --- MODE EDIT ---
        await FirebaseFirestore.instance.collection('materi').doc(widget.docId).update(dataToSave);
        
        if (!mounted) return;
        Navigator.pop(context, true); // Balik ke Home

      } else {
        // --- MODE BARU ---
        String newCode = _generateJoinCode();
        dataToSave['joinCode'] = newCode;
        dataToSave['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance.collection('materi').add(dataToSave);
        
        if (!mounted) return;
        _showSuccessDialog(newCode); // Tampilkan Kode
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Gagal menyimpan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = widget.docId != null ? "Edit Materi" : (widget.isQuizOnly ? "Buat Kuis Baru" : "Buat Materi Baru");
    String buttonText = widget.docId != null ? "UPDATE MATERI" : "SIMPAN MATERI";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A11CB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.title, "Judul"),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _titleController,
              label: "Judul",
              hint: "Masukkan judul...",
              icon: Icons.title,
            ),
            const SizedBox(height: 20),

            // Hanya tampilkan kolom konten jika bukan Quiz Only
            if (!widget.isQuizOnly) ...[
              _buildSectionHeader(Icons.book_rounded, "Isi Materi"),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _contentController,
                label: "Penjelasan Materi",
                hint: "Tuliskan materi pelajaran...",
                icon: Icons.notes,
                maxLines: 5,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(Icons.quiz_rounded, "Pertanyaan Kuis"),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Tambah"),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A11CB)),
                ),
              ],
            ),

            if (tempQuiz.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(Icons.post_add, size: 50, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text("Belum ada kuis. Klik tambah untuk membuat.", 
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
              ),

            ...tempQuiz.asMap().entries.map((entry) {
              int qIdx = entry.key;
              return _buildQuestionCard(qIdx);
            }).toList(),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(buttonText, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER UI ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6A11CB), size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          floatingLabelStyle: const TextStyle(color: Color(0xFF6A11CB)),
        ),
      ),
    );
  }

  // Widget Kartu Pertanyaan Kuis
  Widget _buildQuestionCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A11CB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Soal #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB))),
                ),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: "Hapus Soal",
                )
              ],
            ),
            const SizedBox(height: 10),
            
            // Pertanyaan dengan Controller agar saat discroll tidak hilang
            TextField(
              controller: TextEditingController(text: tempQuiz[index]['question'])
                ..selection = TextSelection.fromPosition(TextPosition(offset: tempQuiz[index]['question'].length)),
              onChanged: (v) => tempQuiz[index]['question'] = v,
              decoration: const InputDecoration(
                hintText: "Tulis pertanyaan di sini...",
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            
            const Text("Pilihan Jawaban (Klik bulat untuk kunci jawaban):", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            
            ...List.generate(4, (optIdx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optIdx,
                      groupValue: tempQuiz[index]['answer'],
                      onChanged: (val) {
                        setState(() {
                          tempQuiz[index]['answer'] = val;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Opsi Jawaban dengan Controller
                        child: TextField(
                          controller: TextEditingController(text: tempQuiz[index]['options'][optIdx]),
                          onChanged: (v) => tempQuiz[index]['options'][optIdx] = v,
                          decoration: InputDecoration(
                            hintText: "Opsi ${String.fromCharCode(65 + optIdx)}",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}