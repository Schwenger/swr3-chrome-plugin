
all: main/background.coffee
	coffee --compile main/background.coffee

.PHONY: clean
clean:
	touch main/background.js
	rm main/background.js
