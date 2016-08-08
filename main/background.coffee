# We avoid scoping issues by alerting the global scope to update the 
# radio upon the GET-request's arrival.
update_radio = (playlist) ->
	if radio? then radio.accept(playlist) else reset()

class Radio
	# the is and the expected state might deviate if the user repeatedly clicks on
	# the button while there was no response to the requests, yet.
	_is_on: false
	_expected_on: false
	_radio: undefined
	# 0 if not paused
	_paused_at: 0

	constructor: (@url) ->
		@_prepare()
	
	start: ->
		if @_radio?
			@_radio.play()
			@_is_on = true
			@_set_icon "green"
			@_paused_at = 0
		@_expected_on = true

	stop: ->
		if @_radio?
			@_radio.pause()
			@_is_on = false
			@_set_icon "red"
			@_paused_at = current_time()
		@_expected_on = false

	trigger: ->
		if @_is_on is @_expected_on
			if @_is_on then @stop() else @start()
		else 
			@_expected_on = !@_expected_on

	paused_since: ->
		if @_paused_at isnt 0 then (current_time() - @_paused_at) else 0

	kill: ->
		@_radio?.pause()
		@_radio?.remove()
		@_radio = undefined
		@_is_on = @_expected_on = false
		@_paused_at = 0

	reset: ->
		@kill()
		@_prepare()

	accept: (stream) ->
		@_create_radio_element stream

	_prepare: () ->
		@_fetch_playlist(update_radio)

	_fetch_playlist: (consumer) ->
		jQuery.get(@url, consumer)

	_create_radio_element: (playlist) ->
		stream = @_get_stream_url(playlist)
		radio = document.createElement('audio')
		radio.setAttribute('src', stream)
		@_radio = radio
		@_align_states()

	_align_states: ->
		if @_expected_on then @start() else @stop()
		@_paused_at = 0
		@_is_on = @_expected_on

	_get_stream_url: (playlist) ->
		for line in playlist.split("\n") when line.indexOf("#") isnt 0
			return line

	_set_icon: (color) ->
		chrome.browserAction.setIcon({
			path: "images/icon48#{color}.png"
		})

#### MAIN LOGIC ####
playlistURL = "http://mp3-live.swr3.de/swr3_s.m3u"

radio = new Radio playlistURL

reset_threshold = 10 * 60 * 1000 # ms, so 10 minutes

trigger = ->
	if radio.paused_since() > reset_threshold
		radio.reset()
	radio.trigger()

reset = ->
	radio.kill()
	radio = new Radio playlistURL

current_time = ->
	new Date().getTime()

#### CHROME EXTENSION HANDLING ####

chrome.browserAction.onClicked.addListener (tab) ->
	trigger()

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) -> 
	trigger() if (request?.intent is "trigger_swr3")

contextMenuId = chrome.contextMenus.create({
    "title": "Kill radio",
    "contexts": ["browser_action"]
    })

chrome.contextMenus.onClicked.addListener (info, tab) ->
	reset() if info.menuItemId is contextMenuId


