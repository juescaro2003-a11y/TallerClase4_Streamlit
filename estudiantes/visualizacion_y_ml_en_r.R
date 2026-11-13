# ==============================================================================
#  VISUALIZACIÓN DE DATOS Y APRENDIZAJE AUTOMÁTICO CON R
#  Material de trabajo - Herramientas de visualización de datos
# ==============================================================================
#
#  INSTRUCCIONES
#   1. Ejecutar la sección 1.1 (instalación y carga de paquetes). La instalación
#      solo es necesaria la primera vez; la carga, en cada sesión.
#   2. Ejecutar el resto del archivo en orden, de arriba hacia abajo, porque cada
#      sección utiliza objetos creados en las anteriores.
#   3. Ejecutar una línea o un bloque seleccionado: Ctrl+Enter.
#   4. Ir a una sección: Ctrl+Shift+O (índice del documento).
#
#  Los datos de clientes son simulados. Los mapas usan el conjunto quakes de R.
#  La aplicación Shiny se encuentra en el archivo independiente app.R.
# ==============================================================================

# ============================================================================
# 1. Preparación del entorno -----------------------------------------------
# ============================================================================

# 1.1 Paquetes utilizados ---------------------------------------------------
# Instalación: necesaria una sola vez (instala únicamente los paquetes faltantes).
paquetes_necesarios <- c("tidyverse", "plotly", "patchwork", "ggrepel",
                         "scales", "corrplot", "GGally", "viridis",
                         "rpart", "shiny", "leaflet")

paquetes_faltantes <- paquetes_necesarios[
  !(paquetes_necesarios %in% installed.packages()[, "Package"])
]

if (length(paquetes_faltantes) > 0) {
  install.packages(paquetes_faltantes, repos = "https://cloud.r-project.org")
}

# Carga de paquetes: se ejecuta en cada sesión de trabajo.
library(tidyverse)
library(plotly)
library(leaflet)
library(patchwork)
library(ggrepel)
library(scales)
library(corrplot)
library(GGally)
library(viridis)
library(rpart)

# ============================================================================
# 2. Datos de ejemplo ------------------------------------------------------
# ============================================================================

# 2.1 Estructura de los datos -----------------------------------------------
set.seed(42)

clientes <- data.frame(
  cliente         = sprintf("C%03d", 1:180),
  grupo_verdadero = factor(rep(c("Ocasional", "Regular", "Frecuente"), each = 60),
                           levels = c("Ocasional", "Regular", "Frecuente")),
  compras         = c(rpois(60, 4), rpois(60, 10), rpois(60, 17)),
  gasto_medio     = c(rnorm(60, 100, 15), rnorm(60, 50, 10), rnorm(60, 25, 6)),
  edad            = round(c(rnorm(60, 45, 8), rnorm(60, 35, 8), rnorm(60, 27, 6))),
  canal           = sample(c("App", "Web", "Tienda"), 180, replace = TRUE)
)

clientes$gasto_medio <- pmax(clientes$gasto_medio, 5)
clientes$gasto_total <- clientes$compras * clientes$gasto_medio

# 2.2 Variable de mora simulada ---------------------------------------------
# Generación de la variable de mora (tres pasos):
#   1. Predictor lineal: puntaje que combina edad y compras.
#   2. Función logística plogis(): convierte el puntaje en probabilidad (0 a 1).
#   3. rbinom(): simula el resultado 0/1 con esa probabilidad (ensayo de Bernoulli).
predictor_lineal       <- 0.12 * (35 - clientes$edad) + 0.05 * (clientes$compras - 10)
probabilidad_mora_real <- plogis(predictor_lineal)
clientes$mora_binaria  <- rbinom(n = 180, size = 1, prob = probabilidad_mora_real)

table(clientes$mora_binaria)

# 2.3 Serie temporal de ventas ----------------------------------------------
ventas_mensuales <- data.frame(
  mes    = seq(as.Date("2025-01-01"), by = "month", length.out = 12),
  ventas = c(120, 135, 128, 150, 160, 155, 170, 185, 180, 200, 230, 260)
)

head(clientes)
glimpse(clientes)

# ============================================================================
# 3. Primeros ejemplos de visualización ------------------------------------
# ============================================================================

# 3.1 Gráficos con R base --------------------------------------------------
# Cuatro vistas de los mismos datos en una cuadrícula de dos filas y dos columnas.
par(mfrow = c(2, 2))

