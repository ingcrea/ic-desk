#!/usr/bin/env python3
import sys
import os
import json
import asyncio
import struct
import websockets
from PIL import Image
from io import BytesIO

from PyQt6.QtCore import Qt, QThread, pyqtSignal, QPoint
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLineEdit, QPushButton, QLabel, QMessageBox, QFrame
)
from PyQt6.QtGui import QPixmap, QImage, QPainter, QIcon, QMouseEvent, QKeyEvent

# Configuración del Relay
RELAY_URL = "wss://desk.ingcrea.com"
PANEL_KEY = "SrC0mS0p0rt3#S3cur1tyKey#2026"

class WebSocketClientThread(QThread):
    frame_received = pyqtSignal(bytes)
    status_changed = pyqtSignal(str)
    connection_lost = pyqtSignal()

    def __init__(self, agent_id):
        super().__init__()
        self.agent_id = agent_id
        self.loop = None
        self.websocket = None
        self.running = True

    def run(self):
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self.connect_relay())

    async def connect_relay(self):
        url = f"{RELAY_URL}/?type=panel&id={self.agent_id}&panel_key={PANEL_KEY}"
        self.status_changed.emit("Conectando al relay...")
        
        try:
            async with websockets.connect(url, max_size=20*1024*1024) as ws:
                self.websocket = ws
                self.status_changed.emit("Conexión establecida. Solicitando flujo de video...")
                
                # Enviar comando inicial para activar transmisión en el agente
                await self.send_command("__RELAY_START__")
                
                while self.running:
                    try:
                        message = await ws.recv()
                        if isinstance(message, bytes):
                            self.frame_received.emit(message)
                        else:
                            # Procesar mensajes de texto JSON (status, etc.)
                            data = json.loads(message)
                            if data.get("type") == "agent_offline":
                                self.status_changed.emit("El agente está offline en el relay. Despertándolo...")
                            elif data.get("type") == "connected":
                                self.status_changed.emit("Conectado con éxito al agente remoto.")
                    except websockets.exceptions.ConnectionClosed:
                        break
        except Exception as e:
            self.status_changed.emit(f"Error de conexión: {str(e)}")
        
        self.status_changed.emit("Conexión cerrada.")
        self.connection_lost.emit()

    async def send_command(self, cmd_text):
        if self.websocket and self.websocket.open:
            payload = json.dumps({"type": "command", "command": cmd_text})
            await self.websocket.send(payload)

    def send_command_sync(self, cmd_text):
        if self.loop and self.websocket:
            asyncio.run_coroutine_threadsafe(self.send_command(cmd_text), self.loop)

    def send_input_event(self, event_data):
        if self.loop and self.websocket and self.websocket.open:
            payload = json.dumps(event_data)
            asyncio.run_coroutine_threadsafe(self.websocket.send(payload), self.loop)

    def stop(self):
        self.running = False
        if self.loop:
            self.loop.call_soon_threadsafe(self.loop.stop)


