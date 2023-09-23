
import maas.client
from maas.client.enum import NodeStatus, InterfaceType, LinkMode
from maas.client.viscera.interfaces import InterfaceType
from robot.api.deco import library, keyword
from typing import List
import xmltodict, json



@library(scope='GLOBAL', version='0.1',auto_keywords=False)
class MaasController(object):
    """ Class for controlling MAAS Server. """


    def __init__(self, maas_url, username, password):
        """ MaasManager constructor method: Instantiate MAAS Client. """
        self.maas_url = maas_url
        self.username = username
        self.password = password
        self.client = maas.client.login(url=self.maas_url, username=self.username, password=self.password)


    @keyword('Get Machines')
    def get_machines(self):
        """ Get list of all enlisted MAAS machines. """
        return self.client.machines.list()._items


    @keyword('Get Machine Names')
    def get_machine_names(self):
        """ Get list of all enlisted MAAS machine names. """
        machines = self.client.machines.list()._items
        return [machine.hostname for machine in machines]


    @keyword('Get Machine HW Details', types={'machine_system_id': str})
    def get_machine_details(self, machine_system_id):
        """ Get MAAS machine hardware details. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine_details = machine.get_details()
        details = machine_details['lshw'].decode('utf8').replace("'", '"')
        details_ordered_dict = xmltodict.parse(details)
        return  json.loads(json.dumps(details_ordered_dict))


    @keyword('Get Machine By Hostname', types={'hostname': str})
    def get_machine(self, hostname):
        """ Get MAAS machine given its hostname. """
        machines = self.client.machines.list()._items
        try:
            machine = [machine for machine in machines if machine.hostname==hostname][0]
        except IndexError as error:
            raise Exception(f'Machine with hostname {hostname} not found.')
        else: 
            return machine


    @keyword('Get Machine By System ID', types={'machine_system_id': str})
    def get_machine_by_id(self, machine_system_id):
        """ Get MAAS machine given its system_id. """
        machines = self.client.machines.list()._items
        try:
            machine = [machine for machine in machines if machine.system_id==machine_system_id][0]
        except IndexError as error:
            raise Exception(f'Machine with system ID {machine_system_id} not found.')
        else: 
            return machine


    @keyword('Get Machine Total Storage Size', types={'hostname': str})
    def get_machine_storage_size(self, hostname):
        """ Get MAAS machine total storage size. """
        machine = self.get_machine(hostname)
        storage = []
        for block_device in machine.block_devices._items:
            storage.append(float(block_device.used_size))
        return '{0:.2f}'.format(sum(storage) / float(1024 ** 3))


    @keyword('Get Machines By Tag', types={'tag': str})
    def get_machines_by_tag(self, tag):
        """ Get list of MAAS machines given a tag. """
        machines = []
        for machine in self.client.machines.list()._items:
            if tag in [machine_tag.name for machine_tag in machine.tags]:
                machines.append(machine)
        return machines


    @keyword('Get Machines By Status', types={'status': str})
    def get_machines_by_status(self, status):
        """ Get list of MAAS machines given their status. """
        if status not in list(NodeStatus.__members__.keys()):
            raise ValueError(f'Not accepted Machine state provided,'
                             f'possible machine status: {list(NodeStatus.__members__.keys())}')
        machines = self.client.machines.list()._items
        return [machine for machine in machines if machine.status.name==status]


    @keyword('Lock Machine', types={'machine_system_id': str})
    def lock_machine(self, machine_system_id):
        """ Lock MAAS machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.lock()


    @keyword('Release Machine', types={'machine_system_id': str, 'wait_release_complete': bool})
    def release_machine(self, machine_system_id, wait_release_complete=False):
        """ Release MAAS machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.release(wait=wait_release_complete)


    @keyword('Delete Machine', types={'machine_system_id': str})
    def delete_machine(self, machine_system_id):
        """ Delete MAAS machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.delete()


    @keyword('Power Off Machine', types={'machine_system_id': str})
    def power_off(self, machine_system_id):
        """ Power-off machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.power_off()


    @keyword('Power On Machine', types={'machine_system_id': str})
    def power_on(self, machine_system_id):
        """ Power-on machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.power_on()


    @keyword('Get Ready Machines')
    def get_ready_machines(self):
        """ Get list of machines in READY STATUS """
        machines = self.client.machines.list()._items
        return [machine for machine in machines if machine.status.name=="READY"]


    @keyword('Get Powered Off Deployed Machines')
    def get_powered_off_deployed_machines(self):
        """ Get list of all powered-off machines. """
        machines = self.client.machines.list()._items
        return [machine for machine in machines if machine.status.name=="DEPLOYED" and machine.power_state.name=="OFF"]


    @keyword('Get Powered On Deployed Machines')
    def get_powered_on_deployed_machines(self):
        """ Get list of all powered-on machines. """
        machines = self.client.machines.list()._items
        return [machine for machine in machines if machine.status.name=="DEPLOYED" and machine.power_state.name=="ON"]


    @keyword('Get Powered On Deployed Machines by Tag', types={'tag': str})
    def get_powered_on_deployed_machines_by_tag(self, tag):
        """ Get list of all powered-on machines by tag. """
        tagged_machines = self.get_machines_by_tag(tag)
        return [machine for machine in tagged_machines if machine.status.name=="DEPLOYED" and machine.power_state.name=="ON"]


    @keyword('Get Powered Off Deployed Machines by Tag', types={'tag': str})
    def get_powered_off_deployed_machines_by_tag(self, tag):
        """ Get list of all powered-off machines by tag. """
        tagged_machines = self.get_machines_by_tag(tag)
        return [machine for machine in tagged_machines if machine.status.name=="DEPLOYED" and machine.power_state.name=="OFF"]


    @keyword('Set Machine Hostname', types={'machine_system_id': str, 'hostname': str})
    def set_machine_hostname(self, machine_system_id, hostname):
        """ Set machine's hostname. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.hostname=hostname
        machine.save()


    @keyword('Commission Machine', types={'machine_system_id': str, 'enable_ssh': bool, 'skip_networking': bool, 'wait_commission_complete': bool})
    def commission_machine(self, machine_system_id, enable_ssh=True, skip_networking=True, wait_commission_complete=False):
        """ Commission machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.commission(enable_ssh=enable_ssh, skip_networking=skip_networking, wait=wait_commission_complete)


    @keyword('Acquire Machine', types={'machine_hostname': str})
    def allocate_machine(self, machine_hostname):
        """ Acquire machine. """
        machine = self.client.machines.allocate(hostname=machine_hostname)


    @keyword('Deploy Machine', types={'machine_system_id': str, 'distro_series':str, 'hwe_kernel':str, 'wait_deploy_complete': bool})
    def deploy_machine(self, machine_system_id, distro_series='focal', hwe_kernel='ga-20.04', wait_deploy_complete=False):
        """ Deploy a MAAS commissioned machine. """
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.deploy(wait=wait_deploy_complete)


    @keyword('Get Fabric', types={'fabric_name': str})
    def get_fabric(self, fabric_name):
        """ Get MAAS fabic given a fabric name. """
        fabrics = self.client.fabrics.list()._items
        fabric = [fabric for fabric in fabrics if fabric.name==fabric_name][0]
        return self.client.fabrics.get(id=fabric.id)


    @keyword('Get Fabrics')
    def get_fabrics(self):
        """ Get all MAAS fabrics """
        return self.client.fabrics.list()._items


    @keyword('Get Fabric Names')
    def get_fabric_names(self):
        """ Get all MAAS fabric names. """
        return [fabric.name for fabric in self.client.fabrics.list()._items]


    @keyword('Get Fabric VLANs', types={'fabric_name': str})
    def get_fabric_vlans(self, fabric_name):
        """ Get all VLANs belonging to a specific MAAS Fabric. """
        return [vlan for vlan in self.get_fabric(fabric_name).vlans._items]


    @keyword('Get Fabric VLAN Names', types={'fabric_name': str})
    def get_fabric_vlan_names(self, fabric_name):
        """ Get VLAN names belonging to a specific MAAS Fabric. """
        return [{'name':vlan.name, 'id':vlan.id, 'dhcp':vlan.dhcp_on} for vlan in self.get_fabric(fabric_name).vlans._items]


    @keyword('Get VLANs')
    def get_vlans(self):
        """ Get list of VLANs. """
        fabrics = self.get_fabrics()
        return [vlan for fabric in fabrics for vlan in fabric.vlans._items]


    @keyword('Get VLAN Subnets', types={'vlan_id': int})
    def get_vlan_subnets(self, vlan_id):
        """ Get VLAN subnets. """
        return [subnet for subnet in self.client.subnets.list()._items if subnet.vlan.id==vlan_id]


    @keyword('Get VLAN Subnets CIDRs', types={'vlan_id': int})
    def get_vlan_subnets_cidrs(self, vlan_id):
        """ Get VLAN subnets CIDRs """
        return [subnet.cidr for subnet in self.client.subnets.list()._items if subnet.vlan.id==vlan_id]


    @keyword('Get Machine Events', types={'hostname': str, 'events_count': int})
    def get_events(self, hostname, events_count=100):
        """ Get last Machine event entries. """
        events = self.client.events.query(hostnames={hostname}, limit=events_count)._items
        events_output = [ ]
        for event in events:
            events_output.append({'id': event.event_id,'type': event.event_type, 'description': event.description, 'created': event.created.ctime()})
        return events_output


    @keyword('Create Tag', types={'tag_name': str, 'tag_description': str})
    def create_tag(self, tag_name, tag_description):
        """ Create a machine tag. """
        self.client.tags.create(name=tag_name, comment=tag_description)


    @keyword('Get Tag', types={'tag_name': str})
    def get_tag(self, tag_name):
        """ Get a specified machine tag. """
        return self.client.tags.get(name=tag_name)


    @keyword('Delete Tag', types={'tag_name': str})
    def delete(self, tag_name):
        """ Delete a specified machine tag. """
        tag = self.get_tag(tag_name)
        tag.delete()

    @keyword('Get Tag Names')
    def get_tag_names(self):
        """ Get all configured tag names. """
        tags = self.client.tags.list()._items
        return [tag.name for tag in tags]


    @keyword('Add Tag To Machine', types={'machine_system_id': str, 'tag_name': str})
    def add_tag_to_machine(self, machine_system_id, tag_name):
        """ "Add tag to MAAS Machine. """
        tag = self.get_tag(tag_name)
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.tags.add(tag)


    @keyword('Set Default Ubuntu Commissioning Release', types={'release': str, 'minimum_hwe_kernel_version': str})
    def set_commissioning_ubuntu_os_release(self, release, minimum_hwe_kernel_version):
        """ Set default Ubuntu release for commissioning. """
        try:
            self.client.maas.set_commissioning_distro_series(series=release)
            self.client.maas.set_default_min_hwe_kernel(version=minimum_hwe_kernel_version)
        except Exception as error:
            raise Exception(f'Failed to set commissioning release: {str(error)}')


    @keyword('Set Default Deployment Operating System', types={'operating_system': str, 'release': str})
    def set_deployment_os(self, operating_system, release):
        """ Set default OS for deployment. """
        try:
            self.client.maas.set_default_os(series=operating_system)
            self.client.maas.set_default_distro_series(series=release)
        except Exception as error:
            raise Exception(f'Failed to set deployment OS: {str(error)}')


    @keyword('Add KVM Host', types={'kvm_host_type': str, 'kvm_hostname': str, 'kvm_power_address': str, 'kvm_power_pass': str, 'zone': str, 
                                    'kvm_cpu_over_commit_ratio': float, 'kvm_memory_over_commit_ratio': float})
    def create_kvm_pod(self, kvm_host_type, kvm_hostname, kvm_power_address, kvm_power_pass, zone, kvm_cpu_over_commit_ratio, kvm_memory_over_commit_ratio):
        """ Add an existing KVM hypervisor host as a MAAS pod. """
        kvm_pod = self.client.pods.create(type=kvm_host_type, power_address=kvm_power_address, power_pass=kvm_power_pass, name=kvm_hostname, zone=zone)
        #kvm_pod.cpu_over_commit_ratio=kvm_cpu_over_commit_ratio
        #kvm_pod.memory_over_commit_ratio=kvm_memory_over_commit_ratio
        kvm_pod.save()
        return kvm_pod


    @keyword('Get KVM Host By Name ', types={'kvm_hostname': str})
    def get_kvm_pod(self, kvm_hostname):
        """ Get a KVM hypervisor host by hostname. """
        kvm_pods = self.client.pods.list()._items
        kvm_pod = [pod for pod in kvm_pods if pod.name==kvm_hostname][0]
        return kvm_pod


    @keyword('Create KVM Pod Machine', types={'kvm_hostname': str, 'machine_hostname': str})
    def create_kvm_pod_machine(self, kvm_hostname, machine_hostname, **machine_config):
        """ Create a KVM Virtual machine using the configured MAAS kvm pod. """
        kvm_pods = self.client.pods.list()._items
        kvm_pod = [pod for pod in kvm_pods if pod.name==kvm_hostname][0]
        # Create the label configuration for storage parameter of created pod machine
        storage = machine_config['machine_config']['storage']
        storage_config = []
        for label, args  in storage.items():
            storage_config.append(':'.join([label, str(args['size'])]))
        # Create the label configuration for default network interface (default_interface). We only need the fabric and VLAN Id (vid) for attaching the default interface.
        interface_name = list(machine_config['machine_config']['default_interface'].keys())[0]
        interface_configuration = {}
        interface_configuration.update(machine_config['machine_config']['default_interface'][interface_name].items())
        interface_configuration.update(machine_config['machine_config']['default_interface'][interface_name]['vlan'].items())
        maas_required_interface_configuration = ','.join(['%s=%s' % (key, value) for (key, value) in interface_configuration.items() if key in ['fabric','vid']])

        machine = kvm_pod.compose(hostname=machine_hostname, cores=machine_config['machine_config']['cores'],
                                  memory=machine_config['machine_config']['memory'], 
                                  architecture=machine_config['machine_config']['architecture'],
                                  interfaces=':'.join([interface_name, maas_required_interface_configuration]),
                                  storage=','.join(storage_config))
        return machine


    @keyword('Create Availability Zone', types={'zone_name': str, 'zone_description': str})
    def create_zone(self, zone_name, zone_description):
        """ Create an availability zone. """
        self.client.zones.create(name=zone_name, description=zone_description)


    @keyword('Get Availability Zone', types={'zone_name': str})
    def get_zone(self, zone_name):
        """ Get a specified availability zone. """
        return self.client.zones.get(name=zone_name)


    @keyword('Get Availability Zones Names')
    def get_zones_names(self):
        """ Get all configured availability zones names. """
        zones = self.client.zones.list()._items
        return [zone.name for zone in zones]


    @keyword('Create Resource Pool', types={'pool_name': str, 'pool_description': str})
    def create_pool(self, pool_name, pool_description):
        """ Create a resource pool. """
        self.client.resource_pools.create(name=pool_name, description=pool_description)


    @keyword('Get Resource Pool', types={'pool_name': str})
    def get_pool(self, pool_name):
        """ Get a specified resource pool. """
        return self.client.resource_pools.get(name=pool_name)


    @keyword('Get Resource Pools Names')
    def get_pool_names(self):
        """ Get all configured resource pools names. """
        pools = self.client.resource_pools.list()._items
        return [pool.name for pool in pools]


    @keyword('Add Machine To Resource Pool', types={'machine_system_id': str, 'resource_pool_name': str,})
    def add_machine_to_pool(self, machine_system_id, resource_pool_name):
        """ Add a MAAS machine to an existing resource pool. """
        try:
          pool = [pool for pool in self.client.resource_pools.list()._items if pool.name==resource_pool_name][0]
        except IndexError as error:
            raise Exception(f'Resource Pool with name {resource_pool_name} not found.')
        machine = self.client.machines.get(system_id=machine_system_id)
        machine.pool = pool
        machine.save()


    def _get_interface_type(self, type):
        """ Return interface type based on value, possible values the InterfaceType enum values like physical, bond, bridge etc."""
        interface_type = None
        for key, value in InterfaceType.__members__.items():
            if value.value == type:
                interface_type = InterfaceType.__members__[key]
                return interface_type


    @keyword('Add Interface To Machine', types={'machine_system_id': str, 'interface_name': str, 'interface_type': str, 'fabric_name': str,
             'vlan': dict, 'mac_address': str, 'bond_parents_interfaces': list, 'bond_mode': str, 'bond_miimon': int, 'bond_updelay': int, 'bond_downdelay':int,
             'bridge_parent_interface': str, 'bridge_type': str, 'bridge_stp_enabled': bool})
    def add_interface(self,
        machine_system_id, 
        interface_type,
        interface_name,
        fabric_name,
        vlan,
        *,
        mac_address =  None,
        bond_parents_interfaces = None,
        bond_mode = None,
        bond_miimon = 0,
        bond_updelay = 0,
        bond_downdelay = 0,
        bridge_parent_interface = None,
        bridge_type = None,
        bridge_stp_enabled = True):
        """ Add managed interface to machine like physical interface, bond or bridge """
        machine = self.client.machines.get(system_id=machine_system_id)
        if machine.status not in list([NodeStatus.NEW, NodeStatus.READY, NodeStatus.BROKEN, NodeStatus.ALLOCATED]):
            raise Exception('Interface configuration cannot be modified unless the node is New, Ready, Allocated, or Broken.')

        interface_types = [type[1].value for type in InterfaceType.__members__.items()]
        if interface_type not in interface_types:
            raise Exception(f'Not accepted interface type {interface_type} to be added. Available interface types: {interface_types}')

        added_interface_type = self._get_interface_type(interface_type)
        fabric = [fabric for fabric in self.client.fabrics.list() if fabric.name==fabric_name][0]
        vlan_attached = [vlan_attached for vlan_attached in fabric.vlans._items if vlan_attached.name==vlan['name'] and vlan_attached.vid == vlan['vid']][0]

        if added_interface_type == InterfaceType.PHYSICAL:
            if mac_address == None:
                raise Exception(f'mac_address is required when adding physical interface type.')
            interface = machine.interfaces.create(name=interface_name, interface_type=added_interface_type, mac_address=mac_address, vlan=vlan_attached)
            return interface
        elif added_interface_type == InterfaceType.BOND:
            if bond_parents_interfaces == None:
                raise Exception(f'bond_parents_interfaces is required when adding bond interface type.')
            if bond_mode == None:
                raise Exception(f'bond_mode is required when adding bond interface type.')
            parents_interfaces = [interface for interface in machine.interfaces._items if interface.name in bond_parents_interfaces]
            bond = machine.interfaces.create(name=interface_name, interface_type=added_interface_type, vlan=vlan_attached, parents=parents_interfaces, bond_mode=bond_mode, 
                                             bond_miimon=bond_miimon, bond_updelay=bond_updelay, bond_downdelay=bond_downdelay)
            return bond
        elif added_interface_type == InterfaceType.BRIDGE:
            if bridge_parent_interface == None:
                raise Exception(f'bridge_parent_interface is required when adding bridge interface type.')
            if bridge_type == None:
                raise Exception(f'bridge_type is required when adding bridge interface type.')
            try:
                parent_interface = [interface for interface in machine.interfaces._items if interface.name==bridge_parent_interface][0]
            except IndexError as error:
                raise Exception(f'Interface with name {bridge_parent_interface} not found.')
            bridge = machine.interfaces.create(name=interface_name, interface_type=added_interface_type, vlan=vlan_attached, parent=parent_interface, bridge_stp=bridge_stp_enabled)
            bridge._data['params']['bridge_type']=bridge_type
            bridge.save()
        else:
            raise Exception(f'Interface type {interface_type} not supported currently for configuration to machine')


    @keyword('Link Interface', types={'machine_system_id': str, 'interface_name': str, 'subnet_cidr': str, 'ip_address': str})
    def link_interface(self, machine_system_id, interface_name, subnet_cidr, ip_address):
        """ Link managed interface (static IP allocation). """
        machine = self.client.machines.get(system_id=machine_system_id)
        subnet = [subnet for subnet in self.client.subnets.list() if subnet.cidr==subnet_cidr][0]
        try:
            interface = [interface for interface in machine.interfaces._items if interface.name==interface_name][0]
        except IndexError as error:
            raise Exception(f'Interface with name {interface_name} not found. Existing interfaces: {[interface.name for interface in machine.interfaces._items]}')
        interface_link = interface.links.create(mode=LinkMode.STATIC, subnet=subnet, ip_address=ip_address, force=True)
        return interface_link

