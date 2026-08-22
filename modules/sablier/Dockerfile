# Multi-stage build to test a local fork of Sablier.
FROM golang:1.26 AS builder

WORKDIR /src

# Cache dependencies first for faster rebuilds.
COPY go.mod go.sum ./
RUN go mod download

# Build the binary.
COPY . .
ARG VERSION=local-fork
RUN GOFLAGS=-tags=nomsgpack CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags "-s -w \
      -X github.com/sablierapp/sablier/pkg/version.Version=${VERSION} \
      -X github.com/sablierapp/sablier/pkg/version.BuildUser=docker" \
    -o /out/sablier ./cmd/sablier \
    && chmod 0755 /out/sablier

FROM scratch


COPY --from=builder /out/sablier /bin/sablier


ENV TZ=UTC

EXPOSE 10000

ENTRYPOINT [ "/bin/sablier" ]
CMD [ "start" ]