class ScreenCanvas(QWidget):
    def __init__(self, thread_client):
        super().__init__()
        self.thread_client = thread_client
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)
        self.setMouseTracking(True)
        
        self.screen_width = 1920
        self.screen_height = 1080
        self.canvas_pixmap = QPixmap(self.screen_width, self.screen_height)
        self.canvas_pixmap.fill(Qt.GlobalColor.black)
        
        # Escala automática
        self.scale_factor_x = 1.0
        self.scale_factor_y = 1.0

    def resizeEvent(self, event):
        super().resizeEvent(event)
        self.update_scale_factors()

    def update_scale_factors(self):
        if self.width() > 0 and self.height() > 0:
            self.scale_factor_x = self.screen_width / self.width()
            self.scale_factor_y = self.screen_height / self.height()

    def update_frame(self, raw_bytes):
        if len(raw_bytes) < 18:
            return
        
        # Decodificar cabecera binaria de 18 bytes (Big-Endian)
        # col(2B), row(2B), cellW(2B), cellH(2B), x(2B), y(2B), sw(2B), sh(2B)
        col, row, cellW, cellH, x, y, sw, sh = struct.unpack(">HHHHHHHH", raw_bytes[2:18])
        
        # Ajustar lienzo si cambia el tamaño de pantalla del agente
        if sw != self.screen_width or sh != self.screen_height:
            self.screen_width = sw
            self.screen_height = sh
            new_pixmap = QPixmap(sw, sh)
            new_pixmap.fill(Qt.GlobalColor.black)
            # Copiar lo existente
            painter = QPainter(new_pixmap)
            painter.drawPixmap(0, 0, self.canvas_pixmap)
            painter.end()
            self.canvas_pixmap = new_pixmap
            self.update_scale_factors()

        # Decodificar JPEG
        jpeg_data = raw_bytes[18:]
        pixmap_cell = QPixmap()
        if pixmap_cell.loadFromData(jpeg_data, "JPEG"):
            # Dibujar el fragmento en el lienzo principal
            painter = QPainter(self.canvas_pixmap)
            painter.drawPixmap(x, y, pixmap_cell)
            painter.end()
            self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        # Dibujar el lienzo principal escalado al tamaño de la ventana
        painter.drawPixmap(self.rect(), self.canvas_pixmap)
        painter.end()

    # ── Envío de Eventos de Mouse y Teclado ───────────────────────────────────

    def mouseMoveEvent(self, event: QMouseEvent):
        rx = int(event.position().x() * self.scale_factor_x)
        ry = int(event.position().y() * self.scale_factor_y)
        self.thread_client.send_input_event({
            "type": "mouse_move",
            "x": rx,
            "y": ry
        })

    def mousePressEvent(self, event: QMouseEvent):
        self.handle_mouse_click(event, True)

    def mouseReleaseEvent(self, event: QMouseEvent):
        self.handle_mouse_click(event, False)

    def handle_mouse_click(self, event: QMouseEvent, is_down):
        rx = int(event.position().x() * self.scale_factor_x)
        ry = int(event.position().y() * self.scale_factor_y)
        
        btn = "left"
        if event.button() == Qt.MouseButton.RightButton:
            btn = "right"
        elif event.button() == Qt.MouseButton.MiddleButton:
            btn = "middle"

        self.thread_client.send_input_event({
            "type": "mouse_click",
            "x": rx,
            "y": ry,
            "button": btn,
            "down": is_down
        })

    def keyPressEvent(self, event: QKeyEvent):
        self.handle_key_event(event, True)

    def keyReleaseEvent(self, event: QKeyEvent):
        self.handle_key_event(event, False)

    def handle_key_event(self, event: QKeyEvent, is_down):
        # Mapear códigos de tecla de Qt a Windows Virtual Keycodes
        qt_key = event.key()
        vk = self.map_qt_key_to_vk(qt_key)
        if vk:
            self.thread_client.send_input_event({
                "type": "key",
                "key": vk,
                "down": is_down
            })

    def map_qt_key_to_vk(self, qt_key):
        # Mapeo básico de teclas comunes a Virtual Keycodes de Windows
        mapping = {
            Qt.Key.Key_Backspace: 0x08,
            Qt.Key.Key_Tab: 0x09,
            Qt.Key.Key_Clear: 0x0C,
            Qt.Key.Key_Return: 0x0D,
            Qt.Key.Key_Enter: 0x0D,
            Qt.Key.Key_Shift: 0x10,
            Qt.Key.Key_Control: 0x11,
            Qt.Key.Key_Alt: 0x12,
            Qt.Key.Key_Pause: 0x13,
            Qt.Key.Key_CapsLock: 0x14,
            Qt.Key.Key_Escape: 0xFF, # Nuestro agente usa 0xFF como señal escape
            Qt.Key.Key_Space: 0x20,
            Qt.Key.Key_PageUp: 0x21,
            Qt.Key.Key_PageDown: 0x22,
            Qt.Key.Key_End: 0x23,
            Qt.Key.Key_Home: 0x24,
            Qt.Key.Key_Left: 0x25,
            Qt.Key.Key_Up: 0x26,
            Qt.Key.Key_Right: 0x27,
            Qt.Key.Key_Down: 0x28,
            Qt.Key.Key_Insert: 0x2D,
            Qt.Key.Key_Delete: 0x2E,
            # Letras A-Z
            Qt.Key.Key_A: 0x41, Qt.Key.Key_B: 0x42, Qt.Key.Key_C: 0x43, Qt.Key.Key_D: 0x44,
            Qt.Key.Key_E: 0x45, Qt.Key.Key_F: 0x46, Qt.Key.Key_G: 0x47, Qt.Key.Key_H: 0x48,
            Qt.Key.Key_I: 0x49, Qt.Key.Key_J: 0x4A, Qt.Key.Key_K: 0x4B, Qt.Key.Key_L: 0x4C,
            Qt.Key.Key_M: 0x4D, Qt.Key.Key_N: 0x4E, Qt.Key.Key_O: 0x4F, Qt.Key.Key_P: 0x50,
            Qt.Key.Key_Q: 0x51, Qt.Key.Key_R: 0x52, Qt.Key.Key_S: 0x53, Qt.Key.Key_T: 0x54,
            Qt.Key.Key_U: 0x55, Qt.Key.Key_V: 0x56, Qt.Key.Key_W: 0x57, Qt.Key.Key_X: 0x58,
            Qt.Key.Key_Y: 0x59, Qt.Key.Key_Z: 0x5A,
        }
        return mapping.get(qt_key, None)


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("IC-Desk Viewer — Ingenieria Creativa")
        self.resize(1024, 768)
        self.setStyleSheet("background-color: #060913; color: #E2E8F0;")
        
        # Logo de IngCrea
        self.logo_path = "/home/ingcrea/github/ic-desk/logo-texto-blanco.png"
        if os.path.exists(self.logo_path):
            self.setWindowIcon(QIcon(self.logo_path))

        self.thread_client = None
        self.setup_ui()

    def setup_ui(self):
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout_main = QVBoxLayout(self.central_widget)
        
        # ── BARRA DE CONEXIÓN SUPERIOR ────────────────────────────────────────
        self.conn_bar = QFrame()
        self.conn_bar.setStyleSheet("background-color: #0F172A; border-bottom: 2px solid #1E293B;")
        layout_bar = QHBoxLayout(self.conn_bar)
        
        self.lbl_id = QLabel("Puesto ID:")
        self.lbl_id.setStyleSheet("font-weight: bold; font-size: 13px; color: #38BDF8;")
        
        self.input_id = QLineEdit()
        self.input_id.setPlaceholderText("Ej. 8122-8714")
        self.input_id.setStyleSheet("background-color: #1E293B; color: #FFF; border: 1px solid #475569; padding: 6px; border-radius: 4px;")
        
        self.btn_connect = QPushButton("Conectar")
        self.btn_connect.setStyleSheet("background-color: #0284C7; color: #FFF; font-weight: bold; padding: 6px 16px; border-radius: 4px; border: none;")
        self.btn_connect.clicked.connect(self.toggle_connection)
        
        self.lbl_status = QLabel("Desconectado")
        self.lbl_status.setStyleSheet("color: #94A3B8; font-size: 12px; margin-left: 12px;")

        layout_bar.addWidget(self.lbl_id)
        layout_bar.addWidget(self.input_id)
        layout_bar.addWidget(self.btn_connect)
        layout_bar.addWidget(self.lbl_status)
        layout_bar.addStretch()

        # ── LIENZO CANVAS DE VIDEO ───────────────────────────────────────────
        self.canvas = QWidget()
        self.canvas_layout = QVBoxLayout(self.canvas)
        self.canvas_layout.setContentsMargins(0, 0, 0, 0)
        
        # Pantalla de bienvenida / Espera
        self.welcome_screen = QLabel("Ingresa el ID del cliente para iniciar el control remoto...")
        self.welcome_screen.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.welcome_screen.setStyleSheet("font-size: 16px; color: #64748B; font-weight: bold;")
        self.canvas_layout.addWidget(self.welcome_screen)

        self.layout_main.addWidget(self.conn_bar)
        self.layout_main.addWidget(self.canvas, 1)

    def toggle_connection(self):
        if self.thread_client and self.thread_client.isRunning():
            # Desconectar
            self.thread_client.stop()
            self.thread_client.wait()
            self.on_disconnected()
        else:
            # Conectar
            agent_id = self.input_id.text().strip()
            if not agent_id:
                QMessageBox.warning(self, "Validación", "Por favor ingresa un ID válido.")
                return

            self.btn_connect.setText("Desconectar")
            self.btn_connect.setStyleSheet("background-color: #DC2626; color: #FFF; font-weight: bold; padding: 6px 16px; border-radius: 4px;")
            self.input_id.setEnabled(False)

            self.thread_client = WebSocketClientThread(agent_id)
            self.thread_client.status_changed.connect(self.on_status_changed)
            self.thread_client.connection_lost.connect(self.on_disconnected)
            
            # Crear y configurar el canvas de pantalla activa
            self.screen_canvas = ScreenCanvas(self.thread_client)
            self.thread_client.frame_received.connect(self.screen_canvas.update_frame)

            # Reemplazar vista de bienvenida
            self.welcome_screen.hide()
            self.canvas_layout.addWidget(self.screen_canvas)

            self.thread_client.start()

    def on_status_changed(self, status_text):
        self.lbl_status.setText(status_text)

    def on_disconnected(self):
        self.lbl_status.setText("Desconectado.")
        self.btn_connect.setText("Conectar")
        self.btn_connect.setStyleSheet("background-color: #0284C7; color: #FFF; font-weight: bold; padding: 6px 16px; border-radius: 4px;")
        self.input_id.setEnabled(True)
        
        # Eliminar el canvas y mostrar bienvenida
        if hasattr(self, 'screen_canvas'):
            self.screen_canvas.hide()
            self.canvas_layout.removeWidget(self.screen_canvas)
            self.screen_canvas.deleteLater()
            del self.screen_canvas
            
        self.welcome_screen.show()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
