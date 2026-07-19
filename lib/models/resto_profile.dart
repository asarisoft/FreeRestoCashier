class RestoProfile {
  final String name;
  final String? address;
  final String? phone;
  final String? footerNote;
  final int paperWidth;
  final bool useLogo;
  final String? logoUrl;
  final DateTime createdAt;

  const RestoProfile({
    required this.name,
    this.address,
    this.phone,
    this.footerNote,
    this.paperWidth = 58,
    this.useLogo = false,
    this.logoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
        'footerNote': footerNote,
        'paperWidth': paperWidth,
        'useLogo': useLogo,
        'logoUrl': logoUrl,
        'createdAt': createdAt,
      };

  factory RestoProfile.fromJson(Map<String, dynamic> json) => RestoProfile(
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        footerNote: json['footerNote'] as String?,
        paperWidth: json['paperWidth'] as int? ?? 58,
        useLogo: json['useLogo'] as bool? ?? false,
        logoUrl: json['logoUrl'] as String?,
        createdAt: (json['createdAt'] as dynamic).toDate(),
      );

  RestoProfile copyWith({
    String? name,
    String? address,
    String? phone,
    String? footerNote,
    int? paperWidth,
    bool? useLogo,
    String? logoUrl,
  }) =>
      RestoProfile(
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        footerNote: footerNote ?? this.footerNote,
        paperWidth: paperWidth ?? this.paperWidth,
        useLogo: useLogo ?? this.useLogo,
        logoUrl: logoUrl ?? this.logoUrl,
        createdAt: createdAt,
      );
}
