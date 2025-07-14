# INFRA
All infrastructure related topics to the main game. 

## Setup
Create `secrets.env` like this and export it to your terminal via `source secrets.env`:

````shell 
TF_VAR_project_id="my-gcp-project"
TF_VAR_user="my-github-username"
TF_VAR_password="my-github-token"
````

Next call the following steps from the main directory:

````shell 
terraform init
terraform plan
terraform apply
````