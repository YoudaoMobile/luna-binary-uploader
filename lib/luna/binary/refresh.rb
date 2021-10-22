require 'luna/binary/common/common'
require 'luna/binary/delete'
require 'json'

module Luna
    module Binary
        class Refresh
            attr_accessor :binary_path
            attr_accessor :request_result_hash

            def run 
                spec_repo_binary = Common.instance.createNeedFrameworkMapper
                dependencies_mapper = Common.instance.dependenciesMapper
                failList = []
                successList = []
                spec_repo_binary.each { |k,v|
                    if request_result_hash[k] != nil && request_result_hash[k].include?(v)
                        begin
                            puts "#{k} #{v}".yellow
                            
                            uploader = Common.instance.upload_lockitem(dependencies_mapper,k ,binary_path, true)
                            if uploader != nil
                                Delete.new(k,v).delete
                                puts "#{k} #{v} 重新制作上传".yellow
                                uploader.upload
                                successList << "#{k} #{v}"
                            else
                                failList << "#{k} #{v} 失败，请确保在非二进制状态下"
                            end
        
                        rescue => exception
                            failList << "#{k} #{v} exception:#{exception}"
                        ensure
                            
                        end                        
                    else   
                      failList << "name: #{k} #{v} 在服务不存在"
                    end 
                } 
                puts "-=-=-=-=-=-=-=-=重新上传的名单-=-=-=-=-=-=-=-=".yellow
                successList.each { |item|
                    puts item.green
                }

                puts "-=-=-=-=-=-=-=-=失败的名单-=-=-=-=-=-=-=-=".yellow if failList.length > 0
                failList.each { |item|
                    puts item.red
                }
            end

            def in_framework_service(dependencies_mapper, name, version)
                 dependency = dependencies_mapper[name]
                if lockfile.dependencies_mappe
                else
                    
                end
            end

            def lockfile 
                return Common.instance.lockfile
            end

            def request_result_hash
                if @request_result_hash == nil
                    @request_result_hash = Common.instance.request_result_hash
                end
                return @request_result_hash
            end
        
        end 
    end
end