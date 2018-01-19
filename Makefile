.phony: all

all: docs/fari.html

docs/fari.html: fari.sh
	git worktree prune
	[ -d $(@D) ] || git worktree add $(@D) gh-pages
	docco --output $(@D) $^
