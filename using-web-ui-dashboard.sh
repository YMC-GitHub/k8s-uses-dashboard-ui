 #!/bin/sh


#面板目录
DASHBOARD_DIR=dashboard #存放 dashboard 面板文件的目录
#面板版本
#DASHBOARD_VERSION=v2.0.0-beta4 # dashboard 的版本
#DASHBOARD_VERSION=v2.0.0-beta1 
DASHBOARD_VERSION=v1.10.1
#DASHBOARD_VERSION=v1.8.3

# 建相关目录
mkdir -p $DASHBOARD_DIR
mkdir -p ${DASHBOARD_DIR}/${DASHBOARD_VERSION}

# 下配置文件
DASHBOARD_LOCAL_FILE=kubernetes-dashboard.yaml
WORK_FILE_NAME=${DASHBOARD_DIR}/${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE}
case $DASHBOARD_VERSION in
    'v1.10.1'|'v1.8.3')
    echo '下配置文件-地址01'
    curl -o $WORK_FILE_NAME https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/src/deploy/recommended/kubernetes-dashboard.yaml
    ;;
    'v2.0.0-beta1'|'v2.0.0-beta2')
    echo '下配置文件-地址01'
    curl -o $WORK_FILE_NAME https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
    ;;
    *)
    echo '修下配置文件-其他03'
    ;;
esac
# 备份其配置
cp $WORK_FILE_NAME ${WORK_FILE_NAME}.backup
# cp --force ${WORK_FILE_NAME}.backup $WORK_FILE_NAME
# 改配置文件
#2 修复证书问题
# action-设置|set
function fix_cert_question_as_set_action(){
#sed -n '46,57p'  $WORK_FILE_NAME
sed -i '46,57s/^/#/g'  $WORK_FILE_NAME
sed -n '46,57p'  $WORK_FILE_NAME
}
function fix_cert_question_as_del_action(){
# action-删除|del
sed -i '46,57s/^#//g'  $WORK_FILE_NAME
sed -n '46,57p'  $WORK_FILE_NAME
}
ACTION="设置"
#ACTION="删除"
case $ACTION in
    '设置'|set)
    echo '修复证书问题-行动之设置'
    fix_cert_question_as_set_action
    ;;
    '删除'|del)
    echo '修复证书问题-行动之删除'
    fix_cert_question_as_del_action
    ;;
    *)
    echo '修复证书问题-行动之其他'
    ;;
esac

#2 查看所需镜像
# cat --number $WORK_FILE_NAME | grep "image"
#2 用国内镜像（替换）
# v2.0.0-beta4镜像不以k8s.gcr.io（kubernetesui/dashboard）开头，不用以下镜像
#debug-note:cat --number $WORK_FILE_NAME | grep "image"
sed -i 's@image: k8s.gcr.io/@image: registry.cn-hangzhou.aliyuncs.com/google_containers/@g' $WORK_FILE_NAME
#2 用国外镜像（还原）
#sed -i 's@image: registry.cn-hangzhou.aliyuncs.com/google_containers/@image: k8s.gcr.io/@g' $WORK_FILE_NAME
#2 部在何节点
#cat --number $WORK_FILE_NAME | grep "nodeSelector"
#sed -n '188,197p'  $WORK_FILE_NAME
WORK_FILE_LINE=188
sed -i "${WORK_FILE_LINE}a nodeSelector:     #部署在哪一个节点的选择器" $WORK_FILE_NAME
WORK_FILE_LINE=`expr $WORK_FILE_LINE + 1`
sed -i "${WORK_FILE_LINE}s/^ *//g" $WORK_FILE_NAME
SPACE_LENGTH=$(printf "%6s" ' ')
sed -i "${WORK_FILE_LINE}s/^/$SPACE_LENGTH/" $WORK_FILE_NAME

sed -i "${WORK_FILE_LINE}a type: master" $WORK_FILE_NAME
WORK_FILE_LINE=`expr $WORK_FILE_LINE + 1`
sed -i "${WORK_FILE_LINE}s/^ *//g" $WORK_FILE_NAME
SPACE_LENGTH=$(printf "%8s" ' ')
sed -i "${WORK_FILE_LINE}s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
#sed -n "${WORK_FILE_LINE}p"  $WORK_FILE_NAME

