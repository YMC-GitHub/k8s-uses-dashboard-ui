#!/bin/sh

#### 它是什么

#### 为什么要

#### 如何进行
#面板目录
DASHBOARD_DIR=dashboard #存放 dashboard 面板文件的目录
#面板版本
DASHBOARD_VERSION=v1.10.1
#命名空间
#DASHBOARD_NS=kube-system
DASHBOARD_NS=kubernetes-dashboard
#配置文件操作
CONFIG_ACTION="下载|修改|使用|查看" #"下载|备份|还原|修改|使用|删除|查看"
CONFIG_ACTION_EDIT="查看|"         #"修改|还原"
SET_IMAGE_SOURCE_ACTION="修改"     #"修改|还原"
#访问面板方式
CONNECT_TO_DASHBOARD_TYPE="NODEPORT" #"NODEPORT"

#节点地址
MASTER_IP=192.168.2.3
#节点端口
NODE_PORT=30088
#运行记录
RUN_TIME_LOG=dashboard-manage.log

# 建相关目录
mkdir -p $DASHBOARD_DIR
mkdir -p ${DASHBOARD_DIR}/${DASHBOARD_VERSION}

# 下载配置文件
function config_file_download() {
  DASHBOARD_LOCAL_FILE=kubernetes-dashboard.yaml
  WORK_FILE_NAME=${DASHBOARD_DIR}/${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE}
  case $DASHBOARD_VERSION in
  'v1.10.1' | 'v1.8.3')
    echo '下配置文件-地址01' >>$RUN_TIME_LOG
    curl -o $WORK_FILE_NAME https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/src/deploy/recommended/kubernetes-dashboard.yaml
    ;;
  'v2.0.0-beta1' | 'v2.0.0-beta2')
    echo '下配置文件-地址01' >>$RUN_TIME_LOG
    curl -o $WORK_FILE_NAME https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
    ;;
  *)
    echo '修下配置文件-其他03' >>$RUN_TIME_LOG
    ;;
  esac
}
if [[ "$CONFIG_ACTION" =~ '下载' ]]; then
  echo "下载配置文件.." >>$RUN_TIME_LOG
  config_file_download
fi

# 备份配置文件
if [[ "$CONFIG_ACTION" =~ '备份' ]]; then
  echo "备份配置文件.." >>$RUN_TIME_LOG
  cp $WORK_FILE_NAME ${WORK_FILE_NAME}.backup
fi
# 还原备份文件
if [[ "$CONFIG_ACTION" =~ '还原' ]]; then
  echo "还原配置文件.." >>$RUN_TIME_LOG
  cp --force ${WORK_FILE_NAME}.backup $WORK_FILE_NAME
fi

# 修改配置文件
#2 管理镜像来源
function set_image_source_1_10_1() {
  if [[ "$SET_IMAGE_SOURCE_ACTION" =~ '查看' ]]; then
    echo "查看所需镜像.." >>$RUN_TIME_LOG
    cat --number $WORK_FILE_NAME | grep "image"
  fi
  if [[ "$SET_IMAGE_SOURCE_ACTION" =~ '修改' ]]; then
    echo "使用国内镜像.." >>$RUN_TIME_LOG
    sed -i 's@image: k8s.gcr.io/@image: registry.cn-hangzhou.aliyuncs.com/google_containers/@g' $WORK_FILE_NAME
  fi
  if [[ "$SET_IMAGE_SOURCE_ACTION" =~ '还原' ]]; then
    echo "使用国外镜像.." >>$RUN_TIME_LOG
    sed -i 's@image: registry.cn-hangzhou.aliyuncs.com/google_containers/@image: k8s.gcr.io/@g' $WORK_FILE_NAME
  fi
}
function config_file_update() {
  case $DASHBOARD_VERSION in
  'v1.10.1')
    echo "管理镜像来源.." >>$RUN_TIME_LOG
    set_image_source_1_10_1
    ;;
  esac
}
if [[ "$CONFIG_ACTION" =~ '修改' ]]; then
  echo "修改配置文件.." >>$RUN_TIME_LOG
  config_file_update
fi

