FROM postgres:15

# Instalamos herramientas necesarias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      awscli \
      cron \
      util-linux \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiamos script
COPY backup.sh /app/backup.sh

# Permisos
RUN chmod +x /app/backup.sh