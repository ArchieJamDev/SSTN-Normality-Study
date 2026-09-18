# 00b_pilot_sstn_timing.R
# Piloto: instala los paquetes objetivo, inspecciona la API real de sstn, y
# mide tiempos de calibracion/test a varios n. Pensado para correr como job
# de GitHub Actions (ver .github/workflows/simulate.yml, job "pilot-timing"),
# no localmente ni en el entorno en la nube de Claude (sin acceso a CRAN).
#
# Escribe todo a notes/pilot_sstn_timing.txt ademas de la consola, para que
# quede como artifact del job.

pkgs <- c("sstn", "nortest", "moments", "tseries", "fBasics", "gld", "SimMultiCorrData")
installed <- rownames(installed.packages())
to_install <- setdiff(pkgs, installed)
if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}
invisible(lapply(pkgs, library, character.only = TRUE))

dir.create("notes", showWarnings = FALSE)
log_con <- file("notes/pilot_sstn_timing.txt", open = "wt")
sink(log_con, split = TRUE)  # split=TRUE: tambien va a consola (log del job)

cat("=== Version de sstn ===\n")
print(packageVersion("sstn"))

cat("\n=== Funciones exportadas por sstn ===\n")
print(ls("package:sstn"))

set.seed(20260918)

cat("\n=== Prueba minima: n=50, datos normales ===\n")
x <- rnorm(50)
# NOTA: ajustar el nombre real de la funcion segun lo que muestre ls() arriba
# si sstn.test no es el nombre correcto.
result <- tryCatch(sstn::sstn.test(x), error = function(e) {
  cat("sstn::sstn.test no existe o fallo:", conditionMessage(e), "\n")
  NULL
})
print(result)
cat("\nEstructura del objeto devuelto:\n")
str(result)

cat("\n=== Tiempos de calibracion/test por n ===\n")
ns <- c(10, 25, 50, 100, 250, 500)
tiempos <- sapply(ns, function(n) {
  xx <- rnorm(n)
  t <- system.time(sstn::sstn.test(xx))
  t[["elapsed"]]
})
names(tiempos) <- ns
print(tiempos)

cat("\n=== Version de R y sesion ===\n")
print(sessionInfo())

sink()
close(log_con)
