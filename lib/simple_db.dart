library simple_db;

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

abstract class Mapper<T> {
  T fromMap(Map<dynamic, dynamic> map);
  dynamic getId(T t);
  Map<dynamic, dynamic> toMap(T t);
}

abstract class StorageEvent<T> {
  T data;
  StorageEvent({this.data});
}

class SaveEvent<T> extends StorageEvent<T>{
  SaveEvent(T data) : super(data: data);
}

class DeleteEvent<T> extends StorageEvent<T>{
  DeleteEvent(T data) : super(data: data);
}

class Storage<T> {
  StreamController<StorageEvent> _eventsController = StreamController<StorageEvent>.broadcast();
  Stream get events => _eventsController.stream;

  Mapper<T> mapper;
  String dbName;

  Storage(this.mapper, {this.dbName}) {
    dbName = dbName ?? T.toString();
  }

  Future<dynamic> delete(T data) async {
    Database db;
    dynamic k;

    try{
      db = await open();
      k = db.delete(mapper.getId(data));
      if(k != null)
        _eventsController.add(DeleteEvent(data));

    } catch (e, s){
      print(e);
      print(s);

    } finally {
      if(db != null)
        db.close();
    }

    return k;
  }

  Future<dynamic> deleteAll() async {
    List<dynamic> keys;
    try{
      List<T> items = await list();
      keys = <dynamic>[];

      for(T t in items){
        dynamic key = delete(t);
        if(key != null)
          keys.add(key);
      }

    } catch(e, s){
      print(e);
      print(s);

    }

    return keys;
  }

  Future<List<T>> list() async {
    Database db;
    List<T> dataList;

    try {
      db = await open();
      List<Record> records = await db.findRecords(Finder());
      dataList = <T>[];

      for (Record r in records) {
        r.value["id"] = r.key;
        T data = mapper.fromMap(r.value);
        dataList.add(data);
      }

    } catch(e, s){
      print(e);
      print(s);

    } finally {
      if(db != null)
        db.close();
    }

    return dataList;
  }

  Future<Database> open() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase(appDocDirectory.path + "/" + dbName);
  }

  dynamic save(T data) async {
    dynamic result;
    Database db;

    try {
      db = await open();
      result = await db.put(mapper.toMap(data));

      if(result != null)
       _eventsController.add(SaveEvent(data));

    } catch (e, s) {
      print(e.toString());
      print(s.toString());

    } finally {
      if(db != null)
        db.close();

    }

    return result;
  }
}
