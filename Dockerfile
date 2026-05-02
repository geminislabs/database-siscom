FROM timescale/timescaledb:2.15.1-pg15

RUN apt-get update && \
    apt-get install -y postgresql-15-partman && \
    rm -rf /var/lib/apt/lists/*