# EKS

## Minikube

### Reset

```shell
minikube stop && minikube delete && minikube start --cpus=2 --memory=2048mb
```

### Addons

```shell
minikube addons enable metrics-server
```

### Get service url

```shell
minikube service boilerplate-service -n front-end --url
```

## Setup

```shell
kubectl apply -f fe/template.yaml
```

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/template.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Load test

```shell
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://boilerplate-service.front-end.svc.cluster.local:8080; done"
```

## Kubectl

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
kubectl get po -n front-end -w
kubectl get pod -n argocd
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
