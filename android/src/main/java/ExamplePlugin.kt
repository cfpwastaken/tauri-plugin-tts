package space.httpjames.tauri_plugin_tts

import android.content.Intent
import android.app.Activity
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.webkit.WebView
import app.tauri.annotation.Command
import app.tauri.annotation.InvokeArg
import app.tauri.annotation.TauriPlugin
import app.tauri.plugin.Plugin
import app.tauri.plugin.Invoke
import app.tauri.plugin.JSObject
import app.tauri.plugin.JSArray
import java.util.Locale
import java.util.UUID

@InvokeArg
internal class SpeakArgs {
    lateinit var text: String
    var language: String? = null
}

@InvokeArg
internal class AvailableArgs {
    var language: String? = null
}

@TauriPlugin
class ExamplePlugin(private val activity: Activity): Plugin(activity) {
    private var tts: TextToSpeech? = null
    private var isInitialized = false

    override fun load(webView: WebView) {
        initializeTTS()
    }

    private fun initializeTTS() {
        tts = TextToSpeech(activity) { status ->
            isInitialized = status == TextToSpeech.SUCCESS
            if (isInitialized) {
                tts?.language = Locale.US
                val event = JSObject()
                event.put("initialized", true)
                trigger("ttsInitialized", event)
            } else {
                val event = JSObject()
                event.put("error", "Failed to initialize TTS")
                trigger("ttsError", event)
            }
        }
    }

    @Command
    fun speak(invoke: Invoke) {
        if (!isInitialized || tts == null) {
            invoke.reject("TTS not initialized")
            return
        }

        try {
            val args = invoke.parseArgs(SpeakArgs::class.java)
            
            // Set language if provided
            args.language?.let { lang ->
                try {
                    val locale = Locale.forLanguageTag(lang)
                    val result = tts?.setLanguage(locale)
                    if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                        invoke.reject("Language not supported: $lang")
                        return
                    }
                } catch (e: Exception) {
                    invoke.reject("Invalid language code: $lang")
                    return
                }
            }

            val utteranceId = UUID.randomUUID().toString()

            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    val event = JSObject()
                    event.put("status", "started")
                    trigger("ttsStatus", event)
                }

                override fun onDone(utteranceId: String?) {
                    val ret = JSObject()
                    ret.put("success", true)
                    invoke.resolve(ret)
                }

                override fun onError(utteranceId: String?) {
                    invoke.reject("Speech failed")
                }
            })

            val result = tts?.speak(args.text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
            if (result == TextToSpeech.ERROR) {
                invoke.reject("Failed to queue speech")
            }

        } catch (e: Exception) {
            invoke.reject(e.message ?: "Unknown error")
        }
    }

    @Command
    fun stop(invoke: Invoke) {
        tts?.stop()
        invoke.resolve()
    }

    @Command
    fun configure(invoke: Invoke) {
        val intent = Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)
        activity.startActivity(intent)
        invoke.resolve()
    }

    @Command
    fun is_available(invoke: Invoke) {
        if (!isInitialized || tts == null) {
            invoke.reject("TTS not initialized")
            return
        }

        val args = invoke.parseArgs(AvailableArgs::class.java)
				val locale = Locale.forLanguageTag(args.language)
				val res = tts?.setLanguage(locale)
				val hasData = res != TextToSpeech.LANG_MISSING_DATA && res != TextToSpeech.LANG_NOT_SUPPORTED
        val ret = JSObject()
        ret.put("available", hasData)
        invoke.resolve(ret)
    }

    @Command
    fun get_voices(invoke: Invoke) {
        if (!isInitialized || tts == null) {
            invoke.reject("TTS not initialized")
            return
        }
        val ttsLocal = tts ?: run {
            invoke.reject("TTS not initialized")
            return
        }

        val res = JSObject()

        val engines = ttsLocal.getEngines()
        val engineList = JSArray()

        for (engine in engines) {
            val obj = JSObject()
            obj.put("label", engine.label)
            obj.put("name", engine.name)
            engineList.put(obj)
        }

        res.put("engines", engineList)

        val voices = ttsLocal.getVoices()
        val voiceList = JSArray()

        for (voice in voices) {
            val obj = JSObject()
            obj.put("name", voice.getName())
            obj.put("locale", voice.getLocale().toLanguageTag())
            obj.put("iso3", voice.getLocale().getISO3Language())
            obj.put("quality", voice.getQuality())
            obj.put("latency", voice.getLatency())
            obj.put("network", voice.isNetworkConnectionRequired())
            voiceList.put(obj)
        }

        res.put("voices", voiceList)

        invoke.resolve(res)
    }

    // override fun destroy() {
    //     tts?.stop()
    //     tts?.shutdown()
    //     super.destroy()
    // }
}
