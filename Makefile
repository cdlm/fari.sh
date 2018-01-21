.phony: all pushdocs

all: README.md docs/fari.html

pushdocs: all
	! git -C docs diff --no-patch --exit-code
	git -C docs commit --all --message "Rebuild docs"
	git -C docs push

README.md: fari.sh
	sed -n '/^\s*$$/q; /^#!/d; s/^#//p' < $< > $@

docs/fari.html: fari.sh
	git worktree prune
	[ -d $(@D) ] || git worktree add $(@D) gh-pages
	docco --output $(@D) $^
