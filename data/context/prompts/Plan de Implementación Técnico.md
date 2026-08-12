Objetivo General
Implementar una arquitectura Local-First en la aplicación Flutter que garantice operabilidad 100% offline. Esto incluye arranque sin conexión, persistencia local nativa de datos, visualización interactiva de mapas y capacidad de realizar inserciones/modificaciones que se sincronicen de manera bidireccional y automática con Supabase al restablecerse la conectividad.

Ejes de la Solución
1. Persistencia y Sincronización de Datos (PowerSync + Supabase)
Base de Datos Local: Utilizar PowerSync, el cual gestiona de manera transparente una base de datos SQLite local en el dispositivo. Esto permite que la app lea y escriba directamente a velocidad local sin depender de la red.

Sincronización Bidireccional: PowerSync se conecta directamente a PostgreSQL (Supabase) mediante replicación lógica. No requiere desarrollo de lógica custom ni plugins caseros: el motor detecta los cambios locales y los sincroniza en segundo plano de forma transaccional tan pronto se recupera la conexión a internet.

2. Gestión de Mapas sin Conexión (flutter_map + FMTC)
Caché de Teselas (Tiles): Implementar una estrategia híbrida utilizando el almacenamiento en caché nativo de flutter_map para sesiones breves, complementado con la librería robusta flutter_map_tile_caching (FMTC) para la descarga masiva y persistente de mapas en regiones geográficas específicas (ideal para trabajo de campo en zonas con conectividad intermitente).
🚀 Plan de Implementación Técnico
Fase 1: Configuración del Backend y Replicación (Supabase)
Habilitar la Replicación Lógica en Supabase para las tablas críticas (ej. locations).

Configurar las Sync Rules en el panel de PowerSync para definir qué porción de la base de datos se descargará y sincronizará en el dispositivo del usuario.

Fase 2: Capa de Datos Local en Flutter
Inicializar el cliente de PowerSync en el arranque de la aplicación para asegurar que la app esté lista para operar offline desde el primer segundo.

Refactorizar los repositorios de la app para que todas las consultas (SELECT, INSERT, UPDATE) apunten a la instancia local de SQLite gestionada por PowerSync, eliminando llamadas directas y bloqueantes a la API de Supabase en el flujo de UI.

Fase 3: Estrategia Offline para Mapas (flutter_map)
Configurar el TileLayer con parámetros de caché optimizados (maxCacheSize) para retener las teselas recientemente visitadas.

Implementar un módulo de descarga bajo demanda con FMTC, permitiendo al usuario descargar el paquete de mapas del área de interés (ej. la zona de estudio o municipio) antes de salir al campo.