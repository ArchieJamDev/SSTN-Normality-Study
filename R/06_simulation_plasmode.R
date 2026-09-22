# 06_simulation_plasmode.R
#
# Bloque 3 -- simulacion plasmode completa: para UNA subescala real
# calibrada (data/processed/plasmode_calibration.csv, ver
# R/04_moments_and_feasibility.R) y cada tamano de muestra del grid, genera
# R replicas sinteticas via generar_plasmode() (R/05_calibration_plasmode.R,
# distribucion GLD ajustada por igualacion de momentos -- ver DESIGN.md
# seccion 16) y corre la bateria completa de 11 pruebas
# (R/08_run_battery.R, incluye Epps-Pulley desde sep 2026).
#
# A diferencia del Bloque 2 (una sola familia con un eje de parametro), aca
# el eje que varia entre corridas es la subescala real (11 en total, ver
# DESIGN.md secciones 11 y 14) -- por eso este script toma la subescala como
# primer argumento de linea de comandos y se shardea por matrix en el
# workflow (mismo patron que R/01_simulation_classical.R para el Bloque 1 --
# 11 unidades independientes, no tiene sentido un solo job secuencial de
# mas de 2 horas cuando se puede paralelizar).
#
# n grid por defecto {10,25,50,100,250,500,1000,1500} -- grid completo ya
# cerrado para los Bloques 2 y 3 por igual (DESIGN.md seccion 26). A
# diferencia de como se hizo con el Bloque 2 (grid corto primero, extension
# a n=1000/1500 despues, en una corrida separada que casi se pierde por no
# tener soporte de n_list desde el arranque -- ver seccion 27 y el
# incidente del 19 sep 2026), aca el soporte de n_list esta desde la
# primera version de este script, no como parche posterior.
#
# Uso: Rscript R/06_simulation_plasmode.R <subescala> [R] [n_list]
#   <subescala>: nombre de archivo tal como aparece en la columna `archivo`
#                de data/processed/plasmode_calibration.csv (ej.
#                "dass_depression.csv")
#   [R]: numero de replicas Monte Carlo por celda (default 10000)
#   [n_list]: lista de tamaños de muestra separados por coma (ej. "1000" o
#             "10,25,50,100,250,500,1000,1500"). Default: grid completo de
#             arriba. Si se pasa un grid distinto al default, el archivo de
#             salida queda con sufijo _nXXX para no pisar la corrida
#             canonica.

source("R/00_setup.R")
source("R/05_calibration_plasmode.R")
source("R/08_run_battery.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Uso: Rscript R/06_simulation_plasmode.R <subescala> [R] [n_list]")
}
subescala_elegida <- args[1]
R_replicas <- if (length(args) >= 2) as.integer(args[2]) else 10000L

n_grid_default <- c(10, 25, 50, 100, 250, 500, 1000, 1500)
n_grid <- if (length(args) >= 3) {
  as.integer(strsplit(args[3], ",")[[1]])
} else {
  n_grid_default
}
es_grid_default <- identical(sort(n_grid), sort(n_grid_default))

calibracion <- cargar_calibracion_plasmode()
if (!subescala_elegida %in% calibracion$archivo) {
  stop(sprintf(
    "Subescala desconocida: '%s'. Debe ser una de: %s",
    subescala_elegida, paste(calibracion$archivo, collapse = ", ")
  ))
}

cat(sprintf(
  "Bloque 3 -- subescala='%s', R=%d replicas, %d tamaños de muestra = %d celdas\n\n",
  subescala_elegida, R_replicas, length(n_grid), length(n_grid)
))

# Misma semilla fija que los Bloques 1 y 2, por consistencia de convencion
# (cada subescala corre en su propio proceso R como shard independiente del
# workflow, sin riesgo de correlacion entre shards).
set.seed(20260918)

filas <- list()
idx <- 1
for (n in n_grid) {
  # Numero de pruebas de la bateria detectado en la primera replica (11
  # desde la adicion de Epps-Pulley) -- ya NO hardcodeado a 10 (ver
  # incidente equivalente en R/07_real_data_subsampling.R y
  # R/10_simulation_categorias.R al agregar esta prueba).
  rechazos <- NULL
  nombres_pruebas <- NULL
  t0 <- Sys.time()
  for (r in seq_len(R_replicas)) {
    x <- generar_plasmode(subescala_elegida, n, calibracion)
    pvals <- run_battery(x)
    if (is.null(rechazos)) {
      nombres_pruebas <- names(pvals)
      rechazos <- matrix(NA, nrow = R_replicas, ncol = length(pvals))
    }
    rechazos[r, ] <- pvals < 0.05
  }
  tasas <- colMeans(rechazos, na.rm = TRUE)
  n_na <- colSums(is.na(rechazos))
  names(tasas) <- nombres_pruebas
  names(n_na) <- paste0(nombres_pruebas, "_na")
  segundos <- as.numeric(Sys.time() - t0, units = "secs")

  fila <- c(
    list(subescala = subescala_elegida, n = n, R = R_replicas),
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
  sprintf("data/results/bloque3_%s.csv", subescala_base)
} else {
  sprintf("data/results/bloque3_%s_n%s.csv", subescala_base, paste(n_grid, collapse = "-"))
}
readr::write_csv(tabla, out_path)
cat(sprintf("\nGuardado %s\n", out_path))
cat("Listo.\n")
