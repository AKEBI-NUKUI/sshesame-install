#!/bin/bash
# 读取用户输入的端口号
read -p "请输入你想要更改的端口号：" port
# 检查端口号是否合法
if [[ $port -gt 1 && $port -lt 65536 ]]; then
  # 用sed命令替换/etc/ssh/sshd_config中的#Port 22或者Port 22为Port $port
  sudo sed -i "s/^#Port 22$/Port $port/;s/^Port 22$/Port $port/" /etc/ssh/sshd_config
  # 在当前目录新建一个sshesame的文件夹
  mkdir sshesame
  # 下载sshesame-linux-amd64并改名为sshesame放入sshesame文件夹
  wget -O /root/sshesame/sshesame https://github.com/jaksi/sshesame/releases/download/v0.0.27/sshesame-linux-amd64
  # 下载sshesame.yaml并改名为config.yaml再放入sshesame文件夹
  wget -O /root/sshesame/config.yaml https://github.com/jaksi/sshesame/releases/download/v0.0.27/sshesame.yaml
  sed -i 's/listen_address: 127.0.0.1:2022/listen_address: 0.0.0.0:22/' /root/sshesame/config.yaml
  # 写入启动脚本
  echo "#!/bin/sh" > /root/sshesame/start.sh
  echo "nohup ./sshesame -config config.yaml >> /root/sshesame/sshesame.log 2>&1 &" >> /root/sshesame/start.sh
  chmod -R +x /root/sshesame
  echo "[Unit]" > /lib/systemd/system/sshesame.service
  echo "Description=sshesame" > /lib/systemd/system/sshesame.service
  echo "After=network.target" >> /lib/systemd/system/sshesame.service
  echo "[Service]" >> /lib/systemd/system/sshesame.service
  echo "Type=forking " >> /lib/systemd/system/sshesame.service
  echo "User=root" >> /lib/systemd/system/sshesame.service
  echo "Group=root" >> /lib/systemd/system/sshesame.service
  echo "WorkingDirectory=/root/sshesame" >> /lib/systemd/system/sshesame.service
  echo "KillMode=control-group" >> /lib/systemd/system/sshesame.service
  echo "Restart=no" >> /lib/systemd/system/sshesame.service
  echo "ExecStart=/root/sshesame/start.sh" >> /lib/systemd/system/sshesame.service
  echo "[Install]" >> /lib/systemd/system/sshesame.service
  echo "WantedBy=multi-user.target" >> /lib/systemd/system/sshesame.service
  systemctl restart sshd
  systemctl enable sshesame
  systemctl start sshesame
else
  # 端口号不合法，提示用户重新输入
  echo "端口号不合法，请输入一个1到65535之间的整数。"
fi
