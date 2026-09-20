# Bitácora de diseño — SSTN-Normality-Study

Registro de las decisiones metodológicas tomadas hasta ahora, para no perder contexto entre sesiones de trabajo.

## 1. Punto de partida

Anarat, A. & Schwender, H. (2026). "A Test for Normality Based on Self-Similarity" (arXiv:2604.03810, Mathematical Institute, HHU Düsseldorf; paquete `sstn` en CRAN, actualizado mayo 2026). El SSTN explota que, entre las distribuciones de varianza finita, solo la normal es autosimilar bajo convolución. Estadístico: transforma la función característica empírica estandarizada en iteraciones sucesivas m=1..M, mide discrepancias entre transformaciones consecutivas, estandariza cada una respecto a su nula, y toma el máximo absoluto.

El paper original compara el SSTN contra Shapiro-Wilk, Anderson-Darling, Jarque-Bera, Lilliefors y D'Agostino-Pearson, sobre 8 familias de distribuciones (normal desplazada, Gamma, chi², lognormal, Weibull, t-Student, mezcla de normales, convolución uniforme-normal), n∈{10,25,50,100,250,500}, α=.05, R=1000. SSTN competitivo o superior en casi todos los escenarios; débil solo frente a D'Agostino-Pearson en la convolución uniforme-normal para n≥50. **No hay ninguna aplicación a datos reales en el paper original** — es puramente simulación. Nadie más lo ha extendido todavía (paper de abril 2026).

## 2. Lista final de pruebas (10)

