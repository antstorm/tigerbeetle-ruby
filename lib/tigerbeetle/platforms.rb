module TigerBeetle
  PLATFORMS = {
    'x86_64-darwin'  => ['x86_64-macos'],
    'arm64-darwin'   => ['aarch64-macos'],
    'x86_64-linux'   => ['x86_64-linux-gnu.2.27', 'x86_64-linux-musl'],
    'aarch64-linux'  => ['aarch64-linux-gnu.2.27', 'aarch64-linux-musl'],
    'x64-mingw-ucrt' => ['x86_64-windows'],
  }.freeze
end
