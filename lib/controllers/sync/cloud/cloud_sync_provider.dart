class CloudFileMetadata {
  final String name;
  final int sizeBytes;
  final DateTime? modifiedTime;
  final String? etag;

  const CloudFileMetadata({
    required this.name,
    required this.sizeBytes,
    this.modifiedTime,
    this.etag,
  });

  @override
  String toString() =>
      'CloudFileMetadata(name: $name, size: $sizeBytes, modified: $modifiedTime)';
}

abstract class CloudSyncProvider {
  String get id;
  String get displayName;

  Future<bool> testConnection();
  Future<void> uploadFile(String remoteFileName, List<int> bytes);
  Future<List<int>?> downloadFile(String remoteFileName);
  Future<CloudFileMetadata?> getFileMetadata(String remoteFileName);
  Future<bool> deleteFile(String remoteFileName);
}