plot(clientes$compras, clientes$gasto_medio,
     main = "plot(): dispersión", xlab = "Compras", ylab = "Gasto medio",
     pch = 19, col = "steelblue")

hist(clientes$gasto_medio,
     main = "hist(): histograma", xlab = "Gasto medio",
     breaks = 12, col = "gold", border = "white")

boxplot(gasto_medio ~ grupo_verdadero, data = clientes,
        main = "boxplot(): diagrama de caja", xlab = "Perfil", ylab = "Gasto medio",
        col = c("tomato", "gold", "skyblue"))

barplot(table(clientes$canal),
        main = "barplot(): frecuencias", col = c("#187D80", "#E8A33D", "grey60"))

par(mfrow = c(1, 1))

# 3.2 Mapas con Leaflet -----------------------------------------------------
# quakes incluye coordenadas de sismos en la región de Fiyi. El mapa de fondo
# de addTiles() requiere conexión a internet.

# Ejemplo 1. Un punto por sismo. Haz clic para ver magnitud y profundidad.
sismos <- subset(datasets::quakes, mag >= 5.5)

mapa_sismos <- leaflet(sismos) |>
  addTiles() |>
  addCircleMarkers(lng = ~long, lat = ~lat, radius = 6,
                   popup = ~paste("Magnitud:", mag, "| Profundidad:", depth, "km"))
if (interactive()) print(mapa_sismos)

# Ejemplo 2. Colorea los sismos por magnitud y añade una leyenda.
paleta_magnitud <- colorNumeric("YlOrRd", domain = sismos$mag)

mapa_magnitud <- leaflet(sismos) |>
  addTiles() |>
  addCircleMarkers(lng = ~long, lat = ~lat, radius = 7,
                   color = ~paleta_magnitud(mag), stroke = FALSE, fillOpacity = 0.9) |>
  addLegend(position = "bottomright", pal = paleta_magnitud,
            values = ~mag, title = "Magnitud")
if (interactive()) print(mapa_magnitud)

# 3.3 Componer y resumir con patchwork y corrplot ----------------------------
# patchwork reúne dos gráficos de ggplot2 en un panel.
puntos_inicio <- ggplot(clientes, aes(compras, gasto_medio)) +
  geom_point(alpha = 0.5) +
  labs(x = "Compras", y = "Gasto medio")

cajas_inicio <- ggplot(clientes, aes(grupo_verdadero, gasto_medio)) +
  geom_boxplot() +
  labs(x = "Perfil", y = "Gasto medio")

print(puntos_inicio | cajas_inicio)  # Lado a lado
print(puntos_inicio / cajas_inicio)  # Uno encima del otro

# corrplot resume la asociación lineal entre tres variables numéricas.
# El color indica el signo y el tamaño del círculo indica la fuerza.
correlaciones_inicio <- cor(clientes[, c("compras", "gasto_medio", "edad")])
corrplot(correlaciones_inicio, method = "circle", tl.col = "black")


# ============================================================================
# 4. Visualización con ggplot2 ---------------------------------------------
# ============================================================================

# 4.1 Diagrama de dispersión ------------------------------------------------
# Propósito: representar la relación entre dos variables cuantitativas y
# detectar patrones, agrupaciones o valores atípicos.
grafico_puntos <- ggplot(clientes, aes(x = compras, y = gasto_medio,
                                       color = grupo_verdadero)) +
  geom_point(alpha = 0.6, size = 2) +
  labs(title = "Compras y gasto medio por cliente",
       x = "Compras en el periodo",
       y = "Gasto promedio por compra",
       color = "Perfil") +
  theme_minimal(base_size = 13)

print(grafico_puntos)

# 4.2 Gráfico de líneas -----------------------------------------------------
# Propósito: mostrar la evolución de una variable a lo largo del tiempo.
grafico_lineas <- ggplot(ventas_mensuales, aes(x = mes, y = ventas)) +
  geom_line(linewidth = 1, color = "#187D80") +
  geom_point(size = 3, color = "#187D80") +
  scale_x_date(date_labels = "%b", date_breaks = "1 month") +
  labs(title = "Ventas mensuales", x = "Mes", y = "Ventas") +
  theme_minimal(base_size = 13)

print(grafico_lineas)

