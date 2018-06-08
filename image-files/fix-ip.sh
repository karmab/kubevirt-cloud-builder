#!/bin/bash
IP=`hostname -I| cut -f1 -d" "`
sed -i s@https://.*@https://$IP:6443@ .kube/config
