package com.sercommx.icdesk.viewmodel

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sercommx.icdesk.models.SessionState
import com.sercommx.icdesk.network.ICDeskApiClient
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ICDeskViewModel : ViewModel() {
    private val _sessionState = MutableStateFlow(SessionState.DISCONNECTED)
    val sessionState: StateFlow<SessionState> = _sessionState.asStateFlow()

    private val _supportPIN = MutableStateFlow("")
    val supportPIN: StateFlow<String> = _supportPIN.asStateFlow()

    private var isPolling = false

    @SuppressLint("HardwareIds")
    fun connect(context: Context) {
        if (_sessionState.value == SessionState.CONNECTED || isPolling) return

        viewModelScope.launch {
            _sessionState.value = SessionState.DISCONNECTED
            
            // Generar Agent ID nativo de Android
            val agentId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            _supportPIN.value = agentId

            val model = Build.MODEL
            val osVersion = "Android ${Build.VERSION.RELEASE}"
            
            isPolling = true
            
            // Loop de Conexión
            while (isPolling) {
                val registered = ICDeskApiClient.registerAgent(
                    agentId = agentId,
                    hostname = model,
                    os = osVersion
                )

                if (registered) {
                    _sessionState.value = SessionState.CONNECTED
                    
                    // Conectar WebSocket paralelo para streaming binario y comandos de alta velocidad
                    com.sercommx.icdesk.network.ICDeskWebSocketClient.connect(agentId, model)
                    
                    // Iniciar Long Polling
                    while (isPolling) {
                        val cmd = ICDeskApiClient.pollCommands(agentId)
                        if (cmd != null) {
                            val cmdId = cmd.optString("id")
                            val cmdText = cmd.optString("text")
                            
                            if (cmdId.isNotEmpty() && cmdText.isNotEmpty()) {
                                val output = handlePolledCommand(cmdText)
                                ICDeskApiClient.sendResponse(agentId, cmdId, output)
                            }
                        } else {
                            // Si falló por timeout normal (sin comandos), intentará de nuevo rápido,
                            // si falló por error de red, delay previene spam
                            delay(500)
                        }
                    }
                } else {
                    _sessionState.value = SessionState.ERROR
                    delay(5000) // Falló registro, reintentar en 5s
                }
            }
        }
    }

    private suspend fun handlePolledCommand(cmdText: String): String {
        return when {
            cmdText.startsWith("__RELAY_START__") -> {
                _sessionState.value = SessionState.SCREEN_SHARING
                // TODO: Iniciar MediaProjection Service
                "RELAY_ACTIVE"
            }
            cmdText.startsWith("__RELAY_STOP__") -> {
                _sessionState.value = SessionState.CONNECTED
                // TODO: Detener MediaProjection Service
                "RELAY_STOPPED"
            }
            cmdText.startsWith("__ELEVATE__") -> {
                "ELEVATION_NOT_SUPPORTED_ANDROID"
            }
            else -> {
                "COMMAND_NOT_SUPPORTED_ON_THIS_PLATFORM"
            }
        }
    }

    fun disconnect() {
        isPolling = false
        _sessionState.value = SessionState.DISCONNECTED
        com.sercommx.icdesk.network.ICDeskWebSocketClient.disconnect()
    }
}
