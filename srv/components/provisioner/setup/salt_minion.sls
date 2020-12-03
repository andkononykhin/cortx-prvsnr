#
# Copyright (c) 2020 Seagate Technology LLC and/or its Affiliates
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# For any questions about this software or licensing,
# please email opensource@seagate.com or cortx-questions@seagate.com.
#

salt_minion_configured:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://components/provisioner/salt_minion/files/minion
    - keep_source: True
    - backup: minion
    - template: jinja

# FIXME EOS-8473 prepend is not a clean solution
salt_minion_grains_configured:
  file.managed:
    - name: /etc/salt/grains
    - source: salt://srv/components/provisioner/salt_minion/files/grains
    - keep_source: True
    - backup: minion
    - template: jinja

# TODO EOS-8473 better content management
salt_minion_id_set:
  file.prepend:
    - name: /etc/salt/minion_id
    - text: {{ grains.id }}

salt_minion_config_is_good:
  cmd.run:
    - name: 'salt-call --local test.ping'
    - require:
      - salt_minion_configured
      - salt_minion_grains_configured
      - salt_minion_id_set

salt_minion_pki_set:
  file.recurse:
    - name: /etc/salt/pki/minion
    - source: salt://provisioner/files/minions/{{ grains.id }}/pki
    - clean: True
    - keep_source: True
    - maxdepth: 0

salt_minion_master_pki_set:
  file.managed:
    - name: /etc/salt/pki/minion/minion_master.pub
    - source: salt://provisioner/files/master/pki/master.pub
    - keep_source: True
    - backup: minion
    - template: jinja

salt_minion_enabled:
  service.enabled:
    - name: salt-minion.service
    - require:
      - salt_minion_config_is_good
      - salt_minion_grains_configured
      - salt_minion_id_set
      - salt_minion_pki_set
      - salt_minion_master_pki_set

# stopped on any changes to restart later
salt_minion_stopped:
  service.dead:
    - name: salt-minion.service
    - require:
      - salt_minion_config_is_good
    - watch:
      - file: salt_minion_config_updated
      - file: salt_minion_grains_configured
      - file: salt_minion_id_set
      - file: salt_minion_pki_set
      - file: salt_minion_master_pki_set
