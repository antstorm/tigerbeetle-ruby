module TBClient
  module SharedLib
    class << self
      NATIVE_DIR = File.expand_path('native', __dir__).freeze
      PKG_DIR = File.expand_path('../../ext/tb_client/pkg', __dir__).freeze

      def path
        prefix = ''
        linux_libc = ''
        suffix = ''

        arch, os = RUBY_PLATFORM.split('-')

        arch =
          case arch
          when 'x86_64', 'amd64' then 'x86_64'
          when 'aarch64', 'arm64' then 'aarch64'
          else
            raise "Unsupported architecture: #{arch}"
          end

        case os
        when /darwin/
          prefix = 'lib'
          system = 'macos'
          suffix = '.dylib'
        when 'linux'
          prefix = 'lib'
          system = 'linux'
          linux_libc = detect_libc
          suffix = '.so'
        when 'windows'
          system = 'windows'
          suffix = '.dll'
        else
          raise "Unsupported system: #{os}"
        end

        target_dir = "#{arch}-#{system}#{linux_libc}"
        filename = "#{prefix}tb_client#{suffix}"

        native_path = File.join(NATIVE_DIR, target_dir, filename)
        return native_path if File.exist?(native_path)

        pkg_path = File.join(PKG_DIR, target_dir, filename)
        return pkg_path if File.exist?(pkg_path)

        raise "tb_client library not found. Searched:\n  #{native_path}\n  #{pkg_path}"
      end

      private

      def detect_libc
        ldd_output = `ldd --version 2>&1 | head -n 1`.downcase

        if ldd_output.include?('musl')
          '-musl'
        elsif ldd_output.include?('gnu') || ldd_output.include?('glibc')
          '-gnu.2.27'
        else
          raise "Unsupported libc: #{ldd_output}"
        end
      end
    end
  end
end
