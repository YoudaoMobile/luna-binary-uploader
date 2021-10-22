require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'


module Luna
  module Binary
    class Analysis 
        
        attr_accessor :need_upload
        attr_accessor :binary_path


        def initialize
            validate!
        end

        def validate!
            arr = Dir.glob(Luna::Binary::Common.instance.podFilePath)
            if arr == nil 
                raise '当前路径下没有Podfile'
            end
        end

        def lockfile
            return Luna::Binary::Common.instance.lockfile
        end

        def run
            failList = []
            successList = []
    
            dependenciesMapper = Luna::Binary::Common.instance.dependenciesMapper
            dedupingMapper = {}
            lockfile.pod_names.each { |item|
                    moduleName = item.split('/').first
                    if !moduleName["/"] && dedupingMapper[moduleName] == nil
                        dedupingMapper[moduleName] = moduleName
                        puts moduleName.yellow
                        begin
                            uploader = Luna::Binary::Common.instance.upload_lockitem(dependenciesMapper, moduleName, binary_path)
                            if uploader != nil
                                successList << uploader
                            else
                                failList << "#{moduleName} 为空"
                            end
                            
                        rescue => exception
                            failList << "#{moduleName} exception: #{exception}"
                        ensure
                            
                        end
                    end
            }
            puts "-=-=-=-=-=-=-=-=-=-=-=-打印错误信息=-=-=-=-=-=-=-=-=-=-=-=-=-=".yellow if failList.length > 0
            puts "请查看下时候存在影响，如怀疑程序错误请联系作者".yellow if failList.length > 0
            failList.each{ |item|
                puts item.red
            }

            puts "-=-=-=-=-=-=-=-=-=-=-=-命令生成=-=-=-=-=-=-=-=-=-=-=-=-=-=".yellow
            hasInCocopodsSpec = []
            externalSpec = []
            local_spec = []
            failPrint = []
        
            successList.each { |item|
                if item.local_path
                    local_spec << item
                elsif item.gitUrl.length > 0
                    externalSpec << item
                else
                    hasInCocopodsSpec << item
                end
            }
            hasInCocopodsSpec.each { |item|
                begin
                    item.printPreUploadCommand
                rescue => exception
                    failPrint << "#{item.podspecName} exception: #{exception}"
                ensure
                    
                end   
            }
            externalSpec.each { |item|
                begin
                    item.printPreUploadCommand
                rescue => exception
                    failPrint << "#{item.podspecName} exception: #{exception}"
                ensure
                    
                end 
            }

            local_spec.each { |item|
                begin
                    item.printPreUploadCommand
                rescue => exception
                    failPrint << "#{item.podspecName} exception: #{exception}"
                ensure
                    
                end 
            }

            puts "-=-=-=-=-=-=-=-=-=-=-=-命令生成end=-=-=-=-=-=-=-=-=-=-=-=-=-=".yellow

            failPrint.each{ |item|
                puts item.red
            }

            execUpload(successList)
        end
        
        def execUpload(items)
            if need_upload != nil && need_upload == "upload"
                puts "-=-=-=-=-=-=-=-=-=-=-=-开始上传=-=-=-=-=-=-=-=-=-=-=-=-=-=".yellow
                items.each { |item|
                    begin
                        item.upload
                    rescue => exception
                        puts "异常上传过程中出现了:#{exception}".red
                    else
                        
                    end
                    
                }
                puts "-=-=-=-=-=-=-=-=-=-=-=-上传结束=-=-=-=-=-=-=-=-=-=-=-=-=-=".yellow
            end
        end

        def command(c)
            return Luna::Binary::Common.instance.command(c)
        end

    end
  end
end