class MateriModel {
  final String? id; // <--- INI PENTING: Variabel penampung ID
  final String title;
  final String content;
  final List<Map<String, dynamic>> quiz;

  MateriModel({
    this.id, // <--- INI PENTING: Agar bisa diisi dari Home Page
    required this.title,
    required this.content,
    required this.quiz,
  });
}

// Data Dummy (Bisa dihapus nanti)
final List<MateriModel> materiList = [
  MateriModel(
    id: "dummy1",
    title: "Contoh Materi",
    content: "Isi materi...",
    quiz: [],
  ),
];