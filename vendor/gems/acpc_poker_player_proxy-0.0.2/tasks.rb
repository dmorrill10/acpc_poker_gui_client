require 'fileutils'

module Tasks
   def tag_gem_version(version)
      puts "Tagging #{version}..."
      system "git tag -a #{version} -m 'Tagging #{version}'"
      puts "Pushing #{version} to git..."
      system "git push --tags"
   end
   
   def integrate_into_app_fn(rel_app_root_path, gem_name)
      unless rel_app_root_path && gem_name
         raise "Usage: $0 integrate <app to integrate #{gem_name} into>"
      end
      
      app_root_path = File.expand_path "../#{rel_app_root_path}", __FILE__
      new_gem_path = "#{app_root_path}/vendor/gems/"
      
      puts "Unpacking \"#{gem_name}\" to \"#{new_gem_path}\"..."
      system "gem unpack #{gem_name} --target #{new_gem_path}"
   end
   
   def integrate_into_app(rel_app_root_path, gem_name)
      begin
         integrate_into_app_fn rel_app_root_path, gem_name
      rescue => e
         message = e.message || $?
         puts message
      end
   end
end