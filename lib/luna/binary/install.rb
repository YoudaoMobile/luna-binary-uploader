require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'

module Luna
    module Binary
        class Install
            attr_reader :is_open
            def initialize(is_open)
                @is_open = is_open
                run
            end

            def run
                buffer = ""
                podfile_path = Dir.pwd + "/Podfile"
                IO.foreach(podfile_path) { |line|
                    if line.match(/@use_luna_frameworks =/)  || line.match(/@use_luna_frameworks=/)
                        buffer += "@use_luna_frameworks = #{is_open}\n"
                    else
                        buffer += line
                    end
                }   
                File.open(podfile_path, "w") { |source_file|
                    source_file.write buffer
                }

                Common.instance.command("rm -rf #{Dir.pwd}/Pods")
                Common.instance.command("pod install")

            end
        end
    end
end