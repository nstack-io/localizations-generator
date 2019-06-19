TL_PROJ_ROOT_FOLDER="App"
TL_GEN_PATH="${SRCROOT}/${TL_PROJ_ROOT_FOLDER}/Resources/NStack/nstack-translations-generator.bundle"
TL_CONFIG_PATH="${SRCROOT}/${TL_PROJ_ROOT_FOLDER}/Resources/NStack/NStack.plist"
TL_OUT_PATH="${SRCROOT}/${TL_PROJ_ROOT_FOLDER}/Resources/NStack/Translations"

# Check if doing a clean build
if test -f "${DERIVED_FILE_DIR}/TranslationsGenerator.lock"; then
echo "Not clean build, won't fetch translations this time."
else
echo "Clean build. Getting translations..."
"${TL_GEN_PATH}/Contents/MacOS/nstack-translations-generator" -plist "${TL_CONFIG_PATH}" -output "${TL_OUT_PATH}" -standalone
touch "${DERIVED_FILE_DIR}/TranslationsGenerator.lock" # create lock file
fi
