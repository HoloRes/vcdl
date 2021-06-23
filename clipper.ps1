# HoloClipper Revision 9 Version 1
# Keyframes are the enemy, and should be eradicated.

# Written and Tested by Sheer Curiosity
param (
    [string]$outputTitle = "output", # Defines the output filename, without extension    Options: Any Title You Want
    [string]$siteType = $null, # Defines the type of video being clipped                 Options: Youtube, Other
    [string]$videoLink = $null, # Defines input link                                     Options: YouTube Links and Direct Video File Links
    [string]$dlDir = ".", # Defines the download directory for the final file            Options: Any Directory On Your PC
    [string]$timestamps = $null, # Defines the timestamps to be clipped                  Options: Timestamps In This Format (Add Comma & No Space For Multiple Subclips): [xx:xx:xx-xx:xx:xx],[xx:xx:xx-xx:xx:xx]
    [string]$outputFileExt = "mkv", # Defines the output file extension                  Options: Any Video Extensions Supported By FFMPEG
		[string]$miniclipFileExt = "mkv",
		[string]$useAltCodecs = "false",
		[string]$rescaleVideo = "false",
		[string]$doNotStitch = "false",
		[int]$paddingInt = 5,
    [int]$parallelChunkSize = 5
)

$ffmpegExts = @(
	"3g2", "3gp", "a64", "ac3", "aac", "adts", "adx", "aif", "aiff", "afc", "aifc", "al", "tun", "pcm", "amr",
	"amv", "apm", "apng", "aptx", "aptxhd", "asf", "wmv", "wma", "asf", "wmv", "wma", "ass", "ssa", "ast", "au",
	"avi", "avs", "avs2", "bit", "caf", "cavs", "c2", "mpd", "302", "drc", "vc2", "dnxhd", "dnxhr", "dts", "dv",
	"dvd", "eac3", "f4v", "ffmeta", "cpk", "flm", "fits", "flac", "flv", "g722", "tco", "rco", "gif", "gsm", "gxf",
	"h261", "h263", "h264", "264", "hevc", "h265", "265", "m3u8", "ico", "lbc", "bmp", "dpx", "jls", "jpeg", "jpg",
	"ljpg", "pam", "pbm", "pcx", "pgm", "pgmyuv", "png", "ppm", "sgi", "tga", "tif", "tiff", "jp2", "j2c", "j2k",
	"xwd", "sun", "ras", "rs", "im1", "im8", "im24", "sunras", "xbm", "xface", "pix", "y", "m4v", "m4a", "m4b",
	"sf", "ircam", "ismv", "isma", "ivf", "jss", "js", "vag", "latm", "loas", "lrc", "m4v", "mkv", "sub", "mjpg",
	"mjpeg", "mlp", "mmf", "mov", "mp2", "m2a", "mpa", "mp3", "mp4", "mpg", "mpeg", "mpg", "mpeg", "m1v", "m2v",
	"ts", "m2t", "m2ts", "mts", "mjpg", "ul", "mxf", "mxf", "nut", "oga", "ogg", "ogv", "oma", "opus", "mp4",
	"psp", "yuv", "rgb", "rm", "ra", "roq", "rso", "sw", "sb", "sbc", "msbc", "scc", "sox", "spdif", "spx",
	"srt", "sup", "vob", "swf", "thd", "tta", "uw", "ub", "vc1", "rcv", "vob", "voc", "w64", "wav", "webm",
	"chk", "xml", "webp", "vtt", "wtv", "wv", "y4m"
)

