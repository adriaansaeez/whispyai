# WhispyAI Implementation Roadmap

## Contexto Actual

- El repositorio todavia no contiene codigo, tooling ni CI; la unica fuente de verdad actual es `PLAN.md`.
- El objetivo del MVP es una app nativa de macOS en la menubar con este flujo critico:
  - `hotkey global -> dictado local Apple -> prompt -> rewrite con IA -> insercion automatica en la app activa`
- Restricciones del MVP:
  - Speech local con Apple.
  - Un solo proveedor implementado en v1: OpenAI.
  - Sin historial, sync, templates, analytics, workflows multiples ni Ollama.

## Objetivo Del Proyecto

Construir una utilidad de menubar para macOS que permita al usuario dictar texto, mejorarlo automaticamente con IA y reinsertarlo en cualquier aplicacion compatible sin copiar y pegar manualmente.

## Metricas Principales

- `Time To Text`: tiempo desde pulsar la hotkey hasta ver el texto insertado.
- Objetivo MVP: `< 3 segundos` en el camino feliz.
- Metricas secundarias:
  - tasa de exito de insercion en apps objetivo
  - tasa de onboarding completado
  - tasa de errores por permisos

## Principios De Implementacion

- Priorizar el camino critico antes que la configuracion avanzada.
- Mantener desacoplados los modulos definidos en `PLAN.md`:
  - `Speech Service`
  - `Prompt Engine`
  - `AI Provider Layer`
  - `Accessibility Service`
- Mantener el contrato del proveedor:

```swift
protocol AIProvider {
    func transform(
        text: String,
        prompt: String
    ) async throws -> String
}
```

- No introducir features de v2 durante el MVP.
- Instrumentar latencia desde la primera version end-to-end.

## Arquitectura Objetivo Del MVP

### App Shell

- App nativa macOS con SwiftUI.
- Menubar como punto de entrada principal.
- Ventana de settings/onboarding separada del flujo rapido de uso.

### Speech Service

- Responsabilidad: capturar audio y convertir voz en texto localmente.
- Tecnologia prevista: `Speech` + `AVFoundation`.

### Prompt Engine

- Responsabilidad: construir el prompt enviado al proveedor.
- Debe preservar significado e idioma original.

### AI Provider Layer

- Responsabilidad: abstraer el proveedor de IA.
- v1 implementa solo OpenAI.
- Debe quedar lista la extension futura a Anthropic, Gemini y OpenRouter.

### Accessibility Service

- Responsabilidad: localizar el campo enfocado y reemplazar o insertar texto.
- Tecnologia prevista: `Accessibility API` / `AXUIElement`.

### Persistencia Y Configuracion

- `UserDefaults` para preferencias generales.
- La API key debe evaluarse para almacenarse en Keychain desde v1 aunque el plan mencione `UserDefaults` para persistencia general.

## Roadmap Por Fases

## Fase 0: Decisiones Tecnicas Base

### Objetivo

Cerrar las decisiones que afectan toda la implementacion antes de generar codigo.

### Trabajo

- Definir version minima de macOS soportada.
- Definir estructura inicial del proyecto y modulos.
- Definir estrategia de estado global y errores.
- Definir politica de almacenamiento de API keys.
- Definir lista inicial de apps objetivo para pruebas de accessibility.

### Entregables

- Documento de decisiones tecnicas.
- Estructura inicial de carpetas/proyecto.
- Lista de riesgos priorizados.

### Criterios De Aceptacion

- La arquitectura permite implementar el flujo critico sin refactors mayores.
- Los modulos del plan quedan reflejados desde el inicio.
- Queda claro que v1 soporta OpenAI y deja extensibilidad a mas providers.

### Testing

- Revision tecnica del diseño contra `PLAN.md`.
- Validacion de que no se esta introduciendo scope de v2.

## Fase 1: Scaffold De La App

### Objetivo

Tener una app macOS compilable con menubar y base de configuracion.

### Trabajo

- Crear el proyecto base en Xcode.
- Añadir menubar app shell.
- Añadir ventana minima de settings.
- Definir estructura de modulos y capas.
- Preparar modelos de configuracion y estado.

