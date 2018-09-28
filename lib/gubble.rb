require 'erb'

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
				(@request.path == @url_path+'/' || @request.path == @url_path)
			@response.set_redirect(
				WEBrick::HTTPStatus::TemporaryRedirect,
				@url_path+"/view?page=#{u('/')}",
			)
			return
		end

		if @request.request_method == 'GET' && @request.path == @url_path+'/view'
			view
			return
		end

		@response.status = 400
		@response.body = 'Invalid request' # TODO(horgh): template
		return
	end

	private

	def view
		external_path = @request.query()['page']

		if external_path.nil?
			@response.status = 400
			@response.body = 'No page given' # TODO(horgh): template
			return
		end

		external_path = normalize_path(external_path)
		if external_path.nil?
			@response.status = 400
			@response.body = 'Invalid file' # TODO(horgh): template
			return
		end

		fs_path = File.join(@data_dir, external_path)

		if !File.exist?(fs_path)
			@response.status = 404
			@response.body = 'File not found' # TODO(horgh): template
			return
		end

		if Dir.exist?(fs_path)
			render_dir(fs_path, external_path)
			return
		end

		render_file(fs_path, external_path)
		return
	end

	def normalize_path(external_path)
		return nil if /[^a-zA-Z0-9_\/ .-]/.match(external_path)
		return nil if /\.\./.match(external_path)
		external_path = '' if external_path == '/'
		return external_path
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
		render_template('directory.rhtml', binding)
		return
	end

	def render_file(fs_path, external_path)
		contents = File.read(fs_path)
		render_template('file.rhtml', binding)
		return
	end

	def render_template(name, binding)
		erb = ERB.new(
			File.read(
				File.join(@template_dir, name),
			),
		)
		@response.content_type = 'text/html; charset=utf-8'
		@response.body = erb.result(binding)
		return
	end
end
