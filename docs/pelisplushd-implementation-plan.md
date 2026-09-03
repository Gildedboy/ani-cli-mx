# Plan de implementación de PelisPlusHD

Estado: implementación terminada para 3.0.0; pendiente únicamente de publicación.

## Estado de entrega

La implementación fue terminada y validada el 3 de septiembre de 2026. Este
documento conserva tanto el diseño como la lógica de resolución para servir de
material fuente en futuras conversaciones y en otros clientes. No se debe
reiniciar la investigación sin revisar primero el código y este documento.

### Implementado y comprobado

- Versión interna cambiada a `3.0.0`.
- Menú principal con una sola entrada `Buscar`.
- Submenú `Anime`, `Películas`, `Series` y `Doramas`; cada opción abre su campo
  de búsqueda.
- Búsqueda directa mediante `-t/--type`; una consulta directa sin tipo se
  rechaza.
- Validaciones para impedir `--source` y `--skip` con contenido no anime.
- IDs tipados de PelisPlusHD y tokens de episodio como `s1e1`.
- Búsqueda y filtrado de películas, series y doramas; PelisPlusHD nunca se usa
  para anime.
- Catálogo de temporadas/capítulos y salto del selector de episodios para
  películas.
- Resolución completa de películas:
  `PelisPlusHD -> Embed69 -> PoW SHA-256 -> AES-256-CBC -> Vidhide -> P.A.C.K.E.R. -> HLS`.
- Resolución completa de series/doramas:
  `PelisPlusHD -> Embed69 -> Vidhide -> P.A.C.K.E.R. -> HLS`.
- Propagación de calidad, referrer, sitio, espejo e idioma.
- Selector/prioridad de idiomas `LAT`, `ESP` y `SUB`, configurable con
  `ANI_CLI_PELISPLUS_LANGUAGE`.
- Controles contextuales: las películas no muestran siguiente, anterior,
  selector de capítulo ni modo continuo.
- Títulos contextuales e historial con tipo de contenido.
- Pruebas reales satisfactorias con un frame decodificado por mpv para
  `Interstellar` y `Belleza verdadera S1E1`.
- README, manual, disclaimer, workflow de Windows y manifiesto Scoop
  actualizados para 3.0.0 y para ampliar el alcance más allá de anime.
- Prueba real satisfactoria de una serie normal: `Mythic Quest S1E1`, con
  clasificación como serie, resolución HLS y frame decodificado por mpv.
- Suite offline completa satisfactoria. La suite de red puede requerir
  `ANI_CLI_ANIDB_CURL` por la protección vigente de AniDB.

### Incidencia conocida del proveedor

Bug manual reportado:

- `Backrooms (2026)` reproduce la entrada marcada `SUB`, pero ese archivo no
  muestra subtítulos. La inspección de Embed69, Vidhide, el resultado
  P.A.C.K.E.R. y el manifiesto HLS confirmó que no existe una pista VTT/SRT ni
  una pista HLS separada que el cliente pueda cargar.
- Otras películas comprobadas por el usuario, como Avatar y John Wick, sí
  muestran los subtítulos de su variante `SUB`. Por tanto, `SUB` representa
  normalmente subtítulos incrustados y Backrooms es una carga individual mal
  etiquetada por el proveedor, no un fallo general del resolutor.
- Vidhide es el mirror implementado y validado. Streamwish se intenta primero
  para películas `SUB`, pero su enlace puede pasar por un cargador JavaScript;
  si no produce HLS válido, la resolución vuelve de forma segura a Vidhide.

### Verificación final

```sh
./tests/sanity.sh --syntax
./tests/sanity.sh --network
git diff --check
```

### Pruebas manuales disponibles

