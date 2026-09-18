# 03_extract_real_subscales.R
#
# Extrae los puntajes de subescala de las 4 bases reales (data/raw/*.zip,
# cada una del catalogo de datos crudos de openpsychometrics.org, NO paquetes
# de CRAN — ver notes/DESIGN.md seccion 5) y los deja en data/processed/ como
# un CSV por dataset, una columna por subescala, un renglon por respondente
# valido para esa subescala.
#
# Estos puntajes reales alimentan a 04_moments_and_feasibility.R (asimetria y
# curtosis empiricas de cada subescala -> objetivo de calibracion) y a
# 07_real_data_subsampling.R (remuestreo m-de-N sobre los datos reales).
#
# Las 4 bases y sus subescalas (11 en total, ver notes/DESIGN.md seccion 5):
#   DASS  (data/raw/DASS_data_21.02.19.zip)     -> Depression, Anxiety, Stress
#   RIASEC(data/raw/RIASEC_data12Dec2018.zip)   -> R, I, A, S, E, C
#   MACH  (data/raw/MACH_data.zip)              -> Machiavellianism (unidim.)
#   RSE   (data/raw/RSE.zip)                    -> Self-Esteem (unidim.)
#
# Los 4 archivos data.csv adentro de los zip son delimitados por TAB (a pesar
# de la extension .csv) — confirmado inspeccionando los datos crudos.
#
# Claves de puntuacion, todas confirmadas contra el codebook.txt de cada zip
# (DASS) o contra fuentes citadas abajo (MACH-IV, RSE):
#
#   DASS-42 (escala Q1A..Q42A, Likert 1-4, SIN items invertidos):
#     Depression = {3,5,10,13,16,17,21,24,26,31,34,37,38,42}
#     Anxiety    = {2,4,7,9,15,19,20,23,25,28,30,36,40,41}
#     Stress     = {1,6,8,11,12,14,18,22,27,29,32,33,35,39}
#     (clave estandar DASS-42; Lovibond & Lovibond, 1995)
#
#   RIASEC (columnas R1-R8, I1-I8, A1-A8, S1-S8, E1-E8, C1-C8, Likert 1-5,
#     SIN items invertidos, confirmado en codebook.txt): 6 subescalas de 8
#     items cada una, suma directa.
#
#   MACH-IV (columnas Q1A..Q20A, Likert 1-5, WITH items invertidos):
#     Items invertidos = {3,4,6,7,9,10,11,14,16,17}
#     (clave de reversion confirmada via checkpsych.com/tests/mach-iv/, que
#     cita expresamente la lista de items a invertir; contenido de cada item
#     cruzado manualmente contra la direccion de reversion esperada — ver
#     notes/DESIGN.md seccion 5)
#     Puntaje total unidimensional = suma de los 20 items (invertidos donde
#     corresponda).
#
#   RSE (columnas Q1-Q10, Likert 1-4, 0 = no contesto, WITH items invertidos):
#     Items invertidos = {3,5,8,9,10}
#     (clave estandar Rosenberg 1965; confirmada via
#     socy.umd.edu/about-us/using-rosenberg-self-esteem-scale)
#     Puntaje total unidimensional = suma de los 10 items.

source("R/00_setup.R")

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

#' Lee el data.csv (separado por TAB) que esta dentro de un .zip crudo.
read_zip_csv <- function(zip_path, csv_name = "data.csv") {
  entries <- utils::unzip(zip_path, list = TRUE)$Name
  target <- entries[basename(entries) == csv_name]
  stopifnot(length(target) == 1)
  con <- unz(zip_path, target)
  on.exit(close(con))
  readr::read_tsv(
    con,
    col_types = readr::cols(.default = readr::col_character()),
    na = c("", "NA", "NULL"),
    progress = FALSE
  )
}

