# used to prevent setting up (most) unnecessary requests to swr3
initializing = false
# the radio element
radio = null
# url to recieve a playlist from the station
playlistURL = "http://mp3-live.swr3.de/swr3_s.m3u"
# sanity checks for inresponsive player resolving
lastRestartTime = 0
highFrequencyRestartCounter = 0

chrome.browserAction.onClicked.addListener (tab) ->
	trigger()

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) -> 
	trigger() if (request?.intent is "trigger_swr3")

trigger = () ->
	if radio?
		if radio.paused then start_stream() else stop_stream()
	else
		init_radio(playlistURL, start_stream) unless initializing	
	turned_on = not turned_on

init_radio = (url, callback) ->
	initializing = true
	jQuery.get(url, (content) -> 
		lines = content.split("\n")
		actual_url = findFirst(lines, (string) -> string.indexOf("#") isnt 0)
		radio_tmp = document.createElement('audio');
		radio_tmp.setId
		radio_tmp.setAttribute('src', actual_url);
		radio = radio_tmp
		initializing = false
		callback()
	)

findFirst = (array, predicate) ->
	for elem in array when predicate(elem)
		return elem

start_stream = () ->
	return if checkHighFrequencyRestarting() is "red"
	radio.play()
	if radio.paused
		console.log("player irresponsive; reinitializing")
		init_radio(playlistURL, start_stream)	
	else
		setIcon("green")

checkHighFrequencyRestarting = () ->
	status = "green"
	currentTime = new Date().getTime()
	if currentTime - lastRestartTime < 3 * 1000
		console.log("suspicion raised")
		highFrequencyRestartCounter++
		if highFrequencyRestartCounter > 3
			console.log("detected restarts in a high frequency; reinitializing")
			reset()
			status = "red"
	else
		highFrequencyRestartCounter = 0
	lastRestartTime = currentTime
	return status

reset = () ->
	radio = undefined
	highFrequencyRestartCounter = 0
	currentTime = 0
	init_radio(playlistURL, start_stream)

stop_stream = () ->
	radio.pause()
	if radio.paused
		setIcon("red")
	else
		console.log("player irresponsive; reinitializing")
		init_radio(playlistURL, stop_stream)

setIcon = (kind) ->
	chrome.browserAction.setIcon({
		path: "images/icon48" + kind + ".png"
	})



