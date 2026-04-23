.PHONY: all default clean help

CLUSTER_NAME ?= levivannoort
CILIUM_VERSION ?= 1.19.3
ARGOCD_VERSION ?= v3.3.8

all: default

default: kind-configuration-default.yaml
	kind create cluster --name $(CLUSTER_NAME)-default --config kind-configuration-default.yaml
	kubectl cluster-info --context kind-$(CLUSTER_NAME)-default
	cilium install --version 1.19.3
	kubectl apply -k management --server-side --context kind-$(CLUSTER_NAME)-default || true
	kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=60s --context kind-$(CLUSTER_NAME)-default
	kubectl apply -k management --server-side --context kind-$(CLUSTER_NAME)-default
	kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s --context kind-$(CLUSTER_NAME)-default

clean:
	kind delete cluster --name $(CLUSTER_NAME)-default || true

help:
	@echo "Usage:"
	@echo "  make all                     - Create cluster, install Cilium and bootstrap argocd"
	@echo "  make kind-default            - Create a kind cluster with default configuration"
	@echo "  make clean                   - Delete the kind cluster"
