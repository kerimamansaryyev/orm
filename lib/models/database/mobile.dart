import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

DatabaseFactory appDataBaseFactory() {
  return databaseFactoryIo;
}

Future<String> getAppDbPath() async {
  return (await getApplicationDocumentsDirectory()).path;
}
