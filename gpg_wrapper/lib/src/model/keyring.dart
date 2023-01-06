import 'dart:core';

import 'package:gpg_wrapper/src/gpg_enum_parsers.dart';
import 'package:gpg_wrapper/src/model/trustdb.dart';

class KeyRing {
  KeyRing({
    List<PublicKeyInfo>? publicKeys,
    TrustDatabase? trustDatabase
  }) : publicKeys = publicKeys ?? <PublicKeyInfo>[],
       trustDatabase = trustDatabase ?? TrustDatabase();

  /// All the public keys available in this keyring.
  List<PublicKeyInfo> publicKeys;

  /// The trust database record for this keyring.
  TrustDatabase trustDatabase;
}

class PublicKeyInfo {
  PublicKeyInfo({
    this.validity = KeyValidity.unknown,
    this.length = 0,
    this.publicKeyAlgorithm = PublicKeyAlgorithm.rsaEncryptOrSign,
    BigInt? keyId,
    DateTime? dateCreated,
    this.dateWillExpire,
    this.ownerTrust,
    List<KeyCapability>? keyCapabilities,
    this.usableCapabilities,
    this.hasSecretKey = false,
    this.curveName,
    List<ComplianceFlag>? complianceFlags,
    this.dateLastUpdated,
    this.originIndex = 0,
    this.originUrl,
    this.fingerprint,
    this.keyGrip,
    UserId? userId,
    this.subKeys
  }) : keyId = keyId ?? BigInt.zero,
       dateCreated = dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0).subtract(Duration(days: 100000000)),
       keyCapabilities = keyCapabilities ?? <KeyCapability>[],
       complianceFlags = complianceFlags ?? <ComplianceFlag>[],
       userId = userId ?? UserId();

  PublicKeyInfo.parse(List<String> lineParts) : this(
    validity: GpgEnumParsers.keyValidity(lineParts[1]),
    length: int.parse(lineParts[2]),
    publicKeyAlgorithm: GpgEnumParsers.publicKeyAlgorithm(lineParts[3]),
    keyId: BigInt.parse(lineParts[4], radix: 16),
    dateCreated: DateTime.fromMillisecondsSinceEpoch(int.parse(lineParts[5]) * 1000),
    dateWillExpire: lineParts[6].isEmpty
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.parse(lineParts[6]) * 1000),
    ownerTrust: lineParts[7], 
    keyCapabilities: GpgEnumParsers.keyCapabilities(lineParts[11], shouldGetUsable: false),
    usableCapabilities: GpgEnumParsers.keyCapabilities(lineParts[11], shouldGetUsable: true),
    hasSecretKey: lineParts[14] == "+",
    curveName: lineParts[16].isEmpty
        ? null
        : lineParts[16],
    complianceFlags: GpgEnumParsers.complianceFlags(lineParts[17]),
    dateLastUpdated: lineParts[18].isEmpty
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.parse(lineParts[18]) * 1000)
  );

  /// The computed validity of a key. If given for a key record it describes the validity taken from the best rated user ID.
  KeyValidity validity;

  /// The length of key in bits
  int length;

  /// Public Key Algorithm
  PublicKeyAlgorithm publicKeyAlgorithm;

  /// This is the 64 bit keyid as specified by OpenPGP and the last 64 bit of the SHA-1 fingerprint of an X.509 certifciate.
  BigInt keyId;

  /// The creation date of the key is given in UTC.
  DateTime dateCreated;

  /// Key expiration date or empty if it does not expire.
  DateTime? dateWillExpire;

  /// This is a single letter, but be prepared that additional information may follow in future versions. Only present on primary keys.
  String? ownerTrust;

  /// Capabilities of this key
  List<KeyCapability> keyCapabilities;

  /// Usable capabilities of the entire key. Only present on primary keys.
  List<KeyCapability>? usableCapabilities;

  /// True if the secret key for this key is available
  bool hasSecretKey;

  /// The ECC curve name
  String? curveName;

  /// Asserted compliance modes and screening result for this key.
  List<ComplianceFlag> complianceFlags;

  /// The timestamp of the last update of the key.
  DateTime? dateLastUpdated;

  /// The origin of the key
  int originIndex;

  /// The origin URL of the key
  String? originUrl;

  /// The fingerprint of the key
  String? fingerprint;

  /// The KeyGrip of the key
  String? keyGrip;

  /// The user id of this key
  UserId userId;

  /// The subkeys of this primary key.  Null if this is a sub-key
  List<PublicKeyInfo>? subKeys;

  /// The hex encoded value of the keyId
  @override
  String toString() {
    return keyId.toRadixString(16);
  }
}

class UserId
{
  UserId({
    this.validity = KeyValidity.unknown,
    DateTime? dateCreated,
    this.userIdHash = "",
    this.userId = "",
    this.originIndex = 0,
    this.originUrl
  }) : dateCreated = dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0).subtract(Duration(days: 100000000));

  UserId.parse(List<String> lineParts) : this(
    validity: GpgEnumParsers.keyValidity(lineParts[1]),
    dateCreated: DateTime.fromMillisecondsSinceEpoch(int.parse(lineParts[5]) * 1000),
    userIdHash: lineParts[7],
    userId: lineParts[9].replaceAll("\\x3a", ":"),
    originIndex: int.parse(lineParts[19].split(" ")[0])
  );

  /// If the validity information is given for a UID or UAT record, it describes the validity calculated based on this user ID
  KeyValidity validity;

  /// For UID and UAT records, this is used for the self-signature date
  DateTime dateCreated;

  /// This is a hash of the userId contents used to represent that exact user ID.
  String userIdHash;

  /// Value of the user id
  String userId;

  /// The origin of the User ID
  int originIndex;

  /// The origin URL of the User ID
  String? originUrl;

  @override
  String toString() {
    return userId;
  }
}

enum PublicKeyAlgorithm {
  /// RSA (Encrypt or Sign)
  rsaEncryptOrSign,

  /// RSA Encrypt-Only
  rsaEncrypt,

  /// RSA Sign-Only
  rsaSign,

  /// Elgamal (Encrypt-Only)
  elgamal,

  /// Digital Signature Algorithm
  dsa
}

enum KeyValidity {
  /// Unknown (this key is new to the system)
  unknown,

  /// The key is invalid (e.g. due to a missing self-signature)
  invalid,

  /// The key has been disabled
  /// (deprecated - use the 'D' in field 12 instead)
  disabled,

  /// The key has been revoked
  revoked,

  /// The key has expired
  expired,

  /// Unknown validity (i.e. no value assigned)
  unknownValidity,

  /// Undefined validity.  '-' and 'q' (<see cref="UnknownValidity"/>) may safely be treated as the same value for most purposes
  undefined,

  /// The key is not valid
  notValid,

  /// The key is marginal valid.
  marginalValid,

  /// The key is fully valid
  fullyValid,

  /// The key is ultimately valid.  This often means that the secret key is available, but any key may be marked as ultimately valid.
  ultimatelyValid,

  /// The key has a well known private part.
  hasWellKnownPrivatePart,

  /// The key has special validity.  This means that it might be self-signed and expected to be used in the STEED system.
  specialValidity,
}

enum KeyCapability
{
  encrypt,
  sign,
  certify,
  authentication,
  restrictedEncryption,
  timestamping,
  groupKey,
  unknown
}

enum ComplianceFlag
{
  /// The key is compliant with RFC4880bis
  rfc4880,

  /// The key is compliant with compliance mode "de-vs".
  deVs,

  /// Screening hit on the ROCA vulnerability.
  rocaVulnerable
}
