require 'luna/binary/common/common'
require 'luna/binary/delete'
require 'json'

module Luna
    module Binary
        class Refresh
            attr_accessor :binary_path
            attr_accessor :request_result_hash

            def run 
                spec_repo_binary = createNeedFrameworkMapper
                rootPath = "#{Luna::Binary::Common.instance.tempLunaUploaderPath}/refresh"
                Luna::Binary::Common.instance.deleteDirectory("#{rootPath}")
                system "mkdir -p #{rootPath};"
                failList = []
                spec_repo_binary.each { |k,v|
                    if request_result_hash[k] != nil && request_result_hash[k].include?(v)
                        begin
                            pathArr = Dir.glob("#{binary_path}/**/#{k.sub("-","_")}.framework")
                            if pathArr != nil
                                Pod::UserInterface.puts "#{pathArr.first} #{k}".yellow
                                srcPath = File.dirname(pathArr.first)
                                system "cp -r #{srcPath} #{rootPath};"
                                File.rename("#{rootPath}/#{File.basename(srcPath)}", "#{rootPath}/#{k}")
                                zipCommand = "cd #{rootPath};zip -r #{k}.zip #{k}"
                                p zipCommand
                                system zipCommand
                                Luna::Binary::Delete.new(k,v).deleteBinaryFramework
                                command = "cd #{rootPath};curl #{CBin.config.binary_upload_url} -F \"name=#{k}\" -F \"version=#{v}\" -F \"annotate=#{k}_#{v}_log\" -F \"file=@#{k}.zip\""
                                p command 
                                system command
                            end 
                        rescue => exception
                            p exception
                            failList << "#{k} #{exception}"
                        else
                            
                        end
                    else   
                      failList << "name: #{k}"
                    end 
                } 
                p "exception:#{failList}"
            end

            def lockfile 
                return Luna::Binary::Common.instance.lockfile
            end

            def request_result_hash
                if @request_result_hash == nil
                    @request_result_hash = Luna::Binary::Common.instance.request_result_hash
                end
                return @request_result_hash
            end
            
            def createNeedFrameworkMapper
                return Luna::Binary::Common.instance.createNeedFrameworkMapper
            end
        end 
    end
end