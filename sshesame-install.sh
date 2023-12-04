#!/bin/bash
# 定义sshesame的目录
SSHESAMEDIR=/root/sshesame
# 定义sshesame的下载链接
SSHESAMEURL=https://github.com/jaksi/sshesame/releases/download/v0.0.27/sshesame-linux-amd64
# 定义sshesame的配置文件的下载链接
SSHESAMECFG=https://github.com/jaksi/sshesame/releases/download/v0.0.27/sshesame.yaml
# 定义sshesame的服务文件的路径
SSHESAMESVC=/lib/systemd/system/sshesame.service

# 定义一个函数来部署sshesame
deploy_sshesame() {
  # 在当前目录新建一个sshesame的文件夹
  mkdir sshesame
  # 下载sshesame-linux-amd64并改名为sshesame放入sshesame文件夹
  wget -O $SSHESAMEDIR/sshesame $SSHESAMEURL
  # 下载sshesame.yaml并改名为config.yaml再放入sshesame文件夹
  wget -O $SSHESAMEDIR/config.yaml $SSHESAMECFG
  # 修改配置文件中的监听地址
  sed -i 's/listen_address: 127.0.0.1:2022/listen_address: 0.0.0.0:22/' $SSHESAMEDIR/config.yaml
  # 写入启动脚本
  echo "#!/bin/sh" > $SSHESAMEDIR/start.sh
  echo "nohup ./sshesame -config config.yaml >> $SSHESAMEDIR/sshesame.log 2>&1 &" >> $SSHESAMEDIR/start.sh
  chmod -R +x $SSHESAMEDIR
  # 写入服务文件
  echo "[Unit]" > $SSHESAMESVC
  echo "Description=sshesame" >> $SSHESAMESVC
  echo "After=network.target" >> $SSHESAMESVC
  echo "[Service]" >> $SSHESAMESVC
  echo "Type=forking " >> $SSHESAMESVC
  echo "User=root" >> $SSHESAMESVC
  echo "Group=root" >> $SSHESAMESVC
  echo "WorkingDirectory=$SSHESAMEDIR" >> $SSHESAMESVC
  echo "KillMode=control-group" >> $SSHESAMESVC
  echo "Restart=no" >> $SSHESAMESVC
  echo "ExecStart=$SSHESAMEDIR/start.sh" >> $SSHESAMESVC
  echo "[Install]" >> $SSHESAMESVC
  echo "WantedBy=multi-user.target" >> $SSHESAMESVC
  # 启动sshesame服务
  systemctl enable sshesame
  systemctl start sshesame
}

# 检查/etc/ssh/sshd_config中是否有#Port 22或Port 22
grep -qE "^#?Port 22$" /etc/ssh/sshd_config
# 如果没有，直接开始部署sshesame
if [ $? -ne 0 ]; then
  echo "在/etc/ssh/sshd_config中没有找到#Port 22或Port 22，无需更改端口号。"
  # 调用部署sshesame的函数
  deploy_sshesame
  exit 0
fi

# 读取用户输入的端口号
read -p "请输入你想要更改的端口号：" port
# 检查端口号是否合法
if [[ $port -gt 1 && $port -lt 65536 ]]; then
  # 用sed命令替换/etc/ssh/sshd_config中的#Port 22或者Port 22为Port $port
  sudo sed -i "s/^#Port 22$/Port $port/;s/^Port 22$/Port $port/" /etc/ssh/sshd_config
  # 调用部署sshesame的函数
  deploy_sshesame
  # 重启sshd服务
  systemctl restart sshd
else
  # 端口号不合法，提示用户重新输入
  echo "端口号不合法，请输入一个1到65535之间的整数。"
fi
