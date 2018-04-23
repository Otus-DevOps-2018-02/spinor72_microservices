#!/usr/bin/python
import sys
import os
import argparse
import json
from subprocess import Popen, PIPE
import ConfigParser

URL_TEMPLATE = "gs://{}/{}/default.tfstate"
DEBUG = True
BUCKET = "storage-bucket-spinor72-test"
PREFIX = "terraform/docker"


def load_state(bucket, prefix):
    try:
        state_loader = Popen(["gsutil", "cp", URL_TEMPLATE.format(bucket, prefix), "-"], stdout=PIPE, stderr=PIPE)
        error = state_loader.stderr.read()
        if error:
            print error
            sys.stderr.write(error)
            sys.exit(os.EX_DATAERR)
        data = json.loads(state_loader.stdout.read())
        return data

    except ValueError:
        if DEBUG:
            sys.stderr.write("No JSON object could be decoded")
            sys.exit(os.EX_DATAERR)
        else:
            return "{}"
    except OSError:
        if DEBUG:
            sys.stderr.write("Gsutill not installed or other system error")
            sys.exit(os.EX_DATAERR)
        else:
            return "{}"


def print_list(data):
    try:
        inventory = {"_meta": {"hostvars": {}}}
        hosts = (i for i in data.get('modules',[]) if i.get('resources') and i.get('resources').get('null_resource.ansible'))
        for _ in hosts:
            host = _.get('outputs')
            vars = host.get('vars', {}).get('value', {})
            name, ansible_host = '', ''
            names, ansible_hosts = [], []

            if host.get('name'):
                name = host.get('name').get('value')
            else:
                raise ValueError("Host name not present")
            if name:
                inventory["_meta"]["hostvars"][name] = vars
            if host.get('host'):
                ansible_host = host.get('host').get('value', '')
            else:
                raise ValueError("Host address not present")
            if name and ansible_host:
                inventory["_meta"]["hostvars"][name]['ansible_host'] = ansible_host

            if host.get('names'):
                names = host.get('names').get('value')
                if host.get('hosts'):
                    ansible_hosts = host.get('hosts').get('value', [])
                    for z in zip(names, ansible_hosts):
                        inventory["_meta"]["hostvars"][z[0]] = {}
                        inventory["_meta"]["hostvars"][z[0]]['ansible_host'] = z[1]

            if host.get('groups'):
                for g in host.get('groups').get('value', []):
                    if g not in inventory:
                        inventory[g] = {'hosts': [], "vars": {}}
                    if name: 
                        inventory[g]['hosts'].append(name)
                    for h in names:
                        inventory[g]['hosts'].append(h)

        print json.dumps(inventory, sort_keys=True, indent=4, separators=(',', ': '))
    except ValueError as e:
        if DEBUG:
            sys.stderr.write(e.message)
            sys.exit(os.EX_DATAERR)
        else:
            print "{}"
    except AttributeError:
        if DEBUG:
            sys.stderr.write("Inventory data invalid")
            sys.exit(os.EX_DATAERR)
        else:
            print "{}"


def print_host(host):
    print '{}'

prefix = os.environ.get('GS_BUCKET')
bucket = os.environ.get('GS_PREFIX')

config = ConfigParser.ConfigParser()
config_file = os.path.splitext(os.path.abspath(__file__))[0] + ".cfg"
if os.path.isfile (config_file):
    try:
        config.read(config_file)
        prefix = config.get('gs', 'prefix')
        bucket = config.get('gs', 'bucket')
    except :
        sys.stderr.write("Error in configuration file")

if not prefix or not bucket:
    sys.stderr.write("Cannot set configuration options for bucket")
    sys.exit(os.EX_DATAERR)

parser = argparse.ArgumentParser()
parser.add_argument("--list", help="print inventory in json format", action="store_true")
parser.add_argument("--host", help="print host vars in json format")
args = parser.parse_args()

state = load_state(bucket, prefix)
if args.list:
    print_list(state)
elif args.host:
    print_host(args.host)
