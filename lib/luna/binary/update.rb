require 'luna/binary/common/common'
require 'luna/binary/delete'
require 'json'

module Luna
    module Binary
        class Update
            attr_accessor :binary_path
            attr_accessor :request_result_hash

            def run 
                spec_repo_binary = Common.instance.createNeedFrameworkMapper
                failList = []
                successList = []
                dependenciesMapper = Common.instance.dependenciesMapper
                spec_repo_binary.each { |k,v|
                    if request_result_hash[k] == nil || request_result_hash[k].include?(v) == false
                        begin
                            uploader = Common.instance.upload_lockitem(dependenciesMapper, k, binary_path)
                            if uploader != nil
                                successList << uploader
                            else
                                failList << "#{k} #{v} 失败，请确保在非二进制状态下"
                            end
                            
                        rescue => exception
                            failList << "#{k} exception: #{exception}"
                        ensure
                            
                        end
                    else   
                      failList << "已存在name: #{k} version #{v} 的framework"
                    end 
                } 
                puts "-=-=-=-=-=-=-=-=framework制作中-=-=-=-=-=-=-=-=-=-=".yellow
                successList.each { |item|
                    puts "#{item.podspecName} 制作中".yellow
                    item.upload
                }

                puts "-=-=-=-=-=-=-=-=更新成功名单-=-=-=-=-=-=-=-=-=-=".yellow
                successList.each { |item|
                    puts "#{item.podspecName}".yellow
                }

                puts "-=-=-=-=-=-=-=-=update 失败名单-=-=-=-=-=-=-=-=-=-=".yellow if failList.length > 0
                failList.each {|item|
                    puts item.red
                }

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