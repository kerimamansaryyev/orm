import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

DatabaseFactory appDataBaseFactory() {
  return databaseFactoryWeb;
}

Future<String> getAppDbPath() {
  return SynchronousFuture('web_storage');
}
