# unattended-cloud-fine-tuning
Fine-tune LLM models unattended on cloud platforms.

## Setup test Knowledge Base

Download extra directories, run `git submodule update --init --recursive .` on this directory root. This will download the `fine-tuning` repo.

### Create infrastructure

To setup the infrastructure

1. Open the `infra/terraform/knowledge_base` directory
2. Run `terraform init` on it. Can be obtained from [Terraform.io](https://www.terraform.io/).
3. Open the Hetzner console and create an API key and upload your SSH public key.
4. Create and fill the `secret.tfvars` file:

```ini
hcloud_token = "<Add here>"
hcloud_ssh_key = "<Add here>"
```

5. Run terraform `terraform apply -var-file=secret.tfvars`, inspect the changes and accept them with `y`.

6. Check the "Servers" tab on the Hetzner panel to get the new server IP. It can be accessed with `ssh root@<IP>`.

### (Optionally) Preload DBPedia data
If you already downloaded DBPedia 2016v04 locally you can use this data instead of pulling it again from DBPedia's server.

1. SSH to the new server `ssh root@<IP>`.
2. Run `df` to find the DBPedia 2016v04 disk path. Sample output:

    ```
    df -h
    Filesystem      Size  Used Avail Use% Mounted on
    tmpfs           192M  856K  192M   1% /run
    /dev/sda1        38G  1.2G   35G   4% /
    tmpfs           960M     0  960M   0% /dev/shm
    tmpfs           5.0M     0  5.0M   0% /run/lock
    /dev/sda15      253M  146K  252M   1% /boot/efi
    /dev/sdb        108G   28K  105G   1% /mnt/HC_Volume_102384877
                    ^^^^ this 110GB disk is the sources one
    /dev/sdc        787G   28K  787G   1% /mnt/HC_Volume_102387499
                    ^^^^ this 800GB disk is the loaded files one
    /dev/sdd         20G   24K   19G   1% /mnt/HC_Volume_102477904
                    ^^^^ this  20GB disk is the Vector DBs one
    tmpfs           192M   12K  192M   1% /run/user/0
    ```

3. Close the ssh session `exit`.
4. Go to the local repository, on the `fine-tuning/datasets` directory and run rsync:    `rsync -HPaz --mkpath by_url/ root@<IP>:/mnt/HC_Volume_<REPLACE THE NUMBER HERE>/datasets/by_url/` (note that the trailing slashes are relevant).

### Setup KB server (Apache Jena Fuseki)

1. On the `infra/playbooks` directory create a file named `ansible_hosts.yml` with the following content.

    ```yaml
    knowledge_bases:
        hosts:
            <ip>:
                ansible_user: root  # As configured by Hetzner
                source_disk: "/mnt/HC_Volume_<REPLACE_THE_SOURCES_DISK_NUMBER_HERE>"
                loaded_disk: "/mnt/HC_Volume_<REPLACE_THE_LOADED_DISK_NUMBER_HERE>"
                kb_admin_password: "<ADD_HERE_A_RANDOM_PASSWORD_FOR_THE_KNOWLEDGE_BASE>"
    ```

2. Install the required ansible modules. `ansible-galaxy collection install -r ansible_galaxy_requirements.yml`. [See here how to obtain `ansible`](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible).

3. Run ansible `ansible-playbook -i ansible_hosts.yml -l knowledge_bases site.yml`

### Download the datasets to the server

1. Connect to the server via ssh: `ssh root@<IP>`
2. Go to the data_loader code: `cd /usr/src/fine-tuning/`
3. Create virtualenv: `virtualenv venv`
4. Open virtualenv: `source venv/bin/activate`
5. Install dependencies: `pip install -r requirements.txt`
6. Run the pulling script: `python3 scripts/pull_knowledge_bases.py`
    - Alternatively, use [screen](https://www.gnu.org/software/screen/) so the server can be disconnected from without stopping the download: `screen python3 scripts/pull_knowledge_bases.py`


### Upload the datasets to the Knowledge Base

1. Connect to the server via ssh: `ssh root@<IP>`
2. Go to the data_loader code: `cd /usr/src/fine-tuning/`
3. Open virtualenv: `source venv/bin/activate`
4. Create temporary directory for unpacking files before load. `mkdir "<PATH_TO_LOADED_DISK>/tmp"`
   - This is needed to hold files that expand to >30GB before load.
5. Run data loading script: `ADMIN_SPARQL_PASSWORD=<ADD_HERE_THE_PASSWORD> TMPDIR="<PATH_TO_LOADED_DISK>/tmp" ./infra/initialize_kb.sh`
    - This is a VERY SLOW process (**THIS STEP WILL TAKE MULTIPLE DAYS**) so you probably would want to run it inside a `screen` session.

### Weaviate vector DB

1. On the `infra/playbooks` directory create a file named `ansible_hosts.yml` with the following content.

    ```yaml
    vector_dbs:
        hosts:
            <ip>:
                ansible_user: root  # As configured by Hetzner
                vector_disk: "/mnt/HC_Volume_<REPLACE_THE_VECTOR_DISK_NUMBER_HERE>"
                vector_db_apikey: "<ADD_HERE_A_RANDOM_API_KEY_FOR_THE_VECTOR_DB>"
    ```

2. Install the required ansible modules. `ansible-galaxy collection install -r ansible_galaxy_requirements.yml`. [See here how to obtain `ansible`](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible).

3. Run ansible `ansible-playbook -i ansible_hosts.yml -l vector_dbs site.yml`
