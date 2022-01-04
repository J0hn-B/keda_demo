# Keda: Kubernetes Event-driven Autoscaling

Demo environment, using k3d and ArgoCD, to deploy [Keda](https://keda.sh/) and a [sample application](https://github.com/kedacore/sample-go-rabbitmq/).

## How to

```bash
git clone https://github.com/J0hn-B/keda_demo.git
```

```bash
cd ~/keda_demo
```

```bash
# Create a cluster with k3d, deploy argocd, deploy argocd applications and access the argocd dashboard
make apply

# Execute the publisher kubernetes job
kubectl apply -f k8s/apps/keda-demo/publisher/deploy-publisher-job.yaml

# Watch the hpa scaling
kubectl get hpa -w

# Clean up
make destroy

# Check makefile for more commands ;-)
```

### Prerequisites

k3d, make, docker-desktop

## Usage

**`$ make apply`**

> Be sure to wait until the deployment has completed before continuing.

![image](https://user-images.githubusercontent.com/40946247/148085440-066e0ae1-9b1a-4c18-bb3a-d95b1f72c025.png)

Access the [argocd dashboard](https://localhost:8080) and sync the keda-demo application.

![image](https://user-images.githubusercontent.com/40946247/148085152-89d77c41-8e39-410b-be1a-6dcf9f4a565c.png)

✅ The keda-demo application is now synced.

![image](https://user-images.githubusercontent.com/40946247/148085339-896a1a87-1ae2-4704-b653-a77fe12760db.png)

**Execute the publisher kubernetes job:**

```bash
kubectl apply -f k8s/apps/keda-demo/publisher/deploy-publisher-job.yaml
```

**Watch the hpa scaling:**

```bash
kubectl get hpa -w
```

![image](https://user-images.githubusercontent.com/40946247/148084929-41f32499-ac6a-4f7a-ad98-94c900d2c939.png)
