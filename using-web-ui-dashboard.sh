 #!/bin/sh

mkdir -p dashboard
cd dashboard

# 指定某版本

dashboard_version=v2.0.0-beta1
#dashboard_version=v1.10.1
#dashboard_version=v1.8.3
mkdir $dashboard_version

# 下配置文件
dashboard_local_file=kubernetes-dashboard.yaml
curl -o $dashboard_local_file https://raw.githubusercontent.com/kubernetes/dashboard/${dashboard_version}/src/deploy/recommended/kubernetes-dashboard.yaml
# 改配置文件
#2 用国内镜像（替换）
#debug-note:cat $dashboard_local_file | grep "image"
sed -i 's@image: k8s.gcr.io/@image: registry.cn-hangzhou.aliyuncs.com/google_containers/@g' $dashboard_local_file
#2 用国外镜像（还原）
#sed -i 's@image: registry.cn-hangzhou.aliyuncs.com/google_containers/@image: k8s.gcr.io/@g' $dashboard_local_file
#2 update apiserver-host address
::<<set-for-update-apiserver-host-address
cat $dashboard_local_file | grep "apiserver"
set-for-update-apiserver-host-address
# update kubernetes-dashboard service -> type to "NodePort"
::<<set-for-update-service-type
# cat --number $dashboard_local_file
sed -i '157a type: NodePort' $dashboard_local_file
sed -i '158s/^ *//g' $dashboard_local_file
sed -i "158s/^/  /" $dashboard_local_file
#or (按需使用)
#kubectl --namespace=kube-system edit service kubernetes-dashboard
# 删除
##sed -i '158d' $dashboard_local_file


#2 插入--161行后插入一行nodePort: 30088
sed -i '161a nodePort: 30088' $dashboard_local_file
#note-ymc:行首删除空格
sed -i '162s/^ *//g' $dashboard_local_file
#note-ymc:行首添加指定数量空格
#sed -i "162s/^/    /" $dashboard_local_file
SPACE_LENGTH=$(printf "%6s" ' ')
sed -i "162s/^/$SPACE_LENGTH/" $dashboard_local_file
#2 还原--删除162行
#sed -i '162d' $dashboard_local_file
set-for-update-service-type

# 需修改RoleBinding的相关参数，绑定权限更高的角色
::<<set-role-binding-to-cluster
#cat $dashboard_local_file | grep --line-number "RoleBinding"
#cat $dashboard_local_file | grep --line-number "kind: Role"
# cat --number $dashboard_local_file
#2 kind
sed -i '76s/kind: RoleBinding/kind: ClusterRoleBinding/' $dashboard_local_file
#2 metadata
sed -i '78s/name: kubernetes-dashboard-minimal/name: kubernetes-dashboard/' $dashboard_local_file
sed -i '79d' $dashboard_local_file
#2 roleRef
#sed -i '82s/kind: Role/kind: ClusterRole/' $dashboard_local_file
#sed -i '83s/name: kubernetes-dashboard-minimal/name: cluster-admin/' $dashboard_local_file
sed -i '81s/kind: Role/kind: ClusterRole/' $dashboard_local_file
sed -i '82s/name: kubernetes-dashboard-minimal/name: cluster-admin/' $dashboard_local_file



#cat $dashboard_local_file | grep --line-number "ClusterRoleBinding"
#cat $dashboard_local_file | grep --line-number "kind: ClusterRole"
set-role-binding-to-cluster


# To access Dashboard from your local workstation
# ...
# 移到相关目录
mv --force $dashboard_local_file ${dashboard_version}/${dashboard_local_file}
# cp --force ${dashboard_version}/${dashboard_local_file} $dashboard_local_file
# 用配置文件
kubectl delete ns kubernetes-dashboard
kubectl apply --filename ${dashboard_version}/$dashboard_local_file
# 删配置文件
#kubectl delete --filename ${dashboard_version}/$dashboard_local_file
# 看配置文件
# cat --number ${dashboard_version}/$dashboard_local_file
kubectl get --filename ${dashboard_version}/$dashboard_local_file -o json
#kubectl get serviceaccount dashboard -o json
#kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}"
#kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

# 查看节点
kubectl get pod --namespace kube-system | grep "dashboard"
# 查看服务
kubectl get service --namespace kube-system | grep "kubernetes-dashboard"
kubectl get svc --namespace kube-system | grep "kubernetes-dashboard"
# 查看密钥
kubectl get secret --namespace kube-system | grep "dashboard"


##########
#（可选）开启kubelec proxy
##########
kubectl proxy --address=192.168.1.2 --accept-hosts='^*$' &
#访问
# 虚拟机：
# http://192.168.1.2:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview?namespace=default
# 物理机
# 


##########
# centos启用图形模式
##########
#D:\code-store\Shell\centos-set-default-mode

##########
# centos访问控制面板页面
##########

cat > ${dashboard_version}/kube-dashboard-rbac.yml<<kube-dashboard-rbac-config
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
kubectl create --filename ${dashboard_version}/kube-dashboard-rbac.yml
# kubectl delete --filename ${dashboard_version}/kube-dashboard-rbac.yml
cat > ${dashboard_version}/dashboard-admin.yml<<dashboard-admin-config
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


