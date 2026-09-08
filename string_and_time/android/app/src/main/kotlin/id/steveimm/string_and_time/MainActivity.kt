package id.steveimm.string_and_time

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var metronome: MetronomeAudio? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        metronome = MetronomeAudio(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onStop() {
        metronome?.stop()
        super.onStop()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        metronome?.dispose()
        metronome = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
