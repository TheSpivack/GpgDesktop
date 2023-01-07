import 'package:flutter/material.dart';
import 'package:gpg_wrapper/gpg_wrapper.dart';
import 'package:resizable_widget/resizable_widget.dart';

class KeyRingPage extends StatefulWidget {
  const KeyRingPage({
    super.key,
    required this.gpgService
  });

  final GpgService gpgService;

  @override
  State<KeyRingPage> createState() => _KeyRingPageState();
}

class _KeyRingPageState extends State<KeyRingPage> {
  late TextEditingController _outputController;
  late GpgService gpgService = widget.gpgService;

  @override
  void initState() {
    super.initState();
    _outputController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return ResizableWidget(
        isHorizontalSeparator: false,
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<KeyRing?>(
                  future: widget.gpgService.getKeyRing(),
                  builder: (BuildContext context, AsyncSnapshot<KeyRing?> snapshot) {
                    if(snapshot.hasData) {
                      final pubKeys = snapshot.data!.publicKeys.toList();
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: pubKeys.length,
                          itemBuilder: (ctx, index) {
                            return Card(
                                child: ListTile(
                                    title: Text(snapshot.data!.publicKeys[index].userId.userId)
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
    );
  }
}