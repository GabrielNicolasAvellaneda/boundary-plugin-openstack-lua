Boundary Openstack Plugin
-----------------------------
Collects metrics from Openstack server.

### Platforms
- Linux

### Prerequisites
- Python 2.6 or later
- Openstack Juno+
- Openstack Ceilometer > 0
- Python ceilometerclient module (this is automatically installed if ceilometer is installed)

### Description
This plugin grabs metrics from the openstack node where it is started and parses the data to be able to integrate into 
boundary. To be able to start ceilometer should be well configured on the machine and credentials needs to be created. 
Additional metrics can be added from the ceilometer by editing the plugin.py and adding or replacing different mapping tuple objects.