```sh
./ani-cli-mx
./ani-cli-mx -t movie interstellar
./ani-cli-mx -t series -e s1e1 "mythic quest"
./ani-cli-mx -t dorama -e s1e1 "belleza verdadera"
./ani-cli-mx -t anime -e 1 "one piece"
ANI_CLI_PLAYER=debug ANI_CLI_PELISPLUS_LANGUAGE=LAT ./ani-cli-mx -t movie -S 1 interstellar
ANI_CLI_PLAYER=debug ANI_CLI_PELISPLUS_LANGUAGE=LAT ./ani-cli-mx -t dorama -S 1 -e s1e1 "belleza verdadera"
```

### Archivos modificados hasta el checkpoint

- `ani-cli-mx-core`
- `README.md`
- `ani-cli-mx.1`
- `disclaimer.md`
- `tests/sanity.sh`
- `.github/workflows/windows.yml`
- `bucket/ani-cli-mx.json`
- `docs/pelisplushd-implementation-plan.md`

## Uso de este documento en un chat nuevo

Este archivo es el documento de traspaso y la fuente de contexto para continuar la implementación en otra conversación. Antes de modificar el repositorio, el nuevo agente debe:

1. Leer `AGENTS.md`.
2. Leer completamente `skills/maintain-ani-cli-providers/SKILL.md`.
3. Leer este documento completo.
4. Revisar `git status --short` y preservar cambios ajenos.
5. Confirmar nuevamente los endpoints vivos antes de escribir parsers.

Contexto histórico al crear el plan (antes de implementar 3.0.0):

- Directorio: `/home/gilded/ani-cli-mx`.
- Archivo principal: `ani-cli-mx-core`.
- Versión actual observada: `2.1.0`.
- La interfaz, el modelo de episodios y el historial actuales están orientados a anime.
- Todavía no existe código de PelisPlusHD.
- El único cambio realizado durante la planificación es este documento.
- Esta ampliación se publicará como `3.0.0`, no como una versión menor de la serie 2.x.

La instrucción de producto vigente es: el menú principal debe mostrar una sola opción `Buscar`; su submenú debe contener Anime, Películas, Series y Doramas, y cada opción debe abrir inmediatamente el campo de búsqueda correspondiente.

## Resumen de la investigación previa

Investigación realizada el 2 de septiembre de 2026 en horario de Chihuahua, correspondiente al 3 de septiembre de 2026 UTC en las respuestas HTTP.

### Endpoints y estructura observados

- Sitio base: `https://pelisplushd.bz`.
- Búsqueda: `GET https://pelisplushd.bz/search?s=<consulta>`.
- Película: `/pelicula/<slug>`.
- Serie o dorama: `/serie/<slug>`.
- Capítulo: `/serie/<slug>/temporada/<temporada>/capitulo/<episodio>`.
- Catálogo de doramas: `/generos/dorama`.
- Sitemaps publicados en `robots.txt`: `/sitemap/general`, `/sitemap/movies`, `/sitemap/series` y `/sitemap/animes`.

La búsqueda devuelve HTML renderizado en el servidor. Las tarjetas distinguen tipos mediante la ruta y clases como `Posters-link`, `peliculas`, `series` y `animes`. Los doramas no tienen una ruta propia: son series cuyo detalle contiene el género `/generos/dorama`.

### Cobertura observada

- 15,768 URLs de películas en el sitemap consultado.
- 3,371 URLs de series en el sitemap consultado.
- 331 doramas distribuidos en 14 páginas de catálogo.
- `Belleza verdadera` expuso directamente sus 16 capítulos de la primera temporada.
- `Mythic Quest` expuso cuatro temporadas en su página de detalle.

Estas cifras son una instantánea y deben volver a verificarse si resultan relevantes para una entrega futura.

### Títulos usados para investigar

- Película: `Interstellar`.
- Serie: `Mythic Quest`.
- Dorama: `Belleza verdadera`.

Rutas de referencia:

```text
https://pelisplushd.bz/pelicula/interstellar
https://pelisplushd.bz/serie/mythic-quest
https://pelisplushd.bz/serie/belleza-verdadera
https://pelisplushd.bz/serie/belleza-verdadera/temporada/1/capitulo/1
```

