/// The `.navmaas` backup file (ARCHITECTURE §11). Pure Dart, so it runs in
/// a background isolate.
///
/// Layout: `NAVMAAS` + format byte, a 4-byte header length, the header
/// (JSON), then the body in chunks. The body is the files one after
/// another (name length, name, size, bytes), `manifest.json` last, cut into
/// 1 MiB pieces. Each piece is sealed with ChaCha20-Poly1305 under a key
/// derived from the password with Argon2id: 12-byte nonce, ciphertext,
/// 16-byte tag. Its associated data is the header's hash, the piece's index
/// and a last-piece flag, so the header can't be edited and pieces can't be
/// reordered, dropped or cut off unnoticed.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

const backupFormat = 1;
const _magic = 'NAVMAAS';
const _cipherName = 'chacha20-poly1305';
const _nonceLength = 12;
const _tagLength = 16;
const manifestName = 'manifest.json';

/// Argon2id settings. They travel in the header, so they can change later
/// without breaking old backups.
typedef KdfParams = ({int memoryKib, int iterations, int parallelism});

/// 64 MiB, 3 passes, 1 lane: about half a second on a recent phone.
const KdfParams defaultKdf = (memoryKib: 65536, iterations: 3, parallelism: 1);

/// Why a backup can't be read. Nothing on the phone has changed.
enum BackupError {
  /// Not a `.navmaas` file.
  notABackup,

  /// Made by a newer Navmaas (file format or database).
  tooNew,

  /// The password doesn't open it.
  wrongPassword,

  /// Damaged, cut short or edited.
  damaged,
}

class BackupException implements Exception {
  const new(this.error);

  final BackupError error;

  @override
  String toString() => 'BackupException(${error.name})';
}

/// What can be shown before the password is asked for.
class BackupHeader {
  const new({
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
    required this.includesLibrary,
    this.kdf = defaultKdf,
    this.salt = const [],
    this.chunkSize = 1 << 20,
  });

  factory fromJson(Map<String, Object?> json) {
    final kdf = json['kdf']! as Map<String, Object?>;
    return BackupHeader(
      createdAt: DateTime.parse(json['createdAt']! as String),
      appVersion: json['appVersion']! as String,
      schemaVersion: json['schemaVersion']! as int,
      includesLibrary: json['includesLibrary']! as bool,
      kdf: (
        memoryKib: kdf['memoryKib']! as int,
        iterations: kdf['iterations']! as int,
        parallelism: kdf['parallelism']! as int,
      ),
      salt: base64.decode(kdf['salt']! as String),
      chunkSize: json['chunkSize']! as int,
    );
  }

  final DateTime createdAt;
  final String appVersion;
  final int schemaVersion;
  final bool includesLibrary;
  final KdfParams kdf;
  final List<int> salt;
  final int chunkSize;

  Map<String, Object?> toJson() => {
    'format': backupFormat,
    'kdf': {
      'name': 'argon2id',
      'memoryKib': kdf.memoryKib,
      'iterations': kdf.iterations,
      'parallelism': kdf.parallelism,
      'salt': base64.encode(salt),
    },
    'cipher': _cipherName,
    'chunkSize': chunkSize,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'includesLibrary': includesLibrary,
  };
}

/// A file to put in the backup, under `name` (`navmaas.db`,
/// `attachments/…`, `library/…`).
typedef BackupSource = ({String name, File file});

/// Names a backup may contain: one folder level at most, plain characters,
/// so a crafted file can't write outside the restore folder.
final _safeName = RegExp(
  r'^[A-Za-z0-9_-][A-Za-z0-9_.-]*(/[A-Za-z0-9_-][A-Za-z0-9_.-]*)?$',
);

/// Writes [files], then [manifest] as `manifest.json`, into [out].
/// [header] supplies everything but the salt, which is new for every backup.
Future<void> writeBackup({
  required File out,
  required BackupHeader header,
  required String password,
  required List<BackupSource> files,
  required Map<String, Object?> manifest,
}) async {
  final salt = _random(16);
  final sealed = BackupHeader(
    createdAt: header.createdAt,
    appVersion: header.appVersion,
    schemaVersion: header.schemaVersion,
    includesLibrary: header.includesLibrary,
    kdf: header.kdf,
    salt: salt,
    chunkSize: header.chunkSize,
  );
  final prefix = _prefix(sealed);
  final key = await _deriveKey(password, sealed);
  final sink = out.openWrite();
  try {
    sink.add(prefix);
    final writer = _ChunkWriter(
      sink,
      key,
      await _hash(prefix),
      sealed.chunkSize,
    );
    Future<void> entry(String name, int size, Stream<List<int>> bytes) async {
      final nameBytes = utf8.encode(name);
      await writer.add(
        (ByteData(2)..setUint16(0, nameBytes.length)).buffer.asUint8List(),
      );
      await writer.add(nameBytes);
      await writer.add((ByteData(8)..setUint64(0, size)).buffer.asUint8List());
      var written = 0;
      await for (final part in bytes) {
        written += part.length;
        await writer.add(part);
      }
      // A file that changed while it was read would break the stream.
      if (written != size) throw StateError('$name changed during backup');
    }

    for (final f in files) {
      if (!_safeName.hasMatch(f.name)) throw ArgumentError(f.name);
      await entry(f.name, await f.file.length(), f.file.openRead());
    }
    final json = utf8.encode(jsonEncode(manifest));
    await entry(manifestName, json.length, Stream.value(json));
    await writer.close();
  } finally {
    await sink.close();
  }
}

