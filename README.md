# Taller Streamlit · Segmentación de clientes

**Herramientas de Visualización · Maestría en Analítica Aplicada (Universidad de La Sabana)**
**Autor:** Juan Esteban Carrillo

App interactiva en Streamlit que responde la pregunta del archivo `03_clientes.csv`:
**¿hay grupos de clientes? ¿cómo se relacionan compras y gasto?**

## Qué tiene la app

- **Filtros (barra lateral):** segmento (Frecuente, Regular, Ocasional) y gasto medio mínimo por compra.
- **Dispersión:** compras vs. gasto medio por compra, con color por segmento, transparencia y un leve desplazamiento para que los puntos no se tapen.
- **Caja por segmento:** cómo se reparte el gasto en cada grupo, no solo el promedio.
- **Correlación:** mapa de calor entre compras, gasto medio y edad (escala fija de -1 a 1).
- **Datos:** tabla filtrada y resumen por segmento.
- **Conclusión:** hallazgos y qué **no** se puede concluir con estos datos.

Los títulos de las gráficas se recalculan con los filtros, así que siempre dicen una afirmación sobre los datos visibles.

## Estructura

```
maqueta_streamlit_completa.py      # la app
requirements.txt                   # librerías necesarias
estudiantes/
  └── datos_practica/
        └── 03_clientes.csv        # 180 clientes (datos inventados del curso)
```

La app busca el CSV en esa ruta, relativa al archivo `.py`; no cambies la estructura de carpetas.

## Cómo ejecutarla

```
conda create -n streamlit_env python=3.11
conda activate streamlit_env
pip install -r requirements.txt
streamlit run maqueta_streamlit_completa.py
```

Se abre en el navegador en `http://localhost:8501`.

## Hallazgos principales

- En conjunto, más compras van con menor gasto por compra (r = -0,75).
- Los segmentos están bien separados: el 50 % central de cada uno no se cruza con el de los otros. El segmento Ocasional gasta unas 3,9 veces más por compra que el Frecuente (mediana).
- Dentro de cada segmento la relación casi desaparece (r entre -0,12 y 0,10): la relación general viene de las diferencias entre segmentos.

## Límites

- Los datos son inventados; no describen clientes reales.
- La correlación no implica causalidad.
- Los segmentos vienen dados en el archivo; la app no demuestra cómo se definieron.
- Hay 7 clientes con edades entre 8 y 17 años, posiblemente un error del dato; se dejaron sin modificar.

**Fuente de los datos:** `03_clientes.csv`, material del curso Herramientas de Visualización.
