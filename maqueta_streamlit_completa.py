from pathlib import Path

import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st

# Cuando cambias un control, Streamlit vuelve a ejecutar este archivo de arriba abajo.
# El código está organizado en funciones; main() (al final) las llama en orden.

RUTA_DATOS = Path(__file__).parent / "estudiantes" / "datos_practica" / "03_clientes.csv"
FUENTE = "Fuente: 03_clientes.csv · Herramientas de Visualización."
ORDEN_SEGMENTOS = ["Frecuente", "Regular", "Ocasional"]
COLORES = {"Frecuente": "#1f77b4", "Regular": "#ff7f0e", "Ocasional": "#2ca02c"}
ETIQUETAS = {
    "compras": "Compras por cliente (número)",
    "gasto_medio": "Gasto medio por compra (u. m.)",
    "edad": "Edad (años)",
    "segmento": "Segmento",
}


# ---------------------------------------------------------------
# 1. ACÁ VAN TUS DATOS
# ---------------------------------------------------------------
@st.cache_data
def cargar_datos(ruta=RUTA_DATOS):
    """Lee el CSV de clientes. utf-8-sig quita un carácter invisible al inicio del archivo."""
    return pd.read_csv(ruta, encoding="utf-8-sig")


# ---------------------------------------------------------------
# 2. ACÁ VAN TUS FILTROS
# ---------------------------------------------------------------
def mostrar_filtros(datos):
    """Dibuja los controles en la barra lateral y devuelve lo que eligió el usuario."""
    opciones = ["Todos", *ORDEN_SEGMENTOS]
    segmento = st.sidebar.selectbox("Segmento", opciones)

    # TODO 1 resuelto: deslizador para el gasto mínimo.
    gasto_min = int(np.floor(datos["gasto_medio"].min()))
    gasto_max = int(np.ceil(datos["gasto_medio"].max()))
    gasto_minimo = st.sidebar.slider(
        "Gasto medio mínimo (u. m.)",
        min_value=gasto_min,
        max_value=gasto_max,
        value=gasto_min,
        step=1,
    )
    return segmento, gasto_minimo


def aplicar_filtros(datos, segmento, gasto_minimo):
    """Conserva las filas del segmento elegido y con gasto medio >= al valor del deslizador."""
    vista = datos
    if segmento != "Todos":
        vista = vista.loc[vista["segmento"] == segmento]
    vista = vista.loc[vista["gasto_medio"] >= gasto_minimo]
    return vista


# ---------------------------------------------------------------
# 3. CÁLCULOS PARA TÍTULOS Y CONCLUSIÓN
# ---------------------------------------------------------------
def correlacion(vista, x="compras", y="gasto_medio"):
    """Correlación entre dos columnas. Devuelve None si hay muy pocos datos para calcularla."""
    if len(vista) < 3:
        return None
    r = vista[x].corr(vista[y])
    return None if pd.isna(r) else r


def describir_relacion(r):
    """Convierte la correlación en una frase que se pueda negar."""
    if r is None:
        return "Con este filtro no hay datos suficientes para ver una relación"
    if r <= -0.3:
        return f"En conjunto, más compras van con menor gasto por compra (r = {r:.2f})"
    if r >= 0.3:
        return f"En conjunto, más compras van con mayor gasto por compra (r = {r:.2f})"
    return f"Con este filtro, compras y gasto casi no se relacionan (r = {r:.2f})"


def resumir_segmentos(vista):
    """Número de clientes, promedios y mediana del gasto por segmento."""
    resumen = (
        vista.groupby("segmento")
        .agg(
            clientes=("cliente", "count"),
            compras_promedio=("compras", "mean"),
            gasto_medio_promedio=("gasto_medio", "mean"),
            gasto_medio_mediana=("gasto_medio", "median"),
            edad_promedio=("edad", "mean"),
        )
        .reindex([s for s in ORDEN_SEGMENTOS if s in vista["segmento"].unique()])
        .round(1)
        .reset_index()
    )
    return resumen


