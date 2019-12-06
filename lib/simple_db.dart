library simple_db;

import 'dart:io';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';

class Storage<T> {
  Storage(this.mapper, {this.dbName}){
    dbName = dbName ?? T.toString();
  }
  Mapper<T> mapper;
  String dbName;

  dynamic save(T data) async {
    Database db = await open();
    dynamic result;
    try{
      result = await db.put(mapper.toMap(data));
    }
    catch(e, s){
      print(e.toString());
      print(s.toString());
    }
    return result;
  }

  Future<List<T>> list() async {
    Database db = await open();
    List<Record> records = await db.findRecords(Finder());
    List<T> dataList = <T>[];

    for(Record r in records){
      r.value["id"] = r.key;
      T data = mapper.fromMap(r.value);
      dataList.add(data);
    }
    return dataList;
  }

  Future<Database> open() async{
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase(appDocDirectory.path + "/" + dbName);
  }

  Future<dynamic> deleteAll() async{
    Database db = await open();
    return db.deleteAll(await db.findKeys(Finder()));
  }

  Future<dynamic> delete(T data)  async{
    Database db = await open();
    return db.delete(mapper.getId(data));
  }
}

abstract class Mapper<T> {
  Map<dynamic, dynamic> toMap(T t);
  T fromMap(Map<dynamic, dynamic> map);
  dynamic getId(T t);
}