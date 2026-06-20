# syntax=docker/dockerfile:1

ARG APP_NAME="karate"
ARG APP_BIN="/bin/${APP_NAME}"
ARG APP_DIR="/${APP_NAME}"
ARG APP_EXECUTABLE="${APP_DIR}/${APP_NAME}.jar"
ARG APP_FEATURES_DIR="${APP_DIR}/features"
ARG APP_TARGET_DIR="${APP_DIR}/target"
ARG KARATE_VERSION="2.0.9"
ARG KARATE_SHA256="94b088dc8dddf28808d0d420b2d2e3656f60a9e65563aa5f5a798394701d6c09"
ARG KARATE_JAVA_RUNTIME="temurin21"
ARG KARATE_JAVA_IMAGE="eclipse-temurin:21-jre-alpine@sha256:704db3c40204a44f471191446ddd9cda5d60dab40f0e15c6507b815ed897238b"

FROM alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d AS builder

ARG APP_DIR
ARG APP_EXECUTABLE
ARG KARATE_VERSION
ARG KARATE_SHA256

WORKDIR ${APP_DIR}

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk add --no-cache curl && \
    curl -fsSL "https://github.com/karatelabs/karate/releases/download/v${KARATE_VERSION}/karate-${KARATE_VERSION}.jar" -o "${APP_EXECUTABLE}" && \
    echo "${KARATE_SHA256}  ${APP_EXECUTABLE}" | sha256sum -c -

FROM ${KARATE_JAVA_IMAGE}

ARG REVISION=""
ARG CREATED=""
ARG KARATE_VERSION
ARG KARATE_JAVA_RUNTIME

LABEL org.opencontainers.image.title="karate" \
      org.opencontainers.image.description="Coroboros Karate API testing image (Karate ${KARATE_VERSION} + ${KARATE_JAVA_RUNTIME})" \
      org.opencontainers.image.source="https://gitlab.com/coroboros/infrastructure/karate" \
      org.opencontainers.image.version="${KARATE_VERSION}-${KARATE_JAVA_RUNTIME}" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.authors="Coroboros <ob@coroboros.com>" \
      org.opencontainers.image.vendor="Coroboros" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}"

ARG APP_NAME
ARG APP_BIN
ARG APP_DIR
ARG APP_EXECUTABLE
ARG APP_FEATURES_DIR
ARG APP_TARGET_DIR

ENV LANG="C.UTF-8"

WORKDIR ${APP_DIR}

COPY --from=builder "${APP_DIR}" "${APP_DIR}"

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    printf '#!/bin/bash\nexec java -jar %s "$@"\n' "${APP_EXECUTABLE}" > "${APP_BIN}" && \
    chmod +x "${APP_BIN}" && \
    mkdir -p "${APP_FEATURES_DIR}" "${APP_TARGET_DIR}" && \
    addgroup -g 10001 "${APP_NAME}" && \
    adduser -u 10000 -D -G "${APP_NAME}" -H -S -s /bin/bash "${APP_NAME}" && \
    chown -R 10000:10001 "${APP_DIR}" && \
    apk upgrade --no-cache && \
    apk add --no-cache bash ca-certificates

VOLUME ${APP_FEATURES_DIR}
VOLUME ${APP_TARGET_DIR}

USER 10000:10001

ENTRYPOINT [ "karate" ]
CMD [ "/karate/features" ]
