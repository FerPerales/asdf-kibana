# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

# TODO: adapt this
asdf plugin test kibana https://github.com/ferperales/asdf-kibana.git "kibana --help"
```

Tests are automatically run in GitHub Actions on push and PR.
