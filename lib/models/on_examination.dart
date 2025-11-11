class OnExamination {
  final int? id;
  final String name;

  OnExamination({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory OnExamination.fromMap(Map<String, dynamic> map) {
    return OnExamination(id: map['id'], name: map['name']);
  }

  @override
  String toString() => 'OnExamination(id: $id, name: $name)';
}
