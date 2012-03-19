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

    def run(page=1)
      total = Item.count
      per_page = 20
      page = page.to_i - 1
      items = Item.all(:order => [:rank],
                       :rank.gt => (per_page * page),
                       :rank.lte => (per_page * (page + 1)))
      return if items.empty?

      num_width = items.last.rank.to_s.size
      items.each do |item|
        num = item.rank
        width = num_width - num.to_s.size
        line = "#{' ' * width}#{num}. #{item.full_title}"
        puts truncate(line)
      end
      puts (' ' * num_width) + "  (#{items.first.rank}-#{items.last.rank} of #{total})"
    end

    def open_item(id)
      item = Item.first(:rank => id)
      `thunar #{item.uri}` if item
    end

    def like(id)
      item = Item.first(:rank => id)
      if item
        item.like = true
        item.save
      end
    end

    def unlike(id)
      return if id !~ /^l\d+$/
      index = id[1..-1].to_i
      items = Item.all(:like => true, :order => [:rank])
      item = items[index - 1]
      if item
        item.like = false
        item.save
      end
    end

    def likes
      items = Item.all(:like => true, :order => [:rank])
      num_width = items.size.to_s.size
      items.each_with_index do |item, index|
        num = index + 1
        width = num_width - num.to_s.size
        line = "#{' ' * width}l#{num}. #{item.full_title}"
        puts truncate(line)
      end
    end

    def refresh
      items = @feeds.map do |feed|
        fetch_feed(feed)
      end.flatten.reject(&:nil?)
      all_uris = Item.all.map(&:uri)
      items.reject { |i| all_uris.include?(i.uri) }.each(&:save)
      evolve!
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
    def evolve!
      # initial population
      items = Bulletin::Item.all
      population = (0...100).map { items.sort_by { rand } }
      scores = Array.new(100)
      
      100.times do
        # evaluate
        scores = population.map { |items| evaluate(items) }

        # select
        new_population = (0...100).map do
          left, right = rand(100), rand(100)
          winner = scores[left] > scores[right] ? left : right
          population[winner]
        end
        population = new_population
        
        # variation
        population.map! do |pop|
          if rand < 0.2
            (rand(pop.size) / 10).times do
              item = pop.delete_at(rand(pop.size))
              pop.insert(rand(pop.size))
            end
            pop
          else
            pop
          end
        end
      end

      # get the best for last generation
      best_index = population.map { |items| evaluate(items) }.
        each_with_index.
        max[1]
      winner = population[best_index]
      winner.each_with_index do |item, index|
        item.rank = index + 1
        item.save
      end
    end

    def evaluate(items)
      @likes ||= begin
        hosts = {}
        Bulletin::Item.all(:like => true).each do |i|
          hosts[i.host] ||= 0
          hosts[i.host] = hosts[i.host] + 1
        end
        hosts
      end
      score = 0
      items.reverse.each_with_index do |item, index|
        if @likes[item.host]
          score += (@likes[item.host] * index)
        end
      end
      score
    end

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
    property :like, Boolean, :default => false
    property :rank, Integer, :default => 0, :key => true

    def self.from_rss(rss, item)
      return nil if item.link.nil?
      Item.new(:published_at => item.date,
               :title => item.title.to_s.strip,
               :uri => item.link)
    end

    def full_title
      "#{title} (#{uri.host})"
    end

    def host
      uri.host
    end
  end

  DataMapper.finalize
  DataMapper::Model.raise_on_save_failure = true
end
