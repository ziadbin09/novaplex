package com.novaplex.novaplex

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Rational
import android.view.ContextThemeWrapper
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import androidx.mediarouter.app.MediaRouteChooserDialog
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BRIGHTNESS_CHANNEL = "com.novaplex/brightness"
    private val PIP_CHANNEL = "com.novaplex/pip"
    private val PIP_EVENTS = "com.novaplex/pip_events"
    private val SHARE_CHANNEL = "com.novaplex/share"
    private val MEDIA_SESSION_CHANNEL = "com.novaplex/media_session"
    private val INTENT_CHANNEL = "com.novaplex/intent"
    private val CAST_CHANNEL = "com.novaplex/cast"
    private val CAST_EVENTS = "com.novaplex/cast_events"
    private val STORAGE_CHANNEL = "com.novaplex/storage"
    private val DEVICE_CHANNEL = "com.novaplex/device"

    private val NOTIFICATION_CHANNEL_ID = "novaplex_playback"
    private val NOTIFICATION_ID = 7001
    private val ACTION_PLAY_PAUSE = "com.novaplex.PLAY_PAUSE"

    private var pipEventSink: EventChannel.EventSink? = null
    private var playerIsActive = false

    private var mediaSession: MediaSessionCompat? = null
    private var mediaChannel: MethodChannel? = null
    private var intentChannel: MethodChannel? = null
    private var pendingViewUri: String? = null
    private var pickResult: MethodChannel.Result? = null
    private val PICK_VIDEO_REQUEST = 9001
    private var sessionTitle = "NovaPlex"
    private var lastPlaying = false
    private var lastPositionMs = 0L
    private var lastDurationMs = 0L
    private var receiverRegistered = false

    // ── Cast ─────────────────────────────────────────────────────────────────
    private var castContext: CastContext? = null
    private var castEventSink: EventChannel.EventSink? = null
    private var castStateListener: CastStateListener? = null
    private var sessionManagerListener: SessionManagerListener<CastSession>? = null
    private var castListenersRegistered = false

    private val mediaActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_PLAY_PAUSE) {
                mediaChannel?.invokeMethod(
                    if (lastPlaying) "onPause" else "onPlay", null
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Brightness ──────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIGHTNESS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setBrightness" -> {
                        val brightness = call.argument<Double>("brightness")?.toFloat() ?: -1f
                        val lp = window.attributes
                        lp.screenBrightness = brightness.coerceIn(-1f, 1f)
                        window.attributes = lp
                        result.success(null)
                    }
                    "getBrightness" -> {
                        result.success(window.attributes.screenBrightness.toDouble())
                    }
                    else -> result.notImplemented()
                }
            }

        // ── PiP ─────────────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enterPip" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build()
                            enterPictureInPictureMode(params)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "setPlayerActive" -> {
                        playerIsActive = call.argument<Boolean>("active") ?: false
                        result.success(null)
                    }
                    "isInPipMode" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                                isInPictureInPictureMode
                            else false
                        )
                    }
                    else -> result.notImplemented()
                }
            }

        // PiP mode change events → Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    pipEventSink = events
                }
                override fun onCancel(args: Any?) {
                    pipEventSink = null
                }
            })

        // ── Share ────────────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareVideo" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr != null) {
                            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                type = "video/*"
                                putExtra(Intent.EXTRA_STREAM, Uri.parse(uriStr))
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(shareIntent, "Share Video"))
                            result.success(null)
                        } else {
                            result.error("NO_URI", "No URI provided", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── "Open with" intent channel ───────────────────────────────────────
        intentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialUri" -> {
                        result.success(pendingViewUri)
                        pendingViewUri = null
                    }
                    "pickVideo" -> {
                        pickResult = result
                        val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "video/*"
                        }
                        startActivityForResult(picker, PICK_VIDEO_REQUEST)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        // Capture the URI if the app was cold-started from a video file
        handleViewIntent(intent, appRunning = false)

        // ── Media session / lock screen controls ────────────────────────────
        mediaChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, MEDIA_SESSION_CHANNEL
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        sessionTitle = call.argument<String>("title") ?: "NovaPlex"
                        startMediaSession()
                        result.success(null)
                    }
                    "update" -> {
                        lastPlaying = call.argument<Boolean>("playing") ?: false
                        lastPositionMs =
                            (call.argument<Number>("positionMs") ?: 0).toLong()
                        lastDurationMs =
                            (call.argument<Number>("durationMs") ?: 0).toLong()
                        updateMediaSession()
                        result.success(null)
                    }
                    "stop" -> {
                        stopMediaSession()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // ── Cast / Chromecast ────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAST_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(ensureCast() != null)
                    "getState" -> result.success(castContext?.castState ?: 1)
                    "showPicker" -> {
                        showCastPicker()
                        result.success(null)
                    }
                    "loadMedia" -> {
                        val url = call.argument<String>("url") ?: ""
                        val title = call.argument<String>("title") ?: "Video"
                        val contentType =
                            call.argument<String>("contentType") ?: "video/mp4"
                        val pos = (call.argument<Number>("positionMs") ?: 0).toLong()
                        result.success(castLoadMedia(url, title, contentType, pos))
                    }
                    "play" -> {
                        castRemoteClient()?.play()
                        result.success(null)
                    }
                    "pause" -> {
                        castRemoteClient()?.pause()
                        result.success(null)
                    }
                    "seek" -> {
                        val pos = (call.argument<Number>("positionMs") ?: 0).toLong()
                        castRemoteClient()?.seek(
                            MediaSeekOptions.Builder().setPosition(pos).build()
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        castContext?.sessionManager?.endCurrentSession(true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CAST_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    castEventSink = events
                }
                override fun onCancel(args: Any?) {
                    castEventSink = null
                }
            })

        // ── Device info (emulator detection) ─────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isLikelyEmulator" -> result.success(isLikelyEmulator())
                    else -> result.notImplemented()
                }
            }

        // ── Public storage (MediaStore) ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveVideo" -> {
                        val src = call.argument<String>("sourcePath") ?: ""
                        val name = call.argument<String>("displayName") ?: "video.mp4"
                        val mime = call.argument<String>("mimeType") ?: "video/mp4"
                        // Copying can be large — do it off the main thread.
                        Thread {
                            val uri = try {
                                saveVideoToGallery(src, name, mime)
                            } catch (e: Exception) {
                                null
                            }
                            runOnUiThread { result.success(uri) }
                        }.start()
                    }
                    "deleteVideo" -> {
                        val uriStr = call.argument<String>("uri") ?: ""
                        result.success(deleteVideoEntry(uriStr))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Public storage helpers ───────────────────────────────────────────────

    /// Copy a finished download into the public Movies/NovaPlex collection so it
    /// shows in the gallery and survives uninstall. Returns a content:// URI
    /// (API 29+) or an absolute file path (API ≤28), or null on failure.
    private fun saveVideoToGallery(
        sourcePath: String,
        displayName: String,
        mimeType: String
    ): String? {
        val src = File(sourcePath)
        if (!src.exists()) return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Video.Media.MIME_TYPE, mimeType)
                put(
                    MediaStore.Video.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_MOVIES}/NovaPlex"
                )
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }
            val collection = MediaStore.Video.Media.getContentUri(
                MediaStore.VOLUME_EXTERNAL_PRIMARY
            )
            val uri = resolver.insert(collection, values) ?: return null
            resolver.openOutputStream(uri)?.use { out ->
                src.inputStream().use { it.copyTo(out) }
            } ?: return null
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val moviesDir = File(
                Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_MOVIES
                ),
                "NovaPlex"
            )
            if (!moviesDir.exists()) moviesDir.mkdirs()
            val dest = File(moviesDir, displayName)
            src.copyTo(dest, overwrite = true)
            MediaScannerConnection.scanFile(
                this, arrayOf(dest.absolutePath), arrayOf(mimeType), null
            )
            return dest.absolutePath
        }
    }

    /// Delete a previously saved video (content:// via resolver, else file).
    private fun deleteVideoEntry(uriOrPath: String): Boolean {
        return try {
            if (uriOrPath.startsWith("content://")) {
                contentResolver.delete(Uri.parse(uriOrPath), null, null) > 0
            } else {
                val f = File(uriOrPath)
                if (f.exists()) f.delete() else false
            }
        } catch (e: Exception) {
            false
        }
    }

    // ── Device detection ─────────────────────────────────────────────────────

    /// True when running on an emulator / Android-on-PC (BlueStacks, etc.).
    /// The most reliable signal is an x86 CPU — virtually no real phone is x86,
    /// and it survives BlueStacks spoofing its model to a real device name.
    private fun isLikelyEmulator(): Boolean {
        val abis = Build.SUPPORTED_ABIS.joinToString(",").lowercase()
        if (abis.contains("x86")) return true
        val fp = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        return fp.contains("generic") ||
            fp.contains("emulator") ||
            model.contains("emulator") ||
            model.contains("sdk_gphone") ||
            product.contains("sdk") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            hardware.contains("vbox") ||
            hardware.contains("bluestacks") ||
            product.contains("bluestacks") ||
            manufacturer.contains("bluestacks") ||
            manufacturer.contains("genymotion")
    }

    // ── Cast helpers ─────────────────────────────────────────────────────────

    /// Lazily initialise CastContext. Returns null when Google Play Services /
    /// Cast is unavailable (e.g. on emulators) so callers degrade gracefully.
    private fun ensureCast(): CastContext? {
        castContext?.let { return it }
        return try {
            val gms = GoogleApiAvailability.getInstance()
                .isGooglePlayServicesAvailable(this)
            if (gms != ConnectionResult.SUCCESS) return null
            val ctx = CastContext.getSharedInstance(this)
            castContext = ctx
            registerCastListeners(ctx)
            ctx
        } catch (e: Exception) {
            null
        }
    }

    private fun registerCastListeners(ctx: CastContext) {
        if (castListenersRegistered) return
        castListenersRegistered = true

        castStateListener = CastStateListener { state ->
            castEventSink?.success(mapOf("type" to "state", "state" to state))
        }.also { ctx.addCastStateListener(it) }

        sessionManagerListener = object : SessionManagerListener<CastSession> {
            override fun onSessionStarted(session: CastSession, sessionId: String) {
                castEventSink?.success(mapOf("type" to "connected"))
            }
            override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
                castEventSink?.success(mapOf("type" to "connected"))
            }
            override fun onSessionEnded(session: CastSession, error: Int) {
                castEventSink?.success(mapOf("type" to "disconnected"))
            }
            override fun onSessionStarting(session: CastSession) {}
            override fun onSessionStartFailed(session: CastSession, error: Int) {}
            override fun onSessionEnding(session: CastSession) {}
            override fun onSessionResuming(session: CastSession, sessionId: String) {}
            override fun onSessionResumeFailed(session: CastSession, error: Int) {}
            override fun onSessionSuspended(session: CastSession, reason: Int) {}
        }
        ctx.sessionManager.addSessionManagerListener(
            sessionManagerListener!!, CastSession::class.java
        )
    }

    private fun showCastPicker() {
        val ctx = ensureCast() ?: return
        val selector = ctx.mergedSelector ?: return
        // MediaRouteChooserDialog needs an AppCompat theme; the Flutter activity
        // theme isn't one, so wrap it.
        val themed = ContextThemeWrapper(
            this, androidx.appcompat.R.style.Theme_AppCompat_DayNight_Dialog
        )
        val dialog = MediaRouteChooserDialog(themed)
        dialog.routeSelector = selector
        dialog.show()
    }

    private fun castRemoteClient() =
        castContext?.sessionManager?.currentCastSession?.remoteMediaClient

    private fun castLoadMedia(
        url: String,
        title: String,
        contentType: String,
        positionMs: Long
    ): Boolean {
        val rmc = castRemoteClient() ?: return false
        val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE)
        metadata.putString(MediaMetadata.KEY_TITLE, title)
        val mediaInfo = MediaInfo.Builder(url)
            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
            .setContentType(contentType)
            .setMetadata(metadata)
            .build()
        val request = MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .setAutoplay(true)
            .setCurrentTime(positionMs)
            .build()
        rmc.load(request)
        return true
    }

    // ── "Open with" intent handling ──────────────────────────────────────────

    private fun handleViewIntent(intent: Intent?, appRunning: Boolean) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data?.toString() ?: return
        if (appRunning && intentChannel != null) {
            intentChannel?.invokeMethod("onNewUri", uri)
        } else {
            pendingViewUri = uri
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleViewIntent(intent, appRunning = true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_VIDEO_REQUEST) {
            pickResult?.success(
                if (resultCode == RESULT_OK) data?.data?.toString() else null
            )
            pickResult = null
        }
    }

    // ── MediaSession helpers ─────────────────────────────────────────────────

    private fun startMediaSession() {
        if (mediaSession == null) {
            mediaSession = MediaSessionCompat(this, "NovaPlex").apply {
                setCallback(object : MediaSessionCompat.Callback() {
                    override fun onPlay() {
                        mediaChannel?.invokeMethod("onPlay", null)
                    }
                    override fun onPause() {
                        mediaChannel?.invokeMethod("onPause", null)
                    }
                    override fun onSeekTo(pos: Long) {
                        mediaChannel?.invokeMethod("onSeek", pos.toInt())
                    }
                })
                isActive = true
            }
        }
        createNotificationChannel()
        if (!receiverRegistered) {
            val filter = IntentFilter(ACTION_PLAY_PAUSE)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(mediaActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(mediaActionReceiver, filter)
            }
            receiverRegistered = true
        }
        updateMediaSession()
    }

    private fun updateMediaSession() {
        val session = mediaSession ?: return

        session.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, sessionTitle)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, lastDurationMs)
                .build()
        )
        session.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(
                    if (lastPlaying) PlaybackStateCompat.STATE_PLAYING
                    else PlaybackStateCompat.STATE_PAUSED,
                    lastPositionMs,
                    1.0f
                )
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                        PlaybackStateCompat.ACTION_PAUSE or
                        PlaybackStateCompat.ACTION_PLAY_PAUSE or
                        PlaybackStateCompat.ACTION_SEEK_TO
                )
                .build()
        )
        showNotification()
    }

    private fun showNotification() {
        val session = mediaSession ?: return

        val playPauseIntent = PendingIntent.getBroadcast(
            this, 0,
            Intent(ACTION_PLAY_PAUSE).setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val contentIntent = PendingIntent.getActivity(
            this, 1,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(
                if (lastPlaying) android.R.drawable.ic_media_play
                else android.R.drawable.ic_media_pause
            )
            .setContentTitle(sessionTitle)
            .setContentText(if (lastPlaying) "Playing" else "Paused")
            .setContentIntent(contentIntent)
            .setOngoing(lastPlaying)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                if (lastPlaying) android.R.drawable.ic_media_pause
                else android.R.drawable.ic_media_play,
                if (lastPlaying) "Pause" else "Play",
                playPauseIntent
            )
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(0)
            )
            .build()

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Media playback controls"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun stopMediaSession() {
        if (receiverRegistered) {
            try {
                unregisterReceiver(mediaActionReceiver)
            } catch (_: Exception) {}
            receiverRegistered = false
        }
        mediaSession?.release()
        mediaSession = null
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIFICATION_ID)
    }

    override fun onDestroy() {
        stopMediaSession()
        super.onDestroy()
    }

    // Auto-enter PiP when user presses the home button during playback
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (playerIsActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        }
    }

    override fun onPictureInPictureModeChanged(isInPipMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPipMode)
        pipEventSink?.success(isInPipMode)
    }
}
