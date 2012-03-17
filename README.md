Description
===========

Command line RSS reader that automatically ranks items according to your tastes.

Installation
============

    % gem install bulletin

Open up `~/.bulletinrc` to configure it:

    set :browser, 'firefox'
    set :per_page, 20
    set :db_file, '~/.bulletindb'
    set :expire, 30     # 30 days

    feed 'Title', 'http://feed-url/rss.xml'
    feed 'Second', 'http://second-feed/rss.xml'

Usage
=====

To pull down the latest:

    % bulletin --refresh

Now just start browsing with:

    % bulletin

Use the `--page` option to view other pages.  Use `--read` to read a story from
the command line or `--open` to open it in a browser.  Use `--like` to like a
story which will help with ranking according to your tastes.

    % bulletin --page 2
    % bulletin --read 45
    % bulletin --open 45
    % bulletin --like 45

You can like a story and read/open it simultaneously:

    % bulletin --like --read 45

You can show previous likes with `--likes` or undo it with `--unlike`:

    % bulletin --likes
    % bulletin --unlike l20

TODO
====

* save news to local db
* command line UI
* GP for ranking; terminals: url,title,links
  functions: add/sub/mul/div/scores

License
=======

Copyright (c) Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
