require File.join(File.dirname(__FILE__), 'bulletin')
require 'minitest/autorun'

class BulletinTest < MiniTest::Unit::TestCase
  Bulletin::App.setup_db(false)

  def setup
    @bulletin = Bulletin::App.new(false)
    Bulletin::Item.all.destroy
  end

  def test_refresh
    assert_equal(0, Bulletin::Item.count)
    @bulletin.feed 'Liftoff News', sample_uri
    @bulletin.refresh
    assert_equal(4, Bulletin::Item.count)

    item = Bulletin::Item.first
    assert_equal('Star City', item.title)
    assert_equal('Liftoff News', item.channel_title)
    assert(item.created_at)
    assert(item.published_at)
    assert(item.desc)
    assert(item.desc_html)
    assert(item.uri)
  end

  def test_configure
    @bulletin.set :browser, 'firefox'
    @bulletin.set :per_page, 20
    @bulletin.feed 'Liftoff News', 'http://liftoff.msfc.nasa.gov/rss.xml'

    assert_equal('firefox', @bulletin.send(:options)[:browser])
    assert_equal(20, @bulletin.send(:options)[:per_page])
    assert_equal('Liftoff News', @bulletin.send(:feeds)[0].title)
    assert_equal('http://liftoff.msfc.nasa.gov/rss.xml',
                 @bulletin.send(:feeds)[0].uri)
  end

  def test_environment
    refute(@bulletin.send(:production?))
  end

  def test_fetch_feed
    items = @bulletin.send(:fetch_feed, sample_uri)
    assert_equal('Star City', items[0].title)
    assert_equal(
      'http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp',
      items[0].uri.to_s)
  end

  private
  def sample_uri
    File.join(File.expand_path(File.dirname(__FILE__)),
              'sample.xml')
  end
end
