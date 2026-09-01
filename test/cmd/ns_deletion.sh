#!/bin/bash

set -u

################################################################################
# Configuration
################################################################################

API_SERVICE="v1beta1.metrics.k8s.io"
ANNOTATION_KEY="apiservice.kubernetes.io/non-persistent"
BACKUP_FILE="/tmp/metrics-apiservice.yaml"

WAIT_NS_DELETE=120
WAIT_NS_STUCK=60

PASS_COUNT=0
FAIL_COUNT=0

################################################################################
# Helpers
################################################################################

pass() {
    echo "RESULT   : PASS"
    echo
    PASS_COUNT=$((PASS_COUNT+1))
}

fail() {
    echo "RESULT   : FAIL"
    echo
    FAIL_COUNT=$((FAIL_COUNT+1))
}

header() {
    echo
    echo "=================================================================="
    echo "$1"
    echo "=================================================================="
}

cleanup_namespaces() {
    kubectl delete ns \
        "$@" \
        --ignore-not-found=true \
        --wait=false >/dev/null 2>&1

    sleep 10
}

create_namespaces() {

    cleanup_namespaces "$@"

    for ns in "$@"
    do
        kubectl create ns "${ns}" >/dev/null 2>&1
    done
    sleep 10
}

create_dummy_resources() {
    local ns=$1

    echo "Creating dummy resources in ${ns}"

    kubectl -n "${ns}" create deployment nginx \
        --image=nginx \
        --replicas=1 >/dev/null 2>&1

    kubectl -n "${ns}" create configmap test-cm \
        --from-literal=key=value >/dev/null 2>&1

    kubectl -n "${ns}" create secret generic test-secret \
        --from-literal=password=test123 >/dev/null 2>&1

    kubectl -n "${ns}" expose deployment nginx \
        --port=80 >/dev/null 2>&1

    kubectl -n "${ns}" wait \
        --for=condition=available deployment/nginx \
        --timeout=120s >/dev/null 2>&1 || true
}

all_namespaces_deleted() {

    for ns in "$@"
    do
        kubectl get ns "${ns}" >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            return 1
        fi
    done

    return 0
}


wait_for_namespace_deletion() {

    local timeout=$WAIT_NS_DELETE
    local elapsed=0

    while [ $elapsed -lt $timeout ]
    do
        if all_namespaces_deleted "$@"
        then
            return 0
        fi

        sleep 5
        elapsed=$((elapsed+5))
    done

    return 1
}

wait_for_namespace_deletion_ns() {

    local ns=$1
    local timeout=$WAIT_NS_DELETE
    local elapsed=0

    while [ $elapsed -lt $timeout ]
    do
        kubectl get ns "${ns}" >/dev/null 2>&1

        if [ $? -ne 0 ]; then
            return 0
        fi

        sleep 5
        elapsed=$((elapsed+5))
    done

    return 1
}

namespace_stuck_terminating() {

    local ns=$1

    phase=$(kubectl get ns "$ns" -o jsonpath='{.status.phase}' 2>/dev/null)
    echo "Namespace ${ns} phase=${phase}"
    [ "$phase" = "Terminating" ]
}

wait_for_stuck_namespace() {

    sleep "${WAIT_NS_STUCK}"

    for ns in "$@"
    do
        if namespace_stuck_terminating "${ns}"
        then
            return 0
        fi
    done

    return 1
}

metrics_down() {

    echo "Scaling metrics-server to 0..."

    kubectl scale deployment metrics-server \
        -n kube-system \
        --replicas=0

    sleep 30
    kubectl get pods -n kube-system | grep metrics-server
}

metrics_up() {

    echo "Scaling metrics-server to 1..."

    kubectl get pods -n kube-system | grep metrics-server

    kubectl scale deployment metrics-server \
        -n kube-system \
        --replicas=1

    kubectl get pods -n kube-system | grep metrics-server

    kubectl rollout status deployment metrics-server \
        -n kube-system \
        --timeout=120s

    kubectl get pods -n kube-system | grep metrics-server
}

annotate_true() {

    kubectl annotate apiservice "${API_SERVICE}" \
        "${ANNOTATION_KEY}=true" \
        --overwrite
}

annotate_false() {

    kubectl annotate apiservice "${API_SERVICE}" \
        "${ANNOTATION_KEY}=false" \
        --overwrite
}

remove_annotation() {

    kubectl annotate apiservice "${API_SERVICE}" \
        "${ANNOTATION_KEY}-" \
        >/dev/null 2>&1
}

force_remove_namespace() {

    local ns=$1

    kubectl get ns "${ns}" -o json \
      | jq '.spec.finalizers=[]' \
      | kubectl replace --raw "/api/v1/namespaces/${ns}/finalize" -f -
}