#2 下拉镜像方式
#查看下拉镜像方式
# cat --number $WORK_FILE_NAME | grep "imagePullPolicy:"
#设置下拉镜像方式
sed -i "s/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/" $WORK_FILE_NAME


#2 update apiserver-host address
::<<set-for-update-apiserver-host-address
cat --number $WORK_FILE_NAME | grep "apiserver"
set-for-update-apiserver-host-address

# NodePort方式访问dashboard
#2 设置NodePort方式访问dashboard
case $DASHBOARD_VERSION in
    'v1.10.1'|'v1.8.3')
    echo '访问dashboard方式-地址01'
    set_nodeport_on_1_10_1 #NodePort
    ;;
    'v2.0.0-beta1'|'v2.0.0-beta2')
    echo '访问dashboard方式-地址02'
    WORK_FILE_LINE=188
    ;;
    *)
    echo '访问dashboard方式-其他03'
    ;;
esac
function set_nodeport_on_1_10_1(){
# cat --number $WORK_FILE_NAME
# cat --number $WORK_FILE_NAME | grep -C 10 "157"
sed -i '157a type: NodePort' $WORK_FILE_NAME
sed -i '158s/^ *//g' $WORK_FILE_NAME
sed -i "158s/^/  /" $WORK_FILE_NAME
#or (按需使用)
#kubectl --namespace=kube-system edit service kubernetes-dashboard
# 删除
##sed -i '158d' $WORK_FILE_NAME

#2 插入--161行后插入一行nodePort: 30088
sed -i '161a nodePort: 30088' $WORK_FILE_NAME
#note-ymc:行首删除空格
sed -i '162s/^ *//g' $WORK_FILE_NAME
#note-ymc:行首添加指定数量空格
#sed -i "162s/^/    /" $WORK_FILE_NAME
SPACE_LENGTH=$(printf "%6s" ' ')
sed -i "162s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
#2 还原--删除162行
#sed -i '162d' $WORK_FILE_NAME
}
function set_nodeport_on_2_0_0(){
WORK_FILE_LINE=39
sed -i "${WORK_FILE_LINE}a type: NodePort" $WORK_FILE_NAME
WORK_FILE_LINE=`expr $WORK_FILE_LINE + 1`
sed -i "${WORK_FILE_LINE}s/^ *//g" $WORK_FILE_NAME
SPACE_LENGTH=$(printf "%2s" ' ')
sed -i "${WORK_FILE_LINE}s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
WORK_FILE_LINE=42
sed -i "${WORK_FILE_LINE}a nodePort: 30001" $WORK_FILE_NAME
WORK_FILE_LINE=`expr $WORK_FILE_LINE + 1`
sed -i "${WORK_FILE_LINE}s/^ *//g" $WORK_FILE_NAME
SPACE_LENGTH=$(printf "%6s" ' ')
sed -i "${WORK_FILE_LINE}s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
sed -n "39,45p" $WORK_FILE_NAME
}
function connect_to_dashboard_as_nodeport(){
#DASHBOARD_VERSION=v1.10.1
case $DASHBOARD_VERSION in
    'v1.10.1'|set)
    echo $DASHBOARD_VERSION
    set_nodeport_on_1_10_1
    ;;
    'v2.0.0-beta4'|del)
    echo $DASHBOARD_VERSION
    set_nodeport_on_2_0_0
    ;;
    *)
    echo '修复证书问题-行动之其他'
    ;;
esac
}

