# 05b_pilot_plasmode_sanity.R
#
# Sanity check del generador plasmode (Bloque 3): genera 1 replica de
# n=5000 por cada una de las 11 subescalas y compara su asimetria/curtosis
# empirica contra el objetivo de data/processed/plasmode_calibration.csv,
# para confirmar que los parametros GLD ajustados realmente reproducen la
# forma esperada -- antes de usarlos en la simulacion completa
# (R/06_simulation_plasmode.R).
#
# Separado de R/05_calibration_plasmode.R (que ahora solo define funciones
# puras, sin efectos secundarios al hacer source()) el 19 sep 2026, porque
# este chequeo no debe repetirse en cada una de las miles de llamadas a
# generar_plasmode() de la simulacion completa -- ver notes/DESIGN.md.
#
# Corre en el job `plasmode-sanity-check` del workflow, que depende de
# `moments-and-feasibility` (descarga su artifact plasmode-calibration).

source("R/00_setup.R")
source("R/05_calibration_plasmode.R")

dir.create("notes", showWarnings = FALSE)
log_con <- file("notes/plasmode_sanity_check.txt", open = "wt")
sink(log_con, split = TRUE)

set.seed(20260918)
n_check <- 5000

calibracion <- cargar_calibracion_plasmode()
cat(sprintf(
  "Sanity check: generando 1 replica de n=%d por subescala y comparando\n",
  n_check
))
cat("asimetria/curtosis empirica contra el objetivo real.\n\n")

resultados <- data.frame(
  archivo = calibracion$archivo,
  asim_objetivo = calibracion$asimetria,
  asim_replica = NA_real_,
  curt_objetivo = calibracion$curtosis_exceso,
  curt_replica = NA_real_
)

for (i in seq_len(nrow(calibracion))) {
  x <- generar_plasmode(calibracion$archivo[i], n_check, calibracion)
  resultados$asim_replica[i] <- moments::skewness(x)
  resultados$curt_replica[i] <- moments::kurtosis(x) - 3
  cat(sprintf(
    "%-25s asim: objetivo=%7.4f replica=%7.4f (dif=%6.4f)  curt.exc: objetivo=%7.4f replica=%7.4f (dif=%6.4f)\n",
    calibracion$archivo[i],
    resultados$asim_objetivo[i], resultados$asim_replica[i],
    resultados$asim_replica[i] - resultados$asim_objetivo[i],
    resultados$curt_objetivo[i], resultados$curt_replica[i],
    resultados$curt_replica[i] - resultados$curt_objetivo[i]
  ))
}

cat("\n=== Resumen ===\n")
print(resultados, digits = 4)

cat("\nListo.\n")
sink()
close(log_con)
