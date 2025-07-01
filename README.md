# NSO Always-On Sandbox Build

This repository provides the tools and scripts necessary to build and deploy the Cisco NSO (Network Services Orchestrator) Always-On Sandbox hosted on [DevNet](https://devnetsandbox.cisco.com/DevNet/). NSO is Cisco's network automation and orchestration platform that enables intent-based networking through service modeling and configuration management.

The sandbox sets up a fully operational NSO instance with sample devices and packages for testing and development purposes. The Always-On Sandbox is **read-only**.

This repository is publicly available, offering the community insight into part of the sandbox setup process. The remaining steps are handled by a CI/CD pipeline within the sandbox infrastructure, which is not included here.

## 🚀 Overview

The NSO Always-On Sandbox Build project enables:

- **Version management** through git tags aligned with NSO releases.
- **Automated container builds** of NSO with pre-configured services and devices.
- **Sandbox deployment** with production-ready docker-compose configuration.
- **Development environment** for testing NSO automation and services.

> [!IMPORTANT]
> This repository **does not include** the NSO container image binary. You must download it separately from [software.cisco.com](https://software.cisco.com/download/home).

## 📋 Update NSO Version

Most of the time, you will only need to update the NSO version in the `sandbox_env_vars.sh` file. This file contains environment variables used during the build and deployment process.

### 1. Update NSO Version

Update the NSO version in [sandbox_env_vars.sh](sandbox_env_vars.sh#L2):

```bash
# NSO Version
NSO_VERSION=6.4.4.1
```

### 2. Download NSO Binary

> [!NOTE]
> Download the corresponding NSO container image from [software.cisco.com](https://software.cisco.com/download/home) and **place it in the project root**.

```bash
# Example filename (version should match sandbox_env_vars.sh)
nso-<version>.container-image-prod.linux.x86_64.signed.bin
```

### 3. Verify Image Information

Use the `check-image-info` target to ensure the `BASE_IMAGE` and `NSO_VERSION` variables match what you downloaded against the `sandbox_env_vars.sh`.

If they don't match, the rest of the scripts will fail. Update accordingly.

```bash
make check-image-info
```

### 4. Verify Local Build

Make sure your build works.

Extract and load the NSO image:

```bash
make extract-nso-image
make load-nso-image
```

Build and run locally:

```bash
make all
```

Check the logs to make sure NSO starts correctly:

```bash
make follow
```

> [!TIP]
> Always verify your build before creating tags to ensure everything works correctly.

Access the container:

```bash
make cli
```

### 5. Create Version Tag

Clean up temporary files:

```bash
make cleanup-temp-files
```

Commit changes and create a git tag with the NSO version:

```bash
git add .
git commit -m "Update to NSO version 6.4.4.1"
git tag v6.4.4.1
git push origin main --tags
```

## 🚀 Sandbox Deployment Workflow

### For Sandbox Team

1. **Clone the repository** with the specific NSO version tag:

   ```bash
   git clone --branch v6.4.4.1 <repository-url>
   cd NSO-AlwaysOn-Sandbox-build
   ```

2. **Download** the corresponding NSO container image from [software.cisco.com](https://software.cisco.com/download/home) and **place it in the project root**. The filename should be: `nso-<version>.container-image-prod.linux.x86_64.signed.bin`.

3. **SSL Certificates for Sandbox**

   The SSL certificates must be placed in the correct directory structure before starting the container.

   ```bash
   mkdir -p ${HOME}/ssl/cert
   # Place your certificates:
   # ssl/cert/host.cert
   # ssl/cert/host.key
   # ssl/cert/host.csr (optional)
   ```

> [!NOTE]
> The docker-compose configuration will automatically mount these certificates to the NSO container.

4. **Add the admin password**

   Add the admin password to a `.env` file in the root directory:

   ```bash
   echo "ADMIN_PASSWORD=<admin_password>" > .env
   ```

5. **Build for sandbox deployment**

   ```bash
   make extract-nso-image
   make load-nso-image
   make check-image-info
   ```

   ```bash
   make build-deploy-sandbox
   ```

6. **Clean up** temporary files after deployment:

   ```bash
   make cleanup-temp-files
   ```

## 🛠️ Container Build Process

The container is built with the following components to provide a complete NSO automation environment:

### Base Configuration

- **NSO Version**: Dynamically set via `sandbox_env_vars.sh`.
- **Base Image**: `cisco-nso-prod` (extracted from signed binary).
- **User**: `developer` with password `Services4Ever` (read-only access).
- **Exposed Ports**: 443 (HTTPS), 2024 (SSH), 8080 (HTTP only locally).

### Automated Build Steps

The Dockerfile performs the following automation steps:

1. **User Setup**: Creates a `developer` user with proper permissions.
2. **Configuration**: Copies NSO configuration files to correct locations.
3. **NED Installation**: Links required Network Element Drivers (NEDs).
4. **Package Compilation**: Builds the router package with YANG models.
5. **Environment Setup**: Configures bash aliases and PATH variables.

### Pre-installed Components

#### Network Devices (Netsim)

The container includes the following netsim devices:

<details>
<summary>Click to view complete device list</summary>

```plaintext
admin@ncs# show devices list
NAME             ADDRESS    DESCRIPTION  NED ID               ADMIN STATE
-------------------------------------------------------------------------
core-rtr00       127.0.0.1  -            cisco-iosxr-cli-3.5  unlocked
core-rtr01       127.0.0.1  -            cisco-iosxr-cli-3.5  unlocked
core-rtr02       127.0.0.1  -            cisco-iosxr-cli-3.5  unlocked
dist-rtr00       127.0.0.1  -            cisco-ios-cli-3.8    unlocked
dist-rtr01       127.0.0.1  -            cisco-ios-cli-3.8    unlocked
dist-rtr02       127.0.0.1  -            cisco-ios-cli-3.8    unlocked
dist-sw00        127.0.0.1  -            cisco-nx-cli-3.0     unlocked
dist-sw01        127.0.0.1  -            cisco-nx-cli-3.0     unlocked
dist-sw02        127.0.0.1  -            cisco-nx-cli-3.0     unlocked
edge-firewall00  127.0.0.1  -            cisco-asa-cli-6.6    unlocked
edge-firewall01  127.0.0.1  -            cisco-asa-cli-6.6    unlocked
edge-sw00        127.0.0.1  -            cisco-ios-cli-3.8    unlocked
edge-sw01        127.0.0.1  -            cisco-ios-cli-3.8    unlocked
internet-rtr00   127.0.0.1  -            cisco-ios-cli-3.8    unlocked
internet-rtr01   127.0.0.1  -            cisco-ios-cli-3.8    unlocked
admin@ncs#
```

</details>

#### NSO Service Packages

**Router Package** - A complete service package example including:

- **DNS server configuration** - Automated DNS setup.
- **NTP server configuration** - Time synchronization services.
- **Syslog server configuration** - Centralized logging.
- **YANG models** - Structured configuration templates.
- **Service templates** - XML templates for device configuration.

> [!TIP]
> The router package demonstrates NSO best practices for service creation, including YANG modeling, XML templates, and device group targeting.

## 🔌 Access Information

Go to <https://devnetsandbox.cisco.com/DevNet/> for sandbox access, launch the NSO Always-On Sandbox, and connect to the container.

### Container Access

- **SSH**: Port `2024`
- **HTTPS/GUI**: Port `443`

### Credentials

- **Username**: `developer`
- **Password**: `Services4Ever`
- **Access Level**: Read-only.

## 📋 Development Notes

> [!NOTE]
> The NSO configuration file is named `ncs.conf.xml` (instead of `ncs.conf`) to enable proper XML syntax highlighting in editors.

- During container build, it's copied to the correct location as `ncs.conf`.
- All scripts in `deploy-to-sandbox/` are designed to be executed in the sandbox environment.
- The project supports both Docker and Podman container engines.

## 📞 Support

For sandbox-related issues, visit the [DevNet Sandbox community](https://community.cisco.com/t5/devnet-sandbox/bd-p/4426j-disc-dev-devnet-sandbox).

For NSO-specific questions, refer to the [NSO Developer Hub](https://community.cisco.com/t5/nso-developer-hub/ct-p/5672j-dev-nso).