# NodePort方式访问dashboard
#2 设置NodePort方式访问dashboard
function set_nodeport_on_1_10_1() {

  if [[ "$CONNECT_TO_DASHBOARD_TYPE" =~ 'NODEPORT' ]]; then
    echo '访问dashboard方式-NODEPORT' >>$RUN_TIME_LOG
    # 设置
    # cat --number $WORK_FILE_NAME
    # cat --number $WORK_FILE_NAME | grep -C 10 "157"
    sed -i '157a type: NodePort' $WORK_FILE_NAME
    sed -i '158s/^ *//g' $WORK_FILE_NAME
    sed -i "158s/^/  /" $WORK_FILE_NAME
    #or use as next line
    #kubectl --namespace=kube-system edit service kubernetes-dashboard
    #2 插入--161行后插入一行nodePort: 30088
    sed -i "161a nodePort: $NODE_PORT" $WORK_FILE_NAME
    #note-ymc:行首删除空格
    sed -i '162s/^ *//g' $WORK_FILE_NAME
    #note-ymc:行首添加空格
    SPACE_LENGTH=$(printf "%6s" ' ')
    sed -i "162s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
  else
    # 删除
    sed -i '158d' $WORK_FILE_NAME
    sed -i '162d' $WORK_FILE_NAME
  fi
}
function set_nodeport_on_2_0_0() {
  WORK_FILE_LINE=39
  sed -i "${WORK_FILE_LINE}a type: NodePort" $WORK_FILE_NAME
  WORK_FILE_LINE=$(expr $WORK_FILE_LINE + 1)
  sed -i "${WORK_FILE_LINE}s/^ *//g" $WORK_FILE_NAME
  SPACE_LENGTH=$(printf "%2s" ' ')
  sed -i "${WORK_FILE_LINE}s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
  WORK_FILE_LINE=42
  sed -i "${WORK_FILE_LINE}a nodePort: 30001" $WORK_FILE_NAME
  WORK_FILE_LINE=$(expr $WORK_FILE_LINE + 1)
  sed -i "${WORK_FILE_LINE}s/^ *//g" $WORK_FILE_NAME
  SPACE_LENGTH=$(printf "%6s" ' ')
  sed -i "${WORK_FILE_LINE}s/^/$SPACE_LENGTH/" $WORK_FILE_NAME
  sed -n "39,45p" $WORK_FILE_NAME
}
function connect_to_dashboard_as_nodeport() {
  #DASHBOARD_VERSION=v1.10.1
  case $DASHBOARD_VERSION in
  'v1.10.1' | set)
    echo $DASHBOARD_VERSION
    set_nodeport_on_1_10_1
    ;;
  'v2.0.0-beta4' | del)
    echo $DASHBOARD_VERSION
    set_nodeport_on_2_0_0
    ;;
  *)
    echo '修复证书问题-行动之其他'
    ;;
  esac
}
case $DASHBOARD_VERSION in
'v1.10.1' | 'v1.8.3')
  echo '访问dashboard方式-编号01' >>$RUN_TIME_LOG
  set_nodeport_on_1_10_1 #NodePort
  ;;
'v2.0.0-beta1' | 'v2.0.0-beta2')
  echo '访问dashboard方式-编号02' >>$RUN_TIME_LOG
  WORK_FILE_LINE=188
  ;;
*)
  echo '访问dashboard方式-编号03' >>$RUN_TIME_LOG
  ;;
esac

# 使用配置文件
if [[ "$CONFIG_ACTION" =~ '使用' ]]; then
  echo "应用配置文件.." >>$RUN_TIME_LOG
  kubectl delete ns $DASHBOARD_NS
  kubectl apply --filename $WORK_FILE_NAME
fi
# 删除配置文件
if [[ "$CONFIG_ACTION" =~ '删除' ]]; then
  echo "删除配置文件.." >>$RUN_TIME_LOG
  kubectl delete --filename $WORK_FILE_NAME
fi
# 查看配置文件
if [[ "$CONFIG_ACTION" =~ '查看' ]]; then
  echo "查看配置文件.." >>$RUN_TIME_LOG
  cat --number $WORK_FILE_NAME
fi
#2 查看命名空间
#cat --number $WORK_FILE_NAME | grep "namespace"
#2 查看接口版本
#cat --number $WORK_FILE_NAME | grep "kind:\|apiVersion:"
#2 查看证书名字
#cat --number $WORK_FILE_NAME | grep "kubernetes-dashboard-certs"

# 查看部署状态
# 查看所需镜像
cat --number $WORK_FILE_NAME | grep "image"
# 查看已下镜像
docker image ls | grep "dashboard\|kubernetesui"
# 查看单元状态
kubectl get pods --all-namespaces
kubectl get pods --all-namespaces | grep $DASHBOARD_NS
# 在何节点运行
kubectl get pods --namespace=$DASHBOARD_NS -o wide
# 在何端口运行
kubectl get services --all-namespaces | grep $DASHBOARD_NS

# 访问控制面板
if [[ "$CONNECT_TO_DASHBOARD_TYPE" =~ 'NODEPORT' ]]; then
  echo https://${MASTER_IP}:${NODE_PORT}
fi

# 登录控制面板
:: <<EOF
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
SECRET_TOKEN_VALUE=$(kubectl describe secret $SECRET_TOKEN_NAME -n $SERVICE_ACOUNT_NS | grep "token:" | sed "s/token:      //g")
echo $SECRET_TOKEN_NAME
echo $SECRET_TOKEN_VALUE

# 认证dashboad之配置文件
CLUSTER_NAME=kubernetes
SERVICE_ACOUNT_NAME=dashboard-admin
MASTER_SERVER_ADDR=${MASTER_IP}:${NODE_PORT}
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
EOF

#### 成功案例
:: <<EOF
docker18.09.9-k8s1.15.3-calcio3.8.4-dashboad1.10.1NodePort
EOF
#### 参考文献
:: <<EOF
kubernetes1.16 安装dashboard UI
https://www.jianshu.com/p/f7ebd54ed0d1
EOF
