import 'package:sembast/sembast.dart';

DatabaseFactory appDataBaseFactory() {
  throw UnimplementedError('OrmDatabase has no factory for current platform');
}

Future<String> getAppDbPath() {
  throw UnimplementedError(
      'OrmDatabase has no database path for current platform');
}
