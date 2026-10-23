# UI font subset

`FTEBroom-CJK.otf` is a renamed subset of Noto Sans CJK JP Regular, under the
SIL Open Font License 1.1 (see LICENSE-Noto.txt). The subset contains the
characters used by the shipped translation catalog.

Source revision: `f8d157532fbfaeda587e826d4cd5b21a49186f7c`

Source file: https://github.com/notofonts/noto-cjk/blob/f8d157532fbfaeda587e826d4cd5b21a49186f7c/Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf

SHA256: `68a3fc98800b2a27b371f2fb79991daf3633bd89309d4ffaa6946fd587f375b5`

Regenerate after changing `localization/ui.tsv` with FontTools 4.60.1 and
`python scripts/generate-localization.py --font /path/to/NotoSansCJKjp-Regular.otf`.
The Windows UI continues using Segoe UI for Latin and Cyrillic text.

Linux uses the bundled subset for its base UI font; Latin and Cyrillic ranges
are included independently of the current translation catalog.
