Fiken app icon — pulse

FILES
  AppIcon.appiconset/     drop straight into Assets.xcassets in Xcode.
                          Contains the 1024 master plus dark and tinted
                          variants (iOS 18+), and Contents.json.

  fiken-icon-1024.png         light master
  fiken-icon-1024-dark.png    dark master
  fiken-icon-1024-tinted.png  greyscale, for iOS tinted mode
  fiken-icon-1024-red.png     optional variant, one ring in pencil red
  *.svg                       vector source for each master

  png/                    every icon size drawn individually at that size
                          (1024 down to 29). Use these for Android, web,
                          favicons, or anywhere you control the sizing.

NOTES
  No transparency and no rounded corners baked in — iOS applies its own
  mask. The drawn frame is inset 7.5% so the mask can't clip it.

  The 1024 master is deliberately bolder than the design sheet version.
  Xcode scales one image down to every size, so the master has to stay
  legible at 40px. That means two rings instead of three and a heavier F.

  The png/ files are drawn natively at each size with the ring count and
  weights tuned per size, so they're sharper than anything downscaled.
  iOS won't use them unless you build a legacy multi-size appiconset.

  Colours: paper #F2EFE6, ink #1A1A1A, pencil red #B4463C (#D9705F on dark).
  Typeface is Fredericka the Great (SIL OFL), converted to outlines.
