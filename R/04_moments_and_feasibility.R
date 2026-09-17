# 04_moments_and_feasibility.R
# Para cada una de las 11 subescalas (data/processed/), calcula asimetria y
# curtosis muestral sobre el N completo, y chequea factibilidad bajo Fleishman
# (SimMultiCorrData) y bajo GLD (gld, ajuste por momentos-L).
#
# Salida: notes/feasibility_table.csv con columnas
#   dataset, subescala, N, asimetria, curtosis, factible_fleishman,
#   factible_gld, metodo_elegido
#
# Regla de decision (ver DESIGN.md seccion 3): si todos los puntos son
# factibles bajo un solo metodo, usar ESE metodo para las 11 subescalas
# (consistencia interna). Si ninguno cubre todo, respaldo: metodo de quinto
# orden de Headrick (tambien en SimMultiCorrData).

source("R/00_setup.R")

# TODO: leer data/processed/*_subscales.csv
# TODO: calcular asimetria/curtosis (moments::skewness / moments::kurtosis,
#       ojo con la convencion de curtosis en exceso vs. curtosis cruda)
# TODO: SimMultiCorrData::calc_valid_pdf_skew_kurt() o equivalente para Fleishman
# TODO: gld::fit.fkml() / ajuste por momentos-L para GLD, chequear rango valido
# TODO: escribir notes/feasibility_table.csv
