package com.sercommx.icdesk.models

enum class SessionState {
    DISCONNECTED,
    CONNECTED,
    SCREEN_SHARING,
    ERROR
}

data class RemoteCommand(
    val type: String,
    val payload: Map<String, Any>? = null
)
