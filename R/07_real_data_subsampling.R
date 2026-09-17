# 07_real_data_subsampling.R
# Aplicacion a datos reales: submuestreo repetido tipo "m-out-of-N" por
# subescala (ver DESIGN.md seccion 6).
#
# Para cada una de las 11 subescalas:
#   - escalera de n = multiplos del minimo de Nunnally (10 obs/item):
#     1x, 2x, 5x, 10x... el minimo del instrumento
#   - mas puntos de contraste por debajo del minimo: n=10,20,30
#   - en cada n, extraer muchas submuestras aleatorias (sin reemplazo dentro de
#     cada submuestra) del N completo de la subescala
#   - correr la bateria de 10 pruebas en cada submuestra
#   - tasa de rechazo empirica por prueba y por n = "tasa de deteccion"
#     relativa al N completo como referencia poblacional (NO es potencia
#     clasica — encuadrar asi en el manuscrito)

source("R/00_setup.R")

# Minimos de Nunnally por instrumento (10 obs/item, ver DESIGN.md seccion 5):
NUNNALLY_MIN <- c(
  DASS_depresion = 140, DASS_ansiedad = 140, DASS_estres = 140,  # 14 items c/u
  MACH_IV = 200,                                                  # 20 items
  RSE = 100,                                                      # 10 items
  # RIASEC: TODO completar por subescala una vez confirmado el mapeo item->subescala
  RIASEC = NA
)
MULTIPLES <- c(1, 2, 5, 10)
SMALL_N_CONTRAST <- c(10, 20, 30)
N_SUBSAMPLES_PER_CELL <- 1000L  # replicas de remuestreo por celda (subescala x n)

# TODO: leer data/processed/*_subscales.csv
# TODO: reutilizar nula cacheada del SSTN por n
# TODO: escribir simulations/results/realdata_<subescala>_<n>.csv
