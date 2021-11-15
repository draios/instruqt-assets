FROM docker.io/library/golang:1.12.0-alpine3.9

RUN mkdir /app
ADD . /app
WORKDIR /app
RUN go build -o read_sens_file .
CMD ["/app/read_sens_file"]