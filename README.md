# Animal Taxonomy for macOS

A Finder-launchable macOS SwiftUI app for looking up animal classifications from iNaturalist. Search using a common or scientific name; when a species has recognized subspecies, the app offers those as follow-up choices. For example, search for “tiger” and choose Bengal Tiger, or search for “Tiger Bengal” directly.

The result includes an animal photo when available. Photo attribution (including any license information provided by iNaturalist) and a link to the taxon’s iNaturalist page appear below the image; if the photo cannot be loaded, the app shows a placeholder. The classification includes kingdom, phylum, class, order, superfamily, family, and type (the matched taxonomic rank). A rank that iNaturalist does not provide is shown as “Not listed by source” rather than inferred.

See [ARCHITECTURE.md](ARCHITECTURE.md) for component, lookup-flow, and app-packaging diagrams.

## Build the Finder app

Requires macOS 13 or later and Swift 6 with the Xcode Command Line Tools. From this directory, run:

```bash
./Scripts/package-app.sh
```

This builds the release executable and packages it as `dist/Animal Taxonomy.app`, including a generated macOS icon and `Info.plist`. Open the `.app` from Finder, or launch it from Terminal:

```bash
open "dist/Animal Taxonomy.app"
```

The app needs an internet connection to query the iNaturalist API. The locally built app is not signed or notarized for distribution to other Macs.

## Run from the command line

For development, you can still build or run the Swift package directly:

```bash
swift build
swift run
```
