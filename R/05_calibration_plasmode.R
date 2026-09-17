# 05_calibration_plasmode.R
# Bloque 3: genera datos sinteticos calibrados a la asimetria/curtosis real de
# cada subescala (usando el metodo decidido en 04_moments_and_feasibility.R),
# y corre la bateria de 10 pruebas igual que en los Bloques 1 y 2.
#
# Esto es "simulacion plasmode" (Schreck et al. 2024) — puente entre la
# simulacion parametrica pura y la aplicacion directa a datos reales.

source("R/00_setup.R")

N_REPLICATES <- 10000L
SAMPLE_SIZES <- c(10, 25, 50, 100, 250, 500)
ALPHA <- 0.05

# TODO: leer notes/feasibility_table.csv (metodo elegido + parametros objetivo)
# TODO: generar R replicas por subescala x n usando el metodo elegido
# TODO: reutilizar nula cacheada del SSTN por n
# TODO: escribir simulations/results/plasmode_<subescala>_<n>.csv
