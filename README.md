# Boundary Openstack Plugin

This plugin grabs metrics from the openstack node where it is started and parses the data to be able to integrate into boundary. To be able to start, ceilometer should be well configured on the machine and credentials needs to be created.
Additional metrics can be added from the ceilometer by editing the plugin.py and adding or replacing different mapping tuple objects.

## Prerequisites

### Supported OS

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |         |         |      |

#### Openstack
- Version Juno+
- Ceilometer > 0

#### Boundary Meter Versions V4.0 Or Greater

To get the new meter:

    curl -fsS \
        -d "{\"token\":\"<your API token here>\"}" \
        -H "Content-Type: application/json" \
        "https://meter.boundary.com/setup_meter" > setup_meter.sh
    chmod +x setup_meter.sh
    ./setup_meter.sh

#### For Boundary Meter less than V4.0

|  Runtime | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |         |    +   |      |

- [How to install Python?](https://help.boundary.com/hc/articles/202270132)
- Python libraries: ceilometerclient (this is automatically installed if ceilometer is installed)

### Plugin Setup

None

### Plugin Configuration Fields

#### For All Versions

|Field Name      |Description                                                |
|:---------------|:----------------------------------------------------------|
|service_tenant  |The tenant to get into the service panel for OpenStack     |
|service_endpoint|The endpoint to get into the service panel for OpenStack   |
|service_user    |The user to get into the service panel for OpenStack       |
|service_timeout |The timeout to get into the service panel for OpenStack    |
|service_password|The password to get into the service panel for OpenStack   |

### Metrics Collected

#### For All Versions

|Metric Name             |Description                                                                |
|:-----------------------|:--------------------------------------------------------------------------|
|OS_CPUUTIL_AVG          |Average openstack CPU utilization on the running node                      |
|OS_CPUUTIL_SUM          |Summary of total openstack CPU utilization                                 |
|OS_CPUUTIL_MIN          |The minimum openstack CPU utilization by VMs running on the node           |
|OS_CPUUTIL_MAX          |The maximum openstack CPU utilization by VMs running on the node           |
|OS_CPU_AVG              |Average CPU time used by the openstack VMs                                 |
|OS_CPU_SUM              |Total CPU time used by the openstack VMs                                   |
|OS_INSTANCE_SUM         |Summary of running instances in openstack                                  |
|OS_INSTANCE_MAX         |The maximum number of instances started                                    |
|OS_MEMORY_SUM           |The summary of allocated memory by all VMs on the node                     |
|OS_MEMORY_AVG           |The average allocated memory by all VMs on the node                        |
|OS_MEMORY_USAGE_SUM     |Volume of RAM used by the instance from the amount of its allocated memory |
|OS_MEMORY_USAGE_SUM     |Volume of RAM used by the instance from the amount of its allocated memory |
|OS_VOLUME_SUM           |Summary of created volumes                                                 |
|OS_VOLUME_AVG           |Average of created volumes by the VMs running on the node                  |
|OS_IMAGE_SIZE_SUM       |The total amount of space used by the created images                       |
|OS_IMAGE_SIZE_AVG       |Average amount of space used by the created images                         |
|OS_DISK_READ_RATE_SUM   |The total amount of disk read rate on all VMs running on the node          |
|OS_DISK_READ_RATE_AVG   |Average amount of disk read rate on all VMs running on the node            |
|OS_DISK_WRITE_RATE_SUM  |The total amount of disk write rate on all VMs running on the node         |
|OS_DISK_WRITE_RATE_AVG  |Average amount of disk write rate on all VMs running on the node           |
|OS_NETWORK_IN_BYTES_SUM |The total amount of network incoming bytes to all VMs running on the node  |
|OS_NETWORK_IN_BYTES_AVG |Average amount of network incoming bytes to all VMs running on the node    |
|OS_NETWORK_OUT_BYTES_SUM|The total amount of network outgoing bytes from all VMs running on the node|
|OS_NETWORK_OUT_BYTES_AVG|Average amount of network outgoing bytes from all VMs running on the node  |

#### References

http://docs.openstack.org/admin-guide-cloud/content/section_telemetry-compute-metrics.html
http://developer.openstack.org/api-ref-telemetry-v2.html