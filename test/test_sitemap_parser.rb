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

  def teardown
    Typhoeus::Expectation.clear
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
    code = 404
    response = Typhoeus::Response.new(code: code, headers: {}, body: code.to_s)
    Typhoeus.stub(url).and_return(response)

    sitemap = SitemapParser.new url
    assert_raise RuntimeError.new("HTTP request to #{url} failed with code #{code}.") do
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
    assert_raise RuntimeError.new('Malformed sitemap, no urlset or sitemapindex') do
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

  def test_multiple_nested_sitemaps
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
      response = Typhoeus::Response.new(code: 200, headers: {}, body: File.read(file))
      Typhoeus.stub(url).and_return(response)
    end

    sitemap = SitemapParser.new 'https://example.com/nested_sitemap_index.xml', recurse: true

    assert_equal 12, sitemap.to_a.size
    assert_equal 12, sitemap.urls.count
  end

  def test_nested_sitemap_with_regex
    urls = ['https://example.com/sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = File.join(File.dirname(__FILE__), 'fixtures', filename)
      response = Typhoeus::Response.new(code: 200, body: File.read(file))
      Typhoeus.stub(url).and_return(response)
    end

    sitemap = SitemapParser.new 'https://example.com/sitemap_index.xml', recurse: true, url_regex: /sitemap2/

    assert_equal 3, sitemap.to_a.size
    assert_equal 3, sitemap.urls.count
  end

  def test_nested_sitemap_with_whitespace
    urls = ['https://example.com/whitespace_sitemap_index.xml', 'https://example.com/sitemap.xml', 'https://example.com/sitemap2.xml']
    urls.each do |url|
      filename = url.gsub('https://example.com/', '')
      file = fixture_path(filename)
      response = Typhoeus::Response.new(code: 200, headers: {}, body: File.read(file))
      Typhoeus.stub(url).and_return(response)
    end

    sitemap = SitemapParser.new 'https://example.com/whitespace_sitemap_index.xml', recurse: true

    assert_equal 6, sitemap.to_a.size
    assert_equal 6, sitemap.urls.count
  end

  sub_test_case 'request headers' do
    def test_keeps_custom_headers_and_adds_default_user_agent
      headers = capture_request_headers('https://example.com/sitemap.xml', headers: { 'Accept-Language' => 'fr' })

      assert_equal 'fr', headers['Accept-Language']
      assert_equal 'Sitemap-Parser', headers['User-Agent']
    end

    def test_respects_caller_supplied_user_agent
      headers = capture_request_headers('https://example.com/sitemap.xml', headers: { 'User-Agent' => 'Custom' })

      assert_equal 'Custom', headers['User-Agent']
    end

    def test_adds_default_user_agent_when_no_headers_given
      headers = capture_request_headers('https://example.com/sitemap.xml')

      assert_equal 'Sitemap-Parser', headers['User-Agent']
    end
  end

  sub_test_case 'gzip' do
    def test_gzip_sitemap
      url = 'https://example.com/gzip/sitemap.xml'
      headers = {
        'Content-Type' => 'application/gzip'
      }
      response = Typhoeus::Response.new(code: 200, headers: headers, body: File.read(fixture_path('sitemap.xml.gz')))
      Typhoeus.stub(url).and_return(response)

      sitemap = SitemapParser.new url
      expected = ['http://ben.balter.com/', 'http://ben.balter.com/about/', 'http://ben.balter.com/contact/']

      assert_equal(expected, sitemap.to_a)
    end

    def test_gzip_sitemap_served_as_octet_stream_or_without_content_type
      url = 'https://example.com/sitemap.xml.gz'
      body = File.binread(fixture_path('sitemap.xml.gz'))

      [{ 'Content-Type' => 'application/octet-stream' }, {}].each do |headers|
        Typhoeus::Expectation.clear
        Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 200, headers: headers, body: body))

        assert_equal 3, SitemapParser.new(url).to_a.size
      end
    end

    def test_plain_xml_served_as_octet_stream
      url = 'https://example.com/octet-stream/sitemap.xml'
      body = File.read(fixture_path('sitemap.xml'))
      headers = { 'Content-Type' => 'application/octet-stream' }
      Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 200, headers: headers, body: body))

      assert_equal 3, SitemapParser.new(url).to_a.size
    end

    def test_local_gzip_sitemap
      assert_equal 3, SitemapParser.new(fixture_path('sitemap.xml.gz')).to_a.size
    end
  end

  sub_test_case 'recursion' do
    def test_index_that_lists_itself_terminates
      index = 'https://example.com/loop_index.xml'
      stub_body index, sitemap_index(index, 'https://example.com/sitemap.xml')
      stub_body 'https://example.com/sitemap.xml', File.read(fixture_path('sitemap.xml'))

      assert_equal 3, SitemapParser.new(index, recurse: true).to_a.size
    end

    def test_indexes_that_list_each_other_terminate
      a = 'https://example.com/a.xml'
      b = 'https://example.com/b.xml'
      stub_body a, sitemap_index(b)
      stub_body b, sitemap_index(a, 'https://example.com/sitemap.xml')
      stub_body 'https://example.com/sitemap.xml', File.read(fixture_path('sitemap.xml'))

      assert_equal 3, SitemapParser.new(a, recurse: true).to_a.size
    end

    def test_child_listed_twice_is_fetched_once
      index = 'https://example.com/dupe_index.xml'
      stub_body index, sitemap_index('https://example.com/sitemap.xml', 'https://example.com/sitemap.xml')
      stub_body 'https://example.com/sitemap.xml', File.read(fixture_path('sitemap.xml'))

      assert_equal 3, SitemapParser.new(index, recurse: true).to_a.size
    end

    def test_remote_index_cannot_read_local_files
      index = 'https://example.com/evil_index.xml'
      local = fixture_path('sitemap.xml')
      stub_body index, sitemap_index(local)

      error = assert_raise(RuntimeError) { SitemapParser.new(index, recurse: true).urls }
      assert_match(/Refusing to read/, error.message)
    end

    def test_local_index_can_list_remote_sitemaps
      stub_body 'https://example.com/sitemap.xml', File.read(fixture_path('sitemap.xml'))
      Tempfile.create(['index', '.xml']) do |file|
        file.write(sitemap_index('https://example.com/sitemap.xml'))
        file.flush

        assert_equal 3, SitemapParser.new(file.path, recurse: true).to_a.size
      end
    end
  end

  sub_test_case 'errors' do
    def test_missing_local_file
      error = assert_raise(RuntimeError) { SitemapParser.new('does/not/exist.xml').urls }
      assert_match(/Could not read sitemap at does/, error.message)
    end

    def test_url_without_loc_raises_from_urls
      url = 'https://example.com/bad/sitemap.xml'
      stub_body url, File.read(fixture_path('malformed_sitemap.xml'))

      assert_raise(RuntimeError.new('Malformed sitemap, url without loc')) { SitemapParser.new(url).urls }
    end

    def test_lowercase_user_agent_is_respected
      headers = capture_request_headers('https://example.com/sitemap.xml', headers: { 'user-agent' => 'Custom' })

      assert_equal 'Custom', headers['user-agent']
      assert_not_include headers.keys, 'User-Agent'
    end
  end

  private

  def stub_body(url, body)
    Typhoeus.stub(url).and_return(Typhoeus::Response.new(code: 200, headers: {}, body: body))
  end

  def sitemap_index(*locations)
    entries = locations.map { |loc| "<sitemap><loc>#{loc}</loc></sitemap>" }.join
    %(<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">#{entries}</sitemapindex>)
  end

  def fixture_path(name)
    File.join(__dir__, 'fixtures', name)
  end

  def capture_request_headers(url, **options)
    local_file = fixture_path('sitemap.xml')
    response = Typhoeus::Response.new(code: 200, headers: {}, body: File.read(local_file))
    Typhoeus.stub(url).and_return(response)

    sent_headers = nil
    hook = lambda do |request|
      sent_headers = request.options[:headers]
      true
    end
    Typhoeus.before << hook
    begin
      SitemapParser.new(url, **options).to_a
    ensure
      Typhoeus.before.delete(hook)
    end
    sent_headers
  end
end
