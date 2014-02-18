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

Version:        1.5

Date :          2/17/2014

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
                

TODO List:      - Folder selection is a bit workaroundish. A standard
                  OS directory picker would be better.

=end


require 'sketchup'

module AS_plugin_loader


  # ============================
  
  
  # Get help content
  
  HELPCONTENT = "
Plugin Loader for SketchUp
==========================

by Alexander Schreyer (www.alexschreyer.net)

------------------------------------------------

DESCRIPTION:
============

Adds a submenu to the Plugins menu to offer these functions:
- Load single RB plugin (on-demand)
- Load all RB plugins from a folder (on-demand)
- Install plugin from RBZ or ZIP file


WEBSITE:
========

http://www.alexschreyer.net/projects/plugin-loader-for-sketchup/

Subscribe to the comments on the above page so that you can be notified when a new version is available.


USE:
====

On-demand loading of plugins (single or multiple) -- Your plugin files (with RB extension) may be loaded from any location (hard disk, USB or network drive). If they are in the main SketchUp plugin folder, then you may be able to use this option to reload them (since they were already loaded when SketchUp started). For the multiple plugin option, simply select any file within a folder and all contained plugins will be loaded.
Some (especially the more complex) plugins cannot be loaded using this method. In those cases, you'll have to install them into SketchUp's main plugins folder.

Installing plugins -- This is just another way to permanently install plugins from RBZ or ZIP files.


ORGANIZING PLUGINS:
===================

After you download a plugin, place it into a dedicated location (as described above) by copying its single RB file or extracting the archive it came in (from a ZIP file).
If the plugin only came as an RBZ, then re-name the RBZ to ZIP and extract all of the files. Alternatively, install the plugin into SketchUp's main plugins folder and then move its files (one RB file and any subfolders) to another location.

Your installed plugins are located here:
"+Sketchup.find_support_file("plugins")+"

Afterwards, plugins can be loaded from any computer-accessible location using this tool.


LOADING THIS TOOL:
==================

If you want to load this tool on-demand (instead of installing it), save its files anywhere (e.g. on your USB memory stick - the H: drive in this example) and then load it into SketchUp (no restart required!) by opening the Ruby Console (Window > Ruby Console) and entering this (modify for your setup):

  load \"H:\\PluginLoader.rb\"


DISCLAIMER:
===========

THIS SOFTWARE IS PROVIDED 'AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  
"


  # Get platform info
  @su_os = (Object::RUBY_PLATFORM =~ /mswin/i) ? 'win' :
    ((Object::RUBY_PLATFORM =~ /darwin/i) ? 'mac' : 'other')
    
    
  # Get default directory as a start  
  @dir = (ENV['USERPROFILE'] != nil) ? ENV['USERPROFILE'] : 
    ((ENV['HOME'] != nil) ? ENV['HOME'] : File.dirname(__FILE__) )
  # Get working directory from last opened if it exists
  @last_dir = Sketchup.read_default "as_PluginLoader", "last_dir"
  @dir = @last_dir if @last_dir != nil
  # Do some spring cleaning
  @dir = @dir.tr("\\","/")


  def self.load_plugin_file
  # Loads single plugin from RB file
  
    if Sketchup.version.to_f < 7.0
      filename = UI.openpanel "Select a SketchUp Ruby plugin file (with RB extension) to load it"
    else
      filename = UI.openpanel( "Select a SketchUp Ruby plugin file (with RB extension) to load it", @dir, "*.rb" )
    end
    if filename
      begin
        raise "Selected file is not an RB file." if File.extname(filename) != ".rb"
        # Load this plugin
        load filename
        # Set directory as last used and give feedback
        @dir = File.dirname(filename)
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
        UI.messagebox "Successfully loaded RB plugin: \n#{filename}"
      rescue => e
        UI.messagebox "Could not load RB plugin: \n#{filename}\n\nError: #{e}"
      end
    end
    
  end # load_plugin_file



  def self.load_plugin_folder
  # Load all plugins from selected folder
  
    UI.messagebox "Select any file in the folder from where you would like to load all available RB plugins."
    if Sketchup.version.to_f < 7.0
      filename = UI.openpanel "Select any file - all plugins will be loaded from that folder"
    else
      filename = UI.openpanel( "Select any file - all plugins will be loaded from that folder", @dir, "*.rb" )
    end
    if filename
      foldername = File.dirname(filename)
      begin
        # Modified require_all function - loads all plugins in folder
        Dir.chdir(foldername)
        rbfiles = []
        rbfiles = Dir["*.rb"]
        raise "Nothing to load in this directory." if (rbfiles.length < 1)
        p rbfiles
        $:.push foldername
        rbfiles.each {|f| load f}
        # Set directory as last used and give feedback 
        @dir = foldername
        Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
        UI.messagebox "Successfully loaded all RB plugins from: \n#{foldername}"
      rescue => e
        UI.messagebox "Could not load all RB plugins from: \n#{foldername}\n\nError: #{e}"
      end
    end
    
  end # load_plugin_folder
  
  
  
  def self.load_plugin_zip
  # Installs a plugin permanently from a ZIP or RBZ file
  
    if Sketchup.version_number >= 8000999
      filename = UI.openpanel "Select a plugin/extension installer file (with RBZ or ZIP extension)", @dir, "*.rbz;*.zip"
      if filename
        begin
          raise "Selected file is not an RBZ or ZIP file." if !(File.extname(filename).include? ".rbz" or File.extname(filename).include? ".zip")
          # Install this plugin using SketchUp's built-in function
          Sketchup.install_from_archive(filename)
          # Set directory as last used - no feedback here because this is done by installer
          @dir = File.dirname(filename)
          Sketchup.write_default "as_PluginLoader", "last_dir", @dir.tr("\\","/")
        rescue => e
          UI.messagebox "Couldn't install this RBZ or ZIP plugin: \n#{filename}\n\nError: #{e}"
        end
      end
    else
      UI.messagebox "This tool can't install a plugin using your version of SketchUp. Please update to the latest version."
    end
    
  end # load_plugin_zip    



  def self.pluginloader_help
  # Show the About dialog
  
    begin
      UI.messagebox HELPCONTENT, MB_MULTILINE, "Plugin Loader - About"
    rescue => e
      UI.messagebox "Couldn't display the About box.\nPlease go to my website for more information:\nhttp://www.alexschreyer.net/projects/plugin-loader-for-sketchup/\n\nError: #{e}"
    end
    
  end # pluginloader_help
  
  

end # module



# ====================================================



if !file_loaded?(__FILE__)

  # Get the SketchUp plugins menu
  plugins_menu = UI.menu("Plugins")
  as_rubymenu = plugins_menu.add_submenu("Plugin Loader")

  # Add menu items
  if as_rubymenu
  
    as_rubymenu.add_item("Load single plugin (RB)") { AS_plugin_loader::load_plugin_file }
    as_rubymenu.add_item("Load all plugins from a folder (RB)") { AS_plugin_loader::load_plugin_folder }

    as_rubymenu.add_separator
    
    as_rubymenu.add_item("Install single plugin (RBZ or ZIP)") { AS_plugin_loader::load_plugin_zip }
    as_rubymenu.add_item("Manage installed plugins") { UI.show_preferences "Extensions" }
      
    as_rubymenu.add_separator

    as_rubymenu.add_item("About") { AS_plugin_loader::pluginloader_help }
  
   end
  
  # Let Ruby know we have loaded this file
  file_loaded(__FILE__)

end # if
