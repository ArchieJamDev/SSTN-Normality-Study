# 10_simulation_categorias.R
#
# Bloque 5 -- simulacion completa del efecto de la cantidad de categorias
# de respuesta (k) sobre la potencia de las pruebas de normalidad (ver
# notes/DESIGN.md seccion 32). Para UN escenario y UN k del diseño (12
# celdas en total: 3 escenarios x k in {3,4,5,6}) y cada tamaño de muestra
# del grid, genera R replicas de puntajes compuestos via
# generar_categorias() (R/09_calibration_categorias.R) y corre la bateria
# completa de 10 pruebas (R/08_run_battery.R).
#
# A diferencia de los bloques anteriores (un solo eje que varia entre
# corridas -- familia en el Bloque 1, subescala en los Bloques 3/4 --),
# aca hay DOS ejes cruzados (escenario x k), por eso este script toma
# ambos como los dos primeros argumentos de linea de comandos, y el
# workflow los shardea con una matrix de dos claves (escenario, k) en vez
# de una lista de 12 pares escrita a mano -- ver DESIGN.md seccion 32.
#
# n grid por defecto {10,25,50,100,250,500,1000,1500} -- mismo grid
# canonico que los Bloques 2 y 3 (DESIGN.md seccion 26), por
# comparabilidad directa entre bloques. Soporte de n_list desde el
# arranque, no como parche posterior (mismo criterio que 06 y 07 -- ver
# DESIGN.md seccion 28, incidente del Bloque 2).
#
# Uso: Rscript R/10_simulation_categorias.R <escenario> <k> [R] [n_list]
#   <escenario>: "A_simetrica", "B1_riasec_realistic" o
#                "B2_dass_depression"
#   <k>: numero de categorias de respuesta (3, 4, 5 o 6)
#   [R]: numero de replicas Monte Carlo por celda (default 10000)
#   [n_list]: lista de tamaños de muestra separados por coma. Default:
#             grid completo de arriba. Si se pasa un grid distinto al
#             default, el archivo de salida queda con sufijo _nXXX para
#             no pisar la corrida canonica.

source("R/00_setup.R")
source("R/09_calibration_categorias.R")
source("R/08_run_battery.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Uso: Rscript R/10_simulation_categorias.R <escenario> <k> [R] [n_list]")
}
escenario_elegido <- args[1]
k_elegido <- as.integer(args[2])
R_replicas <- if (length(args) >= 3) as.integer(args[3]) else 10000L

n_grid_default <- c(10, 25, 50, 100, 250, 500, 1000, 1500)
n_grid <- if (length(args) >= 4) {
  as.integer(strsplit(args[4], ",")[[1]])
} else {
  n_grid_default
}
es_grid_default <- identical(sort(n_grid), sort(n_grid_default))

# Validacion temprana (mismo espiritu que la validacion de subescala en
# 06_simulation_plasmode.R): falla rapido con un mensaje claro en vez de
# arrastrar un escenario/k invalido hasta el primer intento de generar
# datos.
obtener_umbrales_categorias(escenario_elegido, k_elegido)

cat(sprintf(
  "Bloque 5 -- escenario='%s', k=%d, R=%d replicas, %d tamaños de muestra = %d celdas\n\n",
  escenario_elegido, k_elegido, R_replicas, length(n_grid), length(n_grid)
))

# Misma semilla fija que los demas bloques, por consistencia de convencion
# (cada celda escenario x k corre en su propio proceso R como shard
# independiente del workflow, sin riesgo de correlacion entre shards).
set.seed(20260920)

filas <- list()
idx <- 1
for (n in n_grid) {
  rechazos <- matrix(NA, nrow = R_replicas, ncol = 10)
  nombres_pruebas <- NULL
  t0 <- Sys.time()
  for (r in seq_len(R_replicas)) {
    x <- generar_categorias(escenario_elegido, k_elegido, n)
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
    list(escenario = escenario_elegido, k = k_elegido, n = n, R = R_replicas),
    as.list(tasas), as.list(n_na),
    list(segundos = segundos)
  )
  filas[[idx]] <- as.data.frame(fila, stringsAsFactors = FALSE)
  idx <- idx + 1

  cat(sprintf(
    "%-20s k=%d n=%4d -> %7.1fs total (%.2fms/replica)\n",
    escenario_elegido, k_elegido, n, segundos, 1000 * segundos / R_replicas
  ))
}

tabla <- do.call(rbind, filas)

dir.create("data/results", showWarnings = FALSE, recursive = TRUE)
out_path <- if (es_grid_default) {
  sprintf("data/results/bloque5_%s_k%d.csv", escenario_elegido, k_elegido)
} else {
  sprintf("data/results/bloque5_%s_k%d_n%s.csv", escenario_elegido, k_elegido, paste(n_grid, collapse = "-"))
}
readr::write_csv(tabla, out_path)
cat(sprintf("\nGuardado %s\n", out_path))
cat("Listo.\n")
