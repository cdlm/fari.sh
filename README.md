
 # Fari

 _**fari:** To do, to make (eo) — Lighthouses (it)_

 **Fari** downloads and prepares _fresh, ready-to-hack_ [Pharo][] images for
 you, so you can forget about the usual setup dance: get image, run it, open
 workspace, juggle windows, copy-paste, do-it, save image under new name…

 ```shell
 $ git clone git@github.com/$user/$repo.git
 $ cd $repo
 $ fari.sh
 ```


 ## Install

 Drop or link
 [`fari.sh`](https://raw.githubusercontent.com/cdlm/fari.sh/master/fari.sh) in
 your `$PATH`.


 ## Configuration

 To have code automatically loaded in the fresh image, add a `load.st` file
 containing the needed code snippet in your project, typically something like:

 ```smalltalk
 "load.st"
 Metacello new baseline: 'Foo';
   repository: 'gitlocal://./src';
   load.
 ```

 This will generate a `pharo.1c0ffee.image` file. The hex suffix comes from the
 downloaded snapthot and identifies which sources file matches the image.

 **Named images:** Instead of `load.st`, you can also use a named load script,
 e.g. `foo.load.st`, resulting in a matching `foo.*.image`. Several named
 images can be generated, each with specific settings, by having as many named
 load scripts. If present, `load.st` is loaded before the named load script of
 each image; this is useful for sharing configuration in all named images.

 **Personal settings:** any existing `local.st` or `foo.local.st` files get
 loaded after the load scripts; those are intended for loading personal tools
 and settings, and should thus be left out of version control.

 **Environment variables:** Fari takes a few environment variables into
 account. We recommend [direnv][] to make any setting persistent and
 project-specific.

 `PHARO_PROJECT`: image name used in the absence of a named load script;
 defaults to `pharo`.

 `PHARO`: name of the Pharo VM command-line executable. Defaults to `pharo-ui`,
 assuming that you have it in your `$PATH`. If you get your VMs from
 [get.pharo.org][], set it to `./pharo-ui`.

 `PHARO_VERSION`: Pharo release, as used in the [get.pharo.org][] URLs;
 defaults to `70`.

 `PHARO_FILES`: URL prefix for downloading the image; defaults to
 `http://files.pharo.org/get-files/${PHARO_VERSION}`.

 ## License

 The [Fari source][github] is available on Github, and is released under the
 [MIT license][mit]. See the [Docco][] generated docs for more information:
 https://cdlm.github.io/fari.sh

 [github]: https://github.com/cdlm/fari.sh
 [mit]: http://opensource.org/licenses/MIT
 [pharo]: http://pharo.org
 [get.pharo.org]: http://get.pharo.org
 [docco]: http://ashkenas.com/docco
 [direnv]: https://direnv.net
