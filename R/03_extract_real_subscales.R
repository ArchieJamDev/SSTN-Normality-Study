# 03_extract_real_subscales.R
# Extrae los puntajes de subescala de los 4 datasets reales en data/raw/ y los
# guarda en data/processed/ (un CSV por dataset, una columna por subescala + N).
#
# Datasets y claves de correccion (ver DESIGN.md seccion 5 y los codebook.txt
# incluidos en cada zip de data/raw/):
#
#   DASS (data/raw/DASS_data_21.02.19.zip) — 42 items Likert 1-4 (Q1A..Q42A).
#     Claves estandar DASS-42 (14 items por subescala):
#       Depresion: 3,5,10,13,16,17,21,24,26,31,34,37,38,42
#       Ansiedad:   2,4,7,9,15,19,20,23,25,28,30,36,40,41
#       Estres:     1,6,8,11,12,14,18,22,27,29,32,33,35,39
#
#   RIASEC (data/raw/RIASEC_data12Dec2018.zip) — 48 items, 6 subescalas.
#     TODO: confirmar mapeo item->subescala contra codebook.txt del zip.
#
#   MACH-IV (data/raw/MACH_data.zip) — 20 items, unidimensional.
#     TODO: confirmar items inversos contra codebook.txt.
#
#   RSE (data/raw/RSE.zip) — 10 items, unidimensional.
#     TODO: confirmar items inversos (RSE tiene items redactados en negativo).
#
# IMPORTANTE: la asimetria/curtosis objetivo para el Bloque 3 (calibracion
# plasmode) se calculan sobre el N COMPLETO de cada dataset, no sobre una
# submuestra — ver DESIGN.md seccion 3.

source("R/00_setup.R")

# TODO: unzip + read.csv de cada dataset (data.table::fread recomendado, son
#       archivos de 20-30MB descomprimidos)
# TODO: aplicar claves de correccion (incluyendo reversion de items inversos)
# TODO: guardar data/processed/<dataset>_subscales.csv