### Entregables

- App que arranca correctamente.
- Icono en menubar.
- Settings basicos navegables.

### Criterios De Aceptacion

- La app se abre sin errores.
- El icono de menubar responde.
- Las preferencias basicas se pueden leer y persistir.

### Testing

- Build local limpia.
- Smoke test manual:
  - abrir app
  - abrir/cerrar settings
  - reiniciar app y validar persistencia minima

## Fase 2: Hotkey Global

### Objetivo

Activar el flujo principal desde cualquier aplicacion.

### Trabajo

- Integrar `KeyboardShortcuts`.
- Configurar shortcut por defecto `Option + Space`.
- Permitir personalizacion de hotkey.
- Disparar evento interno `startDictation()`.

### Entregables

- Hotkey global funcional.
- UI para editar el atajo.

### Criterios De Aceptacion

- La hotkey funciona con la app en background.
- Una segunda pulsacion no deja sesiones duplicadas.
- El atajo configurado se conserva entre reinicios.

### Testing

- Unit tests de persistencia y cambio de hotkey.
- Manual:
  - hotkey por defecto
  - hotkey personalizada
  - app sin foco
  - proteccion contra doble trigger

## Fase 3: Speech Service Local

### Objetivo

Obtener transcripcion fiable y local usando Apple Speech.

### Trabajo

- Solicitar permisos de microfono y speech.
- Implementar captura de audio.
- Integrar reconocimiento con `SFSpeechRecognizer`.
- Exponer estados del proceso:
  - `idle`
  - `requestingPermission`
  - `listening`
  - `transcribing`
  - `success`
  - `failure`
- Implementar `stop`, `cancel` y timeout.

### Entregables

- Speech service reutilizable.
- Feedback visual de grabacion/procesamiento.

### Criterios De Aceptacion

- El usuario puede iniciar y detener una sesion.
- La transcripcion se obtiene sin depender de un proveedor externo.
- Los errores de permisos quedan explicados en UI.

### Testing

- Unit tests de maquina de estados.
- Manual:
  - permiso aceptado
  - permiso denegado
  - dictado corto
  - dictado medio
  - pulsar hotkey y no hablar
  - cancelacion durante grabacion

## Fase 4: Prompt Engine

### Objetivo

Construir un prompt consistente, conservador y configurable.

### Trabajo

- Implementar prompt por defecto de `PLAN.md`.
- Inyectar `{{TEXT}}` en el template.
- Permitir editar prompt desde settings.
- Añadir fallback a prompt por defecto.

### Entregables

- Prompt engine desacoplado del proveedor.
- Configuracion editable por usuario.

### Criterios De Aceptacion

- El prompt siempre preserva significado e idioma.
- Un prompt vacio o invalido no rompe el flujo.

### Testing

- Unit tests:
  - render del prompt
  - texto vacio
  - texto largo
  - fallback correcto
- Manual:
  - texto en espanol
  - texto en ingles
  - texto coloquial

## Fase 5: AI Provider Layer Con OpenAI

### Objetivo

Resolver el rewrite manteniendo un contrato compatible con futuros proveedores.

### Trabajo

- Implementar el protocolo `AIProvider`.
- Crear `OpenAIProvider`.
- Modelar request/response.
- Soportar timeout, cancelacion y errores HTTP/parseo.
- Persistir configuracion minima:
  - provider
  - modelo
  - temperatura
  - max tokens
  - timeout

### Entregables

- Rewrite funcional con OpenAI.
- Contrato listo para Anthropic/Gemini/OpenRouter en el futuro.

### Criterios De Aceptacion

- Una API key valida produce respuesta usable.
- Los errores comunes se muestran claramente.
- La implementacion no acopla la app a un provider unico.

### Testing

- Unit tests:
  - construccion de request
  - parseo de response
  - timeouts
  - errores HTTP
- Integracion:
  - API key valida
  - API key invalida
  - modelo incorrecto
  - respuesta vacia

## Fase 6: Accessibility Service

### Objetivo

Insertar el texto reescrito en la aplicacion activa.

### Trabajo

