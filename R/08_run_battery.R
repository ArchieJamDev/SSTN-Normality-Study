# 08_run_battery.R
# Funcion compartida: corre la bateria completa de 10 pruebas sobre un vector
# de datos y devuelve un vector nombrado de p-valores (o rechazo/no rechazo a
# un alpha dado). La usan 01, 02, 05 y 07 — logica de las pruebas en un solo
# lugar, no duplicada en cada script de simulacion.

source("R/00_setup.R")

#' @param x vector numerico
#' @param null_cache nula del SSTN precalibrada para length(x) (ver
#'   06_sstn_null_calibration.R) — se pasa en vez de recalibrar aqui
run_battery <- function(x, null_cache = NULL) {
  # TODO: Shapiro-Wilk       -> stats::shapiro.test
  # TODO: Anderson-Darling   -> nortest::ad.test
  # TODO: Lilliefors         -> nortest::lillie.test
  # TODO: Jarque-Bera        -> tseries::jarque.bera.test (verificar redundancia
  #                             con D'Agostino-Pearson, ver DESIGN.md seccion 2)
  # TODO: D'Agostino-Pearson -> fBasics::dagoTest
  # TODO: Cramer-von Mises   -> nortest::cvm.test
  # TODO: Shapiro-Francia    -> nortest::sf.test
  # TODO: chi^2 de Pearson   -> nortest::pearson.test
  # TODO: prueba de curtosis -> moments::anscombe.test o equivalente
  # TODO: SSTN               -> sstn::sstn.test, usando null_cache si se paso
  stop("TODO: implementar")
}