# 4.3 Gráfico de barras con valores calculados ------------------------------
# Propósito: comparar una medida resumen entre categorías.
gasto_promedio_por_grupo <- clientes %>%
  group_by(grupo_verdadero) %>%
  summarise(gasto_promedio = mean(gasto_medio))

grafico_barras_valores <- ggplot(gasto_promedio_por_grupo,
                                 aes(x = grupo_verdadero, y = gasto_promedio,
                                     fill = grupo_verdadero)) +
  geom_col(show.legend = FALSE) +
  labs(title = "Gasto promedio por perfil", x = "Perfil", y = "Gasto promedio") +
  theme_minimal(base_size = 13)

print(grafico_barras_valores)

# 4.4 Gráfico de barras de frecuencias --------------------------------------
# Propósito: mostrar cuántas observaciones hay en cada categoría.
grafico_barras_conteo <- ggplot(clientes, aes(x = canal)) +
  geom_bar(fill = "#E8A33D") +
  labs(title = "Clientes por canal", x = "Canal", y = "Número de clientes") +
  theme_minimal(base_size = 13)

print(grafico_barras_conteo)

# 4.5 Histograma ------------------------------------------------------------
# Propósito: describir la distribución de una variable cuantitativa: forma,
# centro, dispersión y asimetría.
grafico_histograma <- ggplot(clientes, aes(x = gasto_medio)) +
  geom_histogram(bins = 20, fill = "#187D80", color = "white") +
  labs(title = "Distribución del gasto medio",
       x = "Gasto medio", y = "Número de clientes") +
  theme_minimal(base_size = 13)

print(grafico_histograma)

# 4.6 Gráfico de densidad ---------------------------------------------------
# Propósito: estimar de forma suavizada la distribución de una variable;
# resulta útil para comparar grupos.
grafico_densidad <- ggplot(clientes, aes(x = gasto_medio, fill = grupo_verdadero)) +
  geom_density(alpha = 0.4) +
  labs(title = "Densidad del gasto medio por perfil",
       x = "Gasto medio", y = "Densidad", fill = "Perfil") +
  theme_minimal(base_size = 13)

print(grafico_densidad)

# 4.7 Diagrama de caja ------------------------------------------------------
# Propósito: resumir una distribución mediante cinco medidas y comparar
# grupos.
grafico_boxplot <- ggplot(clientes, aes(x = grupo_verdadero, y = gasto_medio,
                                        fill = grupo_verdadero)) +
  geom_boxplot(show.legend = FALSE) +
  labs(title = "Gasto medio por perfil", x = "Perfil", y = "Gasto medio") +
  theme_minimal(base_size = 13)

print(grafico_boxplot)

# 4.8 Diagrama de violín ----------------------------------------------------
# Propósito: como el diagrama de caja, pero muestra además la forma de la
# distribución.
grafico_violin <- ggplot(clientes, aes(x = grupo_verdadero, y = gasto_medio,
                                       fill = grupo_verdadero)) +
  geom_violin(alpha = 0.7, show.legend = FALSE) +
  geom_jitter(width = 0.1, alpha = 0.3, size = 1) +
  labs(title = "Distribución del gasto medio por perfil",
       x = "Perfil", y = "Gasto medio") +
  theme_minimal(base_size = 13)

print(grafico_violin)

# 4.9 Paneles por categoría (facetas) ---------------------------------------
# Propósito: comparar un mismo gráfico entre subconjuntos de datos.
grafico_facetas <- grafico_puntos +
  facet_wrap(~ canal) +
  labs(title = "Compras y gasto medio según canal")

print(grafico_facetas)

# 4.10 Mapa de calor ---------------------------------------------------------
# Propósito: representar la magnitud de los valores de una tabla mediante
# intensidad de color.
conteo_canal_grupo <- count(clientes, canal, grupo_verdadero)

grafico_mapa_calor <- ggplot(conteo_canal_grupo,
                             aes(x = grupo_verdadero, y = canal, fill = n)) +
  geom_tile(color = "white") +
  geom_text(aes(label = n), size = 6) +
  scale_fill_gradient(low = "white", high = "#187D80") +
  labs(title = "Clientes por canal y perfil",
       x = "Perfil", y = "Canal", fill = "Clientes") +
  theme_minimal(base_size = 13)

print(grafico_mapa_calor)

