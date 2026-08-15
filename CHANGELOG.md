# Changelog

## [1.10.0](https://github.com/0vethor0/VenHub/compare/v1.9.0...v1.10.0) (2026-08-15)


### Features

* **reports:** add Excel, PDF, and table previews for installation reports ([800ffad](https://github.com/0vethor0/VenHub/commit/800ffadda8711d1c34a082a9f40ed5086cd8239d))

## [1.9.0](https://github.com/0vethor0/VenHub/compare/v1.8.0...v1.9.0) (2026-08-14)


### Features

* **map:** mostrar ubicación GPS del dispositivo en tiempo real ([0791f2d](https://github.com/0vethor0/VenHub/commit/0791f2de1ce1aed435c12852a1ded3a943e52525))

## [1.8.0](https://github.com/0vethor0/VenHub/compare/v1.7.0...v1.8.0) (2026-08-14)


### Features

* **map:** corregir visualización y arrastre de propuestas y puntos en mapa ([85eae86](https://github.com/0vethor0/VenHub/commit/85eae86b56e6cf674bbc2f7b9b62d419336cc094))

## [1.7.0](https://github.com/0vethor0/VenHub/compare/v1.6.0...v1.7.0) (2026-08-14)


### Features

* **map:** añadir gestión y edición interactiva de propuestas y puntos ([d0d3992](https://github.com/0vethor0/VenHub/commit/d0d399238f5f856407e3539659caf2fae4c273aa))


### Bug Fixes

* **format:** formateo del codigo ([5c0bfb3](https://github.com/0vethor0/VenHub/commit/5c0bfb3a251c397eb5d315052b838b1c94853c04))

## [1.6.0](https://github.com/0vethor0/VenHub/compare/v1.5.0...v1.6.0) (2026-08-14)


### Features

* **mapa:** agregar calculadora de altura de postes mediante sensor de inclinación ([2258db9](https://github.com/0vethor0/VenHub/commit/2258db9b499f5c4bfa669fb30327ccb3d9ee488c))

## [1.5.0](https://github.com/0vethor0/VenHub/compare/v1.4.1...v1.5.0) (2026-08-14)


### Features

* **mapa:** agregar puntos de fibra óptica y propuestas de mejora de cámaras ([29338ce](https://github.com/0vethor0/VenHub/commit/29338ce8fb6c3303210f6f1c19c5406f1abbfeec))

## [1.4.1](https://github.com/0vethor0/VenHub/compare/v1.4.0...v1.4.1) (2026-08-13)


### Bug Fixes

* **auth system:** correcion del sistema de redireccion de token de auth con google ([b2667b8](https://github.com/0vethor0/VenHub/commit/b2667b8eb60007fb7e0185f27091a68dab191f7b))
* **auto-update:** se quito la funcion Future.delayed(..., SystemNavigator.pop) en version_update_provider.dart. ([94c2826](https://github.com/0vethor0/VenHub/commit/94c2826856bef6998ddf60d920f82f02468daa7c))

## [1.4.0](https://github.com/0vethor0/VenHub/compare/v1.3.2...v1.4.0) (2026-08-13)


### Features

* **GUI:** reafactorizacion de toda la interces, siguiendo el wireframes ui kit ([fa5b6a8](https://github.com/0vethor0/VenHub/commit/fa5b6a8b5e66bbe8997dfb50141ea403900a7ddd))


### Bug Fixes

* **format:** add format ([38e63b6](https://github.com/0vethor0/VenHub/commit/38e63b6ebe228eb9fd360a19cd6ceff13931eac4))
* solucion en tests unitarios ([7ac46fb](https://github.com/0vethor0/VenHub/commit/7ac46fb1db1dad825ad82c5a043fef4373bc37af))

## [1.3.2](https://github.com/0vethor0/VenHub/compare/v1.3.1...v1.3.2) (2026-08-13)


### Bug Fixes

* **auto-update:** Se ha modificado lib/providers/version_update_provider.dart para utilizar getApplicationSupportDirectory() en lugar de getApplicationDocumentsDirectory(), garantizando que el APK se guarde en la ruta interna /data/data/.../files/, la cual está correctamente configurada bajo &lt;files-path&gt; en file_paths.xml. ([ad14c94](https://github.com/0vethor0/VenHub/commit/ad14c94f4bdfe664cc2ee54ea28ee7f42d6e55d3))

## [1.3.1](https://github.com/0vethor0/VenHub/compare/v1.3.0...v1.3.1) (2026-08-13)


### Bug Fixes

* **actualizaciones:** optimizar flujo de descarga, permisos y manejo de errores de APK ([a520e54](https://github.com/0vethor0/VenHub/commit/a520e543d72e28424c2ee5d86c4fc7c4307b17d1))

## [1.3.0](https://github.com/0vethor0/VenHub/compare/v1.2.0...v1.3.0) (2026-08-13)


### Features

* **UI/UX:** autenticación completa con Google OAuth y recuperación de contraseña ([f441cf4](https://github.com/0vethor0/VenHub/commit/f441cf4d2589454d92a4e7eccac34d0c15847264))

## [1.2.0](https://github.com/0vethor0/VenHub/compare/v1.1.0...v1.2.0) (2026-08-12)


### Features

* **actualizaciones:** mejorar flujo de descarga e instalación de APK y permisos ([dcbbe4c](https://github.com/0vethor0/VenHub/commit/dcbbe4cf8b70f814ec0f809b870b3ba1543b46ae))


### Bug Fixes

* configure android file intent handling and resolve analysis errors ([99f36af](https://github.com/0vethor0/VenHub/commit/99f36afe869947136429fb613aefba8085254365))
* **format:** si aplico el formato al archivo especificado ([3eb3d07](https://github.com/0vethor0/VenHub/commit/3eb3d07bf5cbe33aa68365f794bd8e71791c162c))
* He implementado la solución para el problema de actualización de la app ([2528fc4](https://github.com/0vethor0/VenHub/commit/2528fc400efa42790c7dfadbacead191c2a94902))

## [1.1.0](https://github.com/0vethor0/VenHub/compare/v1.0.0...v1.1.0) (2026-08-12)


### Features

* **refactor:** UI/UX: ([529559c](https://github.com/0vethor0/VenHub/commit/529559c589c3d8bf650d68e7f7a7ac4ac1a8304a))

## 1.0.0 (2026-08-12)


### Features

* implement CI/CD pipelines for automated testing, release management, and AI-generated release notes ([aeab192](https://github.com/0vethor0/VenHub/commit/aeab1929ce10f9803779569306e99cd84df72e38))
* implementar sistema de versionado automático con Realtime y actualización forzada ([b07828d](https://github.com/0vethor0/VenHub/commit/b07828d2cd6bb263531caad01df284aa25e98bb9))
* initialize cross-platform Flutter project structure with core feature screens and Supabase schema ([a294352](https://github.com/0vethor0/VenHub/commit/a294352ebbcbc36a8f73f3401c31841d997105d5))


### Bug Fixes

* Advertencia de obsolescencia y error de suscripción en tiempo real ([e8a7914](https://github.com/0vethor0/VenHub/commit/e8a79142418ded23d4a022cb94b479ead001143b))
* Check formatting ([f075c18](https://github.com/0vethor0/VenHub/commit/f075c183c91f41080bae2fe4f26e40f4a600a114))
