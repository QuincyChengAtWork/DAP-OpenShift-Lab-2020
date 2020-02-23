# Prerequisite: Environment Setup
This section describes how to setup the environment for this tutorial

## Setup CyberArk CorePAS based on CGD

This tutorial is based on 4 virtual machines (`DC`, `VAULT`, `COMP` & `CLIENT`) from  [CGD](https://ca-il-confluence.il.cyber-ark.com/display/gpse/CGD+-+20200101#/)
Note the lab was built with CGD-2020-0101-GA but should work with other versions or CorePas v11.1 as well.

Please refer to https://ca-il-confluence.il.cyber-ark.com/pages/viewpage.action?pageId=285087892&preview=%2F285087892%2F297248443%2FCGD-Stand-Alone-Skytap-Demo-QuickStart_2019_1001.pdf for detailed setup

## Setup 2 Extra VM (DAP Master & OKD)

We will setup 2 more VMs for this tutorial.  One as DAP Master instance and another one for executing OKD.

1. Download `040-OKD.7z` and `041-DAP-MASTER` from `/apj/Conjur-OpenShift-Workshop-20200221` folder in Smartfile.
2. Extract both files
3. In the extracted folder, open `` import them to VMWare workstation.
4. In `COMP` VM, 


## Onboard MySQL Account to CorePAS



## Setup DAP Master


## Configure Vault Synchronizer
