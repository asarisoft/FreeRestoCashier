import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class PrinterService {
  BluetoothDevice? _device;
  BluetoothConnection? _connection;

  BluetoothDevice? get device => _device;
  bool get isConnected =>
      _connection != null && _connection!.isConnected;

  Future<List<BluetoothDevice>> scan() async {
    final results = await FlutterBluetoothSerial.instance
        .startDiscovery()
        .toList();
    return results.map((r) => r.device).toList();
  }

  Future<void> connect(BluetoothDevice device) async {
    final conn = await BluetoothConnection.toAddress(device.address);
    _connection = conn;
    _device = device;
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _device = null;
    _connection = null;
  }

  Future<void> printBytes(List<int> bytes) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('Printer tidak terhubung');
    }
    _connection!.output.add(Uint8List.fromList(bytes));
    await _connection!.output.allSent;
  }

  Future<void> dispose() async {
    await disconnect();
  }
}
