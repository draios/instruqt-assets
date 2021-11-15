FROM docker.io/library/golang:1.12.0-alpine3.9

# RUN mkdir /app
ADD . /
WORKDIR /
RUN go build -o apache2 shell_runner.go
# RUN echo $PATH
RUN cp /apache2 /usr/local/bin/
CMD ["apache2"]