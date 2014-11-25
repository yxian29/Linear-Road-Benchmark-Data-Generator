# Linear Road Benchmark Data Generator

This is an auto provisioning script to help set up the environment to run the `linear road benchmark` data generator.

## Prerequisite

### Install two puppet modules locally.

```
puppet module install puppetlabs-postgresql
puppet module install meltwater-cpan
```

### Install `vagrant plugin` locally

```
vagrant plugin install vagrant-digitalocean
vagrant plugin install vagrant-puppet-install
```

## How to run the simulation?

After provisioning with

```
vagrant up
```
, login to the VM with

```
vagrant ssh
```
. Then run

```
nohup ./run mitsim.config &
```

## How to config?

Modify the `mitsim.config` in the local `data` folder.

## Where is the result?

In the provisioning VM's `data` directory.

