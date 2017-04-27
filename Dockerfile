FROM debian:jessie
MAINTAINER Kevyn Hale, khale@kydeveloper.com

#HOST used to differentiate from master and standby set in docker-compose
ARG HOST 

RUN apt-get update \
  && apt-get install -y \
  inotify-tools \
  postgresql-9.4 \
  postgresql-client-9.4 \
  supervisor \
  ngrep \
  net-tools \
  vim \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/supervisor \
  && chown -R postgres:postgres /var/run/supervisor

ADD pfiles/ /
# If you want to have the replication configured, comment out above and uncomment below
# ADD pfiles-replication/ /

# Set up files based on HOST
RUN mv /$HOST.supervisord.conf /etc/supervisor/supervisord.conf
RUN mv /datadump.sh /usr/local/bin/datadump.sh
RUN mv /$HOST.postgres.sh /usr/local/bin/postgres.sh

RUN mkdir -p /var/wal

RUN chown postgres:postgres /usr/local/bin/postgres.sh  /usr/local/bin/datadump.sh  \
  && chmod +x /usr/local/bin/postgres.sh \
  && chmod +x /usr/local/bin/datadump.sh \
  && chown -R postgres:postgres /var/run/postgresql /usr/local/etc /var/wal /$HOST-conf

  # Locale setting
ENV LOCALE en_US.UTF-8

# Initial default user/pass and schema
ENV USER postgres
ENV PASSWORD postgres

VOLUME	["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/wal"]

RUN touch /var/lib/postgresql/firstrun && chmod 666 /var/lib/postgresql/firstrun

EXPOSE 5432
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]