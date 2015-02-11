=begin

Copyright 2014, Alexander C. Schreyer
All rights reserved

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

License:        GPL (http://www.gnu.org/licenses/gpl.html)

Author :        Alexander Schreyer, www.alexschreyer.net, mail@alexschreyer.net

Website:        http://www.alexschreyer.net/projects/plugin-loader-for-sketchup

Name :          PluginLoader

Version:        1.6

Date :          2/11/2015

Description :   Adds a submenu to the Plugins menu to offer these
                functions:
                - Load single RB plugin (on-demand)
                - Load all RB plugins from a folder (on-demand)
                - Install plugin from RBZ or ZIP file
                
Usage :         Place plugins and support files into a convenient location
                (e.g. a folder on a USB drive). Make sure correct plugin folder structure is kept.
                Then load plugins using this tool from that lcation on-demand. After restarting
                SketchUp, your plugin will be unloaded again.

History:        1.0 (3/9/2009):
                - first version
                1.1 (3/18/2009):
                - Added more plugin links and fixed some spelling
                - Added browser buttons and better explanation
                - Added help menu item and updated helpfile
                - Changed menu order a bit
                1.2 (11/3/2010):
                - Renamed some menu items
                - Added Google custom search
                - Added link to extension manager
                - Reformatted code and added module
                - Removed developer links (those are now in my Ruby Code Editor)
                - Changed layout of browser a bit
                - Fixed mac issues: dlg can't show modal, browser buttons dont work well
                1.3 (5/15/2013):
                - Added RBZ installing option
                - Updated archive links
                - Default file location is now userprofile
                - Plugin remembers last folder
                - Fixed up some dialogs and added more feedback
                - Now reports error if problem occurs
                - New folder structure
                - Fixed multiple loader code
                1.4 (5/16/2013):
                - Removed browser feature to comply with Trimble rules
                1.5 (2/17/2014):
                - Fixed saving of file paths to registry
                - Code cleanup
                1.6 (2/11/2015):
                - Cleaned up code
                - Added SU 15's dialog selector
                - Renamed plugin to extension where applicable
                
TODO List:      

=end


# ============================


require 'sketchup'


# ============================


module AS_extensions

  module AS_plugin_loader
  
  
    # ============================
    
    
    # Get default user directory as a start  
    @dir = (ENV['USERPROFILE'] != nil) ? ENV['USERPROFILE'] : 
           ((ENV['HOME'] != nil) ? ENV['HOME'] : File.dirname(__FILE__) )
    # Get working directory from last opened if it exists
    @last_dir = Sketchup.read_default "as_PluginLoader", "last_dir"
    @dir = @last_dir if @last_dir != nil
    # Do some spring cleaning on the path
    @dir = @dir.tr("\\","/")
    
    
    # ============================
  
  
    def self.load_plugin_file
    # Loads single plugin from RB file
    
      # Pick an RB file
      if Sketchup.version.to_f < 7.0
        f = UI.openpanel "Select a SketchUp Ruby extension file (with RB extension) to load it"
      else
        f = UI.openpanel( "Select a SketchUp Ruby extension file (with RB extension) to load it", @dir, "*.rb" )
      end
  
      if f
        begin
        
          raise "Selected file is not an RB file." if File.extname(f) != ".rb"
          
          # Load this plugin
          d = File.dirname(f) 
          $:.push d
          load f
          # Set directory as last used and give feedback
          @dir = d
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
          UI.messagebox "Successfully loaded Extension: \n\n#{f.upcase!}\n\nIt will remain available until you restart SketchUp."
          
        rescue => e
        
          UI.messagebox "Could not load extension: \n#{f.upcase!}\n\nError: #{e}"
          
        end
      end
      
    end # load_plugin_file
    
    
    # ============================
  
  
    def self.load_plugin_folder
    # Load all plugins from selected folder
    
      begin
      
        # Get directory of RB files. Can't use directory selection if less than 15
        v = Sketchup.version.to_f
        if v >= 15.0
          d = UI.select_directory(title: "Select Folder with SketchUp extensions (RB files) to load")
        elsif v >= 7.0    
          f = UI.openpanel( "Select any file - all extensions will be loaded from that folder", @dir, "*.rb" )
          d = File.dirname(f)    
        else       
          f = UI.openpanel "Select any file - all extensions will be loaded from that folder"
          d = File.dirname(f)    
        end
        
        raise "No valid directory supplied." if d == nil
    
        # Get all of the RB files in the directory
        rbfiles = Array.new
        Dir.chdir(d)
        rbfiles = Dir.glob("*.rb")
     
        raise "No valid RB files in directory." if rbfiles.empty?
  
        # Modified require_all function - loads all plugins in folder
        # p rbfiles
        $:.push d
        rbfiles.each {|f| load f}
        # Set directory as last used and give feedback 
        @dir = d
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
        UI.messagebox "Successfully loaded these extensions: \n\n#{rbfiles.join("\n").upcase!}\n\nThey will remain available until you restart SketchUp."
        
      rescue => e
      
        UI.messagebox "Did not load extensions.\n\nError: #{e}"
      
      end    
      
    end # load_plugin_folder
    
    
    # ============================  
    
    
    def self.load_plugin_zip
    # Installs a plugin permanently from a ZIP or RBZ file
    
      f = UI.openpanel "Select a plugin/extension installer file (with RBZ or ZIP extension)", @dir, "*.rbz;*.zip"
      
      if f
        begin
        
          raise "Selected file is not an RBZ or ZIP file." if !(File.extname(f).include? ".rbz" or File.extname(f).include? ".zip")
          
          # Install this plugin using SketchUp's built-in function
          Sketchup.install_from_archive(f)
          # Set directory as last used - no feedback here because this is done by installer
          @dir = File.dirname(f)
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
          
        rescue => e
        
          UI.messagebox "Couldn't install this RBZ or ZIP extension: \n#{f.upcase!}\n\nError: #{e}"
          
        end
      end
      
    end # load_plugin_zip  
  
  
    # ============================
  
  
    def self.pluginloader_help
    # Show the website as an About dialog
    
      dlg = UI::WebDialog.new('Plugin/Extension Loader Help', true,'AS_pluginloader_Help', 1100, 800, 150, 150, true)
      dlg.set_url('http://www.alexschreyer.net/projects/plugin-loader-for-sketchup')
      dlg.show
      
    end # pluginloader_help
    
    
    # ============================
    
    
    if !file_loaded?(__FILE__)
    
      # Get the SketchUp plugins menu
      plugins_menu = UI.menu("Plugins")
      as_rubymenu = plugins_menu.add_submenu("Plugin/Extension Loader")
    
      # Add menu items
      if as_rubymenu
      
        as_rubymenu.add_item("Load single plugin/extension (RB)") { AS_plugin_loader::load_plugin_file }
        as_rubymenu.add_item("Load all plugins/extensions from a folder (RB)") { AS_plugin_loader::load_plugin_folder }
    
        as_rubymenu.add_separator
        
        as_rubymenu.add_item("Install single plugin/extension (RBZ or ZIP)") { AS_plugin_loader::load_plugin_zip } if Sketchup.version_number >= 8000999
        as_rubymenu.add_item("Manage installed plugins/extensions") { UI.show_preferences "Extensions" }   
        as_rubymenu.add_item("About") { AS_plugin_loader::pluginloader_help }
      
       end
      
      # Let Ruby know we have loaded this file
      file_loaded(__FILE__)
    
    end 
    

    # ============================
    
  
  end # module
  
end # module
