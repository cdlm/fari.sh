.phony: all

all: README.md docs/fari.html

README.md: fari.sh
	sed -n '/^\s*$$/q; /^#!/d; s/^#//p' < $< > $@

docs/fari.html: fari.sh
	git worktree prune
	[ -d $(@D) ] || git worktree add $(@D) gh-pages
	docco --output $(@D) $^
