package com.sercommx.icdesk.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import android.graphics.Bitmap
import android.graphics.PixelFormat

class ScreenCaptureService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    
    private val scope = CoroutineScope(Dispatchers.IO + Job())
    private var isCapturing = false
    
    companion object {
        const val CHANNEL_ID = "ICDeskCaptureChannel"
        const val NOTIFICATION_ID = 101
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("IC Desk Activo")
            .setContentText("Transmitiendo pantalla...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()
            
        startForeground(NOTIFICATION_ID, notification)
        
        if (intent != null && intent.hasExtra("resultCode")) {
            val resultCode = intent.getIntExtra("resultCode", 0)
            val data = intent.getParcelableExtra<Intent>("data")
            val width = intent.getIntExtra("width", 720)
            val height = intent.getIntExtra("height", 1280)
            val density = intent.getIntExtra("density", 1)
            if (data != null && !isCapturing) {
                startCapture(resultCode, data, width, height, density)
            }
        }
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    fun startCapture(resultCode: Int, data: Intent, width: Int, height: Int, density: Int) {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data)

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ICDeskScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )

        isCapturing = true
        imageReader?.setOnImageAvailableListener({ reader ->
            val image: Image? = reader.acquireLatestImage()
            image?.let {
                scope.launch {
                    processImage(it, width, height)
                    it.close()
                }
            }
        }, null)
    }

    private suspend fun processImage(image: Image, width: Int, height: Int) {
        withContext(Dispatchers.IO) {
            try {
                val planes = image.planes
                val buffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * width

                val bitmap = Bitmap.createBitmap(
                    width + rowPadding / pixelStride,
                    height,
                    Bitmap.Config.ARGB_8888
                )
                bitmap.copyPixelsFromBuffer(buffer)

                // Recortamos el padding
                val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height)

                val stream = ByteArrayOutputStream()
                croppedBitmap.compress(Bitmap.CompressFormat.JPEG, 50, stream)
                val jpegData = stream.toByteArray()

                // Enviar frame vía WebSocket global
                com.sercommx.icdesk.network.ICDeskWebSocketClient.sendBinaryFrame(jpegData)
                // Log.d("ICDesk", "Frame capturado: ${jpegData.size} bytes")

            } catch (e: Exception) {
                Log.e("ICDesk", "Error procesando frame", e)
            }
        }
    }

    override fun onDestroy() {
        isCapturing = false
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        scope.cancel()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Canal de Captura IC Desk",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }
}
