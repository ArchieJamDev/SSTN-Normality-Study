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
# Este archivo solo define funciones puras (cargar_calibracion_plasmode(),
# generar_plasmode()), pensadas para reutilizarse via source() desde otros
# scripts SIN efectos secundarios -- no escribe archivos ni corre nada al
# hacer source(). Lo usan:
#   - R/05b_pilot_plasmode_sanity.R -- sanity check de 1 replica x subescala.
#   - R/06_simulation_plasmode.R -- simulacion completa del Bloque 3.
#
# (Hasta el 19 sep 2026 este archivo tambien corria el sanity check al
# hacer source() -- se separo a R/05b_pilot_plasmode_sanity.R porque
# R/06_simulation_plasmode.R necesita reusar generar_plasmode() miles de
# veces sin repetir ese chequeo en cada llamada.)

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
