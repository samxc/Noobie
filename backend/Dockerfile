FROM golang:1.26-bookworm AS build

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/noobie-backend ./cmd/noobie

FROM gcr.io/distroless/base-debian12

WORKDIR /app
COPY --from=build /out/noobie-backend /app/noobie-backend
ENV NOOBIE_DATA_DIR=/app/data
EXPOSE 8091

ENTRYPOINT ["/app/noobie-backend"]
CMD ["serve", "--http=0.0.0.0:8091"]
