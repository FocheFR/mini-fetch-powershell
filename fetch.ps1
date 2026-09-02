[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Collecte des métriques
$os    = Get-CimInstance Win32_OperatingSystem
$cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu   = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Virtual|Basic|Remote" } | Select-Object -First 1).Name
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

# 2. Conversions (Uptime, RAM)
$uptime    = (Get-Date) - $os.LastBootUpTime
$uptimeTxt = "{0}j {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

$ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$ramFree  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$ramUsed  = [math]::Round($ramTotal - $ramFree, 1)

# 3. Styles ANSI
$c = "$([char]27)[36m" # Cyan
$b = "$([char]27)[1m"  # Gras
$r = "$([char]27)[0m"  # Reset

# Palette de couleurs (à retirer si inutile)
$palette = (40..47 | ForEach-Object { "$([char]27)[${_}m   " }) -join "" + "$r"

# 4. Formatage des disques
$diskLines = foreach ($d in $disks) {
    $total = [math]::Round($d.Size / 1GB, 1)
    $used  = [math]::Round(($d.Size - $d.FreeSpace) / 1GB, 1)
    "$b$c Disque $($d.DeviceID) :$r $used Go / $total Go"
}

# 5. Construction de la colonne de droite
$info = @(
    "$b$c$env:USERNAME$r@$b$c$env:COMPUTERNAME$r",
    "--------------------------------------------------",
    "$b$c OS        :$r $($os.Caption.Trim())",
    "$b$c Uptime    :$r $uptimeTxt",
    "$b$c CPU       :$r $($cpu.Name.Trim())",
    "$b$c GPU       :$r $($gpu.Trim())",
    "$b$c RAM       :$r $ramUsed Go / $ramTotal Go"
) + $diskLines + @(
    "",
    $palette   # Supprime cette ligne et celle au-dessus si tu ne veux pas des carrés de couleur
)

# 6. Logo ASCII
$b8 = "$([char]0x2588)" * 8
$logo = @(
    "$c  $b8   $b8  $r",
    "$c  $b8   $b8  $r",
    "$c  $b8   $b8  $r",
    "$c                       $r",
    "$c  $b8   $b8  $r",
    "$c  $b8   $b8  $r",
    "$c  $b8   $b8  $r"
)

# 7. Affichage
Write-Host ""
$spacer   = " " * 23
$maxLines = [math]::Max($logo.Count, $info.Count)

for ($i = 0; $i -lt $maxLines; $i++) {
    $gauche = if ($i -lt $logo.Count) { $logo[$i] } else { $spacer }
    $droite = if ($i -lt $info.Count) { $info[$i] } else { "" }
    Write-Host "$gauche  $droite"
}
Write-Host ""