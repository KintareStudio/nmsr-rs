FROM rust:slim-bookworm AS builder

WORKDIR /tmp/

RUN apt-get update -y && apt-get --no-install-recommends install git libssl-dev pkg-config -y
RUN git clone https://github.com/NickAcPT/nmsr-rs/

WORKDIR /tmp/nmsr-rs/

RUN git checkout main

# Overlay local Kintare customizations on top of upstream
COPY ./nmsr-aas/src/model/request/mode.rs /tmp/nmsr-rs/nmsr-aas/src/model/request/mode.rs
COPY ./nmsr-aas/src/model/request/mod.rs /tmp/nmsr-rs/nmsr-aas/src/model/request/mod.rs
COPY ./nmsr-aas/src/model/request/entry.rs /tmp/nmsr-rs/nmsr-aas/src/model/request/entry.rs
COPY ./nmsr-aas/src/model/resolver/mod.rs /tmp/nmsr-rs/nmsr-aas/src/model/resolver/mod.rs
COPY ./nmsr-aas/src/routes/render.rs /tmp/nmsr-rs/nmsr-aas/src/routes/render.rs
COPY ./nmsr-aas/src/routes/render_model.rs /tmp/nmsr-rs/nmsr-aas/src/routes/render_model.rs
COPY ./nmsr-aas/src/routes/render_skin.rs /tmp/nmsr-rs/nmsr-aas/src/routes/render_skin.rs
COPY ./nmsr-aas/src/routes/mod.rs /tmp/nmsr-rs/nmsr-aas/src/routes/mod.rs
COPY ./nmsr-aas/src/routes/query.rs /tmp/nmsr-rs/nmsr-aas/src/routes/query.rs
COPY ./nmsr-aas/src/routes/extractors.rs /tmp/nmsr-rs/nmsr-aas/src/routes/extractors.rs

RUN RUSTFLAGS="-Ctarget-cpu=native" cargo build --release --bin nmsr-aas --features ears --package nmsr-aas

FROM rust:slim-bookworm

RUN apt-get update -y && apt-get --no-install-recommends install mesa-vulkan-drivers -y

WORKDIR /nmsr/

COPY --from=builder /tmp/nmsr-rs/target/release/nmsr-aas /nmsr/nmsr-aas
COPY ./config.toml /nmsr/config.toml

ENV NMSR_USE_SMAA=1
ENV NMSR_SAMPLE_COUNT=1
ENV WGPU_BACKEND=vulkan
ENV RUST_BACKTRACE=1

RUN chmod +x /nmsr/nmsr-aas

EXPOSE 8080

# Set the entrypoint script
CMD /nmsr/nmsr-aas -c config.toml