# 4.11 Línea de tendencia ----------------------------------------------------
# Propósito: resumir la relación general entre dos variables.
grafico_tendencia <- ggplot(clientes, aes(x = compras, y = gasto_medio)) +
  geom_point(alpha = 0.5, color = "grey40") +
  geom_smooth(method = "lm", se = TRUE, color = "red", fill = "pink") +
  labs(title = "Tendencia lineal entre compras y gasto medio",
       x = "Compras", y = "Gasto medio") +
  theme_minimal(base_size = 13)

print(grafico_tendencia)

# 4.12 Barras horizontales ---------------------------------------------------
grafico_barras_horizontales <- ggplot(gasto_promedio_por_grupo,
                                      aes(x = grupo_verdadero, y = gasto_promedio)) +
  geom_col(fill = "#187D80") +
  coord_flip() +
  labs(title = "Barras horizontales", x = NULL, y = "Gasto promedio") +
  theme_minimal(base_size = 13)

print(grafico_barras_horizontales)

# ============================================================================
# 5. Gráficos interactivos con plotly --------------------------------------
# ============================================================================

# 1. Conversión directa de un gráfico de ggplot2
ggplotly(grafico_puntos)

# 2. Construcción con plot_ly()
plot_ly(clientes, x = ~compras, y = ~gasto_medio, color = ~grupo_verdadero,
        type = "scatter", mode = "markers")

# 3. Gráfico tridimensional
plot_ly(clientes, x = ~compras, y = ~gasto_medio, z = ~edad,
        color = ~grupo_verdadero, type = "scatter3d", mode = "markers",
        marker = list(size = 3))

# ============================================================================
# 6. Composición de gráficos con patchwork ---------------------------------
# ============================================================================

grafico_puntos | grafico_histograma

(grafico_puntos | grafico_densidad) / grafico_boxplot

(grafico_puntos | grafico_boxplot) +
  plot_annotation(title = "Composición de dos gráficos")

# ============================================================================
# 7. Etiquetas sin superposición con ggrepel -------------------------------
# ============================================================================

clientes_mayor_gasto <- clientes[order(-clientes$gasto_total)[1:8], ]

grafico_etiquetas <- ggplot(clientes, aes(x = compras, y = gasto_total)) +
  geom_point(alpha = 0.4, color = "grey50") +
  geom_point(data = clientes_mayor_gasto, color = "red", size = 3) +
  geom_text_repel(data = clientes_mayor_gasto, aes(label = cliente)) +
  labs(title = "Ocho clientes con mayor gasto total",
       x = "Compras", y = "Gasto total") +
  theme_minimal(base_size = 13)

print(grafico_etiquetas)

# ============================================================================
# 8. Formato de escalas con scales -----------------------------------------
# ============================================================================

grafico_dinero <- ggplot(clientes, aes(x = compras, y = gasto_total)) +
  geom_point(color = "#187D80", alpha = 0.6) +
  scale_y_continuous(labels = label_dollar()) +
  labs(title = "Gasto total en dólares", x = "Compras", y = "Gasto total") +
  theme_minimal(base_size = 13)

print(grafico_dinero)

tasa_mora_por_canal <- clientes %>%
  group_by(canal) %>%
  summarise(tasa_mora = mean(mora_binaria))

grafico_porcentaje <- ggplot(tasa_mora_por_canal, aes(x = canal, y = tasa_mora)) +
  geom_col(fill = "#E8A33D") +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "Tasa de mora por canal", x = "Canal", y = "Tasa de mora") +
  theme_minimal(base_size = 13)

print(grafico_porcentaje)

# ============================================================================
# 9. Paletas de color con viridis ------------------------------------------
# ============================================================================

grafico_viridis_categorias <- grafico_puntos + scale_color_viridis_d()
print(grafico_viridis_categorias)

grafico_viridis_continuo <- ggplot(clientes, aes(x = compras, y = gasto_medio,
                                                 color = edad)) +
  geom_point(size = 2) +
  scale_color_viridis_c(option = "plasma") +
  labs(title = "Compras y gasto medio según la edad",
       x = "Compras", y = "Gasto medio", color = "Edad") +
  theme_minimal(base_size = 13)

print(grafico_viridis_continuo)

# ============================================================================
# 10. Matriz de correlación con corrplot ------------------------------------
# ============================================================================

