# 🚨 VEN911-hub


<<<<<<< HEAD

=======
>>>>>>> 4922ef8c41b79f145f207d0f00e0483da2e142c6
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![PostGIS](https://img.shields.io/badge/PostGIS-336791?style=for-the-badge&logo=postgresql&logoColor=white)

**VEN911-hub** es una aplicación móvil desarrollada en Flutter diseñada específicamente para el levantamiento de información en campo y auditoría de puntos de cámara de seguridad del sistema VEN911 en el estado Yaracuy. 

La plataforma permite a los inspectores evaluar en tiempo real las condiciones de infraestructura (energía eléctrica, postes, fibra óptica), geolocalizar puntos con precisión usando bases de datos espaciales (PostGIS) y mantener un foro colaborativo de reportes y fotografías por cada punto auditado.

---

## ✨ Características Principales

*   🗺️ **Mapa Interactivo Geolocalizado:** Visualización de todos los puntos de cámara usando `flutter_map` y OpenStreetMap.
*   🟢🟡🔴 **Indicadores de Estado Visuales:** Identificación rápida del estado del punto (Verde: Operativo, Amarillo: Falla parcial, Rojo: Inoperativo/Sin energía ni fibra).
*   📝 **Formularios Dinámicos de Levantamiento:** Captura de variables clave (nivel de tensión, altura de postes, distancia a nodos, índice delictivo, etc.).
*   📸 **Foro de Reportes y Evidencias:** Sistema de notas y subida de fotografías de evidencias directamente a Supabase Storage.
*   📡 **Sincronización en Tiempo Real:** Actualizaciones instantáneas en todos los dispositivos conectados mediante streams de Supabase.
*   🔐 **Seguridad RLS (Row Level Security):** Gestión de perfiles, autenticación segura y políticas de acceso a nivel de base de datos.
*   🚀 **CI/CD Automatizado:** Workflows de GitHub Actions para análisis de código continuo y despliegue automático de APKs en cada release.

---

## 📋 Requisitos del Sistema

Para compilar y ejecutar este proyecto localmente, necesitas:

*   **Flutter SDK:** `^3.11.5` (o superior)
*   **Dart SDK:** `^3.1.0`
*   **Supabase:** Una instancia de Supabase (Cloud o Local) con PostGIS habilitado.
*   **IDE:** VS Code, Android Studio o IntelliJ con los plugins de Flutter y Dart.
*   **Dispositivo/Emulador:** Dispositivo Android/iOS físico o emulador configurado.

---

## 🚀 Instalación y Configuración

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/tu-usuario/VEN911-Hub.git
   cd VEN911-Hub/ven911_app
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno:**
   Crea un archivo `.env` en la raíz de `ven911_app/` con tus credenciales de Supabase:
   ```env
   SUPABASE_URL=tu_supabase_url
   SUPABASE_ANON_KEY=tu_anon_key
   ```
   *(Opcional)* Si vas a ejecutar scripts de migración de base de datos desde `scripts/`, añade también `SUPABASE_SERVICE_ROLE_KEY`.

4. **Ejecutar la aplicación:**
   Asegurate de tener un dispositivo fisico Android/iOS conectado al computador para probar la aplicación, o en su defecto, un emulador configurado, o en su defecto, la aplicacion se ejecutara en windows de forma local.
   ```bash
   flutter run
   ```

---

## 🛠️ Estructura del Proyecto

*   `/ven911_app`: Código fuente principal de la aplicación Flutter.
*   `/supabase`: Scripts SQL, esquema inicial y migraciones de la base de datos (PostGIS, RLS, tablas).
*   `/scripts`: Scripts de utilidad en Python (ej. `seed_database.py` para carga masiva inicial de datos).
*   `/.github/workflows`: Pipelines de integración y despliegue continuo (CI/CD).
*   `/data`: Archivos JSON y recursos de contexto del dominio.

---

## 🤝 Cómo Contribuir

¡Agradecemos mucho las contribuciones! Para mantener la calidad y el orden del proyecto, sigue estas pautas:

### Guía de Contribución

1. **Haz un Fork** del repositorio.
2. **Crea una nueva rama** para tu característica o corrección de error (`git checkout -b feature/nueva-caracteristica` o `git checkout -b bugfix/correccion-error`).
3. **Realiza tus cambios** y haz commits descriptivos (`git commit -m 'feat: añade funcionalidad X'`).
4. **Sube tus cambios** a tu fork (`git push origin feature/nueva-caracteristica`).
5. **Abre un Pull Request (PR)** hacia la rama `main` de este repositorio.

Hemos preparado plantillas predeterminadas para facilitar la creación de **Issues** y **Pull Requests**. Al abrirlos en GitHub, la plataforma te sugerirá usarlas.

*   [Plantilla para Reporte de Bugs (Issue)](../.github/ISSUE_TEMPLATE/bug_report.md)
*   [Plantilla para Nueva Funcionalidad (Issue)](../.github/ISSUE_TEMPLATE/feature_request.md)
*   [Plantilla para Pull Requests (PR)](../.github/PULL_REQUEST_TEMPLATE.md)

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.

---
*Construido con ❤️ para la optimización de infraestructuras críticas.*
