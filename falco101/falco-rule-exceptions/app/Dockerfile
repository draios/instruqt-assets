FROM docker.io/library/golang:1.12.0-alpine3.9

RUN mkdir /app
ADD . /app
WORKDIR /app
RUN go build -o etc-writer .
CMD ["/app/main"]