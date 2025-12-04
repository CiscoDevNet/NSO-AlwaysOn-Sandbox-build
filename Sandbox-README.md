- [Cisco NSO Always-On Sandbox Lab](#cisco-nso-always-on-sandbox-lab)
  - [What's Inside?](#whats-inside)
  - [Access Details](#access-details)
  - [How to Access](#how-to-access)
  - [Services](#services)
  - [Network Topology](#network-topology)
  - [Need More?](#need-more)
  - [Additional Resources](#additional-resources)

# Cisco NSO Always-On Sandbox Lab

Welcome to the NSO Always-On Sandbox Lab.

The NSO Always-On Sandbox Lab is your playground for testing Northbound APIs. The Lab is _Always On_, ready for your quick testing needs.

## What's Inside?

NSO is a high-quality tool for automating and orchestrating network services across both physical and virtual elements. It's compatible with hundreds of devices from a wide range of networking and infrastructure vendors. With NSO, you can add, change, and delete services smoothly, without causing disruption to the overall service. NSO applies all these changes immediately.

In this Always-On Sandbox Lab, you find a production NSO server managing a multiplatform network, which consists of Netsim devices for NX-OS, IOS XE, IOS XR, and ASA.

## Access Details

Accessing this sandbox is slightly different than previous generations of always-on labs. We no longer provide static usernames and passwords for general use. To gain access, launch the sandbox topology in the portal. This will generate unique credentials for each user.

Creating a reservation:

- Hit the Launch button on the NSO Always-On sandbox tile.
- Select a duration. Your credentials will last this length.
- Hit launch again. The sandbox will bein spinning up.
- New credentials will be created and tested for Web, SSH, NETCONF and RESTCONF.
- Once Active (1-2 mins), the credetails are displayed in the Quick Access Tab.
- A unique password is generated each time a new reservation is made.

This is a SHARED Resource!!

This is an Always-On sandbox is designed for simple automation use cases and is accessed by many users simultanously.

Full admin privileges are afforded to each user. Please do NOT run commands that affect connectivity. Doing so will cause the switch to reset back to a base configuration

## How to Access

You can interact with Cisco NSO through several Northbound interfaces:

- SSH
- NETCONF
- RESTCONF
- HTTPS GUI

Access the NSO instance using the following public URL:

- Address: `sandbox-nso-1.cisco.com`
- Username: `<your-username-from-portal>`
- Password: `<your-password-from-portal>`
- HTTPS port for NSO GUI/API: `443`
  - <https://sandbox-nso-1.cisco.com>
- SSH port for direct NSO access: `2024`
  - `ssh -p 2024 <your-username-from-portal>@sandbox-nso-1.cisco.com -oKexAlgorithms=+diffie-hellman-group14-sha1`

## Services

Two packages are installed on the NSO instance.

- The `Router` package configured `DNS`, `SYSLOG`, `NTP` setting on the Netsim devices. Use it to test Northbound calls.

## Network Topology

The Always-On Sandbox uses Netsim devices. Here's a snapshot of the devices list:

```plaintext
developer@ncs# show devices list
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
developer@ncs#
```

## Need More?

If you require a more realistic environment, check out the NSO reservable Sandbox. It comes with a CML instance for testing with virtual devices.

Enjoy exploring the NSO Sandbox Lab.

## Additional Resources

Look at these resources about Cisco NSO. You find an active developer community, code samples, Learning Labs, and more.

- [NSO Developer Hub](https://community.cisco.com/t5/nso-developer-hub/ct-p/5672j-dev-nso)
- [NSO Overview](https://developer.cisco.com/site/nso/)
- [NSO Documentation](https://developer.cisco.com/docs/nso/)
- [NSO Learning Labs](https://developer.cisco.com/learning/tracks/get_started_with_nso/)
- [NSO code repositories on Code Exchange](https://developer.cisco.com/codeexchange/search/?products=NSO)
- [NSO Sample API Requests on Postman](https://www.postman.com/ciscodevnet/workspace/cisco-devnet-s-public-workspace/folder/3224967-59ba2ee6-4fd2-4b77-b6f9-21af4a3af33b?action=share&creator=2201640&ctx=documentation)
- [Sandbox Support](https://communities.cisco.com/community/developer/sandbox)
