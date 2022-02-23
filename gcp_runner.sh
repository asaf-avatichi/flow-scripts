#!/bin/bash
user=asaf_avatichi
key=~/.ssh/google_compute_engine

print_usage() {
  echo "Usage:
  -i    instance_name [49, 419]
Optinal flags:
  [-k key ]    key
  f    sync flow repo
  b    build flow sensor
  e    build ebpf
    c    percpu
  r    run sensor
  t    trace bpf log
  h    print help
  j    sensor java build"
}

while getopts 'i:kfbehrcjtn' flag; do
  case "${flag}" in
    i) instnace="${OPTARG}" ;;
    k) key="${OPTARG}" ;;
    f) flow=1 ;;
    b) build=1 ;;
    e) ebpf=1 ;;
    c) percpu=1 ;;
    h) help=1 ;;
    r) run=1 ;;
    t) trace=1 ;;
    n) new=1 ;;
    j) java=1 ;;
    *) print_usage
       exit 1 ;;
  esac
done


get_ip() {
    ip=$(gcloud compute instances list | grep avatichi-agent-kernel | grep $1 | awk '{print $5}')
    echo $ip
}

pretty_print () {
    echo $1
    echo "======================"
    echo ""
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    if [ ! -z "$run" ]; then
        pretty_print "killing Sensor"
        ssh $user@$ip "kubectl -n nmspc exec \`kubectl get pods -A | grep flow-sensor | awk '{print \$2}'\` -n=kube-system -- pkill -9 sensor"
    fi
}

if [ ! -z "$help" ]; then
    print_usage
    exit 1
fi

if [ $# -le 1 ]; then
    echo "Not enough arguments supplied"
    print_usage
    exit 1
fi

get_ip $instnace

if [ ! -z "$flow" ]; then
    pretty_print "Syncing Flow repo"
    ssh $user@$ip "mkdir -p ~/flow"
    rsync -avze "ssh -i $key" --exclude '*.git*'  ~/flow $user@$ip:~/
fi

if [ ! -z "$build" ]; then
    pretty_print "Build Flow Sensor"
    ssh $user@$ip "cd ~/flow/sensor;source ~/.profile;go build -ldflags '-s -w -X \"github.com/flow-security/flow/sensor/common.SensorVersion=0.1.999\"'"
    echo "Sensor Done"
fi

if [ ! -z "$ebpf" ]; then
    pretty_print "Build eBPF"
    if [ ! -z "$percpu" ]; then
        BPF_PATH="/data/sensor/eBPF/dist/sensor_ebpf-percpu.o"
        ssh $user@$ip "cd ~/flow/sensor/eBPF;make;make PERCPU=1"
    else
        BPF_PATH="/data/sensor/eBPF/dist/sensor_ebpf.o"
    
        ssh $user@$ip "cd ~/flow/sensor/eBPF;make"
    fi
fi

if [ ! -z "$run" ]; then
    pretty_print "Running Sensor"
    ssh $user@$ip "kubectl -n nmspc exec \`kubectl get pods -A | grep flow-sensor | awk '{print \$2}'\` -n=kube-system -- pkill -9 sensor"
    ssh $user@$ip "kubectl -n nmspc exec \`kubectl get pods -A | grep flow-sensor | awk '{print \$2}'\` -n=kube-system -- env FLOW_EBPF_PATH=$BPF_PATH /data/sensor/sensor"
fi

if [ ! -z "$trace" ]; then
    pretty_print "Tracing BPF"
    ssh $user@$ip "sudo cat /sys/kernel/debug/tracing/trace_pipe"
fi

if [ ! -z "$java" ]; then
    pretty_print "Java"
    rsync -avze "ssh -i $key" --exclude '*.git*'  ~/dev/flow/janet $user@$ip:~/
    ssh $user@$ip "cd ~/janet;source ~/.profile;export JAVA_HOME=/opt/java-se-8u41-ri;gradle -version;gradle installDist"
fi

