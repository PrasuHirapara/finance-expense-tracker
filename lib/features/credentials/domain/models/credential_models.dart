import 'package:equatable/equatable.dart';

class CredentialField extends Equatable {
  const CredentialField({
    required this.keyLabel,
    required this.value,
  });

  final String keyLabel;
  final String value;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': keyLabel,
    'value': value,
  };

  factory CredentialField.fromJson(Map<String, dynamic> json) {
    return CredentialField(
      keyLabel: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[keyLabel, value];
}

class CredentialDraft extends Equatable {
  const CredentialDraft({
    required this.title,
    required this.fields,
  });

  final String title;
  final List<CredentialField> fields;

  @override
  List<Object?> get props => <Object?>[title, fields];
}

class CredentialRecord extends Equatable {
  const CredentialRecord({
    required this.id,
    required this.title,
    required this.encryptedPayload,
    required this.saltBase64,
    required this.nonceBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String encryptedPayload;
  final String saltBase64;
  final String nonceBase64;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    encryptedPayload,
    saltBase64,
    nonceBase64,
    createdAt,
    updatedAt,
  ];
}

class DecryptedCredential extends Equatable {
  const DecryptedCredential({
    required this.id,
    required this.title,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final List<CredentialField> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    fields,
    createdAt,
    updatedAt,
  ];
}

class EncryptedCredentialPayload extends Equatable {
  const EncryptedCredentialPayload({
    required this.encryptedPayload,
    required this.saltBase64,
    required this.nonceBase64,
  });

  final String encryptedPayload;
  final String saltBase64;
  final String nonceBase64;

  @override
  List<Object?> get props => <Object?>[
    encryptedPayload,
    saltBase64,
    nonceBase64,
  ];
}
