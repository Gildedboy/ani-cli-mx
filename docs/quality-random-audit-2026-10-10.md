# CLI: aleatorio y selección real de calidad — 10 de octubre de 2026

Auditoría previa a la implementación sobre `ani-cli-mx-core` 3.0.9.
El menú y los resolvers del repositorio no se modificaron. Se usaron sus
funciones actuales en un arnés temporal, conservando referrers y headers.
La muestra es dirigida: no demuestra cobertura de todos los episodios,
idiomas ni estabilidad futura de los hosts.

## Qué merece implementarse

| Proveedor y muestra | Opciones observadas | Evidencia | Decisión |
| --- | --- | --- | --- |
| PelisPlusHD/Vidhide, South Park s1e1 LAT | 1076p, 720p, 480p | Las tres decodificaron un cuadro; dimensiones 1440×1076, 964×720 y 640×480 | Primera opción para un selector real |
| PelisPlusHD/Vidhide, Interstellar LAT | 1080p, 720p, 480p | Las tres decodificaron un cuadro; 1920×1080, 1280×720 y 852×480 | Primera opción para un selector real |
| AnimeAV1, Yani Neko 1 | Zilla HLS 1080p; Voe 720p | HLS es un media playlist sin variantes; Voe anuncia una única variante 720p. Ambos decodificaron video; mpv de Windows reprodujo HLS con audio tras buscar al segundo 60 | Ofrecer fuente + resolución real; no fingir varias calidades de un mismo mirror |
| JKAnime, One Piece 1 | Desu 480p; Magi 480p | Ambos HLS son media playlists sin variantes y decodificaron 640×480. Desuka no decodificó | Selector de mirror cuando haya alternativas; no selector de calidad para esta muestra |
| AnimeX/Sora, One Piece 1 (`one-piece-p8k27`) | Master anuncia 1080p, 720p, 360p | mpv seleccionó y decodificó las tres resoluciones con audio mediante el master y `--hls-bitrate`. Hubo numerosos 403 y la prueba de continuidad no avanzó desde el segundo 60 | Potencial real, pero no habilitarlo como fuente fiable con esta evidencia |
| AnimeX/Loli, mismo episodio | Master anuncia 360p, 480p, 720p, 1080p | Las pruebas de los extremos no produjeron video reproducible | Descartar estos enlaces en la muestra; anuncio no equivale a disponibilidad |
| AnimeX/Zuna y Yuki, mismo episodio | Sólo 1080p en cada master | Una variante por mirror y cuadro decodificado; Zuna anunció ancho 1920 pero decodificó 1440×1080, Yuki 1440×1080 | Respaldos de fuente; no aportan selección entre resoluciones en esta muestra |
| AnimeX/Nero, mismo episodio | La CLI lo etiqueta 1080 | El enlace emitido por el resolver no decodificó | Descartar en esta muestra |
| AniDB | No confirmado | `/browse?q=One+Piece` respondió HTTP 200 con título Anilab2 y sin las referencias que reconoce el parser actual. No había curl-impersonate disponible | Revisar compatibilidad del proveedor antes de atribuirle opciones de calidad |

No se consultó Hentaila: corresponde al modo adulto separado, fuera de esta
muestra de proveedores normales. AnimeFLV no es una fuente activa.

La altura 1076 de South Park es la resolución anunciada y decodificada del
video; no se debe presentar como si el enlace tuviera exactamente 1080 líneas.
Las verificaciones de un cuadro sólo confirman apertura y decodificación,
no un episodio completo ni continuidad garantizada.

## Por qué el selector actual induce a error

- `jkanime_internal_player_priority`, `jkanime_server_priority` y
  `animeav1_server_priority` emiten prioridades como 940, 950, 960 o 970.
  `select_quality` y `quality_menu_entries` interpretan ese mismo campo
  como resolución. Son datos diferentes que necesitan campos separados.
- `resolve_animex_provider` transforma `quality: auto` en `1080` sin
  inspeccionar las variantes. En esta muestra eso ocultó las alternativas
  360/720/1080 de Sora y las 360/480/720/1080 anunciadas por Loli.
- `select_quality` busca una coincidencia numérica exacta. Si falta, toma el
  primer enlace con un aviso. Sobre los candidatos brutos de esta auditoría,
  pedir 1080, 720 o 480 a AnimeAV1 seguía seleccionando la etiqueta de
  prioridad 960; en JKAnime, 960; en AnimeX, 1080. El filtrado de reproducción
  puede eliminar mirrors rotos, pero no corrige esas etiquetas.
- En South Park, pedir 1080 no coincide con 1076 y recurre al enlace mejor
  ordenado; 720 y 480 sí seleccionan variantes distintas. En Interstellar
  las tres peticiones coinciden con sus respectivas variantes.
- El modo rápido conserva sólo el primer enlace en varias rutas. Abrir un
  futuro selector exige descubrir alternativas bajo demanda en vez de
  presentar una lista de la que ya se descartaron los demás candidatos.
