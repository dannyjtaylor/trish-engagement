<#
    engagement.ps1
    A flashy animated farm celebration for my sis's engagement.
    Run in a fullscreen PowerShell / Windows Terminal window:  .\engagement.ps1
#>
param(
    [int]$ForceWidth  = 0,    # override detected console width (testing)
    [int]$ForceHeight = 0,    # override detected console height (testing)
    [int]$StopAtFrame = 0,    # render only N frames then quit (0 = full show)
    [int]$SleepMs     = 20,   # ms between frames (lower = faster)
    [int]$DumpFrame   = -1,   # debug: print one frame as plain text and exit
    [switch]$DumpBg           # debug: also mark background-filled cells with '#'
)

# ----------------------------------------------------------------------------
#  Setup
# ----------------------------------------------------------------------------
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$ESC = [char]27

try {
    $cw = [Console]::WindowWidth
    $ch = [Console]::WindowHeight
} catch { $cw = 150; $ch = 45 }
if ($ForceWidth  -gt 0) { $cw = $ForceWidth }
if ($ForceHeight -gt 0) { $ch = $ForceHeight }
if (-not $cw -or $cw -lt 60) { $cw = 150 }
if (-not $ch -or $ch -lt 24) { $ch = 45 }

$script:W = $cw - 1
$script:H = $ch - 1
if ($script:W -gt 220) { $script:W = 220 }
if ($script:H -gt 60)  { $script:H = 60 }

$script:ESC = $ESC
$cellCount  = $script:W * $script:H

$script:chr = New-Object 'string[]' $cellCount
$script:cfg = New-Object 'string[]' $cellCount
$script:cbg = New-Object 'string[]' $cellCount

$DEFAULT_FG = '200;200;200'
$groundY    = [int]($script:H * 0.60)
$script:groundY = $groundY

# ----------------------------------------------------------------------------
#  Low level cell helpers
# ----------------------------------------------------------------------------
function Set-Cell($x, $y, $c, $fg) {
    $x = [int]$x; $y = [int]$y
    if ($x -lt 0 -or $x -ge $script:W -or $y -lt 0 -or $y -ge $script:H) { return }
    $i = $y * $script:W + $x
    $script:chr[$i] = $c
    $script:cfg[$i] = $fg
}

function Set-BgCell($x, $y, $bg) {
    $x = [int]$x; $y = [int]$y
    if ($x -lt 0 -or $x -ge $script:W -or $y -lt 0 -or $y -ge $script:H) { return }
    $script:cbg[$y * $script:W + $x] = $bg
}

function Stamp($x, $y, [string[]]$art, $fg) {
    $x = [int]$x; $y = [int]$y
    for ($r = 0; $r -lt $art.Length; $r++) {
        $line = $art[$r]
        for ($c = 0; $c -lt $line.Length; $c++) {
            $ch = $line[$c]
            if ($ch -ne ' ') { Set-Cell ($x + $c) ($y + $r) ([string]$ch) $fg }
        }
    }
}

# ----------------------------------------------------------------------------
#  Static background (sky gradient, hills, ground) -> baked into template
# ----------------------------------------------------------------------------
for ($y = 0; $y -lt $script:H; $y++) {
    if ($y -lt $groundY) {
        $t = $y / [double]$groundY
        $r = [int](70  + $t * 110)
        $g = [int](135 + $t * 90)
        $b = [int](205 + $t * 50)
        $bg = "$r;$g;$b"
    } else {
        $t2 = ($y - $groundY) / [double]($script:H - $groundY)
        $r = [int](96  - $t2 * 52)
        $g = [int](170 - $t2 * 70)
        $b = [int](78  - $t2 * 40)
        $bg = "$r;$g;$b"
    }
    for ($x = 0; $x -lt $script:W; $x++) {
        $i = $y * $script:W + $x
        $script:chr[$i] = ' '
        $script:cfg[$i] = $DEFAULT_FG
        $script:cbg[$i] = $bg
    }
}

# rolling hills near the horizon (set as background bands)
for ($x = 0; $x -lt $script:W; $x++) {
    $h1 = [int]($groundY - 3 - 3 * [Math]::Sin($x / 14.0))
    $h2 = [int]($groundY - 1 - 2 * [Math]::Sin($x / 9.0 + 2))
    for ($y = $h1; $y -lt $groundY; $y++) { Set-BgCell $x $y '78;150;66' }
    for ($y = $h2; $y -lt $groundY; $y++) { Set-BgCell $x $y '88;162;72' }
}

