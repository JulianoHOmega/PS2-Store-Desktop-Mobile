from pathlib import Path
from PIL import Image

source = Image.open('assets/icons/ps2_store_icon.png').convert('RGBA')
res = Path('android/app/src/main/res')
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    dest = res / ('mipmap-' + density)
    dest.mkdir(parents=True, exist_ok=True)
    source.resize((size,size),Image.Resampling.LANCZOS).save(dest / 'ic_launcher.png')
# Ensure an adaptive icon uses our image rather than the default Flutter foreground.
for folder in (res / 'mipmap-anydpi-v26', res / 'mipmap-anydpi'):
    if folder.exists():
        for xml in folder.glob('ic_launcher*.xml'):
            xml.unlink()
print('Icones Android instalados.')
