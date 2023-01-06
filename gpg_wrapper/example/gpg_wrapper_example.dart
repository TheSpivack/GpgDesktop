import 'package:gpg_wrapper/gpg_wrapper.dart';

void main() async {
  var response = await GpgService().listPublicKeys();
  print(response.command);
  print(response.standardError);
  print(response.standardOut);
  print(response.parsedOutput);
}
