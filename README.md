mapr_on_openstack
=================

Deploy MapR cluster on OpenStack cloud.

Initially deploying for [hp helion public cloud](https://horizon.hpcloud.com) only.
[hp helion openstack](https://helion.hpwsportal.com/) will be implemented later soon.

Notes
-----
* Only M3 edition cluster is targeted.
* If you use NFS Gateway, you have to register the free M3 license via www.mapr.com.
* You have to know the fixed-ips to create "/etc/hosts" file for all of the nodes before running.
 
Installation
------------
* Login to [hp helion public cloud](https://horizon.hpcloud.com)
* Prepare your private network (192.168.0.0/24 is assumed for this setup)
* Launch a new instance from "Project">"Compute">"Instance">"Launch Instance"
** AZ: any (all nodes have to belong to the same AZ)