# grass texture on the front ground
$gr = [System.Random]::new(7)
for ($x = 0; $x -lt $script:W; $x++) {
    for ($y = $groundY + 1; $y -lt $script:H; $y++) {
        if ($gr.Next(0, 5) -eq 0) {
            $blade = @("'", ',', '"', '.')[$gr.Next(0, 4)]
            Set-Cell $x $y $blade '70;135;55'
        }
    }
}

# solid "coloured-in" red barn (filled with background colour)
function Fill-Block($x0, $y0, $w, $h, $col) {
    for ($yy = $y0; $yy -lt $y0 + $h; $yy++) {
        for ($xx = $x0; $xx -lt $x0 + $w; $xx++) {
            Set-Cell $xx $yy ' ' $col
            Set-BgCell $xx $yy $col
        }
    }
}

$barnX = [int]($script:W * 0.05)
$barnW = 22
$roofH = 5
$bodyH = 9
$barnBottom = $groundY - 1
$bodyTop = $barnBottom - $bodyH + 1
$roofTop = $bodyTop - $roofH
$barnCx = $barnX + [int]($barnW / 2)

$barnRed  = '190;54;46'
$barnDark = '150;38;32'
$barnCream = '246;232;204'

Fill-Block $barnX $bodyTop $barnW $bodyH $barnRed                       # solid body
for ($i = 0; $i -lt $roofH; $i++) {                                    # solid roof (peak)
    $half = [int]((($i + 1) / [double]$roofH) * ($barnW / 2 + 1))
    Fill-Block ($barnCx - $half) ($roofTop + $i) (2 * $half + 1) 1 $barnDark
}
Fill-Block ($barnCx - 1) ($roofTop + 2) 3 2 $barnCream                  # hayloft window
foreach ($wx in @(($barnX + 3), ($barnX + $barnW - 6))) {             # two windows
    Fill-Block $wx ($bodyTop + 1) 3 2 $barnCream
}
$doorW = 10; $doorH = 6
$doorX = $barnCx - [int]($doorW / 2)
$doorTop = $barnBottom - $doorH + 1
Fill-Block $doorX $doorTop $doorW $doorH $barnCream                     # big doors
for ($yy = $doorTop; $yy -le $barnBottom; $yy++) { Set-Cell $barnCx $yy '|' $barnDark }   # centre split
for ($xx = $doorX; $xx -lt $doorX + $doorW; $xx++) { Set-Cell $xx $doorTop '_' $barnDark } # door header

# solid silo beside the barn
$siloX = $barnX + $barnW + 2
$siloW = 7
$siloTop = $bodyTop + 1
Fill-Block $siloX $siloTop $siloW ($barnBottom - $siloTop + 1) '178;178;190'
Fill-Block $siloX ($siloTop - 1) $siloW 1 '150;150;164'                 # dome cap

# bake templates
$chrT = $script:chr.Clone()
$cfgT = $script:cfg.Clone()
$cbgT = $script:cbg.Clone()

# ----------------------------------------------------------------------------
#  Sprite art
# ----------------------------------------------------------------------------
# two little chickens (kept beneath the barn)
$chickenA = @('  ,_ ', ' (o> ', ' /)  ', ' ^ ^ ')
$chickenB = @('  ,_ ', ' (o> ', ' /)  ', '  ^ ^')

# ----------------------------------------------------------------------------
#  Dynamic drawing helpers
# ----------------------------------------------------------------------------
function Draw-Sun($cx, $cy, $rx, $ry) {
    for ($yy = -$ry; $yy -le $ry; $yy++) {
        $fy = $yy / [double]$ry
        for ($xx = -$rx; $xx -le $rx; $xx++) {
            $fx = $xx / [double]$rx
            $d = ($fx * $fx) + ($fy * $fy)
            if ($d -le 1) {
                $col = if ($d -le 0.5) { '255;232;120' } else { '255;200;48' }
                Set-Cell ($cx + $xx) ($cy + $yy) ' ' $col
                Set-BgCell ($cx + $xx) ($cy + $yy) $col
            }
        }
    }
    # rays
    $rayX = $rx + 2; $rayY = $ry + 2
    Set-Cell $cx ($cy - $rayY) '|' '255;220;90'
    Set-Cell $cx ($cy + $rayY) '|' '255;220;90'
    Set-Cell ($cx - $rayX) $cy '-' '255;220;90'
    Set-Cell ($cx + $rayX) $cy '-' '255;220;90'
    Set-Cell ($cx - $rayX + 1) ($cy - $rayY + 1) '\' '255;220;90'
    Set-Cell ($cx + $rayX - 1) ($cy - $rayY + 1) '/' '255;220;90'
    Set-Cell ($cx - $rayX + 1) ($cy + $rayY - 1) '/' '255;220;90'
    Set-Cell ($cx + $rayX - 1) ($cy + $rayY - 1) '\' '255;220;90'
}