# 需修改RoleBinding的相关参数，绑定权限更高的角色
::<<set-role-binding-to-cluster
#cat --number $WORK_FILE_NAME | grep -C 10 "RoleBinding"
#cat --number $WORK_FILE_NAME | grep --line-number "RoleBinding"
#cat --number $WORK_FILE_NAME | grep --line-number "kind: Role"
# cat --number $WORK_FILE_NAME
#2 kind
sed -i '76s/kind: RoleBinding/kind: ClusterRoleBinding/' $WORK_FILE_NAME
#2 metadata
sed -i '78s/name: kubernetes-dashboard-minimal/name: kubernetes-dashboard/' $WORK_FILE_NAME
sed -i '79d' $WORK_FILE_NAME
#2 roleRef
#sed -i '82s/kind: Role/kind: ClusterRole/' $WORK_FILE_NAME
#sed -i '83s/name: kubernetes-dashboard-minimal/name: cluster-admin/' $WORK_FILE_NAME
sed -i '81s/kind: Role/kind: ClusterRole/' $WORK_FILE_NAME
sed -i '82s/name: kubernetes-dashboard-minimal/name: cluster-admin/' $WORK_FILE_NAME



#cat --number $WORK_FILE_NAME | grep --line-number "ClusterRoleBinding"
#cat --number $WORK_FILE_NAME | grep --line-number "kind: ClusterRole"
#cat --number $WORK_FILE_NAME | grep -C 10 "ClusterRoleBinding"
set-role-binding-to-cluster


# 用配置文件
kubectl delete ns kubernetes-dashboard
kubectl apply --filename $WORK_FILE_NAME
# 删配置文件
#kubectl delete --filename $WORK_FILE_NAME
# 看配置文件
# cat --number $WORK_FILE_NAME
# cat --number $WORK_FILE_NAME | grep "kind: ServiceAccount"
# kubectl get --filename $WORK_FILE_NAME -o json
#kubectl get serviceaccount dashboard -o json
#kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}"
#kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode


# 查看所需镜像
cat --number $WORK_FILE_NAME | grep "image"
# 查看已下镜像
docker image ls | grep "dashboard\|kubernetesui"
# 查看单元状态
kubectl get pods --all-namespaces
kubectl get pods --all-namespaces | grep dashboard
# 在何节点运行
kubectl get pods --namespace=kube-system  -o wide
# 在何端口运行
kubectl get services --all-namespaces | grep dashboard
kubectl  get cs
kubectl cluster-info


# 创建某一用户
SERVICE_ACOUNT_DIR=serivce-acount #服务账号配置文件存放目录
mkdir -p ${DASHBOARD_DIR}/${DASHBOARD_VERSION}/${SERVICE_ACOUNT_DIR}
cat > ${DASHBOARD_DIR}/${DASHBOARD_VERSION}/${SERVICE_ACOUNT_DIR}/dashboard-admin-user.yaml << eof-dashboard-admin-user
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
eof-dashboard-admin-user
kubectl apply --filename ${DASHBOARD_DIR}/${DASHBOARD_VERSION}/${SERVICE_ACOUNT_DIR}/dashboard-admin-user.yaml
cat > ${DASHBOARD_VERSION}/kube-dashboard-rbac.yml<<kube-dashboard-rbac-config
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
kube-dashboard-rbac-config
kubectl create --filename ${DASHBOARD_VERSION}/kube-dashboard-rbac.yml
# kubectl delete --filename ${DASHBOARD_VERSION}/kube-dashboard-rbac.yml
cat > ${DASHBOARD_VERSION}/dashboard-admin.yml<<dashboard-admin-config
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
dashboard-admin-config

# 生成某一证书
::<<set-cert-way-01
grep 'client-certificate-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.crt
grep 'client-key-data' ~/.kube/config | head -n 1 | awk '{print $2}' | base64 -d >> kubecfg.key
openssl pkcs12 -export -clcerts -inkey kubecfg.key -in kubecfg.crt -out kubecfg.p12 -name "kubernetes-client"
echo "拷证书到客户端机器上"
echo "scp root@${MASTER_IP}:/root/kubecfg.p12 ./"
#echo "scp root@${MASTER_IP}:/root/kubecfg.p12 $HOME/"
# scp -i ~/.ssh/google-clound-ssr root@192.168.1.2:/root/kubecfg.p12 $HOME/.kube/
#scp root@${MASTER_IP}:/root/kubecfg.p12 ./
set-cert-way-01
# 证书目录
KEY_DIR=key #存储证书
KEY_FILE_NAME=dashboard
mkdir -p ${DASHBOARD_DIR}/${KEY_DIR}

