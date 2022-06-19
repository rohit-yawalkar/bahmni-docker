#!/bin/bash
set -xe
#Building bahmni core which has embedded Tomcat Server
cd bahmni-package && ./gradlew -PbahmniRelease=${BAHMNI_VERSION} :core:clean :core:build
cp core/build/libs/core-1.0-SNAPSHOT.jar bahmni-lab/docker/bahmni-core.jar
cd ..

# Packaging default config to embed into default image
# Working directory : default-config
cd default-config && scripts/package.sh && cd ..
cp default-config/target/default_config.zip bahmni-package/bahmni-lab/resources/

#Fetching Database Backup Data
gunzip -f -k bahmni-scripts/demo/db-backups/v0.92/openelis_backup.sql.gz
cp bahmni-scripts/demo/db-backups/v0.92/openelis_backup.sql bahmni-package/bahmni-lab/resources/openelis_demo_dump.sql
cd bahmni-package/bahmni-lab

#Extracting Migrations Zip
if [ ! -d build/migrations ]
then
mkdir -p build/migrations
fi
unzip -u -d build/migrations resources/OpenElis.zip

# Unzipping Default Config
unzip -q -u -d build/default_config resources/default_config.zip

#Building Docker images
OPENELIS_IMAGE_TAG=${BAHMNI_VERSION}-${GITHUB_RUN_NUMBER}
docker build -t bahmni/openelis-db:fresh-${OPENELIS_IMAGE_TAG} -f docker/db.Dockerfile . --no-cache
docker build -t bahmni/openelis-db:demo-${OPENELIS_IMAGE_TAG} -f docker/demodb.Dockerfile . --no-cache
docker build -t bahmni/openelis:${OPENELIS_IMAGE_TAG} -f docker/Dockerfile . --no-cache
