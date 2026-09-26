import "dart:math";
import "dart:typed_data";

import "package:audioplayers/audioplayers.dart";

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  // Low single beep — rest is starting, settle in
  Future<void> playRestStart() async {
    await _play(_wav(frequency: 523, durationMs: 350, amplitude: 0.45));
  }

  // Short sharp tick — last 3 seconds of rest
  Future<void> playCountdownTick() async {
    await _play(_wav(frequency: 880, durationMs: 80, amplitude: 0.6));
  }

  // Two ascending beeps — rest is over, go!
  Future<void> playRestEnd() async {
    await _play(_wav(frequency: 1318, durationMs: 220, amplitude: 0.7));
  }

  Future<void> _play(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes));
  }

  Uint8List _wav({
    required double frequency,
    required int durationMs,
    double amplitude = 0.5,
  }) {
    const sampleRate = 44100;
    const channels = 1;
    const bitsPerSample = 16;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);
    int o = 0;

    // RIFF header
    _str(buffer, o, "RIFF");
    o += 4;
    buffer.setUint32(o, 36 + dataSize, Endian.little);
    o += 4;
    _str(buffer, o, "WAVE");
    o += 4;
    // fmt chunk
    _str(buffer, o, "fmt ");
    o += 4;
    buffer.setUint32(o, 16, Endian.little);
    o += 4;
    buffer.setUint16(o, 1, Endian.little);
    o += 2; // PCM
    buffer.setUint16(o, channels, Endian.little);
    o += 2;
    buffer.setUint32(o, sampleRate, Endian.little);
    o += 4;
    buffer.setUint32(o, sampleRate * 2, Endian.little);
    o += 4;
    buffer.setUint16(o, 2, Endian.little);
    o += 2;
    buffer.setUint16(o, bitsPerSample, Endian.little);
    o += 2;
    // data chunk
    _str(buffer, o, "data");
    o += 4;
    buffer.setUint32(o, dataSize, Endian.little);
    o += 4;

    // PCM samples
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = _envelope(i, numSamples);
      final sample = (amplitude * env * sin(2 * pi * frequency * t) * 32767)
          .round()
          .clamp(-32768, 32767);
      buffer.setInt16(o, sample, Endian.little);
      o += 2;
    }

    return buffer.buffer.asUint8List();
  }

  // Short fade-in + fade-out to avoid clicks
  double _envelope(int i, int total) {
    const fadeIn = 441; // 10ms at 44100Hz
    const fadeOut = 882; // 20ms at 44100Hz
    if (i < fadeIn) return i / fadeIn;
    if (i > total - fadeOut) return (total - i) / fadeOut;
    return 1.0;
  }

  void _str(ByteData b, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      b.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  void dispose() => _player.dispose();
}
