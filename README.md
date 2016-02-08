# 💬 nstack-translations-generator
> No more string keys, strongly typed translations are the way!

A tool to generate translations from [NStack](http://nstack.io) API. 

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/nodes-ios/nstack-translations-generator/blob/master/LICENSE)
![Plaform](https://img.shields.io/badge/platform-osx-lightgrey.svg)

## 📦 How does it work
> **TODO:** Elaborate  

Since Swift frameworks unfortunately can't be used inside other frameworks, this project has a special structure to be able to generate one executable, which is wrapped in a bundle. Check out this [great article](https://colemancda.github.io/programming/2015/02/12/embedded-swift-frameworks-osx-command-line-tools/) by Alsey Miller on how this works. 

However, this makes it even more portable and could require you to copy just one file.

## 🔧 Setup
> **TODO:** Improve

1. In your Xcode project *(build phases)* add **New Run Script Phase**
2. Put in the script below and change your project specific IDs and Paths

~~~sh
TL_GEN_PATH="$SOURCE_ROOT/Resources/Language/nstack-translations-generatorBundle"
TL_CONFIG_PATH="$SOURCE_ROOT/Resources/NStack.plist"
TL_OUT_PATH="$SOURCE_ROOT/Resources/Language"

# Check if doing a clean build
if test -d "$BUILT_PRODUCTS_DIR"; then
	echo "Not clean build, won't fetch translations this time."
else
	echo "Clean build. Getting translations..."
	"${TL_GEN_PATH}/Contents/MacOS/nstack-translations-generator" -plist $TL_CONFIG_PATH -output $TL_OUT_PATH
fi
~~~


## 👥 Credits
Made with ❤️ at [Nodes](http://nodesagency.com).

## 📄 License
**nstack-translations-generator** is available under the MIT license. See the [LICENSE](https://github.com/nodes-ios/nstack-translations-generator/blob/master/LICENSE) file for more info.
