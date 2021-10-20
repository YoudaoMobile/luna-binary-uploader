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
            localPathMapper = {}
    
            dependenciesMapper = lockfile.dependencies.map { |item| [item.name, item]}.to_h
            dedupingMapper = {}
            lockfile.pod_names.each { |item|
                    moduleName = item.split('/').first
                    if !moduleName["/"] && dedupingMapper[moduleName] == nil
                        dedupingMapper[moduleName] = moduleName
                        Pod::UserInterface.puts moduleName.yellow
                        if dependenciesMapper[moduleName]
                            lockContent = lockfile.dependencies_to_lock_pod_named(moduleName)
                            if lockContent  #dependencies 应该拿不到所有的spec的依赖，我理解只能拿到podfile里面标明的,词典碰到dependency 没有bonmot的情况
                                lockContent.each { |lockItem|
                                    begin
                                        if lockItem.external_source == nil
                                            uploader = uploadLintPodSpec(moduleName, lockItem.specific_version, binary_path) 
                                            if uploader != nil
                                                successList << uploader
                                            end
                                        else 
                                            p lockItem.external_source
                                            gitURL = lockItem.external_source['git'.parameterize.underscore.to_sym]
                                            tag = lockItem.external_source['tag'.parameterize.underscore.to_sym]
                                            path = lockItem.external_source['path'.parameterize.underscore.to_sym]
                                            p "#{moduleName} git: #{gitURL} tag: #{tag} path: #{path}"
                                            if path
                                                pathArr = Dir.glob("#{Dir.pwd}/#{path}/**/#{moduleName}.podspec")
                                                if pathArr 
                                                    uploader = Luna::Binary::Uploader::SingleUploader.new(moduleName, "", "", binary_path)
                                                    uploader.specification=Pod::Specification.from_file(pathArr.first)
                                                    uploader.specificationWork
                                                    localPathMapper[moduleName] = pathArr.first
                                                end
                                                
                                            elsif gitURL && tag && !moduleName["/"]
                                                uploader = Luna::Binary::Uploader::SingleUploader.new(moduleName, gitURL, tag, binary_path)
                                                uploader.specificationWork
                                                successList << uploader
                                            end
                                        end
                                    rescue => exception
                                        failList << exception
                                    ensure
                                        
                                    end
                                }   
                            end
                        else
                            begin
                                uploader = uploadLintPodSpec(moduleName, lockfile.version(moduleName), binary_path) 
                                if uploader != nil
                                    successList << uploader
                                end
                            rescue => exception
                                failList << exception
                            ensure
                                
                            end
                        end
                    end
            }
            p "-=-=-=-=-=-=-=-=-=-=-=-命令生成=-=-=-=-=-=-=-=-=-=-=-=-=-="
            hasInCocopodsSpec = []
            externalSpec = []
            failPrint = []
        
            successList.each { |item|
                if item.gitUrl.length > 0
                    externalSpec << item
                else
                    hasInCocopodsSpec << item
                end
            }
            hasInCocopodsSpec.each { |item|
                begin
                    item.printPreUploadCommand
                rescue => exception
                    # p exception
                    failPrint << "#{exception}"
                ensure
                    
                end   
            }
            externalSpec.each { |item|
                begin
                    item.printPreUploadCommand
                rescue => exception
                    # p exception
                    failPrint << "#{exception}"
                ensure
                    
                end 
            }

            localPathMapper.each { |k,v|
                p "lbu single #{k} #{v} #{binary_path}"
            }

            p "-=-=-=-=-=-=-=-=-=-=-=-命令生成end=-=-=-=-=-=-=-=-=-=-=-=-=-="
            p "错误信息:#{failPrint}"
            execUpload(hasInCocopodsSpec)
            execUpload(externalSpec)
        end

        def findLintPodspec(moduleName)
            return Luna::Binary::Common.instance.findLintPodspec(moduleName) 
        end

        def uploadLintPodSpec(moduleName, specificVersion, binaryPath) 
            set = findLintPodspec(moduleName)
            if set 
                pathArr = set.specification_paths_for_version(specificVersion)
                if pathArr.length > 0
                    uploader = Luna::Binary::Uploader::SingleUploader.new(moduleName, "", "", binaryPath)
                    uploader.specification=Pod::Specification.from_file(pathArr.first)
                    uploader.specificationWork
                end
            end
            return uploader
        end

        def execUpload(items)
            if need_upload != nil && need_upload == "upload"
                items.each { |item|
                    begin
                        item.upload
                    rescue => exception
                        p "异常上传过程中出现了:#{exception}"
                    else
                        
                    end
                    
                }
            end
        end

        def command(c)
            return Luna::Binary::Common.instance.command(c)
        end

    end
  end
end