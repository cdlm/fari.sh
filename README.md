
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

 **Install:** Drop or link
 [`fari.sh`](https://raw.githubusercontent.com/cdlm/fari.sh/master/fari.sh) in
 your `$PATH`.

 The [Fari source][github] is available on Github, and is released under the
 [MIT license][mit]. See the [Docco][] generated docs for more information:
 https://cdlm.github.io/fari.sh/fari.html

 * * *

 **Configuration:** To have code automatically loaded in the fresh image, add a
 `load.st` file containing the needed code snippet in your project, typically
 something like:

 ```smalltalk
 "load.st"
 Metacello new baseline: 'Foo';
   repository: 'gitlocal://./src';
   load.
 ```

 This will generate a `pharo-$githash.image` file. The git hash comes from the
 downloaded snapthot and identifies which sources file matches the image.

 **Named images:** Instead of `load.st`, you can also use a named load file,
 e.g. `foo.load.st` file, resulting in a matching `foo-*.image`. Several named
 images can be generated, each with specific settings, by having several named
 load files. If present, the `load.st` file will still be loaded in all images,
 before the named load file; this is useful for sharing configuration in all
 named images.

 **Personal settings:** any existing `local.st` or `$prefix.local.st` files
 will be also loaded; those are intended for loading personal tools and
 settings, and should thus be left out of version control.

 In the absence of a named load file, the name prefix defaults to `pharo`; to
 change it, set the `PHARO_PROJECT` environment variable; we recommend
 [direnv][] to make that setting persistent and project-specific.

 [github]: https://github.com/cdlm/fari.sh
 [mit]: http://opensource.org/licenses/MIT
 [pharo]: http://pharo.org
 [docco]: http://ashkenas.com/docco/
 [direnv]: https://direnv.net
