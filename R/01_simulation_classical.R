# 01_simulation_classical.R
# Bloque 1: replica directa de las 8 familias de distribuciones del paper original
# (Anarat & Schwender 2026), mismos parametros, para comparabilidad directa.
#
# Familias (ver notes/DESIGN.md seccion 3):
#   1. Normal desplazada  N(a-3, 9/a^2),         a in {1,2,3,4,5,6}
#   2. Gamma              Gamma(theta,1),         theta in {1,4,6,8,10,12}
#   3. Chi-cuadrado       chi^2_m,                 m in {3,6,9,12,15,18}
#   4. Lognormal          parametro d,              d in {1/6,...,1}
#   5. Weibull             forma k,                  k in {0.5,...,3}
#   6. t-Student           gl nu,                    nu in {1,...,6}
#   7. Mezcla de normales 0.6N(-1,1)+0.4N(4-b,2),  b in {0,...,5}
#   8. Convolucion U(-3,3) * N(0,sigma^2),         sigma in {0,...,1}
#
# n in {10,25,50,100,250,500}, alpha=.05, R=10000 (ver DESIGN.md seccion 4 para la
# justificacion de subir R desde el 1000 del paper original).
#
# IMPORTANTE: la nula del SSTN se calibra UNA sola vez por n (ver 06_sstn_null_calibration.R)
# y se carga desde simulations/null_calibration/ — no recalibrar aqui.

source("R/00_setup.R")

N_REPLICATES <- 10000L
SAMPLE_SIZES <- c(10, 25, 50, 100, 250, 500)
ALPHA <- 0.05

# TODO: cargar la nula cacheada del SSTN por n desde simulations/null_calibration/
# TODO: implementar generadores por familia (list de closures parametrizadas)
# TODO: correr la bateria de 10 pruebas (ver 08_run_battery.R) sobre cada replica
# TODO: escribir resultados a simulations/results/classical_<familia>_<n>.csv
