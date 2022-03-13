#!/bin/bash
# GOOGLE
g_user=asaf_avatichi
g_key=~/.ssh/google_compute_engine

a_user=ec2-user
a_key=~/.ssh/asafavatichi.pem


print_usage() {
    echo "Usage:
    -i    instance_name [49, 419, 414]
    -m    machine type  [amazon, gcp, vagrant]
Optinal flags:
    -f    sync flow repo
    -b    build flow sensor
    -d    debug
    -j    sensor java build
    -r    run sensor
    -e    build ebpf
    -c    ebpf with percpu
More Utils:
    -t    trace bpf log
    -h    print help"
}


amazon_get_ip() {
    ip=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=avatichi-agent-kernel$1" |jq -r '.Reservations[0].Instances[0].PublicIpAddress')
    echo $ip
}

gcp_get_ip() {
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
        $($ssh_run "sudo pkill -9 sensor")
    fi
}

m_sync() {
    rsync -avze "ssh -i $key" --exclude '*.git*'  $1 $user@$ip:$2
}

v_sync() {
    vagrant scp $1 server:$2
}

get_machine() {
    if [ $machine == "amazon" ]; then
        amazon_get_ip $instnace
        key=$a_key
        user=$a_user
        ssh_run="ssh $a_user@$ip"
        sync="m_sync"
    else
        if [ $machine == "gcp" ]; then
            gcp_get_ip $instnace
            key=$g_key
            user=$g_user
            ssh_run="ssh $g_user@$ip"
            sync="m_sync"
        else
            if [ $machine == "vagrant" ]; then
                cd ~/vagrant/$instnace
                ssh_run="vagrant ssh -c"
                sync="v_sync"
            else
                echo "Not recognized machine type"
                print_usage
                exit 1
            fi
        fi
    fi
}

handle_args() {
    if [ ! -z "$debug" ]; then
        pretty_print "debug"
        flow_debug="FLOW_DEBUG=1"
        flow_build_debug="-tags debug_pprof"
    fi

    if [ ! -z "$flow" ]; then
        pretty_print "Syncing Flow repo"
        $($ssh_run "mkdir -p ~/flow")
        $sync ~/flow .
        # rsync -avze "ssh -i $key" --exclude '*.git*'  ~/flow $user@$ip:~/
    fi

    if [ ! -z "$build" ]; then
        pretty_print "Build Flow Sensor"
        $($ssh_run "cd ~/flow/sensor;source ~/.profile;go build -ldflags '-s -w -X \"github.com/flow-security/flow/sensor/common.SensorVersion=0.1.999\"' $flow_build_debug")
        echo "Sensor Done"
    fi

    if [ ! -z "$ebpf" ]; then
        pretty_print "Build eBPF"
        if [ ! -z "$percpu" ]; then
            $($ssh_run "cd ~/flow/sensor/eBPF;make;make PERCPU=1")
            flow_ebpf="FLOW_EBPF_PATH=/data/sensor/eBPF/dist/sensor_ebpf-percpu.o"
        else
            $($ssh_run "cd ~/flow/sensor/eBPF;make")
            flow_ebpf="FLOW_EBPF_PATH=/data/sensor/eBPF/dist/sensor_ebpf.o"
        fi
    fi

    if [ ! -z "$run" ]; then
        pretty_print "Running Sensor"
        $($ssh_run "sudo pkill -9 sensor")
        $($ssh_run "kubectl -n nmspc exec \`kubectl get pods -A | grep flow-sensor | awk '{print \$2}'\` -c sensor -n=kube-system -- env $flow_ebpf $flow_debug TEM=1 /data/sensor/sensor")
    fi

    if [ ! -z "$trace" ]; then
        pretty_print "Tracing BPF"
        $($ssh_run "sudo cat /sys/kernel/debug/tracing/trace_pipe")
    fi

    if [ ! -z "$java" ]; then
        pretty_print "Java"

        $($ssh_run "cd ~/flow/janet;source ~/.profile;export JAVA_HOME=/opt/java-se-8u41-ri;export JANET_VERSION=0.1.999;gradle -version;gradle installDist;cp ~/flow/janet/build/libs/javaflow-0.1.999.jar ~/flow/sensor/janet_loader/.")
        # TODO: build janet loader
        pretty_print "Running"
        $($ssh_run "kubectl -n nmspc exec \`kubectl get pods -A | grep flow-sensor | awk '{print \$2}'\` -c flow-java -n=kube-system -- /data/sensor/janet_loader/janet_loader")
    fi
}

# TODO: support vagrant :)
# watch mem: watch -n 1 'sudo smem  --processfilter="sensor" -k -r | grep sensor'
#[[ $a == z* ]]
#modified="${str:1:-1}"
    # if [ ! -z "$start" ]; then
    #     gcloud compute instances start avatichi-agent-kernel$instnace
    # fi


if [ $# -le 2 ]; then
    echo "Not enough arguments supplied"
    print_usage
    exit 1
fi

while getopts 'i:m:fbehrcjtnd' flag; do
case "${flag}" in
    i) instnace="${OPTARG}" ;;
    m) machine="${OPTARG}" ;;
    f) flow=1 ;;
    b) build=1 ;;
    e) ebpf=1 ;;
    c) percpu=1 ;;
    h) help=1 ;;
    r) run=1 ;;
    t) trace=1 ;;
    n) new=1 ;;
    j) java=1 ;;
    # s) start=1 ;;
    d) debug=1 ;;
    *) print_usage
    exit 1 ;;
esac
done
if [ ! -z "$help" ]; then
    print_usage
    exit 1
fi

trap ctrl_c INT
get_machine
handle_args