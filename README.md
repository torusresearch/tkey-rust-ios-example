# Web3Auth tKey iOS Example with Google verifier

[![Web3Auth](https://img.shields.io/badge/Web3Auth-SDK-blue)](https://web3auth.io/docs/sdk/core-kit/mpc-tkey-ios)
[![Web3Auth](https://img.shields.io/badge/Web3Auth-Community-cyan)](https://community.web3auth.io)

[Join our Community Portal](https://community.web3auth.io/) to get support and stay up to date with the latest news and updates.

This example demonstrates how to use Web3Auth's tKey in iOS.

## How to Use

### Download Manually

```bash
git clone https://github.com/torusresearch/tkey-rust-ios-example/tree/alpha
```

Install & Run:

```bash
cd tkey-ios-tss-example
# run project in Xcode
```

## Important Links

- [Website](https://web3auth.io)
- [Docs](https://web3auth.io/docs)
- [Guides](https://web3auth.io/docs/guides)
- [SDK / API References](https://web3auth.io/docs/sdk)
- [Pricing](https://web3auth.io/pricing.html)
- [Community Portal](https://web3auth.io/community)

# tKey iOS - (TSS) example application

This repository is an example application created by implementing the [MPC tkey iOS SDK](https://github.com/torusresearch/tkey-rust-ios/tree/alpha) and [CustomAuth swift SDK](https://github.com/torusresearch/customauth-swift-sdk/tree/alpha).
With this example app, you can test the various functions of the tkey SDK, and also google Social Login.

After complete building, you can login via your google account.
If you don't have tKey, you can make your own tkey account by clicking this button, using customAuth sdk.
If you already have your account, existing account can be used as well.

## Main Page

![mainPage](https://github-production-user-asset-6210df.s3.amazonaws.com/6962565/239817058-d3eb7adb-e6d7-4fc3-b36b-2772ccb20e1a.png)

### how to start

Once you have the final tkey from initialize and reconstruct tkey, you can test all the features.
The first time you run `Initialize and reconstruct tkey`, two shares will be created and the threshold will be set to two.
This means that both shares will be required for login. (2/2 setting).

On the other hand, if you log in with an existing account, you would need to have the saved shares for the reconstruction to succeed.

### TSS Demo

Click on TSS Demo button to test the TSS module.

![tssDemo Main Page](https://github-production-user-asset-6210df.s3.amazonaws.com/6962565/260435436-3bab93a2-c773-41c6-840b-210a9b8eb8bb.png)
![tssDemo default tss module](https://github-production-user-asset-6210df.s3.amazonaws.com/6962565/260435617-adfa8a87-dafc-4613-a01b-b7af04bbd61e.png)

### Reset Account (Critical)

If you are unable to recover your account, such as losing your recovery key, you can reset your account.
However, you will lose your existing private key, so please use this feature with extreme caution.
