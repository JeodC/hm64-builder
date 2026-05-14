# HM64 Autobuilder

## THIS REPOSITORY IS RETIRED

I have moved the autobuild functions of this repository to my own [RHH-Ports](https://github.com/JeodC/RHH-Ports) repository. As such, the GitHub actions in this repository no longer run. This repository is archived as a reference for others wishing to build arm64 targets, but since it's no longer maintained the build steps may drift out of date.

## Info
This was a simple repository that polled HarbourMasters ports for new release tags (twice per day) and, when a new release was found, built it for linux aarch64. It then notified a separate repository of the new release, and *that* repository took the release zips and updated the ports.

The releases contained binaries and required files for the following:

- Ship of Harkinian (used with [my Ship of Harkinian port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/soh))
- 2 Ship 2 Harkinian (used with [my 2Ship2Harkinian port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/soh2))
- Starship (used with [my Starship port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/starship))
- Ghostship (used with [my SM64-Ghostship port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/sm64-ghostship))
- SpaghettiKart (used with [my SpaghettiKart port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/spaghettikart))
- PaperBoat (not released yet)

Releases from this repository used the same descriptions as the upstream releases.