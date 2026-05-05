# Redis Pro

English | [简体中文](./README.zh_CN.md) 

![Swift5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange.svg?style=flat)
[![release](https://img.shields.io/github/v/release/cmushroom/redis-pro?include_prereleases)](https://github.com/cmushroom/redis-pro/releases)
![platforms](https://img.shields.io/badge/Platforms-macOS%20-orange.svg?style=flat)

## Intro
* **Redis Pro** is a modern, lightweight, and high-performance Redis/Valkey management tool for macOS.
* Built with **SwiftUI** and a premium **Liquid Glass** aesthetic (glassmorphism), it provides a native and fluid user experience.
* Supports **Valkey** and **Redis** (3.x to 7.x) with high-performance NIO-based architecture.

## Features
- [x] **Liquid Glass UI**: Modern glassmorphism design with optimized dark mode support.
- [x] **Hierarchical Key Navigation**: Native tree view with virtualization for lightning-fast browsing of large datasets.
- [x] **SSH Tunneling**: Secure connection support via built-in SSH tunneling.
- [x] **Valkey & Redis Support**: Fully compatible with Valkey and Redis 3.x-7.x.
- [x] **Client Management**: List and terminate client connections.
- [x] **Real-time Monitoring**: Slow log and server info visualization.
- [x] **Batch Operations**: Efficiently delete keys in bulk.
- [x] **TCA Architecture**: Robust state management using The Composable Architecture.

## Installation
* **Direct Download**: Download the latest DMG from the [releases page](https://github.com/cmushroom/redis-pro/releases).
* **Homebrew**:
    ```bash
    brew install redis-pro
    ```

## Platform
* Supports macOS 11.0+ (Intel and Apple Silicon).

## Roadmap
- [ ] Terminal / CLI integration
- [ ] SSH key-based authentication
- [ ] iPadOS support

## Dependencies
* [ValkeySwift](https://github.com/valkey-io/valkey-swift): High-performance NIO-based Redis/Valkey client.
* [swift-log](https://github.com/apple/swift-log): Standard logging for Swift.
* [Puppy](https://github.com/sushichop/Puppy): Flexible logging backend.
* [SwiftJSONFormatter](https://github.com/luin/SwiftJSONFormatter): JSON formatting.
* [TCA](https://github.com/pointfreeco/swift-composable-architecture): State management.
* [swift-nio-ssh](https://github.com/apple/swift-nio-ssh): Native SSH support.

## Snapshot
login
<img width="1124" alt="0" src="https://user-images.githubusercontent.com/2920167/125376590-ec6fb500-e3bd-11eb-8f6b-140c32578e8c.png">

home
<img width="1124" alt="1" src="https://user-images.githubusercontent.com/2920167/125376643-0e693780-e3be-11eb-92fa-9c13dcc26f78.png">

setting
<img width="1128" alt="2" src="https://user-images.githubusercontent.com/2920167/125376658-15904580-e3be-11eb-94cf-8590a550ea1a.png">

Info
<img width="1124" alt="3" src="https://user-images.githubusercontent.com/2920167/125376733-39538b80-e3be-11eb-896d-72cacb469540.png">

Clients
<img width="1124" alt="4" src="https://user-images.githubusercontent.com/2920167/125376767-4a9c9800-e3be-11eb-84b3-33c2c1c846fc.png">


dark mode
<img width="1124" alt="5" src="https://user-images.githubusercontent.com/2920167/125376789-538d6980-e3be-11eb-9267-6a451597f983.png">
<img width="1124" alt="5" src="https://user-images.githubusercontent.com/2920167/125376778-4f614c00-e3be-11eb-8c11-7195e4cdb665.png">
