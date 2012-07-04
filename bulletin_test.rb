if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
  SimpleCov.command_name 'Unit Tests'
end

require File.join(File.dirname(__FILE__), 'bulletin')
require 'minitest/autorun'

class BulletinTest < MiniTest::Unit::TestCase
  Bulletin::App.setup_db(false)

  def setup
    @bulletin = Bulletin::App.new(false)
    Bulletin::Item.all.destroy
  end

  def test_refresh
    @bulletin.options[:expire] = 30
    assert_equal(0, Bulletin::Item.count)
    @bulletin.feed sample_uri
    @bulletin.refresh
    assert_equal(3, Bulletin::Item.count)

    item = Bulletin::Item.first
    assert(item.title)
    assert(item.created_at)
    assert(item.published_at)
    assert(item.uri)
    assert(item.rank)

    @bulletin.refresh
    assert_equal(3, Bulletin::Item.count)
  end

  def test_configure
    @bulletin.set :browser, 'firefox'
    @bulletin.set :per_page, 20
    @bulletin.feed 'http://liftoff.msfc.nasa.gov/rss.xml'

    assert_equal('firefox', @bulletin.send(:options)[:browser])
    assert_equal(20, @bulletin.send(:options)[:per_page])
    assert_equal('http://liftoff.msfc.nasa.gov/rss.xml',
                 @bulletin.send(:feeds)[0])
  end

  def test_environment
    refute(@bulletin.send(:production?))
  end

  private
  def sample_uri
    File.join(File.expand_path(File.dirname(__FILE__)), 'sample.xml')
  end
end
