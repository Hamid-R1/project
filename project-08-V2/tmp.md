wp-mysql-k8s



# project-08-V3



### create one instance with ubuntu20.04 ami


### install docker & docker-compose
```
sudo su -
apt-get update
apt install docker.io -y
docker --version
apt install docker-compose -y
docker-compose -v
```


```
mkdir project
cd project
vim docker-compose.yml
mkdir db_data
mkdir wp_data
docker-compose up -d
```


```
cat docker-compose.yml
version: '3'
services:
  db:
    image: mysql:latest
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: admin123
      MYSQL_DATABASE: hr_db
    volumes:
      - db_data:/var/lib/mysql
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: admin123
      WORDPRESS_DB_NAME: hr_db
    volumes:
      - wp_data:/var/www/html
volumes:
  db_data:
  wp_data:
```


### access wp-apps via public-ip
- yes access,
- install & configure wordpress, done.


```
docker exec -it project_db_1 bin/bash

# go to mysql client/cli
mysql -u root -p		#password is 'admin123'

# see databases
mysql> show databases;

mysql> use hr_db;

mysql> show tables;

mysql> select * from wp_posts;
```

##### ======================== upto here `docker & docker-compose` notes =========================







###### ======================== deploy same things on kubernetes cluster =======================


## deploy same `wordpress` and `mysql` as a databases within `kubernetes cluster` 


### launche 2 `instance` for kubernetes cluster
- one instance for `master node`
	- ubuntu-20.04 ami
	- t2.medium
	- 20gb
- one instance for `worker node`
	- ubuntu-20.04 ami
	- t2.medium
	- 25gb


### ssh `master node` and install & configure `kubernetes tools` 
```
sudo su
apt-get update && apt-get upgrade -y
hostname master
bash


# install ....
{
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sudo apt -y install vim git curl wget kubelet=1.26.0-00 kubeadm=1.26.0-00 kubectl=1.26.0-00
sudo apt-mark hold kubelet kubeadm kubectl
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo kubeadm config images pull --image-repository=registry.k8s.io --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v1.26.0
kubeadm init --image-repository=registry.k8s.io
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config 
kubectl get --raw='/readyz?verbose'
kubectl cluster-info 
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml 
kubeadm token create --print-join-command
kubectl get po -A
}
```




### ssh `worker node` and install & configure `kubernetes tools`
```
sudo su
apt-get update && apt-get upgrade -y
hostname worker
bash



# install......
{
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sudo apt -y install vim git curl wget kubelet=1.26.0-00 kubeadm=1.26.0-00 kubectl=1.26.0-00
sudo apt-mark hold kubelet kubeadm kubectl
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo kubeadm config images pull --image-repository=registry.k8s.io --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v1.26.0
}
```



### next go to `master-node` & copy `kubeadm token create --print-join-command` & paste to `worker node`
```
# copy from master-node & paste to worker node
kubeadm join 172.31.5.10:6443 --token mfhehs.1gcvdz2vtgtqz9co --discovery-token-ca-cert-hash sha256:b5fb1143b4ce8dbb78692cebb087913926172fc39f8074b68f3ed019314b9d7c
```


### next run this in `master node` & check status of maste & worker node is ready or not
```
kubectl get nodes
```


```
vim wp-mysql.yml
kubectl apply -f wp-mysql.yml
kubectl get po -A
```


#### see `wp-mysql.yml` script:
- $ `cat wp-mysql.yml`
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
  replicas: 1
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_HOST
          value: db:3306
        - name: WORDPRESS_DB_USER
          value: root
        - name: WORDPRESS_DB_PASSWORD
          value: admin123
        - name: WORDPRESS_DB_NAME
          value: hr_db
        volumeMounts:
        - name: wp-data
          mountPath: /var/www/html
      - name: mysql
        image: mysql:latest
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: admin123
        - name: MYSQL_DATABASE
          value: hr_db
        volumeMounts:
        - name: db-data
          mountPath: /var/lib/mysql
      volumes:
      - name: db-data
        emptyDir: {}
      - name: wp-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
spec:
  selector:
    app: wordpress
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: LoadBalancer
```



```
kubectl get po -o wide
kubectl exec -it container_name bash

kubectl exec -it cont-mysql bash
mysql -u root -p 		#pasword is 'admin123'
```

