FROM ubuntu:22.04

ENV SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy \
    SQUID_USER_ID=10000 \
    SQUID_GROUP_ID=10000

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y netcat squid-openssl \
 && rm -rf /var/lib/apt/lists/* \
 && groupmod -g ${SQUID_GROUP_ID} ${SQUID_USER} \
 && usermod -u ${SQUID_USER_ID} ${SQUID_USER} \
 && mkdir -p /var/lib/squid \
 && mkdir -p ${SQUID_CACHE_DIR} \
 && mkdir -p ${SQUID_LOG_DIR} \
 && /usr/lib/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 20MB \
 && openssl dhparam -outform PEM -out /etc/squid/proxy-bump-dhparam.pem 2048 \
 && chown -R "${SQUID_USER}":"${SQUID_USER}" /var/lib/squid \
 && chown -R "${SQUID_USER}":"${SQUID_USER}" "${SQUID_CACHE_DIR}" \
 && chown -R "${SQUID_USER}":"${SQUID_USER}" "${SQUID_LOG_DIR}" \
 && chmod -R 755 "${SQUID_LOG_DIR}"

COPY sbin/entrypoint.sh /sbin/entrypoint.sh
COPY etc/squid/ /etc/squid/
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 8080/tcp
#USER ${SQUID_USER}
ENTRYPOINT ["/sbin/entrypoint.sh"]
