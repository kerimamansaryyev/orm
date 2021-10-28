import 'package:orm/orm.dart';

abstract class OrmDao<T extends Orm>{

  Future<void> apply(List<T> records);
  Future<void> delete(List<T> records);
  Future<List<T>> read();
  String get name;
  Future<T?> getByKey<PKeyType>(String fieldName,PKeyType key);
  Future<void> clear();

}