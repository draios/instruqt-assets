#!/bin/bash

while true; do
    # Obtén un número aleatorio entre 1 y 10
    RANDOM_DELAY=$(shuf -i 1-10 -n 1)
    
    # Si el número aleatorio es menor que 8, espera 2 segundos
    if [ $RANDOM_DELAY -lt 8 ]; then
        sleep 2
    fi

    # Hacer la petición con curl
    curl http://javasimpleserver:8030/

    # Si el número aleatorio es 8 o mayor, espera 0.2 segundos (haz varias peticiones rápidas)
    if [ $RANDOM_DELAY -ge 8 ]; then
        sleep 0.2
    fi
done

