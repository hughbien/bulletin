require 'rubygems'
require 'uri'
require 'open-uri'
require 'rss/1.0'
require 'rss/2.0'
require 'ostruct'
require 'data_mapper'
require 'dm-types'
require 'cgi'
require 'nokogiri'

module Bulletin
  VERSION = '0.0.1'

  class App
    attr_reader :options, :feeds
    
    def initialize(production = true)
      @production = production
      @options = {}
      @feeds = []
      @term_width = `tput cols`.to_i
    end

    def run
      items = Item.all
      num_width = items.size.to_s.size
      Item.all.each_with_index do |item, index|
        num = index + 1
        width = num_width - num.to_s.size
        line = "#{' ' * width}#{num}. #{item.full_title}"
        puts truncate(line)
      end
    end

    def open_item(id)
      item = Item.get(id)
      `firefox #{item.uri}` if item
    end

    def refresh
      items = @feeds.map do |feed|
        fetch_feed(feed)
      end.flatten.reject(&:nil?)
      all_uris = Item.all.map(&:uri)
      items.reject { |i| all_uris.include?(i.uri) }.each(&:save)
    end

    def set(option, value)
      @options[option] = value
    end

    def feed(uri)
      @feeds << uri
    end

    def social(site, *args)
      if site == :hackernews
        @feeds << 'http://news.ycombinator.com/rss'
      end
    end

    def load_config
      config = File.join(ENV['HOME'], '.bulletinrc')
      if File.exists?(config)
        app = self
        Object.class_eval do
          define_method(:set) { |opt, val| app.set(opt, val) }
          define_method(:feed) { |uri| app.feed(uri) }
          define_method(:social) { |site, *args| app.social(site, *args) }
        end
        load(config, true)
      end
    end

    private
    def truncate(str)
      str.size <= @term_width ?
        str :
        "#{str[0..@term_width-4]}..."
    end

    def production?
      !!@production
    end

    def fetch_feed(uri)
      rss = RSS::Parser.parse(open(uri) { |io| io.read }, false)
      if rss.nil?
        puts "Can't retrieve #{uri}"
        return
      end
      rss.items.map do |item|
        Item.from_rss(rss, item)
      end
    end

    def self.setup_db(production = true)
      DataMapper.setup(:default, production ?
        "sqlite://#{File.expand_path('~/.bulletindb')}" :
        "sqlite3::memory:")
      if !DataMapper.repository(:default).adapter.storage_exists?('bulletin_items')
        DataMapper.auto_migrate! 
      end
    end
  end

  class Item
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :published_at, DateTime
    property :title, String, :length => 255
    property :uri, URI

    def self.from_rss(rss, item)
      Item.new(:published_at => item.date,
               :title => item.title.strip,
               :uri => item.link)
    end

    def full_title
      "#{title} (#{uri.host})"
    end
  end

  DataMapper.finalize
  DataMapper::Model.raise_on_save_failure = true
end
