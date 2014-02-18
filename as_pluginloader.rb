# Loader for as_pluginloader/as_pluginloader.rb

require 'sketchup.rb'
require 'extensions.rb'

as_pluginloader = SketchupExtension.new "Plugin Loader", "as_pluginloader/as_pluginloader.rb"
as_pluginloader.copyright= 'Copyright 2014 Alexander C. Schreyer'
as_pluginloader.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_pluginloader.version = '1.5'
as_pluginloader.description = "Adds a menu item to the Plugins menu, which allows for on-demand loading of plugins from any location."
Sketchup.register_extension as_pluginloader, true
