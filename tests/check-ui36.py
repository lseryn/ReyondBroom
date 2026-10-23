from pathlib import Path
import sys, wave, struct
root=Path(sys.argv[1])
sound=root/'mod/sound'
with wave.open(str(sound/'test.wav'),'rb') as source:
    assert source.getnframes()==22050, source.getnframes()
    samples=struct.unpack('<'+'h'*source.getnframes()*2, source.readframes(source.getnframes()))
    assert 5900 < max(samples) < 6100, max(samples)
backups=list(sound.glob('*.bak'))
assert len(backups)==1
assert backups[0].read_bytes()==(sound/'original.bin').read_bytes()
print('PASS: 2 seconds trimmed to 1, played at 2x -> 0.5 seconds; half amplitude; exact original backup')
