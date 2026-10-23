"""Small external GTK drag source for the Linux desktop integration regression."""
import gi, sys
from pathlib import Path
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

window = Gtk.Window(title='FTEBroom external WAD drop test')
window.set_default_size(320, 180)
label = Gtk.Label(label='Drag this WAD onto the editor')
box = Gtk.EventBox()
box.add(label)
window.add(box)
box.drag_source_set(Gdk.ModifierType.BUTTON1_MASK,
                      [Gtk.TargetEntry.new('text/uri-list', 0, 0)], Gdk.DragAction.COPY)
def data_get(widget, context, selection, info, time):
    selection.set_uris([Path(sys.argv[1]).resolve().as_uri()])
    print('URI_SENT', flush=True)
box.connect('drag-data-get', data_get)
box.connect('drag-begin', lambda *args: print('DRAG_STARTED', flush=True))
box.connect('drag-failed', lambda *args: print('DRAG_FAILED', flush=True))
window.connect('destroy', Gtk.main_quit)
window.show_all()
Gtk.main()
