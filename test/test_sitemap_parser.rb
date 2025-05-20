# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'helper')

class TestSitemapParser < Test::Unit::TestCase
  def setup
    url = 'https://example.com/sitemap.xml'
    local_file = fixture_path('sitemap.xml')

    # Check if WebMock is available
    @webmock_available = defined?(WebMock)
    
    if @webmock_available
      # Stub HTTP request using WebMock
      stub_request(:get, url)
        .to_return(status: 200, body: File.read(local_file), headers: {})
    end

    if @webmock_available
      @sitemap = SitemapParser.new url
    else
      # If WebMock is not available, use local file for both tests
      @sitemap = SitemapParser.new local_file
    end
    
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
    omit "WebMock not available" unless defined?(WebMock)

    url = 'http://ben.balter.com/foo/bar/sitemap.xml'
    code = 404
    
    stub_request(:get, url)
      .to_return(status: code, body: code.to_s, headers: {})

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new("HTTP request to #{url} failed with code #{code}.") do
      sitemap.urls
    end
  end

  def test_malformed_sitemap
    omit "WebMock not available" unless defined?(WebMock)

    url = 'https://example.com/bad/sitemap.xml'
    malformed_sitemap = fixture_path('malformed_sitemap.xml')
    
    stub_request(:get, url)
      .to_return(status: 200, body: File.read(malformed_sitemap), headers: {})

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new('Malformed sitemap, url without loc') do
      sitemap.to_a
    end
  end

  def test_malformed_sitemap_no_urlset
    omit "WebMock not available" unless defined?(WebMock)

    url = 'https://example.com/bad/sitemap.xml'
    
    stub_request(:get, url)
      .to_return(status: 200, body: '<foo>bar</foo>', headers: {})

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new('Malformed sitemap, no urlset or sitemapindex') do
      sitemap.to_a
    end
  end

  def test_nested_sitemap
    omit "WebMock not available" unless defined?(WebMock)

    urls = ['https://example.com/sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = fixture_path(filename)
      
      stub_request(:get, url)
        .to_return(status: 200, body: File.read(file), headers: {})
    end

    sitemap = SitemapParser.new 'https://example.com/sitemap_index.xml', recurse: true

    assert_equal 6, sitemap.to_a.size
    assert_equal 6, sitemap.urls.count
  end

  def test_multiple_nested_sitemaps
    omit "WebMock not available" unless defined?(WebMock)

    urls = ['https://example.com/nested_sitemap_index.xml',
            'https://example.com/nested_sitemap_index1.xml',
            'https://example.com/nested_sitemap_index2.xml',
            'https://example.com/nested_sitemap_index3.xml',
            'https://example.com/nested_sitemap_index4.xml',
            'https://example.com/nested_sitemap_index5.xml',
            'https://example.com/nested_sitemap_index6.xml']

    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = fixture_path(filename)
      
      stub_request(:get, url)
        .to_return(status: 200, body: File.read(file), headers: {})
    end

    sitemap = SitemapParser.new 'https://example.com/nested_sitemap_index.xml', recurse: true

    assert_equal 12, sitemap.to_a.size
    assert_equal 12, sitemap.urls.count
  end

  def test_nested_sitemap_with_regex
    omit "WebMock not available" unless defined?(WebMock)

    urls = ['https://example.com/sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = File.join(File.dirname(__FILE__), 'fixtures', filename)
      
      stub_request(:get, url)
        .to_return(status: 200, body: File.read(file))
    end

    sitemap = SitemapParser.new 'https://example.com/sitemap_index.xml', recurse: true, url_regex: /sitemap2/

    assert_equal 3, sitemap.to_a.size
    assert_equal 3, sitemap.urls.count
  end

  def test_nested_sitemap_with_whitespace
    omit "WebMock not available" unless defined?(WebMock)

    urls = ['https://example.com/whitespace_sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = fixture_path(filename)
      
      stub_request(:get, url)
        .to_return(status: 200, body: File.read(file), headers: {})
    end

    sitemap = SitemapParser.new 'https://example.com/whitespace_sitemap_index.xml', recurse: true

    assert_equal 6, sitemap.to_a.size
    assert_equal 6, sitemap.urls.count
  end

  sub_test_case 'gzip' do
    def test_gzip_sitemap
      omit "WebMock not available" unless defined?(WebMock)

      url = 'https://example.com/sitemap.xml'
      
      stub_request(:get, url)
        .to_return(
          status: 200, 
          body: File.read(fixture_path('sitemap.xml.gz')),
          headers: {'Content-Type' => 'application/gzip'}
        )

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
