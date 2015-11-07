# Linear Road Benchmark Data Generator

This is an auto provisioning script to help set up the environment to run the [linear road](www.cs.brandeis.edu/~linearroad) benchmark data generator.


## Prerequisite

* Install [puppet](https://puppetlabs.com/).
```{r, engine='bash', count_lines}
$ sudo apt-get install puppet
```
* Install `puppet modules`.

```{r, engine='bash', count_lines}
$ puppet module install puppetlabs-postgresql
$ puppet module install meltwater-cpan
```
* Install [vagrant](https://vagrantup.com).
```{r, engine='bash', count_lines}
$ sudo apt-get install vagrant
```
* Install `vagrant plugin`.

```{r, engine='bash', count_lines}
$ vagrant plugin install vagrant-digitalocean
$ vagrant plugin install vagrant-puppet-install
```

## How to run the simulation?
* After Git cloning the repository to you local. Go to `/vagrant` folder.
* Create a RSA Key Pair.
```{r, engine='bash', count_lines}
$ ssh-keygen -t rsa
Enter file in which to save the key (/home/<username>/.ssh/id_rsa): do-office
```
..* The name of the file must match 'override.ssh.private_key_path' in Vagrantfile

* Boot up the Vagrant environment.

```{r, engine='bash', count_lines}
$ vagrant up
```
* Login to the VM with

```{r, engine='bash', count_lines}
$ vagrant ssh
```
. Then run

```{r, engine='bash', count_lines}
$ cd opt
$ ./run mitsim.config
```

## How to config LRB?

Modify the `mitsim.config` in the local `/vagrant/data` folder.
---
directoryforoutput=/opt/data
databasename=hellolrb
databaseusername=vagrant
databasepassword=hellopwd
numberofexpressways=0.5
---

## Where is the result?

In the provisioning VM's `data` directory. It matches the setting `directoryforoutput` in `mistsim.config`

