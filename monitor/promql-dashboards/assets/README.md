# Access to the cluster

## Kubeconfig 

You can retrieve the Kubeconfig using: 

```
$ make
```

or

```
$ make kubeconfig
```
Don't forget to add the kubeconfig as an env var so you are able to connect to the cluster: 

```
$ export KUBECONFIG=`pwd`/kubeconfig
```

## SSH Access

All the nodes in the cluster are accesible through a pre-configured bastion.
First, look at the internal IP for the node you want to access to: 

```
$ kubectl get nodes -o wide
NAME                            STATUS   ROLES    AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION   CONTAINER-RUNTIME
ip-172-20-39-134.ec2.internal   Ready    node     72s     v1.15.0   172.20.39.134   <none>        Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-39-231.ec2.internal   Ready    node     72s     v1.15.0   172.20.39.231   <none>        Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-41-202.ec2.internal   Ready    master   2m27s   v1.15.0   172.20.41.202   <none>        Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3
ip-172-20-57-213.ec2.internal   Ready    node     78s     v1.15.0   172.20.57.213   <none>        Debian GNU/Linux 9 (stretch)   4.9.0-9-amd64    docker://18.6.3

```

Look at the INTERNAL-IP column and select the IP you want to connect to, and do: 

```
$ make ssh IP=<IP_ADDRESS>
```

For example: 

```
$ make ssh IP=172.20.41.202
```

This would connect to the master node ip-172-20-41-202.ec2.internal.


