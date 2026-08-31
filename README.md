# Moove - Gestión de Transporte Universitario Inteligente

[![Flutter](https://img.shields.io/badge/Platform-Flutter-blue?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=flat&logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com)

Moove es la aplicación móvil oficial del ecosistema SIGA, desarrollada en Flutter. Funciona como un sistema de movilidad institucional de alta precisión (estilo Uber institucional) que permite a los estudiantes rastrear rutas de autobuses en tiempo real, gestionar asistencias automáticas y optimizar la logística de transporte de la universidad.

---

## 📱 Características de la Aplicación

El desarrollo móvil interactúa directamente con el núcleo de base de datos relacional para ofrecer las siguientes soluciones:

* **📍 Monitoreo por GPS en Tiempo Real:** Consumo de datos de telemetría (`bus_gps_logs`) y sincronización mediante Firebase para visualizar la ubicación exacta del autobús, paradas y estimación de salida.
* **🎟️ Registro Automatizado de Asistencia:** Sistema inteligente que valida la presencia del estudiante en la ruta por proximidad geográfica.
* **🏁 Control de Viajes y Turnos:** Gestión de flotas organizadas por turnos (*Mañana, Tarde, Noche*) vinculando vehículos y conductores asignados.
* **🔧 Logística y Mantenimiento:** Interfaz preparada para el reporte técnico del estado del vehículo (Combustible cargado, kilometraje actual y alertas de mantenimiento preventivo/correctivo).

---

## 🛠️ Stack Tecnológico Móvil

* **Framework Core:** Flutter (Compilación nativa multiplataforma).
* **Lenguaje de Programación:** Dart.
* **Geolocalización:** Google Maps API & GPS nativo del dispositivo.
* **Sincronización en Vivo:** Firebase (Estructura de datos reactiva para el estado `en_curso` de los viajes).

---

## 🚀 Instalación y Configuración (Local)

Para levantar el proyecto móvil en tu entorno de desarrollo, asegúrate de tener instalado el SDK de Flutter y ejecuta los siguientes comandos:

```bash
# 1. Clonar el repositorio móvil
git clone https://github.com/EnmaLv/Moove.git

# 2. Navegar al directorio del proyecto
cd Moove

# 3. Limpiar la caché e instalar los paquetes/dependencias de Dart
flutter clean
flutter pub get

# 4. Verificar que tengas un emulador o dispositivo físico conectado
flutter devices

# 5. Ejecutar la aplicación en modo desarrollo
flutter run
```

## 🗺️ Roadmap de Desarrollo Técnico (TODO)

Nuestras prioridades actuales para optimizar el rendimiento y la experiencia de usuario en la app son:

-    [ ] **Optimización de Rendimiento (Multihilo):** Migrar el procesamiento y parsing del JSON pesado del mapa de Google a un Flutter Isolate (hilo secundario) para liberar carga del hilo principal y evitar caídas de frames.

-    [ ] **Sincronización Web:** Concluir el desarrollo de maestros locales en el teléfono para iniciar las pruebas de consumo de la API Web principal de Laravel.

---

## 👥 Desarrollador Principal

-    **EnmaLv** - Mobile Software Engineer / Lead Developer
