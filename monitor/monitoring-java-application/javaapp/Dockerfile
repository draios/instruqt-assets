FROM openjdk:11-jre-slim

# Copia el JAR de la aplicación y jmx_exporter en el contenedor
COPY target/javaapp-1.0-SNAPSHOT.jar /app/javaapp.jar
COPY jmx_prometheus_javaagent-0.16.0.jar /app/jmx_prometheus_javaagent.jar
COPY config.yaml /app/config.yaml

# Expone el puerto 8030 de la aplicación, el puerto JMX (por ejemplo, 9010) y el puerto del jmx_exporter (por ejemplo, 9090)
EXPOSE 8030 9010 9090

# Ejecuta la aplicación con jmx_exporter como agente Java
#CMD ["java", "-javaagent:/app/jmx_prometheus_javaagent.jar=9090:/app/config.yaml", "-Dcom.sun.management.jmxremote", "-Dcom.sun.management.jmxremote.port=9010", "-Dcom.sun.management.jmxremote.rmi.port=9010", "-Dcom.sun.management.jmxremote.authenticate=false", "-Dcom.sun.management.jmxremote.ssl=false", "-Djava.rmi.server.hostname=0.0.0.0", "-jar", "/app/javaapp.jar","-Djava.rmi.server.hostname=0.0.0.0"]
CMD ["java", "-Xms100m", "-Xmx1g", "-javaagent:/app/jmx_prometheus_javaagent.jar=9090:/app/config.yaml", "-Dcom.sun.management.jmxremote", "-Dcom.sun.management.jmxremote.port=9010", "-Dcom.sun.management.jmxremote.rmi.port=9010", "-Dcom.sun.management.jmxremote.authenticate=false", "-Dcom.sun.management.jmxremote.ssl=false", "-Djava.rmi.server.hostname=0.0.0.0", "-jar", "/app/javaapp.jar","-Djava.rmi.server.hostname=0.0.0.0"]

