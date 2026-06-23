import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingUtils {
  RecordingUtils._();

  static final AudioRecorder _recorder = AudioRecorder();

  static bool _isRecording = false;
  static String? _currentFilePath;

  static bool get isRecording => _isRecording;

  static Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;

    if (await Permission.microphone.shouldShowRequestRationale) {
      await openAppSettings();
    }
    return false;
  }

  static Future<String?> startRecording(String stationName) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return null;

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final sanitizedName = stationName.replaceAll(RegExp(r'[^\w\s-]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${recordingsDir.path}/${sanitizedName}_$timestamp.m4a';
    _currentFilePath = filePath;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 2,
      ),
      path: filePath,
    );
    _isRecording = true;
    return filePath;
  }

  static Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path ?? _currentFilePath;
  }

  static Future<void> cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _isRecording = false;
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) await file.delete();
    }
    _currentFilePath = null;
  }

  static Future<List<File>> getRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) return [];
    return recordingsDir.listSync().whereType<File>().toList();
  }

  static Future<void> deleteRecording(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  static void dispose() {
    _recorder.dispose();
  }
}