- Solicitar permiso de accesibilidad.
- Leer elemento enfocado.
- Detectar seleccion actual si existe.
- Reemplazar seleccion o insertar en el cursor.
- Mantener el foco cuando sea posible.

### Entregables

- Servicio de insercion utilizable desde el coordinador principal.

### Criterios De Aceptacion

- Funciona en las apps objetivo definidas para el MVP.
- Si una app no soporta correctamente AX, la app informa el fallo con claridad.

### Testing

- Manual prioritario en:
  - TextEdit
  - Notes
  - Mail
  - Safari o Chrome en inputs web
  - Slack si entra en el set inicial
- Escenarios:
  - con seleccion
  - sin seleccion
  - multilinea
  - campo simple
  - app incompatible

## Fase 7: Orquestacion End-To-End

### Objetivo

Unir todo el flujo critico en una sola sesion controlada.

### Trabajo

- Crear coordinador del flujo.
- Definir concurrencia: una sola sesion activa.
- Encadenar:
  1. hotkey
  2. speech
  3. prompt
  4. AI rewrite
  5. accessibility insert
- Medir tiempos por etapa.
- Implementar cancelacion limpia y manejo de errores.

### Entregables

- Primer flujo completo de punta a punta.

### Criterios De Aceptacion

- El camino feliz funciona en apps reales.
- Cada etapa reporta su error de forma comprensible.
- El tiempo total puede medirse y compararse con el objetivo `< 3s`.

### Testing

- Integracion end-to-end completa.
- Casos de fallo en cada etapa.
- Sesiones repetidas.
- Cancelacion manual.

## Fase 8: Onboarding

### Objetivo

Llevar al usuario desde instalacion hasta primer dictado exitoso.

### Pantallas Del Plan

1. Bienvenida.
2. Permiso de microfono.
3. Permiso de accesibilidad.
4. Seleccion de proveedor.
5. API key.
6. Prompt por defecto.
7. Hotkey.
8. Prueba rapida.

### Trabajo

- Construir onboarding secuencial y corto.
- Validar API key antes de terminar.
- Persistir estado de onboarding completado.
- Añadir recovery desde settings si el usuario se atasca.

### Criterios De Aceptacion

- Un usuario nuevo puede completar setup sin ayuda externa.
- Si niega permisos, la app explica como recuperarlos.
- La prueba rapida valida el valor del producto.

### Testing

- Usuario nuevo.
- Usuario que niega microfono.
- Usuario que niega accesibilidad.
- API key invalida.
- Salida a mitad del onboarding y reentrada.

## Fase 9: Settings Del MVP

### Objetivo

Exponer solo la configuracion necesaria para el MVP.

### Configuracion Incluida

- launch at login
- mostrar icono en menu
- sonido al iniciar grabacion
- hotkey
- provider
- API key
- modelo
- prompt
- temperatura
- max tokens
- timeout

### Criterios De Aceptacion

- La configuracion persiste correctamente.
- Los defaults son seguros.
- El usuario no necesita reiniciar la app para la mayoria de cambios.

### Testing

- Persistencia tras reinicio.
- Valores invalidos.
- Cambios de provider/modelo.
- Prompt personalizado.

## Fase 10: Hardening Del MVP

### Objetivo

Reducir friccion y fallos antes de una beta interna.

### Trabajo

- Mejorar mensajes de error.
- Homogeneizar estados de loading/cancelacion.
- Añadir logging interno no invasivo.
- Afinar feedback visual o sonoro.
- Revisar estabilidad en sesiones repetidas.

### Criterios De Aceptacion

- El flujo aguanta uso diario moderado.
- Los errores dejan claro el siguiente paso para el usuario.

### Testing

- App abierta durante horas.
- Sleep/wake del Mac.
- Cambios de red.
- Cambio de foco entre apps durante dictado y durante insercion.

## Fase 11: Distribucion

### Objetivo

Preparar una build instalable fuera del entorno de desarrollo.

### Trabajo

- Firma del binario.
- Notarizacion Apple.
- Empaquetado en DMG.
- Validacion en una maquina limpia.

### Criterios De Aceptacion

