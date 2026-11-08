# Architecture

Animal Taxonomy is a native macOS SwiftUI application packaged from a Swift
Package executable. It uses iNaturalist as its taxonomy and animal-photo
source; an internet connection is required for lookups and images.

## Application components

```mermaid
flowchart TD
    User[User]
    View[ContentView<br/>SwiftUI interface]
    Model[TaxonomyViewModel<br/>Main-actor UI state]
    Client[INaturalistClient<br/>HTTP and JSON decoding]
    API[iNaturalist API<br/>api.inaturalist.org/v1]
    Models[Taxon and TaxonPhoto<br/>Decodable response models]
    Image[AsyncImage<br/>loads HTTPS photo URL]

    User --> View
    View <-->|queries, matches, selection, loading, errors| Model
    Model -->|search, details, subspecies| Client
    Client -->|HTTPS JSON requests| API
    API -->|taxa responses| Client
    Client --> Models
    Models --> Model
    Model -->|selected taxon's medium photo URL| Image
    Image -->|HTTPS image request| Photo[iNaturalist photo storage]
```

### Responsibilities

- **`ContentView`** renders search, candidate choices, taxonomy ranks, subspecies
  options, and the selected animal's photo. `AsyncImage` displays a loading
  state, a placeholder when the image is unavailable, and the photo attribution
  and iNaturalist source link.
- **`TaxonomyViewModel`** owns observable UI state, filters search results to
  animals, resolves exact and unambiguous matches, and loads subspecies for
  species-level results.
- **`INaturalistClient`** constructs requests to the iNaturalist API, checks
  HTTP status, and decodes taxonomy responses. Request failures are surfaced to
  the view model and shown in the UI.
- **`Taxon`, `TaxonAncestor`, and `TaxonPhoto`** decode taxonomy, rank ancestry,
  and photo metadata. Taxon ancestry supplies the displayed ranks; missing ranks
  are not inferred.

## Lookup flow

```mermaid
sequenceDiagram
    actor User
    participant UI as ContentView
    participant VM as TaxonomyViewModel
    participant Client as INaturalistClient
    participant API as iNaturalist API
    participant Photos as Photo storage

    User->>UI: Enter animal name and identify
    UI->>VM: search()
    VM->>Client: searchAnimals(name)
    Client->>API: GET /taxa/autocomplete
    API-->>Client: Taxon candidates
    Client-->>VM: Animal candidates
    alt Exact or single match
        VM->>Client: taxon(id)
        Client->>API: GET /taxa/{id}
        API-->>Client: Taxon, ancestry, photo metadata
        Client-->>VM: Selected taxon
        opt Selected taxon is a species
            VM->>Client: subspecies(of: id)
            Client->>API: GET /taxa?parent_id=...&rank=subspecies
            API-->>Client: Subspecies candidates
            Client-->>VM: Subspecies choices
        end
        VM-->>UI: Classification and optional type choices
        opt Taxon has a photo URL
            UI->>Photos: Load medium photo over HTTPS
            Photos-->>UI: Image
        end
    else Multiple matches
        VM-->>UI: Candidate choices
        User->>UI: Select a candidate
        UI->>VM: select(taxon)
        Note over VM,API: Selection continues with GET /taxa/{id}
    else No matches
        VM-->>UI: No-match message
    end
```

## Finder app packaging

```mermaid
flowchart LR
    Package[Package.swift]
    Script[Scripts/package-app.sh]
    SwiftBuild[swift build -c release]
    Packer[Scripts/package-app.swift]
    Executable[.build/release/SciClassification]
    Bundle[dist/Animal Taxonomy.app]
    Contents[Contents/MacOS<br/>Contents/Resources<br/>Contents/Info.plist]
    Icon[Generated AppIcon.icns]

    Package --> SwiftBuild
    Script --> SwiftBuild
    SwiftBuild --> Executable
    Script --> Packer
    Executable --> Packer
    Packer --> Bundle
    Packer --> Contents
    Packer --> Icon
    Icon --> Contents
```

The package script builds a release executable, then the AppKit-based packaging
tool creates the `.app` bundle, macOS icon, and `Info.plist`. The `dist/`
directory is generated output and is excluded from Git.

## Project layout

```text
Package.swift
Sources/SciClassification/
  main.swift
  ContentView.swift
  TaxonomyViewModel.swift
  INaturalistClient.swift
  TaxonomyModels.swift
Scripts/
  package-app.sh
  package-app.swift
dist/                         generated app bundle (gitignored)
```
