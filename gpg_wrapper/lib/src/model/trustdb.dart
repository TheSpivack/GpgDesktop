import '../gpg_enum_parsers.dart';

enum StalenessReason {
  /// Trustdb is old
  old,

  /// Trustdb was built with a different trust model than the one we are using now.
  differentTrustModel
}

enum TrustModel
{
  /// Classic trust model, as used in PGP 2.x.
  classic,

  /// PGP trust model, as used in PGP 6 and later. This is the same as the classic trust model,
  /// except for the addition of trust signatures.
  pgp
}

class TrustDatabase {
  TrustDatabase({
    this.stalenessReason,
    this.trustModel = TrustModel.pgp,
    DateTime? dateCreated,
    DateTime? dateWillExpire,
    this.marginalsNeeded = 0,
    this.completesNeeded = 0,
    this.maxCertDepth = 0
  }) : dateCreated = dateCreated ?? DateTime.fromMillisecondsSinceEpoch(0).subtract(Duration(days: 100000000)),
       dateWillExpire = dateWillExpire ?? DateTime.fromMillisecondsSinceEpoch(0).add(Duration(days: 100000000));

  TrustDatabase.parse(List<String> lineParts) : this(
    stalenessReason: GpgEnumParsers.stalenessReason(lineParts[1]),
    trustModel: GpgEnumParsers.trustModel(lineParts[2]),
    dateCreated: DateTime.fromMillisecondsSinceEpoch(int.parse(lineParts[3]) * 1000),
    dateWillExpire: lineParts[4].isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0).add(Duration(days: 100000000))
        : DateTime.fromMillisecondsSinceEpoch(int.parse(lineParts[4]) * 1000),
    marginalsNeeded: int.parse(lineParts[5]),
    completesNeeded: int.parse(lineParts[6]),
    maxCertDepth: int.parse(lineParts[7]));

  /// Reason for staleness of trust.  If this field is empty, then the trustdb is not stale.
  StalenessReason? stalenessReason;

  /// Trust model.  GnuPG before version 1.4 used the <see cref="TrustModels.Classic" /> trust model by default.
  /// GnuPG 1.4 and later uses the <see cref="TrustModels.PGP" /> trust model by default.
  TrustModel trustModel;

  /// Date trustdb was created
  DateTime dateCreated;

  /// Date trustdb will expire
  DateTime dateWillExpire;

  /// Number of marginally trusted users to introduce a new key signer (gpg's option --marginals-needed).
  int marginalsNeeded;

  /// Number of completely trusted users to introduce a new key signer.  (gpg's option --completes-needed)
  int completesNeeded;

  /// Maximum depth of a certification chain. (gpg's option --max-cert-depth)
  int maxCertDepth;
}