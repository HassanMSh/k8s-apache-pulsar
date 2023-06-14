#!/bin/bash

kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin tenants create apache" && \
kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin namespaces create apache/pulsar" && \
kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin topics create-partitioned-topic apache/pulsar/test-topic -p 4" && \
kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash -c "bin/pulsar-admin topics list-partitioned-topics apache/pulsar"
