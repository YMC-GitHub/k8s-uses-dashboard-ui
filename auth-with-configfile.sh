# 生成相应服务账户的的kubeconfig文件
# 该配置文件可以用来登录dashboard

# 准备
# 先创建相关账户、角色、集群、并关联
# D:\code-store\Shell\k8s-manage-service-account\02.sh

# 进行
CLUSTER_NAME=kubernetes
SERVICE_ACOUNT_NAME=dashboard-admin
MASTER_SERVER_ADDR=192.168.1.2:30088
USER_CONFIG_NAME=/root/.kube/${SERVICE_ACOUNT_NAME}.conf
#USER_CONFIG_NAME=/root/.kube/config
#USER_CONFIG_NAME=/root/dashbord-admin.conf
#创建（更新）
kubectl config set-cluster $CLUSTER_NAME --server=$MASTER_SERVER_ADDR --kubeconfig=$USER_CONFIG_NAME
kubectl config set-credentials $SERVICE_ACOUNT_NAME --token=$SECRET_TOKEN_VALUE --kubeconfig=$USER_CONFIG_NAME
kubectl config set-context ${SERVICE_ACOUNT_NAME}@${CLUSTER_NAME} --cluster=$CLUSTER_NAME --user=$SERVICE_ACOUNT_NAME --kubeconfig=$USER_CONFIG_NAME
kubectl config use-context ${SERVICE_ACOUNT_NAME}@${CLUSTER_NAME} --kubeconfig=$USER_CONFIG_NAME
# 查看
kubectl config view
cat /root/.kube/config
cat $USER_CONFIG_NAME
# 删除
rm -rf $USER_CONFIG_NAME

# 拷贝
::<<copy-to-physical-machine
#2 拷贝到物理机
# 物理机执行
SERVICE_ACOUNT_NAME=dashboard-admin
USER_CONFIG_NAME=/root/.kube/${SERVICE_ACOUNT_NAME}.conf
scp -i ~/.ssh/google-clound-ssr root@192.168.1.2:$USER_CONFIG_NAME $HOME/.kube/
# 登录
#2 物理机登录 该地址MASTER_SERVER_ADDR，选择配置文件
copy-to-physical-machine

#### 参考文献
# 
# kubernetes dashboard 1.8 访问认证 ——config文件访问
# https://blog.csdn.net/feifei3851/article/details/82839342
# Kubernetes-dashboard安装、配置令牌和kubeconfig登录
# https://blog.csdn.net/bbwangj/article/details/82790026
# 
# https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/