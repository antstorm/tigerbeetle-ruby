require_relative './lib/tigerbeetle/platforms'

TB_CLIENT_DIR = './ext/tb_client'.freeze
NATIVE_DIR = './lib/tb_client/native'.freeze

task :compile do
  cd TB_CLIENT_DIR do
    ruby 'extconf.rb'
    sh 'make clean'
    sh 'make'
    sh 'make install'
  end
end

task :clean do
  cd TB_CLIENT_DIR do
    sh 'rm -rf ./pkg'
    sh 'rm -f pkg.tar.gz'
  end
  rm_rf NATIVE_DIR
end

task package: [:compile] do
  cd TB_CLIENT_DIR do
    sh 'tar -czf pkg.tar.gz -C ./pkg .'
  end
end

namespace :gem do
  desc 'Build a platform-specific gem'
  task :native, [:platform] do |_t, args|
    platform = args[:platform]
    pkg_dir = File.join(TB_CLIENT_DIR, 'pkg')
    raise "Compiled binaries not found in #{pkg_dir}. Run `rake compile` first." unless Dir.exist?(pkg_dir)

    targets = TigerBeetle::PLATFORMS.fetch(platform)

    targets.each do |target|
      src = File.join(pkg_dir, target)
      dst = File.join(NATIVE_DIR, target)
      mkdir_p dst
      cp_r Dir["#{src}/*"], dst
    end

    Bundler.with_unbundled_env do
      sh "TB_PLATFORM=#{platform} gem build tigerbeetle.gemspec"
    end

    rm_rf NATIVE_DIR
  end

  desc 'Build the source (fallback) gem'
  task :source do
    Bundler.with_unbundled_env { sh 'gem build tigerbeetle.gemspec' }
  end

  desc 'Build all platform gems and the source gem'
  task :all do
    TigerBeetle::PLATFORMS.each_key do |platform|
      Rake::Task['gem:native'].execute(platform:)
    end

    Rake::Task['gem:source'].execute
  end
end
