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
                usleep(50_000)
                mouseUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    /// Simula un clic derecho en la ubicación actual.
    public func simulateRightClick() {
        if let currentEvent = CGEvent(source: nil) {
            let point = currentEvent.location
            if let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: point, mouseButton: .right),
               let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: point, mouseButton: .right) {
                mouseDown.post(tap: .cghidEventTap)
                usleep(50_000)
                mouseUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    /// Simula un doble clic izquierdo.
    public func simulateDoubleClick() {
        if let currentEvent = CGEvent(source: nil) {
            let point = currentEvent.location
            if let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
               let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
                
                mouseDown.setIntegerValueField(.mouseEventClickState, value: 1)
                mouseDown.post(tap: .cghidEventTap)
                mouseUp.setIntegerValueField(.mouseEventClickState, value: 1)
                mouseUp.post(tap: .cghidEventTap)
                
                usleep(50_000)
                
                mouseDown.setIntegerValueField(.mouseEventClickState, value: 2)
                mouseDown.post(tap: .cghidEventTap)
                mouseUp.setIntegerValueField(.mouseEventClickState, value: 2)
                mouseUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    /// Simula un evento de scroll del ratón.
    /// - Parameters:
    ///   - deltaY: Cantidad de desplazamiento vertical.
    ///   - deltaX: Cantidad de desplazamiento horizontal.
    public func simulateScroll(deltaY: Int32, deltaX: Int32 = 0) {
        if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) {
            scrollEvent.post(tap: .cghidEventTap)
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
    
    /// Simula la escritura de una cadena de caracteres usando un teclado virtual.
    /// - Parameter text: El texto a escribir.
    public func typeText(_ text: String) {
        let utf16Chars = Array(text.utf16)
        var events: [CGEvent] = []
        
        for char in utf16Chars {
            var charCode = char
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charCode)
                events.append(event)
            }
        }
        
        for event in events {
            event.post(tap: .cghidEventTap)
            usleep(10_000)
        }
    }
}
#endif
