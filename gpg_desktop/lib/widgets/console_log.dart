import 'package:flutter/material.dart';
import 'package:gpg_wrapper/gpg_wrapper.dart';

class ConsoleLog extends StatelessWidget {
  const ConsoleLog({
    super.key,
    required this.gpgResponse
  });

  final GpgResponse? gpgResponse;

  @override
  Widget build(BuildContext context) {
    var color = Colors.white;
    if(gpgResponse != null) {
      color = gpgResponse!.exitCode != 0
          ? Colors.redAccent
          : RegExp("WARNING").hasMatch(gpgResponse!.standardError ?? "")
          ? Colors.yellowAccent
          : Colors.greenAccent;

    }

    return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        color: Colors.black,
        child: SelectionArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("> ${gpgResponse?.command ?? ""}"),
                  Text(gpgResponse?.standardError ?? "", style: TextStyle(color: color, fontSize: 12))
                ]
            )
        )
    );
  }
}