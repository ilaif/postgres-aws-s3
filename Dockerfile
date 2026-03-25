# syntax=docker/dockerfile:1

# Build stage: compile postgres-aws-s3 extension
FROM postgres:17 AS builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
  && apt-get install -y \
    python3-boto3 \
    postgresql-server-dev-17 \
    git \
    make \
    gcc \
    postgresql-plpython3-17 \
  && git clone --depth 1 https://github.com/chimpler/postgres-aws-s3 /tmp/postgres-aws-s3 \
  && cd /tmp/postgres-aws-s3 && make install


# Runtime stage: clean image with only the extension files copied in
FROM postgres:17

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
  && apt-get install -y \
    python3-boto3 \
    postgresql-plpython3-17

# Copy compiled extension files from builder
COPY --from=builder /usr/share/postgresql/17/extension/aws_s3* /usr/share/postgresql/17/extension/
COPY --from=builder /usr/lib/postgresql/17/lib/aws_s3* /usr/lib/postgresql/17/lib/

COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["postgres"]
