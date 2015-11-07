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
* Add an enviornment variable to store access token.
```{r, engine='bash', count_lines}
$ sudo gedit ~/.bashrc
```
..* Add the following line
```
export DIGITALOCEAN_TOK=******************* (paste the access token obtained from Digital Ocean)
```
* Provisioning with `Digital Ocean`. Modify the `Vagrantfile` in `/vagrant` folder if necessary.
```ruby
  config.vm.provider :digital_ocean do |provider, override|
    override.ssh.private_key_path = './do-office'
    override.vm.box = 'digital_ocean'
    override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
    override.puppet_install.puppet_version = "3.7.2"
    provider.token= ENV['DIGITALOCEAN_TOK']
    # Configurable parameters depending which droplet you want to create 
    provider.image = "ubuntu-14-04-x64"
    provider.region = "nyc1"
    provider.size = "1gb"
  end
```
* Boot up the environment.

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

* Modify the `mitsim.config` in the local `/vagrant/data` folder.
```
directoryforoutput=/opt/data
databasename=hellolrb
databaseusername=vagrant
databasepassword=hellopwd
numberofexpressways=0.5
```

## Where is the result?

MITSIM output will be in the folder designated as `directoryforoutput` in `mistsim.config`.
Three output file: `cardatapoints.out`, `historical-tolls.out`, `maxCarid.out`


