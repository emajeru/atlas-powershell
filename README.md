# Atlas (vCloud Extra Management Options)

This module is meant to consolidate several tedious tasks into a collection of functions to simplify deployment and management of any vCloud environment. It also stands as a first step to an Infrastructure as code Powershell approach.

## Requirements
1. None of the functions contain the `Connect-CIServer` command so a connection to a single CI Server instance will be required before running any of the functions.
2. Some of the functions accept different configuration files in order to automate the run. These will need to be supplied by the users.

## Available Tasks
- Creation
    + Organization
    + Virtual Datacenter
    + Organization User
    + Virtual Application
    + Virtual Machine
    + Edge Gateway
        * NAT Rules
        * Firewall Rules
        * VPN Tunnels
- Retrieval
    + Organization
    + Virtual Datacenter
    + Organization User
    + Edge Gateway
        * NAT Rules
        * Firewall Rules
        * VPN Tunnels