# solid, "coloured-in" cloud
function Draw-Cloud($cx, $cy, $col) {
    $shape = @(
        '    ######    ',
        '  ##########  ',
        ' ############ ',
        '##############'
    )
    for ($r = 0; $r -lt $shape.Length; $r++) {
        $line = $shape[$r]
        for ($c = 0; $c -lt $line.Length; $c++) {
            if ($line[$c] -ne ' ') {
                Set-Cell ($cx + $c) ($cy + $r) ' ' $col
                Set-BgCell ($cx + $c) ($cy + $r) $col
            }
        }
    }
}

# small flower: plus-shaped bloom (yellow centre + 4 petal arms) on a green stem
function Draw-Flower($cx, $baseY, $h, $petal) {
    if ($h -lt 1) { return }
    $by = $baseY - $h                                          # bloom centre
    for ($y = $by + 2; $y -le $baseY; $y++) { Set-Cell $cx $y '|' '60;148;56' }   # stem
    foreach ($p in @(@(0, 0, '255;214;70'), @(0, -1, $petal), @(0, 1, $petal), @(-1, 0, $petal), @(1, 0, $petal))) {
        Set-Cell ($cx + $p[0]) ($by + $p[1]) ' ' $p[2]
        Set-BgCell ($cx + $p[0]) ($by + $p[1]) $p[2]
    }
}

function Draw-Pine($bx, $baseY, $h) {
    if ($h -lt 1) { return }
    for ($tr = 0; $tr -lt $h; $tr++) {
        $half = $tr
        $y = $baseY - ($h - 1) + $tr
        for ($c = -$half; $c -le $half; $c++) {
            $shade = if ((($tr + $c) % 2) -eq 0) { '34;120;44' } else { '48;150;58' }
            Set-Cell ($bx + $c) $y ' ' $shade
            Set-BgCell ($bx + $c) $y $shade
        }
    }
    Set-Cell $bx ($baseY + 1) ' ' '102;66;38'; Set-BgCell $bx ($baseY + 1) '102;66;38'
    Set-Cell $bx ($baseY + 2) ' ' '92;58;34';  Set-BgCell $bx ($baseY + 2) '92;58;34'
}

# Big leafy oak: solid round canopy + thick trunk, scales with growth
function Draw-Oak($cx, $baseY, $rx, $ry) {
    if ($rx -lt 1 -or $ry -lt 1) { return }
    $trunkH = [int]([Math]::Max(2, $ry * 0.7))
    $cyc = $baseY - $trunkH - $ry + 1
    for ($yy = -$ry; $yy -le $ry; $yy++) {
        $fy = $yy / [double]$ry
        for ($xx = -$rx; $xx -le $rx; $xx++) {
            $fx = $xx / [double]$rx
            if (($fx * $fx + $fy * $fy) -le 1.05) {
                $shade = if (((($xx + $yy) % 2) -eq 0)) { '46;138;52' } else { '60;162;66' }
                Set-Cell ($cx + $xx) ($cyc + $yy) ' ' $shade
                Set-BgCell ($cx + $xx) ($cyc + $yy) $shade
            }
        }
    }
    for ($ty = $baseY - $trunkH + 1; $ty -le $baseY; $ty++) {
        foreach ($tx in @(-1, 0, 1)) {
            $tc = if ($tx -eq 0) { '138;90;52' } else { '112;72;42' }
            Set-Cell ($cx + $tx) $ty ' ' $tc
            Set-BgCell ($cx + $tx) $ty $tc
        }
    }
}

