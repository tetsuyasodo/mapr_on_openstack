mapr_on_openstack
=================

Deploy MapR cluster on OpenStack cloud.

Initially deploying for [hp helion public cloud](https://horizon.hpcloud.com) only.
[hp helion openstack](https://helion.hpwsportal.com/) will be implemented later soon.

Notes
-----
* Only M3 edition cluster is targeted.
* If you use MapR NFS Gateway, you have to register the free M3 license via www.mapr.com.
* You have to edit the "user-data.sh" for fixed-ips in advance to successfully create "/etc/hosts" file in the nodes.
  - We can assign specific fixed-ips by [this](https://community.hpcloud.com/article/creating-instance-specific-fixed-ip), which requires CLI tools
 
Installation
------------
* Login to [hp helion public cloud](https://horizon.hpcloud.com)
* Preparation
  - create your private network (192.168.0.0/24 is assumed for this setup)
  - external dns setting like 8.8.8.8 is needed for the subnet
  - make your SSH key
  - security group: set as you can access (Please make sure Ingress/ALLTCP/same-group is open for cluster forming)
* Launch a new instance from "Project">"Compute">"Instance">"Launch Instance"
  - AZ: any (but all nodes have to belong to the same AZ)
  - instance-name: "mapr-1","mapr-2","mapr-3" resp. (Use the same name as "user-data.sh" script)
  - flavor: above small is favorable
  - instance-count: 1 (create one by one. total 3 nodes will be created)
  - boot-source: image
  - image-name: CentOS 6.3 from public images
  - network: the group you have created
  - key: the key you have created
  - post-creation: paste "user-data.sh" contents
* Floating-IP: after 1st node booted up, attach any one floating-ip to access MapR Console
* You boot 3 nodes like above and you can see a new cluster come up.

Access
------
* You can login to MapR Console via https://<1st-node-floatingip>:8443/
* After apply a new M3 license for the cluster, you can mount and access to NFS Gateway.

`$ mkdir /mapr`  
`$ sudo mount -t nfs -o nolock <1st-node-floatingip>:/mapr /mapr`  
`$ ls /mapr  `  

Limitation
----------
* Now HP Public Cloud does not support heat, so we cannot know the fixed-ips in advance.
* Now we use a ephemeral disk for MapR's storage pool. 3 disks attached from cinder volume are required for more performance.
