#!/bin/bash
set -e

# Create a database for geocoding
createdb ${GEOCODE_DB}

# Add PostGIS, TIGER and other required extensions
psql -d ${GEOCODE_DB} <<-SQLBLK
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
CREATE EXTENSION address_standardizer;
SQLBLK

# Insert a record in tiger.platform_loader for the executables and the server (platform: sh)
psql -d ${GEOCODE_DB} <<-SQLBLK
UPDATE tiger.loader_platform
SET declare_sect = 'TMPDIR=${TIGER_STAGING}/temp/
UNZIPTOOL=unzip
WGETTOOL=/usr/bin/wget
export PGBIN=/usr/lib/postgresql/10/bin
export PGPORT=5432
export PGUSER=postgres
export PGPASSWORD=yourpasswordhere
export PGDATABASE=${GEOCODE_DB}
PSQL=psql
SHP2PGSQL=shp2pgsql
cd ${TIGER_STAGING}
' WHERE os = 'sh'
SQLBLK

# Update the staging folder path in tiger.loader_variables table
psql -d ${GEOCODE_DB} -c "UPDATE tiger.loader_variables SET staging_fold = '${TIGER_STAGING}'"

# Load Zip code-5 digit tabulation area
psql -d ${GEOCODE_DB} -c "UPDATE tiger.loader_lookuptables SET load = true WHERE table_name = 'zcta510';"

# Load the Generate Nation (data) script
psql -d ${GEOCODE_DB} -c "SELECT Loader_Generate_Nation_Script('sh')" -tA > ${TIGER_STAGING}/nation_script_load.sh

# Add the target database in the nation_script_load script
# sed -i -e 's/\${PSQL} -c/\${PSQL} -d ${GEOCODE_DB} -c/g' ${TIGER_STAGING}/nation_script_load.sh

# Correct errors in the nation_script_load script
# A value passed to psql command's option -c in line 57 is improperly quoted
sed -i -e 's/\${PSQL} -c \"ALTER TABLE tiger.zcta5 DROP CONSTRAINT IF EXISTS enforce_geotype_the_geom; CREATE TABLE tiger_data.zcta5_all(CONSTRAINT pk_zcta5_all PRIMARY KEY (zcta5ce,statefp), CONSTRAINT uidx_zcta5_raw_all_gid UNIQUE (gid)) INHERITS(tiger.zcta5);/\${PSQL} -c \"ALTER TABLE tiger.zcta5 DROP CONSTRAINT IF EXISTS enforce_geotype_the_geom; CREATE TABLE tiger_data.zcta5_all(CONSTRAINT pk_zcta5_all PRIMARY KEY (zcta5ce,statefp), CONSTRAINT uidx_zcta5_raw_all_gid UNIQUE (gid)) INHERITS(tiger.zcta5);\"/g' ${TIGER_STAGING}/nation_script_load.sh
# If in case, the error is not present, this will undo adding an unquote at the end of line 57 by the previous command
sed -i -e 's/\${PSQL} -c \"ALTER TABLE tiger.zcta5 DROP CONSTRAINT IF EXISTS enforce_geotype_the_geom; CREATE TABLE tiger_data.zcta5_all(CONSTRAINT pk_zcta5_all PRIMARY KEY (zcta5ce,statefp), CONSTRAINT uidx_zcta5_raw_all_gid UNIQUE (gid)) INHERITS(tiger.zcta5);\"\"/\${PSQL} -c \"ALTER TABLE tiger.zcta5 DROP CONSTRAINT IF EXISTS enforce_geotype_the_geom; CREATE TABLE tiger_data.zcta5_all(CONSTRAINT pk_zcta5_all PRIMARY KEY (zcta5ce,statefp), CONSTRAINT uidx_zcta5_raw_all_gid UNIQUE (gid)) INHERITS(tiger.zcta5);\"/g' ${TIGER_STAGING}/nation_script_load.sh


# RUN the nation_script_load script for the USA
chmod 755 ${TIGER_STAGING}/nation_script_load.sh
${TIGER_STAGING}/nation_script_load.sh

# Load the Generate States script
psql -d ${GEOCODE_DB} -c "SELECT Loader_Generate_Script(ARRAY['CA'], 'sh')" -tA > ${TIGER_STAGING}/states_script_load.sh

# Add the target database in the states_script_load script
# sed -i -e 's/\${PSQL} -c/\${PSQL} -d ${GEOCODE_DB} -c/g' ${TIGER_STAGING}/states_script_load.sh

# RUN the states_script_load script for the provided states
chmod 755 ${TIGER_STAGING}/states_script_load.sh
${TIGER_STAGING}/states_script_load.sh

# Add client authentication entry in pg_hba.conf
echo "host all all 172.30.0.0/24 md5" >> ${PGDATA}/pg_hba.conf

# Reload pg_ctl
${PGBIN}/pg_ctl reload
