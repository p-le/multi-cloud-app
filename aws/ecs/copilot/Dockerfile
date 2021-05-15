FROM amazon/aws-cli:2.2.3

WORKDIR /app

RUN curl -Lo /usr/local/bin/copilot \
    https://github.com/aws/copilot-cli/releases/latest/download/copilot-linux \
   && chmod +x /usr/local/bin/copilot \
   && copilot --help

ENTRYPOINT [ "copilot" ]
CMD [ "--help" ]
