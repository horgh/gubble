require 'gubble'
require 'minitest/autorun'
require 'nokogiri'

class HTTPRequest
  attr_accessor :request_method, :path, :query

  def initialize(request_method, path)
    @request_method = request_method
    @path = path
    @query = {}
  end
end

class HTTPResponse
  attr_accessor :status, :headers, :body, :content_type

  def initialize
    @status = 200
    @headers = {}
    @body = ''
    @content_type = ''
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
  def setup
    @request = HTTPRequest.new('GET', '/')
    @response = HTTPResponse.new
    @gubble = Gubble.new('', 'test/data', 'templates', @request, @response)
  end

  def test_index_redirects_to_root
    @gubble.run
    assert_equal 307, @response.status
    assert_equal '/view?page=%2F', @response['Location']
  end

  def test_index
    @request.path = '/view'
    @request.query['page'] = '/'
    @gubble.run
    assert_equal 200, @response.status
    assert_equal(
      [
        {
          href:    'view?page=%2Fdir1',
          content: 'dir1',
        },
        {
          href:    'view?page=%2Fdir2',
          content: 'dir2',
        },
      ],
      parse_links,
    )
  end

  def test_subdir
    @request.path = '/view'
    @request.query['page'] = '/dir1'
    @gubble.run
    assert_equal 200, @response.status
    assert_equal(
      [
        {
          href:    'view?page=%2Fdir1%2Fone.txt',
          content: 'one.txt',
        },
        {
          href:    'view?page=%2Fdir1%2Ftwo.txt',
          content: 'two.txt',
        },
      ],
      parse_links,
    )
  end

  def test_page
    @request.path = '/view'
    @request.query['page'] = '/dir1/one.txt'
    @gubble.run
    assert_equal 200, @response.status
    assert_equal(
      'hi there',
      Nokogiri::HTML(@response.body).css('#content')[0].content.strip,
    )
  end

  def test_traversal_fails
    pages = [
      '/dir1/..',
      '/dir1/../dir1/one.txt',
    ]
    pages.each do |page|
      setup
      @request.path = '/view'
      @request.query['page'] = page
      @gubble.run
      assert_equal 400, @response.status
    end
  end

  def test_nonexisting_file
    @request.path = '/view'
    @request.query['page'] = '/dir1/dne.txt'
    @gubble.run
    assert_equal 404, @response.status
  end

  def test_missing_page_param
    @request.path = '/view'
    @gubble.run
    assert_equal 400, @response.status
  end

  def test_bad_character
    @request.path = '/view'
    @request.query['page'] = '/dir1/hi!.txt'
    @gubble.run
    assert_equal 400, @response.status
  end

  def parse_links
    links = []
    doc = Nokogiri::HTML(@response.body)
    doc.css('li a').each do |link|
      links << {
        href:    link['href'],
        content: link.content.gsub(/\s+/, ' ').strip,
      }
    end
    links
  end
end
