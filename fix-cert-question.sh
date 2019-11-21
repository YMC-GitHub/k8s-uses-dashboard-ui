#!/bin/sh

# 证书目录
CRT_KEY_DIR=key
# 证书名字
CRT_KEY_FILE_NAME=dashboard
# 密钥名字
SECRET_NAME=kubernetes-dashboard-certs
# 命名空间
SECRET_NS=kube-system  # the same ns with the kubernetes-dashboard config
#SECRET_NS=kubernetes-dashboard # not the same ns with the kubernetes-dashboard config
# 操作行为
ACTION="创建|启用" #"创建|启用|查看|删除"
mkdir -p $CRT_KEY_DIR
mkdir -p ${CRT_KEY_DIR}/${SECRET_NS}
# 查看是否存在namespace为$SECRET_NS
# 不存在namespace为创建$SECRET_NS创建namespace
kubectl get namespaces | grep $SECRET_NS
res=$?
if [ $res -eq 0 ]; then
    echo "匹配到 $SECRET_NS"
else
    kubectl create namespace $SECRET_NS
fi

KEY_WORK_NAME=${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}

function create_cert() {
    # 生成密钥
    openssl genrsa -out ${KEY_WORK_NAME}.key 2048
    # 生成证书
    openssl req -days 36000 -new -out ${KEY_WORK_NAME}.csr -key ${KEY_WORK_NAME}.key -subj '/CN=**192.168.100.10**'
    # 签名证书
    openssl x509 -req -in ${KEY_WORK_NAME}.csr -signkey ${KEY_WORK_NAME}.key -out ${KEY_WORK_NAME}.crt
}
if [[ "$ACTION" =~ '创建' ]]; then
    create_cert
fi

# 目录结构
ls $CRT_KEY_DIR/${SECRET_NS}

function use_cert() {
    # 查看旧的证书
    kubectl get secret $SECRET_NAME -n $SECRET_NS
    # 删除旧的证书
    kubectl delete secret $SECRET_NAME -n $SECRET_NS
    # 创建新的证书
    kubectl create secret generic $SECRET_NAME --from-file=${KEY_WORK_NAME}.key --from-file=${KEY_WORK_NAME}.crt -n $SECRET_NS
    # 查看相关服务
    kubectl get pod -n $SECRET_NS
    # 重启相关服务
    POD_NAME=$(kubectl get pod -n $SECRET_NS | grep -o "kubernetes-dashboard.\{17\}")
    kubectl delete pod $POD_NAME -n $SECRET_NS
    # 查看新的服务
    POD_LIST=$(kubectl get pod -n $SECRET_NS)
    POD_NAME=$(echo $POD_LIST | grep -o "kubernetes-dashboard.\{17\}")
    echo $POD_NAME
}
if [[ "$ACTION" =~ '启用' ]]; then
    use_cert
fi

function cat_cert() {
    # 查看目录结构
    ls $CRT_KEY_DIR/${SECRET_NS}
    # 查看相关证书
    kubectl get secret $SECRET_NAME -n $SECRET_NS
    # 查看相关服务
    kubectl get pod -n $SECRET_NS
    kubectl get pod -n $SECRET_NS | grep -o "kubernetes-dashboard.\{17\}"
}
if [[ "$ACTION" =~ '查看' ]]; then
    cat_cert
fi

function delete_cert() {
    # 删除相关证书
    kubectl delete secret $SECRET_NAME -n $SECRET_NS
    # 删除目录文件
    rm -rf ${CRT_KEY_DIR}/${SECRET_NS}
}
if [[ "$ACTION" =~ '删除' ]]; then
    delete_cert
fi

#### 一些思考
# 疑惑：服务账号的命名空间和dashborad配置文件中的命名空间不一样时，是否可以？
# 分析：通过改变不同的命名空间，进行测试。
# 行动：SECRET_NS=kubernetes-dashboard
# 结果：没有相关的服务
# 结论：不可以！

#### 参考文献
:: <<EOF
# 更新https证书有效期，解决只能由火狐浏览器访问，其他浏览器无法访问问题
# https://www.cnblogs.com/xiajq/p/11322568.html
# openssl 证书请求和自签名命令req详解
# https://www.cnblogs.com/gordon0918/p/5409286.html
# 
EOF

:: <<EOF
#on-vm:
K8S_PATH="/root/k8s"
CRT_KEY_DIR="key"
SECRET_NS="kube-system"
CRT_KEY_FILE_NAME="dashboard"
SECRET_NAME="kubernetes-dashboard-certs"

KEY_FILE="${K8S_PATH}/${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}.key"
CRT_FILE="${K8S_PATH}/${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}.crt"
P12_FILE="${K8S_PATH}/${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}.p12"
grep 'client-certificate-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.crt

grep 'client-key-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.key

#openssl pkcs12 -export -clcerts -inkey kubecfg.key -in kubecfg.crt -out kubecfg.p12 -name "kubernetes-client"
openssl pkcs12 -export -clcerts -inkey "$KEY_FILE" -in "$CRT_FILE" -out "$P12_FILE" -name "kubernetes-client"

echo "拷证书到客户端机器上"
MASTER_IP=192.168.2.3
echo "scp root@${MASTER_IP}:$P12_FILE ./"
echo "scp root@${MASTER_IP}:$P12_FILE \$HOME/"


#on-pm:
K8S_PATH="/root/k8s"
CRT_KEY_DIR="key"
SECRET_NS="kube-system"
CRT_KEY_FILE_NAME="dashboard"
SECRET_NAME="kubernetes-dashboard-certs"
KEY_FILE="${K8S_PATH}/${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}.key"
CRT_FILE="${K8S_PATH}/${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}.crt"
P12_FILE="${K8S_PATH}/${CRT_KEY_DIR}/${SECRET_NS}/${CRT_KEY_FILE_NAME}.p12"
MASTER_IP=192.168.2.3
scp -i ~/.ssh/google-clound-ssr root@${MASTER_IP}:$P12_FILE $HOME/.kube/
scp root@${MASTER_IP}:$P12_FILE ./

# 参考文献
# https://www.centos.bz/2018/07/kubernetes%E7%9A%84dashboard%E7%99%BB%E5%BD%95%E6%96%B9%E5%BC%8F/
EOF
