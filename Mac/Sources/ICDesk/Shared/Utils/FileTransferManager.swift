import Foundation

/// `FileTransferManager` proporciona métodos robustos para operaciones de archivos,
/// incluyendo transferencia bidireccional mediante codificación Base64 en fragmentos.
public struct FileTransferManager {
    
    /// Lista el contenido de un directorio.
    /// - Parameter path: La ruta absoluta al directorio.
    /// - Returns: Un arreglo de nombres de archivos y carpetas, o nil si hay un error.
    public static func listDirectory(at path: String) -> [String]? {
        let fileManager = FileManager.default
        do {
            return try fileManager.contentsOfDirectory(atPath: path)
        } catch {
            print("Error listando directorio \(path): \(error)")
            return nil
        }
    }
    
    /// Lee un archivo y lo devuelve codificado en Base64.
    /// - Parameter path: Ruta absoluta del archivo.
    /// - Returns: El contenido del archivo en Base64 o nil si falla.
    public static func readFileAsBase64(at path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            return data.base64EncodedString()
        } catch {
            print("Error leyendo archivo en \(path): \(error)")
            return nil
        }
    }
    
    /// Escribe datos codificados en Base64 a un archivo.
    /// - Parameters:
    ///   - base64String: Los datos en formato Base64.
    ///   - path: Ruta absoluta del archivo destino.
    /// - Returns: Verdadero si la escritura fue exitosa, falso en caso contrario.
    public static func writeBase64ToFile(base64String: String, to path: String) -> Bool {
        guard let data = Data(base64Encoded: base64String) else {
            print("Error: Cadena Base64 inválida.")
            return false
        }
        let url = URL(fileURLWithPath: path)
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Error escribiendo archivo en \(path): \(error)")
            return false
        }
    }
    
    /// Envía un archivo en fragmentos (chunks) para evitar sobrecargar la memoria.
    /// - Parameters:
    ///   - path: Ruta del archivo a leer.
    ///   - chunkSize: Tamaño de cada fragmento en bytes (por defecto 1MB).
    ///   - onChunkReady: Closure llamado cuando un fragmento Base64 está listo para enviarse.
    public static func streamFileInChunks(at path: String, chunkSize: Int = 1024 * 1024, onChunkReady: (String, Bool) -> Void) {
        let url = URL(fileURLWithPath: path)
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            print("No se pudo abrir el archivo para lectura en \(path)")
            return
        }
        
        defer {
            try? fileHandle.close()
        }
        
        var isEOF = false
        while !isEOF {
            let chunkData = fileHandle.readData(ofLength: chunkSize)
            if chunkData.isEmpty {
                isEOF = true
                onChunkReady("", true) // Envía EOF
                break
            }
            
            let base64String = chunkData.base64EncodedString()
            onChunkReady(base64String, false)
        }
    }
}
