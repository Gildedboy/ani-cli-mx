# Auditoría de AnimeAV1 — 29 de septiembre de 2026

## Muestra y método

Se revisaron las páginas de `Yani Neko`, episodios 1 y 2, en modo SUB y la
salida de reproducción del episodio 1. Se probaron los enlaces publicados con
yt-dlp 2024.04.09 y, para UPNShare, Voe y Byse, también con 2026.08.19. Un enlace se consideró
reproducible solo después de que mpv decodificara un fotograma con su referrer.
Estas observaciones describen los enlaces probados hoy; los servidores pueden
cambiar sus páginas, archivos y restricciones.

## Enlaces publicados y resultado

| Servidor | Resultado para el episodio 1 SUB | Causa observada |
| --- | --- | --- |
| HLS | Ausente | Ni el episodio 1 ni el 2 lo publican en `embeds` o `downloads`. |
| MP4Upload | Sí | El embed contiene un MP4 directo. Una petición parcial recibió HTTP 206 y mpv decodificó video AV1 1080p con audio AAC. La URL de descarga del mismo archivo no la acepta yt-dlp, pero la del embed sí. |
| UPNShare | Sin enlace reproducible | Publica una aplicación web cuyo ID va en el fragmento `#`; el HTML no expone el video. Su API de información devuelve datos cifrados. Ambas versiones de yt-dlp rechazaron la URL. |
| Voe | Sin enlace reproducible | `voe.sx` entrega una redirección por JavaScript a otro dominio. La página final contiene datos de reproductor ofuscados. Ambas versiones de yt-dlp rechazaron la URL original. |
| Byse | Sin enlace reproducible | Entrega una aplicación web; el HTML inicial no incluye el archivo. Ambas versiones de yt-dlp rechazaron la URL. |
| TransferIt | Descarga, sin reproducción directa | La página inicial carga `secureboot.js`; yt-dlp 2024.04.09 no obtuvo un archivo de video. |
| Mega | Descarga, sin reproducción directa | AnimeAV1 entrega una URL de archivo con clave en el fragmento. La integración actual no implementa descarga y descifrado de Mega para mpv. |
| 1Fichier | Descarga, sin reproducción directa | La página mostró una espera gratuita de 60 segundos, velocidad limitada y posibilidad de captcha. yt-dlp 2024.04.09 no obtuvo un archivo de video. |

Un HTTP 200 de la página de un host no demuestra reproducción: UPNShare, Voe,
Byse, TransferIt y 1Fichier respondieron 200, pero no entregaron una URL que
mpv pudiera abrir por el método actual.

## Causa de la demora

El modo rápido está activado por defecto (`ANI_CLI_FAST_MODE=1`) y la calidad
predeterminada es `best`. Antes de esta corrección, recorría los embeds en el
orden publicado por AnimeAV1: UPNShare, Voe, Byse y finalmente MP4Upload en
los episodios revisados. HLS no aparece en esas páginas; solo se habría
probado si AnimeAV1 lo publicara. Cada embed no resuelto podía ejecutar yt-dlp
dos veces antes de llegar al MP4 válido.

En modo clásico, además, se procesaban `downloads` antes de `embeds`:
TransferIt, 1Fichier y la URL de descarga de MP4Upload añadían intentos
fallidos. Después, el MP4 ya validado con mpv se probaba otra vez en
`filter_playable_links`.

Ahora AnimeAV1 consulta primero el embed de MP4Upload, extrae el MP4 de su
página y valida un fotograma. Si funciona, termina esa resolución. Si falla,
recorre los demás embeds como alternativas. Las páginas de descarga no se
intentan como reproductores; la URL de descarga de MP4Upload sirve de respaldo
cuando falta su embed. El filtro conserva la validación que ya hizo el
resolver y evita la segunda decodificación.

## Comprobación

- `Yani Neko` episodio 1, modo clásico, reproductor debug: 20,3 s antes de
  los cambios y 6,5 s después, en ejecuciones de esta máquina. El tiempo de
  red varía entre ejecuciones.
- El modo rápido eligió MP4Upload en 6,5 s.
- mpv abrió el MP4 del episodio 1, decodificó un fotograma y detectó video
  AV1 1920×1080, audio AAC y duración aproximada de 23:42.
- El episodio 2 también publica MP4Upload sin HLS y se resolvió en modo clásico.
- La regresión local verifica que MP4Upload se elige antes que los hosts de
  descarga y que se conserva el referrer sin invocar yt-dlp para ese archivo.
- `./tests/sanity.sh --syntax` pasó. La prueba de red completa no llegó a su
  fase de reproducción porque este entorno no tiene `curl-impersonate`, que
  exige el caso de AniDB; las pruebas reales de AnimeAV1 se ejecutaron aparte.

## Trabajo pendiente para otros servidores

UPNShare, Voe y Byse necesitarían resolutores propios que reproduzcan sus
flujos actuales de JavaScript y credenciales, seguidos de una prueba real de
mpv. Su estado actual no se debe cambiar a «sí» basándose solo en HTTP 200.
TransferIt, Mega y 1Fichier son rutas de descarga y necesitarían una
integración de descarga distinta de la selección de mirrors de reproducción.
