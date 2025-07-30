package com.uwaniumnya.crystal

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import com.spotify.android.appremote.api.ConnectionParams
import com.spotify.android.appremote.api.Connector
import com.spotify.android.appremote.api.SpotifyAppRemote
import com.spotify.protocol.client.Subscription
import com.spotify.protocol.types.PlayerState
import com.spotify.protocol.types.Track

class MainActivity : FlutterActivity() {
    private val CHANNEL = "spotify_sdk"
    private var spotifyAppRemote: SpotifyAppRemote? = null
    private var playerStateSubscription: Subscription<PlayerState>? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "connectToSpotifyRemote" -> {
                    val clientId = call.argument<String>("clientId")
                    val redirectUrl = call.argument<String>("redirectUrl")
                    if (clientId != null && redirectUrl != null) {
                        connectToSpotifyRemote(clientId, redirectUrl, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing clientId or redirectUrl", null)
                    }
                }
                "disconnect" -> {
                    disconnectFromSpotify(result)
                }
                "play" -> {
                    val spotifyUri = call.argument<String>("spotifyUri")
                    playTrack(spotifyUri, result)
                }
                "pause" -> {
                    pauseTrack(result)
                }
                "resume" -> {
                    resumeTrack(result)
                }
                "skipNext" -> {
                    skipNext(result)
                }
                "skipPrevious" -> {
                    skipPrevious(result)
                }
                "seekToPosition" -> {
                    val positionMs = call.argument<Int>("positionMs")
                    if (positionMs != null) {
                        seekToPosition(positionMs, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing positionMs", null)
                    }
                }
                "setShuffle" -> {
                    val shuffle = call.argument<Boolean>("shuffle")
                    if (shuffle != null) {
                        setShuffle(shuffle, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing shuffle", null)
                    }
                }
                "setRepeatMode" -> {
                    val repeatMode = call.argument<Int>("repeatMode")
                    if (repeatMode != null) {
                        setRepeatMode(repeatMode, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing repeatMode", null)
                    }
                }
                "getPlayerState" -> {
                    getPlayerState(result)
                }
                "isConnected" -> {
                    result.success(spotifyAppRemote?.isConnected ?: false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun connectToSpotifyRemote(clientId: String, redirectUrl: String, result: MethodChannel.Result) {
        val connectionParams = ConnectionParams.Builder(clientId)
            .setRedirectUri(redirectUrl)
            .showAuthView(true)
            .build()

        SpotifyAppRemote.connect(this, connectionParams, object : Connector.ConnectionListener {
            override fun onConnected(appRemote: SpotifyAppRemote) {
                spotifyAppRemote = appRemote
                subscribeToPlayerState()
                result.success(true)
            }

            override fun onFailure(throwable: Throwable) {
                result.error("CONNECTION_FAILED", throwable.message, null)
            }
        })
    }

    private fun subscribeToPlayerState() {
        spotifyAppRemote?.let { remote ->
            playerStateSubscription = remote.playerApi.subscribeToPlayerState()
                .setEventCallback { playerState ->
                    val stateMap = mapOf(
                        "track" to mapOf(
                            "name" to playerState.track.name,
                            "uri" to playerState.track.uri,
                            "artist" to mapOf(
                                "name" to playerState.track.artist.name,
                                "uri" to playerState.track.artist.uri
                            ),
                            "imageUri" to playerState.track.imageUri.raw,
                            "duration" to playerState.track.duration
                        ),
                        "isPaused" to playerState.isPaused,
                        "playbackPosition" to playerState.playbackPosition,
                        "isShuffling" to playerState.playbackOptions.isShuffling,
                        "repeatMode" to playerState.playbackOptions.repeatMode
                    )
                    
                    methodChannel?.invokeMethod("playerStateChanged", stateMap)
                }
        }
    }

    private fun disconnectFromSpotify(result: MethodChannel.Result) {
        playerStateSubscription?.cancel()
        spotifyAppRemote?.let {
            SpotifyAppRemote.disconnect(it)
        }
        spotifyAppRemote = null
        result.success(null)
    }

    private fun playTrack(spotifyUri: String?, result: MethodChannel.Result) {
        spotifyAppRemote?.let { remote ->
            if (spotifyUri != null) {
                remote.playerApi.play(spotifyUri)
                    .setResultCallback { result.success(null) }
                    .setErrorCallback { throwable -> 
                        result.error("PLAY_FAILED", throwable.message, null) 
                    }
            } else {
                remote.playerApi.resume()
                    .setResultCallback { result.success(null) }
                    .setErrorCallback { throwable -> 
                        result.error("RESUME_FAILED", throwable.message, null) 
                    }
            }
        } ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun pauseTrack(result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.pause()
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("PAUSE_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun resumeTrack(result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.resume()
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("RESUME_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun skipNext(result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.skipNext()
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("SKIP_NEXT_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun skipPrevious(result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.skipPrevious()
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("SKIP_PREVIOUS_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun seekToPosition(positionMs: Int, result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.seekTo(positionMs.toLong())
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("SEEK_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun setShuffle(shuffle: Boolean, result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.setShuffle(shuffle)
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("SHUFFLE_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun setRepeatMode(repeatMode: Int, result: MethodChannel.Result) {
        val mode = when (repeatMode) {
            1 -> com.spotify.protocol.types.Repeat.ONE
            2 -> com.spotify.protocol.types.Repeat.ALL
            else -> com.spotify.protocol.types.Repeat.OFF
        }
        
        spotifyAppRemote?.playerApi?.setRepeat(mode)
            ?.setResultCallback { result.success(null) }
            ?.setErrorCallback { throwable -> 
                result.error("REPEAT_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    private fun getPlayerState(result: MethodChannel.Result) {
        spotifyAppRemote?.playerApi?.playerState
            ?.setResultCallback { playerState ->
                val stateMap = mapOf(
                    "track" to mapOf(
                        "name" to playerState.track.name,
                        "uri" to playerState.track.uri,
                        "artist" to mapOf(
                            "name" to playerState.track.artist.name,
                            "uri" to playerState.track.artist.uri
                        ),
                        "imageUri" to playerState.track.imageUri.raw,
                        "duration" to playerState.track.duration
                    ),
                    "isPaused" to playerState.isPaused,
                    "playbackPosition" to playerState.playbackPosition,
                    "isShuffling" to playerState.playbackOptions.isShuffling,
                    "repeatMode" to playerState.playbackOptions.repeatMode
                )
                result.success(stateMap)
            }
            ?.setErrorCallback { throwable -> 
                result.error("GET_STATE_FAILED", throwable.message, null) 
            }
            ?: result.error("NOT_CONNECTED", "Spotify not connected", null)
    }

    override fun onDestroy() {
        super.onDestroy()
        playerStateSubscription?.cancel()
        spotifyAppRemote?.let {
            SpotifyAppRemote.disconnect(it)
        }
    }
}
