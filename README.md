---

# Proyecto de Topología con Flutter y Firebase

Este proyecto es una aplicación móvil desarrollada utilizando Flutter y Firebase para calcular el área entre tres dispositivos celulares. Permite a los usuarios establecer puntos en un espacio físico y calcular el área del triángulo formado por estos puntos, utilizando la tecnología de geolocalización de los dispositivos.

Link del despliegue con vercel

https://web-application-khaki.vercel.app/

Link del video manual de usuario
https://youtu.be/w6hE0hgTCSs

## Integrantes del Equipo

- David Basantes
- Miguel Carapaz
- Jose Pinos

## Funcionalidades Principales

- Registro y autenticación de usuarios utilizando Firebase Authentication.
- Utilización de la API de geolocalización de Google para determinar la posición de los dispositivos.
- Cálculo del área del triángulo formado por las ubicaciones de tres dispositivos móviles.

## Requisitos

- Flutter SDK
- Google Services JSON (para integración con Firebase)
- Conexión a internet (para utilizar las funciones de Firebase)

## Instalación

1. Clona el repositorio:

```bash
git clone https://github.com/tu_usuario/tu_proyecto.git
```

2. Agrega el archivo `google-services.json` provisto por Firebase en la carpeta `/android/app`.

3. Ejecuta el siguiente comando para obtener las dependencias:

```bash
flutter pub get
```

## Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Habilita la autenticación por correo electrónico en la pestaña **Authentication**.
3. Descarga el archivo `google-services.json` y agrégalo a la carpeta `/android/app` de tu proyecto.

## Estructura del Proyecto

```
topologia_flutter_firebase/
├── android/
├── build/
├── ios/
├── lib/
├── test/
├── .gitignore
├── README.md
└── ...
```

## Uso

1. Abre el proyecto en tu IDE preferido.
2. Conecta tres dispositivos móviles.
3. Ejecuta la aplicación en cada dispositivo.
4. Inicia sesión o regístrate utilizando Firebase Authentication.
5. Establece la ubicación en cada dispositivo.
6. Calcula el área del triángulo formado por las ubicaciones de los dispositivos.

## APK

La APK de la aplicación se encuentra en `build/app/outputs/apk/release` después de compilar el proyecto.

## Contribuciones

¡Las contribuciones son bienvenidas! Si deseas contribuir a este proyecto, por favor abre un problema o envía una solicitud de extracción.


---
