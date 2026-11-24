# Vivado 2026.2 Installation and Licensing

## Current machine status

The downloaded installer is:

```text
/home/dmehta/Downloads/FPGAs_AdaptiveSoCs_Unified_SDI_2026.2_1109_1430_Lin64.bin
```

It passes AMD archive-integrity verification. The attempted user-owned install
location is `/home/dmehta/AMD_FPGA/2026.2`.

The installer currently stops before installation because AMD 2026.2 requires
an authentication token. The browser login and the command-line installer are
separate sessions; the CLI cannot read the ChatGPT browser's AMD cookies. No
password, token, or license file is stored in this repository.

## Basic license path

For Vivado 2026.1 and newer, AMD documents the free Vivado BASIC tier. Artix-7
devices are included in the BASIC device support table. Generate a certificate
license from the AMD Product Licensing site while signed into the AMD account,
download the `.lic` file, and place it in `/home/dmehta/.Xilinx/` or load it
with Vivado License Manager. See AMD's [licensing FAQ](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/licensing-faq.html),
[Product Licensing site instructions](https://docs.amd.com/r/en-US/ug973-vivado-release-notes-install-license/Accessing-the-AMD-Product-Licensing-Site),
and [license installation instructions](https://docs.amd.com/r/en-US/ug973-vivado-release-notes-install-license/Install-Certificate-Based-Node-Locked-License-Key-File).

The existing `/home/dmehta/.Xilinx/trial.lic` is a historical 30-day trial
whose expiration date was 3-Feb-2026; it is not a valid license for the current
date.

## Authentication token

AMD's supported command is:

```bash
cd /home/dmehta/Basys3
/home/dmehta/Downloads/FPGAs_AdaptiveSoCs_Unified_SDI_2026.2_1109_1430_Lin64.bin \
  --nox11 -- --batch AuthTokenGen
```

This command prompts for the AMD account email and password. Enter those
directly into the local terminal only; never paste them into chat or a file.
After the installer creates its token, rerun:

```bash
/home/dmehta/Downloads/FPGAs_AdaptiveSoCs_Unified_SDI_2026.2_1109_1430_Lin64.bin \
  --nox11 -- --agree XilinxEULA,3rdPartyEULA --batch Install \
  --config /home/dmehta/Basys3/installer/vivado_artix7_config.txt
```

The checked-in configuration selects Vivado and Artix-7 only, disables shortcut
creation, and installs to `/home/dmehta/AMD_FPGA/2026.2`.

## Post-install verification

```bash
source /home/dmehta/AMD_FPGA/2026.2/Vivado/settings64.sh
export XILINXD_LICENSE_FILE=/home/dmehta/.Xilinx
vivado -version
vivado -mode batch -source /home/dmehta/Basys3/scripts/build_bitstream.tcl
```

Expected evidence is a Vivado version, a successful Basys3 synthesis and
implementation run, a timing summary with no negative setup/hold slack, and a
generated `.bit` file. The openXC7 flow remains available as a reproducible
fallback and does not replace those Vivado reports.
