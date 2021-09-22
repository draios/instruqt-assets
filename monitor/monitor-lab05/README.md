# Training Lab 5: Troubleshooting HTTP 502 errors

In this scenario we will deploy an example microservice application with 3 services and 4 containers: client, balancer and servers (2).

- The client periodically request a new ticket token.

- The load balancer distributes HTTP requests through servers using HAproxy.

- The servers run a simple example Python application that generate a unique ticket token per request.

ISSUE: The app works well on dev’s laptop using Docker, the same image triggers some 502 HTTP errors on the Kubernetes production environment.

## How to deploy and use this

- `create.sh`: Deploys the application in an existing Kubernetes cluster.
- `triggererror.sh`: Will trigger the 502 HTTP error issue.
- `stoperror.sh`: Will revert the `triggererror.sh` problem, returning to an error-free state.
- `delete.sh`: Removes the application.
