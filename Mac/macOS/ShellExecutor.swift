import Foundation

#if os(macOS)
/// `ShellResponse` encapsula el resultado de la ejecución de un comando de terminal.
public struct ShellResponse: Codable {
    public let success: Bool
    public let data: ShellOutput?
    public let error: ErrorDetail?
}

public struct ShellOutput: Codable {
    public let output: String
}

/// `ShellExecutor` permite ejecutar comandos de bash/zsh en macOS de forma segura.
public struct ShellExecutor {
    
    /// Ejecuta un comando en la terminal y devuelve el resultado en formato JSON estandarizado.
    /// - Parameter command: El comando a ejecutar.
    /// - Returns: Una estructura `ShellResponse` con la salida o el error.
    public static func execute(_ command: String) -> ShellResponse {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.executableURL = URL(fileURLWithPath: "/bin/bash") // o /bin/zsh
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                let success = process.terminationStatus == 0
                if success {
                    return ShellResponse(
                        success: true,
                        data: ShellOutput(output: output),
                        error: nil
                    )
                } else {
                    return ShellResponse(
                        success: false,
                        data: ShellOutput(output: output), // A veces el error está en stdout/stderr combinado
                        error: ErrorDetail(code: "EXEC_ERROR", message: "Proceso terminó con código \(process.terminationStatus)")
                    )
                }
            } else {
                return ShellResponse(
                    success: false,
                    data: nil,
                    error: ErrorDetail(code: "DECODE_ERROR", message: "No se pudo decodificar la salida a UTF-8.")
                )
            }
        } catch {
            return ShellResponse(
                success: false,
                data: nil,
                error: ErrorDetail(code: "RUNTIME_ERROR", message: error.localizedDescription)
            )
        }
    }
}
#endif
