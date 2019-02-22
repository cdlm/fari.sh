.phony: all check format pushdocs

all: README.md docs/fari.html

SHELLCHECK_OPTIONS = --color=always --shell=bash
SHFMT_OPTIONS = -ln bash -i 4 -ci -bn -s

check: fari.sh
	shellcheck $(SHELLCHECK_OPTIONS) $^
	bad=$$(shfmt $(SHFMT_OPTIONS) -l $^); \
		[ -z "$$bad" ] || { echo "$$bad"; false; }

format: fari.sh
	shfmt $(SHFMT_OPTIONS) -w $^

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
