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
                createFrameworks
            end

            def command(c)
                return Luna::Binary::Common.instance.command(c)
            end

            def createFrameworks
                isNext = true
                Pod::UserInterface.puts "请将二进制开关关闭，确保每个模块都是源码运行，因为二进制的因素有可能source缓存还是会引入二进制".yellow
                command("rm -rf #{Dir.pwd}/Pods")
                isNext = command("pod install")
                Luna::Binary::Common.instance.deleteDirectory(binary_path_arm)
                isNext = command("xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration Debug -derivedDataPath '#{Dir.pwd}/build/arm' CONFIGURATION_BUILD_DIR='#{binary_path_arm}'") if isNext == true
                Luna::Binary::Common.instance.deleteDirectory(binary_path_x86)
                isNext = command("xcodebuild -workspace #{workspace} -scheme #{scheme} -configuration Debug -derivedDataPath '#{Dir.pwd}/build/x86' CONFIGURATION_BUILD_DIR='#{binary_path_x86}' -destination 'platform=iOS Simulator,name=iPhone 11'") if isNext == true
                mergeFrameWorks(binary_path_arm, binary_path_x86) if isNext == true
            end
    
            def mergeFrameWorks(binary_path_arm, binary_path_x86)
                Luna::Binary::Common.instance.deleteDirectory(binary_path_merged)
                dedupingMapper = {}
                lockfile.pod_names.each { |item|
                    if item["/"] == nil && dedupingMapper[item] == nil
                        Pod::UserInterface.puts item.yellow
                        armPath = findFramework(item,binary_path_arm)
                        x86Path = findFramework(item,binary_path_x86)
                        mergeFrameWork(item, armPath, x86Path) if armPath != nil && x86Path != nil
                        dedupingMapper[item] = item
                    end 
                }
                
                Pod::UserInterface.puts "合并后的framework的路径为:#{binary_path_merged}".yellow
            end

            def lockfile
                return Luna::Binary::Common.instance.lockfile
            end
    
            def xcodeSimulators
                # simulators = JSON.parse(%x("xcodebuild -workspace #{workspace} -scheme #{scheme} -showdestinations"))  
                
            end
    
            def mergeFrameWork(moduleName, path1, path2)
                command("mkdir -p #{binary_path_merged}; cp -r #{File.dirname(path1)} #{binary_path_merged}; mv #{binary_path_merged}/#{File.basename(File.dirname(path1))} #{binary_path_merged}/#{moduleName};")
                return command("lipo -create #{path2}/#{moduleName} #{path1}/#{moduleName} -output #{binary_path_merged}/#{moduleName}/#{moduleName}.framework/#{moduleName}")
            end
    
            def findFramework(moduleName, binary_path)
                pathArr = Dir.glob("#{binary_path}/**/#{moduleName}.framework")
                if pathArr != nil
                    return pathArr.first
                else
                    return nil
                end
            end
    
    
            def binary_path_merged
                return Luna::Binary::Common.instance.binary_path_merged
            end
    
            def binary_path_arm
                return Luna::Binary::Common.instance.binary_path_arm
            end
    
            def binary_path_x86
                return Luna::Binary::Common.instance.binary_path_x86
            end
        end
    end
end 
