# SSTN-Normality-Study

Comparación de la prueba de normalidad basada en autosimilitud (**SSTN**, Anarat & Schwender, 2026, arXiv:2604.03810; paquete `sstn` en CRAN) frente a 9 pruebas clásicas, mediante simulación Monte Carlo y aplicación a datos psicométricos reales. Proyecto hermano de [AssumptionsLab](../AssumptionsLab), pensado como artículo independiente (candidato natural: Austrian Journal of Statistics, igual que el artículo de AssumptionsLab).

Ver `notes/DESIGN.md` para el registro completo de decisiones metodológicas.

## Objetivo

El paper original de Anarat & Schwender compara el SSTN contra 5 pruebas clásicas (Shapiro-Wilk, Anderson-Darling, Lilliefors, Jarque-Bera, D'Agostino-Pearson) usando únicamente simulación paramétrica — sin ninguna aplicación a datos reales. Este proyecto:

1. Amplía la comparación a 10 pruebas (las 5 del paper original + 4 de la batería de AssumptionsLab que ellos no usaron + el propio SSTN).
2. Extiende la simulación con un bloque de distribuciones platicúrticas (punto débil conocido del SSTN) y un bloque de distribuciones calibradas a la forma real de datos psicométricos (vía Fleishman o la distribución lambda generalizada).
3. Llena el vacío de aplicación a datos reales del paper original, usando 4 datasets psicométricos abiertos de constructos distintos.

## Estructura

```
R/                      Scripts de simulación y análisis
data/raw/                Datasets originales (sin modificar), como se descargaron
data/processed/           Puntajes de subescala extraídos, listos para análisis
simulations/null_calibration/   Distribuciones nulas del SSTN cacheadas por n (evita recalibrar en cada réplica)
simulations/results/      Salidas crudas de las corridas de simulación
notes/                    Bitácora de diseño y decisiones metodológicas
.github/workflows/        Definición de los jobs de simulación en GitHub Actions
```

## Pruebas comparadas (10)

Shapiro-Wilk, Anderson-Darling, Lilliefors, Jarque-Bera, D'Agostino-Pearson, Cramér-von Mises, Shapiro-Francia, chi² de Pearson, prueba de curtosis, SSTN.

Pendiente: confirmar en el código de AssumptionsLab si "Jarque-Bera/asimetría" es el estadístico JB completo o una prueba de asimetría pura, para evitar redundancia conceptual con D'Agostino-Pearson.

## Datasets reales (Open Psychometrics, `data/raw/`)

| Dataset | Constructo | N | Subescalas | Fuente |
|---|---|---|---|---|
| DASS | Depresión / Ansiedad / Estrés | 39.775 | 3 | openpsychometrics.org/tests/DASS/ |
| RIASEC | Intereses vocacionales (códigos de Holland) | 145.828 | 6 | openpsychometrics.org/tests/RIASEC.php |
| MACH-IV | Maquiavelismo | 73.489 | 1 | openpsychometrics.org/tests/MACH-IV/ |
| RSE | Autoestima (Rosenberg) | 47.974 | 1 | openpsychometrics.org/tests/RSE.php |

Se excluyó deliberadamente cualquier dataset de personalidad tipo Big Five/IPIP por las dificultades psicométricas conocidas de ese modelo (efectos techo marcados por ítem, falta de estructura simple en AFE).

## Estado

Estructura inicial creada. Pendiente: `git init` + primer commit (desde esta máquina), cálculo de asimetría/curtosis real por subescala, chequeo de factibilidad Fleishman/GLD, piloto de tiempos para dimensionar el matrix de GitHub Actions.