# Input Checks
if (!$siteType -or !$videoLink -or !$timestamps) {
	Throw "ERROR: Missing Parameters"
}
if ($useAltCodecs.toLower() -ne "false" -and $useAltCodecs.toLower() -ne "true") {
	Throw "ERROR: Invalid input for parameter -useAltCodecs"
}
if ($rescaleVideo.toLower() -ne "false" -and $rescaleVideo.toLower() -ne "true") {
	Throw "ERROR: Invalid input for parameter -rescaleVideo"
}
if ($doNotStitch.toLower() -ne "false" -and $doNotStitch.toLower() -ne "true") {
	Throw "ERROR: Invalid input for parameter -doNotStitch"
}
if ($siteType.ToLower() -ne "youtube" -and $siteType.ToLower() -ne "other") {
	Throw "ERROR: Invalid site type"
}
if ($ffmpegExts -cnotcontains $outputFileExt.toLower()) {
	Throw "ERROR: Invalid output file extension"
}
if ($ffmpegExts -cnotcontains $miniclipFileExt.toLower()) {
	Throw "ERROR: Invalid output file extension"
}
if ($useAltCodecs.toLower() -eq "true" -and $siteType.toLower() -eq "other") {
	Write-Warning "Alternate codecs not supported on other video sites, ignoring -useAltCodecs parameter."
}
if ($doNotStitch.toLower() -ne "true" -and $miniclipFileExt -ne "mkv") {
	Write-Warning "-doNotStitch is unspecified or false, ignoring -miniclipFileExt."
}
if ($outputFileExt -ne "mkv" -and $siteType.toLower() -eq "other") {
	Write-Warning "Using an output file extension other than mkv with other video sites will result in extra re-encoding. Please set the output file extension to mkv to avoid this in the future."
}
if ($outputFileExt -ne "mkv" -and $useAltCodecs.toLower() -eq "true") {
	Write-Warning "Using an output file extension other than mkv with the -useAltCodecs parameter set to true will result in extra re-encoding. Please set the output file extension to mkv to avoid this in the future."
}
if ($miniclipFileExt -ne "mkv" -and $siteType.toLower() -eq "other") {
	Write-Warning "Using a miniclip file extension other than mkv with other video sites will result in extra re-encoding. Please set the miniclip file extension to mkv to avoid this in the future."
}
if ($paddingInt -gt 30) {
	$paddingInt = 30
}
if ($paddingInt -lt 0) {
	$paddingInt = 0
}
if ($parallelChunkSize -lt 0) {
	$parallelChunkSize = 0
}

# Install PoshRSJob for Parallel Processing
Install-module -Name PoshRSJob -Scope CurrentUser
Get-RSJob | Remove-RSJob

# Global Variables
$tempdir = $env:TEMP
$finalStartTimestamps = [System.Collections.ArrayList]@()
$finalRuntimeTimestamps = [System.Collections.ArrayList]@()

