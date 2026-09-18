# 00b_pilot_sstn_timing.R
# Piloto: instala los paquetes objetivo, inspecciona la API real de sstn, y
# mide tiempos de calibracion/test a varios n. Pensado para correr como job
# de GitHub Actions (ver .github/workflows/simulate.yml, job "pilot-timing"),
# no localmente ni en el entorno en la nube de Claude (sin acceso a CRAN).
#
# Escribe todo a notes/pilot_sstn_timing.txt ademas de la consola, para que
# quede como artifact del job.
#
# NOTA (confirmado en la primera corrida real): el paquete sstn exporta un
# UNICO objeto, llamado igual que el paquete -> sstn::sstn(), no sstn.test().

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

cat("\n=== Argumentos de sstn::sstn ===\n")
print(args(sstn::sstn))

set.seed(20260918)

cat("\n=== Prueba minima: n=50, datos normales ===\n")
x <- rnorm(50)
result <- tryCatch(sstn::sstn(x), error = function(e) {
  cat("sstn::sstn fallo:", conditionMessage(e), "\n")
  NULL
})
print(result)
cat("\nEstructura del objeto devuelto:\n")
str(result)

cat("\n=== Prueba minima: n=50, datos NO normales (exponencial), para ver rechazo ===\n")
xe <- rexp(50)
result_exp <- tryCatch(sstn::sstn(xe), error = function(e) {
  cat("sstn::sstn fallo:", conditionMessage(e), "\n")
  NULL
})
print(result_exp)

cat("\n=== Tiempos por n (una sola corrida por n, datos normales) ===\n")
ns <- c(10, 25, 50, 100, 250, 500)
tiempos <- sapply(ns, function(n) {
  xx <- rnorm(n)
  t <- system.time(sstn::sstn(xx))
  t[["elapsed"]]
})
names(tiempos) <- ns
print(tiempos)

cat("\n=== Tiempos por n (promedio de 5 corridas, para estimar mejor) ===\n")
tiempos_prom <- sapply(ns, function(n) {
  ts <- replicate(5, {
    xx <- rnorm(n)
    system.time(sstn::sstn(xx))[["elapsed"]]
  })
  mean(ts)
})
names(tiempos_prom) <- ns
print(tiempos_prom)
cat("\nProyeccion a R=10000 replicas por celda (minutos):\n")
print(round(tiempos_prom * 10000 / 60, 1))

cat("\n=== Version de R y sesion ===\n")
print(sessionInfo())

sink()
close(log_con)
