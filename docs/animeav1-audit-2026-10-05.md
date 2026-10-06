# AnimeAV1: cobertura y reproducción — 5 de octubre de 2026

Se consultaron 15 episodios SUB de 14 series. La muestra es dirigida, no una
medición de todo el catálogo. Los botones visibles no prueban disponibilidad:
se contaron las URLs publicadas en `embeds.SUB` del documento real.

| Serie / episodio | Voe | PDrain |
| --- | --- | --- |
| Yani Neko / 1 y 2 | Sí | No |
| Last Exile / 14 | Sí | Sí |
| Claymore / 1 | Sí | No |
| Fate/strange Fake / 1 (2026) | Sí | No |
| Sousou no Frieren 2nd Season / 1 (2026) | Sí | No |
| Mao / 1 (2026) | Sí | No |
| Hidarikiki no Eren / 1 (2026) | Sí | No |
| Ryoumin 0-nin Start no Henkyou Ryoushu-sama / 1 (2026) | Sí, pero HTTP 404 | No |
| Dandelion / 1 (2026) | Sí | No |
| Otaku ni Yasashii Gal wa Inai!? / 1 (2026) | Sí | No |
| Steel Ball Run / 1 (2026) | Sí | No |
| Green Green / 1 | Sí | No |
| Ping Pong the Animation / 1 | Sí | No |
| Bleach: Sennen Kessen-hen / 10 | Sí | No |

Voe apareció en 15/15 episodios; PDrain en 1/15. MP4Upload y UPNShare aparecieron
en 15/15 y Byse en 14/15. Ninguno publicó HLS en `embeds.SUB`, aunque las páginas
indexadas mostraban un botón HLS. PDrain es una opción ocasional en esta muestra.

## Pruebas de reproducción

