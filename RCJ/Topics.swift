import SwiftUI

// tema al azar, 15 minutos para investigarlo, y no se repite si ya lo hiciste

enum TopicBank {
    static let titles: [String] = [
        "Impulso específico", "Ciclo de combustión escalonada", "Ciclo generador de gas", "Ciclo expansor",
        "Tobera de campana", "Relación de áreas de la tobera", "Tobera subexpandida", "Tobera sobreexpandida",
        "Refrigeración regenerativa", "Refrigeración por película", "Inyector pintle", "Inestabilidad de combustión",
        "Turbobomba y cavitación", "Presurización autógena", "Hidrolox", "Metano líquido como propergol",
        "RP-1 y el coque en los canales", "Propergoles hipergólicos", "Motor de combustible sólido", "Motor iónico",
        "Propulsor de efecto Hall", "Ecuación de Tsiolkovski", "Presupuesto de delta-v", "Efecto Oberth",
        "Transferencia de Hohmann", "Transferencia bielíptica", "Puntos de Lagrange", "Órbita geoestacionaria",
        "Órbita heliosíncrona", "Inclinación orbital", "Perturbación J2", "Reentrada atmosférica",
        "Escudo térmico ablativo", "Losetas reutilizables", "Max Q", "Giro gravitatorio",
        "Encendido de aterrizaje suicida", "Retropropulsión supersónica", "Aletas de rejilla", "Control vectorial de empuje",
        "Oscilación pogo", "Slosh del propergol", "Motores de ullage", "Fracción de carga útil",
        "Carenado del cohete", "Cubesats", "Ruedas de reacción", "Sensor de estrellas",
        "Paneles solares en órbita", "Cinturones de Van Allen", "Síndrome de Kessler", "Mantenimiento de estación",
        "Enlace entre satélites", "Monopropelente", "Presión de cámara", "Diamantes de choque",
        "Separación de flujo en la tobera", "Tobera aerospike", "Motor Raptor", "Motor Merlin",
        "Motor RS-25", "Motor F-1 del Saturno V", "Motor RD-180", "Motor BE-4",
        "Motor Rutherford", "Motor RL10", "Propulsores Draco", "Proceso Sabatier",
        "COPV de helio", "Mezcla oxidante-combustible", "Velocidad característica", "Coeficiente de empuje",
        "Empuje en vacío y al nivel del mar", "Capa límite laminar y turbulenta", "Número de Reynolds", "Número de Mach",
        "Ondas de choque", "Expansión de Prandtl-Meyer", "Resistencia de onda", "Resistencia inducida",
        "Efecto suelo aerodinámico", "Ángulo de ataque y entrada en pérdida", "Perfil supercrítico", "Regla del área de Whitcomb",
        "Flutter aeroelástico", "Polar de resistencia", "Relación sustentación-resistencia", "Alargamiento del ala",
        "Carga alar", "Mach crítico", "Divergencia de resistencia", "Coffin corner",
        "Dutch roll", "Margen estático", "Centro de presiones", "Winglets",
        "Ala delta y vórtice", "Separación inducida por choque", "Efecto suelo en un F1", "Túneles Venturi del fondo",
        "Porpoising", "DRS", "Difusor de un F1", "Aire sucio y rebufo",
        "Degradación térmica del neumático", "Graining", "Blistering", "Ángulo de deslizamiento del neumático",
        "Caída y convergencia", "Altura de marcha y rake", "Compuestos de Pirelli", "Ventana de temperatura del neumático",
        "Undercut y overcut", "MGU-K", "MGU-H", "Límite de flujo de combustible en F1",
        "Monocasco de fibra de carbono", "El halo", "Plank y desgaste del patín", "Parque cerrado",
        "Safety car y el delta", "Evolución de la pista", "Marbles", "Trail braking",
        "Subviraje de entrada", "Diferencial y freno motor", "Push-rod y pull-rod", "Muelles de heave",
        "CFD y el túnel de viento", "Carga aerodinámica y refrigeración", "Outwash del alerón", "Vórtice Y250",
        "Tope de gasto en F1", "Lastre y reparto de pesos", "Relaciones de cambio", "Neumático de 18 pulgadas",
        "Ductos de freno", "Sidepods", "Efecto Coandă", "Inerter",
        "Anti-dive y anti-squat", "Segunda ley de la termodinámica", "Entropía", "Radiación de cuerpo negro",
        "Efecto fotoeléctrico", "Principio de incertidumbre", "Entrelazamiento cuántico", "Decoherencia",
        "Efecto túnel", "Superconductividad", "Condensado de Bose-Einstein", "Efecto Casimir",
        "Dilatación del tiempo", "Ondas gravitacionales", "Bosón de Higgs", "Modelo estándar",
        "Qué es un plasma", "Ecuaciones de Navier-Stokes", "Teoría del caos", "Experimento de la doble rendija",
        "Bandas de energía en un sólido", "Unión PN", "Efecto Doppler", "Radiación de Cherenkov",
        "Radiación de Hawking", "Lentes gravitacionales", "Materia oscura", "Energía oscura",
        "Fermiones y bosones", "Espín", "Principio de exclusión de Pauli", "Efecto Meissner",
        "Efecto Hall cuántico", "Superfluidez", "Transiciones de fase", "Movimiento browniano",
        "Teorema de Noether", "Relatividad general", "Horizonte de sucesos", "Paradoja de Fermi",
        "Sincronicidad", "Neuroplasticidad", "Efecto mariposa", "Ley de los rendimientos decrecientes",
        "Coste de oportunidad", "Interés compuesto", "Inflación y poder adquisitivo", "Oferta y demanda",
        "Ventaja comparativa", "Externalidades", "Tragedia de los comunes", "Teoría de juegos y el equilibrio de Nash",
        "Dilema del prisionero", "Sesgo de confirmación", "Aversión a la pérdida", "Falacia del coste hundido",
        "Efecto Dunning-Kruger", "Memoria de trabajo", "Curva del olvido de Ebbinghaus", "Repetición espaciada",
        "Práctica deliberada", "Interleaving al estudiar", "Recuperación activa", "Efecto de generación",
        "Sueño y consolidación de la memoria", "Atención sostenida", "Carga cognitiva", "Chunking",
        "Modelo mental", "Pensamiento de primeros principios", "Inversión mental", "Navaja de Ockham",
        "Margen de seguridad", "Antifragilidad", "Efecto Lindy", "Cola larga",
        "Ley de potencia", "Regresión a la media", "Teorema de Bayes", "Probabilidad condicionada",
        "Varianza y desviación típica", "Ley de los grandes números", "Teorema central del límite", "Correlación no es causalidad",
        "Número de Euler", "Logaritmos", "Crecimiento exponencial", "Interés frente a lineal",
        "Algoritmo de ordenación rápida", "Búsqueda binaria", "Tabla hash", "Árbol binario",
        "Grafos y el camino más corto", "Complejidad algorítmica", "Recursión", "Máquina de Turing",
        "Criptografía de clave pública", "Función hash", "Firma digital", "Blockchain en una frase útil",
        "Cómo funciona una CPU", "Memoria caché", "Jerarquía de memoria", "Sistema operativo y procesos",
        "Latencia frente a ancho de banda", "TCP y UDP", "DNS", "Cómo viaja un paquete por internet",
        "Compresión con pérdida y sin pérdida", "Código de corrección de errores", "Redundancia", "Backup 3-2-1",
        "ADN y ARN", "Transcripción y traducción", "Mutación", "Selección natural",
        "Deriva genética", "Especiación", "Mitocondrias", "Célula eucariota",
        "Sistema inmune innato y adaptativo", "Vacunas y memoria inmunitaria", "Antibióticos y resistencia", "Microbioma",
        "Homeostasis", "Hormonas y retroalimentación", "Ritmo circadiano", "Eje intestino-cerebro",
        "Plasticidad sináptica", "Dopamina y el refuerzo", "Corteza prefrontal", "Amígdala y el miedo",
        "Sueño REM", "Deuda de sueño", "Ejercicio y BDNF", "Zona 2 de entrenamiento",
        "VO2 máx", "Umbral de lactato", "Fuerza frente a hipertrofia", "Proteína y síntesis muscular",
        "Déficit calórico", "Índice glucémico", "Fibra y saciedad", "Omega-3",
        "Vitamina D", "Hierro y ferritina", "Hidratación y electrolitos", "Cafeína y la adenosina",
        "Placebo", "Ensayo clínico doble ciego", "Tamaño del efecto", "Valor p y sus límites",
        "Sensibilidad y especificidad", "Riesgo absoluto y relativo", "Número necesario a tratar", "Medicina basada en evidencia",
        "Cómo leer un paper", "Revisión por pares", "Predación de revistas", "Reproducibilidad",
        "Historia del método científico", "Experimentos de control", "Variable independiente", "Ciego experimental",
        "Escala de Kardashev", "Ecuación de Drake", "Zona habitable", "Tránsitos de exoplanetas",
        "Velocidad de escape", "Año luz", "Unidad astronómica", "Paralaje",
        "Secuencia principal de las estrellas", "Enana blanca", "Estrella de neutrones", "Agujero negro estelar",
        "Nucleosíntesis", "Fusión en el Sol", "Ciclo CNO", "Neutrinos solares",
        "Campo magnético terrestre", "Dinamo planetaria", "Auroras", "Viento solar",
        "Placas tectónicas", "Corrientes oceánicas", "El Niño", "Ciclo del carbono",
        "Efecto invernadero", "Albedo", "Retroalimentaciones climáticas", "Acidificación del océano",
        "Ciclo del agua", "Acuíferos", "Erosión", "Suelo y materia orgánica",
        "Fotosíntesis", "Respiración celular", "ATP", "Cadena de transporte de electrones",
        "Enzimas", "pH y tampones", "Ósmosis", "Difusión",
        "Tabla periódica y las familias", "Enlaces covalentes e iónicos", "Electronegatividad", "Estados de oxidación",
        "Catálisis", "Equilibrio químico", "Principio de Le Chatelier", "Cinética química",
        "Polímeros", "Cristales y granos de un metal", "Fatiga de materiales", "Límite elástico",
        "Módulo de Young", "Dureza y tenacidad", "Corrosión", "Aleaciones",
        "Fibra de carbono y la matriz", "Cerámicas técnicas", "Semiconductores", "Dopaje del silicio",
        "Transistor", "Ley de Moore y su fin", "Litografía", "Consumo de una GPU",
        "Transformador eléctrico", "Corriente alterna", "Factor de potencia", "Red eléctrica y la inercia",
        "Baterías de litio", "Densidad energética", "Ciclos de carga", "Electrolito sólido",
        "Motor eléctrico y el par", "Inducción electromagnética", "Ley de Faraday", "Ley de Lenz",
        "Óptica geométrica", "Distancia focal", "Difracción", "Interferencia",
        "Láser", "Fibra óptica", "Índice de refracción", "Dispersión de la luz",
        "Sonido y la frecuencia", "Decibelios", "Resonancia", "Efecto Doppler acústico",
        "Ultrasonidos", "Radar", "Lidar", "GPS y la relatividad",
        "Relojes atómicos", "Segundo del SI", "Metrología", "Incertidumbre de medida",
        "Tolerancias en ingeniería", "Ajuste eje-agujero", "Roscas", "Engranajes y la relación",
        "Cojinetes", "Lubricación hidrodinámica", "Tribología", "Desgaste adhesivo",
        "Soldadura y la zona afectada", "Tratamiento térmico del acero", "Temple y revenido", "Acero inoxidable",
        "Hormigón armado", "Pretensado", "Fluencia del hormigón", "Cargas vivas y muertas",
        "Momento flector", "Pandeo", "Cerchas", "Factor de seguridad estructural",
        "Mecánica de fluidos y Bernoulli", "Número de Reynolds en una tubería", "Pérdidas de carga", "Cavitación en bombas",
        "Intercambiador de calor", "Ciclo de Rankine", "Ciclo de Brayton", "Rendimiento de Carnot",
        "Bomba de calor", "Coeficiente de rendimiento", "Aislamiento térmico", "Puente térmico",
        "Convección, conducción y radiación", "Cuerpo gris", "Emitancia", "Inercia térmica",
        "Control PID", "Realimentación negativa", "Estabilidad de un sistema", "Sobreoscilación",
        "Señal y ruido", "Filtro paso bajo", "Muestreo de Nyquist", "Aliasing",
        "Convertidor analógico-digital", "Bit de resolución", "Rango dinámico", "Relación señal-ruido",
        "Visión por computador en una idea", "Red neuronal", "Sobreajuste", "Conjunto de validación",
        "Descenso de gradiente", "Función de pérdida", "Regularización", "Atención en un transformer",
        "Token", "Embedding", "Alucinación de un modelo", "Temperatura de muestreo",
        "Mapa y territorio", "Modelo equivocado útil", "Escala y los órdenes de magnitud", "Estimación de Fermi",
        "Pensar en tasas y no en totales", "Esperanza matemática", "Asimetría de resultados", "Opcionalidad",
        "Círculo de competencia", "Incentivos", "Selección adversa", "Riesgo moral",
        "Principio de Pareto", "Cuello de botella", "Teoría de restricciones", "Ley de Little",
        "Cola y el tiempo de espera", "Variabilidad y las colas", "Throughput", "Trabajo en curso",
        "Deuda técnica", "Acoplamiento y cohesión", "Interfaz estable", "Fallar de forma segura",
        "Idempotencia", "Consistencia eventual", "Relojes lógicos", "Partición de red",
        "Copia en escritura", "Inmutabilidad", "Efectos secundarios", "Pureza de una función",
        "Escritura atómica", "Condición de carrera", "Interbloqueo", "Inanición",
        "Localidad de referencia", "Prefetch", "Falso compartir", "Vectorización",
        "Compilador y las optimizaciones", "Perfilar antes de optimizar", "Ley de Amdahl", "Latencia de cola",
        "Cómo se fabrica un chip", "Sala blanca", "Yield", "Binning",
        "Por qué el cielo es azul", "Por qué el atardecer es rojo", "Arcoíris", "Espejismo",
        "Mareas", "Precesión de los equinoccios", "Fases de la Luna", "Eclipse y la sombra",
        "Por qué vuelan los aviones, de verdad", "Entrada en pérdida de un ala", "Velocidad de pérdida", "Sustentación y el ángulo",
        "Onda de choque en un caza", "Postcombustión", "Relación de derivación de un turbofán", "Compresor axial",
        "Turbina y el álabe", "Materiales de un álabe caliente", "Refrigeración de álabes", "Empuje específico de un reactor",
        "Alcance de Breguet", "Techo de servicio", "Velocidad de mínimo consumo", "Espera en un holding",
        "Navegación inercial", "Giroscopio", "Acelerómetro", "Fusión de sensores",
        "Kalman en cristiano", "Control de actitud de un satélite", "Par de gradiente gravitatorio", "Velas solares",
        "Propulsión nuclear térmica", "Propulsión nuclear eléctrica", "Vela magnética", "Asistencia gravitatoria",
        "Ventana de lanzamiento", "Inclinación y el cosmódromo", "Pérdida por gravedad", "Órbita de transferencia geoestacionaria",
        "Apogeo y perigeo", "Excentricidad", "Nodo ascendente", "Argumento del perigeo",
        "Decaimiento orbital", "Arrastre atmosférico", "Densidad de la termosfera", "Basura espacial y el delta-v para esquivarla",
        "Constelación de satélites", "Latencia de una órbita baja", "Huella de un satélite", "Enlace descendente",
        "Órbita cementerio", "Desorbitar de forma controlada", "Reentrada destructiva", "Balística de la reentrada",
        "Ángulo de reentrada", "Plasma de la reentrada y el silencio de radio", "Paracaídas supersónico", "Retrocohetes de aterrizaje",
        "Tren de aterrizaje de un cohete", "Patas y la energía del impacto", "Quemado de hover-slam", "Reserva de propergol",
        "Margen de mezcla", "Residuos no utilizables", "Presión de vapor", "Subenfriado del oxígeno líquido",
        "Densidad del propergol y el empuje", "Golpe de ariete en una tubería criogénica", "Juntas criogénicas", "Aislamiento de un depósito",
        "Ebullición y el boil-off", "Zero boil-off", "Tanque común", "Alimentación cruzada de propergol",
        "Encendido en el aire de una etapa", "Separación de etapas", "Empuje residual", "Colisión de etapas",
        "Cofia y la separación", "Carga acústica en el despegue", "Vibroacústica", "Ensayo de calificación",
        "Factor de carga", "Aceleración máxima de la carga", "Aisladores de vibración", "Frecuencia propia",
        "Resonancia de un cohete", "Amortiguamiento", "Análisis modal", "Ensayo en mesa vibratoria",
        "Cámara de vacío térmico", "Ciclos térmicos", "Outgassing", "Contaminación molecular",
        "Soldadura por fricción", "Fabricación aditiva de una cámara", "Cobre para refrigerar", "Inconel",
        "Por qué el cobre en una cámara", "Canales fresados", "Impresión de una tobera", "Rugosidad y la capa límite",
        "Eficiencia de combustión", "Longitud característica de la cámara", "Tiempo de residencia", "Inyectores de ducha",
        "Impinging jets", "Atomización del combustible", "Tamaño de gota", "Mezcla antes de quemar",
        "Llama de difusión", "Llama premezclada", "Límites de inflamabilidad", "Apagado de un motor",
        "Reencendido en órbita", "Ullage y el asentamiento", "Aceleración mínima para alimentar", "Adquisición de líquido",
        "Pantallas de adquisición", "Diafragma de un tanque", "Vejiga", "Presurización con helio caliente",
        "Intercambiador en el escape", "Helio disuelto", "Golpe de gas", "Ingestión de gas en la bomba",
        "NPSH", "Inductor de una turbobomba", "Velocidad específica de una bomba", "Curva de la bomba",
        "Acoplamiento bomba-turbina", "Relación de velocidades", "Sellos de una turbobomba", "Cojinete criogénico",
        "Arranque de una turbobomba", "Sobrevelocidad", "Desbalance", "Crítico de revoluciones",
        "Válvula de propergol", "Tiempo de apertura", "Golpe de ariete en el encendido", "Secuencia de válvulas",
        "Encendido por chispa", "Encendido hipergólico", "Torch igniter", "Encendido por láser",
        "Combustión rica y pobre", "Hollín", "Depósitos en la tobera", "Inspección después de un vuelo",
        "Vida de un motor reutilizable", "Ciclos entre revisiones", "Grieta por fatiga térmica", "Inspección no destructiva",
        "Ultrasonidos en un metal", "Rayos X de una soldadura", "Líquidos penetrantes", "Corrientes inducidas",
        "Trazabilidad de un lote", "Por qué se numera una pieza", "Configuración de vuelo", "Control de cambios",
        "Revisión de diseño", "Árbol de fallos", "FMEA", "Redundancia activa y pasiva",
        "Un fallo no tumba el vuelo", "Aborto en la rampa", "Sistema de escape de la tripulación", "Aceleración de un aborto",
        "Traje de presión", "Cabina y la presión parcial de oxígeno", "Hipoxia", "Enfermedad por descompresión",
        "Radiación en un vuelo tripulado", "Dosis", "Blindaje de agua", "Tormentas solares",
        "Por qué entrenar en la centrífuga", "Líquidos en microgravedad", "Cómo se bebe en órbita", "Baño espacial",
        "Soporte vital de ciclo cerrado", "Reciclaje de agua", "Scrubber de CO2", "Sabatier a bordo",
        "Cultivo en órbita", "Por qué las raíces se lían", "Iluminación para plantas", "Polinización sin insectos",
        "Psicología de una misión larga", "Aislamiento", "Retraso de la comunicación", "Autonomía de la tripulación",
        "Por qué Marte es difícil", "Ventanas a Marte", "Aerocaptura", "Escudo inflable",
        "ISRU de oxígeno en Marte", "MOXIE", "Polvo lunar", "Regolito y el oxígeno",
        "Por qué la Luna tiene hielo", "Cráteres en sombra", "Utilidad del hielo", "Energía para extraerlo",
        "Base lunar y la noche de 14 días", "Almacenar energía", "Reactor Kilopower", "Radiadores en el vacío",
        "Por qué un radiador no usa aire", "Temperatura de equilibrio", "Control térmico de un satélite", "Mantas multicapa",
        "Louvers", "Heat pipes", "Material de cambio de fase", "Ciclos día-noche en órbita baja",
        "Paneles desplegables", "Mecanismo de un solo uso", "Para qué sirve un actuador", "Fiabilidad de un despliegue",
        "Antena de alta ganancia", "Haz estrecho", "Apuntado", "Pérdidas de espacio libre",
        "Banda Ku y Ka", "Lluvia y la señal", "Modulación", "Códigos de corrección en un enlace",
        "Por qué un satélite de observación quiere SSO", "Resolución y la apertura", "Órbita y la revisita", "Franja de barrido",
        "Radar de apertura sintética", "Interferometría", "Por qué se ve a través de las nubes", "Resolución en distancia",
        "Relojes de a bordo", "Sincronizar una constelación", "Posición con GNSS", "Multipath",
        "Por qué el GPS necesita relatividad", "Efemerides", "Almanaque", "Dilución de la precisión",
        "Cómo se diseña un ala", "Perfil y el coeficiente de momento", "Torsión del ala", "Flecha",
        "Ala en flecha y el Mach", "Canard", "Estabilidad longitudinal", "Timón de profundidad",
        "Alabeo con alerones", "Guiñada adversa", "Timón de dirección", "Mezcla de mandos",
        "Fly-by-wire", "Leyes de control de un caza", "Envolvente de vuelo", "Protecciones del mando",
        "Por qué un caza es inestable", "Relajación de estabilidad", "Centro de gravedad y el depósito", "Trasvase de combustible",
        "Reabastecimiento en vuelo", "Estela del cisterna", "Pértiga", "Cesta y sonda",
        "Entrada en pérdida profunda", "Barrena", "Recuperación", "Aviso de pérdida",
        "Hielo en el ala", "Botas neumáticas", "Calentadores de borde de ataque", "Por qué el hielo mata la sustentación",
        "Turbulencia de aire claro", "Onda de montaña", "Cizalladura", "Microburst",
        "Techo y visibilidad", "Aproximación ILS", "Sendas de descenso", "Mínimos de aterrizaje",
        "V1, rotación y V2", "Pista balanceada", "Fallo de motor en el despegue", "Subida con un motor",
        "ETOPS", "Despresurización y el descenso de emergencia", "Máscaras", "Tiempo de oxígeno",
        "Caja negra", "Por qué son naranjas", "Registrador de voz", "Qué se investiga en un accidente",
        "Cadena del error", "Cultura justa", "Checklist", "Gestión de recursos de cabina",
        "Por qué los pilotos leen en voz alta", "Sesgo de automatización", "Modo del piloto automático", "Sorpresa de automatización",
        "Mantenimiento y la fatiga de un fuselaje", "Ciclos de presurización", "Corrosión filiforme", "Inspección D",
        "Por qué un avión se retira", "Coste por asiento", "Alcance y la carga de pago", "Reserva de combustible",
        "Viento en cola y el consumo", "Jet stream", "Ruta ortodrómica", "Gran círculo",
        "Cómo elige un despachador la ruta", "Cenizas volcánicas", "Por qué apagan el motor", "Cristal de la cabina",
        "Parabrisas calefactado", "Impacto de ave", "Certificación", "Ensayo de pájaro",
        "Materiales de un fan", "Contención de un álabe suelto", "Por qué el motor no puede reventar el ala", "Fuego en el motor",
        "Extinción y el aislamiento", "APU", "Para qué sirve en tierra", "Arranque con APU",
        "Sistema hidráulico triple", "Fluido Skydrol", "Por qué hay tres", "Ram air turbine",
        "Generador de emergencia", "Baterías de un avión", "Bus eléctrico", "Shedding de cargas",
        "Presurización y las válvulas", "Altitud de cabina", "Por qué duele el oído", "Trompa de Eustaquio",
        "Humedad de cabina", "Por qué es seca", "Jet lag y la luz", "Melatonina con cuidado",
        "Cómo aprende de verdad el cerebro", "Error de predicción", "Myelina y la práctica", "Sueño y lo que acabas de estudiar",
        "Por qué enseñar algo lo fija", "Efecto de prueba", "Ilusión de fluidez", "Subrayar no basta",
        "Mapas conceptuales", "Elaboración", "Ejemplos concretos", "Analogía y dónde falla",
        "Atención y el móvil", "Cambio de tarea", "Coste de la interrupción", "Bloques de foco",
        "Hábitos y la señal", "Fricción", "Entorno y la conducta", "Identidad y la racha",
        "Por qué empiezas y lo dejas", "Valle de la desilusión", "Práctica mínima viable", "Registro honesto",
        "Metas de proceso y de resultado", "Indicador adelantado", "Revisión semanal", "Qué medir y qué no",
        "Decisiones reversibles", "Decisiones de un solo sentido", "Pre-mortem", "Abogado del diablo",
        "Pensar en distribuciones", "El caso medio miente", "Riesgo de ruina", "No apostar el patrimonio",
        "Diversificar de verdad", "Correlación oculta", "Liquidez", "Horizonte temporal",
        "Inflación de estilo de vida", "Ahorro automático", "Fondo de emergencia", "Interés de una deuda",
        "Por qué el tipo compuesto gana al talento un rato", "Paciencia", "Aburrimiento útil", "Constancia aburrida",
        "Leer fuentes primarias", "Quién paga el artículo", "Titular frente al estudio", "Muestra diminuta",
        "Cómo detectar un gráfico tramposo", "Eje cortado", "Porcentaje de un porcentaje", "Base rate",
        "Pensar al revés el argumento", "Qué tendría que ser verdad", "Qué evidencia te haría cambiar", "Actualizar una creencia",
        "Escribir para entender", "Explicarlo en una frase", "La versión para un niño listo", "Dónde está el agujero",
        "Curiosidad como método", "Una pregunta buena", "Qué no sabes todavía", "El siguiente experimento casero",
    ]