# Timestamp Parser
# *NOTE*
# What blub said about the previous version of this parsing function made me
# really self-conscious, so I rewrote it to be less dumb, faster, and more 
# memory efficient!
function getTimestamps() {
	function parserCheck($clipstamps) {
		$clipTimestamps = $clipstamps.Trim("[]").Split("-")
		$ts1Array = [System.Collections.ArrayList]@()
		$ts2Array = [System.Collections.ArrayList]@()
		[void]$ts1Array.AddRange($clipTimestamps[0].Split(":"))
		[void]$ts2Array.AddRange($clipTimestamps[1].Split(":"))
		for ($i = 0; $i -lt $ts1Array.Count; $i++) {
			$ts1Array[$i] = [int]$ts1Array[$i]
		}
		for ($i = 0; $i -lt $ts2Array.Count; $i++) {
			$ts2Array[$i] = [int]$ts2Array[$i]
		}
		if ($ts1Array.Count -eq 2) {
			$ts1Array.Insert(0, 0)
			while ($ts1Array[1] -ge 60) {
				$ts1Array[1] -= 60
				$ts1Array[0] += 1
			}
		}
		if ($ts2Array.Count -eq 2) {
			$ts2Array.Insert(0, 0)
			while ($ts2Array[1] -ge 60) {
				$ts2Array[1] -= 60
				$ts2Array[0] += 1
			}
		}
		if ($ts1Array[2] -lt $paddingInt -and $ts1Array[1] -eq 0 -and $ts1Array[0] -eq 0) {
			$ts1Array[2] = 0
		} else {
			$ts1Array[2] -= $paddingInt
		}
		$ts2Array[2] += $paddingInt
		if ($ts1Array[2] -lt 0) {
			$ts1Array[2] += 60
			$ts1Array[1] -= 1
		}
		if ($ts1Array[1] -lt 0) {
			$ts1Array[1] += 60
			$ts1Array[0] -= 1
		}
		if ($ts2Array[2] -ge 60) {
			$ts2Array[2] -= 60
			$ts2Array[1] += 1
		}
		if ($ts2Array[1] -ge 60) {
			$ts2Array[1] -= 60
			$ts2Array[0] += 1
		}
		for ($i = 0; $i -lt $ts1Array.Count; $i++) {
			if(($ts1Array[$i].ToString().Length) -eq 1) {
				$ts1Array[$i] = "0$($ts1Array[$i])"
			}
			if(($ts2Array[$i].ToString().Length) -eq 1) {
				$ts2Array[$i] = "0$($ts2Array[$i])"
			}
		}
		return (
			"$($ts1Array[0])`:$($ts1Array[1])`:$($ts1Array[2])`:00", 
			"$($ts2Array[0])`:$($ts2Array[1])`:$($ts2Array[2])`:00"
			)
	}
	$clipStamps = $timestamps.Split(",")
	$parserOut = [System.Collections.ArrayList]@()
	for ($i = 0; $i -lt $clipStamps.length; $i++) {
		$res = parserCheck $clipStamps[$i]
		[void]$parserOut.AddRange($res)
	}
	for ($i = 0; $i -lt $parserOut.Count; $i++) {
		if ($i -lt $parserOut.Count - 1 -and $i % 2 -ne 0) {
			$startStamp = [System.Collections.ArrayList]@()
			$endStamp = [System.Collections.ArrayList]@()
			$startStamp.AddRange($parserOut[$i+1].Split(":"))
			$endStamp.AddRange($parserOut[$i].Split(":"))
			for ($j = 0; $j -lt $startStamp.Count; $j++) {
				$startStamp[$j] = [int]$startStamp[$j]
				$endStamp[$j] = [int]$endStamp[$j]
			}
			if ($startStamp[0] -le $endStamp[0]) {
				if ($startStamp[1] -le $endStamp[1]) {
					if ($startStamp[2] -le $endStamp[2]) {
						if ($startStamp[3] -le $endStamp[3]) {
							$parserOut[$i] = "INVALID"
							$parserOut[$i+1] = "INVALID"
						}
					}
				}
			}
		}
	}
	while ($parserOut.Contains("INVALID")) {
		$parserOut.Remove("INVALID")
	}
	for ($i = 0; $i -lt $parserOut.Count; $i++) {
		if ($i % 2 -eq 0) {
			$runtimeArray = [System.Collections.ArrayList]@()
			$startStamp = $parserOut[$i].Split(":")
			$endStamp = $parserOut[$i+1].Split(":")
			for ($j = 0; $j -lt $startStamp.Length; $j++) {
				$startStamp[$j] = [int]$startStamp[$j]
				$endStamp[$j] = [int]$endStamp[$j]
			}
			[void]$runtimeArray.Add($endStamp[0] - $startStamp[0])
			[void]$runtimeArray.Add($endStamp[1] - $startStamp[1])
			[void]$runtimeArray.Add($endStamp[2] - $startStamp[2])
			[void]$runtimeArray.Add($endStamp[3] - $startStamp[3])
			if ($runtimeArray[2] -lt 0) {
				$runtimeArray[2] += 60
				$runtimeArray[1] -= 1
			}
			if ($runtimeArray[1] -lt 0) {
				$runtimeArray[1] += 60
				$runtimeArray[0] -= 1
			}
			for ($j = 0; $j -lt $runtimeArray.Count; $j++) {
				if(($runtimeArray[$j].ToString().Length) -eq 1) {
					$runtimeArray[$j] = "0$($runtimeArray[$j])"
				}
				if(($startStamp[$j].ToString().Length) -eq 1) {
					$startStamp[$j] = "0$($startStamp[$j])"
				}
			}
			[void]$finalStartTimestamps.Add("$($startStamp[0])`:$($startStamp[1])`:$($startStamp[2])`.$($startStamp[3])")
			[void]$finalRuntimeTimestamps.Add("$($runtimeArray[0])`:$($runtimeArray[1])`:$($runtimeArray[2])`.$($runtimeArray[3])")
		}
	}
	return $finalStartTimestamps, $finalRuntimeTimestamps
}

