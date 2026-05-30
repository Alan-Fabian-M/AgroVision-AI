# AgroVision AI 🌾

### Inteligencia Artificial Multimodal y Grafos de Conocimiento para la Agricultura de Precisión en Santa Cruz

![AgroVision AI Banner](https://img.shields.io/badge/AgroVision_AI-Precision_Agriculture-green?style=for-the-badge&logo=google-earth-engine&logoColor=white)
![Estado del Proyecto](https://img.shields.io/badge/Estado-MVP_Hackathon-orange?style=for-the-badge)
![Licencia](https://img.shields.io/badge/Licencia-MIT-blue?style=for-the-badge)

---

## 📌 Índice

- [1. El Problema Local (Santa Cruz, Bolivia)](#1-el-problema-local-santa-cruz-bolivia)
- [2. La Solución: AgroVision AI](#2-la-solución-agrovision-ai)
- [3. Capas de Innovación](#3-capas-de-innovación)
- [4. Arquitectura Tecnológica](#4-arquitectura-tecnológica)
- [5. Flujo Técnico del Sistema](#5-flujo-técnico-del-sistema)
- [6. Características Principales (Comparativa)](#6-características-principales-comparativa)
- [7. Plan de Escalabilidad](#7-plan-de-escalabilidad)
- [8. Modelo de Negocio](#8-modelo-de-negocio)
- [9. Propuesta de Triple Impacto](#9-propuesta-de-triple-impacto)
- [10. Viabilidad y Robustez](#10-viabilidad-y-robustez)
- [11. Instalación y Uso](#11-instalación-y-uso)
- [12. Equipo de Desarrollo](#12-equipo-de-desarrollo)
- [13. Licencia](#13-licencia)

---

## 1. El Problema Local (Santa Cruz, Bolivia)

El departamento de **Santa Cruz** es el motor agroindustrial y el granero de Bolivia, concentrando la mayor parte de la producción de cultivos estratégicos como la **soya, el sorgo, el maíz y la caña de azúcar**. Sin embargo, la competitividad y rentabilidad de este sector vital se ven constantemente amenazadas por la presencia latente de plagas, malezas, enfermedades y el estrés hídrico.

```
┌────────────────────────────────────────────────────────┐
│             EL DESAFÍO DE LA INSPECCIÓN MANUAL         │
├────────────────────────────────────────────────────────┤
│ ❌ Inspección tardía en extensiones de miles de ha     │
│ ❌ Uso excesivo/preventivo de agroquímicos costosos     │
│ ❌ Pérdida de hasta un 30% del rendimiento de cosecha  │
└────────────────────────────────────────────────────────┘
```

### Principales Factores Críticos Identificados:
*   **Inspección Principalmente Manual:** Los agrónomos y productores deben recorrer manualmente extensiones masivas de terreno, lo que hace inviable un monitoreo exhaustivo y oportuno.
*   **Detección Reactiva:** La mayoría de las plagas y enfermedades se identifican visualmente sólo cuando el daño foliar y estructural ya es severo y costoso de remediar.
*   **Abuso de Agroquímicos:** Ante la incertidumbre y la falta de diagnósticos científicos al instante, se aplican pesticidas y fungicidas de manera preventiva o desmedida, desgastando el suelo y elevando los costos de operación.
*   **Desconexión Climática:** Las condiciones de temperatura, humedad y precipitaciones influyen drásticamente en la propagación de agentes patógenos (como la *Roya de la Soya*), pero actualmente no se cruzan en tiempo real con el estado físico de la planta.

> [!WARNING]
> **El Impacto Económico:** Una detección tardía de plagas foliares puede reducir el rendimiento de la soya hasta en un **30-50%**, afectando directamente la seguridad alimentaria y la estabilidad económica regional.

---

## 2. La Solución: AgroVision AI

**AgroVision AI** es una plataforma móvil y web de agricultura de precisión diseñada específicamente para democratizar la asistencia agronómica experta en Santa Cruz. El sistema aprovecha el potencial de la **IA Multimodal**, los **Grafos de Conocimiento** y los **Datos Climáticos en Tiempo Real** para transformar una simple fotografía de celular en una decisión estratégica de alto impacto.

```
       [ 📸 Captura Foto ] ➔ [ 🌐 Obtención GPS ] ➔ [ ☁️ Datos del Clima ]
                                                           │
       [ 🏆 Diagnóstico 360° ] 🗲 [ 🧠 Grafos Neo4j ] 🗲 [ 🤖 Gemini AI Multimodal ]
```

### ¿Cómo Funciona para el Agricultor?
1.  **Captura del Cultivo:** El agricultor toma una fotografía de las hojas o el tallo afectado desde la aplicación móvil.
2.  **Geolocalización Automática:** La app registra de forma transparente la ubicación GPS exacta del hallazgo.
3.  **Análisis Multimodal:** El Backend procesa la imagen y la cruza con los parámetros meteorológicos de la zona en ese preciso instante.
4.  **Razonamiento por Grafos:** Un motor de base de datos orientada a grafos evalúa la susceptibilidad del cultivo según su historial, plagas asociadas y el clima actual.
5.  **Diagnóstico Inmediato:** El usuario recibe un reporte claro con el **diagnóstico preliminar**, **nivel de severidad**, **riesgo de propagación**, **impacto económico estimado** y un **plan de acción sostenible**.

---

## 3. Capas de Innovación

A diferencia de las herramientas convencionales que actúan como simples catálogos visuales, **AgroVision AI** implementa un modelo de diagnóstico integral estructurado en **4 capas complementarias**:

```
┌────────────────────────────────────────────────────────┐
│                CAPAS DE INNOVACIÓN                     │
├────────────────────────────────────────────────────────┤
│  Layer 4: Capa Predictiva (Evaluación de propagación)  │
│  Layer 3: Capa de Conocimiento (Grafo de tratamientos) │
│  Layer 2: Capa Climática (Temp, Humedad, Pronóstico)   │
│  Layer 1: Capa Visual (Identificación por Imagen)      │
└────────────────────────────────────────────────────────┘
```

*   **👁️ Capa Visual:** Clasificación e identificación automatizada de anomalías, plagas, deficiencias nutricionales y patógenos foliares a partir de imágenes capturadas en campo.
*   **🌤️ Capa Climática:** Monitoreo constante de variables clave (temperatura, humedad relativa, dirección del viento y precipitaciones) para alimentar modelos que determinan si el ambiente favorece la proliferación biológica del patógeno.
*   **🧠 Capa de Conocimiento:** Un **Grafo de Conocimiento Agronómico** dinámico que conecta variables complejas:
    $$\text{Plaga/Enfermedad} \longrightarrow \text{Cultivo Hospedero} \longrightarrow \text{Clima Favorable} \longrightarrow \text{Tratamientos Específicos}$$
    Esto proporciona explicabilidad y coherencia científica a cada diagnóstico generado por la IA.
*   **🔮 Capa Predictiva:** Estimación del riesgo de propagación geográfica en parcelas colindantes utilizando la dirección del viento, el pronóstico de lluvias a mediano plazo y la proximidad de otros reportes.

---

## 4. Arquitectura Tecnológica

La infraestructura de **AgroVision AI** está diseñada bajo principios de alta disponibilidad, modularidad y bajo consumo de recursos en el dispositivo móvil del agricultor, trasladando la carga pesada al backend en la nube.

```mermaid
graph TD
    %% Estilo de Nodos
    style APP fill:#2ECC71,stroke:#27AE60,stroke-width:2px,color:#fff
    style BE fill:#3498DB,stroke:#2980B9,stroke-width:2px,color:#fff
    style DB fill:#9B59B6,stroke:#8E44AD,stroke-width:2px,color:#fff
    style GRAPH fill:#F1C40F,stroke:#F39C12,stroke-width:2px,color:#000
    style GEMINI fill:#E74C3C,stroke:#C0392B,stroke-width:2px,color:#fff
    style WEATHER fill:#1ABC9C,stroke:#16A085,stroke-width:2px,color:#fff

    subgraph Capa de Cliente (Móvil)
        APP[📱 Flutter Mobile App]
    end

    subgraph Capa de Servicios & Orquestación
        BE[⚡ FastAPI Backend]
    end

    subgraph Motores de Inteligencia & Datos
        WEATHER[🌤️ OpenWeatherMap API]
        GEMINI[🤖 Gemini API Multimodal]
        GRAPH[🕸️ Neo4j Knowledge Graph]
        DB[🐘 PostgreSQL Database]
    end

    %% Relaciones de Flujo
    APP -->|1. Foto + Coordenadas GPS| BE
    BE -->|2. Obtiene datos meteorológicos| WEATHER
    BE -->|3. Imagen + Clima + Prompt Contextual| GEMINI
    BE -->|4. Consulta reglas y relaciones| GRAPH
    BE -->|5. Almacena historial y reportes| DB
    BE -->|6. Envía diagnóstico estructurado| APP
```

### Componentes de la Arquitectura:

*   **Frontend (Flutter):**
    *   *Propósito:* Interfaz nativa ligera y responsiva para Android e iOS.
    *   *Funciones clave:* Captura fotográfica con compresión local, geolocalización satelital en segundo plano, dashboard interactivo del agricultor y almacenamiento local de diagnósticos offline.
*   **Backend (FastAPI):**
    *   *Propósito:* Microservicio asíncrono de altísimo rendimiento para la orquestación rápida de llamadas.
    *   *Funciones clave:* Validación de payloads, procesamiento e ingesta de imágenes, e integración paralela con APIs y motores de persistencia.
*   **Base de Datos Relacional (PostgreSQL):**
    *   *Propósito:* Persistencia relacional estructurada.
    *   *Funciones clave:* Registro seguro de usuarios, parcelas agrícolas, logs de auditoría y metadatos de los diagnósticos georreferenciados.
*   **Motor de Conocimiento (Neo4j Graph Database):**
    *   *Propósito:* Mapear interacciones biológicas y agronómicas complejas.
    *   *Funciones clave:* Consultas de tipo grafo rápidas para cruzar plagas con agroquímicos aprobados por SENASAG, restricciones de carencia y condiciones de humedad ideales para evitar falsos positivos.
*   **Inteligencia Artificial (Gemini API):**
    *   *Propósito:* Cerebro multimodal y generador de contexto explicativo.
    *   *Funciones clave:* Analiza de manera conjunta la foto de la planta y los datos meteorológicos agregados, devolviendo una respuesta estructurada bajo formato JSON que el backend parsea de forma segura.
*   **Información Climática (OpenWeatherMap API):**
    *   *Propósito:* Sensor meteorológico virtual.
    *   *Funciones clave:* Proporciona temperatura, humedad, presión, velocidad del viento e historial de lluvias localizado con base en el GPS del agricultor.

---

## 5. Flujo Técnico del Sistema

```
[Flutter App] ──(Foto + GPS)──> [FastAPI Backend] ──(Coordenadas)──> [OpenWeatherMap]
                                       │                                  │
                                       │ (Imagen + Clima)                 │ (Datos Clima)
                                       ▼                                  ▼
[PostgreSQL] <──(Historial)─── [FastAPI Backend] ───────────────> [Gemini API]
     │                                 ▲
     │                                 │ (Consulta de Grafo)
     │                                 ▼
     └──────────────────────> [Neo4j Graph DB] (Patrones y Tratamientos Sugeridos)
```

1.  **Disparo:** El productor abre la app de Flutter, captura la zona sospechosa de la hoja y el dispositivo captura los metadatos de latitud/longitud.
2.  **Envío y Recepción:** FastAPI recibe la petición en un endpoint multipart/form-data asíncrono y valida el token del productor.
3.  **Enriquecimiento Climático:** El backend consulta a la API de OpenWeatherMap usando las coordenadas recibidas para rescatar la humedad relativa y la temperatura ambiental actuales en el lote de cultivo.
4.  **Inferencia Multimodal:** FastAPI estructura un Prompt optimizado dirigido al modelo `gemini-1.5-flash` o similar, inyectando la imagen y los datos del clima.
5.  **Validación mediante Grafo:** El backend recibe el diagnóstico primario y realiza una consulta Cypher en Neo4j para mapear las restricciones físicas del tratamiento recomendado (por ejemplo, verificar si el fungicida sugerido no entra en conflicto con las temperaturas de aplicación reportadas o el tipo de cultivo).
6.  **Persistencia:** Se guarda el registro completo en PostgreSQL para el histórico del usuario y mapas de calor futuros.
7.  **Despliegue Visual:** FastAPI retorna un JSON formateado a la app móvil, la cual renderiza de forma interactiva el resultado, alertas visuales y PDF descargable con las directrices de mitigación.

---

## 6. Características Principales (Comparativa)

| Característica / Función | AgroVision AI 🌾 | Apps Tradicionales de IA | Inspección Manual |
| :--- | :---: | :---: | :---: |
| **Diagnóstico por Imagen** | ✅ **Sí (Multimodal)** | ✅ Sí (Solo visual) | ❌ No (Depende de ojo humano) |
| **Integración Climática en vivo** | ✅ **Sí (Tiempo real)** | ❌ No | ❌ No |
| **Grafo de Relaciones Complejas** | ✅ **Sí (Neo4j)** | ❌ No | ⚠️ Parcial (Memoria del agrónomo) |
| **Geolocalización Automática** | ✅ **Sí** | ⚠️ Opcional | ❌ Manual en planillas |
| **Estimación de Daño Económico** | ✅ **Sí** | ❌ No | ⚠️ Estimación manual lenta |
| **Explicabilidad del Tratamiento** | ✅ **Sí (Científico/Grafo)**| ⚠️ Limitado (IA genérica)| ✅ Alta (Por profesionales) |
| **Costo de Despliegue en Campo** | 🟢 **Ultra Bajo** | 🟢 Bajo | 🔴 Alto (Logística y horas-hombre)|

---

## 7. Plan de Escalabilidad

El proyecto ha sido diseñado desde sus cimientos arquitectónicos para crecer orgánicamente a través de cuatro etapas clave de madurez tecnológica y comercial:

```
📊 FASE 1: MVP Hackathon   ➔   🏢 FASE 2: B2B y Cooperativas
                                      │
🤖 FASE 4: IoT & Satelital  💡 FASE 3: Mapa Regional de Riesgo 
```

*   ### 🚀 Fase 1: MVP Hackathon
    *   Lanzamiento de la app móvil básica con captura de fotos, geolocalización automática e integración backend con Gemini API y OpenWeatherMap.
    *   Generación de diagnósticos automatizados y tratamientos de referencia rápida almacenados en Neo4j.
*   ### 🏢 Fase 2: Panel Empresarial y Cooperativas
    *   Desarrollo de un Dashboard Web multiusuario para técnicos agrícolas y supervisores de campo de grandes cooperativas (como Anapo o Cao).
    *   Gestión de múltiples fincas y lotes, permitiendo al agrónomo asignar tareas de fumigación y monitorear el rendimiento del personal en terreno.
*   ### 🗺️ Fase 3: Mapa Regional de Riesgos
    *   Visualización de alertas tempranas georreferenciadas. Las cooperativas y el gobierno pueden ver mapas de calor en tiempo real que revelen la aparición de brotes de plagas específicos en Santa Cruz antes de que se propaguen de un municipio a otro.
*   ### 📡 Fase 4: Integración Satelital e IoT
    *   Cruce de datos foliares con el índice de vegetación de diferencia normalizada (NDVI) proveniente de **Google Earth Engine** e imágenes satelitales Sentinel-2.
    *   Conexión directa con sensores IoT de humedad de suelo y estaciones meteorológicas instaladas en parcelas clave para diagnósticos con cero margen de error.

---

## 8. Modelo de Negocio

Para asegurar la viabilidad financiera y la sostenibilidad a largo plazo, **AgroVision AI** plantea un modelo híbrido estructurado:

```
┌────────────────────────────────────────────────────────┐
│                  MODELO DE NEGOCIO                     │
├────────────────────────────────────────────────────────┤
│ 🟢 Freemium (Pequeño Productor): Diagnósticos Gratuitos│
│ 🔵 B2B SaaS (Grandes Fincas): Gestión de Equipos       │
│ 🟣 Data Intelligence: Predicción de insumos y riesgos  │
└────────────────────────────────────────────────────────┘
```

1.  **Suscripción Freemium:**
    *   *Nivel Gratuito:* Ideal para pequeños agricultores. Permite hasta 10 diagnósticos mensuales sin costo con recomendaciones estándar.
    *   *Nivel Premium:* Diagnósticos e historial ilimitados, descarga de reportes detallados en PDF con aval de tratamientos, y alertas de riesgo climáticos tempranas.
2.  **B2B SaaS (Software as a Service):**
    *   Suscripciones corporativas orientadas a cooperativas agrícolas, asesores técnicos e insumeras.
    *   Acceso al portal web consolidado, métricas de severidad de cultivos de todos sus asociados y analíticas avanzadas de campo.
3.  **Inteligencia de Datos (Monetización de Insights):**
    *   Venta de reportes agregados y anonimizados sobre tendencias de propagación y brotes regionales para aseguradoras agrícolas, distribuidores de insumos y entidades de investigación del Estado.

---

## 9. Propuesta de Triple Impacto

El propósito central de **AgroVision AI** no es únicamente el beneficio comercial; la plataforma está comprometida con la sostenibilidad a través de tres pilares fundamentales de impacto medible:

> [!TIP]
> **Modelo de Triple Impacto**
> *   **Impacto Social 🤝:** Democratizamos la asistencia técnica calificada. Pequeños productores que no pueden costear la visita diaria de un agrónomo experto ahora tienen una guía científica en su bolsillo, reduciendo la brecha tecnológica en el agro cruceño.
> *   **Impacto Ambiental 🍃:** Al diagnosticar con precisión científica y cruzar datos meteorológicos, evitamos la aplicación indiscriminada e infundada de productos químicos en los suelos. Esto se traduce en menor contaminación freática y en la conservación de los ecosistemas locales de Santa Cruz.
> *   **Impacto Económico 💰:** Reducción sustancial del desperdicio de insumos caros y prevención de pérdidas de rendimiento en la cosecha. Cada plaga erradicada a tiempo representa miles de dólares ahorrados para las familias productoras bolivianas.

---

## 10. Viabilidad y Robustez

Nuestra plataforma se destaca por ser sumamente viable y resistente frente a entornos reales de producción agrícola:

*   **Desacoplamiento de Servicios:** El Frontend (Flutter) y el Backend (FastAPI) funcionan de forma autónoma. Si una de las APIs externas experimenta latencia, el sistema cuenta con fallbacks integrados para no interrumpir el flujo del usuario.
*   **Integridad de Datos Asegurada:** La persistencia relacional híbrida (PostgreSQL) y el motor de grafos (Neo4j) garantizan que las relaciones entre enfermedades y tratamientos no se rompan ni pierdan consistencia al escalar a millones de nodos.
*   **Bajo Requisito de Hardware:** No se requiere de sensores costosos en campo ni cámaras profesionales para arrancar. El agricultor promedio de Santa Cruz solo necesita un teléfono inteligente de gama media y conexión de datos estándar (incluso con intermitencia 3G/4G).
*   **Explicabilidad Transparente:** La IA no actúa de forma opaca; cada recomendación de tratamiento emitida por Gemini pasa por el filtro del grafo científico agronómico, evitando alucinaciones del modelo de lenguaje.

---

## 11. Instalación y Uso

### Requisitos Previos:
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (versión 3.x o superior)
*   [Python](https://www.python.org/downloads/) (versión 3.10 o superior)
*   [Neo4j Database](https://neo4j.com/download/) (Local o instancia de Neo4j Aura)
*   [PostgreSQL](https://www.postgresql.org/download/)

### Paso 1: Configurar el Backend (FastAPI)

1.  Navega al directorio del backend:
    ```bash
    cd backend
    ```
2.  Crea e inicializa tu entorno virtual:
    ```bash
    python -m venv venv
    # En Windows
    .\venv\Scripts\activate
    # En macOS/Linux
    source venv/bin/activate
    ```
3.  Instala las dependencias necesarias:
    ```bash
    pip install -r requirements.txt
    ```
4.  Crea tu archivo de variables de entorno copiando la plantilla:
    ```bash
    cp .env.example .env
    ```
    *(Abre el archivo `.env` y rellena las claves correspondientes de Gemini, OpenWeatherMap y tus credenciales de PostgreSQL/Neo4j).*
5.  Inicia el servidor de desarrollo:
    ```bash
    uvicorn main:app --reload
    ```
    El backend estará disponible en `http://127.0.0.1:8000`.

### Paso 2: Configurar la App Móvil (Flutter)

1.  Navega al directorio de la aplicación móvil:
    ```bash
    cd ../app_movil
    ```
2.  Descarga los paquetes de Flutter necesarios:
    ```bash
    flutter pub get
    ```
3.  Ejecuta la aplicación en tu emulador o dispositivo conectado:
    ```bash
    flutter run
    ```

---

## 12. Equipo de Desarrollo

| Nombre del Miembro | Rol en el Proyecto | Contacto / Enlace |
| :--- | :--- | :--- |
| **[Miembro 1]** | Especialista en Inteligencia Artificial y Backend | [GitHub / LinkedIn Placeholder] |
| **[Miembro 2]** | Desarrollador de Aplicaciones Móviles (Flutter) | [GitHub / LinkedIn Placeholder] |
| **[Miembro 3]** | Diseñador UX/UI y Especialista de Negocios | [GitHub / LinkedIn Placeholder] |

---

## 13. Licencia

Este proyecto está bajo la Licencia **MIT**. Para más detalles, consulta el archivo [LICENSE](LICENSE) (placeholder) dentro del repositorio.

---

> [!IMPORTANT]
> ## 🚀 Frase Final para el Pitch
> **"AgroVision AI transforma fotografías agrícolas en decisiones inteligentes, combinando visión artificial, datos climáticos y conocimiento agronómico para reducir pérdidas económicas, mejorar la sostenibilidad y fortalecer la soberanía alimentaria y agrícola de Santa Cruz."**
