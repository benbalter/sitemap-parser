require File.join(File.dirname(__FILE__), 'helper')

class TestSitemapParser < Test::Unit::TestCase
  def setup
    @path = File.expand_path "./fixtures/sitemap.xml", File.dirname( __FILE__ )
    @sitemap = SitemapParser.new @path
    @expected_count = 3
  end

  def test_array
    assert_equal Array, @sitemap.to_a.class
    assert_equal @expected_count, @sitemap.to_a.count
  end

  def test_xml
    assert_equal Nokogiri::XML::NodeSet, @sitemap.urls.class
    assert_equal @expected_count, @sitemap.urls.count
  end

  def test_sitemap
    assert_equal Nokogiri::XML::Document, @sitemap.sitemap.class
  end
end
