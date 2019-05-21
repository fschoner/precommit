
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pre-commit-hooks

<!-- badges: start -->

<!-- badges: end -->

A collection of git pre-commit hooks to use with pre-commit.com.
Currently, we have:

  - `devtools-document`: A hook to run `devtools::document()`.

To add a pre-commit hook to your project, install pre-commit as
described in the [official documentation](https://pre-commit.com/#intro)
and make sure the executable `pre-commit` is in a place that is on your
`$PATH`.

If you installed pre-commit, you can add it to a specific project by
adding a `.pre-commit-config.yaml` file that has a structure like this:

``` yaml
-   repo: https://github.com/lorenzwalthert/pre-commit-hooks
    rev: 0be8269b3431af994c56a90b818540c1d526debc
    hooks: 
    -   id: devtools-document
```

Then, run `pre-commit install` in your repo and you are done. The next
time you run `$ git commit`, the hooks listed in your
`.pre-commit-config.yaml` will get exeuted before the commit.