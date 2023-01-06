import 'dart:convert';

import 'package:gpg_wrapper/gpg_wrapper.dart';

//http://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=blob_plain;f=doc/DETAILS
class GpgOutputParsers {
  static KeyRing? listPublicKeys(GpgResponse gpgOut) {
    if (gpgOut.standardOut == null || gpgOut.standardOut!.trim().isEmpty) {
      return null;
    }

    var keyRing = KeyRing();
    PublicKeyInfo? currentPrimaryKey;
    PublicKeyInfo? currentSubKey;
    LineSplitter().convert(gpgOut.standardOut!).forEach((line) {
      var lineParts = line.split(':');
      var recordType = lineParts[0];
      switch (recordType) {
        case "tru":
          keyRing.trustDatabase = TrustDatabase.parse(lineParts);
          return;
        case "pub":
          if(currentPrimaryKey != null) {
            if(currentSubKey != null) {
              currentPrimaryKey!.subKeys ??= <PublicKeyInfo>[];
              currentPrimaryKey!.subKeys!.add(currentSubKey!);
            }
            keyRing.publicKeys.add(currentPrimaryKey!);
          }
          currentPrimaryKey = PublicKeyInfo.parse(lineParts);
          currentSubKey = null;
          return;
        case "fpr":
          if(currentPrimaryKey == null) {
            throw GpgParserException("Read <fpr> record before a <pub> record");
          }
          if(currentSubKey != null) {
            currentSubKey!.fingerprint = lineParts[9];
          } else {
            currentPrimaryKey!.fingerprint = lineParts[9];
          }
          return;
        case "grp":
          if(currentPrimaryKey == null) {
            throw GpgParserException("Read <grp> record before a <pub> record");
          }
          if(currentSubKey != null) {
            currentSubKey!.keyGrip = lineParts[9];
          } else {
            currentPrimaryKey!.keyGrip = lineParts[9];
          }
          return;
        case "uid":
          if(currentPrimaryKey == null) {
            throw GpgParserException("Read <uid> record before a <pub> record");
          }
          currentPrimaryKey!.userId = UserId.parse(lineParts);
          return;
        case "sub":
          if(currentPrimaryKey == null) {
            throw GpgParserException("Read <sub> record before a <pub> record");
          }
          if(currentSubKey != null) {
            currentPrimaryKey!.subKeys ??= <PublicKeyInfo>[];
            currentPrimaryKey!.subKeys!.add(currentSubKey!);
          }
          currentSubKey = PublicKeyInfo.parse(lineParts);
          return;
      }
    });

    if(currentPrimaryKey != null) {
      keyRing.publicKeys.add(currentPrimaryKey!);
    }

    return keyRing;
  }
}