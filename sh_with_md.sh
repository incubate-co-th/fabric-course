: set ft=markdown ;:<<'```shell' # Skip to the next shell block
# Markdown part
```shell
echo 'shell part'
:<<'```shell'  # This will skip to the next shell block again
```
## Markdown again
```shell
echo 'shell part 2'
:<<'```'  # End of the document
```
