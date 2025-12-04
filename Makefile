.PHONY: all default cilium clean

CLUSTER_NAME ?= cc
KUBE_VERSION ?= v1.34.0
CILIUM_VERSION ?= 1.18.4

all: default

default: kind-configuration-default.yaml
	kind create cluster --name $(CLUSTER_NAME)-default --config kind-configuration-default.yaml
	kubectl cluster-info --context kind-$(CLUSTER_NAME)-default

cilium: kind-configuration-cilium.yaml
	kind create cluster --name $(CLUSTER_NAME)-cilium --config kind-configuration-cilium.yaml
	kubectl cluster-info --context kind-$(CLUSTER_NAME)-cilium

cilium-installation:
	echo "todo: helm install or declarative approach"

clean:
	kind delete cluster --name $(CLUSTER_NAME) || true
	kind delete cluster --name kind-$(CLUSTER_NAME)-cilium || true

help:
	@echo "Usage:"
	@echo "  make default      - Create a kind cluster with default CNI (name: kind)"
	@echo "  make cilium       - Create a kind cluster with Cilium CNI (name: kind-cilium)"
	@echo "  make clean        - Delete both default and Cilium kind clusters"
