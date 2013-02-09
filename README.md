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

License
=======

Copyright (c) Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
