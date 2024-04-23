FROM golang:1.20.6-alpine3.18 as builder

RUN mkdir /build
WORKDIR /build

COPY . .

RUN go get 
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build app.go

FROM alpine:3.18
ENV JWT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

COPY --from=builder /build/app /
RUN chmod +x /app

ENTRYPOINT ["/app"]
