# 04_moments_and_feasibility.R
#
# Version final: para cada una de las 11 subescalas reales (data/processed/*.csv),
# calcula asimetria y curtosis oficiales (N completo), chequea factibilidad
# Fleishman y Polynomial (Headrick, 5to orden, fifths=sixths=0), y ajusta la
# distribucion Lambda Generalizada (GLD, parametrizacion FKML) por maxima
# verosimilitud directo sobre el N COMPLETO de cada subescala.
#
# Decision de metodo (ver notes/DESIGN.md secciones 12 y 14): tanto Fleishman
# como Polynomial (con fifths=sixths=0, el unico valor defendible sin un
# objetivo real de 5to/6to momento, demasiado ruidosos para estimar de forma
# confiable) resultaron INFACTIBLES para las 11/11 subescalas reales
# (confirmado en R/04b_pilot_feasibility.R, corrida 35373706154). GLD via
# gld::fit.fkml(x, method="ML") convergio para las 11/11 (piloto: submuestras
# de n=2000) -> es el UNICO metodo viable, y ademas es el mismo motor ya usado
# en el Bloque 2 (platicurtico), dejando un solo mecanismo generador para las
# dos extensiones propias del estudio (ver DESIGN.md seccion 3).
#
# Esta version ajusta GLD sobre el N COMPLETO de cada subescala (no una
# submuestra) porque es un paso de calibracion UNICO por subescala (11 ajustes
# en total, no un ajuste por replica Monte Carlo) -> la fidelidad extra vale
# el costo computacional. Se imprime el tiempo real de cada ajuste para
# confirmar que sigue siendo viable a N completo (el piloto solo lo probo a
# n=2000).
#
# Salida: data/processed/plasmode_calibration.csv, una fila por subescala:
#   archivo, n, asimetria, curtosis_exceso, fleishman_valid, polynomial_valid,
#   gld_convergio, lambda1..lambda4, segundos_gld
# Esta tabla es (a) la tabla de transparencia metodologica para el manuscrito
# (DESIGN.md seccion 3, punto 5) y (b) el insumo directo de
# R/05_calibration_plasmode.R, que generara replicas sinteticas a cualquier n
# via gld::rgl(n, lambda1=..., lambda2=..., lambda3=..., lambda4=...).
#
# Corre en el job `moments-and-feasibility` del workflow, que depende de
# `extract-subscales` (descarga su artifact real-subscales-processed a
# data/processed/ antes de este script).

source("R/00_setup.R")

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("notes", showWarnings = FALSE)

log_con <- file("notes/moments_and_feasibility.txt", open = "wt")
sink(log_con, split = TRUE)

#' Ver notes/DESIGN.md seccion 12: find_constants() puede devolver un vector
#' atomico suelto (no una lista) cuando falla por completo, y $valid puede
#' venir como string "TRUE"/"FALSE" en vez de logico. Esta funcion cubre
#' ambos casos.
get_valid <- function(res) {
  if (!is.list(res) || is.null(res$valid)) return(FALSE)
  v <- res$valid
  isTRUE(v) || identical(v, "TRUE")
}

subscale_files <- list.files("data/processed", pattern = "\\.csv$", full.names = TRUE)
subscale_files <- subscale_files[basename(subscale_files) != "plasmode_calibration.csv"]
cat("Archivos encontrados en data/processed/:\n")
print(subscale_files)

read_subscale <- function(path) {
  df <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_double()))
  df[[1]]
}

resultados <- data.frame(
  archivo = basename(subscale_files),
  n = NA_integer_,
  asimetria = NA_real_,
  curtosis_exceso = NA_real_,
  fleishman_valid = NA,
  polynomial_valid = NA,
  gld_convergio = NA,
  lambda1 = NA_real_,
  lambda2 = NA_real_,
  lambda3 = NA_real_,
  lambda4 = NA_real_,
  segundos_gld = NA_real_
)

for (i in seq_along(subscale_files)) {
  x <- read_subscale(subscale_files[i])
  resultados$n[i] <- length(x)
  resultados$asimetria[i] <- moments::skewness(x)
  resultados$curtosis_exceso[i] <- moments::kurtosis(x) - 3

  fl <- tryCatch(
    SimMultiCorrData::find_constants(
      method = "Fleishman",
      skews = resultados$asimetria[i],
      skurts = resultados$curtosis_exceso[i]
    ),
    error = function(e) list(valid = FALSE)
  )
  resultados$fleishman_valid[i] <- get_valid(fl)

  pol <- tryCatch(
    SimMultiCorrData::find_constants(
      method = "Polynomial",
      skews = resultados$asimetria[i],
      skurts = resultados$curtosis_exceso[i],
      fifths = 0,
      sixths = 0
    ),
    error = function(e) list(valid = FALSE)
  )
  resultados$polynomial_valid[i] <- get_valid(pol)

  t0 <- Sys.time()
  gld_fit <- tryCatch(
    gld::fit.fkml(x, method = "ML"),
    error = function(e) list(error = conditionMessage(e))
  )
  resultados$segundos_gld[i] <- as.numeric(Sys.time() - t0, units = "secs")
  resultados$gld_convergio[i] <- is.null(gld_fit$error)
  if (is.null(gld_fit$error)) {
    resultados[i, c("lambda1", "lambda2", "lambda3", "lambda4")] <- as.list(gld_fit$lambda)
  }

  cat(sprintf(
    "%-25s n=%6d  asim=%7.4f  curt.exc=%7.4f  fleishman=%s  polynomial=%s  gld=%s (%.1fs)\n",
    resultados$archivo[i], resultados$n[i], resultados$asimetria[i],
    resultados$curtosis_exceso[i], resultados$fleishman_valid[i],
    resultados$polynomial_valid[i], resultados$gld_convergio[i], resultados$segundos_gld[i]
  ))
}

cat("\n=== Tabla final (transparencia metodologica, DESIGN.md seccion 3) ===\n")
print(resultados, digits = 4)

readr::write_csv(resultados, "data/processed/plasmode_calibration.csv")
cat("\nGuardado data/processed/plasmode_calibration.csv\n")
cat("Listo.\n")

sink()
close(log_con)
