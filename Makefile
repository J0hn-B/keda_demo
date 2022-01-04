#? Keda - K8s

# Vars
REPO := $(shell git rev-parse --show-toplevel)



#? Create a cluster with k3d
.PHONY: apply
apply:
	. ./k3d_cluster.sh && create_cluster && install_argocd \
	&& deploy_argocd_apps \
	&& access_argocd


#? Destroy the cluster 
.PHONY: destroy
destroy:
	. ./k3d_cluster.sh && delete_cluster




# # #* Lint code  ==> make code_lint
.PHONY: code_lint
code_lint:
	@echo "$(GREEN) ==> Github Super-Linter will validate your source code.$(NC) < https://github.com/github/super-linter >"
	docker run --rm -e KUBERNETES_KUBEVAL_OPTIONS=--ignore-missing-schemas -e RUN_LOCAL=true \
	-v $(REPO):/tmp/lint ghcr.io/github/super-linter:slim-v4
	
ifeq ($(shell uname), Linux)
	find $(REPO) -type f -name "super-linter.log" -exec rm -f {} \;
else  
	powershell "Get-ChildItem -Recurse $(REPO) | where Name -match 'super-linter.log' | Remove-Item"
endif

# # #* Run automatic checks for rule violations, against Kubernetes manifests YAML files  ==> make datree
.PHONY: datree
datree:
	for file in k8s/apps/*/*/*.yaml; do \
        echo $$file; cat $$file | docker run -i datree/datree test - --ignore-missing-schemas;  \
    done
	