function Draw-Banner($topY, [string[]]$lines, $fg, $border, $bg) {
    $maxlen = 0
    foreach ($l in $lines) { if ($l.Length -gt $maxlen) { $maxlen = $l.Length } }
    $width  = $maxlen + 6
    $height = $lines.Count + 2
    $x0 = [int](($script:W - $width) / 2)
    for ($r = 0; $r -lt $height; $r++) {
        for ($c = 0; $c -lt $width; $c++) {
            $x = $x0 + $c; $y = $topY + $r
            Set-BgCell $x $y $bg
            Set-Cell  $x $y ' ' $fg
        }
    }
    for ($c = 0; $c -lt $width; $c++) {
        Set-Cell ($x0 + $c) $topY '=' $border
        Set-Cell ($x0 + $c) ($topY + $height - 1) '=' $border
    }
    for ($r = 0; $r -lt $height; $r++) {
        Set-Cell $x0 ($topY + $r) '|' $border
        Set-Cell ($x0 + $width - 1) ($topY + $r) '|' $border
    }
    Set-Cell $x0 $topY '+' $border
    Set-Cell ($x0 + $width - 1) $topY '+' $border
    Set-Cell $x0 ($topY + $height - 1) '+' $border
    Set-Cell ($x0 + $width - 1) ($topY + $height - 1) '+' $border
    for ($li = 0; $li -lt $lines.Count; $li++) {
        $line = $lines[$li]
        $sc = $x0 + [int](($width - $line.Length) / 2)
        for ($k = 0; $k -lt $line.Length; $k++) {
            Set-Cell ($sc + $k) ($topY + 1 + $li) ([string]$line[$k]) $fg
        }
    }
    return @($x0, $topY, $width, $height)
}

# ----------------------------------------------------------------------------
#  Large block (figlet-style) font + marquee
# ----------------------------------------------------------------------------
$script:BLOCK = [string][char]9608   # full block
$script:bigFont = @{
    '7' = @('#####', '   ##', '  ## ', ' ##  ', '##   ')
    'D' = @('#### ', '#   #', '#   #', '#   #', '#### ')
    'A' = @(' ### ', '#   #', '#####', '#   #', '#   #')
    'Y' = @('#   #', ' # # ', '  #  ', '  #  ', '  #  ')
    'S' = @(' ####', '#    ', ' ### ', '    #', '#### ')
    'C' = @(' ####', '#    ', '#    ', '#    ', ' ####')
    'O' = @(' ### ', '#   #', '#   #', '#   #', ' ### ')
    'N' = @('#   #', '##  #', '# # #', '#  ##', '#   #')
    'G' = @(' ####', '#    ', '#  ##', '#   #', ' ####')
    'R' = @('#### ', '#   #', '#### ', '#  # ', '#   #')
    'T' = @('#####', '  #  ', '  #  ', '  #  ', '  #  ')
    '!' = @('#', '#', '#', ' ', '#')
    ' ' = @('  ', '  ', '  ', '  ', '  ')
}

function BigWidth($text) {
    $w = 0
    foreach ($c in $text.ToCharArray()) {
        $g = $script:bigFont["$c"]; if (-not $g) { $g = $script:bigFont[' '] }
        $w += $g[0].Length + 1
    }
    return [Math]::Max(0, $w - 1)
}

function Draw-BigText($cx, $topY, $text, $fg) {
    $x = $cx - [int]((BigWidth $text) / 2)
    foreach ($c in $text.ToCharArray()) {
        $g = $script:bigFont["$c"]; if (-not $g) { $g = $script:bigFont[' '] }
        for ($r = 0; $r -lt 5; $r++) {
            $row = $g[$r]
            for ($k = 0; $k -lt $row.Length; $k++) {
                if ($row[$k] -ne ' ') { Set-Cell ($x + $k) ($topY + $r) $script:BLOCK $fg }
            }
        }
        $x += $g[0].Length + 1
    }
}