- La app puede instalarse y abrirse sin friccion inesperada.
- El onboarding funciona en un Mac no preparado previamente.

### Testing

- Instalacion desde cero.
- Primer arranque.
- Onboarding completo en maquina limpia.

## Estrategia De Testing

## 1. Unit Tests

Cubrir primero la logica que mas protege contra regresiones:

- prompt engine
- configuracion y defaults
- maquina de estados del speech service
- request/response del provider OpenAI
- coordinador del flujo
- manejo de errores y timeouts

## 2. Integration Tests

- servicios con dependencias mockeables
- speech service abstraido cuando sea posible
- AI provider con stubs y una prueba real controlada
- accessibility service con doble capa: logica testeable + validacion manual real

## 3. Manual QA

Apps a validar desde el inicio:

- TextEdit
- Notes
- Mail
- Safari o Chrome
- Slack si se incluye en el soporte inicial

Escenarios minimos:

- con seleccion
- sin seleccion
- texto corto
- texto largo
- espanol
- ingles
- API key valida
- API key invalida
- permiso aceptado
- permiso denegado

## 4. Performance Testing

Medir sistematicamente:

- `hotkey -> listening`
- `listening -> transcript`
- `transcript -> AI response`
- `AI response -> insertion`
- `hotkey -> inserted text`

Objetivo:

- detectar pronto si el cuello de botella esta en speech, red o accessibility

## Matriz Minima De QA Del MVP

Cada build candidata debe validarse al menos en estos ejes:

- permisos aceptados y denegados
- hotkey por defecto y personalizada
- con y sin seleccion
- texto corto y largo
- espanol e ingles
- app nativa, web y Electron si aplica
- red correcta, lenta y con error
- cancelacion manual y timeout

## Riesgos Principales Y Mitigaciones

## 1. Accessibility inconsistente entre apps

- Riesgo: no todas las apps exponen bien el campo de texto via AX.
- Mitigacion: fijar una matriz de apps objetivo del MVP desde el inicio y testear sobre ellas continuamente.

## 2. Latencia total por encima del objetivo

- Riesgo: el rewrite remoto puede disparar el `Time To Text`.
- Mitigacion: instrumentar tiempos por etapa desde la primera version end-to-end.

## 3. Mala experiencia inicial por permisos

- Riesgo: el usuario abandona durante onboarding.
- Mitigacion: onboarding guiado, recovery claro y prueba rapida que demuestre valor.

## 4. Acoplamiento prematuro a OpenAI

- Riesgo: retrabajo al añadir otros proveedores.
- Mitigacion: respetar desde el inicio el protocolo `AIProvider`.

## 5. Rewrite demasiado agresivo

- Riesgo: cambia significado o idioma del texto original.
- Mitigacion: prompt por defecto conservador y pruebas bilingues.

## Definition Of Done Del MVP

El MVP se considera listo cuando:

- la app vive en menubar
- el usuario puede configurar OpenAI y una hotkey
- el dictado usa Apple Speech
- el rewrite mantiene significado e idioma
- el texto se inserta automaticamente en apps objetivo
- onboarding deja al usuario operativo
- existe una matriz de QA reproducible
- el rendimiento esta medido y es razonable respecto al objetivo `< 3s`

## Roadmap Sugerido Por Semanas

## Semana 1

- decisiones base
- scaffold de app
- menubar
- settings base
- hotkey

## Semana 2

- speech service
- permisos
- estados UI
- primeras pruebas manuales

## Semana 3

- prompt engine
- OpenAI provider
- configuracion de modelo y API key
- tests de red y errores

## Semana 4

- accessibility service
- insercion en apps reales
- primer end-to-end completo

## Semana 5

- onboarding
- hardening
- instrumentacion de latencia
- QA manual fuerte

## Semana 6

- empaquetado
- firma y notarizacion
- beta interna

## Siguientes Decisiones Recomendadas

Antes de arrancar implementacion, conviene cerrar estas decisiones:

1. Version minima de macOS.
2. Si la API key se almacena en Keychain desde v1.
3. Lista exacta de apps objetivo para validar accessibility.
4. Si el roadmap apunta primero a beta interna o release publica.
