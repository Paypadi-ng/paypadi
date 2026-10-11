import 'package:flutter_test/flutter_test.dart';

// /// A tiny in-memory fake that implements the subset of
// /// `FlutterSecureStorage` API we use in the service.
// class _FakeSecureStorage extends FlutterSecureStorage {
//   _FakeSecureStorage();
//   final Map<String, String> _store = {};

//   @override
//   Future<void> write({
//     required String key,
//     required String? value,
//     AndroidOptions? aOptions,
//     AppleOptions? iOptions,
//     LinuxOptions? lOptions,
//     AppleOptions? mOptions,
//     WindowsOptions? wOptions,
//     WebOptions? webOptions,
//   }) async {
//     if (value == null) {
//       _store.remove(key);
//     } else {
//       _store[key] = value;
//     }
//   }

//   @override
//   Future<String?> read({
//     required String key,
//     AndroidOptions? aOptions,
//     AppleOptions? iOptions,
//     LinuxOptions? lOptions,
//     AppleOptions? mOptions,
//     WindowsOptions? wOptions,
//     WebOptions? webOptions,
//   }) async {
//     return _store[key];
//   }

//   @override
//   Future<void> delete({
//     required String key,
//     AndroidOptions? aOptions,
//     AppleOptions? iOptions,
//     LinuxOptions? lOptions,
//     AppleOptions? mOptions,
//     WindowsOptions? wOptions,
//     WebOptions? webOptions,
//   }) async {
//     _store.remove(key);
//   }

//   @override
//   Future<Map<String, String>> readAll({
//     AndroidOptions? aOptions,
//     AppleOptions? iOptions,
//     LinuxOptions? lOptions,
//     AppleOptions? mOptions,
//     WindowsOptions? wOptions,
//     WebOptions? webOptions,
//   }) async {
//     return Map<String, String>.from(_store);
//   }

//   @override
//   Future<void> deleteAll({
//     AndroidOptions? aOptions,
//     AppleOptions? iOptions,
//     LinuxOptions? lOptions,
//     AppleOptions? mOptions,
//     WindowsOptions? wOptions,
//     WebOptions? webOptions,
//   }) async {
//     _store.clear();
//   }
// }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // test('write/read/delete lifecycle', () async {
  //   final fake = _FakeSecureStorage();
  //   final svc = SecureCacheService(storage: fake);

  //   await svc.write(key: 't1', value: 'v1');
  //   final r = await svc.read('t1');
  //   expect(r, 'v1');

  //   await svc.delete('t1');
  //   final r2 = await svc.read('t1');
  //   expect(r2, isNull);
  // });
}
