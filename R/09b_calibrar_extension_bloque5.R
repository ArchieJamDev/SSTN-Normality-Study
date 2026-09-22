# 09b_calibrar_extension_bloque5.R
#
# Bloque 5 (extension sep 2026) -- calibra los umbrales que faltan para la
# ampliacion del diseno original de R/09_calibration_categorias.R: k in
# {7,8} para los tres escenarios ya publicados (A_simetrica,
# B1_riasec_realistic, B2_dass_depression), y k in {3,...,8} completo para
# las 9 subescalas reales restantes de las 11 ya usadas en los Bloques 3-4
# (ver notes/DESIGN.md seccion 32 para las 2 que ya tienen escenario propio:
# riasec_realistic=B1, dass_depression=B2).
#
# NO recalibra k=3..6 de A_simetrica/B1/B2 -- esos valores ya estan
# hardcodeados en R/09_calibration_categorias.R y publicados en el
# manuscrito; recalcularlos arriesgaria una deriva num'erica minuscula que
# rompa la reproducibilidad de resultados ya reportados. Este script SOLO
# produce celdas nuevas.
#
# Mismo metodo exacto que el diseno original (ver comentarios de
# R/09_calibration_categorias.R y DESIGN.md seccion 32): factor comun
# theta~N(0,1), m=10 items, item_j = lambda*theta + sqrt(1-lambda^2)*eps_j,
# lambda=0.8; umbrales parametrizados como primer_umbral +
# cumsum(exp(log_gaps)) (crecientes bajo optimizacion sin restricciones);
# optim() Nelder-Mead minimizando la suma de cuadrados de la distancia a
# (asimetria objetivo, curtosis exceso objetivo); numeros aleatorios comunes
# (N=150.000, semilla 20260920) generados UNA sola vez y reusados en todas
# las celdas de todos los escenarios, para que las comparaciones entre
# escenarios/k no esten contaminadas por ruido Monte Carlo distinto entre
# celdas (mismo criterio que el diseno original).
#
# A diferencia del diseno original (calibrado "localmente" una sola vez,
# hardcodeado a mano por ser solo 12 vectores cortos -- ver comentario de
# R/09_calibration_categorias.R), esta extension tiene 60 celdas nuevas: se
# corre en GitHub Actions (no en una maquina local) y escribe un CSV en vez
# de un vector R hardcodeado a mano -- mismo patron ya usado en el proyecto
# para los momentos objetivo del Bloque 3
# (data/processed/plasmode_calibration.csv). R/09_calibration_categorias.R
# lee ese CSV al cargarse y fusiona sus filas con la tabla hardcodeada
# original, sin tocar esta ultima.
#
# Uso: Rscript R/09b_calibrar_extension_bloque5.R <escenario> [k_list] [n_starts]
#   <escenario>: "A_simetrica", "B1_riasec_realistic", "B2_dass_depression",
#                o uno de los 9 escenarios nuevos (C1..C9, ver tabla
#                objetivos_calibracion mas abajo)
#   [k_list]: lista de k separados por coma. Default: 7,8 para los tres
#             escenarios ya publicados; 3,4,5,6,7,8 para los 9 nuevos.
#   [n_starts]: cantidad de puntos de partida distintos que intenta el
#               optimizador por celda (default 5) -- mismo criterio que la
#               busqueda multi-arranque ya documentada para B1 k=3 en
#               DESIGN.md seccion 32 (la celda mas dificil del diseno
#               original, con el minimo de parametros libres).

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Uso: Rscript R/09b_calibrar_extension_bloque5.R <escenario> [k_list] [n_starts]")
}
escenario_elegido <- args[1]

escenarios_ya_publicados <- c("A_simetrica", "B1_riasec_realistic", "B2_dass_depression")
k_default <- if (escenario_elegido %in% escenarios_ya_publicados) c(7L, 8L) else 3:8

k_list <- if (length(args) >= 2 && nzchar(args[2])) {
  as.integer(strsplit(args[2], ",")[[1]])
} else {
  k_default
}
n_starts <- if (length(args) >= 3) as.integer(args[3]) else 5L

