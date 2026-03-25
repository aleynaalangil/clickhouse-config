FROM clickhouse/clickhouse-server:24-alpine

#COPY memory.xml /etc/clickhouse-server/config.d/memory.xml
COPY init.sql   /docker-entrypoint-initdb.d/init.sql

EXPOSE 8123