FROM alpine:3.7
ENV CLOUD_SDK_VERSION 234.0.0

# .config is the volume that persists
ENV KUBECONFIG /non-privileged/.config/.kube

ENV PATH /google-cloud-sdk/bin:$PATH
RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        git \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version && \
    gcloud components install kubectl && \
    adduser -D -u 1000 -h /non-privileged non-privileged

# last line: add a user, with no password, uid 1000, home-folder /non-privileged, username non-privileged

# Create the .config folder, as the user, otherwise it's mounted as root. Thanks Docker.
RUN mkdir /non-privileged/.config
RUN mkdir /non-privileged/.ssh

RUN chown -R non-privileged:non-privileged /non-privileged

USER non-privileged

# Set the workdir to the home-folder of the non-privileged user
WORKDIR /non-privileged

VOLUME ["/non-privileged/.config"]
