FROM rust:slim-bookworm AS builder

# git earns its place twice over: cargo fetches ears-rs from a git source, and
# nmsr-aas/build.rs shells out to `git rev-parse HEAD` for the version string and fails
# the build outright if it cannot. That is also why .dockerignore keeps .git/.
RUN apt-get update -y && apt-get --no-install-recommends install git libssl-dev pkg-config -y

WORKDIR /tmp/nmsr-rs/

# Build this repository, rather than a clone of upstream.
#
# Upstream's Dockerfile runs `git clone https://github.com/NickAcPT/nmsr-rs/` and builds
# that, ignoring the build context entirely. Which is right for NickAc, since that URL is
# his code - but for a fork it means our changes never reach the image. This file used to
# work around it by leaving the clone in place and copying ten .rs files over the top,
# immediately before the build.
#
# Two things were wrong with that. The clone tracked `main` with no pin, so an image built
# today and one built last month contained different upstream code; and the ten copied
# files were a frozen snapshot that silently reverted upstream's later edits to those same
# files. That is how the build lost `strip_alpha`, and with it the alpha split between the
# skin's first and second layer.
COPY . .

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
