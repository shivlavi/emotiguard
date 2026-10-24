class TrustedContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship; // e.g. "Spouse", "Parent", "Friend", "Therapist"
  final bool notifyViaSms;
  final bool notifyViaWhatsApp;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.notifyViaSms = true,
    this.notifyViaWhatsApp = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'relationship': relationship,
        'notifyViaSms': notifyViaSms,
        'notifyViaWhatsApp': notifyViaWhatsApp,
      };

  factory TrustedContact.fromJson(Map<String, dynamic> json) => TrustedContact(
        id: json['id'] as String,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String,
        relationship: json['relationship'] as String? ?? 'Friend',
        notifyViaSms: json['notifyViaSms'] as bool? ?? true,
        notifyViaWhatsApp: json['notifyViaWhatsApp'] as bool? ?? true,
      );

  TrustedContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? notifyViaSms,
    bool? notifyViaWhatsApp,
  }) {
    return TrustedContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      notifyViaSms: notifyViaSms ?? this.notifyViaSms,
      notifyViaWhatsApp: notifyViaWhatsApp ?? this.notifyViaWhatsApp,
    );
  }
}
