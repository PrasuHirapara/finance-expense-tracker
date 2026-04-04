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
    this.expiryDate,
  });

  final String title;
  final List<CredentialField> fields;
  final DateTime? expiryDate;

  @override
  List<Object?> get props => <Object?>[title, fields, expiryDate];
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
    this.expiryDate,
  });

  final int id;
  final String title;
  final List<CredentialField> fields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiryDate;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    fields,
    createdAt,
    updatedAt,
    expiryDate,
  ];
}

class CredentialPasswordIssue extends Equatable {
  const CredentialPasswordIssue({
    required this.credentialId,
    required this.credentialTitle,
    required this.fieldLabel,
    required this.description,
  });

  final int credentialId;
  final String credentialTitle;
  final String fieldLabel;
  final String description;

  @override
  List<Object?> get props => <Object?>[
    credentialId,
    credentialTitle,
    fieldLabel,
    description,
  ];
}

class CredentialExpiryReminder extends Equatable {
  const CredentialExpiryReminder({
    required this.credentialId,
    required this.credentialTitle,
    required this.expiryDate,
    required this.daysRemaining,
  });

  final int credentialId;
  final String credentialTitle;
  final DateTime expiryDate;
  final int daysRemaining;

  bool get isExpired => daysRemaining < 0;

  @override
  List<Object?> get props => <Object?>[
    credentialId,
    credentialTitle,
    expiryDate,
    daysRemaining,
  ];
}

class CredentialSecurityReport extends Equatable {
  const CredentialSecurityReport({
    required this.reusedPasswords,
    required this.expiredItems,
    required this.expiringSoonItems,
  });

  final List<CredentialPasswordIssue> reusedPasswords;
  final List<CredentialExpiryReminder> expiredItems;
  final List<CredentialExpiryReminder> expiringSoonItems;

  @override
  List<Object?> get props => <Object?>[
    reusedPasswords,
    expiredItems,
    expiringSoonItems,
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
