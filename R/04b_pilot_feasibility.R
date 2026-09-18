# 04b_pilot_feasibility.R
#
# Piloto para validar, contra el paquete real, la API de SimMultiCorrData y
# gld antes de escribir la version final de 04_moments_and_feasibility.R —
# mismo patron que 00b_pilot_sstn_timing.R con sstn::sstn() (ver
# notes/DESIGN.md secciones 3, 9 y 10).
#
# Corre en el job `feasibility-pilot` del workflow, que depende de
# `extract-subscales` (descarga su artifact real-subscales-processed a
# data/processed/ antes de este script).
#
# Confirmado por documentacion real de los paquetes (ver notes/DESIGN.md
# seccion 12 tras esta corrida):
#   SimMultiCorrData::find_constants(method, skews, skurts, fifths, sixths)
#     - method = "Fleishman" (3er orden) o "Polynomial" (5to orden Headrick)
#     - skurts = CURTOSIS EN EXCESO (kurtosis - 3), no curtosis cruda
#     - devuelve $constants y $valid (booleano de factibilidad)
#     - "Polynomial" exige fifths/sixths (cumulantes estandarizados 5to/6to);
#       se usan 0 por defecto (no tenemos objetivo real para esos momentos,
#       son estadisticos demasiado ruidosos para estimar de forma confiable)
#   gld::fit.fkml(x, method="ML", ...) ajusta la GLD FKML por maxima
#     verosimilitud DIRECTO a un vector de datos crudo — no a un objetivo
#     (asimetria, curtosis) como Fleishman. Aqui se prueba sobre una
#     submuestra (el N completo de algunas subescalas es de decenas de miles
#     de casos, ML podria ser lento) para medir tiempo y ver si converge.

source("R/00_setup.R")

dir.create("notes", showWarnings = FALSE)
log_con <- file("notes/feasibility_pilot.txt", open = "wt")
sink(log_con, split = TRUE)

subscale_files <- list.files("data/processed", pattern = "\\.csv$", full.names = TRUE)
cat("Archivos encontrados en data/processed/:\n")
print(subscale_files)

read_subscale <- function(path) {
  df <- readr::read_csv(path, col_types = readr::cols(.default = readr::col_double()))
  df[[1]]
}

targets <- data.frame(
  archivo = basename(subscale_files),
  n = NA_integer_,
  asimetria = NA_real_,
  curtosis_exceso = NA_real_
)

datos <- setNames(vector("list", length(subscale_files)), basename(subscale_files))

for (i in seq_along(subscale_files)) {
  x <- read_subscale(subscale_files[i])
  datos[[i]] <- x
  targets$n[i] <- length(x)
  targets$asimetria[i] <- moments::skewness(x)
  targets$curtosis_exceso[i] <- moments::kurtosis(x) - 3
}

cat("\n=== Objetivos (asimetria, curtosis en exceso) por subescala ===\n")
print(targets, digits = 4)

# --- Fleishman (3er orden) ------------------------------------------------

cat("\n=== SimMultiCorrData::find_constants(method='Fleishman') ===\n")
fleishman_results <- data.frame(
  archivo = targets$archivo, valid = NA, segundos = NA_real_
)
for (i in seq_len(nrow(targets))) {
  t0 <- Sys.time()
  res <- tryCatch(
    SimMultiCorrData::find_constants(
      method = "Fleishman",
      skews = targets$asimetria[i],
      skurts = targets$curtosis_exceso[i]
    ),
    error = function(e) list(valid = FALSE, error = conditionMessage(e))
  )
  fleishman_results$segundos[i] <- as.numeric(Sys.time() - t0, units = "secs")
  fleishman_results$valid[i] <- isTRUE(res$valid)
  cat(sprintf(
    "  %-25s valid=%s (%.2fs)\n",
    targets$archivo[i], fleishman_results$valid[i], fleishman_results$segundos[i]
  ))
}

# --- Polynomial (5to orden, Headrick) --------------------------------------

cat("\n=== SimMultiCorrData::find_constants(method='Polynomial', fifths=0, sixths=0) ===\n")
polynomial_results <- data.frame(
  archivo = targets$archivo, valid = NA, segundos = NA_real_
)
for (i in seq_len(nrow(targets))) {
  t0 <- Sys.time()
  res <- tryCatch(
    SimMultiCorrData::find_constants(
      method = "Polynomial",
      skews = targets$asimetria[i],
      skurts = targets$curtosis_exceso[i],
      fifths = 0,
      sixths = 0
    ),
    error = function(e) list(valid = FALSE, error = conditionMessage(e))
  )
  polynomial_results$segundos[i] <- as.numeric(Sys.time() - t0, units = "secs")
  polynomial_results$valid[i] <- isTRUE(res$valid)
  cat(sprintf(
    "  %-25s valid=%s (%.2fs)\n",
    targets$archivo[i], polynomial_results$valid[i], polynomial_results$segundos[i]
  ))
}

# --- GLD (fit.fkml sobre submuestra de los datos reales) -------------------

cat("\n=== gld::fit.fkml(x, method='ML') sobre submuestra (n=2000) ===\n")
set.seed(20260918)
gld_results <- data.frame(
  archivo = targets$archivo, convergio = NA, segundos = NA_real_
)
for (i in seq_len(nrow(targets))) {
  x <- datos[[i]]
  x_sub <- if (length(x) > 2000) sample(x, 2000) else x
  t0 <- Sys.time()
  res <- tryCatch(
    gld::fit.fkml(x_sub, method = "ML"),
    error = function(e) list(error = conditionMessage(e))
  )
  gld_results$segundos[i] <- as.numeric(Sys.time() - t0, units = "secs")
  gld_results$convergio[i] <- is.null(res$error)
  cat(sprintf(
    "  %-25s convergio=%s (%.2fs)\n",
    targets$archivo[i], gld_results$convergio[i], gld_results$segundos[i]
  ))
  if (!is.null(res$lambda)) {
    cat("    lambda =", paste(round(res$lambda, 4), collapse = ", "), "\n")
  }
}

cat("\n=== Resumen ===\n")
resumen <- data.frame(
  archivo = targets$archivo,
  fleishman_valid = fleishman_results$valid,
  polynomial_valid = polynomial_results$valid,
  gld_convergio = gld_results$convergio
)
print(resumen)

cat("\nListo.\n")

sink()
close(log_con)
