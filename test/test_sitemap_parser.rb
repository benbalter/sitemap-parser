require File.join(File.dirname(__FILE__), 'helper')

class TestSitemapParser < Test::Unit::TestCase
  def setup
    @url = "https://raw.githubusercontent.com/benbalter/sitemap-parser/master/test/fixtures/sitemap.xml"
    @sitemap = SitemapParser.new @url

    @local_file = File.join(File.dirname(__FILE__), 'fixtures', 'sitemap.xml')
    @local_sitemap = SitemapParser.new @local_file

    @expected_count = 3
  end

  def test_array
    assert_equal Array, @sitemap.to_a.class
    assert_equal @expected_count, @sitemap.to_a.count
    assert_equal Array, @local_sitemap.to_a.class
    assert_equal @expected_count, @local_sitemap.to_a.count
  end

  def test_xml
    assert_equal Nokogiri::XML::NodeSet, @sitemap.urls.class
    assert_equal @expected_count, @sitemap.urls.count
    assert_equal Nokogiri::XML::NodeSet, @local_sitemap.urls.class
    assert_equal @expected_count, @local_sitemap.urls.count
  end

  def test_sitemap
    assert_equal Nokogiri::XML::Document, @sitemap.sitemap.class
    assert_equal Nokogiri::XML::Document, @local_sitemap.sitemap.class
  end

  def test_404
    sitemap = SitemapParser.new "http://ben.balter.com/foo/bar/sitemap.xml"
    assert_nothing_raised do
      assert_equal nil, sitemap.urls
    end
  end

  def test_malformed_sitemap
    url = "https://raw.githubusercontent.com/benbalter/sitemap-parser/master/test/fixtures/malformed_sitemap.xml"
    sitemap = SitemapParser.new url
    assert_nothing_raised do
      assert_equal [], sitemap.to_a
    end
  end
end
