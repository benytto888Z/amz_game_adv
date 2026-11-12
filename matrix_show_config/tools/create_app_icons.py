from pathlib import Path
import json
from PIL import Image

# Exécuter avec : python tools/create_app_icons.py
ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets' / 'images' / 'logoico.jpeg'
ANDROID = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
IOS = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'

sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
if not SOURCE.is_file():
    raise SystemExit(f'Image introuvable : {SOURCE}')

with Image.open(SOURCE) as original:
    source = original.convert('RGB')
    if source.width != source.height:
        raise SystemExit('Le logo doit être carré pour éviter une déformation.')
    metadata = json.loads((IOS / 'Contents.json').read_text(encoding='utf-8'))
    outputs = []
    for entry in metadata['images']:
        filename = entry.get('filename')
        if not filename:
            continue
        dimension = float(entry['size'].split('x')[0]) * int(entry['scale'].removesuffix('x'))
        if not dimension.is_integer() or dimension <= 0:
            raise SystemExit(f'Dimension iOS invalide : {entry}')
        outputs.append((IOS / filename, int(dimension)))
    for density, dimension in sizes.items():
        outputs.append((ANDROID / f'mipmap-{density}' / 'ic_launcher.png', dimension))
    for path, dimension in outputs:
        path.parent.mkdir(parents=True, exist_ok=True)
        source.resize((dimension, dimension), Image.Resampling.LANCZOS).save(path, format='PNG')
        print(f'{path.relative_to(ROOT)} : {dimension} × {dimension}')

print('Icônes générées. Le logo reste inchangé pour le splash Flutter.')
