## Cloud Computing Course Project
#### Secure Data-in-Transit and Data-at-Rest in Containers

# AWS EKS + Istio Setup


## 📌 Prerequisites

✅ AWS account
✅ IAM user with programmatic access (Access Key ID & Secret)
✅ Ubuntu / Mac / WSL / Cloud9 terminal

---

## 📌 1️⃣ Install AWS CLI

**Download and install AWS CLI v2**

**For Linux:**

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify:**

```bash
aws --version
```

---

## 📌 2️⃣ Configure AWS CLI

Run:

```bash
aws configure
```

Provide:

* AWS Access Key ID
* AWS Secret Access Key
* Default region: `ap-south-1`
* Output format: `json`

---

## 📌 3️⃣ Install kubectl

**Download latest kubectl:**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Verify:**

```bash
kubectl version --client
```

---

## 📌 4️⃣ Install eksctl

**Download eksctl:**

```bash
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

**Verify:**

```bash
eksctl version
```

---

## 📌 5️⃣ Create EKS Cluster

**eks-cluster.yaml**

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: secure-cluster
  region: ap-south-1

nodeGroups:
  - name: ng-default
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
```

**Create Cluster:**

```bash
eksctl create cluster -f eks-cluster.yaml
```

Wait 15-20 mins.

---

## 📌 6️⃣ Update kubeconfig

```bash
aws eks --region ap-south-1 update-kubeconfig --name secure-cluster
```

**Check cluster nodes:**

```bash
kubectl get nodes
```

---

## 📌 7️⃣ Install Istio CLI

**Download latest Istio:**

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
```

**Verify:**

```bash
istioctl version
```

---

## 📌 8️⃣ Install Istio on EKS Cluster

**istio-strict-mtls.yaml**

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: demo
  meshConfig:
    enableAutoMtls: true
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
  values:
    global:
      proxy:
        autoInject: enabled
```

**Install:**

```bash
istioctl install -f istio-strict-mtls.yaml -y
```

**Verify installation:**

```bash
kubectl get pods -n istio-system
```

---

## 📌 9️⃣ Deploy Sample Apps (httpbin & sleep)

**httpbin.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        name: httpbin
        ports:
        - containerPort: 80
```
Or apply this command:

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/httpbin/httpbin.yaml

```

**sleep.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: curlimages/curl
        command: ["/bin/sleep", "3650d"]
```
Or apply this command:

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.22/samples/sleep/sleep.yaml
```

**Apply both:**

```bash
kubectl apply -f httpbin.yaml
kubectl apply -f sleep.yaml
```

**Check pods:**

```bash
kubectl get pods
```

---

## 📌  🔒 10️⃣ Apply Destination Rule for mTLS

**destination-rule.yaml**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: httpbin
  namespace: default
spec:
  host: httpbin
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
```

**Apply:**

```bash
kubectl apply -f destination-rule.yaml
```


