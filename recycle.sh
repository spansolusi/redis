#!/bin/bash
host_ip=172.28.200.235
master_port=7000
slave_port=7001
master_service_name=redis-master
slave_service_name=redis-slave
my_master_ip=172.28.200.237
my_master_port=7000
master_auth=SomePassw0rd
master_role=\$(docker exec \$master_service_name redis-cli -h \$host_ip -p \$master_port -a \$master_auth info replication | grep role)
slave_role=\$(docker exec \$slave_service_name redis-cli -h \$host_ip -p \$slave_port -a \$master_auth info replication | grep role)

if [[ \$slave_role == *"master"* ]] && [[ \$master_role == *"master"* ]]
then
  echo "situasi berbahaya!"
  my_master_nmap=\$(nmap -p \$my_master_port \$my_master_ip | grep \$my_master_port'/tcp')
  if [[ \$my_master_nmap == *"open"* ]]; then
    echo "aman untuk lanjut"
    my_master_role=\$(docker exec \$master_service_name redis-cli -h \$my_master_ip -p \$my_master_port -a \$master_auth info replication | grep role)
    if [[ \$my_master_role == *"slave"* ]]; then
      echo "hentikan service redis-slave"
      docker stop \$slave_service_name
      while [[ \$my_master_role == *"slave"* ]]
      do
        echo "tunggu master aktif"
        sleep 5
        my_master_role=\$(docker exec \$master_service_name redis-cli -h \$my_master_ip -p \$my_master_port -a \$master_auth info replication | grep role)
      done
      echo "jalankan kembali service redis-slave"
      docker start \$slave_service_name
    fi
  else
    echo "tidak aman untuk lanjut"
  fi
else
  echo "situasi aman"
fi
EOT
