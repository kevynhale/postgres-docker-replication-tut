FROM debian:jessie
MAINTAINER Kevyn Hale, khale@kydeveloper.com

ARG HOST

RUN apt-get update \
  && apt-get install -y \
  inotify-tools \
  postgresql-9.4 \
  postgresql-client-9.4 \
  supervisor \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/supervisor \
  && chown -R postgres:postgres /var/run/supervisor

ADD postgres-files/ /

RUN mv /$HOST.supervisord.conf /etc/supervisor/supervisord.conf
RUN mv /datadump.sh /usr/local/bin/datadump.sh
RUN mv /postgres.sh /usr/local/bin/postgres.sh
RUN mv /$HOST-conf/* /etc/postgresql/9.4/main/

RUN chown postgres:postgres /usr/local/bin/postgres.sh  /usr/local/bin/datadump.sh \
  && chmod +x /usr/local/bin/postgres.sh \
  && chmod +x /usr/local/bin/datadump.sh \
  && chown -R postgres:postgres /var/run/postgresql /usr/local/etc

  # Locale setting
ENV LOCALE en_US.UTF-8

# Initial default user/pass and schema
ENV USER postgres
ENV PASSWORD postgres

RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf \
  && echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf

#VOLUME	["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/backups"]

RUN touch /var/lib/postgresql/firstrun && chmod 666 /var/lib/postgresql/firstrun

EXPOSE 5432
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]