#
# Makefile for CloudRun-Exec
#

# General Configuration
CLOUD_HELPER_SCRIPT=setup-aws-gcp.sh 		# used to auth+login to `gcloud'

# GCP Configuration:
GCP_IMAGE=hw-info
GCP_REGION=us-central1 				# default region as it's low-co2 and central to all of US
GCP_AUTH_MODEL='--no-allow-unauthenticated'	# secure: web-service only works with auth-token header
#GCP_AUTH_MODEL='--allow-unauthenticated'	# insecure: web-service is open to all (only URL is needed)
# GCP: What is the GCP Project ID?
GCP_PROJECT_ID=$(shell gcloud config get-value core/project)

# Help (use with `make all'):
all:
	@echo "glogin               - GCP: PRE: login to GCP in order to be able to do the build"
	@echo "gbuild               - GCP: Build the App $(GCP_IMAGE) docker image"
	@echo "gdeploy              - GCP: Deploy the app $(GCP_IMAGE) image to Cloud Run"
	@echo "gclean               - GCP: Clean resources created in this entire application"
	@echo "gcall                - GCP: Call the Cloud Run service App $(GCP_IMAGE) via GET /"
	@echo "gcall_exec CMD=<cmd> - GCP: Call the Cloud Run service App $(GCP_IMAGE) via POST /exec w/data"
	@echo "gcall_hw             - GCP: Call the Cloud Run service App $(GCP_IMAGE) and EXECUTE: HW-INFO.SH"
	@echo "gcall_ip             - GCP: Call the Cloud Run service App $(GCP_IMAGE) and EXECUTE: IP-LOCATION.SH"

# Make Targets:
gbuild:
	@echo "* $(GCP_PROJECT_ID): Building Python Cloud Run (authenticated) service for app $(GCP_IMAGE): in $(GCP_REGION)"
	@echo "STEP 1: << gcloud builds submit --tag gcr.io/$(GCP_PROJECT_ID)/$(GCP_IMAGE) >>"
	gcloud builds submit --tag gcr.io/$(GCP_PROJECT_ID)/$(GCP_IMAGE)

gdeploy:
	@echo "* $(GCP_PROJECT_ID): Deploying Python Cloud Run (authenticated) service for app $(GCP_IMAGE): in $(GCP_REGION)"
	@echo "* STEP 2: << gcloud run deploy $(GCP_IMAGE) --image gcr.io/$(GCP_PROJECT_ID)/$(GCP_IMAGE) --platform managed --region $(GCP_REGION) >>"
	gcloud run deploy $(GCP_IMAGE) \
		--image gcr.io/$(GCP_PROJECT_ID)/$(GCP_IMAGE) \
		--max-instances 1 \
		--platform managed \
		--region $(GCP_REGION) \
		$(GCP_AUTH_MODEL)

gclean:
	@echo "* $(GCP_PROJECT_ID): Deleting registry image/container $(GCP_IMAGE) + Cloud Run job $(GCP_IMAGE): in $(GCP_REGION)"
	-gcloud container images delete gcr.io/$(GCP_PROJECT_ID)/$(GCP_IMAGE) --quiet
	-gcloud run services delete $(GCP_IMAGE) \
		--platform managed \
		--region $(GCP_REGION) \
		--quiet

gcall:
	@echo "* $(GCP_PROJECT_ID): Calling Python Cloud Run (authenticated) service URL for app $(GCP_IMAGE)"
	@url=$(shell gcloud run services describe $(GCP_IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl -w "\n" --header "Authorization: Bearer $$token" $$url

glogin:
	@echo "* Project << $(GCP_PROJECT_ID) >>: logging into GCP via helper script $(CLOUD_HELPER_SCRIPT)"
	@echo "  --FYI: this is only necessary the first time, if Project Id is Unset or Empty"
	$(CLOUD_HELPER_SCRIPT) -glogin

gcall_exec:
	@echo "* $(GCP_PROJECT_ID): Calling Cloud Run service $(GCP_IMAGE) with << $(CMD) >>"
	@url=$(shell gcloud run services describe $(GCP_IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
  		--data-binary "$(CMD)"

gcall_hw:
	@echo "* $(GCP_PROJECT_ID): Calling Cloud Run service $(GCP_IMAGE) with << HW-INFO.SH >>"
	@url=$(shell gcloud run services describe $(GCP_IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
		--data-binary "curl -sS https://raw.githubusercontent.com/kordianw/HW-Info/master/hw-info.sh | bash"

gcall_ip:
	@echo "* $(GCP_PROJECT_ID): Calling Cloud Run service $(GCP_IMAGE) with << IP-LOCATION.SH >>"
	@url=$(shell gcloud run services describe $(GCP_IMAGE) --format='value(status.url)' --region $(GCP_REGION) --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
		--data-binary "curl -sS https://raw.githubusercontent.com/kordianw/Shell-Tools/master/ip-location.sh | bash"

# EOF
