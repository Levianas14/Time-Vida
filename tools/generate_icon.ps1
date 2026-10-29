# Render the same 108-unit geometry as assets/branding/app-icon.svg.
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$targets = @{
    'assets/branding/app-icon.png' = 512
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' = 48
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' = 72
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' = 96
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' = 144
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' = 192
}
foreach ($target in $targets.GetEnumerator()) {
    $size = $target.Value
    $canvas = [Drawing.Bitmap]::new($size * 4, $size * 4)
    $g = [Drawing.Graphics]::FromImage($canvas)
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.ScaleTransform($size * 4 / 108.0, $size * 4 / 108.0)
    $g.Clear([Drawing.Color]::Transparent)
    $background = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#0D1420'))
    $surface = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#151F2D'))
    $blue = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#8CB8FF'))
    $rim = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#F4F7FB'), 4)
    $ticks = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#A6B5C6'), 2)
    $hands = [Drawing.Pen]::new($blue, 4.5)
    $ticks.StartCap = $ticks.EndCap = [Drawing.Drawing2D.LineCap]::Round
    $hands.StartCap = $hands.EndCap = [Drawing.Drawing2D.LineCap]::Round
    $hands.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
    $shape = [Drawing.Drawing2D.GraphicsPath]::new()
    $shape.AddArc(0, 0, 48, 48, 180, 90)
    $shape.AddArc(60, 0, 48, 48, 270, 90)
    $shape.AddArc(60, 60, 48, 48, 0, 90)
    $shape.AddArc(0, 60, 48, 48, 90, 90)
    $shape.CloseFigure()
    $g.FillPath($background, $shape)
    $g.FillEllipse($surface, 25, 25, 58, 58)
    $g.DrawEllipse($rim, 25, 25, 58, 58)
    $g.DrawLine($ticks, 54, 32, 54, 35)
    $g.DrawLine($ticks, 76, 54, 73, 54)
    $g.DrawLine($ticks, 54, 76, 54, 73)
    $g.DrawLine($ticks, 32, 54, 35, 54)
    $g.DrawLine($hands, 44, 47, 54, 54)
    $g.DrawLine($hands, 54, 54, 66, 38)
    $g.FillEllipse($blue, 51, 51, 6, 6)
    $output = [Drawing.Bitmap]::new($size, $size)
    $resizer = [Drawing.Graphics]::FromImage($output)
    $resizer.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $resizer.DrawImage($canvas, 0, 0, $size, $size)
    $output.Save((Join-Path $root $target.Key), [Drawing.Imaging.ImageFormat]::Png)
    foreach ($resource in @($resizer, $output, $shape, $hands, $ticks, $rim, $blue, $surface, $background, $g, $canvas)) {
        $resource.Dispose()
    }
}
