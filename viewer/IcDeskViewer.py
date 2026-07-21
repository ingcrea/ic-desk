#!/usr/bin/env python3
import sys
import os
import json
import asyncio
import struct
import urllib.request
import websockets
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QTimer, QSize
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLineEdit, QPushButton, QLabel, QMessageBox, QFrame, QStackedWidget,
    QScrollArea, QSplitter, QTextEdit
)
from PyQt6.QtGui import QPixmap, QImage, QPainter, QIcon, QMouseEvent, QKeyEvent, QFont

# Configuración del servidor
SERVER_URL = "https://desk.ingcrea.com"
RELAY_URL = "wss://desk.ingcrea.com"
PANEL_KEY = "SrC0mS0p0rt3#S3cur1tyKey#2026"


class WebSocketClientThread(QThread):
    frame_received = pyqtSignal(bytes)
    status_changed = pyqtSignal(str)
    connection_lost = pyqtSignal()
    console_output_received = pyqtSignal(str)

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
                self.status_changed.emit("Conectando con el agente remoto...")
                
                # Iniciar streaming
                await self.send_command("__RELAY_START__")
                
                while self.running:
                    try:
                        message = await ws.recv()
                        if isinstance(message, bytes):
                            self.frame_received.emit(message)
                        else:
                            # Mensajes de texto JSON
                            data = json.loads(message)
                            if data.get("type") == "agent_offline":
                                self.status_changed.emit("El agente está offline. Despertándolo...")
                            elif data.get("type") == "connected":
                                self.status_changed.emit("En línea — Solicitando flujo de video...")
                            elif data.get("type") == "cmd_output":
                                # Salida de consola
                                self.console_output_received.emit(data.get("output", ""))
                    except websockets.exceptions.ConnectionClosed:
                        break
        except Exception as e:
            self.status_changed.emit(f"Error: {str(e)}")
        
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
        
        col, row, cellW, cellH, x, y, sw, sh = struct.unpack(">HHHHHHHH", raw_bytes[2:18])
        
        if sw != self.screen_width or sh != self.screen_height:
            self.screen_width = sw
            self.screen_height = sh
            new_pixmap = QPixmap(sw, sh)
            new_pixmap.fill(Qt.GlobalColor.black)
            painter = QPainter(new_pixmap)
            painter.drawPixmap(0, 0, self.canvas_pixmap)
            painter.end()
            self.canvas_pixmap = new_pixmap
            self.update_scale_factors()

        jpeg_data = raw_bytes[18:]
        pixmap_cell = QPixmap()
        if pixmap_cell.loadFromData(jpeg_data, "JPEG"):
            painter = QPainter(self.canvas_pixmap)
            painter.drawPixmap(x, y, pixmap_cell)
            painter.end()
            self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.drawPixmap(self.rect(), self.canvas_pixmap)
        painter.end()

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
        qt_key = event.key()
        vk = self.map_qt_key_to_vk(qt_key)
        if vk:
            self.thread_client.send_input_event({
                "type": "key",
                "key": vk,
                "down": is_down
            })

    def map_qt_key_to_vk(self, qt_key):
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
            Qt.Key.Key_Escape: 0xFF,
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
        self.setStyleSheet("""
            /* Estilos Globales */
            QMainWindow {
                background-color: #090D1A;
            }
            QWidget {
                color: #F8FAFC;
                font-family: 'Outfit', 'Inter', 'Segoe UI', sans-serif;
            }
            
            /* Textos */
            QLabel {
                font-size: 13px;
            }
            
            /* Inputs / Campos de Entrada */
            QLineEdit {
                background-color: #13192B;
                color: #F8FAFC;
                border: 1px solid #1E293B;
                border-radius: 6px;
                padding: 10px 14px;
                selection-background-color: #38BDF8;
            }
            QLineEdit:focus {
                border: 1px solid #38BDF8;
                background-color: #172036;
            }
            
            /* Botones Comunes */
            QPushButton {
                background-color: #1E293B;
                color: #F8FAFC;
                border: 1px solid #334155;
                border-radius: 6px;
                padding: 10px 18px;
                font-weight: bold;
                font-size: 13px;
            }
            QPushButton:hover {
                background-color: #334155;
                border: 1px solid #475569;
            }
            QPushButton:pressed {
                background-color: #0F172A;
            }
            
            /* Botones de Acento */
            QPushButton#btn-primary {
                background-color: #0284C7;
                border: none;
                color: #FFF;
            }
            QPushButton#btn-primary:hover {
                background-color: #0369A1;
            }
            QPushButton#btn-success {
                background-color: #059669;
                border: none;
                color: #FFF;
            }
            QPushButton#btn-success:hover {
                background-color: #047857;
            }
            QPushButton#btn-danger {
                background-color: #E11D48;
                border: none;
                color: #FFF;
            }
            QPushButton#btn-danger:hover {
                background-color: #BE123C;
            }
            
            /* Contenedores y Cards */
            QFrame#card {
                background-color: #13192B;
                border: 1px solid #1E293B;
                border-radius: 12px;
            }
            QFrame#conn-bar, QFrame#viewer-bar {
                background-color: #0F172A;
                border-bottom: 2px solid #1E293B;
            }
            
            /* Consola */
            QTextEdit {
                background-color: #020617;
                color: #10B981;
                border: 1px solid #1E293B;
                border-radius: 6px;
                padding: 10px;
            }
            
            /* Scroll Area */
            QScrollArea {
                border: none;
                background-color: transparent;
            }
            QScrollBar:vertical {
                border: none;
                background: #090D1A;
                width: 8px;
                margin: 0px;
            }
            QScrollBar::handle:vertical {
                background: #1E293B;
                min-height: 20px;
                border-radius: 4px;
            }
            QScrollBar::handle:vertical:hover {
                background: #38BDF8;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                border: none;
                background: none;
            }
        """)
        
        self.logo_path = "/home/ingcrea/github/ic-desk/logo-texto-blanco.png"
        if os.path.exists(self.logo_path):
            self.setWindowIcon(QIcon(self.logo_path))

        self.thread_client = None
        self.api_session_token = None

        # Stack de Vistas (Login, Dashboard, Visor)
        self.stacked_widget = QStackedWidget()
        self.setCentralWidget(self.stacked_widget)

        self.setup_login_view()
        self.setup_dashboard_view()
        self.setup_viewer_view()

    # ── 1. VISTA DE LOGIN ─────────────────────────────────────────────────────
    def setup_login_view(self):
        self.view_login = QWidget()
        layout = QVBoxLayout(self.view_login)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        card = QFrame()
        card.setObjectName("card")
        card.setFixedWidth(400)
        card_layout = QVBoxLayout(card)
        card_layout.setContentsMargins(32, 32, 32, 32)
        card_layout.setSpacing(16)

        # Logo
        self.login_logo = QLabel()
        if os.path.exists(self.logo_path):
            pix = QPixmap(self.logo_path).scaled(140, 140, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
            self.login_logo.setPixmap(pix)
            self.login_logo.setAlignment(Qt.AlignmentFlag.AlignCenter)
            card_layout.addWidget(self.login_logo)

        # Título
        lbl_title = QLabel("IC-Desk")
        lbl_title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        lbl_title.setStyleSheet("font-size: 28px; font-weight: 800; color: #FFF;")
        card_layout.addWidget(lbl_title)

        lbl_subtitle = QLabel("Centro de Operaciones y Soporte por IngCrea")
        lbl_subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        lbl_subtitle.setStyleSheet("font-size: 13px; color: #94A3B8; margin-bottom: 8px;")
        card_layout.addWidget(lbl_subtitle)

        # Campos
        self.input_user = QLineEdit()
        self.input_user.setPlaceholderText("Usuario Autorizado")
        card_layout.addWidget(self.input_user)

        self.input_pass = QLineEdit()
        self.input_pass.setPlaceholderText("Contraseña de Red")
        self.input_pass.setEchoMode(QLineEdit.EchoMode.Password)
        card_layout.addWidget(self.input_pass)

        # Botón
        btn_login = QPushButton("Autenticar Credenciales")
        btn_login.setObjectName("btn-primary")
        btn_login.clicked.connect(self.attempt_login)
        card_layout.addWidget(btn_login)

        layout.addWidget(card)
        self.stacked_widget.addWidget(self.view_login)

    def attempt_login(self):
        user = self.input_user.text().strip()
        pwd = self.input_pass.text().strip()
        if not user or not pwd:
            QMessageBox.warning(self, "Acceso", "Por favor ingresa tus credenciales.")
            return

        try:
            url = f"{SERVER_URL}/soporte/login"
            data = json.dumps({"user": user, "pass": pwd}).encode('utf-8')
            headers = {
                'Content-Type': 'application/json',
                'x-ic-desk-app': 'SrC0mS0p0rt3#S3cur1tyKey#2026'
            }
            req = urllib.request.Request(url, data=data, headers=headers, method='POST')
            with urllib.request.urlopen(req, timeout=5) as res:
                # Leer y guardar cookie de sesión soporte_session
                cookie_header = res.info().get('Set-Cookie')
                if cookie_header:
                    # Extraer el valor del soporte_session cookie
                    parts = cookie_header.split(';')
                    for part in parts:
                        if 'soporte_session' in part:
                            self.api_session_token = part.strip()
                            break
                
                resp = json.loads(res.read().decode('utf-8'))
                if resp.get("success"):
                    self.on_login_success()
                else:
                    QMessageBox.critical(self, "Error", "Credenciales incorrectas.")
        except Exception as e:
            QMessageBox.critical(self, "Error de Acceso", f"No se pudo autenticar: {str(e)}")

    def on_login_success(self):
        self.stacked_widget.setCurrentWidget(self.view_dashboard)
        self.start_dashboard_polling()

    # ── 2. VISTA DE DASHBOARD (LISTA DE AGENTES) ──────────────────────────────
    def setup_dashboard_view(self):
        self.view_dashboard = QWidget()
        layout = QVBoxLayout(self.view_dashboard)
        layout.setContentsMargins(24, 24, 24, 24)

        # Cabecera
        header = QHBoxLayout()
        lbl_dash_title = QLabel("Dashboard de Soporte")
        lbl_dash_title.setStyleSheet("font-size: 24px; font-weight: bold; color: #FFF;")
        header.addWidget(lbl_dash_title)

        header.addStretch()

        self.btn_refresh = QPushButton("Actualizar Lista")
        self.btn_refresh.clicked.connect(self.fetch_agents)
        header.addWidget(self.btn_refresh)
        layout.addLayout(header)

        # Listado de agentes
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        
        self.list_container = QWidget()
        self.layout_list = QVBoxLayout(self.list_container)
        self.layout_list.setAlignment(Qt.AlignmentFlag.AlignTop)
        self.scroll_area.setWidget(self.list_container)

        layout.addWidget(self.scroll_area)
        self.stacked_widget.addWidget(self.view_dashboard)

        # Timer para polling automático
        self.poll_timer = QTimer()
        self.poll_timer.timeout.connect(self.fetch_agents)

    def start_dashboard_polling(self):
        self.fetch_agents()
        self.poll_timer.start(5000) # Cada 5 segundos

    def fetch_agents(self):
        try:
            url = f"{SERVER_URL}/soporte/agentes"
            headers = {}
            if self.api_session_token:
                headers['Cookie'] = self.api_session_token
            else:
                headers['x-sercom-api-key'] = PANEL_KEY
            
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=3) as res:
                agents = json.loads(res.read().decode('utf-8'))
                self.update_agents_list(agents)
        except Exception as e:
            self.layout_list.addWidget(QLabel(f"Error al obtener agentes: {str(e)}"))

    def update_agents_list(self, agents):
        # Limpiar lista anterior
        while self.layout_list.count():
            child = self.layout_list.takeAt(0)
            if child.widget():
                child.widget().deleteLater()

        if not agents:
            lbl_empty = QLabel("No hay agentes activos o en espera en este momento.")
            lbl_empty.setStyleSheet("color: #64748B; font-size: 14px; padding: 20px;")
            self.layout_list.addWidget(lbl_empty)
            return

        for aid, info in agents.items():
            card = QFrame()
            card.setObjectName("card")
            card_layout = QHBoxLayout(card)
            card_layout.setContentsMargins(16, 16, 16, 16)

            # Icono de Monitor
            lbl_icon = QLabel("🖥️")
            lbl_icon.setStyleSheet("font-size: 24px;")
            card_layout.addWidget(lbl_icon)

            # Información del Host
            details = QVBoxLayout()
            admin_suffix = "  🛡️ [ADMIN]" if info.get("isAdmin") else ""
            lbl_name = QLabel(f"{info.get('hostname', 'Puesto Desconocido')} ({aid}){admin_suffix}")
            if info.get("isAdmin"):
                lbl_name.setStyleSheet("font-weight: bold; font-size: 15px; color: #10B981;")
            else:
                lbl_name.setStyleSheet("font-weight: bold; font-size: 15px; color: #FFF;")
            details.addWidget(lbl_name)

            # Specs
            health = info.get("health")
            if health:
                specs_text = f"CPU: {health.get('cpu', 'N/A')} | RAM: {health.get('ramGB', 'N/A')} GB | OS: Windows"
            else:
                specs_text = "Esperando telemetría de hardware..."
            
            lbl_specs = QLabel(specs_text)
            lbl_specs.setStyleSheet("color: #94A3B8; font-size: 12px;")
            details.addWidget(lbl_specs)
            card_layout.addLayout(details, 1)

            # Botón de Conectar / Controlar
            btn_ctrl = QPushButton("Controlar")
            btn_ctrl.setObjectName("btn-primary")
            btn_ctrl.clicked.connect(lambda checked, agent_id=aid: self.start_viewer_session(agent_id))
            card_layout.addWidget(btn_ctrl)

            self.layout_list.addWidget(card)

    # ── 3. VISTA DE VISOR ACTIVO (LIENZO + CONSOLA POWERSHELL) ────────────────
    def setup_viewer_view(self):
        self.view_viewer = QWidget()
        layout = QVBoxLayout(self.view_viewer)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Barra superior del visor
        self.viewer_bar = QFrame()
        self.viewer_bar.setObjectName("viewer-bar")
        layout_vbar = QHBoxLayout(self.viewer_bar)
        
        self.btn_back = QPushButton("◀ Volver al Dashboard")
        self.btn_back.clicked.connect(self.stop_viewer_session)
        layout_vbar.addWidget(self.btn_back)

        self.lbl_active_agent = QLabel("Controlando: -")
        self.lbl_active_agent.setStyleSheet("font-weight: bold; font-size: 13px; color: #38BDF8; margin-left: 12px;")
        layout_vbar.addWidget(self.lbl_active_agent)

        self.lbl_viewer_status = QLabel("Conectando...")
        self.lbl_viewer_status.setStyleSheet("color: #94A3B8; font-size: 12px; margin-left: 12px;")
        layout_vbar.addWidget(self.lbl_viewer_status)
        layout_vbar.addStretch()

        # Botón de Elevación UAC bajo demanda
        self.btn_elevate_uac = QPushButton("⚡ Solicitar Elevación UAC")
        self.btn_elevate_uac.setObjectName("btn-danger")
        self.btn_elevate_uac.clicked.connect(self.request_uac_elevation)
        layout_vbar.addWidget(self.btn_elevate_uac)

        layout.addWidget(self.viewer_bar)

        # Splitter para Lienzo (Arriba) y Consola PowerShell (Abajo)
        self.splitter = QSplitter(Qt.Orientation.Vertical)
        self.splitter.setStyleSheet("QSplitter::handle { background-color: #1E293B; height: 4px; }")

        # Contenedor del Lienzo de Video
        self.video_container = QWidget()
        self.video_container.setStyleSheet("background-color: #060913;")
        self.layout_video = QVBoxLayout(self.video_container)
        self.layout_video.setContentsMargins(0, 0, 0, 0)
        
        self.splitter.addWidget(self.video_container)

        # Consola PowerShell integrada (Igual al panel web)
        self.console_widget = QWidget()
        self.console_widget.setObjectName("card")
        layout_console = QVBoxLayout(self.console_widget)
        layout_console.setContentsMargins(12, 12, 12, 12)
        layout_console.setSpacing(8)

        lbl_console_title = QLabel("PowerShell Consola de Respaldo")
        lbl_console_title.setStyleSheet("font-weight: bold; color: #38BDF8; font-size: 12px;")
        layout_console.addWidget(lbl_console_title)

        self.console_log = QTextEdit()
        self.console_log.setReadOnly(True)
        self.console_log.setFont(QFont("JetBrains Mono", 10))
        layout_console.addWidget(self.console_log, 1)

        # Entrada de comando
        input_layout = QHBoxLayout()
        self.input_cmd = QLineEdit()
        self.input_cmd.setPlaceholderText("Escribe comando PowerShell y presiona Enter...")
        self.input_cmd.setFont(QFont("JetBrains Mono", 10))
        self.input_cmd.returnPressed.connect(self.send_powershell_command)
        input_layout.addWidget(self.input_cmd, 1)

        self.btn_send_cmd = QPushButton("Enviar")
        self.btn_send_cmd.setObjectName("btn-success")
        self.btn_send_cmd.clicked.connect(self.send_powershell_command)
        input_layout.addWidget(self.btn_send_cmd)

        layout_console.addLayout(input_layout)
        self.splitter.addWidget(self.console_widget)

        # Proporciones iniciales del Splitter (70% video, 30% consola)
        self.splitter.setSizes([550, 200])
        layout.addWidget(self.splitter)

        self.stacked_widget.addWidget(self.view_viewer)

    def start_viewer_session(self, agent_id):
        self.poll_timer.stop() # Detener polling de dashboard
        self.stacked_widget.setCurrentWidget(self.view_viewer)
        self.lbl_active_agent.setText(f"Controlando: {agent_id}")
        self.lbl_viewer_status.setText("Conectando...")
        self.console_log.clear()

        # Crear WebSocket client
        self.thread_client = WebSocketClientThread(agent_id)
        self.thread_client.status_changed.connect(self.on_viewer_status_changed)
        self.thread_client.connection_lost.connect(self.stop_viewer_session)
        self.thread_client.console_output_received.connect(self.append_console_output)

        # Crear y añadir el canvas de pantalla interactivo
        self.screen_canvas = ScreenCanvas(self.thread_client)
        self.thread_client.frame_received.connect(self.screen_canvas.update_frame)
        self.layout_video.addWidget(self.screen_canvas)

        self.thread_client.start()

    def on_viewer_status_changed(self, status_text):
        self.lbl_viewer_status.setText(status_text)

    def append_console_output(self, text_output):
        self.console_log.append(text_output.strip())

    def send_powershell_command(self):
        cmd = self.input_cmd.text().strip()
        if not cmd:
            return
        
        self.console_log.append(f"\nPS > {cmd}")
        self.thread_client.send_command_sync(cmd)
        self.input_cmd.clear()

    def stop_viewer_session(self):
        if self.thread_client:
            self.thread_client.stop()
            self.thread_client.wait()
            self.thread_client = None

        if hasattr(self, 'screen_canvas'):
            self.screen_canvas.hide()
            self.layout_video.removeWidget(self.screen_canvas)
            self.screen_canvas.deleteLater()
            del self.screen_canvas

        self.stacked_widget.setCurrentWidget(self.view_dashboard)
        self.start_dashboard_polling()

    def request_uac_elevation(self):
        reply = QMessageBox.question(
            self, 'Elevación de Privilegios UAC',
            '¿Deseas enviar la solicitud de elevación de privilegios UAC al cliente remoto?\n\n'
            'Si el cliente tiene UAC activo, se le presentará un cuadro de diálogo para confirmar.',
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No
        )
        if reply == QMessageBox.StandardButton.Yes:
            self.console_log.append("\n[SISTEMA] Enviando comando de elevación remota (__ELEVATE__)...")
            self.thread_client.send_command_sync("__ELEVATE__")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