def titulo_caja(vista):
    """Título de la caja: qué segmento gasta más por compra (según la mediana)."""
    resumen = resumir_segmentos(vista)
    if resumen.empty:
        return "Sin datos con este filtro"
    if len(resumen) == 1:
        fila = resumen.iloc[0]
        return (f"En el segmento {fila['segmento']} el gasto por compra va de "
                f"{vista['gasto_medio'].min():.0f} a {vista['gasto_medio'].max():.0f} u. m.")
    alto = resumen.loc[resumen["gasto_medio_mediana"].idxmax()]
    bajo = resumen.loc[resumen["gasto_medio_mediana"].idxmin()]
    veces = alto["gasto_medio_mediana"] / bajo["gasto_medio_mediana"]
    return (f"El segmento {alto['segmento']} gasta unas {veces:.1f} veces más por compra "
            f"que el {bajo['segmento']} (mediana)")


def cajas_separadas(vista):
    """True si el 50 % central (la caja) de cada segmento no se cruza con el del siguiente,
    ordenando los segmentos por mediana de gasto."""
    cuartiles = vista.groupby("segmento")["gasto_medio"].quantile([0.25, 0.5, 0.75]).unstack()
    cuartiles = cuartiles.sort_values(0.5)
    return all(cuartiles[0.75].iloc[i] < cuartiles[0.25].iloc[i + 1] for i in range(len(cuartiles) - 1))


def correlacion_dentro_de_segmentos(vista):
    """Correlación compras–gasto calculada dentro de cada segmento por separado."""
    return {seg: correlacion(grupo) for seg, grupo in vista.groupby("segmento")}


def generar_conclusion(vista):
    """Conclusión en texto: lo que se ve con los filtros actuales."""
    if vista.empty:
        return "Con los filtros actuales no queda ningún cliente. Baja el gasto mínimo o cambia el segmento."

    texto = f"- **Relación compras–gasto:** {describir_relacion(correlacion(vista))}.\n"
    resumen = resumir_segmentos(vista)
    if len(resumen) > 1:
        mas_compras = resumen.loc[resumen["compras_promedio"].idxmax()]
        mas_gasto = resumen.loc[resumen["gasto_medio_promedio"].idxmax()]
        texto += (
            f"- El segmento **{mas_compras['segmento']}** es el que **más compra** "
            f"({mas_compras['compras_promedio']:.1f} compras en promedio).\n"
            f"- El segmento **{mas_gasto['segmento']}** es el que **más gasta por compra** "
            f"({mas_gasto['gasto_medio_promedio']:.1f} u. m. en promedio).\n"
        )
        if cajas_separadas(vista):
            texto += ("- En la gráfica de caja, el 50 % central de cada segmento **no se cruza** con el de los otros: "
                      "no es solo una diferencia de promedios, los grupos están separados en gasto por compra.\n")
        else:
            texto += ("- En la gráfica de caja, las cajas de algunos segmentos **se cruzan**: "
                      "la diferencia de promedios no separa del todo a los grupos.\n")

        dentro = correlacion_dentro_de_segmentos(vista)
        valores = ", ".join(f"{seg} r = {r:.2f}" for seg, r in dentro.items() if r is not None)
        if valores:
            texto += (f"- Ojo: **dentro de cada segmento** la relación casi desaparece ({valores}). "
                      "La relación negativa general viene sobre todo de las **diferencias entre segmentos**.\n")
    return texto


def frase_limite(datos):
    """Lo que NO se puede concluir con estos datos (se calcula sobre la base completa)."""
    menores = datos.loc[datos["edad"] < 18, "edad"]
    return (
        "**Qué no se puede concluir:**\n"
        "- Los datos son **inventados** y es una sola muestra de 180 clientes: no describen a clientes reales.\n"
        "- La correlación muestra que las variables **se mueven juntas**, no que comprar más "
        "**cause** gastar menos por compra. Además, dentro de cada segmento casi no hay relación: "
        "no se puede decir que un cliente que compre más vaya a gastar menos por compra.\n"
        "- Los segmentos **ya vienen dados** en el archivo; la gráfica no demuestra que sean los grupos "
        "\"naturales\" ni cómo se definieron.\n"
        f"- Hay **{len(menores)} clientes con edad entre {menores.min()} y {menores.max()} años**. "
        "Puede ser un error del dato; se dejaron sin tocar, así que la relación con la edad debe leerse con cuidado."
    )


