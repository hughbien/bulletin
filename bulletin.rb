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
require 'colorize'

module Bulletin
  VERSION = '0.0.1'

  class App
    attr_reader :options, :feeds
    
    def initialize(production = true)
      @production = production
      @options = {}
      @feeds = []
      @term_width = `tput cols`.to_i
      @term_height = `tput lines`.to_i
    end

    def run(page=1)
      total = Item.count
      per_page = options[:per_page] || (@term_height - 2)
      page = page.to_i - 1
      items = Item.all(:order => [:rank],
                       :rank.gt => (per_page * page),
                       :rank.lte => (per_page * (page + 1)))
      return if items.empty?
      puts table(items)
    end

    def open_item(id)
      item = Item.first(:rank => id)
      `#{options[:browser] || 'firefox'} #{item.uri}` if item
    end

    def save(id)
      item = Item.first(:rank => id)
      if item
        item.is_saved = true
        item.save
      end
    end

    def unsave(id)
      return if id !~ /^\d+$/
      item = Item.first(:is_saved => true, :rank => id)
      if item
        item.is_saved = false
        item.save
      end
    end

    def saved
      items = Item.all(:is_saved => true, :order => [:rank])
      num_width = items.last.rank.to_s.size
      puts table(items)
    end

    def refresh
      items = @feeds.map do |feed|
        fetch_feed(feed)
      end.flatten.reject(&:nil?)
      all_uris = Item.all.map(&:uri)
      items = items.reject { |i| all_uris.include?(i.uri) }.
        sort_by(&:published_at)
      items.each_with_index do |item, index|
        item.rank = index + 1
        item.save
      end
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
      end.reject(&:nil?)
    end

    def table(items)
      id_width = items.map { |i| i.rank.to_s.size }.max
      host_width = items.map { |i| i.host.to_s.size }.max
      items.map do |item|
        id_pad = ' ' * (id_width - item.rank.to_s.size)
        host_pad = ' ' * (host_width - item.host.to_s.size)
        flag = item.is_saved ? 'S' : '*'
        id = "#{id_pad}#{item.rank}"
        host = "#{item.host}#{host_pad}"
        prefix_width = id_width + host_width + 4
        title = if (prefix_width + item.title.size) > @term_width
          "#{item.title[0..@term_width-(4 + prefix_width)]}..."
        else
          item.title
        end
        flag = flag == 'S' ? flag.colorize(:light_red) : flag
        "#{id.colorize(:light_blue)} #{host.colorize(:light_green)} #{flag} #{title}"
      end.join("\n")
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
    property :is_saved, Boolean, :default => false
    property :rank, Integer, :default => 0, :key => true

    def self.from_rss(rss, item)
      return nil if item.link.nil?
      Item.new(:published_at => (item.date || Time.now),
               :title => item.title.to_s.strip,
               :uri => item.link)
    end

    def full_title
      code = self.is_saved ? 'S'.colorize(:light_red) : '*'
      "#{host.colorize(:light_green)} #{code} #{title}"
    end

    def host
      uri.host.sub(/www\./, '').sub(/\.[^.]+$/, '')[0..14]
    end
  end

  DataMapper.finalize
  DataMapper::Model.raise_on_save_failure = true
end
