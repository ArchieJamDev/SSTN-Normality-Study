# 02_simulation_platykurtic.R
# Bloque 2: extension con distribuciones platicurticas — el unico punto debil
# documentado del SSTN (perdio frente a D'Agostino-Pearson en la convolucion
# uniforme-normal del paper original para n>=50).
#
# Familias candidatas (ver DESIGN.md seccion 3):
#   - Uniforme pura U(0,1)
#   - Beta(a,a) simetrica, a in {1,2,3,5,10}  (de uniforme a casi-normal)
#   - Lambda generalizada de Tukey (paquete gld, familia Ramberg-Schmeiser/FKML),
#     barriendo curtosis negativa de forma continua con un solo parametro
#
# Mismos n, alpha y R que 01_simulation_classical.R.

source("R/00_setup.R")

N_REPLICATES <- 10000L
SAMPLE_SIZES <- c(10, 25, 50, 100, 250, 500)
ALPHA <- 0.05

# TODO: definir la malla de parametros GLD para el barrido platicurtico
# TODO: reutilizar la nula cacheada del SSTN por n (simulations/null_calibration/)
# TODO: correr bateria de 10 pruebas, escribir a simulations/results/platykurtic_<config>_<n>.csv