# ---------------------------------------------------------------
# 4. GRÁFICAS (Plotly)
# ---------------------------------------------------------------
def grafica_dispersion(vista, semilla=42):
    """Dispersión compras vs. gasto medio. Se agrega un pequeño temblor (jitter) a las compras
    porque son números enteros y muchos puntos quedarían uno encima del otro."""
    rng = np.random.default_rng(semilla)
    datos_grafica = vista.assign(compras_jitter=vista["compras"] + rng.uniform(-0.25, 0.25, len(vista)))
    figura = px.scatter(
        datos_grafica,
        x="compras_jitter",
        y="gasto_medio",
        color="segmento",
        category_orders={"segmento": ORDEN_SEGMENTOS},
        color_discrete_map=COLORES,
        opacity=0.6,
        hover_data={"cliente": True, "compras": True, "compras_jitter": False, "edad": True},
        labels={**ETIQUETAS, "compras_jitter": ETIQUETAS["compras"]},
        title=describir_relacion(correlacion(vista)),
    )
    return figura


def grafica_caja(vista):
    """Caja del gasto medio por segmento, con todos los puntos para ver cómo se reparte."""
    figura = px.box(
        vista,
        x="segmento",
        y="gasto_medio",
        color="segmento",
        category_orders={"segmento": ORDEN_SEGMENTOS},
        color_discrete_map=COLORES,
        points="all",
        labels=ETIQUETAS,
        title=titulo_caja(vista),
    )
    figura.update_layout(showlegend=False)
    return figura


def grafica_correlacion(vista):
    """Mapa de calor de correlaciones. La escala va fija de -1 a 1 para no exagerar colores."""
    columnas = ["compras", "gasto_medio", "edad"]
    matriz = vista[columnas].corr().round(2)
    matriz.index = matriz.columns = [ETIQUETAS[c] for c in columnas]
    r = correlacion(vista)
    titulo = ("Compras y gasto por compra van en sentido contrario" if r is not None and r <= -0.3
              else "Correlación entre las variables numéricas")
    figura = px.imshow(
        matriz,
        text_auto=True,
        zmin=-1,
        zmax=1,
        color_continuous_scale="RdBu",
        title=titulo,
    )
    figura.update_layout(coloraxis_colorbar_title="r")
    return figura


# ---------------------------------------------------------------
# 5. PROGRAMA PRINCIPAL: PESTAÑAS
# ---------------------------------------------------------------
def main():
    st.set_page_config(page_title="Clientes · Streamlit", layout="wide")
    st.title("¿Hay grupos de clientes? ¿Cómo se relacionan compras y gasto?")
    st.caption("Clase 4 · Herramientas de Visualización · 180 clientes del archivo 03_clientes.csv.")

    datos = cargar_datos()
    segmento, gasto_minimo = mostrar_filtros(datos)
    vista = aplicar_filtros(datos, segmento, gasto_minimo)
    st.write(f"Clientes visibles: {len(vista)} de {len(datos)}")

    if vista.empty:
        st.warning(generar_conclusion(vista))
        return

    # TODO 2 y 3 resueltos: todas las gráficas usan vista y se agregó la pestaña Conclusión.
    tab_dispersion, tab_caja, tab_correlacion, tab_datos, tab_conclusion = st.tabs(
        ["Dispersión", "Caja por segmento", "Correlación", "Datos", "Conclusión"]
    )

    with tab_dispersion:
        st.plotly_chart(grafica_dispersion(vista), use_container_width=True)
        st.caption("Puntos semitransparentes y con un leve desplazamiento horizontal para que no se tapen. " + FUENTE)

    with tab_caja:
        st.plotly_chart(grafica_caja(vista), use_container_width=True)
        st.caption("La caja muestra cómo se reparte el gasto, no solo el promedio. " + FUENTE)

    with tab_correlacion:
        if len(vista) < 3:
            st.info("Se necesitan al menos 3 clientes para calcular correlaciones.")
        else:
            st.plotly_chart(grafica_correlacion(vista), use_container_width=True)
            st.caption("r cercano a -1 o 1 = relación fuerte; cercano a 0 = débil. " + FUENTE)

    with tab_datos:
        st.dataframe(vista, hide_index=True)
        st.subheader("Resumen por segmento")
        st.dataframe(resumir_segmentos(vista), hide_index=True)

    with tab_conclusion:
        st.markdown(generar_conclusion(vista))
        st.markdown(frase_limite(datos))


if __name__ == "__main__":
    main()
