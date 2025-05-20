require 'net/http'
require 'uri'

# Create a simple test for the Net::HTTP implementation
module Test
  def self.run
    puts "Testing Net::HTTP implementation..."
    url = "https://example.com"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Sitemap-Parser'
    
    response = http.request(request)
    puts "Response code: #{response.code}"
    puts "Response body sample: #{response.body[0..100]}"
    puts "Test completed successfully"
  end
end

Test.run