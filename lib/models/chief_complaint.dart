class ChiefComplaint {
  final int? id;
  final String name;

  ChiefComplaint({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory ChiefComplaint.fromMap(Map<String, dynamic> map) {
    return ChiefComplaint(id: map['id'], name: map['name']);
  }

  @override
  String toString() => 'ChiefComplaint(id: $id, name: $name)';
}