### Embed69 y espejos

Las páginas de PelisPlusHD contienen un arreglo JavaScript `video[]` que apunta a Embed69.

Se observaron dos formatos de Embed69:

- Películas: `/f/<IMDb ID>/`. La página contiene `dataLink`, tres idiomas posibles (`LAT`, `ESP`, `SUB`), enlaces cifrados con AES-256-CBC y una prueba de trabajo SHA-256 con challenge, dificultad y salt incluidos en el HTML.
- Series/doramas: `/video/<IMDb-temporada-capítulo>/`. Durante la investigación, esta página expuso espejos en texto claro.

Hosts observados: Vidhide, Streamwish, Voe, Uqload, Doodstream y Waaw. Sus dominios intermedios pueden cambiar, por lo que no deben identificarse mediante una sola hostname fija.

Resultados de los extractores durante la investigación:

- Tanto yt-dlp 2024.04.09 como yt-dlp 2026.08.19 fallaron con los hosts principales.
- Doodstream respondió con challenge/HTTP 403.
- Streamwish entregó una página de carga dependiente de JavaScript.
- Voe entregó una redirección mediante JavaScript hacia otro dominio.
- Waaw produjo un pequeño video `data:` ficticio, que no debe aceptarse como contenido válido.
- Vidhide entregó JavaScript empaquetado con el formato P.A.C.K.E.R.; al desempaquetarlo apareció un manifiesto HLS firmado.

### Reproducción confirmada

La validación siguió la regla del repositorio de decodificar un frame real con mpv, no limitarse a comprobar el manifiesto.

- `Interstellar`: Vidhide -> HLS -> frame decodificado por mpv a 852x480, con audio; duración reportada 02:49:03. El master también anunció 720p y 1080p.
- `Belleza verdadera` T1 E1: Vidhide -> HLS -> frame decodificado por mpv a 888x480, con audio; duración reportada 01:16:40.

El primer intento con el master del dorama eligió automáticamente la calidad más alta y agotó el timeout al cargar el primer segmento. La variante de 480p decodificó correctamente. La implementación debe considerar el tiempo de inicio al elegir calidad y debe comprobar segmentos reales.

### Rendimiento observado

- Cinco consultas consecutivas a la portada terminaron aproximadamente entre 0.52 y 0.55 segundos.
- Una búsqueda de `Breaking Bad` agotó un timeout de 25 segundos, mientras otras búsquedas respondieron normalmente.
- Se necesitan timeouts, reintentos limitados y mensajes que distingan sitio lento de parser roto.

### Zonas actuales del código que requieren atención

- `main_menu_options`, `main_menu` y `search_query_menu` definen la entrada de búsqueda actual.
- El bucle principal de estados se encuentra al final de `ani-cli-mx-core`.
- `site_name_from_ref`, `show_ref_value_for_site` y las funciones de etiquetas interpretan IDs de proveedores.
- `search_anime`, `episodes_list` y `get_episode_url` son los puntos principales de dispatch.
- `select_episode`, `play`, `next_episode_number` y el controlador persistente suponen actualmente episodios numéricos en algunos caminos.
- `history_entries`, `history_provider_label` y `build_history_menu` producen el historial visible.
- `play_episode` construye títulos como `Episode <n>` y propaga referrer/cabeceras al reproductor.
- `tests/sanity.sh` ya contiene pruebas del menú principal, navegación, historial, mpv persistente, Windows y proveedores.

El trabajo debe realizarse en `ani-cli-mx-core` y mantener sincronizados `tests/sanity.sh`, `README.md`, `ani-cli-mx.1` y las aserciones de versión de Windows.

## Objetivo

Ampliar ani-cli-mx para buscar y reproducir anime, películas, series y doramas sin mezclar PelisPlusHD con los proveedores de anime existentes.

