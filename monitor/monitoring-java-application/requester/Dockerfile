FROM alpine:latest

# Instalar curl y otros paquetes necesarios
RUN apk add --no-cache curl bash

# Copia el script al contenedor
COPY requester.sh /requester.sh

# Ejecuta el script al iniciar el contenedor
CMD ["/requester.sh"]

