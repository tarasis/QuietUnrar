#  QuietUnrar (or QuietUnarchiver or QuietDecompressor)

Small app for quietly unarchiving rar, zip and lzma files. No windows on the screen unless there is an issue (bad CRC, requires password, missing volume)
Optionally show progress on Dock Icon or Status Bar (for larger files)
Optionally show a notification on completion (with action button to open finder in that folder)
Optionally play sound when decompression finished

Original was written in 2009 as a little thing for me, and now its getting some TLC and updates. Mostly to play with Objective-C again.
Might see if I can compile libunrar for Apple Silicon rather than having to use Rosetta.

## TO DO

* ✅ Store preferences in User Defaults
* ✅ Move code handling un archiving into seperate class
* ✅ add model code for preferences
* add support for 7zip https://github.com/OlehKulykov/PLzmaSDK
* Investigate metal warning, something to ignore?
* Add testing
* Dock or status bar appearance?
* if keeping my extractRARArchiveWithFilename method rather than unrarkit, swap to using the wide text process method
* reduce menu to only essential - preferences + quit
* about box with thanks & liecense info
* post notification on finishing
* what to do if app open and user unarchives a file? (apart from not make the preferences window front and central)
* investigate why memory keeps increasing if QuietUnarchiver is kept open but decompresses more files. Ran intruments but nothing listed as leaking or zombied.
* Compiler Warning: Lexical or Preprocessor issue "_UNIX macro redefined"


### Metal Warning

2021-05-30 15:17:27.995689+0100 QuietUnrar[91513:2457432] Metal API Validation Enabled
2021-05-30 15:17:28.105839+0100 QuietUnrar[91513:2457432] MTLIOAccelDevice bad MetalPluginClassName property (null)
2021-05-30 15:17:28.124992+0100 QuietUnrar[91513:2457432] +[MTLIOAccelDevice registerDevices]: Zero Metal services found

A new mac project doesn't report these warnings.

### Compiler Warning

/Users/tarasis/Programming/Projects/QuietUnrar/Carthage/Build/Mac/UnrarKit.framework/Versions/A/Headers/raros.hpp:28:11: '_UNIX' macro redefined
/Users/tarasis/Programming/Projects/QuietUnrar/TDNUnarchiver.m:12:9: In file included from /Users/tarasis/Programming/Projects/QuietUnrar/TDNUnarchiver.m:12:
/Users/tarasis/Programming/Projects/QuietUnrar/Carthage/Build/Mac/UnrarKit.framework/Versions/A/Headers/UnrarKit.h:18:9: In file included from /Users/tarasis/Programming/Projects/QuietUnrar/Carthage/Build/Mac/UnrarKit.framework/Headers/UnrarKit.h:18:
/Users/tarasis/Programming/Projects/QuietUnrar/Carthage/Build/Mac/UnrarKit.framework/Versions/A/Headers/URKArchive.h:12:9: In file included from /Users/tarasis/Programming/Projects/QuietUnrar/Carthage/Build/Mac/UnrarKit.framework/Headers/URKArchive.h:12:

## Libraries I'm using or intend to use

* RAR either ...
    * UnrarKit - https://github.com/abbeycode/UnrarKit
    * libunrar -
* ZIP - either ...
    * UnzipKit - https://github.com/abbeycode/UnzipKit
    * SSZipArchive - https://github.com/ZipArchive/ZipArchive
    * ZipZap - https://github.com/pixelglow/ZipZap
* 7Z - either ...
    * un7z - https://github.com/isRyven/un7z
    * SevenZip - https://github.com/lvsti/SevenZip
    * LzmaSDKObjC - https://github.com/OlehKulykov/LzmaSDKObjC
    * PlzmaSDK - https://github.com/OlehKulykov/PLzmaSDK
* DockProgress - https://github.com/sindresorhus/DockProgress (need to check out the whole Swift / Objective-C briding thing, don't remember any of that now)
* FSUserDefaults - https://github.com/cfloisand/FSUserDefaults (gist at https://gist.github.com/cfloisand/ba9eb5b661a7dda494bb45f28cdb7e0a and https://christianfloisand.wordpress.com/2018/03/25/improving-userdefaults-in-swift-with-key-value-observing/)
