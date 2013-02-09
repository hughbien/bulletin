require 'rubygems'
require 'feedzirra'
require 'uri'
require 'data_mapper'
require 'dm-types'
require 'colorize'
require 'nokogiri'
require 'date'

module Bulletin
  VERSION = '0.0.6'
  EDITOR = ENV['EDITOR'] || 'vi'
  BULLETINRC = File.expand_path('~/.bulletinrc')
  BULLETINDB = File.expand_path('~/.bulletindb')

  class App
    attr_reader :options, :feeds
    
    def initialize(production = true)
      @production = production
      @options = {}
      @feeds = []
      @term_width = `tput cols`.to_i
      @term_height = `tput lines`.to_i
    end

    def edit
      `#{EDITOR} #{BULLETINRC} < \`tty\` > \`tty\``
    end

    def filter(site)
      @filter = site
    end

    def run(page=1)
      total = Item.count
      per_page = options[:per_page]
      page = page.to_i - 1
      options = {:order => [:rank]}
      if page > -1
        options.merge!(
          :offset => per_page * page,
          :limit  => per_page)
      end
      if @filter
        options.merge!(
          :uri.like => "%#{@filter}%"
        )
      end
      items = Item.all(options)
      return if items.empty?
      puts table(items)
    end

    def read(id)
      item = Item.first(:rank => id)
      print wrap_line(item.title).colorize(:light_cyan)
      puts (item.is_saved ? ' (S)'.colorize(:light_red) : '')
      print item.uri.host.to_s.colorize(:light_green) + ' on '
      puts item.published_at.strftime('%m/%d/%Y')
      puts ('-----').colorize(:light_red)
      puts html_to_text(item.body)
    end

    def open_item(id)
      item = Item.first(:rank => id)
      `#{options[:browser]} #{item.uri}` if item
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
      return if items.empty?
      num_width = items.last.rank.to_s.size
      puts table(items)
    end

    def refresh
      items = []
      Feedzirra::Feed.fetch_and_parse(@feeds).each do |uri, rss|
        if rss.is_a?(Fixnum)
          puts "Unable to fetch #{uri}"
        else
          items += rss.entries.map { |entry| Item.from_rss(rss, entry) }
        end
      end
      expired = Date.today - options[:expire]
      all_uris = Item.all.map(&:uri)
      items.reject! { |i| all_uris.include?(i.uri) || i.published_at < expired }
      Item.all(:published_at.lt => (Date.today - options[:expire])).destroy
      items = items + Item.all
      items.sort_by!(&:published_at)
      items.reverse!
      items.each_with_index do |item, index|
        item.rank = index + 1
        item.save!
      end
    end

    def set(option, value)
      @options[option] = value
    end

    def feed(uri)
      @feeds << uri
    end

    def setup_db(production = true)
      DataMapper.setup(:default, production ?
        "sqlite://#{File.expand_path(BULLETINDB)}" :
        "sqlite3::memory:")
      if !DataMapper.repository(:default).adapter.storage_exists?('bulletin_items')
        DataMapper.auto_migrate! 
      end
    end

    def load_config
      raise "No configuration found at '#{BULLETINRC}'." if !File.exists?(BULLETINRC)
      app = self
      Object.class_eval do
        define_method(:set) { |opt, val| app.set(opt, val) }
        define_method(:feed) { |uri| app.feed(uri) }
      end
      load(BULLETINRC, true)
      @options[:browser] ||= 'firefox'
      @options[:per_page] ||= (@term_height - 2)
      @options[:expire] ||= 30
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

    def html_to_text(html)
      blocks = %w(p div ul ol h1 h2 h3 h4 h5 h6)
      lists = %w(li)
      swaps = {'br'=>"\n", 'hr'=>"\n"}
      node = Nokogiri::HTML(html)
      node.xpath('.//text()').each do |t|
        if t.ancestors('pre').empty?
          t.content = t.text.gsub(/\s+/,' ')
        else
          t.content = t.text + "\n"
        end
      end
      node.css(swaps.keys.join(',')).each { |n| n.replace(swaps[n.name]) }
      node.css(blocks.join(',')).each { |n| n.after("\n\n") }
      node.css(lists.join(',')).each { |n| n.after("\n").before("* ") }
      text = node.text.split(/\n\n+/).map do |paragraph|
        paragraph.split(/\n/).map do |line|
          wrap_line(line.strip)
        end.join("\n")
      end.join("\n\n").gsub(/\n\n+/, "\n\n").strip
    end

    def wrap_line(line)
      buffer = []
      width = @term_width - 2
      line.split(/\s+/).each do |word|
        if buffer.empty? || (buffer.last.length + word.length + 1) > width
          if buffer.first && buffer.first =~ /^\*/
            buffer << "  #{word}"
          else
            buffer << word
          end
        else
          last = buffer.pop
          buffer << "#{last} #{word}"
        end
      end
      buffer.join("\n")
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
    property :body, Text

    def self.from_rss(rss, entry)
      return nil if entry.url.nil?
      Item.new(:published_at => (entry.published || Time.now),
               :title => entry.title.to_s.strip,
               :uri => entry.url,
               :body => entry.content || entry.summary)
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
