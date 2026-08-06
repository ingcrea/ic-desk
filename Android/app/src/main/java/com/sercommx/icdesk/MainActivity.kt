package com.sercommx.icdesk

import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.util.DisplayMetrics
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.sercommx.icdesk.models.SessionState
import com.sercommx.icdesk.network.ICDeskWebSocketClient
import com.sercommx.icdesk.services.ScreenCaptureService
import com.sercommx.icdesk.ui.MainDashboard
import com.sercommx.icdesk.viewmodel.ICDeskViewModel

class MainActivity : ComponentActivity() {
    private val viewModel: ICDeskViewModel by viewModels()

    private val screenCaptureLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK && result.data != null) {
            val metrics = resources.displayMetrics
            // Para simplificar esta demo, iniciamos el servicio pasándole los parámetros en el intent
            val intent = Intent(this, ScreenCaptureService::class.java).apply {
                putExtra("resultCode", result.resultCode)
                putExtra("data", result.data)
                putExtra("width", metrics.widthPixels)
                putExtra("height", metrics.heightPixels)
                putExtra("density", metrics.densityDpi)
            }
            startService(intent)
        } else {
            // Permiso denegado, abortamos relay
            viewModel.disconnect()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val sessionState by viewModel.sessionState.collectAsState()
            val pin by viewModel.supportPIN.collectAsState()

            val isConnected = sessionState == SessionState.CONNECTED || sessionState == SessionState.SCREEN_SHARING

            LaunchedEffect(sessionState) {
                if (sessionState == SessionState.SCREEN_SHARING) {
                    val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    screenCaptureLauncher.launch(projectionManager.createScreenCaptureIntent())
                } else if (sessionState == SessionState.CONNECTED) {
                    stopService(Intent(this@MainActivity, ScreenCaptureService::class.java))
                }
            }

            MainDashboard(
                pin = pin,
                isConnected = isConnected,
                onConnectClick = {
                    if (isConnected) {
                        viewModel.disconnect()
                    } else {
                        viewModel.connect(applicationContext)
                    }
                }
            )
        }
    }
}
