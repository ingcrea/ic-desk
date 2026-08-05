# 🚀 IC-Desk Enterprise: Arquitectura Comercial y Hoja de Ruta

*Documento de Planificación Maestra - Última actualización: 1 de Agosto, 2026*

Este documento consolida el estado actual de la plataforma IC-Desk y traza la ruta estratégica para su evolución hacia un producto SaaS B2B Élite.

---

## 🏗️ 1. Estado Actual de la Plataforma (Lo que tenemos hoy)

### 🖥️ Frontend (Panel de Control - Web)
*   **Tecnología:** Astro JS + HTML/Vanilla JS (Cero React/Frameworks pesados).
*   **Motor Visual:** Arquitectura Híbrida (SCSS Modular Élite + Tailwind CSS 4).
*   **Estética:** Glassmorphism profundo, variables atómicas CSS (`.c-layout`, `.c-sidebar`, `.c-card`), colores premium y animaciones de latencia nula.
*   **Módulos Activos:**
    *   **Login:** Validado, con animación de starfield y validaciones de seguridad.
    *   **Dashboard:** Monitoreo en tiempo real de cuadrícula de equipos con indicadores de vida (WebSocket Pulse).
    *   **Consola de Control:** Control remoto de pantalla de baja latencia con WebSocket, inyección de teclado, y barra de consola interactiva.
    *   **Gestión Administrativa:** Módulos de *Usuarios, Empresas, Áreas, Configuración Global y Auditoría* con CRUD conectado a PostgreSQL.

### ⚙️ Backend (Servidor Node.js - SV1)
*   **Ubicación:** `sv1.sercommx.com:6001`.
*   **Tecnología:** Node.js, Express, `ws` (WebSockets).
*   **Base de Datos:** PostgreSQL (Gestión de tenants, empresas, usuarios, logs).
*   **Lógica Core:**
    *   Normalización de IDs de agente deterministas.
    *   Proxy WebSocket bidireccional puro entre el Cliente (Agente) y el Panel Web (Soporte).
    *   Persistencia de sesiones y enrutamiento seguro de comandos (IRM, Shell).

### 🛡️ Clientes / Agentes Nativos
*   **Windows (C# .NET):**
    *   Motor de transmisión de video híbrido (GDI+ Clásico + DXGI/H.264 acelerado por GPU).
    *   Generación de ID Determinista (IOKit / Serial de hardware).
    *   Actualización OTA (Over The Air) remota y silenciosa.
    *   Ejecución de scripts PowerShell / CMD de diagnóstico.
*   **Apple Ecosystem (macOS / iOS) [En Progreso]:**
    *   Desarrollo en Swift nativo.
    *   Captura con `ReplayKit` / `ScreenCaptureKit`.

---

## 🔭 2. Visión a Futuro: El Camino a un SaaS Élite

Para posicionar a IC-Desk como una alternativa superior a TeamViewer, AnyDesk o RustDesk en el ámbito corporativo (B2B), debemos transicionar de una "herramienta útil" a un **Ecosistema de Operaciones de TI Automático y Escalable**.

### FASE 1: Estabilización, Refinamiento y Multi-Tenancy (Corto Plazo)
El objetivo es aislar por completo los entornos para que diferentes empresas puedan contratar el servicio sin ver la información cruzada.
*   [ ] **Lógica de "Súper Empresa Administradora" (IC DESK):**
    *   Si en el programa cliente no se introduce ningún *ID de empresa*, el control y visualización del equipo lo toma por defecto **IC DESK (Ingeniería Creativa)** como Súper Empresa.
    *   Si el cliente ingresa un ID de empresa/técnico específico, el equipo desaparece del panel global de IC DESK y se asigna al dashboard de la empresa correspondiente.
*   [ ] **Administración Global y Asignación Cruzada:** IC DESK, como Súper Administrador, tendrá la capacidad desde su panel de buscar equipos huérfanos o no asignados, y reasignarlos o moverlos manualmente entre empresas, áreas o técnicos.
*   [ ] **Sistema de Alias para Equipos:** Permitir asignar un "Alias" familiar a cada equipo (ej. "Caja Registradora 1" o "Servidor Contabilidad") para que el técnico lo identifique inmediatamente sin depender del ID numérico o el hostname.
*   [ ] **Grupos Dinámicos y Áreas:** Que los técnicos puedan organizar los equipos de su empresa por departamentos (Ej: "RRHH", "Punto de Venta").
*   [ ] **Integración de WhatsApp Bot (Alex Bridge):** Notificaciones automáticas por WhatsApp a los supervisores cuando un servidor o caja crítica se desconecte o arroje un uso de CPU mayor al 95%.

### FASE 2: Analítica Predictiva y Automatización de TI (Medio Plazo)
Pasar de ser reactivos (entrar a arreglar) a ser proactivos (el sistema previene y avisa).
*   [ ] **Scripts de Auto-Sanación (Self-Healing):** Poder disparar scripts desde la sección *Configuración Global* que se ejecuten automáticamente si el agente detecta un problema (ej: "Si el disco C: llega al 95%, borrar caché temporal automáticamente").
*   [ ] **Gráficas de Rendimiento en Vivo:** Aprovechar la base de datos PostgreSQL para almacenar historiales de telemetría de cada equipo y mostrar en el panel gráficas hermosas (usando Canvas) del comportamiento de RAM/CPU de los últimos 7 días.
*   [ ] **Auditoría Avanzada de Sesiones:** Grabar o tomar capturas esporádicas cuando se establezca una conexión remota, como prueba de auditoría corporativa.

### FASE 3: Ecosistema Omnicanal y Facturación (Largo Plazo)
Convertir IC-Desk en un servicio SaaS monetizable de autoservicio.
*   [ ] **Gateway de Pagos (Stripe/Conekta):** Cobro automático por número de nodos/agentes instalados o por licencias de técnicos concurrentes.
*   [ ] **White-labeling (Marca Blanca):** Que las empresas que contraten IC-Desk puedan personalizar la aplicación agente con su propio Logo y nombre corporativo.
*   [ ] **Despliegue Multi-Plataforma Total:** Paridad de características del 100% en Windows, macOS, Linux, iOS y Android.
*   [ ] **App Móvil de Supervisión:** Una aplicación nativa que permita a los dueños de empresas ver el estatus de sus equipos desde el celular en tiempo real, conectada directo a nuestro WebSocket.

---

## 🛠️ Reglas de Oro de Desarrollo (Obligatorias)
1. **Cero React/RSC:** El Frontend debe mantenerse puramente funcional con Vanilla JS + Astro. El rendimiento a 60 FPS no se negocia.
2. **Arquitectura SCSS Élite:** Toda interfaz nueva debe respirar el mismo diseño corporativo `.c-*` (BEM).
3. **Retrocompatibilidad (Graceful Degradation):** Si una tecnología acelerada (como DXGI o ScreenCaptureKit) falla en una máquina antigua, el Agente debe caer elegantemente a una alternativa básica sin crashear.
