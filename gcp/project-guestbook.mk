GUESTBOOK_APP_PROJECT_ID	:= multicloud-architect-b5e6e149
GUESTBOOK_APP_SRC			:= $(BASE_PATH)/gcp/guestbook-app
GUESTBOOK_APP_IMG			:= guestbook-app
GUESTBOOK_APP_IMG_TAG 		:= 1.0.0


.PHONY: guestbook-app-gcloud-authenticate
guestbook-app-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=guestbook-app \
		PROJECT_ID=$(GUESTBOOK_APP_PROJECT_ID)

.PHONY: guestbook-app-kubectl-context
guestbook-app-kubectl-context: REGION := asia-northeast1
guestbook-app-kubectl-context: CLUSTER_NAME := simple-regional-cluster-6db5
guestbook-app-kubectl-context:
	@$(MAKE) gcloud-sdk CMD="gcloud container clusters get-credentials --region $(REGION) $(CLUSTER_NAME)"

.PHONY: guestbook-app-build-image
guestbook-app-build-image:
	cd $(GUESTBOOK_APP_SRC) && \
		docker image build -t \
		$(GUESTBOOK_APP_IMG):$(GUESTBOOK_APP_IMG_TAG) .

.PHONY: guestbook-app-test-image
guestbook-app-test-image: PORT := 8080
guestbook-app-test-image: guestbook-app-build-image
	docker container run \
		--rm -it \
		-e PORT=$(PORT) \
		-p $(PORT):$(PORT) \
		$(GUESTBOOK_APP_IMG):$(GUESTBOOK_APP_IMG_TAG)

.PHONY: guestbook-app-push-image
guestbook-app-push-image: guestbook-app-build-image
	docker image tag \
		$(GUESTBOOK_APP_IMG):$(GUESTBOOK_APP_IMG_TAG) \
		$(ARTIFACT_REPOSITORY_REGION)-docker.pkg.dev/$(GUESTBOOK_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(GUESTBOOK_APP_IMG):$(GUESTBOOK_APP_IMG_TAG)
	docker image push $(ARTIFACT_REPOSITORY_REGION)-docker.pkg.dev/$(GUESTBOOK_APP_PROJECT_ID)/$(ARTIFACT_REPOSITORY_NAME)/$(GUESTBOOK_APP_IMG):$(GUESTBOOK_APP_IMG_TAG)

.PHONY: guestbook-app-deploy
guestbook-app-deploy:
	@$(MAKE) guestbook-app-kubectl CMD="kubectl apply -f /frontend/manifests/deployment.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl apply -f /frontend/manifests/service.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl apply -f /redis-cluster/manifests/redis-leader.deployment.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl apply -f /redis-cluster/manifests/redis-leader.service.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl apply -f /redis-cluster/manifests/redis-follower.deployment.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl apply -f /redis-cluster/manifests/redis-follower.service.yaml"

.PHONY: guestbook-app-delete
guestbook-app-delete:
	@$(MAKE) guestbook-app-kubectl CMD="kubectl delete -f /frontend/manifests/service.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl delete -f /frontend/manifests/deployment.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl delete -f /redis-cluster/manifests/redis-leader.service.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl delete -f /redis-cluster/manifests/redis-leader.deployment.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl delete -f /redis-cluster/manifests/redis-follower.service.yaml"
	@$(MAKE) guestbook-app-kubectl CMD="kubectl delete -f /redis-cluster/manifests/redis-follower.deployment.yaml"


.PHONY: guestbook-app-kubectl
guestbook-app-kubectl:
	@$(MAKE) gcloud-sdk ADDITIONAL_VOLUMES="\
		-v $(GUESTBOOK_APP_SRC)/redis-cluster/manifests:/redis-cluster/manifests \
		-v $(GUESTBOOK_APP_SRC)/frontend/manifests:/frontend/manifests"
