import '../gpg_wrapper.dart';

//http://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;a=blob_plain;f=doc/DETAILS
class GpgEnumParsers {
  static StalenessReason? stalenessReason(String value) {
    switch (value) {
      case "":
        return null;
      case "o":
        return StalenessReason.old;
      case "t":
        return StalenessReason.differentTrustModel;
      default:
        throw GpgParserException("Unknown stalenessReason: $value");
    }
  }

  static TrustModel trustModel(String value) {
    switch (value) {
      case "0":
        return TrustModel.classic;
      case "1":
        return TrustModel.pgp;
      default:
        throw GpgParserException("Unknown trustModel: $value");
    }
  }

  static KeyValidity keyValidity(String value) {
    var val = value.isEmpty ? 'o' : value[0];
    switch(val) {
      case 'o':
        return KeyValidity.unknown;
      case 'i':
        return KeyValidity.invalid;
      case 'd':
        return KeyValidity.disabled;
      case 'r':
        return KeyValidity.revoked;
      case 'e':
        return KeyValidity.expired;
      case '-':
        return KeyValidity.unknownValidity;
      case 'q':
        return KeyValidity.undefined;
      case 'n':
        return KeyValidity.notValid;
      case 'm':
        return KeyValidity.marginalValid;
      case 'f':
        return KeyValidity.fullyValid;
      case 'u':
        return KeyValidity.ultimatelyValid;
      case 'w':
        return KeyValidity.hasWellKnownPrivatePart;
      case 's':
        return KeyValidity.specialValidity;
      default:
        throw GpgParserException("Unknown keyValidity: $value");
    }
  }

  static PublicKeyAlgorithm publicKeyAlgorithm(String value) {
    switch (value) {
      case "0":
        return PublicKeyAlgorithm.rsaEncryptOrSign;
      case "1":
        return PublicKeyAlgorithm.rsaEncrypt;
      case "2":
        return PublicKeyAlgorithm.rsaSign;
      case "3":
        return PublicKeyAlgorithm.elgamal;
      case "4":
        return PublicKeyAlgorithm.dsa;
      default:
        throw GpgParserException("Unknown publicKeyAlgorithm: $value");
    }
  }

  /// Parse the string to get the list of key capabilities.  If shouldGetUsable is true, it will look for 
  /// usable capabilities (i.e. where letter indicators are capital.  READ THE DOC REFERENCED AT TOP
  static List<KeyCapability>? keyCapabilities(String value, {bool shouldGetUsable = false}) {
    var regex = !shouldGetUsable
        ? RegExp("[escartg\\?]")
        : RegExp("[ESCARTG]");
    
    var caps = regex.allMatches(value);
    if(caps.isEmpty) {
      return null;
    }
    
    var parsedCaps = <KeyCapability>[];
    for (var cap in caps) {
      switch (cap.group(0)!.toLowerCase()) {
        case "e":
          parsedCaps.add(KeyCapability.encrypt);
          break;
        case "s":
          parsedCaps.add(KeyCapability.sign);
          break;
        case "c":
          parsedCaps.add(KeyCapability.certify);
          break;
        case "a":
          parsedCaps.add(KeyCapability.authentication);
          break;
        case "r":
          parsedCaps.add(KeyCapability.restrictedEncryption);
          break;
        case "t":
          parsedCaps.add(KeyCapability.timestamping);
          break;
        case "g":
          parsedCaps.add(KeyCapability.groupKey);
          break;
        case "?":
          parsedCaps.add(KeyCapability.unknown);
          break;
      }
    }
    return parsedCaps;
  }

  static List<ComplianceFlag>? complianceFlags(String value) {
    if(value.isEmpty) {
      return null;
    }

    var ret = <ComplianceFlag>[];
    value.split(" ").forEach((val) {
      switch(val.trim()) {
        case "8":
          ret.add(ComplianceFlag.rfc4880);
          break;
        case "23":
          ret.add(ComplianceFlag.deVs);
          break;
        case "6001":
          ret.add(ComplianceFlag.rocaVulnerable);
          break;
        default:
          throw GpgParserException("Unknown complianceFlag: $val");
      }
    });

    if(ret.isEmpty) {
      return null;
    }
    return ret;
  }
}