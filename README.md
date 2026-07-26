# IC-Desk — Cliente de Soporte Remoto Open-Source

Cliente de soporte técnico remoto ultraligero y de alto rendimiento. Diseñado con una arquitectura nativa orientada a la eficiencia extrema (cero dependencias externas) y captura de video acelerada por hardware.

---

## 📁 Estructura Pública del Proyecto

```
ic-desk/
├── Windows/
│   └── IcDesk.cs                # Agente nativo Windows en C# (.NET)
└── Mac/
    └── ICDesk/                  # Agente nativo macOS / iOS en Swift
```

---

## 🚀 Características del Agente (v6.1.0)

* **Video H.264 Acelerado por GPU:** Utiliza las APIs nativas del sistema operativo (como DXGI Desktop Duplication y Media Foundation en Windows) para capturar y codificar la pantalla directamente desde la Tarjeta Gráfica (Cero latencia).
* **Peso Pluma Extremo:** Archivo ejecutable huérfano solitario de ~314 KB. No requiere instalar DLLs gigantes, ni motores web embebidos.
* **Mecanismo OTA Integrado:** El agente C# cuenta con un actualizador automático transparente (Over-The-Air) integrado en la misma capa de red de `.NET`.
* **Soporte Bidireccional:** Portapapeles compartido de manera nativa y recepción de inyección de inputs (Mouse/Teclado).

---

## 🏗️ Cómo Compilar el Agente de Windows manualmente

Para entornos Linux (CI/CD):
```bash
mcs -out:IC-Desk.exe -r:System.Net.Http,System.Drawing,System.Windows.Forms IcDesk.cs
```

Para entornos Windows:
```powershell
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:IC-Desk.exe /target:winexe IcDesk.cs
```

---

**IC Desk © 2026** — *Proyecto cliente Open-Source.*
