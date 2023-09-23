
<table align="center"><tr><td align="center" width="9999">
<img src="icons/maas-logo-cropped.png" align="center" width="150" alt="MaaS icon">

# MaasAutomation

</td></tr></table>

MAAS (Metal as a Service) Robot automation project. A repository that enables the provisioning of Virtual Machines under KVM hypervisor using MAAS framework.

## Dependencies

The tasks defined in this repository sshpass utility before running. Install sshpass in a Debian OS family system with the following commands:
```sh
sudo apt update -y
sudo apt upgrade -y
sudo apt install sshpass
```

## KVM Hypervisor Integration
KVM hypervisor is leveraged for provisioning KVM VMs (domains) as managed machines in MAAS server. In order to be able to provision resources in KVM, you need a
user created in KVM Host belonging to libvirt group. Otherwise, you will not be able to address libvirt commands to selected KVM Host.


## Python Requirements

The Python requirements are defined inside `pip_requirements.txt` file. Create and activate a python virtual environment before installing the Python Requirements:
```sh
python3 -m venv maasautomationVenv
source maasautomationVenv/bin/activate
```
You can confirm you’ve successfully activated the virtual environment by checking the location of your Python interpreter:
```sh
which python3
```
The returned Python interpreter should point to the virtual environment interpreter.
Then you can install Python requirements running the command below:
```sh
pip3 install -r pip_requirements.txt
```

## Configuration
MAAS settings like default commissioning OS, the hardware setup of deployed machines, KVM hypervisor etc. are all defined in `resources/maaslabsconfiguration.yml` configuration
file. The top level YAML parameters of this configuration file represent the various MAAS server we can incorporate in our project. Each such server consist of the following attributes:
``` yaml
# maaslabsconfiguration.yml
maas-spiros-desktop:
  maas_url:
  maas_username:
  maas_password:
  default_commission_ubuntu_os:
  commission_timeout:
  default_deployment_os:
  deploy_timeout:
  kvm_hosts:
  machines:
```

## Robot Framework Global Variables
A number of Robot variables need to be set and given as input to automated tasks using the --variable command line option. These variables define parameters like the MAAS server,
the machine or machines where various actions are executed on, the KVM hypervisor selected, the MAAS machine tags etc. You can define any Robot variable as global using this flag
but there is a set of mandatory variables per task that if not set will lead to task execution failure.
List of mandatory Robot variables:
- MAAS_SERVER: The name of the configured MAAS server in `resources/maaslabsconfiguration.yml`. This is the top level - and single server - parameter in our configuration file
(`maas-spiros-desktop`).
- KVM_HOST: The name of the KVM hypervisor in `resources/maaslabsconfiguration.yml` (`kvm_hosts` parameter).
- MAAS_MACHINE: The name of the enlisted MAAS machine (`machines` parameter).
- MAAS_TAG: The MAAS tag added to machines.
- MAAS_MACHINE_HOSTNAME: The hostname of the MAAS machine after commissioning.


## Execution

Always set `PYTHONPATH` to include projects libraries directory. Refer to the robot execution examples below:
```
export PYTHONPATH=libraries/

robot --loglevel TRACE:DEBUG --outputdir logs --timestampoutputs \
--variable MAAS_SERVER:maas-spiros-desktop \
--variable KVM_HOST:kvm.hypervisor.spiros-desktop \
--variable MAAS_MACHINE:maas-machine-1 \
--test Create_KVM_Instance tasks

robot --loglevel TRACE:DEBUG --outputdir logs --timestampoutputs \
--variable MAAS_SERVER:maas-spiros-desktop \
--variable MAAS_MACHINE:maas-machine-1 \
--variable MAAS_MACHINE_HOSTNAME:maas-machine-1 \
--test tasks.maas_commission_deploy.Commission_MAAS_Machine tasks

robot --loglevel TRACE:DEBUG --outputdir logs --timestampoutputs \
--variable MAAS_SERVER:maas-spiros-desktop \
--variable MAAS_MACHINE:maas-machine-1 \
--test tasks.maas_commission_deploy.Deploy_MAAS_Machine tasks

robot --loglevel TRACE:DEBUG --outputdir logs --timestampoutputs --variable MAAS_SERVER:maas-spiros-desktop --test List_MAAS_Machines tasks/maas_commission_deploy.robot
```
