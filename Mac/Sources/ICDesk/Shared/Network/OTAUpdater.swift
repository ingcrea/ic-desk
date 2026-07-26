import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Estructura para parsear la respuesta JSON de versión del servidor.
struct OTAVersionResponse: Codable {
    let version: String
}

/// `OTAUpdater` se encarga de verificar actualizaciones del cliente de manera silenciosa
/// y aplicar la instalación automática en macOS descargando y montando el DMG.
public class OTAUpdater {
    public static let shared = OTAUpdater()
    
    private let currentVersion = "v1.0.0" // Versión compilada actual
    private var updateTimer: Timer?
    
    private init() {}
    
    /// Inicia el bucle de verificación de actualizaciones (cada 60 segundos).
    public func start() {
        // Ejecución inmediata al arranque
        checkForUpdates()
        
        // Timer periódico cada 60 segundos
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
    }
    
    /// Detiene la verificación periódica de actualizaciones.
    public func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Realiza un HTTP GET para obtener la versión más reciente del servidor.
    private func checkForUpdates() {
        guard let url = URL(string: "https://desk.ingcrea.com/soporte/version") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Error verificando actualizaciones: \(error?.localizedDescription ?? "Desconocido")")
                return
            }
            
            do {
                let json = try JSONDecoder().decode(OTAVersionResponse.self, from: data)
                let serverVersion = json.version
                
                if serverVersion != self.currentVersion {
                    print("Nueva versión detectada: \(serverVersion). Iniciando auto-actualización...")
                    self.performAutoUpdate()
                } else {
                    print("El cliente está actualizado (\(self.currentVersion)).")
                }
            } catch {
                print("Error parseando versión OTA: \(error)")
            }
        }
        task.resume()
    }
    
    /// Ejecuta el proceso de descarga e instalación silenciosa (solo macOS).
    private func performAutoUpdate() {
        #if os(macOS)
        guard let url = URL(string: "https://desk.ingcrea.com/soporte/download/mac") else { return }
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                print("Error descargando DMG: \(error?.localizedDescription ?? "Desconocido")")
                return
            }
            
            let tempDir = FileManager.default.temporaryDirectory
            let dmgPath = tempDir.appendingPathComponent("ICDesk_Update.dmg")
            
            do {
                if FileManager.default.fileExists(atPath: dmgPath.path) {
                    try FileManager.default.removeItem(at: dmgPath)
                }
                try FileManager.default.moveItem(at: localURL, to: dmgPath)
                
                // Ejecutar script para montar DMG y sobreescribir la App actual
                self.installFromDMG(dmgPath: dmgPath.path)
            } catch {
                print("Error moviendo el archivo DMG descargado: \(error)")
            }
        }
        downloadTask.resume()
        #else
        print("Actualización detectada. Por favor actualiza desde la App Store en iOS.")
        // Podríamos enviar una notificación NotificationCenter para mostrar una alerta en UI.
        #endif
    }
    
    #if os(macOS)
    /// Monta el DMG, copia el archivo .app a la ruta actual y reinicia la aplicación.
    private func installFromDMG(dmgPath: String) {
        let appBundlePath = Bundle.main.bundlePath
        let appName = URL(fileURLWithPath: appBundlePath).lastPathComponent
        let mountPoint = "/Volumes/ICDeskUpdate"
        
        let script = """
        # Desmontar si ya estaba montado por error
        hdiutil detach "\(mountPoint)" -force 2>/dev/null
        
        # Montar el DMG
        hdiutil attach "\(dmgPath)" -mountpoint "\(mountPoint)" -nobrowse -quiet
        
        # Encontrar la app en el DMG
        APP_PATH=$(find "\(mountPoint)" -maxdepth 1 -name "*.app" | head -n 1)
        
        if [ -n "$APP_PATH" ]; then
            # Eliminar la app actual para evitar conflictos de sobreescritura (si no es /Applications directamente)
            # En macOS es mejor copiar el contenido o usar rsync
            rm -rf "\(appBundlePath)"
            cp -R "$APP_PATH" "\(appBundlePath)"
            
            # Desmontar el DMG
            hdiutil detach "\(mountPoint)" -force -quiet
            
            # Reiniciar la aplicación
            open "\(appBundlePath)"
        else
            hdiutil detach "\(mountPoint)" -force -quiet
        fi
        """
        
        // Ejecutar bash script en segundo plano para no bloquear el proceso mientras se mata a sí mismo
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        
        do {
            try process.run()
            
            // Esperar un breve instante para asegurar que el bash script arrancó y luego salir
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                exit(0)
            }
        } catch {
            print("Error ejecutando script de instalación: \(error)")
        }
    }
    #endif
}
