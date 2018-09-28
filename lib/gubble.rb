require 'erb'

# Gubble takes an HTTP request and replies to it. It is the controller for
# the site.
class Gubble
  include ERB::Util

  def initialize(url_path, data_dir, template_dir, req, res)
    @url_path = url_path
    @data_dir = data_dir
    @template_dir = template_dir
    @request = req
    @response = res
  end

  def run
    if @request.request_method == 'GET' &&
       (@request.path == @url_path + '/' || @request.path == @url_path)
      @response.set_redirect(
        WEBrick::HTTPStatus::TemporaryRedirect,
        @url_path + "/view?page=#{u('/')}",
      )
      return
    end

    if @request.request_method == 'GET' && @request.path == @url_path + '/view'
      view
      return
    end

    render_error(400, 'Invalid request')
    nil
  end

  private

  def view
    external_path = @request.query['page']

    if external_path.nil?
      render_error(400, 'No page specified')
      return
    end

    external_path = normalize_path(external_path)
    if external_path.nil?
      render_error(400, 'Invalid page')
      return
    end

    fs_path = File.join(@data_dir, external_path)

    if !File.exist?(fs_path)
      render_error(404, 'Page not found')
      return
    end

    if Dir.exist?(fs_path)
      render_dir(fs_path, external_path)
      return
    end

    render_file(fs_path, external_path)
    nil
  end

  def normalize_path(external_path)
    return nil if external_path =~ /[^a-zA-Z0-9_\/ .-]/
    return nil if external_path =~ /\.\./
    external_path
  end

  def render_dir(fs_path, external_path)
    files = []
    Dir.foreach(fs_path) do |entry|
      next if entry[0] == '.'
      entry_fs_path = File.join(fs_path, entry)
      entry_external_path = File.join(external_path, entry)
      files << {
        is_dir:        Dir.exist?(entry_fs_path),
        name:          entry,
        external_path: entry_external_path,
      }
    end
    files.sort! { |a, b| a[:name] <=> b[:name] }
    title = external_path
    render_page('directory.rhtml', binding)
    nil
  end

  def render_file(fs_path, external_path)
    contents = File.read(fs_path)
    title = external_path
    render_page('file.rhtml', binding)
    nil
  end

  def render_error(status, message)
    @response.status = status
    title = 'Error'
    render_page('error.rhtml', binding)
    nil
  end

  def render_page(name, binding)
    @response.content_type = 'text/html; charset=utf-8'
    @response.body = render_template('_header.rhtml', binding) +
                     render_template(name, binding)
    nil
  end

  def render_template(name, binding)
    erb = ERB.new(
      File.read(
        File.join(@template_dir, name),
      ),
    )
    erb.result(binding)
  end
end