################################################################################
# Backup
################################################################################

echo "Backing up APIService..."

kubectl get apiservice "${API_SERVICE}" -o yaml > "${BACKUP_FILE}"

################################################################################
# cleanup
################################################################################

remove_annotation
metrics_up
cleanup_namespaces ns1 ns2 ns3 ns4 ns5 ns6 ns7 ns8 ns9 ns10 ns11 ns12 ns13 ns14
wait_for_namespace_deletion ns1 ns2 ns3 ns4 ns5 ns6 ns7 ns8 ns9 ns10 ns11 ns12 ns13 ns14


################################################################################
# TC01
################################################################################

header "TC01 - Namespace deletion when metrics-server healthy"

echo "EXPECTED : Namespaces must be deleted"

metrics_up
remove_annotation
create_namespaces ns1

kubectl delete ns ns1 --wait=false

if wait_for_namespace_deletion
then
    echo "ACTUAL   : Namespaces deleted"
    pass
else
    echo "ACTUAL   : Namespaces not deleted"
    fail
fi

################################################################################
# TC02
################################################################################

header "TC02 - Metrics server down without annotation"

echo "EXPECTED : Namespaces stay in Terminating state"

create_namespaces ns2
metrics_down

kubectl delete ns ns2 --wait=false

if wait_for_stuck_namespace ns2
then
    echo "ACTUAL   : Namespace stuck in Terminating"
    pass
else
    echo "ACTUAL   : Namespace not stuck"
    fail
fi

################################################################################
# TC03
################################################################################

header "TC03 - Recovery after metrics server restored"

echo "EXPECTED : Namespaces deleted after metrics-server returns"

metrics_up

if wait_for_namespace_deletion ns2
then
    echo "ACTUAL   : Namespaces deleted"
    pass
else
    echo "ACTUAL   : Namespaces still exist"
    fail
fi

################################################################################
# TC04
################################################################################

header "TC04 - Annotate after namespaces already stuck"

echo "EXPECTED : Existing terminating namespaces deleted"

create_namespaces ns4
metrics_down

kubectl delete ns ns4 --wait=false

wait_for_stuck_namespace ns4

annotate_true

if wait_for_namespace_deletion ns4
then
    echo "ACTUAL   : Namespaces deleted"
    pass
else
    echo "ACTUAL   : Namespaces not deleted"
    fail
fi

################################################################################
# TC05
################################################################################

header "TC05 - Annotation exists before deletion"

echo "EXPECTED : Namespace deletion succeeds"

create_namespaces ns5
metrics_down

annotate_true

kubectl delete ns ns5 --wait=false

if wait_for_namespace_deletion ns5
then
    echo "ACTUAL   : Namespaces deleted"
    pass
else
    echo "ACTUAL   : Namespaces still exist"
    fail
fi

################################################################################
# TC06
################################################################################

header "TC06 - Annotation=false"

echo "EXPECTED : Namespace remains terminating"

create_namespaces ns6
metrics_down

annotate_false

kubectl delete ns ns6 --wait=false

if wait_for_stuck_namespace ns6
then
    echo "ACTUAL   : Namespace stuck"
    pass
else
    echo "ACTUAL   : Namespace deleted unexpectedly"
    fail
fi

################################################################################
# TC07
################################################################################

header "TC07 - APIService removed"

echo "EXPECTED : Validate behavior when APIService is absent"

kubectl apply -f "${BACKUP_FILE}" >/dev/null 2>&1

create_namespaces ns7

kubectl delete apiservice "${API_SERVICE}"

sleep 20

kubectl delete ns ns7 --wait=false

if wait_for_namespace_deletion ns7
then
    echo "ACTUAL   : Namespaces deleted"
else
    echo "ACTUAL   : Namespaces remained"
fi

echo "RESULT   : MANUAL REVIEW REQUIRED"
echo

kubectl apply -f "${BACKUP_FILE}"

################################################################################
# TC08
################################################################################

header "TC08 - Another APIService unavailable"

echo "EXPECTED : Namespace deletion must remain blocked"

echo
echo "MANUAL STEP REQUIRED"
echo "Bring down another aggregated APIService then press ENTER"
read

create_namespaces ns8

kubectl delete ns ns8 --wait=false

if wait_for_stuck_namespace ns8
then
    echo "ACTUAL   : Namespace stuck"
    pass
else
    echo "ACTUAL   : Namespace deleted"
    fail
fi

################################################################################
# TC09
################################################################################

header "TC09 - Annotation missing"

