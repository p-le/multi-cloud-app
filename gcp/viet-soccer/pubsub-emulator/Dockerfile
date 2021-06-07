ARG GCLOUD_SDK_VERSION=342.0.0-slim

FROM google/cloud-sdk:${GCLOUD_SDK_VERSION}

RUN apt-get install -y google-cloud-sdk-pubsub-emulator

ENTRYPOINT [ "gcloud", "beta" , "emulators", "pubsub", "start" ]

