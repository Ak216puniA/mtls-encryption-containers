# Cloud Computing Course Project

## Introduction

### Problem Statement

Implement end-to-end encryption for secure,
* **Data-in-transit:** Encrypting communication between containers within a Kubernetes cluster.
* **Data-at-rest:** Encrypting data stored inside container volumes to prevent unauthorized access.

### Architecture Overview

* **Istio Service Mesh with mTLS** to encrypt data-in-transit between services.
* **LUKS (Linux Unified Key Setup)** for encrypting storage volumes mounted inside containers.
* **HashiCorp Vault** for access control and secure management of encryption keys.

### Core Concepts

**Data Security layers:**
Our project concerns data in two major modes, Data-in-transit and Data-at-rest. **Data-in-transit** refers to data actively moving between containers/services within the cluster whereas, **Data-at-rest** refers to the data stored in container volumes. The goal of the project is to ensure that the data in both of these modes remain encrypted and hence secure from unauthorized access.

**mTLS:**
Mutual TLS, or mTLS, is an extension of TLS where both the client and the server authenticate each other using digital certificates, rather than just the server proving its identity. This bidirectional authentication provides a higher level of security by ensuring that only trusted workloads can communicate. In this project, mTLS ensures that all service-to-service communication within the Kubernetes cluster is encrypted and verified using certificates issued and managed by Istio, preventing man-in-the-middle attacks and unauthorized access.

**LUKS:**
LUKS (Linux Unified Key Setup) is the standard for disk encryption on Linux, providing a secure and flexible mechanism for encrypting block devices. It supports multiple encryption algorithms and key management options, making it suitable for protecting sensitive data stored on disk. In context of the given project, LUKS is used to encrypt container volumes, ensuring that data-at-rest remains inaccessible even if the storage medium is compromised or accessed outside the container environment.

**Vault:**
Vault is a tool for securely accessing secrets, encryption keys, and other sensitive data. In this project, Vault is used to control access to LUKS encryption keys, enhancing security for data-at-rest.

## Implementation

### Data-in-transit

**Cluster and service setup:**

In order to implement encrypted data-in-transit we performed the following basic setup to exhibit secure data transition between two seperate services deployed on different pods,

* Create an EKS cluster `secure-cluster` using the configurations stored in eks-cluster.yaml, followed by updating the kubeconfig. The given yaml file describes the metadata and node group information needed to create the cluster.

```bash
eksctl create cluster -f eks-cluster.yaml
aws eks --region ap-south-1 update-kubeconfig --name secure-cluster
```

* Install Istio on the `secure-cluster` using the istio-strict-mtls.yaml which specifies the mTLS enabling and auto-injection of envoy proxy sidecars to handle mTLS between the pods.

```bash
istioctl install -f istio-strict-mtls.yaml -y
```

* Deploy httpbin and sleep services on different pods.

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/httpbin/httpbin.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/sleep/sleep.yaml
```

**Working mechanism:**

* Istio is installed on the `secure-cluster` with sidecar auto-injection enabled, means every Pod deployed in the mesh automatically gets an Envoy proxy sidecar injected. These sidecars handle all inbound/outbound traffic and handle mTLS transparently. 
* As we deployed `httpbin` and `sleep` services on pods, both services have Envoy sidecar injected. The services do not talk to each other directly and their traffic is routed via Envoy. 
* The mTLS is enforced in STRICT mode using PeerAuthentication ensuring that all inter-service communication must be encrypted and authenticated via TLS with certificates issued by Istio’s internal CA.

**Example data-in-transit:**

1. Pod A (sleep) sends a request to Pod B (httpbin)​
2. Both pods have Envoy sidecars injected automatically​
3. Traffic from sleep → sleep-sidecar → httpbin-sidecar → httpbin​
4. Envoy proxies negotiate mTLS using Istio-issued certs​
5. If certificate auth fails, traffic is rejected (no fallback to plaintext)​

---

### Data-at-rest

**Encrypting a virtual disk with LUKS:**

A virtual disk can be created and encrypted using LUKS in the following manner,

```bash
# Step 1: Create a 1 GB disk file
dd if=/dev/zero of=encrypted_container.img bs=1M count=1024

# Step 2: Format with LUKS encryption
sudo cryptsetup luksFormat encrypted_container.img

# Step 3: Unlock and map the volume
sudo cryptsetup luksOpen encrypted_container.img encrypted_container

# Step 4: Format as ext4 and mount
sudo mkfs.ext4 /dev/mapper/encrypted_container
sudo mount /dev/mapper/encrypted_container /mnt/encryted_data
```

**Integrating encrypted volume with Kubernetes:**

In order to integrate the created encrypted volume with Kubernetes, we defined a hostPath-base PersistentVolume pointing to `/mnt/encrypted_data`. A PersistentVolumeClaim, or PVC, is then generated which is further used by the pod to mount at `/data`. Any file written to `/data` inside the pod is physically encrypted and stored via LUKS on the local disk at the path `/mnt/encrypted_data`, with its encrypted form stored inside the `encrypted_container.img`.

---

### Vault

**Setup Vault on Kubernetes:**

For vault, we added HashiCorp Helm repository and updated the charts. Followed by creating a new namespace for vault. Command for the same are as follows,

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update​

kubectl create namespace vault​
```

**Storing mTLS certificates in Vault:**

The sensitive mTLS certificates can be secured in the Vault following these simple steps,

1. Log into Vault using the root token
2. Store certificates under `secret/mtls` path

Stored secrets can be verified by running `vault kv get secret/mtls​`

## Project Setup

To setup the project, the following dependencies need to be installed and configured:

### Prerequisites

* AWS account
* IAM user with programmatic access (Access Key ID & Secret)
* Ubuntu / Mac / WSL / Cloud9 terminal

### Installations

**1. AWS CLI**

**Installation (Linux):**

```bash
# Installation (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure and provide,
# * AWS Access Key ID
# * AWS Secret Access Key
# * Default region: `ap-south-1`
# * Output format: `json`
aws configure
```

**2. kubectl**

```bash
# Installation (Linux)
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**3. eksctl**

```bash
# Installation (Linux)
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

**4. Istio CLI**

```bash
# Installation (Linux)
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
```

**5. cryptsetup**

```bash
# Installation (Linux)
sudo apt update
sudo apt install cryptsetup
```

## Testing and Results

**Verifying mTLS and secure pod-to-pod communication:**

![](results/image1.jpeg?raw=true)

![](results/image2.jpeg?raw=true)

![](results/image3.jpeg?raw=true)

**Encrypted container using LUKS:**

![](results/image4.jpeg?raw=true)

**Encrypted data stored inside container image:**

![](results/image5.jpeg?raw=true)
