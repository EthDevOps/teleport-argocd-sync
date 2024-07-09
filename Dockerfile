FROM alpine
RUN mkdir /k8s-configs
ARG TARGETARCH


RUN apk add curl bash nano jq yq

# install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" && mv kubectl /usr/bin && chmod +x /usr/bin/kubectl

# install argocd cli
RUN curl -sSL -o /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${TARGETARCH} && chmod +x /usr/bin/argocd

# install teleport cli
RUN curl https://goteleport.com/static/install.sh | bash -s 16.0.4 oss

COPY sync.sh /usr/local/bin/sync.sh
RUN chmod +x /usr/local/bin/sync.sh


