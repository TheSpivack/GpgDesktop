import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gpg_wrapper/gpg_wrapper.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../widgets/key_selector.dart';

class NotepadPage extends StatefulWidget {
  const NotepadPage({
    super.key,
    required this.gpgService
  });

  final GpgService gpgService;

  @override
  State<NotepadPage> createState() => _NotepadPageState();
}

class _NotepadPageState extends State<NotepadPage> {
  final RegExp _regexPublicKey = RegExp("-----BEGIN PGP PUBLIC KEY BLOCK-----.*-----END PGP PUBLIC KEY BLOCK-----", dotAll: true);
  final RegExp _regexMessage = RegExp("-----BEGIN PGP MESSAGE-----.*-----END PGP MESSAGE-----", dotAll: true);
  final RegExp _regexSigned = RegExp("-----BEGIN PGP SIGNED MESSAGE-----(.*)-----BEGIN PGP SIGNATURE-----.*-----END PGP SIGNATURE-----", dotAll: true);

  late GpgService gpgService = widget.gpgService;
  late TextEditingController _inputController;
  late TextEditingController _outputController;
  List<PublicKeyInfo> _selectedEncryptKeys = <PublicKeyInfo>[];
  List<PublicKeyInfo> _selectedSignKeys = <PublicKeyInfo>[];

  bool _canEncrypt = false;
  bool _canDecrypt = false;
  bool _canSign = false;
  bool _canVerify = false;
  bool _canImport = false;

  void _toggleButtonStates() =>
      setState(() {
        _canEncrypt = _inputController.text.isNotEmpty && _selectedEncryptKeys.isNotEmpty;
        _canDecrypt = _regexMessage.hasMatch(_inputController.text);
        _canSign = _inputController.text.isNotEmpty && _selectedSignKeys.isNotEmpty;
        _canVerify = _regexSigned.hasMatch(_inputController.text);
        _canImport = _regexPublicKey.hasMatch(_inputController.text);
      });

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _outputController = TextEditingController();

    _inputController.addListener(_toggleButtonStates);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                      spacing: 16,
                      alignment: WrapAlignment.start,
                      children: [
                        ElevatedButton(
                            onPressed: _canEncrypt
                                ? encrypt
                                : null,
                            child: const Text("Encrypt")
                        ),
                        ElevatedButton(
                            onPressed: _canDecrypt
                                ? decrypt
                                : null,
                            child: const Text("Decrypt")
                        ),
                        const VerticalDivider(),
                        ElevatedButton(
                            onPressed: _canSign
                                ? sign
                                : null,
                            child: const Text("Sign")
                        ),
                        ElevatedButton(
                            onPressed: _canVerify
                                ? verify
                                : null,
                            child: const Text("Verify")
                        ),
                        /*const VerticalDivider(),
                        ElevatedButton(
                            onPressed: _canSign && _canEncrypt
                                ? signEncrypt
                                : null,
                            child: const Text("Sign + Encrypt")
                        ),*/
                        const VerticalDivider(),
                        ElevatedButton(
                            onPressed: _canImport
                                ? import
                                : null,
                            child: const Text("Import Key")
                        )
                      ]))),
          Expanded(
              child: ResizableWidget(
                  isHorizontalSeparator: false,
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            autofocus: true,
                            autocorrect: false,
                            controller: _inputController,
                            style: const TextStyle(fontSize: 11)
                        )
                    ),
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                            expands: true,
                            readOnly: true,
                            minLines: null,
                            maxLines: null,
                            controller: _outputController,
                            style: const TextStyle(fontSize: 11)
                        )
                    )
                  ]
              )
          ),
          Wrap(
            spacing: 0,
            children: [
              KeySelector(
                  label: "Encrypt For",
                  gpgService: gpgService,
                  onSelectionChanged: (keys) {
                    _selectedEncryptKeys = keys;
                    _toggleButtonStates();
                  }),
              KeySelector(
                  label: "Sign With",
                  gpgService: gpgService,
                  singleOnly: true,
                  privateOnly: true,
                  onSelectionChanged: (keys) {
                    _selectedSignKeys = keys;
                    _toggleButtonStates();
                  })
            ],
          )
        ]);
  }

  void decrypt() async {
    var decryptedMessage = await gpgService.decryptMessage(_regexMessage.firstMatch(_inputController.text)!.group(0).toString());
    setState(() {
      _outputController.text =
          decryptedMessage.standardOut ?? "<NO VALUE FOUND>";
    });
  }

  void encrypt() async {
    var encryptedMessage = await gpgService.encryptMessage(_selectedEncryptKeys, _inputController.text);
    setState(() {
      _outputController.text = encryptedMessage.standardOut ?? "";
    });
  }

  void sign() async {
    var signedMessage = await gpgService.signMessage(_selectedSignKeys.first, _inputController.text);
    setState(() {
      _outputController.text = signedMessage.standardOut ?? "";
    });
  }

  void verify() async {
    var verifiedMessage = await gpgService.verifyMessage(_regexSigned.firstMatch(_inputController.text)!.group(0).toString());
    var outputMessage =  verifiedMessage.standardError?.contains("Good signature from") == true
      ? LineSplitter.split(_regexSigned.firstMatch(_inputController.text)!.group(1).toString().trim()).toList().sublist(1).join("\n") //good signature. Show the unwrapped message in the output
      : "INVALID SIGNATURE - DO NOT TRUST!!";

    setState(() {
      _outputController.text = outputMessage;
    });
  }

  void signEncrypt() async {

  }

  void import() async {
    var response = await gpgService.importKey(publicKeyContents: _regexPublicKey.firstMatch(_inputController.text)!.group(0).toString());
    setState(() {
      _outputController.text = response.exitCode == 0 ? "Public key successfully imported" : "ERROR IMPORTING PUBLIC KEY";
    });
  }
}
