# Wineskin
Wineskin is a tool used to make ports of Windows software to Mac OS X. 

## About
The ports are in the form of normal Mac application bundle wrappers.  It works like a wrapper around the Windows software, and you can share just the wrappers if you choose. Make ports/wrappers to share with others, make ports of your own open source, free, or commercial software, or just make a port for yourself!  Why install and use Windows if you don’t need to?

Source: http://wineskin.urgesoftware.com/

## Modifications
As you may have already noticed, this is not the [original Wineskin repository](https://sourceforge.net/p/wineskin/code/ci/master/tree/). That repository counts with some changes to make Wineskin more stable, and to make its source easier to maintain. Considering this, lots of changes were made in WineskinApp and WineskinLauncher, and now both or them use ObjectiveC_Extension and some new classes to perform most of their tasks. 

## List of modifications
- The Resolution property in Info.plist should never get corrupted (*(null)x24sleep0*);
- The *Auto-detect GPU* feature should never cause malfunction in the port;
- The *Auto-detect GPU* feature should have a much bigger accuracy and detect the memory size of integrated video cards as well;
- Enabling *Mac Driver* and *Decorate window* checkboxes should not corrupt the wrapper registry;
- *Kill Wineskin Processes* should kill ALL Wineskin processes.
- Images (not .icns files) should also be accepted has wrapper icons;
- LNK files should be able to be selected as a port's run path, so Wineskin can extract the path and flags from it;
- Winetricks installation should be silent (with no windows) so it's much faster;
- The first *Advanced* tab (*Configuration*) should be much more simple in the first section:
    - The *Windows EXE* should use Wineskin syntax, including the drive and the flags, (eg. *"C:/Program Files/temp.exe" --run*) instead of using a macOS reference path (eg. */Program Files/temp.exe*) and the flag apart (eg. *--run*).

## License
Keeping the same as the original material, LGPL 2.1 is the license of that project. You can find more details about that in the LICENSE file.

## Credits
Special credits for this version go to doh123, for creating the original Wineskin.
