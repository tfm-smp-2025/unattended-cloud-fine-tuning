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

# Create a volume for the source files for the knowledge base
resource "hcloud_volume" "knowledge_base_source" {
    name = "knowledge_base_source"
    size = 110  # 5.9GB for DBPedia 2016v04 bzipped sources
                # + extra space for Bestiary (~1MB)
                # + 69 for DBPedia 2016-10 bzipped sources
                # + 30GB Gzipped Freebase
                # + 5 extra GB just in case
    delete_protection = true
    server_id = hcloud_server.knowledge_base.id
    automount = true
    format = "ext4"

    labels = {
        "name": "Knowledge_base_sources"
    }

    lifecycle {
       prevent_destroy = true
    }
}