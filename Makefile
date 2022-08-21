#
# Makefile for CloudRun-Exec
#
# * By Kordian W. <code [at] kordy.com>, Aug 2022
#

# General Configuration
IMAGE=cloudrun-exec

# GCP Configuration:
GCP_REGION=us-central1 				# default region as it's low-co2 and central to all of US
GCP_AUTH_MODEL="--no-allow-unauthenticated"	# secure: web-service only works with auth-token header
#GCP_AUTH_MODEL="--allow-unauthenticated"	# insecure: web-service is open to all (only URL is needed)
# GCP: What is the GCP Project ID?
GCP_PROJECT_ID=$(shell gcloud config get-value core/project)

# OTHER Configuration:
CLOUD_HELPER_SCRIPT=setup-aws-gcp.sh 		# used to auth+login to `gcloud'

########################################################

# Help (use with `make all'):
all:
	@echo "build                - Docker (local): Build the App $(IMAGE) docker image"
	@echo "list                 - Docker (local): list the current Docker images in the registry"
	@echo 
	@echo "glogin               - GCP: pre-build: login to GCP in order to be able to do the build"
	@echo "gbuild               - GCP: Build the App $(IMAGE) docker image"
	@echo "gdeploy              - GCP: Deploy the app $(IMAGE) image to Cloud Run"
	@echo 
	@echo "qlist                - GCP: list all services/applications deployed in Google Could Run"
	@echo "gclean               - GCP: Clean resources created in this entire $(IMAGE) application"
	@echo 
	@echo "gcall                - GCP: Call the Cloud Run service App $(IMAGE) via GET /"
	@echo "gcall_exec CMD=<cmd> - GCP: Call the Cloud Run service App $(IMAGE) via POST /exec w/data"
	@echo "gcall_hw             - GCP: Call the Cloud Run service App $(IMAGE) and EXECUTE: HW-INFO.SH"
	@echo "gcall_ip             - GCP: Call the Cloud Run service App $(IMAGE) and EXECUTE: IP-LOCATION.SH"

# Make Targets:
build:
	@echo "* Building Python Docker image for app $(IMAGE)"
	docker image build . --build-arg="app_name=$(IMAGE)" -t "$(IMAGE):latest"

list:
	@echo "* Listing Docker image for app $(IMAGE)"
	docker image list .

gbuild:
	@echo "* $(GCP_PROJECT_ID): Building Python Cloud Run (authenticated) service for app $(IMAGE): in $(GCP_REGION)"
	@echo "STEP 1: << gcloud builds submit --tag gcr.io/$(GCP_PROJECT_ID)/$(IMAGE) >>"
	gcloud builds submit --tag gcr.io/$(GCP_PROJECT_ID)/$(IMAGE)

gdeploy:
	@echo "* $(GCP_PROJECT_ID): Deploying Python Cloud Run (authenticated) service for app $(IMAGE): in $(GCP_REGION)"
	@echo "* STEP 2: << gcloud run deploy $(IMAGE) --image gcr.io/$(GCP_PROJECT_ID)/$(IMAGE) --platform managed --region $(GCP_REGION) >>"
	gcloud run deploy $(IMAGE) \
		--image gcr.io/$(GCP_PROJECT_ID)/$(IMAGE) \
		--max-instances 1 \
		--platform managed \
		--region $(GCP_REGION) \
		$(GCP_AUTH_MODEL)

glist:
	@echo "* $(GCP_PROJECT_ID): listing Google Cloud Run deployed services/apps"
	gcloud run services list

gclean:
	@echo "* $(GCP_PROJECT_ID): Deleting registry image/container $(IMAGE) + Cloud Run job $(IMAGE): in $(GCP_REGION)"
	-gcloud container images delete gcr.io/$(GCP_PROJECT_ID)/$(IMAGE) --quiet
	-gcloud run services delete $(IMAGE) \
		--platform managed \
		--region $(GCP_REGION) \
		--quiet

gcall:
	@echo "* $(GCP_PROJECT_ID): Calling Python Cloud Run (authenticated) service URL for app $(IMAGE)"
	@url=$(shell gcloud run services describe $(IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl -w "\n" --header "Authorization: Bearer $$token" $$url

glogin:
	@echo "* Project << $(GCP_PROJECT_ID) >>: logging into GCP via helper script $(CLOUD_HELPER_SCRIPT)"
	@echo "  --FYI: this is only necessary the first time, if Project Id is Unset or Empty"
	$(CLOUD_HELPER_SCRIPT) -glogin

gcall_exec:
	@echo "* $(GCP_PROJECT_ID): Calling Cloud Run service $(IMAGE) with << $(CMD) >>"
	@url=$(shell gcloud run services describe $(IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
  		--data-binary "$(CMD)"

gcall_hw:
	@echo "* $(GCP_PROJECT_ID): Calling Cloud Run service $(IMAGE) with << HW-INFO.SH >>"
	@url=$(shell gcloud run services describe $(IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
		--data-binary "curl -sS https://raw.githubusercontent.com/kordianw/HW-Info/master/hw-info.sh | bash"

gcall_ip:
	@echo "* $(GCP_PROJECT_ID): Calling Cloud Run service $(IMAGE) with << IP-LOCATION.SH >>"
	@url=$(shell gcloud run services describe $(IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
		--data-binary "curl -sS https://raw.githubusercontent.com/kordianw/Shell-Tools/master/ip-location.sh | bash"

# EOF
