#!/bin/bash

#test directly the endpoing quering blackbox container, 
# it needs the host networking enabled at container level
curl "localhost:9115/probe?target=localhost:8000&module=http_2xx&debug=true"