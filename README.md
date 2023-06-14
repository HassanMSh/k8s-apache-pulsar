# Apache Pulsar


## value.yaml

To run locally:

	### Namespace to deploy pulsar
	# The namespace to use to deploy the pulsar components, if left empty
	# will default to .Release.Namespace (aka helm --namespace).
	namespace: pulsar
	namespaceCreate: false
	
	initialize: true
	
	clusterName: cluster2
	
	## Volume settings
	volumes:
	  persistence: false
	
	## Components
	##
	## Control what components of Apache Pulsar to deploy for the cluster
	components:
	  # zookeeper
	  zookeeper: true
	  # bookkeeper
	  bookkeeper: true
	  # bookkeeper - autorecovery
	  autorecovery: false
	  # broker
	  broker: true
	  # functions
	  functions: true
	  # proxy
	  proxy: true
	  # toolset
	  toolset: true
	  # pulsar manager
	  pulsar_manager: false
	
	## Monitoring Components
	##
	## Control what components of the monitoring stack to deploy for the cluster
	monitoring:
	  # monitoring - prometheus
	  prometheus: false
	  # monitoring - grafana
	  grafana: false
	
	
	# disable monitoring stack
	kube-prometheus-stack:
	   enabled: false
	   prometheusOperator:
	     enabled: false
	   grafana:
	     enabled: false
	   alertmanager:
	     enabled: false
	   prometheus:
	     enabled: false
	
	zookeeper:
	  # Disable pod monitor since we're disabling CRD installation
	  podMonitor:
	    enabled: false
	
	bookkeeper:
	  # Disable pod monitor since we're disabling CRD installation
	  podMonitor:
	    enabled: false
	
	autorecovery:
	  # Disable pod monitor since we're disabling CRD installation
	  podMonitor:
	    enabled: false
	
	broker:
	  # Disable pod monitor since we're disabling CRD installation
	  podMonitor:
	    enabled: false
	  configData:
	    autoSkipNonRecoverableData: "true"
	proxy:
	  # Disable pod monitor since we're disabling CRD installation
	  podMonitor: 
	    enabled: false

For full deployment checkout [values.yaml](https://github.com/apache/pulsar-helm-chart/blob/master/charts/pulsar/values.yaml)

## Deploy Pulsar cluster using Helm

	helm repo add apache https://pulsar.apache.org/charts
	helm repo update
	helm install pulsar apache/pulsar --values values.conf

## Wait 5+ min for everything to be up and running

## Use pulsar-admin to create Pulsar tenants/namespaces/topics

You can use the script attached below.

1. Enter the toolset container.

`kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash`

2. Perform a health check

`bin/pulsar-admin brokers healthcheck`

3. In the toolset container, create a tenant named apache.

`bin/pulsar-admin tenants create apache`

4. In the toolset container, create a namespace named pulsar in the tenant apache.

`bin/pulsar-admin namespaces create apache/pulsar`

5. In the toolset container, create a topic test-topic with 4 partitions in the namespace apache/pulsar.

`bin/pulsar-admin topics create-partitioned-topic apache/pulsar/test-topic -p 4`

6. In the toolset container, list all the partitioned topics in the namespace apache/pulsar.

`bin/pulsar-admin topics list-partitioned-topics apache/pulsar`

### Script

	#!/bin/bash
	
	kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin tenants create apache" && \
	kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin namespaces create apache/pulsar" && \
	kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin topics create-partitioned-topic apache/pulsar/test-topic -p 4" && \
	kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin topics list-partitioned-topics apache/pulsar"

## Use Pulsar client to produce and consume messages

Proxy: You can use the IP address to produce and consume messages to the installed Pulsar cluster.
Note: Java version 17+ is required.

1. Expose Proxy 

`minikube service pulsar-proxy -n pulsar -p clusterName`

2. Download the Apache Pulsar tarball
3. Decompress the tarball based on your download file.
4. Expose PULSAR_HOME.
	* Enter the directory of the decompressed download file.
	* Expose PULSAR_HOME as the environment variable.

`export PULSAR_HOME=$(pwd)`

5. Create a subscription to consume messages from apache/pulsar/test-topic.

`bin/pulsar-client consume -s sub apache/pulsar/test-topic  -n 0`

6. Open a new terminal. In the new terminal, create a producer and send 10 messages to the test-topic topic.

`bin/pulsar-client produce apache/pulsar/test-topic  -m "---------hello apache pulsar-------" -n 10`

7. Verify the results.

## Initialize Pulsar Manager

Due to it being super buggy and useless at this point I will not use it

	kubectl exec -it pulsar-pulsar-manager-pod -- /bin/bash
	export SPRING_CONFIGURATION_FILE=/pulsar-manager/pulsar-manager/application.properties
	./entrypoint.sh
	CSRF_TOKEN=$(curl http://localhost:7750/pulsar-manager/csrf-token)
	curl \
    -H "X-XSRF-TOKEN: $CSRF_TOKEN" \
    -H "Cookie: XSRF-TOKEN=$CSRF_TOKEN;" \
    -H 'Content-Type: application/json' \
    -X PUT http://localhost:7750/pulsar-manager/users/superuser \
    -d '{"name": "admin", "password": "apachepulsar", "description": "test", "email": "username@test.org"}'

There's a database related issue

	Starting PostGreSQL Server
	addgroup: The group `pulsar' already exists.
	adduser: The user `pulsar' already exists.
	/pulsar-manager/startup.sh: 21: initdb: not found
	/pulsar-manager/startup.sh: 22: pg_ctl: not found
	createdb: error: could not connect to database template1: could not connect to server: No such file or directory
	        Is the server running locally and accepting
	        connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432"?
	psql: error: could not connect to server: No such file or directory
	        Is the server running locally and accepting
	        connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432

[issue](https://github.com/apache/pulsar-manager/issues/465)
[Pulsar Manager Documentation](https://github.com/apache/pulsar-manager)

## Sources:

[Standalone](https://pulsar.apache.org/docs/3.0.x/getting-started-helm/)
[Helm Deployment](https://pulsar.apache.org/docs/3.0.x/helm-deploy/)