# 命名空间
kubectl get namespaces | grep "kubernetes-dashboard" #查看是否存在namespace为kubernetes-dashboard
# 不存在namespace为创建kubernetes-dashboard创建namespace
# kubectl create namespace kubernetes-dashboard

# 生成 key
WORK_FILE_NAME=${DASHBOARD_DIR}/${KEY_DIR}/${KEY_FILE_NAME}
openssl genrsa -out ${WORK_FILE_NAME}.key 2048
# 生成证书请求
openssl req -days 36000   -new -out ${WORK_FILE_NAME}.csr    -key ${WORK_FILE_NAME}.key   -subj '/CN=**192.168.100.10**'
# 生成自签证书
openssl x509 -req -in ${WORK_FILE_NAME}.csr -signkey ${WORK_FILE_NAME}.key -out ${WORK_FILE_NAME}.crt
# 目录结构
ls ${DASHBOARD_DIR}/${KEY_DIR}/
# 使用自签证书创建secret
kubectl create secret generic kubernetes-dashboard-certs     --from-file=${WORK_FILE_NAME}.key     --from-file=${WORK_FILE_NAME}.crt      -n kubernetes-dashboard

# 登录控制面板
#2 访问dashboad之NodePort
# https://${MASTER_IP}:${NodePort}
# 物理机：https://192.168.1.2:30088
# 虚拟机：https://192.168.1.2:30088
#2 访问dashboad之Ingress
#2 访问dashboad之接口代理-API Server（需要导入证书）
# 物理机：https://192.168.1.2:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
# 虚拟机：https://192.168.1.2:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

#2 访问dashboad之接口代理-kubectl proxy
# kubectl proxy --address='0.0.0.0' --port=8888 --accept-hosts='^*$'
# 物理机：http://192.168.1.2:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy
# 虚拟机：http://localhost:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

# 认证dashboad之令牌登录
SERVICE_ACOUNT_NAME=dashboard-admin
SERVICE_ACOUNT_NS=kube-system
CLUTER_ROLE_NAME=cluster-admin
CLUTER_ROLE_BINDING_NAME=dashboard-cluster-admin
#创建服务账号
kubectl create serviceaccount $SERVICE_ACOUNT_NAME -n $SERVICE_ACOUNT_NS
#绑定集群角色
kubectl create clusterrolebinding $CLUTER_ROLE_BINDING_NAME --clusterrole=$CLUTER_ROLE_NAME --serviceaccount=${SERVICE_ACOUNT_NS}:${SERVICE_ACOUNT_NAME}
#获取访问令牌
#SECRET_TOKEN_NAME=$(kubectl get secret -n kube-system | grep -o "kubernetes-dashboard-token.\{6\}")
#SECRET_TOKEN_VALUE=$(kubectl describe secret $SECRET_TOKEN_NAME -n kube-system | grep "token:" | sed "s/token:      //g")
#echo $SECRET_TOKEN_NAME
#echo $SECRET_TOKEN_VALUE

SECRET_TOKEN_NAME=$(kubectl get serviceaccount $SERVICE_ACOUNT_NAME -n $SERVICE_ACOUNT_NS -o jsonpath="{.secrets[0].name}")
#SECRET_TOKEN_VALUE=$(kubectl get secret $SECRET_TOKEN_NAME -o jsonpath="{.data.token}" | base64 --decode)
SECRET_TOKEN_VALUE=$(kubectl describe secret $SECRET_TOKEN_NAME -n kube-system | grep "token:" | sed "s/token:      //g")
echo $SECRET_TOKEN_NAME
echo $SECRET_TOKEN_VALUE

# 疑惑:下面两种方式获得的服务账户的token文件名字不一样
# SECRET_TOKEN_NAME=$(kubectl get secret -n kube-system | grep -o "kubernetes-dashboard-token.\{6\}")
# SECRET_TOKEN_NAME=$(kubectl get serviceaccount $SERVICE_ACOUNT_NAME -n $SERVICE_ACOUNT_NS -o jsonpath="{.secrets[0].name}")
# 本操作下，此处下面的这个token对应的哪个服务账户权限要大一些。