/// Reads the header without the password.
Future<BackupHeader> readBackupHeader(File file) async {
  final raf = await file.open();
  try {
    return (await _readPrefix(raf)).header;
  } finally {
    await raf.close();
  }
}

/// Decrypts [file] into [into] (which should be empty) and returns its
/// manifest. Throws [BackupException]; a partly written folder is the
/// caller's to delete.
Future<Map<String, Object?>> readBackup({
  required File file,
  required String password,
  required Directory into,
}) async {
  final raf = await file.open();
  try {
    final (:header, :prefix) = await _readPrefix(raf);
    final key = await _deriveKey(password, header);
    final plain = _PlainReader(
      _ChunkReader(
        raf,
        key,
        await _hash(prefix),
        header.chunkSize,
        prefix.length,
        await raf.length(),
      ),
    );
    Map<String, Object?>? manifest;
    while (!await plain.atEnd) {
      // Nothing may follow the manifest.
      if (manifest != null) throw const BackupException(BackupError.damaged);
      final nameLength = ByteData.sublistView(await plain.take(2)).getUint16(0);
      final String name;
      try {
        name = utf8.decode(await plain.take(nameLength));
      } on FormatException {
        throw const BackupException(BackupError.damaged);
      }
      final size = ByteData.sublistView(await plain.take(8)).getUint64(0);
      if (name == manifestName) {
        try {
          manifest = jsonDecode(
            utf8.decode(await plain.take(size)),
          ) as Map<String, Object?>;
        } on FormatException {
          throw const BackupException(BackupError.damaged);
        }
        continue;
      }
      if (!_safeName.hasMatch(name)) {
        throw const BackupException(BackupError.damaged);
      }
      final target = File('${into.path}/$name');
      await target.parent.create(recursive: true);
      final sink = target.openWrite();
      try {
        await plain.pipe(size, sink);
      } finally {
        await sink.close();
      }
    }
    if (manifest == null) throw const BackupException(BackupError.damaged);
    return manifest;
  } finally {
    await raf.close();
  }
}

List<int> _random(int n) {
  final r = Random.secure();
  return List.generate(n, (_) => r.nextInt(256));
}

Future<List<int>> _hash(List<int> bytes) async =>
    (await const DartSha256().hash(bytes)).bytes;

Uint8List _prefix(BackupHeader header) {
  final json = utf8.encode(jsonEncode(header.toJson()));
  return (BytesBuilder(copy: false)
        ..add(ascii.encode(_magic))
        ..addByte(backupFormat)
        ..add((ByteData(4)..setUint32(0, json.length)).buffer.asUint8List())
        ..add(json))
      .toBytes();
}

Future<({BackupHeader header, Uint8List prefix})> _readPrefix(
  RandomAccessFile raf,
) async {
  final start = await raf.read(_magic.length + 5);
  if (start.length < _magic.length + 5 ||
      ascii.decode(start.sublist(0, _magic.length), allowInvalid: true) !=
          _magic) {
    throw const BackupException(BackupError.notABackup);
  }
  if (start[_magic.length] > backupFormat) {
    throw const BackupException(BackupError.tooNew);
  }
  final length = ByteData.sublistView(start, _magic.length + 1).getUint32(0);
  if (length > 64 * 1024) throw const BackupException(BackupError.damaged);
  final json = await raf.read(length);
  try {
    final header = BackupHeader.fromJson(
      jsonDecode(utf8.decode(json)) as Map<String, Object?>,
    );
    if (header.chunkSize < 1024 || header.chunkSize > 16 << 20) {
      throw const BackupException(BackupError.damaged);
    }
    return (header: header, prefix: Uint8List.fromList([...start, ...json]));
  } on BackupException {
    rethrow;
  } on Object {
    throw const BackupException(BackupError.damaged);
  }
}

