# 01_simulation_classical.R
#
# Bloque 1 -- replica directa del paper original (Anarat & Schwender 2026).
# Genera R replicas Monte Carlo de UNA familia de distribuciones (pasada por
# linea de comandos) x 6 valores de parametro x 6 tamaños de muestra (36
# celdas), corre la bateria de 11 pruebas (R/08_run_battery.R, incluye
# Epps-Pulley desde sep 2026) sobre cada replica, y guarda la tasa de
# rechazo (p < .05) por prueba y celda.
#
# Especificacion de las 8 familias y sus parametros CONFIRMADA VERBATIM
# contra el texto real del paper -- Tabla 1 de arxiv.org/html/2604.03810
# (version HTML de arXiv, no adivinada de memoria; verificacion cruzada con
# dos fetches independientes del mismo texto, ver notes/DESIGN.md seccion
# 17):
#
#   1. Normal desplazada:            N(a-3, 9/a^2)          a in {1,2,3,4,5,6}
#   2. Gamma:                        Gamma(theta, 1)        theta in {1,4,6,8,10,12}
#   3. Chi-cuadrado:                 chi^2_m                m in {3,6,9,12,15,18}
#   4. Lognormal:                    Lognormal(0,(7/6-d)^2) d in {1/6,2/6,3/6,4/6,5/6,1}
#   5. Weibull:                      Weibull(k, 1)          k in {0.5,1,1.5,2,2.5,3}
#   6. t de Student:                 t_nu                   nu in {1,2,3,4,5,6}
#   7. Mezcla de normales:           0.6N(-1,1)+0.4N(4-b,2) b in {0,1,2,3,4,5}
#   8. Convolucion uniforme-normal:  U(-3,3) * N(0,sigma^2) sigma in {0,0.2,0.4,0.6,0.8,1}
#
# n in {10,25,50,100,250,500} (igual que el original). R=1000 replicas en el
# paper original; aqui R=10000 por defecto (ver DESIGN.md seccion 4 -- mas
# resolucion para distinguir pruebas cercanas en potencia, ahora que se
# comparan 10 pruebas en vez de 5). alpha=.05 (umbral fijo, no parametro de
# linea de comandos).
#
# Uso: Rscript R/01_simulation_classical.R <familia> [R]
#   <familia>: uno de los nombres de fam_generadores (ver mas abajo)
#   [R]: numero de replicas Monte Carlo (default 10000; se usa un R chico
#        para el piloto de tiempos antes de comprometer la corrida completa)
#
# Pensado para correr como UN shard del futuro job matrix `simulate-classical`
# del workflow (una familia por shard, o mas fino si el piloto de tiempos lo
# exige) -- ver DESIGN.md seccion 7.

source("R/00_setup.R")
source("R/08_run_battery.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Uso: Rscript R/01_simulation_classical.R <familia> [R]")
}
familia_elegida <- args[1]
R_replicas <- if (length(args) >= 2) as.integer(args[2]) else 10000L

fam_generadores <- list(
  normal_desplazada = function(n, a) stats::rnorm(n, mean = a - 3, sd = 3 / a),
  gamma = function(n, theta) stats::rgamma(n, shape = theta, rate = 1),
  chi2 = function(n, m) stats::rchisq(n, df = m),
  lognormal = function(n, d) stats::rlnorm(n, meanlog = 0, sdlog = (7 / 6 - d)),
  weibull = function(n, k) stats::rweibull(n, shape = k, scale = 1),
  t_student = function(n, nu) stats::rt(n, df = nu),
  mezcla_normal = function(n, b) {
    comp <- stats::rbinom(n, size = 1, prob = 0.4)  # 0 (prob .6) -> comp. 1; 1 (prob .4) -> comp. 2
    ifelse(comp == 0,
      stats::rnorm(n, mean = -1, sd = 1),
      stats::rnorm(n, mean = 4 - b, sd = sqrt(2))
    )
  },
  convolucion_uniforme_normal = function(n, sigma) {
    stats::runif(n, -3, 3) + stats::rnorm(n, mean = 0, sd = sigma)
  }
)

fam_parametros <- list(
  normal_desplazada = c(1, 2, 3, 4, 5, 6),
  gamma = c(1, 4, 6, 8, 10, 12),
  chi2 = c(3, 6, 9, 12, 15, 18),
  lognormal = c(1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1),
  weibull = c(0.5, 1, 1.5, 2, 2.5, 3),
  t_student = c(1, 2, 3, 4, 5, 6),
  mezcla_normal = c(0, 1, 2, 3, 4, 5),
  convolucion_uniforme_normal = c(0, 0.2, 0.4, 0.6, 0.8, 1)
)

n_grid <- c(10, 25, 50, 100, 250, 500)

if (!familia_elegida %in% names(fam_generadores)) {
  stop(sprintf(
    "Familia desconocida: '%s'. Debe ser una de: %s",
    familia_elegida, paste(names(fam_generadores), collapse = ", ")
  ))
}

generador <- fam_generadores[[familia_elegida]]
valores_parametro <- fam_parametros[[familia_elegida]]

cat(sprintf(
  "Bloque 1 -- familia='%s', R=%d replicas, %d valores de parametro x %d tamaños de muestra = %d celdas\n\n",
  familia_elegida, R_replicas, length(valores_parametro), length(n_grid),
  length(valores_parametro) * length(n_grid)
))

# Semilla fija por familia (cada familia corre en su propio proceso R como
# shard del matrix -- no hay riesgo de correlacion entre shards porque cada
# uno genera de una funcion/distribucion distinta desde el primer sorteo).
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
      "%-28s param=%-8s n=%4d -> %7.1fs total (%.2fms/replica)\n",
      familia_elegida, format(valor), n, segundos, 1000 * segundos / R_replicas
    ))
  }
}

tabla <- do.call(rbind, filas)

dir.create("data/results", showWarnings = FALSE, recursive = TRUE)
out_path <- sprintf("data/results/bloque1_%s.csv", familia_elegida)
readr::write_csv(tabla, out_path)
cat(sprintf("\nGuardado %s\n", out_path))
cat("Listo.\n")
