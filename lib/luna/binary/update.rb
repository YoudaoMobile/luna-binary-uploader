require 'luna/binary/common/common'
require 'luna/binary/delete'
require 'json'

module Luna
    module Binary
        class Update
            attr_accessor :binary_path
            attr_accessor :request_result_hash

            def run 
                spec_repo_binary = createNeedFrameworkMapper
                rootPath = "#{Luna::Binary::Common.instance.tempLunaUploaderPath}/update"
                Luna::Binary::Common.instance.deleteDirectory("#{rootPath}")
                system "mkdir -p #{rootPath};"
                failList = []
                successList = []
                dependenciesMapper = lockfile.dependencies.map { |item| [item.name, item]}.to_h
                spec_repo_binary.each { |k,v|
                    if request_result_hash[k] == nil || request_result_hash[k].include?(v) == false
                        moduleName = k
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
                                                    successList<<uploader
                                                end
                                                
                                            elsif gitURL && tag && !moduleName["/"]
                                                uploader = Luna::Binary::Uploader::SingleUploader.new(moduleName, gitURL, tag, binary_path)
                                                uploader.specificationWork
                                                successList << uploader
                                            end
                                        end
                                    rescue => exception
                                        # raise exception
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
                              
                            ensure
                                
                            end
                        end
                    else   
                      failList << "已存在name: #{k}"
                    end 
                } 

                successList.each { |item|
                    Pod::UserInterface.puts "#{item} 制作中".yellow
                    item.upload
                }
                p "exception:#{failList}"
            end

            def lockfile 
                return Luna::Binary::Common.instance.lockfile
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