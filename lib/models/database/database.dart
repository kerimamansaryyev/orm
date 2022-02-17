import 'package:orm/models/dao.dart';
import 'package:orm/orm.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/timestamp.dart';
import 'package:sembast/utils/value_utils.dart';
import 'stub.dart'
    if (dart.library.io) 'mobile.dart'
    if (dart.library.html) 'web.dart';

const kCreatedTimeStampField = 'created_at';

typedef ConstructorDelegate<T extends Orm> = T Function(
    Map<String, dynamic> data);
typedef TransactionDelegate = Future<void> Function(Transaction transaction);

class OrmDataBase<T extends Orm> implements OrmDao<T> {
  OrmDataBase({required this.name, required this.constructorDelegate});

  final String name;
  final ConstructorDelegate<T> constructorDelegate;
  StoreRef get _getTable => intMapStoreFactory.store(name);

  @override
  Future<void> apply(List<T> records, {bool withTimeStamp = false}) {
    var store = _getTable;
    return _makeTransaction((trans) async {
      for (int i = 0; i < records.length; i++) {
        var innerData = {...records[i].jSON};
        if (withTimeStamp && innerData[kCreatedTimeStampField] == null)
          innerData[kCreatedTimeStampField] =
              Timestamp.fromDateTime(DateTime.now());
        var postKey = await store.findFirst(trans,
            finder: Finder(
                filter: Filter.equals(
                    records[i].primaryKeyField, records[i].primaryKey)));
        if (postKey == null)
          await store.add(trans, innerData);
        else
          await store.update(trans, innerData,
              finder: Finder(
                  filter: Filter.equals(
                      records[i].primaryKeyField, records[i].primaryKey)));
      }
    });
  }

  Future<void> deleteWhere({Filter? filter}) {
    var store = _getTable;
    return _makeTransaction((trans) async {
      await store.delete(trans, finder: Finder(filter: filter));
    });
  }

  @override
  Future<void> delete(List<T> records) {
    var store = _getTable;
    return _makeTransaction((trans) async {
      for (int i = 0; i < records.length; i++) {
        var postKey = await store.findFirst(trans,
            finder: Finder(
                filter: Filter.equals(
                    records[i].primaryKeyField, records[i].primaryKey)));
        if (postKey != null) await store.record(postKey.key).delete(trans);
      }
    });
  }

  @override
  Future<List<T>> read(
      {int? offset, int? limit, Filter? filter, bool getAll = false}) async {
    var store = _getTable;
    var finder = Finder(
        offset: getAll ? null : offset,
        limit: getAll ? null : limit,
        filter: filter);

    var list = await store.find(_database!, finder: finder);
    return list
        .map<T>((item) => constructorDelegate(cloneMap(item.value)))
        .toList();
  }

  @override
  Future<T?> getByKey<PKeyType>(String fieldName, PKeyType key) async {
    var store = _getTable;
    var item = await store.findFirst(_database!,
        finder: Finder(filter: Filter.equals(fieldName, key)));
    return item == null ? null : constructorDelegate(cloneMap(item.value));
  }

  @override
  Future<void> clear() {
    var store = _getTable;
    return store.delete(_database!);
  }

  static Future<String> get _localPath => getAppDbPath();

  static Future<void> _makeTransaction(TransactionDelegate action) async {
    await _database!.transaction(action);
  }

  static Future<Database> _launch() async {
    String nameOfDataBase = 'ormDb';
    String path = await _localPath;
    DatabaseFactory postFactory = appDataBaseFactory();
    return postFactory.openDatabase('$path/$nameOfDataBase');
  }

  static Database? _database;

  static Future<void> init() async {
    await _database?.close();
    _database = null;
    _database = await _launch();
  }
}
