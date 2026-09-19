# 07_real_data_subsampling.R
#
# Bloque 4 -- aplicacion a datos reales via remuestreo repetido tipo
# "m-out-of-N" (ver notes/DESIGN.md seccion 6): no hay una nula verdadera
# conocida en datos reales, asi que en vez de una sola decision por
# subescala se extraen R submuestras aleatorias SIN reemplazo a cada tamano
# n de una escalera especifica por instrumento, y se calcula la tasa de
# rechazo empirica por prueba usando el N completo de la subescala como
# poblacion de referencia.
#
# Escalera de n por instrumento (cerrada en DESIGN.md seccion 29): multiplos
# del criterio de Nunnally (10 obs/item) -- 1x, 2x, 5x, 10x el minimo -- mas
# tres puntos de contraste en n pequeño (10, 20, 30):
#
#   RIASEC   (8 items/subescala,  minimo=80):  {10,20,30, 80, 160, 400,  800}
#   RSE      (10 items,           minimo=100): {10,20,30,100, 200, 500, 1000}
#   DASS     (14 items/subescala, minimo=140): {10,20,30,140, 280, 700, 1400}
#   MACH-IV  (20 items,           minimo=200): {10,20,30,200, 400,1000, 2000}
#
# Todas las N reales (39.775-144.234) son muy superiores a estos n maximos
# (800-2.000), asi que el remuestreo es sin reemplazo sin riesgo de agotar
# la poblacion.
#
# Igual que R/06_simulation_plasmode.R (Bloque 3): shardeado por subescala
# (matrix de 11 en el workflow) y con soporte de n_list desde el arranque,
# no como parche posterior -- ver DESIGN.md secciones 27 y 28 sobre por que
# esto importa.
#
# Uso: Rscript R/07_real_data_subsampling.R <subescala> [R] [n_list]
#   <subescala>: nombre de archivo tal como aparece en data/processed/
#                (ej. "dass_anxiety.csv"), producido por
#                R/03_extract_real_subscales.R -- un solo archivo, columna
#                unica con los puntajes crudos.
#   [R]: numero de submuestras por celda (default 10000)
#   [n_list]: lista de tamaños de muestra separados por coma. Default: la
#             escalera del instrumento correspondiente (ver arriba, detectada
#             por el prefijo del nombre de archivo). Si se pasa un grid
#             distinto al default del instrumento, el archivo de salida
#             queda con sufijo _nXXX para no pisar la corrida canonica.

source("R/00_setup.R")
source("R/08_run_battery.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Uso: Rscript R/07_real_data_subsampling.R <subescala> [R] [n_list]")
}
subescala_elegida <- args[1]
R_replicas <- if (length(args) >= 2) as.integer(args[2]) else 10000L

# Escalera de n por instrumento, detectada por el prefijo del nombre de
# archivo de la subescala.
escaleras_n <- list(
  dass    = c(10, 20, 30, 140, 280,  700, 1400),
  riasec  = c(10, 20, 30,  80, 160,  400,  800),
  mach    = c(10, 20, 30, 200, 400, 1000, 2000),
  rse     = c(10, 20, 30, 100, 200,  500, 1000)
)

prefijo <- sub("_.*$", "", sub("\\.csv$", "", subescala_elegida))
if (!prefijo %in% names(escaleras_n)) {
  stop(sprintf(
    "No se reconoce el instrumento de '%s' (prefijo '%s'). Instrumentos conocidos: %s",
    subescala_elegida, prefijo, paste(names(escaleras_n), collapse = ", ")
  ))
}
n_grid_default <- escaleras_n[[prefijo]]

n_grid <- if (length(args) >= 3) {
  as.integer(strsplit(args[3], ",")[[1]])
} else {
  n_grid_default
}
es_grid_default <- identical(sort(n_grid), sort(n_grid_default))

ruta_datos <- file.path("data/processed", subescala_elegida)
if (!file.exists(ruta_datos)) {
  stop(sprintf("No se encontro '%s' (esperado en data/processed/).", ruta_datos))
}
x_completo <- readr::read_csv(ruta_datos, show_col_types = FALSE)[[1]]
x_completo <- x_completo[!is.na(x_completo)]
N <- length(x_completo)

if (max(n_grid) >= N) {
  stop(sprintf(
    "n maximo del grid (%d) >= N de la subescala (%d) -- remuestreo sin reemplazo invalido.",
    max(n_grid), N
  ))
}

cat(sprintf(
  "Bloque 4 -- subescala='%s' (instrumento='%s', N=%d), R=%d submuestras, %d tamaños de muestra = %d celdas\n\n",
  subescala_elegida, prefijo, N, R_replicas, length(n_grid), length(n_grid)
))

# Misma semilla fija que los Bloques 1-3, por consistencia de convencion
# (cada subescala corre en su propio proceso R como shard independiente del
# workflow).
set.seed(20260918)

filas <- list()
idx <- 1
for (n in n_grid) {
  rechazos <- matrix(NA, nrow = R_replicas, ncol = 10)
  nombres_pruebas <- NULL
  t0 <- Sys.time()
  for (r in seq_len(R_replicas)) {
    x <- sample(x_completo, size = n, replace = FALSE)
    pvals <- run_battery(x)
    if (is.null(nombres_pruebas)) nombres_pruebas <- names(pvals)
    rechazos[r, ] <- pvals < 0.05
  }
  tasas <- colMeans(rechazos, na.rm = TRUE)
  n_na <- colSums(is.na(rechazos))
  names(tasas) <- nombres_pruebas
  names(n_na) <- paste0(nombres_pruebas, "_na")
  segundos <- as.numeric(Sys.time() - t0, units = "secs")

  fila <- c(
    list(subescala = subescala_elegida, instrumento = prefijo, N = N, n = n, R = R_replicas),
    as.list(tasas), as.list(n_na),
    list(segundos = segundos)
  )
  filas[[idx]] <- as.data.frame(fila, stringsAsFactors = FALSE)
  idx <- idx + 1

  cat(sprintf(
    "%-25s n=%4d -> %7.1fs total (%.2fms/replica)\n",
    subescala_elegida, n, segundos, 1000 * segundos / R_replicas
  ))
}

tabla <- do.call(rbind, filas)

dir.create("data/results", showWarnings = FALSE, recursive = TRUE)
subescala_base <- sub("\\.csv$", "", subescala_elegida)
out_path <- if (es_grid_default) {
  sprintf("data/results/bloque4_%s.csv", subescala_base)
} else {
  sprintf("data/results/bloque4_%s_n%s.csv", subescala_base, paste(n_grid, collapse = "-"))
}
readr::write_csv(tabla, out_path)
cat(sprintf("\nGuardado %s\n", out_path))
cat("Listo.\n")
