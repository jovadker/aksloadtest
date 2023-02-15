#!/usr/bin/env bash
#Script created to launch Jmeter tests directly from the current terminal without accessing the jmeter master pod.
#It requires that you supply the path to the jmx file
#After execution, test script jmx file may be deleted from the pod itself but not locally.

working_dir="`pwd`"

#Get namesapce variable
echo "Namespace: $2"

jmx="$1"
[ -n "$jmx" ] || read -p 'Enter path to the jmx file ' jmx

if [ ! -f "$jmx" ];
then
    echo "Test script file was not found in PATH"
    echo "Kindly check and input the correct file path"
    exit
fi

test_name="$(basename "$jmx")"

#Get Master pod details

master_pod=`kubectl get pods -n $2 | grep master | awk '{print $1}'`

kubectl cp "$jmx"  "$master_pod:/$test_name" -n $2

## Echo Starting Jmeter load test

kubectl exec -ti $master_pod -n $2 -- /bin/bash /load_test "$test_name"

sleep 5

# Copy dashboard directory to whatever storage we have
kubectl cp $master_pod:/dashboard dashboard -n $2