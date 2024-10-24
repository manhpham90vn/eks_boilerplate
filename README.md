# EKS

## Todo

- [ ] Improve security group, role, autoscaling
- [ ] Add ingress for argocd, prometheus, grafana
- [ ] Limit IP access for argocd, prometheus, grafana endpoint
- [ ] Encrypt secrets in yaml
- [ ] Apply HTTPS
- [ ] Convert front-end app to helm chart
- [ ] Apply demo for front-end and api app (each app uses a different namespace)
- [ ] Use argo rollouts for blue/green deployment
- [ ] Log collector (fluentd/Elasticsearch/Grafana)
- [ ] Terraform remote state (S3)

## Setup

```shell
# Install kubectl
curl -LO https://dl.k8s.io/release/`curl -LS https://dl.k8s.io/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube
sudo mkdir -p /usr/local/bin/
sudo install minikube /usr/local/bin/

# Install terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS Cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

# Install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Install hey
wget -O /tmp/hey_linux_amd64 https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
chmod +x /tmp/hey_linux_amd64
sudo mv /tmp/hey_linux_amd64 /usr/bin/
```

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
minikube service prometheus-server-ext -n prometheus --url
minikube service grafana-ext -n grafana --url
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

# Delete exits iamserviceaccount
eksctl delete iamserviceaccount \
    --cluster=boilerplateCluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller

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
kubectl port-forward service/argo-cd-argocd-server -n argocd 8080:443
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
helm uninstall argo-cd --namespace argocd
```

- install prometheus

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus --namespace prometheus --create-namespace
helm uninstall prometheus --namespace prometheus
```

- install grafana

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana --namespace grafana --create-namespace
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
helm uninstall grafana --namespace grafana
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
kubectl get po -n kube-system
kubectl get po -n front-end -o wide
kubectl get po -n front-end -w
kubectl get pod -n front-end
```

### Replicaset

```shell
kubectl get rs -n front-end
kubectl get rs -n front-end -o wide
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
kubectl get ing -n front-end
kubectl get ingresses -n front-end
kubectl delete ing frontend-ingress -n front-end
```

### Configmap

```shell
kubectl get cm -n front-end -o yaml
kubectl get configmap -n front-end
```

### Force deploy

```shell
kubectl rollout restart deployment boilerplate-deployment -n front-end
```

### Forward

```shell
kubectl port-forward service/argo-cd-argocd-server -n argocd 8080:443
```

### Exec

```shell
kubectl exec -it boilerplate-deployment-5d79c6b64-6djjs -n front-end -- sh
```

### Check diff

```shell
kubectl diff -f fe/template.yaml
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
