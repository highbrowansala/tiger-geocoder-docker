# :----------------:
# Base Image
# :----------------:
FROM postgis-osgeo:2.4.4
# :----------------:
# Install Linux dependencies
RUN apt-get update && apt-get install -y unzip
# :----------------:
# :----------------:
# TIGER Geocoding Staging Directory
# :----------------:
ENV TIGER_STAGING=/home/tiger_staging

RUN mkdir -p ${TIGER_STAGING}/temp

RUN chown -R postgres:postgres ${TIGER_STAGING}
RUN chmod -R 755 ${TIGER_STAGING}
# :----------------:
# Add the initialization script
# :----------------:
ADD ./utils/shell/tiger-conf.sh /docker-entrypoint-initdb.d/

RUN chmod 755 /docker-entrypoint-initdb.d/*

USER postgres
