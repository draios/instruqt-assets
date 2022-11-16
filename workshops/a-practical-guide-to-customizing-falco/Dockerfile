FROM openjdk:8u181-jre-alpine
  
EXPOSE 1389
EXPOSE 8888

RUN apk update && apk add curl

COPY *.jar /app/app.jar

CMD IP=`ip route | sed -n -e 's/^default via \([[:alnum:].]*\).*/\1/p'` && java -jar /app/app.jar -i $IP -p 8888