matriz_correlacion <- cor(clientes[, c("compras", "gasto_medio", "edad", "gasto_total")])

corrplot(matriz_correlacion, method = "color", type = "upper",
         addCoef.col = "black", tl.col = "black")

# ============================================================================
# 11. Matriz de gráficos con GGally -----------------------------------------
# ============================================================================

ggpairs(clientes, columns = c("compras", "gasto_medio", "edad"),
        aes(color = grupo_verdadero, alpha = 0.5))

# ============================================================================
# 12. Aprendizaje automático ------------------------------------------------
# ============================================================================

# 12.1 Estandarización de variables ------------------------------------------
variables_escaladas <- scale(clientes[, c("compras", "gasto_medio", "edad")])

round(colMeans(variables_escaladas), 3)
round(apply(variables_escaladas, 2, sd), 3)

# 12.2 Método del codo -------------------------------------------------------
# Propósito: orientar la elección del número de grupos k en K-means.
set.seed(42)
suma_cuadrados_intra_grupos <- sapply(1:8, function(numero_grupos) {
  kmeans(variables_escaladas, centers = numero_grupos, nstart = 25)$tot.withinss
})

tabla_codo <- data.frame(numero_grupos = 1:8,
                         suma_cuadrados = suma_cuadrados_intra_grupos)

grafico_codo <- ggplot(tabla_codo, aes(x = numero_grupos, y = suma_cuadrados)) +
  geom_line(color = "#187D80", linewidth = 1) +
  geom_point(size = 3, color = "#187D80") +
  scale_x_continuous(breaks = 1:8) +
  labs(title = "Método del codo",
       subtitle = "El punto de inflexión sugiere k = 3",
       x = "Número de grupos (k)", y = "Suma de cuadrados intra-grupo") +
  theme_minimal(base_size = 13)

print(grafico_codo)

# 12.3 K-means ---------------------------------------------------------------
# Propósito: particionar las observaciones en k grupos de modo que las
# observaciones de un mismo grupo sean lo más parecidas posible entre sí.
set.seed(42)
modelo_kmeans <- kmeans(variables_escaladas, centers = 3, nstart = 25)
clientes$segmento_kmeans <- factor(modelo_kmeans$cluster)

centros_de_grupos <- clientes %>%
  group_by(segmento_kmeans) %>%
  summarise(compras = mean(compras), gasto_medio = mean(gasto_medio))

