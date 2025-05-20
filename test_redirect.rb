require 'net/http'
require 'uri'

# Simulate a redirect response
class MockNetHTTPRedirectResponse
  def initialize(location)
    @location = location
  end
  
  def code
    '302'
  end
  
  def [](key)
    return @location if key.downcase == 'location'
    nil
  end
end

# Simulate a success response
class MockNetHTTPSuccessResponse
  def initialize(body)
    @body = body
  end
  
  def code
    '200'
  end
  
  def body
    @body
  end
  
  def [](key)
    nil
  end
end

# Test our redirect handling logic
def test_redirect_handling
  url = "https://example.com/original"
  final_url = "https://example.com/final"
  uri = URI.parse(url)
  
  # Simulate first request with a redirect
  redirect_response = MockNetHTTPRedirectResponse.new(final_url)
  success_response = MockNetHTTPSuccessResponse.new("Final content")
  
  # Simulate our redirect handling logic
  max_redirects = 5
  redirect_count = 0
  current_uri = uri
  
  while redirect_count < max_redirects
    # We'd normally make an HTTP request here
    # For testing, we'll simulate the response
    response = redirect_count == 0 ? redirect_response : success_response
    
    case response.code
    when '200'
      puts "Success! Got final content: #{response.body}"
      break
    when '301', '302', '303', '307', '308'
      location = response['location'] 
      puts "Following redirect to: #{location}"
      current_uri = URI.parse(location)
      redirect_count += 1
    else
      puts "HTTP request failed with code #{response.code}"
      break
    end
  end
  
  if redirect_count >= max_redirects
    puts "Too many redirects"
  end
end

puts "Testing redirect handling..."
test_redirect_handling
puts "Test completed"