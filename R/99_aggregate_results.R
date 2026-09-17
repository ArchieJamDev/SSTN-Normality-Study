# 99_aggregate_results.R
# Descarga todos los artifacts de los jobs del matrix de GitHub Actions (o lee
# simulations/results/ directamente si se corrio local/en esta maquina),
# consolida en tablas resumen (tasa de rechazo por prueba x distribucion x n,
# y por prueba x subescala x n para el bloque de datos reales) listas para el
# manuscrito.

source("R/00_setup.R")

# TODO: leer todos los CSV de simulations/results/
# TODO: consolidar en tabla(s) resumen
# TODO: exportar a notes/ o directo a formato para el manuscrito (Overleaf)
