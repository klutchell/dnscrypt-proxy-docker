# Contributing

We love your input! We want to make contributing to this project as easy and
transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We develop with Github

We use Github to host code, to track issues and feature requests, as well as
accept pull requests.

## We use [Github Flow](https://guides.github.com/introduction/flow/index.html), so all code changes happen through pull requests

Pull requests are the best way to propose changes to the codebase. We actively
welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Any contributions you make will be under the [Software License](LICENSE)

In short, when you submit code changes, your submissions are understood to be
under the same [Software License](LICENSE) that covers the project. Feel free
to contact the maintainers if that's a concern.

## Report bugs using Github's [issues](https://github.com/klutchell/dnscrypt-proxy-docker/issues)

We use GitHub issues to track public bugs. Report a bug by
[opening a new issue](https://github.com/klutchell/dnscrypt-proxy-docker/issues/new);
it's that easy!

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can.
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you
  tried that didn't work)

People _love_ thorough bug reports. I'm not even kidding.

## Use a consistent coding style

- Use [hadolint](https://github.com/hadolint/hadolint) for linting and
  validating Dockerfile changes
- Use [prettier](https://prettier.io) for linting and validating Markdown
  changes

## Building

1. Enable docker buildkit and experimental mode

   ```bash
   export DOCKER_BUILDKIT=1
   export DOCKER_CLI_EXPERIMENTAL=enabled
   ```

2. Build image for host architecture

   ```bash
   docker build . --tag klutchell/dnscrypt-proxy:dev
   ```

3. Optionally cross-build for another architecture

   ```bash
   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
   docker build . --tag klutchell/dnscrypt-proxy:dev --platform linux/arm/v7
   ```

## Testing

1. Run a detached dnscrypt-proxy container

   ```bash
   docker run --rm -d --name dnscrypt klutchell/dnscrypt-proxy:dev
   ```

2. Resolve a name through the proxy with the bundled `dnsprobe`

   ```bash
   docker exec dnscrypt dnsprobe -timeout=10s dnssec.works 127.0.0.1:5053
   ```

3. Stop and remove the test container

   ```bash
   docker stop dnscrypt
   ```

The full integration suite lives in [`docker-compose.test.yml`](docker-compose.test.yml)
and runs in CI on every PR.

## Packaging new dnscrypt-proxy releases

The dnscrypt-proxy version is bumped manually (Renovate is explicitly disabled
for this dependency) so the maintainer can verify upstream notes, recompute the
source SHA256, and tag the release after merge.

1. In your working copy, create a new branch if you haven't already, and update
   the following fields in the [Dockerfile](Dockerfile) with the new version
   and hash.

   ```dockerfile
   ARG DNSCRYPT_PROXY_VERSION=2.1.16
   # https://github.com/DNSCrypt/dnscrypt-proxy/releases/tag/2.1.16
   # sha256sum of https://github.com/DNSCrypt/dnscrypt-proxy/archive/2.1.16.tar.gz
   ARG DNSCRYPT_PROXY_SHA256="7ba5aa76d3fdc6fbb667689ba13d8ac3e66be27655695a9d412e5ad4afe34f8d"
   ```

   DNSCrypt does not publish a `.sha256` companion file for the GitHub source
   archive, so compute it locally from the tarball you're pinning:

   ```bash
   curl -sL https://github.com/DNSCrypt/dnscrypt-proxy/archive/X.Y.Z.tar.gz | sha256sum
   ```

2. Run the following docker build command to regenerate the bundled example
   configuration files from the new upstream source.

   ```bash
   export DOCKER_BUILDKIT=1
   export DOCKER_CLI_EXPERIMENTAL=enabled
   docker build . --target conf-example --output ./config
   ```

3. [Build](#building) and [test](#testing) changes locally.

4. Commit and push changes to `Dockerfile` and any regenerated `config/example-*`
   files.

For the current pattern, see recent commits touching the dnscrypt-proxy `ARG`
lines:

```bash
git log --oneline -- Dockerfile | grep -i dnscrypt-proxy | head -5
```

## Tagging a release (maintainers only)

This section applies to repository maintainers. Contributors do not need to tag
releases — the maintainer will tag once your bump PR is merged.

After a dnscrypt-proxy bump PR is merged to `main`, tag the release on the
**content commit** (the "Update dnscrypt-proxy to release X.Y.Z" commit), not
the merge commit GitHub creates on top.

```bash
git fetch origin
# Find the content commit on origin/main
git log origin/main --grep='Update dnscrypt-proxy to release' --format='%H %s' -1

# Create a signed, annotated tag with the version as the message body
git tag -s vX.Y.Z -m "vX.Y.Z" <content-commit-sha>

# Push the tag
git push origin vX.Y.Z
```

Tags follow `vMAJOR.MINOR.PATCH` matching the upstream dnscrypt-proxy version,
are annotated (not lightweight), and are GPG-signed. The tag message body is
the bare version string — no release notes.

## License

By contributing, you agree that your contributions will be licensed under its
[Software License](LICENSE).

## References

This document was adapted from the open-source contribution guidelines for
[Facebook's Draft](https://github.com/facebook/draft-js)
