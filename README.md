# PearAI

Welcome to PearAI, an innovative AI-powered application designed to enhance your productivity and streamline your workflow. This guide will help you set up PearAI on NixOS and ensure a smooth installation process.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [NixOS Configuration](#nixos-configuration)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

Before installing PearAI, ensure your system meets the following requirements:

- **NixOS**: Make sure you are running NixOS.
- **Unfree Packages**: Enable unfree packages in your NixOS configuration.

## Installation

To install PearAI, follow these steps:
## NixOS Configuration

To integrate PearAI into your NixOS setup, you need to modify your `configuration.nix` file. Follow these steps:

1. **Enable Unfree Packages**:
 Add the following line to your `configuration.nix` to allow unfree packages:
```bash
{ config, pkgs, ... }:

{
nixpkgs.config.allowUnfree = true;
}
```
2. **Install `steam-run`**:
 Ensure `steam-run` is available, as it is required for running PearAI:
```bash
{ config, pkgs, ... }:

{
environment.systemPackages = with pkgs; [
steam-run
];
}
```
3. **Rebuild Your System**:
 Apply the changes by rebuilding your NixOS configuration:
```bash
sudo nixos-rebuild switch
```

## PearAI Installation

1. **Clone the Repository**:
```bash
git clone https://github.com/InSelfControll/PearAI.git
cd PearAI
```
2. **Run the Installation Script**:
 Execute the installation script using bash:
```bash
bash pearai_manager.sh
```
## Usage

Once installed, you can start using PearAI by following the instructions provided in the application. For detailed usage guidelines, refer to the user manual or help section within the app.

## Contributing

We welcome contributions from the community! If you would like to contribute to PearAI, please fork the repository and submit a pull request. For major changes, please open an issue first to discuss what you would like to change.

## License

PearAI is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

---

Thank you for choosing PearAI. We hope it significantly enhances your productivity and experience!

