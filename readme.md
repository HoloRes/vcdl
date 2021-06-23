## Revision 9 Changelog
- Completely rewrote timestamp parser
- Modified parameter names

| Old Name | New Name |
|:---------|:---------|
| fulltitle | outputTitle |
| videotype | siteType |
| inlink | videoLink |
| timestampsIn | timestamps |
| fileOutExt | outputFileExt |

- Removed clip stitching with black screen seperator
- Added customizable miniclip time buffer (The time added to the start and end of each miniclip)

## General Usage Guide

There are only 3 arguments you are required to pass:
* `-siteType`: (youtube/other) - This specifies to the script how to get the file links for what you are downloading. You only need to specify youtube separately due to a difference in how youtube returns direct file links. All other sites or file links should use "other"
* `-videoLink`: The link to the youtube video, direct file link, or whatever you need to clip.
* `-timestamps`: MUST BE IN QUOTES, and specifies the timestamps to clip. Each timestamp pair must be formatted like [xx:xx:xx-xx:xx:xx], and you can have multiple pairs that are seperated with commas, no spaces, and the script will stitch those timestamp pairs together. Overlap that would be caused by adding the time buffer is automatically calculated, so no need to worry about that.

## Full List of Parameters

| Parameter | Type | Description | Tested |
|:----------|:-----|:------------|-------:|
| outputTitle | string | Specifies the title of the final video file.<br>`output` by default. | **YES** |
| siteType | restricted string (youtube/other) | Specifies the type of site you are clipping from.<br>Any other site besides YouTube should use "other" | **YES** |
| videoLink | string | The link to the video that will be clipped.<br>For any site not supported by youtube-dl, please use a direct file link. | **YES** |
| dlDir | Directory Path | Specifies where the final video, or set of clips (if `-doNotStitch` is `true`) will be located.<br>Set as the current working directory by default. | **YES** |
| timestamps | string | **MUST BE IN QUOTES.**<br>Is a set of timestamp pairs, formatted like `[xx:xx:xx-xx:xx:xx]`, with each pair being seperated by a comma.<br>Example: `"[0:00-1:00],[2:43-3:27]"` | **YES** |
| outputFileExt | string | The file extension for the final video file.<br>Changing this can result in extra re-encoding based on your settings, so use at your own risk.<br>`mkv` by default. | **YES** |
| miniclipFileExt | string | The file extension for each miniclip if you have multiple timestamp pairs.<br>This parameter only works when `-doNotStitch` is set to `true`.<br>`mkv` by default. | **YES** |
| useAltCodecs | boolean (true/false) | Allows the script to download videos above 1080p using YouTube's VP9 and AV1 codecs.<br>If set to `true`, this parameter will add extra re-encoding.<br>`false` by default. | **YES** |
| rescaleVideo | boolean (true/false) | Rescales the stitched clip to 1080p.<br>Intended to be used with videos below 1080p.<br>`false` by default. | **NO** |
| doNotStitch | boolean (true/false) | If more than one pair of timestamps are passed, this will save each timestamp pair as its own video.<br>Works in conjunction with `-miniclipFileExt`.<br>`false` by default. | **YES** |
| paddingInt | integer (0-30) | Specifies the amount of time, in seconds, to add to the start and end of each miniclip.<br>This extra time is referred to as the "time buffer" in these docs.<br>`5` by default. | **NO** |
| parallelChunkSize | integer (0+) | Specifies the maximum number of ffmpeg processes to run in parallel.<br>Mainly used to help lower the memory footprint of the script.<br>Setting this to a value over 10 is not advised, do so at your own risk.<br>`5` by default. | **YES** |
