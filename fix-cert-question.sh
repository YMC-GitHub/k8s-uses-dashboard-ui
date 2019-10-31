#!/bin/sh

# 证书目录
CRT_KEY_DIR=key
# 证书名字
CRT_KEY_FILE_NAME=dashboard
# 密钥名字
SECRET_NAME=kubernetes-dashboard-certs
# 命名空间
SECRET_NS=kube-system #kubernetes-dashboard

mkdir -p $CRT_KEY_DIR
# 查看是否存在namespace为$SECRET_NS
# 不存在namespace为创建$SECRET_NS创建namespace
kubectl get namespaces | grep $SECRET_NS
res=$?
if [ $res -eq 0 ];then
    echo "匹配到 $SECRET_NS"
else
   kubectl create namespace $SECRET_NS
fi

KEY_WORK_NAME=${CRT_KEY_DIR}/${CRT_KEY_FILE_NAME}
# 生成密钥
openssl genrsa -out ${KEY_WORK_NAME}.key 2048
# 生成证书
openssl req -days 36000   -new -out ${KEY_WORK_NAME}.csr    -key ${KEY_WORK_NAME}.key   -subj '/CN=**192.168.100.10**'
# 签名证书
openssl x509 -req -in ${KEY_WORK_NAME}.csr -signkey ${KEY_WORK_NAME}.key -out ${KEY_WORK_NAME}.crt
# 目录结构
ls $CRT_KEY_DIR
# 查看旧的证书
kubectl get secret kubernetes-dashboard-certs -n $SECRET_NS
# 删除旧的证书
kubectl delete secret kubernetes-dashboard-certs -n $SECRET_NS
# 创建新的证书
kubectl create secret generic $SECRET_NAME --from-file=${KEY_WORK_NAME}.key --from-file=${KEY_WORK_NAME}.crt -n $SECRET_NS

# 查看相关服务
kubectl get pod -n $SECRET_NS
# 重启相关服务
POD_NAME=$(kubectl get pod -n $SECRET_NS | grep -o "kubernetes-dashboard.\{17\}")
kubectl delete pod $POD_NAME -n $SECRET_NS
# 查看新的服务
POD_LIST=$(kubectl get pod -n $SECRET_NS)
POD_NAME=$(echo $POD_LIST |  grep -o "kubernetes-dashboard.\{17\}")
echo $POD_NAME

#### 一些思考
# 疑惑：服务账号的命名空间和dashborad配置文件中的命名空间不一样时，是否可以？
# 分析：通过改变不同的命名空间，进行测试。
# 行动：
# 结果：

#### 参考文献
::<<EOF
# 更新https证书有效期，解决只能由火狐浏览器访问，其他浏览器无法访问问题
# https://www.cnblogs.com/xiajq/p/11322568.html
# openssl 证书请求和自签名命令req详解
# https://www.cnblogs.com/gordon0918/p/5409286.html
# 
EOF

::<<EOF
grep 'client-certificate-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.crt
grep 'client-key-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.key
openssl pkcs12 -export -clcerts -inkey kubecfg.key -in kubecfg.crt -out kubecfg.p12 -name "kubernetes-client"
echo "拷证书到客户端机器上"
echo "scp root@${MASTER_IP}:/root/kubecfg.p12 ./"
#echo "scp root@${MASTER_IP}:/root/kubecfg.p12 $HOME/"
# scp -i ~/.ssh/google-clound-ssr root@192.168.1.2:/root/kubecfg.p12 $HOME/.kube/
#scp root@${MASTER_IP}:/root/kubecfg.p12 ./

# 参考文献
# https://www.centos.bz/2018/07/kubernetes%E7%9A%84dashboard%E7%99%BB%E5%BD%95%E6%96%B9%E5%BC%8F/
EOF