Future<SecretKey> _deriveKey(String password, BackupHeader header) {
  final kdf = header.kdf;
  if (kdf.memoryKib > 1 << 20 || kdf.iterations > 64) {
    throw const BackupException(BackupError.damaged);
  }
  return DartArgon2id(
    memory: kdf.memoryKib,
    iterations: kdf.iterations,
    parallelism: kdf.parallelism,
    hashLength: 32,
  ).deriveKeyFromPassword(password: password, nonce: header.salt);
}

List<int> _aad(List<int> headerHash, int index, {required bool last}) => [
  ...headerHash,
  ...(ByteData(8)..setUint64(0, index)).buffer.asUint8List(),
  if (last) 1 else 0,
];

const _cipher = DartChacha20.poly1305Aead();

/// Seals the body piece by piece. A full piece is only written once more
/// bytes arrive, so the last piece always carries the last-piece flag.
class _ChunkWriter {
  new(this._sink, this._key, this._headerHash, this._size)
    : _buffer = Uint8List(_size);

  final IOSink _sink;
  final SecretKey _key;
  final List<int> _headerHash;
  final int _size;
  final Uint8List _buffer;
  var _fill = 0;
  var _index = 0;

  Future<void> add(List<int> data) async {
    var i = 0;
    while (i < data.length) {
      if (_fill == _size) await _flush(last: false);
      final n = min(_size - _fill, data.length - i);
      _buffer.setRange(_fill, _fill + n, data, i);
      _fill += n;
      i += n;
    }
  }

  Future<void> close() => _flush(last: true);

  Future<void> _flush({required bool last}) async {
    final box = await _cipher.encrypt(
      Uint8List.sublistView(_buffer, 0, _fill),
      secretKey: _key,
      nonce: _random(_nonceLength),
      aad: _aad(_headerHash, _index, last: last),
    );
    _sink
      ..add(box.nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    _index++;
    _fill = 0;
  }
}

/// Opens the body piece by piece, in order.
class _ChunkReader {
  new(
    this._raf,
    this._key,
    this._headerHash,
    this._size,
    this._position,
    this._end,
  ) : _buffer = Uint8List(_size + _nonceLength + _tagLength);

  final RandomAccessFile _raf;
  final SecretKey _key;
  final List<int> _headerHash;
  final int _size;
  int _position;
  final int _end;

  /// Reused for every piece read from disk.
  final Uint8List _buffer;
  var _index = 0;
  var _done = false;

  /// The next piece's plaintext, or null after the last.
  Future<Uint8List?> next() async {
    if (_done) return null;
    final remaining = _end - _position;
    const overhead = _nonceLength + _tagLength;
    final last = remaining <= _size + overhead;
    final length = last ? remaining : _size + overhead;
    if (length <= overhead) throw const BackupException(BackupError.damaged);
    await _raf.setPosition(_position);
    if (await _raf.readInto(_buffer, 0, length) != length) {
      throw const BackupException(BackupError.damaged);
    }
    final bytes = Uint8List.sublistView(_buffer, 0, length);
    _position += length;
    try {
      final plain = await _cipher.decrypt(
        SecretBox(
          Uint8List.sublistView(bytes, _nonceLength, length - _tagLength),
          nonce: Uint8List.sublistView(bytes, 0, _nonceLength),
          mac: Mac(Uint8List.sublistView(bytes, length - _tagLength)),
        ),
        secretKey: _key,
        aad: _aad(_headerHash, _index, last: last),
      );
      _index++;
      _done = last;
      return plain is Uint8List ? plain : Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      // The first piece failing almost always means the wrong password.
      throw BackupException(
        _index == 0 ? BackupError.wrongPassword : BackupError.damaged,
      );
    }
  }
}

/// The body's plaintext as one stream of bytes, across pieces.
class _PlainReader {
  new(this._chunks);

  final _ChunkReader _chunks;
  Uint8List _current = Uint8List(0);
  var _offset = 0;

  Future<bool> _fill() async {
    while (_offset == _current.length) {
      final next = await _chunks.next();
      if (next == null) return false;
      _current = next;
      _offset = 0;
    }
    return true;
  }

  Future<bool> get atEnd async => !await _fill();

  /// Exactly [n] bytes (small fields and the manifest).
  Future<Uint8List> take(int n) async {
    final out = BytesBuilder(copy: false);
    await _each(n, out.add);
    return out.toBytes();
  }

  /// Streams [n] bytes into [sink], one piece at a time.
  Future<void> pipe(int n, IOSink sink) => _each(n, sink.add);

  Future<void> _each(int n, void Function(List<int>) use) async {
    var left = n;
    while (left > 0) {
      if (!await _fill()) throw const BackupException(BackupError.damaged);
      final take = min(left, _current.length - _offset);
      use(Uint8List.sublistView(_current, _offset, _offset + take));
      _offset += take;
      left -= take;
    }
  }
}
