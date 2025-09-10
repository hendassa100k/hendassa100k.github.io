MD_FILES := $(shell find 'src/' -name '*.md')
HTML_FILES := $(patsubst src/%.md, build/%.html, $(MD_FILES))

HTML_HEADER := src/static/header.html
HTML_FOOTER := src/static/templates/footer.html
TARGET_STYLE_FILE := build/style.css
FORMAT_OPTIONS := -s -f markdown -t html

INDEX_TEMPLATE := src/static/templates/index.html
POST_TEMPLATE := src/static/templates/post.html
ATOM_TEMPLATE := src/static/templates/atom.xml

FEED_FILE := src/feed.yaml

all: pages feed
pages: $(HTML_FILES) build/index.html $(MD_FILES) $(TARGET_STYLE_FILE) $(IMAGE_FILES) 
feed: build/atom.xml

build/%.html: src/%.md
	mkdir -p $(dir $@)
	pandoc $(FORMAT_OPTIONS) --toc --template=$(POST_TEMPLATE) \
	-V 'atom-url:../atom.xml' -V 'main-page:../index.html' \
	--css=../style.css --quiet $< -o $@ < /dev/null

$(TARGET_STYLE_FILE): src/static/style.css
	cp $< $@

build/index.html: src/feed.yaml
	pandoc $(FORMAT_OPTIONS) --template=$(INDEX_TEMPLATE) \
	-V 'atom-url:atom.xml' --css=style.css \
	--metadata-file=$< --quiet -o $@ < /dev/null

build/atom.xml: src/feed.yaml src/static/templates/atom.xml
	pandoc --metadata-file=$(FEED_FILE) \
	--template=$(ATOM_TEMPLATE) \
	-t html -o build/atom.xml < /dev/null

clean:
	rm $(HTML_FILES)
	rm $(TARGET_STYLE_FILE)