grafico_kmeans <- ggplot(clientes, aes(x = compras, y = gasto_medio,
                                       color = segmento_kmeans)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_point(data = centros_de_grupos, shape = 4, size = 6, stroke = 2,
             color = "black") +
  labs(title = "Segmentos obtenidos mediante K-means",
       x = "Compras", y = "Gasto medio", color = "Segmento") +
  theme_minimal(base_size = 13)

print(grafico_kmeans)

table(Perfil_real = clientes$grupo_verdadero,
      Segmento_encontrado = clientes$segmento_kmeans)

# 12.4 Análisis de componentes principales (PCA) -----------------------------
# Propósito: transformar un conjunto de variables correlacionadas en un
# conjunto menor de componentes principales no correlacionados, ordenados de
# mayor a menor varianza explicada. El primer componente (PC1) es la dirección
# de máxima variabilidad; el segundo (PC2) es la de máxima variabilidad entre
# las direcciones ortogonales a PC1, y así sucesivamente.
modelo_pca <- prcomp(variables_escaladas, center = TRUE, scale. = FALSE)

porcentaje_varianza <- round(100 * modelo_pca$sdev^2 / sum(modelo_pca$sdev^2), 1)
porcentaje_varianza

coordenadas_pca <- data.frame(modelo_pca$x[, 1:2],
                              segmento = clientes$segmento_kmeans)

flechas_variables <- data.frame(
  variable = rownames(modelo_pca$rotation),
  PC1 = modelo_pca$rotation[, 1] * 3,
  PC2 = modelo_pca$rotation[, 2] * 3
)

grafico_pca <- ggplot(coordenadas_pca, aes(x = PC1, y = PC2, color = segmento)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_segment(data = flechas_variables,
               aes(x = 0, y = 0, xend = PC1, yend = PC2),
               arrow = arrow(length = unit(0.2, "cm")),
               inherit.aes = FALSE, color = "black") +
  geom_text(data = flechas_variables,
            aes(x = PC1, y = PC2, label = variable),
            inherit.aes = FALSE, vjust = -0.5) +
  labs(title = "Clientes en el plano de los dos primeros componentes",
       x = paste0("PC1 (", porcentaje_varianza[1], " % de la varianza)"),
       y = paste0("PC2 (", porcentaje_varianza[2], " % de la varianza)"),
       color = "Segmento") +
  theme_minimal(base_size = 13)

print(grafico_pca)

tabla_varianza <- data.frame(componente = paste0("PC", seq_along(porcentaje_varianza)),
                             porcentaje = porcentaje_varianza)

grafico_varianza <- ggplot(tabla_varianza, aes(x = componente, y = porcentaje)) +
  geom_col(fill = "#187D80") +
  geom_text(aes(label = paste0(porcentaje, " %")), vjust = -0.3) +
  labs(title = "Varianza explicada por componente",
       x = NULL, y = "Porcentaje de la varianza") +
  theme_minimal(base_size = 13)

print(grafico_varianza)

# 12.5 Regresión lineal ------------------------------------------------------
# Propósito: modelar una respuesta numérica como función lineal de una o más
# variables predictoras, y cuantificar el efecto de cada una:
modelo_regresion <- lm(gasto_medio ~ compras + edad, data = clientes)
summary(modelo_regresion)

clientes$gasto_predicho <- predict(modelo_regresion)
clientes$residuo        <- residuals(modelo_regresion)

grafico_real_vs_predicho <- ggplot(clientes, aes(x = gasto_predicho, y = gasto_medio)) +
  geom_point(alpha = 0.5, color = "#187D80") +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Valores observados frente a valores predichos",
       x = "Gasto predicho", y = "Gasto observado") +
  theme_minimal(base_size = 13)

grafico_residuos <- ggplot(clientes, aes(x = gasto_predicho, y = residuo)) +
  geom_point(alpha = 0.5, color = "#E8A33D") +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  labs(title = "Residuos frente a valores predichos",
       x = "Gasto predicho", y = "Residuo") +
  theme_minimal(base_size = 13)

grafico_real_vs_predicho | grafico_residuos

# 12.6 Regresión logística ---------------------------------------------------
# Propósito: estimar la probabilidad de que ocurra un evento (por ejemplo,
# mora) en función de variables predictoras. Modela el logaritmo de las
# razones de probabilidad (*log-odds*) como función lineal:
set.seed(42)
filas_entrenamiento <- sample(1:nrow(clientes), size = round(0.7 * nrow(clientes)))
datos_entrenamiento <- clientes[filas_entrenamiento, ]
datos_prueba        <- clientes[-filas_entrenamiento, ]

modelo_logistico <- glm(mora_binaria ~ edad + compras + gasto_medio,
                        data = datos_entrenamiento, family = binomial)

summary(modelo_logistico)

datos_prueba$probabilidad_mora <- predict(modelo_logistico, newdata = datos_prueba,
                                          type = "response")
datos_prueba$prediccion_mora   <- ifelse(datos_prueba$probabilidad_mora >= 0.5, 1, 0)

grafico_probabilidades <- ggplot(datos_prueba,
                                 aes(x = probabilidad_mora,
                                     fill = factor(mora_binaria))) +
  geom_histogram(bins = 20, position = "identity", alpha = 0.6, color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed") +
  scale_fill_manual(values = c("0" = "#187D80", "1" = "#E8A33D"),
                    labels = c("Sin mora", "Con mora")) +
  labs(title = "Probabilidad de mora estimada por el modelo",
       x = "Probabilidad estimada", y = "Número de clientes", fill = "Resultado real") +
  theme_minimal(base_size = 13)

print(grafico_probabilidades)

# 12.7 Evaluación de un clasificador -----------------------------------------
matriz_confusion <- as.data.frame(table(
  Real     = factor(datos_prueba$mora_binaria,    levels = c(0, 1)),
  Predicho = factor(datos_prueba$prediccion_mora, levels = c(0, 1))
))

grafico_confusion <- ggplot(matriz_confusion, aes(x = Predicho, y = Real, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), size = 9) +
  scale_fill_gradient(low = "white", high = "#187D80") +
  labs(title = "Matriz de confusión",
       subtitle = "0 = sin mora, 1 = mora", fill = "Clientes") +
  theme_minimal(base_size = 13)

print(grafico_confusion)

verdaderos_positivos <- sum(datos_prueba$prediccion_mora == 1 & datos_prueba$mora_binaria == 1)
verdaderos_negativos <- sum(datos_prueba$prediccion_mora == 0 & datos_prueba$mora_binaria == 0)
falsos_positivos     <- sum(datos_prueba$prediccion_mora == 1 & datos_prueba$mora_binaria == 0)
falsos_negativos     <- sum(datos_prueba$prediccion_mora == 0 & datos_prueba$mora_binaria == 1)

tabla_metricas <- data.frame(
  metrica = c("Exactitud", "Sensibilidad", "Especificidad", "Precisión"),
  valor   = round(c(
    (verdaderos_positivos + verdaderos_negativos) / nrow(datos_prueba),
    verdaderos_positivos / (verdaderos_positivos + falsos_negativos),
    verdaderos_negativos / (verdaderos_negativos + falsos_positivos),
    verdaderos_positivos / (verdaderos_positivos + falsos_positivos)
  ), 3)
)

tabla_metricas

# 12.8 Curva ROC, AUC y coeficiente de Gini ----------------------------------
# Propósito: evaluar la capacidad de discriminación de un clasificador
# independientemente del punto de corte.
umbrales <- seq(0, 1, by = 0.01)

probabilidades_casos_con_mora <-
  datos_prueba$probabilidad_mora[datos_prueba$mora_binaria == 1]
probabilidades_casos_sin_mora <-
  datos_prueba$probabilidad_mora[datos_prueba$mora_binaria == 0]

curva_roc <- data.frame(
  umbral = umbrales,
  tasa_verdaderos_positivos = sapply(umbrales, function(corte)
    mean(probabilidades_casos_con_mora >= corte)),
  tasa_falsos_positivos = sapply(umbrales, function(corte)
    mean(probabilidades_casos_sin_mora >= corte))
)

# Área bajo la curva mediante la regla del trapecio
eje_x <- rev(curva_roc$tasa_falsos_positivos)
eje_y <- rev(curva_roc$tasa_verdaderos_positivos)
auc   <- sum(diff(eje_x) * (eje_y[-1] + eje_y[-length(eje_y)]) / 2)
gini  <- 2 * auc - 1

grafico_roc <- ggplot(curva_roc, aes(x = tasa_falsos_positivos,
                                     y = tasa_verdaderos_positivos)) +
  geom_line(color = "#187D80", linewidth = 1.2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  labs(title = "Curva ROC",
       subtitle = paste0("AUC = ", round(auc, 3), "   |   Gini = ", round(gini, 3)),
       x = "Tasa de falsos positivos", y = "Tasa de verdaderos positivos") +
  theme_minimal(base_size = 13)

print(grafico_roc)

# 12.9 Árbol de decisión -----------------------------------------------------
# Propósito: generar reglas de decisión explícitas y de fácil comunicación
# (por ejemplo, «si la edad es menor de 30 y las compras superan 12, el riesgo
# es alto»).
arbol_decision <- rpart(factor(mora_binaria) ~ edad + compras + gasto_medio,
                        data = datos_entrenamiento, method = "class",
                        control = rpart.control(maxdepth = 3))

plot(arbol_decision, margin = 0.1)
text(arbol_decision, use.n = TRUE, cex = 0.8)

importancia_variables <- data.frame(
  variable    = names(arbol_decision$variable.importance),
  importancia = as.numeric(arbol_decision$variable.importance)
)

grafico_importancia <- ggplot(importancia_variables,
                              aes(x = reorder(variable, importancia),
                                  y = importancia)) +
  geom_col(fill = "#187D80") +
  coord_flip() +
  labs(title = "Importancia de las variables en el árbol",
       x = NULL, y = "Importancia") +
  theme_minimal(base_size = 13)

print(grafico_importancia)

# ============================================================================
# 13. Exportación de gráficos -----------------------------------------------
# ============================================================================

getwd()

ggsave(filename = "grafico_dispersion.png", plot = grafico_puntos,
       width = 10, height = 5, dpi = 130)

# ============================================================================
# 14. Aplicaciones interactivas con Shiny -----------------------------------
# ============================================================================
# La aplicación Shiny se encuentra en el archivo independiente app.R.
# Para ejecutarla: abrir app.R en RStudio y pulsar "Run App".
