package com.sercommx.icdesk.network

import kotlinx.coroutines.*
import okhttp3.*
import okio.ByteString.Companion.toByteString
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Cliente WebSocket para conectarse al servidor IC Desk (soporte.sercommx.com:6001).
 * Utiliza OkHttp y Corrutinas para reconexión asíncrona.
 */
object ICDeskWebSocketClient {

    private var webSocket: WebSocket? = null
    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .build()
        
    private var isConnected = false
    private val scope = CoroutineScope(Dispatchers.IO + Job())
    
    private var currentAgentId: String = ""
    private var currentAgentName: String = ""

    fun connect(agentId: String, agentName: String) {
        if (isConnected) return
        currentAgentId = agentId
        currentAgentName = agentName
        
        val url = "wss://desk.ingcrea.com?type=agent&id=$agentId&agent_token=ICAgentToken2026SecureHashKey"

        val request = Request.Builder().url(url).build()

        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                isConnected = true
                sendRegistration()
                startHeartbeat()
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                // Manejar comandos entrantes (ej. __RELAY_START__)
                println("Mensaje recibido: $text")
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                isConnected = false
                reconnect()
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                isConnected = false
                reconnect()
            }
        })
    }

    private fun sendRegistration() {
        val registerPayload = JSONObject().apply {
            put("type", "agent_register")
            put("agentId", currentAgentId)
            put("name", currentAgentName)
            put("os", "Android")
        }
        webSocket?.send(registerPayload.toString())
    }

    private fun startHeartbeat() {
        scope.launch {
            while (isConnected) {
                delay(15_000) // 15 segundos
                val pingPayload = JSONObject().apply {
                    put("type", "ping")
                    put("timestamp", System.currentTimeMillis())
                }
                webSocket?.send(pingPayload.toString())
            }
        }
    }

    private fun reconnect() {
        scope.launch {
            delay(3000) // Backoff simple
            connect(currentAgentId, currentAgentName)
        }
    }
    
    fun disconnect() {
        isConnected = false
        webSocket?.close(1000, "User disconnected")
        webSocket = null
    }

    fun sendBinaryFrame(data: ByteArray) {
        if (isConnected) {
            webSocket?.send(data.toByteString())
        }
    }
}
