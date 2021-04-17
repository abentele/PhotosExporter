March 2021, Andreas Bentele

# PhotosExporter

This is a headless program (with command line interface) to export all photos of the macOS Photos library to a filesystem folder. Like Apple's Time Machine, it backup's the data in folders containing full backups, while using hard links to minimize disk usage.

You may ask: why another backup solution in addition to Time Machine, which already backups my Photos library?
The answer is: Time Machine is one of the best backup solutions I know. But the macOS Photos Library has it's very special database structure - it's in parts file system based, but not intended to open it with any other program than Apple's Photos. Time Machine does nothing else but backup this database to an external disk. Backups are not portable to another system other than a Mac with Photos.

Using Time Machine to backup my photos is what I've done for many years till I lost some of the most important photos in my Photos library (maybe by own mistake). Because of Time Machine automatically removes old backups to get new disk space, the photos were also deleted from my backups. Fortunately I found the photos in a backup of my old Aperture library. This opened my eyes, so I decided to implement a small program which implements the following requirements, partly inspired by how Time Machine works:

* export all original and modified photos
* generate a human readable folder structure containing all folders and albums from the Photos library (usable with any other program on any platform)
* full exports: each export creates a new folder named after the current date
* make use of hard links whenever possible instead of copying files, to minimize additional disk usage e.g. due to consecutive full backups or photos contained in several albums
* never delete old backups (I want to be able to decide which old backups should be deleted, or if I want to buy a disk with more space for my backups)
* performance and robustness: the backup of my around 30.000 photos should be done in less than an hour (currently it takes around 30 minutes)
* keep it simple: no complex interface to configure things, no complex configuration
* provide two export modes: 1. Time Machine like backup, 2. snapshot export with no extra disk usage if export is on same file system

There are two possible general use cases:
* **SnapshotPhotosExporter**: export all your photos, e.g. to share them with other programs or devices like your TV or other non-Apple devices, share them in the cloud etc.; if the export folder is on the same file system as the Photos Library, there is no extra disk usage
* **IncrementalPhotosExporter**: backup all your photos while keeping the previous backups, like with Time Machine (I would suggest to add a cron job to trigger it daily or weekly)

You also can combine both: export to local disk using SnapshotPhotosExporter. Make a backup using Time Machine to an external disk. Then use the IncrementalPhotosExporter to export the photos to the same external disk while using hard links to the already exported photos in the Time Machine backup instead of copying all photos again (see parameter baseExportPath for more details). 

I believe some other people who think backups are very important could make use of it as well, so I've decided to make the code open source. Any feedback is appreciated, especially pull requests with improvements.


# History

This program was not my first try. I've tried out some other solutions before, that didn't work at all:

* export photos within the Photos app; this didn't work because of several annoying bugs of Photos (I've already reported the bugs to Apple). Also the export in Photos doesn't fulfill the requirements discussed above.
* searched for another existing external solution including scripts, Objective-C or Swift based programs posted in the internet (and github); there were no real existing solutions but only some discussions on the same topic which showed me that this was not only a problem of me. I refused to use solutions which depend highly on re-engineering the photos sqlite database, because of they tend to break with each new Photos update.
* then I've written a script using the Applescript language which automates the Photos app and calls shell scripts to do the file system based things; while the script was rather expressive and short, it observed very bad performance and bad robustness because of annoying bugs in the Photos app and Apple's scripting architecture as well. Also the Photos API was rather limited at the time I used it.

The next step was to re-implement everything using Apple's latest programming language [Swift](https://developer.apple.com/swift/) and the [MediaLibrary Framework](https://developer.apple.com/documentation/medialibrary). The result was very robust, performant and maintainable compared to the previous solutions and worked with macOS Mojave.

Starting with macOS Catalina the MediaLibrary Framework had a bug which causes keywords cannot be requested from the Photos library any more. With macOS Big Sur, the MediaLibrary became deprecated. Therefore I've replaced the MediaLibrary Framework with the [PhotoKit](https://developer.apple.com/documentation/photokit). This framework has also some drawbacks, e.g. the performance is not really optimal and some information cannot be requested from the Photos library, e.g. keywords. To compensate for this, keywords and other data are loaded directly from the Photos sqlite database.  


# Usage

Currently the program doesn't have any arguments and no user interface (I've started to work on it, but it's far from being usable).

It reads photos from the System Photos Library, not any other Photos Library.

To use it:
* create a YAML file ~/Library/Application Support/PhotosExporter/PhotosExporter.yaml and edit the content, e.g.:
```
---
plans:
  -
    type: SnapshotFileSystemExport
    enabled: false
    name: My export
    mediaObjectFilter:
      keywordWhiteList:
        - test
      keywordBlackList:
    targetFolder: /Users/<username>/Pictures/Fotos-Export/test
    deleteFlatPath: false
    exportOriginals: true
```
For settings attributes see the description below.
* checkout the github project, open it in Xcode. Then build and run the application.

