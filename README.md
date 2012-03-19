Description
===========

Personalized news client.  Aggregates news from RSS feeds and ranks according
to your tastes.

Installation
============

    % gem install bulletin

Open up `~/.bulletinrc` to configure it:

    set :browser,  'firefox'
    set :per_page, 80
    set :expire,   10 # days

    feed 'http://feed-url/rss.xml'
    feed 'http://second-feed/rss.xml'

Usage
=====

To pull down the latest:

    % bulletin --refresh

Now just start browsing with:

    % bulletin

Use the `--page` option to view other pages.  Use `--open` to open it in a
browser.  Use `--like` to like a link which will help with ranking according to
your tastes.

    % bulletin --page 2
    % bulletin --open 45
    % bulletin --like 45

You can like a link and open it simultaneously:

    % bulletin --like --open 45

You can show previous likes with `--likes` or undo it with `--unlike`:

    % bulletin --likes
    % bulletin --unlike l20

TODO
====

* handle expiration
* add support for hacker news and reddit
* add support for configuring browser, per_page, and expire

License
=======

Copyright (c) Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
