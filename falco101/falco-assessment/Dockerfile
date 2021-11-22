FROM docker.io/library/golang:1.12.0-alpine3.9

ARG BINARY_NAME
ARG SECONDS
ARG FILES

ENV BINARY_NAME_IN=$BINARY_NAME
ENV SECONDS_IN=$SECONDS
ENV FILES_IN=$FILES

ADD . /
WORKDIR /
RUN go build -o $BINARY_NAME generic_reader.go
RUN cp /$BINARY_NAME /usr/local/bin/
CMD ${BINARY_NAME_IN} ${SECONDS_IN} ${FILES_IN}}

# # build with:
# docker build \
#     --build-arg BINARY_NAME=binary \
#     -t sysdigtraining/generic_reader .

# # and run with:
# docker run \
#     -e "BINARY_NAME_IN=binary" \
#     -e "SECONDS_IN=2" \
#     -e "FILES_IN=~/GIT/instruqt/README.md ~/GIT lol" \
#     sysdigtraining/generic_reader