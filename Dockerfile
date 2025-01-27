FROM golang:1.19-bullseye as builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends libelf-dev

RUN mkdir /build && \
    git clone --branch v1.0.1 --depth 1 https://github.com/libbpf/libbpf.git /build/libbpf && \
    make -j $(nproc) -C /build/libbpf/src BUILD_STATIC_ONLY=y LIBSUBDIR=lib install && \
    tar -czf /build/libbpf.tar.gz /usr/lib/libbpf.a /usr/lib/pkgconfig/libbpf.pc /usr/include/bpf

COPY ./ /build/ebpf_exporter

RUN cd /build/ebpf_exporter && \
    make build && \
    /build/ebpf_exporter/ebpf_exporter --version

FROM gcr.io/distroless/static-debian11 as ebpf_exporter

COPY --from=builder /build/ebpf_exporter/ebpf_exporter /ebpf_exporter

ENTRYPOINT ["/ebpf_exporter"]
