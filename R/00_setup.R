# 00_setup.R
# Instala/carga los paquetes necesarios para todo el proyecto.
# ES: correr una sola vez por máquina/runner antes de cualquier otro script.

pkgs <- c(
  "sstn",             # SSTN (Anarat & Schwender 2026)
  "nortest",          # Lilliefors, Anderson-Darling, Cramér-von Mises, Shapiro-Francia, Pearson chi^2
  "moments",          # Jarque-Bera, asimetria, curtosis
  "tseries",          # Jarque-Bera (alternativa)
  "fBasics",          # D'Agostino-Pearson (dagoTest) y utilidades de momentos
  "nortsTest",        # Epps-Pulley (epps.test), basada en la funcion caracteristica empirica
  "gld",              # Distribucion lambda generalizada (Ramberg-Schmeiser / FKML), ajuste por momentos-L
  "SimMultiCorrData", # Metodo de potencias de Fleishman + extension de quinto orden de Headrick, chequeo de factibilidad
  "dplyr",
  "purrr",
  "tidyr",
  "readr"
)

installed <- rownames(installed.packages())
to_install <- setdiff(pkgs, installed)
if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

invisible(lapply(pkgs, library, character.only = TRUE))

cat("Paquetes listos:\n")
print(pkgs)
