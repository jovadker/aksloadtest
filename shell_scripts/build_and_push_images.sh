#!/bin/bash

set -ex

acrName=$0

if ! az acr repository show -n $acrName --image testframework/jmetermaster:latest &>/dev/null; then
    echo "INFO:master image does not exist....creating..."
    echo "INFO:building jmeter master container and pushing to [ $acrName ] "
    az acr build -t testframework/jmetermaster:latest -f ../docker/master/Dockerfile -r $acrName .
    if [ $? -ne 0 ]
    then
        echo "ERROR:Failed to build and push master container error: '${?}'"
        exit 1
    else
        echo "INFO:jmeter master container completed...."
    fi
else
    echo "INFO:jmetermaster:lastest already existing in acr...."
fi

if ! az acr repository show -n $acrName --image testframework/jmeterslave:latest &>/dev/null; then
    echo "INFO:slave image does not exist....creating..."
    echo "INFO:building jmeter slave container and pushing to [ $acrName ]"
    az acr build -t testframework/jmeterslave:latest -f ../docker/slave/Dockerfile -r $acrName .
    if [ $? -ne 0 ]
    then
        echo "ERROR:Failed to build and push slave error: '${?}'"
        exit 1
    else
        echo "INFO:jmeter slave container completed...."
    fi
else
    echo "INFO:jmeterslave:lastest already existing in acr...."
fi

if ! az acr repository show -n $acrName --image testframework/reporter:latest &>/dev/null; then
    echo "INFO:slave image does not exist....creating..."
    echo "INFO:building jmeter reporter container and pushing to [ $acrName ]"
    az acr build -t testframework/reporter:latest -f ../docker/reporter/Dockerfile -r $acrName .
    if [ $? -ne 0 ]
    then
        echo "ERROR:Failed to build and push slave error: '${?}'"
        exit 1
    else
        echo "INFO:jmeter reporter container completed...."
    fi
else
    echo "INFO:reporter:lastest already existing in acr...."
fi