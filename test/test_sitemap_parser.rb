require File.join(File.dirname(__FILE__), 'helper')

require 'typhoeus'

class TestSitemapParser < Test::Unit::TestCase
  def setup
    url = "https://example.com/sitemap.xml"
    local_file = File.join(File.dirname(__FILE__), 'fixtures', 'sitemap.xml')

    response = Typhoeus::Response.new(code: 200, body: File.read(local_file))
    Typhoeus.stub(url).and_return(response)

    @sitemap = SitemapParser.new url
    @local_sitemap = SitemapParser.new local_file

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
    url = 'http://ben.balter.com/foo/bar/sitemap.xml'
    response = Typhoeus::Response.new(code: 404, body: "404")
    Typhoeus.stub(url).and_return(response)

    sitemap = SitemapParser.new url
    assert_raise_with_message RuntimeError, "HTTP request to #{url} failed" do
      sitemap.urls
    end
  end

  def test_malformed_sitemap
    url = 'https://example.com/bad/sitemap.xml'
    malformed_sitemap = File.join(File.dirname(__FILE__), 'fixtures', 'malformed_sitemap.xml')
    response = Typhoeus::Response.new(code: 200, body: File.read(malformed_sitemap))
    Typhoeus.stub(url).and_return(response)

    sitemap = SitemapParser.new url
    assert_raise_with_message RuntimeError, 'Malformed sitemap, url without loc' do
      sitemap.to_a
    end
  end
end
