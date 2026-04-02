import 'package:open_filex/open_filex.dart';

class FileLauncherService {
  Future<void> openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }
}
