import 'dart:convert';
import 'dart:io';

import 'package:gpg_wrapper/gpg_wrapper.dart';
import 'package:gpg_wrapper/src/gpg_output_parsers.dart';
import 'package:gpg_wrapper/src/model/keyring.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class GpgParserException implements Exception {
  GpgParserException(this.message);

  /// Error message explaining the parser error.
  String message;
}

class GpgResponse {
  GpgResponse({
      this.command = "",
      this.exitCode = 0,
      this.standardOut,
      this.standardError,
      DateTime? startTime,
      DateTime? exitTime
  }) : startTime = startTime ?? DateTime.fromMillisecondsSinceEpoch(0).subtract(Duration(days: 100000000)),
       exitTime = exitTime  ?? DateTime.fromMillisecondsSinceEpoch(0) .add(Duration(days: 100000000));

  /// The command line command that was run
  String command;

  /// The exit code of the gpg command
  int exitCode;

  /// Output that was written to stdout
  String? standardOut;

  /// Output that was written to stderr
  String? standardError;

  /// DateTime the gpg command started running
  DateTime startTime;

  /// DateTime the gpg command exited
  DateTime exitTime;
}

class ParsedGpgResponse<T> extends GpgResponse {
  ParsedGpgResponse({
      super.command,
      super.exitCode,
      super.standardOut,
      super.standardError,
      super.startTime,
      super.exitTime,
      required this.parsedOutput
  });

  ParsedGpgResponse.copy({
    required GpgResponse response,
    required this.parsedOutput
  }) : super(
    command: response.command,
    exitCode: response.exitCode,
    standardOut: response.standardOut,
    standardError: response.standardError,
    startTime: response.startTime,
    exitTime: response.exitTime
  );

  /// The response object that was parsed from the command output
  T parsedOutput;

  @override
  String toString() {
    return "$command\n${standardOut ?? ""}\n${standardError ?? ""}".trim();
  }
}

class GpgService {
  GpgService({
    this.tempPath = ".",
    this.stdOutHandler,
    this.stdErrHandler,
    this.gpgResponseHandler
  });

  String tempPath;
  void Function(String)? stdOutHandler;
  void Function(String)? stdErrHandler;
  void Function(GpgResponse)? gpgResponseHandler;

  KeyRing? _keyRing;

  /// Loads the keyring using listPublicKeys() and save it in memory and gets that
  Future<KeyRing?> getKeyRing({bool reloadCache = false}) async {
    if(reloadCache || _keyRing == null) {
      _keyRing = (await listPublicKeys()).parsedOutput;
    }
    return _keyRing;
  }

  Future<ParsedGpgResponse<KeyRing?>> listPublicKeys() async {
    var gpgOut = await gpg(["--list-keys","--fingerprint","--fingerprint","--with-secret","--with-colons"]);
    return ParsedGpgResponse<KeyRing?>.copy(response: gpgOut, parsedOutput: GpgOutputParsers.listPublicKeys(gpgOut));
  }

  Future<GpgResponse> importKey({String? publicKeyContents, String? publicKeyFile}) async {
    if(publicKeyContents == null && publicKeyFile == null) {
      throw GpgWrapperException("Either publicKeyContents or publicKeyFile must be specified");
    }

    return await gpg(["--import"], inputString: publicKeyContents, inputFile: publicKeyFile);
  }

  Future<GpgResponse> decryptMessage(String message) async {
    return await gpg(["--decrypt"], inputString: message);
  }

  Future<GpgResponse> decryptFile(String filePath) async {
    return await gpg(["--decrypt"], inputFile: filePath);
  }

  Future<GpgResponse> encryptMessage(List<PublicKeyInfo> recipients,String message,{bool shouldArmor = true}) async {
    var arguments = ["--encrypt","--trust-model","always","--output","-"];
    for(var recipient in recipients) {
      arguments.addAll(["--recipient", recipient.userId.userId]);
    }
    if(shouldArmor) {
      arguments.insert(1, "--armor");
    }
    return await gpg(arguments, inputString: message);
  }

  Future<GpgResponse> signMessage(PublicKeyInfo signingKey, String message, {bool shouldArmor = true, bool shouldClearSign = true}) async {
    var arguments = [shouldClearSign ? "--clearsign" : "--sign","--local-user", signingKey.userId.userId, "--output","-"];
    if(shouldArmor) {
      arguments.insert(1, "--armor");
    }
    return await gpg(arguments, inputString: message);
  }

  Future<GpgResponse> signAndEncryptMessage(PublicKeyInfo signingKey, List<PublicKeyInfo> recipients, String message,{bool shouldArmor = true}) async {
    var arguments = ["--encrypt","--trust-model","always","--local-user", signingKey.userId.userId, "--output","-"];
    for(var recipient in recipients) {
    arguments.addAll(["--recipient", recipient.userId.userId]);
    }
    if(shouldArmor) {
    arguments.insert(1, "--armor");
    }
    return await gpg(arguments, inputString: message);
  }

  Future<GpgResponse> verifyMessage(String message) async {
    return await gpg(["--verify"], inputString: message);
  }


  Future<GpgResponse> gpg(List<String> arguments, {String? inputString, String? inputFile}) async {
    if(inputString != null && inputFile != null) {
      throw GpgWrapperException("Only one of inputString and inputFile can be specified.");
    }

    var startTime = DateTime.now();
    var stdOut = StringBuffer();
    var stdErr = StringBuffer();

    File? tempFile;
    if(inputString != null) {
      tempFile = await _tempFile;
      await tempFile.writeAsString(inputString, flush: true);
    }

    if(inputFile != null) {
      arguments.add(inputFile);
    } else if (tempFile != null) {
      arguments.add(tempFile.path);
    }

    var process = await Process.start("gpg", arguments);
    process.stdout
        .transform(utf8.decoder)
        .forEach((out) {
          stdOut.write(out);
          if (stdOutHandler != null) {
            stdOutHandler!(out);
          }
        });
    process.stderr
        .transform(utf8.decoder)
        .forEach((err) {
          stdErr.write(err);
          if (stdErrHandler != null) {
            stdErrHandler!(err);
          }
        });

    var exitCode = await process.exitCode;
    var exitTime = DateTime.now();

    if(tempFile != null) {
      await tempFile.delete();
      arguments.removeLast();//remove it so it's not included in the command reponse
    }

    var response = GpgResponse(
        command: "gpg ${arguments.map((arg) => RegExp("\\s").hasMatch(arg) ? "\"$arg\"" : arg ).join(' ')}",
        exitCode: exitCode,
        standardOut: stdOut.toString(),
        standardError: stdErr.toString(),
        startTime: startTime,
        exitTime: exitTime
    );

    if(gpgResponseHandler != null) {
      gpgResponseHandler!(response);
    }

    return response;
  }

  Future<File> get _tempFile async {
    final dateFormat = DateFormat("yyyyMMddHHmmssSSSS");
    return File(path.join(tempPath,"gpg_wrapper_${dateFormat.format(DateTime.now())}.asc"));
  }
}

class GpgWrapperException implements Exception {
  GpgWrapperException(this.message);

  /// Error message explaining the wrapper error.
  String message;
}
