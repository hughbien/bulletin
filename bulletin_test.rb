require File.join(File.dirname(__FILE__), 'bulletin')
require 'minitest/autorun'

class AppTest < MiniTest::Unit::TestCase
  def setup
    @bulletin = Bulletin::App.new(false)
  end

  def test_configure
    Bulletin::App.set :browser, 'firefox'
    Bulletin::App.set :per_page, 20
    Bulletin::App.feed 'Liftoff News', 'http://liftoff.msfc.nasa.gov/rss.xml'

    assert_equal('firefox', @bulletin.options[:browser])
    assert_equal(20, @bulletin.options[:per_page])
    assert_equal('Liftoff News', @bulletin.feeds[0].title)
    assert_equal('http://liftoff.msfc.nasa.gov/rss.xml', @bulletin.feeds[0].uri)
  end

  def test_environment
    refute(@bulletin.production?)
  end

  def test_fetch_feed
    sample_uri = File.join(
      File.expand_path(File.dirname(__FILE__)),
      'sample.xml')
    rss = @bulletin.fetch_feed(sample_uri)
    assert_equal('Liftoff News', rss.channel.title)
    assert_equal('http://liftoff.msfc.nasa.gov/', rss.channel.link)
    assert_equal('Star City', rss.items[0].title)
    assert_equal(
      'http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp',
      rss.items[0].link)
  end
end