- `quality_menu_entries` existe, pero no se invoca desde el menú actual de
  reproducción. Añadir sólo una entrada al menú no resuelve el contrato de
  datos ni el descubrimiento de variantes.
- PelisPlus valida un candidato dentro del resolver y después selecciona
  según `quality` en `get_episode_url`. Si el elegido difiere del validado
  y falla, la ruta actual termina con error; no reutiliza automáticamente
  el candidato que ya había pasado la validación.
- `pelisplus_packed_host_links` inventa una etiqueta 720 cuando no extrae
  variantes. En ese caso la resolución debe quedar desconocida/automática
  hasta contar con evidencia.

## Audio y estabilidad: requisitos de una implementación útil

El master de Sora tiene un grupo de audio japonés separado mediante
`#EXT-X-MEDIA`. Abrir directamente sólo un child playlist de video produjo
cuadros sin pista de audio. Conservar el master y seleccionar su bitrate
produjo la resolución solicitada y salida de audio en las tres opciones.
Otra solución debe conservar también ese grupo de audio y sus headers.

La prueba adicional de Sora pidió 720p desde el segundo 60 durante 12 segundos,
con un límite de ejecución de 45 segundos. mpv terminó con estado 0, abrió
1280×720 y audio, pero la última posición registrada fue 00:01:00 y aparecieron
127 errores 403. No pasó una comprobación de continuidad; no confundir
estado 0, un manifiesto válido o un cuadro con reproducción sostenida.
La causa de esos 403 no quedó determinada en esta auditoría.

Zilla también depende del reproductor: el mpv Linux instalado activa la
comprobación existente que evita buscar AV1 con FFmpeg antiguo, por lo que
el resolver normal prefirió Voe. El mpv de Windows sí decodificó 1080p con
audio tras buscar al segundo 60. El selector debe mantener esa distinción
de compatibilidad en vez de prometer una calidad que el player no sostiene.

## Opción aleatoria

Es viable independientemente de las calidades. Seleccionar de los tokens
reales del catálogo, preservar decimales y `sXeY`, excluir acciones
`__nav_*`/`__jk_*` y evitar repetir inmediatamente el episodio actual cuando
haya otro. No ofrecer episodio aleatorio para una película.

PelisPlus permite elegir entre temporadas del catálogo cargado. JKAnime usa
paginación bajo demanda: una primera implementación debe explicitar
«aleatorio en esta página»; seleccionar uniformemente de toda la serie
requiere otra estrategia, no descargar todos los bloques sólo para sortear
un episodio. Una acción puntual y reproducción continua aleatoria son
comportamientos distintos; el segundo no está implícito en esta propuesta.

## Alcance de las comprobaciones

Se revisaron funciones de menú, formato de enlaces y selección, se resolvieron
dos muestras de PelisPlus y una por proveedor de anime, y se inspeccionaron
sus manifiestos. Se reutilizaron cuadros ya decodificados por los resolvers.
Los follow-ups respondieron a preguntas concretas: mirrors de JKAnime,
ID real de AnimeX, HLS publicado por AnimeAV1, audio separado de Sora,
compatibilidad de Windows y continuidad ante los 403.

No se ejecutó la suite general ni se recorrieron catálogos completos.
La auditoría inicial precedió a la implementación del menú y de aleatorio.
Los resúmenes, manifiestos y logs temporales quedaron en
`/tmp/ani-cli-quality-audit-2026-10-10/`; las URLs firmadas no se publican aquí.

## Implementación y validación posterior

Se agregó aleatorio al selector de episodios y al menú de reproducción para
anime, series y doramas. Usa tokens reales, conserva decimales y temporadas,
y evita repetir el episodio actual cuando hay alternativas. En JKAnime se
elige una página aleatoria y después un episodio; todas las páginas son
alcanzables sin cargar la serie completa, aunque las probabilidades por
episodio difieren si las páginas tienen tamaños distintos.

El menú de calidad se limita a PelisPlusHD/Vidhide y mpv persistente. Requiere
al menos dos resoluciones explícitas distintas que decodifiquen video. Las
variantes que fallan se excluyen; la selección se comprueba nuevamente antes
de interrumpir el video actual. Se preservan referrer, headers, posición y pausa.
Los demás proveedores auditados no ofrecen este menú.

Las regresiones enfocadas cubrieron selección aleatoria, paginación, exclusión
de variantes fallidas y cambio de calidad sin interrumpir ante un fallo.
También pasaron las regresiones existentes afectadas de menú, paginación,
resolver PelisPlus y mpv persistente. Un mpv real con video local confirmó
retención de posición, pausa y audio, y reinicio normal al cambiar de episodio.
Una comprobación posterior en vivo de South Park s1e1 habilitó el menú con
1076p, 720p y 480p. No se repitió la suite general ni el barrido de proveedores;
una comprobación de decodificación inicial no garantiza continuidad futura.
