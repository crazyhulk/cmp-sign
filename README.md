# cmp-sign

Get the sign of the function, for example:

input:
`sort.Slice.sign`

output:
`func (x any, less func(i int, j int) bool)`


support [mockey](https://github.com/bytedance/mockey)

![mockey](./mockey.jpg)

# install

## Packer
```
use { 'crazyhulk/cmp-sign' }
```

# Setup

```

require'cmp'.setup {
  sources = {
    { name = 'nvim_cmp_sign' }
  }
}
```
