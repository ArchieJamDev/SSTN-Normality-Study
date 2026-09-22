# 09c_consolidar_calibracion_extendida.R
#
# Concatena los 12 CSV de calibracion producidos por el job
# calibrate-categorias-extendido (uno por escenario, R/09b_calibrar_extension_bloque5.R)
# en un solo data/results/calibracion_categorias_extendida.csv --
# R/09_calibration_categorias.R lo lee automaticamente al cargarse y fusiona
# sus filas con la tabla hardcodeada original (A_simetrica/B1/B2, k=3..6),
# sin tocarla.
#
# Uso (despues de descargar los 12 artifacts calibracion-categorias-<escenario>
# a data/results/, ej. con `gh run download <run-id> -p "calibracion-categorias-*"
# -D data/results`, aplanando el nombre del artifact si hace falta):
#   Rscript R/09c_consolidar_calibracion_extendida.R

archivos <- list.files("data/results", pattern = "^calibracion_categorias_(A_simetrica|B1_|B2_|C[1-9]_).*\\.csv$", full.names = TRUE)
# Excluye explicitamente el propio archivo consolidado si ya existiera de una
# corrida anterior (para no auto-incluirse al re-correr este script).
archivos <- archivos[basename(archivos) != "calibracion_categorias_extendida.csv"]

if (length(archivos) == 0) {
  stop("No se encontraron CSV de calibracion en data/results/ (esperado: calibracion_categorias_<escenario>.csv). Descarga primero los artifacts del job calibrate-categorias-extendido.")
}

cat(sprintf("Consolidando %d archivos:\n", length(archivos)))
cat(paste(" -", basename(archivos)), sep = "\n")

tablas <- lapply(archivos, readr::read_csv, show_col_types = FALSE)
consolidado <- dplyr::bind_rows(tablas)

# Chequeo de sanidad: sin duplicados de (escenario, k), y todas las celdas
# esperadas de la ampliacion presentes.
dup <- consolidado[duplicated(consolidado[, c("escenario", "k")]), c("escenario", "k")]
if (nrow(dup) > 0) {
  print(dup)
  stop("Hay pares (escenario, k) duplicados en la consolidacion -- revisar antes de commitear.")
}

esperadas_ampliacion <- c(7, 8)
esperadas_nuevas <- 3:8
escenarios_publicados <- c("A_simetrica", "B1_riasec_realistic", "B2_dass_depression")
escenarios_nuevos <- sprintf("C%d_%s", 1:9, c(
  "dass_anxiety", "dass_stress", "mach_total", "riasec_artistic",
  "riasec_conventional", "riasec_enterprising", "riasec_investigative",
  "riasec_social", "rse_total"
))

faltantes <- character(0)
for (esc in escenarios_publicados) {
  ks <- consolidado$k[consolidado$escenario == esc]
  falt <- setdiff(esperadas_ampliacion, ks)
  if (length(falt) > 0) faltantes <- c(faltantes, sprintf("%s: k=%s", esc, paste(falt, collapse = ",")))
}
for (esc in escenarios_nuevos) {
  ks <- consolidado$k[consolidado$escenario == esc]
  falt <- setdiff(esperadas_nuevas, ks)
  if (length(falt) > 0) faltantes <- c(faltantes, sprintf("%s: k=%s", esc, paste(falt, collapse = ",")))
}
if (length(faltantes) > 0) {
  cat("AVISO -- faltan celdas de la ampliacion (revisa si algun shard del job fallo):\n")
  cat(paste(" -", faltantes), sep = "\n")
} else {
  cat("OK -- las 60 celdas nuevas de la ampliacion estan completas (2x3 + 9x6).\n")
}

readr::write_csv(consolidado, "data/results/calibracion_categorias_extendida.csv")
cat(sprintf("\nGuardado data/results/calibracion_categorias_extendida.csv (%d filas)\n", nrow(consolidado)))
cat("Listo -- commitea este archivo antes de correr simulate-categorias con la matrix ampliada.\n")
