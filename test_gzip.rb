require 'zlib'
require 'stringio'

# Create a gzipped content
def gzip_string(string)
  output = StringIO.new
  gz = Zlib::GzipWriter.new(output)
  gz.write(string)
  gz.close
  output.string
end

# Test our gzip handling method
def test_gzip_handling
  original_content = "<urlset><url><loc>http://example.com</loc></url></urlset>"
  gzipped_content = gzip_string(original_content)
  
  # Create mock response object
  response = Object.new
  def response.body
    @body
  end
  def response.body=(value)
    @body = value
  end
  def response.[]=(key, value)
    @headers ||= {}
    @headers[key] = value
  end
  def response.[](key)
    @headers ||= {}
    @headers[key]
  end
  
  response.body = gzipped_content
  response['Content-Type'] = 'application/gzip'
  
  # Simulate our inflate_body_if_needed method
  inflated = if response['Content-Type'] =~ /application\/((x-)?gzip|octet-stream)/
    begin
      Zlib.gunzip(response.body)
    rescue => e
      puts "Error inflating: #{e}"
      response.body
    end
  else
    response.body
  end
  
  puts "Original size: #{original_content.bytesize}"
  puts "Gzipped size: #{gzipped_content.bytesize}"
  puts "Inflated size: #{inflated.bytesize}"
  puts "Content matches: #{inflated == original_content}"
end

puts "Testing gzip handling..."
test_gzip_handling
puts "Test completed"