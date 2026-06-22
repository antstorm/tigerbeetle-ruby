require_relative './lib/tigerbeetle/version'
require_relative './lib/tigerbeetle/platforms'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 3.0'

  spec.name          = 'tigerbeetle'
  spec.version       = TigerBeetle::VERSION
  spec.authors       = ['Anthony D']
  spec.email         = ['anthony.dmitriyev@gmail.com']

  spec.summary       = 'TigerBeetle Ruby client'
  spec.description   = 'A Ruby client for interacting with the high performance TigerBeetle ledger'
  spec.homepage      = 'https://github.com/antstorm/tigerbeetle-ruby'
  spec.license       = 'Apache-2.0'

  spec.require_paths = ['lib']

  spec.post_install_message = <<-EOS
    BREAKING CHANGES WARNING!

    Starting with the next major version this gem will get replaced with the TigerBeetle
    team owned implementation. While it is very similar, it includes a number of breaking
    changes. Please refer to this migration guide when updating:

    https://github.com/tigerbeetle/tigerbeetle/blob/main/src/clients/ruby/docs/migration.md
  EOS

  platform = ENV['TB_PLATFORM']
  files = [
    Dir['lib/**/*.rb'],
    'CHANGELOG.md',
    'LICENSE',
    'README.md',
    'tigerbeetle.gemspec'
  ].flatten

  if platform
    spec.platform = platform
    native_files = TigerBeetle::PLATFORMS.fetch(platform).flat_map do |target|
      Dir["lib/tb_client/native/#{target}/*"]
    end
    spec.files = files + native_files
  else
    ext = 'ext/tb_client/extconf.rb'
    spec.extensions = [ext]
    spec.files = files + [
      ext,
      Dir['ext/tb_client/tigerbeetle/src/**/*.{zig,c,h}'],
      'ext/tb_client/tigerbeetle/build.zig',
      'ext/tb_client/tigerbeetle/LICENSE'
    ].flatten
  end

  spec.add_dependency 'ffi', '~> 1.14'

  spec.add_development_dependency 'rake', '~> 13.1'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'pry', '~> 0.15'
end
