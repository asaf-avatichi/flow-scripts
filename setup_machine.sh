sudo apt update
sudo apt install rsync make docker.io curl gcc vim -y

curl -sfL https://get.k3s.io |  sh -
curl https://dl.google.com/go/go1.16.linux-amd64.tar.gz -o /tmp/go1.16.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf /tmp/go1.16.linux-amd64.tar.gz
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



# for java 
sudo apt install unzip
wget https://services.gradle.org/distributions/gradle-7.3.2-bin.zip -P /tmp
sudo mkdir /opt/gradle
sudo unzip -d /opt/gradle /tmp/gradle-7.3.2-bin.zip
echo "export PATH=$PATH:/opt/gradle/gradle-7.3.2/bin" >> ~/.profile


wget https://download.java.net/openjdk/jdk8u41/ri/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz -P /tmp
sudo tar zxvf /tmp/openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz -C /opt/
#echo "export PATH=$PATH:/opt/java-se-8u41-ri/bin" >> ~/.profile
#source ~/.profile

wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz -P /tmp
sudo tar zxvf /tmp/openjdk-11+28_linux-x64_bin.tar.gz -C /opt/
echo "export PATH=$PATH:/opt/jdk-11/bin" >> ~/.profile
#echo "export JAVA_HOME=/opt/jdk-11" >> ~/.bashrc


echo "function janet() {\
    java -jar ~/janet/build/libs/javaflow-0.0.1.jar $1 0 debug \
}" >> ~/.bashrc


function gssh() {
    gcloud compute ssh asaf_avatichi@avatichi-agent-kernel$1
}


function go_app() {
    cd ~/flow/flowshop/golang_ssl/server
    go build app.go
    ./app&
    cd ../client
    go build app.go
    ./app
}

sudo apt-get install apache2-utils
# 0xc000043ec8
