mod = Sketchup.active_model # Open model
ent = mod.entities # All entities in model
sel = mod.selection # Current selection

p = "loaded #1"

test = UI.menu('Plugins').add_item('Loaded #1') {}
