# cluster-configuration

This repository contains the desired state of Kubernetes manifests in the form of helm templates. It should represent the state of the different clusters. A Kubernetes operator in the form of 'argocd' is used to synchronise the desired state to the cluster by determining whether the live state of the cluster has diverged from the desired state in this repository.

## pre-requisites

- kubernetes cluster: kind, docker
- tools: kubectl, kubectx, helm, kustomize
- source code management: github


## bootstrapping

We'll use `kind` short for 'kubernetes in docker' to create a kubernetes cluster within docker. 

```shell
$ kind create cluster
```

Bootstrapping the cluster requires to run the following command two times, in the initial apply some of the custom-resource-definitions aren't present and subsequently the manifests can't be applied. Make sure you're connected to the right kubernetes cluster before executing the command.

```shell
kubectx <cluster>
```

### bootstrapping | user authentication

Ingest the secret used for authentication by argocd towards the source code management provider, in this case `github`. For this we use a github OAuth application, navigate to `Settings` > `Developer settings` > `OAuth Apps` and create a new application. The important configuration option is the `Authorization callback URL`, which we'll set to `https://localhost:8080/api/dex/callback` - a port that is going to be exposed soon.

After creation of the OAuth application it will present a client id. In addition we'll generate a client secret. These values will be used when creating a secret that is going to be used in the following command:

```shell
kubectl create namespace argocd
```

```shell
kubectl create secret generic github \
--namespace=argocd \
--from-literal=clientId=<client-id> \
--from-literal=clientSecret=<client-secret>
```

An example of the to be created secret can be seen below:

```shell
kubectl create secret generic github \
--namespace=argocd \
--from-literal=clientId=1234567890abcdefghij \
--from-literal=clientSecret=1234567890abcdefghij1234567890abcdefghij
```

```shell
kubectl label secret github --namespace argocd app.kubernetes.io/part-of=argocd
```

The secret we just created will be used by the file that can be found at the following path: `management/argocd-configmap.yaml`.

### bootstrapping | apply

The configuration for the bootstrap is now present and we apply the initial configuration for the cluster by using kubectl with the kustomize option - run the command twice, as the first time the custom resource definition for the application won't be present:

```shell
kubectl apply -k management/
```

To access the cluster we'll add a portforward to the local cluster to be able to access the argocd interface.

```shell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Login through the previously setup 0Auth application by pressing the 'Login with GitHub'.

## rendering

When rendering or unrendering a specific application or operators we add or remove an index from the list within `resources`, in the example below the kyverno operator is being rendered into the cluster.

`management/[applications/operators]/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: argocd

resources:
 - <application-name>.yaml
```