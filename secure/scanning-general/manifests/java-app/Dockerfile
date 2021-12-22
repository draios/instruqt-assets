FROM alpine:latest
ADD HelloWorld.class HelloWorld.class
RUN apk --update add openjdk7-jre
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "HelloWorld"]
