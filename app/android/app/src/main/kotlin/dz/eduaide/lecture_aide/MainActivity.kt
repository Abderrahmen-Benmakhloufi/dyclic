package dz.eduaide.lecture_aide

import android.content.Context
import android.content.Intent
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.security.MessageDigest
import java.util.Locale
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "dz.eduaide.lecture_aide/native_tts"
        private const val TAG = "NativeTTS"
    }

    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var activeEngineName: String? = null
    private var methodChannel: MethodChannel? = null

    private var mediaPlayer: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private val executor = Executors.newSingleThreadExecutor()

    @Volatile private var isPlayingSequence = false
    @Volatile private var cancelCurrentSpeech = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (text.isBlank()) {
                        result.success(mapOf("success" to false, "error" to "Empty text"))
                        return@setMethodCallHandler
                    }
                    speakUniversal(text)
                    result.success(mapOf("success" to true))
                }
                "stop" -> {
                    stopAllAudio(notifyFlutter = true)
                    result.success(true)
                }
                "getEngines" -> {
                    val engines = getAvailableEngines()
                    result.success(engines)
                }
                "getLanguages" -> {
                    val langs = getAvailableLanguages()
                    result.success(langs)
                }
                "getDiagnostics" -> {
                    val diag = getDiagnostics()
                    result.success(diag)
                }
                "isReady" -> {
                    result.success(true) // Hybrid engine is always ready
                }
                "setEngine" -> {
                    val engineName = call.argument<String>("engine")
                    initSystemTts(engineName) { success ->
                        result.success(success)
                    }
                }
                "reinitialize" -> {
                    initSystemTts(null) { success ->
                        result.success(mapOf("success" to success, "message" to "TTS reinitialized"))
                    }
                }
                "openTtsSettings" -> {
                    val opened = openTtsSettings()
                    result.success(opened)
                }
                "installVoiceData" -> {
                    val opened = installVoiceData()
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }

        // Initialize fallback system TTS engine
        initSystemTts(null, null)
    }

    // ── Universal Hybrid Speech Entry Point ────────────────────────────────────

    private fun speakUniversal(rawText: String) {
        val text = rawText.trim()
        if (text.isEmpty()) return

        stopAllAudio(notifyFlutter = false)
        cancelCurrentSpeech = false
        isPlayingSequence = true

        unmuteIfNecessary()
        requestAudioFocus()

        // Split into manageable chunks (by punctuation or newline)
        val sentences = text.split(Regex("(?<=[.!?;\n])\\s+"))
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        if (sentences.isEmpty()) {
            isPlayingSequence = false
            releaseAudioFocus()
            runOnUiThread {
                methodChannel?.invokeMethod("onDone", null)
            }
            return
        }

        playSentenceQueue(sentences, 0)
    }

    private fun playSentenceQueue(sentences: List<String>, index: Int) {
        if (cancelCurrentSpeech || index >= sentences.size) {
            isPlayingSequence = false
            releaseAudioFocus()
            runOnUiThread {
                methodChannel?.invokeMethod("onDone", null)
            }
            return
        }

        val currentSentence = sentences[index]

        // Notify start on first sentence
        if (index == 0) {
            runOnUiThread {
                methodChannel?.invokeMethod("onStart", null)
            }
        }

        playSingleUtterance(currentSentence) {
            if (!cancelCurrentSpeech) {
                playSentenceQueue(sentences, index + 1)
            } else {
                isPlayingSequence = false
                releaseAudioFocus()
                runOnUiThread {
                    methodChannel?.invokeMethod("onDone", null)
                }
            }
        }
    }

    private fun playSingleUtterance(text: String, onDone: () -> Unit) {
        if (cancelCurrentSpeech) return

        // 1. Check if bundled asset exists for this utterance (single word)
        val clean = text.lowercase().replace(Regex("[^a-z0-9àâäéèêëîïôöùûüç]"), "").trim()
        if (clean.isNotEmpty() && !clean.contains(" ")) {
            if (tryPlayBundledAsset(clean, onDone)) {
                return
            }
        }

        // 2. Check local disk cache (MD5 of text)
        val hash = md5(text)
        val cacheFolder = File(cacheDir, "tts_cache").apply { if (!exists()) mkdirs() }
        val cachedFile = File(cacheFolder, "$hash.mp3")

        if (cachedFile.exists() && cachedFile.length() > 0) {
            Log.d(TAG, "Playing from cache: ${cachedFile.name} for '$text'")
            playFileWithMediaPlayer(cachedFile, onDone)
            return
        }

        // 3. Download from Google Translate TTS in background
        executor.execute {
            if (cancelCurrentSpeech) return@execute

            var downloadSuccess = false
            try {
                val encoded = URLEncoder.encode(text, "UTF-8")
                val url = URL("https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=fr&q=$encoded")
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    setRequestProperty("User-Agent", "Mozilla/5.0 (Android; Mobile)")
                    connectTimeout = 3500
                    readTimeout = 4500
                    connect()
                }

                if (conn.responseCode == 200) {
                    val tempFile = File(cacheFolder, "$hash.temp")
                    conn.inputStream.use { input ->
                        tempFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    if (tempFile.length() > 500) { // Valid MP3
                        tempFile.renameTo(cachedFile)
                        downloadSuccess = true
                    } else {
                        tempFile.delete()
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Online TTS download error: ${e.message}")
            }

            if (cancelCurrentSpeech) return@execute

            if (downloadSuccess && cachedFile.exists()) {
                runOnUiThread {
                    playFileWithMediaPlayer(cachedFile, onDone)
                }
            } else {
                // 4. Fallback to Android System TextToSpeech
                runOnUiThread {
                    fallbackToSystemTts(text, onDone)
                }
            }
        }
    }

    // ── Asset Playback ─────────────────────────────────────────────────────────

    private fun tryPlayBundledAsset(word: String, onDone: (() -> Unit)? = null): Boolean {
        val possibleNames = listOf(
            "flutter_assets/assets/audio/$word.mp3",
            "flutter_assets/assets/audio/${removeAccents(word)}.mp3"
        )

        for (assetPath in possibleNames) {
            try {
                val afd = assets.openFd(assetPath)
                playAfdWithMediaPlayer(afd, onDone)
                return true
            } catch (_: Exception) {
                // Try reading InputStream
                try {
                    val stream = assets.open(assetPath)
                    val tempFile = File(cacheDir, "temp_asset_$word.mp3")
                    tempFile.outputStream().use { stream.copyTo(it) }
                    stream.close()
                    playFileWithMediaPlayer(tempFile, onDone)
                    return true
                } catch (_: Exception) {}
            }
        }
        return false
    }

    private fun playAfdWithMediaPlayer(afd: AssetFileDescriptor, onDone: (() -> Unit)?) {
        try {
            stopMediaPlayerOnly()
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()

                setOnPreparedListener { mp ->
                    mp.start()
                    runOnUiThread {
                        methodChannel?.invokeMethod("onStart", null)
                    }
                }
                setOnCompletionListener {
                    if (onDone != null) {
                        onDone.invoke()
                    } else {
                        isPlayingSequence = false
                        releaseAudioFocus()
                        runOnUiThread {
                            methodChannel?.invokeMethod("onDone", null)
                        }
                    }
                }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer AFD error: what=$what, extra=$extra")
                    if (onDone != null) {
                        onDone.invoke()
                    } else {
                        isPlayingSequence = false
                        releaseAudioFocus()
                        runOnUiThread {
                            methodChannel?.invokeMethod("onDone", null)
                        }
                    }
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            Log.e(TAG, "playAfd error: ${e.message}")
            if (onDone != null) {
                onDone.invoke()
            } else {
                isPlayingSequence = false
                releaseAudioFocus()
                runOnUiThread {
                    methodChannel?.invokeMethod("onDone", null)
                }
            }
        }
    }

    private fun playFileWithMediaPlayer(file: File, onDone: (() -> Unit)?) {
        try {
            stopMediaPlayerOnly()
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setDataSource(file.absolutePath)

                setOnPreparedListener { mp ->
                    mp.start()
                    runOnUiThread {
                        methodChannel?.invokeMethod("onStart", null)
                    }
                }
                setOnCompletionListener {
                    if (onDone != null) {
                        onDone.invoke()
                    } else {
                        isPlayingSequence = false
                        releaseAudioFocus()
                        runOnUiThread {
                            methodChannel?.invokeMethod("onDone", null)
                        }
                    }
                }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer file error: what=$what, extra=$extra")
                    if (onDone != null) {
                        onDone.invoke()
                    } else {
                        isPlayingSequence = false
                        releaseAudioFocus()
                        runOnUiThread {
                            methodChannel?.invokeMethod("onDone", null)
                        }
                    }
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            Log.e(TAG, "playFile error: ${e.message}")
            if (onDone != null) {
                onDone.invoke()
            } else {
                isPlayingSequence = false
                releaseAudioFocus()
                runOnUiThread {
                    methodChannel?.invokeMethod("onDone", null)
                }
            }
        }
    }

    // ── System TextToSpeech Fallback ───────────────────────────────────────────

    private fun fallbackToSystemTts(text: String, onDone: () -> Unit) {
        val engine = tts
        if (engine == null || !ttsReady) {
            Log.e(TAG, "System TTS fallback not available")
            onDone.invoke()
            return
        }

        val utteranceId = UUID.randomUUID().toString()
        val params = Bundle().apply {
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
            putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
            putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
        }

        // Utterance listener for sequence continuation
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(id: String?) {
                runOnUiThread {
                    methodChannel?.invokeMethod("onStart", null)
                }
            }
            override fun onDone(id: String?) {
                runOnUiThread {
                    onDone.invoke()
                }
            }
            @Deprecated("Deprecated in Java")
            override fun onError(id: String?) {
                runOnUiThread {
                    onDone.invoke()
                }
            }
            override fun onError(id: String?, errorCode: Int) {
                runOnUiThread {
                    onDone.invoke()
                }
            }
        })

        val res = engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
        if (res != TextToSpeech.SUCCESS) {
            Log.e(TAG, "System TTS speak returned error code: $res")
            runOnUiThread {
                onDone.invoke()
            }
        }
    }

    private fun initSystemTts(preferredEngine: String?, callback: ((Boolean) -> Unit)?) {
        ttsReady = false
        tts?.stop()
        tts?.shutdown()
        tts = null

        val listener = TextToSpeech.OnInitListener { status ->
            if (status == TextToSpeech.SUCCESS) {
                ttsReady = true
                configureSystemTts()
                runOnUiThread {
                    callback?.invoke(true)
                }
            } else {
                ttsReady = false
                runOnUiThread {
                    callback?.invoke(false)
                }
            }
        }

        if (!preferredEngine.isNullOrBlank()) {
            activeEngineName = preferredEngine
            tts = TextToSpeech(applicationContext, listener, preferredEngine)
        } else {
            activeEngineName = null
            tts = TextToSpeech(applicationContext, listener)
        }
    }

    private fun configureSystemTts() {
        val engine = tts ?: return
        val frFR = Locale("fr", "FR")
        try {
            engine.language = frFR
        } catch (_: Exception) {
            try { engine.language = Locale.FRENCH } catch (_: Exception) {}
        }
        engine.setSpeechRate(0.85f)
        engine.setPitch(1.0f)
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            engine.setAudioAttributes(audioAttributes)
        } catch (_: Exception) {}
    }

    // ── Audio Focus & Volume Control ───────────────────────────────────────────

    private fun unmuteIfNecessary() {
        try {
            val am = audioManager ?: return
            val currentVol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            if (currentVol == 0) {
                val target = (maxVol * 0.7).toInt().coerceAtLeast(1)
                am.setStreamVolume(AudioManager.STREAM_MUSIC, target, AudioManager.FLAG_SHOW_UI)
                Log.d(TAG, "Unmuted media stream to $target / $maxVol")
            }
        } catch (e: Exception) {
            Log.e(TAG, "unmute error: ${e.message}")
        }
    }

    private fun requestAudioFocus() {
        try {
            val am = audioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(attrs)
                    .build()
                am.requestAudioFocus(audioFocusRequest!!)
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            }
        } catch (e: Exception) {
            Log.e(TAG, "requestAudioFocus error: ${e.message}")
        }
    }

    private fun releaseAudioFocus() {
        try {
            val am = audioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                am.abandonAudioFocus(null)
            }
        } catch (_: Exception) {}
    }

    private fun stopAllAudio(notifyFlutter: Boolean = true) {
        cancelCurrentSpeech = true
        isPlayingSequence = false
        stopMediaPlayerOnly()
        try { tts?.stop() } catch (_: Exception) {}
        releaseAudioFocus()
        if (notifyFlutter) {
            runOnUiThread {
                methodChannel?.invokeMethod("onDone", null)
            }
        }
    }

    private fun stopMediaPlayerOnly() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                reset()
                release()
            }
            mediaPlayer = null
        } catch (_: Exception) {
            mediaPlayer = null
        }
    }

    // ── Helper Utilities ───────────────────────────────────────────────────────

    private fun md5(input: String): String {
        val md = MessageDigest.getInstance("MD5")
        val digested = md.digest(input.toByteArray())
        return digested.joinToString("") { "%02x".format(it) }
    }

    private fun removeAccents(str: String): String {
        return str
            .replace('é', 'e')
            .replace('è', 'e')
            .replace('ê', 'e')
            .replace('ë', 'e')
            .replace('à', 'a')
            .replace('â', 'a')
            .replace('ä', 'a')
            .replace('î', 'i')
            .replace('ï', 'i')
            .replace('ô', 'o')
            .replace('ö', 'o')
            .replace('ù', 'u')
            .replace('û', 'u')
            .replace('ü', 'u')
            .replace('ç', 'c')
    }

    private fun getAvailableEngines(): List<Map<String, String>> {
        val engine = tts ?: return emptyList()
        return try {
            engine.engines.map { mapOf("name" to it.name, "label" to it.label) }
        } catch (_: Exception) { emptyList() }
    }

    private fun getAvailableLanguages(): List<String> {
        val engine = tts ?: return emptyList()
        return try {
            (engine.availableLanguages ?: emptySet()).map { it.toLanguageTag() }.sorted()
        } catch (_: Exception) { emptyList() }
    }

    private fun getDiagnostics(): Map<String, Any?> {
        val am = audioManager
        val currentVol = am?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: -1
        val maxVol = am?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: -1
        val cacheFolder = File(cacheDir, "tts_cache")
        val cachedCount = cacheFolder.listFiles()?.size ?: 0

        return mapOf(
            "engineType" to "Universal Hybrid (Assets + MP3 Cache + System TTS)",
            "mediaPlayerReady" to true,
            "systemTtsReady" to ttsReady,
            "mediaVolume" to "$currentVol/$maxVol",
            "cachedAudioFiles" to cachedCount,
            "androidSdk" to Build.VERSION.SDK_INT,
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "activeEngine" to (activeEngineName ?: tts?.defaultEngine ?: "system_default")
        )
    }

    private fun openTtsSettings(): Boolean {
        return try {
            val intent = Intent("com.android.settings.TTS_SETTINGS").apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                })
                true
            } catch (_: Exception) { false }
        }
    }

    private fun installVoiceData(): Boolean {
        return try {
            startActivity(Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            })
            true
        } catch (_: Exception) { false }
    }

    override fun onDestroy() {
        stopAllAudio()
        tts?.shutdown()
        tts = null
        executor.shutdown()
        super.onDestroy()
    }
}
