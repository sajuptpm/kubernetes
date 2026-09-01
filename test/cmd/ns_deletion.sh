#!/bin/bash

set -u

################################################################################
# Configuration
################################################################################

API_SERVICE="v1beta1.metrics.k8s.io"
ANNOTATION_KEY="apiservice.kubernetes.io/non-persistent"
BACKUP_FILE="/tmp/metrics-apiservice.yaml"

WAIT_NS_DELETE=180
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
    kubectl delete ns dummyns1 dummyns2 dummyns3 \
        --ignore-not-found=true >/dev/null 2>&1

    sleep 5
}

create_namespaces() {

    cleanup_namespaces

    kubectl create ns dummyns1 >/dev/null
    kubectl create ns dummyns2 >/dev/null
    kubectl create ns dummyns3 >/dev/null
}

all_namespaces_deleted() {

    for ns in dummyns1 dummyns2 dummyns3
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
        if all_namespaces_deleted; then
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

    if [ "$phase" = "Terminating" ]; then
        return 0
    fi

    return 1
}

wait_for_stuck_namespace() {

    sleep "${WAIT_NS_STUCK}"

    if namespace_stuck_terminating dummyns1; then
        return 0
    fi

    return 1
}

metrics_down() {

    echo "Scaling metrics-server to 0..."

    kubectl scale deployment metrics-server \
        -n kube-system \
        --replicas=0

    sleep 20
}

metrics_up() {

    echo "Scaling metrics-server to 1..."

    kubectl scale deployment metrics-server \
        -n kube-system \
        --replicas=1

    kubectl rollout status deployment metrics-server \
        -n kube-system \
        --timeout=180s
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

################################################################################
# Backup
################################################################################

echo "Backing up APIService..."

kubectl get apiservice "${API_SERVICE}" -o yaml > "${BACKUP_FILE}"

################################################################################
# TC01
################################################################################

header "TC01 - Namespace deletion when metrics-server healthy"

echo "EXPECTED : Namespaces must be deleted"

metrics_up
remove_annotation
create_namespaces

kubectl delete ns dummyns1 dummyns2 dummyns3

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

create_namespaces
metrics_down

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_stuck_namespace
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

if wait_for_namespace_deletion
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

create_namespaces
metrics_down

kubectl delete ns dummyns1 dummyns2 dummyns3

wait_for_stuck_namespace

annotate_true

if wait_for_namespace_deletion
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

create_namespaces
metrics_down

annotate_true

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_namespace_deletion
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

create_namespaces
metrics_down

annotate_false

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_stuck_namespace
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

create_namespaces

kubectl delete apiservice "${API_SERVICE}"

sleep 20

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_namespace_deletion
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
echo "Bring down a NON-METRICS aggregated APIService."
echo "Then press ENTER."
read

create_namespaces

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_stuck_namespace
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

create_namespaces
metrics_down

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_stuck_namespace
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

create_namespaces
metrics_down

kubectl annotate apiservice "${API_SERVICE}" \
    "${ANNOTATION_KEY}=yes" \
    --overwrite

kubectl delete ns dummyns1 dummyns2 dummyns3

if wait_for_stuck_namespace
then
    echo "ACTUAL   : Namespace stuck"
    pass
else
    echo "ACTUAL   : Namespace deleted"
    fail
fi

################################################################################
# Cleanup
################################################################################

header "Cleanup"

kubectl apply -f "${BACKUP_FILE}" >/dev/null 2>&1

metrics_up

cleanup_namespaces

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