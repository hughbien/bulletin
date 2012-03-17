require 'rubygems'
require 'uri'
require 'open-uri'
require 'rss/1.0'
require 'rss/2.0'
require 'ostruct'
require 'data_mapper'
require 'dm-types'

module Bulletin
  VERSION = '0.0.1'

  class App
    attr_reader :options, :feeds
    
    def initialize(production = true)
      @production = production
      @options = {}
      @feeds = []
    end

    def refresh
      items = @feeds.map do |feed|
        fetch_feed(feed.uri)
      end.flatten
      items.each(&:save)
    end

    def set(option, value)
      @options[option] = value
    end

    def feed(title, uri)
      @feeds << OpenStruct.new(:title => title, :uri => uri)
    end

    def load_config
      config = File.join(ENV['HOME'], '.bulletinrc')
      if File.exists?(config)
        app = self
        Object.class_eval do
          define_method(:set) { |opt, val| app.set(opt, val) }
          define_method(:feed) { |title, uri| app.feed(title, uri) }
        end
        load(config, true)
      end
    end

    private
    def production?
      !!@production
    end

    def fetch_feed(uri)
      rss = RSS::Parser.parse(open(uri) { |io| io.read }, false)
      rss.items.map do |item|
        Item.new(:title => item.title,
                 :uri => item.link,
                 :description => item.description)
      end
    end

    def self.setup_db(production = true)
      DataMapper.setup(:default, production ?
        "sqlite://#{File.expand_path('~/.bulletindb')}" :
        "sqlite3::memory:")
      if !DataMapper.repository(:default).adapter.storage_exists?('items')
        DataMapper.auto_migrate! 
      end
    end
  end

  class Item
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :title, String
    property :description, Text
    property :uri, URI
  end

  DataMapper.finalize
end
