# IC Desk — Constantes Canónicas del Proyecto

> **LECTURA OBLIGATORIA** para cualquier agente, IA o desarrollador antes de tocar este proyecto.
> Si no respetas estas constantes, **ROMPERÁS la autenticación** del sistema.

---

## NOMBRE DEL PROYECTO
- **Nombre correcto:** `IC Desk` (o `IC-Desk`)
- **Nombres PROHIBIDOS:** `SercomDesk`, `Sercom Desk`

---

## TOKENS Y CABECERAS HTTP — VALORES FIJOS

### Token del Agente Windows (cliente C#)
| Propiedad | Valor |
|---|---|
| Constante en C# | `AgentToken = "ICAgentToken2026SecureHashKey"` |
| Header HTTP enviado | `x-ic-agent-token: ICAgentToken2026SecureHashKey` |
| Constante en Node.js | `const IC_AGENT_TOKEN = 'ICAgentToken2026SecureHashKey'` |
| Header leído en Node | `req.headers['x-ic-agent-token']` |

### API Key del Panel Web (operadores humanos)
| Propiedad | Valor |
|---|---|
| Header enviado por el panel | `X-IC-API-Key: SrC0mS0p0rt3#S3cur1tyKey#2026` |
| Header leído en Node | `req.headers['x-ic-api-key']` |

**NOTA:** `x-ic-api-key` es para operadores humanos del panel. `x-ic-agent-token` es para el agente Windows. Son cosas distintas.

---

## URLs DE PRODUCCION
| Servicio | URL |
|---|---|
| Panel web / login | https://desk.ingcrea.com |
| API REST | https://desk.ingcrea.com/soporte/* |
| WebSocket Relay | wss://desk.ingcrea.com |
| Descarga exe | https://desk.ingcrea.com/d/win |
| Script instalacion | irm https://desk.ingcrea.com | iex |

---

## INFRAESTRUCTURA
| Componente | Ubicacion |
|---|---|
| Servidor Node.js principal | SV1: /home/alex/alex_omega/whatsapp_sovereign/index.js |
| Relay WebSocket | SV1: /home/alex/alex_omega/whatsapp_sovereign/relay.js |
| Panel estatico Astro | SV1: /home/alex/alex_omega/whatsapp_sovereign/panel/ |
| Ejecutable agente | SV1: /home/alex/alex_omega/whatsapp_sovereign/IC-Desk.exe |
| Codigo fuente local | /home/ingcrea/github/ic-desk/ |

---

## PALABRAS PROHIBIDAS — NUNCA USAR EN CODIGO NUEVO

| PROHIBIDO | CORRECTO |
|---|---|
| x-sercom-agent-token | x-ic-agent-token |
| SercomAgentToken2026SecureHashKey | ICAgentToken2026SecureHashKey |
| SERCOM_AGENT_TOKEN | IC_AGENT_TOKEN |
| SercomDesk | IC Desk |
| x-sercom-api-key (para agentes) | x-ic-agent-token (para agentes) |

---

## VERSION ACTUAL
- Cliente Windows: v6.7.5
- Calidad JPEG captura: 80 (linea ~835 en IcDesk.cs)

Ultima actualizacion: 2026-07-29
