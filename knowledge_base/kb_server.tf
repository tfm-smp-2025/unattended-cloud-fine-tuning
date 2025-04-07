# Set the variable value in *.tfvars file
# or using -var="hcloud_token=..." CLI option
variable "hcloud_token" {}
variable "hcloud_ssh_key" {}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}


# Create a server
resource "hcloud_server" "knowledge_base" {
    image = "ubuntu-24.04"
    name = "knowledge-base"
    server_type = "cpx11"   # We'll create it first with this image, then
                            # move to CPX21 without resizing the disk, that 
                            # way we can move back and forth to this tier
    ssh_keys = ["${var.hcloud_ssh_key}"]

    labels = {
        "name": "Knowledge_Base"
    }
}

# Create a volume for the Bestiary (source and DB) and the DBPedia 2016v04 (source)
resource "hcloud_volume" "dbpedia_disk" {
    name = "dbpedia2016v4_src"
    size = 200  # 5.9GB for DBPedia's bzipped sources + extra space for Bestiary (<1GB)
                # + ~200GB for DBPedia loaded to the Graph DB
    delete_protection = true
    server_id = hcloud_server.knowledge_base.id
    automount = true
    format = "ext4"

    labels = {
        "name": "DBPedia_2016v04_and_Bestiary"
    }

    lifecycle {
       prevent_destroy = true
    }
}