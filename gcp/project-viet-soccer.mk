VIET_SOCCER_PROJECT_ID			:= multicloud-architect-b5e6e149
VIET_SOCCER_SRC					:= $(BASE_PATH)/gcp/viet-soccer
VIET_SOCCER_ARTIFACT_REPOSITORY := asia-northeast1-docker.pkg.dev/multicloud-architect-b5e6e149/viet-soccer-registry

VIET_SOCCER_IMAGES[download-api]	:= 1.0.0
VIET_SOCCER_IMAGES[summary-api]		:= 1.0.0
VIET_SOCCER_IMAGES[youtube-comment]	:= 1.0.16
VIET_SOCCER_IMAGES[youtube-upload]	:= 1.0.0
VIET_SOCCER_MICROSERVICES 			:= download-api summary-api youtube-comment youtube-upload

define make-microservices-targets
viet-soccer-build-$1:
	cd $(VIET_SOCCER_SRC) && \
		PROJECT=$(VIET_SOCCER_PROJECT_ID) \
		REPOSITORY=$(VIET_SOCCER_ARTIFACT_REPOSITORY) \
		DOWNLOAD_API_IMG=download-api \
		SUMMARY_API_IMG=summary-api \
		YOUTUBE_COMMENT_IMG=youtube-comment \
		YOUTUBE_UPLOAD_IMG=youtube-upload \
		DOWNLOAD_API_TAG=${VIET_SOCCER_IMAGES[download-api]} \
		SUMMARY_API_TAG=${VIET_SOCCER_IMAGES[summary-api]} \
		YOUTUBE_COMMENT_TAG=${VIET_SOCCER_IMAGES[youtube-comment]} \
		YOUTUBE_UPLOAD_TAG=${VIET_SOCCER_IMAGES[youtube-upload]} \
		docker-compose \
			-f docker-compose.artifact.yaml \
			build $1

viet-soccer-push-$1:
	docker image push $(VIET_SOCCER_ARTIFACT_REPOSITORY)/$1:${VIET_SOCCER_IMAGES[$1]}
endef

.PHONY: viet-soccer-dev
viet-soccer-dev:
	cd $(VIET_SOCCER_SRC) && \
		PROJECT=$(VIET_SOCCER_PROJECT_ID) \
		docker-compose \
			-f docker-compose.dev.yaml \
			-f docker-compose.emulator.yaml \
			up --build --remove-orphans

$(foreach service,$(VIET_SOCCER_MICROSERVICES),$(eval $(call make-microservices-targets,$(service))))
