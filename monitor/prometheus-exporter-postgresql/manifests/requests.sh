#!/bin/bash

kubectl exec -it postgres-7c875964dd-vfr4t -c postgres -- pgbench -i -d postgresdb -U postgresadmin 

watch -n 11 kubectl exec -it postgres-7c875964dd-vfr4t -c postgres -- pgbench -i -d postgresdb -U postgresadmin

watch -n 43 kubectl exec -it postgres-7c875964dd-vfr4t -c postgres -- pgbench -i -d postgresdb -U postgresadmin 
