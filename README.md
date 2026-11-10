# RCJ

App para el iPhone. Tracking de habitos, pasos, metas y lista de viajes.

## Tecnologias

- Swift y SwiftUI
- Xcode, iOS 27.2
- MapKit para el mapa
- HealthKit para los pasos
- Core Location para el GPS
- Un JSON en el telefono para todos los datos que ingreses, no hay servidor

## Que hace

- Habitos: marcas cada dia tus habitos y ves la racha. El + para añadir uno está al lado del título.
- Metas: van por grupos y vas tachando en base a cuando los cumples.
- Actividad: pasos de Salud iOS y caminatas con el GPS.
- Viajes: mapa de paises, sitios pendientes y notas para cada viaje.
- Memoria: Buscar tema gira como una tragaperras y para en un tema. 15 minutos para mirarlo. Si lo marcas como hecho, no vuelve a salir. Saltar pide otro. Con reducir movimiento, el tema sale directo.
- El fondo es un degradado gris que se apaga hacia el negro.

## Como abrirla

1. Abre `RCJ.xcodeproj` en Xcode.
2. Elige tu iPhone.
3. Dale a Run.

Hace falta iOS 27.2. Los datos se guardan en el telefono.

Si quieres empezar con cosas ya puestas, deja un `PersonalSeed.json` dentro de `.private/`. Si no esta, la app abre vacia.

## Probar que guarda bien

Desde la carpeta del proyecto:

```
swiftc -o /tmp/rcj-check Tests/Check.swift RCJ/Store.swift RCJ/CountryAtlas.swift && /tmp/rcj-check
```
