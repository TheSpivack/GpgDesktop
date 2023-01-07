import 'package:flutter/material.dart';
import 'package:gpg_wrapper/gpg_wrapper.dart';
import 'package:path_provider/path_provider.dart';

import 'pages/keyring.dart';
import 'pages/notepad.dart';
import 'widgets/console_log.dart';

class ApplicationWrapper extends StatefulWidget {
  const ApplicationWrapper({super.key});

  @override
  State<StatefulWidget> createState() => _ApplicationWrapperState();
}

class _ApplicationWrapperState extends State<ApplicationWrapper> {
  late NotepadPage _notepadPage;
  late KeyRingPage _keyringPage;

  late GpgService _gpgService;
  GpgResponse? _lastGpgResponse;

  int _selectedIndex = 0;
  late Widget _selectedPage;

  @override
  void initState() {
    super.initState();
    _gpgService = GpgService(gpgResponseHandler: (gpgOut) => setState(() => _lastGpgResponse = gpgOut));
    _gpgService.getKeyRing();
    getTemporaryDirectory().then((dir) => _gpgService.tempPath = dir.path);

    _notepadPage = NotepadPage(gpgService: _gpgService);
    _keyringPage = KeyRingPage(gpgService: _gpgService);

    _selectedPage = _keyringPage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
            children: [
              NavigationRail(
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.selected,
                  onDestinationSelected: (index) => setState(() {
                    _selectedIndex = index;
                    switch (_selectedIndex) {
                      case 0:
                        _selectedPage = _keyringPage;
                        break;
                      case 1:
                        _selectedPage = _notepadPage;
                        break;
                    }
                  }),
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                        icon: Icon(Icons.key_outlined),
                        selectedIcon: Icon(Icons.key),
                        label: Text("Key Ring")
                    ),
                    NavigationRailDestination(
                        icon: Icon(Icons.note_alt_outlined),
                        selectedIcon: Icon(Icons.note_alt),
                        label: Text("Notepad")
                    )
                  ]
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                  child: Column(
                      children: [
                        Expanded(child: _selectedPage),
                        ConsoleLog(gpgResponse: _lastGpgResponse),
                      ]
                  )
              )
            ])
    );
  }
}