# cluster-configuration

This repository contains the desired state of Kubernetes manifests in the form of helm templates. It should represent the state of the kubernetes cluster. A Kubernetes operator in the form of 'argocd' is used to synchronise the desired state to the cluster by determining whether the live state of the cluster has diverged from the desired state in this repository.

## pre-requisites

- kubernetes cluster: kind, docker
- tools: kubectl, kubectx, helm, kustomize
- source code management: github

## bootstrapping

We'll use `kind` short for 'kubernetes in docker' to create a kubernetes cluster within docker. 

```shell
kind create cluster
```

Make sure you're connected to the right kubernetes cluster before executing the command.

```shell
kubectx <cluster>
```

### bootstrap | user-authentication

Ingest the secret used for authentication by argocd towards the source code management provider, in this case `github`. For this we use a github OAuth application, navigate to `Settings` > `Developer settings` > `OAuth Apps` and create a new application. The important configuration option is the `Authorization callback URL`, which we'll set to `https://localhost:8080/api/dex/callback` - a port that is going to be exposed soon.

After creation of the OAuth application it will present a client id. In addition we'll generate a client secret. These values will be used when creating a secret that is going to be used in the following command:

Option 1: command-line secret creation:

```shell
kubectl create namespace argocd
```

```shell
kubectl create secret generic user-authentication \
--namespace=argocd \
--from-literal=clientId=<client-id> \
--from-literal=clientSecret=<client-secret>
```

An example of the to be created secret can be seen below:

```shell
kubectl create secret generic user-authentication \
--namespace=argocd \
--from-literal=clientId=1234567890abcdefghij \
--from-literal=clientSecret=1234567890abcdefghij1234567890abcdefghij
```

```shell
kubectl label secret user-authentication --namespace argocd app.kubernetes.io/part-of=argocd
```

Option 2: apply secret template object

Alternatively apply the template object for the secret can be found within the `authentication` directory called `user-authentication-secret.yaml` - replace the keys with `< >`:

```shell
kubectl apply -f authentication/user-authentication-secret.yaml
```

The secret we just created will be used by the file that can be found at the following path: `management/argocd-configmap.yaml`. 

[1]: https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#2-configure-argo-cd-for-sso

### bootstrap | scm-authentication



### bootstrap | apply

The configuration for the bootstrap is now present and we apply the initial configuration for the cluster by using kubectl with the kustomize option - requires to run the following command two times, in the initial apply some of the custom-resource-definitions aren't present and subsequently the manifests can't be applied:

```shell
kubectl apply -k management/
```

To access the cluster we'll add a portforward to the local cluster to be able to access the argocd interface.

```shell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Login through the previously setup 0Auth application by pressing the 'Log in via GitHub'.

## rendering

When rendering or unrendering a specific application or operators we add or remove an index from the list within `resources`, in the example below the kyverno operator is being rendered into the cluster.

`management/[ application | operator ]/kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: argocd

resources:
 - [ application | operator ].yaml
```

## rendering | applications

Add the file that is being rendered within the kustomize configuration. This is an argocd application that points to the `applications/<application>` folder in the root of the repository. This allows us to render the application to the cluster by using a helm chart or a set of kustomize files.

`management/applications/<application>.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <application>
  namespace: argocd 
  labels:
    component: applications
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: applications
  source:
    repoURL: https://github.com/levivannoort/cluster-configuration.git
    path: applications/<application>
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: <application>
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      selfHeal: true
      prune: true
```

## rendering | operators

Add the file that is being rendered within the kustomize configuration. This is an argocd application that points to the `operators/<operator>` folder in the root of the repository. This allows us to render the operator to the cluster by using a helm chart or a set of kustomize files.

`management/operators/<operator>.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <operator>
  namespace: argocd 
  labels:
    component: operators
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: operators
  source:
    repoURL: https://github.com/levivannoort/cluster-configuration.git
    path: operators/<operator>
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: <operator>
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      selfHeal: true
      prune: true
```