#' Puntaje de subescala: suma de items, con reversion opcional, exigiendo
#' caso completo en los items de esa subescala (sin promediar con datos
#' parciales, para no sesgar la forma de la distribucion).
#'
#' @param df data.frame ya leido (columnas caracter)
#' @param items nombres de columna de los items de esta subescala
#' @param reverse_items subconjunto de `items` a invertir (o character(0))
#' @param min_val,max_val rango Likert valido (fuera de rango -> NA)
#' @return vector numerico de puntajes totales, un valor por caso completo
score_subscale <- function(df, items, reverse_items = character(0),
                            min_val, max_val) {
  mat <- sapply(items, function(it) {
    v <- suppressWarnings(as.numeric(df[[it]]))
    v[v < min_val | v > max_val] <- NA_real_
    if (it %in% reverse_items) v <- (min_val + max_val) - v
    v
  })
  complete <- stats::complete.cases(mat)
  rowSums(mat[complete, , drop = FALSE])
}

# --- DASS --------------------------------------------------------------

cat("=== DASS ===\n")
dass_raw <- read_zip_csv("data/raw/DASS_data_21.02.19.zip")

dass_items <- function(nums) paste0("Q", nums, "A")

dass_depression <- score_subscale(
  dass_raw, dass_items(c(3,5,10,13,16,17,21,24,26,31,34,37,38,42)),
  min_val = 1, max_val = 4
)
dass_anxiety <- score_subscale(
  dass_raw, dass_items(c(2,4,7,9,15,19,20,23,25,28,30,36,40,41)),
  min_val = 1, max_val = 4
)
dass_stress <- score_subscale(
  dass_raw, dass_items(c(1,6,8,11,12,14,18,22,27,29,32,33,35,39)),
  min_val = 1, max_val = 4
)

cat(sprintf("  Depression: n=%d\n", length(dass_depression)))
cat(sprintf("  Anxiety:    n=%d\n", length(dass_anxiety)))
cat(sprintf("  Stress:     n=%d\n", length(dass_stress)))

readr::write_csv(
  data.frame(depression = dass_depression),
  "data/processed/dass_depression.csv"
)
readr::write_csv(
  data.frame(anxiety = dass_anxiety),
  "data/processed/dass_anxiety.csv"
)
readr::write_csv(
  data.frame(stress = dass_stress),
  "data/processed/dass_stress.csv"
)

# --- RIASEC --------------------------------------------------------------

cat("=== RIASEC ===\n")
riasec_raw <- read_zip_csv("data/raw/RIASEC_data12Dec2018.zip")

riasec_dims <- list(
  realistic     = paste0("R", 1:8),
  investigative = paste0("I", 1:8),
  artistic      = paste0("A", 1:8),
  social        = paste0("S", 1:8),
  enterprising  = paste0("E", 1:8),
  conventional  = paste0("C", 1:8)
)

for (dim_name in names(riasec_dims)) {
  scores <- score_subscale(
    riasec_raw, riasec_dims[[dim_name]], min_val = 1, max_val = 5
  )
  cat(sprintf("  %s: n=%d\n", dim_name, length(scores)))
  readr::write_csv(
    stats::setNames(data.frame(scores), dim_name),
    sprintf("data/processed/riasec_%s.csv", dim_name)
  )
}

# --- MACH-IV --------------------------------------------------------------

cat("=== MACH-IV ===\n")
mach_raw <- read_zip_csv("data/raw/MACH_data.zip")

mach_items <- paste0("Q", 1:20, "A")
mach_reverse <- paste0("Q", c(3,4,6,7,9,10,11,14,16,17), "A")

mach_total <- score_subscale(
  mach_raw, mach_items, reverse_items = mach_reverse,
  min_val = 1, max_val = 5
)
cat(sprintf("  Machiavellianism (total): n=%d\n", length(mach_total)))
readr::write_csv(
  data.frame(machiavellianism = mach_total),
  "data/processed/mach_total.csv"
)

# --- RSE --------------------------------------------------------------

cat("=== RSE ===\n")
rse_raw <- read_zip_csv("data/raw/RSE.zip")

rse_items <- paste0("Q", 1:10)
rse_reverse <- paste0("Q", c(3,5,8,9,10))

rse_total <- score_subscale(
  rse_raw, rse_items, reverse_items = rse_reverse,
  min_val = 1, max_val = 4
)
cat(sprintf("  Self-Esteem (total): n=%d\n", length(rse_total)))
readr::write_csv(
  data.frame(self_esteem = rse_total),
  "data/processed/rse_total.csv"
)

cat("\nListo. 11 archivos escritos en data/processed/.\n")
