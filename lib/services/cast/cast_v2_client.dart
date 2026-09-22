import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class CastV2Message {
  final String namespace;
  final String sourceId;
  final String destinationId;
  final Map<String, dynamic> payload;

  CastV2Message({
    required this.namespace,
    required this.sourceId,
    required this.destinationId,
    required this.payload,
  });
}

class CastV2Client {
  static const kNamespaceConnection = 'urn:x-cast:com.google.cast.tp.connection';
  static const kNamespaceHeartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
  static const kNamespaceReceiver = 'urn:x-cast:com.google.cast.receiver';
  static const kNamespaceMedia = 'urn:x-cast:com.google.cast.media';

  final SecureSocket _socket;
  final String sessionId;
  String? _transportId;
  int _requestId = 1;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<bool>.broadcast();
  final List<int> _buffer = [];

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<bool> get stateStream => _stateController.stream;

  CastV2Client._(this.sessionId, this._socket) {
    _socket.listen(_onData, onError: _onError, onDone: _onDone);
  }

  static Future<CastV2Client> connect(String host, int port, {String? sessionId}) async {
    final sId = sessionId ?? 'sender-${DateTime.now().millisecondsSinceEpoch}';
    final socket = await SecureSocket.connect(
      host,
      port,
      onBadCertificate: (cert) => true,
      timeout: const Duration(seconds: 5),
    );

    final client = CastV2Client._(sId, socket);
    client.sendMessage(
      namespace: kNamespaceConnection,
      destinationId: 'receiver-0',
      payload: {'type': 'CONNECT'},
    );

    return client;
  }

  void _onData(List<int> chunk) {
    _buffer.addAll(chunk);

    while (_buffer.length >= 4) {
      final payloadLength = (_buffer[0] << 24) | (_buffer[1] << 16) | (_buffer[2] << 8) | _buffer[3];
      final totalMessageLength = 4 + payloadLength;

      if (_buffer.length < totalMessageLength) {
        break;
      }

      final messageBytes = _buffer.sublist(4, totalMessageLength);
      _buffer.removeRange(0, totalMessageLength);

      try {
        final parsed = _decodeCastMessage(messageBytes);
        if (parsed != null) {
          _handleMessage(parsed);
        }
      } catch (_) {}
    }
  }

  void _handleMessage(CastV2Message msg) {
    final type = msg.payload['type'] as String?;

    if (msg.namespace == kNamespaceHeartbeat && type == 'PING') {
      sendMessage(
        namespace: kNamespaceHeartbeat,
        destinationId: msg.sourceId,
        payload: {'type': 'PONG'},
      );
      return;
    }

    if (msg.namespace == kNamespaceReceiver && type == 'RECEIVER_STATUS') {
      final status = msg.payload['status'] as Map<String, dynamic>?;
      final applications = status?['applications'] as List<dynamic>?;
      if (applications != null && applications.isNotEmpty) {
        final app = applications.first as Map<String, dynamic>;
        final newTransportId = app['transportId'] as String?;
        if (newTransportId != null && newTransportId != _transportId) {
          _transportId = newTransportId;
          sendMessage(
            namespace: kNamespaceConnection,
            destinationId: newTransportId,
            payload: {'type': 'CONNECT'},
          );
        }
      }
    }

    if (!_messageController.isClosed) {
      _messageController.add(msg.payload);
    }
  }

  void sendMessage({
    required String namespace,
    String? destinationId,
    required Map<String, dynamic> payload,
  }) {
    if (payload['requestId'] == null && namespace != kNamespaceConnection && namespace != kNamespaceHeartbeat) {
      payload['requestId'] = _requestId++;
    }

    final dest = destinationId ?? _transportId ?? 'receiver-0';
    final payloadJson = jsonEncode(payload);

    final encodedProto = _encodeCastMessage(
      sourceId: sessionId,
      destinationId: dest,
      namespace: namespace,
      payloadUtf8: payloadJson,
    );

    final length = encodedProto.length;
    final header = [
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ];

    _socket.add(header + encodedProto);
  }

  List<int> _encodeCastMessage({
    required String sourceId,
    required String destinationId,
    required String namespace,
    required String payloadUtf8,
  }) {
    final builder = BytesBuilder();

    builder.add([0x08, 0x00]);

    _writeStringField(builder, 2, sourceId);
    _writeStringField(builder, 3, destinationId);
    _writeStringField(builder, 4, namespace);

    builder.add([0x28, 0x00]);

    _writeStringField(builder, 6, payloadUtf8);

    return builder.toBytes();
  }

  void _writeStringField(BytesBuilder builder, int fieldNumber, String value) {
    final tag = (fieldNumber << 3) | 2;
    builder.addByte(tag);
    final utf8Bytes = utf8.encode(value);
    _writeVarint(builder, utf8Bytes.length);
    builder.add(utf8Bytes);
  }

  void _writeVarint(BytesBuilder builder, int value) {
    var v = value;
    while (v >= 0x80) {
      builder.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
    builder.addByte(v & 0x7F);
  }

  CastV2Message? _decodeCastMessage(List<int> bytes) {
    var offset = 0;
    String sourceId = '';
    String destinationId = '';
    String namespace = '';
    String payloadUtf8 = '';

    while (offset < bytes.length) {
      final tag = bytes[offset++];
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x07;

      if (wireType == 0) {
        while (offset < bytes.length && (bytes[offset++] & 0x80) != 0) {}
      } else if (wireType == 2) {
        var length = 0;
        var shift = 0;
        while (offset < bytes.length) {
          final b = bytes[offset++];
          length |= (b & 0x7F) << shift;
          if ((b & 0x80) == 0) break;
          shift += 7;
        }

        if (offset + length <= bytes.length) {
          final fieldBytes = bytes.sublist(offset, offset + length);
          offset += length;

          if (fieldNumber == 2) {
            sourceId = utf8.decode(fieldBytes, allowMalformed: true);
          } else if (fieldNumber == 3) {
            destinationId = utf8.decode(fieldBytes, allowMalformed: true);
          } else if (fieldNumber == 4) {
            namespace = utf8.decode(fieldBytes, allowMalformed: true);
          } else if (fieldNumber == 6) {
            payloadUtf8 = utf8.decode(fieldBytes, allowMalformed: true);
          }
        }
      }
    }

    if (namespace.isNotEmpty && payloadUtf8.isNotEmpty) {
      try {
        final json = jsonDecode(payloadUtf8) as Map<String, dynamic>;
        return CastV2Message(
          namespace: namespace,
          sourceId: sourceId,
          destinationId: destinationId,
          payload: json,
        );
      } catch (_) {}
    }

    return null;
  }

  void _onError(dynamic error) {
    close();
  }

  void _onDone() {
    close();
  }

  Future<void> close() async {
    if (!_stateController.isClosed) {
      _stateController.add(false);
      _stateController.close();
    }
    if (!_messageController.isClosed) {
      _messageController.close();
    }
    try {
      await _socket.close();
    } catch (_) {}
  }
}
