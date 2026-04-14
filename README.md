# HM64 Autobuilder
This is a simple repository to automatically obtain new release tags (twice per day) and if there is a new release, build it for linux aarch64. The repository then notifies a separate repository of a new release, and *that* repository takes the release zips and updates the ports.

The releases contain binaries and required files for the following:

- Ship of Harkinian (used with [my Ship of Harkinian port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/soh))
- 2 Ship 2 Harkinian (used with [my 2Ship2Harkinian port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/soh2))
- Starship (used with [my Starship port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/starship))
- Ghostship (used with [my SM64-Ghostship port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/sm64-ghostship))
- SpaghettiKart (used with [my SpaghettiKart port](https://github.com/JeodC/RHH-Ports/tree/main/ports/released/harbourmasters64/spaghettikart))
- PaperBoat (not released yet)

Releases from *this* repository use the same descriptions as the upstream releases.

Thanks to beniamino for the actions build which inspired this repository.
