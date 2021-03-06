#!/usr/bin/env ruby

require 'gubble'
require 'optparse'
require 'webrick'

def main
  args = parse_args
  return false if args.nil?

  server = WEBrick::HTTPServer.new Port: args[:port]
  trap('INT') { server.shutdown }
  server.mount_proc '/' do |req, res|
    Gubble.new(
      args[:url_path],
      args[:data_dir],
      args[:template_dir],
      req,
      res,
    ).run
  end
  server.start

  true
end

def parse_args
  args = {
    port: 8081,
    url_path: '/',
  }
  # rubocop:disable Metrics/LineLength
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
    opts.on(
      '-d',
      '--data-dir DIR',
      'Directory containing data files',
    ) { |v| args[:data_dir] = v }
    opts.on(
      '-p',
      '--port PORT',
      "Port to listen on (defaults to #{args[:port]})",
    ) { |v| args[:port] = v }
    opts.on(
      '-t',
      '--template-dir DIR',
      'Directory containing template files',
    ) { |v| args[:template_dir] = v }
    opts.on(
      '-u',
      '--url-path PATH',
      "URL path to Gubble. If you want it to be reachable at /gubble instead of /, use this (defaults to #{args[:url_path]}",
    ) { |v| args[:url_path] = v }
  end.parse!
  # rubocop:enable Metrics/LineLength

  if !args.key?(:data_dir)
    STDERR.puts 'You must provide a data directory.'
    return nil
  end
  if !Dir.exist?(args[:data_dir])
    STDERR.puts "Directory `#{args[:data_dir]}' does not exist."
    return nil
  end

  args[:port] = args[:port].to_i
  if args[:port] <= 0
    STDERR.puts 'Invalid port.'
    return nil
  end

  if !args.key?(:template_dir)
    STDERR.puts 'You must provide a template directory.'
    return nil
  end
  if !Dir.exist?(args[:template_dir])
    STDERR.puts "Directory `#{args[:template_dir]}' does not exist."
    return nil
  end

  args
end

exit true if main
exit false
