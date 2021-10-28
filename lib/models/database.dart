import 'package:orm/models/dao.dart';
import 'package:orm/orm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/timestamp.dart';
import 'package:sembast/utils/value_utils.dart';
const kCreatedTimeStampField = 'created_at';

typedef ConstructorDelegate<T extends Orm> = T Function(Map<String, dynamic> data);
typedef TransactionDelegate = Future<void> Function(Transaction transaction); 
typedef FilterOrmDelegate = bool Function(Map<String, dynamic> data);

class OrmDataBase<T extends Orm> implements OrmDao<T>{

  
  OrmDataBase({
    required this.name, 
    required this.constructorDelegate
  });

  final String name;
  final ConstructorDelegate<T> constructorDelegate;
  StoreRef get _getTable => intMapStoreFactory.store(name);
  
  @override
  Future<void> apply(List<T> records, {bool withTimeStamp = false}) {
    var store = _getTable;
    return _makeTransaction(
      (trans)async{
         for( int i=0; i<records.length;i++ ){
             var innerData = {...records[i].jSON};
             if(withTimeStamp && innerData[kCreatedTimeStampField] == null)
               innerData[kCreatedTimeStampField] = Timestamp.fromDateTime(DateTime.now());  
             var postKey = await store.findFirst( trans, finder: Finder( filter: Filter.equals(records[i].primaryKeyField, records[i].primaryKey)));
             if( postKey == null )  await store.add(trans, innerData);
             else await store.update(trans, innerData,finder:Finder( filter: Filter.equals(records[i].primaryKeyField, records[i].primaryKey)));
          }
      }
    );
  }

  @override
  Future<void> delete(List<T> records) {
    var store = _getTable;
    return _makeTransaction(
      (trans)async{
          for( int i=0; i<records.length;i++ ){
             var postKey = await store.findFirst( trans, finder: Finder( filter: Filter.equals(records[i].primaryKeyField, records[i].primaryKey)));
             if( postKey != null )  await store.record(postKey.key).delete(trans);
          }
      }
    );
  }

  @override
  Future<List<T>> read({int? offset, int? limit, FilterOrmDelegate? filter, bool getAll = false})async{
    var store = _getTable;
      var finder = Finder(
        offset: offset,
        limit: limit,
        filter: _applyIfNotNull(filter)
      );

      var list = await store.find(_database, finder: getAll? null:finder);
      return list.map<T>((item) => constructorDelegate(cloneMap(item.value))).toList();
  }

  @override
  Future<T?> getByKey<PKeyType>(String fieldName, PKeyType key)async{
     var store = _getTable;
     var item = await store.findFirst(_database, finder: Finder( filter: Filter.equals(fieldName, key)));
     return item == null? null: constructorDelegate(cloneMap(item.value));
  }

  @override
  Future<void> clear(){
    var store = _getTable;
    return store.delete(_database);
  }

  static Future<String> get _localPath async => (await getApplicationDocumentsDirectory()).path;

  static Filter? _applyIfNotNull(FilterOrmDelegate? filter){
    return filter == null? null: Filter.custom((record) => filter(record.value));
  }

  static Future<void> _makeTransaction( TransactionDelegate action )async{
    await _database.transaction(action);
  }

  static Future<Database> _launch() async{
     String nameOfDataBase = 'ormDb';
     String path = await _localPath;
     DatabaseFactory postFactory = databaseFactoryIo;
     return postFactory.openDatabase('$path/$nameOfDataBase');
  }

  static late final Database _database;

  static Future<void> init()async{
    _database = await _launch();
  }

} 