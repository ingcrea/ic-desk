import Foundation
#if os(macOS)
import IOKit
#elseif os(iOS)
import UIKit
import Security
#endif

/// `AgentIdentifier` es responsable de generar y recuperar el ID único
/// y determinista del agente (dispositivo) donde se ejecuta IC Desk.
public struct AgentIdentifier {
    
    /// Obtiene el identificador determinista del agente.
    /// - Returns: Una cadena con el identificador único.
    public static func getAgentID() -> String {
        #if os(macOS)
        return getMacSerialNumber()
        #elseif os(iOS)
        return getIOSIdentifier()
        #else
        return UUID().uuidString
        #endif
    }
    
#if os(macOS)
    /// Obtiene el número de serie físico de la Mac usando IOKit.
    private static func getMacSerialNumber() -> String {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }
        
        guard platformExpert != 0 else { return "UNKNOWN_MAC" }
        
        if let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() as? String {
            return serialNumberAsCFString
        }
        return "UNKNOWN_MAC"
    }
#elseif os(iOS)
    /// Obtiene o genera el identificador del dispositivo iOS y lo guarda en Keychain.
    private static func getIOSIdentifier() -> String {
        let account = "ICDeskAgentID"
        let service = "com.icdesk.ingcrea"
        
        // Intentar leer de Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data, let id = String(data: data, encoding: .utf8) {
            return id
        }
        
        // Generar y guardar si no existe
        let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        guard let data = newID.data(using: .utf8) else { return newID }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemAdd(addQuery as CFDictionary, nil)
        
        return newID
    }
#endif
}
