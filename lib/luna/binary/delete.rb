require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'

module Luna
    module Binary
        class Delete 
            attr_reader :name
            attr_reader :version

            def initialize(name, version)
                @name = name
                @version = version
                validate!
            end

            def validate!
                raise "缺少参数" unless name
                raise "缺少参数" unless version
            end 

            def delete
                begin
                    deleteRepo
                rescue => exception
                    
                ensure
                    deleteBinaryFramework
                end
            end

            def deleteRepo
                command = "cd #{Common.instance.repoPath}; git stash;git checkout master;git pull origin master;"
                system command
                Common.instance.deleteDirectory("#{Common.instance.repoPath}/#{name}/#{version}")
                commandADD = "cd #{Common.instance.repoPath};git add .; git commit -m 'DEL::#{name}-#{version} by LBU'; git push -f origin master"
                system commandADD
            end

            def deleteBinaryFramework 
                command = "curl -X 'DELETE' #{Common.instance.binary_upload_url}/#{name}/#{version}"
                p command 
                system command
            end
        end
    end
end