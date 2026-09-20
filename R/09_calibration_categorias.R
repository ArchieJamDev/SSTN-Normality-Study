# 09_calibration_categorias.R
#
# Bloque 5 -- funciones puras de generacion para el diseño de efecto de la
# cantidad de categorias de respuesta (k) sobre la potencia de las pruebas
# de normalidad (ver notes/DESIGN.md seccion 32). Mismo criterio de
# separacion que 05_calibration_plasmode.R (seccion 28): solo funciones
# puras aca, sin efectos secundarios -- la simulacion completa vive en
# R/10_simulation_categorias.R.
#
# Mecanismo generador: factor comun theta ~ N(0,1); m=10 items fijos
# (variable controlada, no manipulada -- ver DESIGN.md seccion 32);
# item_j = lambda*theta + sqrt(1-lambda^2)*eps_j, eps_j ~ N(0,1) iid;
# cada item se discretiza en k categorias ordenadas via k-1 umbrales sobre
# la variable latente; el compuesto es la suma de los m items
# discretizados.
#
# lambda=0.8 (no 0.6, el valor inicial explorado) -- con lambda=0.6 el
# objetivo de curtosis del escenario B2 (dass_depression, -1.1549) resulto
# infactible para cualquier k: el promedio de 10 items diluia demasiado la
# platicurtosis inducida sin importar donde se colocaran los umbrales.
# Ver DESIGN.md seccion 32 para el hallazgo completo.
#
# Los umbrales de abajo fueron calibrados una sola vez, localmente (numeros
# aleatorios comunes, N=150.000, semilla 20260920, optim() Nelder-Mead
# minimizando distancia a (asimetria objetivo, curtosis objetivo) -- ver
# DESIGN.md seccion 32), y se hardcodean aca en vez de recalibrarse en cada
# corrida del workflow (mismo criterio que los parametros GLD ya ajustados
# de data/processed/plasmode_calibration.csv para el Bloque 3, salvo que
# aca no hace falta ni siquiera un CSV de por medio: son solo 12 vectores
# cortos).

lambda_categorias <- 0.8
m_items_categorias <- 10L

# Parte A: umbrales simetricos (cuantiles equiespaciados), sin calibrar a
# ningun objetivo real -- asimetria=0 por construccion. Sirve de linea base
# (efecto de la sola discrecion, ver DESIGN.md seccion 32).
#
# Partes B1 (riasec_realistic, objetivo asimetria=0.7220 curtosis
# exceso=-0.1463) y B2 (dass_depression, objetivo asimetria=0.0386 curtosis
# exceso=-1.1549): umbrales calibrados via optimizacion numerica. B1 k=3 no
# alcanza el objetivo con precision exacta (asimetria lograda 0.7318,
# curtosis lograda -0.1515) -- documentado en DESIGN.md seccion 32 como
# hallazgo propio: con solo 2 umbrales libres, k=3 tiene el minimo de
# flexibilidad posible en este diseño, y el objetivo real queda justo
# fuera de la region exactamente alcanzable con m=10, lambda=0.8, k=3.
umbrales_categorias <- list(
  A_simetrica = list(
    `3` = c(-0.430727, 0.430727),
    `4` = c(-0.674490, 0.000000, 0.674490),
    `5` = c(-0.841621, -0.253347, 0.253347, 0.841621),
    `6` = c(-0.967422, -0.430727, 0.000000, 0.430727, 0.967422)
  ),
  B1_riasec_realistic = list(
    `3` = c(0.149688, 1.733351),
    `4` = c(-0.382251, 0.783554, 1.286023),
    `5` = c(0.014722, 0.281181, 1.675442, 1.862090),
    `6` = c(-0.652662, 0.044506, 0.825368, 1.103223, 1.318492)
  ),
  B2_dass_depression = list(
    `3` = c(-0.468331, 0.529549),
    `4` = c(-0.587470, 0.007969, 0.719825),
    `5` = c(-0.703984, -0.243605, 0.320351, 0.699274),
    `6` = c(-0.809481, -0.343401, 0.046172, 0.391858, 0.784547)
  )
)

#' Devuelve el vector de umbrales calibrados para un escenario y k dados.
#'
#' @param escenario uno de "A_simetrica", "B1_riasec_realistic",
#'   "B2_dass_depression"
#' @param k numero de categorias de respuesta (3, 4, 5 o 6)
#' @return vector numerico de k-1 umbrales crecientes
obtener_umbrales_categorias <- function(escenario, k) {
  if (!escenario %in% names(umbrales_categorias)) {
    stop(sprintf(
      "Escenario desconocido: '%s'. Debe ser uno de: %s",
      escenario, paste(names(umbrales_categorias), collapse = ", ")
    ))
  }
  k_chr <- as.character(k)
  if (!k_chr %in% names(umbrales_categorias[[escenario]])) {
    stop(sprintf(
      "k=%s sin umbrales calibrados para el escenario '%s'. k debe ser uno de: %s",
      k_chr, escenario, paste(names(umbrales_categorias[[escenario]]), collapse = ", ")
    ))
  }
  umbrales_categorias[[escenario]][[k_chr]]
}

#' Genera n puntajes compuestos (suma de m_items_categorias items
#' discretizados en k categorias) para un escenario dado.
#'
#' @param escenario uno de "A_simetrica", "B1_riasec_realistic",
#'   "B2_dass_depression"
#' @param k numero de categorias de respuesta (3, 4, 5 o 6)
#' @param n numero de puntajes compuestos a generar (tamaño de muestra)
#' @return vector entero de longitud n con los puntajes compuestos
generar_categorias <- function(escenario, k, n) {
  umbrales <- obtener_umbrales_categorias(escenario, k)
  m <- m_items_categorias
  theta <- rnorm(n)
  eps <- matrix(rnorm(n * m), nrow = n, ncol = m)
  latente <- lambda_categorias * theta + sqrt(1 - lambda_categorias^2) * eps
  respuestas <- matrix(1L, nrow = n, ncol = m)
  for (t in umbrales) respuestas <- respuestas + (latente > t)
  rowSums(respuestas)
}
