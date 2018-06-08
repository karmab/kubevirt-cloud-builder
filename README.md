# KubeVirt Cloud Builder

The repo contains artifacts and scripts that can be used to build and test a gcloud compute image containing Kubernetes and KubeVirt.

## Build

packer needs a patch pending from this [pr](https://github.com/hashicorp/packer/pull/6350) 
- put the files except the json one in a kubevirt-button directory
- edit packer-kubevirt-button.json to properly set the path of your account_file. You can optionally change things like
   - cpu and memory of the image with the machine_type
   - network_ip depending on which region you'll want the resulting images to launch in
- create the image with the following command 

```
packer build kubevirt-gcp-centos.json
```

then you can deploy an instance making sure you 
- name it kubevirt
- force the primary private ip to 10.132.15.253
- use the zone europe-west1-b ( to have the ip from the correct subnet)

to make the image available publicly, we need to store it in google cloud storage

```
PROJECT="kubevirt-button"
IMAGE="kubevirt-button"
VERSION="v0.5.0"
BUCKET="kubevirt"
gcloud compute images export --destination-uri gs://$BUCKET/$VERSION.tar.gz --image $IMAGE  --project $PROJECT
```
