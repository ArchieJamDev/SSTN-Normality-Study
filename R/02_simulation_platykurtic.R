# 02_simulation_platykurtic.R
#
# Bloque 2 -- extension platicurtica, diseno propio (no hay paper de referencia
# que replicar aqui, a diferencia del Bloque 1). Motivo: la convolucion
# uniforme-normal del Bloque 1 (el unico punto debil claro del SSTN reportado
# en el paper original) sugiere que vale la pena barrer curtosis negativa de
# forma mas sistematica y continua -- ver notes/DESIGN.md secciones 3 y 23.
#
# Familia unica: Beta(a,a) simetrica (asimetria=0 para cualquier a; solo se
# mueve la curtosis). Curtosis en exceso = -6/(2a+3) para Beta(a,a) -- barrido
# continuo desde fuertemente platicurtica (a=0.5, forma de "bañera"/arcoseno)
# hasta casi-normal (a=10):
#
#   a=0.5 -> curtosis exceso ~ -1.5   (arcoseno, forma de U)
#   a=1   -> curtosis exceso ~ -1.2   (uniforme pura -- Beta(1,1)=Uniforme(0,1))
#   a=2   -> curtosis exceso ~ -0.857
#   a=3   -> curtosis exceso ~ -0.667
#   a=5   -> curtosis exceso ~ -0.462
#   a=10  -> curtosis exceso ~ -0.261
#
# No se usa GLD aca (queda reservado para el Bloque 3, calibracion a datos
# reales) -- un solo motor generador simple, sin mezclar mecanismos.
#
# n grid por defecto {10,25,50,100,250,500} -- igual al Bloque 1. n_max
# cerrado en 1500 (ver DESIGN.md seccion 26): grid final del bloque es
# {10,25,50,100,250,500,1000,1500}, con 1000/1500 corridos aparte via el
# tercer argumento de linea de comandos para no repetir el grid por defecto
# ya validado -- ver mas abajo.
#
# Uso: Rscript R/02_simulation_platykurtic.R <familia> [R] [n_list]
#   <familia>: por ahora solo "beta" (unica familia definida en este bloque)
#   [R]: numero de replicas Monte Carlo (default 10000)
#   [n_list]: lista de tamaños de muestra separados por coma (ej. "1000" o
#             "1000,1500"). Default: "10,25,50,100,250,500". Si se pasa un
#             grid distinto al default, el archivo de salida queda con sufijo
#             _nXXX para no pisar la corrida canonica -- ver mas abajo.

source("R/00_setup.R")
source("R/08_run_battery.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Uso: Rscript R/02_simulation_platykurtic.R <familia> [R] [n_list]")
}
familia_elegida <- args[1]
R_replicas <- if (length(args) >= 2) as.integer(args[2]) else 10000L

n_grid_default <- c(10, 25, 50, 100, 250, 500)
n_grid <- if (length(args) >= 3) {
  as.integer(strsplit(args[3], ",")[[1]])
} else {
  n_grid_default
}
es_grid_default <- identical(sort(n_grid), sort(n_grid_default))

fam_generadores <- list(
  beta = function(n, a) stats::rbeta(n, shape1 = a, shape2 = a)
)

fam_parametros <- list(
  beta = c(0.5, 1, 2, 3, 5, 10)
)

if (!familia_elegida %in% names(fam_generadores)) {
  stop(sprintf(
    "Familia desconocida: '%s'. Debe ser una de: %s",
    familia_elegida, paste(names(fam_generadores), collapse = ", ")
  ))
}

generador <- fam_generadores[[familia_elegida]]
valores_parametro <- fam_parametros[[familia_elegida]]

cat(sprintf(
  "Bloque 2 -- familia='%s', R=%d replicas, %d valores de parametro x %d tamaños de muestra = %d celdas\n\n",
  familia_elegida, R_replicas, length(valores_parametro), length(n_grid),
  length(valores_parametro) * length(n_grid)
))

# Misma semilla fija que el Bloque 1, por consistencia de convencion (no hay
# riesgo de correlacion entre bloques/familias -- cada uno corre en su propio
# proceso R como job/shard independiente del workflow).
set.seed(20260918)

filas <- list()
idx <- 1
for (valor in valores_parametro) {
  for (n in n_grid) {
    # Numero de pruebas de la bateria detectado en la primera replica (11
    # desde la adicion de Epps-Pulley) -- ya NO hardcodeado a 10 (ver
    # incidente equivalente en R/06_simulation_plasmode.R,
    # R/07_real_data_subsampling.R y R/10_simulation_categorias.R al
    # agregar esta prueba).
    rechazos <- NULL
    nombres_pruebas <- NULL
    t0 <- Sys.time()
    for (r in seq_len(R_replicas)) {
      x <- generador(n, valor)
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
      list(familia = familia_elegida, parametro = valor, n = n, R = R_replicas),
      as.list(tasas), as.list(n_na),
      list(segundos = segundos)
    )
    filas[[idx]] <- as.data.frame(fila, stringsAsFactors = FALSE)
    idx <- idx + 1

    cat(sprintf(
      "%-8s param=%-6s n=%4d -> %7.1fs total (%.2fms/replica)\n",
      familia_elegida, format(valor), n, segundos, 1000 * segundos / R_replicas
    ))
  }
}

tabla <- do.call(rbind, filas)

dir.create("data/results", showWarnings = FALSE, recursive = TRUE)
out_path <- if (es_grid_default) {
  sprintf("data/results/bloque2_%s.csv", familia_elegida)
} else {
  sprintf("data/results/bloque2_%s_n%s.csv", familia_elegida, paste(n_grid, collapse = "-"))
}
readr::write_csv(tabla, out_path)
cat(sprintf("\nGuardado %s\n", out_path))
cat("Listo.\n")
