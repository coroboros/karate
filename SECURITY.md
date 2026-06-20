# Security policy

## Supported versions

Latest `main` only. Tagged releases follow the same support model as the `main` branch at the time of the release.

## Reporting a vulnerability

Report vulnerabilities to **ob@coroboros.com**. Do not open public issues, MRs, or comments for security problems.

Expected initial response: within 5 business days.

Coordinated disclosure preferred. A fix window of 30 days is the default before public disclosure; we will agree on a different window when the severity demands it.

## Scope

This repository builds the Karate API-testing image. In scope:

- **Supply chain of the build** — a base image, apk package, or the downloaded Karate jar that resolves to a compromised artifact, or a build step that fetches unverified content. The Karate jar is pinned by version and verified by SHA-256.
- **Image hardening** — the image runs non-root (`karate`, uid 10000) with `karate` as its entrypoint; a privilege or escape path baked into the image is in scope.
- **Provenance** — every published image is container-scanned and cosign-signed with a CycloneDX SBOM attestation, via the shared [`coroboros/ci`](https://gitlab.com/coroboros/ci) template. A signing or attestation gap is in scope.
