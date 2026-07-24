#if os(macOS)
import Foundation
import CoreGraphics

/// `InputControlManager` permite simular eventos de teclado y ratón de forma programática.
/// Utiliza `CGEventPost` para inyectar eventos a nivel de sistema operativo en macOS.
public class InputControlManager {
    
    public init() {}
    
    /// Mueve el cursor del ratón a una coordenada específica en pantalla.
    /// - Parameter point: La coordenada X e Y (origen arriba-izquierda).
    public func moveMouse(to point: CGPoint) {
        if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) {
            event.post(tap: .cghidEventTap)
        }
    }
    
    /// Simula un clic (presionar y soltar) del botón izquierdo del ratón en la ubicación actual.
    public func simulateLeftClick() {
        if let currentEvent = CGEvent(source: nil) {
            let point = currentEvent.location
            if let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
               let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
                mouseDown.post(tap: .cghidEventTap)
                // Pequeño retraso humano
                usleep(50000)
                mouseUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    /// Simula la pulsación de una tecla usando su código virtual (Virtual Key Code).
    /// - Parameter keyCode: El código virtual de la tecla a pulsar (ej. 0x00 para la tecla 'A').
    public func simulateKeyPress(keyCode: CGKeyCode) {
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
#endif
