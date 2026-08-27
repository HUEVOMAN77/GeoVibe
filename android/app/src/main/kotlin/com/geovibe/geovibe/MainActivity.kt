package com.geovibe.geovibe

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val safetyShareChannel = "geovibe/safety_share"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, safetyShareChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "shareSafety") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val channel = call.argument<String>("channel")
                val message = call.argument<String>("message")
                if (channel.isNullOrBlank() || message.isNullOrBlank()) {
                    result.error("invalid_arguments", "Faltan datos para compartir seguridad.", null)
                    return@setMethodCallHandler
                }
                try {
                    val targetIntent = createSafetyIntent(channel, message)
                    if (targetIntent.resolveActivity(packageManager) != null) {
                        startActivity(targetIntent)
                    } else if (channel == "facebook" &&
                        createFacebookAppIntent(message).resolveActivity(packageManager) != null
                    ) {
                        startActivity(createFacebookAppIntent(message))
                    } else if (channel != "sms") {
                        startActivity(
                            Intent.createChooser(
                                createGenericShareIntent(message),
                                "Compartir estado de seguridad",
                            ),
                        )
                    } else {
                        throw IllegalStateException("No hay aplicación de SMS disponible")
                    }
                    result.success(true)
                } catch (exception: Exception) {
                    result.error("share_failed", exception.message, null)
                }
            }
    }

    private fun createSafetyIntent(channel: String, message: String): Intent = when (channel) {
        "whatsapp" -> Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            setPackage("com.whatsapp")
            putExtra(Intent.EXTRA_TEXT, message)
        }
        "facebook" -> Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, message)
            putExtra(Intent.EXTRA_TITLE, "Estoy a Salvo · GeoVibe")
            setPackage("com.facebook.orca")
        }
        "sms" -> Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")).apply {
            putExtra("sms_body", message)
        }
        else -> throw IllegalArgumentException("Canal no reconocido")
    }

    private fun createGenericShareIntent(message: String): Intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, message)
        putExtra(Intent.EXTRA_TITLE, "Estoy a Salvo · GeoVibe")
    }

    private fun createFacebookAppIntent(message: String): Intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, message)
        putExtra(Intent.EXTRA_TITLE, "Estoy a Salvo · GeoVibe")
        setPackage("com.facebook.katana")
    }
}
