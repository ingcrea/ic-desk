package com.sercommx.icdesk.network

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

object ICDeskApiClient {
    private const val BASE_URL = "https://desk.ingcrea.com/soporte"
    private const val SECURE_HASH_KEY = "ICAgentToken2026SecureHashKey"

    suspend fun registerAgent(agentId: String, hostname: String, os: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val url = URL("$BASE_URL/register")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("x-ic-agent-token", SECURE_HASH_KEY)
            connection.doOutput = true

            val payload = JSONObject().apply {
                put("id", agentId)
                put("hostname", hostname)
                put("os", os)
                put("isAdmin", false)
                put("health", JSONObject.NULL)
            }

            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(payload.toString())
                writer.flush()
            }

            return@withContext connection.responseCode == 200
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext false
        }
    }

    suspend fun pollCommands(agentId: String): JSONObject? = withContext(Dispatchers.IO) {
        try {
            val ts = System.currentTimeMillis()
            val url = URL("$BASE_URL/poll?id=$agentId&_t=$ts")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.readTimeout = 35000
            connection.connectTimeout = 10000
            connection.setRequestProperty("x-ic-agent-token", SECURE_HASH_KEY)

            if (connection.responseCode == 200) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                if (response.isNotEmpty() && !response.contains("\"command\":null")) {
                    return@withContext JSONObject(response).optJSONObject("command")
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return@withContext null
    }

    suspend fun sendResponse(agentId: String, cmdId: String, output: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val url = URL("$BASE_URL/response")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("x-ic-agent-token", SECURE_HASH_KEY)
            connection.doOutput = true

            val safeOutput = output
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")

            val payload = JSONObject().apply {
                put("id", agentId)
                put("cmdId", cmdId)
                put("output", safeOutput)
            }

            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(payload.toString())
                writer.flush()
            }

            return@withContext connection.responseCode == 200
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext false
        }
    }
}