Las 5 del paper original (Shapiro-Wilk, Anderson-Darling, Lilliefors, Jarque-Bera, D'Agostino-Pearson) + 4 de la batería `.al_nortest_battery()`/`.al_norm_core_battery()` de AssumptionsLab que el paper original no usó (Cramér-von Mises, Shapiro-Francia, chi² de Pearson, prueba de curtosis separada) + SSTN = 10.

**Pendiente sin cerrar**: verificar en el código real de AssumptionsLab si lo que se etiqueta "Jarque-Bera/asimetría" (gateado por n≥8, el umbral típico de una prueba de asimetría pura, no el de JB que ya incorpora curtosis) es el estadístico JB genuino o una prueba de asimetría pura mal etiquetada. Si es esto último, hay redundancia conceptual con D'Agostino-Pearson (ambas ómnibus de momentos) que conviene aclarar antes de fijar la lista en el manuscrito.

## 3. Diseño de simulación — tres bloques

**Bloque 1 — réplica directa**: las 8 familias del paper original, mismos parámetros y n, para comparabilidad directa con sus resultados publicados.

**Bloque 2 — extensión platicúrtica**: uniforme pura, familia Beta(a,a) simétrica (a∈{1,2,3,5,10}), y/o familia lambda generalizada de Tukey (paquete `gld`, Ramberg-Schmeiser/FKML) para barrer curtosis negativa de forma continua. Motivo: es el único punto débil claro del SSTN reportado en el paper original.

**Bloque 3 — distribuciones calibradas a datos reales**: para cada subescala real elegida, se calcula asimetría y curtosis muestral (sobre el N completo, como objetivo estable — la asimetría/curtosis son estadísticos de alta varianza, por eso se exige N grande). Se ajusta una distribución sintética (Fleishman o GLD) que reproduzca esos dos momentos, y se generan réplicas independientes a cualquier n. Este bloque es el puente entre la simulación paramétrica pura y la aplicación a datos reales — técnica conocida en la literatura como *simulación plasmode* (ver Schreck et al. 2024, *Statistics in Medicine*, "Statistical plasmode simulations").

### Elección de método de calibración (Fleishman vs. GLD)

No hay un ganador universal documentado — un estudio comparativo directo (Fleishman vs. Ramberg-Schmeiser) encontró precisión prácticamente equivalente entre ambos, con las mismas limitaciones en combinaciones extremas de asimetría+curtosis (ambos empiezan a fallar alrededor de asimetría≈2, curtosis≈6). Por lo tanto:

1. Calcular (asimetría, curtosis) objetivo para cada subescala real elegida (con N completo).
2. Chequear factibilidad de esos puntos bajo Fleishman (`SimMultiCorrData` en R) y bajo GLD (`gld`, ajuste por momentos-L).
3. Si todos los puntos son factibles bajo un solo método, usar ESE método para todas las subescalas — consistencia interna, no mezclar mecanismos generadores.
4. Si ningún método cubre todos los puntos, usar como respaldo uniforme el método de quinto orden de Headrick (2002), que amplía la región factible más allá de ambos.
5. Reportar la tabla de factibilidad completa en el manuscrito (subescala, objetivo, método verificado, parámetros ajustados) — transparencia metodológica.

Dado que el Bloque 2 (platicúrtico) ya usa la familia GLD, si la factibilidad lo permite conviene usar GLD también en el Bloque 3, dejando un solo motor de generación para las dos extensiones propias del estudio (el Bloque 1, de réplica directa, mantiene su propio mecanismo por comparabilidad con el paper original).

## 4. Réplicas Monte Carlo

El paper original usa R=1000. El error estándar de una tasa de rechazo estimada para p≈.05 da un IC95% de aproximadamente [.037,.064] — coincide casi exactamente con la banda de error tipo I que ellos reportan, lo que sugiere que esa banda es sobre todo ruido de Monte Carlo, no una falla real de calibración. Con 10 pruebas a comparar (vs. 5 del original), conviene subir a **R=10.000-20.000** para poder distinguir diferencias finas entre pruebas cercanas en potencia.

**Actualizado tras el piloto real (18 sep 2026, ver sección 10)**: la premisa original de esta sección — que había que cachear la nula del SSTN por separado para no recalibrar en cada réplica — **no aplica**. `sstn::sstn()` calibra internamente en cada llamada (finito para n chico, asintótico para n grande) y aun así tarda 4-9 milisegundos por llamada. R=10.000 réplicas en un solo n toma bajo 1 minuto. No hace falta ninguna capa externa de caché de la nula — se llama `sstn::sstn(x)` directo en cada réplica, igual que cualquier otra prueba de la batería. Esto simplifica bastante el diseño original de esta sección (y de `R/06_sstn_null_calibration.R`, ver sección 10).

## 5. Datasets reales — selección final

Fuente: openpsychometrics.org/_rawdata/ (repositorio real, no paquetes de CRAN). Criterios de selección: N grande (soporta escalera de submuestras más larga + estimación estable de asimetría/curtosis objetivo), constructos genuinamente distintos entre sí, relevancia para People Analytics/RRHH donde sea posible. **Se excluyó deliberadamente cualquier dataset de personalidad tipo Big Five/IPIP** por las dificultades psicométricas conocidas de ese modelo específico (efectos techo por ítem, falta de estructura simple en AFE, falta de invarianza transcultural).

Elegidos (4, archivos ya descargados en `data/raw/`):

- **DASS** (Depression Anxiety Stress Scales) — N=39.775, 42 ítems Likert 1-4, 3 subescalas de 14 ítems c/u (Depresión, Ansiedad, Estrés — claves de corrección estándar DASS-42). Caso de asimetría extrema deliberado (efecto suelo marcado) — el más probable de forzar los límites de factibilidad de Fleishman/GLD.
- **RIASEC** (códigos de Holland) — N=145.828, 48 ítems, 6 subescalas. El de mayor relevancia directa para RRHH (ajuste persona-puesto, orientación vocacional).
- **MACH-IV** (maquiavelismo) — N=73.489, 20 ítems, unidimensional. Ángulo de conducta organizacional contraproducente/liderazgo tóxico.
- **RSE** (autoestima de Rosenberg) — N=47.974, 10 ítems, unidimensional.

Total: 11 subescalas candidatas a evaluar.

## 6. Aplicación a datos reales — diseño de remuestreo

No hay una nula verdadera conocida en datos reales — casi con certeza los puntajes de subescala no son normales. En vez de una sola decisión por dataset (poco informativo), se usa un diseño de **submuestreo repetido tipo "m-out-of-N"**: para cada subescala, se extraen muchas submuestras aleatorias a distintos tamaños n, y se calcula la tasa de rechazo empírica por prueba y por n, usando el N completo como referencia poblacional. Esto no es potencia clásica contra una alternativa paramétrica conocida — es tasa de detección relativa a la distribución empírica real. Encuadrar así explícitamente en el manuscrito.

**Escalera de n**: múltiplos del criterio de Nunnally (1978, *Psychometric Theory*, 2ª ed.) de 10 observaciones por ítem — 1×, 2×, 5×, 10×... el mínimo por instrumento — más algunos puntos por debajo del mínimo (n=10, 20, 30) como contraste con el régimen de n pequeño donde el SSTN mostró más ventaja en la simulación original. Nota para el manuscrito: el criterio de Nunnally tiene una crítica metodológica bien establecida (MacCallum, Widaman, Zhang & Hong, 1999, *Psychological Methods*) — presentarlo como "tamaño de muestra ecológicamente representativo de la práctica psicométrica", no como óptimo estadístico.

No todas las subescalas son igual de informativas: las de efecto suelo/techo fuerte (DASS) probablemente hacen que las 10 pruebas rechacen casi al 100% desde n pequeño (útil para ilustrar consenso, no para discriminar entre pruebas); las subescalas con más ítems y menos asimetría (ej. RIASEC, con 6 subescalas de forma más variada) son donde más se espera desacuerdo entre pruebas.

## 7. Infraestructura de cómputo

Se descartó correr todo localmente por el volumen del diseño factorial (10 pruebas × ~3 bloques de distribuciones × 6 n × R=10.000+, más el remuestreo real). Plan: GitHub Actions con `strategy: matrix` para paralelizar por celda del diseño (familia×n, o dataset×subescala), cada job escribiendo su resultado como artifact CSV. Antes de comprometer el diseño completo, correr un piloto pequeño (100-200 réplicas de una celda) para medir tiempo real por réplica y dimensionar el matrix (límite de 6h por job en runners estándar de GitHub-hosted).

Paso compartido: calibrar y cachear la nula del SSTN por n como job/artifact previo, para que los jobs del matrix no la recalculen cada uno.

Caché de dependencias de R vía `r-lib/actions/setup-r-dependencies` (o `renv`) para no reinstalar paquetes en cada job del matrix.

**Decidido**: repo público en GitHub — minutos de Actions ilimitados en runners estándar, y se declarará vinculado al artículo (mencionado en la sección de disponibilidad de datos/código del manuscrito para AJS) como repositorio de reproducibilidad.

## 8. Journal objetivo

Austrian Journal of Statistics — mismo journal que el artículo de AssumptionsLab ya en marcha, mismo flujo de trabajo en Overleaf/LaTeX cuando llegue el momento de redactar.

## 10. Resultados del piloto real en GitHub Actions (18 sep 2026)

Corrido vía `R/00b_pilot_sstn_timing.R` como job `pilot-timing` del workflow (repo público, runners `ubuntu-latest`, R 4.6.1, instalación con `r-lib/actions/setup-r-dependencies@v2`). Log completo: artifact `pilot-sstn-timing` de la corrida 35363053764.

- **API real**: el paquete `sstn` (v1.0.2) exporta un único objeto, `sstn::sstn(x, verbose = TRUE)` — no `sstn.test()` como se asumió al escribir los scripts iniciales. No hay parámetros expuestos para M/T/β (el paper los describe, pero el paquete los maneja internamente con valores fijos — no configurables desde la interfaz pública).
- **Salida**: lista con `$method` (string, indica si usó calibración de muestra finita o aproximación asintótica — el corte observado está en algún punto entre n=50 y n=100), `$test.statistic`, `$p.value`.
- **Sanity check**: con n=50 datos normales, p=.897 (no rechaza, correcto); con n=50 datos exponenciales, estadístico=24.34, p≈0 (rechaza con fuerza, correcto).
- **Tiempos reales** (promedio de 5 corridas por n, datos normales): n=10→3.8ms, 25→4.0ms, 50→4.2ms, 100→4.0ms, 250→4.6ms, 500→5.4ms. Prácticamente plano en n — nada de la explosión de costo que se anticipaba.
- **Proyección a R=10.000 réplicas por celda**: 0.6 a 0.9 minutos según n. Para todo el Bloque 1 (48 configuraciones × 6 n × R=10.000, solo el componente SSTN) esto da un estimado de horas, no días — perfectamente viable en un solo job de GitHub Actions sin necesitar el matrix tan agresivo que se había anticipado (el matrix sigue siendo buena idea para paralelizar y acotar el tiempo de espera, pero ya no es estrictamente necesario para que quepa en el límite de 6h por job).
- **Consecuencia directa sobre el diseño**: `R/06_sstn_null_calibration.R` y el job `calibrate-null` del workflow quedan obsoletos tal como se concibieron — no hace falta cachear nada, `sstn::sstn(x)` se llama directo en cada réplica dentro de `08_run_battery.R`. Se deja el archivo con una nota explicando esto en vez de borrarlo, por si en el futuro se necesita optimizar más.

## 11. Extracción de subescalas reales (18 sep 2026)

Implementado `R/03_extract_real_subscales.R`. Confirmado el separador real de los 4 `data.csv` (dentro de cada zip): **TAB**, pese a la extensión `.csv`.

**Claves de puntuación confirmadas** (además de la clave DASS-42 ya documentada en la sección 5):

- **RIASEC**: columnas `R1-R8, I1-I8, A1-A8, S1-S8, E1-E8, C1-C8`, Likert 1-5, sin ítems inversos (confirmado en `codebook.txt`) — suma directa de los 8 ítems por dimensión.
- **MACH-IV**: columnas `Q1A..Q20A`, Likert 1-5. Ítems inversos = {3,4,6,7,9,10,11,14,16,17} — confirmado vía [checkpsych.com/tests/mach-iv](https://www.checkpsych.com/tests/mach-iv/), que publica explícitamente la lista de ítems a invertir, y cruzado manualmente contra el contenido/dirección de cada ítem (los que expresan confianza/idealismo — ítems 3,4,6,7,9,10,11,14,16, y el 17 por su doble negación sobre Barnum — se invierten; los que expresan cinismo/manipulación directa quedan tal cual). Puntaje total = suma de los 20 ítems (invertidos donde corresponde) — escala unidimensional, sin subescalas separadas.
- **RSE**: columnas `Q1-Q10`, Likert 1-4 (0 = no contestó, tratado como faltante). Ítems inversos = {3,5,8,9,10} — clave estándar de Rosenberg (1965), confirmada vía [socy.umd.edu — Using the Rosenberg Self-Esteem Scale](https://socy.umd.edu/about-us/using-rosenberg-self-esteem-scale). Puntaje total = suma de los 10 ítems (invertidos donde corresponde).

Regla general de limpieza: por cada subescala, un caso solo entra al puntaje total si TODOS sus ítems de esa subescala están en rango Likert válido (fuera de rango, vacío o `"NULL"` → faltante) — no se promedia con datos parciales, para no distorsionar artificialmente la forma de la distribución del puntaje total.

Salida: 11 archivos en `data/processed/` (uno por subescala, gitignoreados — se regeneran corriendo el script), vía el job `extract-subscales` del workflow.

**Primer intento falló** (corrida 35365830807): `Error in close.connection(con) : invalid connection`. Causa: `readr::read_tsv()` ya cierra la conexión que se le pasa después de leerla — el `on.exit(close(con))` en `read_zip_csv()` intentaba cerrarla una segunda vez. Corregido quitando ese `close()` explícito.

**Chequeo exploratorio (no oficial — solo para validar la lógica de extracción antes de comprometerla a R/GitHub, hecho en Python fuera del pipeline)**: los 11 puntajes tienen Ns entre ~39.700 y ~144.200, rangos y mín/máx exactamente los esperados por conteo de ítems × rango Likert (ninguna subescala se sale del rango teórico, lo que confirma que la lógica de reversión/filtrado es correcta). Dato interesante para el Bloque 2: varias subescalas reales ya muestran curtosis en exceso negativa apreciable de forma natural (ej. DASS-Depresión, RIASEC-Investigative/Artistic, todas entre -0.6 y -1.2) — refuerza la relevancia de incluir distribuciones platicúrticas en la simulación, más allá de ser solo el punto débil reportado del SSTN en el paper original. Los valores oficiales (asimetría/curtosis con N completo, para calibración plasmode) se calculan en R dentro de `R/04_moments_and_feasibility.R` — pendiente.

## 12. Piloto de factibilidad Fleishman/GLD — primer intento fallido y hallazgos (18 sep 2026)

Corrido vía `R/04b_pilot_feasibility.R` como job `feasibility-pilot` (depende de `extract-subscales`, descarga su artifact `real-subscales-processed`). Log completo del intento fallido: corrida 35368898567 (`gh run view 35368898567 --log-failed`).

**Lo que sí funcionó**: las 11 subescalas se leyeron correctamente y se imprimió la tabla de objetivos (asimetría, curtosis en exceso) con N completo por subescala — confirma que `R/03_extract_real_subscales.R` y su artifact están sanos de punta a punta.

**Hallazgo sustantivo — Fleishman infeasible para las 11 subescalas**: `SimMultiCorrData::find_constants(method="Fleishman", ...)` devolvió `valid=FALSE` para las 11 subescalas reales, cada una con un warning de R ("No valid power method constants could be found..."). Consistente con que las 11 tienen curtosis en exceso negativa (rango aproximado -0.15 a -1.15, ver sección 11) combinada con asimetría no nula — cae fuera de la región factible de Fleishman de 3er orden. Esto refuerza directamente la motivación del Bloque 2 (platicúrtico) del diseño: no es solo el punto débil reportado del SSTN en el paper original, sino también una limitación real y documentada del método de calibración plasmode más simple frente a datos psicométricos reales.

**Bug encontrado — `find_constants()` puede devolver un vector atómico en vez de una lista**: en la primera llamada con `method="Polynomial"` (subescala `dass_anxiety.csv`), el script crasheó con `Error in res$valid : $ operator is invalid for atomic vectors`, invocado desde `isTRUE(res$valid)`, precedido por un warning de "no se encontraron constantes válidas" igual al de Fleishman. Es decir: cuando `find_constants()` falla por completo (no encuentra ni siquiera una solución inválida que reportar como lista), devuelve un vector atómico suelto en lugar de la lista habitual con `$constants`/`$valid` — el resumen de documentación de rdrr.io consultado antes de escribir el piloto no mencionaba este caso (solo describía retornos NULL o lista en fallo), así que el hallazgo es puramente empírico, vía el job real.

**Corrección aplicada**: se agregó un helper `get_valid(res)` en `R/04b_pilot_feasibility.R` que primero chequea `is.list(res)` antes de tocar `$valid`, y que además cubre el caso ya conocido de que `$valid` puede venir como string `"TRUE"`/`"FALSE"` en vez de lógico. Los dos sitios de llamada (bucle Fleishman y bucle Polynomial) se cambiaron de `isTRUE(res$valid)` a `get_valid(res)`. Pendiente: volver a correr el job con la corrección para ver (a) si el método Polynomial (5to orden, Headrick) sí es factible para las 11 subescalas una vez que no crashea, y (b) si `gld::fit.fkml()` converge sobre las submuestras de datos reales (esta sección del piloto nunca se alcanzó por el crash).

## 13. Nota para la introducción/motivación del manuscrito (18 sep 2026)

La infactibilidad de Fleishman de 3er orden para las 11/11 subescalas reales (sección 12) es más que un detalle técnico de calibración — es un argumento de motivación para el diseño de tres bloques del estudio. La literatura de simulación Monte Carlo sobre pruebas de normalidad suele usar familias paramétricas "de libro" (Gamma, lognormal, mezclas de normales, etc.) que caen cómodamente dentro de la región factible de Fleishman. Los datos psicométricos reales evaluados aquí —constructos con efectos suelo/techo, escalas Likert acotadas, ítems no simétricos— caen sistemáticamente en curtosis negativa combinada con asimetría no nula, la combinación que Fleishman de 3er orden no puede reproducir.

Esto sugiere encuadrar el Bloque 2 (platicúrtico) no solo como respuesta al punto débil reportado del SSTN en el paper original (Anarat & Schwender 2026), sino como el régimen donde realmente viven los constructos psicológicos reales — y el Bloque 3 (plasmode, con las 11 subescalas) lo confirma empíricamente. Argumento a usar en la introducción/motivación del manuscrito para justificar por qué un diseño de solo réplica + alternativas paramétricas clásicas sería insuficiente para evaluar la utilidad práctica del SSTN en aplicaciones de RRHH/psicometría.

## 14. Resultados definitivos del piloto de factibilidad y decisión de método (18 sep 2026)

Corrida exitosa: `R/04b_pilot_feasibility.R` corrió sin errores tras la corrección de la sección 12 (corrida 35373706154, artifact `feasibility-pilot-log`). Resultados completos para las 11 subescalas:

- **Fleishman (3er orden)**: `valid=FALSE` para las 11/11 — confirmado (ya reportado en la sección 12).
- **Polynomial (Headrick, 5to orden, `fifths=0, sixths=0`)**: **también `valid=FALSE` para las 11/11**. Esto contradice la expectativa original del diseño (sección 3, punto 4: "usar como respaldo uniforme el método de Headrick, que amplía la región factible más allá de ambos"). La razón: los grados de libertad extra de Headrick que amplían la región factible son precisamente los cumulantes estandarizados de 5to/6to orden (`fifths`/`sixths`) — al fijarlos en 0 (única opción defendible, ya que no hay un objetivo real confiable para esos momentos, demasiado ruidosos de estimar con precisión incluso con N grande), el método Polynomial pierde exactamente la flexibilidad adicional que necesitaría para llegar a esta región de curtosis negativa. En la práctica, con `fifths=sixths=0`, Polynomial no ofrece ninguna ventaja sobre Fleishman para estos 11 objetivos.
- **GLD (`gld::fit.fkml(x, method="ML")`, ajuste sobre submuestra n=2000)**: **convergió para las 11/11**, con tiempos de 0.67-1.76s por subescala.

**Decisión de método (reemplaza el punto 4 de la sección 3)**: dado que ni Fleishman ni Polynomial (con `fifths=sixths=0`) son factibles para ninguna de las 11 subescalas, **GLD es el único método viable** — no hace falta decidir entre "un método único" vs. "mezcla", ya que GLD cubre el 100% de los casos por sí solo. Esto además deja un único motor generador para el Bloque 2 (platicúrtico) y el Bloque 3 (plasmode), como ya se anticipaba como preferible al final de la sección 3.

**Ajuste al pasar a producción**: la versión final `R/04_moments_and_feasibility.R` ajusta GLD sobre el **N completo** de cada subescala (no la submuestra de n=2000 usada en el piloto solo por velocidad), porque es un paso de calibración único por subescala (11 ajustes en total, no uno por réplica Monte Carlo) — la fidelidad adicional vale el costo computacional, y el tiempo real a N completo se confirma corriendo el script en el job `moments-and-feasibility` (no se pilotea aparte: la API y el comportamiento de `fit.fkml()` ya están confirmados empíricamente, solo falta ver el tiempo a escala real).

**Confirmado en producción (corrida 35375789088, job `moments-and-feasibility`, 23m40s total)**: las 11/11 convergieron a N completo (39.775 a 144.233 casos según subescala). Tiempo de ajuste GLD por subescala: entre 7.2s (`dass_depression`, n=39.775) y 221.3s (`riasec_investigative`, n=144.233) — suma total ≈17 minutos de los 23m40s del job (el resto, ~5-6 min, es la instalación de paquetes de R, igual que en los demás jobs). El tiempo NO escala de forma simple con N ni con la magnitud de la curtosis objetivo — p. ej. `dass_depression` (curtosis en exceso más extrema del set, -1.1549) fue el ajuste más rápido de todos (7.2s), mientras que `riasec_investigative` y `riasec_realistic`, con N casi idéntico, difieren en más del doble de tiempo (221.3s vs. 131.7s) — aparenta ser una cuestión de cuántas iteraciones necesita el optimizador de `fit.fkml()` para converger desde sus valores iniciales, no del tamaño de muestra en sí. En cualquier caso, el total (~23 min) es perfectamente viable como un job único de GitHub Actions, muy por debajo del límite de 6h.

Salida final guardada: `data/processed/plasmode_calibration.csv` — una fila por subescala con `n`, `asimetria`, `curtosis_exceso`, `fleishman_valid`, `polynomial_valid`, `gld_convergio`, `lambda1..lambda4` (parámetros FKML ajustados) y `segundos_gld`. Esta tabla es el insumo directo de `R/05_calibration_plasmode.R` (generación de réplicas sintéticas vía `gld::rgl()` a cualquier n) y la tabla de transparencia metodológica del manuscrito.

## 15. API de `gld::rgl()` confirmada + generador plasmode (18 sep 2026)

Antes de escribir `R/05_calibration_plasmode.R` se confirmó la firma real de `gld::rgl()` contra la documentación de CRAN (`search.r-project.org/CRAN/refmans/gld`) y el código fuente del paquete (`github.com/cran/gld`), no por memoria:

```r
rgl(n, lambda1 = 0, lambda2 = NULL, lambda3 = NULL, lambda4 = NULL,
    param = "fkml", lambda5 = NULL)
```

- `param = "fkml"` es el valor por defecto y es la **misma parametrización** que usa `gld::fit.fkml()` (Freimer-Mudholkar-Kollia-Lin) — no hace falta traducir entre parametrizaciones distintas de la GLD.
- `lambda1` puede pasarse como escalar (con `lambda2/3/4` sueltos) **o como un vector de longitud 4** con los 4 parámetros juntos — confirmado en `.gl.parameter.tidy()` (detecta `length(lambda1) > 1` y lo pasa tal cual a `gl.check.lambda()`, que indexa `lambda[1..4]`). Se usa esta forma vectorizada: `gld::rgl(n, lambda1 = c(l1,l2,l3,l4), param = "fkml")`.

Implementado `R/05_calibration_plasmode.R`: función `generar_plasmode(archivo, n)` (usa la tabla `data/processed/plasmode_calibration.csv`) + un sanity check que genera una réplica de n=5000 por cada una de las 11 subescalas y compara asimetría/curtosis empírica contra el objetivo real — corre en el job `plasmode-sanity-check` del workflow (depende de `moments-and-feasibility`).

**Nota sobre artifacts con múltiples paths sin ancestro común**: el artifact `plasmode-calibration` (subido con `data/processed/plasmode_calibration.csv` Y `notes/moments_and_feasibility.txt` juntos) preserva el prefijo completo de cada archivo desde la raíz del repo al no tener un directorio ancestro común — confirmado porque el usuario lo bajó con `gh run download` sin `--path` y el archivo apareció en `<destino>/notes/moments_and_feasibility.txt`. Por eso el job `plasmode-sanity-check` lo descarga a la raíz del workspace (`path: .`) en vez de a `data/processed`, para no anidarlo dos veces.

## 16. Bug de calibración: `method="ML"` no reproduce los momentos objetivo — cambio a `method="Mom"` (18 sep 2026)

El sanity check de `R/05_calibration_plasmode.R` (corrida 35380154662, job `plasmode-sanity-check`) generó una réplica de n=5000 por subescala con los parámetros GLD ajustados en la sección 15 (`fit.fkml(x, method="ML")`) y comparó su asimetría/curtosis empírica contra el objetivo real. Las diferencias fueron demasiado grandes para ser solo ruido de muestreo — hasta 0.42 en curtosis en exceso (`riasec_realistic.csv`: objetivo -0.1463, réplica +0.2763) y hasta 0.23 en asimetría (`riasec_artistic.csv`).

**Causa**: `gld::fit.fkml(x, method="ML")` ajusta por máxima verosimilitud directo sobre el vector de datos crudo — no está diseñado para que la distribución ajustada reproduzca exactamente la asimetría/curtosis muestral, solo maximiza la verosimilitud del conjunto de datos completo. Confirmado contra la documentación real de `fit.fkml()` (`search.r-project.org/CRAN/refmans/gld/html/fit.fkml.html`): el argumento `method` acepta, entre otros, `"ML"`, `"Mom"`, `"Lmom"`, `"TL"`, `"MSP"`, `"TM"`, `"SM"`, `"DLA"`. La descripción de `"Mom"` ("method of Moments"): *"chooses the values of the parameters that minimise the (sum of the squared) difference between the first four sample moments of the data and the first four moments of the fitted distribution"* — esto es exactamente el objetivo de calibración declarado en la sección 3 del diseño ("se ajusta una distribución sintética que reproduzca esos dos momentos"), a diferencia de `"ML"`.

**Corrección**: `R/04_moments_and_feasibility.R` ahora usa `gld::fit.fkml(x, method="Mom")`, con `method="ML"` como respaldo automático solo si `"Mom"` no converge para alguna subescala (columna nueva `gld_metodo` en `plasmode_calibration.csv`, para dejar constancia en la tabla de transparencia del manuscrito de qué método se usó en cada caso). Pendiente: re-correr `moments-and-feasibility` con la corrección y volver a correr `plasmode-sanity-check` para confirmar que las diferencias objetivo-réplica bajan a un rango consistente con ruido de muestreo puro (referencia aproximada bajo normalidad, n=5000: EE(asimetría)≈√(6/n)≈0.035, EE(curtosis en exceso)≈√(24/n)≈0.069 — para distribuciones no normales la varianza real de estos estimadores suele ser mayor, pero sirve de orden de magnitud).

Esto es un hallazgo metodológico útil por derecho propio: confirma la importancia de validar con un sanity check numérico (no solo con "convergió sin error") antes de dar por buena una calibración — vale la pena mencionarlo en la sección de métodos del manuscrito como control de calidad del proceso de simulación plasmode.

**Confirmado tras la corrección (corrida 35385335301)**: las 11/11 subescalas convergieron con `method="Mom"` sin necesitar el respaldo `"ML"`. Dos mejoras simultáneas:

- **Precisión**: las diferencias objetivo-réplica (n=5000, una sola réplica por subescala) bajaron a un rango de -0.032 a +0.038 en asimetría y -0.031 a +0.058 en curtosis en exceso — consistente con el orden de magnitud esperado por puro ruido de muestreo a ese n (EE aprox. 0.035 y 0.069 respectivamente bajo normalidad). Compárese con las diferencias de hasta 0.42 con `method="ML"`.
- **Velocidad**: el ajuste por subescala pasó de 7-221 segundos (`"ML"`) a **5-12 milisegundos** (`"Mom"`) — el job `moments-and-feasibility` completo bajó de 23m40s a 6m17s (el tiempo restante es casi todo instalación de paquetes, igual que los demás jobs).

Con esto, el Bloque 3 (calibración plasmode) queda completamente cerrado y validado: los 11 objetivos reales tienen su GLD ajustada, el generador `generar_plasmode()` está confirmado empíricamente, y `data/processed/plasmode_calibration.csv` es la tabla final de transparencia metodológica para el manuscrito.

## 17. Especificación del Bloque 1 confirmada contra el paper original (19 sep 2026)

Antes de escribir `R/01_simulation_classical.R` se confirmó la Tabla 1 (setup de simulación) del paper original directamente desde `arxiv.org/html/2604.03810` (versión HTML de arXiv, texto real, no de memoria) — verificado con dos fetches independientes que devolvieron el mismo contenido verbatim:

| Familia | Parametrización | Valores del parámetro |
|---|---|---|
| Normal desplazada | N(a−3, 9/a²) | a ∈ {1,2,3,4,5,6} |
| Gamma | Γ(θ,1) | θ ∈ {1,4,6,8,10,12} |
| Chi-cuadrado | χ²ₘ | m ∈ {3,6,9,12,15,18} |
| Lognormal | Lognormal(0, (7/6−d)²) | d ∈ {1/6,2/6,3/6,4/6,5/6,1} |
| Weibull | Weibull(k,1) | k ∈ {0.5,1,1.5,2,2.5,3} |
| t de Student | t_ν | ν ∈ {1,2,3,4,5,6} |
| Mezcla de normales | 0.6·N(−1,1) + 0.4·N(4−b,2) | b ∈ {0,1,2,3,4,5} |
| Convolución uniforme-normal | U(−3,3) * N(0,σ²) | σ ∈ {0,0.2,0.4,0.6,0.8,1} |

n ∈ {10,25,50,100,250,500} (6 valores), R=1.000 réplicas en el original (aquí R=10.000, ver sección 4), α=.05. Total: 6 parámetros × 6 n = 36 celdas por familia, 288 celdas en total.

Nota sobre la familia "normal desplazada": al ser realmente normal para cualquier a (solo cambian media y varianza, y las 10 pruebas de la batería son invariantes a locación-escala), esta familia mide en la práctica el **error Tipo I** de cada prueba bajo H0 verdadera, no potencia — los distintos valores de `a` sirven como chequeo de estabilidad numérica, no como variación real de la forma de la distribución.

Implementado `R/01_simulation_classical.R`: recibe `<familia>` y `[R]` por línea de comandos (pensado para ser un shard del futuro job matrix `simulate-classical`, una familia por shard), genera las 36 celdas de esa familia, corre `run_battery()` (R/08_run_battery.R) sobre cada réplica, y guarda tasa de rechazo por prueba y celda en `data/results/bloque1_<familia>.csv` (con columna `segundos` por celda, para poder dimensionar el matrix real).

**Antes de comprometer R=10.000 en las 8 familias**, se agrega el job `classical-timing-pilot` (matrix de 8 shards, uno por familia, R=200 cada uno, sin dependencias de otros jobs) para medir el tiempo real de la batería completa (no solo SSTN, que ya se midió en la sección 10) a través de las 8 familias y los 6 n — y así decidir la granularidad final del matrix (¿un shard por familia alcanza dentro de las 6h de GitHub Actions, o hace falta partir también por n?).

## 18. Nota metodológica para la discusión del manuscrito: naturaleza ordinal de los puntajes sumados (19 sep 2026)

Los 11 puntajes de subescala reales (DASS, RIASEC, MACH-IV, RSE) son sumas de ítems Likert (ordinales) — no mediciones continuas genuinas. Sumar (o promediar) ítems ordinales para constituir un puntaje único que representa el "nivel" de presencia de un constructo es una práctica extendida y aceptada en psicología y ciencias sociales, pero no es estrictamente coherente desde el punto de vista matemático: la estructura de varianza de una variable ordinal (con categorías discretas, típicamente equidistantes solo por supuesto, no por medición) no se traduce de forma simple a la varianza de un puntaje sumado/promediado — la relación entre la "forma" de las distribuciones de los ítems individuales y la forma de la distribución del puntaje compuesto no es trivial ni completamente comprendida en términos generales.

Esto es relevante para este estudio en dos sentidos:

1. **Interpretación de la asimetría/curtosis objetivo del Bloque 3**: los momentos que se calibran (sección 14) son los del puntaje sumado, no de una variable latente continua subyacente — es una limitación compartida con toda la práctica psicométrica que usa puntajes totales/promedio (y con el mismo paper original de SSTN, que tampoco aplica a datos reales). Vale la pena mencionarlo explícitamente en la discusión, no como defecto del diseño sino como encuadre honesto del alcance de la "aplicación a datos reales": se está evaluando normalidad de puntajes compuestos tal como se usan en la práctica, no de constructos latentes.
2. **Consistencia interna del estudio**: las 11 subescalas fueron tratadas exactamente de la misma manera (suma directa de ítems, con reversión donde corresponde, exigiendo caso completo — ver sección 11) — no hay inconsistencia metodológica entre subescalas que pudiera confundir comparaciones entre ellas.

Punto a desarrollar en la sección de discusión/limitaciones del manuscrito, citando la literatura relevante sobre el tratamiento de datos ordinales como intervalares en psicometría aplicada (debate clásico, sin resolución consensuada) al momento de redactar esa sección.

## 19. Corrección de un bug silencioso en D'Agostino-Pearson (19 sep 2026)

`R/08_run_battery.R` extraía el p-valor omnibus con `dt@test$p.value["Omnibus"]`, pero `fBasics::dagoTest()` nombra ese elemento `"Omnibus  Test"` (con DOS espacios) — confirmado contra el código fuente real del paquete. Indexar por un nombre que no existe devuelve `NA` sin error ni warning en R, así que esto no aparecía en ningún log. Corregido a `pv[grepl("^Omnibus", names(pv))]`, más robusto que depender de un conteo exacto de espacios.

Los ensayos usados de acá en adelante para dimensionar el Bloque 1 (tiempos, matrix, etc.) son todos posteriores a esta corrección — ver sección siguiente.

## 20. Limitaciones de rango válido de n por prueba (documentado para justificar NA)

De las 10 pruebas de la batería, la única con restricción explícita de tamaño de muestra que se manifiesta en el grid del Bloque 1 (n∈{10,25,50,100,250,500}) es D'Agostino-Pearson: `fBasics::dagoTest()` exige internamente n≥20 (`.omnibus.test()`: `if (n < 20) stop("sample size must be at least 20")` — confirmado contra el código fuente real del paquete). Por eso `dagostino_pearson` es NA en las 48 celdas con n=10 (8 familias × 6 parámetros); las otras 9 pruebas producen resultado en esa celda — confirmado empíricamente en la corrida limpia (35430523246), donde ninguna otra columna de la batería mostró NA en ningún valor de n. Se maneja vía `safe_p()` en `run_battery()`, igual que cualquier otra prueba fuera de su rango válido.

## 21. Estimación de tiempos y planificación del Bloque 1 completo (19 sep 2026)

Con los datos limpios del job `classical-timing-pilot` (corrida 35430523246, R=200, 288 celdas = 8 familias × 36 celdas), se calculó el tiempo real de cómputo por familia a partir de la columna `segundos` de cada CSV, y se extrapoló linealmente a R=10.000 (tiempo ∝ R, confirmado por la columna `segundos` de cada celda individual, que ya escala con n dentro de cada familia sin comportamiento anómalo):

| familia | ms/réplica | min estimados a R=10.000 |
|---|---|---|
| mezcla_normal | 3.14 | 18.8 |
| chi2 | 3.71 | 22.3 |
| weibull | 5.10 | 30.6 |
| t_student | 5.33 | 32.0 |
| normal_desplazada | 5.34 | 32.1 |
| lognormal | 5.36 | 32.2 |
| convolucion_uniforme_normal | 5.27 | 31.6 |
| gamma | 5.42 | 32.5 |

Todas las familias caen entre 19 y 33 minutos de cómputo puro por familia a R=10.000 — muy por debajo del límite de 6h por job de GitHub Actions (ubuntu-latest). **Decisión de planificación**: el job final `simulate-classical` usa un matrix de 8 shards (uno por familia, igual que el piloto `classical-timing-pilot`), cada uno corriendo `Rscript R/01_simulation_classical.R <familia> 10000` — no hace falta partir además por n, ya que ni la familia más lenta (gamma, ~32.5 min) se acerca al límite. El tiempo de pared total del workflow queda determinado por el resto de la cadena de dependencias (`extract-subscales` → `moments-and-feasibility` → `plasmode-sanity-check`, que corren en serie por depender unas de otras — ver sección 7), no por este matrix, que corre en paralelo con esa cadena.

## 22. Bloque 1 cerrado — corrida final R=10.000 (19 sep 2026)

Corrida 35431776551, job `simulate-classical`, 8/8 shards exitosos, 288 celdas totales (36 por familia). Tiempos reales de pared por shard: entre 22m51s (gamma) y 39m40s (lognormal) — algo por encima del estimado de la sección 21, pero muy lejos del límite de 6h.

Patrón de NA validado programáticamente sobre las 288 filas: `dagostino_pearson` es NA en exactamente las 48 celdas con n=10 (ver sección 20), como se esperaba. **Único hallazgo adicional**: la celda `mezcla_normal` (b=0, n=250) tiene un NA aislado en `curtosis` (`moments::anscombe.test()`) — 1 de 10.000 réplicas. No se repite en ninguna otra de las 288 celdas. Es ruido numérico esperable de una prueba iterativa sobre ~2,88 millones de evaluaciones totales de la batería (no hay un `stop()` de tamaño mínimo documentado para `anscombe.test()` como sí lo hay para `dagoTest()` — parece ser un caso puntual donde una réplica generada produjo un valor de curtosis muestral en el borde de la transformación interna de la prueba). No afecta la tasa de rechazo reportada (`colMeans(..., na.rm=TRUE)` ya lo maneja) y no requiere ninguna corrección de código.

**Bloque 1 (réplica directa) queda cerrado**: `data/results/bloque1_<familia>.csv` (8 archivos, artifacts `classical-final-<familia>` de la corrida 35431776551) son los datos finales para el manuscrito.

## 23. Diseño cerrado del Bloque 2 — extensión platicúrtica (19 sep 2026)

La sección 3 dejaba abierto si usar "uniforme pura, Beta(a,a) simétrica, y/o GLD". Decisión final:

**Familia única: Beta(a,a) simétrica**, a∈{0.5,1,2,3,5,10} (6 valores, mismo tamaño de grid que el Bloque 1). Asimetría=0 para cualquier a; curtosis en exceso = −6/(2a+3), barrido continuo:

| a | curtosis exceso |
|---|---|
| 0.5 | ≈ −1.5 (arcoseno, forma de U) |
| 1 | ≈ −1.2 (uniforme pura — Beta(1,1)=Uniforme(0,1), por eso no se lista aparte) |
| 2 | ≈ −0.857 |
| 3 | ≈ −0.667 |
| 5 | ≈ −0.462 |
| 10 | ≈ −0.261 (cerca de la normal) |

**No se usa GLD en este bloque** — queda reservado para el Bloque 3 (calibración a datos reales), un solo motor generador por bloque propio, sin mezclar mecanismos sin necesidad.

n∈{10,25,50,100,250,500}, R=10.000 — mismo grid que el Bloque 1, para comparabilidad directa entre bloques.

Implementado `R/02_simulation_platykurtic.R` — mismo patrón que `01_simulation_classical.R` (`<familia> [R]` por línea de comandos, `run_battery()`, `data/results/bloque2_<familia>.csv`). Una sola familia (no 8 como el Bloque 1), así que no hace falta matrix. Antes de comprometer R=10.000, job `platykurtic-timing-pilot` (R=200) para medir tiempo real y confirmar que a=0.5 (la forma más alejada de lo visto en el Bloque 1) no genera problemas numéricos en ninguna de las 10 pruebas.

## 9. Pendientes abiertos

- [x] `git init` + primer commit.
- [x] Decidir repo público vs. privado en GitHub — público, declarado en el artículo como repositorio de reproducibilidad.
- [x] Crear el repo en GitHub y configurar el remoto — `github.com/ArchieJamDev/SSTN-Normality-Study`.
- [x] Piloto de tiempo de cómputo del SSTN vía GitHub Actions — ver sección 10. `R/06_sstn_null_calibration.R` resultó innecesario.
- [x] Implementar `R/08_run_battery.R` de verdad con las 9 pruebas clásicas (nortest/moments/tseries/fBasics) + `sstn::sstn()` — confirmado sin errores vía el job `battery-sanity-check` (corrida 35364083008, éxito).
- [ ] Verificar JB/asimetría vs. D'Agostino-Pearson en código de AssumptionsLab (posible redundancia) — no bloquea este proyecto: aquí cada una de las 9 pruebas clásicas usa su propia función canónica de R, sin ambigüedad (ver sección 10 del código de `08_run_battery.R`).
- [x] Extraer y limpiar los puntajes de subescala (`data/processed/`) — ver sección 11. Claves de corrección confirmadas para las 4 bases (DASS, RIASEC, MACH-IV, RSE).
- [ ] Calcular asimetría/curtosis oficial (en R) de las 11 subescalas con N completo — `R/04_moments_and_feasibility.R`, pendiente de implementar. Chequeo exploratorio en Python ya hecho (sección 11) solo para validar la lógica de extracción.
- [x] Chequeo de factibilidad Fleishman/GLD sobre esos 11 puntos objetivo; decidir método único. Ver secciones 12 y 14: **Fleishman y Polynomial (fifths=sixths=0) infactibles para las 11/11 subescalas; GLD (`fit.fkml`, ML) converge para las 11/11** — método único decidido: GLD.
- [x] Escribir y correr la versión final `R/04_moments_and_feasibility.R` (ajusta GLD sobre N completo) y el job `moments-and-feasibility` — corrido con éxito (corrida 35375789088), 11/11 convergen, ~23 min de job, ver sección 14. `data/processed/plasmode_calibration.csv` generado con los parámetros GLD finales.
- [x] Escribir `R/05_calibration_plasmode.R` — ver sección 15. API de `gld::rgl()` confirmada contra fuente real; `generar_plasmode()` implementado + sanity check (job `plasmode-sanity-check`) corrido — ver sección 16.
- [x] **Corregido y re-corrido**: sanity check reveló que `fit.fkml(method="ML")` no reproducía bien los momentos objetivo (sección 16) — corregido a `method="Mom"`. Confirmado en corrida 35385335301: 11/11 con `"Mom"` (sin necesitar respaldo), diferencias objetivo-réplica ya en rango de ruido de muestreo, y el ajuste pasó de 7-221s a 5-12ms por subescala. **Bloque 3 (calibración plasmode) cerrado.**
- [x] **Bloque 1 (réplica directa)**: `R/01_simulation_classical.R` escrito — ver sección 17. Job `classical-timing-pilot` corrido con `R/08_run_battery.R` corregido (sección 19) — `dagostino_pearson` válido para n≥25 en las 8 familias; NA en n=10 por límite propio de la prueba (sección 20), no por error.
- [x] Tiempos reales confirmados por familia (corrida 35430523246, ver sección 20): 18.8-32.5 min por familia a R=10.000 — sharding por familia alcanza sin partir además por n.
- [x] Escribir y correr el job final `simulate-classical` (matrix de 8 familias, R=10.000) — corrida 35431776551, 8/8 shards exitosos. **Bloque 1 cerrado** — ver sección 22.
- [x] Cerrar diseño del Bloque 2 (familia Beta(a,a), a∈{0.5,1,2,3,5,10}) — ver sección 23. `R/02_simulation_platykurtic.R` escrito, job `platykurtic-timing-pilot` agregado.
- [x] Correr `simulate-platykurtic` (Bloque 2, directo a R=10.000 — ver sección 25) y validar el patrón de NA del CSV resultante, igual que con el Bloque 1 — corrida 35437615474 (grid 10-500), 36/36 celdas válidas.
- [x] Cerrar el n_max de los Bloques 2/3 — **n_max=1500**, ver sección 26 (saturación de potencia + escalera del Bloque 4 + distribución real de tamaños muestrales en la literatura). Grid final: {10,25,50,100,250,500,1000,1500}.
- [x] Correr/confirmar los puntos exploratorios n=1000 y n=1500 del Bloque 2 (job `platykurtic-explore-n-alto`) y armar el CSV final concatenado con el grid canónico (10-500) — corrida 35440170904, 12/12 celdas válidas (ver sección 27). **Bloque 2 cerrado.**
- [x] Separar `05_calibration_plasmode.R` (funciones puras) de `05b_pilot_plasmode_sanity.R` (sanity check) y escribir `06_simulation_plasmode.R` con soporte de `n_list` desde el arranque — ver sección 28.
- [x] Correr el job `simulate-plasmode` (Bloque 3, matrix de 11 subescalas, R=10.000, grid completo {10,25,50,100,250,500,1000,1500}) y validar el patrón de NA del CSV resultante de cada subescala — corrida 35444808801, 11/11 shards exitosos, 88/88 celdas válidas (mismo patrón de NA que los Bloques 1/2: `dagostino_pearson` solo en n=10; sin reaparición del problema de `anscombe.test()` del Bloque 2, ver sección 27 — estas 11 distribuciones no llegan a curtosis tan extrema como a=0.5). **Bloque 3 cerrado.**
- [x] Cerrar la escalera de n del Bloque 4 por instrumento y escribir `R/07_real_data_subsampling.R` — ver sección 29.
- [x] Correr el job `simulate-real-subsampling` (Bloque 4, matrix de 11 subescalas, R=10.000, grid por instrumento) y validar el patrón de NA del CSV resultante de cada subescala — corrida 35446692844, 11/11 shards exitosos a la primera, 77/77 celdas válidas (mismo patrón de NA que los Bloques 1-3: `dagostino_pearson` solo en n=10, nada más). **Bloque 4 cerrado — los cuatro bloques de simulación están completos.**
- [x] Commitear al repositorio los 8 CSV finales del Bloque 1 (`data/results/bloque1_<familia>.csv`) — nunca se habían versionado pese a que el bloque quedó cerrado en la sección 22; recuperados desde los artifacts de la corrida 35431776551 (`classical-final-<familia>`) y confirmados idénticos en estructura y tamaño (288 filas, 36 por familia) — ver sección 30. **Ahora los cuatro bloques están completos y versionados en `data/results/`.**

## 24. Inputs de `workflow_dispatch` para no re-correr bloques ya cerrados (19 sep 2026)

`workflow_dispatch` sin inputs corre TODOS los jobs del archivo en cada disparo, incluidos los ya validados/cerrados (pilotos, extracción de datos reales, Bloque 1 completo con R=10.000) — desperdicio de tiempo y minutos de Actions cada vez que se agrega un job nuevo para otro bloque. Se agregaron tres inputs booleanos (`correr_pilotos_y_reales`, `correr_bloque1`, `correr_bloque2`), cada uno controlando el `if:` de su grupo de jobs, todos en `false` por defecto salvo el bloque activo en desarrollo. Para re-correr algo ya cerrado hay que pasarlo explícito: `gh workflow run simulate.yml -f correr_bloque1=true`.

## 25. Se elimina el piloto de tiempos como paso obligatorio (19 sep 2026)

La justificación original de pilotear con R=200 antes de comprometer R=10.000 (secciones 7 y 17) era evitar pasarse del límite de 6h por job de GitHub Actions. Con el Bloque 1 completo (sección 21) ya hay evidencia real de que ninguna de las 8 familias se acerca a ese límite (18-40 min a R=10.000, costo por réplica similar entre distribuciones) — seguir midiendo tiempos con un piloto aparte ya no aporta nada. Para el Bloque 2 (y bloques futuros con generadores simples de una sola llamada, ej. `rbeta()`) se va directo a R=10.000: `simulate-platykurtic` reemplaza al job `platykurtic-timing-pilot`. La validación de calidad de los resultados (patrón de NA, valores fuera de rango) se sigue haciendo después de la corrida sobre el CSV final, igual que con el Bloque 1 (sección 22) — eso no tiene costo de cómputo adicional, es solo revisión de datos.

## 26. n_max de los Bloques 2/3 — cerrado en n=1500 (19 sep 2026)

El grid de n del Bloque 1 (10 a 500) es una restricción de réplica del paper original, no elegible. Para los Bloques 2 y 3 (diseño propio) se evaluaron tres justificaciones para el techo de n, que terminan apuntando en la misma dirección:

1. **Saturación empírica de potencia**: con `weibull` k=3 del Bloque 1 como referencia, a n=500 la tasa de rechazo todavía está lejos de 1 para varias pruebas — hay margen real para seguir observando el comportamiento de las 10 pruebas más allá de n=500.
2. **Escalera de n real del Bloque 4** (remuestreo sobre datos reales, sección 6): criterio de Nunnally (10 obs/ítem) específico por instrumento da mínimos de 80 (RIASEC, 8 ítems) a 200 (MACH-IV, 20 ítems); con un multiplicador razonable sobre esos mínimos, el rango real de n en las submuestras del Bloque 4 termina entre ~800 y ~2.000 según el instrumento.
3. **Distribución de tamaños muestrales en la literatura publicada de constructos sociales**: n=200-500 es el rango que domina en estudios publicados; n=1000-1500 es minoritario pero realista, típico de estudios con muestras grandes recolectadas online — justo el tipo de dato que alimenta el Bloque 4 (datasets de openpsychometrics.org).

**Decisión final**: n_max=1500 para los Bloques 2 y 3. El grid queda así: n∈{10,25,50,100,250,500} (cobertura densa del rango que domina en la práctica publicada, y comparabilidad directa con el Bloque 1) + puntos de extensión en n=1000 y n=1500 (extremo alto, menos común pero plausible, y compatible con el rango real de las submuestras del Bloque 4). No hace falta esperar a cerrar el multiplicador exacto de la escalera del Bloque 4 para fijar este número — las tres justificaciones convergen en el mismo orden de magnitud sin depender de ese detalle.

`R/02_simulation_platykurtic.R` acepta un tercer argumento opcional (`n_list`, ej. `Rscript R/02_simulation_platykurtic.R beta 10000 1000,1500`) para correr celdas de n puntuales sin repetir el grid por defecto (10-500) ya cubierto — el resultado sale a un archivo con sufijo `_nXXX` que se concatena directo con la corrida canónica (10-500), sin volver a correr nada. **Confirmado (corrida 35440170904, job `platykurtic-explore-n-alto`)**: n=1000 y n=1500 corridos con éxito, 12/12 celdas válidas (ver también sección 27 — el patrón de `curtosis_na` para a=0.5 llega a 100% en ambos). CSV final concatenado en `data/results/bloque2_beta.csv` con el grid completo {10,25,50,100,250,500,1000,1500}. **Bloque 2 cerrado.**

## 27. Límite de dominio de `moments::anscombe.test()` para curtosis extrema (19 sep 2026)

En la corrida canónica del Bloque 2 (`bloque2_beta.csv`, grid 10-500) aparece un patrón de NA en la columna `curtosis_na` (prueba de curtosis de Anscombe-Glynn, `moments::anscombe.test()`) que **no** es el típico límite de n mínimo (como el de D'Agostino-Pearson en n=10, sección 20) sino un problema de dominio que **empeora con n creciente**, y solo para el parámetro más platicúrtico del diseño (a=0.5, forma de bañera/arcoseno, curtosis en exceso ≈ -1.5):

| n   | curtosis_na (a=0.5, de 10.000) |
|-----|---------------------------------|
| 10  | 0 |
| 25  | 0 |
| 50  | 0 |
| 100 | 288 (2.9%) |
| 250 | 7.243 (72.4%) |
| 500 | 9.923 (99.2%) |

Para a∈{1,2,3,5,10} (curtosis en exceso desde -1.2 hasta -0.26), `curtosis_na=0` en todo el grid — el problema es específico del caso más extremo. **Confirmado con los puntos de extensión (corrida 35440170904)**: la tendencia continúa hasta el tope — `curtosis_na=10.000/10.000` (100%) en n=1000 y n=1500 para a=0.5, mientras que a∈{1,2,3,5,10} se mantienen en 0 en ambos puntos. El patrón queda completo:

| n    | curtosis_na (a=0.5, de 10.000) |
|------|---------------------------------|
| 10   | 0 |
| 25   | 0 |
| 50   | 0 |
| 100  | 288 (2.9%) |
| 250  | 7.243 (72.4%) |
| 500  | 9.923 (99.2%) |
| 1000 | 10.000 (100%) |
| 1500 | 10.000 (100%) |

**Mecanismo (confirmado contra el código fuente real de `moments::anscombe.test()`, paquete `moments` en CRAN)**: el estadístico pasa por un término `z <- (1 - 2/(9*a) - ((1 - 2/a)/(1 + xx*sqrt(2/(a-4))))^(1/3)) / sqrt(2/(9*a))`, donde `xx` mide qué tan lejos está la curtosis muestral `b` de la esperada bajo normalidad. Para muestras fuertemente platicúrticas, `xx` es muy negativo, lo que puede volver negativa la base `(1 + xx*sqrt(2/(a-4)))` antes de elevarla a la potencia 1/3. En R, un número negativo elevado a una potencia fraccionaria vía el operador `^` da `NaN` (R no calcula raíces cúbicas reales de negativos por esa vía) — esto se propaga como NA en el p-valor final. Que empeore con n creciente (al revés de un límite de n mínimo típico) tiene sentido: a mayor n, la distribución muestral de `b` se concentra más estrechamente alrededor de la curtosis poblacional real, así que la condición de base negativa se cumple de forma sistemática en vez de ocasional.

**Tratamiento**: se documenta como limitación de dominio propia de esta prueba clásica (no un error de nuestra implementación) — mismo criterio que la sección 20 para D'Agostino-Pearson. No se excluye la celda a=0.5 del diseño: el patrón de NA creciente con n es en sí mismo un resultado relevante para la comparación con SSTN en el régimen de curtosis extrema, que es justamente la extensión que motiva el Bloque 2 (sección 23).

## 28. Bloque 3 — separación de `05_calibration_plasmode.R` y arquitectura de `06_simulation_plasmode.R` (19 sep 2026)

Al preparar la simulación completa del Bloque 3 se encontraron dos problemas de diseño, ambos evitables aplicando las lecciones del incidente del Bloque 2 (sección 27 / el script sin `n_list` nunca pusheado):

1. **Efecto secundario oculto en `source()`**: `R/05_calibration_plasmode.R` corría su sanity check (1 réplica de n=5000 × 11 subescalas, escritura de `notes/plasmode_sanity_check.txt`, `sink()`) automáticamente cada vez que se hacía `source()` del archivo, sin ningún `if` que lo condicionara. El propio script ya advertía este problema por adelantado ("si más adelante hace falta reutilizar `generar_plasmode()` sin correr este chequeo, hay que separar las funciones a su propio archivo"). Si `06_simulation_plasmode.R` le hubiera hecho `source()` tal cual, cada una de las miles de llamadas habría repetido el sanity check completo. **Se corrigió antes de escribir el script de simulación, no después**: `05_calibration_plasmode.R` quedó con solo las funciones puras (`cargar_calibracion_plasmode()`, `generar_plasmode()`, sin efectos secundarios), y el sanity check se movió a `05b_pilot_plasmode_sanity.R` (mismo patrón que `00b_pilot_sstn_timing.R` y `04b_pilot_feasibility.R`). El job `plasmode-sanity-check` del workflow se actualizó para apuntar al archivo nuevo.

2. **Soporte de `n_list` desde el arranque, no como parche**: `06_simulation_plasmode.R` acepta el grid de n como tercer argumento opcional desde su primera versión (`Rscript R/06_simulation_plasmode.R <subescala> [R] [n_list]`), grid por defecto {10,25,50,100,250,500,1000,1500} — el grid completo ya cerrado en la sección 26, no el grid corto del Bloque 2 seguido de una extensión separada que casi se pierde por falta de esta misma flexibilidad desde el principio.

**Arquitectura de ejecución**: a diferencia del Bloque 2 (una sola familia Beta(a,a), un solo job), el Bloque 3 tiene 11 subescalas reales independientes — mismo patrón que el Bloque 1 (`simulate-classical`, matrix de 8 familias) en vez del patrón del Bloque 2 (un job secuencial). `06_simulation_plasmode.R` toma la subescala como primer argumento de línea de comandos, y el job `simulate-plasmode` del workflow la shardea vía `strategy.matrix` (11 shards paralelos, cada uno con el grid completo de 8 tamaños de muestra a R=10.000) en vez de un solo job secuencial de más de 2 horas.

## 29. Bloque 4 — escalera de n cerrada por instrumento y arquitectura de `07_real_data_subsampling.R` (19 sep 2026)

Cierre del detalle que quedaba abierto en la sección 6 (múltiplos de Nunnally, sin fijar el grid exacto). Escalera de n por instrumento — múltiplos {1×, 2×, 5×, 10×} del mínimo de Nunnally (10 obs/ítem) + tres puntos de contraste en n pequeño (10, 20, 30):

| Instrumento | Ítems/subescala | Mínimo Nunnally (1×) | Grid completo (7 puntos) |
|---|---|---|---|
| RIASEC | 8 | 80 | {10, 20, 30, 80, 160, 400, 800} |
| RSE | 10 | 100 | {10, 20, 30, 100, 200, 500, 1000} |
| DASS | 14 | 140 | {10, 20, 30, 140, 280, 700, 1400} |
| MACH-IV | 20 | 200 | {10, 20, 30, 200, 400, 1000, 2000} |

Los máximos (800-2.000) coinciden con la estimación de la sección 26. Todas las N reales de las 11 subescalas (39.775-144.234) son muy superiores a estos máximos, así que el remuestreo es **sin reemplazo** sin riesgo de agotar la población (criterio explícito: `max(n_grid) < N`, con `stop()` si no se cumple).

**R = 10.000 submuestras por celda**, misma convención que los Bloques 1-3.

**Arquitectura**: mismo patrón que el Bloque 3 (sección 28) — `R/07_real_data_subsampling.R` toma la subescala como primer argumento de línea de comandos (shardeado por matrix de 11 en el workflow), con soporte de `n_list` desde la primera versión del script, no como parche posterior. El grid por defecto se detecta automáticamente por el prefijo del nombre de archivo de la subescala (`dass_`, `riasec_`, `mach_`, `rse_`) mapeado a la escalera de su instrumento. Lee los puntajes crudos de `data/processed/<subescala>.csv` (columna única, nombre variable según subescala — el script la toma genéricamente por posición, no por nombre, para no tener que hardcodear 11 nombres de columna distintos).

## 30. Los 8 CSV finales del Bloque 1 se versionan en el repositorio (20 sep 2026)

Los datos del Bloque 1 estaban cerrados desde la sección 22 (corrida 35431776551), pero solo existían como artifacts de esa corrida — nunca se habían descargado ni commiteado a `data/results/`. Recuperados y commiteados en esta fecha: `data/results/bloque1_<familia>.csv` (8 archivos, uno por familia). Verificación de consistencia antes del commit: header idéntico en los 8 (`familia,parametro,n,R,<10 pruebas>,<10 _na>,segundos`), 37 líneas cada uno (36 filas de datos + encabezado), total 288 filas — coincide exactamente con lo documentado en la sección 22.

Con esto, los cuatro bloques de simulación (`bloque1_<familia>.csv` ×8, `bloque2_beta.csv`, `bloque3_plasmode.csv`, `bloque4_real.csv`) están completos y versionados en `data/results/`, listos como insumo de `R/99_aggregate_results.R`.
