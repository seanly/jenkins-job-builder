FROM openjdk:17-alpine3.14

COPY --from=mikefarah/yq /usr/bin/yq /usr/bin/yq
RUN apk update && \
    apk add --update --no-cache python3 py3-pip curl wget jq bash
RUN pip install jinja2-cli[yaml]

WORKDIR /jjb

COPY ./ /jjb

ENTRYPOINT ["./create-jobs.sh"]