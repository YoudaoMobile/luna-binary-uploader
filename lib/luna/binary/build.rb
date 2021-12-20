require "luna/binary/uploader/version"
require "cocoapods"
require 'cocoapods-imy-bin/native/sources_manager'
require 'cocoapods-imy-bin/config/config'
require 'cocoapods-imy-bin'
require 'json'
require 'luna/binary/common/common'

module Luna
    module Binary
        class Build
            attr_accessor :workspace
            attr_accessor :scheme
            def initialize
                
            end

            def run 
                return createFrameworks
            end

            def command(c)
                return Common.instance.command(c)
            end

            def createFrameworks
                isNext = true
                puts "请将二进制开关关闭，确保每个模块都是源码运行，因为二进制的因素有可能source缓存还是会引入二进制".yellow
                Install.new(false)
                Common.instance.deleteDirectory(binary_path_arm)
                tempLunaUploaderPath = Common.instance.tempLunaUploaderPath
                isNext = command("xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration Debug -derivedDataPath '#{tempLunaUploaderPath}/build/arm/temp'") if isNext == true
                isNext = command("cp -r #{tempLunaUploaderPath}/build/arm/temp/Build/Products/Debug-iphoneos #{binary_path_arm}") if isNext == true #本可以用CONFIGURATION_BUILD_DIR直接指定结果文件夹，结果经常性的编译报错
                Common.instance.deleteDirectory(binary_path_x86)
                isNext = command("xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration Debug -derivedDataPath '#{tempLunaUploaderPath}/build/x86/temp' -destination 'platform=iOS Simulator,name=iPhone 11'") if isNext == true
                isNext = command("cp -r #{tempLunaUploaderPath}/build/x86/temp/Build/Products/Debug-iphonesimulator #{binary_path_x86}") if isNext == true
                mergeFrameWorks(binary_path_arm, binary_path_x86) if isNext == true
                return isNext
            end
    
            def mergeFrameWorks(binary_path_arm, binary_path_x86)
                Common.instance.deleteDirectory(binary_path_merged)
                dedupingMapper = {}
                failList = []
                p lockfile.pod_names
                lockfile.pod_names.each { |i|
                    item = i.split("/").first
                    if dedupingMapper[item] == nil
                        begin
                            puts item.yellow
                            armPath = findFramework(item,binary_path_arm)
                            x86Path = findFramework(item,binary_path_x86)

                            is_merge = mergeFrameWork(item, armPath, x86Path) if armPath != nil && x86Path != nil
                            trasher_path = "#{Common.instance.tempLunaUploaderPath}/trasher"
                            failList << "#{item} 存在问题，已搬到#{trasher_path}" if is_merge == false
                            command("mkdir #{trasher_path}; mv #{binary_path_merged}/#{item} #{trasher_path}") if is_merge == false
                            dedupingMapper[item] = item
                        rescue => exception
                            failList << "#{item} exception : #{exception}"
                        ensure
                            
                        end
                       
                    end 
                }
                
                puts "合并后的framework的路径为:#{binary_path_merged}".green
                puts "-=-=-=-=-=-=-=-=merge 失败名单-=-=-=-=-=-=-=-=-=-=" if failList.length > 0
                failList.each { |item|
                    puts item.red
                }
            end

            def lockfile
                return Common.instance.lockfile
            end
    
            def xcodeSimulators
                # simulators = JSON.parse(%x("xcodebuild -workspace #{workspace} -scheme #{scheme} -showdestinations"))  
                
            end
    
            def mergeFrameWork(moduleName, path1, path2)
                command("mkdir -p #{binary_path_merged}; cp -r #{File.dirname(path1)} #{binary_path_merged}; cp -r #{File.dirname(path2)} #{binary_path_merged}; mv #{binary_path_merged}/#{File.basename(File.dirname(path1))} #{binary_path_merged}/#{moduleName};")
                framework_name = moduleName.gsub("-", "_")
                return command("lipo -create #{path2}/#{framework_name} #{path1}/#{framework_name} -output #{binary_path_merged}/#{moduleName}/#{framework_name}.framework/#{framework_name}")
            end
    
            def findFramework(moduleName, binary_path)
                pathArr = Dir.glob("#{binary_path}/**/#{moduleName.sub('-', '_')}.framework")
                if pathArr != nil
                    return pathArr.first
                else
                    return nil
                end
            end
    
    
            def binary_path_merged
                return Common.instance.binary_path_merged
            end
    
            def binary_path_arm
                return Common.instance.binary_path_arm
            end
    
            def binary_path_x86
                return Common.instance.binary_path_x86
            end
        end
    end
end 
