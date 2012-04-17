Description
===========

RSS reader with support for Hacker News and Reddit.

Installation
============

    % gem install bulletin

Open up `~/.bulletinrc` to configure it:

    set :browser,  'firefox'
    set :per_page, 80
    set :expire,   10 # days

    feed 'http://feed-url/rss.xml'
    feed 'http://second-feed/rss.xml', :limit => 10

    hacker_news
    hacker_news :ask, :limit => 10

    reddit
    reddit :gaming, :limit => 10

Usage
=====

To pull down the latest:

    % bulletin --refresh

Now just start browsing with:

    % bulletin

Use the `--page` option to view other pages.  Use `--read` to read a link and
`--open` or `--open-local` to read it in a browser.  Use `--save` to save it.

    % bulletin --page 2
    % bulletin --read 45
    % bulletin --save 45

You can save a link and read it simultaneously:

    % bulletin --save --read 45

Show all links without paginating with `--all`:

    % bulletin --all

You can show saved links with `--saved` or undo it with `--unsave`:

    % bulletin --saved
    % bulletin --unsave 20

TODO
====

* add single read
* handle expiration
* add support for atom feeds
* add support for hacker news and reddit
* add support for configuring browser, per_page, and expire

License
=======

Copyright (c) Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