echo "EXPECTED : Namespace remains terminating"

remove_annotation

create_namespaces ns9
metrics_down

kubectl delete ns ns9 --wait=false

if wait_for_stuck_namespace ns9
then
    echo "ACTUAL   : Namespace stuck"
    pass
else
    echo "ACTUAL   : Namespace deleted"
    fail
fi

################################################################################
# TC10
################################################################################

header "TC10 - Invalid annotation value"

echo "EXPECTED : Namespace remains terminating"

create_namespaces ns10
metrics_down

kubectl annotate apiservice "${API_SERVICE}" \
    "${ANNOTATION_KEY}=yes" \
    --overwrite

kubectl delete ns ns10 --wait=false

if wait_for_stuck_namespace ns10
then
    echo "ACTUAL   : Namespace stuck"
    pass
else
    echo "ACTUAL   : Namespace deleted"
    fail
fi

################################################################################
# TC11
################################################################################

header "TC11 - Namespace with pods and resources"

echo "EXPECTED : Namespace and resources deleted"

metrics_up
remove_annotation

cleanup_namespaces ns11

kubectl create ns ns11 >/dev/null

create_dummy_resources ns11

kubectl delete ns ns11 --wait=false

if wait_for_namespace_deletion_ns ns11
then
    echo "ACTUAL   : Namespace deleted"
    pass
else
    echo "ACTUAL   : Namespace still exists"
    fail
fi

################################################################################
# TC12
################################################################################

header "TC12 - Namespace with resources and metrics-server down"

echo "EXPECTED : Namespace stuck in Terminating"

cleanup_namespaces ns12
remove_annotation

kubectl create ns ns12 >/dev/null

create_dummy_resources ns12

metrics_down

kubectl delete ns ns12 --wait=false

sleep "${WAIT_NS_STUCK}"

if namespace_stuck_terminating ns12
then
    echo "ACTUAL   : Namespace stuck in Terminating"
    pass
else
    echo "ACTUAL   : Namespace not stuck"
    fail
fi

################################################################################
# TC13
################################################################################

header "TC13 - Namespace with resources, metrics-server down and annotation=true"

echo "EXPECTED : Namespace deleted"

cleanup_namespaces ns13

kubectl create ns ns13 >/dev/null

create_dummy_resources ns13

metrics_down

annotate_true

kubectl delete ns ns13 --wait=false

if wait_for_namespace_deletion_ns ns13
then
    echo "ACTUAL   : Namespace deleted"
    pass
else
    echo "ACTUAL   : Namespace still exists"
    fail
fi

################################################################################
# TC14
################################################################################

header "TC14 - Force namespace deletion via finalizer removal"

echo "EXPECTED : Namespace removed"

cleanup_namespaces ns14

remove_annotation

kubectl create ns ns14 >/dev/null

create_dummy_resources ns14

metrics_down

kubectl delete ns ns14 --wait=false

sleep "${WAIT_NS_STUCK}"

echo "Removing namespace finalizers..."

force_remove_namespace ns14 >/dev/null 2>&1

sleep 10

kubectl get ns ns14 >/dev/null 2>&1

if [ $? -ne 0 ]
then
    echo "ACTUAL   : Namespace removed"
    pass
else
    echo "ACTUAL   : Namespace still exists"
    fail
fi

################################################################################
# Cleanup
################################################################################

header "Cleanup"

kubectl apply -f "${BACKUP_FILE}" >/dev/null 2>&1

metrics_up

cleanup_namespaces nsTC01-1 nsTC01-2 nsTC02-1 nsTC02-2 nsTC04-1 nsTC04-2 nsTC05-1 nsTC05-2 nsTC06-1 nsTC06-2 nsTC07-1 nsTC07-2 nsTC08-1 nsTC08-2 nsTC09-1 nsTC09-2 nsTC10-1 nsTC10-2 sTC11-1 nsTC12-1 nsTC13-1 nsTC14-1
wait_for_namespace_deletion nsTC01-1 nsTC01-2 nsTC02-1 nsTC02-2 nsTC04-1 nsTC04-2 nsTC05-1 nsTC05-2 nsTC06-1 nsTC06-2 nsTC07-1 nsTC07-2 nsTC08-1 nsTC08-2 nsTC09-1 nsTC09-2 nsTC10-1 nsTC10-2 sTC11-1 nsTC12-1 nsTC13-1 nsTC14-1


################################################################################
# Summary
################################################################################

echo
echo "==============================================================="
echo "TEST SUMMARY"
echo "==============================================================="
echo "PASSED : ${PASS_COUNT}"
echo "FAILED : ${FAIL_COUNT}"
echo "==============================================================="