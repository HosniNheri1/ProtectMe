class EmergencyContact {
  String id;
  String name;
  String phone;
  String? email;
  String? relationship;
  int priority;
  bool receivesSMS;
  bool receivesCall;
  bool isActive;
  DateTime addedDate;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
    this.priority = 1,
    this.receivesSMS = true,
    this.receivesCall = true,
    this.isActive = true,
    required this.addedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'priority': priority,
      'receivesSMS': receivesSMS,
      'receivesCall': receivesCall,
      'isActive': isActive,
      'addedDate': addedDate,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      relationship: map['relationship'],
      priority: map['priority'],
      receivesSMS: map['receivesSMS'],
      receivesCall: map['receivesCall'],
      isActive: map['isActive'],
      addedDate: DateTime.parse(map['addedDate']),
    );
  }
    EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    int? priority,
    bool? receivesSMS,
    bool? receivesCall,
    bool? isActive,
    DateTime? addedDate,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      receivesSMS: receivesSMS ?? this.receivesSMS,
      receivesCall: receivesCall ?? this.receivesCall,
      isActive: isActive ?? this.isActive,
      addedDate: addedDate ?? this.addedDate,
    );
  }
}
