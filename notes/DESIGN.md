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

**Optimización de cómputo clave**: la calibración de la nula del SSTN depende solo de (n, M, T, β), no del dataset ni de la distribución alternativa. Calibrar la nula UNA sola vez por cada n usado y cachearla (carpeta `simulations/null_calibration/`), reutilizándola en todas las réplicas de todas las distribuciones alternativas a ese n, y también en el bloque de remuestreo de datos reales cuando coincida el n. Sin esto, el costo de recalibrar en cada réplica hace inviable subir R.

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

Decisión pendiente: repo público (gratis, sin límite práctico de minutos, mejor para reproducibilidad ante la revista) vs. privado (cuota mensual limitada).

## 8. Journal objetivo

Austrian Journal of Statistics — mismo journal que el artículo de AssumptionsLab ya en marcha, mismo flujo de trabajo en Overleaf/LaTeX cuando llegue el momento de redactar.

## 9. Pendientes abiertos

- [ ] Verificar JB/asimetría vs. D'Agostino-Pearson en código de AssumptionsLab (posible redundancia).
- [ ] Calcular asimetría/curtosis real de las 11 subescalas (con los datos ya descargados en `data/raw/`).
- [ ] Chequeo de factibilidad Fleishman/GLD sobre esos 11 puntos objetivo; decidir método único.
- [ ] Extraer y limpiar los puntajes de subescala (`data/processed/`) — claves de corrección: DASS (estándar DASS-42, 14 ítems/subescala), RIASEC (6 subescalas del codebook), MACH-IV (unidimensional, 20 ítems), RSE (unidimensional, 10 ítems, ítems inversos a revisar en el codebook).
- [ ] Piloto de tiempo de cómputo del SSTN (calibración de nula + estadístico) para dimensionar R y el matrix de GitHub Actions.
- [ ] `git init` + primer commit (pendiente, se hace desde esta máquina).
- [ ] Decidir repo público vs. privado en GitHub.
