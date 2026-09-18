# 05_calibration_plasmode.R
#
# Generador de replicas sinteticas plasmode (Bloque 3) a partir de los
# parametros GLD (FKML) ajustados en R/04_moments_and_feasibility.R y
# guardados en data/processed/plasmode_calibration.csv.
#
# API real de gld::rgl() confirmada contra la fuente del paquete (CRAN +
# github.com/cran/gld), ver notes/DESIGN.md seccion 15:
#   rgl(n, lambda1=0, lambda2=NULL, lambda3=NULL, lambda4=NULL,
#       param="fkml", lambda5=NULL)
#   - lambda1 puede pasarse como escalar O como un VECTOR de longitud 4 con
#     los 4 parametros juntos (dejando lambda2/3/4 en NULL) --
#     .gl.parameter.tidy() lo detecta por length(lambda1) > 1 y lo pasa tal
#     cual a gl.check.lambda(), que extrae lambda[1..4] por indice. Se usa
#     esta forma vectorizada aqui.
#   - param="fkml" es el default de rgl() y es la MISMA parametrizacion que
#     usa gld::fit.fkml() (Freimer-Mudholkar-Kollia-Lin) -- no hace falta
#     traducir entre parametrizaciones distintas.
#
# Uso previsto: cada celda del Bloque 3 del diseño de simulacion (subescala x
# n) llamara a generar_plasmode(archivo, n) para obtener UNA replica
# sintetica de tamano n, sobre la cual se corre la bateria de 10 pruebas
# (R/08_run_battery.R) -- repetido R veces por celda dentro del futuro job
# `simulate`.
#
# Este script, corrido directamente (Rscript R/05_calibration_plasmode.R),
# ademas hace un sanity check: genera una replica de n=5000 por cada una de
# las 11 subescalas y compara su asimetria/curtosis empirica contra el
# objetivo de data/processed/plasmode_calibration.csv, para confirmar que
# los parametros GLD ajustados realmente reproducen la forma esperada antes
# de usarlos en la simulacion completa.
#
# Corre en el job `plasmode-sanity-check` del workflow, que depende de
# `moments-and-feasibility` (descarga su artifact plasmode-calibration).

source("R/00_setup.R")

.plasmode_calibracion <- NULL

#' Carga (cacheada) la tabla de calibracion GLD de las 11 subescalas.
cargar_calibracion_plasmode <- function(path = "data/processed/plasmode_calibration.csv") {
  if (is.null(.plasmode_calibracion) || !identical(attr(.plasmode_calibracion, "ruta"), path)) {
    df <- readr::read_csv(path, show_col_types = FALSE)
    stopifnot(all(df$gld_convergio))  # las 11 subescalas deben tener un ajuste valido
    attr(df, "ruta") <- path
    .plasmode_calibracion <<- df
  }
  .plasmode_calibracion
}

#' Genera UNA replica sintetica plasmode de tamano n para una subescala dada.
#'
#' @param archivo nombre de archivo de la subescala tal como aparece en
#'   data/processed/plasmode_calibration.csv (p.ej. "dass_depression.csv")
#' @param n tamano de la replica a generar
#' @param calibracion data.frame de calibracion (por defecto la carga cacheada)
#' @return vector numerico de longitud n
generar_plasmode <- function(archivo, n, calibracion = cargar_calibracion_plasmode()) {
  fila <- calibracion[calibracion$archivo == archivo, ]
  if (nrow(fila) != 1) {
    stop(sprintf(
      "Subescala '%s' no encontrada (o duplicada) en la tabla de calibracion.",
      archivo
    ))
  }
  lambdas <- as.numeric(fila[1, c("lambda1", "lambda2", "lambda3", "lambda4")])
  gld::rgl(n, lambda1 = lambdas, param = "fkml")
}

# --- Sanity check: la replica generada reproduce el objetivo? -------------
#
# Corre siempre que este script se ejecute (Rscript R/05_calibration_plasmode.R
# directo, como en el job `plasmode-sanity-check`). Si mas adelante un script
# de simulacion necesita reutilizar generar_plasmode() vía source() sin
# volver a correr este chequeo, conviene separar las funciones a su propio
# archivo en ese momento -- no se resuelve aqui por adelantado.

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