# Mapea cada uno de los 9 escenarios nuevos al archivo de subescala real
# correspondiente en data/processed/plasmode_calibration.csv (mismos
# momentos objetivo ya usados como insumo del Bloque 3, seccion 14/32 --
# ver R/04_moments_and_feasibility.R). B1=riasec_realistic y
# B2=dass_depression NO se repiten aca porque ya tienen escenario propio
# (nombre corto historico) desde el diseno original.
mapa_subescala <- c(
  C1_dass_anxiety         = "dass_anxiety.csv",
  C2_dass_stress          = "dass_stress.csv",
  C3_mach_total           = "mach_total.csv",
  C4_riasec_artistic      = "riasec_artistic.csv",
  C5_riasec_conventional  = "riasec_conventional.csv",
  C6_riasec_enterprising  = "riasec_enterprising.csv",
  C7_riasec_investigative = "riasec_investigative.csv",
  C8_riasec_social        = "riasec_social.csv",
  C9_rse_total            = "rse_total.csv"
)

es_simetrica <- identical(escenario_elegido, "A_simetrica")
es_nuevo <- escenario_elegido %in% names(mapa_subescala)
es_publicado_no_simetrico <- escenario_elegido %in% c("B1_riasec_realistic", "B2_dass_depression")

if (!es_simetrica && !es_nuevo && !es_publicado_no_simetrico) {
  stop(sprintf(
    "Escenario desconocido: '%s'. Debe ser 'A_simetrica', 'B1_riasec_realistic', 'B2_dass_depression', o uno de: %s",
    escenario_elegido, paste(names(mapa_subescala), collapse = ", ")
  ))
}

target_skew <- NA_real_
target_kurt <- NA_real_
if (es_nuevo || es_publicado_no_simetrico) {
  momentos <- readr::read_csv("data/processed/plasmode_calibration.csv", show_col_types = FALSE)
  archivo_objetivo <- if (es_nuevo) {
    mapa_subescala[[escenario_elegido]]
  } else if (identical(escenario_elegido, "B1_riasec_realistic")) {
    "riasec_realistic.csv"
  } else {
    "dass_depression.csv"
  }
  fila <- momentos[momentos$archivo == archivo_objetivo, ]
  if (nrow(fila) != 1) {
    stop(sprintf("No se encontro (o hay mas de una) fila para '%s' en plasmode_calibration.csv", archivo_objetivo))
  }
  target_skew <- fila$asimetria[1]
  target_kurt <- fila$curtosis_exceso[1]
}

lambda_categorias <- 0.8
m_items_categorias <- 10L
N_calib <- 150000L
semilla_calib <- 20260920L

# Numeros aleatorios comunes -- una sola generacion, reusada en TODAS las
# celdas de TODOS los escenarios (igual que el diseno original).
set.seed(semilla_calib)
theta_comun <- rnorm(N_calib)
eps_comun   <- matrix(rnorm(N_calib * m_items_categorias), nrow = N_calib, ncol = m_items_categorias)

composite_moments <- function(umbrales, theta = theta_comun, eps = eps_comun, lambda = lambda_categorias) {
  m <- ncol(eps)
  latente <- lambda * theta + sqrt(1 - lambda^2) * eps
  respuestas <- matrix(1L, nrow = length(theta), ncol = m)
  for (t in umbrales) respuestas <- respuestas + (latente > t)
  compuesto <- rowSums(respuestas)
  mu <- mean(compuesto)
  m2 <- mean((compuesto - mu)^2)
  m3 <- mean((compuesto - mu)^3)
  m4 <- mean((compuesto - mu)^4)
  c(skew = m3 / m2^1.5, kurt_exc = m4 / m2^2 - 3)
}

umbrales_desde_params <- function(params) {
  primer <- params[1]
  if (length(params) > 1) {
    gaps <- exp(params[-1])
    c(primer, primer + cumsum(gaps))
  } else {
    primer
  }
}

objetivo <- function(params, target_skew, target_kurt) {
  umbrales <- umbrales_desde_params(params)
  mom <- composite_moments(umbrales)
  (mom["skew"] - target_skew)^2 + (mom["kurt_exc"] - target_kurt)^2
}