# Also rewrote this bit, the old version was giving me an aneurysm.
$finalStartTimestamps, $finalRuntimeTimestamps = getTimestamps
if ($siteType.toLower() -eq "youtube") {
	$ytdlAttempts = 0
	while (!$avFileLinks -and $ytdlAttempts -lt 5) {
		if ($useAltCodecs.toLower() -eq "true") {
			$avFileLinks = youtube-dl -f "bestvideo+bestaudio[acodec^=mp4a]/best" -g --youtube-skip-dash-manifest "$videoLink"
		} else {
			$avFileLinks = youtube-dl -f "bestvideo[vcodec^=avc1]+bestaudio[acodec^=mp4a]/best[vcodec^=avc1]" -g --youtube-skip-dash-manifest "$videoLink"
		}
		$ytdlAttempts++
	}
	if ($ytdlAttempts -eq 5) {
		Write-output "Error Fetching Direct File Links. Verify Inputted Media Link"
		Throw "ERROR: YTDL failed to fetch media links"
	}
	$vLink, $aLink = $avFileLinks.split(" ")
}
if ($siteType.toLower() -eq "other") {
	$ytdlAttempts = 0
	while (!$avLink -and $ytdlAttempts -lt 5) {
		$avLink = youtube-dl -f "best" -g "$videoLink" --add-header Accept:'*/*'
		$ytdlAttempts++
	}
	if ($ytdlAttempts -eq 5) {
		Write-output "Error Fetching Direct File Links. Verify Inputted Media Link"
		Throw "ERROR: YTDL failed to fetch media links"
	}
}
for ($i = 0; $i -lt $finalStartTimestamps.Count; $i++) {
	if ($siteType.toLower() -eq "youtube") {
  	if ($finalStartTimestamps.Count -eq 1) {
			if ($finalStartTimestamps[$i] -eq "00:00:00.00") {
				ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -c:v copy "$dlDir/$outputTitle.vid.mkv"
				ffmpeg -y -ss $finalStartTimestamps[$i] -i ($aLink) -t $finalRuntimeTimestamps[$i] -c:a copy "$dlDir/$outputTitle.aud.m4a"
				if ($outputFileExt -eq "mkv") {
					ffmpeg -y -i "$dlDir/$outputTitle.vid.mkv" -i "$dlDir/$outputTitle.aud.m4a" -c copy "$dlDir/$outputTitle.mkv"
				} elseif ($outputFileExt -eq "mp4" -and $useAltCodecs.toLower() -eq "false") {
					ffmpeg -y -i "$dlDir/$outputTitle.vid.mkv" -i "$dlDir/$outputTitle.aud.m4a" -c copy "$dlDir/$outputTitle.mp4"
				} else {
					ffmpeg -y -i "$dlDir/$outputTitle.vid.mkv" -i "$dlDir/$outputTitle.aud.m4a" -crf 18 "$dlDir/$outputTitle.$outputFileExt"
				}
				remove-Item -path "$dlDir/$outputTitle.vid.mkv"
				remove-Item -path "$dlDir/$outputTitle.aud.m4a"
			} else {
				ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -c:v libx264 "$dlDir/$outputTitle.vid.mkv"
				ffmpeg -y -ss $finalStartTimestamps[$i] -i ($aLink) -t $finalRuntimeTimestamps[$i] -c:a copy "$dlDir/$outputTitle.aud.m4a"
				if ($outputFileExt -eq "mkv") {
					ffmpeg -y -i "$dlDir/$outputTitle.vid.mkv" -i "$dlDir/$outputTitle.aud.m4a" -c copy "$dlDir/$outputTitle.mkv"
				} elseif ($outputFileExt -eq "mp4" -and $useAltCodecs.toLower() -eq "false") {
					ffmpeg -y -i "$dlDir/$outputTitle.vid.mkv" -i "$dlDir/$outputTitle.aud.m4a" -c copy "$dlDir/$outputTitle.mp4"
				} else {
					ffmpeg -y -i "$dlDir/$outputTitle.vid.mkv" -i "$dlDir/$outputTitle.aud.m4a" -crf 18 "$dlDir/$outputTitle.$outputFileExt"
				}
				remove-Item -path "$dlDir/$outputTitle.vid.mkv"
				remove-Item -path "$dlDir/$outputTitle.aud.m4a"
			}
    }
    if ($finalStartTimestamps.Count -ge 2) {
      Start-RSJob -ScriptBlock {
        $finalStartTimestamps = $args[0]
        $finalRuntimeTimestamps = $args[1]
        $i = $args[2]
	      $vLink = $args[3]
        $aLink = $args[4]
        $tempdir = $args[5]
				$miniclipFileExt = $args[6]
				if ($finalStartTimestamps[$i] -eq "00:00:00.00") {
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -c:v copy "$tempdir/clip$($i+1).vid.mkv"
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($aLink) -t $finalRuntimeTimestamps[$i] -c:a copy "$tempdir/clip$($i+1).aud.m4a"
					if ($miniclipFileExt -eq "mkv") {
						ffmpeg -y -i "$tempdir/clip$($i+1).vid.mkv" -i "$tempdir/clip$($i+1).aud.m4a" -c copy "$tempdir/clip$($i+1).mkv"
					} elseif ($miniclipFileExt -eq "mp4" -and $useAltCodecs.toLower() -eq "false") {
						ffmpeg -y -i "$tempdir/clip$($i+1).vid.mkv" -i "$tempdir/clip$($i+1).aud.m4a" -c copy "$tempdir/clip$($i+1).mp4"
					} else {
						ffmpeg -y -i "$tempdir/clip$($i+1).vid.mkv" -i "$tempdir/clip$($i+1).aud.m4a" -crf 18 "$tempdir/clip$($i+1).$miniclipFileExt"
					}
					Remove-Item -Path "$tempdir/clip$($i+1).vid.mkv"
					Remove-Item -Path "$tempdir/clip$($i+1).aud.m4a"
				} else {
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -c:v libx264 "$tempdir/clip$($i+1).vid.mkv"
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($aLink) -t $finalRuntimeTimestamps[$i] -c:a copy "$tempdir/clip$($i+1).aud.m4a"
					if ($miniclipFileExt -eq "mkv") {
						ffmpeg -y -i "$tempdir/clip$($i+1).vid.mkv" -i "$tempdir/clip$($i+1).aud.m4a" -c copy "$tempdir/clip$($i+1).mkv"
					} elseif ($miniclipFileExt -eq "mp4" -and $useAltCodecs.toLower() -eq "false") {
						ffmpeg -y -i "$tempdir/clip$($i+1).vid.mkv" -i "$tempdir/clip$($i+1).aud.m4a" -c copy "$tempdir/clip$($i+1).mp4"
					} else {
						ffmpeg -y -i "$tempdir/clip$($i+1).vid.mkv" -i "$tempdir/clip$($i+1).aud.m4a" -crf 18 "$tempdir/clip$($i+1).$miniclipFileExt"
					}
					Remove-Item -Path "$tempdir/clip$($i+1).vid.mkv"
					Remove-Item -Path "$tempdir/clip$($i+1).aud.m4a"
				}
      } -ArgumentList $finalStartTimestamps, $finalRuntimeTimestamps, $i, $vLink, $aLink, $tempdir, $miniclipFileExt
      $parallelChunkCount++
    }
  }
  if ($siteType.toLower() -eq "other") {
    if ($finalStartTimestamps.Count -eq 1) {
			if ($finalStartTimestamps[$i] -eq "00:00:00.00") {
				if ($outputFileExt -eq "mkv") {
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($avLink) -t $finalRuntimeTimestamps[$i] -c copy "$dlDir/$outputTitle.$outputFileExt"
				} else {
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($avLink) -t $finalRuntimeTimestamps[$i] -crf 18 "$dlDir/$outputTitle.$outputFileExt"
				}
			} else {
				if ($outputFileExt -eq "mkv") {
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -c:v libx264 -c:a copy "$dlDir/$outputTitle.$outputFileExt"
				} else {
					ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -crf 18 "$dlDir/$outputTitle.$outputFileExt"
				}
			}
    }
    if ($finalStartTimestamps.Count -ge 2) {
      Start-RSJob -ScriptBlock {
        $finalStartTimestamps = $args[0]
        $finalRuntimeTimestamps = $args[1]
        $i = $args[2]
        $avLink = $args[3]
        $tempdir = $args[4]
				if ($finalStartTimestamps[$i] -eq "00:00:00.00") {
					if ($miniclipFileExt -eq "mkv") {
						ffmpeg -y -ss $finalStartTimestamps[$i] -i ($avLink) -t $finalRuntimeTimestamps[$i] -c copy "$tempdir/clip$($i+1).mkv"
					} else {
						ffmpeg -y -ss $finalStartTimestamps[$i] -i ($avLink) -t $finalRuntimeTimestamps[$i] -crf 18 "$tempdir/clip$($i+1).$miniclipFileExt"
					}
				} else {
					if ($miniclipFileExt -eq "mkv") {
						ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -c:v libx264 -c:a copy "$tempdir/clip$($i+1).mkv"
					} else {
						ffmpeg -y -ss $finalStartTimestamps[$i] -i ($vLink) -t $finalRuntimeTimestamps[$i] -crf 18 "$tempdir/clip$($i+1).$miniclipFileExt"
					}
				}
      } -ArgumentList $finalStartTimestamps, $finalRuntimeTimestamps, $i, $avLink, $tempdir
      $parallelChunkCount++
    }
  }
  if ($parallelChunkCount -eq $parallelChunkSize) {
    Get-RSJob -State Running | Wait-RSJob
    $parallelChunkCount = 0
  }
}
Get-RSJob -State Running | Wait-RSJob
if ($doNotStitch.toLower() -eq "true") {
	for ($i = 0; $i -lt $finalStartTimestamps.Count; $i++) {
		Move-Item -Path "$tempdir/clip$($i+1).$miniclipFileExt" -Destination "$dlDir/$outputTitle`_clip$($i+1).$miniclipFileExt"
	}
} else {
	for ($i = 0; $i -lt $finalStartTimestamps.Count; $i++) {
		$stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/clip$($i+1).mkv`" "
		$stitchCmdMapInputs = $stitchCmdMapInputs + "[$i`:v:0][$i`:a:0]"
	}
	$stitchCmdMapInputs = $stitchCmdMapInputs + "concat=n=$($finalStartTimestamps.Count)`:v=1:a=1[outv][outa]"
	$stitchCmd = "ffmpeg -y $stitchCmdInputs-crf 18 -filter_complex `"$stitchCmdMapInputs`" -map `"[outv]`" -map `"[outa]`" `"$dlDir/output.$outputFileExt`""
	Invoke-Expression $stitchCmd
	if ($rescaleVideo.toLower() -eq "true") {
		ffmpeg -i "$dlDir/output.$outputFileExt" -vf scale=1920x1080:flags=bicubic "$dlDir/outputSCALED.$outputFileExt"
		Remove-Item -Path "$dlDir/output.$outputFileExt"
    Rename-Item -Path "$dlDir/outputSCALED.$outputFileExt" -NewName "$outputTitle.$outputFileExt"
	} elseif ($outputTitle -ne "output") {
		Rename-Item -Path "$dlDir/output.$outputFileExt" -NewName "$outputTitle.$outputFileExt"
	}
	Get-RSJob | Remove-RSJob
	for ($i = 0; $i -lt $finalStartTimestamps.Count; $i++) {
		Remove-Item -Path "$tempdir/clip$($i+1).$miniclipFileExt"
	}
}