PelisPlusHD se utilizará exclusivamente para:

- Películas.
- Series.
- Doramas.

El anime conservará sus proveedores, búsqueda, fallback y comportamiento actuales.

La lógica de resolución de PelisPlusHD debe quedar agrupada y explicada en el código y en este plan, de modo que otro chat pueda retomarla sin repetir la investigación. La aplicación Android se atenderá por separado y no impone una arquitectura específica a este repositorio.

## Decisiones de producto

### Menú interactivo

El menú principal tendrá una sola entrada de búsqueda:

```text
Inicio
├── Buscar
│   ├── Anime
│   ├── Películas
│   ├── Series
│   ├── Doramas
│   └── Volver al inicio
├── Continuar viendo
└── Salir
```

Cada tipo abre inmediatamente su campo correspondiente:

- `Buscar anime:`
- `Buscar película:`
- `Buscar serie:`
- `Buscar dorama:`

Escape regresa un nivel y Ctrl-C sale de la aplicación. La navegación esperada es:

```text
Resultados -> Campo de búsqueda -> Tipo de contenido -> Inicio
```

### Búsqueda directa mediante banderas

Se agregará `-t` / `--type` para indicar el tipo de contenido:

```sh
ani-cli-mx -t anime "one piece"
ani-cli-mx -t movie "interstellar"
ani-cli-mx -t series "mythic quest"
ani-cli-mx -t dorama "belleza verdadera"
```

También se aceptarán los alias en español `pelicula` y `serie`. Internamente se normalizarán a `movie` y `series`.

Comportamiento acordado:

- Sin argumentos: abrir el menú Inicio.
- Con tipo y consulta: realizar la búsqueda directamente.
- Con tipo pero sin consulta: abrir el campo de búsqueda de ese tipo.
- Con consulta pero sin tipo: terminar con un mensaje que solicite `--type`.
- `--source` continuará seleccionando exclusivamente proveedores de anime.
- Una combinación como `--type movie --source animeflv` se rechazará con un mensaje claro.

## Modelo interno

Agregar un contexto canónico `media_kind`:

```text
anime | movie | series | dorama
```

Los resultados de PelisPlusHD usarán referencias tipadas:

```text
pelisplus:movie:<slug>
pelisplus:series:<slug>
pelisplus:dorama:<slug>
```

Se crearán funciones específicas para extraer proveedor, tipo y slug. No se dependerá de eliminar ciegamente todo lo anterior al primer `:`.

Para series y doramas, los capítulos tendrán identificadores opacos separados de sus etiquetas:

```text
s1e1<TAB>T1 · E1 · The Errand Girl
s1e2<TAB>T1 · E2 · With or Without Make-Up
s3e10<TAB>T3 · E10
```

No se codificará temporada y episodio como un decimal, pues entraría en conflicto con episodios fraccionarios de anime. La navegación comparará tokens literalmente, sin interpolarlos como expresiones regulares de `sed`.

## Fases de implementación

### 1. Generalizar el estado de navegación

- Introducir `media_kind` sin modificar el comportamiento de anime.
- Volver neutrales las variables y funciones compartidas de resultados.
- Conservar compatibilidad con IDs e historial existentes.
- Hacer contextuales los textos de búsqueda, resultados y reproducción.
- Ejecutar `ani-skip` solamente cuando `media_kind=anime`.

### 2. Crear los menús

- Cambiar la entrada principal `Buscar anime` por `Buscar`.
- Crear el estado `media_type_menu`.
- Agregar Anime, Películas, Series, Doramas y Volver al inicio.
- Conectar cada opción con su campo de búsqueda.
- Preservar el comportamiento de Escape y Ctrl-C en fzf, rofi y dmenu.

### 3. Implementar las banderas directas

- Agregar `-t` y `--type` al parser de argumentos.
- Normalizar valores y alias.
- Validar combinaciones incompatibles con `--source`, `--skip` y otras funciones exclusivas de anime.
- Mantener el orden flexible actual de opciones y consulta.
- Documentar ejemplos interactivos y no interactivos.

