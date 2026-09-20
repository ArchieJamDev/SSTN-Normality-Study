# 99_aggregate_results.R
#
# Consolida los cuatro CSV finales de los cuatro bloques de simulacion en un
# solo dataset en formato largo, con columnas que identifican el
# bloque/escenario de cada fila. Insumo para el analisis y la redaccion de
# resultados del manuscrito.
#
# Bloques y sus columnas identificadoras propias (ver notes/DESIGN.md
# secciones 17/22, 23, 28, 29):
#   Bloque 1 (replica directa, 8 archivos, uno por familia): familia, parametro
#   Bloque 2 (platicurtico, Beta(a,a), 1 archivo):            familia, parametro
#   Bloque 3 (plasmode/GLD, 11 subescalas, 1 archivo consolidado): subescala
#   Bloque 4 (remuestreo real, 11 subescalas, 1 archivo consolidado): subescala, instrumento, N
#
# Las cuatro comparten: n, R, las 10 pruebas (tasa de rechazo) + sus 10
# columnas _na, y segundos. Se unifican en un solo data.frame ancho,
# agregando `bloque` (1-4) y `bloque_nombre`, con NA en las columnas
# identificadoras que no aplican a cada bloque.
#
# A diferencia del resto de los scripts del proyecto, este NO hace
# source("R/00_setup.R"): no necesita ninguno de los paquetes de pruebas
# estadisticas (sstn, nortest, moments, tseries, fBasics, gld,
# SimMultiCorrData) que ese script instala para el resto del proyecto, solo
# readr para leer/escribir CSV -- evita instalar ~7 paquetes innecesarios en
# el job de GitHub Actions correspondiente.
#
# Uso: Rscript R/99_aggregate_results.R

columnas_pruebas <- c(
  "shapiro_wilk", "anderson_darling", "lilliefors", "jarque_bera",
  "dagostino_pearson", "cramer_von_mises", "shapiro_francia",
  "pearson_chi2", "curtosis", "sstn"
)
columnas_na <- paste0(columnas_pruebas, "_na")
columnas_comunes <- c("n", "R", columnas_pruebas, columnas_na, "segundos")
columnas_id <- c("bloque", "bloque_nombre", "familia", "parametro", "subescala", "instrumento", "N")
columnas_finales <- c(columnas_id, columnas_comunes)

completar_columnas <- function(df, bloque, bloque_nombre) {
  df$bloque <- bloque
  df$bloque_nombre <- bloque_nombre
  for (col in columnas_id) {
    if (!col %in% names(df)) df[[col]] <- NA
  }
  as.data.frame(df[, columnas_finales])
}

# Bloque 1: 8 archivos, uno por familia
archivos_b1 <- sort(Sys.glob("data/results/bloque1_*.csv"))
if (length(archivos_b1) != 8) {
  stop(sprintf("Se esperaban 8 archivos del Bloque 1, se encontraron %d.", length(archivos_b1)))
}
b1 <- do.call(rbind, lapply(archivos_b1, readr::read_csv, show_col_types = FALSE))
b1 <- completar_columnas(b1, 1L, "Replica directa (8 familias)")

# Bloque 2: un solo archivo (Beta(a,a))
b2 <- readr::read_csv("data/results/bloque2_beta.csv", show_col_types = FALSE)
b2 <- completar_columnas(b2, 2L, "Platicurtico (Beta(a,a))")

# Bloque 3: un solo archivo consolidado (11 subescalas via plasmode/GLD)
b3 <- readr::read_csv("data/results/bloque3_plasmode.csv", show_col_types = FALSE)
b3 <- completar_columnas(b3, 3L, "Plasmode calibrado a datos reales (GLD)")

# Bloque 4: un solo archivo consolidado (11 subescalas, remuestreo real)
b4 <- readr::read_csv("data/results/bloque4_real.csv", show_col_types = FALSE)
b4 <- completar_columnas(b4, 4L, "Remuestreo m-out-of-N sobre datos reales")

consolidado <- rbind(b1, b2, b3, b4)

# Chequeos de sanidad antes de guardar: conteos de fila esperados por bloque
# (ver notes/DESIGN.md secciones 22, 23, 28, 29).
conteos_esperados <- c(`1` = 288L, `2` = 48L, `3` = 88L, `4` = 77L)
conteos_reales <- table(consolidado$bloque)
for (b in names(conteos_esperados)) {
  n_esperado <- conteos_esperados[[b]]
  n_real <- if (b %in% names(conteos_reales)) as.integer(conteos_reales[[b]]) else 0L
  if (n_real != n_esperado) {
    stop(sprintf("Bloque %s: se esperaban %d filas, se encontraron %d.", b, n_esperado, n_real))
  }
}
stopifnot(nrow(consolidado) == sum(conteos_esperados))

# Todas las tasas de rechazo deben estar en [0,1] (o NA)
tasas <- as.matrix(consolidado[, columnas_pruebas])
if (any(tasas < 0 | tasas > 1, na.rm = TRUE)) {
  stop("Hay tasas de rechazo fuera de [0,1] en el dataset consolidado.")
}

dir.create("data/results", showWarnings = FALSE, recursive = TRUE)
readr::write_csv(consolidado, "data/results/consolidado.csv")

cat(sprintf(
  "Consolidado: %d filas (Bloque 1=%d, Bloque 2=%d, Bloque 3=%d, Bloque 4=%d)\n",
  nrow(consolidado), conteos_reales[["1"]], conteos_reales[["2"]], conteos_reales[["3"]], conteos_reales[["4"]]
))
cat("Guardado data/results/consolidado.csv\n")
cat("Listo.\n")
