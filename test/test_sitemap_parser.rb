# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'helper')

require 'typhoeus'

class TestSitemapParser < Test::Unit::TestCase
  def setup
    url = 'https://example.com/sitemap.xml'
    local_file = fixture_path('sitemap.xml')

    response = Typhoeus::Response.new(code: 200, headers: {}, body: File.read(local_file))
    Typhoeus.stub(url).and_return(response)

    @sitemap = SitemapParser.new url
    @local_sitemap = SitemapParser.new local_file

    @expected_count = 3
  end

  def test_array
    assert_equal Array, @sitemap.to_a.class
    assert_equal @expected_count, @sitemap.to_a.size
    assert_equal Array, @local_sitemap.to_a.class
    assert_equal @expected_count, @local_sitemap.to_a.size
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
    response = Typhoeus::Response.new(code: 404, headers: {}, body: '404')
    Typhoeus.stub(url).and_return(response)

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new("HTTP request to #{url} failed") do
      sitemap.urls
    end
  end

  def test_malformed_sitemap
    url = 'https://example.com/bad/sitemap.xml'
    malformed_sitemap = fixture_path('malformed_sitemap.xml')
    response = Typhoeus::Response.new(code: 200, headers: {}, body: File.read(malformed_sitemap))
    Typhoeus.stub(url).and_return(response)

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new('Malformed sitemap, url without loc') do
      sitemap.to_a
    end
  end

  def test_malformed_sitemap_no_urlset
    url = 'https://example.com/bad/sitemap.xml'
    response = Typhoeus::Response.new(code: 200, headers: {}, body: '<foo>bar</foo>')
    Typhoeus.stub(url).and_return(response)

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new('Malformed sitemap, no urlset') do
      sitemap.to_a
    end
  end

  def test_nested_sitemap
    urls = ['https://example.com/sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = fixture_path(filename)
      response = Typhoeus::Response.new(code: 200, headers: {}, body: File.read(file))
      Typhoeus.stub(url).and_return(response)
    end

    sitemap = SitemapParser.new 'https://example.com/sitemap_index.xml', recurse: true
    assert_equal 6, sitemap.to_a.size
    assert_equal 6, sitemap.urls.count
  end

  def test_nested_sitemap_with_regex
    urls = ['https://example.com/sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = File.join(File.dirname(__FILE__), 'fixtures', filename)
      response = Typhoeus::Response.new(code: 200, body: File.read(file))
      Typhoeus.stub(url).and_return(response)
    end

    sitemap = SitemapParser.new 'https://example.com/sitemap_index.xml', recurse: true, url_regex: /sitemap2\.xml/
    assert_equal 3, sitemap.to_a.size
    assert_equal 3, sitemap.urls.count
  end

  sub_test_case 'gzip' do
    def test_gzip_sitemap
      url = 'https://example.com/sitemap.xml'
      headers = {
        'Content-Type' => 'application/gzip'
      }
      response = Typhoeus::Response.new(code: 200, headers: headers, body: File.read(fixture_path('sitemap.xml.gz')))
      Typhoeus.stub(url).and_return(response)

      sitemap = SitemapParser.new url
      expected = ['http://ben.balter.com/', 'http://ben.balter.com/about/', 'http://ben.balter.com/contact/']
      assert_equal(expected, sitemap.to_a)
    end
  end

  private

  def fixture_path(name)
    File.join(__dir__, 'fixtures', name)
  end
end
