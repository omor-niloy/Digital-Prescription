class Medicine {
  final int? id;
  final String name;

  Medicine({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(id: map['id'], name: map['name']);
  }

  @override
  String toString() => 'Medicine(id: $id, name: $name)';
}
