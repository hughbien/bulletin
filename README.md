Description
===========

Personalized news client.  Aggregates news from RSS feeds, Reddit, and Hacker
News and ranks links according to your tastes.

Installation
============

    % gem install bulletin

Open up `~/.bulletinrc` to configure it:

    set :browser,  'firefox'
    set :per_page, 80
    set :expire,   10 # days

    feed 'http://feed-url/rss.xml'
    feed 'http://second-feed/rss.xml'

    social :hackernews
    social :reddit
    social :subreddit, :gaming
    social :subreddit, :programming

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

* GP for ranking; terminals: url,title,links
  functions: add/sub/mul/div/scores

License
=======

Copyright (c) Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.
