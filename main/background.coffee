# used to prevent setting up (most) unnecessary requests to swr3
initializing = false
# the radio element
radio = null
# tracks stream's status
turned_on = false

chrome.browserAction.onClicked.addListener (tab) ->
	if radio?
		if turned_on then stop_stream() else start_stream()
	else
		init_radio("http://mp3-live.swr3.de/swr3_s.m3u", start_stream) unless initializing	
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
	radio.play()

stop_stream = () ->
	radio.pause()