# A framed sign: big headline on top, smaller subtitle lines beneath
function Draw-Marquee($topY, $bigText, [string[]]$subs, $bigFg, $subFg, $border, $bg) {
    $bw = BigWidth $bigText
    $maxSub = 0
    foreach ($s in $subs) { if ($s.Length -gt $maxSub) { $maxSub = $s.Length } }
    $inner  = [Math]::Max($bw, $maxSub)
    $width  = $inner + 8
    $height = 5 + $subs.Count + 4
    $x0 = [int](($script:W - $width) / 2)
    for ($r = 0; $r -lt $height; $r++) {
        for ($c = 0; $c -lt $width; $c++) {
            Set-BgCell ($x0 + $c) ($topY + $r) $bg
            Set-Cell  ($x0 + $c) ($topY + $r) ' ' $subFg
        }
    }
    for ($c = 0; $c -lt $width; $c++) {
        Set-Cell ($x0 + $c) $topY '=' $border
        Set-Cell ($x0 + $c) ($topY + $height - 1) '=' $border
    }
    for ($r = 0; $r -lt $height; $r++) {
        Set-Cell $x0 ($topY + $r) '|' $border
        Set-Cell ($x0 + $width - 1) ($topY + $r) '|' $border
    }
    Set-Cell $x0 $topY '+' $border
    Set-Cell ($x0 + $width - 1) $topY '+' $border
    Set-Cell $x0 ($topY + $height - 1) '+' $border
    Set-Cell ($x0 + $width - 1) ($topY + $height - 1) '+' $border
    Draw-BigText ($x0 + [int]($width / 2)) ($topY + 2) $bigText $bigFg
    for ($li = 0; $li -lt $subs.Count; $li++) {
        $line = $subs[$li]
        $sc = $x0 + [int](($width - $line.Length) / 2)
        for ($k = 0; $k -lt $line.Length; $k++) {
            Set-Cell ($sc + $k) ($topY + 7 + $li) ([string]$line[$k]) $subFg
        }
    }
    return @($x0, $topY, $width, $height)
}

# ----------------------------------------------------------------------------
#  Renderer (coalesced truecolor)
# ----------------------------------------------------------------------------
function Render {
    $W = $script:W; $H = $script:H; $e = $script:ESC
    $chr = $script:chr; $cfg = $script:cfg; $cbg = $script:cbg
    $sb = New-Object System.Text.StringBuilder ($W * $H * 4)
    for ($y = 0; $y -lt $H; $y++) {
        [void]$sb.Append($e).Append('[').Append([string]($y + 1)).Append(';1H')
        $lf = ''; $lb = ''
        $base = $y * $W
        for ($x = 0; $x -lt $W; $x++) {
            $i = $base + $x
            $f = $cfg[$i]; $b = $cbg[$i]
            if ($f -ne $lf -or $b -ne $lb) {
                [void]$sb.Append($e).Append('[38;2;').Append($f).Append(';48;2;').Append($b).Append('m')
                $lf = $f; $lb = $b
            }
            [void]$sb.Append($chr[$i])
        }
        [void]$sb.Append($e).Append('[0m')
    }
    [Console]::Out.Write($sb.ToString())
}

# ----------------------------------------------------------------------------
#  Animation configuration
# ----------------------------------------------------------------------------
$growFrames = 50
$sleepMs    = $SleepMs
# CONGRATS pops up just a few frames after the oak (the last plant) finishes growing
$phase1End  = $growFrames + 5
$phase2End  = $phase1End + 150
$lastFrame  = if ($StopAtFrame -gt 0) { [Math]::Min($StopAtFrame, $phase2End) } else { $phase2End }

$flashPalette = @('255;70;70', '255;200;40', '70;220;120', '90;180;255', '255;120;220', '255;255;255')
$pinkPalette  = @('255;150;190', '255;120;170', '255;200;220', '255;90;150', '255;235;245')

# tree positions
$trees = @(
    @{ x = 0.37; type = 'oak';  rx = 0.072; ry = 0.135 },
    @{ x = 0.66; type = 'pine'; m = 0.20 },
    @{ x = 0.80; type = 'pine'; m = 0.13 },
    @{ x = 0.92; type = 'pine'; m = 0.17 }
)

# confetti particles (deterministic)
$rng = [System.Random]::new(20260613)
$pCount = 120
$pX = New-Object 'int[]' $pCount
$pCol = New-Object 'string[]' $pCount
$pCh  = New-Object 'string[]' $pCount
$pSp  = New-Object 'double[]' $pCount
$confChars = @('*', 'o', '+', '.', 'x')
$confCols  = @('255;90;90', '255;210;70', '90;220;140', '120;180;255', '255;130;220', '255;255;255')
for ($i = 0; $i -lt $pCount; $i++) {
    $pX[$i]   = $rng.Next(0, $script:W)
    $pCol[$i] = $confCols[$rng.Next(0, $confCols.Count)]
    $pCh[$i]  = $confChars[$rng.Next(0, $confChars.Count)]
    $pSp[$i]  = 0.8 + $rng.NextDouble() * 1.6
}