# 认证dashboad之密码登录
# 认证dashboad之配置登录
# 认证dashboad之无密登录
# kubectl proxy --address='0.0.0.0' --port=8888 --accept-hosts='^*$' &
# 问题：端口占用
# 原因：
# 解决：
::<<centos7-delete-used-port
# 被占用的端口
PORT=8888
# 获取进程编号
PROCESS_ID=$(netstat -nap | grep $PORT)
# 杀死相关进程
kill $PROCESS_ID
centos7-delete-used-port
#


##########
# centos启用图形模式
##########
#D:\code-store\Shell\centos-set-default-mode

########
# k8s认证：证书-身份识别
# 为什么要认证--上学时候给心仪的女孩传纸条，传送的过程可能会被别的同学偷看，甚至内容可能会从我喜欢你修改成我不喜欢你了.
########
# 用户账号
# 本地证书-可直接连接apiserver授信
# cat .kube/config
# 服务账号
# D:\code-store\Shell\k8s-manage-service-account

########
# k8s授权：rbac-权限检查
########
# D:\code-store\Shell\k8s-manage-service-account

########
# k8s准入控制：补充授权机制-多个插件实现，只在创建 删除 修改 或做代理操作时做补充
########

#### 遇到问题
# 问题：configmaps is forbidden: User "system:serviceaccount:kube-system:kubernetes-dashboard" 
# 描述：于vmware的centos7中使用NodePort方式访问dashboard成功后，输入令牌进行认证，出现该提示。
# 解决：
# 参考：https://blog.51cto.com/icenycmh/2122309
::<<delete-err-0001
sed -i 's/kind: RoleBinding/kind: ClusterRoleBinding/g' ${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE}
sed -i 's/name: kubernetes-dashboard-minimal/name: kubernetes-dashboard/g' ${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE}
sed -i 's/name: kubernetes-dashboard-minimal/name: cluster-admin/g' ${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE}
# cat ${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE} | grep "kind: Role"
delete-err-0001
::<<delete-err-0001-way02
SERVICE_ACOUNT_NAME=dashboard-admin
SERVICE_ACOUNT_NS=kube-system
CLUTER_ROLE_NAME=cluster-admin
CLUTER_ROLE_BINDING_NAME=dashboard-cluster-admin
#创建服务账号
kubectl create serviceaccount $SERVICE_ACOUNT_NAME -n $SERVICE_ACOUNT_NS
#绑定集群角色
kubectl create clusterrolebinding $CLUTER_ROLE_BINDING_NAME --clusterrole=$CLUTER_ROLE_NAME --serviceaccount=${SERVICE_ACOUNT_NS}:${SERVICE_ACOUNT_NAME}
#获取访问令牌
SECRET_TOKEN_NAME=$(kubectl get serviceaccount $SERVICE_ACOUNT_NAME -n $SERVICE_ACOUNT_NS -o jsonpath="{.secrets[0].name}")
#SECRET_TOKEN_VALUE=$(kubectl get secret $SECRET_TOKEN_NAME -o jsonpath="{.data.token}" | base64 --decode)
SECRET_TOKEN_VALUE=$(kubectl describe secret $SECRET_TOKEN_NAME -n kube-system | grep "token:" | sed "s/token:      //g")
echo $SECRET_TOKEN_NAME
echo $SECRET_TOKEN_VALUE
delete-err-0001-way02

