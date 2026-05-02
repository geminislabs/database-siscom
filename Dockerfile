FROM timescale/timescaledb:2.15.1-pg15

RUN apk add --no-cache \
    git \
    make \
    clang15 \
    llvm15 \
    musl-dev \
    postgresql15-dev

RUN git clone https://github.com/pgpartman/pg_partman.git /tmp/pg_partman && \
    cd /tmp/pg_partman && \
    make && \
    make install && \
    rm -rf /tmp/pg_partman