# flower field layout (deterministic) - rows of small plus-shaped blooms across the foreground
$flowers = New-Object System.Collections.ArrayList
$frng = [System.Random]::new(20260613)
$petals = @('255;105;160', '236;64;72', '255;208;72', '198;110;230', '248;248;252', '255;150;60', '255;90;180')
# keep flowers clear of the two chickens beneath the barn (incl. room above for blooms)
$chickX0 = $barnX - 1; $chickX1 = $barnX + 14; $chickY1 = $groundY + 10
for ($row = $groundY + 3; $row -lt $script:H; $row += 2) {
    $offset = $frng.Next(0, 7)
    for ($fxp = 3 + $offset; $fxp -lt $script:W - 3; $fxp += 7) {
        $fx = $fxp + $frng.Next(-1, 2)
        if ($fx -ge $chickX0 -and $fx -le $chickX1 -and $row -le $chickY1) { continue }
        [void]$flowers.Add(@{
                x   = $fx
                y   = $row
                h   = $frng.Next(1, 4)
                col = $petals[$frng.Next(0, $petals.Count)]
            })
    }
}

# ----------------------------------------------------------------------------
#  Per-frame scene builder
# ----------------------------------------------------------------------------
function Build-Scene($frame) {
        # reset to baked template (fast native copy)
        [Array]::Copy($script:chrT, $script:chr, $script:chr.Length)
        [Array]::Copy($script:cfgT, $script:cfg, $script:cfg.Length)
        [Array]::Copy($script:cbgT, $script:cbg, $script:cbg.Length)

        $grow = [Math]::Min(1.0, $frame / [double]$script:growFrames)

        # --- sun rising (a bit wider than tall) ---
        $sunRy = [int][Math]::Max(3, $script:H * 0.06)
        $sunRx = [int]($sunRy * 1.6)
        $sunCx = [int]($script:W * 0.83)
        $startCy = $groundY - 1
        $endCy   = [int]($script:H * 0.14)
        $sunCy = [int]($startCy + ($endCy - $startCy) * $grow)
        Draw-Sun $sunCx $sunCy $sunRx $sunRy

        # --- solid clouds drifting ---
        $span = $script:W + 18
        $c1 = $script:W - [int]((($frame * 0.6) + 5)  % $span)
        $c2 = $script:W - [int]((($frame * 0.45) + 60) % $span)
        $c3 = $script:W - [int]((($frame * 0.35) + 110) % $span)
        Draw-Cloud $c1 2 '248;249;252'
        Draw-Cloud $c2 5 '240;243;250'
        Draw-Cloud $c3 1 '252;253;255'

        # --- trees growing ---
        foreach ($t in $trees) {
            if ($t.type -eq 'oak') {
                $rx = [int]([Math]::Max(1, $script:W * $t.rx * $grow))
                $ry = [int]([Math]::Max(1, $script:H * $t.ry * $grow))
                if ($grow -gt 0.02) { Draw-Oak ([int]($script:W * $t.x)) ($groundY - 1) $rx $ry }
            } else {
                $maxh = [int]($script:H * $t.m)
                $h = [int]($maxh * $grow)
                if ($grow -gt 0 -and $h -lt 1) { $h = 1 }
                Draw-Pine ([int]($script:W * $t.x)) ($groundY - 1) $h
            }
        }

        # --- the flower field (obvious bright blooms, growing) ---
        foreach ($fl in $flowers) {
            $fh = [int]([Math]::Max(1, $fl.h * $grow))
            if ($grow -gt 0.04) { Draw-Flower $fl.x $fl.y $fh $fl.col }
        }

        # --- the two little chickens beneath the barn (yellow beaks) ---
        $legA = ([int]($frame / 3) % 2) -eq 0
        $bob = if ((($frame / 4) % 2) -eq 0) { 0 } else { 1 }
        $ch1y = $groundY + 1 + $bob
        $ch2y = $groundY + 2 - $bob
        Stamp ($barnX + 2) $ch1y ($(if ($legA) { $chickenA } else { $chickenB })) '244;240;232'
        Stamp ($barnX + 8) $ch2y ($(if ($legA) { $chickenB } else { $chickenA })) '244;240;232'
        Set-Cell ($barnX + 5) ($ch1y + 1) '>' '255;196;40'   # yellow beak
        Set-Cell ($barnX + 11) ($ch2y + 1) '>' '255;196;40'  # yellow beak

        # ------------------------------------------------------------------
        #  Phase-specific overlay (banner + celebration)
        # ------------------------------------------------------------------
        if ($frame -lt $phase1End) {
            $fg = $flashPalette[$frame % $flashPalette.Count]
            $bd = $flashPalette[($frame + 3) % $flashPalette.Count]
            $box = Draw-Marquee ([int]($script:H * 0.10)) '7 DAYS' @("UNTIL YOU'RE ENGAGED!") $fg '255;255;255' $bd '24;20;52'
            # twinkling sparkles around the banner
            $sx0 = $box[0]; $sy0 = $box[1]; $sw = $box[2]; $shh = $box[3]
            $sr = [System.Random]::new(5)
            for ($s = 0; $s -lt 40; $s++) {
                $ang = $sr.NextDouble() * 6.283
                $rad = 2 + $sr.NextDouble() * 5
                $sx = [int]($sx0 + $sw / 2 + [Math]::Cos($ang) * ($sw / 2 + $rad))
                $sy = [int]($sy0 + $shh / 2 + [Math]::Sin($ang) * ($shh / 2 + $rad))
                if ((($frame + $s) % 5) -lt 3) {
                    Set-Cell $sx $sy (@('*', '+', '.')[$s % 3]) $flashPalette[($frame + $s) % $flashPalette.Count]
                }
            }
        }
        else {
            # celebration confetti + hearts (mirrored so both sides match)
            for ($i = 0; $i -lt $pCount; $i++) {
                $fph = $frame - $phase1End
                $py = [int]((($fph * $pSp[$i]) + $i * 5) % ($groundY + 6)) - 3
                $px = ($pX[$i] + [int]([Math]::Sin(($fph + $i) / 6.0) * 2)) % $script:W
                if ($py -ge 0 -and $py -lt $groundY) {
                    Set-Cell $px $py $pCh[$i] $pCol[$i]
                    Set-Cell ($script:W - 1 - $px) $py $pCh[$i] $pCol[$i]
                }
            }
            # floating hearts
            for ($i = 0; $i -lt 12; $i++) {
                $fph = $frame - $phase1End
                $hy = $script:H - 4 - [int]((($fph * 1.0) + $i * 9) % ($script:H - 4))
                $hx = (15 + $i * [int]($script:W / 13)) % $script:W
                Set-Cell $hx $hy '<' $pinkPalette[$i % $pinkPalette.Count]
                Set-Cell ($hx + 1) $hy '3' $pinkPalette[$i % $pinkPalette.Count]
            }
            $pulse = $pinkPalette[($frame / 3) % $pinkPalette.Count]
            Draw-Marquee ([int]($script:H * 0.08)) 'CONGRATS!' @("So happy for you, sis!", "Can't wait to celebrate with you and Alex!!") '255;255;255' '255;236;245' $pulse '70;18;52' | Out-Null
        }
}

