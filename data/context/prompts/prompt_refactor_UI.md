Necesito realizar una refactorización a nivel de interfaz de usuario, sin intervenir drásticamente en la experiencia de usuario ni en la distribución de cómo se interactúa con los datos.

A nivel de interfaz de usuario:

1. Limítate a seguir las propuestas de interfaces guardadas en las imágenes .png dentro de la carpeta "WhiteFriends.uikey". Ahí se muestran las referencias para la pantalla de carga, la pantalla de ajustes, entre otras cosas. También se pueden visualizar los colores predominantes, la combinación de colores para la app, así como los colores y tamaños de las fuentes. Lo primordial es que te acoples a las referencias de estos wireframes.
2. Sustituye el icono actual de la aplicación por el que se muestra dentro de la misma carpeta "WhiteFriends.uikey".

Por otra parte, a nivel de backend y base de datos:
Quiero que agregues y modifiques algunos campos en la tabla "puntos_camara". A su vez, debes realizar las modificaciones concernientes dentro del código de la app de Flutter. Los nuevos campos son los siguientes:

• Contexto específico:
Es un campo de tipo texto libre para que el usuario ingrese información a su criterio relacionada con la ubicación del punto de la coordenada (por ejemplo: "entrada o salida de un municipio", "intersecciones", etc.). El nombre técnico del campo debe ser "contexto_especifico".

• Flujo peatonal:
A nivel de código de la app, implementa un combo box con tres respuestas precargadas:
(a) Alto
(b) Medio
(c) Bajo

• Flujo vehicular:
Igualmente, debe ser un combo box para desplegar las siguientes respuestas precargadas:
(a) Alto
(b) Medio
(c) Bajo

• Puntos ciegos:
Un campo de tipo texto.

• Observaciones:
Un campo de tipo texto libre.