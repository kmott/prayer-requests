SHELL := /bin/bash

localdev:
	@npm run localdev
.PHONY: localdev

localdev-deno:
	@pushd src >/dev/null ; deno run --allow-net --allow-read deno.ts ; popd >/dev/null
.PHONY: localdev-deno

build: clean
	@npm run build
.PHONY: build

build-run: build
	@node dist/express.js
.PHONY: build-run

package: build
	@packer build prayer-requests.pkr.hcl
.PHONY: package

deploy: deploy-preflight
	@nomad run --detach prayer-requests.nomad.hcl
.PHONY: deploy

deploy-preflight:
	@if [[ -z "${NOMAD_TOKEN}" ]]; then                                              \
		echo "ERROR: Please run klm_nomad_setup before deployment, cannot continue"; \
		exit 1;                                                                      \
	fi
.PHONY: deploy-preflight

clean:
	@if [[ -d "dist" ]]; then    \
		rm -rf dist;             \
	fi
.PHONY: clean
