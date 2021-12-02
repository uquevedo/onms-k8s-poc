#!env bash
# @author Alejandro Galue <agalue@opennms.com>
#
# WARNING: For testing purposes only

NAMESPACE="shared"
TARGET_DIR="k8s/pki" # Expected location for the configMap that keeps the Truststore
ONMS_USER_PASSWORD="0p3nNM5" # Must match KAFKA_SASL_PASSWORD from app-credentials
TRUSTSTORE_FILE="kafka-truststore.jks" # Must be consistent with KAFKA_SSL_TRUSTSTORE_LOCATION from app-settings
TRUSTSTORE_PASSWORD="0p3nNM5" # Must match KAFKA_SSL_TRUSTSTORE_PASSWORD from app-credentials
CLUSTER_NAME="onms" # Must match the name of the cluster inside dependencies/kafka.yaml

kubectl create namespace $NAMESPACE
kubectl create secret generic kafka-user-credentials --from-literal="opennms=$ONMS_USER_PASSWORD" -n $NAMESPACE
kubectl apply -f "https://strimzi.io/install/latest?namespace=$NAMESPACE" -n $NAMESPACE
kubectl apply -f dependencies -n $NAMESPACE
kubectl wait kafka/$CLUSTER_NAME --for=condition=Ready --timeout=300s -n $NAMESPACE

mkdir -p $TARGET_DIR

CERT_FILE_PATH="$TARGET_DIR/kafka-ca.crt"
kubectl get secret $CLUSTER_NAME-cluster-ca-cert -n $NAMESPACE -o jsonpath='{.data.ca\.crt}' | base64 --decode > $CERT_FILE_PATH

TEMP_TRUSTSTORE="/tmp/ca.truststore.$(date +%s)"
keytool -import -trustcacerts -alias root -file $CERT_FILE_PATH -keystore $TEMP_TRUSTSTORE -storepass "$TRUSTSTORE_PASSWORD" -noprompt
mv -f $TEMP_TRUSTSTORE $TARGET_DIR/$TRUSTSTORE_FILE

kubectl get all -n $NAMESPACE

echo "Done!"
echo "The Truststore for Kafka Clients is available at $TARGET_DIR/$TRUSTSTORE_FILE"
