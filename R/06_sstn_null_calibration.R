# 06_sstn_null_calibration.R
# Calibra y cachea la distribucion nula del SSTN, UNA sola vez por cada n
# usado en todo el proyecto (Bloques 1, 2, 3 y el remuestreo de datos reales).
#
# La nula del SSTN depende solo de (n, M, T, beta) — no del dataset ni de la
# distribucion alternativa (ver DESIGN.md seccion 4). Correr este script antes
# que cualquier otro script de simulacion/remuestreo, y que todos los demas
# LEAN el cache en vez de recalibrar.
#
# Salida: simulations/null_calibration/null_n<n>.rds por cada n en NS_NEEDED.

source("R/00_setup.R")

# Union de todos los n usados en el proyecto: la malla clasica del paper
# original + la escalera de Nunnally de las 4 subescalas reales (ver
# DESIGN.md seccion 6) — completar la segunda parte una vez determinados los
# multiplos exactos por instrumento.
NS_NEEDED <- c(10, 20, 25, 30, 50, 100, 250, 500)  # TODO: agregar la escalera Nunnally completa

# TODO: para cada n en NS_NEEDED, calibrar la nula del SSTN (ver documentacion
#       del paquete sstn — calibracion especifica para n chico, aproximacion
#       asintotica para n grande) y guardar en
#       simulations/null_calibration/null_n<n>.rds
