sudo apt update
sudo apt install rsync make docker.io curl gcc vim -y

curl -sfL https://get.k3s.io |  sh -
curl https://dl.google.com/go/go1.15.linux-amd64.tar.gz -o /tmp/go1.15.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf /tmp/go1.15.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
sudo chmod 777 /etc/rancher/k3s/k3s.yaml

mkdir -p ~/flow
sudo ln -s ~/flow/ /srv/

echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

echo "alias flowexec=\"kubectl exec --stdin --tty `kubectl get pods -A | grep flow-sensor | awk '{print $2}'` -n=kube-system -- /bin/bash\"" >> ~/.bashrc
echo "alias flowhelm='cd ~/flow/sensor/deploy/;helm install flow . --set flowToken=\"\"\
    --set flowClientID=\"810c21d2-9134-4a92-aa1b-a01d1a89cdcf\"\
    --set flowClientSecret=\"46ed464f-2ed7-438a-8443-c652dea3d330\"\
    --set flowUrl=\"https://api.dev.flowsecurity.app/\"\
    --set flowRepository=\"registry.dev.flowsecurity.app\"\
    --set flowSensorManagerPath=\"sensor\"\
    --set flowAuthUrl=\"https://flow-dev.frontegg.com/frontegg/identity/resources/auth/v1/api-token\"\
    --set flowAuthAud=\"https://flowsecurity-staging-authenticator\"\
    --set image.repository=\"registry.dev.flowsecurity.app/sensor\"\
    --set init_image.repository=\"registry.dev.flowsecurity.app/init_sensor\"\
    --set clusterName=\"Avatichi\"\
    -n kube-system'
alias flowrun=\"kubectl -n nmspc exec  `kubectl get pods -A | grep flow-sensor | awk '{print $2}'` -n=kube-system -- env FLOW_EBPF_PATH=/data/sensor/eBPF/dist/sensor_ebpf.o /data/sensor/sensor\"" >> ~/.bashrc