    static func pick(done: Set<String>, avoid: String?) -> String? {
        let open = titles.filter { !done.contains($0) }
        let pool = open.filter { $0 != avoid }
        return (pool.isEmpty ? open : pool).randomElement()
    }
}

struct TopicsView: View {
    let store: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offered: String?
    @State private var reel: [String] = []
    @State private var offset: CGFloat = 0
    @State private var spinning = false
    @State private var spinID = 0
    private let row: CGFloat = 52

    private var topicsLeft: Bool {
        TopicBank.titles.contains { !store.doneTopicIDs.contains($0) }
    }

    var body: some View {
        Dashboard(title: "Memoria", centered: true) {
            if let session = store.data.topicSession {
                live(session)
            } else if spinning {
                reelView
            } else if let offered {
                proposal(offered)
            } else if topicsLeft {
                Button("Buscar tema") { search(avoid: nil) }
                    .buttonStyle(CapsuleButton(prominent: true))
            } else {
                Text("Ya no quedan temas nuevos.").foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            // si cambias de pestaña a medias, el cierre no puede dejar el tema anterior
            spinID += 1
            spinning = false
            offset = 0
        }
    }

    // el rollo no se lee en voz: solo cuenta el tema que queda al parar
    private var reelView: some View {
        VStack(spacing: 0) {
            ForEach(Array(reel.enumerated()), id: \.offset) { _, title in
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: row)
                    .padding(.horizontal, 12)
            }
        }
        .offset(y: offset)
        .frame(height: row, alignment: .top)
        .clipped()
        .background(surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.14))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Buscando tema")
    }

    private func proposal(_ topic: String) -> some View {
        VStack(spacing: 20) {
            Text(topic)
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("15 minutos para investigarlo por tu cuenta. Si no te interesa, sáltalo antes de empezar.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("\(TopicBank.titles.filter { !store.doneTopicIDs.contains($0) }.count) por hacer")
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("Saltar") { search(avoid: topic) }
                    .buttonStyle(CapsuleButton())
                Button("Empezar") { _ = store.beginTopic(topic) }
                    .buttonStyle(CapsuleButton(prominent: true))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func live(_ session: TopicSession) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let total = 15.0 * 60
            let left = max(0, session.endsAt.timeIntervalSince(context.date))
            let seconds = Int(left)
            let progress = min(1, max(0, 1 - left / total))
            VStack(spacing: 20) {
                Text(session.topicID)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .accessibilityLabel(seconds > 0 ? "\(seconds / 60) minutos y \(seconds % 60) segundos" : "Tiempo terminado")
                        ProgressView(value: progress)
                            .tint(.white)
                            .accessibilityLabel("Progreso de los 15 minutos")
                        Text(seconds > 0 ? "Investiga el tema por tu cuenta. Puedes terminarlo antes o cancelar." : "Se acabó el tiempo. Márcalo como hecho o cancélalo.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 12) {
                    Button("Cancelar", role: .cancel) { cancel() }
                        .buttonStyle(CapsuleButton())
                    Button(seconds > 0 ? "Terminar" : "Hecho") { finish() }
                        .buttonStyle(CapsuleButton(prominent: true))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func search(avoid: String?) {
        guard !spinning, let picked = TopicBank.pick(done: store.doneTopicIDs, avoid: avoid) else { return }
        if reduceMotion {
            offered = picked
            return
        }
        spinID += 1
        let token = spinID
        let strip = reelStrip(ending: picked)
        // sin esto el offset nuevo se anima desde el rollo anterior
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            reel = strip
            offset = 0
            spinning = true
            offered = nil
        }
        DispatchQueue.main.async {
            guard token == spinID else { return }
            withAnimation(.timingCurve(0.05, 0.8, 0.15, 1, duration: 1.7)) {
                offset = -CGFloat(strip.count - 1) * row
            } completion: {
                guard token == spinID else { return }
                spinning = false
                offered = picked
            }
        }
    }

    private func reelStrip(ending: String) -> [String] {
        var items = (0..<18).compactMap { _ in TopicBank.titles.randomElement() }
        items.append(ending)
        return items
    }

    private func finish() {
        if store.completeTopic() { offered = nil }
    }

    private func cancel() {
        if store.cancelTopic() { offered = nil }
    }
}