# 问题：services \"https:kubernetes-dashboard:\" is forbidden: User \"system:anonymous\" cannot get resource \"services/proxy\" in API group \"\" in the namespace \"kube-system\""
# 描述：于vmware的centos7中使用API Server方式访问dashboard时出现
# 参考：https://www.centos.bz/2018/07/kubernetes%E7%9A%84dashboard%E7%99%BB%E5%BD%95%E6%96%B9%E5%BC%8F/
# 原因：可能是证书问题
# 解决：
# 火狐浏览器Mozilla Firefox怎样导入证书
# https://jingyan.baidu.com/article/4e5b3e191205d291911e2463.html
# Kubernetes dashboard1.8.0 WebUI安装与配置
# https://blog.csdn.net/a632189007/article/details/78840971
# 
# 问题：您的连接不是私密连接
# 描述：于物理机中使用非firefox访问dashboad之NodePort时，出现该提示。只有firefox浏览器可以访问。
# 解决：D:\code-store\Shell\k8s-uses-web-ui-dashboard\fix-cert-question-in.sh
# 参考：
# 分析：可能是证书问题
# 原因：
# 更新https证书有效期，解决只能由火狐浏览器访问，其他浏览器无法访问问题
# https://www.cnblogs.com/xiajq/p/11322568.html
# # https://www.jianshu.com/p/f7ebd54ed0d1
::<<delete-err-0002-way2
mkdir certs
kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
kubectl get pods --namespace="kube-system"
kubectl describe pods/kubernetes-dashboard-68798cb565-lwcrb --namespace="kube-system" 
delete-err-0002-way2


# 问题：raw.githubusercontent.com 的响应时间过长。
# 描述：
# 解决：
# echo "151.101.100.133 raw.githubusercontent.com " >> /etc/hosts



# 问题：Unauthorized
# 描述：于vmware的centos7中使用API Server方式访问dashboard，提示需要证书，导入相关证书之后继续就出现该提示。
# 分析：可能是浏览器缓存了之前的token，关闭浏览器，重新用token登录。
# 原因：
# 解决：
# 参考：

# 问题：error validating "dashboard/v2.0.0-beta4/kubernetes-dashboard.yaml"
# 参考：
# 解决：检查文件格式
# 原因：该配置文件格式不对

# 问题："services \"kubernetes-dashboard\" not found"
# 参考：
# 解决：
# 原因
::<<EOF
# 查看服务账号
kubectl get serviceaccounts
kubectl get serviceaccount dashboard -n default
kubectl describe serviceaccount dashboard -n default
kubectl describe serviceaccount default -n default
# 删除服务账号
kubectl delete serviceaccount dashboard -n default
# 删除集群绑定
kubectl delete clusterrolebinding dashboard-admin -n default

#创建服务账号
kubectl create serviceaccount dashboard -n default
#绑定集群用户
kubectl create clusterrolebinding dashboard-admin -n default --clusterrole=cluster-admin  --serviceaccount=default:dashboard
#获取访问令牌
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
kubectl describe secret -n kube-system dashboard-admin-token
# 疑惑:下面两种方式获得的服务账户的token文件名字不一样
# SECRET_TOKEN_NAME=$(kubectl get secret -n kube-system | grep -o "kubernetes-dashboard-token.\{6\}")
# SECRET_TOKEN_NAME=$(kubectl get serviceaccount $SERVICE_ACOUNT_NAME -n $SERVICE_ACOUNT_NS -o jsonpath="{.secrets[0].name}")
# 本操作下，此处下面的这个token对应的哪个服务账户权限要大一些。
EOF

#########
# 参考文献
#########
#
# https://blog.csdn.net/java_zyq/article/details/82178152
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# https://github.com/kubernetes/dashboard
# https://github.com/kubernetes/dashboard/releases
#
# centos7下kubernetes（5。部署kubernetes dashboard）
# https://www.cnblogs.com/lkun/p/9603051.html
# kubernetes搭建dashboard报错
# https://www.cnblogs.com/xulingjie/p/10101321.html
# kubernetes的dashboard登录方式
# https://www.centos.bz/2018/07/kubernetes%E7%9A%84dashboard%E7%99%BB%E5%BD%95%E6%96%B9%E5%BC%8F/