Normally, the exporter adds the timestamp of a photo to the exported photo's filename. Use the keyword "export-no-date" in Photos to omit the timestamp in the filename.

If you move the exported folder, be sure to recreate the `Latest` link, because it would be broken after moving the folders.

## Settings of the exporter

All settings can be applied both to the SnapshotPhotosExporter and to IncrementalPhotosExporter.

* plans: each plan is a configuration to export your photos. You can add one or multiple plans to export
* type: either `SnapshotFileSystemExport` or `IncrementalFileSystemExport`
* enabled: `true` or `false` - can be used to disable export configuration
* mediaObjectFilter: if defined, only photos based on whitelist / blacklist configuration are exported:
** keywordWhiteList: list with keywords of photos which should be exported
** keywordBlackList: list with keyword of photos which should not be exported
* exportOriginals: set to false if original photos should not be exported (default: true); original photos are the photos which are not edited
* exportCurrent: set to false if current photos should not be exported (default: true); current photo is either the original photo (e.g. in RAW format) if the photo isn't modified by the user, or the modified photo in jpeg format
* exportDerived: set to false if derived photos should not be exported (default: true); derived photos are the renderings (jpeg photos) which may contain user modifications
* targetFolder: the folder the photos should be exported to
* baseExportPath (only IncrementalPhotosExporter, optional parameter): the path to an already existing export folder on the same device; example: export all photos using SnapshotPhotosExporter to your local disk or SSD; create a backup using Time Machine; additionally export the photos using IncrementalPhotosExporter to the same device as your Time Machine backup. Then you would set the baseExportPath to the export folder within your Time Machine backup, to link the exported photos with the photos of your Time Machine backup to save disk space.
* deleteFlatPath: true if the .flat folders should be deleted after the export (default:true; disable deleting if you want to use the export folder as base for an incremental export, see parameter baseExportPath)

# Supported platforms

* macOS 11 "Big Sur" (tested by the maintainer)

# Implementation

The program starts with reading all metadata of the [System Photos Library](https://support.apple.com/en-us/HT204414). This is implemented in [PhotosMetadataReader.swift](PhotosExporter/photolibrary-access/PhotosMetadataReader.swift) using [PhotoKit](https://developer.apple.com/documentation/photokit) and SQL.

The rest is implemented in [PhotosExporter.swift](PhotosExporter/exporter/PhotosExporter.swift) and inherited classes [SnapshotPhotosExporter.swift](PhotosExporter/exporter/SnapshotPhotosExporter.swift) and [IncrementalPhotosExporter.swift](PhotosExporter/exporter/IncrementalPhotosExporter.swift).

The two implementations are different:
* [IncrementalPhotosExporter.swift](PhotosExporter/exporter/IncrementalPhotosExporter.swift): After loading the metadata, a folder `InProgress` is created. This is a temporary folder where the program copies all exported folders and files to; . After the export of all files has been succeeded, the folder is renamed to the current date formatted with the date pattern `yyyy-MM-dd HH-mm-ss`. Also a symbolic link (alias) to this folder named `Latest` is created to know which files to link on the next export. If an error occurs during the backup, the `InProgress` folder will be left, until the next run of the program finally deletes it.
* [SnapshotPhotosExporter.swift](PhotosExporter/exporter/SnapshotPhotosExporter.swift): it uses an `InProgress` folder, too. If the files of the Photos Library and the target folder are on the same file system, the files are not copied to the `InProgress` folder. Instead, hard links are created, to minimize disk usage. After the export of all files has been succeeded, the folder is renamed to `Snapshot`, while the old `Snapshot` folder is removed before.

The main part - exporting the albums and photos - is done in two phases: the first phase is to export all original and modified photos to a folder named `.flat`. The second phase creates all sub-folders based on the folders and albums in the Photos Library.

This screenshot should give an idea about the generated folder structure:
![](/doc/filesystem-structure.png)

While exporting media files to the `.flat` folder, the program checks if a file has been changed since the last export, and uses a hard link in case the file hasn't been changed. This is done by comparing the media file in the Photos Library with the corresponding file in the `Latest` folder. While a comparison by something like a MD5 or SHA checksum would be the preferred way to check if the file content has been changed, I've decided to implement a simple comparison based on the file size for performance reasons.

As you can see, the SnapshotPhotosExporter is highly optimized to always keep the export directory on the same file system. If you backup your disk with Time Machine, no extra disk space is required because of the hard links. If photos are modified within the Photos app (or Photos recalculates the photos e.g. because of changed algorithms), the photos in the export directory may also be changed. For using the photos with other devices or programs, this behavior will be what you need. For backups on external drives it wouldn't be sufficient - therefore the IncrementalPhotosExporter was designed.

