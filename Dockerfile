FROM alpine:latest

RUN apk -U add curl bash git perl openssh-client

# Install secretary
RUN curl -o /usr/bin/secretary -fsSL "https://github.com/meltwater/secretary/releases/download/0.8.0/secretary-`uname -s`-`uname -m`" && \
    chmod +x /usr/bin/secretary && \
    echo "cadb17b3585feb209046aa65475b06aa989d5089  /usr/bin/secretary" | sha1sum -c -

ADD ssh_config.txt /root/.ssh/config
RUN chmod 0600 /root/.ssh/config

# Output directory for the repository with one subdirectory per branch
VOLUME /branches

# Scratch directory where the repository is cloned to
VOLUME /repository

#ENV GITHUB_REPOSITORY_NAME example/example-repo
#ENV GITHUB_TOKEN abc123

#ENV GIT_REPOSITORY_URL git@github.com:example/example-repo.git
#ENV SSH_KEY ENC[KMS,def456]

COPY launch.sh /launch.sh
COPY sync.sh /sync.sh
ENTRYPOINT ["/launch.sh"]
