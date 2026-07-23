import 'package:flutter/foundation.dart';

class SyncProvider extends ChangeNotifier {
  bool get isSyncing => false;
  bool get hasPendingSync => false;
  String? get lastSyncTime => null;
  String? get syncStatus => null;

  Future<void> initialize() async {}

  Future<bool> syncAllData(String userId) async => true;

  Future<bool> retryPendingSync(String userId) async => true;

  Future<bool> pullMedicinesFromServer() async => true;

  void clearSyncStatus() {}
}
