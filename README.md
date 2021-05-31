#  QuietUnrar (or QuietUnarchiver or QuietDecompressor)

Small app for quietly unarchiving rar, zip and lzma files. No windows on the screen unless there is an issue (bad CRC, requires password, missing volume)
Optionally show progress on Dock Icon or Status Bar (for larger files)
Optionally show a notification on completion (with action button to open finder in that folder)

Original was written in 2009 as a little thing for me, and now its getting some TLC and updates. Mostly to play with Objective-C again.

## TO DO

* Store preferences in User Defaults (or mac equvalent)
* ✅ Move code handling un archiving into seperate class
* add model code for preferences
* add support for 7zip https://github.com/OlehKulykov/PLzmaSDK
* Investigate metal warning, something to ignore?

### Metal Warning

2021-05-30 15:17:27.995689+0100 QuietUnrar[91513:2457432] Metal API Validation Enabled
2021-05-30 15:17:28.105839+0100 QuietUnrar[91513:2457432] MTLIOAccelDevice bad MetalPluginClassName property (null)
2021-05-30 15:17:28.124992+0100 QuietUnrar[91513:2457432] +[MTLIOAccelDevice registerDevices]: Zero Metal services found

A new mac project doesn't report these warnings.