# 安装kubernetes1.12.1的 dashboard v1.10 + Heapster
# http://www.chinacion.cn/article/4402.html
# Kubernetes-基于k8s-v1.14.0安装dashboard-1.10.1
# https://blog.csdn.net/Excairun/article/details/88989706
# Kubernetes1.15.1安装 Dashboard 的WEB UI插件
# https://cloud.tencent.com/developer/article/1487532
# kubernetes1.16 安装dashboard UI
# https://www.jianshu.com/p/f7ebd54ed0d1
#
# 跟着官方文档从零搭建K8S
# https://juejin.im/post/5d7fb46d5188253264365dcf#heading-18
# Using RBAC Authorization
# https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding

::<<eof
Linux下使用SSH远程执行命令方法收集
https://www.cnblogs.com/EasonJim/p/8431628.html
SSH 远程执行任务
https://www.cnblogs.com/sparkdev/p/6842805.html
linux 安装ssh以及ssh用法与免密登录
https://www.cnblogs.com/xiaoaofengyue/p/8080639.html
Google Cloud Platform配置SSH公钥私钥无密码登录
https://www.jianshu.com/p/b5da657a824d
linux 本地终端 SSH 连接 gcp (Google Cloud Platform ) 配置教程
https://blog.csdn.net/u010820857/article/details/88240477
sed命令替换文件内容
https://www.cnblogs.com/YLuluuu/p/9258782.html
linux （debian） 设置开机自启动
https://blog.csdn.net/liguangxianbin/article/details/79591423
shell读取文件内容并进行变量赋值
https://blog.csdn.net/smallnetvisitor/article/details/81285456
Linux里如何查找文件内容
http://blog.chinaunix.net/uid-25266990-id-199887.html
grep和正则表达式
https://www.cnblogs.com/hmm01031007/p/11354542.html
【sed】删除和替换文件中某一行的方法
https://blog.csdn.net/feifei_csdn/article/details/80841442
从文件中搜索关键字并显示行数（cat,grep函数）
https://www.cnblogs.com/chenwenyan/p/7840486.html

k8s安装部署过程个人总结及参考文章
https://www.cnblogs.com/snowwhite/p/9074918.html
Using kubeadm to Create a Cluster（推荐）
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

docker machine创建docker主机时能否指定主机静态ip地址
http://www.dockone.io/question/963

修改 docker-machine 的默认 IP 地址
https://www.huolg.net/devops/707

2019安装k8s详细教程
https://blog.csdn.net/xyz_dream/article/details/88372356

k8s集群一键安装（v1.11.2）
https://blog.csdn.net/ws576023219/article/details/83142406
https://github.com/ws1990/k8s-install.git

使用kubeadmin快速部署一个K8S集群（1.14）（centos）
https://www.cnblogs.com/nulige/articles/10941218.html

Kubeadmin自动化部署kubernetes-1.14.1(centos)
https://blog.csdn.net/a814902893/article/details/97273565

使用 kubeadm 在 GCP 部署 Kubernetes
https://www.jianshu.com/p/dfce7dc51e85

从零开始搭建Kubernetes集群（一）----虚拟机的安装
https://blog.csdn.net/java_zyq/article/details/82147871
从零开始搭建K8S集群（二）-- 搭建K8S集群
https://blog.csdn.net/java_zyq/article/details/82149869

从零开始搭建Kubernetes集群（三、搭建K8S集群）
https://blog.csdn.net/qq_27639619/article/details/88816387

从零开始搭建K8S--搭建K8S Ingress
https://blog.csdn.net/java_zyq/article/details/82179107

使用VirtualBox在本地搭建单节点K8S集群
https://www.jianshu.com/p/73930e3a6359

虚拟机virtualbox安装kubernetes 1.14【第一篇、安装设置虚拟机】
https://blog.csdn.net/hanbing6174/article/details/90085461

虚拟机virtualbox安装kubernetes 1.14【第二篇、安装k8s】
https://blog.csdn.net/hanbing6174/article/details/90092800

虚拟机virtualbox安装kubernetes 1.14【第三篇、安装DashBoard】
https://blog.csdn.net/hanbing6174/article/details/90108200

K8s-部署应用
https://www.cnblogs.com/zydev/p/10318801.html

在k8s集群上运行你的应用
https://blog.csdn.net/qq_33171970/article/details/98779719

