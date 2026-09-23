# tools/generate-brand-assets.ps1
#
# Regenerates the SyncthingIgnoreGUI brand assets (logo + Windows app icon).
#
#   docs/assets/logo.svg      vector master (hand-tuned, mirrors the raster)
#   docs/assets/logo-512.png  raster export for docs / README
#   docs/assets/logo-128.png  small raster export
#   app/windows/runner/resources/app_icon.ico   multi-size Windows icon
#
# Mark: a teal rounded tile holding a sync loop (two arcs) cut by a bold slash —
# "sync" filtered by "ignore". Geometry below must stay in sync with logo.svg.
#
# Runs offline: only .NET System.Drawing is used (no Python/ImageMagick needed).
[CmdletBinding()]
param(
  [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Default to the repository root (this script lives in <repo>/tools).
# Resolved here rather than in the param block: Windows PowerShell 5.1 has not
# populated $PSScriptRoot yet while parameter defaults are evaluated.
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

$assetsDir = Join-Path $RepoRoot 'docs/assets'
$resDir = Join-Path $RepoRoot 'app/windows/runner/resources'
New-Item -ItemType Directory -Force -Path $assetsDir, $resDir | Out-Null

# --- palette -----------------------------------------------------------------
$ColorTealTop = [System.Drawing.ColorTranslator]::FromHtml('#22C6B4')
$ColorTealBottom = [System.Drawing.ColorTranslator]::FromHtml('#08665C')
$White = [System.Drawing.Color]::White

# --- geometry (fractions of the canvas size) ---------------------------------
$CornerRatio = 0.22   # rounded-tile corner radius
$RingRadius = 0.285   # ring centre-line radius
$StrokeRatio = 0.115  # ring + slash stroke width
$SlashFrom = 0.255    # slash runs (SlashFrom, SlashTo) -> (SlashTo, SlashFrom)
$SlashTo = 0.745
$GapHalfAngle = 25.0  # arcs leave a 50 deg gap centred on 135 deg and 315 deg

function New-RoundedRectPath {
  param([single]$Size, [single]$Radius)
  $d = $Radius * 2
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $path.AddArc(0, 0, $d, $d, 180, 90)
  $path.AddArc($Size - $d, 0, $d, $d, 270, 90)
  $path.AddArc($Size - $d, $Size - $d, $d, $d, 0, 90)
  $path.AddArc(0, $Size - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-LogoBitmap {
  param([int]$Size)

  $s = [single]$Size
  $bmp = [System.Drawing.Bitmap]::new(
    $Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $tile = $null
  $tileBrush = $null
  $pen = $null
  try {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $rect = [System.Drawing.RectangleF]::new(0, 0, $s, $s)

    # 1) gradient tile
    $tile = New-RoundedRectPath -Size $s -Radius ([single]($s * $CornerRatio))
    $tileBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
      $rect, $ColorTealTop, $ColorTealBottom, [single]90)
    $g.FillPath($tileBrush, $tile)

    # 2) white glyph: sync loop (two arcs) cut by the ignore slash
    $pen = [System.Drawing.Pen]::new($White, [single]($s * $StrokeRatio))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    $centre = $s / 2.0
    $ringRadius = [single]($s * $RingRadius - ($s * $StrokeRatio) / 2.0)
    $ellipse = [System.Drawing.RectangleF]::new(
      $centre - $ringRadius, $centre - $ringRadius, $ringRadius * 2, $ringRadius * 2)

    if ($Size -lt 32) {
      # Tiny sizes: a plain ring stays legible where short arcs would blur.
      $g.DrawEllipse($pen, $ellipse)
    }
    else {
      $sweep = [single]((360.0 - $GapHalfAngle * 4) / 2)
      $g.DrawArc($pen, $ellipse, [single](315 + $GapHalfAngle), $sweep)
      $g.DrawArc($pen, $ellipse, [single](135 + $GapHalfAngle), $sweep)
    }

    $g.DrawLine(
      $pen,
      [single]($s * $SlashFrom), [single]($s * $SlashTo),
      [single]($s * $SlashTo), [single]($s * $SlashFrom))
  }
  finally {
    if ($pen) { $pen.Dispose() }
    if ($tileBrush) { $tileBrush.Dispose() }
    if ($tile) { $tile.Dispose() }
    $g.Dispose()
  }
  return $bmp
}

function Get-LogoPngBytes {
  param([int]$Size)
  $bmp = New-LogoBitmap -Size $Size
  $stream = [System.IO.MemoryStream]::new()
  try {
    $bmp.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    return $stream.ToArray()
  }
  finally {
    $stream.Dispose()
    $bmp.Dispose()
  }
}

function Save-LogoPng {
  param([int]$Size, [string]$Path)
  # Cast back to byte[]: PowerShell unrolls arrays returned from a function.
  [System.IO.File]::WriteAllBytes($Path, [byte[]](Get-LogoPngBytes -Size $Size))
  Write-Host "wrote $Path ($Size x $Size)"
}

# --- raster exports ----------------------------------------------------------
Save-LogoPng -Size 512 -Path (Join-Path $assetsDir 'logo-512.png')
Save-LogoPng -Size 128 -Path (Join-Path $assetsDir 'logo-128.png')

# --- multi-size Windows icon (PNG-compressed entries, Vista+) ----------------
$icoSizes = 16, 24, 32, 48, 64, 128, 256
$frames = @{}
foreach ($size in $icoSizes) {
  $frames[$size] = [byte[]](Get-LogoPngBytes -Size $size)
}

$icoStream = [System.IO.MemoryStream]::new()
$writer = [System.IO.BinaryWriter]::new($icoStream)
try {
  $writer.Write([uint16]0)                 # reserved
  $writer.Write([uint16]1)                 # type: icon
  $writer.Write([uint16]$icoSizes.Count)   # image count

  $offset = 6 + 16 * $icoSizes.Count
  foreach ($size in $icoSizes) {
    $bytes = $frames[$size]
    $dimension = if ($size -ge 256) { 0 } else { $size }
    $writer.Write([byte]$dimension)        # width  (0 = 256)
    $writer.Write([byte]$dimension)        # height
    $writer.Write([byte]0)                 # palette
    $writer.Write([byte]0)                 # reserved
    $writer.Write([uint16]1)               # colour planes
    $writer.Write([uint16]32)              # bits per pixel
    $writer.Write([uint32]$bytes.Length)
    $writer.Write([uint32]$offset)
    $offset += $bytes.Length
  }
  foreach ($size in $icoSizes) { $writer.Write($frames[$size]) }
  $writer.Flush()

  $icoPath = Join-Path $resDir 'app_icon.ico'
  [System.IO.File]::WriteAllBytes($icoPath, $icoStream.ToArray())
  Write-Host "wrote $icoPath ($($icoSizes -join ', ') px, $($icoStream.Length) bytes)"
}
finally {
  $writer.Dispose()
  $icoStream.Dispose()
}
