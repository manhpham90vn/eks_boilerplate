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

### Terraform apply

```shell
terraform -chdir=infrastructure apply -var-file="terraform.tfvars" -auto-approve
```

### Terraform destroy

```shell
terraform -chdir=infrastructure destroy -var-file="terraform.tfvars" -auto-approve
```

## Kubectl Apply

- update kubectl config

```shell
aws eks update-kubeconfig --region ap-southeast-1 --name boilerplateCluster
```

- enable iam oidc provider and iamserviceaccount

```shell
eksctl utils associate-iam-oidc-provider \
    --region ap-southeast-1 \
    --cluster boilerplateCluster \
    --approve

eksctl create iamserviceaccount \
    --cluster=boilerplateCluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::047590809543:policy/PolicyForAWSLoadBalancerController \
    --override-existing-serviceaccounts \
    --region ap-southeast-1 \
    --approve

aws ec2 modify-instance-metadata-options \
    --http-put-response-hop-limit 2 \
    --http-tokens required \
    --region ap-southeast-1 \
    --instance-id i-0bb559897c11f90ac
```

- install metrics server

```shell
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm install metrics-server metrics-server/metrics-server -n kube-system
helm uninstall metrics-server -n kube-system
```

- install cert manager

```shell
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true
helm uninstall cert-manager --namespace cert-manager
```

- install load balancer controller

```shell
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --set clusterName=boilerplateCluster \
    --namespace kube-system \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set region=ap-southeast-1 \
    --set vpcId=vpc-0a79b2a9c626f86cf
helm uninstall aws-load-balancer-controller --namespace kube-system
```

- apply app front-end

```shell
kubectl apply -f fe/template.yaml
```

- install argocd

```shell
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-cd argo/argo-cd \
    --namespace argocd \
    --create-namespace
kubectl apply -f argocd/template.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
helm uninstall argo-cd --namespace argocd
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
kubectl get ingresses -n front-end
kubectl delete ing frontend-ingress -n front-end
```

### Top

```shell
kubectl top pod -n front-end
kubectl top node
```

### Logs

```shell
kubectl get events -n kube-system
kubectl -n kube-system logs deployment.apps/coredns
kubectl -n kube-system logs deployment.apps/aws-load-balancer-controller
kubectl logs -n kube-system --tail -1 -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Test

```shell
hey -z 1m -c 5 -disable-keepalive http://manhdev.click
```
