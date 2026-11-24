# Adds U+02BB (MODIFIER LETTER TURNED COMMA, Uzbek oʻ / gʻ) to the bundled
# Roboto / RobotoMono fonts by mapping it to their existing U+2018 glyph.
# The stock fonts lack U+02BB, so uz text showed empty boxes on screen and in
# PDFs. Idempotent. Needs fontTools:  python tool/patch_fonts_02bb.py
from fontTools.ttLib import TTFont

FONTS = ['Roboto-Regular', 'Roboto-Bold', 'RobotoMono-Regular', 'RobotoMono-Bold']

for name in FONTS:
    path = f'assets/fonts/{name}.ttf'
    font = TTFont(path)
    for table in font['cmap'].tables:
        if table.isUnicode() and 0x2018 in table.cmap:
            table.cmap[0x02BB] = table.cmap[0x2018]
    font.save(path)
    print(path, 'U+02BB ->', font.getBestCmap()[0x02BB])
