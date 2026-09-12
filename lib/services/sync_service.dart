import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'api_service.dart';
import 'local_database.dart';

class SyncService {
  static final SyncService instance = SyncService._();

  SyncService._();

  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _syncing = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        flush();
      }
    });

    final current = await Connectivity().checkConnectivity();

    if (current.any((result) => result != ConnectivityResult.none)) {
      await flush();
    }
  }

  Future<String> enqueue({
    required String type,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) return '';
    final db = await LocalDatabase.database;

    final localId = _uuid.v4();

    final finalPayload = {...payload, 'local_id': localId};

    await db.insert('sync_queue', {
      'local_id': localId,
      'type': type,
      'endpoint': endpoint,
      'payload': jsonEncode(finalPayload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
      'last_error': null,
    });

    return localId;
  }

  Future<int> pendingCount() async {
    if (kIsWeb) return 0;
    final db = await LocalDatabase.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> flush() async {
    if (kIsWeb) return;
    if (_syncing) return;

    _syncing = true;

    try {
      final db = await LocalDatabase.database;

      final rows = await db.query(
        'sync_queue',
        orderBy: 'created_at ASC, id ASC',
      );

      for (final row in rows) {
        final localDbId = row['id'] as int;
        final endpoint = row['endpoint'] as String;
        final type = row['type'] as String;
        final payload =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;

        final response = await ApiService.post(endpoint, payload);
        final statusCode = response['statusCode'] as int? ?? 0;
        if (statusCode == 200 || statusCode == 201 || statusCode == 422) {
          await db.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [localDbId],
          );

          if (statusCode == 422) {
            debugPrint(
              'Item eliminado de cola por error no recuperable (422): ${response['message']}',
            );
          }
        } else {
          // Errores de red (500, timeout, sin conexión) se conservan para reintentar luego
          debugPrint('Error temporal ($statusCode). Se mantendrá en cola.');
        }
        debugPrint(
          'Sync [$type] -> Status: $statusCode | Resp: ${response['message']}',
        );
        final success = statusCode >= 200 && statusCode < 300;

        final alreadyRegistered =
            type == 'asistencia' &&
            statusCode == 409 &&
            response['code'] == 'YA_REGISTRADO';

        if (success || alreadyRegistered) {
          await db.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [localDbId],
          );
          continue;
        }

        await db.update(
          'sync_queue',
          {
            'attempts': (row['attempts'] as int? ?? 0) + 1,
            'last_error': response['message']?.toString(),
          },
          where: 'id = ?',
          whereArgs: [localDbId],
        );

        if (statusCode == 0) {
          break;
        }

        if (type == 'gps' && response['code'] == 'VIAJE_NO_ACTIVO') {
          break;
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _initialized = false;
  }
}
