#!/bin/bash
#
# # Fari
#
# _**fari:** To do, to make (eo) — Lighthouses (it)_
#
# **Fari** downloads and prepares _fresh, ready-to-hack_ [Pharo][] images for
# you, so you can forget about the usual setup dance: get image, run it, open
# workspace, juggle windows, copy-paste, do-it, save image under new name…
#
# ```shell
# $ git clone git@github.com/$user/$repo.git
# $ cd $repo
# $ fari.sh build
# $ fari.sh run
# ```
#
#
# ## Install
#
# Drop or link
# [`fari.sh`](https://raw.githubusercontent.com/cdlm/fari.sh/master/fari.sh) in
# your `$PATH`.
#
#
# ## Configuration
#
# To have code automatically loaded in the fresh image, add a `load.st` file
# containing the needed code snippet in your project, typically something like:
#
# ```smalltalk
# "load.st"
# Metacello new baseline: 'Foo';
#   repository: 'gitlocal://./src';
#   load.
# ```
#
# This will generate a `pharo.1c0ffee.image` file. The hex suffix comes from the
# downloaded snapthot and identifies which sources file matches the image.
#
# **Named images:** Instead of `load.st`, you can also use a named load script,
# e.g. `foo.load.st`, resulting in a matching `foo.*.image`. Several named
# images can be generated, each with specific settings, by having as many named
# load scripts. If present, `load.st` is loaded before the named load script of
# each image; this is useful for sharing configuration in all named images.
#
# **Personal settings:** any existing `local.st` or `foo.local.st` files get
# loaded after the load scripts; those are intended for loading personal tools
# and settings, and should thus be left out of version control.
#
# **Environment variables:** Fari takes a few environment variables into
# account. We recommend [direnv][] to make any setting persistent and
# project-specific.
#
# `PHARO_PROJECT`: image name used in the absence of a named load script;
# defaults to `pharo`.
#
# `PHARO`: name of the Pharo VM command-line executable. Defaults to `pharo-ui`,
# assuming that you have it in your `$PATH`. If you get your VMs from
# [get.pharo.org][], set it to `./pharo-ui`.
#
# `PHARO_VERSION`: Pharo release, as used in the [get.pharo.org][] URLs;
# defaults to `70`.
#
# `PHARO_FILES`: URL prefix for downloading the image; defaults to
# `http://files.pharo.org/get-files/${PHARO_VERSION}`.
#
# `PHARO_IMAGE_FILE`: Name of the image distribution file to download; defaults
# to `pharo.zip` but would be `pharo64.zip` for 64-bit images.
#
## License
#
# The [Fari source][github] is available on Github, and is released under the
# [MIT license][mit]. See the [Docco][] generated docs for more information:
# https://cdlm.github.io/fari.sh
#
# [github]: https://github.com/cdlm/fari.sh
# [mit]: http://opensource.org/licenses/MIT
# [pharo]: http://pharo.org
# [get.pharo.org]: http://get.pharo.org
# [docco]: http://ashkenas.com/docco
# [direnv]: https://direnv.net

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# Now let's start. First & foremost, we toggle [bash strict
# mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/).
set -euo pipefail
IFS=$'\n\t'

### Invocation syntax

# Fari makes each of the `fari_*` functions defined below available as
# subcommands. For instance, `fari build foo` would invoke the `fari_build`
# function, passing `foo` along as the name of the image to build.
#
# For convenience, we accept alternate names for some of the subcommands;
# running `fari` with no argument is equivalent to `fari build`.
function dispatch_subcommand() {
    local subcommand="${1:-build}"
    # If the command was specified, drop it from the arguments.
    [[ $# -ge 1 ]] && shift

    # Resolve subcommand into function + first arguments.
    local -a actual
    case "$subcommand" in
        build | fetch | backup | load | prepare | run)
            actual=("fari_$subcommand")
            ;;
        list | ls)
            actual=('fari_list')
            ;;
        rename | mv)
            actual=('fari_rename')
            ;;
        copy | cp)
            actual=('fari_rename' '--copy')
            ;;
        delete | rm)
            actual=('fari_delete')
            ;;
        *)
            die "Error: ${subcommand} is not a known subcommand."
            ;;
    esac

    # Invoke the actual subcommand.
    "${actual[@]}" "$@"
}

### Subcommands
#
# When the functions below handle images, changes, and source files, they do so
# based on their basename, or extensionless path.