########
# k8s认证：证书-身份识别
# 为什么要认证--上学时候给心仪的女孩传纸条，传送的过程可能会被别的同学偷看，甚至内容可能会从我喜欢你修改成我不喜欢你了.
########
# 用户账号
# 本地证书-可直接连接apiserver授信
# cat .kube/config
# 服务账号
::<<k8s-manage-service-account
# 查看
kubectl describe pods myapp-deploy-55b78d8548-t4xxx
kubectl explain pods.spec.serviceAccountName
kubectl describe sa admin
kubectl get secrets 
kubectl get sa
kubectl get serviceaccounts
kubectl get serviceaccounts -n default
# 创建
kubectl create serviceaccount mysa --dry-run
kubectl create serviceaccount admin --dry-run
kubectl create serviceaccount default --dry-run
kubectl create serviceaccount dashboard -n default --dry-run
kubectl create clusterrolebinding dashboard-admin -n default --clusterrole=cluster-admin  --serviceaccount=default:dashboard --dry-run
# 删除
#kubectl delete serviceaccount --help
#kubectl delete serviceaccount default --dry-run
#kubectl delete serviceaccount -n kube-system kubernetes-dashboard

cat > pod-sa-demo.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod-sa-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
  serviceAccount: admin #定义,则pod使用自定义的sa账号；不定义，则自动使用default-token-xx
EOF
# 使用
# kubectl apply -f pod-sa-demo.yaml
# 查看
# kubectl describe pods pod-sa-demo
k8s-manage-service-account

########
# k8s授权：rbac-权限检查
########
# D:\code-store\Shell\k8s-manage-service-account

########
# k8s准入控制：补充授权机制-多个插件实现，只在创建 删除 修改 或做代理操作时做补充
########

#### 遇到问题
# 问题：configmaps is forbidden: User "system:serviceaccount:kube-system:kubernetes-dashboard" 
# 解决：
# 参考：https://blog.51cto.com/icenycmh/2122309
::<<delete-err-0001
sed -i 's/kind: RoleBinding/kind: ClusterRoleBinding/g' ${dashboard_version}/${dashboard_local_file}
sed -i 's/name: kubernetes-dashboard-minimal/name: kubernetes-dashboard/g' ${dashboard_version}/${dashboard_local_file}
sed -i 's/name: kubernetes-dashboard-minimal/name: cluster-admin/g' ${dashboard_version}/${dashboard_local_file}

# cat ${dashboard_version}/${dashboard_local_file} | grep "kind: Role"
delete-err-0001

# 问题：services \"https:kubernetes-dashboard:\" is forbidden: User \"system:anonymous\" cannot get resource \"services/proxy\" in API group \"\" in the namespace \"kube-system\""
# 参考：https://www.centos.bz/2018/07/kubernetes%E7%9A%84dashboard%E7%99%BB%E5%BD%95%E6%96%B9%E5%BC%8F/
# 原因：可能是证书问题
# 解决：
# 火狐浏览器Mozilla Firefox怎样导入证书
# https://jingyan.baidu.com/article/4e5b3e191205d291911e2463.html
# Kubernetes dashboard1.8.0 WebUI安装与配置
# https://blog.csdn.net/a632189007/article/details/78840971
::<<delete-err-0002-way2
mkdir certs
kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
kubectl get pods --namespace="kube-system"
kubectl describe pods/kubernetes-dashboard-68798cb565-lwcrb --namespace="kube-system" 
delete-err-0002-way2

# 问题：Unauthorized 
# 参考：


# 问题：
# 参考：
# 解决：
# 

kubectl get serviceaccounts
kubectl get serviceaccount dashboard -n default
kubectl describe serviceaccount dashboard -n default
kubectl describe serviceaccount default -n default

kubectl delete serviceaccount dashboard -n default
kubectl delete clusterrolebinding dashboard-admin -n default

#创建dashboard管理用户
kubectl create serviceaccount dashboard -n default
#绑定用户为集群管理用户
kubectl create clusterrolebinding dashboard-admin -n default --clusterrole=cluster-admin  --serviceaccount=default:dashboard
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
kubectl describe secret -n kube-system dashboard-admin-token


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

# Kubernetes-基于k8s-v1.14.0安装dashboard-1.10.1
# https://blog.csdn.net/Excairun/article/details/88989706
# Kubernetes1.15.1安装 Dashboard 的WEB UI插件
# https://cloud.tencent.com/developer/article/1487532
# kubernetes1.16 安装dashboard UI
# https://www.jianshu.com/p/f7ebd54ed0d1
#
# 跟着官方文档从零搭建K8S
# https://juejin.im/post/5d7fb46d5188253264365dcf#heading-18
#


# 认证dashboad之无密登录
# kubectl proxy --address='0.0.0.0' --port=8888 --accept-hosts='^*$' &
#
# 问题：
# 解决：
::<<centos7-delete-used-port
netstat -nap | grep 8888
kill 38888
centos7-delete-used-port

# 认证dashboad之令牌登录
# 
# 认证dashboad之密码登录
# 认证dashboad之配置登录

# 访问dashboad之NodePort
# 访问dashboad之Ingress
# 访问dashboad之接口代理-API Server（需要导入证书）
# 物理机：https://192.168.1.2:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
# 虚拟机：https://192.168.1.2:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

# 访问dashboad之接口代理-kubectl proxy
# kubectl proxy --address='0.0.0.0' --port=8888 --accept-hosts='^*$'
# 物理机：http://192.168.1.2:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy
# 虚拟机：http://localhost:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy



