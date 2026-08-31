# Ficha del Problema - LinkClub

## Contexto

La Universidad Tecnológica de Bolívar cuenta con una amplia variedad de clubes y grupos estudiantiles abiertos a toda la comunidad universitaria, entre ellos grupos de ajedrez, fútbol y teatro, además de otros con intereses igualmente diversos. Estos grupos organizan actividades, eventos y experiencias de forma regular, pero su capacidad de comunicarlas a la comunidad universitaria es limitada.

## El problema

Actualmente no existe una herramienta destinada específicamente a que estos clubes puedan darse a conocer, comunicar sus actividades y ofrecer sus experiencias a quien esté interesado. Cada grupo recurre a canales dispersos y no oficiales (conversaciones informales, publicaciones sueltas en redes sociales, voz a voz) sin que exista un punto central donde toda esa información converja.

Esta carencia tiene dos caras. Por un lado, afecta a los propios integrantes de los clubes, que no cuentan con un canal formal para dar visibilidad a lo que hacen y a las experiencias que ofrecen. Por otro lado, afecta a los estudiantes que aún no pertenecen a ningún grupo pero podrían estar interesados en unirse: sin un lugar donde descubrir qué clubes existen y qué están haciendo, esa información simplemente no les llega.

## Por qué importa

Que esta información llegue al mayor número de personas posible es relevante tanto para la vida estudiantil como para la continuidad de los propios clubes: un grupo que no logra darse a conocer tiene más dificultad para crecer, sostener actividades y atraer nuevos integrantes. La ausencia de una plataforma unificada no es solo una molestia de comunicación, sino una barrera real para la participación estudiantil en la vida extracurricular de la universidad.

## A quién afecta

- **Miembros de clubes**, que necesitan un canal formal para difundir sus actividades.
- **Estudiantes interesados aún no vinculados**, que necesitan un punto de descubrimiento accesible.
- **La comunidad universitaria en general**, cuya vida extracurricular depende en parte de qué tan bien circula esta información.

## Tensiones de calidad

Al centralizar toda la información de clubes en un solo sistema, dos metas de calidad entran en tensión directa:

**Disponibilidad vs. Rendimiento.** Garantizar que el sistema nunca deje de responder ante un fallo de conexión con la base de datos (por ejemplo, mediante reintentos, timeouts o mensajes de error controlados) añade pasos adicionales al procesamiento de cada solicitud, lo que puede aumentar el tiempo de respuesta. Priorizar rendimiento puro —minimizar cada verificación posible— dejaría al sistema más expuesto a fallar visiblemente ante cualquier interrupción del servicio de base de datos.

LinkClub prioriza disponibilidad sobre rendimiento, ya que es preferible que una consulta tarde un poco más en manejar un fallo de forma controlada, a que la aplicación se caiga por completo cuando el estudiante más necesita ver si hay un evento próximo. Esta decisión es consistente con el orden de metas de calidad declarado en la [Sección 1 de arc42](./arc42/01_introduccion_y_metas.md) (Disponibilidad antes que Rendimiento) y con la elección de arquitectura hexagonal, que aísla el manejo de fallos de conexión sin comprometer la lógica de negocio.

## Propuesta

**LinkClub** busca resolver este problema centralizando en una sola aplicación móvil la gestión de avisos, eventos, grupos y noticias de los clubes estudiantiles, de modo que tanto los miembros como cualquier interesado externo puedan mantenerse informados desde un solo lugar.

Concretamente, la aplicación permite a los administradores de club publicar avisos, eventos y noticias asociados a su grupo, mientras que cualquier estudiante,esté o no vinculado a un club, puede explorar el catálogo completo de clubes activos, consultar sus próximas actividades y descubrir grupos afines a sus intereses sin depender de canales informales o de conocer a alguien que ya pertenezca a ellos.

Frente a los canales actuales (grupos de WhatsApp, publicaciones sueltas en redes sociales, voz a voz), LinkClub ofrece un punto único y persistente de información: lo que un club publica queda disponible para toda la comunidad universitaria, no solo para quienes ya forman parte de un grupo cerrado. Esto reduce la dependencia de que la información "llegue por casualidad" y le da a cada club un canal formal y visible, independientemente de qué tan activo sea en redes sociales por su cuenta.