#' Calibra los k-1 umbrales de una celda via optim() Nelder-Mead
#' multi-arranque (se queda con el mejor de los n_starts resultados).
calibrar_celda <- function(k, target_skew, target_kurt, n_starts, maxit = 3000) {
  base_simetrica <- qnorm((1:(k - 1)) / k)
  puntos_partida <- list(base_simetrica)
  set.seed(k * 1000L + round(target_skew * 1e4) + round(target_kurt * 1e4))
  for (i in 2:n_starts) {
    puntos_partida[[i]] <- sort(base_simetrica + rnorm(k - 1, sd = 0.25 * i / n_starts))
  }

  mejor <- NULL
  mejor_val <- Inf
  for (umb0 in puntos_partida) {
    primer0 <- umb0[1]
    gaps0 <- diff(umb0)
    gaps0[gaps0 <= 1e-6] <- 1e-6
    params0 <- c(primer0, log(gaps0))
    res <- tryCatch(
      optim(params0, objetivo, target_skew = target_skew, target_kurt = target_kurt,
            method = "Nelder-Mead",
            control = list(maxit = maxit, reltol = 1e-13)),
      error = function(e) NULL
    )
    if (!is.null(res) && res$value < mejor_val) {
      mejor_val <- res$value
      mejor <- res
    }
  }
  umbrales <- umbrales_desde_params(mejor$par)
  mom <- composite_moments(umbrales)
  list(umbrales = umbrales, skew = unname(mom["skew"]), kurt_exc = unname(mom["kurt_exc"]), dist2 = mejor_val)
}

cat(sprintf("Calibrando escenario='%s', k in {%s} (objetivo asimetria=%s, curtosis exceso=%s)\n",
            escenario_elegido, paste(k_list, collapse = ","),
            if (es_simetrica) "0 (simetrica, sin calibrar)" else sprintf("%.6f", target_skew),
            if (es_simetrica) "NA (formula analitica)" else sprintf("%.6f", target_kurt)))

filas <- list()
idx <- 1
for (k in k_list) {
  t0 <- Sys.time()
  if (es_simetrica) {
    # Parte A: cuantiles equiespaciados, sin optimizacion -- formula
    # analitica identica a la usada para k=3..6 en el diseno original.
    umbrales <- qnorm((1:(k - 1)) / k)
    mom <- composite_moments(umbrales)
    r <- list(umbrales = umbrales, skew = unname(mom["skew"]), kurt_exc = unname(mom["kurt_exc"]), dist2 = NA_real_)
  } else {
    r <- calibrar_celda(k, target_skew, target_kurt, n_starts = n_starts)
  }
  segundos <- as.numeric(Sys.time() - t0, units = "secs")
  cat(sprintf("  k=%d -> umbrales=[%s] skew=%.4f kurt_exc=%.4f dist2=%s (%.1fs)\n",
              k, paste(sprintf("%.6f", r$umbrales), collapse = ", "),
              r$skew, r$kurt_exc,
              if (is.na(r$dist2)) "NA" else sprintf("%.3g", r$dist2),
              segundos))

  fila <- data.frame(
    escenario = escenario_elegido, k = k,
    skew_objetivo = if (es_simetrica) 0 else target_skew,
    kurt_exc_objetivo = if (es_simetrica) NA_real_ else target_kurt,
    skew_logrado = r$skew, kurt_exc_logrado = r$kurt_exc, dist2 = r$dist2,
    stringsAsFactors = FALSE
  )
  for (j in seq_len(k - 1)) fila[[sprintf("umbral_%d", j)]] <- r$umbrales[j]
  filas[[idx]] <- fila
  idx <- idx + 1
}

tabla <- dplyr::bind_rows(filas)

dir.create("data/results", showWarnings = FALSE, recursive = TRUE)
out_path <- sprintf("data/results/calibracion_categorias_%s.csv", escenario_elegido)
readr::write_csv(tabla, out_path)
cat(sprintf("\nGuardado %s\n", out_path))
cat("Listo.\n")
