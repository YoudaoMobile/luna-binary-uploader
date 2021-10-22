require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'

module Luna
    module Binary
        class Init
            attr_reader :url
            def initialize(url)
                @url = url
                run
            end

            def run
                 Common.instance.command("curl -o #{Pod::Config.instance.home_dir}/bin_dev.yml #{url}")
                 Common.instance.command("pod repo add z-ios-framework-spec-repo #{CBin.config.binary_repo_url}")
            end

        end
    end
end