Hyper-V 批量创建虚拟机自动改IP并配置PPPOE拨号
https://blog.51cto.com/biwei/2308671

在VMware Workstation中批量创建上千台虚拟机
https://blog.51cto.com/wangchunhai/1940573

利用win10自带的虚拟机Hyper-V安装Centos7
https://www.cnblogs.com/cxxjohnson/p/9267988.html
#  bcdedit /set hypervisorlaunchtype off

使用 kubeadm 安装 kubernetes v1.16
https://www.kubernetes.org.cn/5846.html

kubernetes1.16.0高可用安装(sealos)
https://www.kubernetes.org.cn/5904.html

安装Kubernetes V1.16.2
https://www.cnblogs.com/bluersw/p/11713468.html

Kubernetes 安装文档推荐(1.15.1)
https://www.kubernetes.org.cn/5650.html

kubernetes(k8s)集群安装calico
https://www.cnblogs.com/sunsky303/p/11268289.html

k8s calico flannel cilium 网络性能测试
https://www.jianshu.com/p/cfc4e62ff3ea

k8s与各网络插件集成
https://yq.aliyun.com/articles/680081/

ssh 使用 sed 替换的时候，替换的字符串有单双引号的时候怎么用
https://www.cnblogs.com/zhuzi91/p/8990416.html

linux中sed命令替换包含引号、斜杠等特殊字符的的使用
https://blog.csdn.net/lovingwyf/article/details/38375277

VMware中CentOS 7设置固定IP同时连接内外网，网络配置
https://blog.csdn.net/java_zyq/article/details/78280904

VMware虚拟机设置centos固定ip地址
https://blog.csdn.net/xukaijj/article/details/78855402

Centos 7.5 双网卡内外网同时访问路由设置
https://blog.csdn.net/weixin_42926889/article/details/81814780

VMware虚拟CentOS 6.5在NAT模式下配置静态IP地址及Xshell远程控制配置
https://blog.csdn.net/wanz2/article/details/52820876

VMware虚拟机三种网络模式（Centos虚拟机）
https://blog.csdn.net/zhang_xinxiu/article/details/84404848

Failed to start LSB 网络服务启动失败的四种解决方法
https://blog.csdn.net/luckyzsion/article/details/78282000

CentOS ping www.baidu.com 报错 name or service not know
https://www.cnblogs.com/Lin-Yi/p/7787392.html

install-kubeadm
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

Kubernetes 各版本基础镜像列表
https://www.cnblogs.com/twobrother/p/11188865.html

Kubernetes  dashboard镜像
https://github.com/kubernetes/dashboard/releases

iptables查看、添加、删除规则
https://www.cnblogs.com/bethal/p/5806525.html

K8S从1.15.x升级到 1.15.5
https://kuboard.cn/install/upgrade-k8s/1.15.x-1.15.4.html#%E5%89%8D%E6%8F%90%E6%9D%A1%E4%BB%B6

kubeadm单集群部署k8s1.15.1&calico网络
https://www.cnblogs.com/AutoSmart/p/11230268.html

k8s集群配置dashboard（最先版1.13.3 1.10.1）
https://blog.csdn.net/AtlanSI/article/details/88544500
kubeadm安装kubernetes1.13集群
http://www.luyixian.cn/news_show_11429.aspx
eof

#### 卸载k8sdashboard
::<<eof-delete-dashboard
kubectl get secret,sa,role,rolebinding,services,deployments --namespace=kube-system | grep dashboard

kubectl delete deployment kubernetes-dashboard --namespace=kube-system 
kubectl delete service kubernetes-dashboard  --namespace=kube-system 
kubectl delete role kubernetes-dashboard-minimal --namespace=kube-system 
kubectl delete rolebinding kubernetes-dashboard-minimal --namespace=kube-system
kubectl delete sa kubernetes-dashboard --namespace=kube-system 
kubectl delete secret kubernetes-dashboard-certs --namespace=kube-system
kubectl delete secret kubernetes-dashboard-key-holder --namespace=kube-system
eof-delete-dashboard



