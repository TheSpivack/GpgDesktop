import 'package:flutter/material.dart';
import 'package:gpg_wrapper/gpg_wrapper.dart';

class KeySelector extends StatefulWidget {
  const KeySelector({
    super.key,
    required this.label,
    required this.onSelectionChanged,
    this.singleOnly = false,
    this.privateOnly = false,
    required this.gpgService
  });

  final String label;
  final void Function(List<PublicKeyInfo>) onSelectionChanged;
  final bool singleOnly;
  final bool privateOnly;
  final GpgService gpgService;

  @override
  State<KeySelector> createState() => _KeySelectorState();
}

class _KeySelectorState extends State<KeySelector> {
  List<PublicKeyInfo> _selectedKeys = <PublicKeyInfo>[];

  @override
  Widget build(BuildContext context) {
    final body = <Widget>[];
    body.add(TextButton(
        onPressed: widget.singleOnly && _selectedKeys.isNotEmpty
            ? null
            : () async {
          var result = await showDialog<List<PublicKeyInfo>>(
              context: context,
              builder: (context) => KeySelectorDialog(
                  gpgService: widget.gpgService,
                  selectedKeys: _selectedKeys,
                  onlyShowPrivate: widget.privateOnly
              ));

          if(result != null) {
            setState(() {
              _selectedKeys = result;
              widget.onSelectionChanged(_selectedKeys);
            });
          }
        },
        child: const Text("Select")
    ));

    body.addAll(_selectedKeys.map((key) => Chip(
      label: Text(key.userId.userId),
      onDeleted: () => setState(() {
        _selectedKeys.removeWhere((k) => key.keyId == k.keyId);
        widget.onSelectionChanged(_selectedKeys);
      }),
    )));

    return Container(
        margin: const EdgeInsets.fromLTRB(16,8,16,8),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
              labelText: widget.label,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4)
              )
          ),
          child: Wrap(
            spacing: 4,
            children: body,
          ),
        )
    );
  }
}

class KeySelectorDialog extends StatefulWidget {
  const KeySelectorDialog({
    super.key,
    required this.gpgService,
    required this.selectedKeys,
    this.onlyShowPrivate = false
  });

  final GpgService gpgService;
  final List<PublicKeyInfo> selectedKeys;
  final bool onlyShowPrivate;

  @override
  State<KeySelectorDialog> createState() => _KeySelectorDialogState();
}

class _KeySelectorDialogState extends State<KeySelectorDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
        elevation: 5,
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 1.2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                  child: FutureBuilder<KeyRing?>(
                      future: widget.gpgService.getKeyRing(),
                      builder: (BuildContext context, AsyncSnapshot<KeyRing?> snapshot) {
                        if(snapshot.hasData) {
                          final pubKeys = snapshot.data!.publicKeys.where((key) => key.hasSecretKey || !widget.onlyShowPrivate).toList();
                          return ListView.builder(
                              shrinkWrap: true,
                              itemCount: pubKeys.length,
                              itemBuilder: (ctx, index) {
                                return Card(
                                    child: ListTile(
                                        leading: Checkbox(
                                          value: widget.selectedKeys.any((key) => key.keyId == pubKeys[index].keyId),
                                          onChanged: (bool? value) => setState(() {
                                            if(value == true) {
                                              widget.selectedKeys.add(pubKeys.firstWhere((key) => key.keyId == pubKeys[index].keyId));
                                            }
                                            else {
                                              widget.selectedKeys.removeWhere((key) => key.keyId == pubKeys[index].keyId);
                                            }
                                          }),
                                        ),
                                        title: Text(pubKeys[index].userId.userId)
                                    ));
                              }
                          );
                        }
                        return const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(),
                        );
                      }
                  )
              ),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 16,
                    alignment: WrapAlignment.start,
                    children: [
                      ElevatedButton(
                          onPressed: () => {
                            Navigator.pop(context, widget.selectedKeys)
                          },
                          child: const Text("Select")
                      ),
                      TextButton(
                          onPressed: () => {
                            Navigator.pop(context)
                          },
                          child: const Text("Cancel")
                      )
                    ],
                  )
              )
            ],
          ),
        )
    );
  }
}