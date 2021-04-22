There are only 3 arguments you are required to pass:
* `-videotype`: (youtube/other) - This specifies to the script how to get the file links for what you are downloading. You only need to specify youtube separately due to a difference in how youtube returns direct file links. All other sites or file links should use "other"
* `-inlink`: The link to the youtube video, direct file link, or whatever you need to clip.
* `-timestampsIn`: must be in quotes, and specifies the timestamps to clip. Each timestamp pair must be formatted like [xx:xx:xx-xx:xx:xx], and you can have multiple pairs that are seperated with commas, no spaces, and the script will stitch those timestamp pairs together with a 3 second black screen. Overlap that would be caused by adding the 5 second buffers is automatically calculated, so no need to worry about that.

The rest of these arguments are optional, but help tell the script exactly what you want.
* `-dlDir`: must be in quotations, specifies where to download the clip. By default, the file is downloaded to the current working directory.
* `-fulltitle`: must be in quotations, specifies output file name. Output by default
* `-fileOutExt`: specifies the output extension for the file. Supports any extensions that ffmpeg can support. mkv by default
* `-rescaleVideo`: (true/false) - tells the script whether or not you want to rescale the video to 1080p, if the source is at a lower resolution. False by default.
* `-doNotStitch`: (true/false) - tells the script whether or not you want to save the clip as multiple files. False by default.