### 4. Implementar la búsqueda de PelisPlusHD

- Agregar una URL base y referrer independientes.
- Usar un agente de navegador, timeouts y reintentos limitados.
- Consultar `GET /search` con `curl -G --data-urlencode` y el parámetro `s`.
- Separar cada tarjeta antes de extraer slug y título.
- Aceptar solamente rutas `/pelicula/` para películas.
- Aceptar solamente rutas `/serie/` para series y doramas.
- Ignorar siempre los resultados `/anime/` de PelisPlusHD.
- Conservar título y año cuando estén disponibles.

Para doramas, los resultados `/serie/` se validarán consultando en paralelo sus páginas de detalle y comprobando el género `dorama`. Para la opción Series se excluirán esos mismos resultados, evitando duplicados entre categorías.

### 5. Implementar películas

- Resolver la página `/pelicula/<slug>`.
- Extraer las opciones de reproductor disponibles.
- Saltar el menú de episodios.
- Abrir directamente la selección de idioma/fuente o reproducir si sólo existe una opción.
- Usar el título de la película sin el sufijo `Episode 1`.
- Ocultar Siguiente, Anterior, Elegir episodio y Modo continuo durante una película.

### 6. Implementar temporadas y capítulos

- Extraer todas las rutas `/temporada/<n>/capitulo/<n>` de la página de la serie.
- Mantener el orden de temporada y episodio.
- Mostrar etiquetas como `T1 · E8 · <título>`.
- Resolver la URL del capítulo a partir del token `s1e8`.
- Permitir Siguiente, Anterior y reproducción continua entre temporadas.
- Aceptar `-e S1E1` para uso directo.
- Conservar sin cambios los rangos numéricos de anime.

### 7. Resolver Embed69

Soportar los dos formatos observados:

- Series/doramas: la página `/video/<id>/` expone espejos en texto claro.
- Películas: la página `/f/<IMDb ID>/` protege enlaces mediante prueba de trabajo y AES.

Para películas:

1. Extraer challenge, dificultad y salt.
2. Resolver la prueba SHA-256 con un límite de trabajo.
3. Derivar la clave requerida.
4. Decodificar los payloads Base64.
5. Descifrar AES-256-CBC mediante OpenSSL.
6. Agrupar enlaces por `LAT`, `ESP` y `SUB`.

Los resultados descifrados se almacenarán en caché durante la sesión. Si la dificultad supera el límite razonable para una CLI, la fuente fallará de forma controlada.

La secuencia que debe conservarse claramente documentada es:

```text
PelisPlusHD
  -> extraer video[]
  -> abrir Embed69
  -> obtener mirrors por idioma
  -> resolver el host elegido
  -> extraer manifiesto/archivo final
  -> probar un frame con headers y referrer
  -> fallback al siguiente mirror si falla
```

Para películas, Embed69 se resuelve así:

1. Leer `POW_CHALLENGE`, `POW_DIFFICULTY`, `POW_SALT` y `dataLink`.
2. Buscar desde cero el primer nonce cuyo SHA-256 de `challenge + nonce decimal` empiece con la cantidad requerida de ceros.
3. Calcular la clave como los 32 bytes de SHA-256 de `challenge + nonce + salt`.
4. Decodificar cada enlace Base64.
5. Usar los primeros 16 bytes como IV y el resto como ciphertext.
6. Descifrar con AES-256-CBC y padding PKCS#7.
7. Validar que el resultado sea una URL HTTP(S) y agruparlo por `LAT`, `ESP` o `SUB`.

Para series y doramas, el formato observado `/video/<id>/` entrega mirrors en llamadas `playServerVast('<URL>')`; se extraen como texto y se agrupan por idioma sin ejecutar JavaScript remoto.

Para Vidhide:

