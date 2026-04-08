#!/usr/bin/env ruby
require 'mkmf'
require_relative '../../lib/tigerbeetle/version'

makefile_path = File.join('Makefile')
client_version = TigerBeetle::TB_VERSION
min_client_version = '0.16.4'

makefile = ''

if find_executable('zig') && File.exist?('./tigerbeetle/build.zig')
  makefile = <<~MFILE
    all:
    \techo "Compiling native TB client from the source"
    \tzig version
    \tunset -v DESTDIR && cd ./tigerbeetle && zig build clients:c -Dconfig-release=#{client_version} -Dconfig-release-client-min=#{min_client_version}
    \n\n
    install:
    \tcp -rf ./tigerbeetle/src/clients/c/lib ./pkg
    \n\n
    clean:
    \trm -rf ./tigerbeetle/src/clients/c/lib
  MFILE
else
  puts "ERROR: Cannot compile TigerBeetle native client."
  puts ""
  puts "This gem requires compilation from source, but the build tools were not found."
  puts "Requirements:"
  puts "  - Zig compiler (https://ziglang.org/download/)"
  puts "  - TigerBeetle source in ext/tb_client/tigerbeetle/"
  puts "    (run: git submodule update --init --recursive)"
  puts ""
  puts "Alternatively, install a precompiled platform-specific gem:"
  puts "  gem install tigerbeetle --platform ruby"
  puts "  # or let RubyGems auto-select: gem install tigerbeetle"
  exit 1
end

File.open(makefile_path, 'w') do |f|
  f.puts makefile
end
