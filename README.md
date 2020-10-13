# 💬 nstack-localizations-generator
(Formerly nstack-translations-manager)

> No more string keys, strongly typed translations are the way!

A tool to generate localizations from [NStack](http://nstack.io) API. 

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/nodes-ios/nstack-localizations-generator/blob/master/LICENSE)
![Plaform](https://img.shields.io/badge/platform-osx-lightgrey.svg)

## 📦 How does it work
> **TODO:** Elaborate  

Since Swift frameworks unfortunately can't be used inside other frameworks, this project has a special structure to be able to generate one executable, which is wrapped in a bundle. Check out this [great article](https://colemancda.github.io/programming/2015/02/12/embedded-swift-frameworks-osx-command-line-tools/) by Alsey Miller on how this works. 

However, this makes it even more portable because you need to copy a single file.

## 🔧 Setup
> **TODO:** Improve

1. In your Xcode project *(build phases)* add **New Run Script Phase** and drag it before **Compile Sources** phase
2. Put in the script below and change your project specific IDs and Paths
3. Go to [the latest release](https://github.com/nodes-ios/nstack-localizations-generator/releases) and download the `nstack-localizations-generator.bundle.zip`, unzip it and copy it to `${SRCROOT}/${TL_PROJ_ROOT_FOLDER}/Resources/NStack/`. This will be referenced from the build script, so the location has to match the one in the script.
4. Everytime you do **Clean** and then **Build**, your translations will be fetched and models generated

**You can find the localizations run script [here](translations_script.sh).**

## 👥 Credits
Made with ❤️ at [Nodes](http://nodesagency.com).

## 📄 License
**nstack-translations-generator** is available under the MIT license. See the [LICENSE](https://github.com/nodes-ios/nstack-localizations-generator/blob/master/LICENSE) file for more info.