1. Seguir redirects conservando referrer y cookies de la resolución.
2. Desempaquetar localmente el bloque Dean Edwards P.A.C.K.E.R sin ejecutar el resultado.
3. Extraer el objeto de enlaces usado por `sources`.
4. Elegir `hls4`, después `hls3` y finalmente `hls2`, según disponibilidad.
5. Leer el master HLS, aplicar la calidad solicitada y probar un segmento/frame real.
6. Conservar URL, referrer, headers, idioma, servidor y sitio hasta abrir el reproductor.

Esta explicación y sus fixtures serán suficiente material de referencia para quien implemente la misma extracción en otro proyecto, sin convertir ani-cli-mx en una librería compartida.

### 8. Resolver espejos y fallback

Prioridad inicial:

1. Vidhide y dominios equivalentes.
2. Streamwish y su familia de dominios.
3. Voe y sus redirecciones.
4. Uqload.
5. Doodstream.

Vidhide será el camino imprescindible para la primera versión, por ser el espejo validado con frames reales. Se implementará un desempaquetador determinista para su JavaScript P.A.C.K.E.R.; nunca se ejecutará JavaScript remoto.

Cada enlace conservará sus metadatos:

```text
referrer >URL>VALUE
source >URL>Vidhide
site >URL>PelisPlusHD
```

Un espejo sólo será aceptado después de que mpv decodifique un frame. Un HTTP 200 del manifiesto, una URL de embed sin resolver o el video ficticio de un host no contarán como éxito.

### 9. Selección de idioma

Mostrar solamente los idiomas disponibles:

```text
Idioma
├── Latino
├── Castellano
└── Subtitulado
```

- Seleccionar automáticamente cuando sólo exista uno.
- Preferir Latino inicialmente para películas, series y doramas.
- Recordar la selección durante la sesión del título.
- Mostrar idioma, espejo y sitio en la salida `debug`.
- No mezclar este selector con las suposiciones `dub/sub` de anime.

### 10. Adaptar historial y reproducción

- Mantener legible el formato tabulado existente.
- Usar el ID tipado para distinguir cada categoría.
- Mostrar etiquetas como `[PelisPlusHD · Película]` y `[PelisPlusHD · Dorama]`.
- Guardar el token de capítulo para series y doramas.
- Permitir reabrir una película desde el historial para volver a reproducirla.
- Usar encabezados como `Belleza verdadera · T1 E8`.
- Hacer contextuales Volver a resultados y Buscar otro contenido.

### 11. Agregar pruebas y diagnósticos

Pruebas offline:

- Menú principal y submenú de tipos.
- Navegación hacia atrás en cada nivel.
- Parser de películas, series y doramas con fixtures.
- Exclusión de anime procedente de PelisPlusHD.
- Validación del género dorama.
- Catálogo con varias temporadas.
- Tokens `s1e1`, siguiente/anterior e historial.
- Película sin menú de episodios.
- Agrupación de idiomas.
- Vector conocido de prueba de trabajo y AES.
- Desempaquetado de Vidhide.
- Fallback tras timeout, 403, video ficticio o enlace inválido.
- Propagación de referrer y cabeceras hasta mpv.
- Compatibilidad completa con las pruebas existentes de anime.
- Disponibilidad de OpenSSL en Git Bash/Windows.

Pruebas de red:

- Buscar `Interstellar` como película.
- Buscar `Mythic Quest` como serie.
- Buscar `Belleza verdadera` como dorama.
- Verificar un frame real de una película con mpv.
- Verificar un frame real de una serie o dorama con mpv.
- Confirmar que los segmentos, no sólo el manifiesto, son accesibles.

Los diagnósticos separarán fallos de catálogo, Embed69, cifrado, espejo y segmentos multimedia.

### 12. Documentar, verificar y publicar

Actualizar conjuntamente:

