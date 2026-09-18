# 06_sstn_null_calibration.R
#
# OBSOLETO tal como se concibio originalmente — ver notes/DESIGN.md seccion 10
# (piloto real del 18 sep 2026).
#
# La premisa era que la nula del SSTN habia que calibrarla y cachearla aparte
# para no recalcularla en cada replica. El piloto real mostro que
# sstn::sstn(x) calibra internamente en cada llamada (finito para n chico,
# asintotico para n grande) y aun asi tarda 4-9 milisegundos por llamada —
# R=10.000 replicas en un solo n toma menos de 1 minuto. No hace falta
# ninguna capa externa de cache.
#
# 08_run_battery.R llama sstn::sstn(x) directo, igual que cualquier otra
# prueba de la bateria. Este archivo se deja como referencia historica del
# analisis, no se usa en el pipeline.
