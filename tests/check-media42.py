from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
log = (root / 'ftebroom/qconsole.log').read_text(errors='replace')
assert not any(x in log for x in ('DESKTOP_FAIL', 'TRANSFORM_FAIL', 'CSQC_Abort', 'Unknown command', 'mod by zero', 'runaway loop error')), log
for name in ('image_decoded_dimensions', 'image_viewer_window', 'image_cache_reuses_file',
             'image_from_pak', 'image_cache_bounded', 'image_cache_released'):
    assert 'DESKTOP_PASS ' + name in log, name

def map_text(name):
    return (root / f'ftebroom/maps/import42_{name}.map').read_text()

def tokens(name):
    return re.findall(r'"(?:\\.|[^"\\])*"|[{}()\[\]]|[^\s{}()\[\]"]+', map_text(name))

assert tokens('before') == tokens('undo'), 'Import undo must restore the entire document'
assert tokens('after') == tokens('redo'), 'Import redo must restore all imported content'
assert map_text('after').count('\n( ') == map_text('before').count('\n( ') + 6
assert map_text('after').count('info_player_deathmatch') == map_text('before').count('info_player_deathmatch') + 1
assert '42 123' in map_text('after') and '47 128' in map_text('after')
print('PASS: image viewer/cache/PAK and whole-document import undo/redo, entity and surface attributes')

for name in ('fracture_exact_count','fracture_volume_conserved','fracture_undo_original','fracture_redo_fragments','fracture_independent_brush_entities'):
    assert 'TRANSFORM_PASS '+name in log, name

for name in ('perforate_selects_only_plugs','perforate_requested_sides','perforate_single_undo','perforate_rejects_unplaceable_holes'):
    assert 'TRANSFORM_PASS '+name in log, name

for name in ('model_conversion_file_created','model_conversion_md3_roundtrip'):
    assert 'DESKTOP_PASS '+name in log, name

# The source has two different poses. Verify baking changes the actual vertices,
# rather than only writing two identical frame headers.
import struct
output = next((root / 'assets/models/converted').glob('*.md3'))
data = output.read_bytes()
surface = struct.unpack_from('<I', data, 100)[0]
vertices = struct.unpack_from('<I', data, surface + 80)[0]
xyz = surface + struct.unpack_from('<I', data, surface + 100)[0]
assert data[xyz:xyz+vertices*8] != data[xyz+vertices*8:xyz+vertices*16], 'Animation was not baked'
print('PASS: distinct animated poses survived conversion to MD3')

for name in ('pk3_text_editor_save','text_editor_dirty_switch_guard','pk3_delete_with_backup','loose_delete_recoverable','file_tiles_stable_at_bottom','custom_wall_staged','mounted_pk3_replace','mounted_pk3_reload','studio_wall_shader_loaded'):
 assert 'DESKTOP_PASS '+name in log, name
assert 'runaway loop error' not in log
for name in ('array43_linear_count','array43_linear_bounds','array43_single_undo','array43_radial_count','array43_random_seed','holes43_over_budget_rejected','holes43_boundary_atomic'):
 assert 'TRANSFORM_PASS '+name in log,name
print('PASS: PK3 edits/deletion, text guard, stable bottom scrolling, wall staging, arrays and Perforate limits')
