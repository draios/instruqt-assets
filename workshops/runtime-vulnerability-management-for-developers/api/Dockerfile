FROM golang:1.20.6-alpine3.18 as builder

RUN mkdir /build
WORKDIR /build

COPY . .

RUN apk add git openssl

# Hacky way to generate cert for this example app
RUN openssl req -x509 -newkey rsa:2048 -keyout myservice.key -out myservice.cert -days 365 -nodes -subj "/CN=myservice.example.com"


RUN go get 
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build app.go

FROM alpine:3.18.2
ENV JWT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c


COPY --from=builder /build/app /build/myservice.cert /build/myservice.key /
RUN chmod +x /app

ENTRYPOINT ["/app"]
