Description
===========

Command line RSS reader.

Installation
============

    $ gem install bulletin

Open up `~/.bulletinrc` to configure it:

    set :browser,  'firefox' # defaults to firefox
    set :per_page, 80        # defaults to terminal height
    set :expire,   10        # defaults to 30 days

    feed 'http://feed-url/rss.xml'
    feed 'http://second-feed/rss.xml'

Usage
=====

To pull down the latest:

    $ bulletin --refresh

Now just start browsing with:

    $ bulletin

Use the `--page` option to view other pages.  Use `--read` to read a link and
`--open` to read it in a browser.  Use `--save` to save it.

    $ bulletin --page 2
    $ bulletin --read 45
    $ bulletin --save 45

Show all links without paginating with `--all`:

    $ bulletin --all

You can show saved links with `--saved` or undo it with `--unsave`:

    $ bulletin --saved
    $ bulletin --unsave 20

By default, bulletin uses the files `~/.bulletinrc` and `~/.bulletindb` to
configure and store data.  This can be changed using `--configure`:

    $ bulletin --configure ~/path/to/.bulletin --page 2

The above will use `~/path/to/.bulletinrc` and `~/path/to/.bulletindb`.  This
works best with an alias entry in your `.bashrc` or `.zshrc`.  Also, this is
helpful if you want to maintain separate bulletins with different feeds:

    alias bhome="bulletin --configure ~/.bulletin-home"
    alias bwork="bulletin --configure ~/.bulletin-work"

TODO
====

* remove bulletin configure option
* add bulletin -e

License
=======

Copyright (c) Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
