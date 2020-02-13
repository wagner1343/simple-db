library simple_db;

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

abstract class Mapper<T> {
  T fromMap(Map<dynamic, dynamic> map);

  Map<dynamic, dynamic> toMap(T t);
}

abstract class Identifiable {
  dynamic id;
}

abstract class StorageEvent<T extends Identifiable> {
  T data;

  StorageEvent({this.data});
}

class SaveEvent<T extends Identifiable> extends StorageEvent<T> {
  SaveEvent(T data) : super(data: data);
}

class DeleteEvent<T extends Identifiable> extends StorageEvent<T> {
  DeleteEvent(T data) : super(data: data);
}

class Storage<T extends Identifiable> {
  StreamController<StorageEvent> _eventsController =
      StreamController<StorageEvent>.broadcast();

  Stream get events => _eventsController.stream;

  Mapper<T> mapper;
  String dbName;
  String storeName;

  Storage(this.mapper, {this.dbName, this.storeName}) {
    storeName = storeName ?? T.toString();
    dbName = dbName ?? "data.db";
  }

  Stream<List<T>> stream() async *{
    var db = await _openDB();
    yield* storeRef.query().onSnapshots(db).map<List<T>>((snapshots) => mapSnapshots(snapshots));
  }

  Future delete(T data) async {
    Database db;

    try {
      db = await _openDB();
      await storeRef.delete(db,
          finder: Finder(filter: Filter.byKey(data.id)));
    } catch (e, s) {
      print(e);
      print(s);
    } finally {
      if (db != null) db.close();
    }
  }

  String dataString(T data) {
    return "(${data.id?.toString()} -> $data)";
  }

  Future<int> deleteAll() async {
    int count;
    try {
      var db = await _openDB();
      count = await storeRef.delete(db);
    } catch (e, s) {
      print(e);
      print(s);
    }

    return count;
  }

  List<T> mapSnapshots(List<RecordSnapshot<dynamic, Map>> snapshots){
    return snapshots.map<T>((snap) => mapper.fromMap(snap.value)..id = snap.key).toList();
  }

  Future<List<T>> list() async {
    Database db;
    List<T> dataList;

    try {
      db = await _openDB();
      List<RecordSnapshot> snapshots = await storeRef.find(db);
      return mapSnapshots(snapshots);
    } catch (e, s) {
      print(e);
      print(s);
    } finally {
      if (db != null) db.close();
    }

    return dataList;
  }

  Future<Database> _openDB() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase(appDocDirectory.path + "/" + dbName);
  }

  StoreRef<dynamic, Map> get storeRef => StoreRef<dynamic, Map>(storeName);

  dynamic save(T data) async {
    dynamic result;
    Database db;

    try {
      db = await _openDB();
      result = await storeRef.add(db, mapper.toMap(data));

      if (result != null) {
        data.id = result;
        _eventsController.add(SaveEvent(data));
      }
    } catch (e, s) {
      print(e.toString());
      print(s.toString());
    } finally {
      if (db != null) db.close();
    }

    return result;
  }
}
