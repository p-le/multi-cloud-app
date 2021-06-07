SYSTEM_PACKAGE_PROJECT_ID	:= multicloud-architect-b5e6e149
SYSTEM_PACKAGE_SRC			:= $(BASE_PATH)/gcp/cloudrun/system-package
SYSTEM_PACKAGE_IMG			:= system-package
SYSTEM_PACKAGE_IMG_TAG 		:= 1.0.0


.PHONY: system-package-gcloud-authenticate
system-package-gcloud-authenticate:
	@$(MAKE) gcloud-authenticate \
		CONFIGURATION_NAME=system-package \
		PROJECT_ID=$(SYSTEM_PACKAGE_PROJECT_ID)


.PHONY: system-package-artifact-registry-authenticate
system-package-artifact-registry-authenticate:
	@$(MAKE) gcloud-authenticate-artifact-registry \
		PROJECT_ID=$(SYSTEM_PACKAGE_PROJECT_ID) \
		HOSTNAMES=asia-northeast1-docker.pkg.dev


.PHONY: system-package-build-image
system-package-build-image:
	cd $(SYSTEM_PACKAGE_SRC) && \
		docker image build -t \
		$(SYSTEM_PACKAGE_IMG):$(SYSTEM_PACKAGE_IMG_TAG) .


.PHONY: system-package-test-image
system-package-test-image: PORT := 8080
system-package-test-image: system-package-build-image
	@cd $(SYSTEM_PACKAGE_SRC) && \
		docker container run \
			--rm -it \
			-e PORT=$(PORT) \
			-p $(PORT):$(PORT) \
			--name system-package \
			$(SYSTEM_PACKAGE_IMG):$(SYSTEM_PACKAGE_IMG_TAG)

.PHONY: system-package-test-emulator
system-package-test-emulator: PORT := 8085
system-package-test-emulator:
	@docker container run \
		--rm -it \
		--net=system-package \
		--name system-package-emulator \
		-p $(PORT):$(PORT) \
		system-package-emulator:$(GCLOUD_SDK_VERSION) \
			gcloud beta emulators system-package start \
			--project=$(SYSTEM_PACKAGE_PROJECT_ID) \
			--host-port=0.0.0.0:$(PORT)


.PHONY: system-package-push-image
system-package-push-image: system-package-build-image
	@$(MAKE) gcloud-activate-configuration PROJECT_ID=$(SYSTEM_PACKAGE_PROJECT_ID)
	docker image tag \
		$(SYSTEM_PACKAGE_IMG):$(SYSTEM_PACKAGE_IMG_TAG) \
		asia-northeast1-docker.pkg.dev/$(SYSTEM_PACKAGE_PROJECT_ID)/system-package/$(SYSTEM_PACKAGE_IMG):$(SYSTEM_PACKAGE_IMG_TAG)
	docker image push asia-northeast1-docker.pkg.dev/$(SYSTEM_PACKAGE_PROJECT_ID)/system-package/$(SYSTEM_PACKAGE_IMG):$(SYSTEM_PACKAGE_IMG_TAG)