El reproductor Voe redirige mediante JavaScript a otro dominio. Allí publica
un JSON ofuscado: ROT13, eliminación de separadores, Base64, desplazamiento
de caracteres, inversión y otro Base64. El JSON contiene una URL HLS firmada.
La CLI reproduce estas transformaciones sin ejecutar el JavaScript remoto,
obtiene una URL nueva en cada resolución y conserva el referrer del embed final.
El procedimiento también está descrito en el código público de
[voe-dl](https://github.com/p4ul17/voe-dl/blob/main/voe_dl/decoding.py).

Se extrajo HLS de nueve enlaces Voe: Yani Neko, Last Exile, Mao, Fate/strange
Fake, Frieren 2, Hidarikiki no Eren, Dandelion, Otaku ni Yasashii Gal wa Inai!?
y Steel Ball Run. Ryoumin devolvió HTTP 404 y no se aceptó como video.

mpv decodificó un fotograma de seis episodios Voe: Yani Neko 1, Last Exile 14,
Mao 1, Fate/strange Fake 1, Frieren 2 episodio 1 y Dandelion 1. Las cinco
pruebas adicionales al primer caso tardaron aproximadamente 4,4–4,7 segundos
en esta conexión. Esto valida el inicio de reproducción, no la reproducción
completa ni la estabilidad futura del host.

PDrain de Last Exile 14 publicó el archivo `SuUoCfue`; su API informó
`video/mp4`, descarga y reproductor permitidos. mpv decodificó un fotograma
desde `https://pixeldrain.com/api/file/SuUoCfue` en unos 2 segundos.
El endpoint y sus posibles límites/captcha están documentados por
[Pixeldrain](https://de03.pixeldrain.com/api).

La CLI completa seleccionó AnimeAV1 / Voe en Yani Neko y Mao. En Ryoumin
descartó Voe y seleccionó AnimeAV1 / MP4Upload. Se conservaron fuente,
sitio y referrer. Las pruebas locales cubren prioridad, decodificación de
Voe, referrer final, rechazo de un Voe no reproducible y respaldo MP4Upload.

## Otros resolutores

| Host | Evidencia y estado |
| --- | --- |
| UPNShare | La aplicación usa `/api/v1/video` y datos cifrados; una petición solo con el ID devolvió HTTP 400 «Request is invalid». Sigue pendiente reproducir sus parámetros y decodificación. No se demostró reproducción. |
| Byse | Se localizaron sus módulos públicos y APIs de detalles, configuración, playback y comprobación. Yani Neko 1 devolvió `captcha_required:true`; GET y POST vacíos de playback devolvieron HTTP 405. Estos intentos no reproducen todo el flujo del navegador. Sigue pendiente. |
| TransferIt | Ruta de descarga; el análisis anterior encontró `secureboot.js`. No se volvió a validar playback en esta revisión. |
| Mega | Ruta de archivo con clave en el fragmento. Requiere descarga/descifrado y un flujo distinto de HLS directo. No se implementó en esta revisión. |
| 1Fichier | Ruta de descarga con espera y posible captcha según la auditoría anterior. No se volvió a validar en esta revisión. |
| YourUpload | Publicado en Bleach 10; yt-dlp obtuvo un MP4. La prueba completada tras la pausa decodificó un fotograma H.264 720p con audio AAC mediante mpv. |
| VidHide y StreamTape | Publicados en Bleach 10; yt-dlp instalado rechazó las URLs probadas como no soportadas. Requerirían revisión específica. |

La preferencia implementada es HLS publicado → Voe → PDrain → YourUpload → MP4Upload,
seguida de los embeds adicionales mediante el extractor genérico existente.
MP4Upload queda como último reproductor de la lista actualmente verificada.
Sin Python 3, Voe conserva el intento con yt-dlp y después continúa al respaldo.

La auditoría anterior permanece como registro histórico:
[29 de septiembre](animeav1-audit-2026-09-29.md).

## Validación posterior a la pausa

HLS reapareció en `embeds.SUB` y `embeds.DUB` de Yani Neko 1.
El SUB usa `/play/0d9e54509457b1d309dc273c1dc83d8b`; mpv decodificó
un fotograma AV1 1920×1080 y detectó audio AAC con los encabezados de
`zilla_header_fields` y el referrer del player. Hubo una advertencia de
reconexión al precargar otro segmento; esta prueba no garantiza continuidad
durante todo el episodio. La CLI completa seleccionó `AnimeAV1 / HLS`.

El modo clásico también termina al validar HLS, evitando resolver Voe
después de haber encontrado una reproducción válida. YourUpload de Bleach 10
también decodificó un fotograma: se prioriza antes de MP4Upload cuando se publica.

## Validación ampliada para 3.0.8 y alpha36

Se volvió a consultar HLS en diez series: Yani Neko, Mao, Frieren 2,
Fate/strange Fake, Otaku ni Yasashii Gal wa Inai!?, Last Exile, Claymore,
Green Green, Ping Pong y Bleach. Las diez publicaron HLS SUB.

Con mpv de Windows 0.41.0 y FFmpeg libavformat 62, las veinte pruebas pasaron:
240 fotogramas desde el inicio y 48 fotogramas tras buscar el segundo 600 en
cada episodio. Los saltos tardaron aproximadamente 5,2–8 segundos en esta
conexión. La muestra verifica inicio, varios segmentos y una posición remota;
no equivale a reproducir diez episodios completos.

Con mpv de Ubuntu 0.37.0 y FFmpeg 6.1.1, las diez reprodujeron desde el inicio,
pero las diez pruebas de salto fallaron con errores de análisis AV1 y timeout.
La CLI evita Zilla HLS si el reproductor de prueba declara FFmpeg 6 o anterior,
y continúa a Voe u otro respaldo. No cambia de servidor durante la reproducción.
FFmpeg 7 no se probó en esta revisión; el caso reciente verificado usa libavformat 62.

Android alpha36 conserva HLS como primera opción, declara su MIME explícitamente,
añade Voe/PDrain/YourUpload y mantiene MP4Upload como respaldo. Se preservan los
encabezados de Zilla y el referrer final de Voe. La reproducción Media3 en un
telefono físico es una verificación separada y requiere un dispositivo conectado.

## JKAnime y comprobaciones de la entrega

La consulta completa de episodios de JKAnime se introdujo el 22 de abril
y pasó a lanzar todas las páginas simultáneamente el 1 de agosto. En una serie
larga podía generar una ráfaga de peticiones. El firewall respondió HTTP 429;
una consulta aislada tras una pausa respondió HTTP 200.

La CLI 3.0.8 carga ahora bloques bajo demanda y los guarda durante cinco minutos.
El selector permite navegar, buscar un número exacto o ir al último episodio.
Siguiente/anterior y los rangos consultan solo los bloques necesarios. Se
mantienen los decimales y números ausentes del catálogo real; no se genera
una lista sintética completa. Un HTTP 429 pausa nuevas peticiones, incluidos
los diagnósticos, durante 65 segundos. Esto reduce tráfico, pero no garantiza
que el firewall nunca bloquee una IP por otras peticiones.

La prueba local de One Piece simula 118 bloques: abrir el catálogo requiere
dos consultas, repetirlo usa caché y pasar de un bloque a otro añade una.
Se verifican decimales, huecos, orden inverso, rangos, menús, expiración y 429.
La validación general en vivo pasó JKAnime y AnimeAV1 después de este cambio,
pero se detuvo en AniDB por búsqueda sin resultados. No se declara toda la
suite de red aprobada. El usuario pidió publicar la CLI y aplazar nuevas
consultas de JKAnime hasta mañana.

La app alpha36 incorpora la misma carga bajo demanda, navegación de páginas,
búsqueda por número, caché y pausa ante 429. Las pruebas en teléfono quedan
a cargo del usuario; la APK se entrega firmada en su carpeta de Windows.