# ----------------------------------------------------------------------------
#  Debug: dump a single frame as plain text (no ANSI) for verification
# ----------------------------------------------------------------------------
if ($DumpFrame -ge 0) {
    Build-Scene $DumpFrame
    for ($y = 0; $y -lt $script:H; $y++) {
        $sb = New-Object System.Text.StringBuilder
        $base = $y * $script:W
        for ($x = 0; $x -lt $script:W; $x++) {
            $i = $base + $x
            $c = $script:chr[$i]
            if ($DumpBg -and $c -eq ' ' -and $script:cbg[$i] -ne $script:cbgT[$i]) { $c = '#' }
            [void]$sb.Append($c)
        }
        Write-Output ($sb.ToString().TrimEnd())
    }
    return
}

# ----------------------------------------------------------------------------
#  Main loop
# ----------------------------------------------------------------------------
try {
    try { [Console]::CursorVisible = $false } catch {}
    [Console]::Out.Write("$ESC[2J")

    for ($frame = 0; $frame -lt $lastFrame; $frame++) {
        Build-Scene $frame
        Render
        Start-Sleep -Milliseconds $sleepMs
    }

    # hold the final frame for a beat
    Start-Sleep -Milliseconds 2500
}
finally {
    [Console]::Out.Write("$ESC[0m")
    try { [Console]::CursorVisible = $true } catch {}
    try { [Console]::SetCursorPosition(0, [Math]::Max(0, $script:H - 1)) } catch {}
    Write-Host ""
    Write-Host ""
}