- Ayuda integrada.
- `README.md`.
- `ani-cli-mx.1`.
- `disclaimer.md` y el resumen legal incluido en el README.
- Descripción del proyecto y metadatos de paquetes, incluido `bucket/ani-cli-mx.json`.
- `tests/sanity.sh`.
- Workflow y aserciones de versión de Windows.
- Dependencias y diagnósticos.

Se auditarán todos los textos que actualmente presentan ani-cli-mx exclusivamente como una herramienta para anime. Las descripciones generales y avisos legales deben ampliarse a contenido multimedia, incluyendo anime, películas, series y doramas. Los textos específicos de una función de anime, como proveedores de anime o `ani-skip`, conservarán esa precisión.

El disclaimer completo ya utiliza en gran parte términos generales como contenido y medios externos, pero debe revisarse junto con su versión corta del README para asegurar que:

- No limite el alcance del proyecto solamente a anime.
- Cubra búsqueda, reproducción y descarga de todos los tipos soportados.
- Mantenga claro que el proyecto no aloja contenido.
- Mantenga claro que los proveedores son externos y no afiliados.
- Mantenga el uso sujeto a las leyes y jurisdicción del usuario.
- No prometa legalidad, disponibilidad ni autorización de catálogos externos.

Las pruebas de documentación deben detectar descripciones globales obsoletas como `anime CLI` o `watch anime` en README, manual y manifiestos. No deben fallar por menciones legítimas dentro de secciones dedicadas exclusivamente al flujo de anime.

OpenSSL pasará a ser una dependencia requerida para PelisPlusHD. Se comprobará su disponibilidad en las plataformas soportadas antes de habilitar la fuente.

Verificación final:

```sh
./tests/sanity.sh --syntax
./tests/sanity.sh --network
git diff --check
```

Por tratarse de una ampliación del alcance fundamental de la aplicación, un nuevo modelo de contenido y una nueva interfaz de búsqueda, la versión acordada es `3.0.0`.

## Criterios de aceptación

La implementación estará terminada cuando:

- El menú Buscar permita iniciar los cuatro tipos de búsqueda.
- Las banderas directas funcionen y las consultas ambiguas se rechacen.
- El flujo de anime no presente regresiones.
- Películas, series y doramas no devuelvan anime de PelisPlusHD.
- Una película se reproduzca sin simular un episodio.
- Series y doramas con varias temporadas naveguen correctamente.
- Idioma, espejo, referrer y cabeceras se conserven hasta el reproductor.
- El fallback descarte servidores defectuosos sin seleccionarlos.
- mpv decodifique al menos un frame real de cada flujo requerido.
- La resolución quede explicada junto a sus funciones y cubierta por fixtures, incluyendo PoW, AES, Vidhide, headers y fallback.
- Las descripciones generales y disclaimers representen todo el contenido soportado y conserven las advertencias actuales sobre terceros, copyright, jurisdicción y uso bajo responsabilidad del usuario.
- Las pruebas de sintaxis, red y Windows sean satisfactorias.

## Riesgos conocidos

- PelisPlusHD y Embed69 pueden cambiar dominio o HTML sin aviso.
- El challenge de Embed69 puede aumentar su dificultad.
- Los dominios de los espejos rotan con frecuencia.
- Algunos manifiestos funcionan mientras sus segmentos fallan o responden lentamente.
- El soporte dependerá de extractores propios porque yt-dlp no resolvió los hosts principales durante la investigación.
- La naturaleza y disponibilidad legal del catálogo puede variar según jurisdicción; el proyecto debe considerar ese riesgo antes de distribuir la integración.

## Fuera de alcance inicial

- Usar PelisPlusHD como proveedor de anime.
- Mezclar PelisPlusHD con el fallback automático de anime.
- Incorporar recomendaciones, populares, años o géneros como navegación adicional.
- Ejecutar JavaScript remoto para obtener enlaces.
- Garantizar todos los espejos desde la primera entrega.
- Implementar o publicar la aplicación Android; ese proyecto se atenderá por separado.
