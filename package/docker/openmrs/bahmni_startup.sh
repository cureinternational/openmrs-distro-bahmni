#!/bin/bash
set -e

# This script is used to run startup commands before starting OpenMRS distro startup script that comes with docker image. The last line starts OpenMRS script.
echo "Running Bahmnni EMR Startup Script..."

echo "Substituting Environment Variables..."
envsubst < /etc/bahmni-emr/templates/bahmnicore.properties.template > ${OPENMRS_APPLICATION_DATA_DIRECTORY}/bahmnicore.properties
envsubst < /etc/bahmni-emr/templates/openmrs-runtime.properties.template > ${OPENMRS_APPLICATION_DATA_DIRECTORY}/openmrs-runtime.properties
envsubst < /etc/bahmni-emr/templates/mail-config.properties.template > ${OPENMRS_APPLICATION_DATA_DIRECTORY}/mail-config.properties
envsubst < /etc/bahmni-emr/templates/rulesengine-concept.properties.template > ${OPENMRS_APPLICATION_DATA_DIRECTORY}/rulesengine-concept.properties
/openmrs/wait-for-it.sh --timeout=3600 ${OMRS_DB_HOSTNAME}:3306

echo "Copy Configuration Folder from bahmni_config"
if [ -d /etc/bahmni_config/masterdata/configuration ]
then
  cp -r /etc/bahmni_config/masterdata/configuration/ ${OPENMRS_APPLICATION_DATA_DIRECTORY}/
fi
mysql --host="${OMRS_DB_HOSTNAME}" --user="${OMRS_DB_USERNAME}" --password="${OMRS_DB_PASSWORD}" "${OMRS_DB_NAME}" -e "UPDATE global_property SET global_property.property_value = '' WHERE  global_property.property = 'search.indexVersion';" || true

if [ "${OMRS_DOCKER_ENV}" = 'true' ]
then
echo "setting the folder permissions"
setfacl -d -m o::rx -m g::rx /home/bahmni/document_images/
setfacl -d -m o::rx -m g::rx /home/bahmni/uploaded_results/
fi

if [ "${PUBLISH_PATIENT_EVENTS_TO_JMS}" == "true" ]; then
  envsubst < /etc/bahmni-emr/templates/tomcat_context_with_event_resource.template > /usr/local/tomcat/conf/context.xml
fi

echo "Running OpenMRS Startup Script..."
./startup.sh
