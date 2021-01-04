March 2018, Andreas Bentele

# PhotosExporter

This is a headless program (with command line interface) to export all photos of the macOS Photos library to a filesystem folder. Like Apple's Time Machine, it backup's the data in folders containing full backups, while using hard links to minimize disk usage.

You may ask: why another backup solution in addition to Time Machine, which already backups my Photos library?
The answer is: Time Machine is one of the best backup solutions I know. But the macOS Photos Library has it's very special database structure - it's in parts file system based, but not intended to open it with any other program but Apple's Photos. Time Machine does nothing else but backup this database to an external disk. Backups are not portable to another system but a Mac with Photos.

Using Time Machine to backup my photos is what I've done for many years till I lost some of the most important photos in my Photos library (maybe by own mistake). Because of Time Machine automatically removes old backups to get new disk space, the photos were also deleted from my backups. Fortunately I found the photos in a backup of my old Aperture library. This opened my eyes, so I decided to implement a small program which implements the following requirements, partly inspired by how Time Machine works:

* export all original and modified photos
* generate a human readable folder structure containing all folders, albums, smart albums, moments, etc. from the Photos library (usable with any other program on any platform)
* full exports: each export creates a new folder named after the current date
* make use of hard links whenever possible instead of copying files, to minimize additional disk usage e.g. due to consecutive full backups or photos contained in several albums
* never delete old backups (I want to be able to decide which old backups should be deleted, or if I want to buy a disk with more space for my backups)
* performance and robustness: the backup of my around 30.000 photos should be done in less than an hour (currently it takes around 30 minutes); if it doesn't succeed, the program should at least let me know the error
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
* searched for another existing external solution including scripts, Objective-C or Swift based programs posted in the WWW; there were no real existing solutions but only some discussions on the same topic which showed me that this was not only a problem of me
* then I've written a script using the Applescript language which automates the Photos app and calls shell scripts to do the file system based things; while the script was rather expressive and short, it had very bad performance and bad robustness because of annoying bugs in the Photos app and Apple's scripting architecture as well. Also the Photos API was rather limited at the time I used it.

The final step was to re-implement everything using Apple's latest programming language [Swift](https://developer.apple.com/swift/) and the [MediaLibrary Framework](https://developer.apple.com/documentation/medialibrary). The result is a very robust, performant and maintainable solution compared to the previous solutions.


# Compilation
You have checkout the project, open it in Xcode and compile it. You are free to customize the code to your needs, but it's not required.

# Usage

Currently the program doesn't have any arguments and no user interface.

It will try to read a json config file from your Application Support directory. In case the config is not available the programm will create a default config file for you and print out information about where to save a customized config file from it.

Be sure the target path is on a file system which supports hard links. 

Then run the program with Xcode, or compile the project and use the executable to export your photos.

Normally, the exporter adds the timestamp of a photo to the exported photo's filename. Use the keyword "export-no-date" in Photos to omit the timestamp in the filename.

If you move the exported folder, be sure to recreate the `Latest` link, because it would be broken after moving the folders.

## Parameters in config file

The configuration file contains a list of exporters to be run. Each exporter has these parameters: 

* `exportCalculatedPhotos`: set to false if calculated photos (edited) should not be exported (default: true)
* `exportOriginalPhotos`: set to false if original photos (masters) should not be exported (default: true)
* `deleteFlatPathAfterExport` (ignored by incremental exporter): true if the `.flat` folders should be deleted after the export (default:true; disable deleting if you want to use the export folder as base for an incremental export, see parameter baseExportPath)
* `targetPath`: Directory where to put the exported folders and photos (needs to be on a volume supporting hard links)
* `baseExportPath` (only IncrementalPhotosExporter, optional parameter): the path to an already existing export folder on the same device; example: export all photos using SnapshotPhotosExporter to your local disk or SSD; create a backup using Time Machine; additionally export the photos using IncrementalPhotosExporter to the same device as your Time Machine backup. Then you would set the baseExportPath to the export folder within your Time Machine backup, to link the exported photos with the photos of your Time Machine backup to save disk space.
* `logLevel`: Verbosity of output. Valid levels are: debug, info, warn, error
* `groupsToExport`: Selection of groups for which folders shall be created in the export folder. Exported photos are hard linked into these folders. Available groups are "Moments", "Collections", "Years", "Places", "Faces", "Videos", "Selfies", "Panoramas", "Screenshots", "Albums", "SmartAlbums". 
  * Note: If "Places" is selected, subfolders for country, province, city and poi will be created.
  * Note: If `groupsToExport` is empty only the `.flat` folder is created during export
