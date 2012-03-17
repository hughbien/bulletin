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
    def initialize(production = true)
      @production = production
      setup_db
    end

    def production?
      !!@production
    end

    def fetch_feed(uri)
      RSS::Parser.parse(open(uri) { |io| io.read }, false)
    end

    def options
      self.class.instance_variable_get(:@options) || {}
    end

    def feeds
      self.class.instance_variable_get(:@feeds) || []
    end

    def setup_db
      DataMapper.setup(:default, production? ?
        "sqlite://#{File.expand_path('~/.bulletindb')}" :
        "sqlite3::memory:")
    end

    def self.set(option, value)
      @options ||= {}
      @options[option] = value
    end

    def self.feed(title, uri)
      @feeds ||= []
      @feeds << OpenStruct.new(:title => title, :uri => uri)
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
end
