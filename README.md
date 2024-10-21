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

## Command Minikube

### Get service url

```shell
minikube service boilerplate-service -n front-end --url
```
