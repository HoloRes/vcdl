# Written and Tested by Sheer Curiosity

# HoloClipper Revision 4 Version 5

# REQUIRED BINARIES (BOTH MUST BE ADDED TO PATH)
# -ffmpeg
# -ffprobe
# -youtube-dl

# Define parameters
param (
    [string]$fulltitle = "output",   # Defines the output filename, without extension
    [string]$videotype = $null,      # Defines the type of video being clipped
    [string]$inlink = $null,         # Defines input link
    [string]$dlDir = ".",            # Defines the download directory for the final file
    [string]$timestampsIn = $null,   # Defines the timestamps to be clipped
    [string]$fileOutExt = "mkv"      # Defines the output file extension
)
# Define directory for temporary files
$tempdir = "."

# Define "parser" function, which parses the input timestamps into a format
# the script can work with
#
# I'm scared to touch this function, mainly because I forgot how exactly
# it works.
function parser($clipstamps) {
    $clipTimestamps=$clipstamps.trim("[]")
    $clip1st1,$clip1st2=$clipTimestamps.split("-")
    $c1st1array=$clip1st1.split(":")
    $c1st2array=$clip1st2.split(":")
    $c1a1,$c1a2,$c1a3=$clip1st1.split(":")
    $c1b1,$c1b2,$c1b3=$clip1st2.split(":")
    $c1a0 = 0
    $c1a1 = [int]$c1a1
    $c1a2 = [int]$c1a2
    $c1a3 = [int]$c1a3
    $c1b0 = 0
    $c1b1 = [int]$c1b1
    $c1b2 = [int]$c1b2
    $c1b3 = [int]$c1b3
    if ($c1st1array.length -eq 2) {
        while ($c1a1 -ge 60) {
            $c1a1 = $c1a1 - 60
            $c1a0 ++
        }
        if (($c1a1.tostring().length) -eq 1) {
            $c1a1 = "0$c1a1"
        }
        if (($c1a2.tostring().length) -eq 1) {
            $c1a2 = "0$c1a2"
        }
        $tsin = "$c1a0`:$c1a1`:$c1a2`:00"
    }
    if ($c1st1array.length -eq 3) {
        if (($c1a1.tostring().length) -eq 1) {
             $c1a1 = "0$c1a1"
        }
        if (($c1a2.tostring().length) -eq 1) {
            $c1a2 = "0$c1a2"
        }
        if (($c1a3.tostring().length) -eq 1) {
            $c1a3 = "0$c1a3"
        }
        $tsin = "$c1a1`:$c1a2`:$c1a3`:00"
    }
    if ($c1st2array.length -eq 2) {
        while ($c1b1 -ge 60) {
            $c1b1 = $c1b1 - 60
            $c1b0 ++
        }
        if (($c1b1.tostring().length) -eq 1) {
            $c1b1 = "0$c1b1"
        }
        if (($c1b2.tostring().length) -eq 1) {
            $c1b2 = "0$c1b2"
        }
        $tein = "$c1b0`:$c1b1`:$c1b2`:00"
    }
    if ($c1st2array.length -eq 3) {
        if (($c1b1.tostring().length) -eq 1) {
      	    $c1b1 = "0$c1b1"
        }
        if (($c1b2.tostring().length) -eq 1) {
            $c1b2 = "0$c1b2"
        }
        if (($c1b3.tostring().length) -eq 1) {
            $c1b3 = "0$c1b3"
        }
        $tein = "$c1b1`:$c1b2`:$c1b3`:00"
		}
    $clipts = $tsin.split(":")
    $clipts1 = [int]$clipts[0] #1ts1
    $clipts2 = [int]$clipts[1] #1ts2
    $clipts3 = [int]$clipts[2] #1ts3
    $clipts4 = [int]$clipts[3] #1ts4
    if ($clipts3 -lt 5 -and $clipts2 -eq 0 -and $clipts1 -eq 0) {
        $clipts3 = 0
    }
    else {
        $clipts3 = $clipts3 - 5
        if ($clipts3 -lt 0) {
            $clipts3 = $clipts3 + 60
            $clipts2 = $clipts2 - 1
            if ($clipts2 -lt 0) {
                $clipts2 = $clipts2 + 60
                $clipts1 = $clipts1 - 1
            }
        }
    }
    $clipte = $tein.split(":")
    $clipte1 = [int]$clipte[0] #1te1
    $clipte2 = [int]$clipte[1] #1te2
    $clipte3 = [int]$clipte[2] #1te3
    $clipte4 = [int]$clipte[3] #1te4
    $clipte3 = $clipte3 + 5
    if ($clipte3 -ge 60) {
        $clipte3 = $clipte3 - 60
        $clipte2 = $clipte2 + 1
        if ($clipte2 -ge 60) {
            $clipte2 = $clipte2 - 60
            $clipte1 = $clipte1 + 1
        }
    }
    $cliptc1 = $clipte1 - $clipts1
    $cliptc2 = $clipte2 - $clipts2
    $cliptc3 = $clipte3 - $clipts3
    $cliptc4 = $clipte4 - $clipts4
    if ($cliptc3 -lt 0) {
        $cliptc3 = $cliptc3 + 60
        $cliptc2 = $cliptc2 - 1
        if ($cliptc2 -lt 0) {
            $cliptc2 = $cliptc2 + 60
            $cliptc1 = $cliptc1 - 1
        }
    }
    if (($cliptc1.tostring().length) -eq 1) {
        $cliptc1 = "0$cliptc1"
    }
    if (($cliptc2.tostring().length) -eq 1) {
        $cliptc2 = "0$cliptc2"
    }
    if (($cliptc3.tostring().length) -eq 1) {
        $cliptc3 = "0$cliptc3"
    }
    if (($cliptc4.tostring().length) -eq 1) {
        $cliptc4 = "0$cliptc4"
    }
    if (($clipts1.tostring().length) -eq 1) {
        $clipts1 = "0$clipts1"
    }
    if (($clipts2.tostring().length) -eq 1) {
        $clipts2 = "0$clipts2"
    }
    if (($clipts3.tostring().length) -eq 1) {
        $clipts3 = "0$clipts3"
    }
    if (($clipts4.tostring().length) -eq 1) {
        $clipts4 = "0$clipts4"
    }
    $clipSps = "$clipts1`:$clipts2`:$clipts3.$clipts4"
    $clipRt = "$cliptc1`:$cliptc2`:$cliptc3.$cliptc4"
    return $clipSps, $clipRt
}
$clipper = {
    $miniclipnum = $timestampsIn.split(",").length
    $parserNum = $timestampsIn.split(",").length
    $clipsSps = @()
    $clipsRt = @()
    $clipnum = 0
    $clipnumout = 1
    $mapperNum = 0
    $ytdlAttempts = 0
    $clipStamps=$timestampsIn.split(",")
    if ($videotype.toLower() -eq "youtube") {
        while (!$glinks -and $ytdlAttempts -lt 5) {
            $glinks = youtube-dl -g "$inlink"
            $glinksBACKUP = youtube-dl -g --youtube-skip-dash-manifest "$inlink"
            $ytdlAttempts = $ytdlAttempts + 1
        }
        if ($ytdlAttempts -eq 5) {
            Write-output "Error Fetching Direct File Links. Verify Inputted Media Link"
            Throw "ERROR: YTDL failed to fetch media links"
        }
        $glink1,$glink2 = $glinks.split(" ")
        $glinkBACK1,$glinkBACK2 = $glinksBACKUP.split(" ")
        if (!$glink2) {$glink2 = $glink1}
        if (!$glinkBACK2) {$glinkBACK2 = $glinkBACK1}
    }
    if ($videotype.toLower() -eq "other") {
        $glink = youtube-dl -g "$inlink"
        while (!$glink-and $ytdlAttempts -lt 5) {
            $glink = youtube-dl -g "$inlink"
            $ytdlAttempts = $ytdlAttempts + 1
        }
        if ($ytdlAttempts -eq 5) {
            Write-output "Error Fetching Direct File Links. Verify Inputted Media Link"
            Throw "ERROR: YTDL failed to fetch media links"
        }
    }
    while ($parserNum -gt 0) {
        $parserOut = parser $clipStamps[$clipnum]
        $clipsSps += $parserOut[0]
        $clipsRt += $parserOut[1]
        if ($videotype.toLower() -eq "youtube") {
            if ($miniclipnum -eq 1) {
                ffmpeg -y -ss $clipsSps[$clipnum] -i ($glink1) -t $clipsRt[$clipnum] -ss $clipsSps[$clipnum] -i ($glink2) -t $clipsRt[$clipnum] "$dlDir/$fulltitle.$fileOutExt"
                if ((Test-Path("$dlDir/$fulltitle.$fileOutExt")) -eq $true) {
                    Write-output "Clipping Complete"
                }
                else {
                    ffmpeg -y -ss $clipsSps[$clipnum] -i ($glinkBACK1) -t $clipsRt[$clipnum] -ss $clipsSps[$clipnum] -i ($glinkBACK2) -t $clipsRt[$clipnum] "$dlDir/$fulltitle.$fileOutExt"
                    if ((Test-Path("$dlDir/$fulltitle.$fileOutExt")) -eq $true) {
                        Write-output "Clipping Complete"
                    }
                    else {
                        Write-output "Clipping Unsuccessful"
                    }
                }
            }
            if ($miniclipnum -ge 2) {
                ffmpeg -y -ss $clipsSps[$clipnum] -i ($glink1) -t $clipsRt[$clipnum] -ss $clipsSps[$clipnum] -i ($glink2) -t $clipsRt[$clipnum] "$tempdir/clip$clipnumout.mkv"
                if ((Test-Path("$tempdir/clip$clipnumout.mkv")) -eq $true) {
                    $stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/clip$clipnumout.mkv`" "
                    $stitchCmdMapInputs = $stitchCmdMapInputs + "[$mapperNum`:v:0][$mapperNum`:a:0]"
                    $stitchCmdMapInputsCount ++
                    if ($parsernum -gt 1) {
                        $mapperNum ++
                        $stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/blackscreen.mkv`" "
                        $stitchCmdMapInputs = $stitchCmdMapInputs + "[$mapperNum`:v:0][$mapperNum`:a:0]"
                        $stitchCmdMapInputsCount ++
                    }
                }
                else {
                    ffmpeg -y -ss $clipsSps[$clipnum] -i ($glink1) -t $clipsRt[$clipnum] -ss $clipsSps[$clipnum] -i ($glink2) -t $clipsRt[$clipnum] "$tempdir/clip$clipnumout.mkv"
                    if ((Test-Path("$tempdir/clip$clipnumout.mkv")) -eq $true) {
                        $stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/clip$clipnumout.mkv`" "
                        $stitchCmdMapInputs = $stitchCmdMapInputs + "[$mapperNum`:v:0][$mapperNum`:a:0]"
                        $stitchCmdMapInputsCount ++
                        if ($parsernum -gt 1) {
                            $mapperNum ++
                            $stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/blackscreen.mkv`" "
                            $stitchCmdMapInputs = $stitchCmdMapInputs + "[$mapperNum`:v:0][$mapperNum`:a:0]"
                            $stitchCmdMapInputsCount ++
                        }
                    }
                    else {
                        Write-output "Clipping Unsuccessful"
                    }
                }
            }
        }
        if ($videotype.toLower() -eq "other") {
            if ($miniclipnum -eq 1) {
                ffmpeg -y -ss $clipsSps[$clipnum] -i ($glink) -t $clipsRt[$clipnum] "$dlDir/$fulltitle.$fileOutExt"
                if ((Test-Path("$dlDir/$fulltitle.$fileOutExt")) -eq $true) {
                    Write-output "Clipping Complete"
                }
                else {
                    Write-output "Clipping Unsuccessful"
                }
            }
            if ($miniclipnum -ge 2) {
                ffmpeg -y -ss $clipsSps[$clipnum] -i ($glink) -t $clipsRt[$clipnum] "$tempdir/clip$clipnumout.mkv"
                $stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/clip$clipnumout.mkv`" "
                $stitchCmdMapInputs = $stitchCmdMapInputs + "[$mapperNum`:v:0][$mapperNum`:a:0]"
                $stitchCmdMapInputsCount ++
                if ($parsernum -gt 1) {
                    $mapperNum ++
                    $stitchCmdInputs = $stitchCmdInputs + "-i `"$tempdir/blackscreen.mkv`" "
                    $stitchCmdMapInputs = $stitchCmdMapInputs + "[$mapperNum`:v:0][$mapperNum`:a:0]"
                    $stitchCmdMapInputsCount ++
                }
            }
        }
        $mapperNum ++
        $clipnum ++
        $clipnumout ++
        $parserNum --
    }
    $stitchCmdMapInputs = $stitchCmdMapInputs + "concat=n=$stitchCmdMapInputsCount`:v=1:a=1[outv][outa]"
    $stitchCmd = "ffmpeg -y -hide_banner -loglevel error $stitchCmdInputs -filter_complex `"$stitchCmdMapInputs`" -map `"[outv]`" -map `"[outa]`" -x264-params keyint=24:min-keyint=1 `"$dlDir/output.$fileOutExt`""
    if ($miniclipnum -ge 2) {
        $clipresolution = ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$tempdir/clip1.mkv"
        $clipbitrate = ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=s=x:p=0 "$tempdir/clip1.mkv"
        $clipframerate = ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=s=x:p=0 "$tempdir/clip1.mkv"
        ffmpeg -y -f lavfi -i color=black:s="$clipresolution":r=$clipframerate -f lavfi -i anullsrc -ar $clipbitrate -ac 2 -t 3 "$tempdir/blackscreen.mkv"
        Invoke-Expression $stitchCmd
        Rename-Item -Path "$dlDir/output.$fileOutExt" -NewName "$fulltitle.$fileOutExt"
        if ((Test-Path("$dlDir/$fulltitle.$fileOutExt")) -eq $true) {
            Write-output "Clipping Complete"
        }
        else {
            Write-output "Clipping Unsuccessful"
        }
        $parsernum = $miniclipnum
        $clipnumout = 1
        remove-item "$tempdir/blackscreen.mkv"  
        while ($parserNum -gt 0) {
            remove-Item -path "$tempdir/clip$clipnumout.mkv"
            $clipnumout ++
            $parserNum --
        }
    }
    else {return}
}
&$clipper