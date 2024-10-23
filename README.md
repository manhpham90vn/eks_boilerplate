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

## Terraform

### Terraform init

```shell
terraform -chdir=infrastructure init
```

### Terraform show changes

```shell
terraform -chdir=infrastructure plan -var-file="terraform.tfvars"
```

### Terraform apply env production

```shell
terraform -chdir=infrastructure apply -var-file="terraform.tfvars" -auto-approve
```

### Terraform destroy

```shell
terraform -chdir=infrastructure destroy -var-file="terraform.tfvars" -auto-approve
```

## Kubectl Apply

```shell
aws eks update-kubeconfig --region ap-southeast-1 --name EKS_Cluster
```

- install metrics-server

```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

- install load balancer controller

```shell
eksctl utils associate-iam-oidc-provider \
    --region ap-southeast-1 \
    --cluster EKS_Cluster \
    --approve
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.3/cert-manager.yaml
wget -O /tmp/v2_9_0_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.9.0/v2_9_0_full.yaml
sed -i 's/your-cluster-name/EKS_Cluster/g' /tmp/v2_9_0_full.yaml
kubectl apply -f /tmp/v2_9_0_full.yaml
```

- apply app front-end

```shell
kubectl apply -f fe/template.yaml
```

- install argocd

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/template.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

## Kubectl

### Cluster Info

```shell
kubectl cluster-info
```

### Node info

```shell
kubectl get no
kubectl get node
```

### Namespace

```shell
kubectl get ns
kubectl get namespace
```

### All

```shell
kubectl get all -n kube-system
kubectl get all -n front-end
```

### Info

```shell
kubectl describe pod/coredns-878d47785-h45sn -n kube-system
```

### Pod

```shell
kubectl get po -n front-end
kubectl get po -n front-end -w
kubectl get pod -n argocd
kubectl get po -n kube-system
kubectl get pod -n front-end
```

### Replicaset

```shell
kubectl get rs -n front-end
kubectl get replicaset -n front-end
```

### Service

```shell
kubectl get svc -n front-end
kubectl get service -n front-end
kubectl delete service boilerplate-service -n front-end
```

### Deployment

```shell
kubectl get deploy -n front-end
kubectl get deployment -n front-end
kubectl get deployment metrics-server -n kube-system
kubectl delete deployment boilerplate-deployment -n front-end
```

### Autoscale

```shell
kubectl get hpa -n front-end
kubectl get horizontalpodautoscalers -n front-end
```

### Ingress

```shell
kubectl get ingress -n front-end
kubectl delete ingress frontend-ingress -n front-end
```

### Top

```shell
kubectl top pod -n front-end
kubectl top node
```

### Test

```shell
hey -z 1m -c 5 -disable-keepalive https://google.com
```
