# EKS

## Command Kubectl

### Cluster Info

```shell
kubectl cluster-info
```

### Node info

```shell
kubectl get node
kubectl get no
```

### Namespace

```shell
kubectl get namespace
kubectl get ns
```

### All

```shell
kubectl get all -n front-end
```

### Pod

```shell
kubectl get pod -n front-end
kubectl get po -n front-end
```

### Replicaset

```shell
kubectl get replicaset -n front-end
kubectl get rs -n front-end
```

### Service

```shell
kubectl get service -n front-end
kubectl get svc -n front-end
```

### Deployment

```shell
kubectl get deployment -n front-end
kubectl get deploy -n front-end
```

### Autoscale

```shell
kubectl get horizontalpodautoscalers -n front-end
kubectl get hpa -n front-end
```

### Top

```shell
kubectl top pod -n front-end
kubectl top node
```

## Command Minikube

### Get service url

```shell
minikube service boilerplate-service -n front-end --url
```

### Start

```shell
minikube start --cpus=2 --memory=2048mb
```

### Stop

```shell
minikube stop && minikube delete
```

### Addons

```shell
minikube addons enable metrics-server
```
