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
    server_type = "ccx33"   # We'll create it first with this image, then
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
                # + extra space for Beastiary (~1MB)
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


# Create a volume for the storage of the loaded knowledge base
resource "hcloud_volume" "knowledge_base_loaded" {
    name = "knowledge_base_loaded"
    size = 800  # basically nothing for Beastiary (13MB)
                # + 380G DBPedia 2016v04
                # + .... DBPedia 2016-10
                # + ~220GB for Freebase
    delete_protection = true
    server_id = hcloud_server.knowledge_base.id
    automount = true
    format = "ext4"

    labels = {
        "name": "Knowledge_base_loaded"
    }

    lifecycle {
       prevent_destroy = true
    }
}

# Create a volume for the storage of the vector database
resource "hcloud_volume" "vector_db" {
    name = "vector_db"
    size = 20
    delete_protection = true
    server_id = hcloud_server.knowledge_base.id
    automount = true
    format = "ext4"

    labels = {
        "name": "vector_db"
    }

    lifecycle {
       prevent_destroy = true
    }
}