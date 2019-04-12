install:
	gem install kitabu-2.1.0.gem

build:
	rm kitabu-2.1.0.gem; gem build kitabu.gemspec

uninstall:
	gem uninstall --silent kitabu

export: uninstall build install
	rm -fr temp; \
	mkdir temp && \
	cd temp && \
	kitabu new teste && \
	cd teste && \
	kitabu export --only epub