# **Build** all specified project images from a freshly downloaded base.
function fari_build() {
    # Ensure environment variables have sensible values.
    : "${PHARO_PROJECT:=pharo}"
    : "${PHARO:=pharo-ui}"
    : "${PHARO_VERSION:=70}"
    : "${PHARO_FILES:="http://files.pharo.org/get-files/${PHARO_VERSION}"}"
    : "${PHARO_IMAGE_FILE:=pharo.zip}"

    local fetched hash
    local -a images=("$@")

    # With no argument, we build one image per uniquely named load script in the
    # current directory, or default to `$PHARO_PROJECT`.
    [[ ${#images[@]} -eq 0 ]] && images=($(fari_list))
    [[ ${#images[@]} -eq 0 ]] && images=("$PHARO_PROJECT")

    # Get base image, extract build hash.
    fetched="$(fari_fetch "${PHARO_FILES}/${PHARO_IMAGE_FILE}")"
    hash="${fetched##*-}"

    # We build all specified images first…
    for project in "${images[@]}"; do
        fari_delete "${project}_tmp"
        fari_prepare "$fetched" "$project" "${project}_tmp"
    done

    # …and then back the old ones up, before moving the new ones in place.
    for project in "${images[@]}"; do
        fari_backup "${project}"
        fari_rename "${project}_tmp" "${project}.${hash}"
    done
}

# **List** basenames of load scripts found in the current directory.
function fari_list() {
    local regex='\.(load|local)\.st$'
    find . -maxdepth 1 -type f \
        | sed -En "/${regex}/s/${regex}//p" \
        | uniq
}

# **Run** an existing image.
function fari_run() {
    [[ $# -le 1 ]] || die "Usage: ${FUNCNAME[0]} [image]"
    local image="${1:-}"

    # Similar logic as in `fari_build` to determine which image to launch.
    : "${image:=$(fari_list | head -n1)}"
    : "${image:=$PHARO_PROJECT}"

    image=$(ls "$image".*.image)
    [ -e "$image" ] || die "No such image: ${image}"
    ${PHARO} "${image}"
}

# **Rename** or copy an image+changes file pair. Will not overwrite existing
# files.
function fari_rename() {
    [[ $# -ge 2 ]] || die "Usage: ${FUNCNAME[0]} [--copy] original new"
    local copy='mv'
    [[ $1 == '--copy' ]] && {
        copy='cp'
        shift
    }
    local original="$1" new="$2"

    [ -e "${original}.image" ] || die "No original image: ${original}.image"
    [ ! -e "${new}.image" ] || die "Destination file already exists: ${new}.image"
    [ ! -e "${new}.changes" ] || die "Destination file already exists: ${new}.changes"

    "$copy" "${original}.image" "${new}.image"
    "$copy" "${original}.changes" "${new}.changes"
}

# **Delete** image+changes file pairs.
function fari_delete() {
    [[ $# -ge 1 ]] || die "Usage: ${FUNCNAME[0]} basename..."

    for name in "$@"; do
        rm -f "${name}.image"
        rm -f "${name}.changes"
    done
}

# **Backup** an image+changes file pair. Backups have a `backup-YYYMMDD`
# timestamp appended to their original basename.
function fari_backup() {
    [[ $# -eq 1 ]] || die "Usage: ${FUNCNAME[0]} name"
    local name="$1" backup_stamp hash base
    backup_stamp="backup-$(date +%Y%m%d-%H%M)"

    # Look for images with any hash
    shopt -s nullglob
    for image in ${name}.*.image; do
        image="${image%.image}"
        hash="${image##*.}"
        base="${image%.$hash}"
        fari_rename "${image}" "${base}_${backup_stamp}.${hash}"
    done
}

# **Fetch** a zip archive containing image, changes, and sources files.
function fari_fetch() {
    [[ $# -eq 1 ]] || die "Usage: ${FUNCNAME[0]} url"
    local url="$1" downloaded tmp

    # Download & unzip everything in a temporary directory.
    tmp=$(mktemp -dt "pharo.XXXXXX")      #TODO clean up automatically
    download_to "${tmp}/image.zip" "$url" #TODO cache in a known place and continue?
    unzip -q "${tmp}/image.zip" -d "$tmp"

    # The filenames include the short hash of the commit they were generated
    # from, which is not predictable from the URL. We find and check that the
    # file does exist (`ls` will fail otherwise), then return its full path,
    # minus extension.
    downloaded="$(ls "${tmp}"/*.image)"
    downloaded="${downloaded%.image}"
    echo "$downloaded"
}

# **Load** project code by running any available load scripts pertaining to the
# `script` shortname, modifying the given `image` in place.
function fari_load() {
    [[ $# -eq 2 ]] || die "Usage: ${FUNCNAME[0]} script image"
    local script="$1" image="$2"

    for script_file in "load.st" "${script}.load.st" "local.st" "${script}.local.st"; do
        if [[ -e $script_file ]]; then
            ${PHARO} "${image}.image" st --save --quit "$script_file"
        fi
    done
}

# **Prepare** a `new` image, starting from the given `base`, loading project
# `script`s.
function fari_prepare() {
    [[ $# -eq 3 ]] || die "Usage: ${FUNCNAME[0]} base script new"
    local base="$1" script="$2" new="$3"
    local sources="${base}.sources"

    # 64-bit images use source file named after 32-bit
    if [[ ! -f ${sources} ]]; then
        sources="${sources/-64bit-/-32bit-}"
        [[ -f ${sources} ]] || die "Could not find the sources file for this image"
    fi
    cp -f "${sources}" "$(dirname "$new")"
    fari_rename --copy "$base" "$new"
    fari_load "$script" "$new"
}

### Shell utilities

# Silence output of a command.
function silently() { "$@" 2>/dev/null; }

# Display progress message.
function info() { echo "$@" 1>&2; }

# Abort execution with an error message and non-zero status.
function die() {
    echo "$@" 1>&2
    exit 1
}

# Download a `url` to the given file. A convenience wrapper around `curl` or
# `wget`.
function download_to() {
    [[ $# -eq 2 ]] || "Usage: ${FUNCNAME[0]} filename url"
    local dest="$1" url="$2"

    curl --silent --location --compressed --output "$dest" "$url" #TODO the same with wget
}

### Launch time!

# Only call the main function if this script was called as a command. This makes
# it possible to source this script as a library.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    dispatch_subcommand "$@"
fi
