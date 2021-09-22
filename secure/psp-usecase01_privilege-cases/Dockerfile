FROM alpine

RUN apk update
RUN apk add sudo
RUN adduser -D user
RUN adduser user wheel
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers

USER user
CMD ["/bin/sh", "-c", "while true; do sleep 10; done"]
