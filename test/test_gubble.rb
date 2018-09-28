require 'gubble'
require 'minitest/autorun'

class HTTPRequest
  attr_accessor :request_method, :path

  def initialize(request_method, path)
    @request_method = request_method
    @path = path
  end
end

class HTTPResponse
  attr_accessor :status, :headers, :body

  def initialize
    @status = 200
    @headers = {}
    @body = ''
  end

  def set_redirect(_status, location)
    @status = 307
    @headers['Location'] = location
  end

  def [](field)
    @headers[field]
  end
end

class GubbleTest < Minitest::Test
  def test_index_redirects_to_root
    request = HTTPRequest.new('GET', '/')
    response = HTTPResponse.new
    Gubble.new('', 'test/data', 'test/data', request, response).run
    assert_equal 307, response.status
    assert_equal '/view?page=%2F', response['Location']
  end
end
