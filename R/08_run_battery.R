# 08_run_battery.R
# Funcion compartida: corre la bateria completa de 10 pruebas sobre un vector
# de datos y devuelve un vector nombrado de p-valores. La usan 01, 02, 05 y 07
# — logica de las pruebas en un solo lugar, no duplicada en cada script de
# simulacion.
#
# Cada una de las 9 pruebas clasicas usa su propia funcion canonica de un
# paquete de R, sin ambiguedad conceptual entre ellas (ver notes/DESIGN.md
# seccion 9): Jarque-Bera (tseries) y D'Agostino-Pearson (fBasics, estadistico
# Omnibus) son dos omnibus de momentos DISTINTOS con calibracion distinta; la
# prueba de curtosis (moments::anscombe.test) es aparte, prueba solo curtosis.
#
# sstn::sstn() confirmado en el piloto real (ver DESIGN.md seccion 10):
# firma sstn::sstn(x, verbose = TRUE); calibra la nula internamente en cada
# llamada (finito para n chico, asintotico para n grande) en 4-9ms — no hace
# falta ninguna cache externa, se llama directo aqui.

source("R/00_setup.R")

#' Corre las 10 pruebas de normalidad sobre un vector numerico.
#'
#' @param x vector numerico (la muestra a evaluar)
#' @return vector numerico nombrado con los 10 p-valores; NA en la prueba que
#'   no se pudo calcular (ej. Shapiro-Wilk fuera de su rango valido de n)
run_battery <- function(x) {
  n <- length(x)

  safe_p <- function(expr) {
    tryCatch(expr, error = function(e) NA_real_, warning = function(w) {
      # Algunas pruebas (ej. sf.test) devuelven warning en vez de error fuera
      # de su rango valido de n — tratamos igual, NA en vez de propagar.
      tryCatch(suppressWarnings(expr), error = function(e) NA_real_)
    })
  }

  p_shapiro_wilk   <- safe_p(stats::shapiro.test(x)$p.value)
  p_anderson_darling <- safe_p(nortest::ad.test(x)$p.value)
  p_lilliefors     <- safe_p(nortest::lillie.test(x)$p.value)
  p_jarque_bera    <- safe_p(tseries::jarque.bera.test(x)$p.value)
  p_dagostino_pearson <- safe_p({
    dt <- fBasics::dagoTest(x)
    # OJO: fBasics::dagoTest() nombra el p-valor omnibus "Omnibus  Test" (con
    # DOS espacios) -- confirmado contra el codigo fuente real del paquete
    # (svn.r-project.org/Rmetrics/trunk/fBasics/R/NormalityTests.R y el
    # espejo en rdrr.io), no "Omnibus". Indexar por el nombre incorrecto no
    # tira error ni warning en R -- devuelve NA silenciosamente, por eso este
    # bug paso desapercibido hasta que el piloto del Bloque 1 mostro
    # dagostino_pearson_na=200 (el maximo posible) en TODAS las celdas de las
    # 8 familias (ver notes/DESIGN.md seccion 19). Se usa grepl() en vez del
    # string exacto para no depender de un conteo de espacios fragil.
    pv <- dt@test$p.value
    unname(pv[grepl("^Omnibus", names(pv))])
  })
  p_cramer_von_mises <- safe_p(nortest::cvm.test(x)$p.value)
  p_shapiro_francia <- safe_p(nortest::sf.test(x)$p.value)
  p_pearson_chi2   <- safe_p(nortest::pearson.test(x)$p.value)
  p_curtosis       <- safe_p(moments::anscombe.test(x)$p.value)
  p_sstn           <- safe_p(sstn::sstn(x, verbose = FALSE)$p.value)

  c(
    shapiro_wilk        = p_shapiro_wilk,
    anderson_darling     = p_anderson_darling,
    lilliefors           = p_lilliefors,
    jarque_bera          = p_jarque_bera,
    dagostino_pearson    = p_dagostino_pearson,
    cramer_von_mises     = p_cramer_von_mises,
    shapiro_francia      = p_shapiro_francia,
    pearson_chi2         = p_pearson_chi2,
    curtosis             = p_curtosis,
    sstn                 = p_sstn
  )
}

# Sanity check rapido al cargar el script directamente (no al hacer source()
# desde otro script — solo si se corre este archivo suelto).
if (sys.nframe() == 0) {
  set.seed(20260918)
  cat("=== Sanity check: n=50, datos normales ===\n")
  print(run_battery(rnorm(50)))
  cat("\n=== Sanity check: n=50, datos exponenciales (debe rechazar la mayoria) ===\n")
  print(run_battery(rexp(50)))
}
