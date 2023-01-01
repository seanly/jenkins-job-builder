FROM mikefarah/yq as yq

FROM openjdk:17-alpine3.14
COPY --from=yq /usr/bin/yq /usr/bin/yq
RUN apk update && \
    apk add --update --no-cache python3 py3-pip curl wget jq bash
RUN pip install jinja2-cli[yaml]
