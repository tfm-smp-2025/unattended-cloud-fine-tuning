# unattended-cloud-fine-tuning
Fine-tune LLM models unattended on cloud platforms.

## Setup test Knowledge Base

### Create infrastructure

To setup the infrastructure

1. Open the `knowledge_base` directory
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
    /dev/sdb        196G   28K  186G   1% /mnt/HC_Volume_102384877
                    ^^^^ this 200GB disk is the one we're interested in
    tmpfs           192M   12K  192M   1% /run/user/0
    ```

3. Close the ssh session `exit`.
4. Go to the local repository, on the `fine-tuning/datasets` directory and run rsync:    `rsync -HPaz --mkpath by_url/ root@<IP>:/mnt/HC_Volume_<REPLACE THE NUMBER HERE>/datasets/by_url/` (note that the trailing slashes are relevant).

### Setup KB server (Apache Jena)

@TODO@

### Download the datasets to the server

@TODO@

### Upload the datasets to the Knowledge Base

@TODO@
