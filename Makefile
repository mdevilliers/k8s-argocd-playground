
KIND_INSTANCE=k8s-argocd-playground

# creates a K8s instance
.PHONY: k8s_new
k8s_new:
	kind create cluster --config ./kind/kind.yaml --name $(KIND_INSTANCE)

# deletes a k8s instance
.PHONY: k8s_drop
k8s_drop:
	kind delete cluster --name $(KIND_INSTANCE)

# sets KUBECONFIG for the K8s instance
.PHONY: k8s_connect
k8s_connect:
	kind export kubeconfig --name $(KIND_INSTANCE)

# created following instructions here - https://argoproj.github.io/argo-cd/getting_started/
.PHONY: install_argocd
install_argocd: k8s_connect
	kubectl create namespace argo-cd
	kubectl apply -n argo-cd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl patch svc argocd-server -n argo-cd -p '{"spec": {"type": "LoadBalancer"}}'

PHONY: argocd_port_forward
argocd_port_forward: k8s_connect
	kubectl port-forward svc/argocd-server -n argo-cd 8080:443

.PHONY: argocd_admin_password
argocd_get_admin_password: k8s_connect
	kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# install argocd rollouts following instructions here - https://argoproj.github.io/argo-rollouts/installation/#controller-installation
.PHONY: install_argocd_rollouts
install_argocd_rollouts: k8s_connect
	kubectl create namespace argo-rollouts
	kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# install argocd workflow following instructions here - https://argoproj.github.io/argo-events/quick_start/
# NOTE: 'argo' namespace used as hardcoded in the script
.PHONY: install_argocd_workflow
install_argocd_workflow: k8s_connect
	kubectl create namespace argo
	kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/install.yaml
	# install eventbus
	kubectl create namespace argo-events
	kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml

.PHONY: argocd_rollout_dashboard
argocd_rollout_dashboard: k8s_connect
	kubectl argo rollouts dashboard

.PHONY: install_guestbook
install_guestbook:
	helm install -f ./helm/guestbook/values.yaml my-guestbook ./helm/guestbook
