# Training Lab 7: Image Scanning and CI/CD Pipeline

In this scenario we will deploy a Jenkins application in a Kubernetes cluster, and we will configure two pipelines for automatic Docker image build and scanning using Sysdig Secure.

There are some problems with one of the images that will be built and scanned:
    - It contains OS vulnerabilities (base image)
    - It contains application vulnerabilities (python libraries)
    - It exports port 22, which is not a desirable practice.
    - It must not pass the scan.

## How to deploy and use this?

* `create.sh`: Deploys the application in an existing Kubernetes cluster.
* `populate.sh`: Deploys the pipeline configuration and all required plugins.
* `delete.sh`: Removes the application.