* `exporterType`: `snapshot` or `incremental`

## Parameters hard coded

In addition to the parameters read from the config file these parameters are currently hard coded:

* `exportMediaGroupFilter`: filter for the media groups (default: all media groups are exported)
* `exportMediaObjectFilter`: filter for media objects (default: all media objects are exported)

# Supported platforms

* macOS 10.14 "Mojave" (tested by the maintainer)
* macOS 10.13 "High Sierra", Photos 3.0, XCode 10.1, Swift 4.2 (tested by Kai Unger)

# Implementation

The program starts with reading all metadata of the [System Photos Library](https://support.apple.com/en-us/HT204414). This is implemented in [MetadataLoader.swift](PhotosExporter/exporter/MetadataLoader.swift) using the [MediaLibrary Framework](https://developer.apple.com/documentation/medialibrary). While the MediaLibrary Framework would allow to read the iPhoto Library, the current sourcecode focuses on the Photos Library.

The rest is implemented in [PhotosExporter.swift](PhotosExporter/exporter/PhotosExporter.swift) and inherited classes [SnapshotPhotosExporter.swift](PhotosExporter/exporter/SnapshotPhotosExporter.swift) and [IncrementalPhotosExporter.swift](PhotosExporter/exporter/IncrementalPhotosExporter.swift).

The two implementations are different:
* [IncrementalPhotosExporter.swift](PhotosExporter/exporter/IncrementalPhotosExporter.swift): After loading the metadata, a folder `InProgress` is created. This is a temporary folder where the program copies all exported folders and files to; . After the export of all files has been succeeded, the folder is renamed to the current date formatted with the date pattern `yyyy-MM-dd HH-mm-ss`. Also a symbolic link (alias) to this folder named `Latest` is created to know which files to link on the next export. If an error occurs during the backup, the `InProgress` folder will be left, until the next run of the program finally deletes it.
* [SnapshotPhotosExporter.swift](PhotosExporter/exporter/SnapshotPhotosExporter.swift): it uses an `InProgress` folder, too. If the files of the Photos Library and the target folder are on the same file system, the files are not copied to the `InProgress` folder. Instead, hard links are created, to minimize disk usage. After the export of all files has been succeeded, the folder is renamed to `Current`, while the old `Current` folder is removed before.

The main part - exporting the albums and photos - is done in two phases: the first phase is to export all original and modified photos to a folder named `.flat`. The second phase creates all sub-folders based on the albums, smart albums etc. in the Photos Library.

This screenshot should give an idea about the generated folder structure:
![](/doc/filesystem-structure.png)

While exporting media files to the `.flat` folder, the program checks if a file has been changed since the last export, and uses a hard link in case the file hasn't been changed. This is done by comparing the media file in the Photos Library with the corresponding file in the `Latest` folder. While a comparison by something like a MD5 or SHA checksum would be the preferred way to check if the file content has been changed, I've decided to implement a simple comparison based on the file size for performance reasons.

As you can see, the SnapshotPhotosExporter is highly optimized to always keep the export directory on the same file system. If you backup your disk with Time Machine, no extra disk space is required because of the hard links. If photos are modified within the Photos app (or Photos recalculates the photos e.g. because of changed algorithms), the photos in the export directory may also be changed. For using the photos with other devices or programs, this behavior will be what you need. For backups on external drives it wouldn't be sufficient - therefore the IncrementalPhotosExporter was designed.

