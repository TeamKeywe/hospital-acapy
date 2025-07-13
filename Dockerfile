FROM ghcr.io/openwallet-foundation/acapy-agent:py3.12-1.2.4

USER root

# 필요한 패키지 설치
RUN apt update && apt install -y \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /configs /data

# 파일 복사
COPY entrypoint.sh /entrypoint.sh
COPY init_wallets.sh /init_wallets.sh
COPY config.yml /configs/config.yml
COPY data/hospital.csv /data/hospital.csv

RUN chmod +x /entrypoint.sh /init_wallets.sh

ENTRYPOINT ["/entrypoint.sh"]