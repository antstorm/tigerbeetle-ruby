TB_CLIENT_DIR = './ext/tb_client'.freeze

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
end

task package: [:compile] do
  cd TB_CLIENT_DIR do
    sh 'tar -czf pkg.tar.gz -C ./pkg .'
  end
end
