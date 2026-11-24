# GitHub Release Checklist

## Safe-to-publish content

- RTL, testbenches, constraints, Tcl/shell scripts, Python/Qt host code.
- Educational documentation, architecture diagrams in text, and evidence
  logs that contain no credentials.
- Small reproducible bitstream artifacts with SHA-256 checksums.

## Never publish

- AMD installer archives, authentication tokens, `.lic` files, passwords, or
  private account data.
- Local toolchain installations under `/home/dmehta/openxc7` or
  `/home/dmehta/AMD_FPGA`.
- Generated logs containing access tokens or machine secrets.

## Release evidence

Every release should name the exact source commit, board part, tool version,
clock constraint, simulation command, timing report, and hardware observation.
The repository uses conservative labels so a future reader can distinguish
simulation, openXC7 implementation, Vivado implementation, and physical board
verification.
