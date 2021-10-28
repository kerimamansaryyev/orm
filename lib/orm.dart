library orm;
import 'package:sembast/timestamp.dart';
import 'package:orm/models/database.dart';
export 'package:orm/models/database.dart' hide kCreatedTimeStampField;

abstract class Orm<PKeyType>{

  Map<String,dynamic> jSON;
  String get primaryKeyField;
  
  PKeyType get primaryKey => jSON[primaryKeyField] as PKeyType;

  bool operator ==(other) {
    return (other is Orm && other.hashCode == this.hashCode);
  }
  int get hashCode => primaryKey.hashCode;

  @override
  String toString() {
    return jSON.toString();
  }

  Orm(this.jSON);

}

mixin CopyAbleMixin<T>{
  T get copy;
}

abstract class CreationTime<PKeyType> implements Orm<PKeyType>{
  Timestamp? get createdAt => jSON[kCreatedTimeStampField];
}